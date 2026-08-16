local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Analytics = game:GetService("RbxAnalyticsService")

local function loadSansFlexFont()
    local customFont
    local success = pcall(function()
        if type(getcustomasset) ~= "function" or type(writefile) ~= "function" then
            error("custom asset APIs unavailable")
        end
        local ttfAsset = getcustomasset("SansFlex.ttf")
        local jsonName = "SansFlex.json"
        local jsonStr = [[
{
    "name": "SansFlex",
    "faces": [
        {"name": "Regular", "weight": 400, "style": "normal", "assetId": "]] .. ttfAsset .. [["},
        {"name": "BoldItalic", "weight": 700, "style": "italic", "assetId": "]] .. ttfAsset .. [["}
    ]
}
]]
        writefile(jsonName, jsonStr)
        customFont = Font.new(getcustomasset(jsonName), Enum.FontWeight.Bold, Enum.FontStyle.Italic)
    end)
    if success and customFont then
        return customFont, true
    end
    local builderSans
    pcall(function() builderSans = Enum.Font.BuilderSans end)
    return builderSans or Enum.Font.Gotham, false
end

local STACY_GREEN = Color3.fromRGB(80, 255, 125)
local GAME_COMMAND_GREEN = Color3.fromRGB(0, 255, 0)
local DEFAULT_SOURCE_URL = "https://raw.githubusercontent.com/x8lua/scripts/main/stacycmd/StacyUI.lua"
local GAKURAN_PLACE_ID = 128736949265057
local AUTOEXEC_FILE = "StacyCMD.autoexec"
local SERVER_HOP_FILE = "StacyCMD.NotSameServers.json"
local KEY_API = "https://api.x8stuff.lol"

local StacyUI = {}
StacyUI.__index = StacyUI
StacyUI.Version = "2.5.5"

