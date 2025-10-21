--[[
    ⚠️ WEAKNESS STATUS DISPLAY
    Detects animation 133461474706559 and displays weakness level with smooth elevator roll effect
    
    FEATURES:
    - Monitors animation 133461474706559
    - Tracks weakness from workspace.Players.Survivors.Chance.ResistanceMultipliers.WeaknessStatus
    - Displays "WEAKNESS" label with roman numeral (I, II, III, IV, V, VI, etc.)
    - Smooth elevator roll effect showing transitions
    - Only shows when weakness decreases (hatfix effect)
    - Remembers last weakness if current doesn't exist
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Configuration
local TARGET_ANIMATION_ID = "rbxassetid://133461474706559"
local WEAKNESS_PATH = {"Players", "Survivors", "Chance", "ResistanceMultipliers", "WeaknessStatus"}

-- Script control
local scriptEnabled = true
local connections = {}

-- Global toggle support (can be controlled via _G.WeaknessDisplayEnabled)
_G.WeaknessDisplayEnabled = true
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.WeaknessDisplayEnabled ~= nil then
            scriptEnabled = _G.WeaknessDisplayEnabled
        end
    end
end)

-- State tracking
local lastWeaknessValue = nil
local isDisplaying = false

-- Persistent music state
local persistentMusic = nil
local musicTimePosition = 1 -- Start at 1 second initially

-- Roman numeral conversion
local function numberToRoman(tier)
    if tier <= 0 then
        return "0"
    end
    
    local romanNumerals = {
        {1000, "M"},
        {900, "CM"},
        {500, "D"},
        {400, "CD"},
        {100, "C"},
        {90, "XC"},
        {50, "L"},
        {40, "XL"},
        {10, "X"},
        {9, "IX"},
        {5, "V"},
        {4, "IV"},
        {1, "I"}
    }
    
    local result = ""
    local remaining = tier
    
    for _, pair in ipairs(romanNumerals) do
        local value = pair[1]
        local numeral = pair[2]
        
        while remaining >= value do
            result = result .. numeral
            remaining = remaining - value
        end
    end
    
    return result
end

-- Convert weakness value to tier and roman numeral
-- -20 → (1, "I"), -40 → (2, "II"), -60 → (3, "III"), etc.
local function weaknessToRoman(weaknessValue)
    local tier = math.floor(math.abs(weaknessValue) / 20)
    local roman = numberToRoman(tier)
    return tier, roman
end

-- Get weakness status from workspace
local function getWeaknessStatus()
    local current = workspace
    
    for _, childName in ipairs(WEAKNESS_PATH) do
        current = current:FindFirstChild(childName)
        if not current then
            return lastWeaknessValue
        end
    end
    
    if current:IsA("ValueBase") then
        local value = current.Value
        if typeof(value) == "number" then
            return value
        end
    end
    
    return lastWeaknessValue
end

-- Create GUI for weakness display
local function createWeaknessGUI()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Remove old instance if exists
    local oldGui = playerGui:FindFirstChild("WeaknessDisplayGUI")
    if oldGui then
        oldGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WeaknessDisplayGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- Main container
    local container = Instance.new("CanvasGroup")
    container.Name = "Container"
    container.Size = UDim2.new(0, 600, 0, 120)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1
    container.Parent = screenGui
    
    -- "WEAKNESS" label (left side)
    local weaknessLabel = Instance.new("TextLabel")
    weaknessLabel.Name = "WeaknessLabel"
    weaknessLabel.Size = UDim2.new(0.7, 0, 1, 0)
    weaknessLabel.Position = UDim2.new(0, 0, 0, 0)
    weaknessLabel.BackgroundTransparency = 1
    weaknessLabel.Text = "WEAKNESS"
    weaknessLabel.Font = Enum.Font.GothamBold
    weaknessLabel.TextSize = 72
    weaknessLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    weaknessLabel.TextStrokeTransparency = 0.5
    weaknessLabel.TextStrokeColor3 = Color3.fromRGB(139, 0, 0)
    weaknessLabel.TextXAlignment = Enum.TextXAlignment.Left
    weaknessLabel.Parent = container
    
    -- Numeral container (for clipping) - right side
    local numeralClipFrame = Instance.new("Frame")
    numeralClipFrame.Name = "NumeralClip"
    numeralClipFrame.Size = UDim2.new(0.3, 0, 1, 0)
    numeralClipFrame.Position = UDim2.new(0.5, 0.075, 0, 0)
    numeralClipFrame.BackgroundTransparency = 1
    numeralClipFrame.ClipsDescendants = true
    numeralClipFrame.Parent = container
    
    -- Scrolling frame for elevator roll effect
    local scrollFrame = Instance.new("Frame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.Position = UDim2.new(0, 0, 0, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.Parent = numeralClipFrame
    
    return screenGui, container, scrollFrame, numeralClipFrame
end

-- Play the weakness display effect with elevator roll
local function playWeaknessDisplay(currentValue, previousValue)
    if isDisplaying then
        return
    end
    
    isDisplaying = true
    
    local gui, container, scrollFrame, numeralClipFrame = createWeaknessGUI()
    
    -- Calculate previous tier (always drop from last recorded weakness to 0)
    local previousTier, previousRoman = weaknessToRoman(previousValue)
    
    -- Define all possible floors from highest to 0
    -- Always roll from previous tier down to 0
    local maxTier = math.max(previousTier, 10) -- Support up to X
    local allFloors = {}
    for i = maxTier, 0, -1 do
        table.insert(allFloors, numberToRoman(i))
    end
    
    -- Find starting and ending floor indices
    local startIndex = 1
    local endIndex = #allFloors -- Always end at 0 (last floor)
    
    for i, floor in ipairs(allFloors) do
        if floor == previousRoman then
            startIndex = i
        end
        -- End index is always the last floor (0)
        if floor == "0" then
            endIndex = i
        end
    end
    
    -- Create floor labels in the scrollFrame
    local numFloors = #allFloors
    local cellHeight = numeralClipFrame.AbsoluteSize.Y
    
    for i, floorText in ipairs(allFloors) do
        local floorLabel = Instance.new("TextLabel")
        floorLabel.Name = "Floor_" .. floorText
        floorLabel.Size = UDim2.new(1, 0, 0, cellHeight)
        floorLabel.Position = UDim2.new(0, 0, 0, (i - 1) * cellHeight)
        floorLabel.BackgroundTransparency = 1
        floorLabel.Text = floorText
        floorLabel.Font = Enum.Font.Michroma
        floorLabel.TextSize = 72
        floorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        floorLabel.TextStrokeTransparency = 0.5
        floorLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        floorLabel.TextXAlignment = Enum.TextXAlignment.Right
        floorLabel.Parent = scrollFrame
    end
    
    -- Update scroll frame size to fit all floors
    scrollFrame.Size = UDim2.new(1, 0, 0, cellHeight * numFloors)
    
    -- Position scrollFrame to show the starting floor
    local startYOffset = -(startIndex - 1) * cellHeight
    scrollFrame.Position = UDim2.new(0, 0, 0, startYOffset)
    
    -- Set initial state
    container.GroupTransparency = 1
    container.Size = UDim2.new(0, 580, 0, 114)
    
    task.spawn(function()
        -- Use persistent music or create new one
        local introSound = persistentMusic
        local isNewMusic = false
        
        if not introSound or not introSound.Parent then
            -- Create new music
            introSound = Instance.new("Sound")
            introSound.SoundId = getcustomasset("forvids/sfx/tetra.mp3")
            introSound.Volume = 0
            introSound.TimePosition = musicTimePosition
            introSound.Parent = game:GetService("SoundService")
            introSound:Play()
            persistentMusic = introSound
            isNewMusic = true
        else
            -- Resume existing music
            introSound.Volume = 0
            if not introSound.Playing then
                introSound:Play()
            end
        end
        
        -- Fade in the music
        local fadeInSound = TweenService:Create(
            introSound,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Volume = 0.25}
        )
        fadeInSound:Play()
        
        -- Phase 1: Fade in (0.4s)
        local fadeInTween = TweenService:Create(
            container,
            TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {GroupTransparency = 0}
        )
        fadeInTween:Play()
        fadeInTween.Completed:Wait()
        
        -- Subtle pulse
        local pulseTween = TweenService:Create(
            container,
            TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 600, 0, 120)}
        )
        pulseTween:Play()
        
        -- Phase 2: Wait before roll (1.0s)
        task.wait(1.0)
        
        -- Phase 3: Roll from previous floor to current floor
        local targetYOffset = -(endIndex - 1) * cellHeight
        
        -- Calculate duration based on distance
        local floorsToTraverse = math.abs(endIndex - startIndex)
        local rollDuration = floorsToTraverse * 0.5 -- 0.5 seconds per floor
        rollDuration = math.max(0.3, rollDuration) -- Minimum 0.3 seconds
        
        -- Track which floors have been passed to play sound once per floor
        local lastFloorPassed = startIndex
        local soundConnection
        
        soundConnection = RunService.Heartbeat:Connect(function()
            local currentYOffset = scrollFrame.Position.Y.Offset
            local currentFloorIndex = math.floor(-currentYOffset / cellHeight + 0.5) + 1
            
            -- Check if we've passed to a new floor
            if currentFloorIndex ~= lastFloorPassed and currentFloorIndex >= 1 and currentFloorIndex <= numFloors then
                lastFloorPassed = currentFloorIndex
                
                -- Play the floor pass sound
                local sound = Instance.new("Sound")
                sound.SoundId = getcustomasset("forvids/sfx/tetrio/garbagerise.ogg")
                sound.Volume = 0.5
                sound.Parent = game:GetService("SoundService")
                sound:Play()
                
                -- Clean up sound after it finishes
                game:GetService("Debris"):AddItem(sound, 2)
            end
        end)
        
        local rollTween = TweenService:Create(
            scrollFrame,
            TweenInfo.new(rollDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Position = UDim2.new(0, 0, 0, targetYOffset)}
        )
        rollTween:Play()
        rollTween.Completed:Wait()
        
        -- Disconnect the sound trigger
        if soundConnection then
            soundConnection:Disconnect()
        end
        
        -- Check if weakness reached zero
        if endIndex == numFloors then -- Last floor is 0
            -- Play achievement sound
            local achievementSound = Instance.new("Sound")
            achievementSound.SoundId = getcustomasset("forvids/sfx/tetrio/achievement_1.ogg")
            achievementSound.Volume = 0.6
            achievementSound.Parent = game:GetService("SoundService")
            achievementSound:Play()
            game:GetService("Debris"):AddItem(achievementSound, 3)
            
            -- Change text to bright white (0.1s)
            local weaknessLabel = container:FindFirstChild("WeaknessLabel")
            local numeralLabels = scrollFrame:GetChildren()
            
            -- Fade text to bright white
            local brightWhite = Color3.new(1, 1, 1)
            local tweens = {}
            
            if weaknessLabel then
                table.insert(tweens, TweenService:Create(
                    weaknessLabel,
                    TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {TextColor3 = brightWhite}
                ))
            end
            
            for _, label in ipairs(numeralLabels) do
                if label:IsA("TextLabel") then
                    table.insert(tweens, TweenService:Create(
                        label,
                        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {TextColor3 = brightWhite}
                    ))
                end
            end
            
            -- Play all brightness tweens
            for _, tween in ipairs(tweens) do
                tween:Play()
            end
            
            -- Wait for brightness to complete
            if #tweens > 0 then
                tweens[1].Completed:Wait()
            end
            
            -- Fade out everything (5s)
            local containerFadeOut = TweenService:Create(
                container,
                TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {GroupTransparency = 1}
            )
            containerFadeOut:Play()
            
            -- Fade out the music over 5 seconds too
            local fadeOutSound = TweenService:Create(
                introSound,
                TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Volume = 0}
            )
            fadeOutSound:Play()
            containerFadeOut.Completed:Wait()
            
            -- Save music position and keep music playing
            musicTimePosition = introSound.TimePosition
            
            -- Cleanup
            gui:Destroy()
            isDisplaying = false
            return
        end
        
        -- Phase 4: Hold (1.2s)
        task.wait(1.2)
        
        -- Phase 5: Fade out (0.8s)
        local fadeOutTween = TweenService:Create(
            container,
            TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {GroupTransparency = 1}
        )
        fadeOutTween:Play()
        
        -- Fade out the music simultaneously
        local fadeOutSound = TweenService:Create(
            introSound,
            TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Volume = 0}
        )
        fadeOutSound:Play()
        fadeOutTween.Completed:Wait()
        
        -- Save music position and keep music playing
        musicTimePosition = introSound.TimePosition
        
        -- Cleanup
        gui:Destroy()
        isDisplaying = false
    end)
