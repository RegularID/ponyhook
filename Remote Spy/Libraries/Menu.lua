local Menu = {}
local Windows = {}
local Dragging = {}

Menu.ScreenSize = Vector2.new()


local CoreGui = game:GetService("CoreGui")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Camera = workspace.CurrentCamera

local RenderSteppedLoop


local protect_gui = function(self, Parent)
    if typeof(syn) == "table" and syn.protect_gui then
        syn.protect_gui(self)
        self.Parent = Parent
    elseif typeof(gethui) == "function" then
        self.Parent = gethui()
    else
        self.Parent = Parent
    end
end


local Gui = Instance.new("ScreenGui")
protect_gui(Gui, CoreGui)
Gui.Name = "gui"
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling


local function ConvertVector(Value, Type)
    if Type == "UDim" then
        return typeof(Value) == "Vector2" and UDim.new(Value.X, Value.Y) or typeof(Value) == "UDim" and Value or UDim.new()
    end

    return typeof(Value) == "Vector2" and UDim2.fromOffset(Value.X, Value.Y) or typeof(Value) == "UDim2" and Value or UDim2.new()
end


local function AddEvent(self, Name)
    local Event = {}
    local Callbacks = {}

    function Event:Fire(...)
        for _, Callback in pairs(Callbacks) do
            Callback(...)
        end
    end

    function Event:Connect(Callback)
        if typeof(Callback) == "function" then
            Callbacks[Callback] = Callback

            return {
                Disconnect = function(self)
                    Callbacks[Callback] = nil
                end
            }
        end

        return error("Callback must be a function")
    end

    self[Name] = Event
    return Event
end


