-- =====================
-- MODULE: Aimbot
-- =====================
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace       = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Aimbot = {}

-- ── State ──────────────────────────────────────────────────
Aimbot.Enabled       = false
Aimbot.WallCheck     = true
Aimbot.FOV           = 150
Aimbot.Smooth        = 3
Aimbot.TargetBone    = "Head"
Aimbot.TriggerInput  = Enum.UserInputType.MouseButton2
Aimbot.BulletVelocity = 800

local ActiveTarget  = nil
local OverlayCircle = nil

-- ── Private helpers ────────────────────────────────────────
local function getCamera()
    return Workspace.CurrentCamera
end

local function hasLineOfSight(part, character)
    if not Aimbot.WallCheck then return true end
    local camera = getCamera()
    local origin = camera.CFrame.Position
    local direction = part.Position - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, camera }
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, params)
    return not result or result.Instance:IsDescendantOf(character)
end

local function isValidTarget(player)
    if not player or not player.Character then return false end
    local character  = player.Character
    local part       = character:FindFirstChild(Aimbot.TargetBone)
    local humanoid   = character:FindFirstChildOfClass("Humanoid")
    if not (part and humanoid and humanoid.Health > 0) then return false end
    local _, onScreen = getCamera():WorldToViewportPoint(part.Position)
    return onScreen and hasLineOfSight(part, character)
end

local function findClosestTarget()
    local bestTarget  = nil
    local bestDist    = Aimbot.FOV
    local cursor      = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local character = player.Character
        local part      = character and character:FindFirstChild(Aimbot.TargetBone)
        local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
        if not (part and humanoid and humanoid.Health > 0) then continue end

        local projected, onScreen = getCamera():WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(projected.X, projected.Y) - cursor).Magnitude
        if dist < bestDist and hasLineOfSight(part, character) then
            bestDist   = dist
            bestTarget = player
        end
    end

    return bestTarget
end

-- ── Public API ─────────────────────────────────────────────
function Aimbot:SetEnabled(state)
    self.Enabled = state
    if not state then
        ActiveTarget = nil
        if OverlayCircle then OverlayCircle.Visible = false end
    end
end

function Aimbot:GetOverlayCircle()
    return OverlayCircle
end

function Aimbot:Init()
    OverlayCircle           = Drawing.new("Circle")
    OverlayCircle.Color     = Color3.fromRGB(0, 255, 255)
    OverlayCircle.Thickness = 1
    OverlayCircle.NumSides  = 64
    OverlayCircle.Filled    = false
    OverlayCircle.Visible   = false

    RunService.RenderStepped:Connect(function()
        local cursor = UserInputService:GetMouseLocation()

        -- FOV circle
        if self.Enabled then
            OverlayCircle.Position = cursor
            OverlayCircle.Radius   = self.FOV
            OverlayCircle.Visible  = true
        else
            OverlayCircle.Visible = false
        end

        -- Aim logic
        if self.Enabled and UserInputService:IsMouseButtonPressed(self.TriggerInput) then
            if not isValidTarget(ActiveTarget) then
                ActiveTarget = findClosestTarget()
            end

            if ActiveTarget and ActiveTarget.Character then
                local character = ActiveTarget.Character
                local bone      = character:FindFirstChild(self.TargetBone)
                local root      = character:FindFirstChild("HumanoidRootPart")
                if not (bone and root) then return end

                local camera   = getCamera()
                local camPos   = camera.CFrame.Position
                local distance = (camPos - bone.Position).Magnitude
                local travel   = distance / self.BulletVelocity
                local velocity = root.AssemblyLinearVelocity

                -- Lead + gravity compensation
                local lead      = bone.Position + (velocity * travel)
                local drop      = 0.5 * Workspace.Gravity * (travel ^ 2)
                local predicted = lead + Vector3.new(0, drop, 0)

                local projected, onScreen = camera:WorldToViewportPoint(predicted)
                if not onScreen then return end

                local dx = (projected.X - cursor.X) / self.Smooth
                local dy = (projected.Y - cursor.Y) / self.Smooth

                if typeof(mousemoverel) == "function" then
                    mousemoverel(dx, dy)
                end
            end
        else
            ActiveTarget = nil
        end
    end)
end

function Aimbot:Destroy()
    if OverlayCircle then
        OverlayCircle.Visible = false
        OverlayCircle:Remove()
        OverlayCircle = nil
    end
end

return Aimbot
