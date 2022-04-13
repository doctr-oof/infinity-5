--[[
    Network.lua
    Refactor & ChiefWildin
    Created on 02/07/2022 @ 11:06:07

    Description:
        Simple networking module for Infinity.

    Documentation:
        [client] ::BatchRegister(list: table): nil
            (list: table) -> { object_name: string, object_type: string ("RemoteEvent" or "RemoteFunction") }
            -> Create RemoteEvents and RemoteFunctions with one function call.

        [server] ::RegisterFunction(function_name: string, callback: (Player, any) -> (any)): nil
            -> Register RemoteFunction

        [server] ::RegisterEvent(event_name: string, callback: (Player, any) -> (any)): nil
            -> Register RemoteEvent

        [server/client] ::Fired(event_name: string, callback(player: Player?)): nil
            ?player = optional, will always be first argument if fired to the server.
            -> Register Callback for RemoteEvent execution.

        [server/client] ::Invoked(event_name: string, callback(player: Player?)): any
            ?player = optional, will always be first argument if fired to the server.
            -> Register Callback for RemoteFunction execution.

        [server/client] ::Promised(event_name: string, callback(player: Player?)): nil
        ##### DO NOT USE THIS #####
            ?player = optional, will always be first argument if fired to the server.
            -> Register a Promised Callback for RemoteEvent execution.

        [server/client] ::InvokePromise(event_name: string, ...args): Promise
--]]


--= Module Loader =--
local require = require(game.ReplicatedStorage:WaitForChild("Infinity"))

--= Class Root =--
local Network = {}
Network.__classname = "NetworkNew"

--= Controllers =--

--= Other Classes =--

--= Modules & Config =--
local Promise = require("$lib/Promise")

--= Roblox Services =--
local RunService = game:GetService("RunService")

--= Instance References =--
local Events = {}
local Functions = {}

--= Constants =--
local IS_CLIENT = RunService:IsClient()
local ERRORS = {
    CANT_FIND_REMOTE_EVENT                  = "RemoteEvent <%s> has not been registered by the server",
    CANT_FIND_REMOTE_EVENT_SUGGEST_FUNCTION = "RemoteEvent <%s> has not been registered by the server, are you looking for the RemoteFunction <%s>?",
    CANT_FIND_REMOTE_FUNCTION               = "RemoteFunction <%s> has not been registered by the server",
    CANT_FIND_REMOTE_FUNCTION_SUGGEST_EVENT = "RemoteFunction <%s> has not been registered by the server, are you looking for the RemoteEvent <%s>?",
}

--= Variables =--
local Indexed = not IS_CLIENT

--= Shorthands =--

--= Functions =--

--= Class Internal =--

--= Class API =--

if not IS_CLIENT then
    -- don't expose this to the client
    function Network:BatchRegister(evt_list): nil
        for _, evt in pairs(evt_list) do
            if evt[2] == "RemoteEvent" then
                self:RegisterEvent(evt[1])
            elseif evt[2] == "RemoteFunction" then
                self:RegisterFunction(evt[1])
            end
        end
    end

    function Network:RegisterEvent(RemoteName: string, Callback: (Player, any) -> (any)): nil
        local Remote = Events[RemoteName]
        if not Remote then
            Remote = Instance.new("RemoteEvent")
            Remote.Name = RemoteName
            Remote.Parent = script
            Events[RemoteName] = Remote
        end

        if Callback then
            Remote.OnServerEvent:Connect(Callback)
        end
    end
    
    function Network:RegisterFunction(RemoteName: string, Callback: (Player, any) -> (any)): nil
        local Remote = Functions[RemoteName]
        if not Remote then
            Remote = Instance.new("RemoteFunction")
            Remote.Name = RemoteName
            Remote.Parent = script
            Functions[RemoteName] = Remote
        end

        if Callback then
            Remote.OnServerInvoke = Callback
        end
    end
else
    local function IndexChild(child: Instance)
        if child:IsA("RemoteEvent") then
            Events[child.Name] = child
        elseif child:IsA("RemoteFunction") then
            Functions[child.Name] = child
        end
    end

    -- Index any new remotes as they are added
    script.ChildAdded:Connect(IndexChild)

    -- Index existing remotes
    for _, v in pairs(script:GetChildren()) do
        IndexChild(v)
    end

    Indexed = true
end

function Network:GetEvent(evt: string): RemoteEvent|nil
    while not Indexed do task.wait() end

    local event = Events[evt]
    if event then
        return event
    elseif Functions[evt] then
        warn(ERRORS.CANT_FIND_REMOTE_FUNCTION_SUGGEST_EVENT:format(evt, evt))
        print(debug.traceback())
    else
        warn(ERRORS.CANT_FIND_REMOTE_EVENT:format(evt))
        print(debug.traceback())
    end
end

function Network:GetFunction(func: string): RemoteFunction|nil
    while not Indexed do task.wait() end

    local remote = Functions[func]
    if remote then
        return remote
    elseif Events[func] then
        warn(ERRORS.CANT_FIND_REMOTE_FUNCTION_SUGGEST_EVENT:format(func, func))
        print(debug.traceback())
    else
        warn(ERRORS.CANT_FIND_REMOTE_FUNCTION:format(func))
        print(debug.traceback())
    end
end

function Network:Fired(evt, callback): nil
    local event = self:GetEvent(evt)
    if event then
        if IS_CLIENT then
            event.OnClientEvent:Connect(callback)
        else
            event.OnServerEvent:Connect(callback)
        end
    end
end

function Network:Invoked(func, callback): nil
    local remote = self:GetFunction(func)
    if remote then
        if IS_CLIENT then
            remote.OnClientInvoke = callback
        else
            remote.OnServerInvoke = callback
        end
    end
end

function Network:Promised(func, callback): nil
    local remote = self:GetFunction(func)
    if remote then
        if IS_CLIENT then
            remote.OnClientInvoke = Promise.promisify(callback)
        else
            remote.OnServerInvoke = Promise.promisify(callback)
        end
    end
end

function Network:Fire(evt_name, ...)
	local args = { ... }
	local evt = self:GetEvent(evt_name)

	if evt then
		if IS_CLIENT then
			evt:FireServer(...)
		else
			if typeof(args[1]) == "Instance" and args[1]:IsA("Player") then
                local player = table.remove(args, 1)
				evt:FireClient(player, table.unpack(args))
			else
				evt:FireAllClients(...)
			end
		end
	end
end

function Network:Invoke(func_name, ...)
	local args = { ... }
	local func = self:GetFunction(func_name)

	if func then
		if IS_CLIENT then
			return func:InvokeServer(...)
		else
			assert(args[1]:IsA("Player"))

			local player = table.remove(args, 1)
			return func:InvokeClient(player, table.unpack(args))
		end
    else
        warn("Invoke requested on non-existent function", func_name)
	end
end

function Network:InvokePromise(func_name, ...)
	local args = { ... }
	local func = self:GetFunction(func_name)

	if func then
		if IS_CLIENT then
			return Promise.new(function(resolve)
                resolve(func:InvokeServer(table.unpack(args)))
            end)
		else
			assert(args[1]:IsA('Player'))

			local sliced = { ... }
			table.remove(sliced, 1)
			return Promise.new(function(resolve) resolve(func:InvokeClient(args[1], table.unpack(sliced))) end)
		end
	end
end

return Network
