local function updateHealthBarColor(frame, ...)
    if frame.colorOverride then
        local forceUpdate = ...
        local previousColor = frame.colorOverride.previousColor
        if forceUpdate or previousColor.r ~= frame.healthBar.r or previousColor.g ~= frame.healthBar.g or previousColor.b ~= frame.healthBar.b then
            frame.healthBar:SetStatusBarColor(frame.colorOverride.color.r, frame.colorOverride.color.g, frame.colorOverride.color.b)

            frame.colorOverride.previousColor.r = frame.healthBar.r
            frame.colorOverride.previousColor.g = frame.healthBar.g
            frame.colorOverride.previousColor.b = frame.healthBar.b
        end
    end
end

hooksecurefunc("CompactUnitFrame_UpdateHealthColor", updateHealthBarColor)

local playerRole = 0
local offTanks = {}
local nonTanks = {}

local function resetFrame(frame)
    if frame.colorOverride then
        frame.colorOverride = nil
        frame.healthBar:SetStatusBarColor(frame.healthBar.r, frame.healthBar.g, frame.healthBar.b)
    end
end

local function classColorFrame(frame)
    local localizedClass, englishClass = UnitClass(frame.unit)
    local classColor = RAID_CLASS_COLORS[englishClass]

    if not frame.colorOverride then
        frame.colorOverride = {
            ["color"] = {},
            ["previousColor"] = {},
        };
    end

    frame.colorOverride.color.r = classColor.r
    frame.colorOverride.color.g = classColor.g
    frame.colorOverride.color.b = classColor.b

    updateHealthBarColor(frame, true)
end

local function getGroupRoles()
    local collectedTanks = {}
    local collectedOther = {}
    local unitPrefix, unit, i, unitRole
    local isInRaid = IsInRaid()

    if isInRaid then
        unitPrefix = "raid"
    else
        unitPrefix = "party"
    end

    for i = 1, GetNumGroupMembers() do
        unit = unitPrefix .. i
        if not UnitIsUnit(unit, "player") then
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

    return collectedTanks, collectedOther
end

local function threatSituation(monster)
    local threatStatus = -1
    local tankValue    =  0
    local offTankValue =  0
    local playerValue  =  0
    local nonTankValue =  0
    local unit, isTanking, status, threatValue

    -- store if an offtank is tanking, or store their threat value if higher than others
    for _, unit in ipairs(offTanks) do
        isTanking, status, _, _, threatValue = UnitDetailedThreatSituation(unit, monster)
        if isTanking then
            threatStatus = status + 2
            tankValue = threatValue
        elseif status and threatValue > offTankValue then
            offTankValue = threatValue
        elseif UnitIsUnit(unit, monster .. "target") then
            threatStatus = 5 -- ensure threat status if monster is targeting a tank
        end
    end

    -- store if the player is tanking, or store their threat value if higher than others
    isTanking, status, _, _, threatValue = UnitDetailedThreatSituation("player", monster)
    if isTanking then
        threatStatus = status
        tankValue = threatValue
    elseif status then
        playerValue = threatValue
    end

    -- store if a non-tank is tanking, or store their threat value if higher than others
    for _, unit in ipairs(nonTanks) do
        isTanking, status, _, _, threatValue = UnitDetailedThreatSituation(unit, monster)
        if isTanking then
            threatStatus = 3 - status
            tankValue = threatValue
        elseif status and threatValue > nonTankValue then
            nonTankValue = threatValue
        end
    end

    -- ensure threat status if monster is targeting a friend
    if threatStatus < 0 and UnitIsFriend("player", monster .. "target") then
        threatStatus = 0
        tankValue    = 0
        offTankValue = 0
        playerValue  = 0
        nonTankValue = 0
    end

    return threatStatus, tankValue, offTankValue, playerValue, nonTankValue
end

local function updateThreatColor(frame)
    if UnitCanAttack("player", frame.unit) and (UnitAffectingCombat(frame.unit) or UnitReaction(frame.unit, "player") < 4)
        and not UnitIsPlayer(frame.unit) and not CompactUnitFrame_IsTapDenied(frame) then
        --[[Custom threat situation nameplate coloring:
           -1 = no threat data (monster not in combat).
            0 = a non tank is tanking by threat.
            1 = a non tank is tanking by force.
            2 = player tanking monster by force.
            3 = player tanking monster by threat.
           +4 = another tank is tanking by force.
           +5 = another tank is tanking by threat.
        ]]--
        local status, tank, offtank, player, nontank = threatSituation(frame.unit)

        -- only recalculate color when situation was actually changed with gradient toward sibling color
        if not frame.colorOverride or frame.colorOverride.lastStatus ~= status then
            local r, g, b = 1.0, 0.0, 0.0       -- red outside combat

            if playerRole == "TANK" then
                if status >= 5 then             -- another tank tanking by threat
                    r, g, b = 0.20, 0.50, 0.90  -- blue    no problem
                elseif status >= 4 then         -- another tank tanking by force
                    r, g, b = 1.00, 0.60, 0.00  -- orange  another tank stealing aggro
                elseif status >= 3 then         -- player tanking by threat
                    r, g, b = 0.00, 0.50, 0.01  -- green   no problem
                elseif status >= 2 then         -- player tanking by force
                    r, g, b = 1.00, 1.00, 0.47  -- yellow  player stealing aggro
                elseif status >= 1 then         -- others tanking by force
                    r, g, b = 1.00, 0.00, 0.00  -- red     taunt now
                elseif status >= 0 then         -- others tanking by threat
                    r, g, b = 1.00, 0.30, 0.00  -- orange  taunt?
                end
            elseif next(nonTanks) then
                if status >= 4 then             -- tanks tanking by threat or by force
                    r, g, b = 0.00, 0.50, 0.01  -- green   no problem
                elseif status >= 2 then         -- player tanking by force
                    r, g, b = 1.00, 0.30, 0.00  -- orange  player stealing aggro
                elseif status >= 0 then         -- others tanking by threat or by force
                    r, g, b = 1.00, 0.60, 0.00  -- green   no problem
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

            updateHealthBarColor(frame, true)
        end
    else
        resetFrame(frame)
    end
end

local myFrame = CreateFrame("frame")
myFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
myFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE");
myFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
myFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
myFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED");
myFrame:RegisterEvent("RAID_ROSTER_UPDATE");
myFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
myFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
myFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "UNIT_THREAT_SITUATION_UPDATE" or event == "PLAYER_REGEN_ENABLED" then
        local callback = function()
            for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
                updateThreatColor(nameplate.UnitFrame)
            end
        end
         -- to ensure colors update when mob is back at their spawn
        if event ~= "PLAYER_REGEN_ENABLED" then
            callback()
        else
            C_Timer.NewTimer(5.0, callback)
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local callback = function()
            local nameplate = C_NamePlate.GetNamePlateForUnit(arg1)
            if nameplate then
                if not UnitIsPlayer(nameplate.UnitFrame.unit) then
                    updateThreatColor(nameplate.UnitFrame)
                else
                    classColorFrame(nameplate.UnitFrame)
                end
            end
        end
        callback()
        C_Timer.NewTimer(0.3, callback)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local nameplate = C_NamePlate.GetNamePlateForUnit(arg1)
        if nameplate then
            resetFrame(nameplate.UnitFrame)
        end
    elseif event == "PLAYER_ROLES_ASSIGNED" or event == "RAID_ROSTER_UPDATE" or
           event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        offTanks, nonTanks = getGroupRoles()
        playerRole = GetSpecializationRole(GetSpecialization())
    end
end);