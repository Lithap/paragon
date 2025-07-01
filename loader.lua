
if not game:IsLoaded() then game.Loaded:Wait() end

------------------------------------------------------------------------
-- 🔧 CONFIG HANDLING ---------------------------------------------------
------------------------------------------------------------------------
local ConfigManager = loadfile("Paragon/utils/configmanager.lua")
local DefaultConfig = loadfile("Paragon/config.lua")()
local Config        = ConfigManager.Load(DefaultConfig)
ConfigManager.BindAutoSave(Config)

------------------------------------------------------------------------
-- 🔐 KEY SYSTEM -------------------------------------------------------
------------------------------------------------------------------------
local KeySystem = loadfile("Paragon/ui/keysystem.lua")()
KeySystem:Init(function()  -- called once key is valid

    --------------------------------------------------------------------
    -- 🖥️  DEMO MENU ----------------------------------------------------
    --------------------------------------------------------------------
    local Menu = loadfile("Paragon/ui/menu.lua")(Config)

    -- build a minimal tab so something appears immediately
    local Demo = Menu:Tab("Demo")
    Demo:Toggle("Example Toggle","ESP.Example")
    Demo:Slider("Example Slider","ESP.ExampleValue",0,100)
    Demo:Keybind("Example Key","ESP.ExampleKey")

    Menu:Init()  -- not strictly required yet but reserved for future

    print("[Paragon] loader finished – UI should now be visible")
end)
