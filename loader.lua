-- Paragon/loader.lua  •  one-file cloud bootstrap
-- ─────────────────────────────────────────────────────────
-- ① waits for game load
-- ② RemoteRequire() pulls sub-modules from GitHub raw CDN & caches them
-- ③ loads + autosaves config
-- ④ runs key system (fancy prompt)
-- ⑤ shows demo tab so you see the menu pop up

------------------------------------------------------------------
-- 🕒 wait for game
------------------------------------------------------------------
if not game:IsLoaded() then game.Loaded:Wait() end

------------------------------------------------------------------
-- 🌐 RemoteRequire  (GitHub fetch + in-memory cache)
------------------------------------------------------------------
local BASE   = "https://raw.githubusercontent.com/Lithap/paragon/main/"
local cache  = {}

local function RemoteRequire(path)
    if cache[path] then return cache[path] end
    local src = game:HttpGet(BASE .. path, true)
    local chunk = loadstring(src, "@"..path)
    local result = chunk()
    cache[path] = result
    return result
end

------------------------------------------------------------------
-- ⚙  Config (load + autosave)
------------------------------------------------------------------
local ConfigManager = RemoteRequire("utils/configmanager.lua")
local DefaultConfig = RemoteRequire("config.lua")
local Config        = ConfigManager.Load(DefaultConfig)
ConfigManager.BindAutoSave(Config)

------------------------------------------------------------------
-- 🔐 Key system  (fancy prompt included)
------------------------------------------------------------------
local KeySystem = RemoteRequire("ui/keysystem.lua")()
KeySystem:Init(function()

    --------------------------------------------------------------
    -- 🖥️  Demo menu so you can see something instantly
    --------------------------------------------------------------
    local MenuFactory = RemoteRequire("ui/menu.lua")
    local Menu = MenuFactory(Config)

    local Demo = Menu:Tab("Demo")
    Demo:Toggle ("Example Toggle", "ESP.Example")
    Demo:Slider ("Example Slider", "ESP.ExampleValue", 0, 100)
    Demo:Keybind("Example Key",    "ESP.ExampleKey")

    Menu:Init()
    print("[Paragon] fully loaded — key prompt + menu should be visible")
end)
