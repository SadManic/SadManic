-- =====================
-- MODULE: ESP
-- =====================
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local ESP = {}

ESP.Enabled     = false
ESP.Chams       = false
ESP.HealthBars  = false
ESP.Skeleton    = false
ESP.Boxes       = true
ESP.Names       = true
ESP.WeaponText  = true
ESP.Zombies     = false
ESP.MaxDistance = 500

local ESP_COLOR         = Color3.fromRGB(255, 0, 0)
local OUTLINE_COLOR     = Color3.fromRGB(255, 255, 255)
local FILL_TRANSPARENCY = 0.5
local MAX_CHAMS         = 30
local ENGINE_CHAM_LIMIT = 1000

-- Name label config — small and semi-transparent for combat readability
local NAME_TEXT_SIZE    = 11       -- down from 14, less screen clutter
local NAME_TRANSPARENCY = 0.35    -- slight fade so it doesn't overpower the scene
local NAME_OFFSET_Y     = 18      -- tighter above head
local WEAPON_OFFSET_Y   = NAME_OFFSET_Y + 13

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

local function createEntry(player)
    if ActiveESP[player] or player == LocalPlayer then return end
    ActiveESP[player] = {
        Text = newDrawing("Text", {
            Color       = Color3.fromRGB(255, 255, 255),
            Size        = NAME_TEXT_SIZE,
            Center      = true,
            Outline     = true,
            Transparency = NAME_TRANSPARENCY,
            Visible     = false,
        }),
        Box = newDrawing("Square", {
            Color = ESP_COLOR, Thickness = 1.5, Filled = false, Visible = false,
        }),
        HealthBg = newDrawing("Square", {
            Color = Color3.fromRGB(0,0,0), Thickness = 1, Filled = true, Visible = false,
        }),
        HealthFill = newDrawing("Square", {
            Color = Color3.fromRGB(0,255,80), Thickness = 1, Filled = true, Visible = false,
        }),
        WeaponText = newDrawing("Text", {
            Color        = Color3.fromRGB(255, 200, 0),
            Size         = 10,
            Center       = true,
            Outline      = true,
            Transparency = NAME_TRANSPARENCY,
            Visible      = false,
        }),
        Cham  = nil,
        Bones = {},
    }
end

local function removeEntry(player)
    local d = ActiveESP[player]
    if not d then return end
    d.Text.Visible = false;       d.Text:Remove()
    d.Box.Visible = false;        d.Box:Remove()
    d.HealthBg.Visible = false;   d.HealthBg:Remove()
    d.HealthFill.Visible = false; d.HealthFill:Remove()
    d.WeaponText.Visible = false; d.WeaponText:Remove()
    if d.Cham then d.Cham:Destroy() end
    for _, line in ipairs(d.Bones) do line.Visible = false; line:Remove() end
    ActiveESP[player] = nil
end

local function hideEntry(d)
    d.Text.Visible       = false
    d.Box.Visible        = false
    d.HealthBg.Visible   = false
    d.HealthFill.Visible = false
    d.WeaponText.Visible = false
    for _, line in ipairs(d.Bones) do line.Visible = false end
    if d.Cham then d.Cham:Destroy(); d.Cham = nil end
end

