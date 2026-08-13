# StacyCMD UI Library

Standalone console UI extracted from StacyCMD with the moderation gameplay persistence and autoplay systems removed

## Load

```lua
local StacyUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/x8lua/scripts/main/stacycmd/StacyUI.lua"
))()
```

## Create a console

```lua
local console = StacyUI.new({
    Name = "MyConsole",
    Prefix = "demo@StacyUI$ ",
    ToggleKey = Enum.KeyCode.F1,
    CommandKey = Enum.KeyCode.Semicolon,
    IntroSize = Vector2.new(480, 120),
    IntroTargetSize = Vector2.new(92, 26),
    IntroTargetOffset = Vector2.new(0, 0),
    IntroTweenDuration = 0.7,
    OnDestroy = function()
        print("Script resources destroyed")
    end,
})

console:Register({
    Name = "echo",
    Description = "Print text in the console",
    Usage = "echo [text]",
    Callback = function(arguments, _, ui)
        ui:Log(table.concat(arguments, " "))
    end,
})
```

The console opens by default after a centered full-screen StacyCMD brand intro that shrinks directly into the aligned header title, then fades in the command UI. `IntroSize` controls the starting title, `IntroTargetSize` controls the finished header title, `IntroTargetOffset` adjusts its final X/Y position, and `IntroTweenDuration` controls the shrink time. Pass `Intro = false` to skip the intro or `Visible = false` to start hidden.

Set `Usage` on a command to show its syntax in autocomplete suggestions, for example `Usage = "kick [reason] [time]"`.

Commands receive positional values in `arguments[1]`, `arguments[2]`, and so on. Quoted values and escaped quotes are supported, so `echo "hello world"` keeps `hello world` as one argument. Register a command with `Args` to validate required values and expose named values at `arguments.Named`:

```lua
console:Register({
    Name = "echo",
    Description = "Print text",
    Args = {
        { Name = "text", Required = true },
    },
    Callback = function(arguments, _, ui)
        ui:Log(arguments.Named.text)
    end,
})
```

`Args` automatically creates usage text when `Usage` is omitted. `arguments.Raw` contains the unparsed text after the command name.

The public API includes `new` `Register` `Unregister` `Execute` `CheckForUpdate` `PlayIntro` `SetFlyEnabled` `SetPredictionEnabled` `StopPrediction` `TeleportTo` `ViewPlayer` `ServerHop` `ShowWhoIsThis` `HideWhoIsThis` `ShowGameCommands` `ShowGames` `ShowGameDetail` `ExecuteGameScript` `ShowSettings` `FocusCommandBar` `Log` `Clear` `SetPrefix` `SetToggleKey` `SetCommandKey` `Toggle` and `Destroy`. Registered commands may provide an optional `Usage` string for autocomplete display. Set `GameSpecific = true` to include a custom command in `gamecmds` and display it in lime green.

The protected built ins are `help` `clear` `cmds` `games` `gamecmds` `settings` `updatelog` `version` `to` `view` `maxzoom` `jpower` `reset` `fly` `flingui` `prediction` `lagdetection` `rejoin` `serverhop` `shop` `sudoaptupdate` and `ctrlc`. `autorevive`, `legacyto`, and `whoisthis` are also available in the supported Gakuran game.

`flingui` loads the FlingV2 interface from the configured FlingV2 source URL.

`games` opens the dark supported-games browser with Roblox thumbnails and icons. Larpkuran runs `gakuran_fling.lua`; when launched outside its supported place, StacyCMD warns that it might not work. `placeholder` intentionally produces a runtime nil-call error followed by a randomized compatibility remark in the console. The detail page's `AUTOEXEC ON` button saves the selected game in `StacyCMD.autoexec` and runs it on the next StacyCMD load; click it again to turn autoexec off.

Games typography loads `SansFlex.ttf` through `getcustomasset` and a generated font-family JSON when executor file APIs are available, then assigns the resulting object through `FontFace`. It falls back to BuilderSans or Gotham when that local font file is unavailable.

`maxzoom [num]` sets the speaker's maximum camera zoom distance

`fly [speed]` toggles camera-relative flight and closes the console while enabled so W A S D and Q E control movement. Disabling flight restores the humanoid from PlatformStand. The fly movement implementation is adapted from Infinite Yield.

`prediction` toggles cyan Drawing API markers at predicted nearby-player positions. Press P to remove the markers. It appears in `gamecmds` with the game-command color.

`view [player|self|random]` is a regular command that changes the camera subject. In the Gakuran place it also appears in `gamecmds` and matches Gakuran names. Use plain `view` or `view self` to restore the local character camera.

Press `;` to open or refocus the command bar. Recognized semicolon commands fade the console out immediately; unknown commands keep the prompt focused for correction. Inactivity still closes it after 2.5 seconds. F1 remains the console toggle. `settings` opens the command-key configuration page.

`jpower [num]` sets the local character's jump power. `rejoin` reconnects to the current server instance. `serverhop` (or `shop`) finds a non-full public server that has not been visited during the current UTC hour, records it in `StacyCMD.NotSameServers.json`, and teleports there.

`reset` sets the local character humanoid health to zero. `lagdetection [percentage]` samples player positions every half-second and uses PurgatoryNotify when the chosen percentage have not moved for 1.5 seconds; it defaults to `90` and clears below that threshold.

`to [player]` normally matches usernames and display names. In place `128736949265057`, it matches `PlayerInfoBillboard.Info.Text` instead and is highlighted as a game-specific command.

`to random` teleports to a random available player other than the local player.

`whoisthis` opens a draggable Gakuran inspector. It selects the visible player closest to the cursor without requiring the cursor to touch their model, then shows their Gakuran name, username, and display name.

`autorevive` is a one-way Gakuran command for the current executor session. It revives the local humanoid, clears game death effects, and replaces the reset callback with a forced revive flow. Reload the executor session to clear it.

`legacyto` restores username and display-name matching for the current session. `gamecmds` opens the searchable command browser filtered to active game-specific commands, with command names shown in lime green.

`sudoaptupdate` checks the configured StacyUI source for a newer version, validates it, plays the reverse StacyCMD intro, waits a random `0.1-2.0` seconds, and reloads into the normal intro while preserving custom commands. The new instance is also available as `getgenv().StacyCMD`.

`cmds` opens a separate searchable command browser with descriptions and clickable command rows

Command suggestions support Up and Down selection, Tab completion, and Enter execution

After Enter, recognized commands leave the prompt unfocused. Unknown command names restore prompt focus for correction.

`updatelog` opens the searchable release history with the Bodoni StacyCMD title and bright green CMD mark

Each StacyCMD release adds its newest entry at the top of the update log

`ctrlc` calls `Destroy` which unbinds input disconnects every UI connection destroys the ScreenGui clears library state and runs the optional `OnDestroy` callback

The console displays a compact Bodoni StacyCMD header with bright green CMD branding F1 state ready banner and accent matched command suggestions by default

See `Example.lua` for a complete loader and command setup

## Mobile echo-only replica

`StacyCMDReplica.lua` is a self-contained StacyCMD-style interface for lightweight/mobile use. It deliberately supports **only** `echo [text]`; it does not load any StacyCMD built-ins. On touch devices, its round green `CMD` button is always present in the lower-right corner, including when the console is closed. Tapping it opens the console and focuses the command bar for the on-screen keyboard.

```lua
local StacyCMDReplica = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/x8lua/scripts/main/stacycmd/StacyCMDReplica.lua"
))()
local console = StacyCMDReplica.new()
```

Use `F1` on desktop or the mobile `CMD` button to open it. `MobileReplicaExample.lua` is a ready-to-run loader.
