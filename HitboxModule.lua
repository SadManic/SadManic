-- =============================================================================
-- 4. GHOST HITBOX SYSTEM (STABLE HYBRID ENGINE)
-- =============================================================================
local HitboxModule = {
    Active = false,
    HeadScale = 10,
    HitboxSize = 10,
}

local hitboxConnection = nil
local ModifiedTrackers = {}

local function applyHitboxExpansion(character)
    -- 1. Anti-Freeze Dynamic Mesh Scaling
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

    -- 2. Hookless Physical Hitbox Transformation
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart and rootPart:IsA("BasePart") then
        if rootPart.Size.X ~= HitboxModule.HitboxSize then
            rootPart.Size = Vector3.new(HitboxModule.HitboxSize, HitboxModule.HitboxSize, HitboxModule.HitboxSize)
            rootPart.Transparency = 1 
            rootPart.CanCollide = false
        end
    end
end

local function resetHitboxCache()
    for character, originalSize in pairs(ModifiedTrackers) do
        pcall(function()
            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
            end
        end)
    end
    table.clear(ModifiedTrackers)
end

function HitboxModule:Toggle(state)
    self.Active = state
    if not state then
        if hitboxConnection then
            hitboxConnection:Disconnect()
            hitboxConnection = nil
        end
        resetHitboxCache()
        print("[ChrisM] Hitbox engine safely suspended.")
        return
    end

    print("[ChrisM] Running stable hitbox framework pipeline...")

    hitboxConnection = RunService.Heartbeat:Connect(function()
        if not self.Active then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = CharactersFolder and CharactersFolder:FindFirstChild(player.Name) or player.Character
                if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
                    if not ModifiedTrackers[character] then
                        local root = character:FindFirstChild("HumanoidRootPart")
                        if root then ModifiedTrackers[character] = root.Size end
                    end
                    pcall(applyHitboxExpansion, character)
                end
            end
        end
    end)
    print("[ChrisM] Stable Target Expanders Active.")
end

-- =============================================================================
-- 5. BOOTSTRAP (GLOBAL ALLOCATION DEFINITION)
-- =============================================================================
print("[ChrisM] Initialising subsystems...")
_G.ESP      = ESP
_G.Teleport = Teleport
_G.Hitbox   = HitboxModule -- Declared globally so Rayfield UI can read it instantly!
