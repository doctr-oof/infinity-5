--[[
    Heartbeat.lua
    By FriendlyBiscuit
    05/02/2022 @ 15:57:38
    
    Description:
        Infinity 6 built-in Heartbeat event connector.
--]]

local run_svc = game:GetService('RunService')

return {
    Aliases = { 'Heartbeat', 'OnHeartbeat' },
    ExecutionOrder = 8,
    PromiseType = 'None',
    Handle = function(job_module: {}, callback: (self: {}) -> ())
        run_svc.Heartbeat:Connect(function(...)
            callback(job_module, ...)
        end)
    end
}