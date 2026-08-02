--[[
    PurgatoryNotify — Roblox Notification UI Library
    Version 1.0.0  |  github.com/x8lua/scripts/ImGUI

    Quick start:
        local Notify = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/x8lua/scripts/main/ImGUI/Notify.lua"
        ))()
        Notify.push("Altar of Purgatory", "Activated by @kerrmeet")

    OOP usage:
        local n = Notify.new({ color = Color3.fromRGB(200, 30, 30) })
        n:push("Alert", "Something happened!", { duration = 6 })
        n:clear()
        n:destroy()
--]]

local PurgatoryNotify = {}
PurgatoryNotify.__index = PurgatoryNotify
PurgatoryNotify.Version = "1.0.0"

-- ── Services ─────────────────────────────────────────────────────────────────
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- ── Defaults ─────────────────────────────────────────────────────────────────
local DEFAULTS = {
    color       = Color3.fromRGB(53, 3, 139),      -- background purple
    accentColor = Color3.fromRGB(102, 0, 255),      -- stroke accent
    duration    = 4,                                -- seconds on screen
    maxVisible  = 5,                                -- max simultaneous cards
    position    = "bottom-center",                  -- see POSITION_MAP
    animIn      = 0.35,                             -- fade-in duration (s)
    animOut     = 0.25,                             -- fade-out duration (s)
    height      = 90,                               -- card height (px)
    minWidth    = 360,
    maxWidth    = 480,
    spacing     = 8,                                -- gap between cards (px)
}

local POSITION_MAP = {
    ["bottom-center"] = { anchor = Vector2.new(0.5, 1), pos = UDim2.new(0.5,  0, 0.92, 0), grows = "up"   },
    ["bottom-right"]  = { anchor = Vector2.new(1,   1), pos = UDim2.new(0.98, 0, 0.92, 0), grows = "up"   },
    ["top-center"]    = { anchor = Vector2.new(0.5, 0), pos = UDim2.new(0.5,  0, 0.08, 0), grows = "down" },
    ["top-right"]     = { anchor = Vector2.new(1,   0), pos = UDim2.new(0.98, 0, 0.08, 0), grows = "down" },
}

-- ── Utility ───────────────────────────────────────────────────────────────────
local function merge(base, overrides)
    local t = {}
    for k, v in pairs(base) do t[k] = v end
    if overrides then
        for k, v in pairs(overrides) do t[k] = v end
    end
    return t
end

local function getPlayer()
    return Players.LocalPlayer or Players.PlayerAdded:Wait()
end

-- ── Constructor ───────────────────────────────────────────────────────────────
function PurgatoryNotify.new(cfg)
    cfg = merge(DEFAULTS, cfg)
    local self = setmetatable({
        _cfg       = cfg,
        _active    = {},
        _gui       = nil,
        _stack     = nil,
        _order     = 0,
        _destroyed = false,
    }, PurgatoryNotify)
    self:_buildGui()
    return self
end

-- ── Build the persistent ScreenGui + stack frame ──────────────────────────────
function PurgatoryNotify:_buildGui()
    local cfg     = self._cfg
    local posInfo = POSITION_MAP[cfg.position] or POSITION_MAP["bottom-center"]

    local playerGui = getPlayer():WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("_PNotifyGui")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name           = "_PNotifyGui"
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = false
    sg.Parent         = playerGui
    self._gui = sg

    -- stack: auto-sizes vertically, holds all cards
    local stack = Instance.new("Frame")
    stack.Name              = "Stack"
    stack.AnchorPoint       = posInfo.anchor
    stack.Position          = posInfo.pos
    stack.Size              = UDim2.new(0, cfg.maxWidth, 0, 0)
    stack.AutomaticSize     = Enum.AutomaticSize.Y
    stack.BackgroundTransparency = 1
    stack.BorderSizePixel   = 0
    stack.Parent            = sg

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(cfg.minWidth, 0)
    sizeConstraint.MaxSize = Vector2.new(cfg.maxWidth, math.huge)
    sizeConstraint.Parent  = stack

    local layout = Instance.new("UIListLayout")
    layout.FillDirection      = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment  = (posInfo.grows == "up")
        and Enum.VerticalAlignment.Bottom
        or  Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, cfg.spacing)
    layout.Parent    = stack

    self._stack = stack
end

