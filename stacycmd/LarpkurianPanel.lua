local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local env = type(getgenv) == "function" and getgenv() or _G
local requestFunction = (syn and syn.request) or (http and http.request) or http_request or request
assert(type(requestFunction) == "function", "Larpkurian Panel requires an executor HTTP request API")

local VisualUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/x8lua/scripts/main/stacycmd/VisualCommandUI.lua?nocache=" .. tostring(tick()), false
))()
assert(VisualUI.LarPanelVersion == 2026101701, "LarPanel UI is outdated. Please run the latest loader again.")
if env.LarPanel then
    pcall(function() env.LarPanel:Destroy() end)
end
local stopped = false
local console
console = VisualUI:CreateWindow({
    Name = "LarPanel",
    IntroText = "LarPanel",
    IntroBlur = false,
    Theme = VisualUI.Themes.dark,
    Position = "bottom",
    Draggable = true,
    Prefix = ";",
    OnDestroy = function()
        stopped = true
        if env.LarPanel == console then env.LarPanel = nil end
    end,
})
env.LarPanel = console

local errors = {
    PANEL_ACCESS_DENIED = "This account is not authorized to use the Larpkurian Panel.",
    INVALID_SESSION = "Sign in to LarpKuran through StacyUI first.",
    BINDING_MISMATCH = "Sign in with the LarpKuran account belonging to this Roblox player.",
    SESSION_REVOKED = "Your session has expired or was revoked. Sign in again.",
    ACCESS_RESTRICTED = "Your LarpKuran account is not active.",
    NOT_LARPKURIAN = "This player is not an active authenticated Larpkurian in this server.",
    TARGET_UPDATE_REQUIRED = "This Larpkurian must reload the updated LarpKuran before bring can work.",
    BRING_COOLDOWN = "Wait a few seconds before sending another bring.",
    TARGET_BUSY = "A bring is already pending for this player.",
    CANNOT_BRING_SELF = "You cannot bring yourself.",
    COMMAND_NOT_FOUND = "The command expired or the server restarted. It is not confirmed.",
}
local function log(message, isError)
    if stopped then return end
    if isError then warn("[LarPanel] " .. message) else print("[LarPanel] " .. message) end
    task.spawn(function()
        if not stopped then console:CreateNotification(isError and "LarPanel | Error" or "LarPanel", message, 7) end
    end)
end
local function call(action, input)
    input = input or {}
    input.sessionToken = env.StacyCMDStartupToken or env.StacyKeyToken
    input.robloxUserId = tostring(player.UserId)
    input.jobId = tostring(game.JobId)
    if type(gethwid) == "function" then pcall(function() input.deviceId = gethwid() end) end
    if type(input.deviceId) ~= "string" or #input.deviceId < 6 then
        pcall(function() input.deviceId = game:GetService("RbxAnalyticsService"):GetClientId() end)
    end
    local ok, response = pcall(requestFunction, {
        Url = "https://api.x8stuff.lol/api/larpkuran/panel/" .. action,
        Method = "POST",
        Headers = {["Content-Type"]="application/json"},
        Body = HttpService:JSONEncode(input),
    })
    if not ok or type(response) ~= "table" then return nil, "Panel connection failed." end
    local decoded, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
    if not decoded or type(data) ~= "table" then return nil, "Invalid panel response (HTTP " .. tostring(response.StatusCode) .. ")." end
    if response.StatusCode < 200 or response.StatusCode >= 300 or data.ok ~= true then
        return nil, errors[data.code] or ("Panel request failed: " .. tostring(data.code or response.StatusCode))
    end
    return data
end
local function resolve(query)
    query = tostring(query or ""):lower():gsub("^@", "")
    if query == "" then return nil, "Usage: bring <username, display name or UserId>" end
    local exact, prefix = {}, {}
    for _, target in ipairs(Players:GetPlayers()) do
        local name, display = target.Name:lower(), target.DisplayName:lower()
        if name == query or tostring(target.UserId) == query then return target end
        if display == query then table.insert(exact, target)
        elseif name:sub(1, #query) == query or display:sub(1, #query) == query then table.insert(prefix, target) end
    end
    local matches = #exact > 0 and exact or prefix
    if #matches == 1 then return matches[1] end
    return nil, #matches > 1 and "Multiple players match. Use an exact username or UserId." or "Player not found in this server."
end
local bringing = false
console:AddCommand("bring", {"player"}, "Bring an updated Larpkurian to you", function(arguments)
        local target, why = resolve(table.concat(arguments, " "))
        if not target then log(why, true); return end
        if bringing then log("Wait for the current bring result.", true); return end
        bringing = true
        task.spawn(function()
            local ok, err = pcall(function()
                local result, failure = call("bring", {targetUserId=tostring(target.UserId)})
                if not result then log(failure, true); return end
                log("Bring queued for @" .. target.Name .. ". Waiting for their client...")
                local id = result.command.id
                for _ = 1, 23 do
                    task.wait(1)
                    if stopped then return end
                    local state, errorMessage = call("status", {commandId=id})
                    if not state then log(errorMessage, true); return end
                    local command = state.command
                    if command.status == "executed" then log("@" .. target.Name .. " confirmed arrival."); return end
                    if command.status == "failed" then log("Bring failed: " .. tostring(command.error), true); return end
                    if command.status == "expired" then break end
                end
                log("Bring timed out. Arrival was not confirmed.", true)
            end)
            bringing = false
            if not ok then log("Bring error: " .. tostring(err), true) end
        end)
    end)
console:AddCommand("players", {}, "List active Larpkurians in this server", function()
        local data, err = call("state")
        if not data then log(err, true); return end
        local count = 0
        for _, peer in ipairs(data.peers or {}) do
            if Players:GetPlayerByUserId(tonumber(peer.userId)) then
                count += 1
                log("@" .. peer.username .. (peer.anonymous and " [Anonymous]" or "") .. (peer.canBring and " [Bring ready]" or " [Update required]"))
            end
        end
        log(tostring(count) .. " active Larpkurian(s).")
    end)
console:AddCommand("help", {}, "Show panel commands", function()
    log("bring <username, display name or UserId>\nplayers\nhelp\nctrlc")
end)
console:AddCommand("ctrlc", {}, "Close LarPanel", function() console:Destroy() end)
console:Open()
task.spawn(function()
    local data, err = call("state")
    if data then log("Larpkurian Panel authorized.") else log(err, true) end
end)
return console
