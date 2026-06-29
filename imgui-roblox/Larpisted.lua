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
local shiftBeganConnection
shiftBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.KeyCode == Enum.KeyCode.LeftShift and velocityEnabled then
		isProfileShifted = true
		isNitroActive = true
		
		nitroOnceSound.TimePosition = 0.5
		nitroOnceSound:Play()
		nitroLoopSound:Play()
		
		Window:Notify({ Title = "Nitro Activated", Content = "⚡ Nitro Mode Active!", Duration = 1.5 })
	end
end)

local shiftEndedConnection
shiftEndedConnection = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
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

local currentHealthConnection
local currentDiedConnection
local charAddedConnection

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	
	local lastHealth = humanoid.Health
	
	if currentHealthConnection then currentHealthConnection:Disconnect() end
	currentHealthConnection = humanoid.HealthChanged:Connect(function(health)
		if health < lastHealth and health > 0 then
			playDamageSFX()
		end
		lastHealth = health
	end)
	
	if currentDiedConnection then currentDiedConnection:Disconnect() end
	currentDiedConnection = humanoid.Died:Connect(function()
		playDeathSFX()
		if currentHealthConnection then currentHealthConnection:Disconnect() end
		if currentDiedConnection then currentDiedConnection:Disconnect() end
	end)
end

if LocalPlayer.Character then
	task.spawn(onCharacterAdded, LocalPlayer.Character)
