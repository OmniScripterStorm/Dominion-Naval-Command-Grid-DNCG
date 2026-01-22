--[[
    AZUREUS MARITIME DOMINION // DNCG TARGETING LIBRARY
    This library contains all visual targeting functions of the Dominion Naval Command Grid(DNCG).
    Author: 1st Research Group 'Stasis λ'
]]

local TargetLib = {}
local Camera = nil

--// OBJECT POOL
local Pool = {
    Lines = {},
    Squares = {},
    Text = {}
}

local ActiveDrawings = {}

--// HELPERS
local function GetLine()
    local l = Drawing.new("Line")
    l.Thickness = 1.5
    l.Color = Color3.fromRGB(0, 245, 212) -- Cyan
    l.Transparency = 1
    l.Visible = false
    table.insert(ActiveDrawings, l)
    return l
end

local function GetSquare()
    local s = Drawing.new("Square")
    s.Thickness = 1.5
    s.Color = Color3.fromRGB(0, 245, 212)
    s.Filled = false
    s.Visible = false
    table.insert(ActiveDrawings, s)
    return s
end

--// INIT
function TargetLib:Init(cam)
    Camera = cam
    -- Pre-allocate a few shapes if needed, or JIT
end

--// CLEANUP
function TargetLib:Clear()
    for _, d in ipairs(ActiveDrawings) do
        d.Visible = false
        d:Remove() -- For full reset. In a loop, we'd reuse, but for simplicity we clear.
    end
    table.clear(ActiveDrawings)
end

--// RENDER HOVER (Acquisition Box)
function TargetLib:RenderHover(targetTbl)
    self:Clear()
    if not targetTbl then return end
    
    local pos, vis = Camera:WorldToViewportPoint(targetTbl.Root.Position)
    if vis then
        local box = GetSquare()
        box.Size = Vector2.new(40, 40)
        box.Position = Vector2.new(pos.X - 20, pos.Y - 20)
        box.Color = Color3.fromRGB(255, 255, 255) -- White for hover
        box.Transparency = 0.5
        box.Visible = true
    end
end

--// RENDER LOCKED (Target Box + Lead Line)
function TargetLib:RenderLock(targetTbl, aimPos)
    self:Clear()
    if not (targetTbl and targetTbl.Root) then return end
    
    -- 1. Draw Target Box
    local pos, vis = Camera:WorldToViewportPoint(targetTbl.Root.Position)
    if vis then
        local box = GetSquare()
        box.Size = Vector2.new(50, 50)
        box.Position = Vector2.new(pos.X - 25, pos.Y - 25)
        box.Color = Color3.fromRGB(255, 0, 0) -- Red for Locked
        box.Thickness = 2
        box.Visible = true
    end
    
    -- 2. Draw Lead Indicator
    if aimPos then
        local leadPos, lVis = Camera:WorldToViewportPoint(aimPos)
        if vis and lVis then
            local line = GetLine()
            line.From = Vector2.new(pos.X, pos.Y)
            line.To = Vector2.new(leadPos.X, leadPos.Y)
            line.Visible = true
            
            local dot = GetSquare() -- Prediction dot
            dot.Size = Vector2.new(4, 4)
            dot.Filled = true
            dot.Position = Vector2.new(leadPos.X - 2, leadPos.Y - 2)
            dot.Color = Color3.fromRGB(0, 255, 0)
            dot.Visible = true
        end
    end
end

return TargetLib
