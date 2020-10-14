NameplatePlayerDebuffContainerMixin = {};

function NameplatePlayerDebuffContainerMixin:Setup()
    local _, class = UnitClass("player");
    
    local xOffset, yOffset = -1, -3;

    if (class == "DEATHKNIGHT") then
        yOffset = -23;
    elseif (class == "PALADIN") then
        yOffset = -23;
    elseif (class == "WARLOCK") then
        yOffset = -23;
    elseif (class == "ROGUE") then
        yOffset = -16;
    elseif (class == "HUNTER") then
        self:createPetHealthBar();
        yOffset = -8;
    elseif (class == "DRUID") then
        local shape = GetShapeshiftForm();

        if (shape == 2) then
            yOffset = -16;
        end

        self:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
    elseif (class == "MONK") then
        local myspec = GetSpecialization();

        if (myspec == 3) then
            yOffset = -16;
        elseif (myspec == 1) then
            yOffset = -10;
        end

        self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
    end

    self:SetParent(ClassNameplateManaBarFrame);
    self:UpdateAnchors(xOffset, yOffset);
end

function NameplatePlayerDebuffContainerMixin:UpdateAnchors(xOffset, yOffset)
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
    elseif (event == "UPDATE_SHAPESHIFT_FORM") then
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
        local name, texture, count, debuffType, duration, expirationTime, caster, isStealable, _, spellId, _, isBossDebuff, _, _ = UnitAura(self.unit, i, self.filter);

        if (name) then
            if (not self.buffList[buffIndex]) then
                self.buffList[buffIndex] = CreateFrame("Frame", nil, self, "NameplateBuffButtonTemplate");
                self.buffList[buffIndex]:SetMouseClickEnabled(false);
                self.buffList[buffIndex].layoutIndex = buffIndex;
            end
            local buff = self.buffList[buffIndex];
            buff:SetID(i);
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

    for i = buffIndex, PLAYER_DEBUFF_MAX_DISPLAY do
        if (self.buffList[i]) then
            self.buffList[i]:Hide();
        end
    end
end

function NameplatePlayerDebuffContainerMixin:createPetHealthBar()
    if (self.petHealBar) then
        return;
    end

    local bar = CreateFrame('StatusBar', nil, self);
    bar:SetPoint("TOPLEFT", ClassNameplateManaBarFrame, "BOTTOMLEFT", 0, 0);
    bar:SetSize(self:GetWidth(), 4);
    bar:SetStatusBarTexture([[Interface\TargetingFrame\UI-TargetingFrame-BarFill]]);
    bar:SetStatusBarColor(0.6, 1.0, 0.8);
    bar:SetOrientation('HORIZONTAL');
    bar:SetMovable(false);
    bar:EnableMouse(false);
    bar.unit = "pet";

    bar.border = CreateFrame("Frame", nil, bar, "BackdropTemplate");
    bar.border:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1);
    bar.border:SetSize(bar:GetWidth(), bar:GetHeight() + 2);
    bar.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeSize = 1
    });
    bar.border:SetBackdropBorderColor(0, 0, 0, 1.0);

    bar:SetScript('OnEvent', function(self, event, ...)
        if event == 'UNIT_MAXHEALTH' then
            self:SetMinMaxValues(0, UnitHealthMax(self.unit));
        elseif event == 'UNIT_HEALTH' or event == 'UNIT_HEALTH_FREQUENT' then
            self:SetValue(UnitHealth(self.unit));
        elseif event == 'UNIT_PET' or event == 'PLAYER_ENTERING_WORLD' then
            self:SetMinMaxValues(0, UnitHealthMax(self.unit));
            self:SetValue(UnitHealth(self.unit));
        end
    end)

    bar:RegisterUnitEvent('UNIT_MAXHEALTH', bar.unit);
    bar:RegisterUnitEvent('UNIT_HEALTH', bar.unit);
    bar:RegisterEvent('UNIT_PET');
    bar:RegisterEvent('PLAYER_ENTERING_WORLD');

    self.petHealBar = bar;
end