-- Larpkuran: Rere UI with auto-parry diagnostics.
-- This build contains no target-interaction workflow.
local compiler = loadstring or load
assert(type(compiler) == "function", "Rere requires loadstring or load")

if _G.LarpkuranRere and _G.LarpkuranRere.Stop then
    pcall(_G.LarpkuranRere.Stop)
end
if _G.LarpkuranRereUI and _G.LarpkuranRereUI.Shutdown then
    pcall(_G.LarpkuranRereUI.Shutdown)
end

local source = game:HttpGet("https://raw.githubusercontent.com/x8lua/Rere/v0.1.24/src/Rere.lua")
local Rere = assert(compiler(source))()
Rere.Init()
_G.LarpkuranRereUI = Rere

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DEFAULT_CONFIG = {
    AutoParry = true,
    Radius = 14,
    HoldTime = 0.24,
    TimingScale = 1,
    ParryLead = 0.15,
    ParryChance = 100,
    TouchEnabled = false,
    TouchStrength = 5000,
    TouchAnimationKey = "F",
    AutoPerfectNote = false,
}
local CONFIG_FILE = "larpkuran-rere-config.json"
local config = _G.LarpkuranRereConfig or {}
for key, value in pairs(DEFAULT_CONFIG) do
    if config[key] == nil then config[key] = value end
end
_G.LarpkuranRereConfig = config

local controller = {
    Enabled = config.AutoParry,
    Radius = config.Radius,
    HoldTime = config.HoldTime,
    TimingScale = config.TimingScale,
    ParryLead = config.ParryLead,
    ParryChance = config.ParryChance,
    BlockingUntil = 0,
    PulseActive = false,
    KnownAnimations = 0,
    TriggerCount = 0,
    AcceptedBlocks = 0,
    RejectedBlocks = 0,
    LastTarget = "",
    LastAnimation = "",
    LastState = "Idle",
    LastError = "",
    Events = {},
    Connections = {},
    TouchEnabled = config.TouchEnabled,
    TouchStrength = config.TouchStrength,
    TouchAnimationKey = config.TouchAnimationKey,
    AutoPerfectNote = config.AutoPerfectNote,
    RhythmHits = 0,
    RhythmHeld = {},
}

local function log(message)
    table.insert(controller.Events, 1, os.date("%H:%M:%S") .. "  " .. message)
    while #controller.Events > 40 do
        table.remove(controller.Events)
    end
end

