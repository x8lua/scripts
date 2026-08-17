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
local LocalPlayer = Players.LocalPlayer

local controller = {
    Enabled = true,
    Radius = 14,
    HoldTime = 0.24,
    TimingScale = 1,
    ParryLead = 0.15,
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
    TouchEnabled = false,
    TouchStrength = 5000,
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

local combatAnimations = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Combat")
for _, animation in ipairs(combatAnimations:GetDescendants()) do classifyAnimation(animation) end
table.insert(controller.Connections, combatAnimations.DescendantAdded:Connect(classifyAnimation))
for _, player in ipairs(Players:GetPlayers()) do watchPlayer(player) end
table.insert(controller.Connections, Players.PlayerAdded:Connect(watchPlayer))
table.insert(controller.Connections, RunService.Heartbeat:Connect(touchBurst))

function controller.Stop()
    controller.Enabled = false
    controller.TouchEnabled = false
    for _, connection in ipairs(controller.Connections) do pcall(function() connection:Disconnect() end) end
    table.clear(controller.Connections)
    local block = getCombatModule("Block")
    if block and typeof(block.Unblock) == "function" then pcall(block.Unblock) end
    log("STOP listeners disconnected")
end

_G.LarpkuranRere = controller

local enabled = Rere.State(true)
local radius = Rere.State(14)
local holdTime = Rere.State(0.24)
local timingScale = Rere.State(1)
local parryLead = Rere.State(0.15)
local touchEnabled = Rere.State(false)
local touchStrength = Rere.State(5000)
local filter = Rere.State("")

Rere:Connect(function()
    controller.Enabled = enabled:get()
    controller.Radius = radius:get()
    controller.HoldTime = holdTime:get()
    controller.TimingScale = timingScale:get()
    controller.ParryLead = parryLead:get()
    controller.TouchEnabled = touchEnabled:get()
    controller.TouchStrength = touchStrength:get()

    Rere.Window({"Larpkuran"})
        Rere.TabBar()
            Rere.Tab({"Parry"})
                Rere.Checkbox({"Enable auto parry"}, {isChecked = enabled})
                Rere.SliderNum({"Radius", 0.5, 2, 30, "%.1f studs"}, {number = radius})
                Rere.SliderNum({"Hold time", 0.01, 0.05, 0.6, "%.2f s"}, {number = holdTime})
                Rere.SliderNum({"Timing scale", 0.01, 0.5, 1.5, "%.2fx"}, {number = timingScale})
                Rere.SliderNum({"Parry lead", 0.01, 0, 0.25, "%.2f s"}, {number = parryLead})
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