end

-- Handle animation played
local function onAnimationPlayed(animationTrack)
    if not scriptEnabled then return end
    
    -- Check if it's the target animation
    if animationTrack.Animation.AnimationId ~= TARGET_ANIMATION_ID then
        return
    end
    
    -- Ignore if already displaying
    if isDisplaying then
        print("⚠️ Weakness: Animation detected but display already showing, skipping")
        return
    end
    
    -- Get current weakness status
    local currentWeakness = getWeaknessStatus()
    
    -- Determine which value to drop from
    local dropFromValue = nil
    
    -- If path exists, use current weakness
    if currentWeakness and currentWeakness ~= lastWeaknessValue then
        dropFromValue = currentWeakness
        print(string.format("⚠️ Animation detected! Path exists with weakness: %d", currentWeakness))
    -- If path disappeared but we have a last known value, use that
    elseif lastWeaknessValue then
        dropFromValue = lastWeaknessValue
        print(string.format("⚠️ Animation detected! Path missing, using last known: %d", lastWeaknessValue))
    else
        print("⚠️ Animation detected but no weakness data available (neither current nor last)")
        return
    end
    
    -- Show the GUI, dropping from the determined value to 0
    local tier, roman = weaknessToRoman(dropFromValue)
    print(string.format("⚠️ Showing GUI: Dropping from %s (%d) to 0", roman, dropFromValue))
    
    playWeaknessDisplay(0, dropFromValue)
    
    -- Update last known status if we got a new current value
    if currentWeakness then
        lastWeaknessValue = currentWeakness
    end
