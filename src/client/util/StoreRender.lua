--= Module Loader =--
local require   = require(game.ReplicatedStorage:WaitForChild('Skateworks'))

--= Modules & Config =--
local resource  = require('$lib/Resources')
local get       = require('$util/EasyGet')
local out       = require('$util/EasyOutput')

--= Main Function =--
return function(frame: any, settings: table, data: table): void
    if not settings.MethodOverride then
        local model = resource:Get('rendermodels/' .. settings.Model)
        
        if model then
            local cam = Instance.new('Camera', get(frame, 'ProductRender'))
            cam.CFrame = settings.Params.CameraPos
            cam.FieldOfView = settings.Params.CameraFov or cam.FieldOfView
            get(frame, 'ProductRender').CurrentCamera = cam
            model:SetPrimaryPartCFrame(settings.Params.ModelPos)
            model.Parent = get(frame, 'ProductRender')
            
            if settings.Params.LightColor then
                get(frame, 'ProductRender').LightColor = settings.Params.LightColor
            end
            
            for target, properties in pairs(settings.Targets) do
                local object = get(model, target)
                
                if object then
                    for property, key in pairs(properties) do
                        local value = data[key]
                        
                        if value then
                            object[property] = value
                        else
                            out.warn('Failed to render "%s" - key "%s" not found.', settings.Model, key)
                        end
                    end
                else
                    out.warn('Failed to fully render "%s" - target "%s" not found.', settings.Model, target)
                end
            end
        else
            out.warn('Failed to render "%s" - model not found.', settings.Model)
        end
    elseif settings.MethodOverride == 'UniqueModel' then
        local model = resource:Get(settings.PathRoot .. data.Model)
        
        if model then
            local cam = Instance.new('Camera', get(frame, 'ProductRender'))
            cam.CFrame = settings.Params.CameraPos
            cam.FieldOfView = settings.Params.CameraFov or cam.FieldOfView
            get(frame, 'ProductRender').CurrentCamera = cam
            
            if model:GetAttribute('Legacy') then
                model:SetPrimaryPartCFrame(settings.Params.ModelPos * CFrame.Angles(0, math.rad(90), 0))
            else
                model:SetPrimaryPartCFrame(settings.Params.ModelPos)
            end
            
            model.Parent = get(frame, 'ProductRender')
        else
            out.warn('Failed to render unique model "%s" - model not found.', data.Model)
        end
    elseif settings.MethodOverride == 'Gradient' then
        get(frame, 'ProductRender').Visible = false
        get(frame, 'ProductTexture').Visible = false
        get(frame, 'ProductGradient').Visible = true
        
        local keypoints = { }
        
        for _, key in pairs(data.Gradient) do
            table.insert(keypoints, ColorSequenceKeypoint.new(key[1], key[2]))
        end
        
        get(frame, 'ActualGradient').Color = ColorSequence.new(keypoints)
    elseif settings.MethodOverride == 'Texture' then
        get(frame, 'ProductRender').Visible = false
        get(frame, 'ProductGradient').Visible = false
        get(frame, 'ProductTexture').Visible = true
        get(frame, 'ProductTexture').Image = data[settings.Texture]
    end
end