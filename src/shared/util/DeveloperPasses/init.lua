
local RunService = game:GetService('RunService')
local MarketService = game:GetService('MarketplaceService')
local DataService = game:GetService('DataStoreService')

local DeveloperPasses = { }
local Types = require(script.Types)

export type DeveloperPass = Types.DeveloperPass
export type Error = Types.Error

local NO_CALLBACK_WARNING : Error = { Fatal = false, Message = 'No callback supplied for product [%d]!!!' }
local PLAYER_ALREADY_OWNS_PASS : Error = { Fatal = false, Message = 'Player already owns pass!!!' }

local cache = { }
local purchase_cache = { }

local function display_error(err: Error, productid: number?)
	if err.Fatal then
		return error(err.Message)
	end
	warn(err.Message)
end

local function is_cached(player: Player, productid: number)
	if not purchase_cache[productid] then
		purchase_cache[productid] = { }
	end
	return purchase_cache[productid][player]
end

if RunService:IsServer() then
    if script:FindFirstChild('RemoteFunction') == nil then
        Instance.new('RemoteFunction', script)
    end

    if script:FindFirstChild('RemoteEvent') == nil then
        Instance.new('RemoteEvent', script)
    end

	local get_method, set_method = nil, nil

	local function player_has_pass(player: Player, passid: number) : boolean
		if get_method ~= nil then
			return get_method(player, passid)
		end
		return false
	end

	function DeveloperPasses.RegisterPass(id: number, name: string?, callback: () -> Player)
		local developer_pass : DeveloperPass = {
			Name = name,
			ProductId = id,
			Callback = callback }

		purchase_cache[id] = {}
		cache[id] = developer_pass
	end

	function DeveloperPasses.RegisterCallback(id: number, callback: () -> Player)
		if not cache[id] then
			DeveloperPasses.RegisterPass(id, '', callback)
		else
			cache[id].Callback = callback
		end
	end

	function DeveloperPasses.ProductPurchasedHandle(id: number, player: Player)
		if cache[id] then
			purchase_cache[id][player] = true
			if cache[id].Callback then
				cache[id].Callback(player)
				-- ADD TO A DATABASE?
				if set_method  ~= nil then
					set_method(player, id)
				end
				return true
			else
				display_error(NO_CALLBACK_WARNING, id)
				return false
			end
		end
	end

	function DeveloperPasses:PromptProductPurchase(player: Player, id: number)
		if is_cached(player, id) or player_has_pass(player, id) then
			display_error(PLAYER_ALREADY_OWNS_PASS)
			return
		end

		-- we can prompt, not cached or owned..
		MarketService:PromptProductPurchase(player, id)
	end

	function DeveloperPasses:_OwnsPass(player, id)
		--print('i am checking for', player, id)
		if is_cached(player, id) or player_has_pass(player, id) then
			return true
		end
		return false
	end

	function DeveloperPasses.SetSaveMethod(callback)
		set_method = callback
	end

	function DeveloperPasses.SetGetMethod(callback)
		get_method = callback
	end

	script.RemoteEvent.OnServerEvent:Connect(function(player: Player, event: string, id: number)
		if (event == 'PromptProductPurchase') then
			DeveloperPasses:PromptProductPurchase(player, id)
		end
	end)

	script.RemoteFunction.OnServerInvoke = function(player, event: string, id: number)
		if event == 'HasPass' then
			return DeveloperPasses:_OwnsPass(player, id)
		end
	end
end

function DeveloperPasses:PromptPurchase(id: number, player: Player?)
	if RunService:IsClient() then
		script.RemoteEvent:FireServer('PromptProductPurchase', id)
		return
	end
	self:PromptProductPurchase(player, id)
end

function DeveloperPasses:HasPass(id: number, player: Player?) : boolean
	if RunService:IsClient() then
		return script.RemoteFunction:InvokeServer('HasPass', id)
	end

	return self:_OwnsPass(player, id)
end

return DeveloperPasses