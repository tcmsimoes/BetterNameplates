local function resetHealthBarColor(frame)
    if frame.colorOverride then
        frame.colorOverride = nil
    end

    CompactUnitFrame_UpdateHealthColor(frame)
end

local function updateHealthBarColor(frame)
    if frame.colorOverride then
        local r = frame.colorOverride.color.r
        local g = frame.colorOverride.color.g
        local b = frame.colorOverride.color.b

        frame.healthBar:SetStatusBarColor(r, g, b)

        frame.colorOverride.previousColor.r = r
        frame.colorOverride.previousColor.g = g
        frame.colorOverride.previousColor.b = b
    end
end

hooksecurefunc("CompactUnitFrame_UpdateHealthColor", updateHealthBarColor)
-- try to avoid misterious color reset
hooksecurefunc("CompactUnitFrame_UpdateHealthBorder", updateHealthBarColor)
hooksecurefunc("CompactUnitFrame_UpdateAggroFlash", updateHealthBarColor)

local playerRole = 0
local offTanks = {}
local nonTanks = {}

local function getGroupRoles()
    local collectedTanks = {}
    local collectedOther = {}
    local collectedPlayer, unitPrefix, unit, i, unitRole
    local isInRaid = IsInRaid()

    collectedPlayer = GetSpecializationRole(GetSpecialization())
    if isInRaid then
        unitPrefix = "raid"
    else
        unitPrefix = "party"
    end

    for i = 1, GetNumGroupMembers() do
        unit = unitPrefix .. i
        if not UnitIsUnit(unit, "player") and not UnitIsUnit(unit, "pet") then
            unitRole = UnitGroupRolesAssigned(unit)
            if isInRaid and unitRole ~= "TANK" then
                _, _, _, _, _, _, _, _, _, unitRole = GetRaidRosterInfo(i)
                if unitRole == "MAINTANK" then
                    unitRole = "TANK"
                end
            end
            if unitRole == "TANK" then
                table.insert(collectedTanks, unit)
            else
                table.insert(collectedOther, unit)
            end
        end
    end

    return collectedTanks, collectedOther, collectedPlayer
end

local function threatSituation(monster)
    local targetStatus = -1
    local threatStatus = -1
    local tankValue    =  0
    local offTankValue =  0
    local playerValue  =  0
    local nonTankValue =  0
    local unit, isTanking, status, threatValue

    -- store if an offtank is tanking, or store their threat value if higher than others
    for _, unit in ipairs(offTanks) do
        local isTanking, status, _, _, threatValue = UnitDetailedThreatSituation(unit, monster)
        if status then
            if isTanking then
                threatStatus = status + 2
                tankValue = threatValue
            elseif threatValue > offTankValue then
                offTankValue = threatValue
            end
        end
        if UnitIsUnit(unit, monster .. "target") then
            targetStatus = 5
        end
    end
    -- store if the player is tanking, or store their threat value if higher than others
    local isTanking, status, _, _, threatValue = UnitDetailedThreatSituation("player", monster)
    if status then
        if isTanking then
            threatStatus = status
            tankValue = threatValue
        else
            playerValue = threatValue
        end
    end
    if UnitIsUnit("player", monster .. "target") then
        targetStatus = 3
    end
    -- store if a non-tank is tanking, or store their threat value if higher than others
    for _, unit in ipairs(nonTanks) do
        local isTanking, status, _, _, threatValue = UnitDetailedThreatSituation(unit, monster)
        if status then
            if isTanking then
                threatStatus = 3 - status
                tankValue = threatValue
            elseif threatValue > nonTankValue then
                nonTankValue = threatValue
            end
        end
        if UnitIsUnit(unit, monster .. "target") then
            targetStatus = 0
        end
    end
    -- default to offtank low threat on a nongroup target if none of the above were a match
    if targetStatus < 0 and UnitExists(monster .. "target") then
        unit = monster .. "target"
        local isTanking, status, _, _, threatValue = UnitDetailedThreatSituation(unit, monster)
        if playerRole == "TANK" then
            if status then
                if isTanking then
                    threatStatus = status + 2
                    tankValue = threatValue
                elseif threatValue > offTankValue then
                    offTankValue = threatValue
                end
            end
            if not UnitIsFriend(monster, unit) then
                targetStatus = 5
            end
        else
            if status then
                if isTanking then
                    threatStatus = 3 - status
                    tankValue = threatValue
                elseif threatValue > nonTankValue then
                    nonTankValue = threatValue
                end
            end
            if not UnitIsFriend(monster, unit) then
                targetStatus = 0
            end
        end
    end
    -- clear threat values if tank was found through monster target instead of threat
    if targetStatus > -1 and (UnitIsPlayer(monster) or threatStatus < 0) then
        threatStatus = targetStatus
    end
    -- player status is always -1 if not in combat
    if not UnitAffectingCombat("player") then
        playerValue = -1
    end

    return threatStatus
