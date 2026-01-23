--[[
    AZUREUS MARITIME DOMINION // DNCG GUI LIBRARY (V4 - Refactored)
    Author: 1st Research Group 'Stasis λ'
    Notes: Re-engineered for stability, readability, and maintainability.
]]

--[[
    AZUREUS MARITIME DOMINION // DNCG GUI LIBRARY (V4.2 - Visual Fixes)
    Author: 1st Research Group 'Stasis λ'
    Notes: Restores original UI specification and corrects layout regressions.
]]

local GUILib = {}

--// THEME & CONSTANTS
GUILib.Theme = {
    Background = Color3.fromHex("0D1B2A"), Primary = Color3.fromHex("1B263B"), Accent = Color3.fromHex("415A77"),
    Text = Color3.fromHex("E0E1DD"), Enemy = Color3.fromHex("FF595E"), Friendly = Color3.fromHex("80FFDB"),
    Self = Color3.fromHex("00F5D4"), Locked = Color3.fromHex("9EF01A")
}
local RADAR_DIAMETER = 250

--// Private helper function for creating and styling UI elements.
local function Create(class, properties)
    local obj = Instance.new(class)
    for prop, value in pairs(properties) do
        if prop == "Children" then
            for _, child in ipairs(value) do child.Parent = obj end
        else
            obj[prop] = value
        end
    end
    return obj
end