local UPDATE_LOG = {
    { Version = "v2.5.3", Text = "Moved key verification to the x8stuff device-bound API" },
    { Version = "v2.5.5", Text = "Changed mobile layout to continuous viewport-based scaling" },
    { Version = "v2.5.4", Text = "Added responsive mobile scaling while preserving the required key system" },
    { Version = "v2.5.2", Text = "Fixed autorevive death-effect cleanup service binding" },
    { Version = "v2.5.1", Text = "Made recognized semicolon commands fade out immediately" },
    { Version = "v2.5.0", Text = "Added the one-way Gakuran autorevive command" },
    { Version = "v2.4.9", Text = "Added the regular flingui loader command" },
    { Version = "v2.4.8", Text = "Changed whoisthis to select the player closest to the cursor" },
    { Version = "v2.4.7", Text = "Moved the local key-gate values out of the obvious source constants" },
    { Version = "v2.4.6", Text = "Added the draggable Gakuran whoisthis hover inspector" },
    { Version = "v2.4.5", Text = "Redesigned the key page with Discord access and a Why Discord section" },
    { Version = "v2.4.4", Text = "Fixed custom Sans Flex FontFace assignment in the games pages" },
    { Version = "v2.4.3", Text = "Added serverhop and shop commands for finding a new public server" },
    { Version = "v2.4.2", Text = "Added Sans Flex game typography and restored the Larpkuran thumbnail" },
    { Version = "v2.4.1", Text = "Redesigned the games pages and fixed the Larpkuran icon" },
    { Version = "v2.4.0", Text = "Added the supported games browser and script auto-execution" },
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
    fontSans = Enum.Font.Gotham,
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
        if key == "Font" and typeof(value) == "Font" then
            object.FontFace = value
        else
            object[key] = value
        end
    end
    object.Parent = parent
    return object
end

-- why dont you join my discord and grabbing a key in the source instead >:(
local function gateValues()
    local storage = string.char(83, 116, 97, 99, 121, 67, 77, 68, 46, 107, 101, 121)
    local expected = table.concat({ string.char(120, 56), string.char(120, 120, 121) })
    return storage, expected
end

local function deviceId()
    if type(gethwid) == "function" then
        local ok, id = pcall(gethwid)
        if ok and type(id) == "string" and #id >= 6 then
            return id
        end
    end
    return Analytics:GetClientId()
end

local function keyRequest(path, data)
    local http = request or http_request or (syn and syn.request)
    if not http then
        return false, "HTTP requests are unavailable."
    end
    local ok, response = pcall(http, {
        Url = KEY_API .. path,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(data),
    })
    if not ok then
        return false, "Key server is offline. Try again soon."
    end
    local parsed
    local decoded = pcall(function()
        parsed = HttpService:JSONDecode(response.Body or "")
    end)
    if not decoded or type(parsed) ~= "table" then
        return false, "Key server returned an unreadable response."
    end
    if response.StatusCode < 200 or response.StatusCode >= 300 or not parsed.ok then
        return false, parsed.message or "Key rejected."
    end
    return true, parsed
end

local function activateKey(key)
    return keyRequest("/v1/activate", { key = key, deviceId = deviceId() })
end

local function readSavedKey()
    if type(readfile) ~= "function" then
        return nil
    end
    local storage = gateValues()
    local read, key = pcall(readfile, storage)
    return read and trim(tostring(key)) or nil
end

local function readAutoExecGame()
    if type(readfile) ~= "function" then
        return nil
    end
    local read, gameId = pcall(readfile, AUTOEXEC_FILE)
    gameId = read and trim(tostring(gameId)) or ""
    return gameId ~= "" and gameId or nil
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
    self.GameFont, self.UseCustomGameFont = loadSansFlexFont()
    self.SavedKey = readSavedKey()
    self.KeyVerified = false
    self.KeySessionToken = nil
    self.KeyValidationStarted = false
    self.WelcomeEnabled = options.Welcome ~= false
    self.StartVisible = options.Visible ~= false
    self.Commands = {}
    self.History = {}
    self.HistoryIndex = 0
    self.SelectedSuggestionIndex = 0
    self.SuggestionButtons = {}
    self.CommandBrowserGameOnly = false
    self.SelectedGame = nil
    self.AutoExecGame = readAutoExecGame()
    self.AutoExecStarted = false
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

    if self.SavedKey then
        local activated, result = activateKey(self.SavedKey)
        if activated then
            self.KeyVerified = true
            self.KeySessionToken = result.sessionToken
        end
    end

    if self.KeyVerified and self.IsGakuranGame and not self.UseLegacyTo then
        self:_notifyGakuranToOverride()
    end

    if self.KeyVerified then
        self:_startVerifiedConsole()
        self:_startKeyValidation()
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
    if not self.AutoExecStarted and self.AutoExecGame then
        self.AutoExecStarted = true
        task.defer(function()
            if not self.Destroyed then
                self:ExecuteGameScript(self.AutoExecGame, true)
            end
        end)
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
    self.Commands.games = {
        Description = "Browse supported game scripts",
        Usage = "games",
        Protected = true,
        Callback = function(_, _, ui)
            ui:ShowGames()
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
        self.Commands.autorevive = {
            Description = "Permanently enable automatic revive and death-screen cleanup this session",
            Usage = "autorevive",
            GameSpecific = true,
            HighlightLime = true,
            Protected = true,
            Callback = function(_, _, ui)
                local enabled, reason = ui:EnableAutoRevive()
                if not enabled then
                    ui:Log("autorevive  " .. tostring(reason), ui.Style.warn)
                    return false, reason
                end
                ui:Log("autorevive enabled for this executor session", GAME_COMMAND_GREEN)
                return true
            end,
        }
        self.Commands.whoisthis = {
            Description = "Hover a player to see their Gakuran, username, and display name",
            Usage = "whoisthis",
            GameSpecific = true,
            HighlightLime = true,
            Protected = true,
            Callback = function(_, _, ui)
                ui:ShowWhoIsThis()
                return true
            end,
        }
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
    self.Commands.flingui = {
        Description = "Open the FlingV2 interface",
        Usage = "flingui",
        Protected = true,
        Callback = function(_, _, ui)
            local ok, result = pcall(function()
                return loadstring(game:HttpGet("https://raw.githubusercontent.com/unrexl/Scripts/refs/heads/main/FlingV2"))()
            end)
            if not ok then
                ui:Log("flingui error  " .. tostring(result), ui.Style.error)
                return false, result
            end
            ui:Log("flingui loaded", ui.Style.info)
            return true, result
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
    local serverHopCommand = {
        Description = "Find and join a different public server",
        Usage = "serverhop",
        Protected = true,
        Callback = function(_, _, ui)
            local hopped, reason = ui:ServerHop()
            if not hopped then
                ui:Log("Server hop error  " .. tostring(reason), ui.Style.error)
                return false, reason
            end
            return true
        end,
    }
    self.Commands.serverhop = serverHopCommand
    self.Commands.shop = {
        Description = "Alias for serverhop",
        Usage = "shop",
        Protected = true,
        Callback = serverHopCommand.Callback,
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

function StacyUI:EnableAutoRevive()
    local env = getgenv()
    if env.__STACYCMD_AUTO_REVIVE_ACTIVE then
        return false, "already enabled; reload the executor session to clear it"
    end

    local player = self.Speaker
    local activeCharacter
    local resetRequested = false
    local respawnDeadline = 0

    local function clearScreenEffects()
        local playerGui = player:FindFirstChildOfClass("PlayerGui")
        local deathUI = playerGui and playerGui:FindFirstChild("DeathUI")
        if deathUI then
            deathUI:Destroy()
        end
        local healthUI = playerGui and playerGui:FindFirstChild("HealthServiceUI")
        if healthUI then
            for _, name in ipairs({ "VignetteContainer", "GrippedDarkOverlay", "GrippedImpactFlash", "M2RagdollImpactFlash", "M2RagdollDarkOverlay" }) do
                local effect = healthUI:FindFirstChild(name, true)
                if effect and effect:IsA("GuiObject") then
                    effect.Visible = false
                end
            end
        end
        for _, container in ipairs({ Lighting, workspace.CurrentCamera }) do
            if container then
                for _, effect in ipairs(container:GetChildren()) do
                    if effect:IsA("BlurEffect") or (effect:IsA("ColorCorrectionEffect") and effect.Saturation <= 0) then
                        effect.Enabled = false
                    end
                end
            end
        end
    end

    local function reviveHumanoid(humanoid)
        if humanoid and humanoid.Parent and humanoid.Health <= 0 then
            humanoid.Health = humanoid.MaxHealth
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    local function bind(character)
        activeCharacter = character
        resetRequested = false
        respawnDeadline = 0
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.HealthChanged:Connect(function(health)
                if health <= 0 then
                    task.defer(reviveHumanoid, humanoid)
                end
            end)
        end
        clearScreenEffects()
    end

    env.__STACYCMD_AUTO_REVIVE_ACTIVE = true
    player.CharacterAdded:Connect(bind)
    if player.Character then
        bind(player.Character)
    end
    RunService.Heartbeat:Connect(function()
        clearScreenEffects()
        local humanoid = activeCharacter and activeCharacter:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then
            reviveHumanoid(humanoid)
            resetRequested = false
            respawnDeadline = 0
        elseif not humanoid and not resetRequested then
            resetRequested = true
            respawnDeadline = os.clock() + 1
        elseif resetRequested and os.clock() >= respawnDeadline and player.Character == activeCharacter then
            resetRequested = false
            pcall(function()
                player:LoadCharacter()
            end)
        end
    end)
    player:WaitForChild("PlayerGui").ChildAdded:Connect(function()
        task.defer(clearScreenEffects)
    end)
    Lighting.ChildAdded:Connect(function()
        task.defer(clearScreenEffects)
    end)
    pcall(function()
        local resetEvent = Instance.new("BindableEvent")
        resetEvent.Event:Connect(function()
            if resetRequested then
                return
            end
            resetRequested = true
            respawnDeadline = os.clock() + 1
            local humanoid = activeCharacter and activeCharacter:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end)
        StarterGui:SetCore("ResetButtonCallback", resetEvent)
    end)
    clearScreenEffects()
    return true
end

function StacyUI:ServerHop()
    local hour = os.date("!*t").hour
    local visited = { Hour = hour, IDs = {} }
    if type(readfile) == "function" then
        local read, contents = pcall(readfile, SERVER_HOP_FILE)
        if read then
            local decoded, saved = pcall(HttpService.JSONDecode, HttpService, contents)
            if decoded and type(saved) == "table" and saved.Hour == hour and type(saved.IDs) == "table" then
                visited = saved
            end
        end
    end

    local seen = {}
    for _, id in ipairs(visited.IDs) do
        seen[tostring(id)] = true
    end
    local cursor = nil
    for _ = 1, 5 do
        local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end
        local requested, body = pcall(function()
            return game:HttpGet(url)
        end)
        if not requested then
            return false, body
        end
        local decoded, page = pcall(HttpService.JSONDecode, HttpService, body)
        if not decoded or type(page) ~= "table" then
            return false, "could not read public server list"
        end
        for _, server in ipairs(page.data or {}) do
            local id = tostring(server.id)
            local playing = tonumber(server.playing)
            local maxPlayers = tonumber(server.maxPlayers)
            if id ~= game.JobId and not seen[id] and playing and maxPlayers and playing < maxPlayers then
                table.insert(visited.IDs, id)
                if type(writefile) == "function" then
                    pcall(writefile, SERVER_HOP_FILE, HttpService:JSONEncode(visited))
                end
                self:Log("Server hop found a new server...", self.Style.info)
                local teleported, teleportError = pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, id, self.Speaker)
                return teleported, teleportError
            end
        end
        cursor = page.nextPageCursor
        if not cursor or cursor == "null" then
            break
        end
    end
    return false, "no unvisited public server found"
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
    self.ResponsiveScale = create("UIScale", { Scale = 1 }, self.Main)

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
    self:_buildGames()
    self:_buildUpdateLog()
    self:_buildSettings()
    self:_buildKeySystem()
    self:_buildWhoIsThis()
    self:_updatePromptBounds()

    self:_connect(self.PrefixLabel:GetPropertyChangedSignal("TextBounds"), function()
        self:_updatePromptBounds()
    end)
    self:_connect(self.Main:GetPropertyChangedSignal("AbsolutePosition"), function()
        self:_updatePromptBounds()
    end)
    self:_applyResponsiveLayout()
    if workspace.CurrentCamera then
        self:_connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
            self:_applyResponsiveLayout()
        end)
    end

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

function StacyUI:_applyResponsiveLayout()
    if self.Destroyed or not self.Main then
        return
    end

    self.DesktopWidth = self.DesktopWidth or self.Style.width
    self.DesktopHeight = self.DesktopHeight or self.Style.height
    self.Style.width = self.DesktopWidth
    self.Style.height = self.DesktopHeight

    if not UserInputService.TouchEnabled then
        self.ResponsiveScale.Scale = 1
        self.Main.Size = UDim2.fromOffset(self.DesktopWidth, self.DesktopHeight)
        return
    end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(400, 700)
    local horizontalScale = (viewport.X - 24) / self.DesktopWidth
    local verticalScale = (viewport.Y - 110) / self.DesktopHeight
    self.ResponsiveScale.Scale = math.max(0.1, math.min(horizontalScale, verticalScale, 1))
    self.Main.AnchorPoint = Vector2.new(0.5, 0)
    self.Main.Position = UDim2.new(0.5, 0, 0, 34)
    self.Main.Size = UDim2.fromOffset(self.DesktopWidth, self.DesktopHeight)
    self.KeyHint.Text = "TAP TO TYPE"
    self.KeyHint.Size = UDim2.new(0, 110, 0, 18)
    self:_updatePromptBounds()
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
    self:HideGames(false)
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

function StacyUI:_applyGameFont(object)
    if self.UseCustomGameFont then
        object.FontFace = self.GameFont
    else
        object.Font = self.GameFont
    end
    return object
end

function StacyUI:_buildWhoIsThis()
    local style = self.Style
    self.WhoIsThis = create("Frame", {
        Name = "WhoIsThis", AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromOffset(32, 160),
        Size = UDim2.fromOffset(335, 184), BackgroundColor3 = Color3.fromRGB(16, 16, 19),
        BorderSizePixel = 0, Visible = false, Active = true, ZIndex = 60,
    }, self.Gui)
    create("UICorner", { CornerRadius = UDim.new(0, 8) }, self.WhoIsThis)
    create("UIStroke", { Color = STACY_GREEN, Transparency = 0.35, Thickness = 1 }, self.WhoIsThis)
    local header = create("Frame", {
        Name = "Header", Active = true, BackgroundColor3 = Color3.fromRGB(28, 28, 33),
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 44), ZIndex = 61,
    }, self.WhoIsThis)
    create("UICorner", { CornerRadius = UDim.new(0, 8) }, header)
    create("Frame", { BackgroundColor3 = Color3.fromRGB(28, 28, 33), BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -8), Size = UDim2.new(1, 0, 0, 8), ZIndex = 61 }, header)
    create("TextLabel", {
        BackgroundTransparency = 1, Font = Enum.Font.Bodoni, RichText = true,
        Text = 'Stacy <font color="#50FF7D">CMD</font>', TextColor3 = style.text, TextSize = 21,
        TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(14, 5), Size = UDim2.fromOffset(140, 28), ZIndex = 62,
    }, header)
    create("TextLabel", {
        BackgroundTransparency = 1, Font = style.fontMono, Text = "WHO IS THIS", TextColor3 = STACY_GREEN,
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(156, 14), Size = UDim2.fromOffset(100, 18), ZIndex = 62,
    }, header)
    local close = create("TextButton", {
        AutoButtonColor = false, BackgroundTransparency = 1, Font = style.fontMono, Text = "X", TextColor3 = style.muted,
        TextSize = 15, Position = UDim2.new(1, -38, 0, 6), Size = UDim2.fromOffset(30, 30), ZIndex = 62,
    }, header)
    self.WhoIsThisHint = create("TextLabel", {
        BackgroundTransparency = 1, Font = self.GameFont, Text = "Move your cursor near a player", TextColor3 = style.muted,
        TextSize = 16, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
        Position = UDim2.fromOffset(16, 58), Size = UDim2.new(1, -32, 0, 108), ZIndex = 61,
    }, self.WhoIsThis)
    self.WhoIsThisDetails = create("TextLabel", {
        BackgroundTransparency = 1, Font = self.GameFont, RichText = true, TextColor3 = style.text,
        TextSize = 16, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        Visible = false, Position = UDim2.fromOffset(18, 56), Size = UDim2.new(1, -36, 0, 112), ZIndex = 61,
    }, self.WhoIsThis)
    local dragging, dragStart, startPosition
    self:_connect(header.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = self.WhoIsThis.Position
        end
    end)
    self:_connect(header.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    self:_connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            self.WhoIsThis.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    self:_connect(close.MouseButton1Click, function() self:HideWhoIsThis() end)
end

function StacyUI:_getPlayerUnderCursor()
    local camera = workspace.CurrentCamera
    if not camera then
        return nil
    end
    local cursor = UserInputService:GetMouseLocation()
    local closestPlayer
    local closestDistance = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= self.Speaker then
            local character = player.Character
            local target = character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
            if target then
                local screenPoint, visible = camera:WorldToViewportPoint(target.Position)
                if visible and screenPoint.Z > 0 then
                    local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - cursor).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

function StacyUI:_refreshWhoIsThis()
    if self.Destroyed or not self.WhoIsThis or not self.WhoIsThis.Visible then
        return
    end
    local player = self:_getPlayerUnderCursor()
    if not player then
        self.WhoIsThisHint.Visible = true
        self.WhoIsThisDetails.Visible = false
        return
    end
    local billboard = player.Character and player.Character:FindFirstChild("PlayerInfoBillboard")
    local info = billboard and billboard:FindFirstChild("Info")
    local gakuranName = info and info.Text or "Unavailable"
    self.WhoIsThisHint.Visible = false
    self.WhoIsThisDetails.Visible = true
    self.WhoIsThisDetails.Text = '<font color="#50FF7D">GAKURAN NAME</font>\n' .. gakuranName .. '\n\n<font color="#A0A0A0">USERNAME</font>\n@' .. player.Name .. '\n\n<font color="#A0A0A0">DISPLAY NAME</font>\n' .. player.DisplayName
end

function StacyUI:ShowWhoIsThis()
    if not self.IsGakuranGame then
        self:Log("whoisthis is only available in Gakuran", self.Style.warn)
        return self
    end
    self.WhoIsThis.Visible = true
    self:HideCommands(false)
    task.spawn(function()
        while not self.Destroyed and self.WhoIsThis and self.WhoIsThis.Visible do
            self:_refreshWhoIsThis()
            task.wait(0.1)
        end
    end)
    return self
end

function StacyUI:HideWhoIsThis()
    if self.WhoIsThis then
        self.WhoIsThis.Visible = false
    end
    return self
end

function StacyUI:_buildGames()
    local style = self.Style
    self.Games = create("Frame", {
        Name = "Games", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(680, 360), BackgroundColor3 = Color3.fromRGB(15, 15, 17),
        BorderSizePixel = 0, Visible = false, ZIndex = 40,
    }, self.Gui)
    create("UICorner", {CornerRadius = UDim.new(0, 10)}, self.Games)
    create("UIStroke", {Color = Color3.fromRGB(52, 53, 60), Transparency = 0.25, Thickness = 1}, self.Games)
    local header = create("Frame", {BackgroundColor3 = Color3.fromRGB(23, 23, 27), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 58), ZIndex = 41}, self.Games)
    create("UICorner", {CornerRadius = UDim.new(0, 10)}, header)
    create("Frame", {BackgroundColor3 = Color3.fromRGB(23, 23, 27), BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 10), ZIndex = 41}, header)
    create("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.Bodoni, Text = 'Stacy <font color="#50FF7D">CMD</font>', RichText = true, TextColor3 = style.text, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(18, 5), Size = UDim2.fromOffset(160, 30), ZIndex = 42}, header)
    self.GamesTitle = create("TextLabel", {BackgroundTransparency = 1, Font = style.fontMono, Text = "SUPPORTED GAMES", TextColor3 = style.muted, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 35), Size = UDim2.fromOffset(180, 14), ZIndex = 42}, header)
    local close = create("TextButton", {BackgroundTransparency = 1, AutoButtonColor = false, Font = style.fontMono, Text = "X", TextColor3 = style.muted, TextSize = 15, Position = UDim2.new(1, -42, 0, 8), Size = UDim2.fromOffset(32, 30), ZIndex = 42}, header)
    self:_connect(close.MouseButton1Click, function() self:HideGames() end)
    create("TextLabel", {BackgroundTransparency = 1, Font = self.GameFont, Text = "Continue  >", TextColor3 = style.text, TextSize = 23, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(18, 68), Size = UDim2.fromOffset(210, 30), ZIndex = 42}, self.Games)
    self.GamesList = create("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(18, 104), Size = UDim2.new(1, -36, 0, 236), CanvasSize = UDim2.new(), ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.X, ZIndex = 41}, self.Games)
    self.GamesLayout = create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, self.GamesList)
    self:_connect(self.GamesLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function() self.GamesList.CanvasSize = UDim2.fromOffset(self.GamesLayout.AbsoluteContentSize.X + 8, 0) end)
    self.GameDetail = create("Frame", {Name = "Detail", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(680, 460), BackgroundColor3 = Color3.fromRGB(15, 15, 17), BorderSizePixel = 0, Visible = false, ZIndex = 45}, self.Gui)
    create("UICorner", {CornerRadius = UDim.new(0, 10)}, self.GameDetail)
    create("UIStroke", {Color = Color3.fromRGB(52, 53, 60), Transparency = 0.25, Thickness = 1}, self.GameDetail)
    local dhead = create("Frame", {BackgroundColor3 = Color3.fromRGB(23, 23, 27), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 48), ZIndex = 46}, self.GameDetail)
    create("UICorner", {CornerRadius = UDim.new(0, 10)}, dhead)
    create("Frame", {BackgroundColor3 = Color3.fromRGB(23, 23, 27), BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 10), ZIndex = 46}, dhead)
    self.GameDetailBack = create("TextButton", {BackgroundTransparency = 1, AutoButtonColor = false, Font = style.fontMono, Text = "<  GAMES", TextColor3 = style.muted, TextSize = 12, Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(90, 30), ZIndex = 47}, dhead)
    self:_connect(self.GameDetailBack.MouseButton1Click, function() self:ShowGames() end)
    create("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.Bodoni, RichText = true, Text = 'Stacy <font color="#50FF7D">CMD</font>', TextColor3 = style.text, TextSize = 20, Position = UDim2.new(0.5, -75, 0, 8), Size = UDim2.fromOffset(150, 30), ZIndex = 47}, dhead)
    local detailClose = create("TextButton", {BackgroundTransparency = 1, AutoButtonColor = false, Font = style.fontMono, Text = "X", TextColor3 = style.muted, TextSize = 15, Position = UDim2.new(1, -42, 0, 8), Size = UDim2.fromOffset(32, 30), ZIndex = 47}, dhead)
    self:_connect(detailClose.MouseButton1Click, function() self:HideGames() end)
    self.GameDetailImage = create("ImageLabel", {BackgroundColor3 = Color3.fromRGB(28, 28, 32), BorderSizePixel = 0, Image = "", ScaleType = Enum.ScaleType.Crop, Position = UDim2.fromOffset(18, 66), Size = UDim2.fromOffset(400, 225), ZIndex = 46}, self.GameDetail)
    create("UICorner", {CornerRadius = UDim.new(0, 7)}, self.GameDetailImage)
    self.GameDetailIcon = create("ImageLabel", {BackgroundColor3 = Color3.fromRGB(28, 28, 32), BorderSizePixel = 0, Image = "", ScaleType = Enum.ScaleType.Crop, Position = UDim2.fromOffset(438, 66), Size = UDim2.fromOffset(58, 58), ZIndex = 47}, self.GameDetail)
    create("UICorner", {CornerRadius = UDim.new(0, 8)}, self.GameDetailIcon)
    self.GameDetailName = create("TextLabel", {BackgroundTransparency = 1, Font = self.GameFont, TextColor3 = style.text, TextSize = 27, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Position = UDim2.fromOffset(508, 66), Size = UDim2.fromOffset(150, 58), ZIndex = 47}, self.GameDetail)
    self.GameDetailInfo = create("TextLabel", {BackgroundTransparency = 1, Font = self.GameFont, TextColor3 = style.muted, TextSize = 16, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(438, 134), Size = UDim2.fromOffset(220, 88), ZIndex = 47}, self.GameDetail)
    self.GameExecute = create("TextButton", {AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(51, 102, 255), BorderSizePixel = 0, Font = self.GameFont, Text = "EXECUTE", TextColor3 = Color3.new(1, 1, 1), TextSize = 19, Position = UDim2.fromOffset(438, 233), Size = UDim2.fromOffset(142, 58), ZIndex = 47}, self.GameDetail)
    create("UICorner", {CornerRadius = UDim.new(0, 7)}, self.GameExecute)
    self.GameAutoExec = create("TextButton", {AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(38, 38, 43), BorderSizePixel = 0, Font = style.fontMono, TextColor3 = style.muted, TextSize = 11, Position = UDim2.fromOffset(588, 233), Size = UDim2.fromOffset(70, 58), ZIndex = 47}, self.GameDetail)
    create("UICorner", {CornerRadius = UDim.new(0, 7)}, self.GameAutoExec)
    create("Frame", {BackgroundColor3 = Color3.fromRGB(50, 50, 56), BorderSizePixel = 0, Position = UDim2.fromOffset(18, 309), Size = UDim2.new(1, -36, 0, 1), ZIndex = 46}, self.GameDetail)
    self.GameDetailDescription = create("TextLabel", {BackgroundTransparency = 1, Font = self.GameFont, RichText = true, TextColor3 = style.text, TextSize = 18, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(24, 327), Size = UDim2.new(1, -48, 0, 100), ZIndex = 46}, self.GameDetail)
    self:_connect(self.GameExecute.MouseButton1Click, function()
        local selectedGame = self.SelectedGame
        self:HideGames(false)
        self:ExecuteGameScript(selectedGame)
    end)
    self:_connect(self.GameAutoExec.MouseButton1Click, function() self:ToggleGameAutoExec(self.SelectedGame) end)
end

function StacyUI:_gameData(id)
    if id == "gakuran" then
        return {Id = id, Title = "Larpkuran", Author = "Flingpan", Summary = "May, 2007 - Flingpan", Description = 'May, 2007 <font color="#999999">-</font> Flingpan\n\nAn <b>INTENDED</b> Slice of Life experience (though I guess our community just loves to fling LOL)', Icon = "rbxthumb://type=GameIcon&id=9199655655&w=512&h=512", Image = "rbxthumb://type=GameThumbnail&id=128736949265057&w=768&h=432", SupportedPlace = GAKURAN_PLACE_ID, Url = "https://raw.githubusercontent.com/x8lua/scripts/refs/heads/main/gakuran_fling.lua"}
    end
    return {Id = "placeholder", Title = "Placeholder", Author = "StacyCMD", Summary = "Compatibility test", Description = "A placeholder game script for testing compatibility errors.", Icon = "rbxassetid://1847653031", Image = "rbxassetid://1847653031", SupportedPlace = -1}
end

function StacyUI:_updateGameAutoExecButton()
    local enabled = self.AutoExecGame == self.SelectedGame
    self.GameAutoExec.Text = enabled and "AUTO\nON" or "AUTO\nOFF"
    self.GameAutoExec.BackgroundColor3 = enabled and STACY_GREEN or Color3.fromRGB(45, 45, 50)
    self.GameAutoExec.TextColor3 = enabled and Color3.fromRGB(10, 20, 10) or self.Style.muted
end

function StacyUI:ShowGames()
    self:HideCommands(false); self:HideUpdateLog(false); self:HideSettings(false); self:HideGameDetail(false)
    self.Games.Visible = true; self.IgnoreToggleUntil = os.clock() + 0.35
    for _, child in ipairs(self.GamesList:GetChildren()) do if child:IsA("GuiButton") then child:Destroy() end end
    for _, id in ipairs({"gakuran", "placeholder"}) do
        local gameInfo = self:_gameData(id)
        local row = create("TextButton", {AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(26, 26, 30), BorderSizePixel = 0, Text = "", Size = UDim2.fromOffset(190, 224), ZIndex = 42}, self.GamesList)
        create("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
        local icon = create("ImageLabel", {BackgroundColor3 = Color3.fromRGB(35, 35, 39), BorderSizePixel = 0, Image = gameInfo.Icon, ScaleType = Enum.ScaleType.Crop, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(174, 150), ZIndex = 43}, row)
        create("UICorner", {CornerRadius = UDim.new(0, 6)}, icon)
        create("TextLabel", {BackgroundTransparency = 1, Font = self.GameFont, Text = gameInfo.Title, TextColor3 = self.Style.text, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(10, 162), Size = UDim2.new(1, -20, 0, 28), ZIndex = 43}, row)
        create("TextLabel", {BackgroundTransparency = 1, Font = self.GameFont, Text = gameInfo.Summary, TextColor3 = self.Style.muted, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(10, 192), Size = UDim2.new(1, -20, 0, 24), ZIndex = 43}, row)
        self:_connect(row.MouseButton1Click, function() self:ShowGameDetail(id) end)
    end
    self.GamesTitle.Text = "SUPPORTED GAMES  |  2 SCRIPTS"
    self.Prompt:ReleaseFocus()
    return self
end

function StacyUI:ShowGameDetail(id)
    local gameInfo = self:_gameData(id); self.SelectedGame = id
    self.Games.Visible = false; self.GameDetail.Visible = true
    self.GameDetailName.Text = gameInfo.Title; self.GameDetailImage.Image = gameInfo.Image; self.GameDetailIcon.Image = gameInfo.Icon; self.GameDetailDescription.Text = gameInfo.Description
    self.GameDetailInfo.Text = "By " .. gameInfo.Author .. "\n\nScript status: Supported\n" .. (gameInfo.SupportedPlace == game.PlaceId and "Current game: Compatible" or "Current game: May not work")
    self:_updateGameAutoExecButton(); self.Prompt:ReleaseFocus(); self.IgnoreToggleUntil = os.clock() + 0.35
    return self
end

function StacyUI:HideGameDetail(restoreFocus)
    if self.GameDetail then self.GameDetail.Visible = false end
    if restoreFocus ~= false and self.Open and not self.Destroyed then task.defer(self.Prompt.CaptureFocus, self.Prompt) end
    return self
end

function StacyUI:HideGames(restoreFocus)
    if self.Games then self.Games.Visible = false end
    self:HideGameDetail(false)
    if restoreFocus ~= false and self.Open and not self.Destroyed then task.defer(self.Prompt.CaptureFocus, self.Prompt) end
    return self
end

function StacyUI:ToggleGameAutoExec(id)
    if self.AutoExecGame == id then
        self.AutoExecGame = nil
        if type(delfile) == "function" then
            pcall(delfile, AUTOEXEC_FILE)
        elseif type(writefile) == "function" then
            pcall(writefile, AUTOEXEC_FILE, "")
        end
    else
        self.AutoExecGame = id
        if type(writefile) == "function" then pcall(writefile, AUTOEXEC_FILE, id) end
    end
    self:_updateGameAutoExecButton()
    self:Log(self.AutoExecGame and ("Autoexec enabled  " .. self.AutoExecGame) or "Autoexec disabled", self.Style.info)
end

function StacyUI:ExecuteGameScript(id, fromAutoExec)
    local gameInfo = self:_gameData(id)
    if gameInfo.Id == "placeholder" then
        local messages = {"See? I knew that script wasn't compatible with this game", "What did I tell you? That script doesn't work here", "Like I said earlier, that script isn't compatible with this game"}
        local incompatibleScript
        local _, scriptError = pcall(function()
            incompatibleScript()
        end)
        local cleanError = tostring(scriptError):match("attempt to .+") or tostring(scriptError)
        self:Log(cleanError .. ", " .. messages[math.random(1, #messages)], self.Style.error)
        return false
    end
    if gameInfo.SupportedPlace ~= game.PlaceId then
        self:Log("Warning  " .. gameInfo.Title .. " may not work in this game", self.Style.warn)
    end
    if not fromAutoExec then self:Log("Executing " .. gameInfo.Title, self.Style.info) end
    local ok, result = pcall(function() return loadstring(game:HttpGet(gameInfo.Url))() end)
    if not ok then self:Log("Script error  " .. tostring(result), self.Style.error); return false, result end
    return true, result
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
    self:HideGames(false)
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
        Size = UDim2.fromOffset(500, 405),
        BackgroundColor3 = Color3.fromRGB(15, 15, 18),
        BackgroundTransparency = 0.01,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 30,
    }, self.Gui)
    create("UICorner", { CornerRadius = UDim.new(0, 10) }, self.KeySystem)
    create("UIStroke", { Color = STACY_GREEN, Transparency = 0.45, Thickness = 1 }, self.KeySystem)
    local header = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(24, 24, 29), BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 86), ZIndex = 31,
    }, self.KeySystem)
    create("UICorner", { CornerRadius = UDim.new(0, 10) }, header)
    create("Frame", {
        BackgroundColor3 = Color3.fromRGB(24, 24, 29), BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 10), ZIndex = 31,
    }, header)
    create("TextLabel", {
        Name = "Brand",
        BackgroundTransparency = 1,
        Font = Enum.Font.Bodoni,
        RichText = true,
        Text = 'Stacy <font color="#50FF7D">CMD</font>',
        TextColor3 = style.text,
        TextSize = 31,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(24, 10),
        Size = UDim2.new(1, -48, 0, 38),
        ZIndex = 32,
    }, header)
    create("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        Font = self.GameFont,
        Text = "A simple key. No ads, no linkvertise, no nonsense.",
        TextColor3 = style.muted,
        TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(26, 50), Size = UDim2.new(1, -52, 0, 24), ZIndex = 32,
    }, header)
    create("TextLabel", {
        BackgroundTransparency = 1, Font = self.GameFont, Text = "GET YOUR KEY",
        TextColor3 = STACY_GREEN, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(26, 106), Size = UDim2.fromOffset(180, 22), ZIndex = 31,
    }, self.KeySystem)
    create("TextLabel", {
        BackgroundTransparency = 1, Font = self.GameFont,
        Text = "Join the Discord, grab your key, then paste it below.",
        TextColor3 = style.text, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(26, 128), Size = UDim2.new(1, -52, 0, 26), ZIndex = 31,
    }, self.KeySystem)
    local discord = create("TextButton", {
        Name = "DiscordLink", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(88, 101, 242),
        BorderSizePixel = 0, Font = self.GameFont, Text = "COPY DISCORD INVITE",
        TextColor3 = Color3.new(1, 1, 1), TextSize = 16,
        Position = UDim2.fromOffset(26, 164), Size = UDim2.new(1, -52, 0, 40), ZIndex = 31,
    }, self.KeySystem)
    create("UICorner", { CornerRadius = UDim.new(0, 6) }, discord)
    self.KeySystemKeyBox = create("TextBox", {
        Name = "Key",
        BackgroundColor3 = Color3.fromRGB(28, 28, 33),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = self.GameFont,
        PlaceholderText = "Paste your key here",
        PlaceholderColor3 = style.muted,
        Text = "",
        TextColor3 = style.text,
        TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(26, 216),
        Size = UDim2.new(1, -52, 0, 42),
        ZIndex = 31,
    }, self.KeySystem)
    create("UICorner", { CornerRadius = UDim.new(0, 6) }, self.KeySystemKeyBox)
    create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, self.KeySystemKeyBox)
    local verify = create("TextButton", {
        Name = "Verify",
        AutoButtonColor = false,
        BackgroundColor3 = STACY_GREEN,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Font = self.GameFont,
        Text = "VERIFY KEY",
        TextColor3 = Color3.fromRGB(10, 20, 10),
        TextSize = 17,
        Position = UDim2.fromOffset(26, 268),
        Size = UDim2.new(1, -52, 0, 42),
        ZIndex = 31,
    }, self.KeySystem)
    create("UICorner", { CornerRadius = UDim.new(0, 6) }, verify)
    self.KeySystemStatus = create("TextLabel", {
        Name = "Status", BackgroundTransparency = 1, Font = self.GameFont,
        Text = "Ready", TextColor3 = style.muted, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(26, 310), Size = UDim2.new(1, -52, 0, 18), ZIndex = 31,
    }, self.KeySystem)
    self.KeySystemWhy = create("TextButton", {
        Name = "WhyDiscord", AutoButtonColor = false, BackgroundTransparency = 1,
        Font = self.GameFont, Text = "Why Discord?", TextColor3 = style.muted, TextSize = 15,
        Position = UDim2.fromOffset(26, 326), Size = UDim2.new(1, -52, 0, 28), ZIndex = 31,
    }, self.KeySystem)
    self.KeySystemWhyText = create("TextLabel", {
        Name = "WhyDiscordText", BackgroundTransparency = 1, Font = self.GameFont,
        RichText = true, TextColor3 = style.text, TextSize = 15, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        Visible = false, Position = UDim2.fromOffset(26, 358), Size = UDim2.new(1, -52, 0, 170), ZIndex = 31,
        Text = "<b>I’ll never put StacyCMD behind ad-key systems.</b> I’m not trying to squeeze money out of you or send you through pop-ups just to use something I made. This project exists because I enjoy building it and I want the community around it to help shape it.\n\nThe Discord is simply where that happens. Come hang out, tell me what feels broken, throw in a feature idea, or pitch a totally new game idea. It’s still growing, but every message genuinely helps.",
    }, self.KeySystem)
    self:_connect(discord.MouseButton1Click, function()
        if type(setclipboard) == "function" then
            pcall(setclipboard, "https://discord.gg/WM7RyD7Znn")
            discord.Text = "INVITE COPIED"
        else
            discord.Text = "discord.gg/WM7RyD7Znn"
        end
    end)
    self:_connect(self.KeySystemWhy.MouseButton1Click, function()
        local shown = not self.KeySystemWhyText.Visible
        self.KeySystemWhyText.Visible = shown
        self.KeySystemWhy.Text = shown and "Why Discord?  -" or "Why Discord?  +"
        self.KeySystem.Size = UDim2.fromOffset(500, shown and 550 or 405)
    end)
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
    self:HideGames(false)
    self:_clearSuggestions()
    self.Prompt:ReleaseFocus()
    self.KeySystem.Visible = true
    if self.KeySystemStatus then
        self.KeySystemStatus.Text = "Waiting for key"
        self.KeySystemStatus.TextColor3 = self.Style.muted
    end
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
    key = trim(tostring(key))
    if key == "" then
        return false
    end
    if self.KeySystemStatus then
        self.KeySystemStatus.Text = "Contacting key server..."
        self.KeySystemStatus.TextColor3 = self.Style.muted
    end
    local activated, result = activateKey(key)
    if not activated then
        if self.KeySystemStatus then
            self.KeySystemStatus.Text = tostring(result)
            self.KeySystemStatus.TextColor3 = self.Style.error
        end
        return false
    end
    self.KeyVerified = true
    self.KeySessionToken = result.sessionToken
    self.SavedKey = key
    local storage = gateValues()
    if type(writefile) == "function" then
        pcall(writefile, storage, key)
    end
    if self.KeySystemStatus then
        self.KeySystemStatus.Text = "Access granted"
        self.KeySystemStatus.TextColor3 = STACY_GREEN
    end
    self.KeySystemKeyBox:ReleaseFocus()
    self.KeySystem.Visible = false
    if self.IsGakuranGame and not self.UseLegacyTo then
        self:_notifyGakuranToOverride()
    end
    self:_startVerifiedConsole()
    self:_startKeyValidation()
    return true
