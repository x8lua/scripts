local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local SoundService = game:GetService("SoundService")

local STACY_GREEN = Color3.fromRGB(80, 255, 125)
local GAME_COMMAND_GREEN = Color3.fromRGB(0, 255, 0)
local DEFAULT_SOURCE_URL = "https://raw.githubusercontent.com/x8lua/scripts/main/stacycmd/StacyUI.lua"
local GAKURAN_PLACE_ID = 128736949265057
local KEY_FILE = "StacyCMD.key"
local REQUIRED_KEY = "x8xxy"

local StacyUI = {}
StacyUI.__index = StacyUI
StacyUI.Version = "2.3.1"

local UPDATE_LOG = {
    { Version = "v2.3.1", Text = "Made the local StacyCMD key gate required" },
    { Version = "v2.3.0", Text = "Added the optional in-console keysystem page" },
    { Version = "v2.2.9", Text = "Made semicolon command mode close after 2.5 seconds of inactivity" },
    { Version = "v2.2.8", Text = "Removed the startup built-in command list" },
    { Version = "v2.2.7", Text = "Changed lag detection to sample player positions" },
    { Version = "v2.2.6", Text = "Added reverse intro animation during self-updates" },
    { Version = "v2.2.5", Text = "Changed lag detection to monitor local network ping" },
    { Version = "v2.2.4", Text = "Added a configurable lag detection percentage" },
    { Version = "v2.2.3", Text = "Raised the lag detection threshold to 90 percent" },
    { Version = "v2.2.2", Text = "Changed lag detection to trigger when half the server is still" },
    { Version = "v2.2.1", Text = "Fixed semicolon input and added reset and lag detection" },
    { Version = "v2.2.0", Text = "Added command focus, settings, error feedback, random view, and restored suggestions" },
    { Version = "v2.1.6", Text = "Fixed the intro title endpoint and added a position offset" },
    { Version = "v2.1.5", Text = "Matched the intro endpoint to a smaller header title and removed the doubled overlay" },
    { Version = "v2.1.4", Text = "Added manual intro size and tween settings and restored suggestion visibility" },
    { Version = "v2.1.3", Text = "Made view without a player restore the local camera" },
    { Version = "v2.1.2", Text = "Added Gakuran-name view support and reduced the intro title size" },
    { Version = "v2.1.1", Text = "Moved view to the regular command category" },
    { Version = "v2.1.0", Text = "Added view, jpower, and rejoin; fixed fly recovery; and added the intro UI fade" },
    { Version = "v2.0.2", Text = "Aligned the startup intro and header branding" },
    { Version = "v2.0.1", Text = "Removed the startup intro background" },
    { Version = "v2.0.0", Text = "Added the full-screen StacyCMD startup intro" },
    { Version = "v1.9.0", Text = "Added random teleporting, command focus cleanup, and the prediction toggle" },
    { Version = "v1.8.1", Text = "Changed gamecmds to use the searchable command browser" },
    { Version = "v1.8.0", Text = "Added gamecmds and Gakuran name teleportation with legacyto rollback" },
    { Version = "v1.7.0", Text = "Added the built in fly toggle command" },
    { Version = "v1.6.0", Text = "Added sudoaptupdate self updates and made the console visible by default" },
    { Version = "v1.5.2", Text = "Added command usage text to autocomplete suggestions" },
    { Version = "v1.5.1", Text = "Fixed arrow-key selection while the command prompt has focus" },
    { Version = "v1.5.0", Text = "Restyled command suggestions and added reliable keyboard navigation" },
    { Version = "v1.4.9", Text = "Added the built in maxzoom command for camera distance control" },
    { Version = "v1.4.8", Text = "Matched the command console header to the Bodoni StacyCMD brand" },
    { Version = "v1.4.7", Text = "Added modal focus grace against stray F1 toggle events" },
    { Version = "v1.4.6", Text = "Blocked F1 toggles while StacyUI search or prompt owns focus" },
    { Version = "v1.4.5", Text = "Kept StacyUI open when command search receives focus" },
    { Version = "v1.4.4", Text = "Improved description typography and fixed browser search focus" },
    { Version = "v1.4.3", Text = "Locked browser search editing until the field is clicked" },
    { Version = "v1.4.2", Text = "Made browser search click activated during gameplay" },
    { Version = "v1.4.1", Text = "Stopped browser search from capturing gameplay input" },
    { Version = "v1.4.0", Text = "Fixed cmds results and added the searchable update log" },
    { Version = "v1.3.0", Text = "Added searchable cmds command browser" },
    { Version = "v1.2.1", Text = "Polished command suggestions to match StacyCMD styling" },
    { Version = "v1.2.0", Text = "Added the version header and built in console state" },
    { Version = "v1.1.1", Text = "Changed the default toggle key to F1" },
    { Version = "v1.1.0", Text = "Added protected ctrlc teardown command" },
}

local DEFAULT_STYLE = {
    fontMono = Enum.Font.Code,
    fontSans = Enum.Font.SourceSans,
    text = Color3.fromRGB(220, 220, 220),
    muted = Color3.fromRGB(150, 150, 150),
    error = Color3.fromRGB(255, 120, 120),
    warn = Color3.fromRGB(255, 220, 120),
    info = Color3.fromRGB(160, 200, 255),
    accent = Color3.fromRGB(255, 224, 102),
    background = Color3.fromRGB(20, 20, 20),
    suggestionBackground = Color3.fromRGB(30, 30, 30),
    suggestionHighlight = Color3.fromRGB(55, 55, 55),
    divider = Color3.fromRGB(60, 60, 60),
    headerBackground = Color3.fromRGB(26, 26, 26),
    transparency = 0.4,
    width = 1000,
    height = 320,
}

local function mergeStyle(overrides)
    local style = {}
    for key, value in pairs(DEFAULT_STYLE) do
        style[key] = value
    end
    for key, value in pairs(overrides or {}) do
        style[key] = value
    end
    return style
end

local function trim(value)
    return value:match("^%s*(.-)%s*$") or ""
end

local function splitWords(value)
    local words = {}
    for word in value:gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

local function findPlayerByGameName(input)
    input = input:lower()
    for _, player in Players:GetPlayers() do
        local billboard = player.Character and player.Character:FindFirstChild("PlayerInfoBillboard")
        local info = billboard and billboard:FindFirstChild("Info")
        if info and info.Text:lower():find(input, 1, true) then
            return player
        end
    end
end

local function findPlayerByUsername(input)
    input = input:lower()
    local partialMatch
    for _, player in Players:GetPlayers() do
        local username = player.Name:lower()
        local displayName = player.DisplayName:lower()
        if username == input or displayName == input then
            return player
        end
        if not partialMatch and (username:find(input, 1, true) or displayName:find(input, 1, true)) then
            partialMatch = player
        end
    end
    return partialMatch
end

