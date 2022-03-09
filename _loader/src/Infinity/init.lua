--= Pathing =--
local prefix_paths = {
    ['%$'] = game.ReplicatedStorage
}

--= Roblox Services =--
local run_svc = game:GetService('RunService')

--= Internal Functions =--
function split(input: string): table
    local result = { }
    
    for match in input:gmatch('([^/]+)') do
        table.insert(result, match)
    end
    
    return result
end

function get_root_path(first_node: string): any
    local fix_len = 0
    local root
    
    for prefix, path in pairs(prefix_paths) do
        if first_node:find(prefix) == 1 then
            root = path
            fix_len = #prefix
        end
    end
    
    if not root then
        if run_svc:IsClient() then
            root = game.Players.LocalPlayer:WaitForChild('PlayerScripts')
        else
            root = game:GetService('ServerScriptService')
        end
    end
    
    return root, fix_len
end

--= Main Loader Function =--
function Infinity(query: string|ModuleScript): any
    if type(query) == 'string' then
        local nodes = split(query)
        local root, fix_len = get_root_path(nodes[1])
        local result
        
        nodes[1] = nodes[1]:sub(fix_len)
        
        for _, node in pairs(nodes) do
            if not result then
                if root[node] then
                    result = root[node]
                end
            elseif result[node] then
                result = result[node]
            else
                warn(('[Infinity] Failed to require %q - node/module %q not found.'):format(query, node))
                result = nil
            end
        end
        
        return result and require(result) or nil
    else
        return require(query)
    end
end

--= Return =--
return Infinity