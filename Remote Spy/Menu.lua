--[[
    * Was  a little HIGH on crack and you know some brain damage, while writing this code
]]

local Menu = {}
local _Menu = import "Libraries/Menu"
local Compiler = import "Compiler"
local Settings = import "Settings"
local Highlighter = import "Syntaxer/Source"


local get_table_length = function(Table)
    local Length = 0
    for _ in pairs(Table) do
        Length = Length + 1
    end
    return Length
end


local Main = _Menu:CreateWindow("Remote Spy - v1.0.0")
local RemoteInfo = _Menu:CreateWindow("Remote Info"):SetSize(Vector2.new(250, 350))

local EditorTab = Main.Tab("Editor")
local IndexTab = Main.Tab("Index")
local HooksTab = Main.Tab("Hooks")
local ScriptsTab = Main.Tab("Scripts")
local SettingsTab = Main.Tab("Settings")

local IndexMain = IndexTab.Container("Main", UDim2.new(0.8, 0, 1, 0), UDim2.new())
local IndexList = IndexMain.List("List", UDim2.new(1, 0, 1, -30), UDim2.new(0, 0, 0, 30))
IndexList.ListLayout("List")
local IndexFilter = IndexTab.Container("Filter", UDim2.new(0.2, 0, 1, 0), UDim2.new(0.8, 0, 0, 0))
local IndexFilterList = IndexFilter.List("List", UDim2.new(1, -10, 1, -20), UDim2.new(0, 5, 0, 15))

local HooksMain = HooksTab.Container("Hooks", UDim2.new(1, 0, 1, 0), UDim2.new())
local SettingsMain = SettingsTab.Container("Settings", UDim2.new(1, 0, 1, 0), UDim2.new())
local SettingsList = SettingsMain.List("List", UDim2.new(0.7, 0, 1, 0), UDim2.new(0, 0.3, 0, 0))
local SettingsIndex = SettingsMain.List("Index", UDim2.new(0.3, 0, 1, 0), UDim2.new())

local InfoTab = RemoteInfo.Tab("Info")
local CallsTab = RemoteInfo.Tab("Calls")

local InfoMain = InfoTab.Container("Main", UDim2.new(1, 0, 1, 0), UDim2.new())
local CallsMain = CallsTab.Container("Main", UDim2.new(1, 0, 1, 0), UDim2.new())
local CallsList = CallsMain.List("List", UDim2.new(1, 0, 1, 0), UDim2.new())


function Menu:Kill()
    _Menu:Kill()
end


function Menu:GetTextBounds(...)
    return _Menu:GetTextBounds(...)
end


local RemoteGroups = {}
local SelectedRemote


local ScriptEditor = EditorTab.Container("Editor", UDim2.new(1, 0, 1, -25), UDim2.new())
local EditorButtons = EditorTab.Container("Buttons", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 1, -20))

ScriptEditor = ScriptEditor.List("Editor", UDim2.new(1, 0, 1, 0), UDim2.new()):SetBackground(Color3.fromRGB(35, 35, 35))
local ScriptEditorText = ScriptEditor.Label("Text", UDim2.new(1, -10, 1, 0), UDim2.new(0, 5, 0, 0), "Left"):SetText("", nil, nil, nil, "Left", "Top"):SetBackground(nil, 1)
local CopyScriptEditorText = EditorButtons.Button("Copy", UDim2.new(0, 120, 1, 0), UDim2.new(), "Center", function()
    setclipboard(ScriptEditorText:GetText())
end):SetBackground(Color3.fromRGB(35, 35, 35)):SetLabel("Copy")
local ClearScriptEditorText = EditorButtons.Button("Clear", UDim2.new(0, 120, 1, 0), UDim2.new(0, 125, 0, 0), "Center", function()
    Highlighter:Highlight(ScriptEditorText.self, "")
end):SetBackground(Color3.fromRGB(35, 35, 35)):SetLabel("Clear")
Highlighter:Highlight(ScriptEditorText.self, "print(\"Hello World!\")")


IndexMain.Label("Explorer", UDim2.new(1, 0, 0, 15), UDim2.new()):SetLabel("Explorer"):SetBackground(Color3.fromRGB(55, 55, 55)):SetBorder(nil, 0)
IndexMain.Line(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 15), Color3.fromRGB(35, 35, 35))

