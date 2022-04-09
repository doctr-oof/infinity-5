--[[
    ReplicatorServer.lua
    FriendlyBiscuit
    Created on 06/22/2021 @ 22:36:43
    
    Description:
        Adds a single-lane queued network event to quickly receive client data
        sent to the server, as well as send data to clients.
    
    Documentation:
        <nil> ::Listen(name: string, callback: (client: Player, ...)->())
        -> Listens to the target event and fires the callback with any data passed.
           Since this is on the server, the first argument passed will always be the
           player that fired this event.
        
        <nil> ::BroadcastAll(name: string, ...: tuple)
        -> Fires the target event and data to all players.
        
        <nil> ::BroadcastOthers(name: string, skip: Player, ...: tuple)
        -> Fires the target event and data to all players EXCEPT the specified player.
        
        <nil> ::Broadcast(name: string, target: Player, ...: tuple)
        -> Fires the target event and data to the specified player.
--]]

--= Module Loader =--
local require       = require(game.ReplicatedStorage:WaitForChild('Infinity'))

--= Root =--
local Replicator    = { }

--= Modules & Config =--
local network       = require('$lib/Network')
local out           = require('$util/EasyOutput')

--= Roblox Services =--
local player_svc    = game:GetService('Players')

--= Variables =--
local events        = { }

--= Job API =--
function Replicator:Listen(name: string, callback: (client: Player, any)->()): nil
    if events[name] then
        table.insert(events[name], callback)
    else
        events[name] = { callback }
    end
end

function Replicator:BroadcastAll(name: string, ...): nil
    network:Fire('PACKET', name, ...)
end

function Replicator:BroadcastOthers(name: string, skip: Player, ...): nil
    for _, player in pairs(player_svc:GetPlayers()) do
        if player ~= skip then
            network:Fire('PACKET', player, name, ...)
        end
    end
end

function Replicator:Broadcast(name: string, target: Player, ...): nil
    network:Fire('PACKET', target, name, ...)
end

--= Job Initializers =--
function Replicator:InitAsync(): nil
    network:Fired('PACKET', function(client: Player, name: string, ...)
        local event_data = events[name]
        
        if event_data then
            for _, callback in pairs(event_data) do
                callback(client, ...)
            end
        else
            out.warn('Failed to replicate event %q - no event registered.', name)
        end
    end)
end

function Replicator:Init(): nil
    network:RegisterEvent('PACKET')
end

--= Return Job =--
return Replicator