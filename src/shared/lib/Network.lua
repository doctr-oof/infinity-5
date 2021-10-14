local RunService = game:GetService('RunService')

-- Variables
local isClient = RunService:IsClient()

-- Constants
local errors = {
	EVENT_NOT_INITIALIZED = '%s was not initialized on the server.'
}

-- Module
local Network = {}

if not isClient then
	function Network:BatchRegister(events)
		for _, evt in pairs(events) do
			if evt[2] == 'RemoteEvent' then
				self:RegisterEvent(evt)
			elseif evt[2] == 'RemoteFunction' then
				self:RegisterFunction(evt)
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
end

function Network:GetRemote(evtName)
	local evt = script:FindFirstChild(evtName)

	if evt and evt:IsA('RemoteEvent') then
		return evt
	else
		warn(errors.EVENT_NOT_INITIALIZED:format(evtName))
	end
end

function Network:GetFunction(evtName)
	local evt = script:FindFirstChild(evtName)

	if evt and evt:IsA('RemoteFunction') then
		return evt
	else
		warn(errors.EVENT_NOT_INITIALIZED:format(evtName))
	end
end

function Network:Fired(evtName, callback)
	local evt = self:GetRemote(evtName)
	if evt then
		if isClient then
			evt.OnClientEvent:Connect(callback)
		else
			evt.OnServerEvent:Connect(callback)
		end
	end
end

function Network:Invoked(evtName, callback)
	local evt = self:GetFunction(evtName)
	if evt then
		if isClient then
			evt.OnClientInvoke = callback
		else
			evt.OnServerInvoke = callback
		end
	end
end

function Network:Fire(evtName, ...)
	local args = { ... }

	local evt = self:GetRemote(evtName)
    
	if evt then
		if isClient then
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
	local evt = self:GetRemote(evtName)
    
	if evt then
        evt:FireAllClients(...)
	end
end

function Network:Invoke(evtName, ...)
	local args = { ... }

	local evt = self:GetFunction(evtName)
	if evt then
		if isClient then
			return evt:InvokeServer(...)
		else
			assert(args[1]:IsA('Player'))
			local sliced = {...}
			table.remove(sliced,1)
			return evt:InvokeClient(args[1], table.unpack(sliced))
		end
	end
end

return Network