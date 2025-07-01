-- utils/configmanager.lua
-- Paragon Config Manager  (auto save / load)
--   • Persists the user's settings (booleans, numbers, keycodes) between sessions
--   • Uses syn.store / syn.get if available, otherwise JSON file in writefile/readfile
--   • Throttles writes to disk (1 save per 5 seconds max)
---------------------------------------------------------------------
local HttpService = game:GetService("HttpService")
local RS          = game:GetService("RunService")

local SAVE_KEY    = "ParagonConfig"           -- syn.store key
local FILE_NAME   = "ParagonConfig.json"      -- fallback writefile path
local SAVE_DELAY  = 5                         -- seconds between saves

local lastSave = 0
local queued   = false

---------------------------------------------------------------------
-- ▶ Serialization helpers -----------------------------------------
---------------------------------------------------------------------
local function deepCopy(tbl)
    local copy = {}
    for k,v in pairs(tbl) do
        if type(v)=="table" then copy[k] = deepCopy(v) else copy[k] = v end
    end
    return copy
end

local function serialize(tbl)
    local raw = deepCopy(tbl)
    for k,v in pairs(raw) do
        if typeof(v)=="EnumItem" then raw[k] = {__enum = v.EnumType.Name, name = v.Name}
        elseif type(v)=="table" then raw[k] = serialize(v) end
    end
    return raw
end

local function deserialize(tbl)
    for k,v in pairs(tbl) do
        if type(v)=="table" then
            if v.__enum then tbl[k] = Enum[v.__enum][v.name]
            else tbl[k] = deserialize(v) end
        end
    end
    return tbl
end

---------------------------------------------------------------------
-- ▶ Storage abstraction -------------------------------------------
---------------------------------------------------------------------
local function store(data)
    local json = HttpService:JSONEncode(serialize(data))
    if syn and syn.store then
        syn.store(SAVE_KEY, json)
    else
        writefile(FILE_NAME, json)
    end
end

local function retrieve()
    local raw
    if syn and syn.get then raw = syn.get(SAVE_KEY)
    elseif isfile and isfile(FILE_NAME) then raw = readfile(FILE_NAME) end

    if raw and #raw>0 then
        local ok,decoded = pcall(HttpService.JSONDecode, HttpService, raw)
        if ok and type(decoded)=="table" then return deserialize(decoded) end
    end
    return nil
end

---------------------------------------------------------------------
-- ▶ Public API -----------------------------------------------------
---------------------------------------------------------------------
local ConfigManager = {}

function ConfigManager.Load(defaults)
    local saved = retrieve()
    if saved then
        -- shallow merge into defaults (saved overrides)
        local function merge(dst,src)
            for k,v in pairs(src) do
                if type(v)=="table" and type(dst[k])=="table" then merge(dst[k],v) else dst[k]=v end
            end
        end
        merge(defaults,saved)
    end
    return defaults
end

function ConfigManager.QueueSave(config)
    if queued then return end
    queued = true
    task.delay(SAVE_DELAY, function()
        store(config)
        queued = false; lastSave = tick()
    end)
end

---------------------------------------------------------------------
-- ▶ Auto‑save hook via RunService ----------------------------------
---------------------------------------------------------------------
-- Call ConfigManager.BindAutoSave(config) once to enable automatic
-- saving when any value changes (uses metatable proxy technique).
---------------------------------------------------------------------
function ConfigManager.BindAutoSave(config)
    local proxy = {}
    local function attach(tbl)
        for k,v in pairs(tbl) do if type(v)=="table" then attach(v) end end
        return setmetatable(tbl, {
            __newindex = function(t,k,v)
                rawset(t,k,v)
                ConfigManager.QueueSave(config)
            end
        })
    end
    attach(config)
end

return ConfigManager
