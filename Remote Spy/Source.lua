--[[
    * Syntax Highlighter sometimes breaks (not my problem),
    * Minimize UI,
    * Close UI,
    * Stop Logging Button,
    * Calls View,
    * Index Explorer Fix,
    * Index Explorer Clear,
    * UI Drag Fix (y position bottom offset),
    * UI Scaler,
    * Scripts Tab,
    * Settings Tab,
    * Hooks Tab
]]


if _G.PonySpy and _G.PonySpy.Kill then
    _G.PonySpy.Kill()
end


Settings = import("Settings")
Settings:Load()

Menu = import("Menu")
Index = import("Index")

_G.PonySpy = {}
function _G.PonySpy.Kill()
    _G.PonySpy = nil
    Menu.Kill()
    Index.Kill()
end
