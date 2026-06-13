-- =====================
-- MAIN: ChrisM Hub
-- =====================
local BASE         = "https://raw.githubusercontent.com/jaikinpicio-bot/ChrisM/main/"
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local CoreGui      = game:GetService("CoreGui")
local Players      = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui", 30)

-- Added Crosshair.lua explicitly to the tracking array so it's managed cleanly
local MODULES = {
    "Crosshair.lua", "Aimbot.lua", "ESP.lua", "Fullbright.lua",
    "Teleport.lua", "ItemESP.lua", "EventESP.lua", "UI.lua"
}

-- Shared progress state written by loader, read by both animations
local loadProgress = {
    done    = 0,
    total   = #MODULES,
    current = "",
    allDone = false,
}

-- ══════════════════════════════════════════
-- IN-GAME LOADING SCREEN
-- Full-screen overlay, appears before anything else
-- ══════════════════════════════════════════
local LoadGui = Instance.new("ScreenGui")
LoadGui.Name            = "ChrisMLoadScreen"
LoadGui.DisplayOrder    = 999
LoadGui.ResetOnSpawn    = false
LoadGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
LoadGui.IgnoreGuiInset  = true  -- stretch to true top-left, no topbar gap
LoadGui.Parent          = PlayerGui

-- Dark full-screen backdrop
local Backdrop = Instance.new("Frame")
Backdrop.Name             = "Backdrop"
Backdrop.Size             = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
Backdrop.BorderSizePixel  = 0
Backdrop.Parent           = LoadGui

-- Subtle grid pattern overlay (thin lines)
local GridOverlay = Instance.new("Frame")
GridOverlay.Size             = UDim2.new(1, 0, 1, 0)
GridOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GridOverlay.BackgroundTransparency = 0.97
GridOverlay.BorderSizePixel  = 0
GridOverlay.Parent           = Backdrop

-- Center card
local Card = Instance.new("Frame")
Card.Name             = "Card"
Card.Size             = UDim2.new(0, 360, 0, 220)
Card.AnchorPoint      = Vector2.new(0.5, 0.5)
Card.Position         = UDim2.new(0.5, 0, 0.5, 0)
Card.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Card.BorderSizePixel  = 0
Card.Parent           = Backdrop
local _cc = Instance.new("UICorner"); _cc.CornerRadius = UDim.new(0, 14); _cc.Parent = Card
local _cs = Instance.new("UIStroke")
_cs.Color     = Color3.fromRGB(60, 80, 160)
_cs.Thickness = 1
_cs.Parent    = Card

-- Logo badge
local LogoBadge = Instance.new("Frame")
LogoBadge.Size             = UDim2.new(0, 48, 0, 48)
LogoBadge.AnchorPoint      = Vector2.new(0.5, 0)
LogoBadge.Position         = UDim2.new(0.5, 0, 0, 28)
LogoBadge.BackgroundColor3 = Color3.fromRGB(70, 110, 210)
LogoBadge.BorderSizePixel  = 0
LogoBadge.Parent           = Card
local _lbc = Instance.new("UICorner"); _lbc.CornerRadius = UDim.new(0, 12); _lbc.Parent = LogoBadge

local LogoText = Instance.new("TextLabel")
LogoText.Size             = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text             = "CM"
LogoText.TextColor3       = Color3.new(1, 1, 1)
LogoText.TextSize         = 18
LogoText.Font             = Enum.Font.GothamBold
LogoText.Parent           = LogoBadge

-- Title
local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size             = UDim2.new(1, -32, 0, 22)
TitleLbl.AnchorPoint      = Vector2.new(0.5, 0)
TitleLbl.Position         = UDim2.new(0.5, 0, 0, 86)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text             = "ChrisM Hub"
TitleLbl.TextColor3       = Color3.fromRGB(235, 235, 245)
TitleLbl.TextSize         = 20
TitleLbl.Font             = Enum.Font.GothamBold
TitleLbl.Parent           = Card

-- Subtitle / current module
local SubLbl = Instance.new("TextLabel")
SubLbl.Size             = UDim2.new(1, -32, 0, 16)
SubLbl.AnchorPoint      = Vector2.new(0.5, 0)
SubLbl.Position         = UDim2.new(0.5, 0, 0, 112)
SubLbl.BackgroundTransparency = 1
SubLbl.Text             = "Initialising..."
SubLbl.TextColor3       = Color3.fromRGB(90, 110, 180)
SubLbl.TextSize         = 12
SubLbl.Font             = Enum.Font.Gotham
SubLbl.Parent           = Card

