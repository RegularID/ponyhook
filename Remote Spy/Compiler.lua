local Compiler = {}
local NullInstances = {}

local Settings = import "Settings"

local math_round = function(Number, Decimals)
    Decimals = Decimals or 0
    return string.format("%." .. Decimals .. "f", Number)
end


local get_table_length = function(Table)
    local Length = 0
    for _ in pairs(Table) do
        Length = Length + 1
    end
    return Length
end


local is_table_dictionary = function(Table)
    for _ in ipairs(Table) do
        return false
    end
    
    return true
end


local table_clone
table_clone = function(Table)
    local Clone = {}
    for k, v in pairs(Table) do
        if typeof(v) == "table" then
            Clone[k] = table_clone(v)
        else
            Clone[k] = v
        end
    end

    return Clone
end


local Players = game:GetService("Players")


function _G.GetNull(Index)
    if Index > #NullInstances or Index < 1 then
        return error("Index out of range")
    end

    return NullInstances[Index]
end


-- This function should be transformed into a UserDataToTable
-- for example we could use like CFrames to do {p = a, LookVector = b, RightVector = c, X = 999}
function Compiler:InstanceToTable(self:Instance, All:boolean):table
    local function Recurse(self:table, Function:Function):table
        local Result = {}
        if typeof(self) == "table" then
            for k, v in pairs(self) do
                if typeof(v) == "table" then
                    Result[k] = Recurse(v, Function)
                else
                    Result[k] = Function(k, v)
                end
            end
        end

        return Result
    end
                    
    local Result = {}
    
    if All == true then
        for _, v in ipairs(self:GetChildren()) do
            Result[tostring(v)] = InstanceToTable(v, true)
        end
    else
        for _, v in ipairs(self:GetChildren()) do
            Result[tostring(v)] = v
        end
    end
    
    -- Overwrite, Properties are more important than children
    if typeof(self) == "Instance" and typeof(getproperties) == "function" then
        for k, v in pairs(getproperties(self)) do
            Result[k] = v
        end
    end
    
    return Result
end


