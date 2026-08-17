workspace.FallenPartsDestroyHeight = 0/0

if getgenv().__gakuranFlingCleanup then
    pcall(getgenv().__gakuranFlingCleanup)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local touchStrength = 5000
local targetStrength = 9e9
local predictionMultiplier = 2.6
local teleportDistance = 20
local targetOffset = 2
local targetQuery = ""
local victimVelocityLimit = 1000
local velocityLimitEnabled = true
local standingStillThreshold = 0.5
local lockedTarget = nil
local targetMethod = "Predictive Fling"

local touchEnabled = false
local touchConnection = nil
local deathConnection = nil
local touchBurstRunning = false
local touchActiveBurst = nil
local touchCollisionState = {}

local targetBusy = false
local targetCancelled = false
local targetCleanup = nil
local motionHistory = {}
local predictionSmoothing = {}
local motionConnection = nil
local teleportConnection = nil
local rageEnabled = false
local savedNormalTouchStrength = touchStrength
local touchStrengthSlider = nil
local Notify = nil

local function rootOf(character)
    if not character then
        return nil
    end

    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    return humanoid and humanoid.RootPart
        or character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
        or character.PrimaryPart
end

local function teleportForward()
    local character = LocalPlayer.Character
    local root = rootOf(character)
    if not root or not root.Parent then
        return
    end

    local camera = workspace.CurrentCamera
    local look = camera and camera.CFrame.LookVector or root.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude < 0.05 then
        flatLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    end
    if flatLook.Magnitude < 0.05 then
        return
    end

    local destination = root.Position + flatLook.Unit * teleportDistance
    root.CFrame = CFrame.new(destination, destination + flatLook.Unit)
end

local function playTouchAnimation()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://133566007754001"

    local track = animator:LoadAnimation(animation)
    track.Looped = false
    track.Priority = Enum.AnimationPriority.Action4
    local originalWalkSpeed = humanoid.WalkSpeed
    local boosted = false

    track:Play()
    task.spawn(function()
        local waitForLength = 0
        while track.Length <= 0 and waitForLength < 1 do
            waitForLength = waitForLength + task.wait()
        end

        task.wait(0.5)
        if track.IsPlaying and humanoid.Parent then
            humanoid.WalkSpeed = originalWalkSpeed * 1.4
            boosted = true
        end
    end)

    track.Stopped:Once(function()
        if boosted and humanoid.Parent then
            humanoid.WalkSpeed = originalWalkSpeed
        end
        animation:Destroy()
    end)
end
local function notify(title, content, options)
    if Notify then
        Notify.push(title, content, options)
    end
end

local function toggleRage()
    if not touchStrengthSlider then
        return
    end

    rageEnabled = not rageEnabled
    if rageEnabled then
        savedNormalTouchStrength = math.clamp(touchStrength, 100, 5000)
        touchStrength = 9e9
        touchStrengthSlider:SetRange(50000, 9e9)
        touchStrengthSlider:SetValue(touchStrength)
        notify("Rage enabled", "Touch Strength range is now 50000 to 9e9", {
            color = Color3.fromRGB(180, 20, 20),
            duration = 4,
        })
    else
        touchStrengthSlider:SetRange(100, 5000)
        touchStrength = savedNormalTouchStrength
        touchStrengthSlider:SetValue(touchStrength)
        notify("Rage disabled", "Touch Strength restored to " .. tostring(touchStrength), {
            color = Color3.fromRGB(10, 80, 170),
            duration = 4,
        })
    end
end

local function alivePlayer(player)
    if not player or player == LocalPlayer or player.Parent ~= Players then
        return false
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    return humanoid ~= nil and humanoid.Health > 0 and rootOf(character) ~= nil
end

local function findPlayer(query)
    query = string.lower(query or "")
    if query == "" then
        return nil
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local username = string.lower(player.Name)
            local displayName = string.lower(player.DisplayName)
            if string.sub(username, 1, #query) == query or string.sub(displayName, 1, #query) == query then
                return player
            end
        end
    end

    return nil
end

local function nearestPlayer()
    local myRoot = rootOf(LocalPlayer.Character)
    if not myRoot then
        return nil
    end

    local closest = nil
    local closestDistance = nil

    for _, player in ipairs(Players:GetPlayers()) do
        if alivePlayer(player) then
            local targetRoot = rootOf(player.Character)
            local distance = (targetRoot.Position - myRoot.Position).Magnitude
            if not closestDistance or distance < closestDistance then
                closest = player
                closestDistance = distance
            end
        end
    end

    return closest
end

local function currentTarget()
    if alivePlayer(lockedTarget) then
        return lockedTarget
    end

    local queried = findPlayer(targetQuery)
    if alivePlayer(queried) then
        lockedTarget = queried
        return queried
    end

    return nil
end

local function pingMilliseconds()
    local ok, value = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)

    if ok and type(value) == "number" then
        return value
    end

    return 60
