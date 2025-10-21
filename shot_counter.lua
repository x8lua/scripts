--[[
    🎯 SHOT COUNTER DISPLAY
    Detects animation 71685573690338 and displays shot counter with smooth number increment
    
    FEATURES:
    - Monitors animation 71685573690338
    - Tracks total shots and ROW (both saved to JSON)
    - Displays "SHOT" with total count (persistent)
    - Displays "ROW" with persistent count (saved to JSON, resets to 0 only on streak break)
    - Smooth elevator roll number animation
    - Plays zenith.mp3 music that continues across displays
    - Press P to destroy display instantly
    - Uses same fade in SFX as weakness display
    - Consecutive streak system with 21 ranks (1-20, then "ABSOLUTE CHANCE" for 21+)
    - Special levelup.ogg sound for streaks 21+
    - Streak rank achievements with unique visual effects
    - Detects fail animations (138008678294576 or 108014891454394)
    - Streak broken: "Streak broken." message with gray smoke fade, health red flicker, ROW rolls to 0, card tear SFX
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- Ensure task library compatibility
local task = task or {
	spawn = function(func) coroutine.wrap(func)() end,
	wait = wait
}

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Configuration
local TARGET_ANIMATION_ID = "rbxassetid://71685573690338"
local RESET_ANIMATION_IDS = {
	["rbxassetid://138008678294576"] = true,
	["rbxassetid://108014891454394"] = true,
}
local SAVE_FILE = "shot_counter_data.json"

-- Streak Configuration (consecutive successes)
local STREAK_RANKS = {
	{threshold = 1,  title = "First Pull",        message = "The game begins.",                        color = Color3.fromRGB(200, 200, 200), effect = "flash_start", tier = 1},
	{threshold = 2,  title = "Warm Hands",        message = "You're feeling it.",                      color = Color3.fromRGB(255, 140, 60),  effect = "faint_glow", tier = 2},
	{threshold = 3,  title = "Steady Pull",       message = "The barrel likes you.",                   color = Color3.fromRGB(255, 215, 100), effect = "soft_flash", tier = 3},
	{threshold = 4,  title = "Lucky Rhythm",      message = "Every trigger hits right.",               color = Color3.fromRGB(255, 200, 80),  effect = "pulse", tier = 4},
	{threshold = 5,  title = "Rolling Fate",      message = "Luck's on repeat.",                       color = Color3.fromRGB(255, 120, 50),  effect = "flicker", tier = 5},
	{threshold = 6,  title = "Risk Runner",       message = "You're betting with air.",                color = Color3.fromRGB(255, 150, 90),  effect = "shake_light", tier = 6},
	{threshold = 7,  title = "Trigger Whisperer", message = "Even the gun listens.",                   color = Color3.fromRGB(255, 180, 110), effect = "spark_pulse", tier = 7},
	{threshold = 8,  title = "Smoke Dancer",      message = "Barrel heat sings your name.",            color = Color3.fromRGB(255, 150, 80),  effect = "smoke", tier = 8},
	{threshold = 9,  title = "Table Breaker",     message = "The house watches closely.",              color = Color3.fromRGB(255, 180, 100), effect = "card_flash", tier = 9},
	{threshold = 10, title = "Streak Walker",     message = "They start praying you miss.",            color = Color3.fromRGB(255, 80, 80),   effect = "red_pulse", tier = 10},
	{threshold = 11, title = "Burning Chamber",   message = "Smoke means you're doing it right.",      color = Color3.fromRGB(200, 60, 40),   effect = "smoke_flash", tier = 11},
	{threshold = 12, title = "Unblinking Hand",   message = "Even the killer hesitates.",              color = Color3.fromRGB(255, 150, 150), effect = "reticle_flash", tier = 12},
	{threshold = 13, title = "Loaded Prayer",     message = "Faith clicks before the hammer.",         color = Color3.fromRGB(255, 200, 140), effect = "light_burst", tier = 13},
	{threshold = 14, title = "The Dealer's Fear", message = "The house flinches.",                     color = Color3.fromRGB(180, 40, 40),   effect = "dark_bloom", tier = 14},
	{threshold = 15, title = "High Roller",       message = "You bet. The world folds.",               color = Color3.fromRGB(255, 240, 180), effect = "gold_flicker", tier = 15},
	{threshold = 16, title = "Fate Tamer",        message = "Probability bends its knees.",            color = Color3.fromRGB(255, 220, 100), effect = "lightning", tier = 16},
	{threshold = 17, title = "Card Saint",        message = "Every shot's a sermon.",                  color = Color3.fromRGB(255, 230, 150), effect = "glow_aura", tier = 17},
	{threshold = 18, title = "Gambler King",      message = "The table belongs to you.",               color = Color3.fromRGB(255, 200, 90),  effect = "gold_flash", tier = 18},
	{threshold = 19, title = "Fatebreaker",       message = "You shoot through probability.",          color = Color3.fromRGB(255, 255, 180), effect = "divine_flash", tier = 19},
	{threshold = 20, title = "ABSOLUTE CHANCE",   message = "Luck can't keep up anymore.",             color = Color3.fromRGB(255, 255, 255), effect = "jackpot_burst", tier = 20},
	-- All streaks 21+ keep same rank & trigger special SFX
	{threshold = 21, title = "ABSOLUTE CHANCE",   message = "The dice no longer roll.",                color = Color3.fromRGB(255, 255, 255), effect = "jackpot_loop", tier = "max"},
}


-- Script control
local scriptEnabled = true
local connections = {}

-- Global toggle support (can be controlled via _G.ShotCounterEnabled)
_G.ShotCounterEnabled = true
task.spawn(function()
    local lastState = scriptEnabled
    while true do
        task.wait(0.1)
        if _G.ShotCounterEnabled ~= nil then
            local newState = _G.ShotCounterEnabled
            if newState ~= lastState then
                scriptEnabled = newState
                print(string.format("🎯 Shot Counter: %s", scriptEnabled and "ENABLED ✓" or "DISABLED ✗"))
                lastState = newState
            end
        end
    end
end)

-- State tracking
local isDisplaying = false
local previousAnimationId = nil
local shotData = {
    total = 0,
    row = 0  -- Current consecutive success streak (ROW = streak)
}

-- Persistent music state
local persistentMusic = nil
local musicTimePosition = 0

-- Load shot data from JSON (total and row are saved)
local function loadShotData()
    if not isfile(SAVE_FILE) then
        return
    end
    
    local success, result = pcall(function()
        local jsonData = readfile(SAVE_FILE)
        return HttpService:JSONDecode(jsonData)
    end)
    
    if success and result then
        shotData.total = result.total or 0
        shotData.row = result.row or 0
    end
end

-- Save shot data to JSON (total and row)
local function saveShotData()
    local success, err = pcall(function()
        local jsonData = HttpService:JSONEncode({
            total = shotData.total,
            row = shotData.row
        })
        writefile(SAVE_FILE, jsonData)
    end)
    
    if not success then
        warn("Failed to save shot data:", err)
    end
end

-- Display streak rank achievement with visual effects
local function displayStreakRank(rank, currentRow)
	if isDisplaying then
		return
	end
	
	-- Validate rank data
	if not rank or not rank.color or not rank.title or not rank.message then
		warn("Invalid rank data provided to displayStreakRank")
		return
	end

	isDisplaying = true
	print("[RANK UP] Displaying:", rank.title, "| Effect:", rank.effect, "| Row:", currentRow)

	-- Play rank up SFX (special sound for 21+ streaks)
	local rankUpSfx = Instance.new("Sound")
	local sfxPath = "forvids/sfx/tetrio/ratingraise.ogg"
	
	-- Use special levelup sound for streaks 21+
	if currentRow and currentRow >= 21 then
		sfxPath = "forvids/sfx/tetrio/levelup.ogg"
	end
	
	local success, soundId = pcall(function()
		return getcustomasset(sfxPath)
	end)
	if success and soundId then
		rankUpSfx.SoundId = soundId
		rankUpSfx.Volume = 0.8
		rankUpSfx.Parent = game:GetService("SoundService")
		rankUpSfx:Play()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "StreakRankDisplay"
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 800, 0, 400)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Parent = gui

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.25, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = rank.title
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 64
	titleLabel.TextColor3 = rank.color
	titleLabel.TextStrokeTransparency = 0.3
	titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	titleLabel.TextTransparency = 1
	titleLabel.Parent = container

	-- Message
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "MessageLabel"
	messageLabel.Size = UDim2.new(1, 0, 0.2, 0)
	messageLabel.Position = UDim2.new(0, 0, 0.55, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = rank.message
	messageLabel.Font = Enum.Font.GothamBold
	messageLabel.TextSize = 32
	messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	messageLabel.TextStrokeTransparency = 0.5
	titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	messageLabel.TextTransparency = 1
	messageLabel.Parent = container

	-- Effect overlay (different per rank)
	local effectFrame = Instance.new("Frame")
	effectFrame.Name = "EffectFrame"
	effectFrame.Size = UDim2.new(1.5, 0, 1.5, 0)
	effectFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	effectFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	effectFrame.BackgroundColor3 = rank.color
	effectFrame.BackgroundTransparency = 1
	effectFrame.BorderSizePixel = 0
	effectFrame.Parent = container

	task.spawn(function()
		-- Fade in title and message
		local titleFadeIn = TweenService:Create(
			titleLabel,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{TextTransparency = 0}
		)
		local messageFadeIn = TweenService:Create(
			messageLabel,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{TextTransparency = 0.2}
		)
		titleFadeIn:Play()
		messageFadeIn:Play()
		titleFadeIn.Completed:Wait()

		-- Apply visual effect based on rank.effect
		local effectTweens = {}
		
		if rank.effect == "flash_start" then
			-- Simple flash to start (rank 1)
			local flashTween = TweenService:Create(
				effectFrame,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 0.8}
			)
			flashTween:Play()
			flashTween.Completed:Wait()
			local fadeOut = TweenService:Create(
				effectFrame,
				TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{BackgroundTransparency = 1}
			)
			fadeOut:Play()
			
		elseif rank.effect == "faint_glow" then
			-- Faint orange glow
			local glowTween = TweenService:Create(
				effectFrame,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{BackgroundTransparency = 0.85}
			)
			table.insert(effectTweens, glowTween)
			glowTween:Play()
			
		elseif rank.effect == "soft_flash" then
			-- Soft gold flash
			for i = 1, 2 do
				task.spawn(function()
					task.wait((i - 1) * 0.3)
					local flash = TweenService:Create(
						effectFrame,
						TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{BackgroundTransparency = 0.7}
					)
					flash:Play()
					flash.Completed:Wait()
					local fadeOut = TweenService:Create(
						effectFrame,
						TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{BackgroundTransparency = 1}
					)
					fadeOut:Play()
				end)
			end
			
		elseif rank.effect == "pulse" then
			-- Gold-orange pulse
			local pulseTween = TweenService:Create(
				effectFrame,
				TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{BackgroundTransparency = 0.75}
			)
			table.insert(effectTweens, pulseTween)
			pulseTween:Play()
			
		elseif rank.effect == "flicker" then
			-- Fiery flicker
			task.spawn(function()
				for i = 1, 8 do
					effectFrame.BackgroundTransparency = math.random(70, 95) / 100
					task.wait(0.15)
				end
				effectFrame.BackgroundTransparency = 1
			end)
			
		elseif rank.effect == "shake_light" then
			-- Light shake with glow (rank 6)
			local glowTween = TweenService:Create(
				effectFrame,
				TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true),
				{BackgroundTransparency = 0.8}
			)
			table.insert(effectTweens, glowTween)
			glowTween:Play()
			
			-- Light shake
			task.spawn(function()
				local originalPos = container.Position
				for i = 1, 8 do
					local offsetX = math.random(-3, 3)
					local offsetY = math.random(-3, 3)
					container.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
					task.wait(0.08)
				end
				container.Position = originalPos
			end)
			
		elseif rank.effect == "spark_pulse" then
			-- Spark particles with pulse (rank 7)
			local pulseTween = TweenService:Create(
				effectFrame,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{BackgroundTransparency = 0.75}
			)
			table.insert(effectTweens, pulseTween)
			pulseTween:Play()
			
			-- Create spark particles
			for i = 1, 12 do
				task.spawn(function()
					task.wait(math.random() * 2)
					local spark = Instance.new("Frame")
					spark.Size = UDim2.new(0, 8, 0, 8)
					spark.Position = UDim2.new(0.5, 0, 0.5, 0)
					spark.AnchorPoint = Vector2.new(0.5, 0.5)
					spark.BackgroundColor3 = Color3.fromRGB(255, 220, 100)
					spark.BorderSizePixel = 0
					spark.Parent = effectFrame
					
					-- Random direction
					local angle = math.random() * math.pi * 2
					local distance = 150
					local targetX = math.cos(angle) * distance
					local targetY = math.sin(angle) * distance
					
					local sparkTween = TweenService:Create(
						spark,
						TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{
							Position = UDim2.new(0.5, targetX, 0.5, targetY),
							BackgroundTransparency = 1
						}
					)
					sparkTween:Play()
					task.wait(0.8)
					spark:Destroy()
				end)
			end
			
		elseif rank.effect == "red_pulse" then
			-- Red pulse with shake
			local pulseTween = TweenService:Create(
				effectFrame,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{BackgroundTransparency = 0.7}
			)
			table.insert(effectTweens, pulseTween)
			pulseTween:Play()
			
			-- Shake effect
			task.spawn(function()
				local originalPos = container.Position
				for i = 1, 10 do
					local offsetX = math.random(-5, 5)
					local offsetY = math.random(-5, 5)
					container.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
					task.wait(0.05)
				end
				container.Position = originalPos
			end)
			
		elseif rank.effect == "card_flash" then
			-- Playing card flash (rank 9)
			local cardFrame = Instance.new("Frame")
			cardFrame.Size = UDim2.new(0, 120, 0, 180)
			cardFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
			cardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
			cardFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			cardFrame.BorderSizePixel = 3
			cardFrame.BorderColor3 = rank.color
			cardFrame.Parent = effectFrame
			
			-- Card symbol (spade/heart/club/diamond)
			local symbolLabel = Instance.new("TextLabel")
			symbolLabel.Size = UDim2.new(1, 0, 1, 0)
			symbolLabel.BackgroundTransparency = 1
			symbolLabel.Text = "♠"
			symbolLabel.Font = Enum.Font.GothamBold
			symbolLabel.TextSize = 80
			symbolLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
			symbolLabel.Parent = cardFrame
			
			-- Flip and fade animation
			local flipTween = TweenService:Create(
				cardFrame,
				TweenInfo.new(1.0, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Rotation = 360, BackgroundTransparency = 1}
			)
			local symbolFade = TweenService:Create(
				symbolLabel,
				TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{TextTransparency = 1}
			)
			flipTween:Play()
			symbolFade:Play()
			
		elseif rank.effect == "smoke" then
			-- Smoke overlay with low boom
			local boomSfx = Instance.new("Sound")
			boomSfx.SoundId = "rbxasset://sounds/Launching rocket.mp3"
			boomSfx.Volume = 0.3
			boomSfx.PlaybackSpeed = 0.7
			boomSfx.Parent = game:GetService("SoundService")
			boomSfx:Play()
			
			-- Smoke effect (multiple particles)
			for i = 1, 5 do
				task.spawn(function()
					local smoke = Instance.new("Frame")
					smoke.Size = UDim2.new(0, 100, 0, 100)
					smoke.Position = UDim2.new(math.random(20, 80) / 100, 0, math.random(20, 80) / 100, 0)
					smoke.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					smoke.BackgroundTransparency = 0.5
					smoke.BorderSizePixel = 0
					smoke.Parent = effectFrame
					
					local smokeTween = TweenService:Create(
						smoke,
						TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{BackgroundTransparency = 1, Size = UDim2.new(0, 200, 0, 200)}
					)
					smokeTween:Play()
					task.wait(1.5)
					smoke:Destroy()
				end)
			end
			
		elseif rank.effect == "smoke_flash" then
			-- Smoke with bright flash (rank 11)
			-- Flash first
			local flashTween = TweenService:Create(
				effectFrame,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 0.5}
			)
			flashTween:Play()
			flashTween.Completed:Wait()
			
			-- Then smoke
			for i = 1, 8 do
				task.spawn(function()
					task.wait(math.random() * 0.5)
					local smoke = Instance.new("Frame")
					smoke.Size = UDim2.new(0, 80, 0, 80)
					smoke.Position = UDim2.new(math.random(15, 85) / 100, 0, math.random(15, 85) / 100, 0)
					smoke.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
					smoke.BackgroundTransparency = 0.4
					smoke.BorderSizePixel = 0
					smoke.Parent = effectFrame
					
					local smokeTween = TweenService:Create(
						smoke,
						TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{BackgroundTransparency = 1, Size = UDim2.new(0, 250, 0, 250)}
					)
					smokeTween:Play()
					task.wait(2)
					smoke:Destroy()
				end)
			end
			
			local fadeOut = TweenService:Create(
				effectFrame,
				TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{BackgroundTransparency = 1}
			)
			fadeOut:Play()
			
		elseif rank.effect == "reticle_flash" then
			-- Glowing reticle flash
			local reticle = Instance.new("Frame")
			reticle.Size = UDim2.new(0, 60, 0, 60)
			reticle.Position = UDim2.new(0.5, 0, 0.5, 0)
			reticle.AnchorPoint = Vector2.new(0.5, 0.5)
			reticle.BackgroundTransparency = 1
			reticle.BorderSizePixel = 0
			reticle.Parent = effectFrame
			
			local crosshairH = Instance.new("Frame")
			crosshairH.Size = UDim2.new(1, 0, 0, 3)
			crosshairH.Position = UDim2.new(0, 0, 0.5, 0)
			crosshairH.AnchorPoint = Vector2.new(0, 0.5)
			crosshairH.BackgroundColor3 = rank.color
			crosshairH.BorderSizePixel = 0
			crosshairH.Parent = reticle
			
			local crosshairV = Instance.new("Frame")
			crosshairV.Size = UDim2.new(0, 3, 1, 0)
			crosshairV.Position = UDim2.new(0.5, 0, 0, 0)
			crosshairV.AnchorPoint = Vector2.new(0.5, 0)
			crosshairV.BackgroundColor3 = rank.color
			crosshairV.BorderSizePixel = 0
			crosshairV.Parent = reticle
			
			local flashTween = TweenService:Create(
				reticle,
				TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = UDim2.new(0, 200, 0, 200)}
			)
			flashTween:Play()
			
		elseif rank.effect == "light_burst" then
			-- Bright light burst (rank 13)
			-- Central bright flash
			local burstTween = TweenService:Create(
				effectFrame,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 0.3, BackgroundColor3 = Color3.fromRGB(255, 255, 255)}
			)
			burstTween:Play()
			burstTween.Completed:Wait()
			
			-- Rays shooting outward
			for i = 1, 8 do
				task.spawn(function()
					local angle = (i - 1) * (math.pi * 2 / 8)
					local ray = Instance.new("Frame")
					ray.Size = UDim2.new(0, 15, 0, 200)
					ray.Position = UDim2.new(0.5, 0, 0.5, 0)
					ray.AnchorPoint = Vector2.new(0.5, 1)
					ray.Rotation = math.deg(angle)
					ray.BackgroundColor3 = Color3.fromRGB(255, 255, 200)
					ray.BorderSizePixel = 0
					ray.Parent = effectFrame
					
					local rayTween = TweenService:Create(
						ray,
						TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{BackgroundTransparency = 1, Size = UDim2.new(0, 15, 0, 400)}
					)
					rayTween:Play()
					task.wait(0.8)
					ray:Destroy()
				end)
			end
			
			local fadeOut = TweenService:Create(
				effectFrame,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{BackgroundTransparency = 1}
			)
			fadeOut:Play()
			
		elseif rank.effect == "dark_bloom" then
			-- Dark red bloom
			local bloomTween = TweenService:Create(
				effectFrame,
				TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 0.6, Size = UDim2.new(2.5, 0, 2.5, 0)}
			)
			table.insert(effectTweens, bloomTween)
			bloomTween:Play()
			
		elseif rank.effect == "gold_flicker" then
			-- Fast gold-white flicker
			task.spawn(function()
				for i = 1, 15 do
					if i % 2 == 0 then
						effectFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					else
						effectFrame.BackgroundColor3 = rank.color
					end
					effectFrame.BackgroundTransparency = 0.6
					task.wait(0.08)
					effectFrame.BackgroundTransparency = 1
					task.wait(0.08)
				end
			end)
			
		elseif rank.effect == "lightning" then
			-- Golden lightning flash
			for i = 1, 4 do
				task.spawn(function()
					task.wait((i - 1) * 0.2)
					local lightning = Instance.new("Frame")
					lightning.Size = UDim2.new(0, 10, 2, 0)
					lightning.Position = UDim2.new(math.random(10, 90) / 100, 0, -0.5, 0)
					lightning.Rotation = math.random(-30, 30)
					lightning.BackgroundColor3 = Color3.fromRGB(255, 255, 200)
					lightning.BorderSizePixel = 0
					lightning.Parent = effectFrame
					
					task.wait(0.1)
					lightning:Destroy()
				end)
			end
			
		elseif rank.effect == "glow_aura" then
			-- Glowing aura (rank 17)
			local auraTween = TweenService:Create(
				effectFrame,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{BackgroundTransparency = 0.6, Size = UDim2.new(2, 0, 2, 0)}
			)
			table.insert(effectTweens, auraTween)
			auraTween:Play()
			
			-- Rotating glow particles
			for i = 1, 6 do
				task.spawn(function()
					local angle = (i - 1) * (math.pi * 2 / 6)
					local particle = Instance.new("Frame")
					particle.Size = UDim2.new(0, 20, 0, 20)
					particle.BackgroundColor3 = Color3.fromRGB(255, 220, 150)
					particle.BorderSizePixel = 0
					particle.Parent = effectFrame
					
					-- Orbit animation
					for t = 0, 2.5, 0.05 do
						local currentAngle = angle + t * 2
						local radius = 150
						local x = math.cos(currentAngle) * radius
						local y = math.sin(currentAngle) * radius
						particle.Position = UDim2.new(0.5, x, 0.5, y)
						task.wait(0.05)
					end
					particle:Destroy()
				end)
			end
			
		elseif rank.effect == "gold_flash" then
			-- Intense gold flash (rank 18)
			local flashTween = TweenService:Create(
				effectFrame,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 0.2, BackgroundColor3 = Color3.fromRGB(255, 215, 0)}
			)
			flashTween:Play()
			flashTween.Completed:Wait()
			
			-- Pulsing aftermath
			local pulseTween = TweenService:Create(
				effectFrame,
				TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true),
				{BackgroundTransparency = 0.7}
			)
			table.insert(effectTweens, pulseTween)
			pulseTween:Play()
			
		elseif rank.effect == "divine_flash" then
			-- Divine white-gold flash (rank 19)
			local divineFlash = TweenService:Create(
				effectFrame,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 0.1, BackgroundColor3 = Color3.fromRGB(255, 255, 255)}
			)
			divineFlash:Play()
			divineFlash.Completed:Wait()
			
			-- Cross beams of light
			for i = 1, 4 do
				task.spawn(function()
					local beam = Instance.new("Frame")
					beam.Size = UDim2.new(3, 0, 0, 8)
					beam.Position = UDim2.new(0.5, 0, 0.5, 0)
					beam.AnchorPoint = Vector2.new(0.5, 0.5)
					beam.Rotation = (i - 1) * 45
					beam.BackgroundColor3 = Color3.fromRGB(255, 250, 200)
					beam.BorderSizePixel = 0
					beam.Parent = effectFrame
					
					local beamTween = TweenService:Create(
						beam,
						TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{BackgroundTransparency = 1}
					)
					beamTween:Play()
					task.wait(1.2)
					beam:Destroy()
				end)
			end
			
			local fadeOut = TweenService:Create(
				effectFrame,
				TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{BackgroundTransparency = 1}
			)
			fadeOut:Play()
			
		elseif rank.effect == "jackpot_burst" then
			-- Jackpot burst (rank 20)
			-- Triple flash burst
			for flash = 1, 3 do
				task.spawn(function()
					task.wait((flash - 1) * 0.3)
					local burstTween = TweenService:Create(
						effectFrame,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{BackgroundTransparency = 0.3}
					)
					burstTween:Play()
					burstTween.Completed:Wait()
					local fadeOut = TweenService:Create(
						effectFrame,
						TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{BackgroundTransparency = 1}
					)
					fadeOut:Play()
				end)
			end
			
			-- Coin rain effect
			for i = 1, 20 do
				task.spawn(function()
					task.wait(math.random() * 0.8)
					local coin = Instance.new("Frame")
					coin.Size = UDim2.new(0, 30, 0, 30)
					coin.Position = UDim2.new(math.random() * 1, 0, -0.1, 0)
					coin.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
					coin.BorderSizePixel = 2
					coin.BorderColor3 = Color3.fromRGB(200, 150, 0)
					coin.Parent = effectFrame
					
					local coinTween = TweenService:Create(
						coin,
						TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{Position = UDim2.new(coin.Position.X.Scale, 0, 1.2, 0), Rotation = 360}
					)
					coinTween:Play()
					task.wait(1.5)
					coin:Destroy()
				end)
			end
			
		elseif rank.effect == "jackpot_loop" then
			-- Continuous jackpot effect (rank 21+)
			-- Constant golden glow
			local glowTween = TweenService:Create(
				effectFrame,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{BackgroundTransparency = 0.5}
			)
			table.insert(effectTweens, glowTween)
			glowTween:Play()
			
			-- Spiraling particles
			task.spawn(function()
				for i = 1, 25 do
					task.wait(0.1)
					local particle = Instance.new("Frame")
					particle.Size = UDim2.new(0, 15, 0, 15)
					particle.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
					particle.BorderSizePixel = 0
					particle.Parent = effectFrame
					
					-- Spiral outward
					local startAngle = math.random() * math.pi * 2
					task.spawn(function()
						for t = 0, 1.5, 0.05 do
							local angle = startAngle + t * 4
							local radius = t * 200
							local x = math.cos(angle) * radius
							local y = math.sin(angle) * radius
							particle.Position = UDim2.new(0.5, x, 0.5, y)
							particle.BackgroundTransparency = t / 1.5
							task.wait(0.05)
						end
						particle:Destroy()
					end)
				end
			end)
		end

		-- Hold for 2.5 seconds
		task.wait(2.5)

		-- Stop all effect tweens
		for _, tween in pairs(effectTweens) do
			tween:Cancel()
		end

		-- Fade out
		local titleFadeOut = TweenService:Create(
			titleLabel,
			TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{TextTransparency = 1}
		)
		local messageFadeOut = TweenService:Create(
			messageLabel,
			TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{TextTransparency = 1}
		)
		local effectFadeOut = TweenService:Create(
			effectFrame,
			TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{BackgroundTransparency = 1}
		)

		titleFadeOut:Play()
		messageFadeOut:Play()
		effectFadeOut:Play()
		titleFadeOut.Completed:Wait()

		-- Cleanup
		gui:Destroy()
		if rankUpSfx then
			rankUpSfx:Destroy()
		end
		isDisplaying = false
	end)
