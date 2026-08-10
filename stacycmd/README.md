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
    Callback = function(arguments, _, ui)
        ui:Log(table.concat(arguments, " "))
    end,
})
```

The public API includes `new` `Register` `Unregister` `Execute` `Log` `Clear` `SetPrefix` `SetToggleKey` `Toggle` and `Destroy`

The protected built ins are `help` `clear` `cmds` `updatelog` `version` `maxzoom` and `ctrlc`

`maxzoom [num]` sets the speaker's maximum camera zoom distance

`cmds` opens a separate searchable command browser with descriptions and clickable command rows

Command suggestions support Up and Down selection, Tab completion, and Enter execution

`updatelog` opens the searchable release history with the Bodoni StacyCMD title and bright green CMD mark

Each StacyCMD release adds its newest entry at the top of the update log

`ctrlc` calls `Destroy` which unbinds input disconnects every UI connection destroys the ScreenGui clears library state and runs the optional `OnDestroy` callback

The console displays a compact Bodoni StacyCMD header with bright green CMD branding F1 state ready banner and accent matched command suggestions by default

See `Example.lua` for a complete loader and command setup