end
charAddedConnection = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

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
local driveLoopConnection
driveLoopConnection = RunService.Stepped:Connect(function()
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

-- ─── YouTube Music Player ───
local SERVER_URL = "http://localhost:5000"

-- Ensure directories exist
if not isfolder("Larpisted") then pcall(makefolder, "Larpisted") end
if not isfolder("Larpisted/Musics") then pcall(makefolder, "Larpisted/Musics") end

-- Load default URL or saved URL
local YOUTUBE_MUSIC_URL = "https://music.youtube.com/watch?v=Mf-vzfNuQiI&list=RDAMVMSm_DVsixxsk"
if isfile("Larpisted/ytmusic_url.txt") then
	local saved = readfile("Larpisted/ytmusic_url.txt")
	if saved and #saved > 0 then
		YOUTUBE_MUSIC_URL = saved
	end
end

local MusicPlayerTab = Window:CreateTab("Music Player")
local MusicSettingsTab = Window:CreateTab("Music Settings")

-- Initialize Console to show it is active and not bugged
Window:AddLog("YouTube Music Player Console Initialized.")
Window:AddLog("Initializing playback...")

-- Player Tab Elements
MusicPlayerTab:CreateLabel("─── Currently Playing ───")
local songLabel = MusicPlayerTab:CreateLabel("🎵 Status: Connecting...")

-- Media Player variables
local timelineFill = nil
local timelineBar = nil
local timeLabel = nil
local playPauseBtn = nil
local speakerLabel = nil
local volFill = nil
local volBar = nil

local isDraggingTimeline = false
local isDraggingVolume = false
local currentVolume = 1.0
local isPaused = false
local isLooping = true

local playlistQueue = {}
local currentTrackIndex = 1
local activeSound = nil
local playbackConnection = nil
local endedConnection = nil
local charAddedConnectionMusic = nil
local seatConnection = nil
local mouse = LocalPlayer:GetMouse()

-- Forward declarations
local playNextSong
local preDownloadNext
local applyOutsideEffect
local getAudioParent
local isPlayerSittingInVehicle
local playNow
local destroyScript

isPlayerSittingInVehicle = function()
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	return seat and seat:IsA("VehicleSeat")
end

getAudioParent = function()
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	
	if seat and seat:IsA("VehicleSeat") then
		return seat, false
	elseif activeSound and activeSound:IsDescendantOf(game) and activeSound.Parent and activeSound.Parent:IsA("VehicleSeat") then
		return activeSound.Parent, true
	else
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp or workspace, false
	end
end

-- Create custom interactive YouTube Player Controls bar
local playerScript = MusicPlayerTab:Script("YouTube Player Widget", true, function(enabled)
	if not enabled then return end
	
	local screen = Instance.new("ScreenGui")
	screen.Size = UDim2.new(1, 0, 0, 48)
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 0, 48)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = screen
	
	timelineBar = Instance.new("TextButton")
	timelineBar.Size = UDim2.new(1, -10, 0, 4)
	timelineBar.Position = UDim2.new(0, 5, 0, 6)
	timelineBar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	timelineBar.BorderSizePixel = 0
	timelineBar.Text = ""
	timelineBar.Parent = mainFrame
	
	timelineFill = Instance.new("Frame")
	timelineFill.Size = UDim2.new(0, 0, 1, 0)
	timelineFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	timelineFill.BorderSizePixel = 0
	timelineFill.Parent = timelineBar
	
	local handle = Instance.new("Frame")
	handle.Size = UDim2.new(0, 10, 0, 10)
	handle.AnchorPoint = Vector2.new(0.5, 0.5)
	handle.Position = UDim2.new(1, 0, 0.5, 0)
	handle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	handle.BorderSizePixel = 0
	handle.Parent = timelineFill
	
	local handleCorner = Instance.new("UICorner")
	handleCorner.CornerRadius = UDim.new(1, 0)
	handleCorner.Parent = handle
	
	timelineBar.MouseButton1Down:Connect(function()
		isDraggingTimeline = true
	end)
	
	local controlsContainer = Instance.new("Frame")
	controlsContainer.Size = UDim2.new(1, -10, 0, 24)
	controlsContainer.Position = UDim2.new(0, 5, 0, 18)
	controlsContainer.BackgroundTransparency = 1
	controlsContainer.Parent = mainFrame
	
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.Parent = controlsContainer
	
	playPauseBtn = Instance.new("TextButton")
	playPauseBtn.Size = UDim2.new(0, 20, 0, 20)
	playPauseBtn.BackgroundTransparency = 1
	playPauseBtn.Text = isPaused and "▶" or "⏸"
	playPauseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	playPauseBtn.TextSize = 14
	playPauseBtn.LayoutOrder = 1
	playPauseBtn.Parent = controlsContainer
	
	playPauseBtn.MouseButton1Click:Connect(function()
		if not activeSound or not activeSound:IsDescendantOf(game) then return end
		if isPaused then
			activeSound:Resume()
			isPaused = false
			playPauseBtn.Text = "⏸"
			Window:AddLog("Resumed playback.")
		else
			activeSound:Pause()
			isPaused = true
			playPauseBtn.Text = "▶"
			Window:AddLog("Paused playback.")
		end
	end)
	
	local skipBtn = Instance.new("TextButton")
	skipBtn.Size = UDim2.new(0, 20, 0, 20)
	skipBtn.BackgroundTransparency = 1
	skipBtn.Text = "⏭"
	skipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	skipBtn.TextSize = 14
	skipBtn.LayoutOrder = 2
	skipBtn.Parent = controlsContainer
	
	skipBtn.MouseButton1Click:Connect(function()
		if #playlistQueue == 0 then return end
		Window:AddLog("User skipped current song.")
		if endedConnection then endedConnection:Disconnect() end
		if playbackConnection then playbackConnection:Disconnect() end
		
		currentTrackIndex = (currentTrackIndex % #playlistQueue) + 1
		playNextSong()
	end)
	
	speakerLabel = Instance.new("TextLabel")
	speakerLabel.Size = UDim2.new(0, 16, 0, 20)
	speakerLabel.BackgroundTransparency = 1
	speakerLabel.Text = currentVolume == 0 and "🔇" or "🔊"
	speakerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	speakerLabel.TextSize = 12
	speakerLabel.LayoutOrder = 3
	speakerLabel.Parent = controlsContainer
	
	volBar = Instance.new("TextButton")
	volBar.Size = UDim2.new(0, 50, 0, 20)
	volBar.BackgroundTransparency = 1
	volBar.Text = ""
	volBar.LayoutOrder = 4
	volBar.Parent = controlsContainer
	
	local volBg = Instance.new("Frame")
	volBg.Size = UDim2.new(1, 0, 0, 3)
	volBg.Position = UDim2.new(0, 0, 0.5, -1)
	volBg.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	volBg.BorderSizePixel = 0
	volBg.Parent = volBar
	
	volFill = Instance.new("Frame")
	volFill.Size = UDim2.new(currentVolume, 0, 1, 0)
	volFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	volFill.BorderSizePixel = 0
	volFill.Parent = volBg
	
	local volHandle = Instance.new("Frame")
	volHandle.Size = UDim2.new(0, 8, 0, 8)
	volHandle.AnchorPoint = Vector2.new(0.5, 0.5)
	volHandle.Position = UDim2.new(1, 0, 0.5, 0)
	volHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	volHandle.BorderSizePixel = 0
	volHandle.Parent = volFill
	
	local volHandleCorner = Instance.new("UICorner")
	volHandleCorner.CornerRadius = UDim.new(1, 0)
	volHandleCorner.Parent = volHandle
	
	volBar.MouseButton1Down:Connect(function()
		isDraggingVolume = true
	end)
	
	timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(0, 80, 0, 20)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	timeLabel.TextSize = 11
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	pcall(function() timeLabel.Font = Enum.Font.Code end)
	timeLabel.Text = "0:00 / 0:00"
	timeLabel.LayoutOrder = 5
	timeLabel.Parent = controlsContainer
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDraggingTimeline = false
			isDraggingVolume = false
		end
	end)
end)

