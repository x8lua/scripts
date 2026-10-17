local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local env = type(getgenv) == "function" and getgenv() or _G
local requestFunction = (syn and syn.request) or (http and http.request) or http_request or request
assert(type(requestFunction) == "function", "Larpkurian Panel requires an executor HTTP request API")

local VisualUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/x8lua/Roblox/54e360bcfb5842f36498554e105faccf4ab701ff/UI-Libraries/Visual%20Command%20UI%20Library/Source.lua?nocache=" .. tostring(tick()), false
))()
assert(VisualUI.LarPanelVersion == 2026101702, "LarPanel UI is outdated. Please run the latest loader again.")
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
        return nil, errors[data.code] or ("Panel request failed: " .. tostring(data.code or response.StatusCode)), data.code
    end
    return data
end
local function resolve(query)
    query = tostring(query or ""):lower():gsub("^@", "")
    if query == "" then return nil, "Usage: bring <username, display name, UserId or all>" end
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
local function roster()
    local data, err = call("state")
    if not data then return nil, err end
    local result, seen = {}, {}
    for _, peer in ipairs(data.peers or {}) do
        local userId = tonumber(peer.userId)
        local target = userId and Players:GetPlayerByUserId(userId)
        if target and not seen[userId] then
            seen[userId] = true
            table.insert(result, {player=target, peer=peer})
        end
    end
    table.sort(result, function(a, b) return a.player.Name:lower() < b.player.Name:lower() end)
    return result
end
local authErrors = {PANEL_ACCESS_DENIED=true, INVALID_SESSION=true, BINDING_MISMATCH=true, SESSION_REVOKED=true, ACCESS_RESTRICTED=true}
local function bringOne(target)
    if stopped then return false end
    if Players:GetPlayerByUserId(target.UserId) ~= target then
        log("@" .. target.Name .. " left this server. Skipped.", true)
        return false
    end
    local result, failure, code = call("bring", {targetUserId=tostring(target.UserId)})
    if not result then log(failure, true); return false, code end
    log("Bring queued for @" .. target.Name .. ". Waiting for their client...")
    for _ = 1, 23 do
        task.wait(1)
        if stopped then return false end
        local state, errorMessage, statusCode = call("status", {commandId=result.command.id})
        if not state then log(errorMessage, true); return false, statusCode end
        local command = state.command
        if command.status == "executed" then log("@" .. target.Name .. " confirmed arrival."); return true end
        if command.status == "failed" then log("Bring failed for @" .. target.Name .. ": " .. tostring(command.error), true); return false end
        if command.status == "expired" then break end
    end
    log("Bring timed out for @" .. target.Name .. ". Arrival was not confirmed.", true)
    return false
end
local bringing = false
console:AddCommand("bring", {"player/all"}, "Bring one or all ready Larpkurians", function(arguments)
    if stopped then return end
    local query = table.concat(arguments, " "):match("^%s*(.-)%s*$")
    local all = query:lower() == "all"
    local target, why
    if not all then
        target, why = resolve(query)
        if not target then log(why, true); return end
    end
    if bringing then log("Wait for the current bring result.", true); return end
    bringing = true
    task.spawn(function()
        local ok, err = pcall(function()
            if not all then bringOne(target); return end
            local entries, failure = roster()
            if not entries then log(failure, true); return end
            if stopped then return end
            local targets, skipped = {}, 0
            for _, entry in ipairs(entries) do
                if entry.player.UserId ~= player.UserId then
                    if entry.peer.canBring == true then table.insert(targets, entry.player)
                    else skipped += 1 end
                end
            end
            if #targets == 0 then log("No other bring-ready Larpkurians in this server."); return end
            log("Bring all: " .. #targets .. " ready; " .. skipped .. " need an update.")
            local confirmed, attempted = 0, 0
            for index, nextTarget in ipairs(targets) do
                -- The server limits each issuer to one bring every three seconds.
                if index > 1 then task.wait(3.1) end
                if stopped then return end
                attempted += 1
                local arrived, code = bringOne(nextTarget)
                if arrived then confirmed += 1 end
                if authErrors[code] then break end
            end
            if not stopped then
                log("Bring all: " .. confirmed .. "/" .. #targets .. " arrival(s) confirmed; " .. (attempted - confirmed) .. " failed/unconfirmed; " .. (#targets - attempted) .. " not attempted.")
            end
        end)
        bringing = false
        if not ok then log("Bring error: " .. tostring(err), true) end
    end)
end)
console:AddCommand("players", {}, "List exact Larpkurian accounts; optional page", function(arguments)
    if stopped then return end
    local page = tonumber(arguments and arguments[1] or "1")
    if not page or page < 1 or page % 1 ~= 0 then log("Usage: players [page number]", true); return end
    local entries, failure = roster()
    if not entries then log(failure, true); return end
    local pages = math.max(1, math.ceil(#entries / 5))
    if page > pages then log("Page out of range. Available pages: 1-" .. pages, true); return end
    local lines = {#entries .. " active Larpkurian(s) | Page " .. page .. "/" .. pages}
    for index = (page - 1) * 5 + 1, math.min(page * 5, #entries) do
        local entry = entries[index]
        local target, peer = entry.player, entry.peer
        table.insert(lines, "@" .. target.Name .. " | " .. target.DisplayName .. "\nUserId: " .. target.UserId .. (target.UserId == player.UserId and " [You]" or "") .. (peer.anonymous and " [Anonymous]" or "") .. (peer.canBring == true and " [Bring ready]" or " [Update required]"))
    end
    log(table.concat(lines, "\n"))
end)
console:AddCommand("help", {}, "Show panel commands", function()
    log("bring <username, display name, UserId or all>\nplayers [page]\nhelp\nctrlc")
end)
console:AddCommand("ctrlc", {}, "Close LarPanel", function() console:Destroy() end)
console:Open()
task.spawn(function()
    local data, err = call("state")
    if data then log("Larpkurian Panel authorized.") else log(err, true) end
end)
return console
