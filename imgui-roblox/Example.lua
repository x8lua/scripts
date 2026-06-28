-- Dear ImGui Roblox - Example Script
-- Paste this script into your Roblox Executor or local script (with ImGui loaded as a ModuleScript)

-- [How to use in standard Roblox Studio]:
-- 1. Create a ModuleScript named "ImGui" in ReplicatedStorage.
-- 2. Paste the code from ImGui.lua into it.
-- 3. Use: local ImGui = require(game.ReplicatedStorage.ImGui)
-- 
-- [How to use in Roblox Exploit Executor]:
-- You can load the code dynamically or paste ImGui.lua directly at the top of this script.
-- Example of dynamic load (if you host the script online):
-- local ImGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/yourpath/ImGui.lua"))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ImGui
local success, result = pcall(function()
    return require(ReplicatedStorage:WaitForChild("ImGui", 2))
end)

if success and result then
    ImGui = result
else
    -- Fallback: If not in Studio, warn user or define how they can manually integrate it.
    warn("[Dear ImGui] Module not found in ReplicatedStorage. Please ensure ImGui.lua is placed there, or load it via loadstring.")
    -- For demonstration, we assume ImGui is already loaded in the environment.
    return
end

-- Initialize the window
local window = ImGui.new("Dear ImGui GLW+OpenGL3 example")

-- 1. Create "Hello, world!" Tab
local demoTab = window:CreateTab("Hello, World!")

demoTab:CreateLabel("This is some useful text.")

-- Checkboxes (Toggles)
local demoWindowToggle = demoTab:CreateToggle("Demo Window", true, function(state)
    print("Demo Window state:", state)
end)

local anotherWindowToggle = demoTab:CreateToggle("Another Window", false, function(state)
    print("Another Window state:", state)
end)

-- Slider
local floatSlider = demoTab:CreateSlider("float", 0, 1, 0.5, function(value)
    print("Float slider changed:", value)
end)

-- Dropdown
local dropdown = demoTab:CreateDropdown("clear color", {"R:117, G:130, B:131", "R:255, G:0, B:0", "R:0, G:255, B:0", "R:0, G:0, B:255"}, "R:117, G:130, B:131", function(selected)
    print("Selected color option:", selected)
end)

-- Button with Click Counter
local counter = 0
local countButton
countButton = demoTab:CreateButton("Button", function()
    counter = counter + 1
    print("Button pressed! Counter:", counter)
    -- Dynamic label update could be paired here
end)

demoTab:CreateLabel("Application average 13.355 ms/frame (74.9 FPS)")


-- 2. Create "Dear ImGui Demo" Tab
local widgetsTab = window:CreateTab("Dear ImGui Demo")

-- Section 1: Help
local helpSection = widgetsTab:CreateSection("Help")
helpSection:CreateLabel("Dear ImGui says hello! (1.89.6 WIP)")
helpSection:CreateButton("Show Documentation", function()
    print("Documentation button clicked!")
end)

-- Section 2: Configuration
local configSection = widgetsTab:CreateSection("Configuration")
configSection:CreateToggle("Show FPS Counter", true, function(state)
    print("Toggle FPS:", state)
end)
configSection:CreateSlider("UI Scale", 0.5, 2.0, 1.0, function(val)
    print("UI Scale updated:", val)
end)

-- Section 3: Window Options
local windowOptions = widgetsTab:CreateSection("Window options")
windowOptions:CreateToggle("No Titlebar", false, function(state)
    window.TitleBar.Visible = not state
end)
windowOptions:CreateToggle("No Scrollbar", false, function(state)
    -- Example toggle
end)

print("[Dear ImGui] Demo window created successfully! Press 'Insert' key to toggle GUI visibility.")
