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

The console opens by default after a centered full-screen StacyCMD brand intro that shrinks directly into the aligned header title. Pass `Intro = false` to skip the intro or `Visible = false` to start hidden.

Set `Usage` on a command to show its syntax in autocomplete suggestions, for example `Usage = "kick [reason] [time]"`.

The public API includes `new` `Register` `Unregister` `Execute` `CheckForUpdate` `PlayIntro` `SetFlyEnabled` `SetPredictionEnabled` `StopPrediction` `TeleportTo` `ShowGameCommands` `Log` `Clear` `SetPrefix` `SetToggleKey` `Toggle` and `Destroy`. Registered commands may provide an optional `Usage` string for autocomplete display. Set `GameSpecific = true` to include a custom command in `gamecmds` and display it in lime green.

The protected built ins are `help` `clear` `cmds` `gamecmds` `updatelog` `version` `to` `maxzoom` `fly` `prediction` `sudoaptupdate` and `ctrlc`. `legacyto` is also available in the supported Gakuran game.

`maxzoom [num]` sets the speaker's maximum camera zoom distance

`fly [speed]` toggles camera-relative flight and closes the console while enabled so W A S D and Q E control movement. The fly movement implementation is adapted from Infinite Yield.

`prediction` toggles cyan Drawing API markers at predicted nearby-player positions. Press P to remove the markers.

`to [player]` normally matches usernames and display names. In place `128736949265057`, it matches `PlayerInfoBillboard.Info.Text` instead and is highlighted as a game-specific command.

`to random` teleports to a random available player other than the local player.

`legacyto` restores username and display-name matching for the current session. `gamecmds` opens the searchable command browser filtered to active game-specific commands, with command names shown in lime green.

`sudoaptupdate` checks the configured StacyUI source for a newer version, validates it, unloads the current console, and reloads it while preserving custom commands. The new instance is also available as `getgenv().StacyCMD`.

`cmds` opens a separate searchable command browser with descriptions and clickable command rows

Command suggestions support Up and Down selection, Tab completion, and Enter execution

After Enter, recognized commands leave the prompt unfocused. Unknown command names restore prompt focus for correction.

`updatelog` opens the searchable release history with the Bodoni StacyCMD title and bright green CMD mark

Each StacyCMD release adds its newest entry at the top of the update log

`ctrlc` calls `Destroy` which unbinds input disconnects every UI connection destroys the ScreenGui clears library state and runs the optional `OnDestroy` callback

The console displays a compact Bodoni StacyCMD header with bright green CMD branding F1 state ready banner and accent matched command suggestions by default

See `Example.lua` for a complete loader and command setup
