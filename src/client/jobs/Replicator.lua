--[[
    Replicator.lua
    FriendlyBiscuit
    Created on 06/22/2021 @ 22:59:56
    
    Description:
        Adds a single-lane queued network event to quickly fire-and-forget data to
        the server in order of call.
    
    Documentation:
        <nil> ::Listen(name: string, callback: Function)
        -> Listens to the target event and fires the callback with any data passed.
        
        <nil> ::Send(name: string, ...: tuple)
        -> Fires and forgets the target event.
           
           NOTE: Your data is not guaranteed to be sent immediately as it is technically
           pooled into the built-in BindableEvent queue.
--]]

--= Module Loader =--
local require       = require(game.ReplicatedStorage:WaitForChild('Infinity'))

--= Root =--
local Replicator    = { }

--= Modules & Config =--
local network       = require('$lib/Network')
local out           = require('$util/EasyOutput')

--= Variables =--
local events        = { }

--= Job API =--
function Replicator:Listen(name: string, callback: Function): nil
    if events[name] then
        table.insert(events[name], callback)
    else
        events[name] = { callback }
    end
end

function Replicator:Send(name: string, ...): nil
    network:Fire('PACKET', name, ...)
end

--= Job Initializers =--
function Replicator:InitAsync(): nil
    network:Fired('PACKET', function(name: string, ...)
        local event_data = events[name]
        
        if event_data then
            for _, callback in pairs(event_data) do
                callback(...)
            end
        else
            out.warn('Failed to handle replicated event %q - no listener registered.', name)
        end
    end)
end

--= Return Job =--
return Replicator