local function SetGlobal(Key, self)
    getfenv()[Key] = self
end


local function import(Path:string)
    local Directory = "PonyHook/Games/Mad Games/"
    local File = Directory .. Path .. ".lua"

    if isfile(File) then
        local Source = loadstring(readfile(File))
        local Success, Result = pcall(Source)

        if not Success then
            warn(Result)
            return
        end

        return SetGlobal(Path, Result)
    end

    warn("File not found: " .. File)
end


getgenv().import = import