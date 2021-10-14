local ChinaPolicyService = {}

--[[

	This module is a proxy for the IsSubjectToChinaPolicies value in PolicyService::GetPolicyInfoForPlayerAsync.
	
	Please use it like this to check whether you need to adjust your content: (for this entire server/client)
	
		local ChinaPolicyService = require(path.to.module)
		
		if ChinaPolicyService:IsActive() then
			-- this server/client runs in China and should be made compliant
		else
			-- this server/client does not run in China and does not need to be made compliant
		end
		
	You can also use ChinaPolicyService:IsActiveForPlayer(player) to get the policy for just a specific player.
	
	--------------------------------------------------------------------------------------------------------
	
	WARNING: On the server, please use ChinaPolicyService:WaitForReady() before trying to call ChinaPolicyService:IsActive()
	
	Please also note that a second value is returned that describes if fetching the policy failed and a default was assumed:
	
		local active, default = ChinaPolicyService:IsActive()
		if active and default then
			warn("The client/server runs in China mode, but this might be a global player, we failed to fetch value")
		end
	
	--------------------------------------------------------------------------------------------------------
	
	You should also have been provided with a ChinaPolicyPlugin script that you can use to easily change
	the settings of this module.
	
	We use this module rather than PolicyService:GetPolicyInfoForPlayerAsync directly, to make sure that
	our teams of testers can still test in your games without needing to play on actual Chinese servers.
	This is because in addition to using PolicyService, this module also has a group whitelist on top.

--]]

local DEFAULT_POLICY = false -- policy value to use when policy fetch fails

local TESTER_GROUPID = 9170755 -- the group of testers Roblox will use to test China Initiative games

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")

local active -- policy value for entire client/server
local ready = false -- whether `active` is the final value
local default = false -- whether policy is a default because we failed to fetch policy values

local changed = Instance.new("BindableEvent") -- for firing changes on `active`
local readySignal = Instance.new("BindableEvent") -- for firing when the final value for `active` is set

local isForced = false -- whether policy is forced for all players
local doGroupCheck = true -- whether policy is (additionally) determined by group membership to tester group

-- Find plugin setting values
for _, child in pairs(script:GetChildren()) do
	if child:IsA("BoolValue") then
		if child.Name == "Forced" then
			isForced = child.Value
		elseif child.Name == "DisableGroupCheck" then
			doGroupCheck = not child.Value
		end
	end
end

-- Helper function for remote calls
local function retry(times, func)
	for i = 1, times do
		local success, value = pcall(func)
		if success then
			return value
		end
		wait(i/2) -- back-off
	end
end

local policyCache = {}
local defaultForPlayers = {} -- for which players did the policy checks fail?

-- Whether policy is active
local function getPolicyActive(player)
	-- Compute the cached values if not yet computed
	if policyCache[player] == nil then
		local policy
	
		if isForced then
			-- Always on when forced
			policy = true
		else
			-- Try actual policy value first
			policy = retry(3, function()
				return PolicyService:GetPolicyInfoForPlayerAsync(player).IsSubjectToChinaPolicies
			end)
			
			if doGroupCheck and not policy and player.UserId > 0 then
				-- Group check is active
				local isInGroup = retry(3, function()
					return player:IsInGroup(TESTER_GROUPID)
				end)
				
				-- Force policy enabled for those in the group
				if isInGroup then
					policy = true
				end
			end
		end
		
		-- Make sure player hasn't left game in mean-time, to prevent memory leaking
		if player.Parent == Players then
			
			-- Cache player policy
			if policy == nil then
				--warn("[ChinaPolicyService] Failed to obtain policy for " .. player.UserId .. ", resorting to default policy value")
				policyCache[player] = DEFAULT_POLICY
			else
				policyCache[player] = policy
			end
			
			-- Whether policy is default value
			defaultForPlayers[player] = (policy == nil)
			
		end
	end
	
	-- Now return cached values
	return policyCache[player], defaultForPlayers[player]
end

-- Clean up entries when a player leaves
Players.PlayerRemoving:Connect(
	function(player)
		policyCache[player] = nil
		defaultForPlayers[player] = nil
	end
)

if RunService:IsServer() then

	-- On the server, assume default until a player joins
	active = isForced
	
	if not active then
		
		local connection
		
		local function onPlayerAdded(player)
			if not connection then
				-- Safeguard in case multiple players join in exact same frame
				return
			end
			
			-- Stop listening for new players
			connection:Disconnect()
			connection = nil
			
			-- Set policy based on player
			active, default = getPolicyActive(player)
			ready = true
			if active then
				changed:Fire(active, default)
			end
			
			-- Inform WaitForReady yielders
			readySignal:Fire(active, default)
		end
		
		-- Listen for first player added
		connection = Players.PlayerAdded:Connect(onPlayerAdded)
		if #Players:GetPlayers() > 0 then
			onPlayerAdded(Players:GetPlayers()[1])
		end
		
	else
		
		-- Value already `true`, so won't change
		ready = true
		
	end

else

	-- On the client, just check if the local player is in the tester group
	active, default = getPolicyActive(Players.LocalPlayer)
	ready = true
	
end

-- Whether the policy is currently active for client/server as a whole
function ChinaPolicyService:IsActive()
	return active, default
end

-- Whether ChinaPolicyService:IsActive() is the final value
function ChinaPolicyService:IsReady()
	return ready
end

-- Wait for the final value for this node (when first player has joined)
function ChinaPolicyService:WaitForReady()
	if ready then
		-- Already final
		return active, default
	end
	
	-- Wait for final value
	return readySignal.Event:Wait()
end

-- For listening to changes in policy for client/server as a whole (only does something on the server)
ChinaPolicyService.Changed = changed.Event

-- Whether the policy is currently active for a specific player (will cache after first call)
function ChinaPolicyService:IsActiveForPlayer(player)
	-- Ensure input is a player object
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		error("bad argument #1 to 'IsActiveForPlayer' (Player expected, got " .. typeof(player) .. ")", 2)
	end
	
	-- Delegate to helper to compute and cache policy values
	return getPolicyActive(player)
end

return ChinaPolicyService
