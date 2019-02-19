NameplatePlayerDebuffContainerMixin = {};

function NameplatePlayerDebuffContainerMixin:Setup()
    local _, myclass = UnitClass("player");
    local myspec = GetSpecialization();
    local xOffset, yOffset = -1, -5;

    if (myclass == "DEATHKNIGHT") then
        yOffset = -23;
    elseif (myclass == "PALADIN") then
        yOffset = -23;
    elseif (myclass == "WARLOCK") then
        yOffset = -23;
    elseif (myclass == "ROGUE") then
        yOffset = -16;
    elseif (class == "DRUID") then
        if (myspec == 2) then
            yOffset = -16;
        else
            yOffset = -5;
        end
        
        self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
    elseif (myclass == "MONK") then
        if (myspec == SPEC_MONK_WINDWALKER) then
            yOffset = -16;
        elseif (myspec == SPEC_MONK_BREWMASTER) then
            yOffset = -10;
        else
            yOffset = -5;
        end

        self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
    end

    self:SetParent(ClassNameplateManaBarFrame);
    self:ClearAllPoints();
    self:SetPoint("TOPLEFT", self:GetParent(), "BOTTOMLEFT", xOffset, yOffset);
end

function NameplatePlayerDebuffContainerMixin:OnLoad()
    self:Setup();

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
    elseif (event == "PLAYER_SPECIALIZATION_CHANGED") then
        self:Setup();
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