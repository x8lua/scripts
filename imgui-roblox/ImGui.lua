-- xGui Roblox UI Library
-- A Dear ImGui-style interface for Roblox exploits

local xGui = {}
xGui.__index = xGui
xGui.Version = "1.6.0"

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
    
    Font = Enum.Font.Code,
    TextSize = 13,
    FontFace = nil,  -- set below after table closes

    HeaderBg = Color3.fromRGB(35, 40, 50),
    HeaderHovered = Color3.fromRGB(45, 50, 60),
}

-- Load ProggyClean.ttf via the font-family JSON trick.
-- getcustomasset() only returns an rbxasset:// path; Font.new() requires a
-- font-family JSON that references that path — so we generate one on the fly.
do
    local ok, face = pcall(function()
        local ttfPath  = "ProggyClean.ttf"
        local jsonPath = "ProggyClean_Family.json"

        -- Download TTF if not cached locally
        if not isfile(ttfPath) then
            writefile(ttfPath,
                game:HttpGet("https://raw.githubusercontent.com/x8lua/scripts/main/ProggyClean.ttf", true))
        end

        local ttfAsset = getcustomasset(ttfPath)

        -- Write the font-family descriptor JSON
        local json = '{"name":"ProggyClean","faces":[{"name":"Regular","weight":400,"style":"normal","assetId":"'
                     .. ttfAsset .. '"}]}'
        writefile(jsonPath, json)

        local jsonAsset = getcustomasset(jsonPath)
        return Font.new(jsonAsset, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end)
    if ok and face then
        Theme.FontFace = face
    end
end

-- Helper: apply the correct font to any text GuiObject.
-- Uses FontFace (custom TTF) when loaded, otherwise falls back to Enum.Font.Code.
-- Wrapped in pcall so a bad font never crashes the whole UI.
local function applyFont(obj)
    if Theme.FontFace then
        local ok = pcall(function() obj.FontFace = Theme.FontFace end)
        if not ok then
            pcall(function() obj.Font = Enum.Font.Code end)
        end
    else
        pcall(function() obj.Font = Enum.Font.Code end)
    end
end

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
function xGui.new(title, toggleKey)
    local self = setmetatable({}, xGui)
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DearImGui_Roblox"
    screenGui.ResetOnSpawn = false
    ParentGui(screenGui)
    
    self.ScreenGui = screenGui
    self.Tabs = {}
    self.ActiveTab = nil
    self.Collapsed = false
    self.Visible = true
    self.WindowSize = UDim2.new(0, 500, 0, 380)
    
    self.ToggleKey = Enum.KeyCode.Insert
    if toggleKey then
        if typeof(toggleKey) == "string" then
            pcall(function() self.ToggleKey = Enum.KeyCode[toggleKey] end)
        elseif typeof(toggleKey) == "EnumItem" then
            self.ToggleKey = toggleKey
        end
    end
    
    -- CanvasGroup wrapper — lets us tween the entire window's transparency at once
    local cg = Instance.new("CanvasGroup")
    cg.Name = "xGui_CanvasGroup"
    cg.Size = self.WindowSize
    cg.Position = UDim2.new(0.5, -250, 0.5, -190)
    cg.BackgroundTransparency = 1
    cg.GroupTransparency = 1
    cg.Parent = screenGui
    self.CanvasGroup = cg

    -- Main Window Frame (fills the CanvasGroup)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Theme.WindowBg
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Theme.WindowBorder
    mainFrame.Parent = cg
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
    applyFont(titleLabel)
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
    applyFont(collapseArrow)
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
    applyFont(closeButton)
    closeButton.TextSize = Theme.TextSize + 1
    closeButton.TextColor3 = Theme.TextColor
    closeButton.Text = "X"
    closeButton.Parent = titleBar
    
    -- Set up window drag (drags the CanvasGroup!)
    MakeDraggable(cg, titleBar)
    
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
    collapseArrow.MouseButton1Click:Connect(function()
        self.Collapsed = not self.Collapsed
        if self.Collapsed then
            collapseArrow.Text = "►"
            titleBar.BackgroundColor3 = Theme.TitleBgCollapsed
            contentContainer.Visible = false
            tabBar.Visible = false
            cg.Size = UDim2.new(0, cg.Size.X.Offset, 0, 22)
        else
            collapseArrow.Text = "▼"
            titleBar.BackgroundColor3 = Theme.TitleBg
            contentContainer.Visible = true
            tabBar.Visible = true
            cg.Size = self.WindowSize
        end
    end)
    
    -- Window Close Functionality (with smooth outro)
    closeButton.MouseButton1Click:Connect(function()
        local outroInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        local targetSize = self.WindowSize
        local outroSize = UDim2.new(0, targetSize.X.Offset * 0.85, 0, targetSize.Y.Offset * 0.85)
        local tw = TweenService:Create(cg, outroInfo, {
            GroupTransparency = 1,
            Size = outroSize
        })
        tw:Play()
        tw.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)
    
    -- Keyboard toggle key support (customizable, defaults to Insert)
    self.ToggleConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == self.ToggleKey then
            self.Visible = not self.Visible
            if not self.Visible then
                -- Outro animation
                local targetSize = self.WindowSize
                local outroSize = UDim2.new(0, targetSize.X.Offset * 0.85, 0, targetSize.Y.Offset * 0.85)
                local outroInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                local t = TweenService:Create(cg, outroInfo, {
                    GroupTransparency = 1,
                    Size = outroSize
                })
                t:Play()
                t.Completed:Connect(function()
                    if not self.Visible then
                        cg.Visible = false
                    end
                end)
            else
                -- Intro animation
                cg.Visible = true
                cg.GroupTransparency = 1
                local targetSize = self.WindowSize
                local startSize = UDim2.new(0, targetSize.X.Offset * 0.85, 0, targetSize.Y.Offset * 0.85)
                cg.Size = startSize
                
                local introInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                TweenService:Create(cg, introInfo, {
                    GroupTransparency = 0,
                    Size = targetSize
                }):Play()
            end
        end
    end)

    -- ── Resize Handles ──────────────────────────────────────────────────
    local MIN_W, MIN_H = 300, 200
    local MAX_W, MAX_H = 900, 700

    local function makeResizeHandle(anchorX, anchorY, cursorX, cursorY, applyW, applyH)
        local handle = Instance.new("TextButton")
        handle.Size   = UDim2.new(0, 8, 0, 8)
        handle.AnchorPoint = Vector2.new(anchorX, anchorY)
        handle.Position    = UDim2.new(anchorX, 0, anchorY, 0)
        handle.BackgroundTransparency = 1
        handle.Text = ""
        handle.ZIndex = 10
        handle.Parent = mainFrame

        -- Corner indicators (tiny squares)
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 4, 0, 4)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.new(0.5, 0, 0.5, 0)
        dot.BackgroundColor3 = Theme.WindowBorder
        dot.BorderSizePixel = 0
        dot.Parent = handle

        local resizing   = false
        local resizeStart, startSize, startPos

        handle.InputBegan:Connect(function(inp)
            if self.Collapsed then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing    = true
                resizeStart = inp.Position
                startSize   = cg.Size
                startPos    = cg.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(inp)
            if resizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local dx = inp.Position.X - resizeStart.X
                local dy = inp.Position.Y - resizeStart.Y
                
                local newW = startSize.X.Offset
                local newH = startSize.Y.Offset
                
                if applyW then
                    if anchorX == 0 then
                        newW = math.clamp(startSize.X.Offset - dx, MIN_W, MAX_W)
                    else
                        newW = math.clamp(startSize.X.Offset + dx, MIN_W, MAX_W)
                    end
                end
                
                if applyH then
                    if anchorY == 0 then
                        newH = math.clamp(startSize.Y.Offset - dy, MIN_H, MAX_H)
                    else
                        newH = math.clamp(startSize.Y.Offset + dy, MIN_H, MAX_H)
                    end
                end
                
                cg.Size = UDim2.new(0, newW, 0, newH)
                self.WindowSize = cg.Size
                
                local newX = startPos.X.Offset
                local newY = startPos.Y.Offset
                
                if applyW and anchorX == 0 then
                    local actualDiffX = newW - startSize.X.Offset
                    newX = startPos.X.Offset - actualDiffX
                end
                
                if applyH and anchorY == 0 then
                    local actualDiffY = newH - startSize.Y.Offset
                    newY = startPos.Y.Offset - actualDiffY
                end
                
                cg.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
            end
        end)

        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end)

        handle.MouseEnter:Connect(function() dot.BackgroundColor3 = Theme.TitleBg end)
        handle.MouseLeave:Connect(function() dot.BackgroundColor3 = Theme.WindowBorder end)
    end

    -- 4 corners
    makeResizeHandle(0, 0, 0, 0,  true,  true)  -- NW
    makeResizeHandle(1, 0, 1, 0,  true,  true)  -- NE
    makeResizeHandle(0, 1, 0, 1,  true,  true)  -- SW
    makeResizeHandle(1, 1, 1, 1,  true,  true)  -- SE  (main grip)
    -- 4 edges
    makeResizeHandle(0.5, 0, 0.5, 0,  false, true)  -- N
    makeResizeHandle(0.5, 1, 0.5, 1,  false, true)  -- S
    makeResizeHandle(0, 0.5, 0, 0.5,  true, false)  -- W
    makeResizeHandle(1, 0.5, 1, 0.5,  true, false)  -- E

    -- ── Intro animation ─────────────────────────────────────────────────
    cg.GroupTransparency = 1
    local targetSize = self.WindowSize
    cg.Size = UDim2.new(0, targetSize.X.Offset * 0.85, 0, targetSize.Y.Offset * 0.85)
    task.defer(function()
        local introInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        TweenService:Create(cg, introInfo, {
            GroupTransparency = 0,
            Size = targetSize
        }):Play()
    end)

    -- Built-in Console Tab (layout separate, positioned at bottom-right corner)
    local consoleTab = self:CreateTab("Console")
    consoleTab.Button.Parent = mainFrame
    consoleTab.Button.Size = UDim2.new(0, 50, 0, 16)
    consoleTab.Button.Position = UDim2.new(1, -60, 1, -21)
    consoleTab.Button.BackgroundColor3 = Theme.TabBg
    consoleTab.Button.BorderSizePixel = 1
    consoleTab.Button.BorderColor3 = Theme.WindowBorder
    consoleTab.Button.Text = "Console"
    consoleTab.Button.TextColor3 = Color3.fromRGB(150, 150, 150)
    self.ConsoleTab = consoleTab
    self.ConsoleLogs = {}

    return self