end

local function predictionSeconds()
    local pingSeconds = pingMilliseconds() / 1000
    return math.clamp((pingSeconds + 1 / 60) * predictionMultiplier, 0.015, 0.4)
end

local function predictPosition(position, velocity, predictionTime)
    local gravity = Vector3.new(0, -workspace.Gravity, 0)
    return position + velocity * predictionTime + gravity * 0.5 * predictionTime * predictionTime
end

local function groundedState(character, root)
    local parameters = RaycastParams.new()
    parameters.FilterType = Enum.RaycastFilterType.Exclude
    parameters.FilterDescendantsInstances = {character, LocalPlayer.Character}

    local distance = math.max(3.5, root.Size.Y * 0.5 + 1.5)
    local hit = workspace:Raycast(root.Position, Vector3.new(0, -distance, 0), parameters)
    return hit ~= nil and hit.Normal.Y > 0.45, hit
end

local function recordMotionSamples()
    local now = os.clock()

    for _, player in ipairs(Players:GetPlayers()) do
        if alivePlayer(player) then
            local root = rootOf(player.Character)
            local history = motionHistory[player]
            if not history then
                history = {}
                motionHistory[player] = history
            end

            history[#history + 1] = {
                time = now,
                position = root.Position,
                velocity = root.AssemblyLinearVelocity,
            }

            while #history > 12 or (#history > 2 and now - history[1].time > 0.5) do
                table.remove(history, 1)
            end
        else
            motionHistory[player] = nil
            predictionSmoothing[player] = nil
        end
    end
end

