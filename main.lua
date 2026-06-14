-- =============================================================================
-- 1. SERVICES & CORE SETUP
-- =============================================================================
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

print("[ChrisM] Script started")

local CharactersFolder = Workspace:WaitForChild("Characters", 5)
if CharactersFolder then
    print("[ChrisM] CharactersFolder found")
else
    warn("[ChrisM] CharactersFolder not found — using player.Character fallback")
end

-- =============================================================================
-- 2. ESP
-- =============================================================================
local ESP = {
    Enabled     = false,
    Chams       = false,
    HealthBars  = false,
    Skeleton    = false,
    Boxes       = true,
    Names       = true,
    WeaponText  = true,
    MaxDistance = 500,
}

local ESP_COLOR         = Color3.fromRGB(255, 0, 0)
local OUTLINE_COLOR     = Color3.fromRGB(255, 255, 255)
local FILL_TRANSPARENCY = 0.5
local MAX_CHAMS         = 30
local ENGINE_CHAM_LIMIT = 1000
local NAME_TEXT_SIZE    = 11
local NAME_TRANSPARENCY = 0.35
local NAME_OFFSET_Y     = 18

local SKELETON_BONES = {
    {"Head","UpperTorso"}, {"Head","Torso"},
    {"UpperTorso","LowerTorso"}, {"LowerTorso","HumanoidRootPart"}, {"Torso","HumanoidRootPart"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"Torso","Right Arm"}, {"Torso","Left Arm"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"HumanoidRootPart","Right Leg"}, {"HumanoidRootPart","Left Leg"},
}

local ActiveESP = {}

local function newDrawing(kind, props)
    local ok, d = pcall(function()
        local obj = Drawing.new(kind)
        for k, v in pairs(props) do obj[k] = v end
        return obj
    end)
    if not ok then
        warn("[ChrisM][ESP] Failed to create Drawing." .. kind .. ": " .. tostring(d))
        return nil
    end
    return d
end

local function ensureBones(data, count)
    while #data.Bones < count do
        local line = newDrawing("Line", {
            Color = Color3.fromRGB(0, 255, 255), Thickness = 1, Visible = false,
        })
        if line then table.insert(data.Bones, line) end
    end
end

function ESP:GetTargetCharacterModel(player)
    if CharactersFolder then
        local t = CharactersFolder:FindFirstChild(player.Name)
        if t then return t end
    end
    return player.Character
end

function ESP:GetPlayerEquipment(player)
    local weaponName, backpackName = nil, nil
    local character = self:GetTargetCharacterModel(player)
    if not character then return nil, nil end

    for _, child in ipairs(character:GetChildren()) do
        local nl = child.Name:lower()
        if child:IsA("Folder") or child:IsA("Model") then
            if nl:find("backpack") or nl:find("bag") or nl:find("knapsack") then
                backpackName = child.Name
            elseif child.Name == "Equipped" or child.Name == "Equipment" then
                for _, sub in ipairs(child:GetChildren()) do
                    if sub:IsA("Folder") or sub:IsA("Model") then
                        local sl = sub.Name:lower()
                        if sl:find("backpack") or sl:find("bag") or sl:find("knapsack") then
                            backpackName = sub.Name
                        elseif sub:FindFirstChild("Muzzle") or sub:FindFirstChild("SightLine") or sub:FindFirstChild("Base") then
                            weaponName = sub.Name
                        end
                    end
                end
                if not weaponName or not backpackName then
                    local attr = child:GetAttribute("ItemName") or child:GetAttribute("WeaponName")
                    if attr then
                        local al = tostring(attr):lower()
                        if al:find("backpack") or al:find("bag") or al:find("knapsack") then
                            backpackName = tostring(attr)
                        else
                            weaponName = tostring(attr)
                        end
                    end
                end
            end
        elseif child:IsA("Tool") then
            weaponName = child.Name
        end
    end
    return weaponName, backpackName
end

