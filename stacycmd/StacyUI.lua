local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local StacyUI = {}
StacyUI.__index = StacyUI
StacyUI.Version = "1.3.0"

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
    self.OnDestroy = options.OnDestroy
    self.ToggleKey = options.ToggleKey or Enum.KeyCode.F1
    self.ActionName = "StacyUIToggle_" .. tostring(self):gsub("[^%w]", "")
    self.Prefix = options.Prefix or (self.Player.Name .. "@StacyUI$ ")

    self:_build(options)
    self:SetToggleKey(self.ToggleKey)
    self:_registerBuiltIns()

    if options.Welcome ~= false then
        self:Log("StacyCMD v" .. StacyUI.Version .. "  READY", self.Style.info)
        self:Log("BUILTINS  help  clear  cmds  version  ctrlc", self.Style.muted)
    end

    if options.Visible == true then
        self:Toggle(true)
    end

    return self
end

function StacyUI:_registerBuiltIns()
    self.Commands.help = {
        Description = "List every available command",
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
        Protected = true,
        Callback = function(_, _, ui)
            ui:Clear()
        end,
    }
    self.Commands.version = {
        Description = "Show the StacyCMD version",
        Protected = true,
        Callback = function(_, _, ui)
            ui:Log("StacyCMD v" .. StacyUI.Version, ui.Style.accent)
        end,
    }
    self.Commands.cmds = {
        Description = "Open the searchable command browser",
        Protected = true,
        Callback = function(_, _, ui)
            ui:ShowCommands()
        end,
    }
    self.Commands.ctrlc = {
        Description = "Destroy the entire script and UI",
        Protected = true,
        Callback = function(_, _, ui)
            ui:Destroy()
        end,
    }
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

    create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Font = style.fontSans,
        TextSize = 18,
        TextColor3 = style.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(16, 5),
        Size = UDim2.new(0, 130, 0, 26),
        Text = "StacyCMD",
    }, self.Header)

    create("TextLabel", {
        Name = "Version",
        BackgroundTransparency = 1,
        Font = style.fontMono,
        TextSize = 12,
        TextColor3 = style.accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(104, 8),
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

    create("TextLabel", {
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
        if input.KeyCode == Enum.KeyCode.Escape then
            self:HideCommands()
        end
    end)
    self:_connect(self.CommandBrowserLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        self.CommandBrowserList.CanvasSize = UDim2.new(0, 0, 0, self.CommandBrowserLayout.AbsoluteContentSize.Y + 6)
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
    for name in pairs(self.Commands) do
        if query == "" or name:lower():find(query, 1, true) then
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
            Size = UDim2.new(1, -4, 0, 42),
            ZIndex = 22,
        }, self.CommandBrowserList)
        create("UICorner", { CornerRadius = UDim.new(0, 4) }, row)
        create("TextLabel", {
            Name = "Name",
            BackgroundTransparency = 1,
            Font = self.Style.fontMono,
            Text = name,
            TextColor3 = self.Style.accent,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(10, 4),
            Size = UDim2.new(1, -20, 0, 17),
            ZIndex = 23,
        }, row)
        create("TextLabel", {
            Name = "Description",
            BackgroundTransparency = 1,
            Font = self.Style.fontSans,
            Text = command.Description,
            TextColor3 = self.Style.muted,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(10, 21),
            Size = UDim2.new(1, -20, 0, 15),
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
    self.CommandBrowserSearch.Text = ""
    self:_refreshCommandBrowser()
    self.CommandBrowser.Visible = true
    self.CommandBrowserSearch:CaptureFocus()
    return self
end

function StacyUI:HideCommands()
    if self.CommandBrowser then
        self.CommandBrowser.Visible = false
    end
    if not self.Destroyed and self.Open then
        task.defer(self.Prompt.CaptureFocus, self.Prompt)
    end
    return self
end

function StacyUI:_buildSuggestions()
    local style = self.Style

    self.Suggestions = create("Frame", {
        Name = "Suggestions",
        BackgroundTransparency = 0.04,
        BackgroundColor3 = style.suggestionBackground,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 1, 6),
        Size = UDim2.new(0, 288, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Visible = false,
    }, self.Main)

    create("UICorner", { CornerRadius = UDim.new(0, 5) }, self.Suggestions)
    create("UIStroke", {
        Color = style.divider,
        Transparency = 0.15,
        Thickness = 1,
    }, self.Suggestions)
    create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
    }, self.Suggestions)
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, self.Suggestions)

    self.Description = create("TextLabel", {
        Name = "Description",
        BackgroundTransparency = 1,
        Font = style.fontMono,
        TextSize = 12,
        TextColor3 = style.muted,
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
        Padding = UDim.new(0, 3),
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
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 26),
    }, self.SuggestionList)

    create("UICorner", { CornerRadius = UDim.new(0, 4) }, button)
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 8),
    }, button)
    create("Frame", {
        Name = "SelectionBar",
        BackgroundColor3 = self.Style.accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(-10, 4),
        Size = UDim2.new(0, 2, 1, -8),
        Visible = false,
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
        old.BackgroundTransparency = 1
        old.TextColor3 = self.Style.text
        old.SelectionBar.Visible = false
    end

    self.SelectedSuggestionIndex = ((self.SelectedSuggestionIndex - 1 + delta) % count) + 1
    local current = self.SuggestionButtons[self.SelectedSuggestionIndex]
    current.BackgroundTransparency = 0.35
    current.TextColor3 = self.Style.accent
    current.SelectionBar.Visible = true

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
        if not self.Destroyed and self.Open and not self.CommandBrowser.Visible then
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
    assert(not (self.Commands[definition.Name] and self.Commands[definition.Name].Protected), "cannot replace a built in command")

    self.Commands[definition.Name] = {
        Description = definition.Description or "No description available",
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
    self.ToggleKey = keyCode
    if self.KeyHint then
        self.KeyHint.Text = keyCode.Name .. "  TOGGLE"
    end
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
        self:HideCommands()
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
    self.Open = false
    ContextActionService:UnbindAction(self.ActionName)
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    table.clear(self.Connections)
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
