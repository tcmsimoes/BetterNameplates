COMBATFEEDBACK_FADEINTIME = 0
COMBATFEEDBACK_HOLDTIME = 0
COMBATFEEDBACK_FADEOUTTIME = 0

local function MySetupPlayerNameplate(unit)
    local namePlate = C_NamePlate.GetNamePlateForUnit(unit, issecure())
    if namePlate and namePlate.UnitFrame and namePlate.UnitFrame.healthBar then
        PixelUtil.SetHeight(namePlate.UnitFrame.healthBar, 10)
        namePlate.UnitFrame:SetScale(1.1)

        -- workaround for the mysterious disapearing of healthbar
        namePlate.UnitFrame.hideHealthbar = false;
        namePlate.UnitFrame.healthBar:SetShown(true);
        namePlate.UnitFrame.healthBar:Show()
        namePlate.UnitFrame:Show()
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
        C_CVar.SetCVar("NamePlateVerticalScale", 1.1)
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