local function SetDraggable(self, Frame)
    local DragOrigin
    local GuiOrigin

    Frame.InputBegan:Connect(function(Input, Process)
        if (not Dragging.Gui and not Dragging.True) and (Input.UserInputType == Enum.UserInputType.MouseButton1) then
            for k, v in pairs(Windows) do
                v.Frame.ZIndex = 1
            end
            Frame.ZIndex = 2

            Dragging = {Gui = Frame, True = true}
            self.Dragging = true
            DragOrigin = Vector2.new(Input.Position.X, Input.Position.Y)
            GuiOrigin = Frame.Position
        end
    end)

    UserInput.InputChanged:Connect(function(Input, Process)
        if Dragging.Gui ~= Frame then return end
        if not (UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
            Dragging = {Gui = nil, True = false}
            self.Dragging = false
            return
        end

        if self.Draggable then
            if (Input.UserInputType == Enum.UserInputType.MouseMovement) then
                local Delta = Vector2.new(Input.Position.X, Input.Position.Y) - DragOrigin
                local ScreenSize = Menu.ScreenSize

                local ScaleX = (ScreenSize.X * GuiOrigin.X.Scale)
                local ScaleY = (ScreenSize.Y * GuiOrigin.Y.Scale)
                local OffsetX = math.clamp(GuiOrigin.X.Offset + Delta.X + ScaleX,   0, ScreenSize.X - Frame.AbsoluteSize.X)
                local OffsetY = math.clamp(GuiOrigin.Y.Offset + Delta.Y + ScaleY, -36, ScreenSize.Y - Frame.AbsoluteSize.Y)
                
                local Position = UDim2.fromOffset(OffsetX, OffsetY)
                Frame.Position = Position
            end
        end
    end)
end


local function GetTextBounds(Text, Size, Font)
    return TextService:GetTextSize(Text, Size, Font, Vector2.new())
end


local function CreateLine(Parent, Size, Position, Color)
    local Line = {}
    
    local Frame = Instance.new("Frame")
    Frame.Name = "Line"
    Frame.BackgroundColor3 = Color
    Frame.BorderSizePixel = 0
    Frame.Size = Size
    Frame.Position = Position
    Frame.ZIndex = 5
    Frame.Parent = Parent

    Line.self = Frame

    function Line:SetProperty(Name, Value)
        Frame[Name] = Value
    end

    return Line
end


local function CreateRounded(Parent, Size)
    local Rounded = {}

    local Corner = Instance.new("UICorner")
    Corner.Name = "Round"
    Corner.CornerRadius = ConvertVector(Size, "UDim")
    Corner.Parent = Parent

    Rounded.self = Corner

    function Rounded:SetSize(Size)
        Corner.CornerRadius = ConvertVector(Size, "UDim")
    end

    return Rounded
end


local function CreateLineClass(self)
    function self.Line(...)
        return CreateLine(self.Frame, ...)
    end
end


local function CreateLabelClass(self)
    function self.Label(Name, Size, Position, TextPositionX)
        local TextPositionX = typeof(TextPositionX) == "string" and TextPositionX or "Center"
        local Label = {}

        local TextLabel = Instance.new("TextLabel")
        TextLabel.Name = Name
        TextLabel.BackgroundTransparency = 1
        TextLabel.BorderSizePixel = 0
        TextLabel.Size = ConvertVector(Size)
        TextLabel.Position = ConvertVector(Position)
        TextLabel.Font = Enum.Font.SourceSans
        TextLabel.TextSize = 14
        TextLabel.TextColor3 = Color3.fromRGB(205, 205, 205)
        TextLabel.Text = ""
        TextLabel.TextXAlignment = Enum.TextXAlignment[TextPositionX]
        TextLabel.Parent = self.Frame

        Label.Name = Name
        Label.self = TextLabel

        function Label:GetText()
            return TextLabel.Text
        end
        
        function Label:SetLabel(Text)
            TextLabel.Text = typeof(Text) == "string" and Text or ""
            return Label
        end

        function Label:SetText(Text, Font, Size, Color, TextPositionX, TextPositionY)
            TextLabel.Text = typeof(Text) == "string" and Text or TextLabel.Text
            TextLabel.Font = Font or TextLabel.Font
            TextLabel.TextSize = Size or TextLabel.TextSize
            TextLabel.TextColor3 = Color or TextLabel.TextColor3
            TextLabel.TextXAlignment = typeof(TextPositionX) == "string" and TextPositionX or TextLabel.TextXAlignment.Name
            TextLabel.TextYAlignment = typeof(TextPositionY) == "string" and TextPositionY or TextLabel.TextYAlignment.Name
            return Label
        end

        function Label:SetPosition(Position)
            TextLabel.Position = ConvertVector(Position)
            return Label
        end

        function Label:SetSize(Size)
            TextLabel.Size = ConvertVector(Size)
            return Label
        end

        function Label:SetBorder(Color, Size, Mode)
            TextLabel.BorderSizePixel = typeof(Size) == "number" and Size or 0
            TextLabel.BorderColor3 = typeof(Color) == "Color3" and Color or Color3.fromRGB(35, 35, 35)
            TextLabel.BorderMode = typeof(Mode) == "string" and Mode or "Outline"
            return Label
        end

        function Label:SetBackground(Color, Transparency)
            TextLabel.BackgroundColor3 = typeof(Color) == "Color3" and Color or Color3.fromRGB(45, 45, 45)
            TextLabel.BackgroundTransparency = typeof(Transparency) == "number" and Transparency or 0
            return Label
        end

        function Label:SetColor(Color, Transparency, StrokeTransparency)
            TextLabel.TextColor3 = typeof(Color) == "Color3" and Color or Color3.fromRGB(205, 205, 205)
            TextLabel.TextTransparency = typeof(Transparency) == "number" and Transparency or 0
            TextLabel.TextStrokeTransparency = typeof(StrokeTransparency) == "number" and StrokeTransparency or 0.75
            return Label
        end

        table.insert(self.Items, Label)
        return Label
    end
end


local function CreateButtonClass(self)
    function self.Button(Name, Size, Position, TextPositionX, Callback)
        local Button = {}

        local TextButton = Instance.new("TextButton")
        local Rounded = CreateRounded(TextButton, Vector2.new())

        TextButton.Name = Name
        TextButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        TextButton.BorderSizePixel = 0
        TextButton.Size = ConvertVector(Size)
        TextButton.Position = ConvertVector(Position)
        TextButton.Font = Enum.Font.SourceSans
        TextButton.Text = ""
        TextButton.TextXAlignment = Enum.TextXAlignment[TextPositionX] or Enum.TextXAlignment.Center
        TextButton.TextColor3 = Color3.fromRGB(205, 205, 205)
        TextButton.TextSize = 14
        TextButton.AutoButtonColor = false
        TextButton.Parent = self.Frame
        TextButton.MouseButton1Click:Connect(function()
            if typeof(Callback) == "function" then
                Callback()
            end
        end)

        Button.Name = Name
        Button.self = TextButton

        function Button:SetLabel(Text)
            TextButton.Text = typeof(Text) == "string" and Text or ""
            return Button
        end

        function Button:SetPosition(Position)
            TextButton.Position = ConvertVector(Position)
            return Button
        end

        function Button:SetSize(Size)
            TextButton.Size = ConvertVector(Size)
            return Button
        end

        function Button:SetBorder(Color, Size, Mode)
            TextButton.BorderSizePixel = typeof(Size) == "number" and Size or 0
            TextButton.BorderColor3 = typeof(Color) == "Color3" and Color or Color3.fromRGB(35, 35, 35)
            TextButton.BorderMode = typeof(Mode) == "string" and Mode or "Outline"
            return Button
        end

        function Button:SetBackground(Color, Transparency)
            TextButton.BackgroundColor3 = typeof(Color) == "Color3" and Color or Color3.fromRGB(45, 45, 45)
            TextButton.BackgroundTransparency = typeof(Transparency) == "number" and Transparency or 0
            return Button
        end

        function Button:SetRounded(Size)
            Rounded:SetSize(Size)
            return Button
        end

        table.insert(self.Items, Button)
        return Button
    end
end


local function CreateTextBoxClass(self)
    function self.TextBox(Name, Size, Position, Text, PlaceholderText, Callback)
        local TextBox = {}

        local _TextBox = Instance.new("TextBox")
        local Rounded = CreateRounded(_TextBox, Vector2.new())

        _TextBox.Name = Name
        _TextBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        _TextBox.BorderSizePixel = 0
        _TextBox.Size = ConvertVector(Size)
        _TextBox.Position = ConvertVector(Position)
        _TextBox.Font = Enum.Font.SourceSans
        _TextBox.Text = typeof(Text) == "string" and Text or ""
        _TextBox.PlaceholderText = typeof(PlaceholderText) == "string" and PlaceholderText or ""
        _TextBox.TextColor3 = Color3.fromRGB(205, 205, 205)
        _TextBox.PlaceholderColor3 = Color3.fromRGB(85, 85, 85)
        _TextBox.TextSize = 14
        _TextBox.Parent = self.Frame
        _TextBox:GetPropertyChangedSignal("Text"):Connect(function()
            if typeof(Callback) == "function" then
                Callback(_TextBox.Text)
            end
        end)

        TextBox.Name = Name
        TextBox.self = _TextBox

        function TextBox:GetText()
            return _TextBox.Text
        end

        function TextBox:SetText(Text)
            _TextBox.Text = typeof(Text) == "string" and Text or ""
            return TextBox
        end

        function TextBox:SetRichText(Boolean)
            _TextBox.RichText = typeof(Boolean) == "boolean" and Boolean or false
            return TextBox
        end

        function TextBox:SetPosition(Position)
            _TextBox.Position = ConvertVector(Position)
            return TextBox
        end

        function TextBox:SetSize(Size)
            _TextBox.Size = ConvertVector(Size)
            return TextBox
        end

        function TextBox:SetBorder(Color, Size, Mode)
            _TextBox.BorderSizePixel = typeof(Size) == "number" and Size or 0
            _TextBox.BorderColor3 = typeof(Color) == "Color3" and Color or Color3.fromRGB(35, 35, 35)
            _TextBox.BorderMode = typeof(Mode) == "string" and Mode or "Outline"
            return TextBox
        end

        function TextBox:SetBackground(Color, Transparency)
            _TextBox.BackgroundColor3 = typeof(Color) == "Color3" and Color or Color3.fromRGB(45, 45, 45)
            _TextBox.BackgroundTransparency = typeof(Transparency) == "number" and Transparency or 0
            return TextBox
        end

        function TextBox:SetRounded(Size)
            Rounded:SetSize(Size)
            return TextBox
        end
        

        table.insert(self.Items, TextBox)
        return TextBox
    end
end


local function CreateCheckBoxClass(self)
    function self.CheckBox(Name, Size, Position, Text, Checked, Callback)
        local CheckBox = {}
        CheckBox.Checked = typeof(Checked) == "boolean" and Checked or false

        local TextButton = Instance.new("TextButton")
        local Rounded = CreateRounded(TextButton, Vector2.new())

        TextButton.Name = Name .. "CheckBox"
        TextButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        TextButton.BorderSizePixel = 0
        TextButton.Size = UDim2.fromOffset(15, 15)
        TextButton.Position = ConvertVector(Position)
        TextButton.Text = CheckBox.Checked and "✓" or ""
        TextButton.Font = Enum.Font.SourceSans
        TextButton.TextColor3 = Color3.fromRGB(40, 115, 140)
        TextButton.TextSize = 14
        TextButton.AutoButtonColor = false
        TextButton.Parent = self.Frame
        TextButton.MouseButton1Click:Connect(function()
            CheckBox.Checked = not CheckBox.Checked
            TextButton.Text = CheckBox.Checked and "✓" or ""
            if typeof(Callback) == "function" then
                Callback(CheckBox.Checked)
            end
        end)

        CheckBox.Name = Name
        CheckBox.self = TextButton

        function CheckBox:SetLabel(Text)
            TextButton.Text = typeof(Text) == "string" and Text or ""
            return CheckBox
        end

        function CheckBox:SetPosition(Position)
            TextButton.Position = ConvertVector(Position)
            return CheckBox
        end

        function CheckBox:SetSize(Size)
            TextButton.Size = ConvertVector(Size)
            return CheckBox
        end

        function CheckBox:SetRounded(Size)
            Rounded:SetSize(Size)
            return CheckBox
        end

        function CheckBox:SetValue(Value)
            CheckBox.Checked = Value
            TextButton.Text = CheckBox.Checked and "✓" or ""
            return CheckBox
        end

        table.insert(self.Items, CheckBox)
        return CheckBox
    end
end


local function CreateDropdownClass(self)
    function self.Dropdown(Name, Size, Position, Text, Callback)
        local Dropdown = {}
        Dropdown.Visible = false

        local TextButton = Instance.new("TextButton")
        local Frame = Instance.new("Frame")
        local Rounded = CreateRounded(TextButton, Vector2.new())

        TextButton.Name = Name
        TextButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        TextButton.BorderSizePixel = 0
        TextButton.Size = ConvertVector(Size)
        TextButton.Position = ConvertVector(Position)
        TextButton.Font = Enum.Font.SourceSans
        TextButton.Text = typeof(Text) == "string" and Text or ""
        TextButton.TextColor3 = Color3.fromRGB(205, 205, 205)
        TextButton.TextSize = 14
        TextButton.Parent = self.Frame
        TextButton.MouseButton1Click:Connect(function()
            Dropdown.Visible = not Dropdown.Visible
        end)

        Frame.Name = "Dropdown"
        Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        Frame.BorderSizePixel = 0

        Dropdown.Name = Name
        Dropdown.Button = TextButton
        Dropdown.Frame = Frame

        function Dropdown:SetLabel(Text)
            TextButton.Text = typeof(Text) == "string" and Text or ""
            return Dropdown
        end

        function Dropdown:SetPosition(Position)
            TextButton.Position = ConvertVector(Position)
            return Dropdown
        end

        function Dropdown:SetSize(Size)
            TextButton.Size = ConvertVector(Size)
            return Dropdown
        end

        function Dropdown:SetRounded(Size)
            Rounded:SetSize(Size)
            return Dropdown
        end

        function Dropdown:AddItem(Text, Value)
            local Item = Instance.new("TextButton")
            local Rounded = CreateRounded(Item, Vector2.new())

            Item.Name = Name .. "Item"
            Item.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            Item.BorderSizePixel = 0
            Item.Size = UDim2.fromOffset(15, 15)
            Item.Position = UDim2.fromOffset(0, 15)
            Item.Text = typeof(Text) == "string" and Text or ""
            Item.Font = Enum.Font.SourceSans
            Item.TextColor3 = Color3.fromRGB(40, 115, 140)
            Item.TextSize = 14
            Item.AutoButtonColor = false
            Item.Parent = Frame
            Item.MouseButton1Click:Connect(function()
                TextButton.Text = Item.Text
                Dropdown.Visible = false
                if typeof(Callback) == "function" then
                    Callback(Value)
                end
            end)

            table.insert(Dropdown.Items, Item)
            return Dropdown
        end

        return Dropdown
    end
end



local function CreateListLayoutClass(self)
    function self.ListLayout(Name)
        local ListLayout = {}

        local _ListLayout = Instance.new("UIListLayout")
        _ListLayout.Name = Name
        _ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        _ListLayout.Parent = self.Frame

        ListLayout.Name = Name
        ListLayout.self = _ListLayout

        function ListLayout:SetPadding(Padding)
            _ListLayout.Padding = ConvertVector(Padding, "UDim")
            return ListLayout
        end

        function ListLayout:SetSpacing(Spacing)
            _ListLayout.Spacing = typeof(Spacing) == "number" and Spacing or 0
            return ListLayout
        end

        table.insert(self.Items, ListLayout)
        return ListLayout
    end
end


local function CreateGroupClass(self)
    function self.Group(Name, Size, Position)
        local Group = {}

        local Frame = Instance.new("Frame")
        local Rounded = CreateRounded(Frame, Vector2.new())

        Frame.Name = Name
        Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        Frame.BorderSizePixel = 0
        Frame.Size = ConvertVector(Size)
        Frame.Position = ConvertVector(Position)
        Frame.Parent = self.Frame

        Group.Name = Name
        Group.Frame = Frame
        Group.Items = {}

        function Group:SetBackground(Color, Transparency)
            local Color = typeof(Color) == "Color3" and Color
            local Transparency = typeof(Transparency) == "number" and Transparency

            if Color then
                Frame.BackgroundColor3 = Color
            end

            if Transparency then
                Frame.BackgroundTransparency = Transparency
            end

            return Group
        end

        function Group:SetPosition(Position)
            Frame.Position = ConvertVector(Position)
            return Group
        end

        function Group:SetSize(Size)
            Frame.Size = ConvertVector(Size)
            return Group
        end

        function Group:SetRounded(Size)
            Rounded:SetSize(Size)
            return Group
        end

        function Group:SetVisible(Visible)
            Frame.Visible = typeof(Visible) == "boolean" and Visible or false
            return Group
        end

        function Group:GetVisible()
            return Frame.Visible
        end


        CreateLineClass(Group)
        CreateLabelClass(Group)
        CreateButtonClass(Group)
        CreateTextBoxClass(Group)
        CreateCheckBoxClass(Group)
        CreateDropdownClass(Group)
        CreateListLayoutClass(Group)

        return Group
    end
end


local function CreateListClass(self)
    function self.List(Name, Size, Position)
        local List = {}

        local ScrollingFrame = Instance.new("ScrollingFrame")
        local Rounded = CreateRounded(ScrollingFrame, Vector2.new())

        ScrollingFrame.Name = Name
        ScrollingFrame.BackgroundTransparency = 1
        ScrollingFrame.BorderSizePixel = 0
        ScrollingFrame.Size = ConvertVector(Size)
        ScrollingFrame.Position = ConvertVector(Position)
        ScrollingFrame.CanvasSize = UDim2.new()
        ScrollingFrame.ScrollBarThickness = 0
        ScrollingFrame.Parent = self.Frame

        List.Name = Name
        List.Frame = ScrollingFrame
        List.Items = {}

        function List:SetBackground(Color, Transparency)
            local Color = typeof(Color) == "Color3" and Color
            local Transparency = typeof(Transparency) == "number" and Transparency

            if Color then
                ScrollingFrame.BackgroundColor3 = Color
            end

            if Transparency then
                ScrollingFrame.BackgroundTransparency = Transparency
            end

            return List
        end

        function List:SetPosition(Position)
            ScrollingFrame.Position = ConvertVector(Position)
            return List
        end

        function List:SetSize(Size)
            ScrollingFrame.Size = ConvertVector(Size)
            return List
        end

        function List:SetRounded(Size)
            Rounded:SetSize(Size)
            return List
        end

        function List:GetCanvasSize()
            return ScrollingFrame.CanvasSize
        end

        function List:SetCanvasSize(Size)
            ScrollingFrame.CanvasSize = ConvertVector(Size)
            return List
        end

        function List:SetVisible(Visible)
            ScrollingFrame.Visible = typeof(Visible) == "boolean" and Visible or false
            return List
        end

        function List:GetVisible()
            return ScrollingFrame.Visible
        end

        function List:Clear()
            List.Frame:ClearAllChildren()
            List.Items = {}
            return List
        end

        CreateLineClass(List)
        CreateLabelClass(List)
        CreateButtonClass(List)
        CreateTextBoxClass(List)
        CreateCheckBoxClass(List)
        CreateDropdownClass(List)
        CreateGroupClass(List)
        CreateListLayoutClass(List)

        return List
    end
end


function Menu:Kill()
    RenderSteppedLoop:Disconnect()
    Gui:Destroy()
    Menu = nil
end


function Menu:GetTextBounds(...)
    return GetTextBounds(...)
end


function Menu:CreateWindow(Name)
    local Window = {}

    local Frame = Instance.new("Frame")
    Frame.Name = Name
    Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Frame.BorderSizePixel = 1
    Frame.BorderColor3 = Color3.fromRGB(25, 25, 25)
    Frame.Size = UDim2.fromOffset(600, 300)
    Frame.Visible = false
    Frame.Parent = Gui

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.BorderSizePixel = 0
    TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    TopBar.Size = UDim2.new(1, 0, 0, 20)
    TopBar.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.Font = Enum.Font.SourceSans
    Title.Text = Name
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.Parent = TopBar

    local TabIndex = Instance.new("Frame")
    TabIndex.Name = "TabIndex"
    TabIndex.BorderSizePixel = 0
    TabIndex.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    TabIndex.Size = UDim2.new(1, 0, 0, 20)
    TabIndex.Position = UDim2.fromOffset(0, 20)
    TabIndex.Parent = Frame
    CreateLine(TabIndex, UDim2.new(1, 0, 0, 1), UDim2.new(), Color3.fromRGB(35, 35, 35))

    local TabIndexList = Instance.new("Frame")
    TabIndexList.Name = "List"
    TabIndexList.BackgroundTransparency = 1
    TabIndexList.Size = UDim2.new(1, 0, 1, 0)
    TabIndexList.Parent = TabIndex

    local TabIndexListLayout = Instance.new("UIListLayout")
    TabIndexListLayout.Name = "TabIndexListLayout"
    TabIndexListLayout.FillDirection = Enum.FillDirection.Horizontal
    TabIndexListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabIndexListLayout.Parent = TabIndexList

    local Tabs = Instance.new("Frame")
    Tabs.Name = "Tabs"
    Tabs.BorderSizePixel = 0
    Tabs.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    Tabs.Size = UDim2.new(1, 0, 1, -41)
    Tabs.Position = UDim2.fromOffset(0, 41)
    Tabs.Parent = Frame

    Window.Tabs = {}
    Window.Frame = Frame
    Window.Draggable = true
    Window.Resizable = true
    Window.MinSize = Vector2.new(100, 100)
    Window.MaxSize = Vector2.new(1000, 1000)

    local OnTabChanged = AddEvent(Window, "OnTabChanged")
    

    function Window:SetSize(Size)
        self.Frame.Size = ConvertVector(Size)
        return Window
    end

    function Window:SetPosition(Position)
        self.Frame.Position = ConvertVector(Position)
        return Window
    end

    function Window:SetVisible(Visible)
        Frame.Visible = typeof(Visible) == "boolean" and Visible or false
        return Window
    end

    function Window:SetTitle(Text)
        Title.Text = typeof(Text) == "string" and Text or ""
        return Window
    end

    local TopLine = CreateLine(nil, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 1), Color3.fromRGB(40, 115, 140))
    local LeftLine = CreateLine(nil, UDim2.new(0, 1, 1, 0), UDim2.new(), Color3.fromRGB(35, 35, 35))
    local RightLine = CreateLine(nil, UDim2.new(0, 1, 1, 0), UDim2.new(1, -1, 0, 0), Color3.fromRGB(35, 35, 35))
    local BottomLeftLine = CreateLine(TabIndex, UDim2.new(), UDim2.new(0, 0, 1, -1), Color3.fromRGB(35, 35, 35))
    local BottomRightLine = CreateLine(TabIndex, UDim2.new(), UDim2.new(), Color3.fromRGB(35, 35, 35))

    local function ChangeTab(Tab)
        for k, Tab in pairs(Window.Tabs) do
            Tab.Frame.Visible = false
            Tab.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            Tab.Button.TextColor3 = Color3.fromRGB(205, 205, 205)
        end

        Tab.Frame.Visible = true
        Tab.Button.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        Tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)

        if Tab.Button.AbsolutePosition.X > Tab.Frame.AbsoluteSize.X then
            LeftLine:SetProperty("Visible", true)
        else
            LeftLine:SetProperty("Visible", false)
        end

        if Tab.Button.AbsolutePosition.X + Tab.Button.AbsoluteSize.X < Tab.Frame.AbsoluteSize.X then
            RightLine:SetProperty("Visible", true)
        else
            RightLine:SetProperty("Visible", false)
        end

        TopLine:SetProperty("Parent", Tab.Button)
        LeftLine:SetProperty("Parent", Tab.Button)
        RightLine:SetProperty("Parent", Tab.Button)

        local FRAME_POSITION = Tab.Frame.AbsolutePosition
        local BUTTON_POSITION = Tab.Button.AbsolutePosition
        local BUTTON_SIZE = Tab.Button.AbsoluteSize
        local LENGTH = BUTTON_POSITION.X - FRAME_POSITION.X
        local OFFSET = (BUTTON_POSITION.X + BUTTON_SIZE.X) - FRAME_POSITION.X

        BottomLeftLine:SetProperty("Size", UDim2.new(0, LENGTH, 0, 1))
        BottomRightLine:SetProperty("Size", UDim2.new(1, -OFFSET, 0, 1))
        BottomRightLine:SetProperty("Position", UDim2.new(0, OFFSET, 1, -1))

        OnTabChanged:Fire(Tab.Name)
    end


    function Window:SetTab(Name)
        for k, Tab in pairs(Window.Tabs) do
            if Tab.Name == Name then
                ChangeTab(Tab)
                break
            end
        end
        return Window
    end

    function Window.Tab(Name)
        local Tab = {}

        local Frame = Instance.new("Frame")
        local Button = Instance.new("TextButton")

        Frame.Name = Name .. "Tab"
        Frame.BorderSizePixel = 0
        Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        Frame.Size = UDim2.new(1, 0, 1, 0)
        Frame.Parent = Tabs

        Button.Name = Name .. "Button"
        Button.BorderSizePixel = 0
        Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        Button.Size = UDim2.new(0, GetTextBounds(string.upper(Name), 14, Enum.Font.SourceSans).X + 20, 1, 0)
        Button.Font = Enum.Font.SourceSans
        Button.Text = string.upper(Name)
        Button.TextColor3 = Color3.fromRGB(205, 205, 205)
        Button.TextSize = 14
        Button.TextStrokeTransparency = 0.75
        Button.Parent = TabIndexList
        Button.MouseButton1Click:Connect(function()
            ChangeTab(Tab)
        end)

        Tab.Containers = {}
        Tab.Name = Name
        Tab.Frame = Frame
        Tab.Button = Button

        function Tab.Container(Name, Size, Position)
            local Container = {}
            local Frame = Instance.new("Frame")
            Frame.Name = Name
            Frame.BorderSizePixel = 0
            Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            Frame.Size = ConvertVector(Size)
            Frame.Position = ConvertVector(Position)
            Frame.Parent = Tab.Frame

            Container.Items = {}
            Container.Name = Name
            Container.Frame = Frame

            local Lines = {}
            --Lines.Top = CreateLine(Frame, UDim2.new(1, 0, 0, 1), UDim2.new(), Color3.fromRGB(35, 35, 35)) Don't need one because we already have one from the topbar
            Lines.Left = CreateLine(Frame, UDim2.new(0, 1, 1, 0), UDim2.new(), Color3.fromRGB(35, 35, 35))
            Lines.Right = CreateLine(Frame, UDim2.new(0, 1, 1, 0), UDim2.new(1, -1, 0, 0), Color3.fromRGB(35, 35, 35))
            Lines.Bottom = CreateLine(Frame, UDim2.new(), UDim2.new(0, 0, 1, -1), Color3.fromRGB(35, 35, 35))
        
            CreateLineClass(Container)
            CreateLabelClass(Container)
            CreateButtonClass(Container)
            CreateTextBoxClass(Container)
            CreateCheckBoxClass(Container)
            CreateDropdownClass(Container)
            CreateGroupClass(Container)
            CreateListClass(Container)
            CreateListLayoutClass(Container)

            return Container
        end
        
        Window.Tabs[Name] = Tab
        ChangeTab(Tab)

        return Tab
    end


    SetDraggable(Window, Frame)

    Windows[Name] = Window
    return Window
end


RenderSteppedLoop = RunService.RenderStepped:Connect(function()
    Menu.ScreenSize = Vector2.new(Camera.ViewportSize.X, Camera.ViewportSize.Y)

    do
        if UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            local MouseLocation = UserInput:GetMouseLocation()

            for _, Window in pairs(Windows) do
                local Frame = Window.Frame
                local FramePosition = Frame.AbsolutePosition
                local FrameSize = Frame.AbsoluteSize

                if (FramePosition.X - MouseLocation.X) > 3 and (FramePosition.X - MouseLocation.X) < -1 then

                end
            end
        end
    end
end)


return Menu
