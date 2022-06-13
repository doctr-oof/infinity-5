--[[
    PlayerAdded.lua
    By FriendlyBiscuit
    05/01/2022 @ 22:17:08
    
    Description:
        Infinity 6 built-in PlayerAdded event connector.
--]]

local player_svc = game:GetService('Players')
local run_svc    = game:GetService('RunService')

return {
    Aliases = { 'PlayerAdded', 'PlayerJoined', 'PlayerJoin' },
    ExecutionOrder = 5,
    Handle = function(job_module: {}, callback: (self: {}, client: Player) -> ())
        player_svc.PlayerAdded:Connect(function(client: Player)
            callback(job_module, client)
        end)
        
        if run_svc:IsStudio() then
            for _, player in pairs(player_svc:GetPlayers()) do
                callback(job_module, player)
            end
        end
    end
}