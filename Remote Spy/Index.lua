local Index = {}
local Remotes = {}

Listener = import("Listener")

local function CreateLog(Remote)
    if Remotes[Remote] then
        Remotes[Remote]:Update(Remote, Remote.Logs[#Remote.Logs])
    else
        Remotes[Remote] = Menu:AddRemote(Remote)
    end
end


function Index:Kill()
    Listener:Kill()
end


function Index:Clear()
    for _, Remote in pairs(Remotes) do
        Remote:Remove()
    end
    table.clear(Remotes)
end


do
    local Remotes = Listener:Get()
    for _, Remote in ipairs(Remotes) do
        CreateLog(Remote)
    end
end


Listener:Add("Index", function(Remote)
    CreateLog(Remote)
end)


return Index