local IndexSearchBox = IndexMain.TextBox("Search", UDim2.new(1, 0, 0, 15), UDim2.new(0, 0, 0, 15), "", "Search", function(Text)
    for _, Group in pairs(RemoteGroups) do
        if not Group:GetVisible() then
            IndexList:SetCanvasSize(IndexList:GetCanvasSize() + UDim2.fromOffset(0, 15))
        end
        Group:SetVisible(true)

        if Text ~= "" then
            local Name = string.lower(Group.Name)
            if not string.find(Name, string.lower(Text)) then
                Group:SetVisible(false)
                IndexList:SetCanvasSize(IndexList:GetCanvasSize() - UDim2.fromOffset(0, 15))
            end
        end
    end
end)
IndexMain.Line(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 30), Color3.fromRGB(35, 35, 35))


local function AddFilterToIndex(Name, Value, Callback)
    local Group = IndexFilterList.Group(Name, UDim2.new(1, 0, 0, 15), UDim2.new()):SetBackground(nil, 1)
    Group.Label(Name, UDim2.new(1, 0, 1, 0), UDim2.new(), "Left"):SetLabel(Name):SetBackground(nil, 1)
    Group.CheckBox(Name, UDim2.new(1, 0, 1, 0), UDim2.new(1, -15, 0, 0), "", Value, Callback)
    Group.Line(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 1, 0), Color3.fromRGB(35, 35, 35))
end

IndexFilter.Label("Filter", UDim2.new(1, 0, 0, 15), UDim2.new()):SetLabel("Filter"):SetBackground(Color3.fromRGB(55, 55, 55)):SetBorder(nil, 0)
IndexFilter.Line(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 15), Color3.fromRGB(35, 35, 35))
IndexFilterList.ListLayout("List"):SetPadding(Vector2.new(0, 2))

AddFilterToIndex("Fire Server", Settings.Index.FireServer, function(Value)
    Settings.Index.FireServer = Value
    Settings:Save()
end)

AddFilterToIndex("On Client Event", Settings.Index.OnClientEvent, function(Value)
    Settings.Index.OnClientEvent = Value
    Settings:Save()
end)

AddFilterToIndex("Invoke Server", Settings.Index.InvokeServer, function(Value)
    Settings.Index.InvokeServer = Value
    Settings:Save()
end)

AddFilterToIndex("On Client Invoke", Settings.Index.OnClientInvoke, function(Value)
    Settings.Index.OnClientInvoke = Value
    Settings:Save()
end)

AddFilterToIndex("Fire", Settings.Index.Fire, function(Value)
    Settings.Index.Fire = Value
    Settings:Save()
end)

AddFilterToIndex("On Event", Settings.Index.OnEvent, function(Value)
    Settings.Index.OnEvent = Value
    Settings:Save()
end)

AddFilterToIndex("Invoke", Settings.Index.Invoke, function(Value)
    Settings.Index.Invoke = Value
    Settings:Save()
end)

AddFilterToIndex("On Invoke", Settings.Index.OnInvoke, function(Value)
    Settings.Index.OnInvoke = Value
    Settings:Save()
end)

AddFilterToIndex("HTTP", Settings.Index.HTTP, function(Value)
    Settings.Index.HTTP = Value
    Settings:Save()
end)

AddFilterToIndex("Caller Check", Settings.CallerCheck, function(Value)
    Settings.CallerCheck = Value
    Settings:Save()
end)

AddFilterToIndex("Thread Check", Settings.ThreadCheck, function(Value)
    Settings.ThreadCheck = Value
    Settings:Save()
end)


local RemoteInfoName = InfoMain.Label("Name", UDim2.new(1, 0, 0, 15), UDim2.new(), "Left"):SetLabel("Name: null")
InfoMain.Line(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 15), Color3.fromRGB(35, 35, 35))

local RemoteInfoClassName = InfoMain.Label("Class Name", UDim2.new(1, 0, 0, 15), UDim2.new(0, 0, 0, 15), "Left"):SetLabel("Class Name: null")
InfoMain.Line(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 30), Color3.fromRGB(35, 35, 35))

local RemoteInfoCalls = InfoMain.Label("Calls", UDim2.new(1, 0, 0, 15), UDim2.new(0, 0, 0, 30), "Left"):SetLabel("Calls: 0")
InfoMain.Line(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 45), Color3.fromRGB(35, 35, 35))

local RemoteInfoCopyPath = InfoMain.Button("Copy Path", UDim2.new(1, -40, 0, 25), UDim2.new(0, 20, 0, 50), "Center", function()
    if SelectedRemote then
        setclipboard(Compiler:GetPath(SelectedRemote.self))
    end
end):SetLabel("Copy Path"):SetRounded(Vector2.new(0, 3)):SetBackground(Color3.fromRGB(60, 60, 60))

