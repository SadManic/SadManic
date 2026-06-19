-- =============================================================================
-- MATRIX CORE AUTOMATED TARGETING & FOV ENGINE (LMB & WALLCHECK INTEGRATED)
-- =============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Aimbot = {
    Enabled = false,
    WallCheck = true,      -- Filter targets behind solid walls/cover
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

local isLMBPressed = false

-- Hardware input listeners for the mouse hold state
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end -- Don't lock on if typing in chat/menus
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isLMBPressed = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isLMBPressed = false
    end
end)

-- Grabs the player model hook directly from your global folder configuration
local function getTargetCharacterModel(player)
    local charsFolder = _G.CharactersFolder
    if charsFolder then
        local t = charsFolder:FindFirstChild(player.Name)
        if t then return t end
    end
    return player.Character
end

-- Checks if a clear line of sight exists between your camera and the target's bone
local function isVisible(camera, targetPart, targetCharacter)
    local myCharacter = getTargetCharacterModel(LocalPlayer)
    if not myCharacter then return false end

    local origin = camera.CFrame.Position
    local destination = targetPart.Position
    local direction = destination - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    -- Ignore yourself, the target you are checking, the active camera viewport, and other players
    params.FilterDescendantsInstances = { myCharacter, targetCharacter, camera, Players }
    params.IgnoreWater = true

    local raycastResult = Workspace:Raycast(origin, direction, params)
    
    -- If raycastResult is nil, nothing blocked the line of sight
    return raycastResult == nil
end

-- Scan method utilizing your existing ActiveESP layout table to eliminate overhead
local function getClosestPlayerToCrosshair()
    local camera = Workspace.CurrentCamera
    if not camera then return nil end

    local centerScreen = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local closestPlayer = nil
    local shortestDistance = Aimbot.FOV

    -- Loops through your shared global ESP tracking table
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
                        
                        -- Process raycast geometry intercept checks if WallCheck option is turned on
                        if Aimbot.WallCheck and not isVisible(camera, targetPart, character) then
                            continue -- Skip this player entirely, they're behind a wall
                        end

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
    
    -- Keep visual FOV circle centered and size-matched
    if FOVCircle then
        FOVCircle.Radius = Aimbot.FOV
        FOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        FOVCircle.Visible = Aimbot.Enabled
    end

    -- Run target locking only if enabled in menu AND holding LMB
    if Aimbot.Enabled and isLMBPressed then
        local target = getClosestPlayerToCrosshair()
        if target then
            local currentCFrame = camera.CFrame
            
            if Aimbot.Smoothness == 1 then
                -- Frame-Perfect Hard Snap
                camera.CFrame = CFrame.lookAt(currentCFrame.Position, target.Part.Position)
            else
                -- Smooth Humanized Lerp Tracking
                local targetRotation = CFrame.lookAt(currentCFrame.Position, target.Part.Position)
                camera.CFrame = currentCFrame:Lerp(targetRotation, 1 / Aimbot.Smoothness)
            end
        end
    end
end

-- Instantiate loop
RunService:BindToRenderStep("AimbotTargetingPipeline", Enum.RenderPriority.Camera.Value + 1, processAimbotPipeline)

_G.Aimbot = Aimbot
return Aimbot