end

-- Display shot counter
local function displayShotCounter()
    if isDisplaying then
        return
    end
    
    isDisplaying = true
    
	-- Increment counters
    shotData.total = shotData.total + 1
    shotData.row = shotData.row + 1  -- Row increases (streak and ROW are the same)
    
    print("[SHOT COUNTER] Total:", shotData.total, "| Row:", shotData.row)
    
    -- Check for streak rank achievement (using ROW)
    local rankToDisplay = nil
    for _, rank in ipairs(STREAK_RANKS) do
        if shotData.row == rank.threshold then
            rankToDisplay = rank
            break
        end
    end
    
    -- For streaks 21+, use the max rank (tier = "max")
    if not rankToDisplay and shotData.row >= 21 then
        for _, rank in ipairs(STREAK_RANKS) do
            if rank.tier == "max" then
                rankToDisplay = rank
                break
            end
        end
    end
    
    if rankToDisplay then
        print("[STREAK RANK] Reached rank:", rankToDisplay.title, "at row", shotData.row)
        task.spawn(function()
            displayStreakRank(rankToDisplay, shotData.row)
        end)
    end
    
    -- Save total to JSON
    saveShotData()
    
    -- Create GUI
    local gui = Instance.new("ScreenGui")
    gui.Name = "ShotCounterDisplay"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")
    
    -- Main container
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 700, 0, 300)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1
    container.Parent = gui
    
    -- Left side: SHOT label and number
    local shotLabel = Instance.new("TextLabel")
    shotLabel.Name = "ShotLabel"
	shotLabel.Size = UDim2.new(0.28, 0, 0.35, 0)
	shotLabel.Position = UDim2.new(0.22, 0, 0.12, 0)
    shotLabel.BackgroundTransparency = 1
    shotLabel.Text = "SHOT"
    shotLabel.Font = Enum.Font.GothamBold
    shotLabel.TextSize = 44
    shotLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    shotLabel.TextStrokeTransparency = 0.5
    shotLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    shotLabel.Parent = container
    
    -- SHOT number container (below SHOT label, smaller than ROW)
    local shotNumberClip = Instance.new("Frame")
    shotNumberClip.Name = "ShotNumberClip"
	shotNumberClip.Size = UDim2.new(0.28, 0, 0.4, 0)
	shotNumberClip.Position = UDim2.new(0.22, 0, 0.5, 0)
    shotNumberClip.BackgroundTransparency = 1
    shotNumberClip.ClipsDescendants = true
    shotNumberClip.Parent = container

    -- SHOT scrolling frame
    local shotScrollFrame = Instance.new("Frame")
    shotScrollFrame.Name = "ShotScrollFrame"
    shotScrollFrame.Size = UDim2.new(1, 0, 2, 0)
    shotScrollFrame.Position = UDim2.new(0, 0, 0, 0)
    shotScrollFrame.BackgroundTransparency = 1
    shotScrollFrame.Parent = shotNumberClip

    -- Create SHOT number labels (current and next)
    local currentTotal = math.max(0, shotData.total - 1)
    local nextTotal = shotData.total

    local function createShotNumberLabel(number, yOffset)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0.5, 0)
        label.Position = UDim2.new(0, 0, yOffset, 0)
        label.BackgroundTransparency = 1
        label.Text = tostring(number)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 56
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0.5
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.Parent = shotScrollFrame
        return label
    end

    -- Create current total (top) and next total (bottom)
    createShotNumberLabel(currentTotal, 0)
    createShotNumberLabel(nextTotal, 0.5)
    
    -- Right side: ROW label (bigger and more prominent)
    local rowLabel = Instance.new("TextLabel")
    rowLabel.Name = "RowLabel"
    rowLabel.Size = UDim2.new(0.68, 0, 0.4, 0)
	rowLabel.Position = UDim2.new(0.295, 0, 0.08, 0)
    rowLabel.BackgroundTransparency = 1
    rowLabel.Text = "ROW"
    rowLabel.Font = Enum.Font.GothamBold
    rowLabel.TextSize = 72
    rowLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    rowLabel.TextStrokeTransparency = 0.5
    rowLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    rowLabel.Parent = container
    
    -- ROW number container (below ROW label, bigger)
    local rowNumberClip = Instance.new("Frame")
    rowNumberClip.Name = "RowNumberClip"
    rowNumberClip.Size = UDim2.new(0.68, 0, 0.4, 0)
	rowNumberClip.Position = UDim2.new(0.295, 0, 0.5, 0)
    rowNumberClip.BackgroundTransparency = 1
    rowNumberClip.ClipsDescendants = true
    rowNumberClip.Parent = container
    
    -- ROW scrolling frame
    local rowScrollFrame = Instance.new("Frame")
    rowScrollFrame.Name = "RowScrollFrame"
    rowScrollFrame.Size = UDim2.new(1, 0, 2, 0)
    rowScrollFrame.Position = UDim2.new(0, 0, 0, 0)
    rowScrollFrame.BackgroundTransparency = 1
    rowScrollFrame.Parent = rowNumberClip
    
    -- Create ROW number labels (current and next)
    local currentRow = math.max(0, shotData.row - 1)
    local nextRow = shotData.row
    
    local function createRowNumberLabel(number, yOffset)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0.5, 0)
        label.Position = UDim2.new(0, 0, yOffset, 0)
        label.BackgroundTransparency = 1
        label.Text = tostring(number)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 88
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0.5
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.Parent = rowScrollFrame
        return label
    end
    
    -- Create current row (top) and next row (bottom)
    createRowNumberLabel(currentRow, 0)
    createRowNumberLabel(nextRow, 0.5)
    
    -- Set initial state
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(0, 0, 0, 0)
    
    -- Set all child elements to transparent initially
    for _, child in pairs(container:GetDescendants()) do
        if child:IsA("GuiObject") then
            child.BackgroundTransparency = 1
            if child:IsA("TextLabel") then
                child.TextTransparency = 1
            end
        end
    end
    
    task.spawn(function()
        
        -- Use persistent music or create new one
        local zenithSound = persistentMusic
        
        if not zenithSound or not zenithSound.Parent then
            -- Create new music
            zenithSound = Instance.new("Sound")
            zenithSound.SoundId = getcustomasset("forvids/sfx/zenith.mp3")
            zenithSound.Volume = 0
            zenithSound.TimePosition = musicTimePosition
            zenithSound.Parent = game:GetService("SoundService")
            zenithSound:Play()
            persistentMusic = zenithSound
        else
            -- Resume existing music
            zenithSound.Volume = 0
            if not zenithSound.Playing then
                zenithSound:Play()
            end
        end
        
        -- Fade in the music
        local fadeInSound = TweenService:Create(
            zenithSound,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Volume = 0.25}
        )
        fadeInSound:Play()
        
        -- Phase 1: Fade in with scale (0.4s) - from 0 to 1
        local fadeInTween = TweenService:Create(
            container,
            TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 700, 0, 300)}
        )
        
        -- Fade in all text elements
        local fadeInTexts = {}
        for _, child in pairs(container:GetDescendants()) do
            if child:IsA("TextLabel") then
                table.insert(fadeInTexts, TweenService:Create(
                    child,
                    TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {TextTransparency = 0}
                ))
            end
        end
        fadeInTween:Play()
        for _, textTween in pairs(fadeInTexts) do
            textTween:Play()
        end
        fadeInTween.Completed:Wait()
        
        -- Wait 1 second before rolling
        task.wait(1)
        
	-- Phase 2: Elevator roll animation (0.8s) - Roll up SHOT and ROW numbers
	-- Play SHOT increment SFX while rolling
	local shotIncrementSfx = Instance.new("Sound")
	shotIncrementSfx.SoundId = getcustomasset("forvids/sfx/tetrio/mmstart.ogg")
	shotIncrementSfx.Volume = 1
	shotIncrementSfx.Parent = game:GetService("SoundService")
        local rowRollTween = TweenService:Create(
            rowScrollFrame,
            TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, 0, -1, 0)}  -- Move up full height to show next row number
        )
        local shotRollTween = TweenService:Create(
            shotScrollFrame,
            TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, 0, -1, 0)}  -- Move up full height to show next total number
        )
	rowRollTween:Play()
        shotRollTween:Play()
	shotIncrementSfx:Play()
        rowRollTween.Completed:Wait()
        
        -- Phase 3: Hold (1s)
        task.wait(1)
        
        -- Phase 4: Fade out (5s)
        local fadeOutTexts = {}
        for _, child in pairs(container:GetDescendants()) do
            if child:IsA("TextLabel") then
                table.insert(fadeOutTexts, TweenService:Create(
                    child,
                    TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {TextTransparency = 1}
                ))
            end
        end
        for _, textTween in pairs(fadeOutTexts) do
            textTween:Play()
        end
        
        -- Fade out the music simultaneously
        local fadeOutSound = TweenService:Create(
            zenithSound,
            TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Volume = 0}
        )
        fadeOutSound:Play()
        
        -- Wait for fade out to complete
        if fadeOutTexts[1] then
            fadeOutTexts[1].Completed:Wait()
        end
        
        -- Save music position and keep music playing
        musicTimePosition = zenithSound.TimePosition
        
        -- Cleanup
		gui:Destroy()
		if shotIncrementSfx then
			shotIncrementSfx:Destroy()
		end
        isDisplaying = false
        
        -- Check if we hit a streak milestone after the counter display (using ROW)
        local currentRow = shotData.row
        print("[STREAK CHECK] Current row:", currentRow)
        
        local rankToDisplay = nil
        for _, rank in ipairs(STREAK_RANKS) do
            if currentRow == rank.threshold then
                rankToDisplay = rank
                break
            end
        end
        
        -- For streaks 21+, use the max rank (tier = "max")
        if not rankToDisplay and currentRow >= 21 then
            for _, rank in ipairs(STREAK_RANKS) do
                if rank.tier == "max" then
                    rankToDisplay = rank
                    break
                end
            end
        end
        
        if rankToDisplay then
            print("[STREAK MILESTONE] Reached threshold:", rankToDisplay.threshold, "- Title:", rankToDisplay.title)
            local success, err = pcall(function()
                displayStreakRank(rankToDisplay, currentRow)
            end)
            if not success then
                warn("Error displaying streak rank:", err)
            end
        end
    end)
