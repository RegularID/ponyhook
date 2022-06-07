-- maybe save logs inside the remotes[self] table

local Listener = {}
local Remotes = {}
local Callbacks = {}
local Scheduled = {}
local Scheduled2 = {} -- im lazy
local ConnectionHooks = {}
local Listening = true

local SchedulerUpdater


local request = request or http and http.request or syn and syn.request
local is_lua_closure = islclosure or function(f)
    if typeof(f) ~= "function" then return false end
    return debug.getinfo(f).what == "Lua"
end
local get_callback_value = getcallbackmember or getcallbackvalue or get_callback_value or get_callback_member or function() end
local lower_first_letter = function(String)
    return string.sub(String, 1, 1):lower() .. string.sub(String, 2)
end

local Hooks = Import("Hooks")

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")


local function CheckSignalConnection(self)
    if self.IsA(self, "RemoteEvent") then
        if #getconnections(self.OnClientEvent) > 0 then
            return true
        end
    elseif self.IsA(self, "BindableEvent") then
        if #getconnections(self.Event) > 0 then
            return true
        end
    else
        error("???")
    end
end


local function Create(self, Caller, Method, Arguments)
    if not Settings.Index[Method] then return end
    if Settings.Ignore then return end
    if Settings.CallerCheck and Caller == nil then return end

    if not Remotes[self] then
        Remotes[self] = {
            self = self,
            Calls = 0,
            Logs = {}
        }
    end

    local Remote = Remotes[self]
    local Log = {
        self = self,
        Caller = Caller,
        Method = Method,
        Arguments = Arguments,
        Time = os.date("%X"),
    }

    Remote.Calls += 1
    table.insert(Remote.Logs, Log)
    table.insert(Scheduled, Remote)
end


function Listener:Kill()
    Listening = false
    SchedulerUpdater:Disconnect()
    for _, Connection in ipairs(ConnectionHooks) do
        Connection:Disconnect()
    end
end


function Listener:Get()
    return Remotes
end


function Listener:Add(Name, Callback)
    table.insert(Callbacks, {
        Name = Name,
        Callback = Callback
    })
end


local function UpdateScheduler()
    for i, Remote in ipairs(Scheduled) do
        for _, v in ipairs(Callbacks) do
            v.Callback(Remote)
        end
        table.remove(Scheduled, i)
    end

    for i, Remote in ipairs(Scheduled2) do
        local self = Remote
        spawn(function()
            if self:IsA("RemoteEvent") then
                if CheckSignalConnection(self) then
                    local Connection
                    Connection = self.OnClientEvent:Connect(function(...)
                        Create(self, nil, "OnClientEvent", {...})
                    end)
                end
            elseif self:IsA("RemoteFunction") then
                local Callback = get_callback_value(self, "OnClientInvoke")
                if Callback then
                    
                end
            elseif self:IsA("BindableEvent") then
                if CheckSignalConnection(self) then
                    local Connection
                    Connection = self.Event:Connect(function(...)
                        Create(self, nil, "OnEvent", {...})
                    end)
                end
            elseif self:IsA("BindableFunction") then
                local Callback = get_callback_value(self, "OnInvoke")
                if Callback then
                    
                end
            end
        end)

        table.remove(Scheduled2, i)
    end
end


local function OnRequest(...)
    Create(...)
end


local function OnConnect(self)
    table.insert(Scheduled2, self)
end


local function OnFire(self, Caller, Arguments)
    spawn(function()
        if self:IsA("RemoteEvent") then
            Create(self, Caller, "FireServer", Arguments)
        elseif self:IsA("RemoteFunction") then
            Create(self, Caller, "InvokeServer", Arguments)
        elseif self:IsA("BindableEvent") then
            Create(self, Caller, "Fire", Arguments)
        elseif self:IsA("BindableFunction") then
            Create(self, Caller, "Invoke", Arguments)
        end
    end)
end


local Index
local NewIndex
local NameCall


