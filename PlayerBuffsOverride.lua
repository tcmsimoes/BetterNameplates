local visibleSpells = {
-- other classes
    ["Pain Suppression"] = true,
    ["Guardian Spirit"] = true,
    ["Ironbark"] = true,
    ["Life Cocoon"] = true,
    ["Blessing of Sacrifice"] = true,
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
    ["Unholy Strength"] = true
};

function UpdatePlayerBuffs(nameplate, unit)
    local buffFrame = nameplate.UnitFrame.BuffFrame;

    if not buffFrame.isActive then
        for i = 1, BUFF_MAX_DISPLAY do
            if (buffFrame.buffList[i]) then
                buffFrame.buffList[i]:Hide();
            end
        end

        return;
    end

    buffFrame.unit = unit;
    buffFrame:UpdateAnchor();

    local buffIndex = 1;

    for spell in pairs(visibleSpells) do
        if (buffIndex > 4) then
            break;
        end

        local name, texture, count, _, duration, expirationTime, caster, _, _, spellId, _, _, _, _ = UnitAura(unit, spell);
        if (name) then
            if (not buffFrame.buffList[buffIndex]) then
                buffFrame.buffList[buffIndex] = CreateFrame("Frame", buffFrame:GetParent():GetName() .. "Buff" .. buffIndex, buffFrame, "NameplateBuffButtonTemplate");
                buffFrame.buffList[buffIndex]:SetMouseClickEnabled(false);
                buffFrame.buffList[buffIndex].layoutIndex = buffIndex;
            end
            local buff = buffFrame.buffList[buffIndex];
            buff:SetID(buffIndex);
            buff.Icon:SetTexture(texture);
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

    for i = buffIndex, BUFF_MAX_DISPLAY do
        if (buffFrame.buffList[i]) then
            buffFrame.buffList[i]:Hide();
        end
    end
    buffFrame:Layout();
end


hooksecurefunc(NamePlateDriverFrame, "OnUnitAuraUpdate", function(self, unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit, issecure());
    if ((nameplate) and UnitIsUnit("player", unit)) then
        local _, _, class = UnitClass(unit);
        if (class == 6) then
            UpdatePlayerBuffs(nameplate, unit);
        end
    end
end)
