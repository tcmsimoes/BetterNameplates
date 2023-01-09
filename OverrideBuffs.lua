local myPlayerBuffs = {
-- other classes
---- defensive
    ["Guardian Spirit"] = true,
    ["Divine Hymn"] = true,
    ["Pain Suppression"] = true,
    ["Power Word: Barrier"] = true,
    ["Spirit Link Totem"] = true,
    ["Healing Tide Totem"] = true,
    ["Ironbark"] = true,
    ["Tranquility"] = true,
    ["Life Cocoon"] = true,
    ["Revival"] = true,
    ["Blessing of Sacrifice"] = true,
    ["Aura Mastery"] = true,
    ["Commanding Shout"] = true,
    ["Darkness"] = true,
---- offensive
    ["Bloodlust"] = true,
    ["Time Warp"] = true,
-- dk
    ["Anti-Magic Shell"] = true,
    ["Icebound Fortitude"] = true,
    ["Dark Succor"] = true,
    ["Icy Talons"] = false,
---- blood
    ["Bone Shield"] = true,
    ["Vampiric Blood"] = true,
    ["Dancing Rune Weapon"] = true,
    ["Rune Tap"] = true,
    ["Tombstone"] = true,
    ["Bonestorm"] = true,
    ["Vampiric Aura"] = true,
    ["Sanguine Ground"] = true,
---- frost
    ["Pillar of Frost"] = true,
    ["Obliteration"] = true,
    ["Breath of Sindragosa"] = true,
    ["Cold Heart"] = true,
    ["Unleashed Frenzy"] = true,
---- unholy
    ["Festermight"] = true,
    ["Helchains"] = true,
};

local myTargetDebuffs = {
-- hunter
    ["Death Chakram"] = true,
};



local function MyFilterTargetDebuff(aura)
    if myTargetDebuffs[aura.name] ~= nil and myTargetDebuffs[aura.name] == false then
        return false
    end

    return myTargetDebuffs[aura.name] or aura.nameplateShowPersonal;
end

local function MyFilterPlayerBuff(aura)
    if myPlayerBuffs[aura.name] ~= nil and myPlayerBuffs[aura.name] == false then
        return false
    end

    return myPlayerBuffs[aura.name] or aura.nameplateShowPersonal;
end

local function MyShouldShowBuff(frame, aura, forceAll)
    if not aura or not aura.name then
        return false;
    end

    aura.filter = frame.filter;

    if UnitIsPlayer(frame.unit) then
        return (forceAll or (aura.isHelpful and MyFilterPlayerBuff(aura)) or frame.myPlayerDebuffs)
                and not C_UnitAuras.IsAuraFilteredOutByInstanceID(frame.unit, aura.auraInstanceID, aura.filter);
    else
        if not aura.isHelpful then
            return (forceAll or aura.nameplateShowAll
                    or (MyFilterTargetDebuff(aura) and (aura.sourceUnit == "player" or aura.sourceUnit == "pet" or aura.sourceUnit == "vehicle")))
                    and not C_UnitAuras.IsAuraFilteredOutByInstanceID(frame.unit, aura.auraInstanceID, aura.filter)
        else
            aura.filter = AuraUtil.AuraFilters.Helpful;
            return (forceAll or not UnitIsPlayer(frame.unit))
                    and not C_UnitAuras.IsAuraFilteredOutByInstanceID(frame.unit, aura.auraInstanceID, aura.filter);
        end
    end
end

local function MyParseAllAuras(frame, forceAll)
    if not frame.myAuras then
        frame.myAuras = TableUtil.CreatePriorityTable(AuraUtil.DefaultAuraCompare, TableUtil.Constants.AssociativePriorityTable);
    else
        frame.myAuras:Clear();
    end

    local function HandleAura(aura)
        if MyShouldShowBuff(frame, aura, forceAll) then
            frame.myAuras[aura.auraInstanceID] = aura;
        end

        return false;
    end

    local batchCount = nil;
    local usePackedAura = true;
    AuraUtil.ForEachAura(frame.unit, frame.filter, batchCount, HandleAura, usePackedAura);

    -- add enemy buffs
    if not UnitIsPlayer(frame.unit) then
        AuraUtil.ForEachAura(frame.unit, AuraUtil.AuraFilters.Helpful, batchCount, HandleAura, usePackedAura);
    end
end

