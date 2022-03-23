--[[
    InfinityServer.server.lua
    FriendlyBiscuit
    Created on 09/25/2021 @ 00:30:41
    
    Description:
        Initializes the server jobs and loops.
--]]

--= Constants =--
local run_svc       = game:GetService('RunService')
local player_svc    = game:GetService('Players')
local shared_jobs   = game.ReplicatedStorage:WaitForChild('jobs')
local local_jobs    = script.Parent:WaitForChild('jobs')

--= Messages =--
local MESSAGES      = {
    NOT_FAST_ENOUGH = '%s\'s ::Immediate() callback ran too slow. This function should run instantly; check for yields.'
}

--= Variables =--
local loaded_loops  = { }
local loaded_ticks  = { }
local ticking       = false

--= Functions =--
function alert(message: string, ...): nil
    local final_str
    
    final_str = ('[InfinityServer] '):format() .. message
    
    if #{...} > 0 then
        for _, data in pairs({...}) do
            final_str = final_str:format(data)
        end
    end
    
    warn(final_str)
end

function run_immediate(module: table, callback: () -> ()): nil
    local routine = coroutine.create(callback)
    
    coroutine.resume(routine, module)
    
    if coroutine.status(routine) ~= 'dead' then
        alert(MESSAGES.NOT_FAST_ENOUGH, module.__jobname)
    end
end

function lazy_load_folder(root: Instance): table
    local result = { }
    
    local function recurse(object: Instance): nil
        for _, child in pairs(object:GetChildren()) do
            if child:IsA('ModuleScript') then
                local module_data = require(child)
                
                module_data.__jobname = child.Name
                
                if module_data.Immediate and module_data.Enabled ~= false then
                    run_immediate(module_data, module_data.Immediate)
                end
                
                result[child.Name] = module_data
            elseif child:IsA('Folder') then
                recurse(child)
            end
        end
    end
    
    recurse(root)
    
    return result
end

function load_jobs(target: Folder): nil
    local modules = lazy_load_folder(target)
    
    table.sort(modules, function(a, b)
        if a.Priority and b.Priority then
            return a.Priority < b.Priority
        end
        
        return false
    end)
    
    for _, job in pairs(modules) do
        if job.Enabled == false then continue end
        
        if job.Init then
            job:Init()
        end
    end
    
    for _, job in pairs(modules) do
        if job.Enabled == false then continue end
        
        if job.Run then
            task.defer(function()
                job:Run()
            end)
        end
        
        if job.PlayerAdded then
            player_svc.PlayerAdded:Connect(function(client: Player)
                job:PlayerAdded(client)
            end)
            
            for _, player in pairs(player_svc:GetPlayers()) do
                task.defer(function()
                    job:PlayerAdded(player)
                end)
            end
        end
        
        if job.PlayerLeft then
            player_svc.PlayerRemoving:Connect(function(client: Player)
                job:PlayerLeft(client)
            end)
        end
        
        if job.Stepped then
            run_svc.Stepped:Connect(function(...)
                job:Stepped(...)
            end)
        end
        
        if job.Heartbeat then
            run_svc.Heartbeat:Connect(function(...)
                job:Heartbeat(...)
            end)
        end
        
        if job.RenderStepped then
            run_svc.RenderStepped:Connect(function(...)
                job:RenderStepped(...)
            end)
        end
        
        if job.Update and job.UpdateRate then
            table.insert(loaded_loops, { job, job.UpdateRate, 0, false })
        end
        
        if job.Tick then
            local target_priority = job.TickPriority or 999
            
            if loaded_ticks[target_priority] then
                target_priority += 1
            end
            
            table.insert(loaded_ticks, target_priority, { job, job.TickRate or 1, 0 })
        end
    end
end

--= Initialize =--
load_jobs(local_jobs)
load_jobs(shared_jobs)

run_svc.Stepped:Connect(function(...)
    for _, loop in pairs(loaded_loops) do
        if tick() - loop[3] >= loop[2] and not loop[4] then
            loop[4] = true
            loop[1]:Update(...)
            loop[3] = tick()
            loop[4] = false
        end
    end
end)

run_svc.Stepped:Connect(function()
    if ticking then return end
    ticking = true
    
    for _, ticker in pairs(loaded_ticks) do
        ticker[3] += 1
        
        if ticker[3] >= ticker[2] then
            ticker[3] = 0
            ticker[1]:Tick()
        end
    end
    
    ticking = false
end)