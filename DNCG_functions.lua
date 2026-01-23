--[[
    AZUREUS MARITIME DOMINION // DNCG FUNCTION LIBRARY
    This library contains all essential core functions of the Dominion Naval Command Grid(DNCG).
    Author: 1st Research Group 'Stasis λ'
]]

local Funcs = {}

--// CACHED SERVICES & CONSTANTS
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RAW_ANTIGRAV = 457.79998779296875 
local SHELL_MASS = 2.8
local NET_ACCEL_Y = -(Workspace.Gravity - (RAW_ANTIGRAV / SHELL_MASS))

local CONST = {
    Velocities = { Ship = 710, AA = 700 },
    DistSq = { Acquire = 100 * 100 },
    GravityVec = Vector3.new(0, NET_ACCEL_Y, 0)
}

local ATS_CONST = {
    MAX_RANGE = 2500,
    RANGE_SCALER = 250,
    VERTICAL_ENGAGEMENT_LIMIT = -100
}


local BTV_MATRIX = {
    ["Hijacker"] = 1.00,
    ["Heavy Bomber"] = 0.90,
    ["Torpedo Bomber"] = 0.80,
    ["Bomber"] = 0.75,
    ["Carrier"] = 0.65,
    ["Battleship"] = 0.65,
    ["Heavy Cruiser"] = 0.50,
    ["Cruiser"] = 0.50,
    ["Destroyer"] = 0.50,
    ["Submarine"] = 0.40,
    ["Player"] = 0.40, -- Default Player/Infantry
    ["Ship"] = 0.40    -- Default Ship/Unclassified
}

function Funcs.Validate(targetTbl)
    return targetTbl and targetTbl.Root and targetTbl.Root.Parent and targetTbl.Hum and targetTbl.Hum.Health > 0
end

-- Calculates the A.T.S. Heuristic Threat Score
function Funcs.CalculateATSThreat(myRoot, targetTbl)
    local root = targetTbl.Root
    local dist = (myRoot.Position - root.Position).Magnitude

    if dist > ATS_CONST.MAX_RANGE then return 0 end

    -- Determine Base Threat Value (BTV)
    local baseType = targetTbl.Type
    local nameMatch = string.match(targetTbl.Name, "(%a+)")

    -- Hijacker Overrule (Any player within 50 studs)
    if baseType == "Player" and dist <= 50 then
        baseType = "Hijacker"
    elseif baseType == "Ship" and nameMatch and BTV_MATRIX[nameMatch] then
        baseType = nameMatch
    end

    local btv = BTV_MATRIX[baseType] or BTV_MATRIX["Ship"]

    -- Distance Multiplier (DM) = 1.0 + (MaxRange - Distance) / RangeScaler
    local dm = 1.0 + (ATS_CONST.MAX_RANGE - dist) / ATS_CONST.RANGE_SCALER

    return btv * dm
end

-- ScanAllTargets is necessary for A.T.S. map coverage
function Funcs.ScanAllTargets(localPlayer)
    local allTargets = {}
    local myTeam = localPlayer.Team
    local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not myRoot then return allTargets end

    local myPos = myRoot.Position
    local myYPos = myPos.Y

    -- 1. Player Scan (for AA/Plane/Hijackers)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Team ~= myTeam and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")
            
            if root and hum and hum.Health > 0 then
                -- [NEW FILTER] Ignore targets far below our current Y-position
                if root.Position.Y < myYPos + ATS_CONST.VERTICAL_ENGAGEMENT_LIMIT and (root.Position.Y < -200) then continue end

                local isPlane = false
                local seat = hum.SeatPart
                local typeName = "Player"

                if seat and seat.Parent then
                    local vName = seat.Parent.Name
                    if vName:find("Bomber") or vName:find("Plane") then
                        isPlane = true
                        if vName:find("Heavy Bomber") then
                            typeName = "Heavy Bomber"
                        elseif vName:find("Torpedo") then
                            typeName = "Torpedo Bomber"
                        else
                            typeName = "Bomber"
                        end
                    end
                end

                table.insert(allTargets, {
                    Root = root, Hum = hum, Name = p.Name, 
                    Type = isPlane and typeName or "Player"
                })
            end
        end
    end

    -- 2. Ship Scan (for Capital/Cruiser/Destroyer)
    for _, m in ipairs(Workspace:GetChildren()) do
        local teamVal = m:FindFirstChild("Team")
        if teamVal and teamVal.Value ~= myTeam.Name then
            local hp = m:FindFirstChild("HP")
            if hp and hp.Value > 0 then
                local root = m.PrimaryPart or m:FindFirstChild("Base") or m:FindFirstChild("Hull")
                if root then
                    -- [NEW FILTER] Ignore targets below our current Y-position
                    if root.Position.Y < myYPos + ATS_CONST.VERTICAL_ENGAGEMENT_LIMIT and (root.Position.Y < -200) then continue end

                    local shipClass = string.match(m.Name, "(%a+)") 
                    table.insert(allTargets, {
                        Root = root,
                        Hum = {Health = hp.Value, MaxHealth = m:FindFirstChild("MaxHP") and m.MaxHP.Value or 100},
                        Name = m.Name,
                        Type = shipClass or "Ship"
                    })
                end
            end
        end
    end

    return allTargets