end

function StacyUI:_startKeyValidation()
    if self.KeyValidationStarted or not self.KeySessionToken or not self.SavedKey then
        return
    end
    self.KeyValidationStarted = true
    task.spawn(function()
        while not self.Destroyed and self.KeyVerified do
            task.wait(5 * 60)
            if self.Destroyed or not self.KeyVerified then
                break
            end
            local valid = keyRequest("/v1/validate", {
                sessionToken = self.KeySessionToken,
                deviceId = deviceId(),
            })
            if not valid then
                local renewed, result = activateKey(self.SavedKey)
                if renewed then
                    self.KeySessionToken = result.sessionToken
                else
                    self.KeyVerified = false
                    self:ShowKeySystem()
                    if self.KeySystemStatus then
                        self.KeySystemStatus.Text = tostring(result)
                        self.KeySystemStatus.TextColor3 = self.Style.error
                    end
                    break
                end
            end
        end
    end)
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
    self:HideGames(false)
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
            if command and self.CommandFocusActive and not self.Destroyed then
                self.CommandFocusActive = false
                self.CommandFocusSession = self.CommandFocusSession + 1
                if not self.CommandBrowser.Visible and not self.UpdateLog.Visible and not self.Settings.Visible and not self.Games.Visible and not self.GameDetail.Visible and not self.KeySystem.Visible then
                    self:Toggle(false)
                end
            end
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
    self:HideGames(false)
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
        if self.Settings.Visible or self.CommandBrowser.Visible or self.UpdateLog.Visible or self.Games.Visible or self.GameDetail.Visible then
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
        if UserInputService.TouchEnabled then
            self:_applyResponsiveLayout()
            self.Main.GroupTransparency = 0
        elseif self.OpenFromIntro then
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
        self:HideGames(false)
        self.Prompt:ReleaseFocus()
        if UserInputService.TouchEnabled then
            self.Main.Visible = false
        else
            TweenService:Create(self.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0, 20),
            }):Play()
            task.delay(0.2, function()
                if not self.Destroyed and not self.Open then
                    self.Main.Visible = false
                end
            end)
        end
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
