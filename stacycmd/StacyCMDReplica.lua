-- StacyCMDReplica.lua
-- Standalone, mobile-ready StacyCMD-style console. The only command is: echo [text]
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local StacyCMDReplica = {}
StacyCMDReplica.__index = StacyCMDReplica

local STACY_GREEN = Color3.fromRGB(80, 255, 125)
local DARK = Color3.fromRGB(10, 13, 12)
local PANEL = Color3.fromRGB(17, 22, 19)
local TEXT = Color3.fromRGB(232, 238, 233)
local MUTED = Color3.fromRGB(139, 153, 143)
local ERROR = Color3.fromRGB(255, 113, 113)

local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do object[property] = value end
    object.Parent = parent
    return object
end

local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

function StacyCMDReplica.new(options)
    options = options or {}
    local self = setmetatable({}, StacyCMDReplica)
    self._connections = {}
    self._open = options.Visible ~= false
    self._destroyed = false

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = create("ScreenGui", {Name = options.Name or "StacyCMDReplica", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, playerGui)
    self.Console = create("Frame", {Name = "Console", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(800, 330), BackgroundColor3 = DARK, BackgroundTransparency = 0.04, BorderSizePixel = 0, Visible = self._open, ClipsDescendants = true}, self.Gui)
    create("UICorner", {CornerRadius = UDim.new(0, 12)}, self.Console)
    create("UIStroke", {Color = Color3.fromRGB(54, 72, 59), Thickness = 1}, self.Console)

    local header = create("Frame", {Name = "Header", Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = PANEL, BorderSizePixel = 0}, self.Console)
    create("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Color3.fromRGB(51, 64, 55), BorderSizePixel = 0}, header)
    create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(17, 0), Size = UDim2.new(1, -140, 1, 0), Font = Enum.Font.Bodoni, RichText = true, Text = "Stacy <font color="#50FF7D">CMD</font>", TextColor3 = TEXT, TextSize = 27, TextXAlignment = Enum.TextXAlignment.Left}, header)
    create("TextLabel", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -54, 0.5, 0), Size = UDim2.fromOffset(78, 22), Font = Enum.Font.GothamMedium, Text = "ECHO ONLY", TextColor3 = STACY_GREEN, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right}, header)
    local close = create("TextButton", {Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Color3.fromRGB(40, 47, 43), BorderSizePixel = 0, Font = Enum.Font.GothamBold, Text = "×", TextColor3 = TEXT, TextSize = 21}, header)
    create("UICorner", {CornerRadius = UDim.new(0, 7)}, close)

    self.Output = create("ScrollingFrame", {Name = "Output", Position = UDim2.fromOffset(14, 57), Size = UDim2.new(1, -28, 1, -112), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = STACY_GREEN, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, self.Console)
    create("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, self.Output)
    create("UIPadding", {PaddingBottom = UDim.new(0, 4)}, self.Output)
    local prompt = create("Frame", {Position = UDim2.new(0, 14, 1, -45), Size = UDim2.new(1, -28, 0, 32), BackgroundColor3 = Color3.fromRGB(27, 34, 29), BorderSizePixel = 0}, self.Console)
    create("UICorner", {CornerRadius = UDim.new(0, 8)}, prompt)
    create("UIStroke", {Color = Color3.fromRGB(48, 69, 53), Thickness = 1}, prompt)
    create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(25, 32), Font = Enum.Font.Code, Text = ">", TextColor3 = STACY_GREEN, TextSize = 19}, prompt)
    self.CommandBar = create("TextBox", {Name = "CommandBar", BackgroundTransparency = 1, Position = UDim2.fromOffset(37, 0), Size = UDim2.new(1, -47, 1, 0), ClearTextOnFocus = false, Font = Enum.Font.Code, PlaceholderText = "echo [text]", PlaceholderColor3 = MUTED, Text = "", TextColor3 = TEXT, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left}, prompt)

    self.MobileOpenButton = create("TextButton", {Name = "MobileOpen", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(54, 54), BackgroundColor3 = STACY_GREEN, BorderSizePixel = 0, Font = Enum.Font.Bodoni, Text = "CMD", TextColor3 = Color3.fromRGB(8, 12, 8), TextSize = 16, Visible = UserInputService.TouchEnabled, ZIndex = 100}, self.Gui)
    create("UICorner", {CornerRadius = UDim.new(1, 0)}, self.MobileOpenButton)

    local function resize()
        if UserInputService.TouchEnabled then
            local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(400, 700)
            self.Console.AnchorPoint = Vector2.new(0.5, 0)
            self.Console.Position = UDim2.new(0.5, 0, 0, 48)
            self.Console.Size = UDim2.new(1, -24, 0, math.max(260, math.min(390, viewport.Y - 80)))
        else
            self.Console.AnchorPoint = Vector2.new(0.5, 0.5)
            self.Console.Position = UDim2.fromScale(0.5, 0.5)
            self.Console.Size = UDim2.fromOffset(800, 330)
        end
    end
    resize()
    if workspace.CurrentCamera then self:_connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), resize) end
    self:_connect(close.MouseButton1Click, function() self:Toggle(false) end)
    self:_connect(self.MobileOpenButton.MouseButton1Click, function() self:FocusCommandBar() end)
    self:_connect(self.CommandBar.FocusLost, function(enterPressed) if enterPressed then self:Execute(self.CommandBar.Text) end end)
    self:_connect(UserInputService.InputBegan, function(input, processed) if not processed and input.KeyCode == Enum.KeyCode.F1 then self:Toggle() end end)
    self:Log("StacyCMD replica loaded. Only <font color="#50FF7D">echo [text]</font> is available.")
    return self
end

function StacyCMDReplica:_connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self._connections, connection)
    return connection
end

function StacyCMDReplica:Log(message, color)
    if self._destroyed then return end
    local line = create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Code, RichText = true, Text = tostring(message), TextColor3 = color or TEXT, TextSize = 15, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, self.Output)
    task.defer(function() if line.Parent then self.Output.CanvasPosition = Vector2.new(0, math.max(0, self.Output.AbsoluteCanvasSize.Y)) end end)
end

function StacyCMDReplica:Execute(raw)
    raw = trim(tostring(raw or ""))
    if raw == "" then return end
    self:Log("<font color="#50FF7D">&gt;</font> " .. raw, MUTED)
    local command, remainder = raw:match("^(%S+)%s*(.-)$")
    command = command:lower()
    if command == "echo" then self:Log(remainder, TEXT) else self:Log("Unknown command: " .. command .. ". Available: echo [text]", ERROR) end
    self.CommandBar.Text = ""
end

function StacyCMDReplica:Toggle(forceState)
    if self._destroyed then return end
    self._open = forceState == nil and not self._open or forceState
    self.Console.Visible = self._open
    if self._open then self:FocusCommandBar() end
end

function StacyCMDReplica:FocusCommandBar()
    if self._destroyed then return end
    if not self._open then self._open, self.Console.Visible = true, true end
    task.defer(function() if self.CommandBar and self.CommandBar.Parent then self.CommandBar:CaptureFocus() end end)
end

function StacyCMDReplica:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, connection in ipairs(self._connections) do connection:Disconnect() end
    self.Gui:Destroy()
end

return StacyCMDReplica