local function isNewerVersion(candidate, current)
    local candidateParts = {}
    local currentParts = {}
    for part in candidate:gmatch("%d+") do
        table.insert(candidateParts, tonumber(part))
    end
    for part in current:gmatch("%d+") do
        table.insert(currentParts, tonumber(part))
    end

    local count = math.max(#candidateParts, #currentParts)
    for index = 1, count do
        local candidatePart = candidateParts[index] or 0
        local currentPart = currentParts[index] or 0
        if candidatePart ~= currentPart then
            return candidatePart > currentPart
        end
    end
    return false
end

local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

-- why dont you join my discord and grabbing a key in the source instead >:(
local function readSavedKey()
    if type(readfile) ~= "function" then
        return nil
    end
    local read, key = pcall(readfile, KEY_FILE)
    return read and trim(tostring(key)) or nil
end

function StacyUI.new(options)
    options = options or {}

    local self = setmetatable({}, StacyUI)
    self.ReloadOptions = {}
    for key, value in pairs(options) do
        self.ReloadOptions[key] = value
    end
    self.Player = options.Player or Players.LocalPlayer
    assert(self.Player, "StacyUI requires a LocalPlayer or options Player")

    self.Style = mergeStyle(options.Style)
    self.KeyVerified = readSavedKey() == REQUIRED_KEY
    self.WelcomeEnabled = options.Welcome ~= false
    self.StartVisible = options.Visible ~= false
    self.Commands = {}
    self.History = {}
    self.HistoryIndex = 0
    self.SelectedSuggestionIndex = 0
    self.SuggestionButtons = {}
    self.CommandBrowserGameOnly = false
    self.PredictionConnections = {}
    self.PredictionMarkers = {}
    self.PredictionEnabled = false
    self.LagConnections = {}
    self.LagDetectionEnabled = false
    self.LagDetected = false
    self.LagDetectionThreshold = 0.9
    self.LagPositionSamples = {}
    self.IntroEnabled = options.Intro ~= false
    self.IntroSize = typeof(options.IntroSize) == "Vector2" and options.IntroSize or Vector2.new(600, 150)
    self.IntroTargetSize = typeof(options.IntroTargetSize) == "Vector2" and options.IntroTargetSize or Vector2.new(92, 26)
    self.IntroTargetOffset = typeof(options.IntroTargetOffset) == "Vector2" and options.IntroTargetOffset or Vector2.new(0, 0)
    self.IntroTweenDuration = math.max(0.05, tonumber(options.IntroTweenDuration) or 0.7)
    self.IntroPlaying = false
    self.OutroPlaying = false
    self.IntroSession = 0
    self.Connections = {}
    self.FlyConnections = {}
    self.FlySpeed = 1
    self.Flying = false
    self.FlySession = 0
    self.Open = false
    self.Destroyed = false
    self.IgnoreToggleUntil = 0
    self.OnDestroy = options.OnDestroy
    self.Speaker = options.Speaker or self.Player
    self.SourceUrl = options.SourceUrl or DEFAULT_SOURCE_URL
    self.IsGakuranGame = game.PlaceId == GAKURAN_PLACE_ID
    self.UseLegacyTo = options.LegacyTo == true
    self.ToggleKey = options.ToggleKey or Enum.KeyCode.F1
    self.CommandKey = options.CommandKey or Enum.KeyCode.Semicolon
    self.ActionName = "StacyUIToggle_" .. tostring(self):gsub("[^%w]", "")
    self.CommandActionName = "StacyUICommandFocus_" .. tostring(self):gsub("[^%w]", "")
    self.CommandFocusSession = 0
    self.CommandFocusActive = false
    self.SettingsCapturingKey = false
    self.Prefix = options.Prefix or (self.Player.Name .. "@StacyUI$ ")

    self:_build(options)
    self:SetToggleKey(self.ToggleKey)
    self:SetCommandKey(self.CommandKey)
    self:_registerBuiltIns()

    if self.KeyVerified and self.IsGakuranGame and not self.UseLegacyTo then
        self:_notifyGakuranToOverride()
    end

    if self.KeyVerified then
        self:_startVerifiedConsole()
    else
        self:ShowKeySystem()
    end

    return self
end

function StacyUI:_startVerifiedConsole()
    if self.WelcomeEnabled then
        self:Log("StacyCMD v" .. StacyUI.Version .. "  READY", self.Style.info)
    end
    if self.StartVisible then
        if self.IntroEnabled then
            self:PlayIntro()
        else
            self:Toggle(true)
        end
    end
end

function StacyUI:_registerBuiltIns()
    self.Commands.help = {
        Description = "List every available command",
        Usage = "help",
        Protected = true,
        Callback = function(_, _, ui)
            local names = {}
            for name in pairs(ui.Commands) do
                table.insert(names, name)
            end
            table.sort(names)
            ui:Log("COMMANDS  " .. table.concat(names, "  "), ui.Style.info)
        end,
    }
    self.Commands.clear = {
        Description = "Clear all console output",
        Usage = "clear",
        Protected = true,
        Callback = function(_, _, ui)
            ui:Clear()
        end,
    }
    self.Commands.version = {
        Description = "Show the StacyCMD version",
        Usage = "version",
        Protected = true,
        Callback = function(_, _, ui)
            ui:Log("StacyCMD v" .. StacyUI.Version, ui.Style.accent)
        end,
    }
    self.Commands.cmds = {
        Description = "Open the searchable command browser",
        Usage = "cmds",
        Protected = true,
        Callback = function(_, _, ui)
            ui:ShowCommands()
        end,
    }
    self.Commands.updatelog = {
        Description = "Open the StacyCMD update log",
        Usage = "updatelog",
        Protected = true,
        Callback = function(_, _, ui)
            ui:ShowUpdateLog()
        end,
    }
    self.Commands.gamecmds = {
        Description = "List commands provided for the current game",
        Usage = "gamecmds",
        HighlightLime = true,
        Protected = true,
        Callback = function(_, _, ui)
            ui:ShowGameCommands()
        end,
    }
    self.Commands.settings = {
        Description = "Open StacyCMD settings",
        Usage = "settings",
        Protected = true,
        Callback = function(_, _, ui)
            ui:ShowSettings()
        end,
    }
    self.Commands.keysystem = {
        Description = "Open the optional StacyCMD key page",
        Usage = "keysystem",
        Protected = true,
        Callback = function(_, _, ui)
            ui:ShowKeySystem()
        end,
    }
    local gakuranToActive = self.IsGakuranGame and not self.UseLegacyTo
    self.Commands.to = {
        Description = gakuranToActive and "Teleport to a player by Gakuran name" or "Teleport to a player by username or display name",
        Usage = "to [player|random]",
        GameSpecific = gakuranToActive,
        HighlightLime = gakuranToActive,
        Protected = true,
        Callback = function(args, _, ui)
            local teleported, reason = ui:TeleportTo(args[1])
            if not teleported then
                ui:Log("Teleport error  " .. tostring(reason), ui.Style.error)
                return false, reason
            end
            return true
        end,
    }
    if self.IsGakuranGame then
        self.Commands.legacyto = {
            Description = "Restore username and display-name teleporting for this session",
            Usage = "legacyto",
            GameSpecific = true,
            HighlightLime = true,
            Protected = true,
            Callback = function(_, _, ui)
                ui.UseLegacyTo = true
                ui.ReloadOptions.LegacyTo = true
                ui.Commands.to.Description = "Teleport to a player by username or display name"
                ui.Commands.to.GameSpecific = false
                ui.Commands.to.HighlightLime = false
                ui:Log("to now uses username and display-name matching for this session", ui.Style.info)
                return true
            end,
        }
    end
    self.Commands.maxzoom = {
        Description = "Set the maximum camera zoom distance",
        Usage = "maxzoom [num]",
        Protected = true,
        Callback = function(args, _, ui)
            args[1] = tonumber(args[1])
            if not args[1] or args[1] <= 0 then
                ui:Log("Usage  maxzoom [num]", ui.Style.warn)
                return false, "maxzoom requires a positive number"
            end
            local speaker = ui.Speaker
            speaker.CameraMaxZoomDistance = args[1]
            ui:Log("Camera max zoom  " .. tostring(args[1]), ui.Style.info)
        end,
    }
    local gakuranViewActive = self.IsGakuranGame
    self.Commands.view = {
        Description = gakuranViewActive and "View by Gakuran name; omit the name to view yourself" or "View another player; omit the name to view yourself",
        Usage = "view [player|self|random]",
        GameSpecific = gakuranViewActive,
        HighlightLime = gakuranViewActive,
        Protected = true,
        Callback = function(args, _, ui)
            local viewed, reason = ui:ViewPlayer(args[1] or "self")
            if not viewed then
                ui:Log("View error  " .. tostring(reason), ui.Style.error)
                return false, reason
            end
            return true
        end,
    }
    self.Commands.jpower = {
        Description = "Set the character jump power",
        Usage = "jpower [num]",
        Protected = true,
        Callback = function(args, _, ui)
            local jumpPower = tonumber(args[1])
            local character = ui.Speaker.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not jumpPower or jumpPower < 0 then
                ui:Log("Usage  jpower [num]", ui.Style.warn)
                return false, "jpower requires a non-negative number"
            end
            if not humanoid then
                ui:Log("Jump power error  character humanoid not found", ui.Style.error)
                return false, "character humanoid not found"
            end
            humanoid.UseJumpPower = true
            humanoid.JumpPower = jumpPower
            ui:Log("Jump power  " .. tostring(jumpPower), ui.Style.info)
            return true
        end,
    }
    self.Commands.reset = {
        Description = "Reset your character",
        Usage = "reset",
        Protected = true,
        Callback = function(_, _, ui)
            local humanoid = ui.Speaker.Character and ui.Speaker.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid then
                return false, "character humanoid not found"
            end
            humanoid.Health = 0
            return true
        end,
    }
    self.Commands.fly = {
        Description = "Toggle camera-relative character flight",
        Usage = "fly [speed]",
        Protected = true,
        Callback = function(args, _, ui)
            local speed = args[1] and tonumber(args[1]) or ui.FlySpeed
            if not speed or speed <= 0 then
                ui:Log("Usage  fly [speed]", ui.Style.warn)
                return false, "fly speed must be a positive number"
            end

            local targetState = not ui.Flying
            local changed, reason = ui:SetFlyEnabled(targetState, speed)
            if not changed then
                ui:Log("Fly error  " .. tostring(reason), ui.Style.error)
                return false, reason
            end

            if targetState then
                ui:Log("Fly enabled  speed " .. tostring(speed), ui.Style.info)
                ui:Toggle(false)
            else
                ui:Log("Fly disabled", ui.Style.info)
            end
            return targetState
        end,
    }
    self.Commands.prediction = {
        Description = "Toggle cyan predicted-position markers for nearby players",
        Usage = "prediction",
        GameSpecific = true,
        HighlightLime = true,
        Protected = true,
        Callback = function(_, _, ui)
            local enabled, reason = ui:SetPredictionEnabled(not ui.PredictionEnabled)
            if not enabled then
                ui:Log("Prediction error  " .. tostring(reason), ui.Style.error)
                return false, reason
            end
            ui:Log("Prediction " .. (ui.PredictionEnabled and "enabled" or "disabled"), ui.Style.info)
            return ui.PredictionEnabled
        end,
    }
    self.Commands.lagdetection = {
        Description = "Toggle player-position freeze detection",
        Usage = "lagdetection [percentage]",
        Protected = true,
        Callback = function(args, _, ui)
            local percentage = args[1] and tonumber(args[1]) or 90
            if not percentage or percentage <= 0 or percentage > 100 then
                ui:Log("Usage  lagdetection [percentage 1-100]", ui.Style.warn)
                return false, "lag detection percentage must be between 1 and 100"
            end
            local enabled, reason = ui:SetLagDetectionEnabled(not ui.LagDetectionEnabled, percentage)
            if not enabled then
                return false, reason
            end
            ui:Log("Lag detection " .. (ui.LagDetectionEnabled and "enabled at " .. tostring(percentage) .. "%" or "disabled"), ui.Style.info)
            return true
        end,
    }
    self.Commands.rejoin = {
        Description = "Rejoin the current server",
        Usage = "rejoin",
        Protected = true,
        Callback = function(_, _, ui)
            ui:Log("Rejoining current server...", ui.Style.info)
            local teleported, teleportError = pcall(function()
                if game.JobId ~= "" then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, ui.Speaker)
                else
                    TeleportService:Teleport(game.PlaceId, ui.Speaker)
                end
            end)
            if not teleported then
                ui:Log("Rejoin error  " .. tostring(teleportError), ui.Style.error)
                return false, teleportError
            end
            return true
        end,
    }
    self.Commands.sudoaptupdate = {
        Description = "Check for and reload the newest StacyCMD version",
        Usage = "sudoaptupdate",
        Protected = true,
        Callback = function(_, _, ui)
            ui:CheckForUpdate()
        end,
    }
    self.Commands.ctrlc = {
        Description = "Destroy the entire script and UI",
        Usage = "ctrlc",
        Protected = true,
        Callback = function(_, _, ui)
            ui:Destroy()
        end,
    }
end

function StacyUI:_notifyGakuranToOverride()
    task.defer(function()
        while self.IntroPlaying and not self.Destroyed do
            task.wait()
        end
        if self.Destroyed then
            return
        end
        local loaded, notifyOrError = pcall(function()
            local Notify = loadstring(game:HttpGet("https://raw.githubusercontent.com/x8lua/scripts/main/ImGUI/Notify.lua?nocache=" .. tostring(tick()), true))()
            Notify.push(
                "'to' command got updated",
                "It now uses Gakuran names for TPing! If you want the old system, use 'legacyto' instead, It will switch 'to' back to display/username. Note: this change is only for the current session.",
                { duration = 8 }
            )
            return Notify
        end)

        if loaded then
            self.GameNotify = notifyOrError
        elseif not self.Destroyed then
            self:Log("Gakuran update notification failed  " .. tostring(notifyOrError), self.Style.warn)
        end
    end)
end

function StacyUI:TeleportTo(input)
    if type(input) ~= "string" or trim(input) == "" then
        return false, "usage: to [player|random]"
    end

    local useGakuranName = self.IsGakuranGame and not self.UseLegacyTo
    local target
    if trim(input):lower() == "random" then
        local candidates = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= self.Speaker and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                    or player.Character.PrimaryPart
                    or player.Character:FindFirstChild("Torso")
                    or player.Character:FindFirstChild("UpperTorso")
                if root then
                    table.insert(candidates, player)
                end
            end
        end
        if #candidates == 0 then
            return false, "no random teleport targets are available"
        end
        target = candidates[math.random(1, #candidates)]
    else
        target = useGakuranName and findPlayerByGameName(input) or findPlayerByUsername(input)
    end
    if not target then
        return false, useGakuranName and "Gakuran name not found" or "player not found"
    end

    local character = self.Speaker.Character
    local targetCharacter = target.Character
    local targetRoot = targetCharacter and (
        targetCharacter:FindFirstChild("HumanoidRootPart")
        or targetCharacter.PrimaryPart
        or targetCharacter:FindFirstChild("Torso")
        or targetCharacter:FindFirstChild("UpperTorso")
    )
    if not character or not targetRoot then
        return false, "character root part not found"
    end

    local teleported, teleportError = pcall(character.PivotTo, character, targetRoot.CFrame)
    if not teleported then
        return false, teleportError
    end
    self:Log("Teleported to " .. target.Name, self.Style.info)
    return true, target
end

function StacyUI:ViewPlayer(input)
    local camera = workspace.CurrentCamera
    if not camera then
        return false, "current camera not found"
    end

    local target = self.Speaker
    local query = type(input) == "string" and trim(input):lower() or "self"
    if query == "random" then
        local candidates = {}
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player ~= self.Speaker and player.Character
            if character and character:FindFirstChildOfClass("Humanoid") then
                table.insert(candidates, player)
            end
        end
        if #candidates == 0 then
            return false, "no random view targets are available"
        end
        target = candidates[math.random(1, #candidates)]
    elseif query ~= "" and query ~= "self" then
        target = self.IsGakuranGame and findPlayerByGameName(input) or findPlayerByUsername(input)
    end
    if not target then
        return false, self.IsGakuranGame and "Gakuran name not found" or "player not found"
    end

    local character = target.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false, "target character humanoid not found"
    end

    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
    self:Log(target == self.Speaker and "Viewing your own character" or "Viewing " .. target.Name, self.Style.info)
    return true, target
end

function StacyUI:ShowGameCommands()
    assert(not self.Destroyed, "StacyUI has been destroyed")
    self.IgnoreToggleUntil = os.clock() + 0.35
    self:HideUpdateLog(false)
    self:HideSettings(false)
    self.CommandBrowserGameOnly = true
    self.CommandBrowserTitle.Text = "GAME COMMANDS"
    self.CommandBrowserSearch.PlaceholderText = "SEARCH GAME COMMANDS"
    self.CommandBrowserEmpty.Text = "NO GAME COMMANDS"
    self.CommandBrowser.Visible = true
    self.CommandBrowserSearch.Text = ""
    self.CommandBrowserSearch.TextEditable = false
    self:_refreshCommandBrowser()
    return self
end

function StacyUI:StopPrediction()
    self.PredictionEnabled = false
    for _, connection in ipairs(self.PredictionConnections) do
        connection:Disconnect()
    end
    table.clear(self.PredictionConnections)

    for _, marker in pairs(self.PredictionMarkers) do
        pcall(function()
            marker.Circle:Remove()
            marker.Dot:Remove()
            marker.Line:Remove()
        end)
    end
    table.clear(self.PredictionMarkers)
end

function StacyUI:StopLagDetection()
    self.LagDetectionEnabled = false
    self.LagDetected = false
    for _, connection in ipairs(self.LagConnections) do
        connection:Disconnect()
    end
    table.clear(self.LagConnections)
    table.clear(self.LagPositionSamples)
    if self.LagNotify then
        pcall(self.LagNotify.clear, self.LagNotify)
    end
end

function StacyUI:SetLagDetectionEnabled(enabled, percentage)
    self:StopLagDetection()
    if not enabled then
        return true
    end

    local loaded, notifyOrError = pcall(function()
        local Notify = loadstring(game:HttpGet("https://raw.githubusercontent.com/x8lua/scripts/main/ImGUI/Notify.lua?nocache=" .. tostring(tick()), true))()
        return Notify.new({ color = Color3.fromRGB(130, 25, 25), accentColor = Color3.fromRGB(255, 85, 85) })
    end)
    if not loaded then
        return false, notifyOrError
    end

    self.LagNotify = notifyOrError
    self.LagDetectionEnabled = true
    self.LagDetectionThreshold = percentage / 100
    local elapsed = 0
    table.insert(self.LagConnections, RunService.Heartbeat:Connect(function(deltaTime)
        if not self.LagDetectionEnabled then
            return
        end
        elapsed = elapsed + deltaTime
        if elapsed < 0.5 then
            return
        end
        elapsed = 0

        local checked = 0
        local still = 0
        local activePlayers = {}
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            local root = character and (
                character:FindFirstChild("HumanoidRootPart")
                or character.PrimaryPart
                or character:FindFirstChild("Torso")
                or character:FindFirstChild("UpperTorso")
            )
            if root then
                activePlayers[player] = true
                checked = checked + 1
                local sample = self.LagPositionSamples[player]
                if sample then
                    if (root.Position - sample.Position).Magnitude <= 0.1 then
                        sample.StillTime = sample.StillTime + 0.5
                    else
                        sample.StillTime = 0
                    end
                    sample.Position = root.Position
                    if sample.StillTime >= 1.5 then
                        still = still + 1
                    end
                else
                    self.LagPositionSamples[player] = { Position = root.Position, StillTime = 0 }
                end
            end
        end
        for player in pairs(self.LagPositionSamples) do
            if not activePlayers[player] then
                self.LagPositionSamples[player] = nil
            end
        end
        local lagging = checked > 0 and still / checked >= self.LagDetectionThreshold

        if lagging and not self.LagDetected then
            self.LagDetected = true
            self.LagNotify:push("LAG DETECTED", "Most players have not changed position for 1.5 seconds.", { duration = 3600 })
        elseif self.LagDetected and not lagging then
            self.LagDetected = false
            self.LagNotify:clear()
        end
    end))
    return true
end

function StacyUI:SetPredictionEnabled(enabled)
    self:StopPrediction()
    if not enabled then
        return true
    end
    if not Drawing or type(Drawing.new) ~= "function" then
        return false, "the Drawing API is unavailable"
    end

    self.PredictionEnabled = true
    local markerColor = Color3.fromRGB(0, 255, 255)
    local visibleRadius = 17
    local predictionScale = 2.6
    local offset = Vector3.new(0, 0, -1.5)

    local function getPing()
        local pingValue = 0.1
        pcall(function()
            pingValue = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
        end)
        return math.clamp(pingValue, 0.01, 0.5)
    end

    local function createMarker()
        local marker = {}
        marker.Circle = Drawing.new("Circle")
        marker.Circle.Radius = 12
        marker.Circle.Thickness = 3
        marker.Circle.Filled = false
        marker.Circle.Color = markerColor
        marker.Circle.Transparency = 1
        marker.Circle.NumSides = 32
        marker.Circle.Visible = false

        marker.Dot = Drawing.new("Circle")
        marker.Dot.Radius = 4
        marker.Dot.Filled = true
        marker.Dot.Color = markerColor
        marker.Dot.Transparency = 1
        marker.Dot.NumSides = 24
        marker.Dot.Visible = false

        marker.Line = Drawing.new("Line")
        marker.Line.Color = markerColor
        marker.Line.Thickness = 2
        marker.Line.Transparency = 0.65
        marker.Line.Visible = false
        return marker
    end

    local function hideMarker(marker)
        marker.Circle.Visible = false
        marker.Dot.Visible = false
        marker.Line.Visible = false
    end

    local function destroyMarker(marker)
        pcall(function()
            marker.Circle:Remove()
            marker.Dot:Remove()
            marker.Line:Remove()
        end)
    end

    local function getPrediction(character, root)
        local totalPredictTime = (getPing() + 0.08) * predictionScale
        local position = root.Position
        local velocity = root.AssemblyLinearVelocity
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local isAirborne = math.abs(velocity.Y) > 2
        if humanoid then
            isAirborne = humanoid.FloorMaterial == Enum.Material.Air
        end

        local predictedPosition
        if isAirborne then
            predictedPosition = position
                + velocity * totalPredictTime
                + Vector3.new(0, -workspace.Gravity, 0) * 0.5 * totalPredictTime ^ 2
        else
            predictedPosition = Vector3.new(
                position.X + velocity.X * totalPredictTime,
                position.Y,
                position.Z + velocity.Z * totalPredictTime
            )
        end
        return predictedPosition + offset
    end

    local function updateMarker(player, marker)
        local localCharacter = self.Player.Character
        local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not localRoot or not root or not humanoid or humanoid.Health <= 0 then
            hideMarker(marker)
            return
        end
        if (root.Position - localRoot.Position).Magnitude > visibleRadius then
            hideMarker(marker)
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then
            hideMarker(marker)
            return
        end
        local standScreen, standOnScreen = camera:WorldToViewportPoint(getPrediction(character, root))
        if not standOnScreen or standScreen.Z <= 0 then
            hideMarker(marker)
            return
        end

        local targetScreen, targetOnScreen = camera:WorldToViewportPoint(root.Position)
        local markerPosition = Vector2.new(standScreen.X, standScreen.Y)
        marker.Circle.Position = markerPosition
        marker.Dot.Position = markerPosition
        marker.Circle.Visible = true
        marker.Dot.Visible = true
        if targetOnScreen and targetScreen.Z > 0 then
            marker.Line.From = Vector2.new(targetScreen.X, targetScreen.Y)
            marker.Line.To = markerPosition
            marker.Line.Visible = true
        else
            marker.Line.Visible = false
        end
    end

    table.insert(self.PredictionConnections, UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.P then
            self:StopPrediction()
            self:Log("Prediction disabled", self.Style.info)
        end
    end))

    table.insert(self.PredictionConnections, RunService.RenderStepped:Connect(function()
        if not self.PredictionEnabled then
            return
        end
        local activePlayers = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= self.Player then
                activePlayers[player] = true
                local marker = self.PredictionMarkers[player]
                if not marker then
                    marker = createMarker()
                    self.PredictionMarkers[player] = marker
                end
                pcall(updateMarker, player, marker)
            end
        end
        for player, marker in pairs(self.PredictionMarkers) do
            if not activePlayers[player] then
                destroyMarker(marker)
                self.PredictionMarkers[player] = nil
            end
        end
    end))
    return true
end

function StacyUI:_stopFly()
    self.FlySession = self.FlySession + 1
    self.Flying = false

    for _, connection in ipairs(self.FlyConnections) do
        connection:Disconnect()
    end
    table.clear(self.FlyConnections)

    if self.FlyGyro then
        self.FlyGyro:Destroy()
        self.FlyGyro = nil
    end
    if self.FlyVelocity then
        self.FlyVelocity:Destroy()
        self.FlyVelocity = nil
    end
    local character = self.Speaker and self.Speaker.Character
    local currentHumanoid = character and character:FindFirstChildOfClass("Humanoid")
    local currentRoot = character and (
        character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
    )
    local humanoid = currentHumanoid or self.FlyHumanoid
    if humanoid and humanoid.Parent then
        humanoid.PlatformStand = false
        humanoid.Sit = false
        humanoid.AutoRotate = true
        pcall(humanoid.ChangeState, humanoid, Enum.HumanoidStateType.GettingUp)
    end
    if currentRoot then
        currentRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        currentRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
    self.FlyHumanoid = nil
    pcall(function()
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end)
end

-- Thanks for Infinite Yield fly
function StacyUI:SetFlyEnabled(enabled, speed)
    self:_stopFly()
    if not enabled then
        return true
    end

    local flySpeed = tonumber(speed) or self.FlySpeed
    if not flySpeed or flySpeed <= 0 then
        return false, "fly speed must be a positive number"
    end

    local speaker = self.Speaker
    local character = speaker.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and (
        character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
    )
    if not humanoid or not root then
        return false, "character humanoid or root part not found"
    end

    self.FlySpeed = flySpeed
    self.Flying = true
    self.FlyHumanoid = humanoid
    self.FlySession = self.FlySession + 1
    local session = self.FlySession
    local control = { F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0 }
    local lastControl = { F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0 }

    local gyro = Instance.new("BodyGyro")
    gyro.P = 9e4
    gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    gyro.CFrame = root.CFrame
    gyro.Parent = root

    local velocity = Instance.new("BodyVelocity")
    velocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    velocity.Velocity = Vector3.new(0, 0, 0)
    velocity.Parent = root

    self.FlyGyro = gyro
    self.FlyVelocity = velocity

    table.insert(self.FlyConnections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or self.FlySession ~= session then
            return
        end
        if input.KeyCode == Enum.KeyCode.W then
            control.F = self.FlySpeed
        elseif input.KeyCode == Enum.KeyCode.S then
            control.B = -self.FlySpeed
        elseif input.KeyCode == Enum.KeyCode.A then
            control.L = -self.FlySpeed
        elseif input.KeyCode == Enum.KeyCode.D then
            control.R = self.FlySpeed
        elseif input.KeyCode == Enum.KeyCode.E then
            control.Q = self.FlySpeed * 2
        elseif input.KeyCode == Enum.KeyCode.Q then
            control.E = -self.FlySpeed * 2
        end
    end))

    table.insert(self.FlyConnections, UserInputService.InputEnded:Connect(function(input)
        if self.FlySession ~= session then
            return
        end
        if input.KeyCode == Enum.KeyCode.W then
            control.F = 0
        elseif input.KeyCode == Enum.KeyCode.S then
            control.B = 0
        elseif input.KeyCode == Enum.KeyCode.A then
            control.L = 0
        elseif input.KeyCode == Enum.KeyCode.D then
            control.R = 0
        elseif input.KeyCode == Enum.KeyCode.E then
            control.Q = 0
        elseif input.KeyCode == Enum.KeyCode.Q then
            control.E = 0
        end
    end))

    task.spawn(function()
        while self.Flying and self.FlySession == session and root.Parent and humanoid.Parent and gyro.Parent and velocity.Parent do
            task.wait()
            local camera = workspace.CurrentCamera
            humanoid.PlatformStand = true

            local forward = control.F + control.B
            local lateral = control.L + control.R
            local vertical = control.Q + control.E
            if forward ~= 0 or lateral ~= 0 or vertical ~= 0 then
                lastControl.F = control.F
                lastControl.B = control.B
                lastControl.L = control.L
                lastControl.R = control.R
                velocity.Velocity = (
                    camera.CFrame.LookVector * forward
                    + (camera.CFrame * CFrame.new(lateral, (forward + vertical) * 0.2, 0)).Position
                    - camera.CFrame.Position
                ) * 50
            elseif lastControl.F + lastControl.B ~= 0 or lastControl.L + lastControl.R ~= 0 then
                velocity.Velocity = Vector3.new(0, 0, 0)
            else
                velocity.Velocity = Vector3.new(0, 0, 0)
            end
            gyro.CFrame = camera.CFrame
        end

        if self.FlySession == session then
            self:_stopFly()
        end
    end)
    return true
end

function StacyUI:CheckForUpdate()
    assert(not self.Destroyed, "StacyUI has been destroyed")
    self:Log("Checking for StacyCMD updates...", self.Style.info)

    local fetched, source = pcall(game.HttpGet, game, self.SourceUrl, true)
    if not fetched then
        self:Log("Update check failed  " .. tostring(source), self.Style.error)
        return false, source
    end

    local remoteVersion = source:match('StacyUI%.Version%s*=%s*"([^"]+)"')
    if not remoteVersion then
        self:Log("Update check failed  remote version not found", self.Style.error)
        return false, "remote version not found"
    end

    if not isNewerVersion(remoteVersion, StacyUI.Version) then
        self:Log("StacyCMD v" .. StacyUI.Version .. " is already current", self.Style.info)
        return false, "already current"
    end

    local chunk, compileError = loadstring(source)
    if not chunk then
        self:Log("Update compile failed  " .. tostring(compileError), self.Style.error)
        return false, compileError
    end

    local loaded, updatedModule = pcall(chunk)
    if not loaded or type(updatedModule) ~= "table" or type(updatedModule.new) ~= "function" then
        local reason = loaded and "download did not return StacyUI" or updatedModule
        self:Log("Update load failed  " .. tostring(reason), self.Style.error)
        return false, reason
    end

    local reloadOptions = {}
    for key, value in pairs(self.ReloadOptions) do
        reloadOptions[key] = value
    end
    reloadOptions.Player = self.Player
    reloadOptions.Speaker = self.Speaker
    reloadOptions.SourceUrl = self.SourceUrl
    reloadOptions.Visible = true
    reloadOptions.Intro = true

    local customCommands = {}
    for name, command in pairs(self.Commands) do
        if not command.Protected then
            table.insert(customCommands, {
                Name = name,
                Description = command.Description,
                Usage = command.Usage,
                GameSpecific = command.GameSpecific,
                HighlightLime = command.HighlightLime,
                Callback = command.Callback,
            })
        end
    end

    self:Log("Updating StacyCMD v" .. StacyUI.Version .. " -> v" .. remoteVersion, self.Style.accent)
    task.defer(function()
        self:PlayOutro()
        task.wait(math.random(1, 20) / 10)
        self:Destroy()
        local created, updatedUI = pcall(updatedModule.new, reloadOptions)
        if not created then
            warn("[StacyUI] Reload failed  " .. tostring(updatedUI))
            return
        end

        for _, definition in ipairs(customCommands) do
            local registered, registerError = pcall(updatedUI.Register, updatedUI, definition)
            if not registered then
                warn("[StacyUI] Could not restore command " .. definition.Name .. "  " .. tostring(registerError))
            end
        end

        local environment = getgenv and getgenv() or _G
        environment.StacyCMD = updatedUI
        updatedUI:Log("Updated to StacyCMD v" .. remoteVersion, updatedUI.Style.info)
    end)
    return true, remoteVersion
end

function StacyUI:PlayOutro()
    if self.Destroyed or self.OutroPlaying or not self.Open then
        return self
    end

    self.OutroPlaying = true
    self:_clearSuggestions()
    self:HideCommands(false)
    self:HideUpdateLog(false)
    self:HideSettings(false)
    self.Prompt:ReleaseFocus()

    local overlay = create("Frame", {
        Name = "Outro",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 100,
    }, self.Gui)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(self.Style.width, self.Style.height)
    local targetSize = self.IntroTargetSize
    local headerPosition = Vector2.new(
        (viewport.X - self.Style.width) * 0.5 + 16,
        40 + math.floor((38 - targetSize.Y) * 0.5)
    ) + self.IntroTargetOffset
    local brand = create("Frame", {
        Name = "Brand",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(headerPosition.X + targetSize.X * 0.5, headerPosition.Y + targetSize.Y * 0.5),
        Size = UDim2.fromOffset(targetSize.X, targetSize.Y),
        ZIndex = 101,
    }, overlay)
    create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Font = Enum.Font.Bodoni,
        RichText = true,
        Text = 'Stacy <font color="#50FF7D">CMD</font>',
        TextColor3 = self.Style.text,
        TextScaled = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 102,
    }, brand)

    self.HeaderBrand.TextTransparency = 1
    local tweenInfo = TweenInfo.new(self.IntroTweenDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
    local brandTween = TweenService:Create(brand, tweenInfo, {
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(self.IntroSize.X, self.IntroSize.Y),
    })
    local consoleTween = TweenService:Create(self.Main, tweenInfo, { GroupTransparency = 1 })
    brandTween:Play()
    consoleTween:Play()
    brandTween.Completed:Wait()
    if not self.Destroyed then
        self.Main.Visible = false
        overlay:Destroy()
        self.OutroPlaying = false
    end
    return self
end

function StacyUI:_connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self.Connections, connection)
    return connection
end

function StacyUI:PlayIntro()
    assert(not self.Destroyed, "StacyUI has been destroyed")
    if self.IntroPlaying or self.OutroPlaying then
        return self
    end

    self.IntroSession = self.IntroSession + 1
    local session = self.IntroSession
    self.IntroPlaying = true
    self.Open = false
    self:_clearSuggestions()
    self:HideCommands(false)
    self:HideUpdateLog(false)
    self:HideSettings(false)
    self.Prompt:ReleaseFocus()
    self.Main.Visible = false

    local overlay = create("Frame", {
        Name = "Intro",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 100,
    }, self.Gui)
    self.IntroOverlay = overlay

    local brand = create("Frame", {
        Name = "Brand",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(self.IntroSize.X, self.IntroSize.Y),
        ZIndex = 101,
    }, overlay)

    local introTitle = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Font = Enum.Font.Bodoni,
        RichText = true,
        Text = 'Stacy <font color="#50FF7D">CMD</font>',
        TextColor3 = self.Style.text,
        TextScaled = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 102,
    }, brand)

    task.spawn(function()
        task.wait(1)
        if self.Destroyed or self.IntroSession ~= session or not overlay.Parent then
            return
        end

        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(self.Style.width, self.Style.height)
        local targetSize = self.IntroTargetSize
        local targetPosition = Vector2.new(
            (viewport.X - self.Style.width) * 0.5 + 16,
            40 + math.floor((38 - targetSize.Y) * 0.5)
        ) + self.IntroTargetOffset
        local tweenInfo = TweenInfo.new(self.IntroTweenDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
        local brandTween = TweenService:Create(brand, tweenInfo, {
            Position = UDim2.fromOffset(targetPosition.X + targetSize.X * 0.5, targetPosition.Y + targetSize.Y * 0.5),
            Size = UDim2.fromOffset(targetSize.X, targetSize.Y),
        })
        brandTween:Play()
        brandTween.Completed:Wait()

        if self.Destroyed or self.IntroSession ~= session then
            return
        end
        self.IntroPlaying = false
        self.OpenFromIntro = true
        TweenService:Create(introTitle, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1,
        }):Play()
        self:Toggle(true)
        task.wait(0.3)
        if self.Destroyed or self.IntroSession ~= session then
            return
        end
        if overlay.Parent then
            overlay:Destroy()
        end
        self.IntroOverlay = nil
    end)
    return self
