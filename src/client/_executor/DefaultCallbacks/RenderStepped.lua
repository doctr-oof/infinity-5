--[[
    RenderStepped.lua
    By FriendlyBiscuit
    05/02/2022 @ 15:57:38
    
    Description:
        Infinity 6 built-in RenderStepped event connector.
--]]

local run_svc = game:GetService('RunService')

return {
    Aliases = { 'RenderStepped', 'OnRenderStepped' },
    ExecutionOrder = 9,
    PromiseType = 'None',
    Handle = function(job_module: {}, callback: (self: {}) -> ())
        run_svc.RenderStepped:Connect(function(...)
            callback(job_module, ...)
        end)
    end
}