local function rootOf(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
end

local function getCombatModule(name)
    local character = LocalPlayer.Character
    local data = character and character:FindFirstChild("PlayerData")
    local combatType = data and data:GetAttribute("CombatType") or "Base"
    local root = ReplicatedStorage:FindFirstChild("CombatSystemClient")
    local combat = root and root:FindFirstChild("Combat")
    local folder = combat and (combat:FindFirstChild(combatType) or combat:FindFirstChild("Base"))
    local moduleScript = folder and folder:FindFirstChild(name)
    if not moduleScript then
        return nil, name .. " module not found"
    end
    local ok, module = pcall(require, moduleScript)
    return ok and module or nil, ok and nil or tostring(module)
end

local function releaseM1Hold()
    local m1 = getCombatModule("M1")
    if m1 and typeof(m1.Hold) == "function" then
        pcall(m1.Hold, "Stop")
    end
end

local function canParry(enemyCharacter)
    if not controller.Enabled then return false end
    local character = LocalPlayer.Character
    local localRoot, enemyRoot = rootOf(character), rootOf(enemyCharacter)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local enemyHumanoid = enemyCharacter and enemyCharacter:FindFirstChildOfClass("Humanoid")
    if not localRoot or not enemyRoot or not humanoid or humanoid.Health <= 0 then return false end
    if not enemyHumanoid or enemyHumanoid.Health <= 0 then return false end
    if (localRoot.Position - enemyRoot.Position).Magnitude > controller.Radius then return false end
    for _, attribute in ipairs({"Ragdoll", "Downed", "GrappleWinnerStun", "CantAnything"}) do
        if character:GetAttribute(attribute) == true then return false end
    end
    return true
end

local windups = {
    Ali = {M1 = {0.292, 0.382, 0.432, 0.232}, M2 = 0.542},
    Basic = {M1 = {0.352, 0.352, 0.352, 0.352}, M2 = 0.537},
    Boxing = {M1 = {0.352, 0.352, 0.352, 0.392}, M2 = 0.442},
    Capoeira = {M1 = {0.362, 0.442, 0.362, 0.292}, M2 = 0.462},
    Hakari = {M1 = {0.362, 0.382, 0.292, 0.392}, M2 = 0.362},
    Karate = {M1 = {0.2895, 0.327, 0.402, 0.477}, M2 = 0.4995},
    Kure = {M1 = {0.332, 0.332, 0.332, 0.332}, M2 = 0.312},
    MuayThai = {M1 = {0.312, 0.312, 0.312, 0.312}, M2 = 0.612},
    Slugger = {M1 = {0.512, 0.462, 0.462, 0.382}, M2 = 0.832},
    Striker = {M1 = {0.362, 0.362, 0.242, 0.132}, M2 = 0.462},
    WingChun = {M1 = {0.312, 0.312, 0.312, 0.712}, M2 = 0.537},
    Wrestling = {M1 = {0.372, 0.382, 0.372, 0.362}, M2 = 0.537},
}
local attacks = {}

local function classifyAnimation(animation)
    if not animation:IsA("Animation") then return end
    local combo = tonumber(string.match(animation.Name, "^(%d+)"))
    local heavy = animation.Name == "M2"
    if not heavy and not combo then return end
    local id = string.match(animation.AnimationId, "%d+")
    if not id then return end
    local class = string.gsub(animation.Parent.Name, "Anims$", "")
    local timing = windups[class]
    local windup = timing and (heavy and timing.M2 or timing.M1[combo]) or (heavy and 0.537 or 0.352)
    if not attacks[id] then controller.KnownAnimations += 1 end
    attacks[id] = {Name = class .. "." .. (heavy and "M2" or "M1"), Windup = windup}
end

local function pulseBlock()
    controller.BlockingUntil = math.max(controller.BlockingUntil, os.clock() + controller.HoldTime)
    if controller.PulseActive then return end
    controller.PulseActive = true
    task.spawn(function()
        local block, errorMessage = getCombatModule("Block")
        if not block or typeof(block.Block) ~= "function" then
            controller.LastError = errorMessage or "Block function missing"
            controller.LastState = "Module error"
            controller.PulseActive = false
            return
        end
        local accepted = false
        while controller.Enabled and os.clock() < controller.BlockingUntil do
            local ok, callError = pcall(block.Block)
            if not ok then
                controller.LastError = tostring(callError)
                break
            end
            accepted = accepted or (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Blocking") == true)
            task.wait()
        end
        if typeof(block.Unblock) == "function" then pcall(block.Unblock) end
        controller.PulseActive = false
        if accepted then
            controller.AcceptedBlocks += 1
            controller.LastState = "Accepted"
            log("BLOCK accepted and released")
        else
            controller.RejectedBlocks += 1
            controller.LastState = "Rejected"
            log("BLOCK rejected")
        end
    end)
end

local function parry(enemyCharacter, attack, speed)
    if not canParry(enemyCharacter) then return end
    if math.random(1, 100) > controller.ParryChance then
        controller.LastState = "Skipped by chance"
        log("PARRY skipped by chance")
        return
    end
    speed = math.max(math.abs(speed or 1), 0.05)
    local delay = math.max(0, attack.Windup / speed * controller.TimingScale - controller.ParryLead)
    controller.TriggerCount += 1
    controller.LastTarget = enemyCharacter.Name
    controller.LastAnimation = attack.Name
    controller.LastState = "Scheduled"
    releaseM1Hold()
    log(string.format("PARRY #%d %s target=%s delay=%.3f", controller.TriggerCount, attack.Name, enemyCharacter.Name, delay))
    task.spawn(function()
        if delay > 0 then task.wait(delay) end
        if canParry(enemyCharacter) then pulseBlock() end
    end)
end

local function watchCharacter(character)
    if not character or character == LocalPlayer.Character then return end
    task.spawn(function()
        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 8)
        local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 8))
        if not animator then return end
        table.insert(controller.Connections, animator.AnimationPlayed:Connect(function(track)
            local animation = track.Animation
            local id = animation and string.match(animation.AnimationId, "%d+")
            local attack = id and attacks[id]
            if attack then parry(character, attack, track.Speed) end
        end))
    end)
