local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local StacyUI = {}
StacyUI.__index = StacyUI
StacyUI.Version = "1.0.0"

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

local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

function StacyUI.new(options)
    options = options or {}

    local self = setmetatable({}, StacyUI)
    self.Player = options.Player or Players.LocalPlayer
    assert(self.Player, "StacyUI requires a LocalPlayer or options Player")

    self.Style = mergeStyle(options.Style)
    self.Commands = {}
    self.History = {}
    self.HistoryIndex = 0
    self.SelectedSuggestionIndex = 0
    self.SuggestionButtons = {}
    self.Connections = {}
    self.Open = false
    self.Destroyed = false
    self.ToggleKey = options.ToggleKey or Enum.KeyCode.Period
    self.ActionName = "StacyUIToggle_" .. tostring(self):gsub("[^%w]", "")
    self.Prefix = options.Prefix or (self.Player.Name .. "@StacyUI$ ")

    self:_build(options)
    self:SetToggleKey(self.ToggleKey)

    if options.Visible == true then
        self:Toggle(true)
    end

    return self
end

function StacyUI:_connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self.Connections, connection)
    return connection
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

    self.Main = create("Frame", {
        Name = "Console",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 40),
        Size = UDim2.fromOffset(style.width, style.height),
        BackgroundColor3 = style.background,
        BackgroundTransparency = style.transparency,
        BorderSizePixel = 0,
        Visible = false,
    }, self.Gui)

    self.Scroll = create("ScrollingFrame", {
        Name = "Log",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, -40),
        Position = UDim2.fromOffset(10, 10),
        CanvasSize = UDim2.new(),
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, self.Main)

    self.LogLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
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

    self:_connect(self.PrefixLabel:GetPropertyChangedSignal("TextBounds"), function()
        self:_updatePromptBounds()
    end)

    self:_connect(self.LogLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        self:_updateCanvas()
    end)

    self:_connect(self.Prompt.FocusLost, function(enterPressed)
        self:_onFocusLost(enterPressed)
    end)

    self:_connect(self.Prompt.InputBegan, function(input)
        self:_onPromptInput(input)
    end)

    self:_connect(self.Prompt:GetPropertyChangedSignal("Text"), function()
        self:_updateSuggestions()
    end)
end

function StacyUI:_buildSuggestions()
    local style = self.Style

    self.Suggestions = create("Frame", {
        Name = "Suggestions",
        BackgroundTransparency = 0.1,
        BackgroundColor3 = style.suggestionBackground,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 1, 6),
        Size = UDim2.new(0, 300, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, self.Main)

    create("UICorner", { CornerRadius = UDim.new(0, 6) }, self.Suggestions)
    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, self.Suggestions)
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    }, self.Suggestions)

    self.Description = create("TextLabel", {
        Name = "Description",
        BackgroundTransparency = 1,
        Font = style.fontSans,
        TextSize = 14,
        TextColor3 = style.text,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
    }, self.Suggestions)

    create("Frame", {
        Name = "Divider",
        BackgroundColor3 = style.divider,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        LayoutOrder = 2,
    }, self.Suggestions)

    self.SuggestionList = create("Frame", {
        Name = "List",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3,
    }, self.Suggestions)

    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    }, self.SuggestionList)
end

function StacyUI:_updatePromptBounds()
    local offset = 10 + self.PrefixLabel.TextBounds.X + 8
    self.Prompt.Position = UDim2.new(0, offset, 1, -28)
    self.Prompt.Size = UDim2.new(1, -(offset + 10), 0, 24)
    if self.Suggestions then
        self.Suggestions.Position = UDim2.new(0, offset, 1, 6)
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
    local button = create("TextButton", {
        Name = name,
        AutoButtonColor = false,
        BackgroundColor3 = self.Style.suggestionHighlight,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = self.Style.fontMono,
        Text = name,
        TextColor3 = self.Style.text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 22),
    }, self.SuggestionList)

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
        old.BackgroundTransparency = 1
        old.TextColor3 = self.Style.text
    end

    self.SelectedSuggestionIndex = ((self.SelectedSuggestionIndex - 1 + delta) % count) + 1
    local current = self.SuggestionButtons[self.SelectedSuggestionIndex]
    current.BackgroundTransparency = 0.7
    current.TextColor3 = self.Style.accent

    local command = self.Commands[current.Text]
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
    if input.KeyCode == Enum.KeyCode.Tab and self.Suggestions.Visible then
        local selected = self.SuggestionButtons[self.SelectedSuggestionIndex]
        if selected then
            self.Prompt.Text = selected.Text .. " "
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
        self.Prompt.Text = ""
        if line ~= "" then
            self:Log(self.Prefix .. line, self.Style.accent)
            table.insert(self.History, 1, line)
            self.HistoryIndex = 0
            self:Execute(line)
        end
        if self.Open then
            task.defer(self.Prompt.CaptureFocus, self.Prompt)
        end
    elseif self.Open then
        self:Toggle(false)
    end
end

function StacyUI:Register(definition)
    assert(type(definition) == "table", "Register expects a command definition")
    assert(type(definition.Name) == "string" and definition.Name ~= "", "command Name is required")
    assert(type(definition.Callback) == "function", "command Callback is required")

    self.Commands[definition.Name] = {
        Description = definition.Description or "No description available",
        Callback = definition.Callback,
    }
    return self
end

function StacyUI:Unregister(name)
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

    local holder = create("Frame", {
        Name = "Entry",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, self.Scroll)

    create("TextLabel", {
        Name = "Message",
        BackgroundTransparency = 1,
        Font = self.Style.fontMono,
        TextSize = 15,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = color or self.Style.text,
        Size = UDim2.new(1, -60, 0, 0),
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
        if child ~= self.LogLayout then
            child:Destroy()
        end
    end
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
    self.ToggleKey = keyCode
    ContextActionService:BindAction(self.ActionName, function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            self:Toggle()
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end, false, keyCode)
    return self
end

function StacyUI:Toggle(forceState)
    assert(not self.Destroyed, "StacyUI has been destroyed")
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
        self.Main.Position = UDim2.new(0.5, 0, 0, 20)
        TweenService:Create(self.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0, 40),
        }):Play()
        task.defer(self.Prompt.CaptureFocus, self.Prompt)
    else
        self:_clearSuggestions()
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
    self.Destroyed = true
    ContextActionService:UnbindAction(self.ActionName)
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    table.clear(self.Connections)
    self.Gui:Destroy()
end

return StacyUI
