-- =============================================================================
-- MANIC EXECUTOR COMBAT UTILITY SUITE: HITBOX COMPLIANCE MODULE
-- =============================================================================
local HitboxModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Internal tracking states
local masterConnection = nil
local gameMetatable = nil
local oldIndex = nil
local oldNewIndex = nil

local CharactersFolder = Workspace:WaitForChild("Characters", 5)

-- Global adjustments managed via the module references
HitboxModule.Active = false
HitboxModule.HeadScale = 10
HitboxModule.HitboxSize = 10
HitboxModule.ChamColor = Color3.fromRGB(255, 0, 80)

-- Core internal asset pipeline
local function applyExpansion(character)
    -- 1. Apply Chams Visuals
    if not character:FindFirstChild("VisualCham") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "VisualCham"
        highlight.FillColor = HitboxModule.ChamColor
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character
    end

    -- 2. Anti-Freeze Head Mesh Scaling
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        local mesh = head:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            mesh.Scale = Vector3.new(HitboxModule.HeadScale, HitboxModule.HeadScale, HitboxModule.HeadScale)
        else
            head.Size = Vector3.new(HitboxModule.HeadScale, HitboxModule.HeadScale, HitboxModule.HeadScale)
        end
        
        local neck = head:FindFirstChild("NeckAttachment") or head:FindFirstChild("FaceCenterAttachment")
        if neck and neck:IsA("Attachment") then
            neck.Position = Vector3.new(0, -HitboxModule.HeadScale / 4, 0)
        end
        head.CanCollide = false
    end

    -- 3. Spoofed Physical Hitbox Expansion
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart and rootPart:IsA("BasePart") then
        setreadonly(gameMetatable, false)
        rootPart.Size = Vector3.new(HitboxModule.HitboxSize, HitboxModule.HitboxSize, HitboxModule.HitboxSize)
        rootPart.Transparency = 0.75
        rootPart.Color = Color3.fromRGB(0, 255, 255) -- Cyan box indicator
        rootPart.Material = Enum.Material.Neon
        rootPart.CanCollide = false
        setreadonly(gameMetatable, true)
    end
end

-- Hook initialization matrix
local function initMetatables()
    if oldIndex and oldNewIndex then return end -- Already hooked safely

    gameMetatable = getrawmetatable(game)
    oldIndex = gameMetatable.__index
    oldNewIndex = gameMetatable.__newindex
    setreadonly(gameMetatable, false)

    gameMetatable.__index = newcclosure(function(self, key)
        if HitboxModule.Active and typeof(self) == "Instance" and self:IsA("Part") and self.Name == "HumanoidRootPart" then
            if key == "Size" then return Vector3.new(2, 2, 1)
            elseif key == "Transparency" then return 1 end
        end
        return oldIndex(self, key)
    end)

    gameMetatable.__newindex = newcclosure(function(self, key, value)
        if HitboxModule.Active and typeof(self) == "Instance" and self:IsA("Part") and self.Name == "HumanoidRootPart" then
            if key == "Size" or key == "Transparency" or key == "CFrame" then return end
        end
        return oldNewIndex(self, key, value)
    end)
    
    setreadonly(gameMetatable, true)
end

-- Public Operational Controls
function HitboxModule.Toggle(state)
    HitboxModule.Active = state
    
    if not state then
        if masterConnection then
            masterConnection:Disconnect()
            masterConnection = nil
        end
        print("[Manic Module] Hitbox engine offline.")
        return
    end

    -- Ensure advanced protection layers are bound securely
    assert(hookmetamethod, "CRITICAL ERROR: Environment missing hookmetamethod capabilities.")
    initMetatables()

    -- Run processing pipeline loop
    masterConnection = RunService.Heartbeat:Connect(function()
        if not HitboxModule.Active then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = CharactersFolder and CharactersFolder:FindFirstChild(player.Name) or player.Character
                if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
                    pcall(applyExpansion, character)
                end
            end
        end
    end)

    print("[Manic Module] Hitbox engine running and spoofing.")
end

return HitboxModule