end

local function watchPlayer(player)
    if player == LocalPlayer then return end
    if player.Character then watchCharacter(player.Character) end
    table.insert(controller.Connections, player.CharacterAdded:Connect(watchCharacter))
end

local function touchBurst()
    if not controller.TouchEnabled then return end
    local root = rootOf(LocalPlayer.Character)
    if not root then return end
    local camera = workspace.CurrentCamera
    local look = camera and camera.CFrame.LookVector or root.CFrame.LookVector
    local direction = Vector3.new(look.X, 0, look.Z)
    if direction.Magnitude < 0.05 then return end
    local original = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = direction.Unit * controller.TouchStrength
    RunService.RenderStepped:Wait()
    if root.Parent then root.AssemblyLinearVelocity = original end
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
        local waited = 0
        while track.Length <= 0 and waited < 1 do
            waited += task.wait()
        end
        task.wait(0.5)
        if track.IsPlaying and humanoid.Parent then
            humanoid.WalkSpeed = originalWalkSpeed * 1.4
            boosted = true
        end
    end)

    track.Stopped:Once(function()
        if boosted and humanoid.Parent then humanoid.WalkSpeed = originalWalkSpeed end
        animation:Destroy()
    end)
    log("TOUCH animation played")
end

local function touchAnimationKeyCode()
    local keyName = string.upper(tostring(controller.TouchAnimationKey or "F"))
    return Enum.KeyCode[keyName]
end

local oldRhythmControl = PlayerGui:FindFirstChild("_LarpkuranAutoRhythm")
if oldRhythmControl then oldRhythmControl:Destroy() end
local rhythmControl = Instance.new("Folder")
rhythmControl.Name = "_LarpkuranAutoRhythm"
rhythmControl.Parent = PlayerGui
controller.RhythmControl = rhythmControl

local function sendRhythmKey(key, down)
    VirtualInputManager:SendKeyEvent(down, key, false, game)
end

local function releaseRhythmLane(lane)
    local hold = controller.RhythmHeld[lane]
    if hold then
        controller.RhythmHeld[lane] = nil
        sendRhythmKey(hold.Key, false)
    end
end

local function releaseAllRhythmKeys()
    for lane in pairs(controller.RhythmHeld) do releaseRhythmLane(lane) end
end

local rhythmFired = setmetatable({}, {__mode = "k"})
local function autoPerfectNote()
    if not controller.AutoPerfectNote or not rhythmControl.Parent then
        releaseAllRhythmKeys()
        return
    end

    local service = PlayerGui:FindFirstChild("RhythmServiceUI")
    local root = service and service:FindFirstChild("RhythmRoot")
    local receptors = root and root:FindFirstChild("Receptors")
    if not (root and root.Visible and receptors) then
        releaseAllRhythmKeys()
        return
    end

    local lanes = {}
    for _, receptor in ipairs(receptors:GetChildren()) do
        local lane = tonumber(receptor.Name:match("^Receptor(%d+)$"))
        local hint = lane and receptor:FindFirstChild("KeyHint")
        local key = hint and Enum.KeyCode[hint.Text:upper()]
        if lane and key then
            lanes[lane] = {
                Key = key,
                X = receptor.AbsolutePosition.X + receptor.AbsoluteSize.X / 2,
                Y = receptor.AbsolutePosition.Y,
            }
        end
    end

    for lane, hold in pairs(controller.RhythmHeld) do
        if not hold.Note.Parent or not hold.Note.Visible or not hold.Head.Parent
            or hold.Head.AbsolutePosition.Y >= hold.ReleaseY then
            releaseRhythmLane(lane)
        end
    end

    local notes = root:GetDescendants()
    for lane, info in pairs(lanes) do
        if not controller.RhythmHeld[lane] then
            for _, note in ipairs(notes) do
                if note:IsA("Frame") and note.Name == "NoteTemplate" and note.Visible then
                    local head = note:FindFirstChild("Head")
                    if head and head.Visible then
                        local x = head.AbsolutePosition.X + head.AbsoluteSize.X / 2
                        local y = head.AbsolutePosition.Y
                        if y < 100 then rhythmFired[note] = nil end
                        if not rhythmFired[note] and math.abs(x - info.X) < 90 and math.abs(y - info.Y) <= 10 then
                            rhythmFired[note] = true
                            local tail = note:FindFirstChild("Tail")
                            local length = tail and tail.AbsoluteSize.Y or 0
                            sendRhythmKey(info.Key, true)
                            controller.RhythmHits += 1
                            if length <= 2 then
                                task.delay(0.025, function()
                                    if not controller.RhythmHeld[lane] then sendRhythmKey(info.Key, false) end
                                end)
                            else
                                controller.RhythmHeld[lane] = {
                                    Note = note,
                                    Head = head,
                                    Key = info.Key,
                                    ReleaseY = info.Y + length,
                                }
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end

