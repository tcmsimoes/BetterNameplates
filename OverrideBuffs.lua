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

function UpdateBuffs(buffFrame, activeBuffs, maxDisplayBuffs)
    local buffIndex = 1;
    for _, activeBuff in ipairs(activeBuffs) do
        if (not buffFrame.buffList[buffIndex]) then
            buffFrame.buffList[buffIndex] = CreateFrame("Frame", nil, buffFrame, "NameplateBuffButtonTemplate");
            buffFrame.buffList[buffIndex]:SetMouseClickEnabled(false);
            buffFrame.buffList[buffIndex].layoutIndex = buffIndex;
        end
        local buff = buffFrame.buffList[buffIndex];
        buff:SetID(activeBuff.index);
        buff.name = activeBuff.name;
        buff.filter = activeBuff.filter;
        buff.Icon:SetTexture(activeBuff.icon);
        if (activeBuff.count > 1) then
            buff.CountFrame.Count:SetText(activeBuff.count);
            buff.CountFrame.Count:Show();
        else
            buff.CountFrame.Count:Hide();
        end
        if (not buff.border) then
            buff.border = CreateFrame("Frame", nil, buff, "BackdropTemplate");
            buff.border:SetAllPoints(buff);
            buff.border:SetBackdrop({
                edgeFile = [[Interface/Buttons/WHITE8X8]], 
                edgeSize = 1, 
            });
        end
        buff.border:Hide();
        if (activeBuff.isBuff and not activeBuff.castByPlayer) then
            if (activeBuff.isStealable) then
                buff.border:SetBackdropBorderColor(0.0, 0.0, 1.0, 0.7);
            elseif (not activeBuff.castByPlayer) then
                buff.border:SetBackdropBorderColor(1.0, 0.0, 0.0, 0.7);
            end

            buff.border:Show();
        end

        CooldownFrame_Set(buff.Cooldown, activeBuff.expirationTime - activeBuff.duration, activeBuff.duration, activeBuff.duration > 0, true);

        if (not buff.isTooltipOverrided) then
            hooksecurefunc(buff, 'OnEnter', function(self, ...)
                NamePlateTooltip:SetUnitAura(self:GetParent().unit, self:GetID(), self.filter);
            end);

            buff.isTooltipOverrided = true;
        end

        buff:Show();

        buffIndex = buffIndex + 1;
    end

    for i = buffIndex, maxDisplayBuffs do
        local buff = buffFrame.buffList[i];
        if (buff) then
            buff:Hide();
            if (buff.border) then
                buff.border:Hide();
            end
        else
            break;
        end
    end
    buffFrame:Layout();
end

function UpdatePlayerBuffs(buffFrame, unit, isFullUpdate, updatedAuraInfos)
    if (not buffFrame:IsVisible() or not unit) then
        return;
    end

    if (AuraUtil.ShouldSkipAuraUpdate(isFullUpdate, updatedAuraInfos, function(auraInfo, ...)
        return auraInfo.isHelpful;
    end)) then
        return;
    end

    buffFrame.isActive = false;
    buffFrame.filter = "HELPFUL";

    local activeBuffs = {};
    local index = 1;
    AuraUtil.ForEachAura(unit, buffFrame.filter, nil, function(...)
        local name, icon, count, dispelType, duration, expirationTime, caster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossAura, castByPlayer, nameplateShowAll = ...;

        if (visibilePlayerBuffs[name] or buffFrame:ShouldShowBuff(name, caster, nameplateShowPersonal, nameplateShowAll)) then
            table.insert(activeBuffs, {
                ["spellId"] = spellId,
                ["name"] = name,
                ["icon"] = icon,
                ["count"] = count,
                ["dispelType"] = dispelType,
                ["duration"] = duration,
                ["expirationTime"] = expirationTime,
                ["caster"] = caster,
                ["isStealable"] = isStealable,
                ["isBossAura"] = isBossAura,
                ["castByPlayer"] = castByPlayer,
                ["filter"] = buffFrame.filter,
                ["isBuff"] = true,
                ["index"] = index
            });
        end

        index = index + 1;
    end);

    local PLAYER_BUFF_MAX_DISPLAY = 8;

    UpdateBuffs(buffFrame, activeBuffs, PLAYER_BUFF_MAX_DISPLAY);
end

function UpdateEnemyBuffs(buffFrame, unit, isFullUpdate, updatedAuraInfos)
    if (not buffFrame:IsVisible() or not unit) then
        return;
    end

    if (AuraUtil.ShouldSkipAuraUpdate(isFullUpdate, updatedAuraInfos, function(auraInfo, ...)
        if (auraInfo.isHarmful) then
            if (buffFrame:ShouldShowBuff(auraInfo.name, auraInfo.sourceUnit, auraInfo.nameplateShowPersonal, auraInfo.nameplateShowAll)) then
                return true;
            end
        elseif (auraInfo.isHelpful) then
            return true;
        end

        return false;
    end)) then
        return;
    end

    buffFrame.isActive = false;
    buffFrame.filter = "HELPFUL";

    local activeBuffs = {};
    local filter = "HARMFULL|INCLUDE_NAME_PLATE_ONLY";
    local index = 1;
    AuraUtil.ForEachAura(unit, filter, nil, function(...)
        local name, icon, count, dispelType, duration, expirationTime, caster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossAura, castByPlayer, nameplateShowAll = ...;

        if (buffFrame:ShouldShowBuff(name, caster, nameplateShowPersonal, nameplateShowAll)) then
            table.insert(activeBuffs, {
                ["spellId"] = spellId,
                ["name"] = name,
                ["icon"] = icon,
                ["count"] = count,
                ["dispelType"] = dispelType,
                ["duration"] = duration,
                ["expirationTime"] = expirationTime,
                ["caster"] = caster,
                ["isStealable"] = isStealable,
                ["isBossAura"] = isBossAura,
                ["castByPlayer"] = castByPlayer,
                ["filter"] = filter,
                ["isBuff"] = false,
                ["index"] = index
            });
        end

        index = index + 1;
    end);

    filter = "HELPFUL";
    index = 1;
    AuraUtil.ForEachAura(unit, filter, nil, function(...)
        local name, icon, count, dispelType, duration, expirationTime, caster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossAura, castByPlayer, nameplateShowAll = ...;

        table.insert(activeBuffs, {
            ["spellId"] = spellId,
            ["name"] = name,
            ["icon"] = icon,
            ["count"] = count,
            ["dispelType"] = dispelType,
            ["duration"] = duration,
            ["expirationTime"] = expirationTime,
            ["caster"] = caster,
            ["isStealable"] = isStealable,
            ["isBossAura"] = isBossAura,
            ["castByPlayer"] = castByPlayer,
            ["filter"] = filter,
            ["isBuff"] = true,
            ["index"] = index
        });

        index = index + 1;
    end);

    local ENEMY_BUFF_MAX_DISPLAY = 6;

    UpdateBuffs(buffFrame, activeBuffs, ENEMY_BUFF_MAX_DISPLAY);
end


hooksecurefunc(_G.NamePlateDriverFrame, "OnUnitAuraUpdate", function(self, unit, ...)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit, issecure());
    if (nameplate and UnitIsUnit("player", unit)) then
        UpdatePlayerBuffs(nameplate.UnitFrame.BuffFrame, nameplate.namePlateUnitToken, ...);
    elseif (nameplate and not UnitIsPlayer(unit)) then
        UpdateEnemyBuffs(nameplate.UnitFrame.BuffFrame, nameplate.namePlateUnitToken, ...);
    end
end);