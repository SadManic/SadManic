-- =====================
-- MODULE: Crosshair
-- Drawing-based crosshair with full config
-- =====================
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local Crosshair = {}

-- ── Default config ─────────────────────────────────────────
Crosshair.Enabled       = false
Crosshair.Style         = "cross"   -- "cross" | "circle" | "dot" | "cross+circle" | "t"
Crosshair.Length        = 10
Crosshair.Thickness     = 2
Crosshair.Gap           = 4
Crosshair.DotSize       = 0
Crosshair.Opacity       = 1.0       -- 0.0 – 1.0
Crosshair.OutlineWidth  = 1
Crosshair.Color         = Color3.fromRGB(0, 255, 136)
Crosshair.OutlineColor  = Color3.fromRGB(0, 0, 0)
Crosshair.ShowTop       = true
Crosshair.ShowBottom    = true
Crosshair.ShowLeft      = true
Crosshair.ShowRight     = true
Crosshair.Dynamic       = false     -- expands on movement

-- ── Internal state ─────────────────────────────────────────
local drawings   = {}
local renderConn = nil
local dynExpand  = 0   -- current dynamic spread offset

-- ── Drawing helpers ────────────────────────────────────────
local function newLine()
    local l = Drawing.new("Line")
    l.Visible   = false
    l.ZIndex    = 5
    l.Thickness = 1
    l.Color     = Color3.new(1,1,1)
    return l
end

local function newCircle()
    local c = Drawing.new("Circle")
    c.Visible   = false
    c.ZIndex    = 5
    c.Thickness = 1
    c.Filled    = false
    c.Color     = Color3.new(1,1,1)
    c.NumSides  = 64
    return c
end

local function newDot()
    local d = Drawing.new("Circle")
    d.Visible  = false
    d.ZIndex   = 5
    d.Thickness = 1
    d.Filled   = true
    d.Color    = Color3.new(1,1,1)
    d.NumSides = 32
    return d
end

local function destroyAll()
    for _, d in ipairs(drawings) do
        pcall(function() d:Remove() end)
    end
    drawings = {}
end

-- ── Allocate all drawing objects ───────────────────────────
-- We pre-create all possible objects and show/hide per style
-- to avoid per-frame allocation.
--
-- Slots:
--   [1]  outline top     (Line)
--   [2]  outline bottom  (Line)
--   [3]  outline left    (Line)
--   [4]  outline right   (Line)
--   [5]  fill top        (Line)
--   [6]  fill bottom     (Line)
--   [7]  fill left       (Line)
--   [8]  fill right      (Line)
--   [9]  outline circle  (Circle)
--   [10] fill circle     (Circle)
--   [11] outline dot     (Circle)
--   [12] fill dot        (Circle)

local function allocate()
    destroyAll()
    for i = 1, 8  do drawings[i]  = newLine()   end
    for i = 9, 10 do drawings[i]  = newCircle() end
    for i = 11,12 do drawings[i]  = newDot()    end
end

-- ── Colour helpers ─────────────────────────────────────────
local function c3(color3)
    return color3
end

