--[[
    Resources.lua
    FriendlyBiscuit
    Created on 05/18/2021 @ 20:10:27
    
    Description:
        Resource Fetch Library.
    
    Documentation:
        <userdata> ::Fetch(query: string)
        -> Waits for an asset to appear in the target folder and then returns
           a clone as the result.
        
        <userdata> ::Get(query: string)
        -> Attempts to clone and return an asset. If the asset is nil, this function
           will error.
--]]


--= Root Tables =--
local Resources = { }

--= Object References =--
local storage   = game.ReplicatedStorage:FindFirstChild('assets')

if not storage then
    storage = Instance.new('Folder')
    storage.Name = 'assets'
end

--= API =--
function Resources:Fetch(query: string): any
    local result = nil
    local _nodes = { }
    local _first
    
    for str in query:gmatch('([^/]+)') do
        table.insert(_nodes, str)
    end
    
    for _, value in pairs(_nodes) do
        if not result then
            result = storage:WaitForChild(value)
        else
            result = result:WaitForChild(value)
        end
    end
    
    return result:Clone()
end

function Resources:Get(query: string): any
    local result = nil
    local _nodes = { }
    local _first
    
    for str in query:gmatch('([^/]+)') do
        table.insert(_nodes, str)
    end
    
    for _, value in pairs(_nodes) do
        if not result then
            result = storage:FindFirstChild(value)
            
            if not result then break end
        else
            result = result:FindFirstChild(value)
        end
    end
    
    return result:Clone()
end

--= Return Module =--
return Resources