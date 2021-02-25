local visibleSpells = {
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
    ["Unholy Strength"] = true,
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
---- fury
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

function UpdatePlayerBuffs(nameplate, unit)
    local buffFrame = nameplate.UnitFrame.BuffFrame;

    if (not buffFrame.isActive) then
        return;
    end

    buffFrame.filter = "HELPFUL";

    local PLAYER_BUFF_MAX_DISPLAY = 8;
    local buffsPresentCount = 0;
    local buffsPresent = {};
    for i = 1, PLAYER_BUFF_MAX_DISPLAY do
        local buff = buffFrame.buffList[i];
        if (buff) then
            if (buff.border) then
                buff.border:Hide();
            end
            if (buff:IsShown()) then
                buffsPresent[buff:GetID()] = true;
                buffsPresentCount = buffsPresentCount + 1;
            end
        end
    end

    local filteredSpells = {};
    for i = 1, 40 do
        local name, texture, count, _, duration, expirationTime, caster, _, _, spellId, _, _, _, _ = UnitAura(unit, i, buffFrame.filter);

        if (not spellId) then
            break;
        end

        if (visibleSpells[name] and not buffsPresent[i]) then
            filteredSpells[i] = {["name"] = name,
                                 ["texture"] = texture,
                                 ["count"] = count,
                                 ["duration"] = duration,
                                 ["expirationTime"] = expirationTime,
                                 ["caster"] = caster,
                                 ["spellId"] = spellId};
        end
    end

    local buffIndex = buffsPresentCount + 1;
    for i, spell in pairs(filteredSpells) do
        if (buffIndex > PLAYER_BUFF_MAX_DISPLAY) then
            break;
        end

        if (spell.name) then
            if (not buffFrame.buffList[buffIndex]) then
                buffFrame.buffList[buffIndex] = CreateFrame("Frame", nil, buffFrame, "NameplateBuffButtonTemplate");
                buffFrame.buffList[buffIndex]:SetMouseClickEnabled(false);
                buffFrame.buffList[buffIndex].layoutIndex = buffIndex;
            end
            local buff = buffFrame.buffList[buffIndex];
            buff:SetID(i);
            buff.Icon:SetTexture(spell.texture);
            if (spell.count > 1) then
                buff.CountFrame.Count:SetText(spell.count);
                buff.CountFrame.Count:Show();
            else
                buff.CountFrame.Count:Hide();
            end

            CooldownFrame_Set(buff.Cooldown, spell.expirationTime - spell.duration, spell.duration, spell.duration > 0, true);

            buff:Show();
            buffIndex = buffIndex + 1;
        end
    end

    for i = buffIndex, PLAYER_BUFF_MAX_DISPLAY do
        if (buffFrame.buffList[i]) then
            buffFrame.buffList[i]:Hide();
        end
    end
    buffFrame:Layout();
end

function UpdateEnemyBuffs(nameplate, unit)
    local buffFrame = nameplate.UnitFrame.BuffFrame;

    if (not buffFrame.isActive) then
        return;
    end

    buffFrame.filter = "HELPFUL";

    local ENEMY_BUFF_MAX_DISPLAY = 4;
    local buffsPresentCount = 0;
    local buffsPresent = {};
    for i = 1, BUFF_MAX_DISPLAY do
        local buff = buffFrame.buffList[i];
        if (buff) then
            if (buff.border) then
                buff.border:Hide();
            end
            if (buff:IsShown()) then
                buffsPresent[buff:GetID()] = true;
                buffsPresentCount = buffsPresentCount + 1;
            end
        end
    end

    local buffIndex = buffsPresentCount + 1;
    for i = 1, ENEMY_BUFF_MAX_DISPLAY do
        local name, texture, count, _, duration, expirationTime, caster, isStealable, _, spellId, _, _, _, _ = UnitAura(unit, i, buffFrame.filter);

        if (name) then
            if (not buffFrame.buffList[buffIndex]) then
                buffFrame.buffList[buffIndex] = CreateFrame("Frame", nil, buffFrame, "NameplateBuffButtonTemplate");
                buffFrame.buffList[buffIndex]:SetMouseClickEnabled(false);
                buffFrame.buffList[buffIndex].layoutIndex = buffIndex;
            end
            local buff = buffFrame.buffList[buffIndex];
            buff:SetID(i);
            buff.Icon:SetTexture(texture);
            if (not buff.border) then
                buff.border = CreateFrame("Frame", nil, buff, "BackdropTemplate");
                buff.border:SetAllPoints(buff);
                buff.border:SetBackdrop({
                    edgeFile = [[Interface/Buttons/WHITE8X8]], 
                    edgeSize = 1, 
                });
            end
            buff.border:Show();
            if (count > 1) then
                buff.CountFrame.Count:SetText(count);
                buff.CountFrame.Count:Show();
            else
                buff.CountFrame.Count:Hide();
            end
            if (isStealable) then
                buff.border:SetBackdropBorderColor(0.0, 0.0, 1.0, 0.7);
            else
                buff.border:SetBackdropBorderColor(1.0, 0.0, 0.0, 0.7);
            end

            CooldownFrame_Set(buff.Cooldown, expirationTime - duration, duration, duration > 0, true);

            buff:Show();
            buffIndex = buffIndex + 1;
        end
    end

    for i = buffIndex, ENEMY_BUFF_MAX_DISPLAY do
        if (buffFrame.buffList[i]) then
            buffFrame.buffList[i]:Hide();
        end
    end
    buffFrame:Layout();
end

local inBattleground = false;

hooksecurefunc(_G.NamePlateDriverFrame, "OnUnitAuraUpdate", function(self, unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit, issecure());
    if (nameplate and UnitIsUnit(unit, "player")) then
        UpdatePlayerBuffs(nameplate, unit);
    elseif (nameplate and not inBattleground) then
        UpdateEnemyBuffs(nameplate, unit);
    end
end);

local myFrame = CreateFrame("Frame");
myFrame:RegisterEvent("PLAYER_ENTERING_WORLD");