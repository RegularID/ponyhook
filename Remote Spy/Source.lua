--[[
    * Fix the script,
    * Syntax Highlighter sometimes breaks (not my problem),
    * Rework the UI
]]


if _G.PonySpy and _G.PonySpy.Kill then
    _G.PonySpy.Kill()
end


local Settings = import "Settings"
Settings:Load()

local Menu = import "Menu"
local Index = import "Index"

_G.PonySpy = {}
function _G.PonySpy.Kill()
    _G.PonySpy = nil
    Menu.Kill()
    Index.Kill()
end