local RemoteInfoClearCalls = InfoMain.Button("Clear Calls", UDim2.new(1, -40, 0, 25), UDim2.new(0, 20, 0, 80), "Center", function()
    if SelectedRemote then
        table.clear(SelectedRemote.Logs)
        SelectedRemote.Calls = 0
        local Group = RemoteGroups[SelectedRemote]
        if Group then
            Group:Update(SelectedRemote)
        end
    end
end):SetLabel("Clear Calls"):SetRounded(Vector2.new(0, 3)):SetBackground(Color3.fromRGB(60, 60, 60))

local RemoteInfoExportCalls = InfoMain.Button("Export Calls", UDim2.new(1, -40, 0, 25), UDim2.new(0, 20, 0, 110), "Center", function()
    if SelectedRemote then
        local Name = Compiler:ToString(tostring(SelectedRemote.self))
        local Directory = Settings.Directory .. "/Logs/"
        if not isfolder(Directory) then makefolder(Directory) end
        local FileName = Directory .. "log-" .. os.time() .. ".txt"
        writefile(FileName, "")
        
        for _, Log in ipairs(SelectedRemote.Logs) do
            local Time = Log.Time
            local Method = Log.Method
            local Arguments = Log.Arguments

            local Text = "Time: " .. Time .. "\n" ..
            "Name: " .. Name .. "\n" ..
            "Method: " .. Method .. "\n" ..
            "Arguments: " .. Compiler:ToString(Arguments) ..
            "\n------------------------------------------------------\n"

            appendfile(FileName, Text)
        end
    end
end):SetLabel("Export Calls"):SetRounded(Vector2.new(0, 3)):SetBackground(Color3.fromRGB(60, 60, 60))


local function AddCallLog(Log)
    local Remote = Log.self

    local Time = Log.Time
    local Caller = tostring(Log.Caller)
    local Method = Log.Method
    local Arguments = Log.Arguments

    local ArgumentsLength = (get_table_length(Arguments) * 15)
    local GroupHeight = (15 * 3) + 25

    local Group = CallsList.Group("Log", UDim2.new(1, 0, 0, GroupHeight), UDim2.new()):SetBackground(Color3.fromRGB(45, 45, 45))
    Group.Label("Time", UDim2.new(1, 0, 0, 15), UDim2.new(), "Left"):SetLabel("Time: " .. Time)
    Group.Label("Caller", UDim2.new(1, 0, 0, 15), UDim2.new(0, 0, 0, 15), "Left"):SetLabel("Caller: " .. Caller)
    Group.Label("Method", UDim2.new(1, 0, 0, 15), UDim2.new(0, 0, 0, 30), "Left"):SetLabel("Method: " .. Method)
    Group.Button("Compile", UDim2.new(1, -40, 0, 25), UDim2.new(0, 20, 0, 50), "Center", function()
        local Code = Compiler:Compile(Remote, Method, Arguments)
        Highlighter:Highlight(ScriptEditorText.self, "")
        Highlighter:Highlight(ScriptEditorText.self, Code)
        ScriptEditor:SetCanvasSize(Vector2.new(ScriptEditorText.self.TextBounds.X + 5, ScriptEditorText.self.TextBounds.Y + 5))
        Main:SetTab("Editor")
    end):SetLabel("Compile"):SetRounded(Vector2.new(0, 3)):SetBackground(Color3.fromRGB(60, 60, 60))


    CallsList:SetCanvasSize(UDim2.new(0, 0, 0, GroupHeight + 2) + CallsList:GetCanvasSize())
end


local IsCallsTabSelected = false
RemoteInfo.OnTabChanged:Connect(function(Tab)
    CallsList:Clear()
    CallsList.ListLayout("List"):SetPadding(Vector2.new(0, 2))
    CallsList:SetCanvasSize(UDim2.new())

    if Tab == "Calls" then
        IsCallsTabSelected = true
        local Count = 0
        for _, Log in ipairs(SelectedRemote.Logs) do
            if not IsCallsTabSelected then break end

            AddCallLog(Log)
            Count = Count + 1
            if Count > 8 then
                wait()
                Count = 0
            end
        end
    end
end)


