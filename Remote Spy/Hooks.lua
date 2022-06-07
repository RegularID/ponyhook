local Hooks = {}
local hooks = {} -- or Hooks.Hooks


function Hooks:Get()
    return hooks
end


function Hooks.new(Name, self, Settings)
    local Hook = {
        Name = Name,
        self = self,
        Settings = Settings
    }


    function Hook:GetSettings()
        return Hook.Settings
    end


    function Hook:Edit(Settings)
        Hook.Settings = Settings
    end


    function Hook:Destroy()
        hooks[self] = nil
    end

    hooks[self] = Hook
    return Hook
end


return Hooks