local function createEntry(player)
    if ActiveESP[player] or player == LocalPlayer then return end
    ActiveESP[player] = {
        Text         = newDrawing("Text",   { Color = Color3.fromRGB(255,255,255), Size = NAME_TEXT_SIZE, Center = true, Outline = true, Transparency = NAME_TRANSPARENCY, Visible = false }),
        Box          = newDrawing("Square", { Color = ESP_COLOR, Thickness = 1.5, Filled = false, Visible = false }),
        HealthBg     = newDrawing("Square", { Color = Color3.fromRGB(0,0,0), Thickness = 1, Filled = true, Visible = false }),
        HealthFill   = newDrawing("Square", { Color = Color3.fromRGB(0,255,80), Thickness = 1, Filled = true, Visible = false }),
        WeaponText   = newDrawing("Text",   { Color = Color3.fromRGB(255,200,0), Size = 10, Center = true, Outline = true, Transparency = NAME_TRANSPARENCY, Visible = false }),
        BackpackText = newDrawing("Text",   { Color = Color3.fromRGB(0,180,255), Size = 10, Center = true, Outline = true, Transparency = NAME_TRANSPARENCY, Visible = false }),
        Cham         = nil,
        Bones        = {},
    }
end

local function removeEntry(player)
    local d = ActiveESP[player]
    if not d then return end
    pcall(function()
        for _, key in ipairs({"Text","Box","HealthBg","HealthFill","WeaponText","BackpackText"}) do
            if d[key] then d[key].Visible = false; d[key]:Remove() end
        end
        if d.Cham then d.Cham:Destroy() end
        for _, line in ipairs(d.Bones) do line.Visible = false; line:Remove() end
    end)
    ActiveESP[player] = nil
end

local function hideEntry(d)
    for _, key in ipairs({"Text","Box","HealthBg","HealthFill","WeaponText","BackpackText"}) do
        if d[key] then d[key].Visible = false end
    end
    for _, line in ipairs(d.Bones) do line.Visible = false end
    if d.Cham then d.Cham:Destroy(); d.Cham = nil end
end

