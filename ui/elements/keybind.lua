-- ui/elements/keybind.lua
-- Click‑to‑set Keybind widget for Paragon UI
--   Displays current key; on click enters capture mode (flashing underscore)
--   Stores Enum.KeyCode in Config table at given path
---------------------------------------------------------------------
local UIS = game:GetService("UserInputService")
local LP  = game:GetService("Players").LocalPlayer

local Keybind = {}
Keybind.__index = Keybind

local function newText(txt,pos)
    local t = Drawing.new("Text")
    t.Text = txt
    t.Position = pos
    t.Size = 15
    t.Color = Color3.fromRGB(255,255,255)
    t.Outline = true
    return t
end

---------------------------------------------------------------------
function Keybind.new(label,path,Config)
    local self = setmetatable({},Keybind)
    self.Label  = label
    self.Path   = path
    self.Config = Config
    self.Current= Enum.KeyCode.None
    self.Capturing = false
    return self
end

---------------------------------------------------------------------
local function getConfigRef(tbl,path)
    local ref = tbl
    for _,seg in ipairs(string.split(path,".")) do ref = ref[seg] end
    return ref
end

function Keybind:Sync()
    self.Current = getConfigRef(self.Config,self.Path)
end

function Keybind:SetKey(code)
    local segs = string.split(self.Path,".")
    local ref  = self.Config
    for i=1,#segs-1 do ref = ref[segs[i]] end
    ref[segs[#segs]] = code
    self.Current = code
end

---------------------------------------------------------------------
-- Draw element; returns height consumed
---------------------------------------------------------------------
function Keybind:Draw(baseX,y)
    self:Sync()
    local labelX = baseX + 10
    local keyX   = baseX + 200

    -- label text
    if not self.LabelObj then
        self.LabelObj = newText(self.Label,Vector2.new(labelX,y-2))
    else
        self.LabelObj.Position = Vector2.new(labelX,y-2)
    end

    -- key text
    local keyTxt = self.Capturing and "Press key..." or self.Current.Name
    if not self.KeyObj then
        self.KeyObj = newText(keyTxt,Vector2.new(keyX,y-2))
    else
        self.KeyObj.Text = keyTxt
        self.KeyObj.Position = Vector2.new(keyX,y-2)
        self.KeyObj.Color = self.Capturing and Color3.fromRGB(255,200,80) or Color3.fromRGB(0,200,80)
    end

    -- define click box around key text
    local w = self.KeyObj.TextBounds.X
    self.ClickRegion = {x1=keyX, y1=y-2, x2=keyX+w, y2=y+14}

    return 20
end

---------------------------------------------------------------------
-- Handle mouse click / key capture
---------------------------------------------------------------------
function Keybind:HandleClick(mx,my)
    -- if capturing, ignore clicks
    if self.Capturing then return end
    local r=self.ClickRegion
    if mx>=r.x1 and mx<=r.x2 and my>=r.y1 and my<=r.y2 then
        self.Capturing=true
        -- temporary connection
        local conn; conn=UIS.InputBegan:Connect(function(inp,gpe)
            if gpe then return end
            if inp.UserInputType==Enum.UserInputType.Keyboard then
                self:SetKey(inp.KeyCode)
                self.Capturing=false
                conn:Disconnect()
            end
        end)
        return true
    end
end

return Keybind
