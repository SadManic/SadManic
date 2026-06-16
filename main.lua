-- =============================================================================
-- MASTER BOOTSTRAP PIPELINE & CONFIGURATION
-- =============================================================================
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

print("[ChrisM] Initialising Master Subsystems...")

local CharactersFolder = Workspace:WaitForChild("Characters", 5)
if CharactersFolder then
    print("[ChrisM] Workspace CharactersFolder Linked Successfully.")
else
    warn("[ChrisM] Workspace CharactersFolder Absent — Activating Player Character Fallbacks.")
end

_G.CharactersFolder = CharactersFolder

-- =============================================================================
-- SYSTEM 2: EVENT-CACHED 2D RENDERING ENGINE & CHAMS ESP
-- =============================================================================
local ESP = {
    Enabled = false,
    Chams = false,
    HealthBars = false,
    Skeleton = false,
    Boxes = true,
    Names = true,
    WeaponText = true,
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
local EquipmentCache = {} 
local CharacterConnections = {}

local function newDrawing(kind, props)
    local ok, d = pcall(function()
        local obj = Drawing.new(kind)
        for k, v in pairs(props) do obj[k] = v end
        return obj
    end)
    return ok and d or nil
end

local function ensureBones(data, count)
    while #data.Bones < count do
        local line = newDrawing("Line", { Color = Color3.fromRGB(0, 255, 255), Thickness = 1, Visible = false })
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

local function updatePlayerEquipment(player)
    local character = ESP:GetTargetCharacterModel(player)
    if not character then 
        EquipmentCache[player] = { Weapon = "No Weapon", Backpack = nil }
        return 
    end

    local weaponName, backpackName = nil, nil
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
    EquipmentCache[player] = { Weapon = weaponName or "No Weapon", Backpack = backpackName }
end

local function trackCharacterEvents(player)
    if CharacterConnections[player] then
        for _, conn in ipairs(CharacterConnections[player]) do conn:Disconnect() end
    end
    CharacterConnections[player] = {}

    local function setupConnections(char)
        if not char then return end
        updatePlayerEquipment(player)
        table.insert(CharacterConnections[player], char.ChildAdded:Connect(function() updatePlayerEquipment(player) end))
        table.insert(CharacterConnections[player], char.ChildRemoved:Connect(function() updatePlayerEquipment(player) end))
    end

    local char = ESP:GetTargetCharacterModel(player)
    if char then setupConnections(char) end
    table.insert(CharacterConnections[player], player.CharacterAdded:Connect(setupConnections))
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
    trackCharacterEvents(player)
end

local function removeEntry(player)
    local d = ActiveESP[player]
    if d then
        pcall(function()
            for _, key in ipairs({"Text","Box","HealthBg","HealthFill","WeaponText","BackpackText"}) do
                if d[key] then d[key].Visible = false; d[key]:Remove() end
            end
            if d.Cham then d.Cham:Destroy() end
            for _, line in ipairs(d.Bones) do line.Visible = false; line:Remove() end
        end)
        ActiveESP[player] = nil
    end
    if CharacterConnections[player] then
        for _, conn in ipairs(CharacterConnections[player]) do conn:Disconnect() end
        CharacterConnections[player] = nil
    end
    EquipmentCache[player] = nil
end

local function hideEntry(d)
    for _, key in ipairs({"Text","Box","HealthBg","HealthFill","WeaponText","BackpackText"}) do
        if d[key] then d[key].Visible = false end
    end
    for _, line in ipairs(d.Bones) do line.Visible = false end
    if d.Cham then d.Cham:Destroy(); d.Cham = nil end
end

local function renderFrame()
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
                table.insert(sorted, { Player = player, Data = d, Distance = dist, Character = character, Humanoid = humanoid })

                local headPos, headOn = camera:WorldToViewportPoint(head.Position)
                if headOn and ESP.Names and d.Text then
                    d.Text.Position = Vector2.new(headPos.X, headPos.Y - NAME_OFFSET_Y)
                    d.Text.Text     = player.Name .. " [" .. math.floor(dist) .. "m]"
                    d.Text.Visible  = true
                elseif d.Text then
                    d.Text.Visible = false
                end

                local rootSc, rootOn = camera:WorldToViewportPoint(root.Position)
                if rootOn and d.Box then
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

                    local eq = EquipmentCache[player]
                    local gun = eq and eq.Weapon or "No Weapon"
                    local bag = eq and eq.Backpack
                    local yOff = 4

                    if ESP.WeaponText then
                        if d.WeaponText then
                            d.WeaponText.Position = Vector2.new(rootSc.X, boxY + boxHeight + yOff)
                            d.WeaponText.Text     = gun
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
                    hideEntry(d)
                end

                if ESP.Skeleton then
                    local validBones = {}
                    for _, pair in ipairs(SKELETON_BONES) do
                        local pA = character:FindFirstChild(pair[1])
                        local pB = character:FindFirstChild(pair[2])
                        if pA and pB then
                            local sA, onA = camera:WorldToViewportPoint(pA.Position)
                            local sB, onB = camera:WorldToViewportPoint(pB.Position)
                            if onA and onB then
                                table.insert(validBones, { Vector2.new(sA.X, sA.Y), Vector2.new(sB.X, sB.Y) })
                            end
                        end
                    end
                    ensureBones(d, #validBones)
                    for i, pts in ipairs(validBones) do
                        d.Bones[i].From    = pts[1]
                        d.Bones[i].To      = pts[2]
                        d.Bones[i].Visible = true
                    end
                    for i = #validBones+1, #d.Bones do d.Bones[i].Visible = false end
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

    table.sort(sorted, function(a, b) return a.Distance < b.Distance end)
    for i, item in ipairs(sorted) do
        local d = item.Data
        local targetZIndex = 1000 - math.clamp(math.floor(item.Distance), 0, 900)
        d.Text.ZIndex = targetZIndex
        d.Box.ZIndex = targetZIndex
        d.HealthBg.ZIndex = targetZIndex
        d.HealthFill.ZIndex = targetZIndex
        d.WeaponText.ZIndex = targetZIndex
        d.BackpackText.ZIndex = targetZIndex

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
end

function ESP:SetEnabled(s)
    self.Enabled = s
    if not s then for _, d in pairs(ActiveESP) do hideEntry(d) end end
end
function ESP:SetChams(s) self.Chams = s end
function ESP:SetSkeleton(s) self.Skeleton = s end

function ESP:Init()
    for _, p in ipairs(Players:GetPlayers()) do createEntry(p) end
    Players.PlayerAdded:Connect(createEntry)
    Players.PlayerRemoving:Connect(removeEntry)
    RunService:BindToRenderStep("ESPRenderPipeline", Enum.RenderPriority.Camera.Value + 1, renderFrame)
end

-- =============================================================================
-- SYSTEM 3: ANTI-CHEAT HARDENED TELEPORTATION ENGINE
-- =============================================================================
local Teleport = {
    BehindOffset = 15,
    IsTracking = false,
    _currentTarget = nil,
    ThrottleInterval = 0.1
}

local trackingConnection = nil
local onStatusChange = nil

local function setStatus(msg, color)
    if onStatusChange then onStatusChange(msg, color or Color3.new(0.5, 0.5, 0.5)) end
end

local function getTeleportCharacterModel(player)
    if CharactersFolder then
        local target = CharactersFolder:FindFirstChild(player.Name)
        if target then return target end
    end
    return player.Character
end

local function findPlayer(name)
    if name == "" then return nil end
    local lower = string.lower(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if string.sub(string.lower(p.Name), 1, #lower) == lower
        or string.sub(string.lower(p.DisplayName), 1, #lower) == lower then
            return p
        end
    end
    return nil
end

local function safeCFrame(targetRoot, targetChar, myChar)
    local cf = targetRoot.CFrame
    local offset = math.max(5, math.abs(Teleport.BehindOffset))
    local ideal = (cf * CFrame.new(0, 0, offset)).Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { myChar, targetChar, Workspace.CurrentCamera, Players }
    params.IgnoreWater = true
    local wallHit = Workspace:Raycast(cf.Position, ideal - cf.Position, params)
    local pos = wallHit and (wallHit.Position + wallHit.Normal * 2.5) or ideal
    local floorHit = Workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -12, 0), params)
    if floorHit then pos = Vector3.new(pos.X, floorHit.Position.Y + 3, pos.Z) end
    return CFrame.new(pos, pos + cf.LookVector)
end

local function doTeleport()
    local targetPlayer = Teleport._currentTarget
    local targetChar = targetPlayer and getTeleportCharacterModel(targetPlayer)
    local myChar = getTeleportCharacterModel(LocalPlayer)
    if not (targetPlayer and targetChar and myChar) then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local myHuman = myChar:FindFirstChildOfClass("Humanoid")
    local tgtRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not (myRoot and myHuman and tgtRoot) then return end
    if myHuman.Health <= 0 then return end
    if myHuman:GetState() ~= Enum.HumanoidStateType.Physics then
        myHuman.PlatformStand = true
        myHuman:ChangeState(Enum.HumanoidStateType.Physics)
    end
    myRoot.CFrame = safeCFrame(tgtRoot, targetChar, myChar)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero
end

function Teleport:OnStatusChange(callback) onStatusChange = callback end

function Teleport:Once(targetName, onDone)
    if self.IsTracking then self:StopTracking() end
    local target = findPlayer(targetName)
    local targetChar = target and getTeleportCharacterModel(target)
    local myChar = getTeleportCharacterModel(LocalPlayer)
    if not target or not targetChar then
        setStatus("Player not found.", Color3.fromRGB(255, 80, 80))
        if onDone then onDone(false) end
        return
    end
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHuman = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local tgtRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not (myRoot and myHuman and tgtRoot) then if onDone then onDone(false) end return end
    myRoot.Anchored = true
    myHuman.PlatformStand = true
    myHuman:ChangeState(Enum.HumanoidStateType.Physics)
    if LocalPlayer.RequestStreamAroundAsync then
        pcall(function() LocalPlayer:RequestStreamAroundAsync(tgtRoot.Position) end)
    end
    myRoot.CFrame = safeCFrame(tgtRoot, targetChar, myChar)
    myRoot.AssemblyLinearVelocity = Vector3.zero
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
    self.IsTracking = true
    setStatus("Tracking " .. target.Name .. "...", Color3.fromRGB(0, 213, 255))
    if onSuccess then onSuccess(target) end
    local lastUpdate = 0
    trackingConnection = RunService.Heartbeat:Connect(function()
        if not self.IsTracking then return end
        local now = os.clock()
        if now - lastUpdate >= self.ThrottleInterval then
            lastUpdate = now
            local ok, err = pcall(doTeleport)
            if not ok then warn("Tracking error: " .. tostring(err)) end
        end
    end)
end

function Teleport:StopTracking()
    if not self.IsTracking then return end
    self.IsTracking = false
    self._currentTarget = nil
    if trackingConnection then trackingConnection:Disconnect(); trackingConnection = nil end
    local myChar = getTeleportCharacterModel(LocalPlayer)
    if myChar then
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        local myHuman = myChar:FindFirstChildOfClass("Humanoid")
        if myRoot and myHuman then
            myRoot.Anchored = true
            myHuman.PlatformStand = false
            myHuman:ChangeState(Enum.HumanoidStateType.GettingUp)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
            RunService.Heartbeat:Wait()
            RunService.Heartbeat:Wait()
            myRoot.AssemblyLinearVelocity = Vector3.zero
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
    LocalPlayer.CharacterRemoving:Connect(function()
        if self.IsTracking then self:StopTracking() end
    end)
end

-- =============================================================================
-- INTERFACE LAYER ROUTING
-- =============================================================================
_G.ESP = ESP
_G.Teleport = Teleport

ESP:Init()
Teleport:Init()

local rayfieldSrc = game:HttpGet('https://sirius.menu/rayfield')
local rayfieldFn, rayfieldErr = loadstring(rayfieldSrc)
if not rayfieldFn then error("[ChrisM] Rayfield Engine Compilation Aborted: " .. tostring(rayfieldErr)) end

local Rayfield = rayfieldFn()
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

-- ── TAB 1: VISUALIZATION INTERFACE
local Tab1 = Window:CreateTab("👁 Player ESP", nil)
Tab1:CreateToggle({ Name = "Enable ESP", CurrentValue = false, Callback = function(v) ESP:SetEnabled(v) end })
Tab1:CreateToggle({ Name = "Boxes", CurrentValue = true, Callback = function(v) ESP.Boxes = v end })
Tab1:CreateToggle({ Name = "Names", CurrentValue = true, Callback = function(v) ESP.Names = v end })
Tab1:CreateToggle({ Name = "Weapon Labels", CurrentValue = true, Callback = function(v) ESP.WeaponText = v end })
Tab1:CreateToggle({ Name = "Chams", CurrentValue = false, Callback = function(v) ESP:SetChams(v) end })
Tab1:CreateToggle({ Name = "Health Bars", CurrentValue = false, Callback = function(v) ESP.HealthBars = v end })
Tab1:CreateToggle({ Name = "Skeleton", CurrentValue = false, Callback = function(v) ESP:SetSkeleton(v) end })
Tab1:CreateInput({
    Name = "Max Distance (m)", PlaceholderText = "500", RemoveTextAfterFocusLost = false,
    Callback = function(t) local n = tonumber(t); if n then ESP.MaxDistance = n end end,
})

-- ── TAB 2: POSITION MANIPULATION INTERFACE
local Tab2 = Window:CreateTab("🎯 Teleport & Targets", nil)
local TargetName = ""
local StatusLabel = Tab2:CreateLabel("Status: Idle")

Teleport:OnStatusChange(function(msg, color)
    pcall(function() StatusLabel:Set("Status: " .. tostring(msg)) end)
end)

Tab2:CreateInput({ Name = "Target Username", PlaceholderText = "Username...", RemoveTextAfterFocusLost = false, Callback = function(t) TargetName = t end })
Tab2:CreateInput({
    Name = "Behind Offset (studs)", PlaceholderText = "15", RemoveTextAfterFocusLost = false,
    Callback = function(t) local n = tonumber(t); if n then Teleport.BehindOffset = n end end,
})

Tab2:CreateButton({
    Name = "⚡ One-Time Teleport",
    Callback = function()
        if TargetName == "" then setStatus("Enter a username first!", Color3.fromRGB(255,80,80)) return end
        Teleport:Once(TargetName)
    end,
})

Tab2:CreateButton({
    Name = "🟢 Start Loop Tracking",
    Callback = function()
        if Teleport.IsTracking then setStatus("Already tracking!", Color3.fromRGB(255,200,0)) return end
        if TargetName == "" then setStatus("Enter a username first!", Color3.fromRGB(255,80,80)) return end
        Teleport:StartTracking(TargetName)
    end,
})

Tab2:CreateButton({
    Name = "🔴 Stop Tracking",
    Callback = function()
        if not Teleport.IsTracking then setStatus("Not currently tracking", Color3.fromRGB(150,150,150)) return end
        Teleport:StopTracking()
    end,
})

print("[ChrisM] Master Window Pipeline Complete.")
