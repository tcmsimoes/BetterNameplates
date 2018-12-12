NameplatePlayerDebuffContainerMixin = {};

function NameplatePlayerDebuffContainerMixin:OnLoad()
    local _, myclass = UnitClass("player");

    if myclass == "PALADIN" then
        self:SetParent(ClassNameplateBarPaladinFrame);
    elseif myclass == "ROGUE" or class == "DRUID" then
        self:SetParent(ClassNameplateBarComboPointFrame);
    elseif myclass == "DEATHKNIGHT" then
        self:SetParent(DeathKnightResourceOverlayFrame);
    elseif myclass == "MAGE" then
        self:SetParent(ClassNameplateBarMageFrame);
    elseif myclass == "WARLOCK" then
        self:SetParent(ClassNameplateBarShardFrame);
    elseif myclass == "MONK" then
        self:SetParent(ClassNameplateBarChiFrame);
    else
        self:SetParent(ClassNameplateManaBarFrame);
    end

    self:ClearAllPoints();
    self:SetPoint("TOPLEFT", self:GetParent(), "BOTTOMLEFT", 0, 0);

    self.buffList = {};
    self.BuffFrameUpdateTime = 0;
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

    local PLAYER_DEBUFF_MAX_DISPLAY = 8;
    local buffIndex = 1;
    for i = 1, PLAYER_DEBUFF_MAX_DISPLAY do
        local name, texture, count, debuffType, duration, expirationTime, caster, _, _, spellId, _, isBossDebuff, _, _ = UnitAura(self.unit, i, self.filter);

        if (name) then
            if (not self.buffList[buffIndex]) then
                self.buffList[buffIndex] = CreateFrame("Frame", self:GetParent():GetName() .. "PlayerDebuff" .. buffIndex, self, "NameplateBuffButtonTemplate");
                self.buffList[buffIndex]:SetMouseClickEnabled(false);
                self.buffList[buffIndex].layoutIndex = buffIndex;
            end
            local buff = self.buffList[buffIndex];
            buff:SetID(i);
            buff.Icon:SetTexture(texture);
            if (isBossDebuff) then
                if (not buff.hasBackdrop) then
                    buff:SetBackdrop({
                        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                        insets = {top = -1, bottom = -1, left = -1, right = -1}
                    });
                    buff.hasBackdrop = true;
                end
                buff:SetBackdropColor(1.0, 0.0, 0.0, 0.4);
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

    for i = buffIndex, PLAYER_DEBUFF_MAX_DISPLAY do
        if (self.buffList[i]) then
            self.buffList[i]:Hide();
        end
    end
end