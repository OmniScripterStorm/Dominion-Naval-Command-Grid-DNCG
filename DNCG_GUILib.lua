-- ============================================================================ --
-- =                Dominion Naval Command Grid - GUI Library                 = --
-- ============================================================================ --
-- This library contains all the functions and data required to build the DNCG  --
-- user interface.                                                              --
-- ============================================================================ --

local GuiLib = {}

-- // UI STATE
local UI = nil

function GuiLib:Build(config)
    -- Define Services locally inside the function to prevent nil upvalues
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")

    -- Cleanup old UI
    if CoreGui:FindFirstChild("DNCG_V3") then 
        CoreGui.DNCG_V3:Destroy() 
    elseif Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui") and Players.LocalPlayer.PlayerGui:FindFirstChild("DNCG_V3") then
        Players.LocalPlayer.PlayerGui.DNCG_V3:Destroy()
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "DNCG_V3"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    
    -- // MAIN FRAME
    local main = Instance.new("Frame", sg)
    main.Name = "HUD"
    main.Size = UDim2.new(1, 0, 1, 0)
    main.BackgroundTransparency = 1
    
    -- // TELEMETRY BAR (Bottom Center)
    local tele = Instance.new("Frame", main)
    tele.Name = "Telemetry"
    tele.Size = UDim2.new(0, 400, 0, 60)
    tele.Position = UDim2.new(0.5, -200, 0.85, 0)
    tele.BackgroundColor3 = Color3.fromRGB(10, 15, 20)
    tele.BackgroundTransparency = 0.2
    tele.BorderSizePixel = 0
    Instance.new("UICorner", tele).CornerRadius = UDim.new(0, 8)
    
    -- Target Name
    local tName = Instance.new("TextLabel", tele)
    tName.Name = "TargetName"
    tName.Size = UDim2.new(1, -20, 0, 25)
    tName.Position = UDim2.new(0, 10, 0, 5)
    tName.BackgroundTransparency = 1
    tName.Text = "WAITING FOR LOCK..."
    tName.TextColor3 = Color3.fromRGB(0, 245, 212) -- Cyan
    tName.Font = Enum.Font.GothamBold
    tName.TextSize = 16
    tName.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Stats
    local tStats = Instance.new("TextLabel", tele)
    tStats.Name = "Stats"
    tStats.Size = UDim2.new(1, -20, 0, 20)
    tStats.Position = UDim2.new(0, 10, 0, 30)
    tStats.BackgroundTransparency = 1
    tStats.Text = "DIST: 0m | HP: 0%"
    tStats.TextColor3 = Color3.fromRGB(200, 200, 200)
    tStats.Font = Enum.Font.Code
    tStats.TextSize = 14
    tStats.TextXAlignment = Enum.TextXAlignment.Left

    -- Mode Indicator (Top Right)
    local modeF = Instance.new("Frame", main)
    modeF.Size = UDim2.new(0, 150, 0, 30)
    modeF.Position = UDim2.new(1, -160, 0, 50)
    modeF.BackgroundColor3 = Color3.fromRGB(10, 15, 20)
    Instance.new("UICorner", modeF)
    
    local modeL = Instance.new("TextLabel", modeF)
    modeL.Name = "ModeLabel"
    modeL.Size = UDim2.new(1, 0, 1, 0)
    modeL.BackgroundTransparency = 1
    modeL.Text = "MODE: BALLISTIC"
    modeL.TextColor3 = Color3.fromRGB(255, 89, 94) -- Red
    modeL.Font = Enum.Font.GothamBlack
    modeL.TextSize = 14
    
    UI = {
        Main = main,
        NameLbl = tName,
        StatsLbl = tStats,
        ModeLbl = modeL
    }
    
    -- // SAFE MOUNTING LOGIC
    local success, err = pcall(function()
        if config and config.CoreGuiService then
            sg.Parent = config.CoreGuiService
        else
            local lp = Players.LocalPlayer
            if lp then
                sg.Parent = lp:WaitForChild("PlayerGui")
            end
        end
    end)
    
    if not success then warn("DNCG GUI Mount Fail: " .. tostring(err)) end
end

function GuiLib:UpdateTelemetry(name, dist, hp, mode)
    if not UI then return end
    
    -- Update Mode
    if UI.ModeLbl then UI.ModeLbl.Text = "MODE: " .. tostring(mode) end
    
    -- Update Target Info
    if name and name ~= "NONE" then
        if UI.NameLbl then
            UI.NameLbl.Text = "TARGET: " .. name:upper()
            UI.NameLbl.TextColor3 = Color3.fromRGB(255, 89, 94) -- Alert Red
        end
        if UI.StatsLbl then
            UI.StatsLbl.Text = string.format("DIST: %.0f STUDS | HP: %.0f%%", dist, hp * 100)
        end
    else
        if UI.NameLbl then
            UI.NameLbl.Text = "SYSTEM STANDBY"
            UI.NameLbl.TextColor3 = Color3.fromRGB(0, 245, 212) -- Idle Cyan
        end
        if UI.StatsLbl then
            UI.StatsLbl.Text = "SCANNING..."
        end
    end
end

return GuiLib
