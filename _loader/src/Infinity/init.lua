--[[
    Infinity.lua
    By FriendlyBiscuit
    05/02/2022 @ 14:13:53
    
    Description:
        Main Infinity 6 Module Loader.
--]]

--= Dependencies =--
local Promise = require(script:WaitForChild('Promise'))

--= Roblox Services =--
local run_svc = game:GetService('RunService')

--= Pathing =--
local PREFIX_PATHS = {
    ['%$'] = game.ReplicatedStorage
}

--= Error Messages =--
local MESSAGES = {
    REQUIRE_ERROR = 'Failed to require %q - the target module errored during require. Promise trace:\n$REP\n%s',
    REQUIRE_NODE_NOT_FOUND = 'Failed to require %q - node/module %q not found.',
    FETCH_REQUIRE_NOT_FOUND = 'Failed to require %q - no module with that name found in the specified context.'
}

--= Internal Functions =--
local function format(template: string, ...: any): string
    return '[InfinityLoader] ' .. MESSAGES[template]:format(...):gsub('%$REP', string.rep('-', 40))
end

local function split(input: string): {string}
    local result = { }
    
    for match in input:gmatch('([^/]+)') do
        table.insert(result, match)
    end
    
    return result
end

local function get_root_path(first_node: string): any
    local fix_len = 0
    local root
    
    for prefix, path in pairs(PREFIX_PATHS) do
        if first_node:find(prefix) == 1 then
            root = path
            fix_len = #prefix
        end
    end
    
    if not root then
        if not run_svc:IsRunning() then
            root = game:GetService('StarterPlayer').StarterPlayerScripts
        elseif run_svc:IsClient() then
            root = game.Players.LocalPlayer:WaitForChild('PlayerScripts')
        else
            root = game:GetService('ServerScriptService')
        end
    end
    
    return root, fix_len
end

local function get(root: Instance, query: string): Instance|nil
    for _, descendant in pairs(root:GetDescendants()) do
        if descendant.Name:lower() == query:lower() then
            return descendant
        end
    end
    
    return nil
end

local function fetch_descendant_timeout(root: Instance, query: string): Instance|nil
    local result = get(root, query)
    local start_time = tick()
    
    if result == nil then
        while not result do
            result = get(root, query)
            if result or (tick() - start_time) >= 15 then break end
            task.wait()
        end
    end
    
    return result
end

--= Main Loader Function =--
function Infinity(query: string|ModuleScript): any
    if type(query) == 'string' then
        local nodes = split(query)
        local root, fix_len = get_root_path(nodes[1])
        local target_module, result
        
        nodes[1] = nodes[1]:sub(fix_len)
        
        if #nodes == 1 then
            target_module = fetch_descendant_timeout(root, nodes[1])
            
            if target_module then
                Promise.new(function(resolve: (module_data: any) -> ())
                    resolve(require(target_module))
                end):andThen(function(module_data: any)
                    result = module_data
                end):catch(function(promise_error: {})
                    warn(format('REQUIRE_ERROR', query, promise_error.trace))
                end):await()
            else
                warn(format('FETCH_REQUIRE_NOT_FOUND', query))
            end
        else
            for _, node in pairs(nodes) do
                if not target_module then
                    if root:WaitForChild(node, 0.5) then
                        target_module = root[node]
                    end
                elseif target_module:WaitForChild(node, 0.5) then
                    target_module = target_module[node]
                else
                    warn(format('REQUIRE_NODE_NOT_FOUND', query, node))
                    target_module = nil
                end
            end
            
            Promise.new(function(resolve: (module_data: any) -> ())
                resolve(require(target_module))
            end):andThen(function(module_data: any)
                result = module_data
            end):catch(function(promise_error: {})
                warn(format('REQUIRE_ERROR', query, promise_error.trace))
            end):await()
        end
        
        return result
    else
        return require(query)
    end
end

--= Return =--
return Infinity