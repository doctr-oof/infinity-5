-- The module loader
local require = require(game.ReplicatedStorage:WaitForChild('Infinity'))

-- Main job table
local TestJob = {
    Priority = 1, -- the order in which this job is executed
    UpdateRate = 0.5, -- update rate in seconds that ::Update() is called
    TickRate = 2, -- update rate in frames that ::Tick() is called. WARNING: this is load balanced based on fps.
    TickPriority = 5
}

-- Custom requires!
local math = require('$lib/Math') -- $ = look in shared folder
local spring = require('lib/Spring') -- otherwise, it's based on the current context

function TestJob:Stepped(): nil
    
end

-- doesn't work on server, duh
function TestJob:RenderStepped(elapsed, delta): nil
    
end

function TestJob:Heartbeat(): nil
    
end

function TestJob:PlayerAdded(player: Player): nil
    
end

function TestJob:PlayerLeft(player: Player): nil
    
end

-- runs async, in order, over time.
-- yields internally, will not overlap. no race condition.
function TestJob:Update(): nil
    
end

-- yields, in order, over frames.
function TestJob:Tick(): nil
    
end

-- Not required
-- Async
function TestJob:Run(): nil
    
end

-- Not required
-- Yields
function TestJob:Init(): nil
    
end

return TestJob