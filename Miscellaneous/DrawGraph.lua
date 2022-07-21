local RunService = game:GetService("RunService")


local function DrawLine(Start: Vector2, End: Vector2, Thickness: number, Color: Color3, Transparency: number)
    local Line = Drawing.new("Line")
    Line.From = Start
    Line.To = End
    Line.Color = typeof(Color) == "Color3" and Color or Color3.new(1, 1, 1)
    Line.Transparency = typeof(Transparency) == "number" and Transparency or 1
    Line.Thickness = typeof(Thickness) == "number" and Thickness or 1
    Line.Visible = true
    
    return Line
end


local function DrawGraph(Name: string, Size: Vector2, Position: Vector2, Callback: any): Graph
    local Graph = {}
    local Lines = {}
    
    Graph.Thick = false
    
    local function GetValue(): number
        return math.clamp(Callback(), 0, Size.Y)
    end
    
    local Title = Drawing.new("Text")
    Title.Text = Name
    Title.Color = Color3.new(1, 1, 1)
    Title.OutlineColor = Color3.new()
    Title.Position = Position + Vector2.new(0, -Size.Y - Title.TextBounds.Y)
    Title.Outline = true
    Title.Visible = true
    
    local Box = Drawing.new("Quad")
    Box.Thickness = 1
    Box.Transparency = 0.3
    Box.PointA = Vector2.new(Position.X + 1, Position.Y - Size.Y)
    Box.PointB = Vector2.new(Position.X + Size.X + 1, Position.Y - Size.Y)
    Box.PointC = Vector2.new(Position.X + Size.X + 1, Position.Y + 1)
    Box.PointD = Vector2.new(Position.X + 1, Position.Y + 1)
    Box.Filled = true
    Box.Visible = true
    
    local LastValue = -GetValue()
    function Graph:Init()
        self.Box = Box
        self.Title = Title
        self.Lines = Lines
        
        for i = 1, Size.X do
            local Value = -GetValue()
            local From = Position + Vector2.new(i, 0)
            local To = From + Vector2.new(1, Value)
            
            if not self.Thick then
                From += Vector2.new(0, LastValue)
            end
            LastValue = Value
            
            table.insert(Lines, DrawLine(From, To))
            RunService.RenderStepped:Wait()
        end
        
        return self
    end
    
    function Graph:SetForeground(Color: Color3)
        assert(typeof(Color) == "Color3", "Color3 expected for Color got '" .. typeof(Color) .. "'")
        for _, Line in ipairs(self.Lines) do
            Line.Color = Color
        end
        
        return self
    end
    
    function Graph:SetTitle(Title: string)
        assert(typeof(Title) == "string", "string expected for Title got '" .. typeof(Title) .. "'")
        self.Title.Text = Title
        
        return self
    end
    
    function Graph:Update()
        local Line = table.remove(Lines, 1)
        
        for _, Line in ipairs(Lines) do
            Line.From = Line.From - Vector2.new(1, 0)
            Line.To = Line.To - Vector2.new(1, 0)
        end
        
        local Value = -GetValue()
        local From = Position + Vector2.new(Size.X, 0)
        local To = From + Vector2.new(1, Value)

        if not self.Thick then
            From += Vector2.new(0, LastValue)
        end
        LastValue = Value
        
        Line.From = From
        Line.To = To
        
        table.insert(Lines, Line)
        
        return self
    end
    
    function Graph:Destroy()
        self.Box:Remove()
        self.Title:Remove()
        for _, Line in ipairs(self.Lines) do
            Line:Remove()
        end
        table.clear(self.Lines)
    end
    
    return Graph
end


return DrawGraph
