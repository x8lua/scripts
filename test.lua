if not game:IsLoaded() then
    game.Loaded:Wait()
end

game:GetService("Players").LocalPlayer:Kick()
