-- Roblox Notification Library for Executors
-- Font: Code | Fade: 0.2s | Optimized Position & Size

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- 清理舊執行紀錄
if getgenv()._NotifyLibInstance then
    getgenv()._NotifyLibInstance:Destroy()
end

local Lib = {}

-- 建立 UI
local gui = Instance.new("ScreenGui")
gui.Name = "CustomNotifyGui"
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
gui.Parent = CoreGui
getgenv()._NotifyLibInstance = gui

-- 容器：位置稍微上移 (0.7)
local container = Instance.new("Frame")
container.Name = "NotifyContainer"
container.Size = UDim2.new(0.6, 0, 0.4, 0)
container.Position = UDim2.new(0.5, 0, 0.7, 0) -- 0.7 比之前的 0.75 更靠上方一點
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundTransparency = 1
container.Parent = gui

local layout = Instance.new("UIListLayout")
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 10) -- 增加間距以配合較大的字體
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = container

function Lib:Notify(config)
    local text = type(config) == "table" and config.Text or tostring(config)
    local duration = type(config) == "table" and config.Duration or 3
    
    local label = Instance.new("TextLabel")
    label.Name = "Notification"
    label.Size = UDim2.new(1, 0, 0, 40) -- 增加高度以容納大字體
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 28 -- 增加字體大小 (原為 18-20)
    label.TextTransparency = 1
    label.TextStrokeTransparency = 0.7 -- 稍微加強描邊，讓大字體更清晰
    label.Parent = container

    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    
    -- Fade In
    TweenService:Create(label, tweenInfo, {
        TextTransparency = 0, 
        TextStrokeTransparency = 0.7
    }):Play()

    -- Fade Out & Destroy
    task.delay(duration, function()
        local fadeOut = TweenService:Create(label, tweenInfo, {
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
