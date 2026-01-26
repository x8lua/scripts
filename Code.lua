--[[
    Advanced Notification Library (Customizable)
    Optimized for Executors | Font: Code | Middle-Upper Pos
]]

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- 清理舊實例
if getgenv()._CodeNotifyLib then
    getgenv()._CodeNotifyLib:Destroy()
end

local Lib = {}

-- 建立主 UI
local gui = Instance.new("ScreenGui")
gui.Name = "CodeNotifyLib"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = CoreGui
getgenv()._CodeNotifyLib = gui

-- 容器：位置在 0.55 (螢幕中段偏下)
local container = Instance.new("Frame")
container.Name = "Container"
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

-- 預設設定
local DEFAULTS = {
    Font = Enum.Font.Code,
    Size = 55,
    Duration = 3,
    FadeIn = 0.2,
    FadeOut = 0.2,
    Color = Color3.fromRGB(255, 255, 255)
}

function Lib:Notify(config)
    -- 支援字串或 Table 傳入
    local cfg = type(config) == "table" and config or {Text = tostring(config)}
    
    local text = cfg.Text or "No Text Provided"
    local font = cfg.Font or DEFAULTS.Font
    local size = cfg.Size or DEFAULTS.Size
    local duration = cfg.Duration or DEFAULTS.Duration
    local fadeInTime = cfg.FadeIn or DEFAULTS.FadeIn
    local fadeOutTime = cfg.FadeOut or DEFAULTS.FadeOut
    local textColor = cfg.Color or DEFAULTS.Color

    local label = Instance.new("TextLabel")
    label.Name = "Notify_" .. tick()
    label.Size = UDim2.new(1, 0, 0, size + 10)
    label.BackgroundTransparency = 1
    label.Font = font
    label.Text = text
    label.TextColor3 = textColor
    label.TextSize = size
    label.TextTransparency = 1
    -- 黑色描邊設定
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 1 
    label.Parent = container

    -- 淡入動畫 (0.2s 預設)
    local fadeIn = TweenService:Create(label, TweenInfo.new(fadeInTime, Enum.EasingStyle.Quad), {
        TextTransparency = 0,
        TextStrokeTransparency = 0 -- 顯示黑色描邊
    })
    fadeIn:Play()

    -- 延遲後淡出
    task.delay(duration, function()
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
