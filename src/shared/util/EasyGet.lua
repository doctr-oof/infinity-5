return function(r, q)
    local _result = r:GetDescendants()
    
    for _, v in pairs(_result) do
        if (v.Name == q) then
            return v
        end
    end
    
    return nil
end