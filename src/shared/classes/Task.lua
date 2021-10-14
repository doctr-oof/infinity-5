--[[
    Task.lua
    FriendlyBiscuit
    Created on 05/15/2021 @ 23:09:14
    
    Description:
        Provides a highly-extensible Task object for scheduling critical or passive
        game loops.
    
    Documentation:
        Constructor:
            <Task> .new([callback: Function, interval: number])
            -> Creates and returns a Task object.
        
        Methods:
            <void> ::Start()
            -> Initiates the task's step loop if it is not already running.
               
               Note: If <Task>.Async is false AND <Task>.MaxTicks > 0, ::Start() will yield
               until the task reaches its maximum tick allocation. <Task>.Async has no
               effect if <Task>.MaxTicks < 0.
            
            <void> ::Stop()
            -> Softly terminates the task's step loop if it is already running after the last tick
               successfully executes. The task can be restarted by calling ::Start() again after
               it has stopped.
               
               Note: You can tell when the task's last tick is finished by waiting for <Task>.Running to
               return false.
            
            <void> ::Reset()
            -> Internally calls ::Stop(), waits for <Task>.Running to return false, resets the task's
               internal tick count and timer clock, and then calls ::Start()
            
            <void> ::Tick([async: boolean])
            -> Attempts to force the task's assigned tick callback to execute.
            
               Notes:
               - If [async] is not provided, the callback's yield status will be determined by <Task>.Async.
                 Whereas if [async] is provided true or false, then the callback's yield status will be
                 forced to the provided value for the duration of the call.
               - If <Task>.AllowOverlap is false and the task is currently ticking, this function will fail
                 with a warning.
               - If <Task>.MaxTicks > 0 and the task has already reached the maximum tick allocation, this
                 function will fail with a warning.
            
            <void> ::TickForce([async: boolean])
            -> Forces the task's assigned tick callback to execute without respecting maximum tick
               allocation, overlap settings, and the internal timer clock.
            
            <void> ::Destroy()
            -> Softly terminates the task's step loop if it is already running after the last tick
               successfully executes, then destroys and cleans up all task data from memory.
        
        Properties/Members:
            AllowOverlap: boolean (default: false)
            -> Allows the tick callback to execute multiple times in parallel.
            
            Async: boolean (default: true)
            -> Determines if the task will run asynchronously. Only affects ::Tick() calls and ::Start() calls
               where MaxTicks > 0.
            
            Callback(task: <Task>): Function
            -> The function to be called each tick. This callback is passed the Task object that called it.
               
               Note: If the callback errors at any point in time, the task will be stopped immediately. This
               includes forced calls via ::Tick() and ::TickForce().
            
            GUID: string [READ-ONLY]
            -> Returns a unique identifier to help distinguish multiple tasks from one-another.
            
            Interval: number (default: 5)
            -> The minimum amount of time (in seconds) to wait between each tick.
               
               Note: If the task callback fails to complete execution by the next tick, the tick will be
               skipped until the next interval passes.
            
            Priority: number (default: 0)
            -> Accessory value for your use. Has no effect on how the task itself runs.
            
            Running: boolean [READ-ONLY]
            -> Returns whether or not the task is currently running from a ::Start() call.
            
            TickCount: number [READ-ONLY]
            -> Returns the total number of times the task has successfully executed a tick cycle.
               This number is reset whenever ::Reset() is called.
            
            MaxOverlaps: number (default: 20)
            -> Sets the maximum number of times a task tick cycles can be rejected due to overlap
               protection before being automatically stopped. If set to any number < 0, then the task
               will be allowed to trip overlap protection infinitely.
            
            MaxTicks: number
            -> Sets the maximum number of allocated tick cycles the task may execute. If this value
               is set to any number < 0, then the task will tick indefinitely unless manually stopped.
--]]

--= Module Loader =--
local require    = require(game.ReplicatedStorage:WaitForChild('Skateworks'))

--= Class Root =--
local Task       = { }
Task.__classname = 'Task'

--= Modules & Config =--
local classify   = require('$lib/Classify')
local out        = require('$util/EasyOutput')

