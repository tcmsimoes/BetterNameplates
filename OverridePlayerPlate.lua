local previousNameplate = nil

local function MySetupPlayerNameplate(unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if nameplate and nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
        if previousNameplate and previousNameplate.UnitFrame and previousNameplate.UnitFrame.healthBar.defaultHeight then
            PixelUtil.SetHeight(previousNameplate.UnitFrame.healthBar, previousNameplate.UnitFrame.healthBar.defaultHeight)
            previousNameplate.UnitFrame.healthBar.defaultHeight = nil
        end
        previousNameplate = nameplate
        previousNameplate.UnitFrame.healthBar.defaultHeight = nameplate.UnitFrame.healthBar:GetHeight()
        PixelUtil.SetHeight(nameplate.UnitFrame.healthBar, 10)
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
            MySetupPlayerNameplate(unit)
        end
    -- workaround for the mysterious disapearing of healthbar
    elseif string.find(event, "PLAYER_") then
        MySetupPlayerNameplate("player")
    end
end)