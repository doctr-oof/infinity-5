--[[
    Alpha.lua
    FriendlyBiscuit
    Created on 05/18/2021 @ 20:13:46
    
    Description:
        Skateworks Alpha Caching and Mapping Utility.
    
    Documentation:
        <table> .Cache(root: userdata)
        -> Returns a table of cached instance transparency values to be
           supplied to .Map().
        
        <void> .Map(cache: table, offset: number)
        -> Maps all objects in the supplied cache to the set offset.
--]]

--= Root =--
local Alpha = { }

--= API =--
function Alpha.cache(root: userdata): table
    local result = { }
    local objects = { root, unpack(root:GetDescendants()) }
    
    for _, object in pairs(objects) do
        local background = pcall(function() return object.BackgroundTransparency end)
        local image = pcall(function() return object.ImageTransparency end)
        local text = pcall(function() return object.TextTransparency end)
        local scroll = pcall(function() return object.ScrollBarImageTransparency end)
        local regular, stroke = pcall(function() return object.ClassName == 'UIStroke' end)
        
        if background or image or text or scroll or stroke then
            result[object] = { }
        end
        
        if background then
            result[object][1] = object.BackgroundTransparency
        end
        
        if image then
            result[object][2] = object.ImageTransparency
        end
        
        if text then
            result[object][3] = object.TextTransparency
            result[object][4] = object.TextStrokeTransparency
        end
        
        if scroll then
            result[object][5] = object.ScrollBarImageTransparency
        end
        
        if regular and stroke then
            result[object][6] = object.Transparency
        end
    end
    
    return result
end

function Alpha.map(alpha_cache: table, offset: number)
    for object, data in pairs(alpha_cache) do
        if data[1] then
            object.BackgroundTransparency = data[1] + offset
        end
        
        if data[2] then
            object.ImageTransparency = data[2] + offset
        end
        
        if data[3] and data[4] then
            object.TextTransparency = data[3] + offset
            object.TextStrokeTransparency = data[4] + offset
        end
        
        if data[5] then
            object.ScrollBarImageTransparency = data[5] + offset
        end
        
        if data[6] then
            object.Transparency = math.clamp(data[6] + offset, 0, 1)
        end
    end
end

Alpha.Cache = Alpha.cache
Alpha.Map = Alpha.map

--= Return Module =--
return Alpha