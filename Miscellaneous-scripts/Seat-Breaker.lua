local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character
local Humanoid = Character:WaitForChild("Humanoid")

local function FindOpenSeat()
    local Seats = {}
    for _, v in ipairs(workspace:GetDescendants()) do -- workspace:GetDescendants() cry about it
        if v:IsA("Seat") then
            table.insert(Seats, v)
        end
    end
    
    for _, Seat in ipairs(Seats) do
        if not Seat:FindFirstChild("SeatWeld") then
            return Seat
        end
    end
end

local Seat = FindOpenSeat()

-- basically the indicator here is that if u don't die GOOD JOB
if Seat then
    Humanoid:ChangeState(11)
    Character.Head:Destroy() -- server kill
    wait(0.1) -- idk needs a small yield Lol?
    Seat:Sit(Humanoid)
end