end

-- Monitor weakness changes even outside animation
local function monitorWeaknessChanges()
    task.spawn(function()
        while scriptEnabled do
            task.wait(0.5) -- Check every 0.5 seconds
            
            local currentWeakness = getWeaknessStatus()
            
            if currentWeakness and currentWeakness ~= lastWeaknessValue then
                if lastWeaknessValue then
                    local prevTier, prevRoman = weaknessToRoman(lastWeaknessValue)
                    local currTier, currRoman = weaknessToRoman(currentWeakness)
                    
                    if currentWeakness > lastWeaknessValue then
                        print(string.format("⚠️ Weakness changed: %s (%d) → %s (%d) [DECREASED]", 
                            prevRoman, lastWeaknessValue, currRoman, currentWeakness))
                    else
                        print(string.format("⚠️ Weakness changed: %s (%d) → %s (%d) [INCREASED]", 
                            prevRoman, lastWeaknessValue, currRoman, currentWeakness))
                    end
                end
                
                lastWeaknessValue = currentWeakness
            end
        end
    end)
end

-- Cleanup function
local function destroyScript()
    scriptEnabled = false
    
    -- Disconnect all connections
    for _, connection in pairs(connections) do
        connection:Disconnect()
    end
    
    -- Remove GUI if it exists
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local gui = playerGui:FindFirstChild("WeaknessDisplayGUI")
        if gui then
            gui:Destroy()
        end
    end
    
    print("⚠️ Weakness Display destroyed")
end

-- Connect to animation events
table.insert(connections, humanoid.AnimationPlayed:Connect(onAnimationPlayed))

-- Handle character respawn
table.insert(connections, player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    table.insert(connections, humanoid.AnimationPlayed:Connect(onAnimationPlayed))
    
    -- Reset state on respawn
    lastWeaknessValue = nil
    isDisplaying = false
end))

-- Press P to destroy script
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        destroyScript()
    end
end))

-- Start monitoring weakness changes
monitorWeaknessChanges()

-- Initialize last weakness value
local initialWeakness = getWeaknessStatus()
if initialWeakness then
    lastWeaknessValue = initialWeakness
    local tier, roman = weaknessToRoman(initialWeakness)
    print(string.format("⚠️ Weakness Display loaded - Initial status: %s (%d)", roman, initialWeakness))
else
    print("⚠️ Weakness Display loaded - No initial weakness detected")
end

print("⚠️ Listening for animation", TARGET_ANIMATION_ID)
print("Press P to destroy script")

