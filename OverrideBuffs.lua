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
    ["Empower Rune Weapon"] = false,
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
-- warrior
    ["Victorious"] = true,
---- fury
    ["Enrage"] = true,
    ["Juggernaut"] = true,
    ["Battle Cry"] = true,
    ["Whirlwind"] = true,
---- arms
    ["Shattered Defenses"] = true,
    ["Weighted Blade"] = true,
    ["Executioner's Precision"] = true,
-- hunter
---- beast mastery
    ["Barbed Shot"] = true,
-- paladin
    ["Selfless Healer"] = true,
-- druid
---- balance
    ["Starfall"] = true,
-- shaman
---- enhancement
    ["Lightning Shield"] = true,
    ["Crash Lightning"] = true,
-- monk
---- brewmaster
    ["Rushing Jade Wind"] = true,
---- windwalker
    ["Hit Combo"] = true,
-- mage
---- fire
    ["Blazing Barrier"] = true,
    ["Enhanced Pyrotechnics"] = true,
};

local myPlayerDebuffs = {
    ["Challenger's Burden"] = false,
}

local myTargetBuffs = {
    ["Challenger's Might"] = false,
};

local myTargetDebuffs = {
-- hunter
    ["Death Chakram"] = true,
};

local function MyShouldShowTargetBuff(aura)
    if myTargetBuffs[aura.name] ~= nil and myTargetBuffs[aura.name] == false then
        return false
    end

    return true
end

local function MyShouldShowTargetDebuff(aura)
    if myTargetDebuffs[aura.name] ~= nil and myTargetDebuffs[aura.name] == false then
        return false
    end

    return myTargetDebuffs[aura.name] or aura.nameplateShowPersonal
end

local function MyShouldShowPlayerBuff(aura)
    if myPlayerBuffs[aura.name] ~= nil and myPlayerBuffs[aura.name] == false then
        return false
    end

    return myPlayerBuffs[aura.name] or aura.nameplateShowPersonal
end

local function MyShouldShowPlayerDebuff(aura)
    if myPlayerDebuffs[aura.name] ~= nil and myPlayerDebuffs[aura.name] == false then
        return false
    end

    return true
end


local function MyShouldShowBuff(self, aura, forceAll)
    if not aura or not aura.name then
        return false;
    end

    aura.filter = self.filter;

    if UnitIsUnit(self.unit, "player") then
        if not aura.isHelpful then
            return (forceAll or aura.nameplateShowAll
                    or MyShouldShowPlayerDebuff(aura))
                    and not C_UnitAuras.IsAuraFilteredOutByInstanceID(self.unit, aura.auraInstanceID, aura.filter)
                    and self.myPlayerDebuffs
        else
            aura.filter = AuraUtil.AuraFilters.Helpful;
            return (forceAll or aura.nameplateShowAll
                    or MyShouldShowPlayerBuff(aura))
                    and not C_UnitAuras.IsAuraFilteredOutByInstanceID(self.unit, aura.auraInstanceID, aura.filter)
                    and not self.myPlayerDebuffs
        end
    else
        if not aura.isHelpful then
            return (forceAll or aura.nameplateShowAll
                    or (MyShouldShowTargetDebuff(aura) and (aura.sourceUnit == "player" or aura.sourceUnit == "pet" or aura.sourceUnit == "vehicle")))
                    and not C_UnitAuras.IsAuraFilteredOutByInstanceID(self.unit, aura.auraInstanceID, aura.filter)
                    and not self.myPlayerDebuffs
        else
            aura.filter = AuraUtil.AuraFilters.Helpful;
            return (forceAll or aura.nameplateShowAll
                    or (MyShouldShowTargetBuff(aura)  and not UnitIsPlayer(self.unit)))
                    and not C_UnitAuras.IsAuraFilteredOutByInstanceID(self.unit, aura.auraInstanceID, aura.filter)
                    and not self.myPlayerDebuffs
        end
    end
end

local function MyParseAllAuras(self, forceAll)
    if self.auras == nil then
        self.auras = TableUtil.CreatePriorityTable(AuraUtil.DefaultAuraCompare, TableUtil.Constants.AssociativePriorityTable);
    else
        self.auras:Clear();
    end

    local function HandleAura(aura)
        if MyShouldShowBuff(self, aura, forceAll) then
            self.auras[aura.auraInstanceID] = aura;
        end

        return false;
    end

    local batchCount = nil;
    local usePackedAura = true;
    AuraUtil.ForEachAura(self.unit, self.filter, batchCount, HandleAura, usePackedAura);

    -- add enemy buffs
    if not UnitIsPlayer(self.unit) then
        AuraUtil.ForEachAura(self.unit, AuraUtil.AuraFilters.Helpful, batchCount, HandleAura, usePackedAura);
    end
end

local function MyUpdateBuffs(self, unit, unitAuraUpdateInfo, auraSettings)
    local filters = {};
    if self.myPlayerDebuffs then
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

    local previousFilter = self.filter;
    local previousUnit = self.unit;
    self.unit = unit;
    self.filter = filterString;
    self.showFriendlyBuffs = auraSettings.showFriendlyBuffs;

    local aurasChanged = false;
    if unitAuraUpdateInfo == nil or unitAuraUpdateInfo.isFullUpdate or unit ~= previousUnit or self.auras == nil or filterString ~= previousFilter then
        MyParseAllAuras(self, auraSettings.showAll);
        aurasChanged = true;
    else
        if unitAuraUpdateInfo.addedAuras ~= nil then
            for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
                if MyShouldShowBuff(self, aura, auraSettings.showAll) then
                    self.auras[aura.auraInstanceID] = aura;
                    aurasChanged = true;
                end
            end
        end

        if unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil then
            for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
                if self.auras[auraInstanceID] ~= nil then
                    local newAura = C_UnitAuras.GetAuraDataByAuraInstanceID(self.unit, auraInstanceID);
                    self.auras[auraInstanceID] = newAura;
                    aurasChanged = true;
                end
            end
        end

        if unitAuraUpdateInfo.removedAuraInstanceIDs ~= nil then
            for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
                if self.auras[auraInstanceID] ~= nil then
                    self.auras[auraInstanceID] = nil;
                    aurasChanged = true;
                end
            end
        end
    end

    self:UpdateAnchor();

    if not aurasChanged then
        return;
    end

    self.buffPool:ReleaseAll();

    if auraSettings.hideAll or not self.isActive then
        return;
    end

    local buffIndex = 1;
    self.auras:Iterate(function(auraInstanceID, aura)
        local buff = self.buffPool:Acquire();
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
        return buffIndex >= 10;
    end);

    self:Layout();
end

local function MyUpdateDebuffs(self, unit, unitAuraUpdateInfo, auraSettings)
    self.myPlayerDebuffs = true;

    MyUpdateBuffs(self, unit, unitAuraUpdateInfo, auraSettings)
end

hooksecurefunc(_G.NamePlateDriverFrame, "OnNamePlateAdded", function(self, namePlateUnitToken)
    local namePlateFrameBase = C_NamePlate.GetNamePlateForUnit(namePlateUnitToken, issecure());
    if namePlateFrameBase and namePlateFrameBase.UnitFrame and namePlateFrameBase.UnitFrame.BuffFrame then
        namePlateFrameBase.UnitFrame.BuffFrame.UpdateBuffs = MyUpdateBuffs;

        self:OnUnitAuraUpdate(namePlateUnitToken);
    end
end);

_G.PersonalFriendlyBuffFrame.UpdateBuffs = MyUpdateDebuffs;