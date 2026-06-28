-- ImGui Roblox UI Library
-- Recreating the Dear ImGui interface in Roblox Luau

local ImGui = {}
ImGui.__index = ImGui

-- Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Theme Configuration (Classic Dear ImGui Theme)
local Theme = {
    WindowBg = Color3.fromRGB(23, 23, 28),         -- Dark charcoal panel background
    WindowBorder = Color3.fromRGB(45, 45, 50),     -- Thin borders
    
    TitleBg = Color3.fromRGB(41, 74, 122),          -- Classic ImGui active title bar blue
    TitleBgCollapsed = Color3.fromRGB(30, 30, 35),
    
    TabBg = Color3.fromRGB(30, 30, 35),
    TabActive = Color3.fromRGB(41, 74, 122),
    TabHovered = Color3.fromRGB(50, 50, 55),
    
    FrameBg = Color3.fromRGB(15, 15, 15),          -- Textbox/checkbox background
    FrameBgHovered = Color3.fromRGB(25, 25, 30),
    FrameBgActive = Color3.fromRGB(35, 35, 40),
    
    ButtonBg = Color3.fromRGB(41, 74, 122),
    ButtonBgHovered = Color3.fromRGB(51, 84, 132),
    ButtonBgActive = Color3.fromRGB(31, 64, 112),
    
    SliderBg = Color3.fromRGB(41, 74, 122),
    SliderBgHovered = Color3.fromRGB(51, 84, 132),
    
    TextColor = Color3.fromRGB(240, 240, 240),
    TextDisabled = Color3.fromRGB(150, 150, 150),
    
    Font = Enum.Font.Code,                          -- Monospace font for authentic look
    TextSize = 13,
    
    HeaderBg = Color3.fromRGB(35, 40, 50),          -- Section header background
    HeaderHovered = Color3.fromRGB(45, 50, 60),
}

-- Utility: Safe parenting for exploit environments
local function ParentGui(gui)
    local success, gethui = pcall(function() return gethui() end)
    if success and gethui then
        gui.Parent = gethui
        return
    end
    
    local success2, syn = pcall(function() return syn end)
    if success2 and syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    end
    
    local success3, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if success3 and coreGui then
        gui.Parent = coreGui
    else
        gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- Utility: Make UI elements draggable