--- Private: Builds the bottom identification bar.
function GUILib:_buildBottomBar(parent)
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    local b = {}

    b.frame = Create("Frame", { Name = "BottomBar", Parent = parent, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(0.8, 0, 0, 60), BackgroundColor3 = GUILib.Theme.Background, BackgroundTransparency = 0.2, BorderSizePixel = 0, Children = { Create("UIStroke", {Color = GUILib.Theme.Accent}), Create("UICorner", {CornerRadius = UDim.new(0, 4)}) }})
    
    -- [FIX] Corrected asset ID for the coat of arms.
    b.coatOfArms = Create("ImageLabel", { Name = "CoatOfArms", Parent = b.frame, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Image = "rbxassetid://7374826931" })
    
    local textGroup = Create("Frame", { Name = "TextGroup", Parent = b.frame, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 60, 0.5, 0), Size = UDim2.new(0, 400, 0, 40), Children = { Create("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Center}) }})
    b.systemNameLabel = Create("TextLabel", { Name = "SystemName", Parent = textGroup, Size = UDim2.new(1, 0, 0, 22), Font = Enum.Font.SourceSansSemibold, TextSize = 20, TextColor3 = GUILib.Theme.Text, Text = "DOMINION NAVAL COMMAND GRID", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
    b.factionNameLabel = Create("TextLabel", { Name = "FactionName", Parent = textGroup, Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = GUILib.Theme.Accent, Text = "AZUREUS MARITIME DOMINION", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })

    local userCreds = Create("Frame", { Name = "UserCreds", Parent = b.frame, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.new(0, 250, 1, 0), Children = { Create("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right}) }})
    
    -- [FIX] Corrected font sizes and alignment for user credentials.
    b.userNameLabel = Create("TextLabel", { Name = "UserName", Parent = userCreds, Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.SourceSansSemibold, TextSize = 18, TextColor3 = GUILib.Theme.Text, Text = localPlayer and localPlayer.DisplayName or "UNKNOWN", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right })
    b.userRankLabel = Create("TextLabel", { Name = "UserRank", Parent = userCreds, Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = GUILib.Theme.Accent, Text = "FETCHING RANK...", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right })
    
    return b
end

--- Private: Builds the fire control status panel.
function GUILib:_buildFireControl(parent)
    local fc = {}
    fc.frame = Create("Frame", { Name = "FireControl", Parent = parent, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -80), Size = UDim2.fromOffset(240, 110), BackgroundColor3 = GUILib.Theme.Background, BackgroundTransparency = 0.2, BorderSizePixel = 0, Children = { Create("UIStroke", {Color = GUILib.Theme.Accent}), Create("UICorner", {CornerRadius = UDim.new(0, 4)}), Create("UIPadding", {PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,5)}), Create("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}) }})
    Create("TextLabel", { Parent = fc.frame, LayoutOrder = 1, Size = UDim2.new(1,0,0,20), Font = Enum.Font.SourceSansSemibold, TextSize = 16, TextColor3 = GUILib.Theme.Accent, Text = "FIRE CONTROL", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
    fc.statusLabel = Create("TextLabel", { Parent = fc.frame, LayoutOrder = 2, Size = UDim2.new(1,0,0,18), Font = Enum.Font.SourceSans, TextSize = 16, TextColor3 = GUILib.Theme.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
    fc.modeLabel = Create("TextLabel", { Parent = fc.frame, LayoutOrder = 3, Size = UDim2.new(1,0,0,18), Font = Enum.Font.SourceSans, TextSize = 16, TextColor3 = GUILib.Theme.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
    fc.targetLabel = Create("TextLabel", { Parent = fc.frame, LayoutOrder = 4, Size = UDim2.new(1,0,0,18), Font = Enum.Font.SourceSans, TextSize = 16, TextColor3 = GUILib.Theme.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
    fc.footer = Create("TextLabel", { Name = "Footer", Parent = fc.frame, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.new(1,0,0,16), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = GUILib.Theme.Accent, Text = "AEGIS MK.IV", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right })
    return fc
end

--- Private: Builds the radar/tactical grid.
function GUILib:_buildRadar(parent)
    local r = {}
    -- [FIX] Adjusted Y position to avoid overlap with default game UI.
    r.panel = Create("Frame", { Name = "RadarPanel", Parent = parent, AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-10,0,40), Size = UDim2.fromOffset(RADAR_DIAMETER+20, RADAR_DIAMETER+40), BackgroundColor3 = GUILib.Theme.Background, BackgroundTransparency = 0.2, BorderSizePixel = 0, Children = { Create("UIStroke", {Color = GUILib.Theme.Accent}), Create("UICorner", {CornerRadius = UDim.new(0, 4)}) }})
    Create("TextLabel", { Parent = r.panel, Position = UDim2.new(0,10,0,5), Size = UDim2.new(1,-20,0,20), Font = Enum.Font.SourceSansSemibold, TextSize = 16, TextColor3 = GUILib.Theme.Accent, Text = "TACTICAL GRID", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
    r.frame = Create("Frame", { Name = "RadarDisplay", Parent = r.panel, AnchorPoint = Vector2.new(0.5,0), Position = UDim2.new(0.5,0,0,30), Size = UDim2.fromOffset(RADAR_DIAMETER, RADAR_DIAMETER), BackgroundColor3 = GUILib.Theme.Primary, BackgroundTransparency = 0.3, ClipsDescendants = true, Children = { Create("UICorner", {CornerRadius = UDim.new(1, 0)}), Create("UIStroke", {Color = GUILib.Theme.Accent}) }})
    r.north = Create("TextLabel", { Name = "NorthIndicator", Parent = r.frame, AnchorPoint = Vector2.new(0.5,0.5), Size = UDim2.fromOffset(20,20), Font = Enum.Font.SourceSans, TextSize = 16, TextColor3 = GUILib.Theme.Enemy, Text = "N", ZIndex = 2, BackgroundTransparency = 1 })
    r.coords = Create("TextLabel", { Name = "Coordinates", Parent = r.panel, AnchorPoint = Vector2.new(0.5,1), Position = UDim2.new(0.5,0,1,-5), Size = UDim2.new(1,0,0,20), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = GUILib.Theme.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center })
    return r
end

--- Private: Builds the target telemetry panel.
function GUILib:_buildTelemetry(parent)
    local t = {}
    t.frame = Create("Frame", { Name = "TelemetryFrame", Parent = parent, Visible = false, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(280, 130), BackgroundColor3 = GUILib.Theme.Background, BackgroundTransparency = 0.2, BorderSizePixel = 0, Children = { Create("UIStroke", {Color = GUILib.Theme.Accent}), Create("UICorner", {CornerRadius = UDim.new(0, 4)}), Create("UIPadding", {PaddingLeft=UDim.new(0,10), PaddingTop=UDim.new(0,10), PaddingRight=UDim.new(0,10)}), Create("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}) }})
    Create("TextLabel", { Parent = t.frame, LayoutOrder = 1, Size = UDim2.new(1,0,0,20), Font = Enum.Font.SourceSansSemibold, TextSize = 16, TextColor3 = GUILib.Theme.Accent, Text = "TARGET TELEMETRY", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
    
    -- [FIX] Restructured health bar elements into a proper horizontal frame.
    local healthFrame = Create("Frame", { Parent = t.frame, LayoutOrder = 2, Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Children = {Create("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, VerticalAlignment=Enum.VerticalAlignment.Center, Padding=UDim.new(0,5)})} })
    Create("TextLabel", { Parent = healthFrame, Size=UDim2.fromOffset(60,20), Text="HEALTH", Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = GUILib.Theme.Text, BackgroundTransparency = 1 })
    local healthBG = Create("Frame", { Parent = healthFrame, Size=UDim2.new(1,-70,0,12), BackgroundColor3=GUILib.Theme.Primary, BorderSizePixel=0, Children = {Create("UICorner", {CornerRadius = UDim.new(1,0)})} })
    t.healthBar = Create("Frame", { Parent = healthBG, Size=UDim2.new(1,0,1,0), BackgroundColor3=GUILib.Theme.Self, BorderSizePixel=0, Children = {Create("UICorner", {CornerRadius = UDim.new(1,0)})} })
    
    t.distanceLabel = Create("TextLabel", { Parent = t.frame, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = GUILib.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left })
    t.speedLabel = Create("TextLabel", { Parent = t.frame, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = GUILib.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left })
    t.classLabel = Create("TextLabel", { Parent = t.frame, LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = GUILib.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left })
    return t
end

--- Builds the entire DNCG interface.
function GUILib:Build(services)
    local CoreGuiService = services.CoreGuiService
    if CoreGuiService:FindFirstChild("DNCG_HUD") then CoreGuiService.DNCG_HUD:Destroy() end

    local mainGui = Create("ScreenGui", { Name = "DNCG_HUD", Parent = CoreGuiService, ResetOnSpawn = false })
    
    self.Elements = {
        mainGui = mainGui,
        bottomBar = self:_buildBottomBar(mainGui),
        fc = self:_buildFireControl(mainGui),
        radar = self:_buildRadar(mainGui),
        telemetry = self:_buildTelemetry(mainGui),
        draw = {} 
    }
    print("DNCG GUI Library Initialized and Built.")
    return self
end

--- Updates the UI elements with new data from the main kernel.
function GUILib:Update(state)
    if not self.Elements then return end
    local E = self.Elements
    
    E.fc.statusLabel.Text = state.enabled and "SYSTEM: ONLINE" or "SYSTEM: OFFLINE"
    E.fc.statusLabel.TextColor3 = state.enabled and self.Theme.Self or self.Theme.Enemy
    E.fc.modeLabel.Text = "MODE: " .. (state.mode or "UNKNOWN")
    E.fc.targetLabel.Text = "TARGET: " .. (state.targetName or "NONE")

    if state.myPos and state.camCF then
        E.radar.coords.Text = string.format("X: %.0f // Y: %.0f // Z: %.0f", state.myPos.X, state.myPos.Y, state.myPos.Z)
        local northVec = state.camCF:VectorToObjectSpace(Vector3.new(0,0,-1))
        local radius = E.radar.frame.AbsoluteSize.X / 2
        E.radar.north.Position = UDim2.new(0.5, northVec.X * radius, 0.5, -northVec.Z * radius)
    end
    
    local hasTarget = state.targetName and state.targetName ~= "NONE"
    E.telemetry.frame.Visible = hasTarget
    if hasTarget then
        E.telemetry.healthBar.Size = UDim2.new(state.targetHealth or 0, 0, 1, 0)
        E.telemetry.distanceLabel.Text = string.format("DISTANCE: %.0f STUDS", state.targetDist or 0)
        E.telemetry.speedLabel.Text = string.format("SPEED: %.1f STUDS/S", state.targetSpeed or 0)
        E.telemetry.classLabel.Text = "CLASS: " .. (state.targetClass or "UNKNOWN"):upper()
    end
    
    if state.userRank then
        E.bottomBar.userRankLabel.Text = state.userRank
    end
end

return GUILib
