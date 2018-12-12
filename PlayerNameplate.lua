hooksecurefunc("DefaultCompactNamePlateFrameSetupInternal", function(frame, setupOptions, frameOptions)
    if not frameOptions.displayName then
        setupOptions.healthBarHeight = 14;
        frameOptions.healthBarColorOverride = nil;
        frameOptions.useClassColors = true;

        DefaultCompactNamePlateFrameAnchorInternal(frame, setupOptions);
    end
end);