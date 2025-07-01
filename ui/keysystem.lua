local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

---------------------------------------------------------------------
-- ▶ CONFIGURATION
---------------------------------------------------------------------
local VALID_KEY = "paragon"          -- required key (case‑insensitive)
local MAX_ATTEMPTS = 3                -- attempts before self‑destruct
local COOLDOWN = 5                    -- seconds between attempts

---------------------------------------------------------------------
-- ▶ INTERNAL STATE
---------------------------------------------------------------------
local attempts = 0                    -- failed attempt counter
local drawings = {}                   -- active Drawing objects
local onValidatedCB                   -- callback when key accepted
local finished = false                -- guard so callback only once

---------------------------------------------------------------------
-- ▶ STORAGE HELPERS (Synapse or getgenv fallback)
---------------------------------------------------------------------
local function saveKey(key)
    if syn and syn.store then
        syn.store("ParagonKey", key)
    else
        getgenv()._ParagonSavedKey = key
    end
end

local function loadKey()
    if syn and syn.get then
        return syn.get("ParagonKey")
    else
        return getgenv()._ParagonSavedKey
    end
end

---------------------------------------------------------------------
-- ▶ VALIDATION
---------------------------------------------------------------------
local function isValid(k)
    return tostring(k):lower() == VALID_KEY:lower()
end

---------------------------------------------------------------------
-- ▶ DRAWING HELPERS
---------------------------------------------------------------------
local function clearDrawings()
    for _,d in ipairs(drawings) do pcall(function() d:Remove() end) end
    drawings = {}
end

local function text(str, size, pos)
    local t = Drawing.new("Text")
    t.Text = str
    t.Size = size
    t.Position = pos
    t.Center = true
    t.Color = Color3.fromRGB(255,255,255)
    t.Outline = true
    table.insert(drawings, t)
    return t
end

local function square(size, pos, color, filled, transparency)
    local s = Drawing.new("Square")
    s.Size = size
    s.Position = pos
    s.Color = color
    s.Filled = filled
    s.Transparency = transparency or 1
    table.insert(drawings, s)
    return s
end

---------------------------------------------------------------------
-- ▶ PROMPT UI
---------------------------------------------------------------------
local inputBuf = ""
local inputTxt -- ref to dynamic Drawing text

local function renderPrompt(msg)
    clearDrawings()
    local cam = workspace.CurrentCamera
    local view = cam.ViewportSize
    local w,h = 320, 160
    local basePos = Vector2.new((view.X-w)/2, (view.Y-h)/2)

    -- background & header bar
    square(Vector2.new(w,h), basePos, Color3.fromRGB(20,20,20), true, 0.85)
    square(Vector2.new(w,30), basePos, Color3.fromRGB(35,35,35), true, 0.95)

    text("PARAGON - KEY REQUIRED", 18, basePos + Vector2.new(w/2, 7))
    text(msg, 15, basePos + Vector2.new(w/2, 50))

    inputTxt = text("_", 16, basePos + Vector2.new(w/2, 95))
end

---------------------------------------------------------------------
-- ▶ INPUT HANDLING
---------------------------------------------------------------------
local function beginCapture()
    inputBuf = ""
    renderPrompt("Enter key to continue")

    local conn; conn = UIS.InputBegan:Connect(function(inp,gpe)
        if gpe then return end
        if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end

        local key = inp.KeyCode
        if key == Enum.KeyCode.Backspace then
            inputBuf = inputBuf:sub(1,#inputBuf-1)
        elseif key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter then
            conn:Disconnect()
            validateInput(inputBuf)
            return
        else
            local char = key.Name
            if #char == 1 then
                inputBuf = inputBuf .. char:lower()
            end
        end
        inputTxt.Text = inputBuf .. "_"
    end)
end

---------------------------------------------------------------------
-- ▶ VALIDATION LOGIC (with cooldown & retry)
---------------------------------------------------------------------
function validateInput(str)
    if isValid(str) then
        saveKey(str)
        clearDrawings()
        finished = true
        if onValidatedCB then onValidatedCB() end
        return
    end

    attempts += 1
    if attempts >= MAX_ATTEMPTS then
        clearDrawings()
        error("PARAGON: Maximum invalid key attempts reached.")
    end

    local retryMsg = string.format("Invalid key. Retry in %d s (%d/%d)", COOLDOWN, attempts, MAX_ATTEMPTS)
    renderPrompt(retryMsg)
    task.delay(COOLDOWN, beginCapture)
end

---------------------------------------------------------------------
-- ▶ PUBLIC API
---------------------------------------------------------------------
local KeySystem = {}

function KeySystem:IsValid()
    return finished
end

function KeySystem:Init(callback)
    onValidatedCB = callback
    if getgenv().BypassKey then
        finished = true; if callback then callback() end; return
    end

    local saved = loadKey()
    if saved and isValid(saved) then
        finished = true; if callback then callback() end; return
    end

    beginCapture()
end

return KeySystem
