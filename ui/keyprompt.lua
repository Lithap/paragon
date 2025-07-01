-- ui/keyprompt.lua
-- Fancy Paragon Key Prompt (v1.0)
-- Provides: fade‑in backdrop, pulsing "Loading..." animation, stylish input box, and 5‑sec cooldown overlay
---------------------------------------------------------------------
local RS  = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local Prompt = {}
Prompt.__index = Prompt

-- internal drawings
local drawings = {}
local function clear()
    for _,d in ipairs(drawings) do pcall(function() d:Remove() end) end
    drawings = {}
end
local function new(class,p)
    local o = Drawing.new(class)
    for k,v in pairs(p) do o[k]=v end
    table.insert(drawings,o)
    return o
end

---------------------------------------------------------------------
function Prompt.Show(message)
    clear()
    local cam = workspace.CurrentCamera
    local vp  = cam.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)

    -- backdrop fade
    Prompt.Backdrop = new("Square",{
        Position = Vector2.new(0,0), Size = vp,
        Color = Color3.fromRGB(0,0,0), Transparency = 0.4, Filled = true
    })

    local w,h = 380,200
    local boxPos = center - Vector2.new(w/2,h/2)
    Prompt.Box = new("Square",{
        Position=boxPos, Size=Vector2.new(w,h), Filled=true,
        Color=Color3.fromRGB(25,25,25), Transparency=0.85
    })
    Prompt.Header = new("Square",{
        Position=boxPos, Size=Vector2.new(w,36), Filled=true,
        Color=Color3.fromRGB(40,40,40), Transparency=1
    })
    Prompt.Title = new("Text",{
        Text="PARAGON AUTH", Size=18, Center=true,
        Position=boxPos+Vector2.new(w/2,6), Outline=true
    })
    Prompt.Msg = new("Text",{
        Text=message, Size=15, Center=true, Position=boxPos+Vector2.new(w/2,70), Outline=true
    })
    Prompt.InputTxt = new("Text",{
        Text="_", Size=16, Center=true, Position=boxPos+Vector2.new(w/2,110), Outline=true
    })
    Prompt.Hint = new("Text",{
        Text="Key: 'paragon'", Size=13, Center=true, Position=boxPos+Vector2.new(w/2,155), Color=Color3.fromRGB(150,150,150), Outline=true
    })

    -- loading dots animator
    Prompt._dot = 0
    if not Prompt._conn then
        Prompt._conn = RS.RenderStepped:Connect(function(dt)
            Prompt._dot = Prompt._dot + dt*3
            local dots = string.rep(".", (math.floor(Prompt._dot)%4))
            Prompt.Msg.Text = message .. dots
        end)
    end
end

function Prompt.UpdateInput(buf)
    if Prompt.InputTxt then Prompt.InputTxt.Text = buf .. "_" end
end

function Prompt.ErrorCooldown(seconds, attempts, max)
    Prompt.Msg.Text = string.format("Invalid key ‑ retry in %d s (%d/%d)", seconds, attempts, max)
end

function Prompt.Hide()
    if Prompt._conn then Prompt._conn:Disconnect(); Prompt._conn=nil end
    clear()
end

return Prompt
