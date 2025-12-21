			local function handleDeathPos(pos)
				if handled then return end
				handled = true
				warn("Death2: captured death position ->", pos)
				-- save for respawn handler
				lastDeathPosition = pos
				lastKillerModel = findClosestKiller(pos)
				if lastKillerModel then
					warn("Death2: found killer model:", lastKillerModel.Name)
					-- capture killer part and CFrame in case model/parts are removed later
					local kp = lastKillerModel:FindFirstChild("Head") or lastKillerModel:FindFirstChild("HumanoidRootPart") or lastKillerModel.PrimaryPart
					if kp and kp:IsDescendantOf(workspace) then
						lastKillerPart = kp
						lastKillerCFrame = kp.CFrame
					else
						lastKillerPart = nil
						lastKillerCFrame = nil
					end
				else
					warn("Death2: no killer model found near death position")
					lastKillerPart = nil
					lastKillerCFrame = nil
				end
				showDeathScreenFor(lastKillerModel, pos)
			end
			
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- 1. SETUP THE GUI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Cleanup old GUI
if playerGui:FindFirstChild("DoorsDeathScreen_Simple") then
	playerGui.DoorsDeathScreen_Simple:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsDeathScreen_Simple"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui
screenGui.DisplayOrder = 100 
-- start disabled; only enable when the local player actually dies
screenGui.Enabled = false
-- Keep this ScreenGui across respawns so the death UI isn't removed automatically
screenGui.ResetOnSpawn = false

-- 2. SETUP AUDIO
local bgm = Instance.new("Sound")
bgm.Name = "DeathSound"
local success, result = pcall(function()
	return getcustomasset("forvids/death/death.mp3")
end)
if success then
	bgm.SoundId = result
else
	bgm.SoundId = "rbxassetid://0" 
end
bgm.Volume = 5
bgm.Parent = screenGui 

---------------------------------------------------------------------------------
-- A. COLORS & ASSETS
---------------------------------------------------------------------------------
local C_BG = Color3.fromRGB(28, 20, 20) 
local C_STROKE = Color3.fromRGB(235, 220, 180) 
local C_TEXT_MAIN = Color3.fromRGB(255, 245, 230) 
local C_TEXT_DIM = Color3.fromRGB(180, 170, 160) 
local C_RED = Color3.fromRGB(255, 100, 100) 
local C_ACCENT_BG = Color3.fromRGB(50, 35, 35) 

local ICON_SKULL = "rbxassetid://13672789956" 
local ICON_DOOR = "rbxassetid://10866380786" 
local ICON_KNOB = "rbxassetid://10866504620" 

-- Persistence for survived-wins (simple JSON in SAVE_FOLDER)
local SAVE_FOLDER = "death2_data"
local function supportsFileAPI()
	return typeof(isfile) == "function" and typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfolder) == "function" and typeof(makefolder) == "function"
end
local function ensureSaveFolder()
	if not supportsFileAPI() then return false end
	if not isfolder(SAVE_FOLDER) then
		local ok, _ = pcall(function() makefolder(SAVE_FOLDER) end)
		return ok
	end
	return true
end
local function getSavePath()
	return SAVE_FOLDER .. "/wins.json"
end

local winCount = 0
local function saveWins()
	if not supportsFileAPI() then return end
	ensureSaveFolder()
	local payload = { count = winCount, updatedAt = os.time() }
	pcall(function() writefile(getSavePath(), HttpService:JSONEncode(payload)) end)
end
local function loadWins()
	if not supportsFileAPI() then return end
	if not isfile(getSavePath()) then return end
	local ok, contents = pcall(function() return readfile(getSavePath()) end)
	if not ok or not contents then return end
	local ok2, data = pcall(function() return HttpService:JSONDecode(contents) end)
	if ok2 and type(data) == "table" and type(data.count) == "number" then
		winCount = math.max(0, math.floor(data.count))
	end
end
-- Load wins at script start (best-effort)
pcall(loadWins)


---------------------------------------------------------------------------------
-- B. INTRO LAYER (Skull Animation)
---------------------------------------------------------------------------------
local introContainer = Instance.new("Frame")
introContainer.Name = "IntroContainer"
introContainer.Size = UDim2.fromScale(1, 1)
introContainer.BackgroundTransparency = 1
introContainer.ZIndex = 50
introContainer.Parent = screenGui

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.ZIndex = 0
	bg.Parent = introContainer
	bg.BackgroundTransparency = 1

local introSkull = Instance.new("ImageLabel")
introSkull.Size = UDim2.fromScale(30, 18) 
introSkull.ScaleType = Enum.ScaleType.Fit
introSkull.AnchorPoint = Vector2.new(0.5, 0.5)
introSkull.Position = UDim2.fromScale(0.5, 0.5)
introSkull.BackgroundTransparency = 1
introSkull.Image = ICON_SKULL
introSkull.ImageColor3 = Color3.fromRGB(255, 255, 255)
introSkull.ImageTransparency = 1
introSkull.ZIndex = 2
introSkull.Parent = introContainer

