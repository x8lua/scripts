local RunService = game:GetService("RunService")

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local HttpService = cloneref(game:GetService("HttpService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer
local SoundService = cloneref(game:GetService("SoundService"))
local Debris = cloneref(game:GetService("Debris"))

-- // Load xGui (Dear ImGui-Style UI Library)
local xGui
do
	local commitSha = "main"
	local apiOk, commitJson = pcall(function()
		return game:HttpGet("https://api.github.com/repos/x8lua/scripts/commits/main?t=" .. tostring(tick()))
	end)
	if apiOk and commitJson then
		local decodeOk, commitData = pcall(function()
			return HttpService:JSONDecode(commitJson)
		end)
		if decodeOk and commitData and commitData.sha then
			commitSha = commitData.sha
		end
	end
	xGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/x8lua/scripts/" .. commitSha .. "/imgui-roblox/ImGui.lua"))()
end

-- // Vehicle Physics State Variables
local velocityEnabled = true
local flightEnabled = false
local flightSpeed = 1
local velocityEnabledKeyCode = Enum.KeyCode.W
local qbEnabledKeyCode = Enum.KeyCode.S

-- // Normal Profile variables
local normal_velocityMult = 0.025
local normal_turnAssistPower = 3.5
local normal_velocityMult2 = 0.15
local normal_ACCEL_ATTACK = 0.05
local normal_ACCEL_RELEASE = 0.03
local normal_TURN_ATTACK = 0.1
local normal_TURN_RELEASE = 0.15

-- // Shift Profile variables
local shift_velocityMult = 0.065
local shift_turnAssistPower = 5.5
local shift_velocityMult2 = 0.25
local shift_ACCEL_ATTACK = 0.12
local shift_ACCEL_RELEASE = 0.02
local shift_TURN_ATTACK = 0.20
local shift_TURN_RELEASE = 0.25

-- // Fading variables
local BRAKE_ATTACK = 0.08
local BRAKE_RELEASE = 0.05
local currentAccelFade = 0
local currentBrakeFade = 0
local currentTurnFade = 0

local isProfileShifted = false
local isNitroActive = false

-- // Nitro sound setup
local nitroOnceSound = Instance.new("Sound")
nitroOnceSound.SoundId = "rbxassetid://1386598740"
nitroOnceSound.Volume = 1.5
nitroOnceSound.Looped = false
nitroOnceSound.Parent = SoundService

local nitroLoopSound = Instance.new("Sound")
nitroLoopSound.SoundId = "rbxassetid://9058734199"
nitroLoopSound.Volume = 1.5
nitroLoopSound.Looped = true
nitroLoopSound.Parent = SoundService

-- // Create xGui Window
local Window = xGui.new("Larpisted", Enum.KeyCode.RightBracket)

-- Shift & Nitro monitoring with xGui Notification
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.KeyCode == Enum.KeyCode.LeftShift and velocityEnabled then
		isProfileShifted = true
		isNitroActive = true
		
		nitroOnceSound:Play()
		nitroLoopSound:Play()
		
		Window:Notify({ Title = "Nitro Activated", Content = "⚡ Nitro Mode Active!", Duration = 1.5 })
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isProfileShifted = false
		isNitroActive = false
		
		nitroOnceSound:Stop()
		nitroLoopSound:Stop()
		
		Window:Notify({ Title = "Nitro Deactivated", Content = "Standard handling restored.", Duration = 1.5 })
	end
end)

-- ─── Audio and Health Monitoring ───
local function playDamageSFX()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://139459336979009"
	sound.Volume = 2
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 5)
end