-- Progress track background
local TrackBg = Instance.new("Frame")
TrackBg.Size             = UDim2.new(1, -48, 0, 4)
TrackBg.AnchorPoint      = Vector2.new(0.5, 0)
TrackBg.Position         = UDim2.new(0.5, 0, 0, 144)
TrackBg.BackgroundColor3 = Color3.fromRGB(30, 32, 48)
TrackBg.BorderSizePixel  = 0
TrackBg.ClipsDescendants = true
TrackBg.Parent           = Card
local _tbc = Instance.new("UICorner"); _tbc.CornerRadius = UDim.new(0, 2); _tbc.Parent = TrackBg

-- Progress fill
local TrackFill = Instance.new("Frame")
TrackFill.Size             = UDim2.new(0, 0, 1, 0)
TrackFill.BackgroundColor3 = Color3.fromRGB(80, 120, 220)
TrackFill.BorderSizePixel  = 0
TrackFill.Parent           = TrackBg
local _tfc = Instance.new("UICorner"); _tfc.CornerRadius = UDim.new(0, 2); _tfc.Parent = TrackFill

-- Step dots row
local DotsFrame = Instance.new("Frame")
DotsFrame.Size             = UDim2.new(1, -48, 0, 10)
DotsFrame.AnchorPoint      = Vector2.new(0.5, 0)
DotsFrame.Position         = UDim2.new(0.5, 0, 0, 156)
DotsFrame.BackgroundTransparency = 1
DotsFrame.BorderSizePixel  = 0
DotsFrame.Parent           = Card

local DotsLayout = Instance.new("UIListLayout")
DotsLayout.FillDirection  = Enum.FillDirection.Horizontal
DotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
DotsLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
DotsLayout.Padding        = UDim.new(0, 7)
DotsLayout.Parent         = DotsFrame

-- One dot per module
local dots = {}
for i = 1, #MODULES do
    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0, 6, 0, 6)
    dot.BackgroundColor3 = Color3.fromRGB(35, 38, 60)
    dot.BorderSizePixel  = 0
    dot.Parent           = DotsFrame
    local _dc = Instance.new("UICorner"); _dc.CornerRadius = UDim.new(0, 3); _dc.Parent = dot
    dots[i] = dot
end

-- Module name chips row
local NamesFrame = Instance.new("Frame")
NamesFrame.Size             = UDim2.new(1, -32, 0, 18)
NamesFrame.AnchorPoint      = Vector2.new(0.5, 0)
NamesFrame.Position         = UDim2.new(0.5, 0, 0, 176)
NamesFrame.BackgroundTransparency = 1
NamesFrame.BorderSizePixel  = 0
NamesFrame.Parent           = Card

local NamesLayout = Instance.new("UIListLayout")
NamesLayout.FillDirection  = Enum.FillDirection.Horizontal
NamesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
NamesLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
NamesLayout.Padding        = UDim.new(0, 4)
NamesLayout.Parent         = NamesFrame

local moduleChips = {}
for i, mod in ipairs(MODULES) do
    local name = mod:gsub("%.lua$", "")
    local chip = Instance.new("TextLabel")
    chip.Size             = UDim2.new(0, 0, 1, 0)
    chip.AutomaticSize    = Enum.AutomaticSize.X
    chip.BackgroundColor3 = Color3.fromRGB(22, 24, 38)
    chip.BackgroundTransparency = 0
    chip.BorderSizePixel  = 0
    chip.Text             = name
    chip.TextColor3       = Color3.fromRGB(50, 55, 90)
    chip.TextSize         = 9
    chip.Font             = Enum.Font.GothamBold
    chip.Parent           = NamesFrame
    local _cc2 = Instance.new("UICorner"); _cc2.CornerRadius = UDim.new(0, 4); _cc2.Parent = chip
    local _cp  = Instance.new("UIPadding")
    _cp.PaddingLeft  = UDim.new(0, 5); _cp.PaddingRight  = UDim.new(0, 5)
    _cp.PaddingTop   = UDim.new(0, 2); _cp.PaddingBottom = UDim.new(0, 2)
    _cp.Parent = chip
    moduleChips[i] = chip
