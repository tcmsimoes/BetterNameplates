hooksecurefunc("DefaultCompactNamePlateFrameAnchorInternal", function(frame, setupOptions)
    if setupOptions and frame.healthBar and not customOptions or not customOptions.ignoreBarSize then
        if setupOptions.healthBarAlpha == 1 then
            PixelUtil.SetHeight(frame.healthBar, setupOptions.healthBarHeight + 10);
        else
            PixelUtil.SetHeight(frame.healthBar, setupOptions.healthBarHeight);
        end

        frame.healthBar.border:UpdateSizes();
    end
end);

hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
    if frame.unit and UnitIsUnit(frame.unit, "player") then
        local localizedClass, englishClass = UnitClass(frame.unit);
        local classColor = RAID_CLASS_COLORS[englishClass];
        if classColor then
            local r, g, b = classColor.r, classColor.g, classColor.b;

            if r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b then
                frame.healthBar:SetStatusBarColor(r, g, b);
        
                if frame.optionTable.colorHealthWithExtendedColors then
                    frame.selectionHighlight:SetVertexColor(r, g, b);
                else
                    frame.selectionHighlight:SetVertexColor(1, 1, 1);
                end
            end
        end
    end
end);