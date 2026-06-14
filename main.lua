-- =============================================================================
-- AUTOMATED CORESYSTEM MEMORY BOOTSTRAPPER (MAIN.LUA)
-- =============================================================================

-- 1. INTERNAL MODULE DECLUSION LAYERS (MEMORY INJECTION ENGINE)
local MemoryModules = {
    ["esp_module"] = function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local Workspace = game:GetService("Workspace")
        local LocalPlayer = Players.LocalPlayer

        local ESP = {
            Enabled = false,
            Chams = false,
            HealthBars = false,
            Skeleton = false,
            Boxes = true,
            Names = true,
            WeaponText = true,
            MaxDistance = 500
        }

        local CharactersFolder = Workspace:WaitForChild("Characters", 5)
        local ESP_COLOR = Color3.fromRGB(255, 0, 0)
        local OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
        local FILL_TRANSPARENCY = 0.5
        local MAX_CHAMS = 30
        local ENGINE_CHAM_LIMIT = 1000

        local NAME_TEXT_SIZE = 11
        local NAME_TRANSPARENCY = 0.35
        local NAME_OFFSET_Y = 18

        local BODY_PARTS = {
            ["Head"] = true, ["Torso"] = true, ["UpperTorso"] = true, ["LowerTorso"] = true,
            ["HumanoidRootPart"] = true, ["Left Arm"] = true, ["Right Arm"] = true,
            ["Left Leg"] = true, ["Right Leg"] = true, ["LeftUpperArm"] = true,
            ["LeftLowerArm"] = true, ["LeftHand"] = true, ["RightUpperArm"] = true,
            ["RightLowerArm"] = true, ["RightHand"] = true, ["LeftUpperLeg"] = true,
            ["LeftLowerLeg"] = true, ["LeftFoot"] = true, ["RightUpperLeg"] = true,
            ["RightLowerLeg"] = true, ["RightFoot"] = true,
        }

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
            local d = Drawing.new(kind)
            for k, v in pairs(props) do d[k] = v end
            return d
        end

        local function ensureBones(data, count)
            while #data.Bones < count do
                table.insert(data.Bones, newDrawing("Line", {
                    Color = Color3.fromRGB(0, 255, 255), Thickness = 1, Visible = false,
                }))
            end
        end

        function ESP:GetTargetCharacterModel(player)
            if CharactersFolder then
                local target = CharactersFolder:FindFirstChild(player.Name)
                if target then return target end
            end
            return player.Character
        end

        function ESP:GetPlayerEquipment(player)
            local weaponName = nil
            local backpackName = nil
            
            local character = self:GetTargetCharacterModel(player)
            if not character then return nil, nil end

            for _, child in ipairs(character:GetChildren()) do
                local nameLower = child.Name:lower()

                if child:IsA("Folder") or child:IsA("Model") then
                    if string.find(nameLower, "backpack") or string.find(nameLower, "bag") or string.find(nameLower, "knapsack") then
                        backpackName = child.Name
                    elseif child.Name == "Equipped" or child.Name == "Equipment" then
                        for _, subChild in ipairs(child:GetChildren()) do
                            if subChild:IsA("Folder") or subChild:IsA("Model") then
                                local subNameLower = subChild.Name:lower()
                                if string.find(subNameLower, "backpack") or string.find(subNameLower, "bag") or string.find(subNameLower, "knapsack") then
                                    backpackName = subChild.Name
                                elseif subChild:FindFirstChild("Muzzle") or subChild:FindFirstChild("SightLine") or subChild:FindFirstChild("Base") then
                                    weaponName = subChild.Name
                                end
                            end
                        end
                        
                        if not weaponName or not backpackName then
                            local nameAttr = child:GetAttribute("ItemName") or child:GetAttribute("WeaponName")
                            if nameAttr then
                                local attrStr = tostring(nameAttr)
                                local attrLower = attrStr:lower()
                                if string.find(attrLower, "backpack") or string.find(attrLower, "bag") or string.find(attrLower, "knapsack") then
                                    backpackName = attrStr
                                else
                                    weaponName = attrStr
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
                Text = newDrawing("Text", { Color = Color3.fromRGB(255, 255, 255), Size = NAME_TEXT_SIZE, Center = true, Outline = true, Transparency = NAME_TRANSPARENCY, Visible = false }),
                Box = newDrawing("Square", { Color = ESP_COLOR, Thickness = 1.5, Filled = false, Visible = false }),
                HealthBg = newDrawing("Square", { Color = Color3.fromRGB(0,0,0), Thickness = 1, Filled = true, Visible = false }),
                HealthFill = newDrawing("Square", { Color = Color3.fromRGB(0,255,80), Thickness = 1, Filled = true, Visible = false }),
                WeaponText = newDrawing("Text", { Color = Color3.fromRGB(255, 200, 0), Size = 10, Center = true, Outline = true, Transparency = NAME_TRANSPARENCY, Visible = false }),
                BackpackText = newDrawing("Text", { Color = Color3.fromRGB(0, 180, 255), Size = 10, Center = true, Outline = true, Transparency = NAME_TRANSPARENCY, Visible = false }),
                Cham = nil,
                Bones = {},
            }
        end

        local function removeEntry(player)
            local d = ActiveESP[player]
            if not d then return end
            pcall(function()
                d.Text.Visible = false; d.Text:Remove()
                d.Box.Visible = false; d.Box:Remove()
                d.HealthBg.Visible = false; d.HealthBg:Remove()
                d.HealthFill.Visible = false; d.HealthFill:Remove()
                d.WeaponText.Visible = false; d.WeaponText:Remove()
                d.BackpackText.Visible = false; d.BackpackText:Remove()
                if d.Cham then d.Cham:Destroy() end
                for _, line in ipairs(d.Bones) do line.Visible = false; line:Remove() end
            end)
            ActiveESP[player] = nil
        end

        local function hideEntry(d)
            d.Text.Visible = false
            d.Box.Visible = false
            d.HealthBg.Visible = false
            d.HealthFill.Visible = false
            d.WeaponText.Visible = false
            d.BackpackText.Visible = false
            for _, line in ipairs(d.Bones) do line.Visible = false end
            if d.Cham then d.Cham:Destroy(); d.Cham = nil end
        end

        local function renderFrame()
            local camera = Workspace.CurrentCamera
            if not camera then return end

            local sorted = {}

            for player, d in pairs(ActiveESP) do
                local character = ESP:GetTargetCharacterModel(player)
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local head = character and character:FindFirstChild("Head")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local alive = humanoid and humanoid.Health > 0

                if ESP.Enabled and root and head and alive then
                    local camPos = camera.CFrame.Position
                    local dist = (camPos - root.Position).Magnitude
                    local _, onSc = camera:WorldToViewportPoint(root.Position)

                    if onSc and dist > 0.1 and dist <= ESP.MaxDistance then
                        table.insert(sorted, { Player = player, Data = d, Distance = dist, Character = character, Humanoid = humanoid })

                        local headPos, headOn = camera:WorldToViewportPoint(head.Position)
                        if headOn and ESP.Names then
                            d.Text.Position = Vector2.new(headPos.X, headPos.Y - NAME_OFFSET_Y)
                            d.Text.Text = player.Name .. " [" .. math.floor(dist) .. "m]"
                            d.Text.Visible = true
                        else
                            d.Text.Visible = false
                        end

                        local topWorld = head.Position + Vector3.new(0, head.Size.Y / 2, 0)
                        local lFoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")
                        local rFoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
                        local bottomWorld = (lFoot and rFoot)
                            and Vector3.new(root.Position.X, math.min(lFoot.Position.Y, rFoot.Position.Y) - 1, root.Position.Z)
                            or root.Position - Vector3.new(0, 3, 0)

                        local topSc, topOn = camera:WorldToViewportPoint(topWorld)
                        local bottomSc, bottomOn = camera:WorldToViewportPoint(bottomWorld)

                        local boxWidth, boxHeight, boxX, boxY

                        if topOn and bottomOn then
                            boxHeight = math.abs(bottomSc.Y - topSc.Y)
                            boxWidth = boxHeight * 0.45
                            boxX = topSc.X - boxWidth / 2
                            boxY = topSc.Y

                            if ESP.Boxes then
                                d.Box.Size = Vector2.new(boxWidth, boxHeight)
                                d.Box.Position = Vector2.new(boxX, boxY)
                                d.Box.Visible = true
                            else
                                d.Box.Visible = false
                            end
                        else
                            d.Box.Visible = false
                        end

                        local currentGun, currentBackpack = ESP:GetPlayerEquipment(player)
                        local currentYOffset = 4

                        if bottomOn and boxHeight and ESP.WeaponText then
                            d.WeaponText.Position = Vector2.new(topSc.X, boxY + boxHeight + currentYOffset)
                            d.WeaponText.Text = currentGun or "No Weapon"
                            d.WeaponText.Visible = true
                            currentYOffset = currentYOffset + 12

                            if currentBackpack then
                                d.BackpackText.Position = Vector2.new(topSc.X, boxY + boxHeight + currentYOffset)
                                d.BackpackText.Text = currentBackpack
                                d.BackpackText.Visible = true
                            else
                                d.BackpackText.Visible = false
                            end
                        else
                            d.WeaponText.Visible = false
                            d.BackpackText.Visible = false
                        end

                        if ESP.HealthBars and humanoid.MaxHealth > 0 and topOn and bottomOn and boxHeight then
                            local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                            local barX = boxX - 6
                            
                            d.HealthBg.Position = Vector2.new(barX - 1, boxY - 1)
                            d.HealthBg.Size = Vector2.new(5, boxHeight + 2)
                            d.HealthBg.Visible = true
                            
                            local fillH = boxHeight * ratio
                            d.HealthFill.Position = Vector2.new(barX, boxY + (boxHeight - fillH))
                            d.HealthFill.Size = Vector2.new(3, fillH)
                            d.HealthFill.Color = Color3.fromRGB(math.floor(255 * (1 - ratio)), math.floor(255 * ratio), 0)
                            d.HealthFill.Visible = true
                        else
                            d.HealthBg.Visible = false
                            d.HealthFill.Visible = false
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
                                d.Bones[i].From = pts[1]
                                d.Bones[i].To = pts[2]
                                d.Bones[i].Visible = true
                            end
                            for i = #validBones + 1, #d.Bones do d.Bones[i].Visible = false end
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
                if ESP.Chams and i <= MAX_CHAMS and item.Distance <= ENGINE_CHAM_LIMIT then
                    if not d.Cham or d.Cham.Parent ~= item.Character then
                        if d.Cham then d.Cham:Destroy() end
                        local hl = Instance.new("Highlight")
                        hl.FillColor = ESP_COLOR
                        hl.OutlineColor = OUTLINE_COLOR
                        hl.FillTransparency = FILL_TRANSPARENCY
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Adornee = item.Character
                        hl.Parent = item.Character
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

        function ESP:SetEnabled(state)
            self.Enabled = state
            if not state then
                self.Chams = false
                self.HealthBars = false
                self.Skeleton = false
                for _, d in pairs(ActiveESP) do hideEntry(d) end
            end
        end

        function ESP:SetChams(state) self.Chams = state end
        function ESP:SetSkeleton(state) self.Skeleton = state end

        function ESP:Init()
            for _, p in ipairs(Players:GetPlayers()) do createEntry(p) end
            Players.PlayerAdded:Connect(createEntry)
            Players.PlayerRemoving:Connect(removeEntry)
            RunService:BindToRenderStep("ESPRenderPipeline", Enum.RenderPriority.Camera.Value + 1, renderFrame)
        end

        return ESP
    end,

    ["teleport_module"] = function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local Workspace = game:GetService("Workspace")
        local LocalPlayer = Players.LocalPlayer

        local Teleport = {
            BehindOffset = 15,
            IsTracking = false,
            _currentTarget = nil
        }

        local CharactersFolder = Workspace:WaitForChild("Characters", 5)
        local trackingConnection = nil
        local onStatusChange = nil

        local function setStatus(msg, color)
            if onStatusChange then
                onStatusChange(msg, color or Color3.new(0.5, 0.5, 0.5))
            end
        end

        local function getTargetCharacterModel(player)
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
            local targetChar = targetPlayer and getTargetCharacterModel(targetPlayer)
            local myChar = getTargetCharacterModel(LocalPlayer)
            
            if not (targetPlayer and targetChar and myChar) then return end

            local myRoot = myChar:FindFirstChild("HumanoidRootPart")
            local myHuman = myChar:FindFirstChildOfClass("Humanoid")
            local tgtRoot = targetChar:FindFirstChild("HumanoidRootPart")

            if not (myRoot and myHuman and tgtRoot) then return end

            if myHuman:GetState() ~= Enum.HumanoidStateType.Physics then
                myHuman.PlatformStand = true
                myHuman:ChangeState(Enum.HumanoidStateType.Physics)
            end

            myRoot.CFrame = safeCFrame(tgtRoot, targetChar, myChar)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
        end

        function Teleport:OnStatusChange(callback)
            onStatusChange = callback
        end

        function Teleport:Once(targetName, onDone)
            if self.IsTracking then self:StopTracking() end

            local target = findPlayer(targetName)
            local targetChar = target and getTargetCharacterModel(target)
            local myChar = getTargetCharacterModel(LocalPlayer)
            
            if not target or not targetChar then
                setStatus("Player not found.", Color3.fromRGB(255, 80, 80))
                if onDone then onDone(false) end
                return
            end

            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local myHuman = myChar and myChar:FindFirstChildOfClass("Humanoid")
            local tgtRoot = targetChar:FindFirstChild("HumanoidRootPart")

            if not (myRoot and myHuman and tgtRoot) then
                if onDone then onDone(false) end
                return
            end

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

            trackingConnection = RunService.Heartbeat:Connect(function()
                local ok, err = pcall(doTeleport)
                if not ok then warn("Tracking error: " .. tostring(err)) end
            end)
        end

        function Teleport:StopTracking()
            self.IsTracking = false
            self._currentTarget = nil

            if trackingConnection then
                trackingConnection:Disconnect()
                trackingConnection = nil
            end

            local myChar = getTargetCharacterModel(LocalPlayer)
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
        end

        return Teleport
    end
}

