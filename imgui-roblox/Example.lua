-- xGui Roblox UI Library — Example Script
-- Run this in your executor

local xGui
local isExecutor = (typeof(identifyexecutor) == "function") or (typeof(getexecutorname) == "function") or (game:GetService("RunService"):IsStudio() == false)

if isExecutor then
    local getOk, code = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/x8lua/scripts/main/imgui-roblox/ImGui.lua?nocache=" .. tostring(tick()))
    end)
    if getOk and code then
        xGui = loadstring(code)()
    end
end

if not xGui then
    local ok, res = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("xGui", 1))
    end)
    if ok and res then
        xGui = res
    else
        error("[xGui] Failed to load library.")
    end
end

-- Create window (passing Enum.KeyCode.RightShift as the toggle key)
local window = xGui.new("xGui — Demo  (resize me!)", Enum.KeyCode.RightShift)

-- ─── Tab 1: Hello World ───────────────────────────────────────────────────────
local demoTab = window:CreateTab("Hello, World!")

demoTab:CreateLabel("This is some useful text.")

local demoWindowToggle = demoTab:CreateToggle("Demo Window", true, function(state)
    print("Demo Window:", state)
end)

local anotherWindowToggle = demoTab:CreateToggle("Another Window", false, function(state)
    print("Another Window:", state)
end)

local floatSlider = demoTab:CreateSlider("float", 0, 1, 0.5, function(value)
    print("Float slider:", value)
end)

local dropdown = demoTab:CreateDropdown("clear color preset",
    {"R:117, G:130, B:131", "R:255, G:0, B:0", "R:0, G:255, B:0"},
    "R:117, G:130, B:131",
    function(sel) print("Selected:", sel) end)

local colorPicker = demoTab:CreateColorPicker("clear color",
    Color3.fromRGB(117, 130, 131),
    function(c) print("Color:", c) end)

local counter = 0
demoTab:CreateButton("Button", function()
    counter = counter + 1
    print("Button pressed! Counter:", counter)
end)

demoTab:CreateLabel("Application average 13.355 ms/frame (74.9 FPS)")

-- ─── Tab 2: Script Editor ─────────────────────────────────────────────────────
local scriptTab = window:CreateTab("Script")

scriptTab:CreateLabel("Script container demo:")

local myScript = scriptTab:Script("Custom UI", false, function(state)
    if not state then
        return
    end
    --!strict
    -- 上面那行是 Luau 的嚴格類型檢查宣告，強迫症工程師必備

    -- 引用 Roblox 的內建服務
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")

    local localPlayer = Players.LocalPlayer
    local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

    -- 1. 建立 UI 外殼 (ScreenGui)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RandomGui"
    screenGui.ResetOnSpawn = false

    -- 2. 建立主視窗 (Frame)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(0.5, -150, 0.5, -100) -- 居中
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    -- 加上一點點現代感的圓角
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 12)
    frameCorner.Parent = frame

    -- 3. 建立標題文字 (TextLabel)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 50)
    titleLabel.Text = "Luau 測試機關"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = frame

    -- 4. 建立那顆靈魂按鈕 (TextButton)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 180, 0, 50)
    button.Position = UDim2.new(0.5, -90, 0.5, -10)
    button.BackgroundColor3 = Color3.fromRGB(98, 86, 202)
    button.Text = "點我！"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 18
    button.Font = Enum.Font.SourceSans
    button.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button

    -- 5. 計數與幹話邏輯
    local clickCount: number = 0
    local phrases: {string} = {
        "哎呀，好爽！",
        "力道不錯，再來！",
        "在 Roblox 裡面點按鈕特別過癮？",
        "恭喜你，你的滑鼠壽命減少了。",
        "按鈕表示：別戳了，痛！"
    }

    -- 點擊事件
    button.MouseButton1Click:Connect(function()
        clickCount += 1
        
        -- 隨機換句話說
        local randomPhrase = phrases[math.random(1, #phrases)]
        button.Text = randomPhrase
        
        -- 點擊時搞個隨機顏色的動畫 (Tween)
        local randomColor = Color3.fromRGB(math.random(50, 200), math.random(50, 200), math.random(150, 255))
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(button, tweenInfo, {BackgroundColor3 = randomColor})
        tween:Play()
        
        print("按鈕總共被臨幸了 " .. tostring(clickCount) .. " 次。")
    end)

    -- 最後把整個 UI 掛到玩家螢幕上
    screenGui.Parent = playerGui
end)

scriptTab:CreateLabel("Press RightShift to toggle UI visibility.")

-- ─── Tab 3: Configuration ─────────────────────────────────────────────────────
local configTab = window:CreateTab("Config")

local helpSection = configTab:CreateSection("Help")
helpSection:CreateLabel("xGui — a Dear ImGui style library for exploits.")
helpSection:CreateLabel("Version: " .. tostring(xGui.Version or "2.2.0"))
helpSection:CreateButton("Documentation", function()
    print("Docs: github.com/x8lua/scripts")
end)

local configSection = configTab:CreateSection("Configuration")
configSection:CreateToggle("Show FPS Counter", true, function(state)
    print("FPS Counter:", state)
end)
configSection:CreateSlider("UI Scale", 0.5, 2.0, 1.0, function(val)
    print("UI Scale:", val)
end)

local windowOptions = configTab:CreateSection("Window options")
windowOptions:CreateToggle("No Titlebar", false, function(state)
    window.TitleBar.Visible = not state
end)

print("[xGui] Window created! Press RightShift to toggle. Drag edges/corners to resize.")