end

function StacyUI:_build(options)
    local style = self.Style
    local playerGui = options.Parent or self.Player:WaitForChild("PlayerGui")

    if options.ReplaceExisting ~= false then
        local existing = playerGui:FindFirstChild(options.Name or "StacyUI")
        if existing then
            existing:Destroy()
        end
    end

    self.Gui = create("ScreenGui", {
        Name = options.Name or "StacyUI",
        IgnoreGuiInset = true,
        DisplayOrder = options.DisplayOrder or 999,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, playerGui)

    local existingErrorSound = SoundService:FindFirstChild("StacyCMDError")
    if existingErrorSound then
        existingErrorSound:Destroy()
    end
    self.ErrorSound = create("Sound", {
        Name = "StacyCMDError",
        SoundId = "rbxassetid://140650754692075",
        Volume = 0.7,
    }, SoundService)

    self.Main = create("CanvasGroup", {
        Name = "Console",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 40),
        Size = UDim2.fromOffset(style.width, style.height),
        BackgroundColor3 = style.background,
        BackgroundTransparency = style.transparency,
        GroupTransparency = 0,
        BorderSizePixel = 0,
        Visible = false,
    }, self.Gui)

    create("UICorner", { CornerRadius = UDim.new(0, 6) }, self.Main)

    self.Header = create("Frame", {
        Name = "Header",
        BackgroundColor3 = style.headerBackground,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
    }, self.Main)

    create("Frame", {
        Name = "AccentLine",
        BackgroundColor3 = style.accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
    }, self.Header)

    self.HeaderBrand = create("TextLabel", {
        Name = "Brand",
        BackgroundTransparency = 1,
        Font = Enum.Font.Bodoni,
        RichText = true,
        TextScaled = true,
        TextColor3 = style.text,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(16, math.floor((38 - self.IntroTargetSize.Y) * 0.5)),
        Size = UDim2.fromOffset(self.IntroTargetSize.X, self.IntroTargetSize.Y),
        Text = 'Stacy <font color="#50FF7D">CMD</font>',
    }, self.Header)

    create("TextLabel", {
        Name = "Version",
        BackgroundTransparency = 1,
        Font = style.fontMono,
        TextSize = 12,
        TextColor3 = style.accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(16 + self.IntroTargetSize.X + 6, 9),
        Size = UDim2.new(0, 80, 0, 20),
        Text = "v" .. StacyUI.Version,
    }, self.Header)

    self.KeyHint = create("TextLabel", {
        Name = "KeyHint",
        BackgroundTransparency = 1,
        Font = style.fontMono,
        TextSize = 12,
        TextColor3 = style.muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 10),
        Size = UDim2.new(0, 180, 0, 18),
        Text = self.ToggleKey.Name .. "  TOGGLE",
    }, self.Header)

    self.Scroll = create("ScrollingFrame", {
        Name = "Log",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, -86),
        Position = UDim2.fromOffset(10, 46),
        CanvasSize = UDim2.new(),
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, self.Main)

    self.LogLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    }, self.Scroll)

    self.EmptyState = create("TextLabel", {
        Name = "EmptyState",
        BackgroundTransparency = 1,
        Font = style.fontMono,
        TextSize = 14,
        TextColor3 = style.muted,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, -20, 0, 58),
        LayoutOrder = -1,
        Text = "NO OUTPUT  |  READY",
    }, self.Scroll)

    self.PrefixLabel = create("TextLabel", {
        Name = "Prefix",
        BackgroundTransparency = 1,
        Font = style.fontMono,
        TextSize = 16,
        TextColor3 = style.accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0, 200, 0, 24),
        Position = UDim2.new(0, 10, 1, -28),
        Text = self.Prefix,
    }, self.Main)

    self.Prompt = create("TextBox", {
        Name = "Prompt",
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        Font = style.fontMono,
        TextSize = 16,
        TextColor3 = style.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "",
    }, self.Main)

    self:_updatePromptBounds()
    self:_buildSuggestions()
    self:_buildCommandBrowser()
    self:_buildUpdateLog()
    self:_buildSettings()
    self:_buildKeySystem()
    self:_updatePromptBounds()

    self:_connect(self.PrefixLabel:GetPropertyChangedSignal("TextBounds"), function()
        self:_updatePromptBounds()
    end)
    self:_connect(self.Main:GetPropertyChangedSignal("AbsolutePosition"), function()
        self:_updatePromptBounds()
    end)

    self:_connect(self.LogLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        self:_updateCanvas()
    end)

    self:_connect(self.Prompt.FocusLost, function(enterPressed)
        self:_onFocusLost(enterPressed)
    end)

    self:_connect(UserInputService.InputBegan, function(input)
        self:_onPromptInput(input)
    end)

    self:_connect(self.Prompt:GetPropertyChangedSignal("Text"), function()
        self:_updateSuggestions()
        if self.CommandFocusActive then
            self:_scheduleCommandAutoHide()
        end
    end)
