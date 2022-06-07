local Profiles = {}

local HttpService = game:GetService("HttpService")

local GameMain = workspace:WaitForChild("GameMain")
local PlayerSessions = GameMain:WaitForChild("SessionProfiles")
local PlayerProfiles = GameMain:WaitForChild("PlayerProfiles")

function Profiles:GetPlayerProfile(Player:Player)
    local Profile = PlayerProfiles:FindFirstChild(tostring(Player))
    
    if not Profile then return {} end
    return HttpService:JSONDecode(Profile.Value)
end


function Profiles:GetPlayerSession(Player:Player)
    local Session = PlayerSessions:FindFirstChild(tostring(Player))
    
    if not Session then return {} end
    return HttpService:JSONDecode(Session.Value)
end


return Profiles