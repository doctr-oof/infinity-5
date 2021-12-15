--[[
          __             _ ___
     ____/ /__ ____ ___ (_) _/_ __
    / __/ / _ `(_-<(_-</ / _/ // /
    \__/_/\_,_/___/___/_/_/ \_, /
    Classify - OOP Helper  /___/
    By FriendlyBiscuit
--]]

--= Root Table =--
local Classify         = { meta = { }, prototype = { } }

--= Constants =--
local SUPPRESS_ERROR   = false
local MESSAGES         = {
    NO_CLASS_NAME      = 'Failed to classify table - "__classname" must be defined.';
    READONLY_PROPERTY = 'Failed to set property "%s" of "%s" - property is read-only.';
    ZERO_DISPOSABLES = 'Cannot :_mark_disposables() with zero items provided.';
    INVALID_CLASS = '%q cannot inherit  %q - target dependency is not a valid Classify class.';
    INDEX_ALREADY_EXISTS = '%q cannot inherit %q - %q already exists in the inheritor.';
    PROPERTY_ALREADY_EXISTS = 'Duplicate inherited property %q from %q has been overwritten in %q.';
}

--= Internal Functions =--
function wrn(message: string, ...): nil
    if SUPPRESS_ERROR then return end
    
    if #{...} > 0 then
        message = message:format(...)
    end
    
    warn(message)
end

function err(message: string, ...): nil
    if SUPPRESS_ERROR then return end
    
    if #{...} > 0 then
        message = message:format(...)
    end
    
    error(message, 3)
end

function deep_copy(source: table, target: table): table|nil
    local result = { }
    
    if type(source) == 'table' then
        for index, value in next, source, nil do
            --print('Copying', index, value)
            rawset(result, deep_copy(index), deep_copy(value))
        end
        
        setmetatable(result, deep_copy(getmetatable(source)))
    else
        result = source
    end
    
    if target then
        for index, value in next, source, nil do
            rawset(target, index, value)
        end
    else
        return result
    end
end

--= Meta-Functions =--
function Classify.meta.__index(self: table, key: string): any
    local properties = rawget(self, '__properties')
    
    if key == 'ClassName' then
        return rawget(self, '__classname')
    end
    
    if properties then
        local property = properties[key]
        
        if property then
            if property.get then
                return property.get(self)
            elseif property.bind and property.target then
                return property.target(self)[property.bind]
            else
                err(MESSAGES.NOREAD_PROPERTY, key, rawget(self, '__classname'))
            end
        end
    end
    
    return rawget(self, key)
end

function Classify.meta.__newindex(self: table, key: string, value: any): nil
    local properties = rawget(self, '__properties')
    local success = false
    
    if key == '__cleaning' and type(value) == 'function' then
        rawget(self, '__meta').clean_callback = value
        return
    end
    
    if properties then
        local property = properties[key]
        
        if property then
            if property.set then
                property.set(self, value)
                success = true
            end
            
            if property.bind and property.target then
                property.target(self)[property.bind] = value
                success = true
            end
            
            if not property.bind and not property.set then
                err(MESSAGES.READONLY, key, rawget(self, '__classname'))
            end
        end
    end
    
    if not success then
        rawset(self, key, value)
    end
end

function Classify.meta.__tostring(self: table): string
    return rawget(self, 'Name') or rawget(self, '__classname')
end

--= Prototype/Injected Functions =--
function Classify.prototype:_mark_disposable(trash: any): nil
    table.insert(rawget(self, '__meta').disposables, trash)
end

function Classify.prototype:_mark_disposables(...): nil
    if #{...} > 0 then
        for _, item in pairs(...) do
            table.insert(rawget(self, '__meta').cleanup, item)
        end
    else
        err(MESSAGES.ZERO_DISPOSABLES)
    end
end

function Classify.prototype:_dispose(): nil
    local disposables = rawget(self, '__meta').disposables
    local index, item = next(disposables)
    
    while item ~= nil do
        disposables[index] = nil
        
        if typeof(item) == 'RBXScriptConnection' then
            item:Disconnect()
        elseif type(item) == 'function' then
            item()
        elseif item.Destroy then
            item:Destroy()
        end
        
        index, item = next(disposables)
    end
end

function Classify.prototype:_clean(): nil
    for index, _ in pairs(self) do
        rawset(self, index, nil)
    end
    
    setmetatable(self, {
        __index = function() return nil end,
        __newindex = function() return nil end,
        __tostring = function() return nil end,
        __metatable = { }
    })
end

function Classify.prototype:Inherit(dependency: any): table
    local copy = deep_copy(dependency)
    local d_class_name = rawget(copy, '__classname')
    local s_class_name = rawget(self, '__classname')
    
    if not d_class_name then
        err(MESSAGES.INVALID_CLASS, s_class_name, d_class_name)
        return
    end
    
    for index, value in next, copy, nil do
        local raw = rawget(copy, index)
        
        if index == '__index' then
            table.insert(rawget(self, '__meta').d_index, value)
        elseif index == '__newindex' then
            table.insert(rawget(self, '__meta').d_newindex, value)
        elseif index == '__meta' then
            for _, callback in pairs(raw.clean_callbacks) do
                table.insert(rawget(self, '__meta').clean_callbacks, callback)
            end
        elseif index == '__properties' then
            local d_properties = rawget(copy, '__properties')
            local s_properties = rawget(self, '__properties')
            
            if d_properties and s_properties then
                for property, data in pairs(d_properties) do
                    if s_properties[property] ~= nil then
                        wrn(MESSAGES.PROPERTY_ALREADY_EXISTS, property, d_class_name, s_class_name)
                    end
                    
                    s_properties[property] = data
                end
            end
        else
            if rawget(self, index) then
                continue
            end
            
            rawset(self, index, raw)
        end
    end
    
    return self
end

function Classify.prototype:Destroy(...): nil
    local clean_callbacks = rawget(self, '__meta').clean_callbacks
    
    for _, callback in pairs(clean_callbacks) do
        callback(...)
    end
    
    self:_dispose()
    self:_clean()
end

Classify.prototype.inherit = Classify.prototype.Inherit

--= Main Module Function =--
function Classify.classify(class: table): any
    local class_name = rawget(class, '__classname')
    
    if class_name == nil then
        err(MESSAGES.NO_CLASS_NAME)
        return
    end
    
    local proxy, result = deep_copy(class)
    
    deep_copy(Classify.meta, proxy)
    deep_copy(Classify.prototype, proxy)
    
    rawset(proxy, '__meta', {
        clean_callbacks = { rawget(proxy, '__cleaning') },
        d_index = { },
        d_newindex = { },
        disposables = { }
    })
    
    result = deep_copy(proxy)
    return setmetatable(result, proxy)
end

return Classify.classify