local Status = {}

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local GameMain = workspace:WaitForChild("GameMain")
local GameStatus = GameMain:WaitForChild("GameStatus")
local GameSession = GameStatus:WaitForChild("SessionData")

local function Update()
    Status = HttpService:JSONDecode(GameSession.Value)
end


Update()
RunService.Heartbeat:Connect(Update)

return Status