local function renderFrame()
    local ok, err = pcall(function()
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local sorted = {}

        for player, d in pairs(ActiveESP) do
            local character = ESP:GetTargetCharacterModel(player)
            local root      = character and character:FindFirstChild("HumanoidRootPart")
            local head      = character and character:FindFirstChild("Head")
            local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
            local alive     = humanoid and humanoid.Health > 0

            if ESP.Enabled and root and head and alive then
                local dist    = (camera.CFrame.Position - root.Position).Magnitude
                local _, onSc = camera:WorldToViewportPoint(root.Position)

                if onSc and dist > 0.1 and dist <= ESP.MaxDistance then
                    table.insert(sorted, {
                        Player    = player,
                        Data      = d,
                        Distance  = dist,
                        Character = character,
                        Humanoid  = humanoid,
                    })

                    -- Name
                    local headPos, headOn = camera:WorldToViewportPoint(head.Position)
                    if headOn and ESP.Names and d.Text then
                        d.Text.Position = Vector2.new(headPos.X, headPos.Y - NAME_OFFSET_Y)
                        d.Text.Text     = player.Name .. " [" .. math.floor(dist) .. "m]"
                        d.Text.Visible  = true
                    elseif d.Text then
                        d.Text.Visible = false
                    end

                    -- Bounding Box Framework (Isolated from physical animation/state jitters)
                    local rootSc, rootOn = camera:WorldToViewportPoint(root.Position)
                    if rootOn and d.Box then
                        -- Calculate standard bounding dimensions directly from the root coordinate plane
                        local topSc = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
                        local bottomSc = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
                        
                        local boxHeight = math.abs(bottomSc.Y - topSc.Y)
                        local boxWidth  = boxHeight * 0.55
                        local boxX      = rootSc.X - boxWidth / 2
                        local boxY      = topSc.Y
                        
                        if ESP.Boxes then
                            d.Box.Size     = Vector2.new(boxWidth, boxHeight)
                            d.Box.Position = Vector2.new(boxX, boxY)
                            d.Box.Visible  = true
                        else
                            d.Box.Visible = false
                        end
                        
                        -- Health bar tracking placement
                        if ESP.HealthBars and d.HealthBg and d.HealthFill then
                            local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                            local barX  = boxX - 6
                            
                            d.HealthBg.Position = Vector2.new(barX - 1, boxY - 1)
                            d.HealthBg.Size     = Vector2.new(5, boxHeight + 2)
                            d.HealthBg.Visible  = true
                            
                            local fillH = boxHeight * ratio
                            d.HealthFill.Position = Vector2.new(barX, boxY + (boxHeight - fillH))
                            d.HealthFill.Size     = Vector2.new(3, fillH)
                            d.HealthFill.Color    = Color3.fromRGB(math.floor(255 * (1 - ratio)), math.floor(255 * ratio), 0)
                            d.HealthFill.Visible  = true
                        else
                            if d.HealthBg then d.HealthBg.Visible = false end
                            if d.HealthFill then d.HealthFill.Visible = false end
                        end

                        -- Weapon / Backpack Text placement
                        local gun, bag = ESP:GetPlayerEquipment(player)
                        local yOff     = 4
                        if ESP.WeaponText then
                            if d.WeaponText then
                                d.WeaponText.Position = Vector2.new(rootSc.X, boxY + boxHeight + yOff)
                                d.WeaponText.Text     = gun or "No Weapon"
                                d.WeaponText.Visible  = true
                                yOff = yOff + 12
                            end
                            if bag and d.BackpackText then
                                d.BackpackText.Position = Vector2.new(rootSc.X, boxY + boxHeight + yOff)
                                d.BackpackText.Text     = bag
                                d.BackpackText.Visible  = true
                            elseif d.BackpackText then
                                d.BackpackText.Visible = false
                            end
                        else
                            if d.WeaponText  then d.WeaponText.Visible  = false end
                            if d.BackpackText then d.BackpackText.Visible = false end
                        end
                    else
                        if d.Box then d.Box.Visible = false end
                        if d.HealthBg then d.HealthBg.Visible = false end
                        if d.HealthFill then d.HealthFill.Visible = false end
                        if d.WeaponText then d.WeaponText.Visible = false end
                        if d.BackpackText then d.BackpackText.Visible = false end
                    end

                    -- Skeleton Rendering
                    if ESP.Skeleton then
                        local validBones = {}
                        for _, pair in ipairs(SKELETON_BONES) do
                            local pA = character:FindFirstChild(pair[1])
                            local pB = character:FindFirstChild(pair[2])
                            if pA and pB then
                                local sA, onA = camera:WorldToViewportPoint(pA.Position)
                                local sB, onB = camera:WorldToViewportPoint(pB.Position)
                                if onA and onB then
                                    table.insert(validBones, {
                                        Vector2.new(sA.X, sA.Y),
                                        Vector2.new(sB.X, sB.Y),
                                    })
                                end
                            end
                        end
                        ensureBones(d, #validBones)
                        for i, pts in ipairs(validBones) do
                            d.Bones[i].From    = pts[1]
                            d.Bones[i].To      = pts[2]
                            d.Bones[i].Visible = true
                        end
                        for i = #validBones+1, #d.Bones do
                            d.Bones[i].Visible = false
                        end
                    else
                        for _, line in ipairs(d.Bones) do line.Visible = false end
                    end

                else
                    hideEntry(d)
                end
            else
                hideEntry(d)
            end
        end

        -- Chams
        table.sort(sorted, function(a, b) return a.Distance < b.Distance end)
        for i, item in ipairs(sorted) do
            local d = item.Data
            if ESP.Chams and i <= MAX_CHAMS and item.Distance <= ENGINE_CHAM_LIMIT then
                if not d.Cham or d.Cham.Parent ~= item.Character then
                    if d.Cham then d.Cham:Destroy() end
                    local hl = Instance.new("Highlight")
                    hl.FillColor           = ESP_COLOR
                    hl.OutlineColor        = OUTLINE_COLOR
                    hl.FillTransparency    = FILL_TRANSPARENCY
                    hl.OutlineTransparency = 0
                    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Adornee             = item.Character
                    hl.Parent              = item.Character
                    d.Cham = hl
                end
            else
                if d.Cham then d.Cham:Destroy(); d.Cham = nil end
            end
        end

        if not ESP.Chams then
            for _, d in pairs(ActiveESP) do
                if d.Cham then d.Cham:Destroy(); d.Cham = nil end
            end
        end
    end)

    if not ok then
        warn("[ChrisM][ESP] renderFrame error: " .. tostring(err))
    end
end

function ESP:SetEnabled(s)
    self.Enabled = s
    if not s then
        for _, d in pairs(ActiveESP) do hideEntry(d) end
    end
end
function ESP:SetChams(s)    self.Chams    = s end
function ESP:SetSkeleton(s) self.Skeleton = s end

function ESP:Init()
    print("[ChrisM] ESP:Init()")
    for _, p in ipairs(Players:GetPlayers()) do createEntry(p) end
    Players.PlayerAdded:Connect(createEntry)
    Players.PlayerRemoving:Connect(removeEntry)
    RunService:BindToRenderStep(
        "ESPRenderPipeline",
        Enum.RenderPriority.Camera.Value + 1,
        renderFrame
    )
    print("[ChrisM] ESP render pipeline bound")
end

-- =============================================================================
-- 3. TELEPORT
-- =============================================================================
local Teleport = {
    BehindOffset   = 15,
    IsTracking     = false,
    _currentTarget = nil,
}

local trackingConnection = nil
local onStatusChange     = nil

local function setStatus(msg, color)
    if onStatusChange then
        onStatusChange(msg, color or Color3.new(0.5, 0.5, 0.5))
    end
end

local function getTargetCharacterModel(player)
    if CharactersFolder then
        local t = CharactersFolder:FindFirstChild(player.Name)
        if t then return t end
    end
    return player.Character
end

local function findPlayer(name)
    if not name or name == "" then return nil end
    local lower = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if p.Name:lower():sub(1, #lower) == lower
        or p.DisplayName:lower():sub(1, #lower) == lower then
            return p
        end
    end
    return nil
end

local function safeCFrame(targetRoot, targetChar, myChar)
    local cf     = targetRoot.CFrame
    local offset = math.max(5, math.abs(Teleport.BehindOffset))
    local ideal  = (cf * CFrame.new(0, 0, offset)).Position

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        myChar, targetChar, Workspace.CurrentCamera, Players
    }
    params.IgnoreWater = true

    local wallHit  = Workspace:Raycast(cf.Position, ideal - cf.Position, params)
    local pos      = wallHit and (wallHit.Position + wallHit.Normal * 2.5) or ideal
    local floorHit = Workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -12, 0), params)
    if floorHit then pos = Vector3.new(pos.X, floorHit.Position.Y + 3, pos.Z) end
    return CFrame.new(pos, pos + cf.LookVector)