end

function StacyUI:_buildCommandBrowser()
    local style = self.Style

    self.CommandBrowser = create("Frame", {
        Name = "CommandBrowser",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(440, 360),
        BackgroundColor3 = style.background,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 20,
    }, self.Gui)

    create("UICorner", { CornerRadius = UDim.new(0, 6) }, self.CommandBrowser)
    create("UIStroke", {
        Color = style.divider,
        Transparency = 0.1,
        Thickness = 1,
    }, self.CommandBrowser)

    local header = create("Frame", {
        Name = "Header",
        BackgroundColor3 = style.headerBackground,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        ZIndex = 21,
    }, self.CommandBrowser)

    create("Frame", {
        Name = "AccentLine",
        BackgroundColor3 = style.accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        ZIndex = 22,
    }, header)

    self.CommandBrowserTitle = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Font = style.fontSans,
        TextSize = 17,
        TextColor3 = style.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(16, 5),
        Size = UDim2.new(1, -100, 0, 26),
        Text = "COMMANDS",
        ZIndex = 22,
    }, header)

    self.CommandBrowserClose = create("TextButton", {
        Name = "Close",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Font = style.fontMono,
        Text = "X",
        TextColor3 = style.muted,
        TextSize = 15,
        Size = UDim2.fromOffset(34, 30),
        Position = UDim2.new(1, -40, 0, 4),
        ZIndex = 22,
    }, header)

    self.CommandBrowserSearch = create("TextBox", {
        Name = "Search",
        BackgroundColor3 = style.headerBackground,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        TextEditable = false,
        Font = style.fontMono,
        PlaceholderText = "SEARCH COMMANDS",
        PlaceholderColor3 = style.muted,
        Text = "",
        TextColor3 = style.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(12, 50),
        Size = UDim2.new(1, -24, 0, 30),
        ZIndex = 21,
    }, self.CommandBrowser)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, self.CommandBrowserSearch)
    create("UIStroke", {
        Color = style.divider,
        Transparency = 0.05,
        Thickness = 1,
    }, self.CommandBrowserSearch)
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    }, self.CommandBrowserSearch)

    self.CommandBrowserList = create("ScrollingFrame", {
        Name = "List",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 90),
        Size = UDim2.new(1, -24, 1, -102),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ZIndex = 21,
    }, self.CommandBrowser)
    self.CommandBrowserLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    }, self.CommandBrowserList)

    self.CommandBrowserEmpty = create("TextLabel", {
        Name = "Empty",
        BackgroundTransparency = 1,
        Font = style.fontMono,
        Text = "NO MATCHES",
        TextColor3 = style.muted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(1, 0, 0, 32),
        Visible = false,
        ZIndex = 22,
    }, self.CommandBrowserList)

    self:_connect(self.CommandBrowserClose.MouseButton1Click, function()
        self:HideCommands()
    end)
    self:_connect(self.CommandBrowserSearch:GetPropertyChangedSignal("Text"), function()
        self:_refreshCommandBrowser()
    end)
    self:_connect(self.CommandBrowserSearch.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.IgnoreToggleUntil = os.clock() + 0.35
            self.CommandBrowserSearch.TextEditable = true
            self.CommandBrowserSearch:CaptureFocus()
        elseif input.KeyCode == Enum.KeyCode.Escape then
            self:HideCommands()
        end
    end)
    self:_connect(self.CommandBrowserSearch.FocusLost, function()
        self.CommandBrowserSearch.TextEditable = false
    end)
    self:_connect(self.CommandBrowserLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        self.CommandBrowserList.CanvasSize = UDim2.new(0, 0, 0, self.CommandBrowserLayout.AbsoluteContentSize.Y + 6)
    end)