-- ── Render ─────────────────────────────────────────────────
local function render()
    if not Crosshair.Enabled then
        for _, d in ipairs(drawings) do d.Visible = false end
        return
    end

    local cursor = UserInputService:GetMouseLocation()
    local cx, cy = cursor.X, cursor.Y

    local len   = Crosshair.Length
    local thick = Crosshair.Thickness
    local gap   = Crosshair.Gap + dynExpand
    local col   = c3(Crosshair.Color)
    local ocol  = c3(Crosshair.OutlineColor)
    local ow    = Crosshair.OutlineWidth
    local alpha = Crosshair.Opacity
    local style = Crosshair.Style
    local dotR  = Crosshair.DotSize

    -- Dynamic expansion: lerp toward velocity-based spread
    if Crosshair.Dynamic then
        local vel   = UserInputService:GetMouseDelta()
        local speed = math.clamp(vel.Magnitude * 0.3, 0, 12)
        dynExpand   = dynExpand + (speed - dynExpand) * 0.25
    else
        dynExpand = 0
    end

    -- Helper: set a line's properties
    local function setLine(idx, x1, y1, x2, y2, isOutline)
        local l = drawings[idx]
        l.From      = Vector2.new(x1, y1)
        l.To        = Vector2.new(x2, y2)
        l.Thickness = isOutline and (thick + ow * 2) or thick
        l.Color     = isOutline and ocol or col
        l.Transparency = 1 - alpha
        l.Visible   = true
    end

    local function hideLine(idx)
        drawings[idx].Visible = false
    end

    -- Determine which arms to draw
    local showTop   = Crosshair.ShowTop    and (style == "cross" or style == "cross+circle" or style == "t")
    local showBot   = Crosshair.ShowBottom and (style == "cross" or style == "cross+circle")
    local showLeft  = Crosshair.ShowLeft   and (style == "cross" or style == "cross+circle" or style == "t")
    local showRight = Crosshair.ShowRight  and (style == "cross" or style == "cross+circle" or style == "t")

    -- Cross arms
    if ow > 0 then
        if showTop    then setLine(1, cx, cy - gap,       cx, cy - gap - len,   true) else hideLine(1) end
        if showBot    then setLine(2, cx, cy + gap,       cx, cy + gap + len,   true) else hideLine(2) end
        if showLeft   then setLine(3, cx - gap, cy,       cx - gap - len, cy,   true) else hideLine(3) end
        if showRight  then setLine(4, cx + gap, cy,       cx + gap + len, cy,   true) else hideLine(4) end
    else
        for i = 1, 4 do hideLine(i) end
    end

    if showTop    then setLine(5, cx, cy - gap,       cx, cy - gap - len,   false) else hideLine(5) end
    if showBot    then setLine(6, cx, cy + gap,       cx, cy + gap + len,   false) else hideLine(6) end
    if showLeft   then setLine(7, cx - gap, cy,       cx - gap - len, cy,   false) else hideLine(7) end
    if showRight  then setLine(8, cx + gap, cy,       cx + gap + len, cy,   false) else hideLine(8) end

    -- Circle
    local showCircle = (style == "circle" or style == "cross+circle")
    local circR = gap + len * 0.6

    if showCircle and ow > 0 then
        local oc = drawings[9]
        oc.Position    = Vector2.new(cx, cy)
        oc.Radius      = circR
        oc.Thickness   = thick + ow * 2
        oc.Color       = ocol
        oc.Transparency = 1 - alpha
        oc.Visible     = true
    else
        drawings[9].Visible = false
    end

    if showCircle then
        local fc = drawings[10]
        fc.Position    = Vector2.new(cx, cy)
        fc.Radius      = circR
        fc.Thickness   = thick
        fc.Color       = col
        fc.Transparency = 1 - alpha
        fc.Visible     = true
    else
        drawings[10].Visible = false
    end

    -- Dot
    local showDot = dotR > 0
    if showDot and ow > 0 then
        local od = drawings[11]
        od.Position    = Vector2.new(cx, cy)
        od.Radius      = dotR + ow
        od.Color       = ocol
        od.Transparency = 1 - alpha
        od.Visible     = true
    else
        drawings[11].Visible = false
    end

    if showDot then
        local fd = drawings[12]
        fd.Position    = Vector2.new(cx, cy)
        fd.Radius      = dotR
        fd.Color       = col
        fd.Transparency = 1 - alpha
        fd.Visible     = true
    else
        drawings[12].Visible = false
    end
end

-- ── Public API ─────────────────────────────────────────────
function Crosshair:SetEnabled(state)
    self.Enabled = state
    if not state then
        for _, d in ipairs(drawings) do d.Visible = false end
    end
end

function Crosshair:ApplyConfig(cfg)
    for k, v in pairs(cfg) do
        self[k] = v
    end
end

function Crosshair:Init()
    allocate()
    renderConn = RunService:BindToRenderStep(
        "CrosshairRender",
        Enum.RenderPriority.Camera.Value + 2,
        render
    )
end

function Crosshair:Destroy()
    if renderConn then
        RunService:UnbindFromRenderStep("CrosshairRender")
        renderConn = nil
    end
    destroyAll()
end

return Crosshair