MusicPlayerTab:CreateLabel("─── Options ───")
MusicPlayerTab:CreateToggle("Loop Playlist", true, function(state)
	isLooping = state
	Window:AddLog("Loop Playlist set to: " .. tostring(state))
end)

local function formatTime(seconds)
	if not seconds or seconds ~= seconds then seconds = 0 end
	return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
end

local function shufflePlaylist()
	local n = #playlistQueue
	if n <= 1 then return end
	local rng = Random.new()
	for i = n, 2, -1 do
		local j = rng:NextInteger(1, i)
		playlistQueue[i], playlistQueue[j] = playlistQueue[j], playlistQueue[i]
	end
	Window:AddLog("Playlist randomized & shuffled successfully.")
end

local function makeRequest(url)
	local success, response = pcall(function()
		return request({
			Url = url,
			Method = "GET"
		})
	end)
	if success and response.StatusCode == 200 then
		return response
	end
	return nil
end

local function downloadSong(videoId)
	local fileName = "Larpisted/Musics/ytmusic_" .. videoId .. ".mp3"
	if isfile(fileName) then
		Window:AddLog("Loading song from local cache: " .. videoId)
		return getcustomasset(fileName)
	end
	
	Window:AddLog("Downloading song from server: " .. videoId)
	local response = makeRequest(SERVER_URL .. "/download/" .. videoId)
	if response then
		writefile(fileName, response.Body)
		Window:AddLog("Song download complete: " .. videoId)
		return getcustomasset(fileName)
	end
	Window:AddLog("Error: Failed to download song: " .. videoId, true)
	return nil
end

