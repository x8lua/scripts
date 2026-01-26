--[[
    Notification Library (Final Production Version)
    - Fix: ContentId table assignment issue
    - Default Volume: 2
    - Position: 0.55 (Middle-Upper)
    - Font: Enum.Font.Code
    - Animation: 0.2s Fade In/Out
]]

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

-- 防止重複載入
if getgenv()._CodeNotifyLib then
    getgenv()._CodeNotifyLib:Destroy()
end

local Lib = {}

-- 建立 UI 實體
local gui = Instance.new("ScreenGui")
gui.Name = "CodeNotifyLib"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = CoreGui
getgenv()._CodeNotifyLib = gui

-- 通知容器
local container = Instance.new("Frame")
container.Name = "NotifyContainer"
container.Size = UDim2.new(0.9, 0, 0.5, 0)
container.Position = UDim2.new(0.5, 0, 0.55, 0) -- 畫面中段偏上
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundTransparency = 1
container.Parent = gui

local layout = Instance.new("UIListLayout")
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = container

-- 音效處理函數 (已修正 table 賦值問題)
local function playSound(soundData)
    if not soundData then return end
    
    local idToUse = nil
    local volumeToUse = 2 -- 預設音量為 2

    if type(soundData) == "table" then
        idToUse = soundData[1]
        volumeToUse = soundData[2] or 2
    else
        idToUse = soundData
        volumeToUse = 2
    end

    if not idToUse or idToUse == "" then return end
    
    -- 確保傳遞給 SoundId 的是字串
    local finalId = (type(idToUse) == "number") and ("rbxassetid://" .. idToUse) or tostring(idToUse)
    
    local s = Instance.new("Sound")
    s.SoundId = finalId
    s.Volume = volumeToUse
    s.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    if not s.IsLoaded then 
        -- 避免長時間卡住，設置一個簡單的等待
        task.spawn(function()
            local loaded = s.Loaded:Wait()
            if loaded then s:Play() end
        end)
    else
        s:Play()
    end
    
    s.Ended:Connect(function() s:Destroy() end)
end

function Lib:Notify(config)
    local cfg = type(config) == "table" and config or {Text = tostring(config)}
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 65)
    label.BackgroundTransparency = 1
    label.Font = cfg.Font or Enum.Font.Code
    label.Text = cfg.Text or "No Text"
    label.TextColor3 = cfg.Color or Color3.fromRGB(255, 255, 255)
    label.TextSize = cfg.Size or 55
    label.TextTransparency = 1
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- 黑色描邊
    label.TextStrokeTransparency = 1 
    label.Parent = container

    -- 淡入 (0.2s)
    task.spawn(playSound, cfg.FadeInSound)
    TweenService:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        TextTransparency = 0,
        TextStrokeTransparency = 0.5
    }):Play()

    -- 延遲淡出
    task.delay(cfg.Duration or 3, function()
        task.spawn(playSound, cfg.FadeOutSound)
        local fadeOut = TweenService:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
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
