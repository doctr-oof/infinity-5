--[[
    Network.lua
    Retro_Mada
    Created on 02/07/2022 @ 11:06:07
    
    Description:
        Simple networking module for Infinity.
    
    Documentation:
        [client] ::BatchRegister(list: table): nil
            (list: table) -> { object_name: string, object_type: string ('RemoteEvent' or 'RemoteFunction') }
            -> Create RemoteEvents and RemoteFunctions with one function call.

        [server] ::RegisterFunction(function_name: string): nil
            -> Register RemoteFunction

        [server] ::RegisterEvent(event_name: string): nil
            -> Register RemoteEvent

        [server/client] ::Fired(event_name: string, callback(player: Player?)): nil
            ?player = optional, will always be first argument if fired to the server.
            -> Register Callback for RemoteEvent execution.

        [server/client] ::Invoked(event_name: string, callback(player: Player?)): any
            ?player = optional, will always be first argument if fired to the server.
            -> Register Callback for RemoteFunction execution.

        [server/client] ::Promised(event_name: string, callback(player: Player?)): Promise
            ?player = optional, will always be first argument if fired to the server.
            -> Register a Promised Callback for RemoteEvent execution.
--]]

--= Module Loader =--
local require = require(game.ReplicatedStorage:WaitForChild('Infinity'))

--= Class Root =--
local Network         = { }
Network.__classname   = 'NetworkNew'

--= Controllers =--

--= Other Classes =--

--= Modules & Config =--
local promise   = require('$lib/Promise')
--local logger    = require('$ 

--= Roblox Services =--
local run_svc = game:GetService("RunService")


--= Instance References =--

--= Constants =--
local IS_CLIENT = run_svc:IsClient()
local ERRORS = {
    CANT_FIND_REMOTE_EVENT      = 'Could not find RemoteEvent <%s>, are you looking for a RemoteFunction?';
    CANT_FIND_REMOTE_FUNCTION   = 'Could not find RemoteFunction <%s>, are you looking for a RemoteEvent?';
}

--= Variables =--

--= Shorthands =--

--= Functions =--

--= Class Internal =--

--= Class API =--

if not IS_CLIENT then
    -- don't expose this to the client
    function Network:BatchRegister(evt_list): nil
        for _, evt in pairs(evt_list) do
            if evt[2] == 'RemoteEvent' then
                self:RegisterEvent(evt[1])
            elseif evt[2] == 'RemoteFunction' then
                self:RegisterFunction(evt[1])
            end
        end
    end
end

function Network:RegisterEvent(evtName)
    local evt = script:FindFirstChild(evtName)

    if evt and evt:IsA('RemoteEvent') then
        return evt
    end

    local evt = Instance.new('RemoteEvent')
    evt.Name = evtName
    evt.Parent = script
end

function Network:RegisterFunction(evtName)
    local evt = script:FindFirstChild(evtName)

    if evt and evt:IsA('RemoteFunction') then
        return evt
    end

    local evt = Instance.new('RemoteFunction')
    evt.Name = evtName
    evt.Parent = script
end

function Network:GetEvent(evt: string): RemoteEvent|nil
    local event = script:FindFirstChild(evt)
    if event and event:IsA('RemoteEvent') then
        return event
    else
        error(ERRORS.CANT_FIND_REMOTE_EVENT:format(evt))
    end
end


function Network:GetFunction(func: string): RemoteFunction|nil
    local remote = script:FindFirstChild(func)
    if remote and remote:IsA('RemoteFunction') then
        return remote
    else
        error(ERRORS.CANT_FIND_REMOTE_FUNCTION:format(func))
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
            remote.OnClientInvoke = promise.promisify(callback)
        else
            remote.OnServerInvoke = promise.promisify(callback)
        end
    end
end

function Network:Fire(evtName, ...)
	local args = { ... }

	local evt = self:GetEvent(evtName)
    
	if evt then
		if IS_CLIENT then
			evt:FireServer(...)
		else
			if typeof(args[1]) == 'Instance' and args[1]:IsA('Player') then
                local sliced = {...}
                table.remove(sliced, 1)
                evt:FireClient(args[1], table.unpack(sliced))
            else
                evt:FireAllClients(...)
            end
		end
	end
end

function Network:FireAll(evtName, ...)
	local evt = self:GetEvent(evtName)
    
	if evt then
        evt:FireAllClients(...)
	end
end

function Network:Invoke(evtName, ...)
	local args = { ... }

	local evt = self:GetFunction(evtName)
	if evt then
		if IS_CLIENT then
			return evt:InvokeServer(...)
		else
			assert(args[1]:IsA('Player'))
			local sliced = {...}
			table.remove(sliced,1)
			return evt:InvokeClient(args[1], table.unpack(sliced))
		end
	end
end
--= Class Constructor =--


--= Class Properties =--
Network.__properties = { }

--= Return Class =--
return Network