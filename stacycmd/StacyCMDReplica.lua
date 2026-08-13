-- StacyCMDReplica.lua
-- Standalone StacyCMD-style mobile console. Only echo [text] is available.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local C = {
    Green = Color3.fromRGB(80, 255, 125),
    Dark = Color3.fromRGB(10, 13, 12),
    Panel = Color3.fromRGB(18, 23, 20),
    Text = Color3.fromRGB(232, 238, 233),
    Muted = Color3.fromRGB(139, 153, 143),
    Error = Color3.fromRGB(255, 113, 113),
}

local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = parent
    return object
end

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local StacyCMDReplica = {}
StacyCMDReplica.__index = StacyCMDReplica

function StacyCMDReplica.new(options)
    options = options or {}
    local self = setmetatable({}, StacyCMDReplica)
    self._connections = {}
    self._destroyed = false
    self._open = options.Visible ~= false

    local playerGui = (options.Player or Players.LocalPlayer):WaitForChild("PlayerGui")
    local name = options.Name or "StacyCMDReplica"
    local oldGui = playerGui:FindFirstChild(name)
    if oldGui then oldGui:Destroy() end
    self.Gui = create("ScreenGui", {
        Name = name, ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, playerGui)

    self.Console = create("Frame", {
        Name = "Console", AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 34), Size = UDim2.fromOffset(800, 330),
        BackgroundColor3 = C.Dark, BackgroundTransparency = 0.04,
        BorderSizePixel = 0, ClipsDescendants = true, Visible = self._open,
    }, self.Gui)
    create("UICorner", { CornerRadius = UDim.new(0, 8) }, self.Console)
    create("UIStroke", { Color = Color3.fromRGB(55, 75, 60), Thickness = 1 }, self.Console)

    local header = create("Frame", {
        Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.Panel,
        BorderSizePixel = 0,
    }, self.Console)
    create("Frame", { Size = UDim2.fromOffset(3, 38), BackgroundColor3 = C.Green, BorderSizePixel = 0 }, header)
    create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -160, 1, 0), Font = Enum.Font.Bodoni,
        RichText = true, Text = 'Stacy <font color="#50FF7D">CMD</font>',
        TextColor3 = C.Text, TextSize = 25, TextXAlignment = Enum.TextXAlignment.Left,
    }, header)
    create("TextLabel", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -52, 0, 10), Size = UDim2.fromOffset(82, 18),
        Font = Enum.Font.Code, Text = "ECHO ONLY", TextColor3 = C.Green,
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right,
    }, header)
    local close = create("TextButton", {
        Name = "Close", AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(28, 26),
        BackgroundColor3 = Color3.fromRGB(42, 47, 44), BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, Text = "X", TextColor3 = C.Text, TextSize = 13,
    }, header)
    create("UICorner", { CornerRadius = UDim.new(0, 6) }, close)

    self.Output = create("ScrollingFrame", {
        Name = "Output", Position = UDim2.fromOffset(10, 47),
        Size = UDim2.new(1, -20, 1, -83), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 5, ScrollBarImageColor3 = C.Green,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, self.Console)
    create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, self.Output)
    self.CommandBar = create("TextBox", {
        Name = "CommandBar", BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 1, -29), Size = UDim2.new(1, -20, 0, 23),
        ClearTextOnFocus = false, Font = Enum.Font.Code, PlaceholderText = "> echo [text]",
        PlaceholderColor3 = C.Muted, Text = "", TextColor3 = C.Text, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self.Console)

    self.MobileOpenButton = create("TextButton", {
        Name = "MobileOpen", AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(58, 58),
        BackgroundColor3 = Color3.fromRGB(55, 58, 57), BackgroundTransparency = 0.5,
        BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.Bodoni,
        Text = "Stacy", TextColor3 = Color3.fromRGB(235, 240, 236), TextSize = 14,
        Visible = UserInputService.TouchEnabled, Active = true, ZIndex = 100,
    }, self.Gui)
    create("UICorner", { CornerRadius = UDim.new(1, 0) }, self.MobileOpenButton)
    create("UIStroke", { Color = Color3.fromRGB(175, 180, 177), Transparency = 0.35, Thickness = 1 }, self.MobileOpenButton)

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(self._connections, connection)
    end
    local function focus()
        self._open = true
        self.Console.Visible = true
        task.defer(function() if self.CommandBar.Parent then self.CommandBar:CaptureFocus() end end)
    end
    self.FocusCommandBar = focus

    local dragging, dragInput, dragStart, startPosition = false, nil, nil, nil
    local holdToken = 0
    local function setDragStyle(active)
        dragging = active
        self.MobileOpenButton.BackgroundColor3 = active and Color3.fromRGB(35, 37, 36) or Color3.fromRGB(55, 58, 57)
        self.MobileOpenButton.BackgroundTransparency = active and 0.25 or 0.5
        self.MobileOpenButton.Text = active and "MOVE" or "Stacy"
        self.MobileOpenButton.TextColor3 = active and Color3.fromRGB(150, 255, 170) or Color3.fromRGB(235, 240, 236)
    end
    local function updateDrag(input)
        local delta = input.Position - dragStart
        self.MobileOpenButton.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
    connect(self.MobileOpenButton.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        holdToken += 1
        local token = holdToken
        dragInput, dragStart, startPosition = input, input.Position, self.MobileOpenButton.Position
        task.delay(1, function()
            if token == holdToken and dragInput == input and self.MobileOpenButton.Parent then setDragStyle(true) end
        end)
    end)
    connect(self.MobileOpenButton.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and dragInput then updateDrag(input) end
    end)
    connect(UserInputService.InputEnded, function(input)
        if not dragInput then return end
        holdToken += 1
        local moved = (input.Position - dragStart).Magnitude > 8
        if not dragging and not moved then focus() end
        if dragging then setDragStyle(false) end
        dragInput = nil
    end)
    connect(close.Activated, function() self._open = false; self.Console.Visible = false; self.CommandBar:ReleaseFocus() end)
    connect(self.CommandBar.FocusLost, function(enterPressed)
        if enterPressed then self:Execute(self.CommandBar.Text) end
    end)
    connect(UserInputService.InputBegan, function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.F1 then
            if self.Console.Visible then self._open = false; self.Console.Visible = false else focus() end
        end
    end)

    local function resize()
        if not UserInputService.TouchEnabled then
            self.Console.AnchorPoint = Vector2.new(0.5, 0.5)
            self.Console.Position = UDim2.fromScale(0.5, 0.5)
            self.Console.Size = UDim2.fromOffset(800, 330)
            return
        end
        local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(400, 700)
        self.Console.AnchorPoint = Vector2.new(0.5, 0)
        self.Console.Position = UDim2.new(0.5, 0, 0, 34)
        self.Console.Size = UDim2.new(1, -24, 0, math.clamp(viewport.Y - 110, 260, 430))
    end
    resize()
    if workspace.CurrentCamera then connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), resize) end
    self:Log('Stacy <font color="#50FF7D">CMD</font> ready. Only <font color="#50FF7D">echo [text]</font> is available.')
    return self