local function estimatedVelocity(target, targetRoot, targetHumanoid, grounded)
    local assemblyVelocity = targetRoot.AssemblyLinearVelocity
    local history = motionHistory[target]
    local observedVelocity = assemblyVelocity

    if history and #history >= 2 then
        local first = history[1]
        local last = history[#history]
        local elapsed = last.time - first.time
        if elapsed > 0.01 then
            observedVelocity = (last.position - first.position) / elapsed
        end
    end

    local velocity = assemblyVelocity:Lerp(observedVelocity, 0.7)

    if grounded then
        local moveVelocity = targetHumanoid.MoveDirection * targetHumanoid.WalkSpeed
        local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
        if moveVelocity.Magnitude > 0.1 then
            horizontal = horizontal:Lerp(moveVelocity, 0.35)
        end
        velocity = horizontal
    end

    return velocity
end

local function simulateTarget(target, horizon)
    local character = target.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local root = rootOf(character)
    if not character or not humanoid or not root then
        return nil, nil
    end

    local grounded = groundedState(character, root)
    local position = root.Position
    local velocity = estimatedVelocity(target, root, humanoid, grounded)
    local gravity = Vector3.new(0, -workspace.Gravity, 0)
    local parameters = RaycastParams.new()
    parameters.FilterType = Enum.RaycastFilterType.Exclude
    parameters.FilterDescendantsInstances = {character, LocalPlayer.Character}

    local elapsed = 0
    while elapsed < horizon do
        local stepTime = math.min(0.03, horizon - elapsed)
        local acceleration = grounded and Vector3.zero or gravity
        local nextPosition = predictPosition(position, velocity, stepTime)
        if grounded then
            nextPosition = position + velocity * stepTime
        end

        local travel = nextPosition - position
        local hit = travel.Magnitude > 0.001 and workspace:Raycast(position, travel, parameters) or nil

        if hit then
            position = hit.Position + hit.Normal * 0.1
            velocity = velocity - hit.Normal * velocity:Dot(hit.Normal)
            if hit.Normal.Y > 0.45 then
                grounded = true
                velocity = Vector3.new(velocity.X, 0, velocity.Z)
            end
        else
            position = nextPosition
            velocity = velocity + acceleration * stepTime

            if grounded then
                local groundProbe = workspace:Raycast(
                    position + Vector3.new(0, 2, 0),
                    Vector3.new(0, -6, 0),
                    parameters
                )

                if groundProbe and groundProbe.Normal.Y > 0.45 then
                    position = Vector3.new(
                        position.X,
                        groundProbe.Position.Y + root.Size.Y * 0.5,
                        position.Z
                    )
                    velocity = Vector3.new(velocity.X, 0, velocity.Z)
                else
                    grounded = false
                end
            end
        end

        elapsed = elapsed + stepTime
    end

    return position, velocity
end

local function saveAndDisableCollision(character)
    local state = {}

    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                state[part] = part.CanCollide
                part.CanCollide = false
            end
        end
    end

    return state
end

local function restoreCollision(state)
    for part, originalState in pairs(state or {}) do
        if part and part.Parent then
            part.CanCollide = originalState
        end
    end
end

local function restoreTouchBurst()
    local burst = touchActiveBurst
    touchActiveBurst = nil

    if burst and burst.root and burst.root.Parent then
        burst.root.AssemblyLinearVelocity = burst.linear
        burst.root.Velocity = burst.velocity
        burst.root.AssemblyAngularVelocity = burst.angular
    end
end

local function stopTouchFling()
    touchEnabled = false

    if touchConnection then
        touchConnection:Disconnect()
        touchConnection = nil
    end

    if deathConnection then
        deathConnection:Disconnect()
        deathConnection = nil
    end

    restoreTouchBurst()
    restoreCollision(touchCollisionState)
    touchCollisionState = {}
    touchBurstRunning = false
end

local function touchBurst()
    if not touchEnabled or touchBurstRunning then
        return
    end

    local root = rootOf(LocalPlayer.Character)
    if not root or not root.Parent then
        return
    end

    local camera = workspace.CurrentCamera
    local look = camera and camera.CFrame.LookVector or Vector3.new(0, 0, -1)
    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude < 0.05 then
        flatLook = Vector3.new(0, 0, -1)
    end

    touchBurstRunning = true
    touchActiveBurst = {
        root = root,
        linear = root.AssemblyLinearVelocity,
        velocity = root.Velocity,
        angular = root.AssemblyAngularVelocity,
    }

    local burstVelocity = flatLook.Unit * touchStrength
    root.AssemblyLinearVelocity = burstVelocity
    root.Velocity = burstVelocity

    RunService.RenderStepped:Wait()
    restoreTouchBurst()
    touchBurstRunning = false
end

local function startTouchFling()
    stopTouchFling()
    targetCancelled = true
    if targetCleanup then
        pcall(targetCleanup)
    end

    touchEnabled = true
    touchCollisionState = saveAndDisableCollision(LocalPlayer.Character)

    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        deathConnection = humanoid.Died:Connect(stopTouchFling)
    end

    touchConnection = RunService.Heartbeat:Connect(touchBurst)
end

local function stopTargetFling()
    targetCancelled = true
    if targetCleanup then
        pcall(targetCleanup)
    end
end

local function predictiveTargetFling(target)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local root = rootOf(character)
    local targetCharacter = target and target.Character
    local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildWhichIsA("Humanoid")
    local targetRoot = target and rootOf(targetCharacter)

    if not character or not humanoid or not root or not targetHumanoid or not targetRoot then
        return false, "character or target is missing"
    end

    local oldLinear = root.AssemblyLinearVelocity
    local oldAngular = root.AssemblyAngularVelocity
    local collisionState = saveAndDisableCollision(character)
    local cleaned = false

    local function cleanup()
        if cleaned then
            return
        end
        cleaned = true

        if root and root.Parent then
            root.AssemblyLinearVelocity = oldLinear
            root.Velocity = oldLinear
            root.AssemblyAngularVelocity = oldAngular
        end

        restoreCollision(collisionState)
    end

    targetCleanup = cleanup
    targetCancelled = false

    local started = tick()
    while not targetCancelled and tick() - started < 1.25 do
        targetRoot = target and rootOf(target.Character)
        targetHumanoid = target and target.Character and target.Character:FindFirstChildWhichIsA("Humanoid")
        if not targetRoot or not targetRoot.Parent or not targetHumanoid or targetHumanoid.Health <= 0 then
            break
        end

        local leadTime = predictionSeconds()
        local predictedPosition, predictedVelocity = simulateTarget(target, leadTime)
        if not predictedPosition or not predictedVelocity then
            break
        end

        local offset = predictedPosition - root.Position
        local flatOffset = Vector3.new(offset.X, 0, offset.Z)
        local horizontalVelocity = Vector3.new(predictedVelocity.X, 0, predictedVelocity.Z)
        local lookHorizontal = Vector3.new(targetRoot.CFrame.LookVector.X, 0, targetRoot.CFrame.LookVector.Z)
        local targetForward = horizontalVelocity.Magnitude > 1
            and horizontalVelocity.Unit
            or (lookHorizontal.Magnitude > 0.05 and lookHorizontal.Unit or Vector3.new(0, 0, -1))

        if flatOffset.Magnitude > 0.05 then
            local flingDirection = flatOffset.Unit
            if horizontalVelocity.Magnitude <= 1 then
                flingDirection = targetForward
            end

            root.AssemblyLinearVelocity = flingDirection * targetStrength
            root.Velocity = flingDirection * targetStrength
        end

        RunService.RenderStepped:Wait()

        if root and root.Parent then
            root.AssemblyLinearVelocity = oldLinear
            root.Velocity = oldLinear
        end
    end

    cleanup()
    targetCleanup = nil
    return true
end

local function rogueTargetFling(target)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local root = rootOf(character)
    local targetCharacter = target and target.Character
    local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildWhichIsA("Humanoid")
    local targetRoot = rootOf(targetCharacter)

    if not character or not humanoid or not root or not targetHumanoid or not targetRoot then
        return false, "character or target is missing"
    end

    local oldPosition = character:GetPivot()
    targetCancelled = false

    if humanoid.Sit then
        humanoid.Sit = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        task.wait()
    end

    character:PivotTo(targetRoot.CFrame)

    local started = tick()
    while not targetCancelled and tick() - started < 2 do
        targetCharacter = target and target.Character
        targetHumanoid = targetCharacter and targetCharacter:FindFirstChildWhichIsA("Humanoid")
        targetRoot = rootOf(targetCharacter)

        if not targetCharacter or not targetCharacter:IsDescendantOf(workspace) or not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
            break
        end

        local victimSpeed = targetRoot.AssemblyLinearVelocity.Magnitude
        if victimSpeed <= standingStillThreshold then
            character:PivotTo(targetRoot.CFrame)
            RunService.Heartbeat:Wait()
            continue
        end

        if velocityLimitEnabled and victimSpeed > victimVelocityLimit then
            break
        end

        local predictionTime = math.clamp((pingMilliseconds() / 1000 + 0.08) * predictionMultiplier, 0.01, 1)
        local position = targetRoot.Position
        local velocity = targetRoot.AssemblyLinearVelocity
        local predictedPosition

        if targetHumanoid.FloorMaterial ~= Enum.Material.Air then
            predictedPosition = Vector3.new(
                position.X + velocity.X * predictionTime,
                position.Y,
                position.Z + velocity.Z * predictionTime
            )
        else
            predictedPosition = position
                + velocity * predictionTime
                + Vector3.new(0, -workspace.Gravity, 0) * 0.5 * predictionTime ^ 2
        end

        local destination = predictedPosition + targetRoot.CFrame:VectorToWorldSpace(Vector3.new(0, 0, targetOffset))
        local launchDirection = (predictedPosition - destination).Unit

        character:PivotTo(CFrame.lookAt(destination, predictedPosition))
        root.AssemblyLinearVelocity = launchDirection * targetStrength
        root.Velocity = launchDirection * targetStrength
        root.AssemblyAngularVelocity = Vector3.new(targetStrength, targetStrength, targetStrength)
        RunService.Heartbeat:Wait()
    end

    if root and root.Parent then
        root.AssemblyLinearVelocity = Vector3.zero
        root.Velocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    if character and oldPosition then
        character:PivotTo(oldPosition)
    end

    return true
end
local xGuiSource = game:HttpGet(
    "https://raw.githubusercontent.com/x8lua/scripts/main/imgui-roblox/ImGui.lua?nocache=" .. tostring(tick())
)
local xGui = loadstring(xGuiSource)()
Notify = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/x8lua/scripts/main/ImGUI/Notify.lua?nocache=" .. tostring(tick()),
    true
))()
local window = xGui.new("Gakuran Fling", Enum.KeyCode.RightShift)
getgenv().__gakuranFlingWindow = window
motionConnection = RunService.Heartbeat:Connect(recordMotionSamples)
teleportConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if not processed then
        if input.KeyCode == Enum.KeyCode.Q then
            teleportForward()
        elseif input.KeyCode == Enum.KeyCode.E then
            toggleRage()
        end
    end
