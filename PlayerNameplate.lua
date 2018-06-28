local function SetupPlayerNamePlate(frame, setupOptions, frameOptions)
    if not frameOptions.displayName then
        frame.healthBar:SetHeight(12)
        frame.healthBar:SetStatusBarTexture("Interface\\AddOns\\BetterNameplates\\media\\bar_serenity")
    end
end

hooksecurefunc("DefaultCompactNamePlateFrameSetupInternal", SetupPlayerNamePlate)

local function UpdatePlayerNamePlateHealthColor(frame)
    if not frame.optionTable.displayName then
        local localizedClass, englishClass = UnitClass(frame.unit);
        local classColor = RAID_CLASS_COLORS[englishClass];
        r, g, b = classColor.r, classColor.g, classColor.b;
        frame.healthBar:SetStatusBarColor(r, g, b);
        frame.healthBar.r, frame.healthBar.g, frame.healthBar.b = r, g, b;
    end
end

hooksecurefunc("CompactUnitFrame_UpdateHealthColor", UpdatePlayerNamePlateHealthColor)