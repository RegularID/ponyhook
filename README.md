# ponyhook
Public version of ponyhook.cc

# Loader.lua
```lua
local ScriptName = "The Streets" -- Script Name here; ex : The Streets

local request = request or syn and syn.request


local FilePath = string.gsub(ScriptName, "%s", "%%20")
local RepositoryPath = "https://raw.githubusercontent.com/RegularID/ponyhook/main/" .. FilePath .. "/"

local Imported = {}
function import(Name: string)
    local Name = string.gsub(Name, "%s", "%%20") -- Replacing Spaces with %20's (really i didn't know)

    if Imported[Name] then
        return Imported[Name]
    end

    local Url = RepositoryPath .. Name .. ".lua"
    local Response = request({Url = Url})
    local Source = loadstring(Response.Body, Name)
    local Success, Result = pcall(Source)
    
    if not Success then 
        warn((Source == nil and "Url: " .. Url .. " " .. Response.StatusMessage) or Result)
        return 
    end
    
    Imported[Name] = Result
    return Result
end

getgenv().import = import
import "Source"
```
