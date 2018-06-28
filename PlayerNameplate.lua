local function SetupPlayerNamePlate(frame, setupOptions, frameOptions)
    if not frameOptions.displayName then
        frame.healthBar:SetHeight(12)

        frameOptions.healthBarColorOverride = nil
        frameOptions.useClassColors = true
    end
end

hooksecurefunc("DefaultCompactNamePlateFrameSetupInternal", SetupPlayerNamePlate)