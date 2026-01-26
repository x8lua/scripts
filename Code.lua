--[[
    Notification Library (Sequential Fade Mode)
    - SingleLine: Fully Fade Out (0.2s) -> Then Fade In (0.2s)
    - Volume Default: 2 | Padding: 2
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
layout.Padding = UDim.new(0, 2)
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
    local fadeTime = 0.2

    -- 處理邏輯：包裝成一個執行函數
    local function spawnNewNotify()
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

        -- Fade In
        task.spawn(playSound, cfg.FadeInSound)
        TweenService:Create(label, TweenInfo.new(fadeTime), {
            TextTransparency = 0, 
            TextStrokeTransparency = 0.5
        }):Play()

        -- Auto Fade Out
        task.delay(cfg.Duration or 3, function()
            if label and label.Parent then
                task.spawn(playSound, cfg.FadeOutSound)
                local out = TweenService:Create(label, TweenInfo.new(fadeTime), {
                    TextTransparency = 1, 
                    TextStrokeTransparency = 1
                })
                out:Play()
                out.Completed:Connect(function() label:Destroy() end)
            end
        end)
    end

    -- [[ 核心修正：單行模式順序動畫 ]]
    local existing = {}
    if cfg.SingleLine then
        for _, child in pairs(container:GetChildren()) do
            if child:IsA("TextLabel") then table.insert(existing, child) end
        end
    end

    if #existing > 0 then
        -- 1. 先讓所有舊的 Fade Out
        for _, oldLabel in ipairs(existing) do
            TweenService:Create(oldLabel, TweenInfo.new(fadeTime), {
                TextTransparency = 1, 
                TextStrokeTransparency = 1
            }):Play()
        end
        -- 2. 等待 0.2s 完畢後，刪除舊的並 Fade In 新的
        task.delay(fadeTime, function()
            for _, oldLabel in ipairs(existing) do oldLabel:Destroy() end
            spawnNewNotify()
        end)
    else
        -- 如果本來就沒東西，直接顯示
        spawnNewNotify()
    end
end

return Lib
