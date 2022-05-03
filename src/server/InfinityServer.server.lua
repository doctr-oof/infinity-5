--[[
    InfinityServer.server.lua
    FriendlyBiscuit
    Created on 09/25/2021 @ 00:30:41

    Description:
        Initializes the server jobs and loops.
--]]

--= Object References =--
local run_svc               = game:GetService('RunService')
local player_svc            = game:GetService('Players')
local shared_jobs           = game.ReplicatedStorage:WaitForChild('jobs')
local local_jobs            = script.Parent:WaitForChild('jobs')

--= Flags =--
local ALLOW_OLD_RUN         = true

--= Messages =--
local MESSAGES              = {
    NOT_FAST_ENOUGH = '%s\'s ::Immediate() callback ran too slow. This function should run instantly; check for yields.',
    OLD_RUN_DISABLED = '%s\'s ::Run() callback will be ignored since the ALLOW_OLD_RUN flag is disabled. Use ::InitAsync() instead.',
    CONVERT_TO_ASYNC = "%s's ::Run() callback is deprecated. Use ::InitAsync() instead."
}

--= Variables =--
local loaded_loops          = {}
local loaded_ticks          = {}
local ticking               = false

--= Functions =--
local function alert(message: string, ...)
    warn(string.format("[InfinityServer] " .. message, ...))
end

local function run_immediate(module: {}, callback: () -> ())
    local routine = coroutine.create(callback)

    coroutine.resume(routine, module)

    if coroutine.status(routine) ~= 'dead' then
        alert(MESSAGES.NOT_FAST_ENOUGH, module.__jobname)
    end
end

local function lazy_load_folder(root: Instance): {}
    local result = {}

    local modulesLoading = 0
    local function recurse(object: Instance)
        for _, child in pairs(object:GetChildren()) do
            if child:IsA('ModuleScript') then
                modulesLoading += 1
                task.spawn(function()
                    pcall(function()
                        local module_data = require(child)

                        if module_data.Enabled ~= false then
                            module_data.__jobname = child.Name

                            if module_data.Immediate then
                                run_immediate(module_data, module_data.Immediate)
                            end

                            result[child.Name] = module_data
                        end
                    end)

                    modulesLoading -= 1
                end)
            elseif child:IsA('Folder') then
                recurse(child)
            end
        end
    end

    recurse(root)

    while modulesLoading > 0 do task.wait() end

    return result
end

local function load_jobs(target: Folder)
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
        if job.InitAsync then
            task.spawn(job.InitAsync, job)
        end

        if job.Run then
            if ALLOW_OLD_RUN then
                task.spawn(job.Run, job)
                alert(MESSAGES.CONVERT_TO_ASYNC, job.__jobname)
            else
                alert(MESSAGES.OLD_RUN_DISABLED, job.__jobname)
            end
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

        if job.Update and job.UpdateRate then
            table.insert(loaded_loops, {job, job.UpdateRate, 0, false})
        end

        if job.Tick then
            local target_priority = job.TickPriority or 999

            if loaded_ticks[target_priority] then
                target_priority += 1
            end

            table.insert(loaded_ticks, target_priority, {job, job.TickRate or 1, 0})
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
