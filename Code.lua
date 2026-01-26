--[[
    Advanced Notification Library
    - Font: Enum.Font.Code (Default)
    - Fade: 0.2s (Default)
    - Position: 0.55 (Middle-Upper)
    - Features: Black Stroke, Sound Support, Fully Customizable per Notify
]]

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- 自動清理舊 UI
if getgenv()._CodeNotifyLib then
    getgenv()._CodeNotifyLib:Destroy()
end

local Lib = {}

-- 建立 ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "CodeNotifyLib"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = CoreGui
getgenv()._CodeNotifyLib = gui

-- 容器位置在 0.55
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

-- 播放音效函數
local function playSound(soundId)
    if not soundId or soundId == "" then return end
    local s = Instance.new("Sound")
    s.SoundId = (type(soundId) == "number") and ("rbxassetid://" .. soundId) or soundId
    s.Volume = 0.5
    s.Parent = game:GetService("SoundService")
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

function Lib:Notify(config)
    -- 支援字串或 Table
    local cfg = type(config) == "table" and config or {Text = tostring(config)}
    
    -- 合併參數與預設值
    local text = cfg.Text or "No Text"
    local font = cfg.Font or Enum.Font.Code
    local size = cfg.Size or 55
    local duration = cfg.Duration or 3
    local fadeInTime = cfg.FadeIn or 0.2
    local fadeOutTime = cfg.FadeOut or 0.2
    local textColor = cfg.Color or Color3.fromRGB(255, 255, 255)
    local inSound = cfg.FadeInSound or nil
    local outSound = cfg.FadeOutSound or nil

    -- 創建標籤
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

    -- 淡入動畫與音效
    playSound(inSound)
    TweenService:Create(label, TweenInfo.new(fadeInTime, Enum.EasingStyle.Quad), {
        TextTransparency = 0,
        TextStrokeTransparency = 0.5
    }):Play()

    -- 自動淡出
    task.delay(duration, function()
        playSound(outSound)
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
