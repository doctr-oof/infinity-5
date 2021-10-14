--[[
    States.lua - Project Ollie
    FriendlyBiscuit
    Created on 03/02/2021 @ 17:49:17
    
    Description:
        Creates an easy-to-use global State Manager with Changed event support.
    
    Documentation:
        <variant> ::Get(manager:string, key:string)
        -> Gets a key's value from the specified Manager.
           NOTE: If the Manager or Key do not exist, they will be created and the
           function will return nil.
        
        <void> ::Set(manager:string, key:string, value:variant)
        -> Sets a key's value under the specified Manager.
           NOTE: If the Manager or Key do not exist, they will be created and the
           key will immediately be set.
        
        <RBXScriptSignal> ::GetChangedSignal(manager:string)
        -> Returns an event that you can connect to that will fire whenever any
           key's value is changed under the specified manager.
           
           The event callback is passed the following data:
               key:string - The name of the key that changed.
               old_value:variant - The previous value of that key.
               new_value:variant - The new value of that key.
        
        <RBXScriptSignal> ::GetKeyChangedSignal(manager:string, key:string)
        -> Returns an event that you connect to that will fire whenever the specified
           key's value is changed under the specified manager.
           
           The event callback is passed the following data:
               old_value:variant - The previous value of the specified key.
               new_value:variant - The new value of the specified key.
--]]

--= Instance Root =--
local States		= { }

--= Variables =--
local managers      = { }

--= Internal =--
function validate(manager)
    local _result = managers[manager]
    
    if not _result then
        managers[manager] = { _keys = { }, _event = Instance.new('BindableEvent') }
        _result = managers[manager]
    end
    
    return _result
end

--= Public API =--
function States:Get(manager: string, key: string)
    return validate(manager)._keys[key]
end

function States:Set(manager: string, key: string, value: string)
    local _man = validate(manager)
    local old_value = _man._keys[key]
    
    if old_value ~= value then
        _man._event:Fire(key, old_value, value)
    end
    
    managers[manager]._keys[key] = value
end

function States:GetChangedSignal(manager: string)
    return validate(manager)._event.Event
end

function States:GetKeyChangedSignal(manager: string, key: string)
    local event = Instance.new('BindableEvent')
    
    States:GetChangedSignal(manager):Connect(function(changed_key, old, new)
        if changed_key == key then
            event:Fire(old, new)
        end
    end)
    
    return event.Event
end

--= Return =--
return States