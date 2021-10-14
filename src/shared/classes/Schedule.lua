--[[
	Schedule.lua
	- retro_mada
	- 2/22/2021
	== API ==

	<Schedule> .new(name : string, delay : number, callback : function)
	-> Creates a schedule. Callback will run every n seconds, where n is delay.
	<Schedule> .get(name : string)
	-> Searches for cached schedule and returns if found.
	<nil> :Pause()
	-> Pauses current schedule. If resumed Schedule will resume where it stopped.
	<nil> :Start()
	-> Resumes a paused schedule.

--]]
local require = require(game.ReplicatedStorage:WaitForChild('Skateworks'))


local Maid = require('$lib/Maid')

local schedules = {}

local Schedule = {}
Schedule.__index = Schedule

function Schedule.new(name : string, delay : number, callback : Function)
	local self = setmetatable({
		_maid = Maid.new(),
		_name = name,
		_state = true,
		_count = 0
	}, Schedule)

	schedules[name] = self

	self._coroutine = coroutine.create(function()
		while wait(delay) do
			if not self._state then
				coroutine.yield()
			end
			self._count += 1
			local success, err = pcall(function()
				callback(self)
			end)

            if not success then
                warn(('!!! Schedule Error (%s): %s'):format(self._name, err))
            end
		end
	end)

	coroutine.resume(self._coroutine)

	return self
end

function Schedule.get(name : string)
	return schedules[name]
end

function Schedule:Pause()
	self._state = false
end

function Schedule:Start()
	self._state = true
	coroutine.resume(self._coroutine)
end

function Schedule:Destroy()
	if self._coroutine then
		self._state = false
	end

	self._maid:DoCleaning()
end

return Schedule