end

local function doTeleport()
    local targetPlayer = Teleport._currentTarget
    local targetChar   = targetPlayer and getTargetCharacterModel(targetPlayer)
    local myChar       = getTargetCharacterModel(LocalPlayer)
    if not (targetPlayer and targetChar and myChar) then return end

    local myRoot  = myChar:FindFirstChild("HumanoidRootPart")
    local myHuman = myChar:FindFirstChildOfClass("Humanoid")
    local tgtRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not (myRoot and myHuman and tgtRoot) then return end

    if myHuman:GetState() ~= Enum.HumanoidStateType.Physics then
        myHuman.PlatformStand = true
        myHuman:ChangeState(Enum.HumanoidStateType.Physics)
    end
    myRoot.CFrame = safeCFrame(tgtRoot, targetChar, myChar)
    myRoot.AssemblyLinearVelocity  = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero
end

function Teleport:OnStatusChange(cb)
    onStatusChange = cb
end

function Teleport:Once(targetName, onDone)
    if self.IsTracking then self:StopTracking() end
    local target     = findPlayer(targetName)
    local targetChar = target and getTargetCharacterModel(target)
    local myChar     = getTargetCharacterModel(LocalPlayer)

    if not target or not targetChar then
        setStatus("Player not found.", Color3.fromRGB(255, 80, 80))
        if onDone then onDone(false) end
        return
    end

    local myRoot  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHuman = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local tgtRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not (myRoot and myHuman and tgtRoot) then
        if onDone then onDone(false) end
        return
    end

    myRoot.Anchored       = true
    myHuman.PlatformStand = true
    myHuman:ChangeState(Enum.HumanoidStateType.Physics)
    pcall(function() LocalPlayer:RequestStreamAroundAsync(tgtRoot.Position) end)
    myRoot.CFrame = safeCFrame(tgtRoot, targetChar, myChar)
    myRoot.AssemblyLinearVelocity  = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero
    RunService.Heartbeat:Wait()
    RunService.Heartbeat:Wait()
    myHuman.PlatformStand = false
    myHuman:ChangeState(Enum.HumanoidStateType.Running)
    myRoot.Anchored = false
    setStatus("Teleported to " .. target.Name .. ".", Color3.fromRGB(0, 200, 80))
    if onDone then onDone(true) end
