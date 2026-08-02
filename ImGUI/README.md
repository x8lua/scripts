# PurgatoryNotify

A lightweight Roblox notification UI library styled after the Altar of Purgatory aesthetic — purple gradient cards, text strokes, and smooth fade animations.

## Load

```lua
local Notify = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/x8lua/scripts/main/ImGUI/Notify.lua"
))()
```

## Quick usage

```lua
-- one line
Notify.push("Altar of Purgatory", "Activated by @kerrmeet")

-- with options
Notify.push("Alert", "Something happened!", {
    duration = 6,
    color    = Color3.fromRGB(200, 30, 30),
})
```

## OOP usage

```lua
local n = Notify.new({
    position = "top-right",   -- "bottom-center" | "bottom-right" | "top-center" | "top-right"
    color    = Color3.fromRGB(10, 80, 170),
    duration = 5,
})

n:push("Title", "Body text")
n:push("Queued", "Cards stack automatically.", { duration = 3 })
n:clear()    -- dismiss all cards on this instance
n:destroy()  -- remove the ScreenGui entirely
```

## Config options

| Key | Default | Description |
|---|---|---|
| `color` | `RGB(53,3,139)` | Card background color |
| `duration` | `4` | Seconds before auto-dismiss |
| `maxVisible` | `5` | Max simultaneous cards (oldest evicted) |
| `position` | `"bottom-center"` | Stack anchor position |
| `animIn` | `0.35` | Fade-in duration (s) |
| `animOut` | `0.25` | Fade-out duration (s) |
| `height` | `90` | Card height in px |
| `minWidth` | `360` | Min card width in px |
| `maxWidth` | `480` | Max card width in px |
| `spacing` | `8` | Gap between stacked cards in px |

Options passed to `push()` override the instance config for that card only.

## RichText

Both `title` and `body` support Roblox RichText tags:

```lua
Notify.push('<font color="#ff4444">Warning</font>', 'Player <b>@x</b> left.')
```
