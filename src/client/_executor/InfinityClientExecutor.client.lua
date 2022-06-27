--[[
    InfinityClientExecutor.client.lua
    By FriendlyBiscuit
    05/01/2022 @ 20:36:28
    
    Description:
        Infinity 6 main client job executor.
--]]

--= Dependencies =--
local Promise               = require(script.Parent:WaitForChild('Promise'))
local flags                 = require(script.Parent:WaitForChild('Flags'))

--= Object References =--
local shared_jobs           = game.ReplicatedStorage:WaitForChild('jobs')
local local_jobs            = script.Parent.Parent:WaitForChild('jobs')
local default_callbacks     = script.Parent:WaitForChild('DefaultCallbacks')

--= Constants =--
local PROMISE_TYPE          = { NONE = 'None', YIELD = 'Yield', ASYNC = 'Async' }
local MESSAGES              = {
    NOT_FAST_ENOUGH         = '%s\'s ::Immediate() callback ran too slow. This function should run instantly; check for yields.';
    JOB_ERROR               = '%s\'s ::%s() callback errored during execution. Promise trace:\n$REP\n%s';
}

--= Variables =--
local preloaded_members     = { }

--= Internal Functions =--
local function format(template: string, ...): string
    return '[InfinityClient] ' .. MESSAGES[template]:format(...):gsub('%$REP', string.rep('-', 40))
end

local function handle_job_error(promise_trace: string, job: {}, member: string)
    warn(format('JOB_ERROR', job.__jobname, member, promise_trace))
end

local function preload_default_callbacks()
    for _, member_module in pairs(default_callbacks:GetChildren()) do
        local member_data = require(member_module)
        
        if member_data.Preload then
            member_data:Preload()
        end
        
        for _, alias in pairs(member_data.Aliases) do
            table.insert(preloaded_members, {
                Alias = alias,
                ExecutionOrder = member_data.ExecutionOrder,
                PromiseType = member_data.PromiseType,
                Handle = member_data.Handle
            })
        end
    end
    
    table.sort(preloaded_members, function(a: {}, b: {})
        return a.ExecutionOrder < b.ExecutionOrder
    end)
end

local function lazy_load_folder(root: Instance): {table}
    local result = { }
    
    local function recurse(object: Instance)
        for _, child in pairs(object:GetChildren()) do
            if child:IsA('ModuleScript') then
                local module_data = require(child)
                module_data.__jobname = child.Name
                module_data.FLAGS = flags
                
                if module_data.Enabled == false then continue end
                
                if module_data.Immediate then
                    local routine = coroutine.create(module_data.Immediate)
                    
                    coroutine.resume(routine)
                    
                    if coroutine.status(routine) ~= 'dead' then
                        warn(format('NOT_FAST_ENOUGH', module_data.__jobname))
                    end
                end
                
                if not module_data.Priority then
                    module_data.Priority = #result + 1
                end
                
                table.insert(result, module_data)
            else
                recurse(child)
            end
        end
    end
    
    recurse(root)
    
    return result
end

local function load_jobs(target: Folder)
    local job_modules = lazy_load_folder(target)
    
    table.sort(job_modules, function(a: {}, b: {})
        if a.Priority and b.Priority then
            return a.Priority < b.Priority
        end
        
        return false
    end)
    
    for _, member in ipairs(preloaded_members) do
        for _, job in ipairs(job_modules) do
            local target_callback = job[member.Alias]
            
            if target_callback then
                if member.PromiseType and member.PromiseType ~= PROMISE_TYPE.NONE then
                    local handle_promise = Promise.promisify(function()
                        member.Handle(job, target_callback)
                    end)
                    
                    if member.PromiseType == PROMISE_TYPE.ASYNC then
                        handle_promise():catch(function(promise_error: {})
                            handle_job_error(promise_error.trace, job, member.Alias)
                        end)
                    else
                        handle_promise():catch(function(promise_error: {})
                            handle_job_error(promise_error.trace, job, member.Alias)
                        end):await()
                    end
                else
                    member.Handle(job, target_callback)
                end
            end
        end
    end
end

preload_default_callbacks()
load_jobs(local_jobs)
load_jobs(shared_jobs)