end

function Teleport:StartTracking(targetName, onSuccess, onFail)
    if self.IsTracking then return end
    local target = findPlayer(targetName)
    if not target then
        setStatus("Player not found.", Color3.fromRGB(255, 80, 80))
        if onFail then onFail() end
        return
    end
    self._currentTarget = target
    self.IsTracking     = true
    setStatus("Tracking " .. target.Name .. "...", Color3.fromRGB(0, 213, 255))
    if onSuccess then onSuccess(target) end
    trackingConnection = RunService.Heartbeat:Connect(function()
        local ok, err = pcall(doTeleport)
        if not ok then warn("[ChrisM][Teleport] " .. tostring(err)) end
    end)
end

function Teleport:StopTracking()
    self.IsTracking     = false
    self._currentTarget = nil
    if trackingConnection then
        trackingConnection:Disconnect()
        trackingConnection = nil
    end
    local myChar = getTargetCharacterModel(LocalPlayer)
    if myChar then
        local myRoot  = myChar:FindFirstChild("HumanoidRootPart")
        local myHuman = myChar:FindFirstChildOfClass("Humanoid")
        if myRoot and myHuman then
            myRoot.Anchored       = true
            myHuman.PlatformStand = false
            myHuman:ChangeState(Enum.HumanoidStateType.GettingUp)
            myRoot.AssemblyLinearVelocity  = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
            RunService.Heartbeat:Wait()
            RunService.Heartbeat:Wait()
            myRoot.AssemblyLinearVelocity  = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
            myHuman:ChangeState(Enum.HumanoidStateType.Running)
            myRoot.Anchored = false
        end
    end
    setStatus("Idle", Color3.fromRGB(150, 150, 150))
end

function Teleport:Init()
    Players.PlayerRemoving:Connect(function(p)
        if self.IsTracking and self._currentTarget == p then
            setStatus("Target left.", Color3.fromRGB(255, 80, 80))
            self:StopTracking()
        end
    end)
    print("[ChrisM] Teleport:Init()")
end

-- =============================================================================
-- 4. BOOTSTRAP
-- =============================================================================
print("[ChrisM] Initialising subsystems...")
_G.ESP      = ESP
_G.Teleport = Teleport
ESP:Init()
Teleport:Init()

