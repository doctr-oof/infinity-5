--[[
    InfinityClient.client.lua
    FriendlyBiscuit
    Created on 09/25/2021 @ 00:30:41
    
    Description:
        Initializes the client/server jobs and loops.
    
    Documentation:
        No documentation provided.
--]]

--= Constants =--
local run_svc       = game:GetService('RunService')
local player_svc    = game:GetService('Players')
local shared_jobs   = game.ReplicatedStorage:WaitForChild('jobs')
local local_jobs    = script.Parent:WaitForChild('jobs')

--= Variables =--
local loaded_loops  = { }

--= Functions =--
function lazy_load_folder(root: Instance): table
    local result = { }
    
    local function recurse(object: Instance): nil
        for _, child in pairs(object:GetChildren()) do
            if child:IsA('ModuleScript') then
                result[child.Name] = require(child)
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
        if job.Init then
            job:Init()
        end
    end
    
    for _, job in pairs(modules) do
        if job.Run then
            task.defer(function()
                job:Run()
            end)
        end
        
        if job.PlayerAdded then
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
    end
end
    
if #loaded_loops >= 0 then
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
end

--= Initialize =--
load_jobs(local_jobs)
load_jobs(shared_jobs)