end

function StacyUI:_buildUpdateLog()
    local style = self.Style

    self.UpdateLog = create("Frame", {
        Name = "UpdateLog",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(440, 360),
        BackgroundColor3 = style.background,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 20,
    }, self.Gui)

    create("UICorner", { CornerRadius = UDim.new(0, 6) }, self.UpdateLog)
    create("UIStroke", {
        Color = style.divider,
        Transparency = 0.1,
        Thickness = 1,
    }, self.UpdateLog)

    local header = create("Frame", {
        Name = "Header",
        BackgroundColor3 = style.headerBackground,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 52),
        ZIndex = 21,
    }, self.UpdateLog)
    create("Frame", {
        Name = "AccentLine",
        BackgroundColor3 = style.accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        ZIndex = 22,
    }, header)
    create("TextLabel", {
        Name = "BrandStacy",
        BackgroundTransparency = 1,
        Font = Enum.Font.Bodoni,
        Text = "Stacy",
        TextColor3 = style.text,
        TextSize = 23,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(16, 3),
        Size = UDim2.new(0, 70, 0, 30),
        ZIndex = 22,
    }, header)
    create("TextLabel", {
        Name = "BrandCMD",
        BackgroundTransparency = 1,
        Font = Enum.Font.Bodoni,
        Text = "CMD",
        TextColor3 = Color3.fromRGB(80, 255, 125),
        TextSize = 23,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(76, 3),
        Size = UDim2.new(0, 70, 0, 30),
        ZIndex = 22,
    }, header)
    create("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        Font = style.fontMono,
        Text = "UPDATE LOG  v" .. StacyUI.Version,
        TextColor3 = style.muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(17, 32),
        Size = UDim2.new(0, 180, 0, 14),
        ZIndex = 22,
    }, header)

    self.UpdateLogClose = create("TextButton", {
        Name = "Close",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Font = style.fontMono,
        Text = "X",
        TextColor3 = style.muted,
        TextSize = 15,
        Size = UDim2.fromOffset(34, 30),
        Position = UDim2.new(1, -40, 0, 5),
        ZIndex = 22,
    }, header)

    self.UpdateLogSearch = create("TextBox", {
        Name = "Search",
        BackgroundColor3 = style.headerBackground,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        TextEditable = false,
        Font = style.fontMono,
        PlaceholderText = "SEARCH UPDATES",
        PlaceholderColor3 = style.muted,
        Text = "",
        TextColor3 = style.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(12, 64),
        Size = UDim2.new(1, -24, 0, 30),
        ZIndex = 21,
    }, self.UpdateLog)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, self.UpdateLogSearch)
    create("UIStroke", {
        Color = style.divider,
        Transparency = 0.05,
        Thickness = 1,
    }, self.UpdateLogSearch)
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    }, self.UpdateLogSearch)

    self.UpdateLogList = create("ScrollingFrame", {
        Name = "List",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 104),
        Size = UDim2.new(1, -24, 1, -116),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ZIndex = 21,
    }, self.UpdateLog)
    self.UpdateLogLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    }, self.UpdateLogList)
    self.UpdateLogEmpty = create("TextLabel", {
        Name = "Empty",
        BackgroundTransparency = 1,
        Font = style.fontMono,
        Text = "NO MATCHES",
        TextColor3 = style.muted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(1, 0, 0, 32),
        Visible = false,
        ZIndex = 22,
    }, self.UpdateLogList)

    self:_connect(self.UpdateLogClose.MouseButton1Click, function()
        self:HideUpdateLog()
    end)
    self:_connect(self.UpdateLogSearch:GetPropertyChangedSignal("Text"), function()
        self:_refreshUpdateLog()
    end)
    self:_connect(self.UpdateLogSearch.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.IgnoreToggleUntil = os.clock() + 0.35
            self.UpdateLogSearch.TextEditable = true
            self.UpdateLogSearch:CaptureFocus()
        elseif input.KeyCode == Enum.KeyCode.Escape then
            self:HideUpdateLog()
        end
    end)
    self:_connect(self.UpdateLogSearch.FocusLost, function()
        self.UpdateLogSearch.TextEditable = false
    end)
