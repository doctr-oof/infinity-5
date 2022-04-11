--[[
       _ ___        _            __             ____
      (_) _ | ___  (_)_ _  ___ _/ /____  ____  |_  /
     / / __ |/ _ \/ /  ' \/ _ `/ __/ _ \/ __/ _/_ <
    /_/_/ |_/_//_/_/_/_/_/\_,_/\__/\___/_/   /____/
    Infinity Animator 3.0
    By FriendlyBiscuit
    
    EARLY-ALPHA TESTING. USE NOT RECOMMENDED!
--]]

--= Root Module Table =--
local Animator3 = { }

--= Infinity Integration =--
local require   = require(game.ReplicatedStorage:WaitForChild('Infinity'))

--= External Classes =--
local Animation = require(script:WaitForChild('Animation'))

--= Services & Requires =--
local tween_svc = game:GetService('TweenService')
local run_svc   = game:GetService('RunService')

--= Generic Tween API =--
function Animator3.CreateAnimation(...): nil
    return Animation.new(...)
end

function Animator3.CreateTween(args: table): Tween
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

function Animator3:Tween(args: table): nil
    local tween = Animator3.CreateTween(args)
    local complete = false
    
    tween.Completed:Connect(function()
        complete = true
        tween:Destroy()
    end)
    
    tween:Play()
    
    if not args.Async then
        while not complete do run_svc.Heartbeat:Wait() end
        complete = nil
    end
end

return Animator3