end

-- Display streak broken notification
local function displayStreakBroken()
	if isDisplaying then
		return
	end

	isDisplaying = true

	-- Play card tearing/breaking SFX
	local tearSfx = Instance.new("Sound")
	tearSfx.SoundId = "rbxasset://sounds/snap.mp3"
	tearSfx.Volume = 0.7
	tearSfx.PlaybackSpeed = 0.8
	tearSfx.Parent = game:GetService("SoundService")
	tearSfx:Play()

	local gui = Instance.new("ScreenGui")
	gui.Name = "StreakBrokenDisplay"
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 800, 0, 400)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Parent = gui

	-- Message
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "MessageLabel"
	messageLabel.Size = UDim2.new(1, 0, 0.3, 0)
	messageLabel.Position = UDim2.new(0, 0, 0.1, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = "Streak broken."
	messageLabel.Font = Enum.Font.GothamBold
	messageLabel.TextSize = 48
	messageLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	messageLabel.TextStrokeTransparency = 0.5
	messageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	messageLabel.TextTransparency = 0
	messageLabel.Parent = container

	-- ROW label showing it rolling back to 0
	local rowLabel = Instance.new("TextLabel")
	rowLabel.Name = "RowLabel"
	rowLabel.Size = UDim2.new(1, 0, 0.2, 0)
	rowLabel.Position = UDim2.new(0, 0, 0.45, 0)
	rowLabel.BackgroundTransparency = 1
	rowLabel.Text = "ROW"
	rowLabel.Font = Enum.Font.GothamBold
	rowLabel.TextSize = 56
	rowLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	rowLabel.TextStrokeTransparency = 0.5
	rowLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	rowLabel.TextTransparency = 0
	rowLabel.Parent = container

	-- ROW number that will animate down
	local rowNumberLabel = Instance.new("TextLabel")
	rowNumberLabel.Name = "RowNumberLabel"
	rowNumberLabel.Size = UDim2.new(1, 0, 0.25, 0)
	rowNumberLabel.Position = UDim2.new(0, 0, 0.65, 0)
	rowNumberLabel.BackgroundTransparency = 1
	rowNumberLabel.Text = tostring(shotData.row)
	rowNumberLabel.Font = Enum.Font.GothamBold
	rowNumberLabel.TextSize = 64
	rowNumberLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	rowNumberLabel.TextStrokeTransparency = 0.5
	rowNumberLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	rowNumberLabel.TextTransparency = 0
	rowNumberLabel.Parent = container

	-- Smoke overlay effect
	local smokeFrame = Instance.new("Frame")
	smokeFrame.Name = "SmokeFrame"
	smokeFrame.Size = UDim2.new(2, 0, 2, 0)
	smokeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	smokeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	smokeFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	smokeFrame.BackgroundTransparency = 0.3
	smokeFrame.BorderSizePixel = 0
	smokeFrame.Parent = container

	-- Health flicker effect (simulate by flashing red overlay)
	local healthFlicker = Instance.new("Frame")
	healthFlicker.Name = "HealthFlicker"
	healthFlicker.Size = UDim2.new(1, 0, 1, 0)
	healthFlicker.Position = UDim2.new(0, 0, 0, 0)
	healthFlicker.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	healthFlicker.BackgroundTransparency = 1
	healthFlicker.BorderSizePixel = 0
	healthFlicker.ZIndex = 10
	healthFlicker.Parent = player.PlayerGui

	local currentRow = shotData.row

	task.spawn(function()
		-- Smoke disperses immediately
		local smokeTween = TweenService:Create(
			smokeFrame,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1, Size = UDim2.new(3, 0, 3, 0)}
		)
		smokeTween:Play()

		-- Health flicker (brief red flash) starts immediately
		task.spawn(function()
			for i = 1, 3 do
				local flashIn = TweenService:Create(
					healthFlicker,
					TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{BackgroundTransparency = 0.6}
				)
				flashIn:Play()
				flashIn.Completed:Wait()
				local flashOut = TweenService:Create(
					healthFlicker,
					TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{BackgroundTransparency = 1}
				)
				flashOut:Play()
				flashOut.Completed:Wait()
			end
		end)

		-- Small delay before starting rollback
		task.wait(0.3)

		-- Animate ROW rolling down to 0 (MAIN FEATURE)
		local rollDuration = 1.2
		local startTime = tick()
		while tick() - startTime < rollDuration do
			local elapsed = tick() - startTime
			local progress = elapsed / rollDuration
			-- Ease out for smoother rollback
			local easedProgress = 1 - math.pow(1 - progress, 3)
			local currentValue = math.floor(currentRow * (1 - easedProgress))
			rowNumberLabel.Text = tostring(currentValue)
			
			-- Make the number pulse red as it decreases
			local pulseIntensity = math.sin(progress * 10) * 0.3 + 0.7
			rowNumberLabel.TextColor3 = Color3.fromRGB(255, 100 * pulseIntensity, 100 * pulseIntensity)
			
			task.wait(0.02)
		end
		rowNumberLabel.Text = "0"
		rowNumberLabel.TextColor3 = Color3.fromRGB(150, 150, 150)

		-- Hold on 0 for a moment
		task.wait(0.5)

		-- Fade out text in gray smoke
		local messageFadeOut = TweenService:Create(
			messageLabel,
			TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{TextTransparency = 1}
		)
		local rowLabelFadeOut = TweenService:Create(
			rowLabel,
			TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{TextTransparency = 1}
		)
		local rowNumberFadeOut = TweenService:Create(
			rowNumberLabel,
			TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{TextTransparency = 1}
		)
		messageFadeOut:Play()
		rowLabelFadeOut:Play()
		rowNumberFadeOut:Play()
		messageFadeOut.Completed:Wait()

		-- Cleanup
		gui:Destroy()
		healthFlicker:Destroy()
		if tearSfx then
			tearSfx:Destroy()
		end

		-- Reset ROW (streak and ROW are the same)
		shotData.row = 0
		saveShotData()  -- Save ROW reset to JSON

		isDisplaying = false
	end)