print("[ChrisM] Fetching Rayfield...")
local rayfieldSrc = game:HttpGet('https://sirius.menu/rayfield')
print("[ChrisM] Rayfield source size: " .. #rayfieldSrc .. " bytes")

local rayfieldFn, rayfieldErr = loadstring(rayfieldSrc)
if not rayfieldFn then
    error("[ChrisM] Rayfield loadstring failed: " .. tostring(rayfieldErr))
end
print("[ChrisM] Rayfield compiled OK, executing...")

local Rayfield = rayfieldFn()
if not Rayfield then
    error("[ChrisM] Rayfield returned nil")
end
print("[ChrisM] Rayfield loaded OK")

-- =============================================================================
-- 5. UI
-- =============================================================================
print("[ChrisM] Building UI...")

local Window = Rayfield:CreateWindow({
    Name                   = "ChrisM Hub",
    Icon                   = 0,
    LoadingTitle           = "ChrisM Hub",
    LoadingSubtitle        = "Apocalypse Rising 2",
    Theme                  = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = true,
    ConfigurationSaving    = { Enabled = false },
})
print("[ChrisM] Window created")

-- ── ESP Tab ────────────────────────────────────────────────
local Tab1 = Window:CreateTab("👁 Player ESP", nil)
print("[ChrisM] ESP tab created")

Tab1:CreateToggle({
    Name         = "Enable ESP",
    CurrentValue = false,
    Callback     = function(v) ESP:SetEnabled(v) end,
})
Tab1:CreateToggle({
    Name         = "Boxes",
    CurrentValue = true,
    Callback     = function(v) ESP.Boxes = v end,
})
Tab1:CreateToggle({
    Name         = "Names",
    CurrentValue = true,
    Callback     = function(v) ESP.Names = v end,
})
Tab1:CreateToggle({
    Name         = "Weapon Labels",
    CurrentValue = true,
    Callback     = function(v) ESP.WeaponText = v end,
})
Tab1:CreateToggle({
    Name         = "Chams",
    CurrentValue = false,
    Callback     = function(v) ESP:SetChams(v) end
})
Tab1:CreateToggle({
    Name         = "Health Bars",
    CurrentValue = false,
    Callback     = function(v) ESP.HealthBars = v end
})
Tab1:CreateToggle({
    Name         = "Skeleton",
    CurrentValue = false,
    Callback     = function(v) ESP:SetSkeleton(v) end
})
Tab1:CreateInput({
    Name                     = "Max Distance (m)",
    PlaceholderText          = "500",
    RemoveTextAfterFocusLost = false,
    Callback                 = function(t)
        local n = tonumber(t)
        if n then ESP.MaxDistance = n end
    end,
})

-- ── Teleport Tab ───────────────────────────────────────────
local Tab2 = Window:CreateTab("🎯 Teleport", nil)
print("[ChrisM] Teleport tab created")

local TargetName  = ""
local StatusLabel = Tab2:CreateLabel("Status: Idle")

Teleport:OnStatusChange(function(msg, _)
    pcall(function() StatusLabel:Set("Status: " .. tostring(msg)) end)
end)

Tab2:CreateInput({
    Name                     = "Target Username",
    PlaceholderText          = "Username...",
    RemoveTextAfterFocusLost = false,
    Callback                 = function(t) TargetName = t end,
})

-- REMOVED SLIDER -> REPLACED WITH SECURE DISTANCE CONFIG TEXT BOX
Tab2:CreateInput({
    Name                     = "Behind Offset (studs)",
    PlaceholderText          = "15",
    RemoveTextAfterFocusLost = false,
    Callback                 = function(t)
        local n = tonumber(t)
        if n then 
            Teleport.BehindOffset = n 
        end
    end,
})

Tab2:CreateButton({
    Name     = "⚡ One-Time Teleport",
    Callback = function()
        if TargetName == "" then
            pcall(function() StatusLabel:Set("Status: Enter a username first!") end)
            return
        end
        Teleport:Once(TargetName)
    end,
})

Tab2:CreateButton({
    Name     = "🟢 Start Loop Tracking",
    Callback = function()
        if Teleport.IsTracking then
            pcall(function() StatusLabel:Set("Status: Already tracking!") end)
            return
        end
        if TargetName == "" then
            pcall(function() StatusLabel:Set("Status: Enter a username first!") end)
            return
        end
        Teleport:StartTracking(
            TargetName,
            function(target)
                pcall(function()
                    StatusLabel:Set("Status: 🟢 Tracking " .. target.Name .. "...")
                end)
            end,
            function()
                pcall(function()
                    StatusLabel:Set("Status: ❌ Player not found")
                end)
            end
        )
    end,
})

Tab2:CreateButton({
    Name     = "🔴 Stop Tracking",
    Callback = function()
        if not Teleport.IsTracking then
            pcall(function() StatusLabel:Set("Status: Not currently tracking") end)
            return
        end
        Teleport:StopTracking()
    end,
})

print("[ChrisM] ✅ All done — hub running")
