--[[
    Replicator.lua
    FriendlyBiscuit
    Created on 05/02/2022 @ 16:05:36
    
    Description:
        Server side network event replication queue handler.
        Allows you to listen to client-queued RemoteEvent calls as well as send queued events to clients.
    
    Documentation:
        <void> ::Listen(eventKey: string, callback: (sender: Player, ...any) -> ())
        -> Creates a listener for the specified key that executes the callback when that event is received.
           Example:
           
           Replicator:Listen("SERVER_MESSAGE", function(sender: Player, message: string)
               print(("Server received a message from %s: %s"):format(client.Name, message))
           end)
        
        <void> ::SendToAll(eventKey: string, ...: any)
        -> Replicates the event to all players currently connected.
           Example:
           
           Replicator:SendToAll("CLIENT_MESSAGE", "Hello, world!")
        
        <void> ::SendToPlayer(eventKey: string, target: Player, ...: any)
        -> Replicates the event to the specified player.
           Example:
           
           Replicator:SendToPlayer("CLIENT_MESSAGE", game.Players.FriendlyBiscuit, "Hello, world!")
        
        <void> ::SendToPlayers(eventKey: string, players: {Player}, ...: any)
        -> Replicates the event to the specified list of players.
           Example:
           
           Replicator:SendToPlayers("CLIENT_MESSAGE", { game.Players.Player1, game.Players.Player2 }, "Hello, world!")
        
        <void> ::SendToOthers(eventKey: string, skip: Player, ...: any)
        -> Replicates the event to all players in the game except the specified player.
           Example:
           
           Replicator:SendToOthers("CLIENT_MESSAGE", game.Players.FriendlyBiscuit, "HELLO, WORLD!")
--]]

--= Root =--
local Replicator    = { Priority = 1 }

--= Roblox Services =--
local rep_svc       = game:GetService('ReplicatedStorage')
local player_svc    = game:GetService('Players')

--= Object References =--
local main_event

--= Constants =--
local EVENT_UUID    = game.JobId
local MESSAGES      = {
    NO_LISTENER     = 'Failed to handle replicated event %q from %q - no event listener registered!';
    STUDIO_MODE     = 'Running in Studio Environment Mode.';
}

--= Variables =--
local listeners     = { }

--= Internal Functions =--
local function format(template: string, ...: any): string
    return '[ReplicatorServer] ' .. MESSAGES[template]:format(...)
end

--= Job API =--
function Replicator:Listen(key: string, callback: (client: Player, ...any) -> ())
    local listener = listeners[key]
    
    if listener then
        table.insert(listener, callback)
    else
        listeners[key] = { callback }
    end
end

function Replicator:SendToAll(key: string, ...: any)
    main_event:FireAllClients(key, ...)
end

function Replicator:SendToPlayer(key: string, target: Player, ...: any)
    main_event:FireClient(target, key, ...)
end

function Replicator:SendToPlayers(key: string, targets: {Player}, ...: any)
    for _, player in pairs(player_svc:GetPlayers()) do
        if table.find(targets, player) then
            main_event:FireClient(player, key, ...)
        end
    end
end

function Replicator:SendToOthers(key: string, skip: Player, ...: any)
    for _, player in pairs(player_svc:GetPlayers()) do
        if player ~= skip then
            main_event:FireClient(player, key, ...)
        end
    end
end

--= Job Initializers =--
function Replicator:Init()
    if EVENT_UUID == '' or self.FLAGS.IS_STUDIO then
        EVENT_UUID = 'REPLICATOR_STUDIO'
        warn('[ReplicatorServer] ' .. MESSAGES.STUDIO_MODE)
    end
    
    main_event = Instance.new('RemoteEvent')
    main_event.Name = EVENT_UUID
    main_event.Parent = rep_svc
    
    main_event.OnServerEvent:Connect(function(client: Player, key: string, ...)
        local listener = listeners[key]
        
        if listener then
            for _, callback in pairs(listener) do
                callback(client, ...)
            end
        else
            warn(format('NO_LISTENER', key, client.name))
        end
    end)
end

--= Return Job =--
return Replicator