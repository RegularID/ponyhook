# ponyhook
Public version of ponyhook.cc

# Loader.lua
```lua
local ScriptName = "The Streets" -- Script Name here; ex : The Streets

local request = request or syn and syn.request


local FilePath = string.gsub(ScriptName, "%s", "%%20")
local RepositoryPath = "https://raw.githubusercontent.com/RegularID/ponyhook/main/" .. FilePath .. "/"

function import(Name: string)
    local Name = string.gsub(Name, "%s", "%%20") -- Replacing Spaces with %20's
    local Url = RepositoryPath .. Name .. ".lua"
    local Response = request({Url = Url})
    local Source = loadstring(Response.Body)
    local Success, Result = pcall(Source)
    
    if not Success then
        if Source == nil then
            warn("Url: " .. Url .. " " .. Response.StatusMessage)
        else
            warn(Result)
        end
        
        return
    end
    
    return Result
end

getgenv().import = import
import "Source"
```