end

-- Version / branding footer
local FooterLbl = Instance.new("TextLabel")
FooterLbl.Size             = UDim2.new(1, -32, 0, 14)
FooterLbl.AnchorPoint      = Vector2.new(0.5, 1)
FooterLbl.Position         = UDim2.new(0.5, 0, 1, -10)
FooterLbl.BackgroundTransparency = 1
FooterLbl.Text             = "Apocalypse Rising 2  •  v1.0"
FooterLbl.TextColor3       = Color3.fromRGB(45, 48, 75)
FooterLbl.TextSize         = 10
FooterLbl.Font             = Enum.Font.Gotham
FooterLbl.Parent           = Card

-- Animate progress bar and dots as modules load
local screenConn
screenConn = RunService.Heartbeat:Connect(function()
    local pct = loadProgress.done / loadProgress.total

    -- Smooth fill tween target
    TweenService:Create(TrackFill, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
        Size = UDim2.new(pct, 0, 1, 0)
    }):Play()

    -- Update subtitle
    if loadProgress.allDone then
        SubLbl.Text      = "Ready"
        SubLbl.TextColor3 = Color3.fromRGB(50, 195, 100)
    elseif loadProgress.current ~= "" then
        SubLbl.Text = "Loading  " .. loadProgress.current .. "..."
    end

    -- Light up dots and chips for completed modules
    for i = 1, #MODULES do
        if i <= loadProgress.done then
            TweenService:Create(dots[i], TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(80, 120, 220)
            }):Play()
            moduleChips[i].TextColor3 = Color3.fromRGB(110, 155, 255)
        end
        -- Pulse the currently-loading one
        if i == loadProgress.done + 1 then
            local pulse = math.abs(math.sin(os.clock() * 4))
            dots[i].BackgroundColor3 = Color3.fromRGB(
                math.floor(50 + pulse * 60),
                math.floor(60 + pulse * 80),
                math.floor(120 + pulse * 100)
            )
            moduleChips[i].TextColor3 = Color3.fromRGB(
                math.floor(60 + pulse * 80),
                math.floor(70 + pulse * 90),
                math.floor(140 + pulse * 100)
            )
        end
    end
end)

-- Dismiss: fade out after all loaded + brief hold
local function dismissLoadScreen()
    screenConn:Disconnect()
    task.wait(0.6) -- brief "Ready" moment
    TweenService:Create(Backdrop, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {
        BackgroundTransparency = 1
    }):Play()
    TweenService:Create(Card, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, -12),
    }):Play()
    task.wait(0.55)
    LoadGui:Destroy()
end

-- ══════════════════════════════════════════
-- DEV CONSOLE LOADER 
-- ══════════════════════════════════════════
local ANIM_SPEED   = 7
local COLOR_DIM    = "2a2a3a"
local COLOR_BRIGHT = "6e9bff"
local COLOR_WHITE  = "eeeef5"

local function findClientLogFrame()
    local master = CoreGui:FindFirstChild("DevConsoleMaster")
    if not master then return nil end
    for _, d in ipairs(master:GetDescendants()) do
        if d:IsA("ScrollingFrame") and d.Name == "ClientLog" then return d end
    end
    return nil
end

local logFrame = findClientLogFrame()
if not logFrame then
    repeat task.wait(0.3); logFrame = findClientLogFrame() until logFrame
end

if logFrame:FindFirstChild("ChrisMLoader") then
    logFrame.ChrisMLoader:Destroy()
end

local loaderLabel = Instance.new("TextLabel")
loaderLabel.Name               = "ChrisMLoader"
loaderLabel.Size               = UDim2.new(1, 0, 0, 44)
loaderLabel.BackgroundTransparency = 1
loaderLabel.TextColor3         = Color3.fromRGB(255,255,255)
loaderLabel.TextXAlignment     = Enum.TextXAlignment.Center
loaderLabel.Font               = Enum.Font.Code
loaderLabel.TextSize           = 20
loaderLabel.RichText           = true
loaderLabel.LayoutOrder        = -999
loaderLabel.Parent             = logFrame