local function renderFrame()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    local sorted = {}

    for player, d in pairs(ActiveESP) do
        local character = player.Character
        local root      = character and character:FindFirstChild("HumanoidRootPart")
        local head      = character and character:FindFirstChild("Head")
        local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
        local alive     = humanoid and humanoid.Health > 0

        if ESP.Enabled and root and head and alive then
            local camPos  = camera.CFrame.Position
            local dist    = (camPos - root.Position).Magnitude
            local _, onSc = camera:WorldToViewportPoint(root.Position)

            if onSc and dist > 0.1 and dist <= ESP.MaxDistance then
                table.insert(sorted, {
                    Player = player, Data = d,
                    Distance = dist, Character = character, Humanoid = humanoid
                })

                -- Name label — small, semi-transparent, distance shown in brackets
                local headPos, headOn = camera:WorldToViewportPoint(head.Position)
                if headOn and ESP.Names then
                    d.Text.Position     = Vector2.new(headPos.X, headPos.Y - NAME_OFFSET_Y)
                    d.Text.Text         = player.Name .. " [" .. math.floor(dist) .. "m]"
                    d.Text.Size         = NAME_TEXT_SIZE
                    d.Text.Transparency = NAME_TRANSPARENCY
                    d.Text.Visible      = true
                else
                    d.Text.Visible = false
                end

                -- Weapon label — one line below name
                local tool = character:FindFirstChildOfClass("Tool")
                if tool and headOn and ESP.WeaponText then
                    d.WeaponText.Position     = Vector2.new(headPos.X, headPos.Y - WEAPON_OFFSET_Y)
                    d.WeaponText.Text         = tool.Name
                    d.WeaponText.Size         = 10
                    d.WeaponText.Transparency = NAME_TRANSPARENCY
                    d.WeaponText.Visible      = true
                else
                    d.WeaponText.Visible = false
                end

                -- Bounding box
                local topWorld    = head.Position + Vector3.new(0, head.Size.Y / 2, 0)
                local lFoot       = character:FindFirstChild("LeftFoot")  or character:FindFirstChild("Left Leg")
                local rFoot       = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
                local bottomWorld = (lFoot and rFoot)
                    and Vector3.new(root.Position.X, math.min(lFoot.Position.Y, rFoot.Position.Y) - 1, root.Position.Z)
                    or  root.Position - Vector3.new(0, 3, 0)

                local topSc, topOn       = camera:WorldToViewportPoint(topWorld)
                local bottomSc, bottomOn = camera:WorldToViewportPoint(bottomWorld)

                if topOn and bottomOn and ESP.Boxes then
                    local h = math.abs(bottomSc.Y - topSc.Y)
                    local w = h * 0.45
                    d.Box.Size     = Vector2.new(w, h)
                    d.Box.Position = Vector2.new(topSc.X - w / 2, topSc.Y)
                    d.Box.Visible  = true
                else
                    d.Box.Visible = false
                end

                -- Health bar
                if ESP.HealthBars and humanoid.MaxHealth > 0 and topOn and bottomOn then
                    local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    local h     = math.abs(bottomSc.Y - topSc.Y)
                    local w     = h * 0.45
                    local bx    = topSc.X - w / 2
                    local by    = topSc.Y
                    local barX  = bx - 6
                    d.HealthBg.Position   = Vector2.new(barX - 1, by - 1)
                    d.HealthBg.Size       = Vector2.new(5, h + 2)
                    d.HealthBg.Visible    = true
                    local fillH = h * ratio
                    d.HealthFill.Position = Vector2.new(barX, by + (h - fillH))
                    d.HealthFill.Size     = Vector2.new(3, fillH)
                    d.HealthFill.Color    = Color3.fromRGB(
                        math.floor(255 * (1 - ratio)), math.floor(255 * ratio), 0
                    )
                    d.HealthFill.Visible = true
                else
                    d.HealthBg.Visible   = false
                    d.HealthFill.Visible = false
                end

                -- Skeleton
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
                                    Vector2.new(sA.X, sA.Y), Vector2.new(sB.X, sB.Y)
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
                    for i = #validBones + 1, #d.Bones do
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

    -- Chams sorted nearest-first
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

    -- Zombie ESP
    local zombieFolder = Workspace:FindFirstChild("Zombies")
    if ESP.Zombies and zombieFolder then
        for _, model in ipairs(zombieFolder:GetChildren()) do
            if model:IsA("Model") then
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    if not model:FindFirstChild("_ZombieESP") then
                        local hl = Instance.new("Highlight")
                        hl.Name                = "_ZombieESP"
                        hl.FillColor           = Color3.fromRGB(255, 80, 0)
                        hl.OutlineColor        = Color3.fromRGB(255, 80, 0)
                        hl.FillTransparency    = 0.5
                        hl.OutlineTransparency = 0
                        hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Adornee             = model
                        hl.Parent              = model
                    end
                end
            end
        end
    elseif not ESP.Zombies and zombieFolder then
        for _, model in ipairs(zombieFolder:GetChildren()) do
            local hl = model:FindFirstChild("_ZombieESP")
            if hl then hl:Destroy() end
        end
    end
end

function ESP:SetEnabled(state)
    self.Enabled = state
    if not state then
        self.Chams      = false
        self.HealthBars = false
        self.Skeleton   = false
        for _, d in pairs(ActiveESP) do
            if d.Cham then d.Cham:Destroy(); d.Cham = nil end
            for _, line in ipairs(d.Bones) do line.Visible = false end
        end
    end
end

function ESP:SetZombies(state)
    self.Zombies = state
    if not state then
        local zombieFolder = Workspace:FindFirstChild("Zombies")
        if zombieFolder then
            for _, model in ipairs(zombieFolder:GetChildren()) do
                local hl = model:FindFirstChild("_ZombieESP")
                if hl then hl:Destroy() end
            end
        end
    end
end

function ESP:SetChams(state)
    self.Chams = state
    if not state then
        for _, d in pairs(ActiveESP) do
            if d.Cham then d.Cham:Destroy(); d.Cham = nil end
        end
    end
end

function ESP:SetSkeleton(state)
    self.Skeleton = state
    if not state then
        for _, d in pairs(ActiveESP) do
            for _, l in ipairs(d.Bones) do l.Visible = false end
        end
    end
end

function ESP:Init()
    for _, p in ipairs(Players:GetPlayers()) do createEntry(p) end
    Players.PlayerAdded:Connect(createEntry)
    Players.PlayerRemoving:Connect(removeEntry)
    RunService:BindToRenderStep("ESPRenderPipeline", Enum.RenderPriority.Camera.Value + 1, renderFrame)
end

function ESP:Destroy()
    RunService:UnbindFromRenderStep("ESPRenderPipeline")
    for player in pairs(ActiveESP) do removeEntry(player) end
end

return ESP