end

function StacyUI:_refreshUpdateLog()
    if self.Destroyed or not self.UpdateLogList then
        return
    end
    local query = self.UpdateLogSearch.Text:lower()
    for _, child in ipairs(self.UpdateLogList:GetChildren()) do
        if child ~= self.UpdateLogLayout and child ~= self.UpdateLogEmpty then
            child:Destroy()
        end
    end

    local matches = {}
    for _, update in ipairs(UPDATE_LOG) do
        if query == "" or update.Version:lower():find(query, 1, true) or update.Text:lower():find(query, 1, true) then
            table.insert(matches, update)
        end
    end
    self.UpdateLogEmpty.Visible = #matches == 0

    for _, update in ipairs(matches) do
        local row = create("Frame", {
            Name = update.Version,
            BackgroundColor3 = self.Style.suggestionHighlight,
            BackgroundTransparency = 0.72,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -4, 0, 54),
            ZIndex = 22,
        }, self.UpdateLogList)
        create("UICorner", { CornerRadius = UDim.new(0, 4) }, row)
        create("TextLabel", {
            Name = "Version",
            BackgroundTransparency = 1,
            Font = self.Style.fontMono,
            Text = update.Version,
            TextColor3 = Color3.fromRGB(80, 255, 125),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(10, 7),
            Size = UDim2.new(0, 70, 0, 40),
            ZIndex = 23,
        }, row)
        create("TextLabel", {
            Name = "Text",
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = update.Text,
            TextColor3 = self.Style.text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Position = UDim2.fromOffset(84, 5),
            Size = UDim2.new(1, -94, 0, 44),
            TextWrapped = true,
            ZIndex = 23,
        }, row)
    end
end

function StacyUI:ShowUpdateLog()
    assert(not self.Destroyed, "StacyUI has been destroyed")
    self.IgnoreToggleUntil = os.clock() + 0.35
    self:HideCommands(false)
    self:HideSettings(false)
    self.UpdateLog.Visible = true
    self.UpdateLogSearch.Text = ""
    self.UpdateLogSearch.TextEditable = false
    self:_refreshUpdateLog()
    return self
end

function StacyUI:HideUpdateLog(restoreFocus)
    if self.UpdateLog then
        self.UpdateLog.Visible = false
    end
    if restoreFocus ~= false and not self.Destroyed and self.Open and not self.CommandBrowser.Visible then
        task.defer(self.Prompt.CaptureFocus, self.Prompt)
    end
    return self
end

function StacyUI:_commandKeyText(keyCode)
    return keyCode == Enum.KeyCode.Semicolon and ";" or keyCode.Name
end

function StacyUI:_buildSettings()
    local style = self.Style
    self.Settings = create("Frame", {
        Name = "Settings",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(400, 150),
        BackgroundColor3 = style.background,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 30,
    }, self.Gui)
    create("UICorner", { CornerRadius = UDim.new(0, 6) }, self.Settings)
    create("UIStroke", { Color = style.divider, Transparency = 0.1, Thickness = 1 }, self.Settings)

    local header = create("Frame", {
        Name = "Header",
        BackgroundColor3 = style.headerBackground,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 50),
        ZIndex = 31,
    }, self.Settings)
    create("TextLabel", {
        Name = "Brand",
        BackgroundTransparency = 1,
        Font = Enum.Font.Bodoni,
        RichText = true,
        Text = 'Stacy <font color="#50FF7D">CMD</font>',
        TextColor3 = style.text,
        TextSize = 21,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(16, 3),
        Size = UDim2.fromOffset(140, 28),
        ZIndex = 32,
    }, header)
    create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Font = style.fontMono,
        Text = "SETTINGS",
        TextColor3 = style.muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(17, 30),
        Size = UDim2.fromOffset(90, 14),
        ZIndex = 32,
    }, header)
    local close = create("TextButton", {
        Name = "Close",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Font = style.fontMono,
        Text = "X",
        TextColor3 = style.muted,
        TextSize = 15,
        Position = UDim2.new(1, -40, 0, 8),
        Size = UDim2.fromOffset(32, 32),
        ZIndex = 32,
    }, header)
    create("TextLabel", {
        Name = "KeyLabel",
        BackgroundTransparency = 1,
        Font = style.fontMono,
        Text = "COMMAND BAR KEY",
        TextColor3 = style.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(18, 82),
        Size = UDim2.fromOffset(190, 30),
        ZIndex = 31,
    }, self.Settings)
    self.SettingsKeyButton = create("TextButton", {
        Name = "CommandKey",
        AutoButtonColor = false,
        BackgroundColor3 = style.suggestionHighlight,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Font = style.fontMono,
        Text = "[ " .. self:_commandKeyText(self.CommandKey) .. " ]",
        TextColor3 = STACY_GREEN,
        TextSize = 14,
        Position = UDim2.new(1, -140, 0, 78),
        Size = UDim2.fromOffset(122, 34),
        ZIndex = 31,
    }, self.Settings)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, self.SettingsKeyButton)

    self:_connect(close.MouseButton1Click, function()
        self:HideSettings()
    end)
    self:_connect(self.SettingsKeyButton.MouseButton1Click, function()
        self.SettingsCapturingKey = true
        self.SettingsKeyButton.Text = "[ PRESS KEY ]"
    end)
    self:_connect(UserInputService.InputBegan, function(input)
        if not self.SettingsCapturingKey or input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        self.SettingsCapturingKey = false
        if input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= self.ToggleKey then
            self:SetCommandKey(input.KeyCode)
        else
            self.SettingsKeyButton.Text = "[ " .. self:_commandKeyText(self.CommandKey) .. " ]"
        end
    end)
end

function StacyUI:ShowSettings()
    self:HideCommands(false)
    self:HideUpdateLog(false)
    self:_clearSuggestions()
    self.Settings.Visible = true
    self.Prompt:ReleaseFocus()
    return self
end

function StacyUI:HideSettings(restoreFocus)
    if self.Settings then
        self.Settings.Visible = false
    end
    self.SettingsCapturingKey = false
    if self.SettingsKeyButton then
        self.SettingsKeyButton.Text = "[ " .. self:_commandKeyText(self.CommandKey) .. " ]"
    end
    if restoreFocus ~= false and not self.Destroyed and self.Open then
        task.defer(self.Prompt.CaptureFocus, self.Prompt)
    end
    return self
end

function StacyUI:_buildKeySystem()
    local style = self.Style
    self.KeySystem = create("Frame", {
        Name = "KeySystem",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(430, 230),
        BackgroundColor3 = style.background,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 30,
    }, self.Gui)
    create("UICorner", { CornerRadius = UDim.new(0, 6) }, self.KeySystem)
    create("UIStroke", { Color = STACY_GREEN, Transparency = 0.35, Thickness = 1 }, self.KeySystem)
    create("TextLabel", {
        Name = "Brand",
        BackgroundTransparency = 1,
        Font = Enum.Font.Bodoni,
        RichText = true,
        Text = 'Stacy <font color="#50FF7D">CMD</font>',
        TextColor3 = style.text,
        TextSize = 25,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(15, 12),
        Size = UDim2.new(1, -30, 0, 36),
        ZIndex = 31,
    }, self.KeySystem)
    create("TextLabel", {
        Name = "Info",
        BackgroundTransparency = 1,
        Font = style.fontMono,
        Text = "KEY REQUIRED\nGet your StacyCMD key from the Discord server.",
        TextColor3 = style.muted,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(20, 62),
        Size = UDim2.new(1, -40, 0, 58),
        ZIndex = 31,
    }, self.KeySystem)
    self.KeySystemKeyBox = create("TextBox", {
        Name = "Key",
        BackgroundColor3 = style.headerBackground,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = style.fontMono,
        PlaceholderText = "PASTE KEY",
        Text = "",
        TextColor3 = style.text,
        TextSize = 13,
        Position = UDim2.fromOffset(24, 130),
        Size = UDim2.new(1, -48, 0, 32),
        ZIndex = 31,
    }, self.KeySystem)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, self.KeySystemKeyBox)
    local verify = create("TextButton", {
        Name = "Verify",
        AutoButtonColor = false,
        BackgroundColor3 = STACY_GREEN,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Font = style.fontMono,
        Text = "VERIFY KEY",
        TextColor3 = Color3.fromRGB(10, 20, 10),
        TextSize = 13,
        Position = UDim2.fromOffset(24, 180),
        Size = UDim2.new(1, -48, 0, 32),
        ZIndex = 31,
    }, self.KeySystem)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, verify)
    self:_connect(verify.MouseButton1Click, function()
        local verified = self:VerifyKey(self.KeySystemKeyBox.Text)
        if not verified then
            self.KeySystemKeyBox.Text = ""
            self.KeySystemKeyBox.PlaceholderText = "INVALID KEY"
        end
    end)
end

function StacyUI:ShowKeySystem()
    self:HideCommands(false)
    self:HideUpdateLog(false)
    self:HideSettings(false)
    self:_clearSuggestions()
    self.Prompt:ReleaseFocus()
    self.KeySystem.Visible = true
    task.defer(self.KeySystemKeyBox.CaptureFocus, self.KeySystemKeyBox)
    return self
end

function StacyUI:HideKeySystem(restoreFocus)
    if not self.KeyVerified then
        return self
    end
    if self.KeySystem then
        self.KeySystem.Visible = false
    end
    if restoreFocus ~= false and not self.Destroyed and self.Open then
        task.defer(self.Prompt.CaptureFocus, self.Prompt)
    end
    return self