function Menu:AddRemote(Remote)
    local self = Remote.self
    local Name = Compiler:ToString(tostring(self))
    local ClassName = self.ClassName
    local Calls = tostring(Remote.Calls)

    local Offset = 2

    IndexList:SetCanvasSize(IndexList:GetCanvasSize() + UDim2.fromOffset(0, 15))
    local Group = IndexList.Group(Name, UDim2.new(1, 0, 0, 15), UDim2.new()):SetBackground(Color3.fromRGB(45, 45, 45))
    local BottomLine = Group.Line(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 1, -1), Color3.fromRGB(35, 35, 35))
    RemoteGroups[Remote] = Group

    local SearchBoxText = string.lower(IndexSearchBox:GetText())
    if SearchBoxText ~= "" then
        local Name = string.lower(Name)
        if not string.find(Name, SearchBoxText) then
            Group:SetVisible(false)
            IndexList:SetCanvasSize(IndexList:GetCanvasSize() + UDim2.fromOffset(0, -15))
        end
    end

    local function Callback()
        local self = Remote.self
        local Name = Compiler:ToString(tostring(self))
        local ClassName = self.ClassName
        local Calls = tostring(Remote.Calls)
        
        SelectedRemote = Remote
        RemoteInfo:SetTab("Info")
        RemoteInfo:SetVisible(true)
        RemoteInfo:SetTitle("Remote Info [" .. Name .. "]")
        RemoteInfoName:SetLabel("Name: " .. Name)
        RemoteInfoClassName:SetLabel("Class Name: " .. ClassName)
        RemoteInfoCalls:SetLabel("Calls: " .. Calls)
    end

    local NameLength = Menu:GetTextBounds("Name: " .. Name, 14, Enum.Font.SourceSans).X
    local ClassNameLength = Menu:GetTextBounds("ClassName: " .. ClassName, 14, Enum.Font.SourceSans).X + NameLength
    local CallsLength = Menu:GetTextBounds("Calls: " .. Calls, 14, Enum.Font.SourceSans).X + ClassNameLength

    local NameButton = Group.Button("Name", UDim2.new(0, NameLength, 1, 0), UDim2.new(), "Left", Callback):SetLabel("Name: " .. Name)

    local ClassNameButton = Group.Button("ClassName", UDim2.new(0, ClassNameLength, 1, 0), UDim2.new(0, NameLength + (Offset * 2), 0, 0), "Left", Callback):SetLabel("ClassName: " .. ClassName)
    local ClassNameLine = Group.Line(UDim2.new(0, 1, 1, -1), UDim2.new(0, NameLength + Offset, 0, 0), Color3.fromRGB(35, 35, 35))

    local CallsButton = Group.Button("Calls", UDim2.new(0, CallsLength, 1, 0), UDim2.new(0, ClassNameLength + (Offset * 4), 0, 0), "Left", Callback):SetLabel("Calls: " .. Calls)
    local CallsLine = Group.Line(UDim2.new(0, 1, 1, -1), UDim2.new(0, ClassNameLength + (Offset * 3), 0, 0), Color3.fromRGB(35, 35, 35))

    function Group:Update(Remote, Log)
        local self = Remote.self
        local Name = Compiler:ToString(tostring(self))
        local ClassName = self.ClassName
        local Calls = tostring(Remote.Calls)

        if SelectedRemote == Remote then
            RemoteInfoName:SetLabel("Name: " .. Name)
            RemoteInfoClassName:SetLabel("Class Name: " .. ClassName)
            RemoteInfoCalls:SetLabel("Calls: " .. Calls)

            if typeof(Log) == "table" then
                AddCallLog(Log)
            end
        end

        local NameLength = Menu:GetTextBounds("Name: " .. Name, 14, Enum.Font.SourceSans).X
        local ClassNameLength = Menu:GetTextBounds("ClassName: " .. ClassName, 14, Enum.Font.SourceSans).X + NameLength
        local CallsLength = Menu:GetTextBounds("Calls: " .. Calls, 14, Enum.Font.SourceSans).X + ClassNameLength

        NameButton:SetLabel("Name: " .. Name):SetSize(UDim2.new(0, NameLength, 1, 0))

        ClassNameButton:SetLabel("ClassName: " .. ClassName):SetSize(UDim2.new(0, ClassNameLength, 1, 0)):SetPosition(UDim2.new(0, NameLength + (Offset * 2), 0, 0))
        ClassNameLine:SetProperty("Position", UDim2.new(0, NameLength + Offset, 1, 0))

        CallsButton:SetLabel("Calls: " .. Calls):SetSize(UDim2.new(0, CallsLength, 1, 0)):SetPosition(UDim2.new(0, ClassNameLength + (Offset * 4), 0, 0))
        CallsLine:SetProperty("Position", UDim2.new(0, ClassNameLength + (Offset * 3), 1, 0))
    end

    function Group:Remove()
        Group.Frame:Destroy()
        RemoteGroups[self] = nil
        IndexList:SetCanvasSize(IndexList:GetCanvasSize() + UDim2.fromOffset(0, -15))
    end

    function Group:SetVisible(Visible)
        local Visible = typeof(Visible) == "boolean" and Visible or false
        Group:SetVisible(Visible)
        IndexList:SetCanvasSize(IndexList:GetCanvasSize() + UDim2.fromOffset(0, Visible and 15 or -15))
    end


    return Group
end


Main:SetVisible(true)
Main:SetTab("Editor")
RemoteInfo:SetVisible(false)


return Menu
