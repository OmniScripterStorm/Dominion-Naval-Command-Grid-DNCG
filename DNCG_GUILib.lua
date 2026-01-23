--[[
    AZUREUS MARITIME DOMINION // DNCG GUI LIBRARY (V4 - Refactored)
    Author: 1st Research Group 'Stasis λ'
    Notes: Re-engineered for stability, readability, and maintainability.
]]

local GUILib = {}

--// THEME & CONSTANTS
GUILib.Theme = { Background = Color3.fromHex("0D1B2A"), Primary = Color3.fromHex("1B263B"), Accent = Color3.fromHex("415A77"), Text = Color3.fromHex("E0E1DD"), Enemy = Color3.fromHex("FF595E"), Friendly = Color3.fromHex("80FFDB"), Self = Color3.fromHex("00F5D4"), Locked = Color3.fromHex("9EF01A") }
local RADAR_DIAMETER = 250
-- [CRITICAL FIX] Corrected the full 14-digit Asset ID
local COAT_OF_ARMS_ID = "rbxassetid://73748269312467"

local function Create(class, props) local i = Instance.new(class); for p,v in pairs(props) do if p=="Children" then for _,c in ipairs(v) do c.Parent=i end else i[p]=v end end; return i end

local radarBlipPool = { Active = {}, Inactive = {} }
local function getRadarBlip(parent)
    local blip = table.remove(radarBlipPool.Inactive)
    if not blip then
        blip = Create("Frame", { Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5,0.5), BorderSizePixel = 0, Children = { Create("UICorner", {CornerRadius = UDim.new(1,0)}), Create("UIStroke", {Thickness = 1}) }})
    end
    blip.Parent = parent
    blip.Visible = true
    return blip
end

