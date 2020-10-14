local myFrame = CreateFrame("Frame")
myFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
myFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

local oldNamePlateTargetFrame = nil
local oldNamePlateTargetScale = -1
local oldNamePlateTargetHealthBarSize = -1

myFrame:SetScript("OnEvent", function(self, event, ...)
    if (not UnitIsUnit("player", "target")) then
        local namePlate = C_NamePlate.GetNamePlateForUnit("target", issecure())
        if (namePlate) then
            local namePlateTargetFrame = namePlate.UnitFrame
            if (namePlateTargetFrame) then
                if (namePlateTargetFrame ~= oldNamePlateTargetFrame) then
                    local newNamePlateTargetScale = namePlateTargetFrame:GetScale()
                    local newNamePlateTargetHealthBarSize = namePlateTargetFrame.healthBar:GetHeight()

                    namePlateTargetFrame.healthBar:SetHeight(newNamePlateTargetHealthBarSize * 1.275)
                    namePlateTargetFrame:SetScale(newNamePlateTargetScale * 1.275)

                    if (oldNamePlateTargetFrame) then
                        oldNamePlateTargetFrame.healthBar:SetHeight(oldNamePlateTargetHealthBarSize)
                        oldNamePlateTargetFrame:SetScale(oldNamePlateTargetScale)
                    end

                    oldNamePlateTargetFrame = namePlateTargetFrame
                    oldNamePlateTargetScale = newNamePlateTargetScale
                    oldNamePlateTargetHealthBarSize = newNamePlateTargetHealthBarSize
                end
            else
                if (oldNamePlateTargetFrame) then
                    oldNamePlateTargetFrame.healthBar:SetHeight(oldNamePlateTargetHealthBarSize)
                    oldNamePlateTargetFrame:SetScale(oldNamePlateTargetScale)
                    oldNamePlateTargetFrame = nil
                end
            end
        end
    end
    if event == "NAME_PLATE_UNIT_ADDED" then
        local namePlate = C_NamePlate.GetNamePlateForUnit("player", issecure())
        if (namePlate) then
            local namePlateTargetFrame = namePlate.UnitFrame
            if (namePlateTargetFrame) then
                namePlateTargetFrame.healthBar:SetHeight(12)
            end
        end
    end
end)