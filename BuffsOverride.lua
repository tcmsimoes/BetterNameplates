local visibleSpells = {
-- other classes
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
-- dk
    ["Unholy Strength"] = true,
    ["Anti-Magic Shell"] = true,
    ["Icebound Fortitude"] = true,
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
-- warrior
    ["Victorious"] = true,
---- fury
    ["Enrage"] = true,
    ["Juggernaut"] = true,
    ["Battle Cry"] = true,
---- arms
    ["Shattered Defenses"] = true,
    ["Weighted Blade"] = true,
    ["Executioner's Precision"] = true,
};

function UpdatePlayerBuffs(nameplate, unit)
    local buffFrame = nameplate.UnitFrame.BuffFrame;

    if (not buffFrame.isActive) then
        return;
    end

    local buffMaxDisplay = 32;
    local buffsPresentCount = 0;
    local buffsPresent = {};
    for i = 1, buffMaxDisplay do
        if (buffFrame.buffList[i]) and buffFrame.buffList[i]:IsShown() then
            buffsPresent[buffFrame.buffList[i]:GetID()] = true;
            buffsPresentCount = buffsPresentCount + 1;
        end
    end

    local filteredSpells = {};
    for i = 1, 40 do
        local name, _, texture, count, _, duration, expirationTime, caster, _, _, spellId, _, _, _, _ = UnitAura(unit, i, "HELPFUL");

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
        if (buffIndex > buffMaxDisplay) then
            break;
        end

        if (spell.name) then
            if (not buffFrame.buffList[buffIndex]) then
                buffFrame.buffList[buffIndex] = CreateFrame("Frame", buffFrame:GetParent():GetName() .. "Buff" .. buffIndex, buffFrame, "NameplateBuffButtonTemplate");
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

    for i = buffIndex, buffMaxDisplay do
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

    local buffMaxDisplay = 32;
    local buffsPresentCount = 0;
    local buffsPresent = {};
    for i = 1, buffMaxDisplay do
        local buff = buffFrame.buffList[i];
        if (buff and buff:IsShown()) then
            buff:SetBackdropColor(0.0, 0.0, 0.0, 0.0);
            buff:SetScale(1.0);
            buffsPresent[buff:GetID()] = true;
            buffsPresentCount = buffsPresentCount + 1;
        end
    end

    local buffIndex = buffsPresentCount + 1;
    for i = 1, buffMaxDisplay do
        local name, _, texture, count, _, duration, expirationTime, caster, _, _, spellId, _, _, _, _ = UnitAura(unit, i, "HELPFUL");

        if (name) then
            if (not buffFrame.buffList[buffIndex]) then
                buffFrame.buffList[buffIndex] = CreateFrame("Frame", buffFrame:GetParent():GetName() .. "Buff" .. buffIndex, buffFrame, "NameplateBuffButtonTemplate");
                buffFrame.buffList[buffIndex]:SetMouseClickEnabled(false);
                buffFrame.buffList[buffIndex].layoutIndex = buffIndex;
                buffFrame.buffList[buffIndex]:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    insets = {top = -1, bottom = -1, left = -1, right = -1}
                });
            end
            local buff = buffFrame.buffList[buffIndex];
            buff:SetID(i);
            buff.Icon:SetTexture(texture);
            buff:SetBackdropColor(1.0, 0.0, 0.0, 0.3);
            buff:SetScale(1.125);
            if (count > 1) then
                buff.CountFrame.Count:SetText(count);
                buff.CountFrame.Count:Show();
            else
                buff.CountFrame.Count:Hide();
            end

            CooldownFrame_Set(buff.Cooldown, expirationTime - duration, duration, duration > 0, true);

            buff:Show();
            buffIndex = buffIndex + 1;
        end
    end

    buffFrame:Layout();
end

hooksecurefunc(NamePlateDriverFrame, "OnUnitAuraUpdate", function(self, unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit, issecure());
    if (nameplate and UnitIsUnit("player", unit)) then
        UpdatePlayerBuffs(nameplate, unit);
    elseif (nameplate) then
        UpdateEnemyBuffs(nameplate, unit);
    end
end)
