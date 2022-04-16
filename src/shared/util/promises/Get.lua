--[[
    Get.lua
    - Refactor
--]]

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
        
        reject(nil)
    end)
end