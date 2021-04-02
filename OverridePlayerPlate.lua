local myFrame = CreateFrame("frame")
myFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
myFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
myFrame:SetScript("OnEvent", function(self, event, unit)
    if UnitIsUnit("player", unit) then
        local namePlate = C_NamePlate.GetNamePlateForUnit(unit, issecure())
        if namePlate and namePlate.UnitFrame and namePlate.UnitFrame.healthBar:GetHeight() < 15 then
            PixelUtil.SetHeight(namePlate.UnitFrame.healthBar, namePlate.UnitFrame.healthBar:GetHeight() + 10)
        end
    end
end)