end

local function updateThreatColor(frame)
    if GetNumGroupMembers() > 1
        and UnitCanAttack("player", frame.unit)
        and not CompactUnitFrame_IsTapDenied(frame)
        and (UnitAffectingCombat(frame.unit) or UnitReaction(frame.unit, "player") < 4) then
        --[[Custom threat situation nameplate coloring:
            -1 = no threat data (monster not in combat).
            0 = a non tank is tanking by threat.
            1 = a non tank is tanking by force.
            2 = player tanking monster by force.
            3 = player tanking monster by threat.
            +4 = another tank is tanking by force.
            +5 = another tank is tanking by threat.
        ]]
        local status = threatSituation(frame.unit)

        -- only recalculate color when situation was actually changed with gradient toward sibling color
        if not frame.colorOverride or frame.colorOverride.lastStatus ~= status then
            local r, g, b = 0.0, 0.0, 0.0

            if playerRole == "TANK" then
                if status >= 5 then             -- another tank tanking by threat
                    r, g, b = 0.20, 0.50, 0.90  -- blue    no problem
                elseif status >= 4 then         -- another tank tanking by force
                    r, g, b = 1.00, 1.00, 0.47  -- yellow  taunt now!
                elseif status >= 3 then         -- player tanking by threat
                    r, g, b = 0.00, 0.50, 0.01  -- green   no problem
                elseif status >= 2 then         -- player tanking by force
                    r, g, b = 1.00, 0.60, 0.00  -- orange  drop aggro!
                elseif status >= 1 then         -- others tanking by force
                    r, g, b = 1.00, 0.00, 0.00  -- red     taunt now!
                elseif status >= 0 then         -- others tanking by threat
                    r, g, b = 1.00, 0.30, 0.00  -- orange  taunt?
                end
            else
                if status >= 4 then             -- tanks tanking by threat or by force
                    r, g, b = 0.00, 0.50, 0.01  -- green   no problem
                elseif status >= 2 then         -- player tanking by force
                    r, g, b = 1.00, 0.00, 0.00  -- red     drop aggro!
                elseif status >= 0 then         -- others tanking by threat or by force
                    r, g, b = 1.00, 1.00, 0.47  -- yellow  no problem?
                end
            end

            if not frame.colorOverride then
                frame.colorOverride = {
                    ["color"] = {},
                    ["previousColor"] = {},
                };
            end

            frame.colorOverride.lastStatus = status
            frame.colorOverride.color.r = r
            frame.colorOverride.color.g = g
            frame.colorOverride.color.b = b
            frame.colorOverride.previousColor.r = 0.0
            frame.colorOverride.previousColor.g = 0.0
            frame.colorOverride.previousColor.b = 0.0

            updateHealthBarColor(frame)
        end
    else
        resetHealthBarColor(frame)
    end
end

local myFrame = CreateFrame("frame")
myFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE");
myFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE"); 
myFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
myFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
myFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
myFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED");
myFrame:RegisterEvent("RAID_ROSTER_UPDATE");
myFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
myFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
myFrame:SetScript("OnEvent", function(self, event, unit)
    local updateAllNamePlates = function()
        for _, namePlate in pairs(C_NamePlate.GetNamePlates(issecure())) do
            if namePlate.UnitFrame and not UnitIsUnit(namePlate.UnitFrame.unit, "player") then
                updateThreatColor(namePlate.UnitFrame)
            end
        end
    end
    if event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" or
       event == "PLAYER_REGEN_ENABLED" then
         -- to ensure colors update when mob is back at their spawn
        if event == "PLAYER_REGEN_ENABLED" then
            C_Timer.After(5.0, updateAllNamePlates)
        end

        updateAllNamePlates()
    elseif event == "NAME_PLATE_UNIT_ADDED" and not UnitIsUnit(unit, "player") then
        local namePlate = C_NamePlate.GetNamePlateForUnit(unit, issecure())
        if namePlate and namePlate.UnitFrame then
            updateThreatColor(namePlate.UnitFrame)
        end
    elseif event == "NAME_PLATE_UNIT_REMOVED" and not UnitIsUnit(unit, "player") then
        local namePlate = C_NamePlate.GetNamePlateForUnit(unit, issecure())
        if namePlate and namePlate.UnitFrame then
            resetHealthBarColor(namePlate.UnitFrame)
        end
    elseif event == "PLAYER_ROLES_ASSIGNED" or event == "RAID_ROSTER_UPDATE" or
           event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        offTanks, nonTanks, playerRole = getGroupRoles()

        updateAllNamePlates()
    end
end);