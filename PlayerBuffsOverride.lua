local visibleSpells = {
-- other classes
    ["Pain Suppression"] = true,
    ["Guardian Spirit"] = true,
    ["Ironbark"] = true,
    ["Life Cocoon"] = true,
    ["Blessing of Sacrifice"] = true,
    ["Commanding Shout"] = true,
-- dk blood
    ["Bone Shield"] = true,
    ["Anti-Magic Shell"] = true,
    ["Vampiric Blood"] = true,
    ["Icebound Fortitude"] = true,
    ["Dancing Rune Weapon"] = true,
    ["Rune Tap"] = true,
    ["Blood Mirror"] = true,
    ["Bonestorm"] = true,
    ["Vampiric Aura"] = true,
-- dk frost
    ["Pillar of Frost"] = true,
    ["Obliteration"] = true,
    ["Unholy Strength"] = true,
-- warrior fury
    ["Enrage"] = true,
    ["Juggernaut"] = true,
    ["Battle Cry"] = true,
-- warrior fury
    ["Shattered Defenses"] = true,
    ["Weighted Blade"] = true,
    ["Executioner's Precision"] = true
};

function UpdatePlayerBuffs(nameplate, unit)
    local buffFrame = nameplate.UnitFrame.BuffFrame;

    if not buffFrame.isActive then
        return;
    end

    local buffMaxDisplay = 4;
    local buffsPresentCount = 0;
    local buffsPresent = {};
    for i = 1, buffMaxDisplay do
        if (buffFrame.buffList[i]) and buffFrame.buffList[i]:IsShown() then
            buffsPresent[buffFrame.buffList[i]:GetID()] = true;
            buffsPresentCount = buffsPresentCount + 1;
        end
    end

    local buffsSlotAvailable = (buffMaxDisplay - buffsPresentCount);
    if buffsSlotAvailable <= 0 then
        return;
    end

    local filteredSpellsCount = 0;
    local filteredSpells = {};
    for i = 1, 40 do
        local name, _, texture, count, _, duration, expirationTime, caster, _, _, spellId, _, _, _, _ = UnitAura(unit, i, "HELPFUL");

        if not spellId then
            break;
        end

        if visibleSpells[name] and not buffsPresent[i] then
            filteredSpells[i] = {["name"] = name,
                                 ["texture"] = texture,
                                 ["count"] = count,
                                 ["duration"] = duration,
                                 ["expirationTime"] = expirationTime,
                                 ["caster"] = caster,
                                 ["spellId"] = spellId};

            filteredSpellsCount = filteredSpellsCount + 1;
        end

        if (filteredSpellsCount > buffsSlotAvailable) then
            break;
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


hooksecurefunc(NamePlateDriverFrame, "OnUnitAuraUpdate", function(self, unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit, issecure());
    if (nameplate and UnitIsUnit("player", unit)) then
        UpdatePlayerBuffs(nameplate, unit);
    end
end)
