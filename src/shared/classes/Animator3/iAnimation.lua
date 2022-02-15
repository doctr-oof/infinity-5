--[[
    iAnimation.lua
    FriendlyBiscuit
    Created on 11/30/2021 @ 22:53:49
    
    INCOMPLETE - DO NOT USE
    
    Description:
        No description provided.
    
    Documentation:
        No documentation provided.
--]]

--= Module Loader =--
local require           = require(game.ReplicatedStorage:WaitForChild('Infinity'))

--= Class Root =--
local iAnimation        = { }
iAnimation.__classname  = 'iAnimation'

--= Controllers =--

--= Other Classes =--

--= Modules & Config =--
local classify          = require('$lib/Classify')
local resource          = require('$lib/Resources')
local fetch             = require('$util/FetchSync')
local get               = require('$util/EasyGet')
local set               = require('$util/EasySet')
local map               = require('lib/Math').smap
local spring            = require('lib/Spring')
local spring_util       = require('lib/SpringUtils')
local step_util         = require('lib/StepUtils')
local alpha             = require('util/Alpha')

--= Roblox Services =--

--= Instance References =--
local local_player      = game.Players.LocalPlayer

--= Constants =--
local RES_KEY           = 'iAnimation'

--= Variables =--

--= Shorthands =--

--= Functions =--

--= Class Internal =--
function iAnimation:_update(): boolean
    local active, p = spring_util.IsAnimating(self._spring)
    local inv = 1 - p
    
    alpha.map(self._alpha_cache, inv)
    
    return active
end

--= Class API =--

--= Class Constructor =--
function iAnimation.new(parent: Instance): any
    local self = classify(iAnimation)
    self._instance = resource:Get(RES_KEY)
    
    if self._instance then
        self._spring = spring.new(0)
        self._spring.s = 40
        self._spring.d = 1
        self._animate, self._stop_main = step_util.BindToRenderStep(self._update)
        self._alpha_cache = alpha.cache(self._instance)
        
        
        
        self:_mark_disposables({ self._instance, self._stop_main })
        
        self:_animate()
        self._instance.Parent = parent and parent or nil
        return self
    else
        warn(('Failed to create "%s" - instance template not found.'):format(iAnimation.__classname))
    end
    
    return self
end

--= Class Properties =--
iAnimation.__properties = { }

--= Return Class =--
return iAnimation