end

function StacyUI:VerifyKey(key)
    if trim(tostring(key)) ~= REQUIRED_KEY then
        return false
    end
    self.KeyVerified = true
    if type(writefile) == "function" then
        pcall(writefile, KEY_FILE, REQUIRED_KEY)
    end
    self.KeySystemKeyBox:ReleaseFocus()
    self.KeySystem.Visible = false
    if self.IsGakuranGame and not self.UseLegacyTo then
        self:_notifyGakuranToOverride()
    end
    self:_startVerifiedConsole()
    return true
end

function StacyUI:_refreshCommandBrowser()
    if self.Destroyed or not self.CommandBrowserList then
        return
    end

    local query = self.CommandBrowserSearch.Text:lower()
    for _, child in ipairs(self.CommandBrowserList:GetChildren()) do
        if child ~= self.CommandBrowserLayout and child ~= self.CommandBrowserEmpty then
            child:Destroy()
        end
    end

    local names = {}
    for name, command in pairs(self.Commands) do
        local inCurrentMode = not self.CommandBrowserGameOnly or command.GameSpecific
        if inCurrentMode and (query == "" or name:lower():find(query, 1, true)) then
            table.insert(names, name)
        end
    end
    table.sort(names)
    self.CommandBrowserEmpty.Visible = #names == 0

    for _, name in ipairs(names) do
        local command = self.Commands[name]
        local row = create("TextButton", {
            Name = name,
            AutoButtonColor = false,
            BackgroundColor3 = self.Style.suggestionHighlight,
            BackgroundTransparency = 0.72,
            BorderSizePixel = 0,
            Text = "",
            Size = UDim2.new(1, -4, 0, 48),
            ZIndex = 22,
        }, self.CommandBrowserList)
        create("UICorner", { CornerRadius = UDim.new(0, 4) }, row)
        create("TextLabel", {
            Name = "Name",
            BackgroundTransparency = 1,
            Font = self.Style.fontMono,
            Text = name,
            TextColor3 = self.CommandBrowserGameOnly and GAME_COMMAND_GREEN
                or (command.HighlightLime and GAME_COMMAND_GREEN or self.Style.accent),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(10, 4),
            Size = UDim2.new(1, -20, 0, 17),
            ZIndex = 23,
        }, row)
        create("TextLabel", {
            Name = "Description",
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = command.Description,
            TextColor3 = self.Style.muted,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(10, 22),
            Size = UDim2.new(1, -20, 0, 20),
            ZIndex = 23,
        }, row)
        row.MouseButton1Click:Connect(function()
            self:HideCommands()
            self.Prompt.Text = name .. " "
            self.Prompt.CursorPosition = #self.Prompt.Text + 1
            self.Prompt:CaptureFocus()
        end)
    end
end

function StacyUI:ShowCommands()
    assert(not self.Destroyed, "StacyUI has been destroyed")
    self.IgnoreToggleUntil = os.clock() + 0.35
    self:HideUpdateLog(false)
    self:HideSettings(false)
    self.CommandBrowserGameOnly = false
    self.CommandBrowserTitle.Text = "COMMANDS"
    self.CommandBrowserSearch.PlaceholderText = "SEARCH COMMANDS"
    self.CommandBrowserEmpty.Text = "NO MATCHES"
    self.CommandBrowser.Visible = true
    self.CommandBrowserSearch.Text = ""
    self.CommandBrowserSearch.TextEditable = false
    self:_refreshCommandBrowser()
    return self
end

function StacyUI:HideCommands(restoreFocus)
    if self.CommandBrowser then
        self.CommandBrowser.Visible = false
    end
    if restoreFocus ~= false and not self.Destroyed and self.Open and not self.UpdateLog.Visible then
        task.defer(self.Prompt.CaptureFocus, self.Prompt)
    end
    return self
end

function StacyUI:_buildSuggestions()
    local style = self.Style

    self.Suggestions = create("Frame", {
        Name = "Suggestions",
        BackgroundTransparency = 0.02,
        BackgroundColor3 = style.background,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 1, 6),
        Size = UDim2.new(0, 316, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 40,
    }, self.Gui)

    create("UICorner", { CornerRadius = UDim.new(0, 4) }, self.Suggestions)
    create("UIStroke", {
        Color = STACY_GREEN,
        Transparency = 0.68,
        Thickness = 1,
    }, self.Suggestions)
    create("UIPadding", {
        PaddingBottom = UDim.new(0, 5),
    }, self.Suggestions)
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0),
    }, self.Suggestions)

    local header = create("Frame", {
        Name = "Header",
        BackgroundColor3 = style.headerBackground,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = 1,
        ZIndex = 41,
    }, self.Suggestions)

    create("Frame", {
        Name = "AccentLine",
        BackgroundColor3 = STACY_GREEN,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        ZIndex = 42,
    }, header)

    create("TextLabel", {
        Name = "BrandStacy",
        BackgroundTransparency = 1,
        Font = Enum.Font.Bodoni,
        TextSize = 17,
        TextColor3 = style.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(12, 2),
        Size = UDim2.fromOffset(47, 26),
        Text = "Stacy",
        ZIndex = 42,
    }, header)

    create("TextLabel", {
        Name = "BrandCMD",
        BackgroundTransparency = 1,
        Font = Enum.Font.Bodoni,
        TextSize = 17,
        TextColor3 = STACY_GREEN,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(55, 2),
        Size = UDim2.fromOffset(43, 26),
        Text = "CMD",
        ZIndex = 42,
    }, header)

    create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Font = style.fontMono,
        TextSize = 10,
        TextColor3 = style.muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(0, 102, 0, 2),
        Size = UDim2.new(1, -114, 0, 26),
        Text = "COMMAND MATCHES",
        ZIndex = 42,
    }, header)

    self.Description = create("TextLabel", {
        Name = "Description",
        BackgroundColor3 = style.suggestionBackground,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        Font = style.fontMono,
        TextSize = 12,
        TextColor3 = style.muted,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        ZIndex = 41,
    }, self.Suggestions)

    create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    }, self.Description)

    create("Frame", {
        Name = "Divider",
        BackgroundColor3 = style.divider,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        LayoutOrder = 3,
        ZIndex = 41,
    }, self.Suggestions)

    self.SuggestionList = create("Frame", {
        Name = "List",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 4,
        ZIndex = 41,
    }, self.Suggestions)

    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 1),
    }, self.SuggestionList)
end

function StacyUI:_updatePromptBounds()
    local offset = 10 + self.PrefixLabel.TextBounds.X + 8
    self.Prompt.Position = UDim2.new(0, offset, 1, -28)
    self.Prompt.Size = UDim2.new(1, -(offset + 10), 0, 24)
    if self.Suggestions then
        local mainPosition = self.Main.AbsolutePosition
        local mainSize = self.Main.AbsoluteSize
        self.Suggestions.Position = UDim2.fromOffset(mainPosition.X + offset, mainPosition.Y + mainSize.Y + 6)
    end
end

function StacyUI:_updateCanvas()
    local height = self.LogLayout.AbsoluteContentSize.Y + 10
    self.Scroll.CanvasSize = UDim2.new(0, 0, 0, height)
    self.Scroll.CanvasPosition = Vector2.new(0, math.max(0, height - self.Style.height + 40))
end

function StacyUI:_clearSuggestions()
    for _, button in ipairs(self.SuggestionButtons) do
        button:Destroy()
    end
    table.clear(self.SuggestionButtons)
    self.SelectedSuggestionIndex = 0
    self.Suggestions.Visible = false
end

function StacyUI:_makeSuggestion(name)
    local command = self.Commands[name]
    local usage = tostring(command and command.Usage or name)
    if usage:lower():sub(1, #name) ~= name:lower() then
        usage = name .. " " .. usage
    end

    local button = create("TextButton", {
        Name = name,
        AutoButtonColor = false,
        BackgroundColor3 = self.Style.headerBackground,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = self.Style.fontMono,
        Text = usage,
        TextColor3 = command and command.HighlightLime and GAME_COMMAND_GREEN or self.Style.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 27),
        ZIndex = 42,
    }, self.SuggestionList)

    create("UIPadding", {
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 10),
    }, button)
    create("Frame", {
        Name = "SelectionBar",
        BackgroundColor3 = STACY_GREEN,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(-16, 0),
        Size = UDim2.new(0, 3, 1, 0),
        Visible = false,
        ZIndex = 43,
    }, button)

    self:_connect(button.MouseButton1Click, function()
        self.Prompt.Text = name .. " "
        self.Prompt.CursorPosition = #self.Prompt.Text + 1
        self.Prompt:CaptureFocus()
    end)

    table.insert(self.SuggestionButtons, button)
end

function StacyUI:_changeSelection(delta)
    local count = #self.SuggestionButtons
    if count == 0 then
        return
    end

    local old = self.SuggestionButtons[self.SelectedSuggestionIndex]
    if old then
        local oldCommand = self.Commands[old.Name]
        old.BackgroundTransparency = 1
        old.TextColor3 = oldCommand and oldCommand.HighlightLime and GAME_COMMAND_GREEN or self.Style.text
        old.SelectionBar.Visible = false
    end

    self.SelectedSuggestionIndex = ((self.SelectedSuggestionIndex - 1 + delta) % count) + 1
    local current = self.SuggestionButtons[self.SelectedSuggestionIndex]
    local command = self.Commands[current.Name]
    current.BackgroundTransparency = 0.12
    current.TextColor3 = command and command.HighlightLime and GAME_COMMAND_GREEN or STACY_GREEN
    current.SelectionBar.Visible = true

    self.Description.Text = command and command.Description or ""
end