local redLayer = introSkull:Clone()
redLayer.ImageColor3 = Color3.new(1,0,0)
redLayer.ImageTransparency = 1
redLayer.ZIndex = 1
redLayer.Parent = introContainer

local cyanLayer = introSkull:Clone()
cyanLayer.ImageColor3 = Color3.new(0,1,1)
cyanLayer.ImageTransparency = 1
cyanLayer.ZIndex = 1
cyanLayer.Parent = introContainer

---------------------------------------------------------------------------------
-- C. OVERVIEW UI
---------------------------------------------------------------------------------
local overviewContainer = Instance.new("Frame")
overviewContainer.Name = "OverviewContainer"
overviewContainer.Size = UDim2.fromScale(1, 1)
overviewContainer.BackgroundTransparency = 1
overviewContainer.Visible = false -- FORCE HIDDEN AT START
overviewContainer.ZIndex = 100
overviewContainer.Parent = screenGui

-- Curtain fade
local fadeCover = Instance.new("Frame")
fadeCover.Name = "FadeCover"
fadeCover.Size = UDim2.fromScale(1, 1)
fadeCover.BackgroundColor3 = Color3.new(0,0,0)
fadeCover.BackgroundTransparency = 0 
fadeCover.ZIndex = 200 
fadeCover.Parent = overviewContainer

-- 1. MAIN CONTAINER
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(700, 450)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.fromScale(0.5, 0.48)
mainFrame.BackgroundColor3 = C_BG
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 101
mainFrame.Parent = overviewContainer

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = C_STROKE
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local mainPad = Instance.new("UIPadding")
mainPad.PaddingTop = UDim.new(0, 20)
mainPad.PaddingLeft = UDim.new(0, 25)
mainPad.PaddingRight = UDim.new(0, 25)
mainPad.PaddingBottom = UDim.new(0, 20)
mainPad.Parent = mainFrame

-- Overview Header
local lblOverview = Instance.new("TextLabel")
lblOverview.Text = "OVERVIEW"
lblOverview.Font = Enum.Font.Oswald
lblOverview.TextSize = 36
lblOverview.TextColor3 = C_STROKE
lblOverview.TextXAlignment = Enum.TextXAlignment.Left
lblOverview.Size = UDim2.new(1, 0, 0, 40)
lblOverview.BackgroundTransparency = 1
lblOverview.ZIndex = 105
lblOverview.Parent = mainFrame

-- Death Cause
local deathRow = Instance.new("Frame")
deathRow.Size = UDim2.new(1, 0, 0, 40)
deathRow.Position = UDim2.new(0, 0, 0, 50)
deathRow.BackgroundTransparency = 1
deathRow.ZIndex = 105
deathRow.Parent = mainFrame

local iconDeath = Instance.new("ImageLabel")
iconDeath.Image = "rbxassetid://13516575727"
iconDeath.ImageColor3 = C_RED
iconDeath.BackgroundTransparency = 1
iconDeath.Size = UDim2.fromOffset(30, 30)
iconDeath.Position = UDim2.new(0, 0, 0.1, 0)
iconDeath.ZIndex = 105
iconDeath.Parent = deathRow

local lblDeath = Instance.new("TextLabel")
lblDeath.Text = "Died to Unknown"
lblDeath.Font = Enum.Font.Oswald
lblDeath.TextSize = 30
lblDeath.TextColor3 = C_RED
lblDeath.TextXAlignment = Enum.TextXAlignment.Left
lblDeath.BackgroundTransparency = 1
lblDeath.Size = UDim2.new(1, -40, 1, 0)
lblDeath.Position = UDim2.new(0, 40, 0, 0)
lblDeath.ZIndex = 105
lblDeath.Parent = deathRow

-- Rounds Survived Row
local doorRow = Instance.new("Frame")
doorRow.Size = UDim2.new(1, 0, 0, 40)
doorRow.Position = UDim2.new(0, 0, 0, 95)
doorRow.BackgroundTransparency = 1
doorRow.ZIndex = 105
doorRow.Parent = mainFrame

local iconDoor = Instance.new("ImageLabel")
iconDoor.Image = ICON_DOOR
iconDoor.ImageColor3 = C_TEXT_MAIN
iconDoor.BackgroundTransparency = 1
iconDoor.Size = UDim2.fromOffset(28, 28)
iconDoor.Position = UDim2.new(0, 2, 0.1, 0)
iconDoor.ZIndex = 105
iconDoor.Parent = doorRow

