-- ui/elements/slider.lua
-- Slider element for Paragon Drawing UI
-- Supports click‑drag to change value, displays current value inline
-- API: Slider.new(label, path, Config, min, max)
---------------------------------------------------------------------
local UIS = game:GetService("UserInputService")
local LP  = game:GetService("Players").LocalPlayer

local Slider = {}
Slider.__index = Slider

---------------------------------------------------------------------
-- Helper constructors (simple, local so we don’t re‑require utils)
---------------------------------------------------------------------
local function newSquare(size,pos,color)
    local s = Drawing.new("Square")
    s.Size  = size
    s.Position = pos
    s.Color = color
    s.Filled = true
    s.Transparency = 1
    return s
end

local function newText(txt,pos)
    local t = Drawing.new("Text")
    t.Text = txt
    t.Position = pos
    t.Color = Color3.fromRGB(255,255,255)
    t.Size = 15
    t.Outline = true
    return t
end

---------------------------------------------------------------------
function Slider.new(label, path, Config, min, max)
    local self = setmetatable({}, Slider)
    self.Label  = label
    self.Path   = path
    self.Config = Config
    self.Min    = min
    self.Max    = max
    self.Value  = min
    return self
end

---------------------------------------------------------------------
-- Sync current value from Config table
---------------------------------------------------------------------
function Slider:Sync()
    local ref = self.Config
    for _,seg in ipairs(string.split(self.Path,".")) do ref = ref[seg] end
    self.Value = ref
end

-- Write current value back to Config
function Slider:Apply(val)
    local segs = string.split(self.Path, ".")
    local ref  = self.Config
    for i=1,#segs-1 do ref = ref[segs[i]] end
    ref[segs[#segs]] = val
    self.Value = val
end

---------------------------------------------------------------------
-- Draw slider; returns element height consumed
---------------------------------------------------------------------
function Slider:Draw(baseX, y)
    self:Sync()

    -- layout constants
    local width = 200
    local barHeight = 4
    local labelXOffset = 10
    local barYOffset = 18

    -- label
    if not self.LabelObj then
        self.LabelObj = newText(self.Label, Vector2.new(baseX + labelXOffset, y-2))
    else
        self.LabelObj.Position = Vector2.new(baseX + labelXOffset, y-2)
    end

    -- value text (right‑aligned)
    local valStr = string.format("%d", self.Value)
    if not self.ValObj then
        self.ValObj = newText(valStr, Vector2.new(baseX + labelXOffset + width + 40, y-2))
    else
        self.ValObj.Text = valStr
        self.ValObj.Position = Vector2.new(baseX + labelXOffset + width + 40, y-2)
    end

    -- bar background
    local barPos = Vector2.new(baseX + labelXOffset, y + barYOffset)
    if not self.BarBg then
        self.BarBg = newSquare(Vector2.new(width, barHeight), barPos, Color3.fromRGB(60,60,60))
    else
        self.BarBg.Position = barPos
    end

    -- bar fill percentage
    local pct   = (self.Value - self.Min) / (self.Max - self.Min)
    if not self.BarFill then
        self.BarFill = newSquare(Vector2.new(width * pct, barHeight), barPos, Color3.fromRGB(0,200,80))
    else
        self.BarFill.Size = Vector2.new(width * pct, barHeight)
        self.BarFill.Position = barPos
    end

    -- clickable region definition
    self.ClickRegion = {x1 = barPos.X, y1 = barPos.Y, x2 = barPos.X+width, y2 = barPos.Y+barHeight+2}

    return barYOffset + 10
end

---------------------------------------------------------------------
-- Handle mouse click/drag; returns true if element consumed the event
---------------------------------------------------------------------
function Slider:HandleInput(mx,my,held)
    local r = self.ClickRegion
    if mx >= r.x1 and mx <= r.x2 and my >= r.y1 and my <= r.y2 then
        -- convert mouse x to value
        local pct = math.clamp((mx - r.x1) / (r.x2 - r.x1), 0, 1)
        local newVal = math.floor(self.Min + (self.Max - self.Min)*pct + 0.5)
        self:Apply(newVal)
        return true
    end
end

return Slider