-- 2. Secure Execution Routine (In-Memory Compiling)
local ESP = MemoryModules["esp_module"]()
local Teleport = MemoryModules["teleport_module"]()

-- 3. Initialize Core Engine Systems
_G.ESP = ESP
ESP:Init()
Teleport:Init()

-- 4. Build Rayfield UI Layer Configuration
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "🎯 Professional Combat Engine",
    Icon = 0,
    LoadingTitle = "Mapping Core Logic Streams...",
    LoadingSubtitle = "Production Integration",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = false }
})

-- Visual Tab Configuration
local Tab1 = Window:CreateTab("👁️ Player ESP", nil)

Tab1:CreateToggle({
    Name = "Master Player Toggle",
    CurrentValue = ESP.Enabled,
    Callback = function(v) ESP:SetEnabled(v) end
})

Tab1:CreateToggle({
    Name = "Bounding Boxes",
    CurrentValue = ESP.Boxes,
    Callback = function(v) ESP.Boxes = v end
})

Tab1:CreateToggle({
    Name = "Player Name Labels",
    CurrentValue = ESP.Names,
    Callback = function(v) ESP.Names = v end
})

Tab1:CreateToggle({
    Name = "Show Weapon Overlays",
    CurrentValue = ESP.WeaponText,
    Callback = function(v) ESP.WeaponText = v end
})