local lblDoor = Instance.new("TextLabel")
lblDoor.Text = "Survived for 3 rounds" -- UPDATED TEXT
lblDoor.Font = Enum.Font.Oswald
lblDoor.TextSize = 30
lblDoor.TextColor3 = C_TEXT_MAIN
lblDoor.TextXAlignment = Enum.TextXAlignment.Left
lblDoor.BackgroundTransparency = 1
lblDoor.Size = UDim2.new(1, -40, 1, 0)
lblDoor.Position = UDim2.new(0, 40, 0, 0)
lblDoor.ZIndex = 105
lblDoor.Parent = doorRow

-- Watermark Skull
local bgSkull = Instance.new("ImageLabel")
bgSkull.Image = ICON_SKULL
bgSkull.Size = UDim2.fromOffset(250, 250)
bgSkull.AnchorPoint = Vector2.new(0.5, 0.5)
bgSkull.Position = UDim2.new(0.5, 0, 0.5, 0)
bgSkull.BackgroundTransparency = 1
bgSkull.ImageTransparency = 0.9 
bgSkull.ImageColor3 = Color3.fromRGB(0, 0, 0) 
bgSkull.ZIndex = 102 
bgSkull.Parent = mainFrame

-- Stats Area
local statsContainer = Instance.new("Frame")
statsContainer.Size = UDim2.new(1, 0, 0, 130)
statsContainer.Position = UDim2.new(0, 0, 1, -130)
statsContainer.BackgroundTransparency = 1
statsContainer.ZIndex = 105
statsContainer.Parent = mainFrame

local rowsFrame = Instance.new("Frame")
rowsFrame.Size = UDim2.new(0.6, 0, 1, 0)
rowsFrame.BackgroundTransparency = 1
rowsFrame.Parent = statsContainer

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = rowsFrame

