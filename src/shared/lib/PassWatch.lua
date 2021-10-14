--[[
    Passwatch
    > ver 1.0
    > retro_mada

    .watch(player: Player) -> watch
        > creates a watch for new gamepass and existing gamepass purchases.
    .get(player: Player) -> watch
        > if watch does not exist it will automatically invoke .watch and return the watch.

    [watch]
        :hasPass(passid: int) -> player_owns_pass <bool>
            > returns if player owns gamepass, even if purchased in session
        :addPass(passid: int, insession: boolean) -> nil
            > add passid to owned gamepasses, if insession it will also add it to the _pis table.
            > _pis = (purchased in session)
]]

-- services
local players = game:GetService 'Players'
local marketplace = game:GetService 'MarketplaceService'

-- variables
local cache = {}
local watchlist = {}

local passwatch = {}
passwatch.__index = passwatch

function passwatch.watch(player)
    if cache[player] then
        return cache[player]
    end

    local self = setmetatable({
        _player = player,
        _owned  = {},
        _pis    = {},
        _cb     = {}
    }, passwatch)

    -- get pre-existing purchases
    for _, id in pairs(watchlist) do
        local success, res = pcall(marketplace.UserOwnsGamePassAsync, marketplace, player.UserId, id)

        if success and res then
            self._owned[id] = true
        end
    end

    cache[player] = self
    return self
end

function passwatch.get(player)
    if cache[player] then
        return cache[player]
    end

    return passwatch.watch(player)
end


function passwatch.watchfor(data)
    assert(data, 'Passwatch cannot watch empty data.')
    for _, pass in pairs(data) do
        if type(pass) == 'number' then
            table.insert(watchlist, pass)
        else
            if pass.GamepassId then
                table.insert(watchlist, pass.GamepassId)
            end
        end
    end
end

function passwatch:hasPass(passid)
    assert(passid, 'passwatch::hasPass > passid cannot be nil.')
    return self._owned[passid]
end

function passwatch:addPass(passid, insession)
    self._owned[passid] = true

    if insession then
        self._pis[passid] = insession
    end
end

function passwatch.OnPurchase(player, id, callback)
    local playercache = cache[player]
    
    if not playercache then
        playercache = passwatch.get(player)
    end

    if not playercache._cb[id] then
        playercache._cb[id] = {}
    end

    table.insert(playercache._cb[id], callback)
end

-- events
marketplace.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
    if purchased then
        local playercache = cache[player]
        
        if playercache then
            playercache:addPass(id)
            
            if playercache._cb[id] then
                for _, cb in pairs(playercache._cb[id]) do
                    cb(purchased)
                end
            end
        end
    end
end)

players.PlayerRemoving:Connect(function(player)
    if cache[player] then
        cache[player] = nil
    end
end)

return passwatch