Index = hookmetamethod(game, "__index", function(self, Key)
    if  Listening and not checkcaller() then -- Yes am lazy
        if lower_first_letter(Key) == "onClientEvent" or lower_first_letter(Key) == "event" then
            OnConnect(self)
        end
    end

    return Index(self, Key)
end)


NewIndex = hookmetamethod(game, "__newindex", function(self, Key, Value)
    local ClassName = self.ClassName

    if Listening then
        if ClassName == "RemoteFunction" then
            if lower_first_letter(Key) == "onClientInvoke" then
                OnConnect(self)
            end
        elseif ClassName == "BindableFunction" then
            if lower_first_letter(Key) == "onInvoke" then
                OnConnect(self)
            end
        end
    end

    return NewIndex(self, Key, Value)
end)


NameCall = hookmetamethod(game, "__namecall", function(self, ...)
    local Arguments = {...}

    if Listening then
        local Method = getnamecallmethod()
        local METHOD = lower_first_letter(Method) -- for cmp checks
        local hooks = Hooks:Get()
        local Ignore = false

        local ClassName = self.ClassName

        local Hook = hooks[ClassName]
        if Hook then
            local Remote = Hook:GetRemote()
            local Settings = Hook:GetSettings()

            if Remote then
                if self == Remote then
                    for _, Setting in ipairs(Settings) do
                        local Status = Setting.Status
                        local DataType = Setting.DataType
                        local Type = Setting.Type -- Value or Custom Set DataType
                        local Index = Setting.Index
                        local Value = Setting.Value

                        for i, Argument in ipairs(Arguments) do
                            if i ~= Index then continue end
                            if typeof(Argument) == DataType then
                                if Type == "Type" then
                                    if Status == "Block" then return end
                                    if Status == "Ignore" then Ignore = true end
                                end
                                
                                if Type == "Value" then
                                    if Argument == Value then
                                        if Status == "Block" then return end
                                        if Status == "Ignore" then Ignore = true end
                                    end
                                end
                            end
                        end
                    end
                end
            else
                -- Global Conditions for ClassName remotes

            end
        end

        local Hook = hooks.HTTP
        if Hook then

        end

        if self == game then
            if METHOD == "httpGetAsync" or METHOD == "httpPostAsync" or METHOD == "httpGet" or METHOD == "httpPost" then
                OnRequest(self, getcallingscript(), Method, Arguments)
            end
        end

        if self == HttpService then
            if METHOD == "getAsync" or METHOD == "postAsync" or METHOD == "requestAsync" then
                OnRequest(self, getcallingscript(), Method, Arguments)
            end
        end

        if not Ignore then
            if ClassName == "BindableEvent" then
                if METHOD == "fire" then
                    OnFire(self, getcallingscript(), Arguments)
                end
            end

            if ClassName == "BindableFunction" then
                if METHOD == "invoke" then
                    OnFire(self, getcallingscript(), Arguments)
                end
            end

            if ClassName == "RemoteEvent" then
                if METHOD == "fireServer" then
                    OnFire(self, getcallingscript(), Arguments)
                end
            end

            if ClassName == "RemoteFunction" then
                if METHOD == "invokeServer" then
                    OnFire(self, getcallingscript(), Arguments)
                end
            end
        end
    end

    return NameCall(self, unpack(Arguments))
end)


if not is_lua_closure(request) and not is_lua_closure(hookfunction) then
    local old_request
    old_request = hookfunction(request, function(Request, ...)
        if Listening then
            if typeof(Request) == "table" then
                OnRequest(Request, getcallingscript(), rawget(Request, "Method") or "GET", {...})
            end
        end

        return old_request(Request, ...)
    end)
end


do
    local Objects = {}
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("BindableEvent") or v:IsA("BindableFunction") then
            table.insert(Objects, v)
        end
    end
    for _, v in ipairs(getnilinstances()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("BindableEvent") or v:IsA("BindableFunction") then
            table.insert(Objects, v)
        end
    end

    for _, Object in ipairs(Objects) do
        OnConnect(Object)
    end
end

SchedulerUpdater = RunService.Heartbeat:Connect(UpdateScheduler)


return Listener