end

-- Create Tab
function xGui:CreateTab(name)
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
    applyFont(tabButton)
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
    
    tab.Select = selectTab
    return tab
end

-- Built-in Console Log Writer
function xGui:AddLog(text, isError)
    table.insert(self.ConsoleLogs, {Text = text, IsError = isError})
    
    local logLabel = Instance.new("TextBox")
    logLabel.Size = UDim2.new(1, 0, 0, 0)
    logLabel.AutomaticSize = Enum.AutomaticSize.Y
    logLabel.BackgroundTransparency = 1
    applyFont(logLabel)
    logLabel.TextSize = Theme.TextSize - 1
    logLabel.TextColor3 = isError and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(220, 220, 220)
    local timeStr = os.date("%H:%M:%S")
    logLabel.Text = string.format("[%s] %s %s", timeStr, isError and "[Error]" or "[Log]", tostring(text))
    logLabel.TextXAlignment = Enum.TextXAlignment.Left
    logLabel.TextYAlignment = Enum.TextYAlignment.Top
    logLabel.TextWrapped = true
    logLabel.ClearTextOnFocus = false
    logLabel.TextEditable = false
    logLabel.Parent = self.ConsoleTab.View
end

-- Modal popup window for errors
function xGui:ShowErrorPopup(errorMessage)
    if self.MainFrame:FindFirstChild("ErrorPopup") then
        self.MainFrame.ErrorPopup:Destroy()
    end

    local popup = Instance.new("Frame")
    popup.Name = "ErrorPopup"
    popup.Size = UDim2.new(1, 0, 1, 0)
    popup.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    popup.BackgroundTransparency = 0.5
    popup.ZIndex = 500
    popup.Parent = self.MainFrame

    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(0, 320, 0, 140)
    dialog.Position = UDim2.new(0.5, -160, 0.5, -70)
    dialog.BackgroundColor3 = Theme.WindowBg
    dialog.BorderSizePixel = 1
    dialog.BorderColor3 = Color3.fromRGB(200, 50, 50)
    dialog.ZIndex = 501
    dialog.Parent = popup

    local dialogStroke = Instance.new("UIStroke")
    dialogStroke.Color = Color3.fromRGB(200, 50, 50)
    dialogStroke.Thickness = 1
    dialogStroke.Parent = dialog

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    title.BorderSizePixel = 0
    applyFont(title)
    title.TextSize = Theme.TextSize
    title.TextColor3 = Theme.TextColor
    title.Text = "  Oops!"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 502
    title.Parent = dialog

    local message = Instance.new("TextLabel")
    message.Size = UDim2.new(1, -20, 1, -64)
    message.Position = UDim2.new(0, 10, 0, 30)
    message.BackgroundTransparency = 1
    applyFont(message)
    message.TextSize = Theme.TextSize - 1
    message.TextColor3 = Color3.fromRGB(230, 230, 230)
    message.Text = errorMessage
    message.TextWrapped = true
    message.TextXAlignment = Enum.TextXAlignment.Center
    message.TextYAlignment = Enum.TextYAlignment.Center
    message.ZIndex = 502
    message.Parent = dialog

    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Size = UDim2.new(1, 0, 0, 24)
    buttonsFrame.Position = UDim2.new(0, 0, 1, -30)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.ZIndex = 502
    buttonsFrame.Parent = dialog

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, 15)
    layout.Parent = buttonsFrame

    local okBtn = Instance.new("TextButton")
    okBtn.Size = UDim2.new(0, 60, 1, 0)
    okBtn.BackgroundColor3 = Theme.ButtonBg
    okBtn.BorderSizePixel = 1
    okBtn.BorderColor3 = Theme.WindowBorder
    applyFont(okBtn)
    okBtn.TextSize = Theme.TextSize
    okBtn.TextColor3 = Theme.TextColor
    okBtn.Text = "Ok"
    okBtn.ZIndex = 503
    okBtn.Parent = buttonsFrame

    local checkBtn = Instance.new("TextButton")
    checkBtn.Size = UDim2.new(0, 60, 1, 0)
    checkBtn.BackgroundColor3 = Theme.ButtonBg
    checkBtn.BorderSizePixel = 1
    checkBtn.BorderColor3 = Theme.WindowBorder
    applyFont(checkBtn)
    checkBtn.TextSize = Theme.TextSize
    checkBtn.TextColor3 = Theme.TextColor
    checkBtn.Text = "Check"
    checkBtn.ZIndex = 503
    checkBtn.Parent = buttonsFrame

    okBtn.MouseButton1Click:Connect(function()
        popup:Destroy()
    end)

    checkBtn.MouseButton1Click:Connect(function()
        popup:Destroy()
        if self.ConsoleTab and self.ConsoleTab.Select then
            self.ConsoleTab.Select()
        end
    end)

    local function addHover(btn)
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Theme.ButtonBgHovered end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Theme.ButtonBg end)
    end
    addHover(okBtn)
    addHover(checkBtn)
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
        applyFont(arrowLabel)
        arrowLabel.TextSize = Theme.TextSize + 2
        arrowLabel.TextColor3 = Theme.TextColor
        arrowLabel.Text = "▼"
        arrowLabel.Parent = headerFrame
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(1, -20, 1, 0)
        titleLabel.Position = UDim2.new(0, 20, 0, 0)
        titleLabel.BackgroundTransparency = 1
        applyFont(titleLabel)
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
        applyFont(label)
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
        applyFont(btn)
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
        -- Update(props) — accepts {Text, Callback}
        function methods:Update(props)
            if props.Text then
                btn.Text = props.Text
                local newWidth = game:GetService("TextService"):GetTextSize(props.Text, Theme.TextSize, Theme.Font, Vector2.new(1000, 1000)).X
                btn.Size = UDim2.new(0, math.max(80, newWidth + 20), 1, 0)
            end
            if props.Callback then
                callback = props.Callback
            end
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
        applyFont(check)
        check.TextSize = Theme.TextSize + 2
        check.TextColor3 = Theme.TextColor
        check.Text = state and "✓" or ""
        check.Parent = box
        
        -- Toggle Text Label
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, 20, 0, 0)
        label.BackgroundTransparency = 1
        applyFont(label)
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
        -- Update(props) — accepts {Text, State, Callback}
        function methods:Update(props)
            if props.Text ~= nil then
                label.Text = props.Text
            end
            if props.State ~= nil then
                state = props.State
                check.Text = state and "✓" or ""
                box.BackgroundColor3 = state and Theme.SliderBg or Theme.FrameBg
            end
            if props.Callback then
                callback = props.Callback
            end
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
        applyFont(valueLabel)
        valueLabel.TextSize = Theme.TextSize - 1
        valueLabel.TextColor3 = Theme.TextColor
        valueLabel.Text = string.format("%.3f", value)
        valueLabel.Parent = sliderBar
        
        -- Parameter Label to the right of the Slider
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -165, 1, 0)
        label.Position = UDim2.new(0, 160, 0, 0)
        label.BackgroundTransparency = 1
        applyFont(label)
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
        applyFont(dropdownBtn)
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
        applyFont(arrowLabel)
        arrowLabel.TextSize = Theme.TextSize - 2
        arrowLabel.TextColor3 = Theme.TextDisabled
        arrowLabel.Text = "▼"
        arrowLabel.Parent = dropdownBtn
        
        -- Dropdown label text to the right
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -165, 1, 0)
        label.Position = UDim2.new(0, 160, 0, 0)
        label.BackgroundTransparency = 1
        applyFont(label)
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
                applyFont(optBtn)
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

    -- 7. Create Color Picker
    function container:CreateColorPicker(text, defaultColor, callback)
        local pickerContainer = Instance.new("Frame")
        pickerContainer.Name = text .. "_ColorPicker"
        pickerContainer.Size = UDim2.new(1, 0, 0, 20)
        pickerContainer.BackgroundTransparency = 1
        pickerContainer.AutomaticSize = Enum.AutomaticSize.Y
        pickerContainer.Parent = parentFrame
        
        local defaultColor = defaultColor or Color3.fromRGB(255, 255, 255)
        local H, S, V = Color3.toHSV(defaultColor)
        
        -- Closed/Header state elements
        local previewBtn = Instance.new("TextButton")
        previewBtn.Name = "PreviewButton"
        previewBtn.Size = UDim2.new(0, 36, 0, 14)
        previewBtn.Position = UDim2.new(0, 0, 0.5, -7)
        previewBtn.BackgroundColor3 = defaultColor
        previewBtn.BorderSizePixel = 1
        previewBtn.BorderColor3 = Theme.WindowBorder
        previewBtn.Text = ""
        previewBtn.AutoButtonColor = false
        previewBtn.Parent = pickerContainer
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -45, 1, 0)
        label.Position = UDim2.new(0, 42, 0, 0)
        label.BackgroundTransparency = 1
        applyFont(label)
        label.TextSize = Theme.TextSize
        label.TextColor3 = Theme.TextColor
        label.Text = text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = pickerContainer
        
        -- Expanded panel — parented to ScreenGui root to avoid clipping inside ScrollingFrame
        local pickerPanel = Instance.new("Frame")
        pickerPanel.Name = "PickerPanel"
        pickerPanel.Size = UDim2.new(0, 192, 0, 196)
        pickerPanel.Position = UDim2.new(0, 0, 0, 0) -- positioned dynamically via RenderStepped
        pickerPanel.BackgroundColor3 = Theme.WindowBg
        pickerPanel.BorderSizePixel = 1
        pickerPanel.BorderColor3 = Theme.WindowBorder
        pickerPanel.Visible = false
        pickerPanel.ZIndex = 200
        -- Reparent to ScreenGui root so it isn't clipped by any scroll frame
        local rootGui = parentFrame:FindFirstAncestorOfClass("ScreenGui")
        pickerPanel.Parent = rootGui or parentFrame
        
        -- Border shadow for the popup panel
        local panelStroke = Instance.new("UIStroke")
        panelStroke.Color = Color3.fromRGB(0, 0, 0)
        panelStroke.Thickness = 1
        panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        panelStroke.Parent = pickerPanel

        -- Saturation-Value Square
        local svSquare = Instance.new("TextButton")
        svSquare.Name = "SVSquare"
        svSquare.Size = UDim2.new(0, 120, 0, 120)
        svSquare.Position = UDim2.new(0, 6, 0, 6)
        svSquare.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
        svSquare.BorderSizePixel = 1
        svSquare.BorderColor3 = Theme.WindowBorder
        svSquare.Text = ""
        svSquare.AutoButtonColor = false
        svSquare.Parent = pickerPanel
        
        -- Saturation Gradient Overlay (White -> Transparent)
        local satOverlay = Instance.new("Frame")
        satOverlay.Size = UDim2.new(1, 0, 1, 0)
        satOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        satOverlay.BorderSizePixel = 0
        satOverlay.Parent = svSquare
        
        local satGradient = Instance.new("UIGradient")
        satGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        satGradient.Transparency = NumberSequence.new(0, 1)
        satGradient.Parent = satOverlay
        
        -- Value Gradient Overlay (Transparent -> Black)
        local valOverlay = Instance.new("Frame")
        valOverlay.Size = UDim2.new(1, 0, 1, 0)
        valOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        valOverlay.BorderSizePixel = 0
        valOverlay.Parent = svSquare
        
        local valGradient = Instance.new("UIGradient")
        valGradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
        valGradient.Rotation = 90
        valGradient.Transparency = NumberSequence.new(1, 0)
        valGradient.Parent = valOverlay
        
        -- SV Picker Cursor (Circle indicator)
        local svPointer = Instance.new("Frame")
        svPointer.Size = UDim2.new(0, 6, 0, 6)
        svPointer.AnchorPoint = Vector2.new(0.5, 0.5)
        svPointer.Position = UDim2.new(S, 0, 1 - V, 0)
        svPointer.BackgroundTransparency = 1
        svPointer.Parent = svSquare
        
        local svPointerStroke = Instance.new("UIStroke")
        svPointerStroke.Color = Color3.fromRGB(255, 255, 255)
        svPointerStroke.Thickness = 1
        svPointerStroke.Parent = svPointer
        
        local svPointerCorner = Instance.new("UICorner")
        svPointerCorner.CornerRadius = UDim.new(1, 0)
        svPointerCorner.Parent = svPointer

        -- Vertical Hue Slider (Rainbow)
        local hueSlider = Instance.new("TextButton")
        hueSlider.Name = "HueSlider"
        hueSlider.Size = UDim2.new(0, 16, 0, 120)
        hueSlider.Position = UDim2.new(0, 132, 0, 6)
        hueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        hueSlider.BorderSizePixel = 1
        hueSlider.BorderColor3 = Theme.WindowBorder
        hueSlider.Text = ""
        hueSlider.AutoButtonColor = false
        hueSlider.Parent = pickerPanel
        
        local hueGradient = Instance.new("UIGradient")
        hueGradient.Rotation = 90
        hueGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
            ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
            ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
        })
        hueGradient.Parent = hueSlider
        
        -- Hue Slider Pointer Indicator
        local huePointer = Instance.new("Frame")
        huePointer.Size = UDim2.new(1, 4, 0, 2)
        huePointer.AnchorPoint = Vector2.new(0.5, 0.5)
        huePointer.Position = UDim2.new(0.5, 0, H, 0)
        huePointer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        huePointer.BorderSizePixel = 0
        huePointer.Parent = hueSlider

        -- Large Color Preview Panel (Next to inputs)
        local largePreview = Instance.new("Frame")
        largePreview.Size = UDim2.new(0, 32, 0, 56)
        largePreview.Position = UDim2.new(0, 154, 0, 132)
        largePreview.BackgroundColor3 = defaultColor
        largePreview.BorderSizePixel = 1
        largePreview.BorderColor3 = Theme.WindowBorder
        largePreview.Parent = pickerPanel

        -- RGB value boxes
        local function createValueBox(name, x, y, width)
            local box = Instance.new("TextBox")
            box.Name = name
            box.Size = UDim2.new(0, width, 0, 16)
            box.Position = UDim2.new(0, x, 0, y)
            box.BackgroundColor3 = Theme.FrameBg
            box.BorderSizePixel = 1
            box.BorderColor3 = Theme.WindowBorder
            applyFont(box)
            box.TextSize = Theme.TextSize - 1
            box.TextColor3 = Theme.TextColor
            box.ClearTextOnFocus = false
            box.TextEditable = false
            box.Parent = pickerPanel
            return box
        end
        
        local rBox = createValueBox("R_Box", 6, 132, 46)
        local gBox = createValueBox("G_Box", 55, 132, 46)
        local bBox = createValueBox("B_Box", 104, 132, 46)
        
        local hBox = createValueBox("H_Box", 6, 152, 46)
        local sBox = createValueBox("S_Box", 55, 152, 46)
        local vBox = createValueBox("V_Box", 104, 152, 46)
        
        local hexBox = createValueBox("Hex_Box", 6, 172, 144)

        -- Update display values
        local function updateColor()
            local activeColor = Color3.fromHSV(H, S, V)
            previewBtn.BackgroundColor3 = activeColor
            largePreview.BackgroundColor3 = activeColor
            
            local rInt = math.round(activeColor.R * 255)
            local gInt = math.round(activeColor.G * 255)
            local bInt = math.round(activeColor.B * 255)
            
            rBox.Text = "R: " .. tostring(rInt)
            gBox.Text = "G: " .. tostring(gInt)
            bBox.Text = "B: " .. tostring(bInt)
            
            hBox.Text = string.format("H: %.2f", H)
            sBox.Text = string.format("S: %.2f", S)
            vBox.Text = string.format("V: %.2f", V)
            
            hexBox.Text = string.format("#%02X%02X%02X", rInt, gInt, bInt)
            
            pcall(callback, activeColor)
        end
        
        -- Initial UI population
        updateColor()

        -- Drag SV square
        local isDraggingSV = false
        local function dragSV(inputPos)
            local absPos = svSquare.AbsolutePosition
            local absSize = svSquare.AbsoluteSize
            local pctX = math.clamp((inputPos.X - absPos.X) / absSize.X, 0, 1)
            local pctY = math.clamp((inputPos.Y - absPos.Y) / absSize.Y, 0, 1)
            
            S = pctX
            V = 1 - pctY
            svPointer.Position = UDim2.new(S, 0, 1 - V, 0)
            updateColor()
        end
        
        svSquare.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDraggingSV = true
                dragSV(input.Position)
                
                local moveCon, releaseCon
                moveCon = UserInputService.InputChanged:Connect(function(moveInput)
                    if isDraggingSV and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                        dragSV(moveInput.Position)
                    end
                end)
                
                releaseCon = UserInputService.InputEnded:Connect(function(releaseInput)
                    if releaseInput.UserInputType == Enum.UserInputType.MouseButton1 or releaseInput.UserInputType == Enum.UserInputType.Touch then
                        isDraggingSV = false
                        if moveCon then moveCon:Disconnect() end
                        if releaseCon then releaseCon:Disconnect() end
                    end
                end)
            end
        end)

        -- Drag Hue Slider
        local isDraggingHue = false
        local function dragHue(inputPos)
            local absPos = hueSlider.AbsolutePosition
            local absSize = hueSlider.AbsoluteSize
            local pctY = math.clamp((inputPos.Y - absPos.Y) / absSize.Y, 0, 1)
            
            H = pctY
            huePointer.Position = UDim2.new(0.5, 0, H, 0)
            svSquare.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
            updateColor()
        end
        
        hueSlider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDraggingHue = true
                dragHue(input.Position)
                
                local moveCon, releaseCon
                moveCon = UserInputService.InputChanged:Connect(function(moveInput)
                    if isDraggingHue and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                        dragHue(moveInput.Position)
                    end
                end)
                
                releaseCon = UserInputService.InputEnded:Connect(function(releaseInput)
                    if releaseInput.UserInputType == Enum.UserInputType.MouseButton1 or releaseInput.UserInputType == Enum.UserInputType.Touch then
                        isDraggingHue = false
                        if moveCon then moveCon:Disconnect() end
                        if releaseCon then releaseCon:Disconnect() end
                    end
                end)
            end
        end)
        
        -- Track panel position via RenderStepped to follow window drag
        local guiService = game:GetService("GuiService")
        local posConn
        posConn = RunService.RenderStepped:Connect(function()
            if not pickerContainer.Parent then
                if posConn then
                    posConn:Disconnect()
                end
                pickerPanel:Destroy()
                return
            end
            if pickerPanel.Visible then
                local inset = guiService:GetGuiInset().Y
                local btnAbs = previewBtn.AbsolutePosition
                local btnSize = previewBtn.AbsoluteSize
                pickerPanel.Position = UDim2.new(0, btnAbs.X, 0, btnAbs.Y + btnSize.Y + inset + 2)
            end
        end)

        -- Toggle expand panel visibility
        previewBtn.MouseButton1Click:Connect(function()
            if not pickerPanel.Visible then
                -- snap into position before showing
                local inset = guiService:GetGuiInset().Y
                local btnAbs = previewBtn.AbsolutePosition
                local btnSize = previewBtn.AbsoluteSize
                pickerPanel.Position = UDim2.new(0, btnAbs.X, 0, btnAbs.Y + btnSize.Y + inset + 2)
            end
            pickerPanel.Visible = not pickerPanel.Visible
        end)
        
        -- Close panel when clicking outside
        UserInputService.InputBegan:Connect(function(input)
            if pickerPanel.Visible and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                local mousePos = input.Position
                local panelPos = pickerPanel.AbsolutePosition
                local panelSize = pickerPanel.AbsoluteSize
                
                local insidePanel = mousePos.X >= panelPos.X and mousePos.X <= (panelPos.X + panelSize.X) and
                                    mousePos.Y >= panelPos.Y and mousePos.Y <= (panelPos.Y + panelSize.Y)
                                    
                local btnPos = previewBtn.AbsolutePosition
                local btnSize2 = previewBtn.AbsoluteSize
                local insideBtn = mousePos.X >= btnPos.X and mousePos.X <= (btnPos.X + btnSize2.X) and
                                  mousePos.Y >= btnPos.Y and mousePos.Y <= (btnPos.Y + btnSize2.Y)
                                  
                if not insidePanel and not insideBtn then
                    pickerPanel.Visible = false
                end
            end
        end)
        
        local methods = {}
        function methods:SetColor(newColor)
            H, S, V = Color3.toHSV(newColor)
            svPointer.Position = UDim2.new(S, 0, 1 - V, 0)
            huePointer.Position = UDim2.new(0.5, 0, H, 0)
            svSquare.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
            updateColor()
        end
        function methods:GetColor()
            return Color3.fromHSV(H, S, V)
        end
        return methods
    end

    -- 8. Script — collapsable sub-GUI container widget that renders code from a callback function
    function container:Script(name, default, callback)
        local state = default or false

        -- Outer container
        local scriptFrame = Instance.new("Frame")
        scriptFrame.Name = name .. "_ScriptWidget"
        scriptFrame.Size = UDim2.new(1, 0, 0, 0)
        scriptFrame.AutomaticSize = Enum.AutomaticSize.Y
        scriptFrame.BackgroundTransparency = 1
        scriptFrame.Parent = parentFrame

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 4)
        layout.Parent = scriptFrame

        -- Header button/toggle
        local headerFrame = Instance.new("TextButton")
        headerFrame.Name = "Header"
        headerFrame.Size = UDim2.new(1, 0, 0, 20)
        headerFrame.BackgroundColor3 = Theme.HeaderBg
        headerFrame.BorderSizePixel = 1
        headerFrame.BorderColor3 = Theme.WindowBorder
        headerFrame.Text = ""
        headerFrame.AutoButtonColor = false
        headerFrame.LayoutOrder = 1
        headerFrame.Parent = scriptFrame

        -- Checkbox indicator
        local box = Instance.new("Frame")
        box.Size = UDim2.new(0, 12, 0, 12)
        box.Position = UDim2.new(0, 4, 0.5, -6)
        box.BackgroundColor3 = state and Theme.SliderBg or Theme.FrameBg
        box.BorderSizePixel = 1
        box.BorderColor3 = Theme.WindowBorder
        box.Parent = headerFrame

        local check = Instance.new("TextLabel")
        check.Size = UDim2.new(1, 0, 1, 0)
        check.BackgroundTransparency = 1
        applyFont(check)
        check.TextSize = Theme.TextSize
        check.TextColor3 = Theme.TextColor
        check.Text = state and "✓" or ""
        check.Parent = box

        -- Label
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -24, 1, 0)
        label.Position = UDim2.new(0, 22, 0, 0)
        label.BackgroundTransparency = 1
        applyFont(label)
        label.TextSize = Theme.TextSize
        label.TextColor3 = Theme.TextColor
        label.Text = name
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = headerFrame

        -- Render surface frame for the mini GUI
        local renderSurface = Instance.new("Frame")
        renderSurface.Name = "RenderSurface"
        renderSurface.Size = UDim2.new(1, 0, 0, 0)
        renderSurface.AutomaticSize = Enum.AutomaticSize.Y
        renderSurface.BackgroundTransparency = 1
        renderSurface.LayoutOrder = 2
        renderSurface.Visible = state
        renderSurface.Parent = scriptFrame

        -- Indent padding for the mini GUI elements so they align beautifully inside the script widget
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 14)
        padding.PaddingTop = UDim.new(0, 2)
        padding.PaddingBottom = UDim.new(0, 2)
        padding.Parent = renderSurface

        local renderLayout = Instance.new("UIListLayout")
        renderLayout.SortOrder = Enum.SortOrder.LayoutOrder
        renderLayout.Padding = UDim.new(0, 5)
        renderLayout.Parent = renderSurface

        -- Render/Execute helper
        local renderObj = {}
        setupContainerMethods(renderObj, renderSurface)

        local function clearUI()
            for _, child in ipairs(renderSurface:GetChildren()) do
                if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                    child:Destroy()
                end
            end
        end

        local function runUI()
            clearUI()
            if not state then return end
            
            local proxyMap = {}
            local realMap = {}
            
            local function isProxy(obj)
                return realMap[obj] ~= nil
            end
            
            local function unwrap(obj)
                return realMap[obj] or obj
            end
            
            local function wrap(realObj)
                if not realObj then return nil end
                if typeof(realObj) ~= "Instance" and typeof(realObj) ~= "userdata" then
                    return realObj
                end
                if proxyMap[realObj] then return proxyMap[realObj] end
                
                local proxy = newproxy(true)
                local meta = getmetatable(proxy)
                
                meta.__index = function(self, key)
                    if key == "Parent" then
                        local realParent = realObj.Parent
                        if realParent == renderSurface then
                            return playerGui
                        end
                        return wrap(realParent)
                    end
                    
                    local val
                    local ok = pcall(function()
                        val = realObj[key]
                    end)
                    if not ok then
                        if key == "ResetOnSpawn" then return false
                        elseif key == "IgnoreGuiInset" then return false
                        elseif key == "DisplayOrder" then return 0
                        elseif key == "Enabled" then return true
                        end
                        return nil
                    end
                    
                    if typeof(val) == "function" then
                        return function(_, ...)
                            local args = {...}
                            for i, arg in ipairs(args) do
                                args[i] = unwrap(arg)
                            end
                            local results = {val(realObj, unpack(args))}
                            for i, res in ipairs(results) do
                                if typeof(res) == "Instance" then
                                    results[i] = wrap(res)
                                end
                            end
                            return unpack(results)
                        end
                    end
                    
                    if typeof(val) == "Instance" then
                        return wrap(val)
                    end
                    return val
                end
                
                meta.__newindex = function(self, key, val)
                    val = unwrap(val)
                    
                    if key == "Parent" then
                        if realObj:IsA("Frame") and realObj.Name == "FakeScreenGui" then
                            realObj.Parent = renderSurface
                            return
                        end
                    end
                    
                    local ok = pcall(function()
                        realObj[key] = val
                    end)
                    if not ok then
                        -- silently ignore unsupported Frame writes (e.g. ResetOnSpawn)
                    end
                end
                
                meta.__tostring = function(self)
                    return tostring(realObj)
                end
                
                proxyMap[realObj] = proxy
                realMap[proxy] = realObj
                return proxy
            end
            
            local customInstance = {
                new = function(className, parent)
                    parent = unwrap(parent)
                    local realObj
                    if className == "ScreenGui" then
                        realObj = Instance.new("Frame")
                        realObj.Name = "FakeScreenGui"
                        realObj.Size = UDim2.new(1, 0, 0, 220)
                        realObj.BackgroundTransparency = 1
                        realObj.BorderSizePixel = 0
                    else
                        realObj = Instance.new(className)
                    end
                    
                    if className == "ScreenGui" then
                        realObj.Parent = renderSurface
                    elseif parent then
                        realObj.Parent = parent
                    end
                    return wrap(realObj)
                end
            }
            
            local env
            env = setmetatable({
                Instance = customInstance,
                game = setmetatable({
                    GetService = function(_, serviceName)
                        return wrap(game:GetService(serviceName))
                    end,
                    getService = function(_, serviceName)
                        return wrap(game:GetService(serviceName))
                    end,
                    Players = wrap(game:GetService("Players")),
                    players = wrap(game:GetService("Players")),
                    Workspace = wrap(workspace),
                    workspace = wrap(workspace),
                }, {
                    __index = function(_, k)
                        local val = game[k]
                        if typeof(val) == "Instance" then
                            return wrap(val)
                        end
                        return val
                    end
                }),
                workspace = wrap(workspace),
                script = wrap(Instance.new("Script")),
                print = function(...)
                    local args = {...}
                    local strs = {}
                    for i = 1, #args do
                        strs[i] = tostring(args[i])
                    end
                    local msg = table.concat(strs, " ")
                    if container.Window then
                        container.Window:AddLog(msg, false)
                    end
                end,
            }, {
                __index = getfenv(callback)
            })
            
            setfenv(callback, env)
            local ok, err = pcall(callback, true)
            if not ok then
                local errMsg = tostring(err)
                warn("[xGui Script Execution Error]:", errMsg)
                if container.Window then
                    container.Window:AddLog(errMsg, true)
                    container.Window:ShowErrorPopup(errMsg)
                end
            end
        end

        local function toggle()
            state = not state
            check.Text = state and "✓" or ""
            box.BackgroundColor3 = state and Theme.SliderBg or Theme.FrameBg
            renderSurface.Visible = state
            if state then
                runUI()
            else
                clearUI()
                pcall(callback, false)
            end
        end

        headerFrame.MouseButton1Click:Connect(toggle)

        -- Hover states
        headerFrame.MouseEnter:Connect(function()
            headerFrame.BackgroundColor3 = Theme.HeaderHovered
            box.BackgroundColor3 = state and Theme.SliderBgHovered or Theme.FrameBgHovered
        end)
        headerFrame.MouseLeave:Connect(function()
            headerFrame.BackgroundColor3 = Theme.HeaderBg
            box.BackgroundColor3 = state and Theme.SliderBg or Theme.FrameBg
        end)

        -- Run once initially if default is true
        if state then
            runUI()
        end

        local methods = {}
        function methods:SetState(newState)
            if state ~= newState then
                toggle()
            end
        end
        function methods:GetState()
            return state
        end
        return methods
    end
    container.CreateScript = container.Script
end

return xGui