local function createStatRow(text, rightText, isKnob, isGold)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundColor3 = C_ACCENT_BG
	row.BackgroundTransparency = 0.5
	row.BorderSizePixel = 0
	row.ZIndex = 106
	row.Parent = rowsFrame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = row
	
	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 16
	lbl.TextColor3 = C_TEXT_DIM
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(0.6, 0, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.ZIndex = 107
	lbl.Parent = row
	
	local valContainer = Instance.new("Frame")
	valContainer.Size = UDim2.new(0.4, 0, 1, 0)
	valContainer.Position = UDim2.new(0.6, 0, 0, 0)
	valContainer.BackgroundTransparency = 1
	valContainer.ZIndex = 107
	valContainer.Parent = row
	
	local valLayout = Instance.new("UIListLayout")
	valLayout.FillDirection = Enum.FillDirection.Horizontal
	valLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	valLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	valLayout.Padding = UDim.new(0, 5)
	valLayout.Parent = valContainer
	
	local valTxt = Instance.new("TextLabel")
	valTxt.Text = rightText
	valTxt.Font = Enum.Font.GothamBold
	valTxt.TextSize = 16
	valTxt.TextColor3 = C_TEXT_MAIN
	valTxt.AutomaticSize = Enum.AutomaticSize.X
	valTxt.BackgroundTransparency = 1
	valTxt.Size = UDim2.new(0, 0, 1, 0)
	valTxt.ZIndex = 107
	valTxt.Parent = valContainer
	
	if isKnob then
		local icon = Instance.new("ImageLabel")
		icon.Image = ICON_KNOB
		icon.Size = UDim2.fromOffset(18, 18)
		icon.BackgroundTransparency = 1
		icon.ZIndex = 107
		icon.Parent = valContainer
		valTxt.LayoutOrder = 2 
		icon.LayoutOrder = 1
	end
	
	local p = Instance.new("UIPadding")
	p.PaddingRight = UDim.new(0, 10)
	p.Parent = valContainer
	-- return the value text so callers can update it later
	return valTxt
end

-- UPDATED STATS: Removed gold/friends, changed text
local roundsStatVal = createStatRow("Rounds Survived", "+ 0", true)


-- Total Calculation Frame
local totalFrame = Instance.new("Frame")
totalFrame.Size = UDim2.new(0.38, 0, 1, 0)
totalFrame.Position = UDim2.new(0.62, 0, 0, 0)
totalFrame.BackgroundColor3 = Color3.fromRGB(45, 30, 30)
totalFrame.BorderSizePixel = 0
totalFrame.ZIndex = 106
totalFrame.Parent = statsContainer

local totalCorner = Instance.new("UICorner")
totalCorner.CornerRadius = UDim.new(0, 8)
totalCorner.Parent = totalFrame

local calcRow = Instance.new("Frame")
calcRow.Size = UDim2.new(1, 0, 0.4, 0)
calcRow.BackgroundTransparency = 1
calcRow.ZIndex = 107
calcRow.Parent = totalFrame

local layoutCalc = Instance.new("UIListLayout")
layoutCalc.FillDirection = Enum.FillDirection.Horizontal
layoutCalc.HorizontalAlignment = Enum.HorizontalAlignment.Center
layoutCalc.VerticalAlignment = Enum.VerticalAlignment.Center
layoutCalc.Padding = UDim.new(0, 4)
layoutCalc.Parent = calcRow

local smKnob = Instance.new("ImageLabel")
smKnob.Image = ICON_KNOB
smKnob.BackgroundTransparency = 1
smKnob.Size = UDim2.fromOffset(20, 20)
smKnob.ZIndex = 107
smKnob.Parent = calcRow

local smText = Instance.new("TextLabel")
smText.Text = "3   x 1.0 =" -- Updated to match stats
smText.Font = Enum.Font.GothamBold
smText.TextSize = 18
smText.TextColor3 = Color3.fromRGB(255, 180, 50) 
smText.BackgroundTransparency = 1
smText.AutomaticSize = Enum.AutomaticSize.X
smText.Size = UDim2.new(0, 0, 1, 0)
smText.ZIndex = 107
smText.Parent = calcRow

local bigRow = Instance.new("Frame")
bigRow.Size = UDim2.new(1, 0, 0.6, 0)
bigRow.Position = UDim2.new(0, 0, 0.4, 0)
bigRow.BackgroundTransparency = 1
bigRow.ZIndex = 107
bigRow.Parent = totalFrame

local bigKnob = Instance.new("ImageLabel")
bigKnob.Image = ICON_KNOB
bigKnob.BackgroundTransparency = 1
bigKnob.Size = UDim2.fromOffset(40, 40)
bigKnob.Position = UDim2.new(0.1, 0, 0.1, 0)
bigKnob.ZIndex = 107
bigKnob.Parent = bigRow

local bigText = Instance.new("TextLabel")
bigText.Text = "3" -- Updated total
bigText.Font = Enum.Font.Oswald
bigText.TextSize = 60
bigText.TextColor3 = C_TEXT_MAIN
bigText.BackgroundTransparency = 1
bigText.Size = UDim2.new(1, -20, 1, 0)
bigText.TextXAlignment = Enum.TextXAlignment.Right
bigText.ZIndex = 107
bigText.Parent = bigRow
-- Capture the original transparency values for overview descendants so we can restore on reuse
local overviewOriginalTrans = {}
do
	for _, obj in ipairs(overviewContainer:GetDescendants()) do
		local props = {}
		pcall(function()
			if obj:IsA("Frame") then
				props.Background = obj.BackgroundTransparency
			end
			if obj:IsA("TextLabel") or obj:IsA("TextButton") then
				props.Text = obj.TextTransparency
				props.Background = obj.BackgroundTransparency
			end
			if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
				props.Image = obj.ImageTransparency
				props.Background = obj.BackgroundTransparency
			end
			if obj:IsA("UIStroke") then
				props.Stroke = obj.Transparency
			end
		end)
		if next(props) then
			overviewOriginalTrans[obj] = props
		end
	end
end


-- 2. BOTTOM BUTTON (Ok)
local btnsFrame = Instance.new("Frame")
btnsFrame.Size = UDim2.new(0, 700, 0, 60)
btnsFrame.AnchorPoint = Vector2.new(0.5, 0)
btnsFrame.Position = UDim2.new(0.5, 0, 0.88, 0)
btnsFrame.BackgroundTransparency = 1
btnsFrame.ZIndex = 101
btnsFrame.Parent = overviewContainer

-- Ok button removed per request (UI remains but no interactive Ok)


---------------------------------------------------------------------------------
-- D. LOGIC
---------------------------------------------------------------------------------
local shakeIntensity = Instance.new("NumberValue")
shakeIntensity.Value = 0 
shakeIntensity.Parent = script

-- don't animate until triggered by a death event
local isAnimating = false
local inputConnection = nil
local scriptConnections = {}
local function registerConnection(conn)
	if conn and conn.Disconnect then
		table.insert(scriptConnections, conn)
	end
end

local function cleanup()
	-- soft cleanup: stop animations and hide UI but keep connections so script works on subsequent deaths
	isAnimating = false
	-- stop music if playing
	pcall(function() if bgm and bgm.IsPlaying then bgm:Stop() end end)
	-- hide overview if present
	pcall(function() if overviewContainer and overviewContainer.Parent then overviewContainer.Visible = false end end)
	-- hide intro if still present (don't destroy so it can be reused)
	pcall(function() if introContainer and introContainer.Parent then introContainer.Visible = false end end)
	-- reset shake
	pcall(function() if shakeIntensity then shakeIntensity.Value = 0 end end)
end

inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Y then
		-- prefer the restore that also resurrects and restores camera
		if cleanupAndRestore then
			cleanupAndRestore()
		else
			cleanup()
		end
	end
end)
registerConnection(inputConnection)

-- We'll add camera/spectate logic and hook the Ok button to a cleanup that restores the camera.
-- This block defines camera helpers and the show flow below.

-- Camera + spectate logic
-- camera functionality removed per user request; keep only UI
local camera = nil
local cameraSpinConnection = nil
local previousCameraType, previousCameraSubject, previousCameraCFrame = nil, nil, nil
local previousCharacterAutoLoads = nil
local lastDeathPosition = nil
local lastKillerModel = nil
local lastSpectateDone = false
-- Safe accessors for CharacterAutoLoads (property may not exist in some environments)
-- character auto-load helpers removed (camera/respawn control removed)

local function findSurvivorModel()
	-- Try multiple strategies to locate the local player's model.
	-- 1) Prefer workspace.Players.Survivors/<player.Name>
	local playersFolder = workspace:FindFirstChild("Players")
	local survivorsFolder = playersFolder and playersFolder:FindFirstChild("Survivors")
	if survivorsFolder then
		local byName = survivorsFolder:FindFirstChild(player.Name)
		if byName then
			warn("Death2: found survivor in Players.Survivors by name ->", byName:GetFullName())
			return byName
		end
	end

	-- 2) Fallback to the player's Character if present
	if player.Character and player.Character.Parent then
		warn("Death2: using player.Character as survivor model ->", player.Character:GetFullName())
		return player.Character
	end

	-- 3) Search workspace for a Model matching common patterns:
	--    - Name == player.Name
	--    - Has a Humanoid and StringValue/ObjectValue tags like "Owner"/"Player"/"Creator"
	--    - Has attributes "Owner" or "Player" matching player.Name or player.UserId
	local function modelMatchesPlayer(model)
		if not model:IsA("Model") then return false end
		if model.Name == player.Name then return true end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		local strTag = model:FindFirstChild("Owner") or model:FindFirstChild("Player") or model:FindFirstChild("Creator")
		if strTag and strTag:IsA("StringValue") and strTag.Value == player.Name then return true end
		local objTag = model:FindFirstChild("Owner") or model:FindFirstChild("Player")
		if objTag and objTag:IsA("ObjectValue") and objTag.Value == player then return true end
		if model.GetAttribute then
			local a = model:GetAttribute("Owner") or model:GetAttribute("Player")
			if a == player.Name or a == player.UserId then return true end
		end
		return false
	end

	-- shallow workspace children
	for _, ch in ipairs(workspace:GetChildren()) do
		if modelMatchesPlayer(ch) then
			warn("Death2: found survivor model via workspace children ->", ch:GetFullName())
			return ch
		end
	end

	-- deep search as last resort
	for _, desc in ipairs(workspace:GetDescendants()) do
		if modelMatchesPlayer(desc) then
			warn("Death2: found survivor model via workspace descendants ->", desc:GetFullName())
			return desc
		end
	end

	-- not found
	return nil
