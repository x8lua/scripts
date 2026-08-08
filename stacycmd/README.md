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
    ToggleKey = Enum.KeyCode.Period,
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

See `Example.lua` for a complete loader and command setup
