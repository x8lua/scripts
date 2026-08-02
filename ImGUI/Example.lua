-- PurgatoryNotify — Example Script
-- Run this in your executor to test the notification library.

local Notify = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/x8lua/scripts/main/ImGUI/Notify.lua?nocache=" .. tostring(tick()),
    true
))()

-- ── Basic usage (module-level shorthand) ─────────────────────────────────────
Notify.push("Altar of Purgatory", "Activated by @kerrmeet")

task.wait(1.5)

-- duration override (8 seconds instead of 4)
Notify.push("Long Alert", "This one stays for 8 seconds.", { duration = 8 })

task.wait(0.6)

-- RichText in title and body
Notify.push(
    '<font color="#ff4444">Warning</font>',
    'Player <b>@someone</b> has joined.',
    { duration = 5 }
)

task.wait(0.6)

-- Custom purple-to-red theme
Notify.push("Custom Color", "Red-tinted notification.", {
    color    = Color3.fromRGB(180, 20, 20),
    duration = 4,
})

-- ── OOP usage: custom instance with its own position + color ─────────────────
task.wait(2)

local topNotify = Notify.new({
    position = "top-right",
    color    = Color3.fromRGB(10, 80, 170),
    duration = 5,
    height   = 80,
})

topNotify:push("Top-Right", "This appears in the top-right corner.")
task.wait(0.4)
topNotify:push("Queued", "Cards stack upward from this corner.")

-- ── clear() wipes all visible cards on that instance ─────────────────────────
task.wait(6)
topNotify:clear()
topNotify:destroy()

-- Clear the default instance too when you're done
-- Notify.clear()
-- Notify.destroy()
