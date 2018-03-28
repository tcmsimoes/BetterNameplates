local myFrame = CreateFrame("Frame")
myFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
myFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

local oldNamePlateTarget = nil
local oldNamePlateTargetScale = -1

myFrame:SetScript("OnEvent", function(self, event)
    if (not UnitIsUnit("player", "target")) then
        local namePlateTarget = C_NamePlate.GetNamePlateForUnit("target", issecure())
        if (namePlateTarget) then
            if (namePlateTarget ~= oldNamePlateTarget) then
                local newNamePlateTargetScale = namePlateTarget.UnitFrame:GetScale()

                namePlateTarget.UnitFrame:SetScale(newNamePlateTargetScale * 1.275)

                if (oldNamePlateTarget) then
                    oldNamePlateTarget.UnitFrame:SetScale(oldNamePlateTargetScale)
                end

                oldNamePlateTarget = namePlateTarget
                oldNamePlateTargetScale = newNamePlateTargetScale
            end
        else
            if (oldNamePlateTarget) then
                oldNamePlateTarget.UnitFrame:SetScale(oldNamePlateTargetScale)
                oldNamePlateTarget = nil
            end
        end
    else
        local class, classFileName = UnitClass("player")
        local color = RAID_CLASS_COLORS[classFileName]
        C_NamePlate.SetNamePlateSelfSize(128, 32)
        oldNamePlateTarget.UnitFrame:SetStatusBarColor(color.r, color.g, color.b)
    end
end)
