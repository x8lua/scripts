# xGui — Premium Dear ImGui-Style Roblox UI Library

A high-performance, feature-rich, and visually polished Roblox UI library designed for exploit environments. Inspired by the classic Dear ImGui layout and styled with modern dark mode aesthetics.

## Key Features
- **Super Smooth Animations:** Custom `CanvasGroup` wrappers enable bouncy scale transitions and transparency fading on execute, close, or toggle.
- **8-Handle Resizability:** Drag-to-resize from any window edge or corner with automatic opposite-edge locking and size constraints.
- **Virtual ScreenGui Sandbox:** Exposes a custom `Script` widget that transparently redirects standard Roblox ScreenGui scripts and renders them inside the xGui panel boundaries.
- **Selectable Console Tab:** A built-in diagnostic console tab that captures print statements and execution errors with selectable TextBoxes so you can easily copy logs to your clipboard.
- **Oops! Error Popup Modals:** Automated popup overlays for script compilation/execution failures with instant "Check" links that jump directly to the console.
- **Zero-Cache Loader:** Uses dynamic tick cache-busting to ensure your users always get the latest patches instantly.

## Installation / Loading

Run the following loadstring in your executor:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/x8lua/scripts/main/imgui-roblox/Example.lua?nocache=" .. tostring(tick())))()
```

## Quick Start Example
```lua
local xGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/x8lua/scripts/main/imgui-roblox/ImGui.lua?nocache=" .. tostring(tick())))()

-- Create Window (passes custom toggle key - defaults to Insert)
local window = xGui.new("xGui — My Script", Enum.KeyCode.RightShift)

-- Create a Tab
local tab = window:CreateTab("Main")

-- Create Widgets
tab:CreateLabel("Welcome to xGui!")

tab:CreateToggle("Enable Feature", false, function(state)
    print("Feature state:", state)
end)

tab:CreateSlider("Multiplier", 1, 100, 50, function(val)
    print("Value:", val)
end)

tab:CreateButton("Run Action", function()
    print("Action executed!")
end)

-- Script Callback Container (Renders a standard Roblox UI inside the xGui window!)
tab:Script("My Sub-GUI", false, function(state)
    if state then
        -- This environment intercepts ScreenGui/PlayerGui writes and renders them here!
        local screenGui = Instance.new("ScreenGui")
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        frame.Parent = screenGui
        
        local text = Instance.new("TextLabel")
        text.Text = "Hello from Virtual ScreenGui!"
        text.Size = UDim2.new(1, 0, 0, 50)
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.Parent = frame
        
        screenGui.Parent = game.Players.LocalPlayer.PlayerGui
    end
end)
```
