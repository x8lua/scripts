-- Roblox Notification Library for Executors
-- Font: Code | Fade: 0.2s | Position: Middle Down

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- 確保不會重複載入導致 UI 重疊
if getgenv()._NotifyLibInstance then
    getgenv()._NotifyLibInstance:Destroy()
end

local Lib = {}

-- 建立頂層 UI
local gui = Instance.new("ScreenGui")
gui.Name = "ExecNotifyGui"
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
gui.Parent = CoreGui
getgenv()._NotifyLibInstance = gui

-- 建立通知容器
local container = Instance.new("Frame")
container.Name = "NotifyContainer"
container.Size = UDim2.new(0.4, 0, 0.4, 0)
container.Position = UDim2.new(0.5, 0, 0.75, 0) -- 畫面中下方
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundTransparency = 1
container.Parent = gui

local layout = Instance.new("UIListLayout")
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = container

-- API 函數
function Lib:Notify(config)
    -- 支援字串傳入或 Table 傳入
    local text = type(config) == "table" and config.Text or tostring(config)
    local duration = type(config) == "table" and config.Duration or 3
    
    local label = Instance.new("TextLabel")
    label.Name = "Notification"
    label.Size = UDim2.new(1, 0, 0, 24)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 18
    label.TextTransparency = 1
    label.TextStrokeTransparency = 0.8
    label.Parent = container

    -- 0.2s Fade In
    local info = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(label, info, {
        TextTransparency = 0, 
        TextStrokeTransparency = 0.8
    }):Play()

    -- 延遲淡出
    task.delay(duration, function()
        local fadeOut = TweenService:Create(label, info, {
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
