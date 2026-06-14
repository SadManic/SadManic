-- =============================================================================
-- GHOST HITBOX SYSTEM (STABLE HYBRID ENGINE)
-- =============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Global fallback connection for game-specific folders
local CharactersFolder = _G.CharactersFolder or workspace:FindFirstChild("Characters")

local HitboxModule = {
    Active = false,
    HeadScale = 10,
    HitboxSize = 10,
}

local hitboxConnection = nil
-- Schema: [character] = { rootSize = Vector3, headSize = Vector3, meshScale = Vector3, standardNeck = Vector3 }
local ModifiedTrackers = {}

local function applyHitboxExpansion(character)
    -- 1. Visual & Physical Head Scaling Adjustment
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

    -- 2. Physical Root Part Scale Modification
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
    for character, originalData in pairs(ModifiedTrackers) do
        pcall(function()
            if character and character.Parent then
                -- Return Root Part back to native configuration
                local root = character:FindFirstChild("HumanoidRootPart")
                if root and originalData.rootSize then
                    root.Size = originalData.rootSize
                    root.Transparency = 0 -- Revert to default visibility settings
                end
                
                -- Clean visual properties on Head
                local head = character:FindFirstChild("Head")
                if head then
                    local mesh = head:FindFirstChildOfClass("SpecialMesh")
                    if mesh and originalData.meshScale then
                        mesh.Scale = originalData.meshScale
                    elseif originalData.headSize then
                        head.Size = originalData.headSize
                    end
                    
                    local neck = head:FindFirstChild("NeckAttachment") or head:FindFirstChild("FaceCenterAttachment")
                    if neck and originalData.standardNeck then
                        neck.Position = originalData.standardNeck
                    end
                    head.CanCollide = true
                end
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
        
        local currentPlayers = Players:GetPlayers()
        for i = 1, #currentPlayers do
            local player = currentPlayers[i]
            if player ~= LocalPlayer then
                local character = CharactersFolder and CharactersFolder:FindFirstChild(player.Name) or player.Character
                
                if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
                    -- Cache exact structural scales prior to modifying properties
                    if not ModifiedTrackers[character] then
                        local root = character:FindFirstChild("HumanoidRootPart")
                        local head = character:FindFirstChild("Head")
                        local neck = head and (head:FindFirstChild("NeckAttachment") or head:FindFirstChild("FaceCenterAttachment"))
                        local mesh = head and head:FindFirstChildOfClass("SpecialMesh")
                        
                        if root and head then
                            ModifiedTrackers[character] = {
                                rootSize = root.Size,
                                headSize = head.Size,
                                meshScale = mesh and mesh.Scale or Vector3.new(1, 1, 1),
                                standardNeck = neck and neck.Position or Vector3.new(0, 0, 0)
                            }
                        end
                    end
                    
                    pcall(applyHitboxExpansion, character)
                end
            end
        end
    end)
    print("[ChrisM] Stable Target Expanders Active.")
end

-- Allocation hook for the global master framework
_G.Hitbox = HitboxModule
return HitboxModule
