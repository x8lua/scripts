--[[
    Notification Library (Final Fix)
    - Fix: SoundId Assignment Error
    - Volume Default: 2
    - Font: Code (Default)
    - Position: 0.55
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

-- 修正音效函數：先提取 ID 再賦值給 SoundId
local function playSound(soundData)
    if not soundData then return end
    
    local rawId, vol
    if type(soundData) == "table" then
        rawId = soundData[1]
        vol = soundData[2] or 2
    else
        rawId = soundData
        vol = 2
    end

    if not rawId or rawId == "" then return end
    
    -- 確保轉為 rbxassetid 字串格式
    local idString = (type(rawId) == "number") and ("rbxassetid://" .. rawId) or tostring(rawId)
    
    local s = Instance.new("Sound")
    s.SoundId = idString -- 現在這裡傳入的是字串，不會再噴 table error
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
