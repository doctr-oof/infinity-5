--[[
    Timer.lua
    Retro_Mada
    Created on 02/11/2022 @ 18:53:02
    
    Description:
        No description provided.
    
    Documentation:
        No documentation provided.
--]]

--= Module Loader =--
local require = require(game.ReplicatedStorage:WaitForChild('Infinity'))

--= Root =--
local Timer = { }

--= Jobs =--

--= Classes =--

--= Modules & Config =--
local network   = require('$lib/Network')
local fetch     = require('$util/FetchSync')

--= Roblox Services =--

--= Object References =--
local local_player      = game.Players.LocalPlayer
local player_gui        = local_player:WaitForChild('PlayerGui')

--= Constants =--

--= Variables =--
--local timer_ui  = fetch(player_gui, 'Timer')
--local label     = fetch(timer_ui, 'Label')
local notify_queue = { }


--= Shorthands =--

--= Functions =--

--= Job API =--
local function set_notify_text(text: string): nil
   -- label.Text = text
end

--= Job Initializers =--
function Timer:Run(): nil

    network:Fired('Notify', function(text: str, delay: number)
        notify_queue[#notify_queue+1] = { text, delay and delay or 1 }
    end)
    --[[
    task.defer(function()
        while task.wait(1) do
            if #notify_queue > 0 then
                local notif = notify_queue[1]
                table.remove(notify_queue, 1)

                set_notify_text(notif[1])
                timer_ui.Enabled = true
                task.wait(1)
                timer_ui.Enabled = false
            end
        end
    end)--]]
end

function Timer:Init(): nil
    
end

--= Return Job =--
return Timer