end)

local touchTab = window:CreateTab("Touch Fling")
touchTab:CreateLabel("continuous one frame camera directed fling")
touchTab:CreateToggle("Enable Touch Fling", false, function(state)
    if state then
        startTouchFling()
        window:Notify({
            Title = "Touch Fling",
            Content = "enabled, collision off",
            Duration = 2,
        })
    else
        stopTouchFling()
        window:Notify({
            Title = "Touch Fling",
            Content = "disabled, collision restored",
            Duration = 2,
        })
    end
end)
touchStrengthSlider = touchTab:CreateSlider("Touch Strength", 100, 5000, touchStrength, function(value)
    touchStrength = value
end)
touchTab:CreateLabel("press E to toggle rage range")
touchTab:CreateKeybind("Play Animation", Enum.KeyCode.T, function(key, isPressedGlobally)
    if isPressedGlobally then
        playTouchAnimation()
    end
end)

local targetTab = window:CreateTab("Target Fling")
targetTab:CreateLabel("Target Username")
targetTab:CreateTextInput("Target Username", "", function(text)
    targetQuery = tostring(text or "")
    lockedTarget = findPlayer(targetQuery)
    if lockedTarget then
        window:Notify({Title = "Target Locked", Content = lockedTarget.Name, Duration = 2})
    end
end)

