local myFrame = CreateFrame("Frame")
myFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
myFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

local oldNamePlateTargetFrame = nil
local oldNamePlateTargetScale = -1

myFrame:SetScript("OnEvent", function(self, event, ...)
    if oldNamePlateTargetFrame then
        oldNamePlateTargetFrame:SetScale(oldNamePlateTargetScale)
        oldNamePlateTargetFrame = nil
    end

    if not UnitIsUnit("player", "target") then
        local namePlate = C_NamePlate.GetNamePlateForUnit("target", issecure())
        if namePlate then
            local namePlateTargetFrame = namePlate.UnitFrame
            if namePlateTargetFrame then
                local newNamePlateTargetScale = namePlateTargetFrame:GetScale()
                namePlateTargetFrame:SetScale(newNamePlateTargetScale * 1.275)

                if oldNamePlateTargetFrame then
                    oldNamePlateTargetFrame:SetScale(oldNamePlateTargetScale)
                end

                oldNamePlateTargetFrame = namePlateTargetFrame
                oldNamePlateTargetScale = newNamePlateTargetScale
            end
        end
    end
end)