local function MakeDraggable(dragFrame, dragHandle)
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        dragFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = dragFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Create Main Window
function ImGui.new(title)
    local self = setmetatable({}, ImGui)
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DearImGui_Roblox"
    screenGui.ResetOnSpawn = false
    ParentGui(screenGui)
    
    self.ScreenGui = screenGui
    self.Tabs = {}
    self.ActiveTab = nil
    self.Collapsed = false
    
    -- Main Window Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.new(0, 500, 0, 380)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -190)
    mainFrame.BackgroundColor3 = Theme.WindowBg
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Theme.WindowBorder
    mainFrame.Parent = screenGui
    self.MainFrame = mainFrame
    
    -- Add subtle border shadow
    local borderShadow = Instance.new("UIStroke")
    borderShadow.Color = Color3.fromRGB(0, 0, 0)
    borderShadow.Thickness = 1
    borderShadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    borderShadow.Parent = mainFrame
    
    -- Title Bar
    local titleBar = Instance.new("TextButton")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 22)
    titleBar.BackgroundColor3 = Theme.TitleBg
    titleBar.BorderSizePixel = 0
    titleBar.Text = ""
    titleBar.AutoButtonColor = false
    titleBar.Parent = mainFrame
    self.TitleBar = titleBar
    
    -- Title Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 24, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Theme.Font
    titleLabel.TextSize = Theme.TextSize
    titleLabel.TextColor3 = Theme.TextColor
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = title
    titleLabel.Parent = titleBar
    
    -- Collapse Arrow Button
    local collapseArrow = Instance.new("TextButton")
    collapseArrow.Name = "CollapseButton"
    collapseArrow.Size = UDim2.new(0, 20, 0, 20)
    collapseArrow.Position = UDim2.new(0, 2, 0, 1)
    collapseArrow.BackgroundTransparency = 1
    collapseArrow.Font = Theme.Font
    collapseArrow.TextSize = Theme.TextSize + 2
    collapseArrow.TextColor3 = Theme.TextColor
    collapseArrow.Text = "▼"
    collapseArrow.Parent = titleBar
    self.CollapseArrow = collapseArrow
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -22, 0, 1)
    closeButton.BackgroundTransparency = 1
    closeButton.Font = Theme.Font
    closeButton.TextSize = Theme.TextSize + 1
    closeButton.TextColor3 = Theme.TextColor
    closeButton.Text = "X"
    closeButton.Parent = titleBar
    
    -- Set up window drag
    MakeDraggable(mainFrame, titleBar)
    
    -- Content Container (Holds Tabs & Options)
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -10, 1, -55)
    contentContainer.Position = UDim2.new(0, 5, 0, 50)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame
    self.ContentContainer = contentContainer
    
    -- Tab Selection Bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, -10, 0, 22)
    tabBar.Position = UDim2.new(0, 5, 0, 25)
    tabBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    tabBar.BorderSizePixel = 1
    tabBar.BorderColor3 = Theme.WindowBorder
    tabBar.Parent = mainFrame
    self.TabBar = tabBar
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = tabBar
    
    -- Window Collapse Functionality
    local originalSize = mainFrame.Size
    collapseArrow.MouseButton1Click:Connect(function()
        self.Collapsed = not self.Collapsed
        if self.Collapsed then
            collapseArrow.Text = "►"
            titleBar.BackgroundColor3 = Theme.TitleBgCollapsed
            contentContainer.Visible = false
            tabBar.Visible = false
            mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 22)
        else
            collapseArrow.Text = "▼"
            titleBar.BackgroundColor3 = Theme.TitleBg
            contentContainer.Visible = true
            tabBar.Visible = true
            mainFrame.Size = originalSize
        end
    end)
    
    -- Window Close Functionality
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Keyboard toggle key support (Insert key by default)
    self.ToggleConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.Insert then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)
    
    return self
end

-- Create Tab
function ImGui:CreateTab(name)
    local tab = {}
    tab.Name = name
    tab.Window = self
    
    -- Tab Header Button
    local tabButton = Instance.new("TextButton")
    tabButton.Name = name .. "_Tab"
    tabButton.Size = UDim2.new(0, 75, 1, -2)
    tabButton.Position = UDim2.new(0, 0, 0, 1)
    tabButton.BackgroundColor3 = Theme.TabBg
    tabButton.BorderSizePixel = 0
    tabButton.Font = Theme.Font
    tabButton.TextSize = Theme.TextSize
    tabButton.TextColor3 = Theme.TextColor
    tabButton.Text = name
    tabButton.Parent = self.TabBar
    
    -- Tab View Panel (Holds widgets)
    local tabView = Instance.new("ScrollingFrame")
    tabView.Name = name .. "_View"
    tabView.Size = UDim2.new(1, 0, 1, 0)
    tabView.BackgroundTransparency = 1
    tabView.BorderSizePixel = 0
    tabView.ScrollBarThickness = 4
    tabView.ScrollBarImageColor3 = Theme.TitleBg
    tabView.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabView.AutomaticSize = Enum.AutomaticSize.Y
    tabView.Visible = false
    tabView.Parent = self.ContentContainer
    tab.View = tabView
    
    local viewLayout = Instance.new("UIListLayout")
    viewLayout.SortOrder = Enum.SortOrder.LayoutOrder
    viewLayout.Padding = UDim.new(0, 6)
    viewLayout.Parent = tabView
    
    local viewPadding = Instance.new("UIPadding")
    viewPadding.PaddingLeft = UDim.new(0, 4)
    viewPadding.PaddingRight = UDim.new(0, 8)
    viewPadding.PaddingTop = UDim.new(0, 4)
    viewPadding.PaddingBottom = UDim.new(0, 4)
    viewPadding.Parent = tabView
    
    -- Auto-adjust tab width based on text length
    local textWidth = game:GetService("TextService"):GetTextSize(name, Theme.TextSize, Theme.Font, Vector2.new(1000, 1000)).X
    tabButton.Size = UDim2.new(0, textWidth + 16, 1, -2)
    
    -- Switch Tab Logic
    local function selectTab()
        for _, otherTab in ipairs(self.Tabs) do
            otherTab.View.Visible = false
            otherTab.Button.BackgroundColor3 = Theme.TabBg
        end
        tabView.Visible = true
        tabButton.BackgroundColor3 = Theme.TabActive
        self.ActiveTab = tab
    end
    
    tabButton.MouseButton1Click:Connect(selectTab)
    
    -- Hover effect
    tabButton.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tabButton.BackgroundColor3 = Theme.TabHovered
        end
    end)
    tabButton.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tabButton.BackgroundColor3 = Theme.TabBg
        end
    end)
    
    tab.Button = tabButton
    table.insert(self.Tabs, tab)
    
    -- Select first tab automatically
    if #self.Tabs == 1 then
        selectTab()
    end
    
    -- Add widget components to tab
    setupContainerMethods(tab, tabView)
    
    return tab