Tab1:CreateToggle({
    Name = "Chams Framework",
    CurrentValue = ESP.Chams,
    Callback = function(v) ESP:SetChams(v) end
})

Tab1:CreateToggle({
    Name = "Health Status Bars",
    CurrentValue = ESP.HealthBars,
    Callback = function(v) ESP.HealthBars = v end
})

Tab1:CreateToggle({
    Name = "Skeleton Frames",
    CurrentValue = ESP.Skeleton,
    Callback = function(v) ESP:SetSkeleton(v) end
})

Tab1:CreateInput({
    Name = "Max Render Depth Radius (Meters)",
    PlaceholderText = "500",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local num = tonumber(text)
        if num then ESP.MaxDistance = num end
    end
})

-- Movement Teleport Tab Configuration
local Tab2 = Window:CreateTab("🎯 Combat Teleport", nil)
local TargetInputString = ""

local StatusLabel = Tab2:CreateLabel("System State: Idle")
Teleport:OnStatusChange(function(msg, color)
    StatusLabel:Set("System State: " .. msg)
end)

Tab2:CreateInput({
    Name = "Target Player Name / Filter",
    PlaceholderText = "Username...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text) TargetInputString = text end
})

Tab2:CreateSlider({
    Name = "Behind Tracking Distance Offset",
    Info = "Distance in studs positioned directly behind the target.",
    Min = 5,
    Max = 30,
    CurrentValue = Teleport.BehindOffset,
    Callback = function(value) Teleport.BehindOffset = value end
})

Tab2:CreateButton({
    Name = "Instant Snap Position (Once)",
    Callback = function() Teleport:Once(TargetInputString) end
})

Tab2:CreateToggle({
    Name = "Engage Constant Tracking Loop",
    CurrentValue = Teleport.IsTracking,
    Callback = function(state)
        if state then
            Teleport:StartTracking(TargetInputString)
        else
            Teleport:StopTracking()
        end
    end
})

print("Main orchestration engine loaded successfully.")
