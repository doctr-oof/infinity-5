--[[
    QuickDebug.lua
    FriendlyBiscuit
    Created on 05/26/2021 @ 16:52:44
    
    Description:
        Allows developers to quickly attach input to callbacks via a rough testing buttons.
    
    Documentation:
        <TextButton> ::AddDebugButton(text: string, callback: Function)
        -> Creates and returns a quick and basic TextButton that will automatically appear
           on your screen. Useful for adding input to testing operations.
--]]

--= Root =--
local QuickDebug    = { Priority = 1 }

--= Object References =--
local local_player  = game.Players.LocalPlayer
local player_gui    = local_player:WaitForChild('PlayerGui')

--= Variables =--
local list

--= Job API =--
function QuickDebug:AddDebugButton(text: string, callback: Function): TextButton
    while not list do task.wait() end
    
    local button = Instance.new('TextButton', list)
    button.BackgroundColor3 = Color3.new(1, 1, 1)
    button.Size = UDim2.new(0, 150, 1, 0)
    button.Text = text
    button.Activated:Connect(callback)
    
    return button
end

--= Job Initializers =--
function QuickDebug:Init(): nil
    local screen_gui = Instance.new('ScreenGui', player_gui)
    screen_gui.IgnoreGuiInset = false
    screen_gui.ZIndexBehavior = 'Global'
    screen_gui.ResetOnSpawn = false
    screen_gui.DisplayOrder = 9999
    
    local frame = Instance.new('Frame', screen_gui)
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.Position = UDim2.fromOffset(0, 6)
    
    local layout = Instance.new('UIListLayout', frame)
    layout.HorizontalAlignment = 'Center'
    layout.FillDirection = 'Horizontal'
    
    list = frame
end

--= Return Job =--
return QuickDebug