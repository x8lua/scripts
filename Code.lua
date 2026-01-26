--[[
    Advanced Notification Library (Volume Default: 2)
    - Font: Enum.Font.Code
    - Position: 0.55
    - Features: Custom Sound ID & Volume (Default 2), Black Stroke, 0.2s Fade
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
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = container

-- 支援音量設定的播放函數 (預設音量改為 2)
local function playSound(soundData)
    if not soundData then return end
    
    local id, vol
    if type(soundData) == "table" then
        id = soundData[1]
        vol = soundData[2] or 2 -- 如果 table 沒填音量，預設為 2
    else
        id = soundData
        vol = 2 -- 如果只傳入 ID，預設為 2
    end

    if not id or id == "" then return end
    
    local s = Instance.new("Sound")
    s.SoundId = (type(id) == "number") and ("rbxassetid://" .. id) or id
    s.Volume = vol
    
    local player = Players.LocalPlayer
    s.Parent = player:FindFirstChild("PlayerGui") or (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) or CoreGui
    
    if not s.IsLoaded then s.Loaded:Wait() end
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

function Lib:Notify(config)
    local cfg = type(config) == "table" and config or {Text = tostring(config)}
    
    local text = cfg.Text or "No Text"
    local font = cfg.Font or Enum.Font.Code
    local size = cfg.Size or 55
    local duration = cfg.Duration or 3
    local fadeInTime = cfg.FadeIn or 0.2
    local fadeOutTime = cfg.FadeOut or 0.2
    local textColor = cfg.Color or Color3.fromRGB(255, 255, 255)
    
    local inSound = cfg.FadeInSound
    local outSound = cfg.FadeOutSound

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, size + 15)
    label.BackgroundTransparency = 1
    label.Font = font
    label.Text = text
    label.TextColor3 = textColor
    label.TextSize = size
    label.TextTransparency = 1
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 1 
    label.Parent = container

    -- Fade In
    task.spawn(playSound, inSound)
    TweenService:Create(label, TweenInfo.new(fadeInTime, Enum.EasingStyle.Quad), {
        TextTransparency = 0,
        TextStrokeTransparency = 0.5
    }):Play()

    -- Fade Out
    task.delay(duration, function()
        task.spawn(playSound, outSound)
        local fadeOut = TweenService:Create(label, TweenInfo.new(fadeOutTime, Enum.EasingStyle.Quad), {
            TextTransparency = 1,
            TextStrokeTransparency = 1
        })
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            label:Destroy()
        end)
    end)
end

return Lib