local loaderConn
loaderConn = RunService.RenderStepped:Connect(function()
    local t    = os.clock() * ANIM_SPEED
    local word = "ChrisM"

    local animated = ""
    for i = 1, #word do
        local wave = math.sin(t - i * 0.75)
        local hex  = wave > 0.3 and COLOR_WHITE or (wave > -0.2 and COLOR_BRIGHT or COLOR_DIM)
        animated = animated .. string.format('<font color="#%s">%s</font>', hex, word:sub(i,i))
    end

    local BAR_W  = 20
    local filled = math.floor((loadProgress.done / loadProgress.total) * BAR_W)
    local bar    = '<font color="#6e9bff">' .. string.rep("█", filled) .. '</font>'
              .. '<font color="#2a2a3a">' .. string.rep("█", BAR_W - filled) .. '</font>'

    local statusColor = loadProgress.allDone and "00e676" or "6e9bff"
    local statusText  = loadProgress.allDone
        and "READY"
        or  string.format("%d / %d   %s", loadProgress.done, loadProgress.total,
                loadProgress.current ~= "" and ("← " .. loadProgress.current) or "")

    loaderLabel.Text = string.format(
        "⚙  %s\n<font color='#%s' size='14'>%s   %s</font>",
        animated, statusColor, bar, statusText
    )
end)

task.spawn(function()
    repeat task.wait(0.1) until loadProgress.allDone
    task.wait(2.2)
    for i = 1, 10 do
        loaderLabel.TextTransparency = i / 10
        task.wait(0.04)
    end
    loaderConn:Disconnect()
    loaderLabel:Destroy()
end)

-- ══════════════════════════════════════════
-- FAULT-TOLERANT MODULE LOADER
-- ══════════════════════════════════════════
local LoadedModules = {}

