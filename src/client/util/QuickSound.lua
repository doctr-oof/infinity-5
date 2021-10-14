--[[
    QuickSound.lua
    FriendlyBiscuit
    Created on 05/18/2021 @ 20:21:24
    
    Description:
        Local Sound Utility.
    
    Documentation:
        No documentation provided.
--]]


--= Module Loader =--
local require       = require(game.ReplicatedStorage:WaitForChild('Infinity'))

--= Root =--
local QuickSound    = { }

--= Modules & Config =--
local sound_data    = require('$config/SoundIds')
local out           = require('$util/EasyOutput')

--= Roblox Services =--
local run_svc       = game:GetService('RunService')
local sound_svc     = game:GetService('SoundService')

--= Object References =--
local local_player  = game.Players.LocalPlayer
local studio = not run_svc:IsRunning()
local storage = studio and sound_svc or local_player:WaitForChild('PlayerGui')

--= Variables =--
local volume_multi  = 1

--= Internal =--
function play(key, volume, pitch)
    local _info = sound_data[key]
    
    if _info then
        local sound = Instance.new('Sound', storage)
        sound.SoundId = type(_info[1]) == 'string' and _info[1] or 'rbxassetid://' .. _info[1]
        sound.Volume = (volume and volume or _info[2]) * volume_multi
        sound.PlaybackSpeed = pitch and pitch or 1
        
        if studio then
            sound_svc:PlayLocalSound(sound)
            
            spawn(function()
                while sound.Playing do wait() end
                sound:Destroy()
            end)
        else
            sound.Ended:Connect(function()
                sound:Destroy()
            end)
            
            sound:Play()
        end
    else
        out.warn('Failed to .Play() sound key "%s" - key not found in SoundData!', key)
    end
end

--= API =--
QuickSound.Play = play
QuickSound.play = play

--= Return =--
return QuickSound