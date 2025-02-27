local previousNameplate = nil
local function MySetupPlayerNameplate()
	local nameplate = C_NamePlate.GetNamePlateForUnit("player");
	if nameplate and nameplate.UnitFrame and nameplate.UnitFrame.HealthBarsContainer then
        if previousNameplate and previousNameplate.UnitFrame and previousNameplate.UnitFrame.HealthBarsContainer.defaultHeight then
            PixelUtil.SetHeight(previousNameplate.UnitFrame.HealthBarsContainer, previousNameplate.UnitFrame.HealthBarsContainer.defaultHeight)
            previousNameplate.UnitFrame.HealthBarsContainer.defaultHeight = nil
            previousNameplate.UnitFrame:SetFrameLevel(nameplate.UnitFrame:GetFrameLevel())
            previousNameplate.UnitFrame:SetFrameStrata(nameplate.UnitFrame:GetFrameStrata())
        end
        previousNameplate = nameplate
        previousNameplate.UnitFrame.HealthBarsContainer.defaultHeight = nameplate.UnitFrame.HealthBarsContainer:GetHeight()
        PixelUtil.SetHeight(nameplate.UnitFrame.HealthBarsContainer, 10)
        nameplate.UnitFrame.HealthBarsContainer.border:UpdateSizes();
        nameplate.UnitFrame:SetFrameLevel(129)
        nameplate.UnitFrame:SetFrameStrata(HIGH)
    end
end

local myFrame = CreateFrame("frame")
myFrame:RegisterEvent("VARIABLES_LOADED")
myFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
myFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
myFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
myFrame:RegisterEvent("PLAYER_UNGHOST")
myFrame:RegisterEvent("PLAYER_UNGHOST")
myFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "VARIABLES_LOADED" then
        C_CVar.SetCVar("nameplateSelectedScale", 1.3)
        C_CVar.SetCVar("NamePlateVerticalScale", 1.0)
        C_CVar.SetCVar("NameplatePersonalShowWithTarget", 1)
        C_CVar.SetCVar("nameplateHideHealthAndPower", 0)
        C_CVar.SetCVar("namePlateSelfScale", 1.0)
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if UnitIsUnit("player", unit) then
            MySetupPlayerNameplate()
        end
    -- workaround for the mysterious disapearing of HealthBarsContainer
    elseif string.find(event, "PLAYER_") then
        MySetupPlayerNameplate("player")
    end
end)