end

-- Display a dedicated ROW reset animation that rolls the ROW number down to 0
local function displayRowResetToZero()
	if isDisplaying then
		return
	end

	isDisplaying = true

	local gui = Instance.new("ScreenGui")
	gui.Name = "RowResetDisplay"
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 700, 0, 300)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Parent = gui

	local rowLabel = Instance.new("TextLabel")
	rowLabel.Name = "RowLabel"
	rowLabel.Size = UDim2.new(0.68, 0, 0.4, 0)
	rowLabel.Position = UDim2.new(0.295, 0, 0.08, 0)
	rowLabel.BackgroundTransparency = 1
	rowLabel.Text = "ROW"
	rowLabel.Font = Enum.Font.GothamBold
	rowLabel.TextSize = 72
	rowLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	rowLabel.TextStrokeTransparency = 0.5
	rowLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	rowLabel.Parent = container

	local rowNumberClip = Instance.new("Frame")
	rowNumberClip.Name = "RowNumberClip"
	rowNumberClip.Size = UDim2.new(0.68, 0, 0.4, 0)
	rowNumberClip.Position = UDim2.new(0.295, 0, 0.5, 0)
	rowNumberClip.BackgroundTransparency = 1
	rowNumberClip.ClipsDescendants = true
	rowNumberClip.Parent = container

	local rowScrollFrame = Instance.new("Frame")
	rowScrollFrame.Name = "RowScrollFrame"
	rowScrollFrame.Size = UDim2.new(1, 0, 2, 0)
	rowScrollFrame.Position = UDim2.new(0, 0, 0, 0)
	rowScrollFrame.BackgroundTransparency = 1
	rowScrollFrame.Parent = rowNumberClip

	local currentRow = shotData.row

	local function createRowNumberLabel(number, yOffset)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0.5, 0)
		label.Position = UDim2.new(0, 0, yOffset, 0)
		label.BackgroundTransparency = 1
		label.Text = tostring(number)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 88
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeTransparency = 0.5
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.Parent = rowScrollFrame
		return label
	end

	createRowNumberLabel(currentRow, 0)
	createRowNumberLabel(0, 0.5)

	container.BackgroundTransparency = 1
	container.Size = UDim2.new(0, 0, 0, 0)

	for _, child in pairs(container:GetDescendants()) do
		if child:IsA("GuiObject") then
			child.BackgroundTransparency = 1
			if child:IsA("TextLabel") then
				child.TextTransparency = 1
			end
		end
	end

	task.spawn(function()
		local fadeInTween = TweenService:Create(
			container,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 700, 0, 300)}
		)

		local fadeInTexts = {}
		for _, child in pairs(container:GetDescendants()) do
			if child:IsA("TextLabel") then
				table.insert(fadeInTexts, TweenService:Create(
					child,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{TextTransparency = 0}
				))
			end
		end
		fadeInTween:Play()
		for _, textTween in pairs(fadeInTexts) do
			textTween:Play()
		end
		fadeInTween.Completed:Wait()

		-- Short hold then roll down to 0
		task.wait(0.4)

		-- Play elevator sound effect during roll
		local elevatorSfx = Instance.new("Sound")
		local success, soundId = pcall(function()
			return getcustomasset("forvids/sfx/tetrio/mmstart.ogg")
		end)
		if success and soundId then
			elevatorSfx.SoundId = soundId
			elevatorSfx.Volume = 1
			elevatorSfx.Parent = game:GetService("SoundService")
			elevatorSfx:Play()
		end

		local rowRollTween = TweenService:Create(
			rowScrollFrame,
			TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{Position = UDim2.new(0, 0, -1, 0)}
		)
		rowRollTween:Play()
		rowRollTween.Completed:Wait()

		-- Update data after visual reset
		shotData.row = 0
		saveShotData()  -- Save ROW reset to JSON

		-- Fade out
		local fadeOutTexts = {}
		for _, child in pairs(container:GetDescendants()) do
			if child:IsA("TextLabel") then
				table.insert(fadeOutTexts, TweenService:Create(
					child,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{TextTransparency = 1}
				))
			end
		end
		for _, textTween in pairs(fadeOutTexts) do
			textTween:Play()
		end
		if fadeOutTexts[1] then
			fadeOutTexts[1].Completed:Wait()
		end

		gui:Destroy()
		if elevatorSfx then
			elevatorSfx:Destroy()
		end
		isDisplaying = false
	end)
