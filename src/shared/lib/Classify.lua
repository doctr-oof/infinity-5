--[[
          _                   _               _  __
     _ __| |____  __      ___| | __ _ ___ ___(_)/ _|_   _
    | '__| '_ \ \/ /____ / __| |/ _` / __/ __| | |_| | | |
    | |  | |_) >  <_____| (__| | (_| \__ \__ \ |  _| |_| |
    |_|  |_.__/_/\_\     \___|_|\__,_|___/___/_|_|  \__, |
    Easy-to-use OOP Class Super Constructor         |___/
    By FriendlyBiscuit/doctr_oof
    
--]]

--= Constants =--
local SUPPRESS_DEBUG = true  -- Suppresses debug messages. Recommended Setting: true. This WILL destroy your output!
local SUPPRESS_ERROR = false -- Suppresses error messages. Recommended Setting: false.
local STRINGS        = {     -- Output message templates. Recommend you don't modify these.
    NO_CLASS_NAME = 'Failed to classify table - "__classname" must be defined.';
    NOREAD_PROPERTY = 'Failed to get property "%s" of "%s" - property cannot be read.';
    READONLY_PROPERTY = 'Failed to set property "%s" of "%s" - property is read-only.';
    DESTROYED = 'Attempted to reference a nil class.';
    ZERO_DISPOSABLES = 'Cannot :add_disposables() with zero items provided.';
    CLASSIFYING = 'Classifying "%s"...';
    INDEX_ORIGINAL = 'Using original __index function for "%s" for member "%s"';
    INDEX_NEW = 'Using new __index function for "%s" for member "%s"';
    NEWINDEX_ORIGINAL = 'Using original __newindex function for "%s" for member "%s" with value %q';
    NEWINDEX_NEW = 'Using new __newindex function for "%s" for member "%s" with value %q';
}

--= Utility Functions =--
function debug(message: string, ...)
    if SUPPRESS_DEBUG then return end
    
    local output = ('[classify-debug] %s'):format(message)
    
    if #{...} > 0 then
        output = output:format(...)
    end
    
    print(output)
end

function err(message: string, ...)
    if SUPPRESS_ERROR then return end
    
    local output = ('[classify-error] %s'):format(message)
    
    if #{...} > 0 then
        output = output:format(...)
    end
    
    error(output, 3)
end

function deep_copy(input: table)
    local result = { }
    
    if type(input) == 'table' then
        for index, value in next, input, nil do
            rawset(result, deep_copy(index), deep_copy(value))
        end
        
        setmetatable(result, deep_copy(getmetatable(input)))
    else
        result = input
    end
    
    return result
end

--= Classify =--
function classify(class: table)
    local class_name = rawget(class, '__classname')
    
    if class_name == nil then
        err(STRINGS.NO_CLASS_NAME)
        return
    end
    
    local proxy, result = deep_copy(class)
    
    rawset(proxy, '__meta', {
        index = rawget(proxy, '__index'),
        newindex = rawget(proxy, '__newindex'),
        destroyed = rawget(proxy, '__cleaning'),
        cleanup = { }
    })
    
    proxy.__index = function(self, key)
        if key == 'ClassName' then
            return rawget(self, '__classname')
        end
        
        if rawget(self, '__properties') then
            local property = rawget(self, '__properties')[key]
            
            if property then
                if property.get then
                    return property.get(self)
                elseif property.bind and property.target then
                    return property.target(self)[property.bind]
                else
                    err(STRINGS.NOREAD_PROPERTY, key, class_name)
                end
            end
        end
        
        local meta = rawget(self, '__meta').index
        
        if meta then
            debug(STRINGS.INDEX_ORIGINAL, class_name, key)
            return meta(self, key)
        else
            debug(STRINGS.INDEX_NEW, class_name, key)
            return rawget(self, key)
        end
    end
    
    proxy.__newindex = function(self, key, value)
        local prop = false
        
        if key == '__cleaning' and type(value) == 'function' then
            rawget(self, '__meta').destroyed = value
        end
        
        if rawget(self, '__properties') then
            local property = rawget(self, '__properties')[key]
            
            if property then
                prop = true
                
                if property.set then
                    property.set(self, value)
                elseif property.bind and property.target then
                    property.target(self)[property.bind] = value
                else
                    err(STRINGS.READONLY_PROPERTY, key, class_name)
                end
            end
        end
        
        local meta = rawget(self, '__meta').newindex
        
        if meta then
            debug(STRINGS.NEWINDEX_ORIGINAL, class_name, key, value)
            meta(self, key, value)
        elseif not prop then
            rawset(self, key, value)
        end
    end
    
    proxy.__tostring = function(self)
        if rawget(self, 'Name') then
            return rawget(self, 'Name')
        else
            return rawget(self, '__classname')
        end
    end
    
    proxy.Destroy = function(self, ...)
        if rawget(self, '__meta').destroyed then
            rawget(self, '__meta').destroyed(self, ...)
        end
        
        self:_dispose()
        self:_clean()
    end
    
    proxy._dispose = function(self)
        local disposables = rawget(self, '__meta').cleanup
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
    
    proxy._clean = function(self)
        for index, _ in pairs(self) do
            rawset(self, index, nil)
        end
        
        setmetatable(self, {
            __index = function() return nil end,
            __newindex = function() return nil end,
            __tostring = function() return nil end,
            __metatable = { }
        })
        
        --[[setmetatable(self, {
            __index = function() err(STRINGS.DESTROYED) end,
            __newindex = function() err(STRINGS.DESTROYED) end,
            __tostring = function() err(STRINGS.DESTROYED) end,
            __metatable = { }
        })--]]
        
        class_name = nil
        proxy = nil
        result = nil
    end
    
    proxy._mark_disposable = function(self, item: any)
        table.insert(rawget(self, '__meta').cleanup, item)
    end
    
    proxy._mark_disposables = function(self, ...)
        if #{...} > 0 then
            for _, item in pairs(...) do
                table.insert(rawget(self, '__meta').cleanup, item)
            end
        else
            err(STRINGS.ZERO_DISPOSABLES)
        end
    end
    
    proxy._markDisposable = proxy._mark_disposable
    proxy._markDisposables = proxy._mark_disposables
    proxy._MarkDisposable = proxy._mark_disposable
    proxy._MarkDisposables = proxy._mark_disposables
    
    result = deep_copy(proxy)
    return setmetatable(result, proxy)
end

--= Return Classify =--
return classify