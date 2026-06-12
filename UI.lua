-- =====================
-- MODULE: UI
-- ChrisM Hub — Neverlose-style layout
-- =====================
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local TextService       = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local UI = {}

-- ══════════════════════════════════════════
-- CONSTANTS
-- ══════════════════════════════════════════
local PILL_W    = 32
local PILL_H    = 17
local KNOB_SIZE = 12
local KNOB_PAD  = 2

local PANEL_W   = 720
local PANEL_H   = 500
local BAR_H     = 38  -- collapsed title bar height

local C = {
    bg0        = Color3.fromRGB(13,  13,  16),
    bg1        = Color3.fromRGB(20,  20,  25),
    bg2        = Color3.fromRGB(26,  26,  33),
    bg3        = Color3.fromRGB(33,  33,  43),
    bg4        = Color3.fromRGB(42,  42,  55),
    border     = Color3.fromRGB(38,  38,  50),
    border2    = Color3.fromRGB(50,  50,  65),
    accent     = Color3.fromRGB(80,  120, 220),
    accent2    = Color3.fromRGB(110, 155, 255),
    text0      = Color3.fromRGB(235, 235, 245),
    text1      = Color3.fromRGB(165, 165, 185),
    text2      = Color3.fromRGB(100, 100, 120),
    text3      = Color3.fromRGB(60,  60,  75),
    green      = Color3.fromRGB(50,  195, 100),
    red        = Color3.fromRGB(210, 70,  70),
    pill_off   = Color3.fromRGB(48,  48,  62),
    pill_on    = Color3.fromRGB(35,  65,  140),
    knob_off   = Color3.fromRGB(100, 100, 120),
    knob_on    = Color3.fromRGB(110, 155, 255),
}

local FONT_REG  = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular,  Enum.FontStyle.Normal)
local FONT_MED  = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Medium,   Enum.FontStyle.Normal)
local FONT_BOLD = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold,     Enum.FontStyle.Normal)

local TW_FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TW_MED    = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- ══════════════════════════════════════════
-- ROOT GUI
-- ══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "ChrisMHubGui"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn   = false
ScreenGui.DisplayOrder   = 10

-- Main panel
local Panel = Instance.new("Frame")
Panel.Name             = "Panel"
Panel.Size             = UDim2.new(0, PANEL_W, 0, PANEL_H)
Panel.Position         = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2)
Panel.BackgroundColor3 = C.bg1
Panel.BorderSizePixel  = 0
Panel.ClipsDescendants = true
Panel.Parent           = ScreenGui
local _pc = Instance.new("UICorner"); _pc.CornerRadius = UDim.new(0,10); _pc.Parent = Panel
local _ps = Instance.new("UIStroke"); _ps.Color = C.border; _ps.Thickness = 1; _ps.Parent = Panel

local minimized = false

-- ══════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or C.border
    s.Thickness = thickness or 1
    s.Parent    = parent
    return s
end