local function MyUpdateBuffs(frame, unit, unitAuraUpdateInfo, auraSettings)
    if frame.auras then
        frame.auras:Clear();
    end

    local filters = {};
    if frame.myPlayerDebuffs then
        table.insert(filters, AuraUtil.AuraFilters.Harmful);
    elseif auraSettings.harmful then
        table.insert(filters, AuraUtil.AuraFilters.Harmful);
        if auraSettings.includeNameplateOnly then
            table.insert(filters, AuraUtil.AuraFilters.Player);
        end
        if auraSettings.raid then
            table.insert(filters, AuraUtil.AuraFilters.Raid);
        end
    elseif auraSettings.helpful then
        table.insert(filters, AuraUtil.AuraFilters.Helpful);
    end
    local filterString = AuraUtil.CreateFilterString(unpack(filters));

    local previousFilter = frame.myPreviousFilter;
    frame.myPreviousFilter = frame.filter;
    frame.filter = filterString;
    local previousUnit = frame.myPreviousUnit;
    frame.myPreviousUnit = unit;
    local aurasChanged = false;

    if not unitAuraUpdateInfo or unitAuraUpdateInfo.isFullUpdate or unit ~= previousUnit or not frame.myAuras or filterString ~= previousFilter then
        MyParseAllAuras(frame, auraSettings.showAll);
        aurasChanged = true;
    else
        if unitAuraUpdateInfo.addedAuras then
            for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
                if MyShouldShowBuff(frame, aura, auraSettings.showAll) then
                    frame.myAuras[aura.auraInstanceID] = aura;
                    aurasChanged = true;
                end
            end
        end

        if unitAuraUpdateInfo.updatedAuraInstanceIDs then
            for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
                if not frame.myAuras[auraInstanceID] then
                    local newAura = C_UnitAuras.GetAuraDataByAuraInstanceID(frame.unit, auraInstanceID);
                    frame.myAuras[auraInstanceID] = newAura;
                    aurasChanged = true;
                end
            end
        end

        if unitAuraUpdateInfo.removedAuraInstanceIDs then
            for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
                if not frame.myAuras[auraInstanceID] then
                    frame.myAuras[auraInstanceID] = nil;
                    aurasChanged = true;
                end
            end
        end
    end

    frame:UpdateAnchor();

    if not aurasChanged then
        return;
    end

    frame.buffPool:ReleaseAll();

    local buffIndex = 1;
    frame.myAuras:Iterate(function(auraInstanceID, aura)
        local buff = frame.buffPool:Acquire();
        buff.isBuff = aura.isHelpful;
        buff.layoutIndex = buffIndex;
        buff.spellID = aura.spellId;
        buff.auraInstanceID = nil;
        buff.Icon:SetTexture(aura.icon);
        buff:SetMouseClickEnabled(false);

        buff.Cooldown:SetEdgeTexture("Interface\\Cooldown\\edge");
        buff.Cooldown:SetSwipeColor(0, 0, 0);
        CooldownFrame_Set(buff.Cooldown, aura.expirationTime - aura.duration, aura.duration, aura.duration > 0, true);

        if aura.applications > 1 then
            buff.CountFrame.Count:SetText(aura.applications);
            buff.CountFrame.Count:Show();
        else
            buff.CountFrame.Count:Hide();
        end

        if not buff.MyBorder then
            buff.MyBorder = CreateFrame("Frame", nil, buff, "BackdropTemplate");
            buff.MyBorder:SetFrameStrata(buff:GetFrameStrata(), buff:GetFrameLevel() + 1)
            buff.MyBorder:SetAllPoints(buff);
            buff.MyBorder:SetBackdrop({
                edgeFile = [[Interface/Buttons/WHITE8X8]],
                edgeSize = 1,
            });
        end
        buff.MyBorder:Hide();

        if aura.isHelpful and not aura.isFromPlayerOrPlayerPet then
            if aura.isStealable then
                buff.MyBorder:SetBackdropBorderColor(0.0, 0.0, 1.0, 0.7);
            elseif not aura.isFromPlayerOrPlayerPet then
                buff.MyBorder:SetBackdropBorderColor(1.0, 0.0, 0.0, 0.7);
            end

            buff.MyBorder:Show();
        end

        buff:Show();

        buffIndex = buffIndex + 1;
        return buffIndex >= BUFF_MAX_DISPLAY;
    end);

    frame:Layout();
end

hooksecurefunc(_G.NamePlateDriverFrame, "OnNamePlateAdded", function(self, namePlateUnitToken)
    local namePlateFrameBase = C_NamePlate.GetNamePlateForUnit(namePlateUnitToken, issecure());
    if namePlateFrameBase then
        if not namePlateFrameBase.UnitFrame.BuffFrame.mySetActiveHook then
            hooksecurefunc(namePlateFrameBase.UnitFrame.BuffFrame, "SetActive", function(self, ...)
                self.isActive = false;
            end);
            namePlateFrameBase.UnitFrame.BuffFrame.mySetActiveHook = true;
        end

        if not namePlateFrameBase.UnitFrame.BuffFrame.myUpdateBuffsHook then
            hooksecurefunc(namePlateFrameBase.UnitFrame.BuffFrame, "UpdateBuffs", function(self, ...)
                self.myPlayerDebuffs = false;
                MyUpdateBuffs(self, ...);
            end);
            namePlateFrameBase.UnitFrame.BuffFrame.myUpdateBuffsHook = true;
        end

        namePlateFrameBase.UnitFrame.BuffFrame:SetActive(false);
        self:OnUnitAuraUpdate(namePlateUnitToken);
    end
end);

hooksecurefunc(_G.PersonalFriendlyBuffFrame, "SetActive", function(self, ...)
    self.isActive = false;
end);

hooksecurefunc(_G.PersonalFriendlyBuffFrame, "UpdateBuffs", function(self, ...)
    self.myPlayerDebuffs = true;
    MyUpdateBuffs(self, ...);
end);