local combatAnimations = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Combat")
for _, animation in ipairs(combatAnimations:GetDescendants()) do classifyAnimation(animation) end
table.insert(controller.Connections, combatAnimations.DescendantAdded:Connect(classifyAnimation))
for _, player in ipairs(Players:GetPlayers()) do watchPlayer(player) end
table.insert(controller.Connections, Players.PlayerAdded:Connect(watchPlayer))
table.insert(controller.Connections, RunService.Heartbeat:Connect(touchBurst))
table.insert(controller.Connections, RunService.RenderStepped:Connect(autoPerfectNote))
table.insert(controller.Connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local animationKey = touchAnimationKeyCode()
    if animationKey and input.KeyCode == animationKey then playTouchAnimation() end
end))

function controller.Stop()
    controller.Enabled = false
    controller.TouchEnabled = false
    controller.AutoPerfectNote = false
    releaseAllRhythmKeys()
    if controller.RhythmControl then controller.RhythmControl:Destroy() end
    for _, connection in ipairs(controller.Connections) do pcall(function() connection:Disconnect() end) end
    table.clear(controller.Connections)
    local block = getCombatModule("Block")
    if block and typeof(block.Unblock) == "function" then pcall(block.Unblock) end
    log("STOP listeners disconnected")
end

_G.LarpkuranRere = controller

local enabled = Rere.State(config.AutoParry)
local radius = Rere.State(config.Radius)
local holdTime = Rere.State(config.HoldTime)
local timingScale = Rere.State(config.TimingScale)
local parryLead = Rere.State(config.ParryLead)
local parryChance = Rere.State(config.ParryChance)
local touchEnabled = Rere.State(config.TouchEnabled)
local touchStrength = Rere.State(config.TouchStrength)
local touchAnimationKey = Rere.State(config.TouchAnimationKey)
local autoPerfectNoteEnabled = Rere.State(config.AutoPerfectNote)
local filter = Rere.State("")

local function saveConfig()
    config.AutoParry = enabled:get()
    config.Radius = radius:get()
    config.HoldTime = holdTime:get()
    config.TimingScale = timingScale:get()
    config.ParryLead = parryLead:get()
    config.ParryChance = parryChance:get()
    config.TouchEnabled = touchEnabled:get()
    config.TouchStrength = touchStrength:get()
    config.TouchAnimationKey = string.upper(tostring(touchAnimationKey:get()))
    config.AutoPerfectNote = autoPerfectNoteEnabled:get()
    _G.LarpkuranRereConfig = config
    if type(writefile) == "function" then
        local ok, errorMessage = pcall(writefile, CONFIG_FILE, HttpService:JSONEncode(config))
        log(ok and "CONFIG saved to file" or "CONFIG file save failed: " .. tostring(errorMessage))
    else
        log("CONFIG saved for this executor session")
    end
end

local function applyConfig()
    enabled:set(config.AutoParry)
    radius:set(config.Radius)
    holdTime:set(config.HoldTime)
    timingScale:set(config.TimingScale)
    parryLead:set(config.ParryLead)
    parryChance:set(config.ParryChance)
    touchEnabled:set(config.TouchEnabled)
    touchStrength:set(config.TouchStrength)
    touchAnimationKey:set(config.TouchAnimationKey)
    autoPerfectNoteEnabled:set(config.AutoPerfectNote)
end