function StacyUI:_updateSuggestions()
    if self.Destroyed then
        return
    end

    local words = splitWords(self.Prompt.Text)
    self:_clearSuggestions()
    if #words ~= 1 or self.Prompt.Text:sub(-1) == " " then
        return
    end

    local query = words[1]:lower()
    local matches = {}
    for name in pairs(self.Commands) do
        if name:lower():sub(1, #query) == query then
            table.insert(matches, name)
        end
    end
    table.sort(matches)

    if #matches == 0 then
        return
    end

    for _, name in ipairs(matches) do
        self:_makeSuggestion(name)
    end
    self.Suggestions.Visible = true
    self:_changeSelection(1)
end

function StacyUI:_onPromptInput(input)
    if UserInputService:GetFocusedTextBox() ~= self.Prompt then
        return
    end
    if self.CommandFocusActive then
        self:_scheduleCommandAutoHide()
    end

    if input.KeyCode == Enum.KeyCode.Return and self.Suggestions.Visible then
        local selected = self.SuggestionButtons[self.SelectedSuggestionIndex]
        if selected then
            self.Prompt.Text = selected.Name
            self.Prompt.CursorPosition = #self.Prompt.Text + 1
            self.Prompt:ReleaseFocus(true)
        end
        return
    end

    if input.KeyCode == Enum.KeyCode.Tab and self.Suggestions.Visible then
        local selected = self.SuggestionButtons[self.SelectedSuggestionIndex]
        if selected then
            self.Prompt.Text = selected.Name .. " "
            self.Prompt.CursorPosition = #self.Prompt.Text + 1
        end
        return
    end

    if input.KeyCode == Enum.KeyCode.Up then
        if self.Suggestions.Visible then
            self:_changeSelection(-1)
        else
            self.HistoryIndex = math.clamp(self.HistoryIndex + 1, 0, #self.History)
            self.Prompt.Text = self.History[self.HistoryIndex] or ""
            self.Prompt.CursorPosition = #self.Prompt.Text + 1
        end
    elseif input.KeyCode == Enum.KeyCode.Down then
        if self.Suggestions.Visible then
            self:_changeSelection(1)
        else
            self.HistoryIndex = math.clamp(self.HistoryIndex - 1, 0, #self.History)
            self.Prompt.Text = self.History[self.HistoryIndex] or ""
            self.Prompt.CursorPosition = #self.Prompt.Text + 1
        end
    end
end

function StacyUI:_onFocusLost(enterPressed)
    if enterPressed then
        local line = trim(self.Prompt.Text)
        local shouldRefocus = false
        self.Prompt.Text = ""
        if line ~= "" then
            local commandName = splitWords(line)[1]
            local command = commandName and self.Commands[commandName]
            shouldRefocus = command == nil
            local commandColor = command and command.HighlightLime and GAME_COMMAND_GREEN or self.Style.accent
            self:Log(self.Prefix .. line, commandColor)
            table.insert(self.History, 1, line)
            self.HistoryIndex = 0
            self:Execute(line)
        end
        if shouldRefocus and not self.Destroyed and self.Open and not self.CommandBrowser.Visible and not self.UpdateLog.Visible and not self.Settings.Visible then
            task.defer(self.Prompt.CaptureFocus, self.Prompt)
        end
    elseif self.Open and not self.CommandBrowser.Visible and not self.UpdateLog.Visible and not self.Settings.Visible then
        self:Toggle(false)
    end
end

function StacyUI:Register(definition)
    assert(type(definition) == "table", "Register expects a command definition")
    assert(type(definition.Name) == "string" and definition.Name ~= "", "command Name is required")
    assert(type(definition.Callback) == "function", "command Callback is required")
    assert(not (self.Commands[definition.Name] and self.Commands[definition.Name].Protected), "cannot replace a built in command")

    self.Commands[definition.Name] = {
        Description = definition.Description or "No description available",
        Usage = definition.Usage or definition.Name,
        GameSpecific = definition.GameSpecific == true,
        HighlightLime = definition.HighlightLime == true or definition.GameSpecific == true,
        Callback = definition.Callback,
    }
    return self
end

function StacyUI:Unregister(name)
    assert(not (self.Commands[name] and self.Commands[name].Protected), "cannot unregister a built in command")
    self.Commands[name] = nil
    return self
end

function StacyUI:Execute(line)
    local arguments = splitWords(trim(line))
    local name = table.remove(arguments, 1)
    if not name then
        return false, "empty command"
    end

    local command = self.Commands[name]
    if not command then
        local message = ('Unknown command "%s"'):format(name)
        self:Log(message, self.Style.error)
        return false, message
    end

    local ok, result = pcall(command.Callback, arguments, line, self)
    if not ok then
        self:Log("Command error  " .. tostring(result), self.Style.error)
        return false, result
    end
    return true, result
end

function StacyUI:Log(text, color)
    assert(not self.Destroyed, "StacyUI has been destroyed")

    self.EmptyState.Visible = false
    local isError = color == self.Style.error

    local holder = create("Frame", {
        Name = "Entry",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, self.Scroll)

    if isError then
        create("ImageLabel", {
            Name = "ErrorIcon",
            BackgroundTransparency = 1,
            Image = "rbxassetid://1847653031",
            Size = UDim2.fromOffset(16, 16),
        }, holder)
        if self.ErrorSound then
            pcall(function()
                self.ErrorSound.TimePosition = 0
                self.ErrorSound:Play()
            end)
        end
    end

    create("TextLabel", {
        Name = "Message",
        BackgroundTransparency = 1,
        Font = self.Style.fontMono,
        TextSize = 15,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = color or self.Style.text,
        Position = UDim2.fromOffset(isError and 21 or 0, 0),
        Size = UDim2.new(1, isError and -81 or -60, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = tostring(text),
    }, holder)

    create("TextLabel", {
        Name = "Timestamp",
        BackgroundTransparency = 1,
        Font = self.Style.fontMono,
        TextSize = 12,
        TextColor3 = self.Style.muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 55, 0, 16),
        Text = os.date("[%H:%M:%S]"),
    }, holder)

    self:_updateCanvas()
    return holder
end

function StacyUI:Clear()
    for _, child in ipairs(self.Scroll:GetChildren()) do
        if child ~= self.LogLayout and child ~= self.EmptyState then
            child:Destroy()
        end
    end
    self.EmptyState.Visible = true
    self:_updateCanvas()
    return self
end

function StacyUI:SetPrefix(prefix)
    self.Prefix = tostring(prefix)
    self.PrefixLabel.Text = self.Prefix
    self:_updatePromptBounds()
    return self
end

function StacyUI:SetToggleKey(keyCode)
    assert(typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode, "SetToggleKey expects an Enum KeyCode")
    ContextActionService:UnbindAction(self.ActionName)
    ContextActionService:UnbindAction(self.CommandActionName)
    self.ToggleKey = keyCode
    if self.KeyHint then
        self.KeyHint.Text = keyCode.Name .. "  TOGGLE"
    end
    ContextActionService:BindAction(self.ActionName, function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            if os.clock() < self.IgnoreToggleUntil then
                return Enum.ContextActionResult.Sink
            end
            local focused = UserInputService:GetFocusedTextBox()
            if focused and focused:IsDescendantOf(self.Gui) then
                return Enum.ContextActionResult.Sink
            end
            self:Toggle()
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end, false, keyCode)
    return self
end

function StacyUI:SetCommandKey(keyCode)
    assert(typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode, "SetCommandKey expects an Enum KeyCode")
    assert(keyCode ~= self.ToggleKey, "command key must differ from the toggle key")
    ContextActionService:UnbindAction(self.CommandActionName)
    self.CommandKey = keyCode
    self.ReloadOptions.CommandKey = keyCode
    if self.SettingsKeyButton then
        self.SettingsKeyButton.Text = "[ " .. self:_commandKeyText(keyCode) .. " ]"
    end
    ContextActionService:BindActionAtPriority(self.CommandActionName, function(_, state)
        if state == Enum.UserInputState.Begin and not self.SettingsCapturingKey and not self.IntroPlaying then
            self:FocusCommandBar()
        end
        return Enum.ContextActionResult.Sink
    end, false, 3000, keyCode)
    return self
end

function StacyUI:FocusCommandBar()
    if not self.KeyVerified then
        self:ShowKeySystem()
        return self
    end
    self.CommandFocusSession = self.CommandFocusSession + 1
    self.CommandFocusActive = true
    self:HideCommands(false)
    self:HideUpdateLog(false)
    self:HideSettings(false)
    if self.Open then
        self.Prompt:CaptureFocus()
    else
        self:Toggle(true)
    end
    self:_scheduleCommandAutoHide()
    task.delay(0.05, function()
        if self.Destroyed or self.CommandKey ~= Enum.KeyCode.Semicolon then
            return
        end
        local text = self.Prompt.Text
        if text:sub(-1) == ";" then
            self.Prompt.Text = text:sub(1, -2)
            self.Prompt.CursorPosition = #self.Prompt.Text + 1
        end
    end)
    return self
end

function StacyUI:_scheduleCommandAutoHide()
    if not self.CommandFocusActive then
        return
    end
    self.CommandFocusSession = self.CommandFocusSession + 1
    local session = self.CommandFocusSession
    task.delay(2.5, function()
        if self.Destroyed or session ~= self.CommandFocusSession or not self.CommandFocusActive then
            return
        end
        if self.Settings.Visible or self.CommandBrowser.Visible or self.UpdateLog.Visible then
            return
        end
        self.CommandFocusActive = false
        self:Toggle(false)
    end)
end

function StacyUI:Toggle(forceState)
    assert(not self.Destroyed, "StacyUI has been destroyed")
    if not self.KeyVerified and forceState ~= false then
        self:ShowKeySystem()
        return false
    end
    if self.IntroPlaying then
        return self.Open
    end
    local nextState = forceState
    if nextState == nil then
        nextState = not self.Open
    end
    if nextState == self.Open then
        return self.Open
    end

    self.Open = nextState
    if self.Open then
        self.Main.Visible = true
        if self.OpenFromIntro then
            self.OpenFromIntro = false
            self.Main.Position = UDim2.new(0.5, 0, 0, 40)
            self.Main.GroupTransparency = 1
            TweenService:Create(self.Main, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                GroupTransparency = 0,
            }):Play()
        else
            self.Main.GroupTransparency = 0
            self.Main.Position = UDim2.new(0.5, 0, 0, 20)
            TweenService:Create(self.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, 0, 0, 40),
            }):Play()
        end
        task.defer(self.Prompt.CaptureFocus, self.Prompt)
    else
        self.CommandFocusActive = false
        self.CommandFocusSession = self.CommandFocusSession + 1
        self:_clearSuggestions()
        self:HideCommands(false)
        self:HideUpdateLog(false)
        self:HideSettings(false)
        self.Prompt:ReleaseFocus()
        TweenService:Create(self.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0, 20),
        }):Play()
        task.delay(0.2, function()
            if not self.Destroyed and not self.Open then
                self.Main.Visible = false
            end
        end)
    end
    return self.Open
end

function StacyUI:Destroy()
    if self.Destroyed then
        return
    end
    self.IntroSession = self.IntroSession + 1
    self.IntroPlaying = false
    self.OutroPlaying = false
    if self.IntroOverlay then
        self.IntroOverlay:Destroy()
        self.IntroOverlay = nil
    end
    self:StopPrediction()
    self:StopLagDetection()
    self:_stopFly()
    self.Destroyed = true
    self.Open = false
    ContextActionService:UnbindAction(self.ActionName)
    ContextActionService:UnbindAction(self.CommandActionName)
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    table.clear(self.Connections)
    if self.ErrorSound then
        self.ErrorSound:Destroy()
        self.ErrorSound = nil
    end
    self.Gui:Destroy()
    table.clear(self.Commands)
    table.clear(self.History)
    table.clear(self.SuggestionButtons)

    if self.OnDestroy then
        local ok, err = pcall(self.OnDestroy, self)
        if not ok then
            warn("[StacyUI] OnDestroy callback failed  " .. tostring(err))
        end
    end
end

return StacyUI
