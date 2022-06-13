--[[
    PlayerRemoving.lua
    By FriendlyBiscuit
    05/01/2022 @ 22:20:44
    
    Description:
        Infinity 6 built-in PlayerRemoving event connector.
--]]

local player_svc = game:GetService('Players')

return {
    Aliases = { 'PlayerRemoved', 'PlayerLeft', 'PlayerLeave' },
    ExecutionOrder = 6,
    Handle = function(job_module: {}, callback: (self: {}, client: Player) -> ())
        player_svc.PlayerRemoving:Connect(function(client: Player)
            callback(job_module, client)
        end)
    end
}