end

-- Shared Widget Creator Setup
function setupContainerMethods(container, parentFrame)
    
    -- 1. Create Collapsible Section
    function container:CreateSection(name)
        local section = {}
        section.Expanded = true
        
        -- Header Bar
        local headerFrame = Instance.new("TextButton")
        headerFrame.Name = name .. "_Header"
        headerFrame.Size = UDim2.new(1, 0, 0, 20)
        headerFrame.BackgroundColor3 = Theme.HeaderBg
        headerFrame.BorderSizePixel = 0
        headerFrame.AutoButtonColor = false
        headerFrame.Parent = parentFrame
        
        local arrowLabel = Instance.new("TextLabel")
        arrowLabel.Name = "Arrow"
        arrowLabel.Size = UDim2.new(0, 20, 1, 0)
        arrowLabel.BackgroundTransparency = 1
        arrowLabel.Font = Theme.Font
        arrowLabel.TextSize = Theme.TextSize + 2
        arrowLabel.TextColor3 = Theme.TextColor
        arrowLabel.Text = "▼"
        arrowLabel.Parent = headerFrame
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(1, -20, 1, 0)
        titleLabel.Position = UDim2.new(0, 20, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Theme.Font
        titleLabel.TextSize = Theme.TextSize
        titleLabel.TextColor3 = Theme.TextColor
        titleLabel.Text = name
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = headerFrame
        
        -- Section Content Container
        local content = Instance.new("Frame")
        content.Name = name .. "_SectionContent"
        content.Size = UDim2.new(1, 0, 0, 0)
        content.BackgroundTransparency = 1
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.Parent = parentFrame
        
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 5)
        contentLayout.Parent = content
        
        local contentPadding = Instance.new("UIPadding")
        contentPadding.PaddingLeft = UDim.new(0, 10)  -- Indent section elements
        contentPadding.PaddingTop = UDim.new(0, 4)
        contentPadding.PaddingBottom = UDim.new(0, 4)
        contentPadding.Parent = content
        
        -- Toggle collapse action
        headerFrame.MouseButton1Click:Connect(function()
            section.Expanded = not section.Expanded
            if section.Expanded then
                arrowLabel.Text = "▼"
                content.Visible = true
            else
                arrowLabel.Text = "►"
                content.Visible = false
            end
        end)
        
        -- Hover effects
        headerFrame.MouseEnter:Connect(function()
            headerFrame.BackgroundColor3 = Theme.HeaderHovered
        end)
        headerFrame.MouseLeave:Connect(function()
            headerFrame.BackgroundColor3 = Theme.HeaderBg
        end)
        
        setupContainerMethods(section, content)
        return section
    end
    
    -- 2. Create Label
    function container:CreateLabel(text)
        local labelFrame = Instance.new("Frame")
        labelFrame.Size = UDim2.new(1, 0, 0, 16)
        labelFrame.BackgroundTransparency = 1
        labelFrame.Parent = parentFrame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Theme.Font
        label.TextSize = Theme.TextSize
        label.TextColor3 = Theme.TextColor
        label.Text = text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = labelFrame
        
        local methods = {}
        function methods:SetText(newText)
            label.Text = newText
        end
        function methods:SetColor(color)
            label.TextColor3 = color
        end
        return methods
    end
    
    -- 3. Create Button
    function container:CreateButton(text, callback)
        local buttonFrame = Instance.new("Frame")
        buttonFrame.Size = UDim2.new(1, 0, 0, 22)
        buttonFrame.BackgroundTransparency = 1
        buttonFrame.Parent = parentFrame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 120, 1, 0) -- Classic ImGui fixed-ish width button, or scalable
        btn.BackgroundColor3 = Theme.ButtonBg
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Theme.WindowBorder
        btn.Font = Theme.Font
        btn.TextSize = Theme.TextSize
        btn.TextColor3 = Theme.TextColor
        btn.Text = text
        btn.Parent = buttonFrame
        
        -- Handle size dynamically if text is long
        local textWidth = game:GetService("TextService"):GetTextSize(text, Theme.TextSize, Theme.Font, Vector2.new(1000, 1000)).X
        btn.Size = UDim2.new(0, math.max(80, textWidth + 20), 1, 0)
        
        btn.MouseButton1Click:Connect(function()
            pcall(callback)
        end)
        
        -- Hover/Press logic
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Theme.ButtonBgHovered
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Theme.ButtonBg
        end)
        btn.MouseButton1Down:Connect(function()
            btn.BackgroundColor3 = Theme.ButtonBgActive
        end)
        btn.MouseButton1Up:Connect(function()
            btn.BackgroundColor3 = Theme.ButtonBgHovered
        end)
        
        local methods = {}
        function methods:SetText(newText)
            btn.Text = newText
            local newWidth = game:GetService("TextService"):GetTextSize(newText, Theme.TextSize, Theme.Font, Vector2.new(1000, 1000)).X
            btn.Size = UDim2.new(0, math.max(80, newWidth + 20), 1, 0)
        end
        return methods
    end
    
    -- 4. Create Toggle (Checkbox)
    function container:CreateToggle(text, default, callback)
        local toggleFrame = Instance.new("TextButton")
        toggleFrame.Size = UDim2.new(1, 0, 0, 20)
        toggleFrame.BackgroundTransparency = 1
        toggleFrame.Text = ""
        toggleFrame.Parent = parentFrame
        
        local state = default or false
        
        -- Checkbox frame
        local box = Instance.new("Frame")
        box.Size = UDim2.new(0, 14, 0, 14)
        box.Position = UDim2.new(0, 0, 0.5, -7)
        box.BackgroundColor3 = state and Theme.SliderBg or Theme.FrameBg
        box.BorderSizePixel = 1
        box.BorderColor3 = Theme.WindowBorder
        box.Parent = toggleFrame
        
        -- Check indicator (visual check)
        local check = Instance.new("TextLabel")
        check.Size = UDim2.new(1, 0, 1, 0)
        check.BackgroundTransparency = 1
        check.Font = Theme.Font
        check.TextSize = Theme.TextSize + 2
        check.TextColor3 = Theme.TextColor
        check.Text = state and "✓" or ""
        check.Parent = box
        
        -- Toggle Text Label
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, 20, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Theme.Font
        label.TextSize = Theme.TextSize
        label.TextColor3 = Theme.TextColor
        label.Text = text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = toggleFrame
        
        local function toggle()
            state = not state
            check.Text = state and "✓" or ""
            box.BackgroundColor3 = state and Theme.SliderBg or Theme.FrameBg
            pcall(callback, state)
        end
        
        toggleFrame.MouseButton1Click:Connect(toggle)
        
        -- Hover effects
        toggleFrame.MouseEnter:Connect(function()
            box.BackgroundColor3 = state and Theme.SliderBgHovered or Theme.FrameBgHovered
        end)
        toggleFrame.MouseLeave:Connect(function()
            box.BackgroundColor3 = state and Theme.SliderBg or Theme.FrameBg
        end)
        
        local methods = {}
        function methods:SetState(newState)
            state = newState
            check.Text = state and "✓" or ""
            box.BackgroundColor3 = state and Theme.SliderBg or Theme.FrameBg
            pcall(callback, state)
        end
        function methods:GetState()
            return state
        end
        return methods
    end
    
    -- 5. Create Slider
    function container:CreateSlider(text, min, max, default, callback)
        local sliderContainer = Instance.new("Frame")
        sliderContainer.Size = UDim2.new(1, 0, 0, 20)
        sliderContainer.BackgroundTransparency = 1
        sliderContainer.Parent = parentFrame
        
        local value = math.clamp(default or min, min, max)
        
        -- Slider Bar Background
        local sliderBar = Instance.new("TextButton")
        sliderBar.Name = "SliderBar"
        sliderBar.Size = UDim2.new(0, 150, 1, -4)
        sliderBar.Position = UDim2.new(0, 0, 0, 2)
        sliderBar.BackgroundColor3 = Theme.FrameBg
        sliderBar.BorderSizePixel = 1
        sliderBar.BorderColor3 = Theme.WindowBorder
        sliderBar.Text = ""
        sliderBar.AutoButtonColor = false
        sliderBar.Parent = sliderContainer
        
        -- Slider Fill Area (Visual representation of progress)
        local sliderFill = Instance.new("Frame")
        sliderFill.Name = "SliderFill"
        sliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        sliderFill.BackgroundColor3 = Theme.SliderBg
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBar
        
        -- Numeric Value Label inside the Slider Bar
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(1, 0, 1, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Font = Theme.Font
        valueLabel.TextSize = Theme.TextSize - 1
        valueLabel.TextColor3 = Theme.TextColor
        valueLabel.Text = string.format("%.3f", value)
        valueLabel.Parent = sliderBar
        
        -- Parameter Label to the right of the Slider
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -165, 1, 0)
        label.Position = UDim2.new(0, 160, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Theme.Font
        label.TextSize = Theme.TextSize
        label.TextColor3 = Theme.TextColor
        label.Text = text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = sliderContainer
        
        -- Handle dragging
        local isAdjusting = false
        
        local function updateValue(inputPos)
            local barAbsPos = sliderBar.AbsolutePosition
            local barAbsSize = sliderBar.AbsoluteSize
            local relativeX = inputPos.X - barAbsPos.X
            local percentage = math.clamp(relativeX / barAbsSize.X, 0, 1)
            
            value = min + (max - min) * percentage
            sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
            valueLabel.Text = string.format("%.3f", value)
            pcall(callback, value)
        end
        
        sliderBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isAdjusting = true
                updateValue(input.Position)
                
                local moveConnection
                local releaseConnection
                
                moveConnection = UserInputService.InputChanged:Connect(function(moveInput)
                    if isAdjusting and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                        updateValue(moveInput.Position)
                    end
                end)
                
                releaseConnection = UserInputService.InputEnded:Connect(function(releaseInput)
                    if releaseInput.UserInputType == Enum.UserInputType.MouseButton1 or releaseInput.UserInputType == Enum.UserInputType.Touch then
                        isAdjusting = false
                        if moveConnection then moveConnection:Disconnect() end
                        if releaseConnection then releaseConnection:Disconnect() end
                    end
                end)
            end
        end)
        
        -- Hover visual effects
        sliderBar.MouseEnter:Connect(function()
            sliderFill.BackgroundColor3 = Theme.SliderBgHovered
        end)
        sliderBar.MouseLeave:Connect(function()
            sliderFill.BackgroundColor3 = Theme.SliderBg
        end)
        
        local methods = {}
        function methods:SetValue(newVal)
            value = math.clamp(newVal, min, max)
            local pct = (value - min) / (max - min)
            sliderFill.Size = UDim2.new(pct, 0, 1, 0)
            valueLabel.Text = string.format("%.3f", value)
            pcall(callback, value)
        end
        function methods:GetValue()
            return value
        end
        return methods
    end
    
    -- 6. Create Dropdown
    function container:CreateDropdown(text, options, default, callback)
        local dropdownContainer = Instance.new("Frame")
        dropdownContainer.Size = UDim2.new(1, 0, 0, 20)
        dropdownContainer.BackgroundTransparency = 1
        dropdownContainer.Parent = parentFrame
        
        local currentSelection = default or options[1] or "None"
        
        -- Dropdown Box Button
        local dropdownBtn = Instance.new("TextButton")
        dropdownBtn.Name = "DropdownButton"
        dropdownBtn.Size = UDim2.new(0, 150, 1, -4)
        dropdownBtn.Position = UDim2.new(0, 0, 0, 2)
        dropdownBtn.BackgroundColor3 = Theme.FrameBg
        dropdownBtn.BorderSizePixel = 1
        dropdownBtn.BorderColor3 = Theme.WindowBorder
        dropdownBtn.Font = Theme.Font
        dropdownBtn.TextSize = Theme.TextSize
        dropdownBtn.TextColor3 = Theme.TextColor
        dropdownBtn.Text = " " .. currentSelection
        dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
        dropdownBtn.AutoButtonColor = false
        dropdownBtn.Parent = dropdownContainer
        
        -- Down Arrow indicator on far right of button
        local arrowLabel = Instance.new("TextLabel")
        arrowLabel.Size = UDim2.new(0, 20, 1, 0)
        arrowLabel.Position = UDim2.new(1, -20, 0, 0)
        arrowLabel.BackgroundTransparency = 1
        arrowLabel.Font = Theme.Font
        arrowLabel.TextSize = Theme.TextSize - 2
        arrowLabel.TextColor3 = Theme.TextDisabled
        arrowLabel.Text = "▼"
        arrowLabel.Parent = dropdownBtn
        
        -- Dropdown label text to the right
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -165, 1, 0)
        label.Position = UDim2.new(0, 160, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Theme.Font
        label.TextSize = Theme.TextSize
        label.TextColor3 = Theme.TextColor
        label.Text = text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = dropdownContainer
        
        -- Dropdown List Popup Frame (drawn directly on ScreenGui to avoid clipping)
        local popupFrame = Instance.new("Frame")
        popupFrame.Name = "DropdownPopup"
        popupFrame.Size = UDim2.new(0, 150, 0, 0)
        popupFrame.BackgroundColor3 = Theme.FrameBg
        popupFrame.BorderSizePixel = 1
        popupFrame.BorderColor3 = Theme.WindowBorder
        popupFrame.Visible = false
        popupFrame.ZIndex = 100 -- Ensure it renders above other elements
        
        -- Access root Window ScreenGui
        local rootScreenGui = parentFrame:FindFirstAncestorOfClass("ScreenGui")
        if rootScreenGui then
            popupFrame.Parent = rootScreenGui
        else
            popupFrame.Parent = parentFrame
        end
        
        local popupLayout = Instance.new("UIListLayout")
        popupLayout.SortOrder = Enum.SortOrder.LayoutOrder
        popupLayout.Parent = popupFrame
        
        local isOpen = false
        
        -- Populates dropdown options
        local function populateOptions()
            for _, child in ipairs(popupFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            local totalHeight = 0
            for i, option in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 20)
                optBtn.BackgroundColor3 = Theme.FrameBg
                optBtn.BorderSizePixel = 0
                optBtn.Font = Theme.Font
                optBtn.TextSize = Theme.TextSize
                optBtn.TextColor3 = option == currentSelection and Theme.TitleBg or Theme.TextColor
                optBtn.Text = " " .. option
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.ZIndex = 101
                optBtn.Parent = popupFrame
                
                totalHeight = totalHeight + 20
                
                optBtn.MouseButton1Click:Connect(function()
                    currentSelection = option
                    dropdownBtn.Text = " " .. option
                    pcall(callback, option)
                    
                    -- Close popup
                    isOpen = false
                    popupFrame.Visible = false
                end)
                
                -- Hover states inside dropdown
                optBtn.MouseEnter:Connect(function()
                    optBtn.BackgroundColor3 = Theme.TabHovered
                end)
                optBtn.MouseLeave:Connect(function()
                    optBtn.BackgroundColor3 = Theme.FrameBg
                end)
            end
            
            popupFrame.Size = UDim2.new(0, 150, 0, math.min(totalHeight, 200))
        end
        
        -- Toggle open/close popup
        dropdownBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            if isOpen then
                populateOptions()
                -- Dynamic positioning below the dropdown button
                popupFrame.Position = UDim2.new(0, dropdownBtn.AbsolutePosition.X, 0, dropdownBtn.AbsolutePosition.Y + dropdownBtn.AbsoluteSize.Y + 36) -- Add topbar inset adjustment
                popupFrame.Visible = true
            else
                popupFrame.Visible = false
            end
        end)
        
        -- Adjust positioning during frame updates to align with moving window
        local positionConnection
        positionConnection = RunService.RenderStepped:Connect(function()
            if not dropdownContainer.Parent then
                positionConnection:Disconnect()
                popupFrame:Destroy()
                return
            end
            if isOpen then
                popupFrame.Position = UDim2.new(0, dropdownBtn.AbsolutePosition.X, 0, dropdownBtn.AbsolutePosition.Y + dropdownBtn.AbsoluteSize.Y + 36)
            end
        end)
        
        -- Close dropdown on clicking elsewhere
        UserInputService.InputBegan:Connect(function(input)
            if isOpen and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                local mousePos = input.Position
                local popupPos = popupFrame.AbsolutePosition
                local popupSize = popupFrame.AbsoluteSize
                
                local insidePopup = mousePos.X >= popupPos.X and mousePos.X <= (popupPos.X + popupSize.X) and
                                    mousePos.Y >= (popupPos.Y + 36) and mousePos.Y <= (popupPos.Y + popupSize.Y + 36)
                                    
                local btnPos = dropdownBtn.AbsolutePosition
                local btnSize = dropdownBtn.AbsoluteSize
                local insideBtn = mousePos.X >= btnPos.X and mousePos.X <= (btnPos.X + btnSize.X) and
                                  mousePos.Y >= (btnPos.Y + 36) and mousePos.Y <= (btnPos.Y + btnSize.Y + 36)
                                  
                if not insidePopup and not insideBtn then
                    isOpen = false
                    popupFrame.Visible = false
                end
            end
        end)
        
        -- Hover effects
        dropdownBtn.MouseEnter:Connect(function()
            dropdownBtn.BackgroundColor3 = Theme.FrameBgHovered
        end)
        dropdownBtn.MouseLeave:Connect(function()
            dropdownBtn.BackgroundColor3 = Theme.FrameBg
        end)
        
        local methods = {}
        function methods:SetSelection(newSelection)
            currentSelection = newSelection
            dropdownBtn.Text = " " .. newSelection
            pcall(callback, newSelection)
        end
        function methods:Refresh(newOptions, selectDefault)
            options = newOptions
            if selectDefault then
                currentSelection = selectDefault
                dropdownBtn.Text = " " .. selectDefault
                pcall(callback, selectDefault)
            end
            if isOpen then
                populateOptions()
            end
        end
        return methods
    end
end

return ImGui
