--[[
        ____      _____       _ __           ___          _                 __
       /  _/___  / __(_)___  (_) /___  __   /   |  ____  (_)___ ___  ____ _/ /_____  _____
       / // __ \/ /_/ / __ \/ / __/ / / /  / /| | / __ \/ / __ `__ \/ __ `/ __/ __ \/ ___/
     _/ // / / / __/ / / / / / /_/ /_/ /  / ___ |/ / / / / / / / / / /_/ / /_/ /_/ / /
    /___/_/ /_/_/ /_/_/ /_/_/\__/\__, /  /_/  |_/_/ /_/_/_/ /_/ /_/\__,_/\__/\____/_/
                                /____/
                                       ___    ____
                                      |__ \  / __ \
                                      __/ / / / / /
                                     / __/_/ /_/ /
                                    /____(_)____/

    ======================================================================================
--]]

-- Root Module Table
local animator  = { }

-- Constants
local tweenSvc  = game:GetService('TweenService')
local eStyle    = Enum.EasingStyle
local eDir      = Enum.EasingDirection

-- Error Messages
local errors    = {
    ALREADY_RUNNING = 'Attempt to call ::Start() failed: animation is already running.';
    ANIM_NOT_RUNNING = 'Attempt to call ::Stop() failed: animation isn\'t running.';
    BAD_WAYPOINTS = 'Attempt to call ::Start() failed: invalid waypoint table or invalid number of waypoints.';
    LOOP_COUNT_INVALID = 'Cannot ::Loop() "%s" times: amount must be a valid integer higher than 0.';
    INVALID_INSTANCE = 'Waypoint %d failed: invalid instance.';
    INVALID_WAYPOINT = 'Waypoint %d failed: invalid waypoint type(). Must be a table, number, or function.';
    INVALID_WAYPOINT_REF = 'Waypoint %d failed: attempt to get() descendant when no animation.Root is set.';
    INVALID_WAYPOINT_LENGTH = 'Waypoint %d failed: invalid waypoint length.';
}

-- Internal
function get(r, q)
    if (not r) then return nil end
    
    for _, v in pairs(r:GetDescendants()) do
        if (v.Name == q) then
            return v
        end
    end
    
    return nil
end

function err(e, ...)
    local s = errors[e]
    
    if (#{...} > 0) then
        s = string.format(s, ...)
    end
    
    warn('[iAnimator2] !!!', s)
end

function runAnim(self)
    if (not self.Waypoints or #self.Waypoints <= 0) then return end
    
    self.Running = true
    
    for i, wp in pairs(self.Waypoints) do
        if (type(wp) == 'function') then
            wp(self)
        elseif (type(wp) == 'number') then
            wait(wp)
        elseif (type(wp) == 'table') then
            if (not self.Running) then return end
            
            local objs = { }
            
            if (type(wp[1]) == 'string') then
                table.insert(objs, get(self.Root, wp[1]))
            elseif (type(wp[1]) == 'table') then
                for _, inst in pairs(wp[1]) do
                    if (type(inst) == 'string') then
                        table.insert(objs, get(self.Root, inst))
                    else
                        table.insert(objs, inst)
                    end
                end
            else
                table.insert(objs, wp[1])
            end
            
            for _, obj in pairs(objs) do
                if (obj) then
                    if (#wp == 6 and self.Running) then
                        if (wp[5]) then
                            animator:TweenSimpleAsync(obj, wp[2], wp[3], wp[4], wp[6])
                        else
                            animator:TweenSimple(obj, wp[2], wp[3], wp[4], wp[6])
                        end
                    elseif (#wp == 9 and self.Running) then
                        if (wp[8]) then
                            animator:TweenAsync(obj, wp[2], wp[3], wp[4], wp[5], wp[6], wp[7], wp[9])
                        else
                            animator:Tween(obj, wp[2], wp[3], wp[4], wp[5], wp[6], wp[7], wp[9])
                        end
                    else
                        err('INVALID_WAYPOINT_LENGTH', i)
                    end
                else
                    err('INVALID_INSTANCE', i)
                end
            end
        else
            err('INVALID_WAYPOINT', i)
        end
    end
    
    self.Running = false
end

function loopAnim(a, n)
    for _ = 1, n do
        runAnim(a)
    end
end

-- Module Functions
function animator.NewTween(i, l, s, dr, re, rv, de, p)
    return tweenSvc:Create(i, TweenInfo.new(l, eStyle[s], eDir[dr], re, rv, de), p)
end

function animator.NewSimpleTween(i, l, s, dr, p)
    return tweenSvc:Create(i, TweenInfo.new(l, eStyle[s], eDir[dr], 0, false, 0), p)
end

function animator:Tween(i, l, s, dr, re, rv, de, p)
    local d, t = false, animator.NewTween(i, l, s, dr, re, rv, de, p)
    
    t.Completed:Connect(function() d = true t:Destroy() end)
    t:Play()
    
    while not (d) do wait() end
end

function animator:TweenSimple(i, l, s, dr, p)
    local d, t = false, animator.NewSimpleTween(i, l, s, dr, p)
    
    t.Completed:Connect(function() d = true t:Destroy() end)
    t:Play()
    
    while not (d) do wait() end
end

function animator:TweenAsync(i, l, s, dr, re, rv, de, p)
    local t = animator.NewTween(i, l, s, dr, re, rv, de, p)
    
    t.Completed:Connect(function() t:Destroy() end)
    t:Play()
end

function animator:TweenSimpleAsync(i, l, s, dr, p)
    local t = animator.NewSimpleTween(i, l, s, dr, p)
    
    t.Completed:Connect(function() t:Destroy() end)
    t:Play()
end

function animator.NewAnimation(w)
    local a = { }
    
    a.AutoDispose = false
    a.CurrentTween = nil
    a.Root = nil
    a.Running = false
    a.Waypoints = w and w or { }
    
    function a:Start(as)
        if (self.Running) then
            err('ALREADY_RUNNING')
            return
        end
        
        if (as) then
            spawn(function() runAnim(self) end)
        else
            runAnim(self)
        end
    end
    
    function a:Stop(f)
        if (self.Running) then
            if (f) then
                self.Running = false
                
                if self.CurrentTween then
                    self.CurrentTween:Stop()
                end
                
                if (self.AutoDispose) then
                    self.Waypoints = { }
                    self = nil
                end
            else
                self.Running = false
                
                if (self.AutoDispose) then
                    self.CurrentTween.Completed:Connect(function()
                        self.Waypoints = { }
                        self = nil
                    end)
                end
            end
        else
            err('ANIM_NOT_RUNNING')
        end
    end
    
    function a:Loop(n, as)
        if (type(n) == 'number' and n > 0) then
            if (as) then
                spawn(function() loopAnim(self, n) end)
            else
                loopAnim(self, n)
            end
        else
            err('LOOP_COUNT_INVALID', tostring(n))
        end
    end
    
    function a:SetWaypoints(w)
        self.Waypoints = w
    end
    
    function a:AddWaypoint(w)
        table.insert(self.Waypoints, w)
    end
    
    function a:RemoveWaypoint(i)
        table.insert(self.Waypoints, i)
    end
    
    function a:InsertWaypoint(i, w)
        table.insert(self.Waypoints, i, w)
    end
    
    return a
end

return animator
