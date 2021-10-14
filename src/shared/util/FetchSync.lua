-- FetchSync(root: userdata, name: string)
-- Waits for descendant to appear in root.
-- FriendlyBiscuit

return function(r, q)
    local _desc = r:GetDescendants()
    local _result
    
    while not (_result) do
        _desc = r:GetDescendants()

        for _, v in pairs(_desc) do
            if (v.Name == q) then
                _result = v
            end
        end
        
        wait()
    end
    
    return _result
end