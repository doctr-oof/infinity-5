--[[
    Zone.lua
    - retro_mada
    - 2/15/2021

    This module is a rewrite of the original 'InArea.lua' developed for club nebula,
    module includes much easier to read code and includes maids and signals.

    == API ==
    (Zone)
        .new(name : string, blueprint : Instance) [ZoneObject] (Creates a new zone object and caches it.)
        .GetZone(name: string) [ZoneObject] (Returns a zone object, if zone is instantiated with key.)

    (ZoneObject)
        PlayerEntered <SignalConnection> (Triggers when a player enters area.)
        PlayerLeaving <SignalConnection> (Triggers when a player leaves area.)

        {client-exclusive}
            LocalPlayerEntered <SignalConnection> (Triggers when the localplayer enters area.)
            LocalPlayerExited <SignalConnection> (Triggers when the localplayer exits area.)

        ::GetPlayers() [Table<Players>] (Returns a table of all players in zone.)
        ::GetRandomPlayer() [Player] (Returns a random player inside zone.)
        ::InsideZone(object : Instance) [Boolean] (Returns if a part instance is inside of a zone.)
        ::Destroy() [nil] (Destroys connections and cleans up zone.)
]]


local require = require(game:GetService('ReplicatedStorage'):WaitForChild('Skateworks'))

local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Maid = require('$lib/Maid')
local Signal = require('$lib/signal')

local isClient = RunService:IsClient()
local find, insert, remove = table.find, table.insert, table.remove
local abs = math.abs

local zones = {}

local Zone = {}
Zone.__index = Zone

local function get_components(cf, size)
    local ax, ay, az, a11, a12, a13, a21, a22, a23, a31, a32, a33 = cf:inverse():components()
    local sx,sy,sz = size.x/2,size.y/2,size.z/2
    return {ax/sx,  ay/sy,  az/sz,  a11/sx, a12/sx, a13/sx, a21/sy, a22/sy, a23/sy, a31/sz, a32/sz, a33/sz}
end


function Zone.new(name, blueprint)
    assert(name, 'Zone Error: Argument 1 expected a string.')
    assert(typeof(blueprint) == 'Instance', 'Zone Error: Argument 2 expected an instance.')

    local self = setmetatable({
        _maid = Maid.new(),
        Players = {},
        Parts = {}
    }, Zone)

    self.PlayerEntered = Signal.new()
    self.PlayerLeaving = Signal.new()

    self._maid:GiveTask(self.PlayerEntered)
    self._maid:GiveTask(self.PlayerLeaving)

    if isClient then
        self.LocalPlayerEntered = Signal.new()
        self.LocalPlayerLeaving = Signal.new()

        self._maid:GiveTask(self.LocalPlayerEntered)
        self._maid:GiveTask(self.LocalPlayerLeaving)
    end

    function recurse(obj, cb)
        for _, v in pairs(obj:GetChildren()) do
            cb(v)

            if #v:GetChildren() > 0 then
                recurse(v, cb)
            end
        end
    end


    if blueprint:IsA('Model') or blueprint:IsA('Folder') then
        recurse(blueprint, function(obj)
            if obj:IsA('BasePart') then
                self.Parts[#self.Parts+1] = get_components(obj.CFrame, obj.Size)
            end
        end)
    elseif blueprint:IsA('BasePart') then
        self.Parts[#self.Parts+1] = get_components(blueprint.CFrame, blueprint.Size)
    end

    zones[name] = self
    return self
end

function Zone:GetPlayers()
    return self.Players
end

function Zone:GetRandomPlayer()
    return self.Players[math.random(1, #self.Players)]
end

function Zone.GetZone(name)
    return zones[name]
end

function Zone:InsideZone(obj)
    local pos = obj.CFrame.p
    local ix, iy, iz = pos.x, pos.y, pos.z
    local inZone = false
    for _, c in pairs(self.Parts) do
        if abs(c[4]*ix+c[5]*iy+c[6]*iz+c[1])<1 and abs(c[7]*ix+c[8]*iy+c[9]*iz+c[2])<1 and abs(c[10]*ix+c[11]*iy+c[12]*iz+c[3])<1 then
            inZone = true
        end
    end
    return inZone
end

function Zone:_update()
    for _, player in pairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character:FindFirstChild('HumanoidRootPart') then
            local root = character.HumanoidRootPart

            if self:InsideZone(root) then
                if not find(self.Players, player) then
                    insert(self.Players, player)
                    self.PlayerEntered:Fire(player)

                    if isClient and player == Players.LocalPlayer then
                        self.LocalPlayerEntered:Fire(player)
                    end
                end
            else
                local index = find(self.Players, player)
                if index then
                    remove(self.Players, index)
                    self.PlayerLeaving:Fire(player)

                    if isClient and player == Players.LocalPlayer then
                        self.LocalPlayerLeaving:Fire(player)
                    end
                end
            end
        end
    end
end

function Zone:Destroy()
    self._maid:DoCleaning()
    zones[self._name] = nil
end

--[[
    !!UPDATE LOOP!!
]]

coroutine.wrap(function()
    while true do
        for _, zone in pairs(zones) do
            zone:_update()
        end

        RunService.Stepped:Wait()
    end
end)()

return Zone