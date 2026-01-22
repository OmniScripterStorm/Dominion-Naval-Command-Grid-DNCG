--[[
    AZUREUS MARITIME DOMINION // DNCG FUNCTION LIBRARY
    This library contains all essential core functions of the Dominion Naval Command Grid(DNCG).
    Author: 1st Research Group 'Stasis λ'
]]

local Funcs = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

--// PHYSICS CONSTANTS
local RAW_ANTIGRAV = 457.79998779296875 
local SHELL_MASS = 2.8
local NET_ACCEL_Y = -(Workspace.Gravity - (RAW_ANTIGRAV / SHELL_MASS))

local CONST = {
    Velocities = { Ship = 710, AA = 700 },
    DistSq = { Acquire = 100 * 100 },
    GravityVec = Vector3.new(0, NET_ACCEL_Y, 0)
}

--// HELPER: FIND TRUE FIRING ORIGIN
function Funcs.GetFiringOrigin(myChar)
    if not myChar then return nil end
    local hum = myChar:FindFirstChild("Humanoid")
    local origin = nil

    -- 1. Default to RootPart
    if myChar:FindFirstChild("HumanoidRootPart") then
        origin = myChar.HumanoidRootPart.Position
    end

    -- 2. If Seated, Check for Main Battery
    if hum and hum.SeatPart then
        local vehicle = hum.SeatPart.Parent
        origin = hum.SeatPart.Position -- Default to seat if no turret found
        
        if vehicle then
            local seatCF = hum.SeatPart.CFrame
            local bestDist = 0
            
            -- Scan children for Main Turrets
            for _, child in ipairs(vehicle:GetChildren()) do
                -- Strict Name Check: "Turret"
                if child.Name == "Turret" then
                    
                    -- Exclude AA Guns (Any turret containing "AA" object)
                    if not child:FindFirstChild("AA") then
                        
                        -- Determine Position (Handle both Model and Part turrets)
                        local turretPos = nil
                        if child:IsA("BasePart") then
                            turretPos = child.Position
                        elseif child:IsA("Model") then
                            -- Use PrimaryPart, or Pivot, or first Part found
                            if child.PrimaryPart then turretPos = child.PrimaryPart.Position
                            else turretPos = child:GetPivot().Position end
                        end
                        
                        if turretPos then
                            -- Check relative position to find the Forward Main Battery
                            -- We convert world pos to object space relative to the seat
                            local relPos = seatCF:PointToObjectSpace(turretPos)
                            
                            -- We assume the main gun is usually Forward (-Z) and slightly Up (+Y)
                            -- We pick the one furthest forward to ensure barrel clearance
                            if relPos.Z < 0 and math.abs(relPos.Z) > bestDist then
                                bestDist = math.abs(relPos.Z)
                                origin = turretPos
                            end
                        end
                    end
                end
            end
        end
    end
    return origin
end

--// CORE: SCANNING
function Funcs.Scan(localPlayer, camera, mousePos, mode)
    local bestTarget = nil
    local bestDist = CONST.DistSq.Acquire
    local myTeam = localPlayer.Team
    local camPos = camera.CFrame.Position

    -- 1. PLAYER SCAN
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
                if mode == "BALLISTIC" and not isPlane and not seat then valid = false
                elseif mode == "AA" and not isPlane then valid = true
                elseif mode == "PLANE" and isPlane then valid = true 
                end

                if valid and (root.Position - camPos).Magnitude < 8000 then
                    local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local dx, dy = screenPos.X - mousePos.X, screenPos.Y - mousePos.Y
                        if (dx*dx + dy*dy) < bestDist then
                            bestDist = (dx*dx + dy*dy)
                            bestTarget = {Root = root, Hum = hum, Name = p.Name, Type = isPlane and "Plane" or "Player"}
                        end
                    end
                end
            end
        end
    end

    -- 2. SHIP SCAN (BALLISTIC)
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
                                local dx, dy = screenPos.X - mousePos.X, screenPos.Y - mousePos.Y
                                if (dx*dx + dy*dy) < bestDist then
                                    bestDist = (dx*dx + dy*dy)
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

--// CORE: MATH SOLVER
function Funcs.CalculateAim(myChar, targetTbl, mode)
    if not (myChar and targetTbl.Root) then return nil end
    
    -- [PARALLAX CORRECTION]
    -- Finds the specific "Turret" object excluding "AA"
    local origin = Funcs.GetFiringOrigin(myChar)
    if not origin then return nil end

    local tPos = targetTbl.Root.Position
    local tVel = targetTbl.Root.AssemblyLinearVelocity

    if mode == "BALLISTIC" then
        local v = CONST.Velocities.Ship
        local g = CONST.GravityVec
        
        if tVel.Magnitude > 160 then tVel = tVel.Unit * 160 end
        
        local time = (tPos - origin).Magnitude / v
        
        -- High Precision Iteration (8-pass)
        for _ = 1, 8 do
            local futurePos = tPos + (tVel * time)
            futurePos = futurePos + (tVel * 0.06) -- Latency Comp
            time = (futurePos - origin).Magnitude / v
        end
        
        local predPos = tPos + (tVel * time)
        local drop = 0.5 * g * time * time
        return predPos - drop 
        
    else
        -- AA / Plane
        local v = CONST.Velocities.AA
        if mode == "PLANE" and tVel.Magnitude > 350 then tVel = tVel.Unit * 350 end
        local dist = (tPos - origin).Magnitude
        local time = dist / v
        return tPos + (tVel * time)
    end
end

--// UTILITY: VALIDATE & TELEMETRY
function Funcs.Validate(targetTbl)
    return targetTbl and targetTbl.Root and targetTbl.Root.Parent and targetTbl.Hum and targetTbl.Hum.Health > 0
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