local function loadConfig()
    if type(readfile) == "function" and type(isfile) == "function" and isfile(CONFIG_FILE) then
        local ok, saved = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and type(saved) == "table" then
            for key, value in pairs(DEFAULT_CONFIG) do config[key] = saved[key] == nil and value or saved[key] end
        else
            log("CONFIG file load failed")
        end
    end
    applyConfig()
    log("CONFIG loaded")
end

local function resetConfig()
    for key, value in pairs(DEFAULT_CONFIG) do config[key] = value end
    applyConfig()
    log("CONFIG reset to defaults")
end

Rere:Connect(function()
    controller.Enabled = enabled:get()
    controller.Radius = radius:get()
    controller.HoldTime = holdTime:get()
    controller.TimingScale = timingScale:get()
    controller.ParryLead = parryLead:get()
    controller.ParryChance = parryChance:get()
    controller.TouchEnabled = touchEnabled:get()
    controller.TouchStrength = touchStrength:get()
    controller.TouchAnimationKey = string.upper(tostring(touchAnimationKey:get()))
    controller.AutoPerfectNote = autoPerfectNoteEnabled:get()

    Rere.Window({"Larpkuran"})
        Rere.TabBar()
            Rere.Tab({"Parry"})
                Rere.Checkbox({"Enable auto parry"}, {isChecked = enabled})
                Rere.SliderNum({"Radius", 0.5, 2, 30, "%.1f studs"}, {number = radius})
                Rere.SliderNum({"Hold time", 0.01, 0.05, 0.6, "%.2f s"}, {number = holdTime})
                Rere.SliderNum({"Timing scale", 0.01, 0.5, 1.5, "%.2fx"}, {number = timingScale})
                Rere.SliderNum({"Parry lead", 0.01, 0, 0.25, "%.2f s"}, {number = parryLead})
                Rere.SliderNum({"Parry chance", 1, 0, 100, "%.0f%%"}, {number = parryChance})
                Rere.Text({"Detected attacks: " .. controller.KnownAnimations})
                Rere.Text({"Triggers: " .. controller.TriggerCount})
                Rere.Text({"Accepted / rejected: " .. controller.AcceptedBlocks .. " / " .. controller.RejectedBlocks})
                Rere.Text({"Last state: " .. controller.LastState})
                Rere.Text({"Last target: " .. (controller.LastTarget ~= "" and controller.LastTarget or "None")})
                Rere.Text({"Last attack: " .. (controller.LastAnimation ~= "" and controller.LastAnimation or "None")})
            Rere.End()
            Rere.Tab({"Touch"})
                Rere.Checkbox({"Enable touch impulse"}, {isChecked = touchEnabled})
                Rere.SliderNum({"Touch strength", 100, 100, 5000, "%.0f"}, {number = touchStrength})
                Rere.InputText({"Animation key", "F"}, {text = touchAnimationKey})
                if Rere.Button({"Play animation"}).clicked() then playTouchAnimation() end
                Rere.Text({"Press " .. controller.TouchAnimationKey .. " to play the touch animation."})
            Rere.End()
            Rere.Tab({"Fun"})
                Rere.Checkbox({"Auto perfect note"}, {isChecked = autoPerfectNoteEnabled})
                Rere.Text({"Rhythm notes hit: " .. controller.RhythmHits})
            Rere.End()
            Rere.Tab({"Config"})
                if Rere.Button({"Save config"}).clicked() then saveConfig() end
                if Rere.Button({"Load config"}).clicked() then loadConfig() end
                if Rere.Button({"Reset config"}).clicked() then resetConfig() end
                Rere.Text({"Persistent file: " .. CONFIG_FILE})
            Rere.End()
            Rere.Tab({"Diagnostics"})
                Rere.InputText({"Filter", "event text..."}, {text = filter})
                Rere.Separator()
                local query, shown = string.lower(filter:get()), 0
                for _, event in ipairs(controller.Events) do
                    if query == "" or string.find(string.lower(event), query, 1, true) then
                        Rere.Text({event})
                        shown += 1
                    end
                    if shown >= 25 then break end
                end
                if shown == 0 then Rere.Text({"No matching events."}) end
                Rere.Text({"Last error: " .. (controller.LastError ~= "" and controller.LastError or "None")})
                if Rere.Button({"Stop and disconnect"}).clicked() then controller.Stop() end
            Rere.End()
        Rere.End()
    Rere.End()
end)
