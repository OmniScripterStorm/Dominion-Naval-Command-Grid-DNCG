--[[
    AZUREUS MARITIME DOMINION // DNCG FUNCTION LIBRARY
    This library contains all essential functions of the Dominion Naval Command Grid(DNCG).
    Author: 1st Research Group 'Stasis λ'
]]

local Lib = {}

--// 1. OPTIMIZATION UPVALUES
local v3 = Vector3.new
local sock = workspace.CurrentCamera
local wtvp = sock.WorldToViewportPoint
local find = game.FindFirstChild
local findFirstChildIsA = game.FindFirstChildWhichIsA
local getChildren = game.GetChildren
local uis = game:GetService("UserInputService")
local guiService = game:GetService("GuiService")

--// 2. CONSTANTS
local CONST = {
    Grav = 196.2,
    AntiGrav = 457.79998779296875,
    Mass = 2.8,
    VelShip = 710,
    VelAA = 700
}
local NET_GRAV = Vector3.new(0, -(CONST.Grav - (CONST.AntiGrav / CONST.Mass)), 0)

--// 3. UTILITY: VISUAL CENTER
-- Returns the best part to draw UI over
function Lib.GetVisualRoot(model)
    if not model then return nil end
    
    -- For Players: RootPart is good
    local hum = find(model, "Humanoid")
    if hum then return find(model, "HumanoidRootPart") or find(model, "Torso") end
    
    -- For Ships: VehicleSeat is often low/buried. Try to find a larger structure part if possible, otherwise Seat.
    local seat = find(model, "VehicleSeat") or find(model, "Seat") or find(model, "DriverSeat")
    if seat then return seat end
    
    return model.PrimaryPart or findFirstChildIsA(model, "BasePart")
end

--// 4. TELEMETRY
function Lib.FormatTelemetry(target)
    if not target or not target.Root then return "NO SIGNAL", "0", "0" end
    local dist = (sock.CFrame.Position - target.Root.Position).Magnitude
    local vel = target.Root.AssemblyLinearVelocity
    local speed = math.sqrt(vel.X^2 + vel.Y^2 + vel.Z^2) -- True magnitude
    return target.Name:upper(), string.format("%.0f", dist), string.format("%.0f", speed)
end

function Lib.SolveBallistic(origin, targetRoot, mode)
    if not targetRoot then return Vector3.zero end
    
    local speed = (mode == "BALLISTIC") and CONST.VelShip or CONST.VelAA
    local tPos = targetRoot.Position
    local tVel = targetRoot.AssemblyLinearVelocity
    
    -- AA/Plane: Linear Lead
    if mode == "AA" or mode == "PLANE" then
        local dist = (tPos - origin).Magnitude
        return tPos + (tVel * (dist / speed))
    end

    -- Ballistic: Gravity Iteration
    local time = (tPos - origin).Magnitude / speed
    local p1 = tPos + (tVel * time)
    local p2 = p1 - (0.5 * NET_GRAV * time * time)
    return p2
end

--// 5. DETECTION LOGIC (FIXED OFFSET)
function Lib.ScanForTargets(myTeam, mode, searchRadius)
    local bestTarget = nil
    local bestScreenDistSq = searchRadius * searchRadius
    
    -- FIX: Account for the TopBar inset (36px usually)
    local inset = guiService:GetGuiInset() 
    local mouseRaw = uis:GetMouseLocation()
    local mouseX, mouseY = mouseRaw.X - inset.X, mouseRaw.Y - inset.Y

    local function Check(model, root, isPlayer)
        -- Team Check
        if isPlayer then
            if model.Team == myTeam then return end
        else
            local t = find(model, "Team")
            if t and t.Value == myTeam.Name then return end
        end

        -- Screen Check
        local pos, vis = wtvp(sock, root.Position)
        if vis then
            local dx = mouseX - pos.X
            local dy = mouseY - pos.Y
            local distSq = (dx*dx) + (dy*dy)
            
            if distSq < bestScreenDistSq then
                bestScreenDistSq = distSq
                bestTarget = {
                    Instance = model,
                    Root = root,
                    Name = model.Name,
                    IsPlayer = isPlayer
                }
            end
        end
    end

    -- A. BALLISTIC (SHIPS)
    if mode == "BALLISTIC" then
        local raw = workspace:GetChildren()
        for i = 1, #raw do
            local m = raw[i]
            -- Check for HP to ensure it's a destroyable ship
            if find(m, "HP") and find(m, "MaxHP") then
                 local root = Lib.GetVisualRoot(m)
                 if root then Check(m, root, false) end
            end
        end

    -- B. PLANE
    elseif mode == "PLANE" then
        local players = game:GetService("Players"):GetPlayers()
        for i = 1, #players do
            local p = players[i]
            if p.Character then
                local hum = find(p.Character, "Humanoid")
                if hum and hum.Sit and hum.SeatPart and hum.SeatPart.Parent then
                    local vName = hum.SeatPart.Parent.Name
                    if vName:find("Plane") or vName:find("Bomber") then
                        -- Target the Plane Model, not the Player
                        local plane = hum.SeatPart.Parent
                        local root = plane.PrimaryPart or hum.SeatPart
                        Check(p, root, true)
                    end
                end
            end
        end
        
    -- C. AA (INFANTRY)
    else
        local players = game:GetService("Players"):GetPlayers()
        for i = 1, #players do
            local p = players[i]
            if p.Character then
                local root = find(p.Character, "HumanoidRootPart")
                local hum = find(p.Character, "Humanoid")
                if root and hum and hum.Health > 0 then Check(p, root, true) end
            end
        end
    end

    return bestTarget
end

return Lib
