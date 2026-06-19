-- =============================================================================
-- MATRIX CORE AUTOMATED TARGETING & FOV ENGINE
-- =============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Aimbot = {
    Enabled = false,
    TargetPart = "Head",   -- Options: "Head", "HumanoidRootPart", "UpperTorso"
    FOV = 120,             -- Radius in pixels
    Smoothness = 1,        -- 1 = Instant frame snap, higher = humanized lerp
}

-- Create interactive drawing asset
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Transparency = 0.5
FOVCircle.Visible = false

-- Grabs the player model hook directly from your existing global folder configuration
local function getTargetCharacterModel(player)
    local charsFolder = _G.CharactersFolder
    if charsFolder then
        local t = charsFolder:FindFirstChild(player.Name)
        if t then return t end
    end
    return player.Character
end

-- Scan method utilizing your existing ActiveESP layout table to eliminate overhead
local function getClosestPlayerToCrosshair()
    local camera = Workspace.CurrentCamera
    if not camera then return nil end

    local centerScreen = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local closestPlayer = nil
    local shortestDistance = Aimbot.FOV

    -- Loops through the shared global ESP tracking table
    local activeTable = _G.ActiveESP or {} 
    for player, _ in pairs(activeTable) do
        local character = getTargetCharacterModel(player)
        if character then
            local targetPart = character:FindFirstChild(Aimbot.TargetPart)
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local alive = humanoid and humanoid.Health > 0

            if targetPart and alive then
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distanceToCenter = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
                    if distanceToCenter < shortestDistance then
                        shortestDistance = distanceToCenter
                        closestPlayer = {
                            Part = targetPart,
                            ScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                        }
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Main calculation intercept pipeline
local function processAimbotPipeline()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    
    -- Dynamic FOV Realignment Check
    if FOVCircle then
        FOVCircle.Radius = Aimbot.FOV
        FOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        FOVCircle.Visible = Aimbot.Enabled
    end

    -- Execution calculations
    if Aimbot.Enabled then
        local target = getClosestPlayerToCrosshair()
        if target then
            local currentCFrame = camera.CFrame
            
            if Aimbot.Smoothness == 1 then
                -- Frame-Perfect Hard Snap: Deletes matrix interpolation overhead entirely
                camera.CFrame = CFrame.lookAt(currentCFrame.Position, target.Part.Position)
            else
                -- Humanized Smooth Tracking: Standard linear angle interpolation
                local targetRotation = CFrame.lookAt(currentCFrame.Position, target.Part.Position)
                camera.CFrame = currentCFrame:Lerp(targetRotation, 1 / Aimbot.Smoothness)
            end
        end
    end
end

function Aimbot:Init()
    -- Latency-free camera connection bypass loop execution
    RunService:BindToRenderStep("AimbotTargetingPipeline", Enum.RenderPriority.Camera.Value + 1, processAimbotPipeline)
end

_G.Aimbot = Aimbot
return Aimbot
