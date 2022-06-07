local Network = {}

local GameMain = workspace:WaitForChild("GameMain")
local Triggers = GameMain:WaitForChild("Triggers")


local Methods = {
    DAMAGE = function(Target:Instance, WeaponType:string, WeaponName:string)
        -- 110 is just damage im assuming
        if WeaponType == "Revolver" then
            Triggers.Damage:FireServer("Revolver", Target, 110, WeaponName)
        elseif WeaponType == "Knife" then
            Triggers.Damage:FireServer("Knife", Target, 110, {
                "Throw"
            }, WeaponName, "Default")
        end
    end,

    PLAY_RADIO = function(SoundId:string, Pause:boolean)
        Triggers.Radio.StatusUdate:FireServer(SoundId, Pause)
    end,

    GET_XBOX_KNIFE = function()
        Triggers.Promo:FireServer()
    end,

    BUY_ITEM = function(Type:string, Name:string)
        Triggers.UIControl.BuyItem:FireServer(Type, Name)
    end,

    EQUIP_ITEM = function(Type:string, Name:string)
        Triggers.UIControl.EquipItem:FireServer(Type, Name)
    end,

    GEAR_EFFECT = function(Gear, ...)
        Triggers.GearEffects:FireServer(Gear, "Client", ...)
    end
}


function Network:Send(Name:string, ...)
    local Method = Methods[string.upper(Name)]
    if Method then
        Method(...)
    end
end


return Network