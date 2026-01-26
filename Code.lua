--[[
    Advanced Notification Library (Single Line Mode Support)
    - Feature: cfg.SingleLine (Boolean)
    - Feature: Smaller Spacing (Padding = 2)
    - Position: 0.55 | Font: Code
]]

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

if getgenv()._CodeNotifyLib then
    getgenv()._CodeNotifyLib:Destroy()
end

local Lib = {}

local gui = Instance.new("ScreenGui")
gui.Name = "CodeNotifyLib"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = CoreGui
getgenv()._CodeNotifyLib = gui

local container = Instance.new("Frame")
container.Name = "NotifyContainer"
container.Size = UDim2.new(0.9, 0, 0.5, 0)
container.Position = UDim2.new(0.5, 0, 0.55, 0) 
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundTransparency = 1
container.Parent = gui

local layout = Instance.new("UIListLayout")
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 2) -- 縮小間距
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = container

local function playSound(soundData)
    if not soundData then return end
    local idToUse, volumeToUse = nil, 2
    if type(soundData) == "table" then
        idToUse = soundData[1]
        volumeToUse = soundData[2] or 2
    else
        idToUse = soundData
    end
    if not idToUse or idToUse == "" then return end
    local finalId = (type(idToUse) == "number") and ("rbxassetid://" .. idToUse) or tostring(idToUse)
    local s = Instance.new("Sound")
    s.SoundId = finalId
    s.Volume = volumeToUse
    s.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    if not s.IsLoaded then task.spawn(function() s.Loaded:Wait() s:Play() end) else s:Play() end
    s.Ended:Connect(function() s:Destroy() end)
end

function Lib:Notify(config)
    local cfg = type(config) == "table" and config or {Text = tostring(config)}
    
    -- 單行模式邏輯：如果開啟，先清除現有的所有通知
    if cfg.SingleLine then
        for _, child in pairs(container:GetChildren()) do
            if child:IsA("TextLabel") then
                -- 快速淡出並刪除
                TweenService:Create(child, TweenInfo.new(0.15), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
                task.delay(0.15, function() child:Destroy() end)
            end
        end
    end

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, (cfg.Size or 55) + 5)
    label.BackgroundTransparency = 1
    label.Font = cfg.Font or Enum.Font.Code
    label.Text = cfg.Text or "No Text"
    label.TextColor3 = cfg.Color or Color3.fromRGB(255, 255, 255)
    label.TextSize = cfg.Size or 55
    label.TextTransparency = 1
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 1 
    label.Parent = container

    task.spawn(playSound, cfg.FadeInSound)
    TweenService:Create(label, TweenInfo.new(0.2), {TextTransparency = 0, TextStrokeTransparency = 0.5}):Play()

    task.delay(cfg.Duration or 3, function()
        if label and label.Parent then
            task.spawn(playSound, cfg.FadeOutSound)
            local out = TweenService:Create(label, TweenInfo.new(0.2), {TextTransparency = 1, TextStrokeTransparency = 1})
            out:Play()
            out.Completed:Connect(function() label:Destroy() end)
        end
    end)
end

return Lib
