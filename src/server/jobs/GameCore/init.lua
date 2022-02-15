--[[
    init.lua
    Retro_Mada
    Created on 02/11/2022 @ 17:18:58
    
    Description:
        No description provided.
    
    Documentation:
        No documentation provided.
--]]

--= Module Loader =--
local require = require(game.ReplicatedStorage:WaitForChild('Infinity'))

--= Root =--
local GameCore = { }

--= Jobs =--

--= Classes =--

--= Modules & Config =--
local logger    = require('$classes/Logger')
local promise   = require('$lib/Promise')

--= Roblox Services =--
local network = require('$lib/Network')

--= Object References =--
local log = logger.new()
log.Name = 'GameCore'

--= Constants =--
local monster_count     = 1
local minimum_players   = 1
local str               = {
    game_ended  = 'Game has ended. Winning side: %s.';
    game_halted = 'Game unexpectedly halted due to: %s.'; 
}


--= Variables =--
local active_players    = { }
local survivors         = { }
local monsters          = { }

local core_cancel
local core_reject
local core_resolve

--= Shorthands =--

--= Functions =--

--= Job API =--
local function shuffle_teams(): nil
    for i = 1, #active_players do
        local ind = math.random(i)
        active_players[i], active_players[ind] = active_players[ind], active_players[i]
    end
end

local function generate_teams(): nil
    if #active_players < minimum_players then
        core_reject('Player count too low to continue.')
    end

    if monster_count > 0 then
        for i = 1, monster_count do
            local ind = math.random(#active_players)
            monsters[i], active_players[ind] = active_players[ind], nil
        end
    end

    -- put remaining players in the survivor pool
    for i = 1, #active_players do
        survivors[#survivors+1] = active_players[i]
    end

    -- we don't need this anymore
    active_players = { }
end

local function spawn_players(): nil
    local survivor_spawns = workspace.SurvivorSpawns:GetChildren()
    for i = 1, #survivor_spawns do
        if survivors[i] == nil then
            continue
        end

        log:print('Moving player to spawn: %s', survivors[i].Name)
        survivors[i].Character:PivotTo(survivor_spawns[i].CFrame * CFrame.new(0, 0, 5))
    end
end

local function monitor_game(): nil
    if #monsters == 0 or #survivors == 0 then
        -- game end
        local winning_side = #monsters > 0  and 'Monsters' or 'Survivors'
        core_resolve(winning_side)
    end
end

--= Job Initializers =--
function GameCore:PlayerAdded(player: Player): nil
    active_players[#active_players+1] = player
end

function GameCore:Run(): nil
    repeat
        task.wait(1)
    until #active_players >= minimum_players

    promise.new(function(resolve: Function, reject: Function, cancel: Function)
        core_resolve    = resolve
        core_reject     = reject
        core_cancel     = cancel
        
        task.wait(5)
        
        network:FireAll('Notify', 'Generating Teams')          

        shuffle_teams()
        generate_teams()

        task.wait(3)
        spawn_players()


        for i = 1, 10 do
            for _, v in pairs(game.Players:GetPlayers()) do
                network:Fire('Notify', v, 'Starting in: ' .. 10-i, 1)          
            end
            task.wait(1)
        end

        for _, v in pairs(survivors) do
            network:Fire('Notify', v, 'You are a survivor. Find out what kind of entity we are dealing with. lol.', 5)         
        end

        for _, v in pairs(monsters) do
            network:Fire('Notify', v, 'You are the entity. Be scary. Do stuff.', 5)
        end

        print('time to begin the game.')

    end):andThen(function(winner)
        log:Warn(str.game_ended, tostring(winner))
    end):catch(function(err)
        print(typeof(err))
        warn(err)
        --log:Warn(str.game_halted, err)
    end)
end

function GameCore:Init(): nil
   network:RegisterEvent('Notify') 
end

--= Return Job =--
return GameCore