function GUILib:_buildBottomBar(parent)
    local Players = game:GetService("Players"); local localPlayer = Players.LocalPlayer; local b = {}
    b.frame = Create("Frame", { Name = "BottomBar", Parent = parent, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(0.8, 0, 0, 60), BackgroundColor3 = self.Theme.Background, BackgroundTransparency = 0.2, BorderSizePixel = 0, Children = { Create("UIStroke", {Color = self.Theme.Accent}), Create("UICorner", {CornerRadius = UDim.new(0, 4)}) }})
    b.coatOfArms = Create("ImageLabel", { Name = "CoatOfArms", Parent = b.frame, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Image = COAT_OF_ARMS_ID })
    local textGroup = Create("Frame", { Parent = b.frame, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 60, 0.5, 0), Size = UDim2.new(0, 400, 0, 40), Children = { Create("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Center}) }})
    b.systemNameLabel = Create("TextLabel", { Parent = textGroup, Size = UDim2.new(1, 0, 0, 22), Font = Enum.Font.SourceSansSemibold, TextSize = 20, TextColor3 = self.Theme.Text, Text = "DOMINION NAVAL COMMAND GRID", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
    b.factionNameLabel = Create("TextLabel", { Parent = textGroup, Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = self.Theme.Accent, Text = "AZUREUS MARITIME DOMINION", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
    local userCreds = Create("Frame", { Parent = b.frame, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.new(0, 250, 1, 0), Children = { Create("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right}) }})
    b.userNameLabel = Create("TextLabel", { Parent = userCreds, Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.SourceSansSemibold, TextSize = 18, TextColor3 = self.Theme.Text, Text = localPlayer and localPlayer.DisplayName or "UNKNOWN", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right })
    b.userRankLabel = Create("TextLabel", { Parent = userCreds, Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = self.Theme.Accent, Text = "FETCHING RANK...", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right })
    return b
end

function GUILib:_buildFireControl(parent)
    local fc = {}; fc.frame = Create("Frame", { Name = "FireControl", Parent = parent, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -80), Size = UDim2.fromOffset(240, 110), BackgroundColor3 = self.Theme.Background, BackgroundTransparency = 0.2, Children = { Create("UIStroke", {Color = self.Theme.Accent}), Create("UICorner", {CornerRadius = UDim.new(0, 4)}), Create("UIPadding", {PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,5)}), Create("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}) }}); Create("TextLabel", { Parent = fc.frame, LayoutOrder = 1, Size = UDim2.new(1,0,0,20), Font = Enum.Font.SourceSansSemibold, TextSize = 16, TextColor3 = self.Theme.Accent, Text = "FIRE CONTROL", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left }); fc.statusLabel = Create("TextLabel", { Parent = fc.frame, LayoutOrder = 2, Size = UDim2.new(1,0,0,18), Font = Enum.Font.SourceSans, TextSize = 16, TextColor3 = self.Theme.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left }); fc.modeLabel = Create("TextLabel", { Parent = fc.frame, LayoutOrder = 3, Size = UDim2.new(1,0,0,18), Font = Enum.Font.SourceSans, TextSize = 16, TextColor3 = self.Theme.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left }); fc.targetLabel = Create("TextLabel", { Parent = fc.frame, LayoutOrder = 4, Size = UDim2.new(1,0,0,18), Font = Enum.Font.SourceSans, TextSize = 16, TextColor3 = self.Theme.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left }); fc.footer = Create("TextLabel", { Parent = fc.frame, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.new(1,0,0,16), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = self.Theme.Accent, Text = "AEGIS MK.IV", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right }); return fc
end

function GUILib:_buildRadar(parent)
    local r = {}; r.panel = Create("Frame", { Name = "RadarPanel", Parent = parent, AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-10,0,10), Size = UDim2.fromOffset(RADAR_DIAMETER+20, RADAR_DIAMETER+40), BackgroundColor3 = self.Theme.Background, BackgroundTransparency = 0.2, Children = { Create("UIStroke", {Color = self.Theme.Accent}), Create("UICorner", {CornerRadius = UDim.new(0, 4)}) }}); Create("TextLabel", { Parent = r.panel, Position = UDim2.new(0,10,0,5), Size = UDim2.new(1,-20,0,20), Font = Enum.Font.SourceSansSemibold, TextSize = 16, TextColor3 = self.Theme.Accent, Text = "TACTICAL GRID", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left }); r.frame = Create("Frame", { Name = "RadarDisplay", Parent = r.panel, AnchorPoint = Vector2.new(0.5,0), Position = UDim2.new(0.5,0,0,30), Size = UDim2.fromOffset(RADAR_DIAMETER, RADAR_DIAMETER), BackgroundColor3 = self.Theme.Primary, BackgroundTransparency = 0.3, ClipsDescendants = true, Children = { Create("UICorner", {CornerRadius = UDim.new(1, 0)}), Create("UIStroke", {Color = self.Theme.Accent}) }}); r.north = Create("TextLabel", { Parent = r.frame, AnchorPoint = Vector2.new(0.5,0.5), Size = UDim2.fromOffset(20,20), Font = Enum.Font.SourceSans, TextSize = 16, TextColor3 = self.Theme.Enemy, Text = "N", ZIndex = 2, BackgroundTransparency = 1 }); r.coords = Create("TextLabel", { Parent = r.panel, AnchorPoint = Vector2.new(0.5,1), Position = UDim2.new(0.5,0,1,-5), Size = UDim2.new(1,0,0,20), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = self.Theme.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center }); return r
end

function GUILib:_buildTelemetry(parent)
    local t = {}; t.frame = Create("Frame", { Name = "TelemetryFrame", Parent = parent, Visible = false, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(280, 130), BackgroundColor3 = self.Theme.Background, BackgroundTransparency = 0.2, Children = { Create("UIStroke", {Color = self.Theme.Accent}), Create("UICorner", {CornerRadius = UDim.new(0, 4)}), Create("UIPadding", {PaddingLeft=UDim.new(0,10), PaddingTop=UDim.new(0,10), PaddingRight=UDim.new(0,10)}), Create("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}) }}); Create("TextLabel", { Parent = t.frame, LayoutOrder = 1, Size = UDim2.new(1,0,0,20), Font = Enum.Font.SourceSansSemibold, TextSize = 16, TextColor3 = self.Theme.Accent, Text = "TARGET TELEMETRY", BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left });
    t.healthLabel = Create("TextLabel", { Parent = t.frame, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = self.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left });
    t.distanceLabel = Create("TextLabel", { Parent = t.frame, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = self.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left }); t.speedLabel = Create("TextLabel", { Parent = t.frame, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = self.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left }); t.classLabel = Create("TextLabel", { Parent = t.frame, LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = self.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left }); return t
end

function GUILib:Build(services)
    local CoreGuiService = services.CoreGuiService; if CoreGuiService:FindFirstChild("DNCG_HUD") then CoreGuiService.DNCG_HUD:Destroy() end
    local mainGui = Create("ScreenGui", { Name = "DNCG_HUD", Parent = CoreGuiService, ResetOnSpawn = false }); self.Elements = { mainGui = mainGui, bottomBar = self:_buildBottomBar(mainGui), fc = self:_buildFireControl(mainGui), radar = self:_buildRadar(mainGui), telemetry = self:_buildTelemetry(mainGui), draw = {} }; print("DNCG GUI Library Initialized and Built."); return self
end

function GUILib:Update(state)
    if not self.Elements then return end; local E = self.Elements
    E.fc.statusLabel.Text = state.enabled and "SYSTEM: ONLINE" or "SYSTEM: OFFLINE"; E.fc.statusLabel.TextColor3 = state.enabled and self.Theme.Self or self.Theme.Enemy; E.fc.modeLabel.Text = "MODE: " .. (state.mode or "UNKNOWN"); E.fc.targetLabel.Text = "TARGET: " .. (state.targetName or "NONE")
    
    if state.myPos and state.camCF then
        E.radar.coords.Text = string.format("X: %.0f // Y: %.0f // Z: %.0f", state.myPos.X, state.myPos.Y, state.myPos.Z)
        local northVec = state.camCF:VectorToObjectSpace(Vector3.new(0,0,-1)); local radius = RADAR_DIAMETER / 2; E.radar.north.Position = UDim2.new(0.5, northVec.X * radius, 0.5, -northVec.Z * radius)
        
        -- Radar Blip Drawing Logic
        for _, blip in ipairs(radarBlipPool.Active) do blip.Visible = false; table.insert(radarBlipPool.Inactive, blip) end; table.clear(radarBlipPool.Active)
        if state.radarData then
            for _, target in ipairs(state.radarData) do
                local blip = getRadarBlip(E.radar.frame); table.insert(radarBlipPool.Active, blip)
                local diff = target.Position - state.myPos; local relPos = state.camCF:VectorToObjectSpace(diff)
                local pos2d = Vector2.new(relPos.X, -relPos.Z).Unit * math.min(diff.Magnitude / 1000, 1) * radius
                blip.Position = UDim2.new(0.5, pos2d.X, 0.5, pos2d.Y)
                blip.BackgroundColor3 = self.Theme[target.Type]; blip.UIStroke.Color = self.Theme.Text
            end
        end
    end
    
    local hasTarget = state.targetName and state.targetName ~= "NONE"; E.telemetry.frame.Visible = hasTarget
    if hasTarget then
        E.telemetry.healthLabel.Text = string.format("HEALTH: %.0f%%", (state.targetHealth or 0) * 100)
        E.telemetry.distanceLabel.Text = string.format("DISTANCE: %.0f STUDS", state.targetDist or 0)
        E.telemetry.speedLabel.Text = string.format("SPEED: %.1f STUDS/S", state.targetSpeed or 0)
        E.telemetry.classLabel.Text = "CLASS: " .. (state.targetClass or "UNKNOWN"):upper()
    end
    
    if state.userRank then E.bottomBar.userRankLabel.Text = state.userRank end
end

return GUILib