local function label(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel        = 0
    for k, v in pairs(props) do l[k] = v end
    l.Parent = parent
    return l
end

local function frame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.BorderSizePixel        = 0
    for k, v in pairs(props) do f[k] = v end
    f.Parent = parent
    return f
end

local function tween(inst, props, info)
    TweenService:Create(inst, info or TW_FAST, props):Play()
end

-- ══════════════════════════════════════════
-- SIDEBAR
-- ══════════════════════════════════════════
local Sidebar = Instance.new("Frame")
Sidebar.Name             = "Sidebar"
Sidebar.Size             = UDim2.new(0, 158, 1, 0)
Sidebar.BackgroundColor3 = C.bg0
Sidebar.BorderSizePixel  = 0
Sidebar.Parent           = Panel
local _sl = Instance.new("UICorner"); _sl.CornerRadius = UDim.new(0,10); _sl.Parent = Sidebar
local _sclip = Instance.new("Frame")
_sclip.Size             = UDim2.new(0, 10, 1, 0)
_sclip.Position         = UDim2.new(1, -10, 0, 0)
_sclip.BackgroundColor3 = C.bg0
_sclip.BorderSizePixel  = 0
_sclip.Parent           = Sidebar
local _sborder = Instance.new("Frame")
_sborder.Size             = UDim2.new(0, 1, 1, 0)
_sborder.Position         = UDim2.new(1, -1, 0, 0)
_sborder.BackgroundColor3 = C.border
_sborder.BorderSizePixel  = 0
_sborder.Parent           = Sidebar

-- Brand header
local BrandHeader = Instance.new("Frame")
BrandHeader.Name             = "BrandHeader"
BrandHeader.Size             = UDim2.new(1, 0, 0, 56)
BrandHeader.BackgroundTransparency = 1
BrandHeader.BorderSizePixel  = 0
BrandHeader.Parent           = Sidebar

local BrandLogo = Instance.new("Frame")
BrandLogo.Name             = "BrandLogo"
BrandLogo.Size             = UDim2.new(0, 32, 0, 32)
BrandLogo.Position         = UDim2.new(0, 12, 0, 12)
BrandLogo.BackgroundColor3 = C.accent
BrandLogo.BorderSizePixel  = 0
BrandLogo.Parent           = BrandHeader
corner(BrandLogo, 8)
label(BrandLogo, {
    Size = UDim2.new(1,0,1,0),
    Text = "CM",
    TextColor3 = Color3.new(1,1,1),
    TextSize = 11,
    FontFace = FONT_BOLD,
})

label(BrandHeader, {
    Position = UDim2.new(0, 50, 0, 13),
    Size     = UDim2.new(1, -54, 0, 16),
    Text     = "ChrisM Hub",
    TextColor3 = C.text0,
    TextSize = 12,
    FontFace = FONT_BOLD,
    TextXAlignment = Enum.TextXAlignment.Left,
})

label(BrandHeader, {
    Position = UDim2.new(0, 50, 0, 29),
    Size     = UDim2.new(1, -54, 0, 14),
    Text     = "Apocolypse Rising 2",
    TextColor3 = C.text2,
    TextSize = 10,
    FontFace = FONT_REG,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local _bDiv = Instance.new("Frame")
_bDiv.Size             = UDim2.new(1, 0, 0, 1)
_bDiv.Position         = UDim2.new(0, 0, 0, 56)
_bDiv.BackgroundColor3 = C.border
_bDiv.BorderSizePixel  = 0
_bDiv.Parent           = Sidebar

-- Nav scroll container
local NavScroll = Instance.new("ScrollingFrame")
NavScroll.Name                 = "NavScroll"
NavScroll.Size                 = UDim2.new(1, 0, 1, -110)
NavScroll.Position             = UDim2.new(0, 0, 0, 57)
NavScroll.BackgroundTransparency = 1
NavScroll.BorderSizePixel      = 0
NavScroll.ScrollBarThickness   = 0
NavScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
NavScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
NavScroll.Parent               = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Padding   = UDim.new(0, 0)
NavLayout.Parent    = NavScroll

local NavPad = Instance.new("UIPadding")
NavPad.PaddingTop    = UDim.new(0, 6)
NavPad.PaddingBottom = UDim.new(0, 6)
NavPad.Parent        = NavScroll

local function navSection(text, order)
    local f = frame(NavScroll, {
        Size         = UDim2.new(1, 0, 0, 22),
        LayoutOrder  = order,
    })
    label(f, {
        Position = UDim2.new(0, 14, 0, 0),
        Size     = UDim2.new(1, -14, 1, 0),
        Text     = text,
        TextColor3 = C.text3,
        TextSize = 9,
        FontFace = FONT_BOLD,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
end

local navItems    = {}
local navItemRefs = {}

local function navItem(pageName, displayText, iconCode, order)
    local btn = Instance.new("TextButton")
    btn.Name             = "Nav_" .. pageName
    btn.Size             = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = C.bg0
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel  = 0
    btn.Text             = ""
    btn.LayoutOrder      = order
    btn.Parent           = NavScroll
    corner(btn, 5)

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 2, 0.6, 0)
    bar.Position         = UDim2.new(0, 0, 0.2, 0)
    bar.BackgroundColor3 = C.accent2
    bar.BorderSizePixel  = 0
    bar.Visible          = false
    bar.Parent           = btn
    corner(bar, 2)

    label(btn, {
        Position = UDim2.new(0, 10, 0, 0),
        Size     = UDim2.new(0, 18, 1, 0),
        Text     = iconCode,
        TextColor3 = C.text2,
        TextSize = 13,
        FontFace = FONT_REG,
        Name     = "Icon",
    })

    local lbl = label(btn, {
        Position = UDim2.new(0, 30, 0, 0),
        Size     = UDim2.new(1, -34, 1, 0),
        Text     = displayText,
        TextColor3 = C.text1,
        TextSize = 12,
        FontFace = FONT_MED,
        TextXAlignment = Enum.TextXAlignment.Left,
        Name = "Label",
    })

    table.insert(navItems, { btn = btn, bar = bar, lbl = lbl, icon = btn:FindFirstChild("Icon"), page = pageName })
    navItemRefs[pageName] = { btn = btn, bar = bar, lbl = lbl }
    return btn
end

navSection("AIMBOT", 1)
navItem("combat",   "Rage",       "⊕", 2)
navItem("legit",    "Legit",      "◎", 3)
navSection("VISUALS", 10)
navItem("visuals",  "Player ESP", "◈", 11)
navItem("world",    "World",      "◉", 12)
navSection("MISC", 20)
navItem("movement", "Movement",   "✦", 21)
navItem("misc",     "Misc",       "⋯", 22)

-- User footer
local Footer = Instance.new("Frame")
Footer.Name             = "Footer"
Footer.Size             = UDim2.new(1, 0, 0, 52)
Footer.Position         = UDim2.new(0, 0, 1, -52)
Footer.BackgroundTransparency = 1
Footer.BorderSizePixel  = 0
Footer.Parent           = Sidebar

local _fDiv = Instance.new("Frame")
_fDiv.Size             = UDim2.new(1, 0, 0, 1)
_fDiv.BackgroundColor3 = C.border
_fDiv.BorderSizePixel  = 0
_fDiv.Parent           = Footer

local FooterBtn = Instance.new("TextButton")
FooterBtn.Size             = UDim2.new(1, -16, 0, 40)
FooterBtn.Position         = UDim2.new(0, 8, 0, 6)
FooterBtn.BackgroundColor3 = C.bg0
FooterBtn.BackgroundTransparency = 1
FooterBtn.BorderSizePixel  = 0
FooterBtn.Text             = ""
FooterBtn.Parent           = Footer
corner(FooterBtn, 6)

FooterBtn.MouseEnter:Connect(function()
    tween(FooterBtn, {BackgroundTransparency = 0.5})
end)
FooterBtn.MouseLeave:Connect(function()
    tween(FooterBtn, {BackgroundTransparency = 1})
end)

local Avatar = Instance.new("Frame")
Avatar.Size             = UDim2.new(0, 28, 0, 28)
Avatar.Position         = UDim2.new(0, 6, 0.5, -14)
Avatar.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
Avatar.BorderSizePixel  = 0
Avatar.Parent           = FooterBtn
corner(Avatar, 14)
stroke(Avatar, C.border2, 1.5)

local AvatarLbl = label(Avatar, {
    Size       = UDim2.new(1,0,1,0),
    Text       = "?",
    TextColor3 = Color3.new(1,1,1),
    TextSize   = 11,
    FontFace   = FONT_BOLD,
})

local UserNameLbl = label(FooterBtn, {
    Position       = UDim2.new(0, 42, 0, 6),
    Size           = UDim2.new(1, -50, 0, 14),
    Text           = "Loading...",
    TextColor3     = C.text0,
    TextSize       = 11,
    FontFace       = FONT_BOLD,
    TextXAlignment = Enum.TextXAlignment.Left,
    Name           = "UserName",
})

local StatusDot = Instance.new("Frame")
StatusDot.Size             = UDim2.new(0, 5, 0, 5)
StatusDot.BackgroundColor3 = C.green
StatusDot.BorderSizePixel  = 0
StatusDot.Parent           = FooterBtn
corner(StatusDot, 3)

label(FooterBtn, {
    Position       = UDim2.new(0, 42, 0, 22),
    Size           = UDim2.new(1, -50, 0, 12),
    Text           = "● Online",
    TextColor3     = C.green,
    TextSize       = 9,
    FontFace       = FONT_REG,
    TextXAlignment = Enum.TextXAlignment.Left,
})

task.spawn(function()
    local name = LocalPlayer.Name
    UserNameLbl.Text  = name
    AvatarLbl.Text    = string.upper(string.sub(name, 1, 2))
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size48x48
        )
    end)
    if ok and img then
        local imgLbl = Instance.new("ImageLabel")
        imgLbl.Size             = UDim2.new(1,0,1,0)
        imgLbl.BackgroundTransparency = 1
        imgLbl.Image            = img
        imgLbl.Parent           = Avatar
        corner(imgLbl, 14)
        AvatarLbl.Visible = false
    end
end)

-- ══════════════════════════════════════════
-- CONTENT AREA
-- ══════════════════════════════════════════
local Content = Instance.new("Frame")
Content.Name             = "Content"
Content.Size             = UDim2.new(1, -158, 1, 0)
Content.Position         = UDim2.new(0, 158, 0, 0)
Content.BackgroundTransparency = 1
Content.BorderSizePixel  = 0
Content.Parent           = Panel

-- Top bar (always visible — doubles as drag handle + title when minimized)
local TopBar = Instance.new("Frame")
TopBar.Name             = "TopBar"
TopBar.Size             = UDim2.new(1, 0, 0, BAR_H)
TopBar.BackgroundTransparency = 1
TopBar.BorderSizePixel  = 0
TopBar.Parent           = Content

-- Title label shown when minimized
local MinTitle = label(TopBar, {
    Position       = UDim2.new(0, 108, 0, 0),
    Size           = UDim2.new(1, -200, 1, 0),
    Text           = "ChrisM Hub",
    TextColor3     = C.text2,
    TextSize       = 11,
    FontFace       = FONT_BOLD,
    TextXAlignment = Enum.TextXAlignment.Center,
    Visible        = false,
    Name           = "MinTitle",
})

-- Config button
local ConfigBtn = Instance.new("TextButton")
ConfigBtn.Size             = UDim2.new(0, 90, 0, 24)
ConfigBtn.Position         = UDim2.new(0, 8, 0.5, -12)
ConfigBtn.BackgroundColor3 = C.bg3
ConfigBtn.BorderSizePixel  = 0
ConfigBtn.Text             = "✎  Default  ▾"
ConfigBtn.TextColor3       = C.text0
ConfigBtn.TextSize         = 11
ConfigBtn.FontFace         = FONT_MED
ConfigBtn.Parent           = TopBar
corner(ConfigBtn, 5)
stroke(ConfigBtn, C.border2)

ConfigBtn.MouseEnter:Connect(function()
    tween(ConfigBtn, {BackgroundColor3 = C.bg4})
end)
ConfigBtn.MouseLeave:Connect(function()
    tween(ConfigBtn, {BackgroundColor3 = C.bg3})
end)

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name             = "CloseBtn"
CloseBtn.Size             = UDim2.new(0, 24, 0, 24)
CloseBtn.Position         = UDim2.new(1, -32, 0.5, -12)
CloseBtn.BackgroundColor3 = C.bg3
CloseBtn.BorderSizePixel  = 0
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = C.text2
CloseBtn.TextSize         = 12
CloseBtn.FontFace         = FONT_BOLD
CloseBtn.Parent           = TopBar
corner(CloseBtn, 5)
stroke(CloseBtn, C.border2)

CloseBtn.MouseEnter:Connect(function()
    tween(CloseBtn, {BackgroundColor3 = C.red, TextColor3 = Color3.new(1,1,1)})
end)
CloseBtn.MouseLeave:Connect(function()
    tween(CloseBtn, {BackgroundColor3 = C.bg3, TextColor3 = C.text2})
end)

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, 24, 0, 24)
MinBtn.Position         = UDim2.new(1, -60, 0.5, -12)
MinBtn.BackgroundColor3 = C.bg3
MinBtn.BorderSizePixel  = 0
MinBtn.Text             = "—"
MinBtn.TextColor3       = C.text2
MinBtn.TextSize         = 12
MinBtn.FontFace         = FONT_BOLD
MinBtn.Parent           = TopBar
corner(MinBtn, 5)
stroke(MinBtn, C.border2)

MinBtn.MouseEnter:Connect(function() tween(MinBtn, {BackgroundColor3 = C.bg4}) end)
MinBtn.MouseLeave:Connect(function() tween(MinBtn, {BackgroundColor3 = C.bg3}) end)

-- Topbar divider (hidden when minimized)
local TopBarDiv = Instance.new("Frame")
TopBarDiv.Name             = "TopBarDiv"
TopBarDiv.Size             = UDim2.new(1, 0, 0, 1)
TopBarDiv.Position         = UDim2.new(0, 0, 1, -1)
TopBarDiv.BackgroundColor3 = C.border
TopBarDiv.BorderSizePixel  = 0
TopBarDiv.Parent           = TopBar

-- Page container
local PageContainer = Instance.new("Frame")
PageContainer.Name             = "PageContainer"
PageContainer.Size             = UDim2.new(1, 0, 1, -BAR_H)
PageContainer.Position         = UDim2.new(0, 0, 0, BAR_H)
PageContainer.BackgroundTransparency = 1
PageContainer.BorderSizePixel  = 0
PageContainer.ClipsDescendants = true
PageContainer.Parent           = Content

-- ══════════════════════════════════════════
-- PAGE BUILDER
-- ══════════════════════════════════════════
local pages = {}

local function makePage(name)
    local pg = Instance.new("Frame")
    pg.Name             = "Page_" .. name
    pg.Size             = UDim2.new(1, 0, 1, 0)
    pg.BackgroundTransparency = 1
    pg.BorderSizePixel  = 0
    pg.Visible          = false
    pg.Parent           = PageContainer

    local colL = Instance.new("ScrollingFrame")
    colL.Name                  = "ColL"
    colL.Size                  = UDim2.new(0.5, -8, 1, -8)
    colL.Position              = UDim2.new(0, 10, 0, 6)
    colL.BackgroundTransparency = 1
    colL.BorderSizePixel       = 0
    colL.ScrollBarThickness    = 2
    colL.ScrollBarImageColor3  = C.border2
    colL.CanvasSize            = UDim2.new(0,0,0,0)
    colL.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    colL.ScrollingDirection    = Enum.ScrollingDirection.Y
    colL.Parent                = pg

    local llayout = Instance.new("UIListLayout")
    llayout.SortOrder = Enum.SortOrder.LayoutOrder
    llayout.Padding   = UDim.new(0, 3)
    llayout.Parent    = colL

    local colR = Instance.new("ScrollingFrame")
    colR.Name                  = "ColR"
    colR.Size                  = UDim2.new(0.5, -8, 1, -8)
    colR.Position              = UDim2.new(0.5, 4, 0, 6)
    colR.BackgroundTransparency = 1
    colR.BorderSizePixel       = 0
    colR.ScrollBarThickness    = 2
    colR.ScrollBarImageColor3  = C.border2
    colR.CanvasSize            = UDim2.new(0,0,0,0)
    colR.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    colR.ScrollingDirection    = Enum.ScrollingDirection.Y
    colR.Parent                = pg

    local rlayout = Instance.new("UIListLayout")
    rlayout.SortOrder = Enum.SortOrder.LayoutOrder
    rlayout.Padding   = UDim.new(0, 3)
    rlayout.Parent    = colR

    pages[name] = { frame = pg, left = colL, right = colR, lo = 0, ro = 0 }
    return pages[name]
end

-- ══════════════════════════════════════════
-- ROW COMPONENTS
-- ══════════════════════════════════════════

local function sectionHeader(col, text)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 26)
    f.BackgroundTransparency = 1
    f.BorderSizePixel  = 0
    f.Parent           = col

    local div = Instance.new("Frame")
    div.Size             = UDim2.new(1, 0, 0, 1)
    div.Position         = UDim2.new(0, 0, 1, -1)
    div.BackgroundColor3 = C.border
    div.BorderSizePixel  = 0
    div.Parent           = f

    label(f, {
        Position       = UDim2.new(0, 2, 0, 0),
        Size           = UDim2.new(1, -2, 1, -2),
        Text           = string.upper(text),
        TextColor3     = C.text3,
        TextSize       = 9,
        FontFace       = FONT_BOLD,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    return f
end

local function makePill(parent, defaultOn)
    local pill = Instance.new("Frame")
    pill.Size             = UDim2.new(0, PILL_W, 0, PILL_H)
    pill.AnchorPoint      = Vector2.new(1, 0.5)
    pill.Position         = UDim2.new(1, -4, 0.5, 0)
    pill.BackgroundColor3 = defaultOn and C.pill_on or C.pill_off
    pill.BorderSizePixel  = 0
    pill.ClipsDescendants = true
    pill.Parent           = parent
    corner(pill, 9)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, KNOB_SIZE, 0, KNOB_SIZE)
    knob.AnchorPoint      = Vector2.new(0, 0.5)
    knob.Position         = defaultOn
        and UDim2.new(0, PILL_W - KNOB_PAD - KNOB_SIZE, 0.5, 0)
        or  UDim2.new(0, KNOB_PAD, 0.5, 0)
    knob.BackgroundColor3 = defaultOn and C.knob_on or C.knob_off
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 2
    knob.Parent           = pill
    corner(knob, 6)

    return pill, knob
end

local function animatePill(pill, knob, state)
    tween(pill, {BackgroundColor3 = state and C.pill_on or C.pill_off})
    tween(knob, {
        BackgroundColor3 = state and C.knob_on or C.knob_off,
        Position = state
            and UDim2.new(0, PILL_W - KNOB_PAD - KNOB_SIZE, 0.5, 0)
            or  UDim2.new(0, KNOB_PAD, 0.5, 0)
    })
end

local function baseRow(col, height)
    local r = Instance.new("Frame")
    r.Size             = UDim2.new(1, 0, 0, height or 28)
    r.BackgroundColor3 = C.bg1
    r.BackgroundTransparency = 1
    r.BorderSizePixel  = 0
    r.Parent           = col
    corner(r, 4)

    r.MouseEnter:Connect(function()
        tween(r, {BackgroundTransparency = 0.85})
    end)
    r.MouseLeave:Connect(function()
        tween(r, {BackgroundTransparency = 1})
    end)

    return r
end

function UI.makeToggleRow(col, labelText, defaultOn, onToggle)
    local r = baseRow(col)
    label(r, {
        Position       = UDim2.new(0, 6, 0, 0),
        Size           = UDim2.new(0.7, 0, 1, 0),
        Text           = labelText,
        TextColor3     = C.text1,
        TextSize       = 12,
        FontFace       = FONT_REG,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local pill, knob = makePill(r, defaultOn)
    local state = defaultOn

    pill.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            animatePill(pill, knob, state)
            if onToggle then onToggle(state) end
        end
    end)
    return r
end

function UI.makeSubToggleRow(col, labelText, defaultOn, onToggle)
    local r = baseRow(col, 26)
    r.BackgroundColor3 = C.bg2
    r.BackgroundTransparency = 0.5

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 2, 0.6, 0)
    bar.Position         = UDim2.new(0, 0, 0.2, 0)
    bar.BackgroundColor3 = C.accent
    bar.BorderSizePixel  = 0
    bar.Parent           = r
    corner(bar, 1)

    label(r, {
        Position       = UDim2.new(0, 10, 0, 0),
        Size           = UDim2.new(0.65, 0, 1, 0),
        Text           = labelText,
        TextColor3     = C.text2,
        TextSize       = 11,
        FontFace       = FONT_REG,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local pill, knob = makePill(r, defaultOn)
    pill.Size = UDim2.new(0, 28, 0, 15)
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = defaultOn
        and UDim2.new(0, 28 - 2 - 10, 0.5, 0)
        or  UDim2.new(0, 2, 0.5, 0)

    local state = defaultOn

    pill.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            tween(pill, {BackgroundColor3 = state and C.pill_on or C.pill_off})
            tween(knob, {
                BackgroundColor3 = state and C.knob_on or C.knob_off,
                Position = state
                    and UDim2.new(0, 28 - 2 - 10, 0.5, 0)
                    or  UDim2.new(0, 2, 0.5, 0)
            })
            if onToggle then onToggle(state) end
        end
    end)
    return r
end

function UI.makeSliderRow(col, labelText, minVal, maxVal, defaultVal, onChanged)
    local r = baseRow(col, 42)

    label(r, {
        Position       = UDim2.new(0, 6, 0, 2),
        Size           = UDim2.new(0.55, 0, 0, 16),
        Text           = labelText,
        TextColor3     = C.text1,
        TextSize       = 11,
        FontFace       = FONT_REG,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local valLbl = label(r, {
        Position       = UDim2.new(0.55, 0, 0, 2),
        Size           = UDim2.new(0.4, 0, 0, 16),
        Text           = tostring(defaultVal),
        TextColor3     = C.accent2,
        TextSize       = 11,
        FontFace       = FONT_BOLD,
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    local trackBg = Instance.new("Frame")
    trackBg.BackgroundColor3 = C.bg4
    trackBg.BorderSizePixel  = 0
    trackBg.Position         = UDim2.new(0, 6, 1, -14)
    trackBg.Size             = UDim2.new(1, -10, 0, 4)
    trackBg.Parent           = r
    corner(trackBg, 2)

    local trackFill = Instance.new("Frame")
    trackFill.BackgroundColor3 = C.accent
    trackFill.BorderSizePixel  = 0
    trackFill.Size             = UDim2.new((defaultVal - minVal)/(maxVal - minVal), 0, 1, 0)
    trackFill.Parent           = trackBg
    corner(trackFill, 2)

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(1, C.accent2),
    }
    grad.Parent = trackFill

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel  = 0
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Size             = UDim2.new(0, 12, 0, 12)
    knob.Position         = UDim2.new((defaultVal - minVal)/(maxVal - minVal), 0, 0.5, 0)
    knob.ZIndex           = 3
    knob.Parent           = trackBg
    corner(knob, 6)

    local currentVal = defaultVal
    local dragging   = false

    local function update(x)
        local abs  = trackBg.AbsolutePosition.X
        local size = trackBg.AbsoluteSize.X
        local pct  = math.clamp((x - abs) / size, 0, 1)
        currentVal = math.floor(minVal + pct * (maxVal - minVal))
        trackFill.Size  = UDim2.new(pct, 0, 1, 0)
        knob.Position   = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text     = tostring(currentVal)
        if onChanged then onChanged(currentVal) end
    end

    trackBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            update(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return r, function() return currentVal end
end

function UI.makeDropdownRow(col, labelText, options, defaultIndex, onChanged)
    local ITEM_H   = 24
    local CLOSED_H = 28
    local OPEN_H   = CLOSED_H + (#options * ITEM_H) + 4

    local container = Instance.new("Frame")
    container.Size             = UDim2.new(1, 0, 0, CLOSED_H)
    container.BackgroundColor3 = C.bg1
    container.BackgroundTransparency = 1
    container.BorderSizePixel  = 0
    container.ClipsDescendants = true
    container.Parent           = col
    corner(container, 4)

    local header = Instance.new("Frame")
    header.Size             = UDim2.new(1, 0, 0, CLOSED_H)
    header.BackgroundTransparency = 1
    header.BorderSizePixel  = 0
    header.Parent           = container

    header.MouseEnter:Connect(function()
        tween(header, {BackgroundTransparency = 0.85})
        header.BackgroundColor3 = C.bg2
    end)
    header.MouseLeave:Connect(function()
        tween(header, {BackgroundTransparency = 1})
    end)

    label(header, {
        Position       = UDim2.new(0, 6, 0, 0),
        Size           = UDim2.new(0.5, 0, 1, 0),
        Text           = labelText,
        TextColor3     = C.text1,
        TextSize       = 12,
        FontFace       = FONT_REG,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local selected = defaultIndex or 1
    local open     = false

    local selBtn = Instance.new("TextButton")
    selBtn.Size             = UDim2.new(0, 100, 0, 20)
    selBtn.AnchorPoint      = Vector2.new(1, 0.5)
    selBtn.Position         = UDim2.new(1, -4, 0.5, 0)
    selBtn.BackgroundColor3 = C.bg3
    selBtn.BorderSizePixel  = 0
    selBtn.Text             = options[selected] .. "  ▾"
    selBtn.TextColor3       = C.text0
    selBtn.TextSize         = 11
    selBtn.FontFace         = FONT_MED
    selBtn.ZIndex           = 2
    selBtn.Parent           = header
    corner(selBtn, 4)
    stroke(selBtn, C.border2)

    selBtn.MouseEnter:Connect(function() tween(selBtn, {BackgroundColor3 = C.bg4}) end)
    selBtn.MouseLeave:Connect(function() tween(selBtn, {BackgroundColor3 = C.bg3}) end)

    local listFrame = Instance.new("Frame")
    listFrame.Size             = UDim2.new(1, 0, 0, #options * ITEM_H + 4)
    listFrame.Position         = UDim2.new(0, 0, 0, CLOSED_H)
    listFrame.BackgroundColor3 = C.bg3
    listFrame.BorderSizePixel  = 0
    listFrame.ZIndex           = 4
    listFrame.Parent           = container
    corner(listFrame, 4)
    stroke(listFrame, C.border2)

    local llayout = Instance.new("UIListLayout")
    llayout.SortOrder = Enum.SortOrder.LayoutOrder
    llayout.Padding   = UDim.new(0, 0)
    llayout.Parent    = listFrame

    local lpad = Instance.new("UIPadding")
    lpad.PaddingTop    = UDim.new(0, 2)
    lpad.PaddingBottom = UDim.new(0, 2)
    lpad.Parent        = listFrame

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size             = UDim2.new(1, 0, 0, ITEM_H)
        optBtn.BackgroundColor3 = C.bg3
        optBtn.BackgroundTransparency = 1
        optBtn.BorderSizePixel  = 0
        optBtn.Text             = opt
        optBtn.TextColor3       = (i == selected) and C.accent2 or C.text1
        optBtn.TextSize         = 11
        optBtn.FontFace         = (i == selected) and FONT_BOLD or FONT_REG
        optBtn.ZIndex           = 5
        optBtn.Parent           = listFrame

        optBtn.MouseEnter:Connect(function()
            tween(optBtn, {BackgroundTransparency = 0.7, TextColor3 = C.text0})
            optBtn.BackgroundColor3 = C.bg4
        end)
        optBtn.MouseLeave:Connect(function()
            tween(optBtn, {BackgroundTransparency = 1, TextColor3 = (i == selected) and C.accent2 or C.text1})
        end)

        optBtn.MouseButton1Click:Connect(function()
            for _, child in ipairs(listFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextColor3 = C.text1
                    child.FontFace   = FONT_REG
                end
            end
            selected          = i
            optBtn.TextColor3 = C.accent2
            optBtn.FontFace   = FONT_BOLD
            selBtn.Text       = opt .. "  ▾"
            open              = false
            TweenService:Create(container, TW_FAST, {Size = UDim2.new(1, 0, 0, CLOSED_H)}):Play()
            if onChanged then onChanged(opt) end
        end)
    end

    selBtn.MouseButton1Click:Connect(function()
        open = not open
        local targetH = open and OPEN_H or CLOSED_H
        TweenService:Create(container, TW_MED, {Size = UDim2.new(1, 0, 0, targetH)}):Play()
        selBtn.Text = options[selected] .. (open and "  ▴" or "  ▾")
    end)

    return container
end

function UI.makeInputRow(col, labelText, placeholder)
    local r = baseRow(col, 40)

    label(r, {
        Position       = UDim2.new(0, 6, 0, 2),
        Size           = UDim2.new(1, -8, 0, 14),
        Text           = labelText,
        TextColor3     = C.text2,
        TextSize       = 10,
        FontFace       = FONT_REG,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local box = Instance.new("TextBox")
    box.BackgroundColor3  = C.bg3
    box.BorderSizePixel   = 0
    box.Position          = UDim2.new(0, 6, 0, 18)
    box.Size              = UDim2.new(1, -10, 0, 18)
    box.Text              = ""
    box.PlaceholderText   = placeholder or "..."
    box.PlaceholderColor3 = C.text3
    box.TextColor3        = C.accent2
    box.TextSize          = 11
    box.ClearTextOnFocus  = false
    box.FontFace          = FONT_REG
    box.Parent            = r
    corner(box, 4)

    local bStroke = stroke(box, C.border, 1)
    box.Focused:Connect(function()   tween(bStroke, {Color = C.accent}) end)
    box.FocusLost:Connect(function() tween(bStroke, {Color = C.border}) end)

    return r, function() return box.Text end
end

function UI.makeActionBtn(col, text, color)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = color or C.accent
    btn.BorderSizePixel  = 0
    btn.Text             = text
    btn.TextColor3       = Color3.new(1,1,1)
    btn.TextSize         = 12
    btn.FontFace         = FONT_BOLD
    btn.Parent           = col
    corner(btn, 5)

    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = (color or C.accent):lerp(Color3.new(1,1,1), 0.1)})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = color or C.accent})
    end)
    btn.MouseButton1Down:Connect(function()
        tween(btn, {BackgroundColor3 = (color or C.accent):lerp(Color3.new(0,0,0), 0.15)})
    end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, {BackgroundColor3 = color or C.accent})
    end)

    return btn
end

function UI.makeStatusLabel(col)
    local r = frame(col, {
        Size = UDim2.new(1, 0, 0, 20),
    })
    local lbl = label(r, {
        Position       = UDim2.new(0, 6, 0, 0),
        Size           = UDim2.new(1, -6, 1, 0),
        Text           = "Status: Idle",
        TextColor3     = C.text2,
        TextSize       = 10,
        FontFace       = FONT_REG,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    return lbl
end

function UI.makeSectionLabel(col, text)
    return sectionHeader(col, text)
end

function UI.makeSpacer(col, height)
    local f = frame(col, {Size = UDim2.new(1, 0, 0, height or 4)})
    return f
end

-- Color picker row (opens a TextBox for hex input + colored swatch)
function UI.makeColorPickerRow(col, labelText, defaultColor, onChanged)
    local r = baseRow(col, 32)

    label(r, {
        Position       = UDim2.new(0, 6, 0, 0),
        Size           = UDim2.new(0.5, 0, 1, 0),
        Text           = labelText,
        TextColor3     = C.text1,
        TextSize       = 12,
        FontFace       = FONT_REG,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- Colour swatch
    local swatch = Instance.new("Frame")
    swatch.Size             = UDim2.new(0, 18, 0, 18)
    swatch.AnchorPoint      = Vector2.new(1, 0.5)
    swatch.Position         = UDim2.new(1, -4, 0.5, 0)
    swatch.BackgroundColor3 = defaultColor or C.accent
    swatch.BorderSizePixel  = 0
    swatch.Parent           = r
    corner(swatch, 4)
    stroke(swatch, C.border2, 1)

    -- Hex input box
    local function color3ToHex(c3)
        return string.format("%02X%02X%02X",
            math.floor(c3.R * 255),
            math.floor(c3.G * 255),
            math.floor(c3.B * 255))
    end

    local function hexToColor3(hex)
        hex = hex:gsub("#", "")
        if #hex ~= 6 then return nil end
        local r2 = tonumber(hex:sub(1,2), 16)
        local g2 = tonumber(hex:sub(3,4), 16)
        local b2 = tonumber(hex:sub(5,6), 16)
        if not (r2 and g2 and b2) then return nil end
        return Color3.fromRGB(r2, g2, b2)
    end

    local box = Instance.new("TextBox")
    box.Size             = UDim2.new(0, 72, 0, 20)
    box.AnchorPoint      = Vector2.new(1, 0.5)
    box.Position         = UDim2.new(1, -28, 0.5, 0)
    box.BackgroundColor3 = C.bg3
    box.BorderSizePixel  = 0
    box.Text             = "#" .. color3ToHex(defaultColor or C.accent)
    box.PlaceholderText  = "#RRGGBB"
    box.PlaceholderColor3 = C.text3
    box.TextColor3       = C.accent2
    box.TextSize         = 11
    box.FontFace         = FONT_REG
    box.ClearTextOnFocus = false
    box.Parent           = r
    corner(box, 4)
    local bStroke = stroke(box, C.border, 1)

    box.Focused:Connect(function()   tween(bStroke, {Color = C.accent}) end)
    box.FocusLost:Connect(function()
        tween(bStroke, {Color = C.border})
        local col2 = hexToColor3(box.Text)
        if col2 then
            swatch.BackgroundColor3 = col2
            box.Text = "#" .. color3ToHex(col2)
            if onChanged then onChanged(col2) end
        else
            box.Text = "#" .. color3ToHex(swatch.BackgroundColor3)
        end
    end)

    return r, function() return swatch.BackgroundColor3 end
end

-- Dropdown row variant that returns index too
function UI.makeValueDropdownRow(col, labelText, options, defaultIndex, onChanged)
    return UI.makeDropdownRow(col, labelText, options, defaultIndex, onChanged)
end

-- ══════════════════════════════════════════
-- PAGE BUILDER PUBLIC API
-- ══════════════════════════════════════════
function UI.makePage(name)
    return makePage(name)
end

function UI.getCol(pageName, side)
    local pg = pages[pageName]
    if not pg then return nil end
    return side == "right" and pg.right or pg.left
end

-- ══════════════════════════════════════════
-- TAB SWITCHER
-- ══════════════════════════════════════════
local currentPage = nil

function UI.switchTo(pageName)
    for _, pg in pairs(pages) do
        pg.frame.Visible = false
    end
    local pg = pages[pageName]
    if pg then pg.frame.Visible = true end
    currentPage = pageName

    for _, item in ipairs(navItems) do
        local active = (item.page == pageName)
        item.bar.Visible = active
        tween(item.lbl, {TextColor3 = active and C.accent2 or C.text1})
        tween(item.btn, {BackgroundTransparency = active and 0.7 or 1})
        if active then item.btn.BackgroundColor3 = C.pill_on end
    end
end

function UI.setupNavigation()
    for _, item in ipairs(navItems) do
        item.btn.MouseButton1Click:Connect(function()
            UI.switchTo(item.page)
        end)
        item.btn.MouseEnter:Connect(function()
            if currentPage ~= item.page then
                tween(item.btn, {BackgroundTransparency = 0.85})
                item.btn.BackgroundColor3 = C.bg3
            end
        end)
        item.btn.MouseLeave:Connect(function()
            if currentPage ~= item.page then
                tween(item.btn, {BackgroundTransparency = 1})
            end
        end)
    end
end

-- ══════════════════════════════════════════
-- MINIMIZE  (collapse to title bar)
-- ══════════════════════════════════════════
local function setMinimized(state)
    minimized = state
    if state then
        -- Collapse panel to just the bar height, hide body content
        TweenService:Create(Panel, TW_MED, {
            Size = UDim2.new(0, PANEL_W, 0, BAR_H)
        }):Play()
        -- Hide sidebar content below brand header
        Sidebar.Visible    = false
        PageContainer.Visible = false
        TopBarDiv.Visible  = false
        MinTitle.Visible   = true
        ConfigBtn.Visible  = false
        -- Change min button to restore symbol
        MinBtn.Text = "□"
    else
        -- Restore full size
        TweenService:Create(Panel, TW_MED, {
            Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
        }):Play()
        Sidebar.Visible    = true
        PageContainer.Visible = true
        TopBarDiv.Visible  = true
        MinTitle.Visible   = false
        ConfigBtn.Visible  = true
        MinBtn.Text = "—"
    end
end

-- ══════════════════════════════════════════
-- DRAGGABLE
-- ══════════════════════════════════════════
function UI.setupDrag()
    local dragging, dragStart, startPos, dragInput

    local function startDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = Panel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end

    -- Drag from topbar (works both minimized and expanded)
    TopBar.InputBegan:Connect(startDrag)
    BrandHeader.InputBegan:Connect(startDrag)

    TopBar.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement then dragInput = inp end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if inp == dragInput and dragging then
            local delta = inp.Position - dragStart
            Panel.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ══════════════════════════════════════════
-- WINDOW CONTROLS
-- ══════════════════════════════════════════
function UI.setupWindowControls(onClose)
    -- Close
    CloseBtn.MouseButton1Click:Connect(function()
        if onClose then pcall(onClose) end
        TweenService:Create(Panel, TweenInfo.new(0.18), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
        }):Play()
        task.delay(0.25, function() ScreenGui:Destroy() end)
    end)

    -- Minimize: collapse to draggable title bar
    MinBtn.MouseButton1Click:Connect(function()
        setMinimized(not minimized)
    end)

    -- Double-click title bar to restore when minimized
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and minimized then
            setMinimized(false)
        end
    end)

    -- Keybind: ] to toggle visibility (both minimized and hidden states)
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Enum.KeyCode.RightBracket then
            if minimized then
                setMinimized(false)
            else
                Panel.Visible = not Panel.Visible
            end
        end
    end)
end

-- ══════════════════════════════════════════
-- TOAST NOTIFICATIONS
-- ══════════════════════════════════════════
local ToastContainer = Instance.new("Frame")
ToastContainer.Name                 = "ToastContainer"
ToastContainer.BackgroundTransparency = 1
ToastContainer.BorderSizePixel      = 0
ToastContainer.AnchorPoint          = Vector2.new(1, 1)
ToastContainer.Position             = UDim2.new(1, -14, 1, -14)
ToastContainer.Size                 = UDim2.new(0, 210, 1, -14)
ToastContainer.Parent               = ScreenGui

local ToastLayout = Instance.new("UIListLayout")
ToastLayout.SortOrder        = Enum.SortOrder.LayoutOrder
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ToastLayout.Padding          = UDim.new(0, 5)
ToastLayout.Parent           = ToastContainer

function UI.toast(featureName, state)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 38)
    f.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    f.BackgroundTransparency = 0.1
    f.BorderSizePixel  = 0
    f.LayoutOrder      = -os.clock()
    f.Parent           = ToastContainer
    corner(f, 6)
    stroke(f, C.border2)

    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = state and C.green or C.red
    accent.BorderSizePixel  = 0
    accent.Size             = UDim2.new(0, 3, 0.7, 0)
    accent.Position         = UDim2.new(0, 4, 0.15, 0)
    accent.Parent           = f
    corner(accent, 2)

    label(f, {
        Position       = UDim2.new(0, 14, 0, 4),
        Size           = UDim2.new(1, -18, 0, 16),
        Text           = featureName,
        TextColor3     = C.text0,
        TextSize       = 11,
        FontFace       = FONT_BOLD,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    label(f, {
        Position       = UDim2.new(0, 14, 0, 20),
        Size           = UDim2.new(1, -18, 0, 14),
        Text           = state and "Enabled" or "Disabled",
        TextColor3     = state and C.green or C.red,
        TextSize       = 10,
        FontFace       = FONT_REG,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    f.BackgroundTransparency = 1
    tween(f, {BackgroundTransparency = 0.1}, TW_MED)

    task.delay(2.5, function()
        tween(f, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)}, TW_FAST)
        task.delay(0.2, function() f:Destroy() end)
    end)
end

-- ══════════════════════════════════════════
-- MOUNT
-- ══════════════════════════════════════════
function UI.mount()
    ScreenGui.Parent = PlayerGui
end

return UI
