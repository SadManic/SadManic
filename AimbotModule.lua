-- =============================================================================
-- AUTOMATED TARGETING ENGINE - HIGH PRIOR_TIY PREDICTION REWRITE
-- =============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Aimbot = {
    Enabled = false,
    WallCheck = true,
    TargetPart = "Head",
    FOV = 120,
    Smoothness = 1, -- 1 is now a true frame-perfect snap
    PredictionFactor = 0.135 -- Adjust this slightly if it overshoots/undershoots running targets
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Transparency = 0.5
FOVCircle.Visible = false

local isRMBPressed = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end 
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRMBPressed = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRMBPressed = false
    end
end)

local function getTargetCharacterModel(player)
    local charsFolder = _G.CharactersFolder
    if charsFolder then
        local t = charsFolder:FindFirstChild(player.Name)
        if t then return t end
    end
    return player.Character
end

local function isVisible(camera, targetPart, targetCharacter)
    local myCharacter = getTargetCharacterModel(LocalPlayer)
    if not myCharacter then return false end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { myCharacter, targetCharacter, camera, Players }
    params.IgnoreWater = true

    local raycastResult = Workspace:Raycast(camera.CFrame.Position, targetPart.Position - camera.CFrame.Position, params)
    return raycastResult == nil
end

local function getClosestPlayerToCrosshair()
    local camera = Workspace.CurrentCamera
    if not camera then return nil, nil end

    local centerScreen = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local closestPart = nil
    local closestChar = nil
    local shortestDistance = Aimbot.FOV

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
                        
                        if Aimbot.WallCheck and not isVisible(camera, targetPart, character) then
                            continue 
                        end

                        shortestDistance = distanceToCenter
                        closestPart = targetPart
                        closestChar = character
                    end
                end
            end
        end
    end
    return closestPart, closestChar
end

local function processAimbotPipeline()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    
    if FOVCircle then
        FOVCircle.Radius = Aimbot.FOV
        FOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        FOVCircle.Visible = Aimbot.Enabled
    end

    if Aimbot.Enabled and isRMBPressed then
        local targetPart, targetChar = getClosestPlayerToCrosshair()
        if targetPart and targetChar then
            
            -- Get target's movement speed/velocity
            local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
            local velocity = rootPart and rootPart.AssemblyLinearVelocity or Vector3.zero
            
            -- Predict future position based on travel speed
            local predictedPosition = targetPart.Position + (velocity * Aimbot.PredictionFactor)
            
            local screenPos, onScreen = camera:WorldToViewportPoint(predictedPosition)
            if onScreen then
                local centerScreen = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                
                local deltaX = screenPos.X - centerScreen.X
                local deltaY = screenPos.Y - centerScreen.Y
                
                local smoothFactor = math.max(1, Aimbot.Smoothness)
                
                if mousemoverel then
                    -- If smoothness is 1, it passes raw delta for instantaneous snap
                    mousemoverel(deltaX / smoothFactor, deltaY / smoothFactor)
                end
            end
        end
    end
end

-- Bound to Render priority to execute right before frame layout compilation
RunService:BindToRenderStep("AimbotPredictivePipeline", Enum.RenderPriority.Last.Value, processAimbotPipeline)

_G.Aimbot = Aimbot
return Aimbot