preDownloadNext = function()
	if #playlistQueue <= 1 then return end
	local nextIndex = (currentTrackIndex % #playlistQueue) + 1
	local nextTrack = playlistQueue[nextIndex]
	if nextTrack then
		task.spawn(function()
			local nextFileName = "Larpisted/Musics/ytmusic_" .. nextTrack.videoId .. ".mp3"
			if not isfile(nextFileName) then
				Window:AddLog("Pre-downloading next song: " .. nextTrack.title)
				downloadSong(nextTrack.videoId)
			else
				Window:AddLog("Next song already cached: " .. nextTrack.title)
			end
		end)
	end
end

applyOutsideEffect = function(sound, outside)
	if not sound or not sound:IsDescendantOf(game) then return end
	
	local muffle = sound:FindFirstChild("MuffleEffect")
	if not muffle then
		muffle = Instance.new("EqualizerSoundEffect")
		muffle.Name = "MuffleEffect"
		muffle.LowGain = 3
		muffle.MidGain = -15
		muffle.HighGain = -80
		muffle.Parent = sound
	end
	
	if outside and sound.Parent and sound.Parent:IsA("VehicleSeat") then
		muffle.Enabled = true
		sound.Volume = currentVolume
	else
		muffle.Enabled = false
		sound.Volume = currentVolume
	end
end

playNextSong = function()
	if #playlistQueue == 0 then
		songLabel:SetText("🎵 Status: Playlist empty")
		return
	end
	
	local track = playlistQueue[currentTrackIndex]
	songLabel:SetText("🎵 Playing: " .. track.title)
	Window:AddLog("Loading track: " .. track.title)
	
	local assetId = downloadSong(track.videoId)
	if assetId then
		local targetParent, isOutside = getAudioParent()
		
		if not activeSound or not activeSound:IsDescendantOf(game) then
			activeSound = Instance.new("Sound")
			activeSound.Name = "CarMusic"
			activeSound.RollOffMaxDistance = 150
			activeSound.RollOffMinDistance = 10
			activeSound.RollOffMode = Enum.RollOffMode.Linear
		end
		
		if activeSound.Parent ~= targetParent then
			pcall(function()
				activeSound.Parent = targetParent
			end)
		end
		
		activeSound.SoundId = assetId
		activeSound:Play()
		isPaused = false
		if playPauseBtn then playPauseBtn.Text = "⏸" end
		Window:AddLog("Now playing: " .. track.title .. " (parent: " .. tostring(targetParent) .. ")")
		
		applyOutsideEffect(activeSound, isOutside)
		preDownloadNext()
		
		if playbackConnection then playbackConnection:Disconnect() end
		playbackConnection = RunService.RenderStepped:Connect(function()
			if activeSound and activeSound:IsDescendantOf(game) and activeSound.TimeLength > 0 then
				if isDraggingTimeline and timelineBar then
					local absoluteWidth = timelineBar.AbsoluteSize.X
					local relativeX = mouse.X - timelineBar.AbsolutePosition.X
					local percentage = math.clamp(relativeX / absoluteWidth, 0, 1)
					activeSound.TimePosition = percentage * activeSound.TimeLength
				end
				
				if isDraggingVolume and volBar then
					local absoluteWidth = volBar.AbsoluteSize.X
					local relativeX = mouse.X - volBar.AbsolutePosition.X
					local percentage = math.clamp(relativeX / absoluteWidth, 0, 1)
					currentVolume = percentage
					activeSound.Volume = percentage
					
					if volFill then volFill.Size = UDim2.new(percentage, 0, 1, 0) end
					
					if speakerLabel then
						if percentage == 0 then
							speakerLabel.Text = "🔇"
						elseif percentage < 0.4 then
							speakerLabel.Text = "🔈"
						else
							speakerLabel.Text = "🔊"
						end
					end
				end
				
				local ratio = activeSound.TimePosition / activeSound.TimeLength
				if timeLabel then
					timeLabel.Text = formatTime(activeSound.TimePosition) .. " / " .. formatTime(activeSound.TimeLength)
				end
				
				if timelineFill then
					timelineFill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
				end
			else
				if timeLabel then
					timeLabel.Text = "0:00 / 0:00"
				end
				if timelineFill then
					timelineFill.Size = UDim2.new(0, 0, 1, 0)
				end
			end
		end)
		
		if endedConnection then endedConnection:Disconnect() end
		endedConnection = activeSound.Ended:Connect(function()
			endedConnection:Disconnect()
			if playbackConnection then playbackConnection:Disconnect() end
			Window:AddLog("Song ended naturally: " .. track.title)
			if isLooping then
				currentTrackIndex = (currentTrackIndex % #playlistQueue) + 1
				playNextSong()
			else
				songLabel:SetText("🎵 Status: Playback finished")
				if timeLabel then timeLabel.Text = "0:00 / 0:00" end
				if playPauseBtn then playPauseBtn.Text = "▶" end
			end
		end)
	else
		Window:AddLog("Failed to load asset ID for: " .. track.title .. ". Skipping.", true)
		currentTrackIndex = (currentTrackIndex % #playlistQueue) + 1
		playNextSong()
	end
end

local function loadPlaylist()
	songLabel:SetText("🎵 Status: Loading playlist...")
	Window:AddLog("Fetching playlist from API URL...")
	local encodedUrl = HttpService:UrlEncode(YOUTUBE_MUSIC_URL)
	local response = makeRequest(SERVER_URL .. "/get_playlist?url=" .. encodedUrl)
	if response then
		playlistQueue = HttpService:JSONDecode(response.Body)
		shufflePlaylist()
		Window:AddLog("Playlist loaded successfully! " .. tostring(#playlistQueue) .. " songs.")
		songLabel:SetText("🎵 Status: Playlist Loaded (" .. tostring(#playlistQueue) .. " songs)")
		return true
	else
		Window:AddLog("Error: Failed to fetch playlist from python server.", true)
		songLabel:SetText("❌ Status: Failed to load playlist. Check server.")
		return false
	end
end

playNow = function()
	if #playlistQueue == 0 then
		if loadPlaylist() then
			currentTrackIndex = 1
			playNextSong()
		end
	else
		currentTrackIndex = 1
		playNextSong()
	end
end

-- Settings Tab Elements
MusicSettingsTab:CreateLabel("─── Source Configuration ───")
local urlInput = MusicSettingsTab:CreateTextInput("URL", YOUTUBE_MUSIC_URL, function(text)
	YOUTUBE_MUSIC_URL = text
	playlistQueue = {}
	pcall(writefile, "Larpisted/ytmusic_url.txt", text)
	Window:AddLog("Saved target URL config to Larpisted/ytmusic_url.txt")
end)

local loadBtn = MusicSettingsTab:CreateButton("Load & Play URL", function()
	Window:AddLog("User triggered URL reload.")
	playNow()
end)

-- Customize layout programmatically
task.spawn(function()
	task.wait(0.5)
	
	local textBoxInstance, buttonInstance
	for _, desc in ipairs(Window.ScreenGui:GetDescendants()) do
		if desc:IsA("TextBox") and desc.Text == YOUTUBE_MUSIC_URL then
			textBoxInstance = desc
		elseif desc:IsA("TextButton") and desc.Text == "Load & Play URL" then
			buttonInstance = desc
		end
	end
	
	if textBoxInstance then
		textBoxInstance.Size = UDim2.new(0, 320, 1, -4)
		local parent = textBoxInstance.Parent
		if parent then
			local label = parent:FindFirstChildOfClass("TextLabel")
			if label then
				label.Visible = false
			end
		end
	end
	
	if buttonInstance then
		buttonInstance.Size = UDim2.new(0, 160, 1, 0)
	end
end)

local function onCharacterAddedMusic(character)
	local humanoid = character:WaitForChild("Humanoid")
	
	if seatConnection then seatConnection:Disconnect() end
	seatConnection = humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		local seat = humanoid.SeatPart
		if seat and seat:IsA("VehicleSeat") then
			Window:AddLog("Entered vehicle seat. Disabling muffle effect, volume set to 1.0")
			if not activeSound or not activeSound:IsDescendantOf(game) then
				playNow()
			else
				local ok = pcall(function()
					activeSound.Parent = seat
				end)
				if not ok then
					playNow()
				end
			end
			applyOutsideEffect(activeSound, false)
		else
			if activeSound and activeSound:IsDescendantOf(game) then
				Window:AddLog("Exited vehicle seat. Enabling muffle effect.")
				applyOutsideEffect(activeSound, true)
			end
		end
	end)
	
	task.spawn(function()
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if hrp and activeSound and activeSound:IsDescendantOf(game) then
			local targetParent, isOutside = getAudioParent()
			if not isPlayerSittingInVehicle() then
				pcall(function()
					activeSound.Parent = hrp
				end)
				applyOutsideEffect(activeSound, false)
			end
		end
	end)
end

if LocalPlayer.Character then
	onCharacterAddedMusic(LocalPlayer.Character)
end
charAddedConnectionMusic = LocalPlayer.CharacterAdded:Connect(onCharacterAddedMusic)

local isDestroyed = false
local function disableAllFeatures()
	if isDestroyed then return end
	isDestroyed = true
	
	warn("[Larpisted] Disabling all vehicle features and cleaning up listeners...")
	
	velocityEnabled = false
	flightEnabled = false
	isProfileShifted = false
	isNitroActive = false
	
	-- Stop sounds
	if nitroOnceSound then nitroOnceSound:Stop() end
	if nitroLoopSound then nitroLoopSound:Stop() end
	
	-- Disconnect vehicle loops
	if driveLoopConnection then driveLoopConnection:Disconnect() end
	
	-- Disconnect input listeners
	if shiftBeganConnection then shiftBeganConnection:Disconnect() end
	if shiftEndedConnection then shiftEndedConnection:Disconnect() end
	
	-- Disconnect character connections
	if charAddedConnection then charAddedConnection:Disconnect() end
	if currentHealthConnection then currentHealthConnection:Disconnect() end
	if currentDiedConnection then currentDiedConnection:Disconnect() end
	
	-- Disconnect music player connections
	if playbackConnection then playbackConnection:Disconnect() end
	if endedConnection then endedConnection:Disconnect() end
	if charAddedConnectionMusic then charAddedConnectionMusic:Disconnect() end
	if seatConnection then seatConnection:Disconnect() end
	
	if activeSound then
		pcall(function()
			activeSound:Stop()
			activeSound:Destroy()
		end)
		activeSound = nil
	end
end

-- Bind clean up to the Window close click and destruction event
local titleBar = Window.TitleBar
local closeButton = titleBar and titleBar:FindFirstChild("CloseButton")
if closeButton then
	closeButton.MouseButton1Click:Connect(disableAllFeatures)
end
Window.ScreenGui.Destroying:Connect(disableAllFeatures)

-- Start playing immediately on startup
task.spawn(function()
	playNow()
end)
