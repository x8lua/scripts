-- xGui Roblox UI Library — Example Script
-- Run this in your executor

local xGui
local ok, res = pcall(function()
    return require(game:GetService("ReplicatedStorage"):WaitForChild("xGui", 1))
end)

if ok and res then
    xGui = res
else
    local getOk, code = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/x8lua/scripts/main/imgui-roblox/ImGui.lua?v=11")
    end)
    if getOk and code then
        xGui = loadstring(code)()
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
    if state then
        Section("Script Controls")
        
        local autoFarm = false
        Toggle("Enable Auto-Farm", false, function(val)
            autoFarm = val
            print("Auto-farm status:", autoFarm)
        end)
        
        Slider("Speed multiplier", 1, 10, 5, function(val)
            print("Speed set to:", val)
        end)
        
        Button("Execute Action", function()
            print("Clicked Execute! AutoFarm is:", autoFarm)
        end)
    else
        print("Script toggled off!")
    end
end)

scriptTab:CreateLabel("Press RightShift to toggle UI visibility.")

-- ─── Tab 3: Configuration ─────────────────────────────────────────────────────
local configTab = window:CreateTab("Config")

local helpSection = configTab:CreateSection("Help")
helpSection:CreateLabel("xGui — a Dear ImGui style library for exploits.")
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

print("[xGui] Window created! Press Insert to toggle. Drag edges/corners to resize.")
