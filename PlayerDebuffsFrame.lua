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

        if (UnitIsUnit("player", unit)) then
            self:UpdateBuffs(unit);
        end
    end
end

function NameplatePlayerDebuffContainerMixin:OnUpdate(elapsed)
    if (self.BuffFrameUpdateTime > 0) then
        self.BuffFrameUpdateTime = self.BuffFrameUpdateTime - elapsed;
    else
        self.BuffFrameUpdateTime = self.BuffFrameUpdateTime + TOOLTIP_UPDATE_TIME;
    end
end

function NameplatePlayerDebuffContainerMixin:UpdateBuffs(unit)
    self.unit = unit;
    self.filter = "HARMFUL";

    local buffIndex = 1;
    for i = 1, BUFF_MAX_DISPLAY do
        local name, _, texture, count, debuffType, duration, expirationTime, caster, _, _, spellId, _, isBossDebuff, _, _ = UnitAura(self.unit, i, self.filter);

        if (name) then
            if (not self.buffList[buffIndex]) then
                self.buffList[buffIndex] = CreateFrame("Frame", self:GetParent():GetName() .. "PlayerDebuff" .. buffIndex, self, "NameplateBuffButtonTemplate");
                self.buffList[buffIndex]:SetMouseClickEnabled(false);
                self.buffList[buffIndex].layoutIndex = buffIndex;
                self.buffList[buffIndex]:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    insets = {top = -1, bottom = -1, left = -1, right = -1}
                });
            end
            local buff = self.buffList[buffIndex];
            buff:SetID(i);
            buff.Icon:SetTexture(texture);
            if (isBossDebuff) then
                buff:SetBackdropColor(1.0, 0.0, 0.0, 0.3);
            else
                buff:SetBackdropColor(0.0, 0.0, 0.0, 0.0);
            end
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

    for i = buffIndex, BUFF_MAX_DISPLAY do
        if (self.buffList[i]) then
            self.buffList[i]:Hide();
        end
    end
end