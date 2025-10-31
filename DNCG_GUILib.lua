-- ============================================================================ --
-- =                Dominion Naval Command Grid - GUI Library                 = --
-- ============================================================================ --
-- This library contains all the functions and data required to build the DNCG  --
-- user interface.                                                              --
-- ============================================================================ --

local GUILib = {}

--// DNCG Theme
local THEME = {
    Background = Color3.fromHex("0D1B2A"), Primary = Color3.fromHex("1B263B"), Accent = Color3.fromHex("415A77"),
    Text = Color3.fromHex("E0E1DD"), Enemy = Color3.fromHex("FF595E"), Friendly = Color3.fromHex("80FFDB"),
    Self = Color3.fromHex("00F5D4"), Locked = Color3.fromHex("9EF01A")
}

--// Radar Configuration
local RADAR_DIAMETER = 250
local RADAR_RADIUS = RADAR_DIAMETER / 2

--// Private helper function for styling text labels.
local function styleText(label, size)
    label.Font = Enum.Font.SourceSans
    label.TextSize = size or 16
    label.TextColor3 = THEME.Text
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

--- Builds and returns the entire DNCG interface.
-- @param services A table containing necessary game services like CoreGuiService.
-- @return The GUILib instance, now populated with .Elements and .Theme tables.
function GUILib:Build(services)
    local CoreGuiService = services.CoreGuiService
    local localPlayer = services.PlayersService.LocalPlayer

    local GUI = {}

    -- Main ScreenGui container
    GUI.mainGui = Instance.new("ScreenGui", CoreGuiService)
    GUI.mainGui.Name = "DNCG_HUD"
    GUI.mainGui.ResetOnSpawn = false

    -- [ BOTTOM BAR ]
    GUI.bottomBar = {}
    local b = GUI.bottomBar
    b.frame = Instance.new("Frame", GUI.mainGui); b.frame.Name = "BottomBar"; b.frame.AnchorPoint = Vector2.new(0.5, 1); b.frame.Position = UDim2.new(0.5, 0, 1, -10); b.frame.Size = UDim2.new(0.8, 0, 0, 60); b.frame.BackgroundColor3 = THEME.Background; b.frame.BackgroundTransparency = 0.2; b.frame.BorderSizePixel = 0; Instance.new("UIStroke", b.frame).Color = THEME.Accent; Instance.new("UICorner", b.frame).CornerRadius = UDim.new(0, 4)
    b.coatOfArms = Instance.new("ImageLabel", b.frame); b.coatOfArms.Name = "CoatOfArms"; b.coatOfArms.AnchorPoint = Vector2.new(0, 0.5); b.coatOfArms.Position = UDim2.new(0, 10, 0.5, 0); b.coatOfArms.Size = UDim2.fromOffset(40, 40); b.coatOfArms.BackgroundTransparency = 1; b.coatOfArms.Image = "rbxassetid://73748269312467"
    local systemTextGroup = Instance.new("Frame", b.frame); systemTextGroup.Name = "TextGroup"; systemTextGroup.BackgroundTransparency = 1; systemTextGroup.AnchorPoint = Vector2.new(0, 0.5); systemTextGroup.Position = UDim2.new(0, 60, 0.5, 0); systemTextGroup.Size = UDim2.new(0, 400, 0, 40); local systemTextLayout = Instance.new("UIListLayout", systemTextGroup); systemTextLayout.FillDirection, systemTextLayout.VerticalAlignment, systemTextLayout.Padding = Enum.FillDirection.Vertical, Enum.VerticalAlignment.Center, UDim.new(0, 0)
    b.systemNameLabel = styleText(Instance.new("TextLabel", systemTextGroup), 20); b.systemNameLabel.Name = "SystemName"; b.systemNameLabel.Text = "DOMINION NAVAL COMMAND GRID"; b.systemNameLabel.Font, b.systemNameLabel.TextColor3 = Enum.Font.SourceSansSemibold, THEME.Text; b.systemNameLabel.Size = UDim2.new(1, 0, 0, 22)
    b.factionNameLabel = styleText(Instance.new("TextLabel", systemTextGroup), 14); b.factionNameLabel.Name = "FactionName"; b.factionNameLabel.Text = "AZUREUS MARITIME DOMINION"; b.factionNameLabel.TextColor3 = THEME.Accent; b.factionNameLabel.Size = UDim2.new(1, 0, 0, 16)
    local userCredsFrame = Instance.new("Frame", b.frame); userCredsFrame.Name = "UserCreds"; userCredsFrame.BackgroundTransparency = 1; userCredsFrame.AnchorPoint = Vector2.new(1, 0.5); userCredsFrame.Position = UDim2.new(1, -15, 0.5, 0); userCredsFrame.Size = UDim2.new(0, 250, 1, 0); local userCredsLayout = Instance.new("UIListLayout", userCredsFrame); userCredsLayout.FillDirection, userCredsLayout.VerticalAlignment, userCredsLayout.HorizontalAlignment, userCredsLayout.Padding = Enum.FillDirection.Vertical, Enum.VerticalAlignment.Center, Enum.HorizontalAlignment.Right, UDim.new(0,0)
    b.userNameLabel = styleText(Instance.new("TextLabel", userCredsFrame), 18); b.userNameLabel.TextXAlignment = Enum.TextXAlignment.Right; b.userNameLabel.Text = localPlayer.DisplayName; b.userNameLabel.Font = Enum.Font.SourceSansSemibold; b.userNameLabel.Size = UDim2.new(1, 0, 0, 20)
    b.userRankLabel = styleText(Instance.new("TextLabel", userCredsFrame), 14); b.userRankLabel.TextXAlignment = Enum.TextXAlignment.Right; b.userRankLabel.TextColor3 = THEME.Accent; b.userRankLabel.Text = "FETCHING RANK..."; b.userRankLabel.Size = UDim2.new(1, 0, 0, 16)

    -- [ FIRE CONTROL PANEL ]
    GUI.fc = {}; local fc = GUI.fc; fc.frame = Instance.new("Frame", GUI.mainGui); fc.frame.AnchorPoint, fc.frame.Position, fc.frame.Size = Vector2.new(1, 1), UDim2.new(1, -10, 1, -80), UDim2.fromOffset(240, 110); fc.frame.BackgroundColor3, fc.frame.BackgroundTransparency, fc.frame.BorderSizePixel = THEME.Background, 0.2, 0; Instance.new("UIStroke", fc.frame).Color = THEME.Accent; Instance.new("UICorner", fc.frame).CornerRadius = UDim.new(0, 4)
    local fcPadding = Instance.new("UIPadding", fc.frame); fcPadding.PaddingLeft, fcPadding.PaddingTop, fcPadding.PaddingRight, fcPadding.PaddingBottom = UDim.new(0,10), UDim.new(0,10), UDim.new(0,10), UDim.new(0,5); local fcLayout = Instance.new("UIListLayout", fc.frame); fcLayout.Padding, fcLayout.SortOrder = UDim.new(0, 2), Enum.SortOrder.LayoutOrder
    fc.title = styleText(Instance.new("TextLabel", fc.frame), 16); fc.statusLabel = styleText(Instance.new("TextLabel", fc.frame)); fc.modeLabel = styleText(Instance.new("TextLabel", fc.frame)); fc.targetLabel = styleText(Instance.new("TextLabel", fc.frame)); fc.title.LayoutOrder, fc.title.Text, fc.title.TextColor3, fc.title.Font, fc.title.Size = 1, "FIRE CONTROL", THEME.Accent, Enum.Font.SourceSansSemibold, UDim2.new(1,0,0,20); fc.statusLabel.LayoutOrder, fc.modeLabel.LayoutOrder, fc.targetLabel.LayoutOrder = 2, 3, 4; for _, label in ipairs({fc.statusLabel, fc.modeLabel, fc.targetLabel}) do label.Size = UDim2.new(1, 0, 0, 18) end
    fc.footer = styleText(Instance.new("TextLabel", fc.frame), 14); fc.footer.Name, fc.footer.AnchorPoint, fc.footer.Position = "Footer", Vector2.new(1, 1), UDim2.new(1, 0, 1, 0); fc.footer.Size, fc.footer.Text, fc.footer.TextXAlignment, fc.footer.TextColor3 = UDim2.new(1,0,0,16), "AEGIS MK.IV", Enum.TextXAlignment.Right, THEME.Accent

    -- [ RADAR PANEL ]
    GUI.radar = {}; local r = GUI.radar; r.panel = Instance.new("Frame", GUI.mainGui); r.panel.AnchorPoint, r.panel.Position, r.panel.Size = Vector2.new(1,0), UDim2.new(1,-10,0,10), UDim2.fromOffset(RADAR_DIAMETER+20, RADAR_DIAMETER+40); r.panel.BackgroundColor3, r.panel.BackgroundTransparency, r.panel.BorderSizePixel = THEME.Background, 0.2, 0; Instance.new("UIStroke", r.panel).Color = THEME.Accent; Instance.new("UICorner", r.panel).CornerRadius = UDim.new(0, 4)
    r.title = styleText(Instance.new("TextLabel", r.panel)); r.title.Position, r.title.Text, r.title.TextColor3, r.title.Font = UDim2.new(0,10,0,5), "TACTICAL GRID", THEME.Accent, Enum.Font.SourceSansSemibold; r.frame = Instance.new("Frame", r.panel); r.frame.AnchorPoint, r.frame.Position, r.frame.Size = Vector2.new(0.5,0), UDim2.new(0.5,0,0,30), UDim2.fromOffset(RADAR_DIAMETER, RADAR_DIAMETER); r.frame.BackgroundColor3, r.frame.BackgroundTransparency, r.frame.ClipsDescendants = THEME.Primary, 0.3, true; Instance.new("UICorner", r.frame).CornerRadius = UDim.new(1, 0); Instance.new("UIStroke", r.frame).Color = THEME.Accent
    r.north = styleText(Instance.new("TextLabel", r.frame)); r.north.AnchorPoint, r.north.Size, r.north.TextColor3, r.north.Text, r.north.ZIndex = Vector2.new(0.5,0.5), UDim2.fromOffset(20,20), THEME.Enemy, "N", 2; r.coords = styleText(Instance.new("TextLabel", GUI.mainGui)); r.coords.AnchorPoint, r.coords.Position, r.coords.Size = Vector2.new(1,0), UDim2.new(1,-10,0,RADAR_DIAMETER+55), UDim2.fromOffset(RADAR_DIAMETER+20, 20); r.coords.TextXAlignment = Enum.TextXAlignment.Center

    -- [ TELEMETRY PANEL ]
    GUI.telemetry = {}; local t = GUI.telemetry; t.frame = Instance.new("Frame", GUI.mainGui); t.frame.Name = "TelemetryFrame"; t.frame.Visible = false; t.frame.AnchorPoint = Vector2.new(0, 0.5); t.frame.Position = UDim2.new(0, 10, 0.5, 0); t.frame.Size = UDim2.fromOffset(280, 130); t.frame.BackgroundColor3 = THEME.Background; t.frame.BackgroundTransparency = 0.2; t.frame.BorderSizePixel = 0; Instance.new("UIStroke", t.frame).Color = THEME.Accent; Instance.new("UICorner", t.frame).CornerRadius = UDim.new(0, 4); local tPadding = Instance.new("UIPadding", t.frame); tPadding.PaddingLeft, tPadding.PaddingTop, tPadding.PaddingRight = UDim.new(0,10), UDim.new(0,10), UDim.new(0,10); local tLayout = Instance.new("UIListLayout", t.frame); tLayout.Padding = UDim.new(0, 2); tLayout.SortOrder = Enum.SortOrder.LayoutOrder
    t.title = styleText(Instance.new("TextLabel", t.frame), 16); t.title.Text, t.title.TextColor3, t.title.Font = "TARGET TELEMETRY", THEME.Accent, Enum.Font.SourceSansSemibold; t.title.LayoutOrder = 1; t.title.Size = UDim2.new(1, 0, 0, 20)
    local healthFrame = Instance.new("Frame", t.frame); healthFrame.Size=UDim2.new(1,0,0,20); healthFrame.BackgroundTransparency=1; healthFrame.LayoutOrder = 2; local healthLayout = Instance.new("UIListLayout", healthFrame); healthLayout.FillDirection=Enum.FillDirection.Horizontal; healthLayout.VerticalAlignment=Enum.VerticalAlignment.Center; healthLayout.Padding=UDim.new(0,5); local healthLabel = styleText(Instance.new("TextLabel", healthFrame), 14); healthLabel.Size=UDim2.fromOffset(60,20); healthLabel.Text="HEALTH"; local healthBarBG = Instance.new("Frame", healthFrame); healthBarBG.Size=UDim2.new(1,-70,0,12); healthBarBG.BackgroundColor3=THEME.Primary; healthBarBG.BorderSizePixel=0; Instance.new("UICorner", healthBarBG).CornerRadius = UDim.new(1,0)
    t.healthBar = Instance.new("Frame", healthBarBG); t.healthBar.Size=UDim2.new(1,0,1,0); t.healthBar.BackgroundColor3=THEME.Self; t.healthBar.BorderSizePixel=0; Instance.new("UICorner", t.healthBar).CornerRadius = UDim.new(1,0)
    t.distanceLabel = styleText(Instance.new("TextLabel", t.frame), 14); t.distanceLabel.Text = "DISTANCE: ..."; t.distanceLabel.LayoutOrder = 3; t.distanceLabel.Size = UDim2.new(1, 0, 0, 18); t.speedLabel = styleText(Instance.new("TextLabel", t.frame), 14); t.speedLabel.Text = "SPEED: ..."; t.speedLabel.LayoutOrder = 4; t.speedLabel.Size = UDim2.new(1, 0, 0, 18); t.classLabel = styleText(Instance.new("TextLabel", t.frame), 14); t.classLabel.Text = "CLASS: ..."; t.classLabel.LayoutOrder = 5; t.classLabel.Size = UDim2.new(1, 0, 0, 18)

    -- [ DRAWING OBJECTS ]
    GUI.draw = {}; local d = GUI.draw
    d.acquisitionCircle = Drawing.new("Circle"); d.acquisitionCircle.Thickness, d.acquisitionCircle.NumSides, d.acquisitionCircle.Filled = 2, 32, false; d.acquisitionCircle.Visible, d.acquisitionCircle.Radius, d.acquisitionCircle.Color = false, 30, THEME.Enemy
    d.acquisitionCross = {Drawing.new("Line"), Drawing.new("Line")}; for _, line in ipairs(d.acquisitionCross) do line.Visible, line.Thickness, line.Color = false, 2, THEME.Enemy end
    d.lockOnBrackets = {}; for i = 1, 8 do d.lockOnBrackets[i] = Drawing.new("Line"); d.lockOnBrackets[i].Visible, d.lockOnBrackets[i].Thickness, d.lockOnBrackets[i].Color = false, 3, THEME.Locked end
    d.leadIndicator = Drawing.new("Line"); d.leadIndicator.Visible, d.leadIndicator.Thickness, d.leadIndicator.Color = false, 2, THEME.Friendly

    -- Assign the fully built GUI and Theme tables to the library instance for access.
    self.Elements = GUI
    self.Theme = THEME

    print("DNCG GUI Library Initialized and Built.")
    return self -- Return the library instance
end
return GUILib
