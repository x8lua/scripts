local StacyUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/x8lua/scripts/main/stacycmd/StacyUI.lua"
))()

local console = StacyUI.new({
    Name = "MyConsole",
    Prefix = "demo@StacyUI$ ",
    ToggleKey = Enum.KeyCode.Period,
    OnDestroy = function()
        print("StacyUI and script resources destroyed")
    end,
})

console:Register({
    Name = "echo",
    Description = "Print text in the console",
    Callback = function(arguments, _, ui)
        ui:Log(table.concat(arguments, " "))
    end,
})

console:Register({
    Name = "clear",
    Description = "Clear the console log",
    Callback = function(_, _, ui)
        ui:Clear()
    end,
})

console:Register({
    Name = "close",
    Description = "Close the console",
    Callback = function(_, _, ui)
        ui:Toggle(false)
    end,
})

console:Log("StacyUI loaded  press Period to toggle", console.Style.info)
console:Log("Run ctrlc to destroy the entire script", console.Style.warn)
