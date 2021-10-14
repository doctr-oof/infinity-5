local input_svc = game:GetService('UserInputService')
local gui_svc   = game:GetService('GuiService')
local IS_CONSOLE = gui_svc:IsTenFootInterface()
local IS_MOBILE = input_svc.TouchEnabled
    and not input_svc.KeyboardEnabled
    and not input_svc.MouseEnabled and not input_svc.GamepadEnabled
    and not gui_svc:IsTenFootInterface()
local IS_PC = not IS_CONSOLE and not IS_MOBILE

return {
    IS_CONSOLE = IS_CONSOLE,
    IS_MOBILE = IS_MOBILE,
    IS_PC = IS_PC
}