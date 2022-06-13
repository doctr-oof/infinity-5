--[[
    Tick.lua
    By FriendlyBiscuit
    05/01/2022 @ 22:36:00
    
    Description:
        No description provided.
--]]

local run_svc = game:GetService('RunService')
local ticks   = { }
local ticking = false

return {
    Aliases = { 'Tick' },
    ExecutionOrder = 3,
    Preload = function()
        run_svc.Stepped:Connect(function()
            if ticking then return end
            ticking = true
            
            for _, tick_data in pairs(ticks) do
                tick_data.Frame += 1
                
                if tick_data.Frame >= tick_data.TickRate then
                    tick_data.Callback(tick_data.JobData, tick_data)
                    tick_data.Frame = 0
                end
            end
            
            ticking = false
        end)
    end,
    Handle = function(job_module: {}, callback: (self: {}) -> ())
        local target_priority = job_module.TickPriority or 1
        
        while ticks[target_priority] do target_priority += 1 end
        
        table.insert(ticks, target_priority, {
            JobData = job_module,
            Callback = callback,
            TickRate = job_module.TickRate or 1,
            Frame = 0
        })
    end
}