NameplatePlayerDebuffContainerMixin = {};

function NameplatePlayerDebuffContainerMixin:OnLoad()
    self.buffList = {};
    self.BuffFrameUpdateTime = 0;
    local _, _, class = UnitClass("player");
    if ((class == 6) or (class == 9)) then
        self:SetPoint("TOP", self:GetParent(), "BOTTOM", 0, 0);
    else
        self:SetPoint("TOP", self:GetParent(), "BOTTOM", 0, -4);
    end
    self:RegisterEvent("UNIT_AURA");
end

function NameplatePlayerDebuffContainerMixin:OnEvent(event, ...)
    if (event == "UNIT_AURA") then
        local unit = ...;
 
        if unit ~= "player" then
            return;
        end

        self:UpdateBuffs();
    end
end

function NameplatePlayerDebuffContainerMixin:OnUpdate(elapsed)
    if (self.BuffFrameUpdateTime > 0) then
        self.BuffFrameUpdateTime = self.BuffFrameUpdateTime - elapsed;
    else
        self.BuffFrameUpdateTime = self.BuffFrameUpdateTime + TOOLTIP_UPDATE_TIME;
    end
end

function NameplatePlayerDebuffContainerMixin:UpdateBuffs()
    local buffMaxDisplay = 4;
    local buffIndex = 1;

    for i = 1, buffMaxDisplay do
        local name, _, texture, count, debuffType, duration, expirationTime, caster, _, _, spellId, _, _, _, _ = UnitAura("player", i);--, "HARMFUL");

        if (name) then
            if (not self.buffList[buffIndex]) then
                self.buffList[buffIndex] = CreateFrame("Frame", "Frame_PlayerDebuff" .. buffIndex, self, "NameplateBuffButtonTemplate");
                self.buffList[buffIndex]:SetMouseClickEnabled(false);
                self.buffList[buffIndex].layoutIndex = buffIndex;
            end
            local buff = self.buffList[buffIndex];
            buff:SetID(i);
            buff.name = name;
            buff.Icon:SetTexture(texture);
            if (count > 1) then
                buff.CountFrame.Count:SetText(count);
                buff.CountFrame.Count:Show();
            else
                buff.CountFrame.Count:Hide();
            end

            CooldownFrame_Set(buff.Cooldown, expirationTime - duration, duration, duration > 0, true);

            buff:SetPoint("TOPLEFT", (i - 1) * 24, 0);
            buff:Show();
            buffIndex = buffIndex + 1;
        end
    end

    for i = buffIndex, buffMaxDisplay do
        if (self.buffList[i]) then
            self.buffList[i]:Hide();
        end
    end
end