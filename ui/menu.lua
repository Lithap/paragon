local UIS = game:GetService("UserInputService")
local RS  = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

---------------------------------------------------------------------
-- ▶ INTERNAL HELPERS
---------------------------------------------------------------------

local function createText(str, size, pos, color)
    local t = Drawing.new("Text")
    t.Color = color or Color3.new(1,1,1)
    t.Size = size
    t.Outline = true
    t.Center = false
    t.Text = str
    t.Position = pos
    return t
end

local function createSquare(size, pos, color, transparency, filled)
    local s = Drawing.new("Square")
    s.Size = size
    s.Position = pos
    s.Color = color
    s.Transparency = transparency or 1
    s.Filled = filled or true
    return s
end

---------------------------------------------------------------------
-- ▶ TOGGLE ELEMENT CLASS
---------------------------------------------------------------------
local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(label, path, Config)
    local self = setmetatable({}, Toggle)
    self.Label  = label
    self.Path   = path
    self.Config = Config
    self.State  = false
    self.TextObj= nil  -- created in Draw cycle
    return self
end

-- update cached State from Config table
function Toggle:Sync()
    local segs = string.split(self.Path, ".")
    local ref = self.Config
    for _,s in ipairs(segs) do ref = ref[s] end
    self.State = ref
end

function Toggle:ToggleValue()
    -- write back to Config table
    local segs = string.split(self.Path, ".")
    local ref  = self.Config
    for i=1,#segs-1 do ref = ref[segs[i]] end
    ref[segs[#segs]] = not self.State
    self.State = not self.State
end

-- render element at y‑offset, return total height consumed
function Toggle:Draw(basePosX, y)
    self:Sync()
    -- size constants
    local checkSize     = 12
    local paddingLeft   = 10
    local textOffsetY   = -2

    -- checkbox square
    local checkPos = Vector2.new(basePosX + paddingLeft, y)
    if not self.BoxObj then
        self.BoxObj = createSquare(Vector2.new(checkSize, checkSize), checkPos, Color3.fromRGB(60,60,60), 1, true)
    else
        self.BoxObj.Position = checkPos
    end

    -- checkmark (drawn as smaller white square here)
    if self.State then
        if not self.MarkObj then
            self.MarkObj = createSquare(Vector2.new(checkSize-4, checkSize-4), checkPos + Vector2.new(2,2), Color3.fromRGB(0,200,80), 1, true)
        else
            self.MarkObj.Size = Vector2.new(checkSize-4, checkSize-4)
            self.MarkObj.Position = checkPos + Vector2.new(2,2)
            self.MarkObj.Visible = true
        end
    elseif self.MarkObj then
        self.MarkObj.Visible = false
    end

    -- text label
    local textPos = Vector2.new(basePosX + paddingLeft + checkSize + 6, y + textOffsetY)
    if not self.TextObj then
        self.TextObj = createText(self.Label, 15, textPos, Color3.new(1,1,1))
    else
        self.TextObj.Position = textPos
    end

    -- click detection handled by Menu (passes through)
    self.ClickRegion = {x1 = checkPos.X, y1 = checkPos.Y, x2 = textPos.X + self.TextObj.TextBounds.X, y2 = checkPos.Y + checkSize}

    return checkSize + 6 -- height consumed
end

function Toggle:HandleClick(mx,my)
    local r = self.ClickRegion
    if mx >= r.x1 and mx <= r.x2 and my >= r.y1 and my <= r.y2 then
        self:ToggleValue()
        return true
    end
end

---------------------------------------------------------------------
-- ▶ MENU MODULE
---------------------------------------------------------------------
local function MenuFactory(Config)
    ----------------
    local Menu = {}
    ----------------
    Menu.Position   = Vector2.new(200, 150)
    Menu.Size       = Vector2.new(340, 400)
    Menu.Visible    = true
    Menu.ActiveTab  = nil
    Menu.Tabs       = {}      -- [name] = { elements... }
    Menu.Dragging   = false

    -----------------------------------------------------------------
    -- Tab builder API
    -----------------------------------------------------------------
    function Menu:Tab(name)
        if not self.Tabs[name] then self.Tabs[name] = {} end
        self.ActiveTab = self.ActiveTab or name

        local container = self.Tabs[name]
        local builder = {}
        function builder:Toggle(label, path)
            table.insert(container, Toggle.new(label, path, Config))
        end
        -- future: builder:Slider, builder:Keybind, etc.
        return builder
    end

    -----------------------------------------------------------------
    -- Internal: Draw everything each frame
    -----------------------------------------------------------------
    function Menu:Draw()
        if not self.Visible then return end
        local pos = self.Position
        local size= self.Size

        -- ❑ main background
        if not self.Bg then
            self.Bg = createSquare(size, pos, Color3.fromRGB(20,20,20), 0.9, true)
        else
            self.Bg.Position = pos; self.Bg.Size = size
        end

        -- ❑ header bar
        if not self.Header then
            self.Header = createSquare(Vector2.new(size.X, 28), pos, Color3.fromRGB(35,35,35), 1, true)
        else
            self.Header.Position = pos
        end

        -- title text
        if not self.Title then
            self.Title = createText("PARAGON MENU", 18, pos + Vector2.new(8,4))
        else
            self.Title.Position = pos + Vector2.new(8,4)
        end

        -- tab headers (simple—horiz list)
        local tabsX = pos.X + 8
        local tabY  = pos.Y + 30
        local idx = 1
        local mouse = LP:GetMouse()
        for name,_ in pairs(self.Tabs) do
            local tObj = self.TabObjs and self.TabObjs[name]
            if not tObj then
                tObj = createText(name, 15, Vector2.new(tabsX, tabY))
                self.TabObjs = self.TabObjs or {}; self.TabObjs[name] = tObj
            else
                tObj.Position = Vector2.new(tabsX, tabY)
            end
            -- active vs inactive color
            if name == self.ActiveTab then
                tObj.Color = Color3.fromRGB(0,200,80)
            else
                tObj.Color = Color3.fromRGB(180,180,180)
            end

            -- click to switch tab
            if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                local w = tObj.TextBounds.X
                if mouse.X >= tabsX and mouse.X <= tabsX + w and mouse.Y >= tabY and mouse.Y <= tabY + 18 then
                    self.ActiveTab = name
                end
            end

            tabsX += tObj.TextBounds.X + 12
            idx += 1
        end

        -- draw elements of active tab
        local elements = self.Tabs[self.ActiveTab]
        if elements then
            local curY = pos.Y + 60
            for _,el in ipairs(elements) do
                curY += el:Draw(pos.X, curY)
            end
        end
    end

    -----------------------------------------------------------------
    -- Dragging logic
    -----------------------------------------------------------------
    UIS.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            local mx,my = LP:GetMouse().X, LP:GetMouse().Y
            local p = Menu.Position; local s = Menu.Size
            if mx >= p.X and mx <= p.X+s.X and my >= p.Y and my <= p.Y+28 then
                Menu.Dragging = true
                Menu.DragOffset = Vector2.new(mx,my) - p
            end
        end
    end)

    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            Menu.Dragging = false
        end
    end)

    RS.RenderStepped:Connect(function()
        if Menu.Dragging then
            local m = LP:GetMouse()
            Menu.Position = Vector2.new(m.X, m.Y) - Menu.DragOffset
        end
        Menu:Draw()
    end)

    -----------------------------------------------------------------
    function Menu:Init() end  -- kept for compatibility (nothing to do yet)

    return Menu
end

return MenuFactory