end

-- Scans for the single target under the cursor
function Funcs.Scan(localPlayer, camera, mousePos, mode)
    local bestTarget = nil
    local bestDist = CONST.DistSq.Acquire
    local myTeam = localPlayer.Team
    local camPos = camera.CFrame.Position

    --// PLAYER SCAN
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Team ~= myTeam and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")
            
            if root and hum and hum.Health > 0 then
                local isPlane = false
                local seat = hum.SeatPart
                if seat and seat.Parent then
                    local vName = seat.Parent.Name
                    if vName:find("Bomber") or vName:find("Plane") then
                        isPlane = true
                    end
                end

                local valid = false
                if mode == "AA" and not isPlane then
                    valid = true
                elseif mode == "PLANE" and isPlane then
                    valid = true
                end

                if valid and (root.Position - camPos).Magnitude < 8000 then
                    local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local dx = screenPos.X - mousePos.X
                        local dy = screenPos.Y - mousePos.Y
                        local distSq = (dx*dx + dy*dy)
                        
                        if distSq < bestDist then
                            bestDist = distSq
                            bestTarget = {Root = root, Hum = hum, Name = p.Name, Type = isPlane and "Plane" or "Player"}
                        end
                    end
                end
            end
        end
    end

    --// SHIP SCAN
    if mode == "BALLISTIC" then
        for _, m in ipairs(Workspace:GetChildren()) do
            local teamVal = m:FindFirstChild("Team")
            if teamVal and teamVal.Value ~= myTeam.Name then
                local hp = m:FindFirstChild("HP")
                if hp and hp.Value > 0 then
                    local root = m.PrimaryPart or m:FindFirstChild("Base") or m:FindFirstChild("Hull")
                    if root and (root.Position - camPos).Magnitude < 12000 then
                        local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
                        if onScreen then
                            local dx = screenPos.X - mousePos.X
                            local dy = screenPos.Y - mousePos.Y
                            local distSq = (dx*dx + dy*dy)
                            
                            if distSq < bestDist then
                                bestDist = distSq
                                bestTarget = {
                                    Root = root,
                                    Hum = {Health = hp.Value, MaxHealth = m:FindFirstChild("MaxHP") and m.MaxHP.Value or 100},
                                    Name = m.Name,
                                    Type = "Ship"
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    return bestTarget
end

-- Scans for ALL entities within a given range for the radar display.
function Funcs.ScanRadar(localPlayer, range)
    local results = {}
    local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return results end

    local myPos = myRoot.Position
    local rangeSq = range * range

    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local root = p.Character.HumanoidRootPart
            if (root.Position - myPos).Magnitude < range then
                local entityType = "Friendly"
                if p == localPlayer then
                    entityType = "Self"
                elseif p.Team ~= localPlayer.Team then
                    entityType = "Enemy"
                end
                table.insert(results, { Position = root.Position, Type = entityType })
            end
        end
    end
    return results
end

function Funcs.CalculateAim(myChar, targetTbl, mode)
    if not (myChar and targetTbl.Root) then return nil end
    local origin = myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position
    local myHum = myChar:FindFirstChild("Humanoid")
    if myHum and myHum.SeatPart then origin = myHum.SeatPart.Position end
    if not origin then return nil end

    local tPos = targetTbl.Root.Position
    local tVel = targetTbl.Root.AssemblyLinearVelocity

    if mode == "BALLISTIC" then
        local v = CONST.Velocities.Ship
        local g = CONST.GravityVec
        if tVel.Magnitude > 160 then tVel = tVel.Unit * 160 end
        
        local time = (tPos - origin).Magnitude / v
        for _ = 1, 8 do
            local futurePos = tPos + (tVel * time)
            futurePos = futurePos + (tVel * 0.06)
            time = (futurePos - origin).Magnitude / v
        end
        
        local predPos = tPos + (tVel * time)
        local drop = 0.5 * g * time * time
        return predPos - drop
    else
        local v = CONST.Velocities.AA
        if mode == "PLANE" and tVel.Magnitude > 350 then tVel = tVel.Unit * 350 end
        
        local dist = (tPos - origin).Magnitude
        local time = dist / v
        return tPos + (tVel * time)
    end
end

function Funcs.GetTelemetry(myChar, targetTbl)
    if not (myChar and targetTbl) then return 0, 0 end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return 0, 0 end
    
    local dist = (myRoot.Position - targetTbl.Root.Position).Magnitude
    local hp = 0
    if targetTbl.Hum then
        local max = targetTbl.Hum.MaxHealth or 100
        hp = math.clamp(targetTbl.Hum.Health / max, 0, 1)
    end
    return dist, hp
end

return Funcs