-- ── Build one notification card ───────────────────────────────────────────────
function PurgatoryNotify:_buildCard(title, body, cardCfg)
    -- CanvasGroup lets us animate the whole card's opacity as one unit
    local canvas = Instance.new("CanvasGroup")
    canvas.Name                 = "Notification"
    canvas.Size                 = UDim2.new(1, 0, 0, cardCfg.height)
    canvas.BackgroundTransparency = 1
    canvas.BorderSizePixel      = 0
    canvas.ClipsDescendants     = true
    canvas.GroupTransparency    = 1        -- invisible until tweened in

    -- inner padding
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, 4)
    pad.PaddingRight  = UDim.new(0, 4)
    pad.PaddingTop    = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.Parent = canvas

    -- ── Background ────────────────────────────────────────────────────────────
    local bg = Instance.new("Frame")
    bg.Name                 = "Background"
    bg.Size                 = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3     = cardCfg.color
    bg.BackgroundTransparency = 0.4
    bg.BorderSizePixel      = 0
    bg.ZIndex               = 0
    bg.Parent               = canvas

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 6)
    bgCorner.Parent = bg

    -- vertical fade: solid → transparent toward the bottom
    local bgGrad = Instance.new("UIGradient")
    bgGrad.Rotation = 90
    bgGrad.Offset   = Vector2.new(0, 0.2)
    bgGrad.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
    })
    bgGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 0.6),
    })
    bgGrad.Parent = bg

    -- border stroke with gradient tint
    local bgStroke = Instance.new("UIStroke")
    bgStroke.Color           = cardCfg.color
    bgStroke.Thickness        = 2
    bgStroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
    bgStroke.LineJoinMode     = Enum.LineJoinMode.Bevel
    bgStroke.Parent           = bg

    local strokeGrad = Instance.new("UIGradient")
    strokeGrad.Rotation = 90
    strokeGrad.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 148, 148)),
    })
    strokeGrad.Parent = bgStroke

    -- ── Content (title + description) ────────────────────────────────────────
    local content = Instance.new("Frame")
    content.Name                 = "Content"
    content.Size                 = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel      = 0
    content.ZIndex               = 1
    content.Parent               = canvas

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection       = Enum.FillDirection.Vertical
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    contentLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    contentLayout.Padding             = UDim.new(0, 0)
    contentLayout.Parent              = content

    -- helper: build a styled TextLabel
    local function makeLabel(text, layoutOrder, sizeY, strokeThickness, fontWeight)
        local lbl = Instance.new("TextLabel")
        lbl.Size                 = UDim2.new(1, 0, sizeY, 0)
        lbl.BackgroundTransparency = 1
        lbl.BorderSizePixel      = 0
        lbl.ZIndex               = 2
        lbl.LayoutOrder          = layoutOrder
        lbl.Text                 = text
        lbl.TextColor3           = Color3.fromRGB(255, 255, 255)
        lbl.TextScaled           = true
        lbl.TextWrapped          = true
        lbl.TextXAlignment       = Enum.TextXAlignment.Center
        lbl.TextYAlignment       = Enum.TextYAlignment.Center
        lbl.RichText             = true
        lbl.FontFace             = Font.new(
            "rbxasset://fonts/families/AccanthisADFStd.json",
            fontWeight,
            Enum.FontStyle.Normal
        )
        lbl.Parent = content

        local lblPad = Instance.new("UIPadding")
        lblPad.PaddingTop    = UDim.new(0, 4)
        lblPad.PaddingBottom = UDim.new(0, 4)
        lblPad.Parent        = lbl

        local lblStroke = Instance.new("UIStroke")
        lblStroke.Color          = Color3.fromRGB(0, 0, 0)
        lblStroke.Thickness       = strokeThickness
        lblStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        lblStroke.LineJoinMode    = Enum.LineJoinMode.Round
        lblStroke.Parent          = lbl

        local lblGrad = Instance.new("UIGradient")
        lblGrad.Rotation = 90
        lblGrad.Offset   = Vector2.new(0, 0.5)
        lblGrad.Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180)),
        })
        lblGrad.Parent = lbl

        return lbl
    end

    makeLabel(title, 0, 0.45, 2,   Enum.FontWeight.Bold)
    makeLabel(body,  1, 0.45, 1.5, Enum.FontWeight.Regular)

    return canvas
end

-- ── push(title, body, opts) ───────────────────────────────────────────────────
-- Show a notification. opts can override any DEFAULTS key per-call.
function PurgatoryNotify:push(title, body, opts)
    if self._destroyed then return end

    local cardCfg = merge(self._cfg, opts)

    -- evict oldest card when at cap
    local active = self._active
    while #active >= self._cfg.maxVisible do
        local oldest = table.remove(active, 1)
        if oldest.thread then task.cancel(oldest.thread) end
        if oldest.card and oldest.card.Parent then
            oldest.card:Destroy()
        end
    end

    self._order = self._order + 1
    local card = self:_buildCard(title, body or "", cardCfg)
    card.LayoutOrder = self._order
    card.Parent      = self._stack

    -- fade in
    TweenService:Create(card,
        TweenInfo.new(cardCfg.animIn, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { GroupTransparency = 0 }
    ):Play()

    local entry = { card = card, thread = nil }
    table.insert(active, entry)

    -- auto-dismiss
    entry.thread = task.delay(cardCfg.duration, function()
        if not card or not card.Parent then return end

        local tweenOut = TweenService:Create(card,
            TweenInfo.new(cardCfg.animOut, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { GroupTransparency = 1 }
        )
        tweenOut:Play()
        tweenOut.Completed:Wait()

        if card and card.Parent then card:Destroy() end

        for i, e in ipairs(active) do
            if e.card == card then
                table.remove(active, i)
                break
            end
        end
    end)

    return entry
end

-- ── clear() — remove all visible notifications immediately ───────────────────
function PurgatoryNotify:clear()
    for _, entry in ipairs(self._active) do
        if entry.thread then task.cancel(entry.thread) end
        if entry.card and entry.card.Parent then entry.card:Destroy() end
    end
    self._active = {}
end

-- ── destroy() — tear down the entire GUI ─────────────────────────────────────
function PurgatoryNotify:destroy()
    self:clear()
    if self._gui and self._gui.Parent then self._gui:Destroy() end
    self._destroyed = true
end

-- ── Module-level singleton shortcuts ─────────────────────────────────────────
-- Returned as a proxy table so the class-method PurgatoryNotify:push is never
-- overwritten (that would cause infinite recursion via the metatable).
local _default = nil
local function getDefault()
    if not _default or _default._destroyed then
        _default = PurgatoryNotify.new()
    end
    return _default
end

local Module = {}

-- static shortcuts
function Module.push(title, body, opts)  return getDefault():push(title, body, opts) end
function Module.clear()                  return getDefault():clear() end
function Module.destroy()
    if _default then _default:destroy() end
    _default = nil
end

-- pass-through so callers can still do Notify.new(cfg)
Module.new     = function(cfg) return PurgatoryNotify.new(cfg) end
Module.Version = PurgatoryNotify.Version

return Module
