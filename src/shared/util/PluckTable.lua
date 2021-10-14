--[[
    PluckTable.lua
    FriendlyBiscuit
    Created on 05/15/2021 @ 22:36:35

    Description:
        Quick utility function to navigate through a table with string paths.

    Documentation:
        <any> PluckTable(input:table, query:string)
        -> Iterates through the input table using nodes parsed from the query
           path.
        
    Example:
        local test = {
            FirstKey = {
                ChildKey = 'Hello, world!'
            }
        }
        
        print(PluckTable(test, 'FirstKey/ChildKey'))
        -> Should print "Hello, world!" to the output.
--]]


return function(input: table, query: string): any
    local result = nil
    local _last = nil
    local _nodes = { }
    
    for match in query:gmatch('([^/]+)') do
        table.insert(_nodes, match)
    end
    
    for _, node in pairs(_nodes) do
        if not result then
            if input[node] then
                result = input[node]
            else
                warn('!!! Failed to pluck() table after reaching', node)
                result = nil
            end
        else
            if result[node] then
                result = result[node]
            else
                warn('!!! Failed to pluck() table after reaching', node)
                result = nil
            end
        end
    end
    
    return result
end