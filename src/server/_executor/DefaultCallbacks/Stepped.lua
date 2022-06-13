--[[
    Stepped.lua
    By FriendlyBiscuit
    05/02/2022 @ 15:57:38
    
    Description:
        Infinity 6 built-in Stepped event connector.
--]]

local run_svc = game:GetService('RunService')

return {
    Aliases = { 'Stepped', 'OnStepped' },
    ExecutionOrder = 7,
    PromiseType = 'None',
    Handle = function(job_module: {}, callback: (self: {}) -> ())
        run_svc.Stepped:Connect(function(...)
            callback(job_module, ...)
        end)
    end
}