local function loadModule(path)
    print("⏳ Loading: " .. path)
    loadProgress.current = path:gsub("%.lua$", "")
    
    -- Step 1: Securely grab the source data via HttpGet
    local getSuccess, src = pcall(function()
        return game:HttpGet(BASE .. path)
    end)
    
    if not getSuccess or not src then
        warn("⚠ HTTP ERROR: Failed to fetch module " .. path)
        loadProgress.done = loadProgress.done + 1
        return { Init = function() end } -- Returns a blank fallback component structure
    end
    
    print("📦 Got " .. #src .. " bytes for: " .. path)
    
    -- Step 2: Attempt compiling the module string
    local fn, compileErr = loadstring(src)
    if not fn then
        warn("⚠ COMPILE ERROR in " .. path .. ": " .. tostring(compileErr))
        loadProgress.done = loadProgress.done + 1
        return { Init = function() end }
    end
    
    -- Step 3: Run the logic inside a runtime protected bubble
    local runSuccess, result = pcall(fn)
    if not runSuccess then
        warn("⚠ RUNTIME ERROR inside execution of " .. path .. ": " .. tostring(result))
        loadProgress.done = loadProgress.done + 1
        return { Init = function() end }
    end
    
    print("✅ OK: " .. path)
    loadProgress.done = loadProgress.done + 1
    return result
end

-- Process all items smoothly in a clean iterative loop (Fixes double logging)
for _, moduleFile in ipairs(MODULES) do
    local modName = moduleFile:gsub("%.lua$", "")
    LoadedModules[modName] = loadModule(moduleFile)
end

local Crosshair  = LoadedModules["Crosshair"]
local Aimbot     = LoadedModules["Aimbot"]
local ESP        = LoadedModules["ESP"]
local Fullbright = LoadedModules["Fullbright"]
local Teleport   = LoadedModules["Teleport"]
local ItemESP    = LoadedModules["ItemESP"]
local EventESP   = LoadedModules["EventESP"]
local UI         = LoadedModules["UI"]

loadProgress.allDone = true
loadProgress.current = ""

-- Dismiss screen (waits 0.6s internally, then fades out over 0.5s)
dismissLoadScreen()

-- ══════════════════════════════════════════
-- UI SANITY CHECK
-- ══════════════════════════════════════════
if type(UI) == "table" then
    local required = {
        "makePage","getCol","makeSectionLabel","makeToggleRow","makeSubToggleRow",
        "makeSliderRow","makeDropdownRow","makeInputRow","makeActionBtn",
        "makeStatusLabel","makeSpacer","makeColorPickerRow","setupNavigation","switchTo",
        "setupDrag","setupWindowControls","toast","mount"
    }
    for _, fn in ipairs(required) do
        if type(UI[fn]) ~= "function" then
            warn("❌ UI missing required API method: " .. fn)
        end
    end
    print("✅ UI API verified")
else
    error("❌ Critical: UI system completely failed execution pass.")
end

-- Safely trigger Init phases (fallback tables use clean empty functions instead of nil)
if Crosshair and Crosshair.Init then Crosshair:Init() end
if Aimbot and Aimbot.Init then Aimbot:Init() end
if ESP and ESP.Init then ESP:Init() end
if Teleport and Teleport.Init then Teleport:Init() end
if ItemESP and ItemESP.Init then ItemESP:Init() end
if EventESP and EventESP.Init then EventESP:Init() end

-- ══════════════════════════════════════════
-- COMBAT PAGE  (nav key: "combat")
-- ══════════════════════════════════════════
UI.makePage("combat")
local cL = UI.getCol("combat", "left")
local cR = UI.getCol("combat", "right")

UI.makeSectionLabel(cL, "Aimbot")
UI.makeToggleRow(cL, "Aimbot", false, function(s)
    if Aimbot.SetEnabled then Aimbot:SetEnabled(s) end
    UI.toast("Aimbot", s)
end)
UI.makeSubToggleRow(cL, "Wall Check", true, function(s)
    Aimbot.WallCheck = s
    UI.toast("Wall Check", s)
end)
UI.makeDropdownRow(cL, "Target Bone", {
    "Head", "HumanoidRootPart", "UpperTorso", "Torso", "RightUpperArm", "LeftUpperArm"
}, 1, function(val)
    Aimbot.TargetBone = val
end)
UI.makeSliderRow(cL, "Smoothness", 1, 20, 3, function(val)
    Aimbot.Smooth = val
end)
UI.makeSliderRow(cL, "Bullet Velocity (studs/s)", 1, 4625, 800, function(val)
    Aimbot.BulletVelocity = val
end)

UI.makeSectionLabel(cR, "FOV")
UI.makeSliderRow(cR, "FOV Radius (px)", 50, 400, 150, function(val)
    Aimbot.FOV = val
    if Aimbot.GetOverlayCircle then
        local c = Aimbot:GetOverlayCircle()
        if c then c.Radius = val end
    end
end)

-- ══════════════════════════════════════════
-- LEGIT PAGE  (nav key: "legit")
-- Crosshair editor
-- ══════════════════════════════════════════
UI.makePage("legit")
local lL = UI.getCol("legit", "left")
local lR = UI.getCol("legit", "right")

UI.makeSectionLabel(lL, "Crosshair")
UI.makeToggleRow(lL, "Enable Crosshair", false, function(s)
    if Crosshair.SetEnabled then Crosshair:SetEnabled(s) end
    UI.toast("Crosshair", s)
end)

UI.makeSectionLabel(lL, "Style")
UI.makeDropdownRow(lL, "Style", {
    "Cross", "Circle", "Dot only", "Cross + Circle", "T-shape"
}, 1, function(val)
    local map = {
        ["Cross"] = "cross", ["Circle"] = "circle",
        ["Dot only"] = "dot", ["Cross + Circle"] = "cross+circle",
        ["T-shape"] = "t"
    }
    Crosshair.Style = map[val] or "cross"
end)

UI.makeSectionLabel(lL, "Size")
UI.makeSliderRow(lL, "Length",    2, 30, 10, function(v) Crosshair.Length    = v end)
UI.makeSliderRow(lL, "Thickness", 1,  8,  2, function(v) Crosshair.Thickness = v end)
UI.makeSliderRow(lL, "Gap",       0, 16,  4, function(v) Crosshair.Gap       = v end)
UI.makeSliderRow(lL, "Dot size",  0,  8,  0, function(v) Crosshair.DotSize   = v end)

UI.makeSectionLabel(lL, "Arms")
UI.makeSubToggleRow(lL, "Top",    true,  function(s) Crosshair.ShowTop    = s end)
UI.makeSubToggleRow(lL, "Bottom", true,  function(s) Crosshair.ShowBottom = s end)
UI.makeSubToggleRow(lL, "Left",   true,  function(s) Crosshair.ShowLeft   = s end)
UI.makeSubToggleRow(lL, "Right",  true,  function(s) Crosshair.ShowRight  = s end)

UI.makeSectionLabel(lR, "Colour")
UI.makeColorPickerRow(lR, "Crosshair color",  Color3.fromRGB(0, 255, 136), function(c)
    Crosshair.Color = c
end)
UI.makeColorPickerRow(lR, "Outline color", Color3.fromRGB(0, 0, 0), function(c)
    Crosshair.OutlineColor = c
end)

UI.makeSectionLabel(lR, "Appearance")
UI.makeSliderRow(lR, "Opacity (%)",     10, 100, 100, function(v) Crosshair.Opacity      = v / 100 end)
UI.makeSliderRow(lR, "Outline width",    0,   4,   1, function(v) Crosshair.OutlineWidth = v end)

UI.makeSectionLabel(lR, "Behaviour")
UI.makeSubToggleRow(lR, "Dynamic expand", false, function(s)
    Crosshair.Dynamic = s
    UI.toast("Dynamic expand", s)
end)

-- ══════════════════════════════════════════
-- VISUALS PAGE  (nav key: "visuals")
-- ══════════════════════════════════════════
UI.makePage("visuals")
local vL = UI.getCol("visuals", "left")
local vR = UI.getCol("visuals", "right")

UI.makeSectionLabel(vL, "Player ESP")

local subChams, subHealth, subBoxes, subNames, subWeapon, subSkeleton, subZombies

UI.makeToggleRow(vL, "Player ESP", false, function(s)
    if ESP.SetEnabled then ESP:SetEnabled(s) end
    subChams.Visible    = s
    subHealth.Visible   = s
    subBoxes.Visible    = s
    subNames.Visible    = s
    subWeapon.Visible   = s
    subSkeleton.Visible = s
    subZombies.Visible  = s
    UI.toast("Player ESP", s)
end)

subNames    = UI.makeSubToggleRow(vL, "Names",        true,  function(s) ESP.Names = s       UI.toast("Names", s)        end)
subBoxes    = UI.makeSubToggleRow(vL, "Boxes",        true,  function(s) ESP.Boxes = s       UI.toast("Boxes", s)        end)
subChams    = UI.makeSubToggleRow(vL, "Chams",        false, function(s) if ESP.SetChams then ESP:SetChams(s) end     UI.toast("Chams", s)        end)
subHealth   = UI.makeSubToggleRow(vL, "Health Bars",  false, function(s) ESP.HealthBars = s  UI.toast("Health Bars", s)  end)
subWeapon   = UI.makeSubToggleRow(vL, "Weapon Label", true,  function(s) ESP.WeaponText = s  UI.toast("Weapon Label", s) end)
subSkeleton = UI.makeSubToggleRow(vL, "Skeleton",     false, function(s) if ESP.SetSkeleton then ESP:SetSkeleton(s) end UI.toast("Skeleton", s)     end)
subZombies  = UI.makeSubToggleRow(vL, "Zombies",      false, function(s) if ESP.SetZombies then ESP:SetZombies(s) end   UI.toast("Zombies", s)      end)

UI.makeSliderRow(vL, "ESP Distance (m)", 10, 5000, 500, function(val)
    ESP.MaxDistance = val
end)

UI.makeSectionLabel(vR, "Item ESP")

local subAccessories

UI.makeToggleRow(vR, "Item ESP", false, function(s)
    if ItemESP.SetEnabled then ItemESP:SetEnabled(s) end
    subAccessories.Visible = s
    UI.toast("Item ESP", s)
end)

subAccessories = UI.makeSubToggleRow(vR, "Accessories", true, function(s)
    if ItemESP.SetAccessories then ItemESP:SetAccessories(s) end
    UI.toast("Accessories", s)
end)

UI.makeSliderRow(vR, "Item Distance (m)", 50, 5000, 500, function(val)
    ItemESP.MaxDistance = val
end)

UI.makeSpacer(vR, 6)
UI.makeSectionLabel(vR, "Event ESP")

UI.makeToggleRow(vR, "Event ESP", false, function(s)
    if EventESP.SetEnabled then EventESP:SetEnabled(s) end
    UI.toast("Event ESP", s)
end)

UI.makeSliderRow(vR, "Event Distance (m)", 50, 5000, 1000, function(val)
    EventESP.MaxDistance = val
end)

-- ══════════════════════════════════════════
-- WORLD PAGE  (nav key: "world")
-- ══════════════════════════════════════════
UI.makePage("world")
local wL = UI.getCol("world", "left")

UI.makeSectionLabel(wL, "Lighting")
UI.makeToggleRow(wL, "Fullbright", false, function(s)
    if Fullbright.SetEnabled then Fullbright:SetEnabled(s) end
    UI.toast("Fullbright", s)
end)

-- ══════════════════════════════════════════
-- MOVEMENT PAGE  (nav key: "movement")
-- ══════════════════════════════════════════
UI.makePage("movement")
local mL = UI.getCol("movement", "left")

UI.makeSectionLabel(mL, "Teleport")

local inputRow, getUsername = UI.makeInputRow(mL, "Target Username", "Enter username...")

UI.makeSliderRow(mL, "Behind Offset (studs)", 1, 30, 15, function(val)
    Teleport.BehindOffset = val
end)

local statusLbl = UI.makeStatusLabel(mL)
if Teleport.OnStatusChange then
    Teleport:OnStatusChange(function(msg, color)
        statusLbl.Text       = "Status: " .. msg
        statusLbl.TextColor3 = color
    end)
end

UI.makeSpacer(mL, 4)
UI.makeSectionLabel(mL, "Actions")

local instantTPBtn = UI.makeActionBtn(mL, "⚡ One-Time Teleport")
local startTPBtn   = UI.makeActionBtn(mL, "🔄 Start Loop Tracking", Color3.fromRGB(180, 40, 40))
local stopTPBtn    = UI.makeActionBtn(mL, "⏹ Stop Tracking",       Color3.fromRGB(46, 46, 46))
stopTPBtn.TextColor3 = Color3.fromRGB(128, 128, 128)

instantTPBtn.MouseButton1Click:Connect(function()
    instantTPBtn.Text = "⏳ Teleporting..."
    if Teleport.Once then
        Teleport:Once(getUsername(), function(success)
            if not success then instantTPBtn.Text = "❌ Not Found" end
            task.delay(1.5, function() instantTPBtn.Text = "⚡ One-Time Teleport" end)
        end)
    else
        instantTPBtn.Text = "❌ Feature Offline"
    end
end)

startTPBtn.MouseButton1Click:Connect(function()
    if Teleport.IsTracking or not Teleport.StartTracking then return end
    Teleport:StartTracking(
        getUsername(),
        function(_target)
            startTPBtn.Text             = "🟢 Tracking..."
            startTPBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
            stopTPBtn.BackgroundColor3  = Color3.fromRGB(0, 213, 255)
            stopTPBtn.TextColor3        = Color3.new(1, 1, 1)
        end,
        function()
            startTPBtn.Text = "❌ Not Found"
            task.delay(1.5, function()
                startTPBtn.Text             = "🔄 Start Loop Tracking"
                startTPBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            end)
        end
    )
end)

stopTPBtn.MouseButton1Click:Connect(function()
    if not Teleport.IsTracking or not Teleport.StopTracking then return end
    Teleport:StopTracking()
    startTPBtn.Text             = "🔄 Start Loop Tracking"
    startTPBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    stopTPBtn.BackgroundColor3  = Color3.fromRGB(46, 46, 46)
    stopTPBtn.TextColor3        = Color3.fromRGB(128, 128, 128)
end)

-- ══════════════════════════════════════════
-- MISC PAGE  (nav key: "misc")
-- ══════════════════════════════════════════
UI.makePage("misc")

-- ══════════════════════════════════════════
-- NAVIGATION + DRAG + WINDOW CONTROLS
-- ══════════════════════════════════════════
UI.setupNavigation()
UI.switchTo("combat")
UI.setupDrag()
UI.setupWindowControls(function()
    if Crosshair and Crosshair.Destroy then Crosshair:Destroy() end
    if Aimbot and Aimbot.Destroy then Aimbot:Destroy() end
    if ESP and ESP.Destroy then ESP:Destroy() end
    if ItemESP and ItemESP.Destroy then ItemESP:Destroy() end
    if EventESP and EventESP.Destroy then EventESP:Destroy() end
    if Fullbright and Fullbright.Enabled and Fullbright.Remove then Fullbright:Remove() end
    if Teleport and Teleport.IsTracking and Teleport.StopTracking then Teleport:StopTracking() end
end)

UI.mount()