end

local function findClosestKiller(fromPosition)
	local playersFolder = workspace:FindFirstChild("Players")
	local killersFolder = playersFolder and playersFolder:FindFirstChild("Killers")
	if not killersFolder then return nil end
	local best, bestDist = nil, math.huge
	for _, model in ipairs(killersFolder:GetChildren()) do
		local part = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
		if part and part.Position then
			local d = (part.Position - fromPosition).Magnitude
			if d < bestDist then
				bestDist = d
				best = model
			end
		end
	end
	return best
end

-- Robust spectate helper with debug logs. Tries to use the target for `duration` seconds.
-- camera/spectate helpers removed per user request

local function cleanupAndRestore()
	-- Soft cleanup and respawn: hide UI but keep connections so UI can be reused on later deaths
	isAnimating = false
	-- stop music if playing
	pcall(function() if bgm and bgm.IsPlaying then bgm:Stop() end end)
	-- hide overview and intro for reuse
	pcall(function()
		if overviewContainer and overviewContainer.Parent then overviewContainer.Visible = false end
		if introContainer and introContainer.Parent then introContainer.Visible = false end
	end)
	-- reset shake
	pcall(function() if shakeIntensity then shakeIntensity.Value = 0 end end)
	-- respawn the player (best-effort)
	pcall(function() player:LoadCharacter() end)
	-- clear saved death state
	lastDeathPosition = nil
	lastKillerModel = nil
end

