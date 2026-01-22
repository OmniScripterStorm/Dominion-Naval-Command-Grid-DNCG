--[[
    AZUREUS MARITIME DOMINION // DNCG FUNCTION LIBRARY
    This library contains all essential functions of the Dominion Naval Command Grid(DNCG).
    Author: 1st Research Group 'Stasis λ'
]]

--[[
    AZUREUS MARITIME DOMINION // DNCG FUNCTION LIBRARY
    Version: 3.0 (Hyper-Efficient)
    Author: 1st Research Group 'Stasis λ'
]]

local Lib = {}

--// 1. OPTIMIZATION UPVALUES (Speed > Readability)
local v3 = Vector3.new
local mag = Vector3.zero.Magnitude
local sock = workspace.CurrentCamera
local wtvp = sock.WorldToViewportPoint
local find = game.FindFirstChild
local getChildren = game.GetChildren
local math_min = math.min
local math_abs = math.abs

--// 2. CONSTANTS
local CONST = {
    Grav = 196.2,
    AntiGrav = 457.79998779296875,
    Mass = 2.8,
    VelShip = 710,
    VelAA = 700,
    RangeSq = 4000 * 4000 -- Max engagement range squared
}
local NET_GRAV = Vector3.new(0, -(CONST.Grav - (CONST.AntiGrav / CONST.Mass)), 0)

--// 3. TELEMETRY & MATH
function Lib.GetDistSq(posA, posB)
    local x, y, z = posA.X - posB.X, posA.Y - posB.Y, posA.Z - posB.Z
    return (x*x) + (y*y) + (z*z)
end

function Lib.FormatTelemetry(target)
    if not target or not target.Root then return "NO SIGNAL", "0", "0" end
    local dist = (sock.CFrame.Position - target.Root.Position).Magnitude
    local speed = target.Root.AssemblyLinearVelocity.Magnitude
    return target.Name:upper(), string.format("%.0f", dist), string.format("%.0f", speed)
end

function Lib.SolveBallistic(origin, targetRoot, mode)
    if not targetRoot then return Vector3.zero end
    
    local speed = (mode == "BALLISTIC") and CONST.VelShip or CONST.VelAA
    local tPos = targetRoot.Position
    local tVel = targetRoot.AssemblyLinearVelocity
    
    -- AA Mode: Simple Linear Lead
    if mode == "AA" or mode == "PLANE" then
        local dist = (tPos - origin).Magnitude
        return tPos + (tVel * (dist / speed))
    end

    -- Ballistic Mode: Iterative Gravity Solver
    local time = (tPos - origin).Magnitude / speed
    -- 3-Pass Iteration for precision without cost
    local p1 = tPos + (tVel * time)
    local p2 = p1 - (0.5 * NET_GRAV * time * time)
    return p2
end

--// 4. DETECTION LOGIC
-- Returns the "Best" target based on screen proximity
function Lib.ScanForTargets(myTeam, mode, searchRadius)
    local bestTarget = nil
    local bestScreenDist = searchRadius -- Pixel radius from mouse
    local mouse = game:GetService("UserInputService"):GetMouseLocation()

    -- Helper to check a candidate
    local function Check(model, root, isPlayer)
        -- Quick Team Check
        if isPlayer then
            if model.Team == myTeam then return end
        else
            local t = find(model, "Team")
            if t and t.Value == myTeam.Name then return end
        end

        -- Screen Check
        local pos, vis = wtvp(sock, root.Position)
        if vis then
            local dx, dy = mouse.X - pos.X, mouse.Y - pos.Y
            local dist = (dx*dx) + (dy*dy) -- Compare squared distance
            if dist < (bestScreenDist * bestScreenDist) then
                bestScreenDist = math.sqrt(dist)
                bestTarget = {
                    Instance = model,
                    Root = root,
                    Name = model.Name,
                    IsPlayer = isPlayer
                }
            end
        end
    end

    -- A. SHIP SCAN (BALLISTIC)
    if mode == "BALLISTIC" then
        local raw = workspace:GetChildren() -- Fast access
        for i = 1, #raw do
            local m = raw[i]
            -- Filter generic names to avoid checking clouds/water
            if m.Name == "Battleship" or m.Name == "Cruiser" or m.Name == "Destroyer" or m.Name == "Carrier" or m.Name == "Submarine" then
                local hp = find(m, "HP")
                if hp and hp.Value > 0 then
                    local r = find(m, "VehicleSeat") or m.PrimaryPart
                    if r then Check(m, r, false) end
                end
            end
        end

    -- B. PLANE SCAN
    elseif mode == "PLANE" then
        local players = game:GetService("Players"):GetPlayers()
        for i = 1, #players do
            local p = players[i]
            if p.Character then
                local hum = find(p.Character, "Humanoid")
                if hum and hum.Sit and hum.SeatPart and hum.SeatPart.Parent then
                    local vName = hum.SeatPart.Parent.Name
                    if vName:find("Plane") or vName:find("Bomber") then
                        local r = find(hum.SeatPart.Parent, "Part") or hum.SeatPart
                        Check(p, r, true)
                    end
                end
            end
        end
        
    -- C. AA SCAN (PLAYERS)
    else
        local players = game:GetService("Players"):GetPlayers()
        for i = 1, #players do
            local p = players[i]
            if p.Character then
                local r = find(p.Character, "HumanoidRootPart")
                local h = find(p.Character, "Humanoid")
                if r and h and h.Health > 0 then Check(p, r, true) end
            end
        end
    end

    return bestTarget
end

return Lib
