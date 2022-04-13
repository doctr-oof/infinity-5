--[[
    InputMonitor.lua
    FriendlyBiscuit
    Created on 09/25/2021 @ 19:32:17
    
    Description:
        No description provided.
    
    Documentation:
        No documentation provided.
--]]

--= Module Loader =--
local require               = require(game.ReplicatedStorage:WaitForChild('Infinity'))

--= Class Root =--
local InputMonitor          = { }
InputMonitor.__classname    = 'InputMonitor'

--= Modules & Config =--
local classify              = require('$lib/Classify')

--= Roblox Services =--
local input_svc             = game:GetService("UserInputService")

--= Class Internal =--
function InputMonitor:_can_process(input: InputObject): boolean
    if type(self._input_state) == 'table' then
        for _, state in pairs(self._input_state) do
            if input.UserInputState == state then
                return true
            end
        end
    elseif input.UserInputState == self._input_state then
        return true
    end
    
    return false
end

function InputMonitor:_create_signal(): nil
    self:_mark_disposable(input_svc.InputChanged:Connect(function(input, processed)
        if #self._binds > 0 and self:_can_process(input) then
            for index, bind in pairs(self._binds) do
                for _, context in pairs(bind[1]) do
                    local valid = false
                    
                    if context.EnumType == Enum.UserInputType and input.UserInputType == context then
                        valid = true
                    elseif context.EnumType == Enum.KeyCode and input.KeyCode == context then
                        valid = true
                    end
                    
                    if valid then
                        task.defer(bind[2](input, processed))
                        
                        if bind[3] then
                            table.remove(self._binds, index)
                        end
                    end
                end
            end
        end
    end))
end

--= Class API =--
function InputMonitor:Bind(context: table, callback: (InputObject, boolean)->()): nil
    table.insert(self._binds, { context, callback })
end

function InputMonitor:BindOnce(context: table, callback: (InputObject, boolean)->()): nil
    table.insert(self._binds, { context, callback, true })
end

--= Class Constructor =--
function InputMonitor.new(): any
    local self = classify(InputMonitor)
    
    self._active = true
    self._input_state = Enum.UserInputState.End
    self._binds = { }
    
    self:_create_signal()
    return self
end

--= Class Properties =--
InputMonitor.__properties = {
    Active = {
        get = function(self)
            return self._active
        end,
        set = function(self, value: boolean)
            self._active = value
            self:_dispose()
            
            if value then
                self:_create_signal()
            end
        end
    },
    InputState = {
        bind = '_input_state',
        target = function(self) return self end
    }
}

--= Return Class =--
return InputMonitor