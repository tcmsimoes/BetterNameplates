ClassNameplateBarHunter = {};

function ClassNameplateBarHunter:Setup()
    local showBar = false;

    if ( self:MatchesClass() ) then
        if ( self:MatchesSpec() ) then
            self:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "pet");
            self:RegisterUnitEvent("UNIT_MAXHEALTH", "pet");
            self:RegisterUnitEvent("UNIT_PET");
            self:RegisterEvent("PLAYER_ENTERING_WORLD");
            showBar = true;
        else
            self:UnregisterEvent("UNIT_HEALTH_FREQUENT");
            self:UnregisterEvent("UNIT_MAXHEALTH");
            self:UnregisterEvent("UNIT_PET");
            self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        end

        self:RegisterEvent("PLAYER_TALENT_UPDATE");
    end

    if (showBar) then
        self:ShowNameplateBar();
        self:UpdateMaxPower();
    else
        self:HideNameplateBar();
    end

    return showBar;
end

function ClassNameplateBarHunter:OnLoad()
    self.class = "HUNTER";
    self.powerToken = "PETHEALTH";
    self.overrideTargetMode = false;
    self.paddingOverride = 0;
    self.currValue = 0;
    self.Border:SetVertexColor(0, 0, 0, 1);
    self.Border:SetBorderSizes(nil, nil, 0, 0);
    self:SetStatusBarColor(0.6, 1.0, 0.8);

    ClassNameplateBar.OnLoad(self);
end

function ClassNameplateBarHunter:OnEvent(event, ...)
    if ( event == "UNIT_HEALTH_FREQUENT" ) then
        local unitTag, powerToken = ...;
        if (unitTag == "pet" and self.powerToken == powerToken ) then
            self:UpdatePower();
            return true;
        end
    elseif ( event == "UNIT_MAXHEALTH" ) then
        local unitTag = ...;
        if (unitTag == "pet") then
            self:UpdateMaxPower();
            return true;
        end
    elseif ( event == "UNIT_PET" or event == "PLAYER_ENTERING_WORLD" ) then
        self:Setup();
        self:UpdatePower();
        return true;
    elseif (event == "PLAYER_TALENT_UPDATE" ) then
        self:Setup();
        self:UpdatePower();
        return true;
    end
    return false;
end

function ClassNameplateBarHunter:UpdateMaxPower()
    local maxhealth = UnitHealthMax("pet");
    self:SetMinMaxValues(0, maxhealth);
end

function ClassNameplateBarHunter:OnUpdate()
    self:UpdatePower();
end

function ClassNameplateBarHunter:UpdatePower()
    self:SetValue(UnitHealth("pet"));
    self:UpdateMaxPower();
end

function ClassNameplateBarHunter:OnOptionsUpdated()
    self:OnSizeChanged();
end

function ClassNameplateBarHunter:OnSizeChanged() -- override
    PixelUtil.SetHeight(self, DefaultCompactNamePlatePlayerFrameSetUpOptions.healthBarHeight);
    self.Border:UpdateSizes();
end