end

function StacyCMDReplica:_connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self._connections, connection)
    return connection
end

function StacyCMDReplica:Log(message, color)
    if self._destroyed then return end
    local line = create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Code, RichText = true, Text = tostring(message), TextColor3 = color or C.Text,
        TextSize = 15, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    }, self.Output)
    task.defer(function() if line.Parent then self.Output.CanvasPosition = Vector2.new(0, self.Output.AbsoluteCanvasSize.Y) end end)
end

function StacyCMDReplica:Execute(raw)
    raw = trim(raw)
    if raw == "" then return end
    self:Log('<font color="#50FF7D">&gt;</font> ' .. raw, C.Muted)
    local command, remainder = raw:match("^(%S+)%s*(.-)$")
    if command and command:lower() == "echo" then
        self:Log(remainder, C.Text)
    else
        self:Log("Unknown command. Available: echo [text]", C.Error)
    end
    self.CommandBar.Text = ""
end

function StacyCMDReplica:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, connection in ipairs(self._connections) do connection:Disconnect() end
    if self.Gui then self.Gui:Destroy() end
end

local env = getgenv()
if env.__STACY_CMD_REPLICA and type(env.__STACY_CMD_REPLICA.Destroy) == "function" then pcall(env.__STACY_CMD_REPLICA.Destroy, env.__STACY_CMD_REPLICA) end
local console = StacyCMDReplica.new()
env.__STACY_CMD_REPLICA = console
env.StacyCMDReplica = StacyCMDReplica
env.StacyCMDReplicaConsole = console
