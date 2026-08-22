local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local requestFn = request or http_request or (syn and syn.request)
assert(type(requestFn) == "function", "HTTP requests are unavailable")
assert(type(writefile) == "function", "writefile is unavailable")

local ROOT = "forvids/sfx/mafioso"
local RAW = "https://raw.githubusercontent.com/x8lua/scripts/main/mafioso/"
local files = {
    { name = "bunny.wav", path = ROOT .. "/bunny.wav" },
    { name = "hit.wav", path = ROOT .. "/hit.wav" },
    { name = "intro.wav", path = ROOT .. "/intro.wav" },
    { name = "miss.wav", path = ROOT .. "/miss.wav" },
    { name = "pain.wav", path = ROOT .. "/pain.wav" },
    { name = "kill/1.wav", path = ROOT .. "/kill/1.wav" },
    { name = "kill/2.wav", path = ROOT .. "/kill/2.wav" },
    { name = "kill/3.wav", path = ROOT .. "/kill/3.wav" },
    { name = "minion/1.wav", path = ROOT .. "/minion/1.wav" },
    { name = "minion/2.wav", path = ROOT .. "/minion/2.wav" },
    { name = "minion/3.wav", path = ROOT .. "/minion/3.wav" },
}

if type(makefolder) == "function" then
    pcall(makefolder, "forvids")
    pcall(makefolder, "forvids/sfx")
    pcall(makefolder, ROOT)
    pcall(makefolder, ROOT .. "/kill")
    pcall(makefolder, ROOT .. "/minion")
end

local old = CoreGui:FindFirstChild("MafiosoDownloader")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "MafiosoDownloader"
gui.ResetOnSpawn = false
gui.Parent = type(gethui) == "function" and gethui() or CoreGui

local panel = Instance.new("Frame")
panel.Parent = gui
panel.AnchorPoint = Vector2.new(.5, .5)
panel.Position = UDim2.fromScale(.5, .5)
panel.Size = UDim2.fromOffset(430, 205)
panel.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
panel.BorderSizePixel = 0
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(58, 64, 74)

local function label(text, pos, size, color, font)
    local l = Instance.new("TextLabel")
    l.Parent = panel
    l.BackgroundTransparency = 1
    l.Position = pos
    l.Size = size
    l.Text = text
    l.TextColor3 = color
    l.Font = font or Enum.Font.Gotham
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

label("MAFIOSO SFX", UDim2.fromOffset(22, 18), UDim2.fromOffset(300, 24), Color3.fromRGB(255, 203, 92), Enum.Font.GothamBold)
local detail = label("Preparing download...", UDim2.fromOffset(22, 52), UDim2.fromOffset(380, 22), Color3.fromRGB(170, 178, 190))
local bytes = label("0 B / 0 B", UDim2.fromOffset(22, 78), UDim2.fromOffset(380, 20), Color3.fromRGB(125, 134, 148))
local track = Instance.new("Frame")
track.Parent = panel
track.Position = UDim2.fromOffset(22, 112)
track.Size = UDim2.fromOffset(386, 10)
track.BackgroundColor3 = Color3.fromRGB(42, 47, 56)
track.BorderSizePixel = 0
Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
local fill = Instance.new("Frame")
fill.Parent = track
fill.Size = UDim2.new(0, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(255, 203, 92)
fill.BorderSizePixel = 0
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
local percent = label("0%", UDim2.fromOffset(22, 132), UDim2.fromOffset(386, 22), Color3.fromRGB(230, 235, 242), Enum.Font.GothamBold)
local status = label("Starting...", UDim2.fromOffset(22, 164), UDim2.fromOffset(386, 22), Color3.fromRGB(125, 134, 148))

local function formatBytes(value)
    if value < 1024 then return string.format("%d B", value) end
    if value < 1024 * 1024 then return string.format("%.1f KB", value / 1024) end
    return string.format("%.2f MB", value / (1024 * 1024))
end

local function download(file)
    local response = requestFn({ Url = RAW .. file.name, Method = "GET" })
    if not response or response.StatusCode < 200 or response.StatusCode >= 300 then
        error("Download failed: " .. file.name)
    end
    local body = response.Body or ""
    writefile(file.path, body)
    return #body
end

task.spawn(function()
    local totalBytes, downloadedBytes = 0, 0
    for _, file in ipairs(files) do
        detail.Text = "Reading " .. file.name
        local ok, response = pcall(requestFn, { Url = RAW .. file.name, Method = "GET" })
        if not ok or not response or response.StatusCode < 200 or response.StatusCode >= 300 then
            status.Text = "Failed: " .. file.name
            status.TextColor3 = Color3.fromRGB(255, 110, 120)
            return
        end
        local body = response.Body or ""
        totalBytes += #body
        writefile(file.path, body)
        downloadedBytes += #body
        local progress = table.find(files, file) / #files
        TweenService:Create(fill, TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromScale(progress, 1) }):Play()
        percent.Text = string.format("%d%%", math.floor(progress * 100 + .5))
        bytes.Text = string.format("%s downloaded · %d/%d files", formatBytes(downloadedBytes), table.find(files, file), #files)
        status.Text = "Saved to workspace/" .. file.path
        task.wait(.08)
    end
    fill.Size = UDim2.fromScale(1, 1)
    percent.Text = "100%"
    detail.Text = "Download complete"
    bytes.Text = formatBytes(downloadedBytes) .. " total"
    status.Text = "Saved 11 files to workspace/" .. ROOT
    task.wait(2.5)
    gui:Destroy()
end)
