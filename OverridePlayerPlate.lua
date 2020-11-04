hooksecurefunc(NamePlateDriverFrame, "SetupClassNameplateBars", function()
    local namePlatePlayer = C_NamePlate.GetNamePlateForUnit("player", issecure());
    if namePlatePlayer then
        namePlatePlayer.UnitFrame.healthBar:SetHeight(12);
    end    
end);

hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
    if UnitIsUnit(frame.unit, "player") then
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
        
                frame.healthBar.r, frame.healthBar.g, frame.healthBar.b = r, g, b;
            end
        end
    end
end);