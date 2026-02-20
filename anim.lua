local pathToGithub = "https://raw.githubusercontent.com/xhayper/Animator/main/Source/"
local sub = string.sub

getgenv().httpRequireCache = getgenv().httpRequireCache or {}

getgenv().HttpRequire = function(path, noCache)
    if sub(path, 1, 8) == "https://" or sub(path, 1, 7) == "http://" then
        if not noCache and httpRequireCache[path] then
            return httpRequireCache[path]
        end
        local content = (syn and syn.request) and syn.request({ Url = path }).Body
                        or (request and request({ Url = path }).Body or game:HttpGet(path))
        httpRequireCache[path] = loadstring(content)()
        return httpRequireCache[path]
    else
        return require(path)
    end
end

getgenv().animatorRequire = function(path)
    return HttpRequire(pathToGithub .. path)
end

-- 加載核心組件
getgenv().Animator = animatorRequire("Animator.lua")
local Utility = animatorRequire("Utility.lua")

-- [[ 優化後的 Hook 函數，解決 ClassName 報錯 ]] --
getgenv().hookAnimatorFunction = function()
    local OldFunc
    OldFunc = hookmetamethod(game, "__namecall", function(Object, ...)
        local NamecallMethod = getnamecallmethod()
        
        -- 修正點：先檢查 Object 是否存在，再檢查 ClassName
        if not isvnode(Object) or not Object or typeof(Object) ~= "Instance" then
            return OldFunc(Object, ...)
        end

        if NamecallMethod == "LoadAnimation" and Object:IsA("Humanoid") then
            if not checkcaller() then
                local args = {...}
                -- 如果是我們想要的那個 LocalPlayer 動畫
                -- 你可以在這裡加入 ID 判斷
                return Animator.new(Object.Parent, args[1])
            end
        end
        
        return OldFunc(Object, ...)
    end)
    Utility:sendNotif("Hook Fixed & Loaded\nby Gemini", nil, 5)
end

Utility:sendNotif("Animator API Ready", nil, 5)

-- 執行 Hook
hookAnimatorFunction()

-- 測試播放
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local myAnim = Animator.new(Character, "rbxassetid://99159420513149")
myAnim:Play()

return "Fixed by x8's helper"
