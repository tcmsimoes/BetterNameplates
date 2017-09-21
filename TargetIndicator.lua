local myFrame = CreateFrame("Frame")
myFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
myFrame:RegisterEvent("PLAYER_TARGET_CHANGED");

local oldNamePlateTarget = nil;
local oldNamePlateTargetScale = -1;

myFrame:SetScript("OnEvent", function(self, event)
    local namePlateTarget = C_NamePlate.GetNamePlateForUnit("target", issecure());
    if (namePlateTarget and namePlateTarget ~= oldNamePlateTarget) then
        local newNamePlateTargetScale = namePlateTarget.UnitFrame:GetScale();

        namePlateTarget.UnitFrame:SetScale(newNamePlateTargetScale * 1.25);

        if (oldNamePlateTarget) then
            oldNamePlateTarget.UnitFrame:SetScale(oldNamePlateTargetScale);
        end

        oldNamePlateTarget = namePlateTarget;
        oldNamePlateTargetScale = newNamePlateTargetScale;
    end
end);
