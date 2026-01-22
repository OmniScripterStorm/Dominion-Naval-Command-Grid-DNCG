--[[
    AZUREUS MARITIME DOMINION // DNCG FUNCTION LIBRARY
    This library contains all essential functions of the Dominion Naval Command Grid(DNCG).
    Author: 1st Research Group 'Stasis λ'
]]

local Lib = {}

--// CACHED SERVICES
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

--// CONSTANTS
local CONST = {
    Grav = 196.2,
    AntiGrav = 457.8,
    Mass = 2.8,
    VelShip = 710,
    VelAA = 700
}
local NET_GRAV = Vector3.new(0, -(CONST.Grav - (CONST.AntiGrav / CONST.Mass)), 0)

--// MATH HELPERS
function Lib.SolveBallistic(origin, targetRoot, mode)
    if not targetRoot then return Vector3.zero end
    local speed = (mode == "BALLISTIC") and CONST.VelShip or CONST.VelAA
    local tPos = targetRoot.Position
    local tVel = targetRoot.AssemblyLinearVelocity

    -- Linear Prediction (AA/Plane)
    if mode ~= "BALLISTIC" then
        local dist = (tPos - origin).Magnitude
        return tPos + (tVel * (dist / speed))
    end

    -- Ballistic Arc (Ship)
    local time = (tPos - origin).Magnitude / speed
    local p1 = tPos + (tVel * time) 
    local p2 = p1 - (0.5 * NET_GRAV * time * time)
    return p2
end

function Lib.FormatTelemetry(target)
    if not target or not target.Root then return "N/A", "0", "0" end
    local dist = (Camera.CFrame.Position - target.Root.Position).Magnitude
    local speed = target.Root.AssemblyLinearVelocity.Magnitude
    return target.Name:sub(1,10):upper(), string.format("%.0f", dist), string.format("%.0f", speed)
end

--// TARGET SCANNER
function Lib.ScanForTargets(myTeam, mode, searchRadius)
    local best = nil
    local bestDist = searchRadius * searchRadius -- Squared comparison
    
    -- Get Mouse and account for GUI Inset (TopBar)
    local mouse = UserInputService:GetMouseLocation()
    -- NOTE: GetMouseLocation includes TopBar. WorldToViewportPoint includes TopBar.
    -- They match in coordinate space.

    local function Check(model, root, isPlayer)
        -- Team Check
        if isPlayer then
            if model.Team == myTeam then return end
        else
            local t = model:FindFirstChild("Team")
            if t and t.Value == myTeam.Name then return end
        end

        -- Screen Math
        local pos, vis = Camera:WorldToViewportPoint(root.Position)
        if vis then
            local dx = mouse.X - pos.X
            local dy = mouse.Y - pos.Y
            local distSq = (dx*dx) + (dy*dy)
            
            if distSq < bestDist then
                bestDist = distSq
                best = {
                    Instance = model,
                    Root = root,
                    Name = model.Name,
                    ScreenPos = Vector2.new(pos.X, pos.Y) -- Return this to Kernel
                }
            end
        end
    end

    -- 1. BALLISTIC (Ships)
    if mode == "BALLISTIC" then
        for _, m in ipairs(Workspace:GetChildren()) do
            if m:FindFirstChild("HP") and m.HP.Value > 0 then
                local r = m:FindFirstChild("VehicleSeat") or m.PrimaryPart
                if r then Check(m, r, false) end
            end
        end
    
    -- 2. PLANE
    elseif mode == "PLANE" then
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p.Character then
                local hum = p.Character:FindFirstChild("Humanoid")
                if hum and hum.Sit and hum.SeatPart and hum.SeatPart.Parent then
                    local vName = hum.SeatPart.Parent.Name
                    if vName:find("Plane") or vName:find("Bomber") then
                        Check(p, hum.SeatPart, true)
                    end
                end
            end
        end

    -- 3. AA (Infantry)
    else 
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p.Character then
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                local h = p.Character:FindFirstChild("Humanoid")
                if r and h and h.Health > 0 then Check(p, r, true) end
            end
        end
    end

    return best
end

return Lib
