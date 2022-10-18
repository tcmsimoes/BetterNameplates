local visibilePlayerBuffs = {
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
---- blood
    ["Bone Shield"] = true,
    ["Vampiric Blood"] = true,
    ["Dancing Rune Weapon"] = true,
    ["Rune Tap"] = true,
    ["Blood Mirror"] = true,
    ["Bonestorm"] = true,
    ["Vampiric Aura"] = true,
---- frost
    ["Pillar of Frost"] = true,
    ["Obliteration"] = true,
    ["Breath of Sindragosa"] = true,
    ["Cold Heart"] = true,
    ["Empower Rune Weapon"] = true,
---- unholy
    ["Festermight"] = true,
    ["Helchains"] = true,
};

local function MyShouldShowBuff(frame, aura, forceAll)
    if not aura or not aura.name then
        return false;
    end

    if UnitIsPlayer(frame.unit) then
        return (frame.showFriendlyBuffs and not aura.isHelpful)
                and not C_UnitAuras.IsAuraFilteredOutByInstanceID(frame.unit, aura.auraInstanceID, AuraUtil.AuraFilters.Harmful);
    else
        return ((aura.nameplateShowAll or forceAll or
                (aura.nameplateShowPersonal and (aura.sourceUnit == "player" or aura.sourceUnit == "pet" or aura.sourceUnit == "vehicle")))
                and not C_UnitAuras.IsAuraFilteredOutByInstanceID(frame.unit, aura.auraInstanceID, AuraUtil.AuraFilters.Harmful)) or
                ((aura.isHelpful and not UnitIsPlayer(frame.unit))
                and not C_UnitAuras.IsAuraFilteredOutByInstanceID(frame.unit, aura.auraInstanceID, AuraUtil.AuraFilters.Helpful));
    end
end

local function MyParseAllAuras(frame, forceAll)
    if frame.auras == nil then
        frame.auras = TableUtil.CreatePriorityTable(AuraUtil.DefaultAuraCompare, TableUtil.Constants.AssociativePriorityTable);
    else
        frame.auras:Clear();
    end

    local function HandleAura(aura)
        if MyShouldShowBuff(frame, aura, forceAll) then
            frame.auras[aura.auraInstanceID] = aura;
        end

        return false;
    end

    local batchCount = nil;
    local usePackedAura = true;
    AuraUtil.ForEachAura(frame.unit, frame.filter, batchCount, HandleAura, usePackedAura);

    if not UnitIsPlayer(frame.unit) then
        -- complete with buffs
        AuraUtil.ForEachAura(frame.unit, AuraUtil.AuraFilters.Helpful, batchCount, HandleAura, usePackedAura);
    end
end

local function MyUpdateBuffs(frame, unit, unitAuraUpdateInfo, auraSettings)
    local previousUnit = frame.myPreviousunit;
    frame.myPreviousunit = unit;
    local aurasChanged = false;

    if UnitIsUnit(unit, "player") and auraSettings.showFriendlyBuffs then
        -- it is personalFriendlyBuffFrame replace with debuffs
        frame.filter = AuraUtil.AuraFilters.Harmful;
    else

    if not unitAuraUpdateInfo or unitAuraUpdateInfo.isFullUpdate or unit ~= previousUnit or frame.auras == nil then
        MyParseAllAuras(frame, auraSettings.showAll);
        aurasChanged = true;
    else
        if not unitAuraUpdateInfo.addedAuras then
            for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
                if MyShouldShowBuff(frame, aura, auraSettings.showAll) then
                    frame.auras[aura.auraInstanceID] = aura;
                    aurasChanged = true;
                end
            end
        end

        if not unitAuraUpdateInfo.updatedAuraInstanceIDs then
            for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
                if not frame.auras[auraInstanceID] then
                    local newAura = C_UnitAuras.GetAuraDataByAuraInstanceID(frame.unit, auraInstanceID);
                    frame.auras[auraInstanceID] = newAura;
                    aurasChanged = true;
                end
            end
        end

        if not unitAuraUpdateInfo.removedAuraInstanceIDs then
            for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
                if not frame.auras[auraInstanceID] then
                    frame.auras[auraInstanceID] = nil;
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
    frame.auras:Iterate(function(auraInstanceID, aura)
        local buff = frame.buffPool:Acquire();
        buff.auraInstanceID = auraInstanceID;
        buff.isBuff = aura.isHelpful;
        buff.layoutIndex = buffIndex;
        buff.spellID = aura.spellId;

        buff.Icon:SetTexture(aura.icon);
        if aura.applications > 1 then
            buff.CountFrame.Count:SetText(aura.applications);
            buff.CountFrame.Count:Show();
        else
            buff.CountFrame.Count:Hide();
        end
        buff.Cooldown:SetEdgeTexture("Interface\\Cooldown\\edge");
        if aura.isHelpful and not aura.castByPlayer then
            if aura.isStealable then
                buff.Cooldown:SetSwipeColor(0, 0, 1);
            else
                buff.Cooldown:SetSwipeColor(1, 0, 0);
            end
        else
            buff.Cooldown:SetSwipeColor(0, 0, 0);
        end
        CooldownFrame_Set(buff.Cooldown, aura.expirationTime - aura.duration, aura.duration, aura.duration > 0, true);

        buff:Show();

        buffIndex = buffIndex + 1;
        return buffIndex >= BUFF_MAX_DISPLAY;
    end);

    frame:Layout();
end

hooksecurefunc(_G.BaseNamePlateUnitFrameTemplate.BuffFrame, "SetActive", function(...)
    print("_G.BaseNamePlateUnitFrameTemplate.BuffFrame.SetActive => false")
    self.isActive = false;
end);

hooksecurefunc(_G.BaseNamePlateUnitFrameTemplate.BuffFrame, "UpdateBuffs", function(...)
    print("_G.BaseNamePlateUnitFrameTemplate.BuffFrame.UpdateBuffs => MyUpdateBuffs")
    MyUpdateBuffs(...);
end);

hooksecurefunc(_G.PersonalFriendlyBuffFrame, "SetActive", function(...)
    print("_G.PersonalFriendlyBuffFrame.SetActive => false")
    self.isActive = false;
end);

hooksecurefunc(_G.PersonalFriendlyBuffFrame, "UpdateBuffs", function(...)
    print("_G.PersonalFriendlyBuffFrame.UpdateBuffs => MyUpdateBuffs")
    MyUpdateBuffs(...);
end);