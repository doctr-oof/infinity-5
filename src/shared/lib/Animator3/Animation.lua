--[[
    iAnimation.lua
    FriendlyBiscuit
    Created on 11/30/2021 @ 22:53:49
    
    EARLY-ALPHA TESTING. USE NOT RECOMMENDED!
    
    Description:
        No description provided.
    
    Documentation:
        No documentation provided.
--]]

--= Module Loader =--
local require           = require(game.ReplicatedStorage:WaitForChild('Infinity'))

--= Class Root =--
local Animation         = { }
Animation.__classname   = 'InfinityAnimation'

--= Other Classes =--
local Logger            = require('$classes/Logger')

--= Modules & Config =--
local classify          = require('$lib/Classify')
local get               = require('$util/EasyGet')

--= Roblox Services =--
local tween_svc         = game:GetService('TweenService')
local run_svc           = game:GetService('RunService')

--= Messages =--
local MESSAGES          = {
    ALREADY_RUNNING = 'Failed to start Animation - already running.',
    INVALID_WAYPOINT_TYPE = 'Waypoint #%d has been removed - not a supported waypoint type.',
    INVALID_WAYPOINT_LENGTH = 'Waypoint #%d has been removed - incorrect index count.',
    NO_SEARCH_ROOT = 'Failed to query object %q by name - no SearchRoot specified.',
    NIL_OBJECT = 'Failed to animate object at waypoint #%d - object is nil or destroyed.'
}

--= Constants =--
local WAYPOINT_TYPES    = { 'function', 'number', 'table' }

--= Functions =--
function create_tween(args: table): Tween
    return tween_svc:Create(
        args.Instance,
        TweenInfo.new(
            args.Length or 1,
            args.Style and Enum.EasingStyle[args.Style] or Enum.EasingStyle.Linear,
            args.Direction and Enum.EasingDirection[args.Direction] or Enum.EasingDirection.Out,
            args.Repeat or 0,
            args.Reverse or false,
            args.Delay or 0),
        args.Properties)
end

function format_waypoint(object: Instance, waypoint: table): table
    local long = #waypoint == 9
    
    return {
        Instance = object,
        Length = waypoint[2],
        Style = waypoint[3],
        Direction = waypoint[4],
        Repeat = long and waypoint[5] or 0,
        Reverse = long and waypoint[6] or false,
        Delay = long and waypoint[7] or 0,
        Async = long and waypoint[8] or waypoint[5],
        Properties = long and waypoint[9] or waypoint[6]
    }
end

--= Class Internal =--
function Animation:__cleaning(): nil
    self:Abort()
end