function Compiler:GetPath(self)
    local Path = ""
    
    local Parents = {}
    
    local Parent = self.Parent
    while Parent do
        table.insert(Parents, Parent)
        Parent = Parent.Parent
    end

    -- reverse the 'Parents' table
    for i = 1, math.round(#Parents / 2) do
        local j = #Parents - i + 1
        Parents[i], Parents[j] = Parents[j], Parents[i]
    end
    table.remove(Parents, 1)

    local Service = table.remove(Parents, 1)
    
    -- this is messy
    if self == game then
        return "game"
    elseif self == workspace then
        return "workspace"
    elseif Service == workspace then
        Path = "workspace"
    elseif Service == Players then
        -- i think it should be like this
        Path = "game:GetService(\"Players\")
        if typeof(Parents) == "table" and Parents[1] == Players.LocalPlayer then
            Path ..= ".LocalPlayer"
            table.remove(Parents, 1)
            -- print(Parents[1])
            if Parents[1] == Players.LocalPlayer.Character then
                Path ..= ".Character"
                table.remove(Parents, 1)
            end
        end
    elseif Service == nil or not self:IsDescendantOf(game) then
        local Index = table.find(NullInstances, self)
        if not Index then
            Index = #NullInstances + 1
        end
        
        table.insert(NullInstances, self)
        return Path .. "_G.GetNull(" .. Index .. ")"
    else
        Path = "game:GetService(\"" .. Service.ClassName .. "\"" .. ")"
    end
    
    table.insert(Parents, self)
    for _, Parent in ipairs(Parents) do
        Path ..= ":FindFirstChild(\"" .. tostring(Parent) .. "\"" .. ")"
    end

    return Path
end


function Compiler:ToString(self)
    -- Technically it was github copilot who typed all of the elseifs
    local Type = typeof(self)

    if Type == "Instance" then
        return Compiler:GetPath(self)
    elseif Type == "string" then
	local Patterns = {
	    ["\n"] = "\\n",
	    ["\t"] = "\\t",
	    ["\r"] = "\\r"
	}

	for Pattern, Value in pairs(Patterns) do
	    self = string.gsub(self, Pattern, Value)
	end

        return "\"" .. self .. "\""
    elseif Type == "number" then
        local Rounded = math_round(self, 3)

        -- if the last number is a 0 or a . then we will remove it; repeat this process until we have a clear number
        while string.sub(Rounded, #Rounded, #Rounded) == "0" do
            Rounded = string.sub(Rounded, 1, #Rounded - 1)
            if string.sub(Rounded, #Rounded, #Rounded) == "." then
                Rounded = string.sub(Rounded, 1, #Rounded - 1)
                break
            end
        end
        return self == 9e9 and "9e9" or self == math.huge and "math.huge" or tostring(Rounded)
    elseif Type == "boolean" then
        return tostring(self)
    elseif Type == "table" then
        local function Recurse(Table, Iteration)
            local Iteration = typeof(Iteration) == "number" and Iteration or 1
            local Whitespace = string.rep(" ", Iteration * 4)
            local String = ""
        
            local IsArray = not is_table_dictionary(Table)
            local Length = get_table_length(Table)

            if Length == 1 then
                Whitespace = ""
            end

            local Index = 0
            for k, v in pairs(Table) do
                Index += 1
                String ..= Whitespace

                if not IsArray then
                    if Table == k then continue end
                    String ..= "[" .. Compiler:ToString(k) .. "] = "
                end

                if typeof(v) == "table" then
                    if Table == v then continue end
                    String ..= Recurse(v, Iteration + 1)
                else
                    String ..= Compiler:ToString(v)
                end

                if Index < Length then
                    String ..= ",\n"
                end
            end
        
        
            Whitespace = string.rep(" ", (Iteration - 1) * 4)
            if Length == 1 then
                return "{" .. String .. "}" -- if there's only 1 item then we don't add newlines
            elseif Length > 0 then
                return "{\n" .. String .. "\n" .. Whitespace .. "}"
            else
                return "{}"
            end
        end

        return Recurse(self)
    elseif Type == "function" then
        return "function() end"
    elseif Type == "EnumItem" then
        return "Enum." .. tostring(self.EnumType) .. "." .. tostring(self.Name)
    elseif Type == "Vector2" then
        return "Vector2.new(" .. Compiler:ToString(self.X) .. ", " .. Compiler:ToString(self.Y) .. ")"
    elseif Type == "Vector2int16" then
        return "Vector2int16.new(" .. Compiler:ToString(self.X) .. ", " .. Compiler:ToString(self.Y) .. ")"
    elseif Type == "Vector3" then
        return "Vector3.new(" .. Compiler:ToString(self.X) .. ", " .. Compiler:ToString(self.Y) .. ", " .. Compiler:ToString(self.Z) .. ")"
    elseif Type == "Vector3int16" then
        return "Vector3int16.new(" .. Compiler:ToString(self.X) .. ", " .. Compiler:ToString(self.Y) .. ", " .. Compiler:ToString(self.Z) .. ")"
    elseif Type == "CFrame" then
        return "CFrame.new(" .. Compiler:ToString(self.Position) .. ", " .. Compiler:ToString(self.LookVector) .. ")"
    elseif Type == "Color3" then
        return "Color3.new(" .. Compiler:ToString(self.r) .. ", " .. Compiler:ToString(self.g) .. ", " .. Compiler:ToString(self.b) .. ")"
    elseif Type == "BrickColor" then
        return "BrickColor.new(" .. Compiler:ToString(self.Number) .. ")" -- number instead of color because shorter
    elseif Type == "UDim" then
        return "UDim.new(" .. Compiler:ToString(self.Scale) .. ", " .. Compiler:ToString(self.Offset) .. ")"
    elseif Type == "UDim2" then
        return "UDim2.new(" .. Compiler:ToString(self.Width) .. ", " .. Compiler:ToString(self.Height) .. ")"
    elseif Type == "Ray" then
        return "Ray.new(" .. Compiler:ToString(self.Origin) .. ", " .. Compiler:ToString(self.Direction) .. ")"
    elseif Type == "Axis" then
        return "Axis.new(" .. Compiler:ToString(self.X) .. ", " .. Compiler:ToString(self.Y) .. ", " .. Compiler:ToString(self.Z) .. ")"
    elseif Type == "Faces" then
        return "Faces.new(" .. Compiler:ToString(self.Right) .. ", " .. Compiler:ToString(self.Left) .. ", " .. Compiler:ToString(self.Top) .. ", " .. Compiler:ToString(self.Bottom) .. ", " .. Compiler:ToString(self.Front) .. ", " .. Compiler:ToString(self.Back) .. ")"
    elseif Type == "Region3" then
        return "Region3.new(" .. Compiler:ToString(self.Min) .. ", " .. Compiler:ToString(self.Max) .. ")"
    elseif Type == "Region3int16" then
        return "Region3int16.new(" .. Compiler:ToString(self.Min) .. ", " .. Compiler:ToString(self.Max) .. ")"
    elseif Type == "Rect" then
        return "Rect.new(" .. Compiler:ToString(self.Min) .. ", " .. Compiler:ToString(self.Max) .. ")"
    elseif Type == "Rectint16" then
        return "Rectint16.new(" .. Compiler:ToString(self.Min) .. ", " .. Compiler:ToString(self.Max) .. ")"
    elseif Type == "TweenInfo" then
        return "TweenInfo.new(" .. Compiler:ToString(self.Time) .. ", " .. Compiler:ToString(self.EasingStyle) .. ", " .. Compiler:ToString(self.EasingDirection) .. ")"
    elseif Type == "NumberRange" then
        return "NumberRange.new(" .. Compiler:ToString(self.Min) .. ", " .. Compiler:ToString(self.Max) .. ")"
    elseif Type == "NumberSequence" then
        return "NumberSequence.new(" .. Compiler:ToString(self.Keypoints) .. ")"
    elseif Type == "NumberSequenceKeypoint" then
        return "NumberSequenceKeypoint.new(" .. Compiler:ToString(self.Time) .. ", " .. Compiler:ToString(self.Value) .. ")"
    elseif Type == "PhysicalProperties" then
        return "PhysicalProperties.new(" .. Compiler:ToString(self.Density) .. ", " .. Compiler:ToString(self.Friction) .. ", " .. Compiler:ToString(self.Elasticity) .. ")"
    elseif Type == "ColorSequence" then
        return "ColorSequence.new(" .. Compiler:ToString(self.Keypoints) .. ")"
    elseif Type == "ColorSequenceKeypoint" then
        return "ColorSequenceKeypoint.new(" .. Compiler:ToString(self.Time) .. ", " .. Compiler:ToString(self.Value) .. ")"
    elseif Type == "Color3Sequence" then
        return "Color3Sequence.new(" .. Compiler:ToString(self.Keypoints) .. ")"
    elseif Type == "Color3SequenceKeypoint" then
        return "Color3SequenceKeypoint.new(" .. Compiler:ToString(self.Time) .. ", " .. Compiler:ToString(self.Value) .. ")"
    elseif Type == "CatalogSearchParams" then
        return "CatalogSearchParams.new()"
    elseif Type == "DockWidgetPluginGuiInfo" then
        return "DockWidgetPluginGuiInfo.new()"
    elseif Type == "nil" then
        return "nil"
    end

    return "[" .. Type .. "]"
end


function Compiler:Compile(self, Method, Arguments)
    local Arguments = table_clone(Arguments)

    local Name = "self"
    local Path = Compiler:GetPath(self)
    local CompiledCode = "-- // Generated by " .. table.concat(Settings.Authors, ", ") .. "\\\\ --\n"

    if Method == "FireServer" or Method == "Fire" or Method == "InvokeServer" or Method == "Invoke" then
        CompiledCode ..= "local " .. Name .. " = " .. Path .. "\n"
        CompiledCode ..= Name .. ":" .. Method .. "("

        if #Arguments > 1 then
            local Whitespace = string.rep(" ", 4)
            local FirstArgument = table.remove(Arguments, 1)
            local LastArgument = table.remove(Arguments, #Arguments)

            CompiledCode ..= Compiler:ToString(FirstArgument) .. ",\n"
            for _, Argument in ipairs(Arguments) do
                if typeof(Argument) == "table" then
                    CompiledCode ..= " " .. Compiler:ToString(Argument) .. ",\n"
                else
                    CompiledCode .. = Whitespace .. Compiler:ToString(Argument) .. ",\n"
                end
            end
            CompiledCode ..= Whitespace .. Compiler:ToString(LastArgument) .. ")\n"
        else
            CompiledCode ..= Compiler:ToString(Arguments[1]) .. ")\n"
        end
    else -- Event, OnInvoke, OnClientEvent, OnClientInvoke
        CompiledCode ..= "-- // Arguments \\\\ --\n"
        local LastArgument = table.remove(Arguments, #Arguments)
        for _, Argument in ipairs(Arguments) do
            CompiledCode .. = Compiler:ToString(Argument) .. ", "
        end
        CompiledCode ..= Compiler:ToString(LastArgument) .. "\n"
        CompiledCode ..= "-- // Remote info \\\\ --\n"
        CompiledCode ..= "-- Path: " .. Path .. "\n"
        CompiledCode ..= "-- Method: " .. Method .. "\n"
        CompiledCode ..= "-- ClassName: " .. self.ClassName .. "\n"
    end

    return CompiledCode
end

return Compiler
