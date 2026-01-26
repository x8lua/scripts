--[[
    Advanced Notification Library (Sound Support Edition)
    Font: Code | Black Stroke | Custom Sounds
]]

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

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
container.Name = "Container"
container.Size = UDim2.new(0.9, 0, 0.5, 0)
container.Position = UDim2.new(0.5, 0, 0.55, 0) -- 你的位置設定 (0.55)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundTransparency = 1
container.Parent = gui

local layout = Instance.new("UIListLayout")
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = container

-- 音效處理函數
local function playNotifySound(soundId)
    if not soundId or soundId == "" then return end
    local s = Instance.new("Sound")
    s.SoundId = (type(soundId) == "number") and ("rbxassetid://" .. soundId) or soundId
    s.Volume = 0.5
    s.Parent = game:GetService("SoundService")
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

function Lib:Notify(config)
    local cfg = type(config) == "table" and config or {Text = tostring(config)}
    
    local text = cfg.Text or "No Text"
    local font = cfg.Font or Enum.Font.Code
    local size = cfg.Size or 55 -- 你的大字體設定
    local duration = cfg.Duration or 3
    local fadeInTime = cfg.FadeIn or 0.2
    local fadeOutTime = cfg.FadeOut or 0.2
    local textColor = cfg.Color or Color3.fromRGB(255, 255, 255)
    
    -- 音效參數
    local fadeInSound = cfg.FadeInSound or nil
    local fadeOutSound = cfg.FadeOutSound or nil

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, size + 15)
    label.BackgroundTransparency = 1
    label.Font = font
    label.Text = text
    label.TextColor3 = textColor
    label.TextSize = size
    label.TextTransparency = 1
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- 黑色描邊
    label.TextStrokeTransparency = 1 
    label.Parent = container

    -- 淡入
    playNotifySound(fadeInSound)
    TweenService:Create(label, TweenInfo.new(fadeInTime), {
        TextTransparency = 0,
        TextStrokeTransparency = 0.5
    }):Play()

    -- 延遲淡出
    task.delay(duration, function()
        playNotifySound(fadeOutSound)
        local fadeOut = TweenService:Create(label, TweenInfo.new(fadeOutTime), {
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
