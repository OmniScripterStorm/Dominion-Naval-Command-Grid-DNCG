--[[
    AZUREUS MARITIME DOMINION // DNCG FUNCTION LIBRARY
    This library contains all essential core functions of the Dominion Naval Command Grid(DNCG).
    Author: 1st Research Group 'Stasis λ'
]]

--[[
    AZUREUS MARITIME DOMINION // DNCG FUNCTION LIBRARY (REV 2 - PRECISION BALLISTICS)
    Author: 1st Research Group 'Stasis λ'
]]

local Funcs = {}

--// CACHED SERVICES & CONSTANTS
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- We use the exact raw float value from the game's memory to prevent drift
local RAW_ANTIGRAV = 457.79998779296875 
local SHELL_MASS = 2.8
local NET_ACCEL_Y = -(Workspace.Gravity - (RAW_ANTIGRAV / SHELL_MASS))

local CONST = {
    Velocities = {
        Ship = 710,
        AA = 700
    },
    DistSq = {
        Acquire = 100 * 100 -- Mouse distance squared for acquisition
    },
    GravityVec = Vector3.new(0, NET_ACCEL_Y, 0) -- Pre-calculated Gravity Vector
}

-- Checks if a target object is still valid and combat-ready.
function Funcs.Validate(targetTbl)
    return targetTbl and targetTbl.Root and targetTbl.Root.Parent and targetTbl.Hum and targetTbl.Hum.Health > 0
end

-- Scans the environment for valid targets based on the current FCS mode.
function Funcs.Scan(localPlayer, camera, mousePos, mode)
    local bestTarget = nil
    local bestDist = CONST.DistSq.Acquire
    local myTeam = localPlayer.Team
    local camPos = camera.CFrame.Position

    --// 1. SCAN PLAYERS (Relevant for AA and PLANE modes)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Team ~= myTeam and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")
            
            if root and hum and hum.Health > 0 then
                local isPlane = false
                local seat = hum.SeatPart
                if seat and seat.Parent then
                    local vName = seat.Parent.Name
                    if vName:find("Bomber") or vName:find("Plane") then isPlane = true end
                end

                local valid = false
                if mode == "AA" and not isPlane then valid = true
                elseif mode == "PLANE" and isPlane then valid = true 
                end

                if valid then
                    -- Optimization: Check distance before expensive WorldToViewportPoint call
                    if (root.Position - camPos).Magnitude < 8000 then
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
    end

    --// 2. SCAN SHIPS (BALLISTIC mode only)
    if mode == "BALLISTIC" then
        for _, m in ipairs(Workspace:GetChildren()) do
            local teamVal = m:FindFirstChild("Team") 
            if teamVal and teamVal.Value ~= myTeam.Name then
                local hp = m:FindFirstChild("HP")
                if hp and hp.Value > 0 then
                    local root = m.PrimaryPart or m:FindFirstChild("Base") or m:FindFirstChild("Hull")
                    if root then
                        if (root.Position - camPos).Magnitude < 12000 then
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
    end

    return bestTarget
end

-- Calculates the precise 3D point in space to aim at for a guaranteed hit.
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
        
        -- Cap Velocity to prevent erratic prediction on glitched ships
        if tVel.Magnitude > 160 then tVel = tVel.Unit * 160 end
        
        -- Iterative Solver: Estimates time-to-impact, predicts future position,
        -- and re-calculates time based on that new position for higher accuracy.
        local time = (tPos - origin).Magnitude / v
        for _ = 1, 8 do
            local futurePos = tPos + (tVel * time)
            futurePos = futurePos + (tVel * 0.06) -- Latency Padding (60ms)
            time = (futurePos - origin).Magnitude / v
        end
        
        local predPos = tPos + (tVel * time)
        local drop = 0.5 * g * time * time
        return predPos - drop -- Subtract the pre-calculated negative gravity vector
        
    else -- (AA / PLANE modes)
        -- Linear Lead: Predicts future position in a straight line.
        local v = CONST.Velocities.AA
        if mode == "PLANE" and tVel.Magnitude > 350 then tVel = tVel.Unit * 350 end
        
        local dist = (tPos - origin).Magnitude
        local time = dist / v
        return tPos + (tVel * time)
    end
end

-- Retrieves telemetry data (Distance and Health) for the GUI.
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