function Animation:_verify_waypoints(): nil
    for index, waypoint in pairs(self._waypoints) do
        if not table.find(WAYPOINT_TYPES, type(waypoint)) then
            table.remove(self._waypoints, index)
            self._log:Warn(MESSAGES.INVALID_WAYPOINT_TYPE, index)
            continue
        end
        
        if type(waypoint) == 'table' and (#waypoint ~= 6 and #waypoint ~= 9) then
            table.remove(self._waypoints, index)
            self._log:Warn(MESSAGES.INVALID_WAYPOINT_LENGTH, index)
        end
    end
end

function Animation:_parse_objects(query: string|table): table
    local result = { }
    local query_type = type(query)
    
    if query_type == 'string' then
        if self.SearchRoot then
            table.insert(result, get(self.SearchRoot, query))
        else
            self._log:Warn(MESSAGES.NO_SEARCH_ROOT, query)
        end
    elseif query_type == 'table' then
        for _, target in pairs(query) do
            if type(target) == 'string' then
                if self.SearchRoot then
                    table.insert(result, get(self.SearchRoot, target))
                else
                    self._log:Warn(MESSAGES.NO_SEARCH_ROOT, target)
                end
            else
                table.insert(result, target)
            end
        end
    else
        table.insert(result, query)
    end
    
    return result
end

--= Class API =--
function Animation:Play(): nil
    if self._running then
        self._log:Warn(MESSAGES.ALREADY_RUNNING)
        return
    end
    
    self._stopped = false
    self._running = true
    self:_verify_waypoints()
    
    for index, waypoint in pairs(self._waypoints) do
        if not self._running or self._stopped then break end
        
        local waypoint_type = type(waypoint)
        
        if waypoint_type == 'function' then
            waypoint(self)
            self._waypoint_event:Fire(index)
        elseif waypoint_type == 'number' then
            task.wait(waypoint)
            self._waypoint_event:Fire(index)
        elseif waypoint_type == 'table' then
            local objects = self:_parse_objects(waypoint[1])
            
            for _, object in pairs(objects) do
                if not self._running or self._stopped then break end
                
                if object then
                    local clean_waypoint_args = format_waypoint(object, waypoint)
                    local waypoint_tween = create_tween(clean_waypoint_args)
                    local complete = false
                    
                    waypoint_tween.Completed:Connect(function()
                        complete = true
                        self._waypoint_event:Fire(index, object)
                        self._active_tweens[waypoint_tween] = nil
                        waypoint_tween:Destroy()
                    end)
                    
                    self._active_tweens[waypoint_tween] = true
                    waypoint_tween:Play()
                    
                    if not clean_waypoint_args.Async then
                        while not complete do run_svc.Heartbeat:Wait() end
                        complete = nil
                    end
                else
                    self._log:Warn(MESSAGES.NIL_OBJECT, index)
                end
            end
        end
    end
    
    self._complete_event:Fire(self._stopped)
    self._active_tweens = { }
    self._running = false
end

function Animation:PlayAsync(): nil
    task.defer(function()
        self:Play()
    end)
end

function Animation:PlayLooped(amount: number): nil
    if self._running or self._looping then
        self._log:Warn(MESSAGES.ALREADY_RUNNING)
        return
    end
    
    self._looping = true
    
    for _ = 1, amount do
        if not self._looping then break end
        self:Play()
    end
    
    self._looping = false
end

function Animation:PlayLoopedAsync(amount: number): nil
    task.defer(function()
        self:PlayLooped(amount)
    end)
end

function Animation:Stop(): nil
    self._looping = false
    self._running = false
    self._stopped = true
end

function Animation:Abort(): nil
    self._looping = false
    self._running = false
    self._stopped = true
    
    for tween, _ in pairs(self._active_tweens) do
        tween:Cancel()
        tween:Destroy()
    end
    
    self._active_tweens = { }
end

function Animation:AddWaypoint(waypoint: table): nil
    table.insert(self._waypoints, waypoint)
end

function Animation:RemoveWaypoint(index: number): nil
    table.remove(self._waypoints, index)
end

function Animation:InsertWaypoint(index: number, waypoint: table): nil
    table.insert(self._waypoints, index, waypoint)
end

--= Class Constructor =--
function Animation.new(waypoints: table): any
    local self = classify(Animation)
    
    self._log = Logger.new(self.__classname)
    self._waypoint_event = Instance.new('BindableEvent')
    self._complete_event = Instance.new('BindableEvent')
    self.WaypointComplete = self._waypoint_event.Event
    self.PlaybackComplete = self._complete_event.Event
    
    self._active_tweens = { }
    self._waypoints = waypoints or { }
    self._running = false
    
    self:_mark_disposables({ self._log, self._waypoint_event, self._complete_event })
    self:_verify_waypoints()
    return self
end

--= Class Properties =--
Animation.__properties = {
    ActiveTweens = { get = function(self) return self._active_tweens end },
    Running = { get = function(self) return self._running end },
    SearchRoot = { internal = '_search_root' },
    Waypoints = {
        internal = '_waypoints',
        set = function(self) self:_verify_waypoints() end
    }
}

--= Return Class =--
return Animation