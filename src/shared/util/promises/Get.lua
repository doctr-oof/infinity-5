--[=[
    Deepsearches an Instance for a specified object and returns the object
    wrapped in a promise.

    - Refactor

    ```lua
        local PromiseGet = require('$util/promises/Get')

        PromiseGet(workspace, 'Baseplate')
            :andThen(function(baseplate)
                -- make baseplate red!
                baseplate.Color = Color3.fromRGB(255, 0, 0)
            end)
            :catch(warn) -- if object isnt found it will return a string.
    ```

    @shared
]=]

-- Infinity
local require = require(game:GetService('ReplicatedStorage'):WaitForChild('Infinity'))

-- Modules
local Promise = require('$lib/Promise')

return function(root : Instance, target: string): Promise
    return Promise.new(function(resolve, reject)
        local descendants = root:GetDescendants()
    
        for _, v in pairs(descendants) do
            if (v.Name == target) then
                resolve(v)
                break
            end
        end
        
        reject(string.format('[PromiseGet] Could not find %s.', target))
    end)
end