--= Roblox Services =--
local run_svc    = game:GetService('RunService')
local http_svc   = game:GetService('HttpService')

--= Functions =--
function call_safe(self)
    self._ticking = true
    
    local success, err = pcall(function()
        self:_callback()
    end)
    
    if not success then
        self._ticking = false
        self:Stop()
        out.warn('Task %s automatically stopped - tick callback error:', self._guid)
        error(err)
    end
    
    self._ticking = false
end

function do_tick(self, async)
    if async ~= nil then
        if async then
            spawn(function()
                call_safe(self)
            end)
        else
            call_safe(self)
        end
    else
        if self._async then
            spawn(function()
                call_safe(self)
            end)
        else
            call_safe(self)
        end
    end
end

--= Class Internal =--
function Task:__cleaning()
    self:Stop()
    while self._running do wait() end
end

--= Class API =--
function Task:Tick(async: bool)
    if not self._overlap and self._ticking then
        out.warn('::Tick() call rejected for Task %s - previous tick has not completed.', self._guid)
        return
    end
    
    if self._max_ticks > 0 and self._tick_count >= self._max_ticks then
        out.warn('::Tick() call rejected for Task %s - maximum tick allocation reached.', self._guid)
        return
    end
    
    self._tick_count += 1
    do_tick(self, async)
end

function Task:TickForce(async: bool)
    do_tick(self, async)
end

function Task:Start()
    if self._step then
        out.warn('Cannot ::Start() Task %s when it is already running.', self._guid)
        return
    end
    
    self._step = run_svc.Stepped:Connect(function()
        if (tick() - self._last_tick) >= self._interval then
            self._last_tick = tick()
            
            if not self._overlap and self._ticking then
                if self._overlap_count >= 0 and self._overlap_count >= self._max_overlaps then
                    self:Stop()
                    out.warn('Task %s automatically stopped - too many auto-tick overlaps.', self._guid)
                    
                    return
                end
                
                self._overlap_count += 1
                out.warn('Skipping auto-tick %d for Task %s - previous tick has not completed.',
                    self._tick_count, self._guid)
                
                return
            end
            
            self._tick_count += 1
            
            if self._max_ticks > 0 and self._tick_count >= self._max_ticks then
                self:Stop()
            end
            
            do_tick(self, false)
        end
    end)
    
    self._running = true
    self:_mark_disposable(self._step)
    
    if not self._async and self._max_ticks > 0 then
        while self._tick_count < self._max_ticks do wait() end
    end
end

function Task:Stop()
    if self._step then
        self._step:disconnect()
        self._step = nil
    end
    
    while self._ticking do wait() end
    self._running = false
end

function Task:Reset()
    self:Stop()
    while self._running do wait() end
    self._last_tick = 0
    self._tick_count = 0
    self:Start()
end

--= Class Constructor =--
function Task.new(callback: Function, interval: number)
    local self = classify(Task)
    
    self._async = true
    self._callback = callback or function() print('EMPTY_TASK_CALLBACK') end
    self._guid = http_svc:GenerateGUID(false)
    self._interval = interval or 5
    self._last_tick = 0
    self._max_overlaps = 20
    self._max_ticks = -1
    self._overlap = false
    self._overlap_count = 0
    self._priority = 0
    self._running = false
    self._step = nil
    self._tick_count = 0
    self._ticking = false
    
    return self
end

--= Class Properties =--
Task.__properties = {
    AllowOverlap = {
        bind = '_overlap',
        target = function(self) return self end
    },
    Async = {
        bind = '_async',
        target = function(self) return self end
    },
    Callback = {
        bind = '_callback',
        target = function(self) return self end
    },
    GUID = {
        get = function(self) return self._guid end
    },
    Interval = {
        bind = '_interval',
        target = function(self) return self end
    },
    Priority = {
        bind = '_priority',
        target = function(self) return self end
    },
    Running = {
        get = function(self) return self._running end
    },
    TickCount = {
        get = function(self) return self._tick_count end
    },
    MaxOverlaps = {
        bind = '_max_overlaps',
        target = function(self) return self end
    },
    MaxTicks = {
        bind = '_max_ticks',
        target = function(self) return self end
    }
}

--= Return Class =--
return Task