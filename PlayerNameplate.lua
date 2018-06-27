local function SetupPlayerNamePlate(frame, setupOptions, frameOptions)
    if frameOptions.displayName == false then -- UnitIsUnit(frame.displayedUnit, "player") doesnt work?!
        frame.healthBar:SetHeight(12)

        frame.optionTable.healthBarColorOverride = nil
        frame.optionTable.useClassColors = true
    end
end

hooksecurefunc("DefaultCompactNamePlateFrameSetupInternal", SetupPlayerNamePlate)