-- Full destroy function to cleanly remove this script and its GUIs/connections
local function destroyScript()
	warn("Death2: destroyScript called - cleaning up everything")
	-- stop bgm
	pcall(function() if bgm and bgm.IsPlaying then bgm:Stop() end end)
	-- disconnect registered connections
	for _, c in ipairs(scriptConnections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(scriptConnections)

	-- Destroy GUI containers
	pcall(function()
		if introContainer and introContainer.Parent then introContainer:Destroy() end
	end)
	pcall(function()
		if overviewContainer and overviewContainer.Parent then overviewContainer:Destroy() end
	end)
	pcall(function() if screenGui and screenGui.Parent then screenGui:Destroy() end end)

	-- Destroy helpers
	pcall(function() if shakeIntensity then shakeIntensity:Destroy() end end)

	-- Clear persisted state
	winCount = 0
	pcall(saveWins)

	-- Expose destroyed flag
	pcall(function() getgenv().Death2Destroyed = true end)
end

-- expose destroy function for external scripts
pcall(function() getgenv().Death2Destroy = destroyScript end)

local function onOkButtonClicked()
	-- immediate fix: stop spinning and attach camera to player's humanoid if present
	stopCameraSpin()
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		local char = player.Character
		if char then
			local hm = char:FindFirstChildOfClass("Humanoid")
			if hm then camera.CameraSubject = hm end
		end
	end
	-- proceed with full cleanup and respawn
	cleanupAndRestore()
end

-- Ok button removed; auto-fade will handle cleanup

-- Show death screen flow; called when the survivor dies
-- forward declare animation runner so it can be called from showDeathScreenFor
local runIntroAndOverview

local function showDeathScreenFor(killerModel, deathPosition)
	screenGui.Enabled = true
	isAnimating = true
	bgm:Play()

	-- killer name
	if killerModel and killerModel.Name then
		lblDeath.Text = "Died to " .. tostring(killerModel.Name)
	else
		lblDeath.Text = "Died to Unknown"
	end

	-- set background transparency per request (0.7)
	fadeCover.BackgroundTransparency = 0.7

	-- run the intro + overview flow. overview will auto-fade after 6s and then cleanup.
	runIntroAndOverview()
end

-- Connect to the local survivor Humanoid.Died
local function hookLocalSurvivor()
	local survivor = findSurvivorModel()
	if not survivor then
		warn("Death2: could not find survivor model for player", player.Name, "(checked workspace.Players.Survivors).")
		return
	end
	-- If the game uses a Players.Survivors folder, only hook models that are descendants of it.
	local playersFolder = workspace:FindFirstChild("Players")
	local survivorsFolder = playersFolder and playersFolder:FindFirstChild("Survivors")
	if survivorsFolder and not survivor:IsDescendantOf(survivorsFolder) then
		warn("Death2: found model but it's not in Players.Survivors; skipping hook for non-survivor model ->", survivor.Name)
		return
	end
	warn("Death2: found survivor model:", survivor.Name)
	local humanoid = survivor:FindFirstChildOfClass("Humanoid")
	local root = survivor:FindFirstChild("HumanoidRootPart") or survivor:FindFirstChild("Torso") or survivor.PrimaryPart
	if humanoid then
		warn("Death2: hooking humanoid.Died for", survivor.Name)
		-- Record death position exactly when health reaches 0 (body may move after death)
		local handled = false

		local function getCurrentDeathPosition()
			-- prefer root part position if available at the instant of death
			if root and root.Parent and root.Position then
				return root.Position
			end
			if survivor.PrimaryPart and survivor.PrimaryPart.Position then
				return survivor.PrimaryPart.Position
			end
			local ok, cf = pcall(function() return survivor:GetModelCFrame() end)
			if ok and cf then return cf.p end
			return Vector3.new(0, 0, 0)
		end

		local function handleDeathPos(pos)
			if handled then return end
			handled = true
			warn("Death2: captured death position ->", pos)
			local killer = findClosestKiller(pos)
			if killer then
				warn("Death2: found killer model:", killer.Name)
			else
				warn("Death2: no killer model found near death position")
			end
			showDeathScreenFor(killer, pos)
		end

		-- If the humanoid is already at or below 0, capture immediately
		if humanoid.Health <= 0 then
			local pos = getCurrentDeathPosition()
			warn("Death2: humanoid already at 0 when hooking, using pos", pos)
			handleDeathPos(pos)
		else
			-- HealthChanged will reliably fire at the moment health crosses to 0
			local healthConn
			healthConn = humanoid.HealthChanged:Connect(function(newHealth)
				if newHealth <= 0 then
					local pos = getCurrentDeathPosition()
					warn("Death2: HealthChanged detected <=0 at pos", pos)
					handleDeathPos(pos)
					if healthConn then healthConn:Disconnect() end
				end
			end)
			registerConnection(healthConn)

			-- fallback to Died event in case HealthChanged wasn't available
			local diedConn = humanoid.Died:Connect(function()
				if handled then return end
				local pos = getCurrentDeathPosition()
				warn("Death2: Died event fired, using pos", pos)
				handleDeathPos(pos)
				if healthConn then healthConn:Disconnect() end
			end)
			registerConnection(diedConn)
		end
	else
		warn("Death2: survivor model has no Humanoid:", survivor.Name)
	end
end

-- attempt to hook now and also when character spawns
hookLocalSurvivor()
local charAddedConn = player.CharacterAdded:Connect(function()
	-- small delay to allow model to be placed under workspace.Players.Survivors if game moves it there
	task.delay(0.2, hookLocalSurvivor)
end)
registerConnection(charAddedConn)

-- Monitor round timer to award wins when timer hits 0 while alive in Survivors
task.spawn(function()
	-- try to locate RoundTimer in PlayerGui
	local roundTimer = nil
	local timerLabel = nil
	while not timerLabel do
		roundTimer = playerGui:FindFirstChild("RoundTimer") or playerGui:FindFirstChild("RoundTimerGui")
		if roundTimer then
			local ok, main = pcall(function() return roundTimer:FindFirstChild("Main") end)
			if ok and main then
				timerLabel = main:FindFirstChild("Time") or main:FindFirstChildWhichIsA("TextLabel")
			end
		end
		if not timerLabel then task.wait(1) end
	end

	local lastWasZero = false
	local timerTextConn = timerLabel:GetPropertyChangedSignal("Text"):Connect(function()
		local txt = timerLabel.Text
		if txt == "0:00" and not lastWasZero then
			lastWasZero = true
			-- check if player alive and in Survivors
			local char = player.Character
			if char and char.Parent then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				local playersRoot = workspace:FindFirstChild("Players")
				local survivors = playersRoot and playersRoot:FindFirstChild("Survivors")
				if humanoid and humanoid.Health > 0 and survivors and char:IsDescendantOf(survivors) then
					-- award win
					winCount = winCount + 1
					saveWins()
					warn("Death2: awarded win, total now", winCount)
				end
			end
		elseif txt ~= "0:00" then
			lastWasZero = false
		end
	end)
	registerConnection(timerTextConn)
end)

---------------------------------------------------------------------------------
-- E. ANIMATION
---------------------------------------------------------------------------------
runIntroAndOverview = function()
	local function active() return isAnimating and screenGui.Parent end

	-- 1. INTRO START
	ContentProvider:PreloadAsync({introSkull})
	-- ensure intro container is visible (cleanup hides it for reuse)
	pcall(function()
		if introContainer then introContainer.Visible = true end
		if overviewContainer then overviewContainer.Visible = false end
		if introSkull then introSkull.Visible = true end
		redLayer.Visible = false
		cyanLayer.Visible = false
	end)
	
	local startScale = UDim2.fromScale(30, 18) 
	local normalScale = UDim2.fromScale(0.7, 0.4)
	
	introSkull.Size = startScale
	introSkull.ImageTransparency = 1 
	
	task.wait(0.5)
	if not active() then return end
	
	-- Fade In
	TweenService:Create(introSkull, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {ImageTransparency = 0}):Play()
	
	task.wait()
	if not active() then return end
	
	-- Shrink
	local shrinkTween = TweenService:Create(introSkull, TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Size = normalScale})
	shrinkTween:Play()
	shrinkTween.Completed:Wait()
	if not active() then return end
	
	-- Jitter
	bg.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
	TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(0,0,0)}):Play()
	
	redLayer.Size = normalScale
	cyanLayer.Size = normalScale
	redLayer.Visible = true
	cyanLayer.Visible = true
	shakeIntensity.Value = 45 
	
	task.wait(0.7)
	if not active() then return end
	
	-- Fade Jitter
	local fadeJitter = TweenInfo.new(0.7, Enum.EasingStyle.Linear)
	TweenService:Create(shakeIntensity, fadeJitter, {Value = 0}):Play()
	TweenService:Create(redLayer, fadeJitter, {ImageTransparency = 1}):Play()
	TweenService:Create(cyanLayer, fadeJitter, {ImageTransparency = 1}):Play()
	
	task.wait(0.3)
	if not active() then return end
	
	-- Static Wait
	shakeIntensity.Value = 0
	introSkull.Position = UDim2.fromScale(0.5, 0.5)
	redLayer.Visible = false
	cyanLayer.Visible = false
	introSkull.ImageTransparency = 0 
	
	task.wait(1)
	if not active() then return end
	
	---------------------------------------------------------------------------
	-- 2. TRANSITION TO OVERVIEW
	---------------------------------------------------------------------------
	local outroDuration = 1.0
	local smallExpandScale = UDim2.fromScale(1.2, 0.7) 
	
	-- A. Start Expansion & Fade Out of Skull
	TweenService:Create(introSkull, TweenInfo.new(outroDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = smallExpandScale,
		ImageTransparency = 1
	}):Play()
	
	-- B. WAIT until it's FULLY gone
	task.wait(outroDuration)
	if not active() then return end
	
	-- C. SHOW Overview (Enable + set cover transparency to requested value)
	overviewContainer.Visible = true
	-- user requested background transparency to be 0.7 for overview
	fadeCover.BackgroundTransparency = 0.7
	-- restore original transparency values for overview descendants (preserve intended styling)
	pcall(function()
		for obj, props in pairs(overviewOriginalTrans) do
			pcall(function()
				if not obj or not obj.Parent then return end
				if props.Background ~= nil and obj:IsA("Frame") or obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
					obj.BackgroundTransparency = props.Background
				end
				if props.Text ~= nil and (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
					obj.TextTransparency = props.Text
				end
				if props.Image ~= nil and (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
					obj.ImageTransparency = props.Image
				end
				if props.Stroke ~= nil and obj:IsA("UIStroke") then
					obj.Transparency = props.Stroke
				end
				-- ensure the object is visible in case it was hidden
				if obj:IsA("GuiObject") then obj.Visible = true end
			end)
		end
		if mainFrame then mainFrame.Visible = true end
	end)

	-- remove the intro container (skull screen) so it doesn't block the world view
	if introContainer and introContainer.Parent then
		-- hide the intro container so it doesn't block the world view; keep it for reuse
		introContainer.Visible = false
	end

	-- show the overview, keep fully visible for 5s, then fade out smoothly over 3s and cleanup
	overviewContainer.Visible = true
	fadeCover.BackgroundTransparency = 0.7
	-- fully visible pause
	local visiblePause = 5
	-- update survived text from persistent wins, then reset persisted wins
	pcall(function()
		loadWins()
		local lastWins = winCount
		lblDoor.Text = "Survived for " .. tostring(lastWins) .. " rounds"
		bigText.Text = tostring(lastWins)
		-- update stat row and small calc text to match
		pcall(function()
			if roundsStatVal then roundsStatVal.Text = "+ " .. tostring(lastWins) end
			if smText then smText.Text = tostring(lastWins) .. "   x 1.0 =" end
		end)
		-- reset persisted wins now that we've shown the last value
		winCount = 0
		saveWins()
		warn("Death2: reset persisted winCount after death overview (was " .. tostring(lastWins) .. ")")
	end)
	task.wait(visiblePause)

	-- fade duration (3s)
	local fadeDuration = 3
	local fadeTween = TweenService:Create(fadeCover, TweenInfo.new(fadeDuration, Enum.EasingStyle.Linear), {BackgroundTransparency = 1})

	-- also tween visible UI elements' transparencies so the overview fades out smoothly
	local tweens = {}
	for _, obj in ipairs(overviewContainer:GetDescendants()) do
		local props = {}
		local shouldTween = false
		if obj:IsA("Frame") then
			props.BackgroundTransparency = 1
			shouldTween = true
		elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
			props.TextTransparency = 1
			props.BackgroundTransparency = 1
			shouldTween = true
		elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			props.ImageTransparency = 1
			props.BackgroundTransparency = 1
			shouldTween = true
		elseif obj:IsA("UIStroke") then
			props.Transparency = 1
			shouldTween = true
		end
		if shouldTween then
			local ok, t = pcall(function()
				return TweenService:Create(obj, TweenInfo.new(fadeDuration, Enum.EasingStyle.Linear), props)
			end)
			if ok and t then
				table.insert(tweens, t)
			end
		end
	end

	-- play all tweens
	for _, t in ipairs(tweens) do pcall(function() t:Play() end) end
	fadeTween:Play()
	fadeTween.Completed:Wait()
	-- after fade completes, cleanup the GUI
	cleanup()
end

---------------------------------------------------------------------------------
-- F. RENDER LOOP
---------------------------------------------------------------------------------
local renderSteppedConn = RunService.RenderStepped:Connect(function()
	if not isAnimating then return end
	
	local currentShake = shakeIntensity.Value
	if currentShake > 0 then
		local offsetX = math.random(-currentShake, currentShake)
		local offsetY = math.random(-currentShake, currentShake)
		introSkull.Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(offsetX, offsetY)
		
		local split = math.max(3, currentShake * 0.6)
		redLayer.Position = introSkull.Position + UDim2.fromOffset(-split, 0)
		cyanLayer.Position = introSkull.Position + UDim2.fromOffset(split, 0)
		
		if introSkull.ImageTransparency < 1 and shakeIntensity.Value > 5 then
			local flicker = (math.random(3, 7)/10) + introSkull.ImageTransparency
			redLayer.ImageTransparency = flicker
			cyanLayer.ImageTransparency = flicker
		end
	end
end)
registerConnection(renderSteppedConn)