targetTab:CreateLabel("Offset and prediction controls")
local targetStrengthSlider = targetTab:CreateSlider("Fling Strength", 5000, 100000, targetStrength, function(value)
    targetStrength = value
end)

targetTab:CreateSlider("Offset Z", -10, 10, targetOffset, function(value)
    targetOffset = value
end)

targetTab:CreateSlider("Prediction Strength", 0.5, 3.2, predictionMultiplier, function(value)
    predictionMultiplier = value
end)

targetTab:CreateButton("Run Target Fling", function()
    if targetBusy then
        window:Notify({Title = "Target Fling", Content = "already running", Duration = 2})
        return
    end

    local target = currentTarget()
    if not target then
        window:Notify({Title = "Target Fling", Content = "enter a username", Duration = 3})
        return
    end

    stopTouchFling()
    targetBusy = true
    targetCancelled = false

    task.spawn(function()
        local ok, result, detail = pcall(function()
            return rogueTargetFling(target)
        end)

        targetBusy = false
        targetCleanup = nil
        if not ok or result == false then
            window:Notify({
                Title = "Target Fling Error",
                Content = not ok and tostring(result) or tostring(detail),
                Duration = 4,
            })
        end
    end)
end)

targetTab:CreateToggle("Velocity Limit Stop", velocityLimitEnabled, function(state)
    velocityLimitEnabled = state
end)

targetTab:CreateSlider("Velocity Limit", 50, 2000, victimVelocityLimit, function(value)
    victimVelocityLimit = value
end)
targetTab:CreateButton("Stop Target Fling", stopTargetFling)
local configTab = window:CreateTab("Config")
configTab:CreateButton("Set Target Strength Max 100000", function()
    targetStrengthSlider:SetMax(100000)
end)
configTab:CreateButton("Set Target Strength Min 0", function()
    targetStrengthSlider:SetMin(0)
end)
configTab:CreateSlider("Q Teleport Distance", 1, 100, teleportDistance, function(value)
    teleportDistance = value
end)
configTab:CreateButton("Clear Target", function()
    targetQuery = ""
    lockedTarget = nil
end)
configTab:CreateButton("Stop Everything", function()
    stopTouchFling()
    stopTargetFling()
    if motionConnection then
        motionConnection:Disconnect()
        motionConnection = nil
    end
    if teleportConnection then
        teleportConnection:Disconnect()
        teleportConnection = nil
    end
end)
configTab:CreateButton("Unload", function()
    if getgenv().__gakuranFlingCleanup then
        getgenv().__gakuranFlingCleanup()
    end
end)

getgenv().__gakuranFlingCleanup = function()
    stopTouchFling()
    stopTargetFling()
    if teleportConnection then
        teleportConnection:Disconnect()
        teleportConnection = nil
    end
    pcall(function()
        window:Destroy()
    end)
    getgenv().__gakuranFlingWindow = nil
    getgenv().__gakuranFlingCleanup = nil
end