end

-- Handle animation played
local function onAnimationPlayed(animationTrack)
    if not scriptEnabled then return end
    
	local currentId = animationTrack.Animation.AnimationId

	-- Check if it's one of the streak-breaking animations (138008678294576 or 108014891454394)
	if RESET_ANIMATION_IDS[currentId] then
		-- Show streak broken if there was an active ROW streak
		if shotData.row > 0 then
			displayStreakBroken()
		end
		-- Note: displayStreakBroken already resets ROW to 0
		previousAnimationId = currentId
		return
	end

	-- Check if it's the target animation (success)
	if currentId == TARGET_ANIMATION_ID then
		displayShotCounter()
	end

	previousAnimationId = currentId
end

-- Monitor animations
local function setupAnimationTracking()
    local animationTrack = humanoid:GetPlayingAnimationTracks()
    
    -- Connect to AnimationPlayed
    local animConnection = humanoid.AnimationPlayed:Connect(onAnimationPlayed)
    table.insert(connections, animConnection)
    
    print("🎯 Shot counter script loaded!")
    print("Monitoring animation:", TARGET_ANIMATION_ID)
end

-- Toggle script with Right Shift + Q, destroy with P
local function setupToggle()
    local toggleConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Q and UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
            scriptEnabled = not scriptEnabled
            print("🎯 Shot counter script:", scriptEnabled and "ENABLED" or "DISABLED")
        elseif input.KeyCode == Enum.KeyCode.P then
            -- COMPLETELY DESTROY EVERYTHING - script, GUI, and all connections
            print("💥 Shot counter COMPLETELY DESTROYED - script stopped")
            
            -- First, destroy the GUI with quick fade out
            local existingGui = player.PlayerGui:FindFirstChild("ShotCounterDisplay")
            if existingGui then
                local container = existingGui:FindFirstChild("Container")
                if container then
                    -- Quick fade out all text
                    local quickFades = {}
                    for _, child in pairs(container:GetDescendants()) do
                        if child:IsA("TextLabel") then
                            table.insert(quickFades, TweenService:Create(
                                child,
                                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                                {TextTransparency = 1}
                            ))
                        end
                    end
                    
                    for _, fade in pairs(quickFades) do
                        fade:Play()
                    end
                    
                    if quickFades[1] then
                        quickFades[1].Completed:Wait()
                    end
                end
                existingGui:Destroy()
            end
            
            -- Disconnect ALL connections (remote events, input listeners, everything)
            for _, connection in pairs(connections) do
                connection:Disconnect()
            end
            
            -- Clear the connections table
            connections = {}
            
            -- Disable the script completely
            scriptEnabled = false
            isDisplaying = false
            
            -- This will stop the script from responding to anything further
            return
        end
    end)
    
    table.insert(connections, toggleConnection)
end

-- Cleanup function
local function cleanup()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    connections = {}
    
    -- Stop music
    if persistentMusic then
        persistentMusic:Stop()
        persistentMusic:Destroy()
        persistentMusic = nil
    end
    
    -- Remove GUI if exists
    local existingGui = player.PlayerGui:FindFirstChild("ShotCounterDisplay")
    if existingGui then
        existingGui:Destroy()
    end
end

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
    cleanup()
    
    
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    task.wait(1)
    setupAnimationTracking()
    setupToggle()  -- Re-setup toggle after cleanup
end)

-- Initialize
loadShotData()
setupAnimationTracking()
setupToggle()

-- Mark script as successfully loaded
_G.ShotCounterLOADED = true
print("✅ Shot Counter successfully loaded!")

-- Cleanup on script removal (works in client executors)
if script then
    script.Destroying:Connect(cleanup)
end

