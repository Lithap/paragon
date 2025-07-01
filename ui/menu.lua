-- ui/menu.lua  (v0.3 — fade/slide animation + scroll)
-- Paragon Drawing‑based Menu  ▸ draggable ▸ dynamic tabs ▸ toggle/slider/keybind ▸ scroll ▸ animated open/close

local UIS = game:GetService("UserInputService")
local RS  = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

---------------------------------------------------------------------
-- ⛏ helpers --------------------------------------------------------
---------------------------------------------------------------------
local function newText(txt,size,pos,col)
    local t = Drawing.new("Text")
    t.Text, t.Size, t.Position = txt, size, pos
    t.Color = col or Color3.new(1,1,1)
    t.Outline, t.Transparency = true, 0
    return t
end
local function newSquare(size,pos,col)
    local s = Drawing.new("Square")
    s.Size, s.Position, s.Color, s.Filled, s.Transparency = size,pos,col,true,0
    return s
end
---------------------------------------------------------------------
local Toggle  = require(script.Parent.elements.toggle)
local Slider  = require(script.Parent.elements.slider)
local Keybind = require(script.Parent.elements.keybind)
---------------------------------------------------------------------
local function MenuFactory(Config)
    local Menu = {
        Position   = Vector2.new(200,150),
        Size       = Vector2.new(360,420),
        Open       = true,
        Alpha      = 0,          -- current transparency lerp (0‑1)
        TargetA    = 1,          -- target alpha
        ActiveTab  = nil,
        Tabs       = {},
        Dragging   = false,
        Scroll     = 0,
        ScrollMax  = 0,
    }

    -----------------------------------------------------------------
    -- 🔑 toggle visibility via key ----------------------------------
    -----------------------------------------------------------------
    local toggleKey = (Config.UI and Config.UI.ToggleKey) or Enum.KeyCode.RightShift
    UIS.InputBegan:Connect(function(inp,gpe)
        if gpe then return end
        if inp.KeyCode == toggleKey then
            Menu.Open = not Menu.Open
            Menu.TargetA = Menu.Open and 1 or 0
        end
    end)

    -----------------------------------------------------------------
    -- 🏗 tab builder API -------------------------------------------
    -----------------------------------------------------------------
    function Menu:Tab(name)
        if not self.Tabs[name] then self.Tabs[name] = {} end
        self.ActiveTab = self.ActiveTab or name
        local cont = self.Tabs[name]
        local b = {}
        function b:Toggle(l,p)  table.insert(cont,Toggle.new(l,p,Config))  end
        function b:Slider(l,p,min,max)  table.insert(cont,Slider.new(l,p,Config,min,max)) end
        function b:Keybind(l,p) table.insert(cont,Keybind.new(l,p,Config)) end
        return b
    end

    -----------------------------------------------------------------
    -- 🎨 transparency helper ---------------------------------------
    -----------------------------------------------------------------
    local function applyAlpha(obj,a)
        if obj then obj.Transparency = a end
    end

    -----------------------------------------------------------------
    -- 📐 layout + draw ---------------------------------------------
    -----------------------------------------------------------------
    function Menu:Draw()
        -- lerp alpha
        self.Alpha += (self.TargetA - self.Alpha) * 0.15
        if self.Alpha < 0.02 then return end  -- invisible, skip draw
        local a = self.Alpha
        local pos,size = self.Position, self.Size

        -- bg & header
        self.Bg     = self.Bg     or newSquare(size,pos,Color3.fromRGB(20,20,20))
        self.Header = self.Header or newSquare(Vector2.new(size.X,28),pos,Color3.fromRGB(35,35,35))
        self.Title  = self.Title  or newText("PARAGON MENU",18,pos+Vector2.new(8,4))
        self.Bg.Position, self.Bg.Size = pos,size
        self.Header.Position = pos
        self.Title.Position  = pos+Vector2.new(8,4)
        applyAlpha(self.Bg, 0.9*a)
        applyAlpha(self.Header, a)
        applyAlpha(self.Title, a)

        -- tabs
        local tX = pos.X+8; local tabY = pos.Y+30; local mouse=LP:GetMouse()
        self.TabObjs = self.TabObjs or {}
        for name,_ in pairs(self.Tabs) do
            local tObj = self.TabObjs[name] or newText(name,15,Vector2.new(),Color3.new(1,1,1)); self.TabObjs[name]=tObj
            tObj.Position = Vector2.new(tX,tabY)
            tObj.Color = (name==self.ActiveTab) and Color3.fromRGB(0,200,80) or Color3.fromRGB(180,180,180)
            applyAlpha(tObj,a)
            -- click switch
            if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                local w=tObj.TextBounds.X
                if mouse.X>=tX and mouse.X<=tX+w and mouse.Y>=tabY and mouse.Y<=tabY+18 then self.ActiveTab=name end
            end
            tX += tObj.TextBounds.X+12
        end

        -- elements
        local elems = self.Tabs[self.ActiveTab]
        if elems then
            local startY = pos.Y+60
            local curY   = startY + self.Scroll
            local totalHeight = 0
            for _,el in ipairs(elems) do
                if el.Draw then
                    local h = el:Draw(pos.X,curY)
                    -- apply alpha to element parts if they expose .TextObj etc.
                    if el.TextObj then applyAlpha(el.TextObj,a) end
                    if el.BoxObj then applyAlpha(el.BoxObj,a) end
                    if el.MarkObj then applyAlpha(el.MarkObj,a) end
                    if el.BarBg then applyAlpha(el.BarBg,a) end
                    if el.BarFill then applyAlpha(el.BarFill,a) end
                    if el.ValObj then applyAlpha(el.ValObj,a) end
                    curY += h; totalHeight += h
                end
            end
            self.ScrollMax = math.max(totalHeight - (size.Y - 70),0)
            self.Scroll = math.clamp(self.Scroll,-self.ScrollMax,0)
        end
    end

    -----------------------------------------------------------------
    -- 🖱 input: drag, scroll, click --------------------------------
    -----------------------------------------------------------------
    UIS.InputBegan:Connect(function(inp,gpe)
        if gpe or Menu.Alpha < 0.05 then return end
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            local m = LP:GetMouse(); local p,s = Menu.Position,Menu.Size
            if m.X>=p.X and m.X<=p.X+s.X and m.Y>=p.Y and m.Y<=p.Y+28 then
                Menu.Dragging = true; Menu.DragOffset = Vector2.new(m.X,m.Y)-p
            end
            local elems = Menu.Tabs[Menu.ActiveTab]
            if elems then
                for _,el in ipairs(elems) do
                    if el.HandleClick and el:HandleClick(m.X,m.Y) then break end
                end
            end
        end
    end)
    UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then Menu.Dragging=false end end)
    UIS.InputChanged:Connect(function(inp,gpe)
        if gpe or Menu.Alpha<0.05 then return end
        if inp.UserInputType==Enum.UserInputType.MouseWheel then
            local m=LP:GetMouse(); local p,s=Menu.Position,Menu.Size
            if m.X>=p.X and m.X<=p.X+s.X and m.Y>=p.Y+30 and m.Y<=p.Y+s.Y then
                Menu.Scroll = math.clamp(Menu.Scroll + inp.Position.Z*12, -Menu.ScrollMax, 0)
            end
        end
    end)

    RS.RenderStepped:Connect(function()
        if Menu.Dragging then
            local m=LP:GetMouse(); Menu.Position = Vector2.new(m.X,m.Y)-Menu.DragOffset
        end
        Menu:Draw()
    end)

    function Menu:Init() end
    return Menu
end
return MenuFactory
