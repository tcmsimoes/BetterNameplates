local myFrame = CreateFrame("Frame")
myFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
myFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

local oldNamePlateTarget = nil
local oldNamePlateTargetScale = -1
local oldNamePlateTargetHealthBarSize = -1

myFrame:SetScript("OnEvent", function(self, event, ...)
    if (not UnitIsUnit("player", "target")) then
        local namePlateTarget = C_NamePlate.GetNamePlateForUnit("target", issecure())
        if (namePlateTarget) then
            if (namePlateTarget ~= oldNamePlateTarget) then
                local newNamePlateTargetScale = namePlateTarget.UnitFrame:GetScale()
                local newNamePlateTargetHealthBarSize = namePlateTarget.UnitFrame.healthBar:GetHeight()

                namePlateTarget.UnitFrame.healthBar:SetHeight(newNamePlateTargetHealthBarSize * 1.275)
                namePlateTarget.UnitFrame:SetScale(newNamePlateTargetScale * 1.275)

                if (oldNamePlateTarget) then
                    oldNamePlateTarget.UnitFrame.healthBar:SetHeight(oldNamePlateTargetHealthBarSize)
                    oldNamePlateTarget.UnitFrame:SetScale(oldNamePlateTargetScale)
                end

                oldNamePlateTarget = namePlateTarget
                oldNamePlateTargetScale = newNamePlateTargetScale
                oldNamePlateTargetHealthBarSize = newNamePlateTargetHealthBarSize
            end
        else
            if (oldNamePlateTarget) then
                oldNamePlateTarget.UnitFrame.healthBar:SetHeight(oldNamePlateTargetHealthBarSize)
                oldNamePlateTarget.UnitFrame:SetScale(oldNamePlateTargetScale)
                oldNamePlateTarget = nil
            end
        end
    end
    if event == "NAME_PLATE_UNIT_ADDED" then
        local namePlateTarget = C_NamePlate.GetNamePlateForUnit("player", issecure())
        if (namePlateTarget) then
            namePlateTarget.UnitFrame.healthBar:SetHeight(12)
        end
    end
end)