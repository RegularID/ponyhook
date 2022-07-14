local wait = task.wait

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer
local Backpack = Player:WaitForChild("Backpack")
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local Tool = Character:FindFirstChild("Punch") or Backpack:FindFirstChild("Punch")
if not Tool then
    Tool = Backpack.ChildAdded:Wait()
    wait()
end


local function LoadHandles()
    Humanoid:UnequipTools()
    for _, v in ipairs(Backpack:GetChildren()) do
        if v:IsA("Tool") and v ~= Tool then
    	    v.Parent = Character
    	    wait()
            v.Parent = Backpack
        end
    end
end

local function SetToolsParent()
    LoadHandles()
    Humanoid:UnequipTools()
    wait(0.1)
    for _, v in ipairs(Backpack:GetChildren()) do
        if v:IsA("Tool") and v ~= Tool then
          -- not exactly sure what this is but we need this for replicating the parent to the tool; test it yourself using roblox studio
    	    v.Parent = Character
            v.Parent = Tool
            v.Parent = Backpack
            v.Parent = Tool
        end
        
        wait()
    end
end


local function GiveToolsPlayer(Target: Player)
    SetToolsParent()
    local tCharacter = typeof(Target) == "Instance" and Target:IsA("Player") and Target.Character
    if not tCharacter then return end
    
    local tHumanoid = tCharacter:FindFirstChild("Humanoid")
    local tRoot = tHumanoid and tHumanoid.RootPart
    if not tRoot then return end
    
    local Tools = {}
    for _, Tool in ipairs(Tool:GetChildren()) do
        if not Tool:IsA("Tool") then continue end
        table.insert(Tools, Tool)
    end

    Tool.Parent = Character
    for _, Tool in ipairs(Tools) do
        local Handle = Tool:WaitForChild("Handle")
        firetouchinterest(Handle, tRoot, 0)
        firetouchinterest(Handle, tRoot, 1)
    end
end

--GiveToolsPlayer(Players.bignamernixon) -- thanks for helping me debug and stuff
