-- ui/menu.lua  (v0.2 — with scroll support)
-- Paragon Drawing‑based Menu  ▸ draggable ▸ dynamic tabs ▸ toggle/slider/keybind ▸ scrollable

local UIS = game:GetService("UserInputService")
local RS  = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

---------------------------------------------------------------------
-- ⛏ quick helpers --------------------------------------------------
---------------------------------------------------------------------
local function newText(txt,size,pos,col)
    local t = Drawing.new("Text"); t.Text=txt; t.Size=size; t.Position=pos; t.Color=col or Color3.new(1,1,1);
    t.Outline=true; return t
end
local function newSquare(size,pos,col,alpha)
    local s = Drawing.new("Square"); s.Size=size; s.Position=pos; s.Color=col; s.Filled=true; s.Transparency=alpha or 1; return s
end
---------------------------------------------------------------------
-- • ELEMENT REQUIRES ----------------------------------------------
---------------------------------------------------------------------
local Toggle  = require(script.Parent.elements.toggle)
local Slider  = require(script.Parent.elements.slider)
local Keybind = require(script.Parent.elements.keybind)
---------------------------------------------------------------------
local function MenuFactory(Config)
    local Menu = {
        Position   = Vector2.new(200,150),
        Size       = Vector2.new(360,420),
        Visible    = true,
        ActiveTab  = nil,
        Tabs       = {},
        Dragging   = false,
        Scroll     = 0,
        ScrollMax  = 0,
    }

    -----------------------------------------------------------------
    -- ▶ UI BUILD API ------------------------------------------------
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
    -- ▶ DRAW LOOP ---------------------------------------------------
    -----------------------------------------------------------------
    function Menu:Draw()
        if not self.Visible then return end
        local pos,size = self.Position, self.Size

        -- background + header --------------------------------------
        self.Bg     = self.Bg     or newSquare(size,pos,Color3.fromRGB(20,20,20),0.9)
        self.Header = self.Header or newSquare(Vector2.new(size.X,28),pos,Color3.fromRGB(35,35,35),1)
        self.Title  = self.Title  or newText("PARAGON MENU",18,pos+Vector2.new(8,4))
        self.Bg.Position, self.Bg.Size = pos,size
        self.Header.Position = pos
        self.Title.Position  = pos+Vector2.new(8,4)

        -- tab headers ---------------------------------------------
        local tX = pos.X+8; local tabY = pos.Y+30; local mouse=LP:GetMouse()
        self.TabObjs = self.TabObjs or {}
        for name,_ in pairs(self.Tabs) do
            local tObj = self.TabObjs[name] or newText(name,15,Vector2.new(),Color3.new(1,1,1)); self.TabObjs[name]=tObj
            tObj.Position = Vector2.new(tX,tabY)
            tObj.Color = (name==self.ActiveTab) and Color3.fromRGB(0,200,80) or Color3.fromRGB(180,180,180)

            -- click to switch
            if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                local w=tObj.TextBounds.X
                if mouse.X>=tX and mouse.X<=tX+w and mouse.Y>=tabY and mouse.Y<=tabY+18 then self.ActiveTab=name end
            end
            tX += tObj.TextBounds.X+12
        end

        -- elements -------------------------------------------------
        local elems = self.Tabs[self.ActiveTab]
        if elems then
            local startY = pos.Y+60
            local curY   = startY + self.Scroll
            local visibleBottom = pos.Y + size.Y - 10
            local totalHeight = 0

            for _,el in ipairs(elems) do
                local h = el:Draw(pos.X,curY)
                curY += h
                totalHeight += h
            end

            -- compute scroll limits
            self.ScrollMax = math.max(totalHeight - (size.Y - 70),0)
            self.Scroll = math.clamp(self.Scroll,-self.ScrollMax,0)
        end
    end

    -----------------------------------------------------------------
    -- ▶ INPUT / DRAG / SCROLL --------------------------------------
    -----------------------------------------------------------------
    UIS.InputBegan:Connect(function(inp,gpe)
        if gpe then return end
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            local m = LP:GetMouse(); local p,s = Menu.Position,Menu.Size
            if m.X>=p.X and m.X<=p.X+s.X and m.Y>=p.Y and m.Y<=p.Y+28 then
                Menu.Dragging = true
                Menu.DragOffset = Vector2.new(m.X,m.Y)-p
            end
            -- pass click into elements
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
        if gpe or not Menu.Visible then return end
        if inp.UserInputType==Enum.UserInputType.MouseWheel then
            local m=LP:GetMouse(); local p,s=Menu.Position,Menu.Size
            -- only scroll when mouse over content area
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
