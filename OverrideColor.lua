local function resetHealthBarColor(frame)
    if frame.colorOverride then
        frame.colorOverride = nil
    end

    local r, g, b, _ =  UnitSelectionColor(frame.unit)
    local localizedClass, englishClass = UnitClass(frame.unit);
    local classColor = RAID_CLASS_COLORS[englishClass];
    if UnitIsPlayer(frame.unit) or UnitTreatAsPlayerForDisplay(frame.unit) then
        r, g, b = classColor.r, classColor.g, classColor.b;
    end
    
    frame.healthBar:SetStatusBarColor(r, g, b);
end

local function updateHealthBarColor(frame)
    if frame.colorOverride then
        if frame.unit ~= frame.colorOverride.unit then
            resetHealthBarColor(frame)
        else
            local r = frame.colorOverride.color.r
            local g = frame.colorOverride.color.g
            local b = frame.colorOverride.color.b

            frame.healthBar:SetStatusBarColor(r, g, b)
        end
    end
end

hooksecurefunc("CompactUnitFrame_UpdateHealthColor", updateHealthBarColor)
hooksecurefunc("CompactUnitFrame_UpdateHealthBorder", updateHealthBarColor)

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
        if not UnitIsUnit("player", unit) and not UnitIsUnit("pet", unit) then
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
    if not frame.unit then
        resetHealthBarColor(frame)

    elseif UnitIsUnit("player", frame.unit) then
        local localizedClass, englishClass = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[englishClass]

        if not frame.colorOverride then
            frame.colorOverride = {
                ["color"] = {},
            }
        end

        frame.colorOverride.unit = frame.unit
        frame.colorOverride.color.r = classColor.r
        frame.colorOverride.color.g = classColor.g
        frame.colorOverride.color.b = classColor.b

        updateHealthBarColor(frame)

    elseif GetNumGroupMembers() > 1
      and not UnitIsPlayer(frame.unit)
      and UnitCanAttack("player", frame.unit)
      and not CompactUnitFrame_IsTapDenied(frame)
      and (UnitAffectingCombat(frame.unit) or UnitReaction("player", frame.unit) < 4) then
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
            local r, g, b = 1.0, 0.0, 0.0 -- default to red

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
                elseif status >= 2 then         -- player tanking
                    r, g, b = 1.00, 0.00, 0.00  -- red     drop aggro!
                elseif status >= 0 then         -- others tanking
                    r, g, b = 1.00, 1.00, 0.47  -- yellow  no problem?
                end
            end

            if not frame.colorOverride then
                frame.colorOverride = {
                    ["color"] = {},
                }
            end

            frame.colorOverride.unit = frame.unit
            frame.colorOverride.lastStatus = status
            frame.colorOverride.color.r = r
            frame.colorOverride.color.g = g
            frame.colorOverride.color.b = b

            updateHealthBarColor(frame)
        end
    else
        resetHealthBarColor(frame)
    end
end

local myFrame = CreateFrame("frame")
myFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
myFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
myFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
myFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
myFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
myFrame:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED")
myFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
myFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
myFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
myFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
myFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
myFrame:RegisterEvent("RAID_ROSTER_UPDATE")
myFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
myFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

myFrame:SetScript("OnEvent", function(self, event, unit)
    local updateAllNameplates = function()
        for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
            if nameplate.UnitFrame and nameplate.UnitFrame.unit then
                updateThreatColor(nameplate.UnitFrame)
            end
        end
    end

    if event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "PLAYER_SOFT_FRIEND_CHANGED" or
       event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_TARGET_CHANGED" or
       event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" or
       event == "UNIT_TARGET" or event == "PLAYER_REGEN_ENABLED" then
        if event == "PLAYER_REGEN_ENABLED" then -- keep trying until mobs back at spawn
            C_Timer.NewTimer(20.0, updateAllNameplates)
        else -- soft targets need a short delay for border
            C_Timer.NewTimer(0.1, updateAllNameplates)
        end

        updateAllNameplates()
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
        if nameplate and nameplate.UnitFrame then
            updateThreatColor(nameplate.UnitFrame)
        end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
        if nameplate and nameplate.UnitFrame then
            resetHealthBarColor(nameplate.UnitFrame)
        end
    elseif event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" or
           event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_ROLES_ASSIGNED" or 
           event == "PLAYER_ENTERING_WORLD" then
        offTanks, nonTanks, playerRole = getGroupRoles()

        C_Timer.NewTimer(0.1, updateAllNameplates)
    end
end)