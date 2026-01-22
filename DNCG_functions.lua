--[[
    AZUREUS MARITIME DOMINION // DNCG FUNCTION LIBRARY
    This library contains all essential core functions of the Dominion Naval Command Grid(DNCG).
    Author: 1st Research Group 'Stasis λ'
]]

local Funcs = {}

--// CACHED SERVICES & CONSTANTS
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CONST = {
    Gravity = Workspace.Gravity,
    AntiGrav = 457.8, -- Naval Warfare float physics
    Mass = 2.8,
    Velocities = {
        Ship = 710, -- Shell speed
        AA = 700    -- Bullet speed
    },
    DistSq = {
        Max = 6000 * 6000,
        Acquire = 100 * 100 -- Mouse distance squared
    },
    NetGravity = Vector3.new(0, -(Workspace.Gravity - (457.8 / 2.8)), 0)
}

--// HELPER: VALIDATE INSTANCE
function Funcs.Validate(targetTbl)
    return targetTbl and targetTbl.Root and targetTbl.Root.Parent and targetTbl.Hum and targetTbl.Hum.Health > 0
end

--// CORE: SCANNING (Highly Optimized)
function Funcs.Scan(localPlayer, camera, mousePos, mode)
    local bestTarget = nil
    local bestDist = CONST.DistSq.Acquire
    local myTeam = localPlayer.Team

    -- 1. SCAN PLAYERS (Common to all modes)
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

                -- Mode Filter
                local valid = false
                if mode == "BALLISTIC" and not isPlane and not seat then valid = false -- Ballistic focuses ships, not players
                elseif mode == "AA" and not isPlane then valid = true
                elseif mode == "PLANE" and isPlane then valid = true 
                end

                if valid then
                    local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local dx = screenPos.X - mousePos.X
                        local dy = screenPos.Y - mousePos.Y
                        local distSq = (dx*dx) + (dy*dy)
                        
                        if distSq < bestDist then
                            bestDist = distSq
                            bestTarget = {
                                Root = root,
                                Hum = hum,
                                Name = p.Name,
                                Type = isPlane and "Plane" or "Player"
                            }
                        end
                    end
                end
            end
        end
    end

    -- 2. SCAN SHIPS (Ballistic Mode Only)
    if mode == "BALLISTIC" then
        for _, m in ipairs(Workspace:GetChildren()) do
            -- Fast check: Does it have a "Team" value? Most NW ships do.
            local teamVal = m:FindFirstChild("Team") 
            if teamVal and teamVal.Value ~= myTeam.Name then
                local hp = m:FindFirstChild("HP")
                if hp and hp.Value > 0 then
                    local root = m.PrimaryPart or m:FindFirstChild("Base") or m:FindFirstChild("Hull")
                    if root then
                        local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
                        if onScreen then
                            local dx = screenPos.X - mousePos.X
                            local dy = screenPos.Y - mousePos.Y
                            local distSq = (dx*dx) + (dy*dy)
                            
                            if distSq < bestDist then
                                bestDist = distSq
                                bestTarget = {
                                    Root = root,
                                    Hum = {Health = hp.Value, MaxHealth = m:FindFirstChild("MaxHP") and m.MaxHP.Value or 100}, -- Mock Humanoid
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

--// CORE: MATH SOLVER
function Funcs.CalculateAim(myChar, targetTbl, mode)
    if not (myChar and targetTbl.Root) then return nil end
    
    local origin = myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position
    -- Adjust origin if seated (Turret position)
    local myHum = myChar:FindFirstChild("Humanoid")
    if myHum and myHum.SeatPart then origin = myHum.SeatPart.Position end
    if not origin then return nil end

    local tPos = targetTbl.Root.Position
    local tVel = targetTbl.Root.AssemblyLinearVelocity

    if mode == "BALLISTIC" then
        -- Projectile Motion w/ Drag & Buoyancy compensation
        local v = CONST.Velocities.Ship
        local g = CONST.NetGravity
        
        -- Cap velocity for ships (Prediction Cap)
        if tVel.Magnitude > 150 then tVel = tVel.Unit * 150 end
        
        -- Iterative Solver
        local time = (tPos - origin).Magnitude / v
        for _ = 1, 3 do
            local predPos = tPos + (tVel * time)
            time = (predPos - origin).Magnitude / v
        end
        
        local predPos = tPos + (tVel * time)
        local drop = 0.5 * g * time * time
        return predPos - drop 
        
    else
        -- Linear Lead (AA / Planes)
        local v = CONST.Velocities.AA
        
        -- Clamp Plane erratic movement
        if mode == "PLANE" and tVel.Magnitude > 300 then tVel = tVel.Unit * 300 end
        
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
