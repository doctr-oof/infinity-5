--[[
    EasyOutput.lua
    FriendlyBiscuit
    Created on 03/02/2021 @ 19:11:18
    
    Description:
        No description provided.
    
    Documentation:
        No documentation provided.
--]]

--= Root =--
local EasyOutput        = { }

--= Constants =--
local suppress_print    = false
local whitelist         = { }
local blacklist         = { 'LODServer', 'LODClient' }

--= API =--
function EasyOutput.print(msg: variant, ...)
    if suppress_print then return end
    
    local name = getfenv(2).script.Name
    
    if #whitelist > 0 and not table.find(whitelist, name) then return end
    if table.find(blacklist, name) then return end
    
    local output = ('[%s] %s'):format(name, msg)
    
    if #{...} > 0 then
        output = output:format(...)
    end
    
    print(output)
end

function EasyOutput.warn(msg: variant, ...)
    local output = ('[%s] %s'):format(getfenv(2).script.Name, msg)
    
    if #{...} > 0 then
        output = output:format(...)
    end
    
    warn(output)
end

function EasyOutput.err(msg: string, ...)
    error(msg:format(...), 2)
end

--= Return Module =--
return EasyOutput