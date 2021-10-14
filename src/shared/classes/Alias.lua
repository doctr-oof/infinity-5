--= Alias Module =--
--[[
    by Retro_Mada
]]

--= Module Loader =--
local require = require(game.ReplicatedStorage:WaitForChild('Skateworks'))

--= Modules =--
local resources = require('$lib/Resources')

--= Configs =--
local names = require('$config/jobs/Names')
local userids = require('$config/jobs/UserIds')

--= Services =--
local player_svc = game:GetService('Players')
local http_svc = game:GetService('HttpService')

--= Variables =--
local rand = Random.new(tick())

--= Module =--
local Alias = { }

local minimum_age = 18
local maximum_age = 65
local genders = { 'Male', 'Female' }

local function rand_userid() : number
    return userids[rand:NextInteger(1, #userids)]
end

local function get_first_name(gender: string) : string
    return names.first[gender:lower()][rand:NextInteger(1, #names.first[gender:lower()])]
end

local function get_last_name() : string
    return names.last[rand:NextInteger(1, #names.last)]
end

function Alias.new(gender: string) : Alias
    if gender == nil then
        gender = genders[rand:NextInteger(1, 2)]
    end

    local _alias = { }
    _alias.GUID = http_svc:GenerateGUID(false)
    _alias.Name = {First = get_first_name(gender), Last = get_last_name()}
    _alias.Gender = gender
    _alias.Age = rand:NextInteger(minimum_age, maximum_age)
    _alias.UserId = rand_userid()

    local success, result = pcall(function()
        return player_svc:GetHumanoidDescriptionFromUserId(_alias.UserId)
    end)

    if success and result ~= nil then
        _alias.humanoid_desc = result
        _alias.model = resources:Fetch('NPCTemplate')
        _alias.model.Parent = game:GetService('ReplicatedStorage')
        _alias.model.Humanoid:ApplyDescription(result)
        _alias.model.Humanoid.DisplayDistanceType = 'None'
        _alias.model.Animate.Disabled = false
        _alias.model.Name = _alias.GUID
    end

    return _alias
end

return Alias