function get(r, q)
    local _result = r:GetDescendants()
    
    for _, v in pairs(_result) do
        if (v.Name == q) then
            return v
        end
    end
    
    return nil
end

return function(objects, props, root)
    for _, object in pairs(objects) do
        local _obj = nil
        
        if type(object) == 'string' then
            _obj = get(root, object)
        else
            _obj = object
        end
        
        if _obj then
            for property, value in pairs(props) do
                _obj[property] = value
            end
        end
    end
end