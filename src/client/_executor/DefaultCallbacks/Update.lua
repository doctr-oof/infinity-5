--[[
    Tick.lua
    By FriendlyBiscuit
    05/01/2022 @ 22:36:00
    
    Description:
        No description provided.
--]]

local run_svc = game:GetService('RunService')
local updates = { }

return {
    Aliases = { 'Update' },
    ExecutionOrder = 4,
    Preload = function()
        run_svc.RenderStepped:Connect(function()
            for _, update in pairs(updates) do
                if tick() - update.LastUpdate >= update.UpdateRate and not update.Updating then
                    update.Updating = true
                    update.Callback(update.JobData, update)
                    update.LastUpdate = tick()
                    update.Updating = false
                end
            end
        end)
    end,
    Handle = function(job_module: {}, callback: (self: {}) -> ())
        table.insert(updates, {
            JobData = job_module,
            Callback = callback,
            UpdateRate = job_module.UpdateRate or 1,
            LastUpdate = 0,
            Updating = false
        })
    end
}