local function playDeathSFX()
	local deathSounds = { "APEX/die1.wav", "APEX/die2.wav" }
	local chosenPath = deathSounds[math.random(1, #deathSounds)]
	
	local success, assetId = pcall(function()
		return getcustomasset(chosenPath)
	end)
	
	if success and assetId then
		local sound = Instance.new("Sound")
		sound.SoundId = assetId
		sound.Volume = 2
		sound.Parent = SoundService
		sound:Play()
		Debris:AddItem(sound, 5)
	else
		warn("[ftgs hub] Failed to load/play death SFX: " .. tostring(assetId or "file path error"))
	end
end

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	
	local lastHealth = humanoid.Health
	
	local healthConnection
	healthConnection = humanoid.HealthChanged:Connect(function(health)
		if health < lastHealth and health > 0 then
			playDamageSFX()
		end
		lastHealth = health
	end)
	
	local diedConnection
	diedConnection = humanoid.Died:Connect(function()
		playDeathSFX()
		if healthConnection then healthConnection:Disconnect() end
		if diedConnection then diedConnection:Disconnect() end
	end)
end

if LocalPlayer.Character then
	task.spawn(onCharacterAdded, LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Main Tab
local VehicleTab = Window:CreateTab("Vehicle Mod")

-- ─── Core Settings Section ───
local BaseSection = VehicleTab:CreateSection("Core Settings")

local velocityEnabledToggle = BaseSection:CreateToggle("Keybinds Active", velocityEnabled, function(s)
	velocityEnabled = s
end)

BaseSection:CreateButton("Emergency Brake (P)", function()
	local Character = LocalPlayer.Character
	if Character and Character:FindFirstChildWhichIsA("Humanoid") and Character:FindFirstChildWhichIsA("Humanoid").SeatPart then
		local SeatPart = Character:FindFirstChildWhichIsA("Humanoid").SeatPart
		SeatPart.AssemblyLinearVelocity = Vector3.zero
		SeatPart.AssemblyAngularVelocity = Vector3.zero
		currentAccelFade, currentBrakeFade, currentTurnFade = 0, 0, 0
	end
end)

-- ─── Profile 1 Settings ───
local TuningSection = VehicleTab:CreateSection("Profile 1 - Standard Mode Settings")

local maxForwardBoostSlider = TuningSection:CreateSlider("Max Forward Boost", 1, 100, 25, function(v)
	normal_velocityMult = v / 1000
end)

local maxTurnAssistSlider = TuningSection:CreateSlider("Max Turn Assist Power", 1, 80, 35, function(v)
	normal_turnAssistPower = v / 10
end)

local maxBrakeForceSlider = TuningSection:CreateSlider("Max Brake/Reverse Force", 1, 300, 150, function(v)
	normal_velocityMult2 = v / 1000
end)

-- ─── Profile 1 Fading Responsiveness ───
local FadingConfigSection = VehicleTab:CreateSection("Profile 1 - Fading Responsiveness")

local accelAttackSlider = FadingConfigSection:CreateSlider("Throttle Attack Speed", 1, 20, 5, function(v)
	normal_ACCEL_ATTACK = v / 100
end)

local accelReleaseSlider = FadingConfigSection:CreateSlider("Throttle Release Speed", 1, 20, 3, function(v)
	normal_ACCEL_RELEASE = v / 100
end)

local turnAttackSlider = FadingConfigSection:CreateSlider("Steering Attack Speed", 1, 40, 10, function(v)
	normal_TURN_ATTACK = v / 100
end)

local turnReleaseSlider = FadingConfigSection:CreateSlider("Steering Release Speed", 1, 40, 15, function(v)
	normal_TURN_RELEASE = v / 100
end)

-- ─── Profile 2 Settings ───
local ShiftTuningSection = VehicleTab:CreateSection("Profile 2 - Shift (Nitro/Drift) Settings")

local shiftMaxForwardBoostSlider = ShiftTuningSection:CreateSlider("Shift - Max Forward Boost", 1, 100, 65, function(v)
	shift_velocityMult = v / 1000
end)

local shiftMaxTurnAssistSlider = ShiftTuningSection:CreateSlider("Shift - Max Turn Assist Power", 1, 80, 55, function(v)
	shift_turnAssistPower = v / 10
end)

local shiftMaxBrakeForceSlider = ShiftTuningSection:CreateSlider("Shift - Max Brake/Reverse Force", 1, 300, 250, function(v)
	shift_velocityMult2 = v / 1000
end)

-- ─── Profile 2 Fading Responsiveness ───
local ShiftFadingSection = VehicleTab:CreateSection("Profile 2 - Shift Fading Responsiveness")

local shiftAccelAttackSlider = ShiftFadingSection:CreateSlider("Shift - Throttle Attack Speed", 1, 20, 12, function(v)
	shift_ACCEL_ATTACK = v / 100
end)

local shiftAccelReleaseSlider = ShiftFadingSection:CreateSlider("Shift - Throttle Release Speed", 1, 20, 2, function(v)
	shift_ACCEL_RELEASE = v / 100
end)

local shiftTurnAttackSlider = ShiftFadingSection:CreateSlider("Shift - Steering Attack Speed", 1, 40, 20, function(v)
	shift_TURN_ATTACK = v / 100
end)

local shiftTurnReleaseSlider = ShiftFadingSection:CreateSlider("Shift - Steering Release Speed", 1, 40, 25, function(v)
	shift_TURN_RELEASE = v / 100
end)

-- ─── Configuration Profile Manager ───
local function listConfigs()
	local list = {}
	if typeof(listfiles) == "function" then
		local ok, files = pcall(listfiles, "")
		if ok and typeof(files) == "table" then
			for _, filepath in ipairs(files) do
				local filename = filepath:match("([^/\\]+)$") or filepath
				if filename:sub(-5) == ".json" then
					local confName = filename:sub(1, -6)
					table.insert(list, confName)
				end
			end
		end
	end
	if #list == 0 then
		table.insert(list, "DefaultCarSetup")
	end
	return list
end

local currentConfigName = "DefaultCarSetup"
local ConfigSection = VehicleTab:CreateSection("Configuration Profile Manager")

local ConfigInput = ConfigSection:CreateTextInput("Profile Name", currentConfigName, function(val)
	currentConfigName = val
end)

local configDropdown
local function refreshDropdown(selectName)
	if configDropdown then
		configDropdown:Refresh(listConfigs(), selectName or currentConfigName)
	end
end

configDropdown = ConfigSection:CreateDropdown("Select Profile", listConfigs(), currentConfigName, function(selected)
	currentConfigName = selected
	ConfigInput:SetText(selected)
end)

local function saveConfig(name)
	local data = {
		velocityEnabled = velocityEnabled,
		normal_velocityMult = normal_velocityMult,
		normal_turnAssistPower = normal_turnAssistPower,
		normal_velocityMult2 = normal_velocityMult2,
		normal_ACCEL_ATTACK = normal_ACCEL_ATTACK,
		normal_ACCEL_RELEASE = normal_ACCEL_RELEASE,
		normal_TURN_ATTACK = normal_TURN_ATTACK,
		normal_TURN_RELEASE = normal_TURN_RELEASE,
		shift_velocityMult = shift_velocityMult,
		shift_turnAssistPower = shift_turnAssistPower,
		shift_velocityMult2 = shift_velocityMult2,
		shift_ACCEL_ATTACK = shift_ACCEL_ATTACK,
		shift_ACCEL_RELEASE = shift_ACCEL_RELEASE,
		shift_TURN_ATTACK = shift_TURN_ATTACK,
		shift_TURN_RELEASE = shift_TURN_RELEASE,
	}
	local success, err = pcall(function()
		writefile(name .. ".json", HttpService:JSONEncode(data))
	end)
	if success then
		Window:Notify({ Title = "Config Saved", Content = "Successfully saved " .. name .. ".json!", Duration = 2 })
		refreshDropdown(name)
	else
		Window:Notify({ Title = "Save Failed", Content = tostring(err), Duration = 3 })
	end
end

local function loadConfig(name)
	local filename = name .. ".json"
	if not isfile(filename) then
		Window:Notify({ Title = "Load Failed", Content = "File not found: " .. filename, Duration = 3 })
		return
	end
	local success, content = pcall(function()
		return readfile(filename)
	end)
	if not success then
		Window:Notify({ Title = "Load Failed", Content = "Could not read file.", Duration = 3 })
		return
	end
	local decodeSuccess, data = pcall(function()
		return HttpService:JSONDecode(content)
	end)
	if not decodeSuccess or not data then
		Window:Notify({ Title = "Load Failed", Content = "Malformed config JSON.", Duration = 3 })
		return
	end

	-- Update variables and UI elements
	if data.velocityEnabled ~= nil then
		velocityEnabled = data.velocityEnabled
		velocityEnabledToggle:SetState(velocityEnabled)
	end
	if data.normal_velocityMult ~= nil then
		normal_velocityMult = data.normal_velocityMult
		maxForwardBoostSlider:SetValue(normal_velocityMult * 1000)
	end
	if data.normal_turnAssistPower ~= nil then
		normal_turnAssistPower = data.normal_turnAssistPower
		maxTurnAssistSlider:SetValue(normal_turnAssistPower * 10)
	end
	if data.normal_velocityMult2 ~= nil then
		normal_velocityMult2 = data.normal_velocityMult2
		maxBrakeForceSlider:SetValue(normal_velocityMult2 * 1000)
	end
	if data.normal_ACCEL_ATTACK ~= nil then
		normal_ACCEL_ATTACK = data.normal_ACCEL_ATTACK
		accelAttackSlider:SetValue(normal_ACCEL_ATTACK * 100)
	end
	if data.normal_ACCEL_RELEASE ~= nil then
		normal_ACCEL_RELEASE = data.normal_ACCEL_RELEASE
		accelReleaseSlider:SetValue(normal_ACCEL_RELEASE * 100)
	end
	if data.normal_TURN_ATTACK ~= nil then
		normal_TURN_ATTACK = data.normal_TURN_ATTACK
		turnAttackSlider:SetValue(normal_TURN_ATTACK * 100)
	end
	if data.normal_TURN_RELEASE ~= nil then
		normal_TURN_RELEASE = data.normal_TURN_RELEASE
		turnReleaseSlider:SetValue(normal_TURN_RELEASE * 100)
	end
	if data.shift_velocityMult ~= nil then
		shift_velocityMult = data.shift_velocityMult
		shiftMaxForwardBoostSlider:SetValue(shift_velocityMult * 1000)
	end
	if data.shift_turnAssistPower ~= nil then
		shift_turnAssistPower = data.shift_turnAssistPower
		shiftMaxTurnAssistSlider:SetValue(shift_turnAssistPower * 10)
	end
	if data.shift_velocityMult2 ~= nil then
		shift_velocityMult2 = data.shift_velocityMult2
		shiftMaxBrakeForceSlider:SetValue(shift_velocityMult2 * 1000)
	end
	if data.shift_ACCEL_ATTACK ~= nil then
		shift_ACCEL_ATTACK = data.shift_ACCEL_ATTACK
		shiftAccelAttackSlider:SetValue(shift_ACCEL_ATTACK * 100)
	end
	if data.shift_ACCEL_RELEASE ~= nil then
		shift_ACCEL_RELEASE = data.shift_ACCEL_RELEASE
		shiftAccelReleaseSlider:SetValue(shift_ACCEL_RELEASE * 100)
	end
	if data.shift_TURN_ATTACK ~= nil then
		shift_TURN_ATTACK = data.shift_TURN_ATTACK
		shiftTurnAttackSlider:SetValue(shift_TURN_ATTACK * 100)
	end
	if data.shift_TURN_RELEASE ~= nil then
		shift_TURN_RELEASE = data.shift_TURN_RELEASE
		shiftTurnReleaseSlider:SetValue(shift_TURN_RELEASE * 100)
	end

	Window:Notify({ Title = "Config Loaded", Content = "Successfully loaded " .. filename .. "!", Duration = 2 })
	refreshDropdown(name)
end

ConfigSection:CreateButton("Save Config File", function()
	saveConfig(currentConfigName)
end)

ConfigSection:CreateButton("Load Config File", function()
	loadConfig(currentConfigName)
end)

-- ─── Physical Drive Loop ───
RunService.Stepped:Connect(function()
	local Character = LocalPlayer.Character
	if not Character or not Character:FindFirstChildWhichIsA("Humanoid") then return end
	
	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
	local SeatPart = Humanoid.SeatPart
	if not SeatPart or not SeatPart:IsA("VehicleSeat") then return end
	
	-- Profile assignment based on Shift state
	local active_velocityMult   = isProfileShifted and shift_velocityMult or normal_velocityMult
	local active_turnAssistPower = isProfileShifted and shift_turnAssistPower or normal_turnAssistPower
	local active_velocityMult2   = isProfileShifted and shift_velocityMult2 or normal_velocityMult2
	local active_ACCEL_ATTACK   = isProfileShifted and shift_ACCEL_ATTACK or normal_ACCEL_ATTACK
	local active_ACCEL_RELEASE  = isProfileShifted and shift_ACCEL_RELEASE or normal_ACCEL_RELEASE
	local active_TURN_ATTACK     = isProfileShifted and shift_TURN_ATTACK or normal_TURN_ATTACK
	local active_TURN_RELEASE    = isProfileShifted and shift_TURN_RELEASE or normal_TURN_RELEASE

	if not velocityEnabled then return end
	
	-- W Input
	if UserInputService:IsKeyDown(velocityEnabledKeyCode) then
		currentAccelFade = math.clamp(currentAccelFade + active_ACCEL_ATTACK, 0, 1)
	else
		currentAccelFade = math.clamp(currentAccelFade - active_ACCEL_RELEASE, 0, 1)
	end
	
	-- S Input
	if UserInputService:IsKeyDown(qbEnabledKeyCode) then
		currentBrakeFade = math.clamp(currentBrakeFade + BRAKE_ATTACK, 0, 1)
	else
		currentBrakeFade = math.clamp(currentBrakeFade - BRAKE_RELEASE, 0, 1)
	end
	
	-- A/D Input
	local targetTurn = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		targetTurn = 1
	elseif UserInputService:IsKeyDown(Enum.KeyCode.D) then
		targetTurn = -1
	end
	
	if currentTurnFade < targetTurn then
		currentTurnFade = math.min(currentTurnFade + active_TURN_ATTACK, targetTurn)
	elseif currentTurnFade > targetTurn then
		currentTurnFade = math.max(currentTurnFade - active_TURN_RELEASE, targetTurn)
	end
	
	-- Calculations
	local rawLookVector = SeatPart.CFrame.LookVector
	local horizontalLookVector = Vector3.new(rawLookVector.X, 0, rawLookVector.Z).Unit
	local originalYVelocity = SeatPart.AssemblyLinearVelocity.Y 
	
	local localVelocity = SeatPart.CFrame:VectorToObjectSpace(SeatPart.AssemblyLinearVelocity)
	local isMovingForward = localVelocity.Z < 0.1 
	local currentSpeed = SeatPart.AssemblyLinearVelocity.Magnitude
	
	-- A. Throttle
	if currentAccelFade > 0 then
		local nextSpeed = currentSpeed * (1 + (active_velocityMult * currentAccelFade))
		if currentSpeed < 5 then nextSpeed = 40 * currentAccelFade end
		
		SeatPart.AssemblyLinearVelocity = Vector3.new(
			horizontalLookVector.X * nextSpeed,
			originalYVelocity,
			horizontalLookVector.Z * nextSpeed
		)
	end
	
	-- B. Brake/Reverse
	if currentBrakeFade > 0 then
		if isMovingForward and currentSpeed > 2 then
			local brakeModifier = active_velocityMult2 * currentBrakeFade
			local targetSpeed = currentSpeed * (1 - brakeModifier)
			SeatPart.AssemblyLinearVelocity = Vector3.new(
				horizontalLookVector.X * targetSpeed,
				originalYVelocity,
				horizontalLookVector.Z * targetSpeed
			)
		else
			local reverseSpeed = currentSpeed + (35 * active_velocityMult2 * currentBrakeFade)
			if currentSpeed < 3 then reverseSpeed = 25 * currentBrakeFade end
			
			SeatPart.AssemblyLinearVelocity = Vector3.new(
				-horizontalLookVector.X * reverseSpeed,
				originalYVelocity,
				-horizontalLookVector.Z * reverseSpeed
			)
		end
	end
	
	-- C. Steering
	if math.abs(currentTurnFade) > 0.01 then
		local finalTurnPower = active_turnAssistPower * currentTurnFade
		if UserInputService:IsKeyDown(qbEnabledKeyCode) and not isMovingForward then
			finalTurnPower = -finalTurnPower
		end
		
		SeatPart.AssemblyAngularVelocity = Vector3.new(0, finalTurnPower, 0)
	else
		if currentAccelFade > 0 or (currentBrakeFade > 0 and not isMovingForward) then
			SeatPart.AssemblyAngularVelocity = Vector3.zero
		end
	end
end)

-- ─── Driving Empire dealership teleports ───
repeat task.wait(0) until game:IsLoaded() and game.PlaceId > 0
if game.PlaceId == 3351674303 then
	local DESection = VehicleTab:CreateSection("Driving Empire Teleports")
	task.spawn(function()
		local dealershipsFolder = workspace:WaitForChild("Game"):WaitForChild("Dealerships"):WaitForChild("Dealerships")
		local list = {}
		for _, value in pairs(dealershipsFolder:GetChildren()) do table.insert(list, value.Name) end
		DESection:CreateDropdown("Teleport to Dealership", list, list[1], function(v)
			game:GetService("ReplicatedStorage").Remotes.Location:FireServer("Enter", v)
		end)
	end)
end
