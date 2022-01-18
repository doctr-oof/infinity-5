--[[
       ___  __     __  ___
      / _ \/ /__ _/ /_/ _/__  ______ _
     / ___/ / _ `/ __/ _/ _ \/ __/  ' \
    /_/  /_/\_,_/\__/_/ \___/_/ /_/_/_/
    FriendlyBiscuit
    01/18/2022 @ 13:18:22
    
    Description:
        Provides a quickly-accessible collection of flags that expose platform information to the client.
    
    Documentation:
        Flags:
            boolean IS_CONSOLE
            -> Returns whether or not the client is playing on a genuine console device.
            
            boolean IS_MOBILE
            -> Returns whether or not the client is playing on a genuine mobile device (emulator included).
            
            boolean IS_PC
            -> Returns true if IS_CONSOLE and IS_MOBILE are both false.
--]]

--= Module Root =--
local Platform      = { }

--= Roblox Services =--
local input_svc     = game:GetService('UserInputService')
local gui_svc       = game:GetService('GuiService')

--= Flags =--
Platform.IS_CONSOLE = gui_svc:IsTenFootInterface()

Platform.IS_MOBILE  = input_svc.TouchEnabled
                    and not input_svc.KeyboardEnabled
                    and not input_svc.MouseEnabled and not input_svc.GamepadEnabled
                    and not gui_svc:IsTenFootInterface()

Platform.IS_PC      = not Platform.IS_CONSOLE and not Platform.IS_MOBILE

--= Return Module =--
return Platform