-- =============================================================================
-- IMPROVED GHOST HITBOX SYSTEM (VISUAL PRESERVATION ENGINE)
-- =============================================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HitboxModule = {
    Active = false,
    HitboxSize = 12,        -- Change this number to adjust your hitbox size!
    ShowVisualBox = true,   -- Set to true to see the hitbox outline, false to hide it
}

local ModifiedTrackers = {}
local Connections = {}

local function applyCleanHitbox(player)
    if player == LocalPlayer then return end

    local function setupCharacter(character)
        local root = character:WaitForChild("HumanoidRootPart", 5)
        if not root or not root:IsA("BasePart") then return end
        if ModifiedTrackers[character] then return end

        -- 1. Cache the original state before touching anything
        ModifiedTrackers[character] = {
            Size = root.Size,
            Transparency = root.Transparency,
            CanCollide = root.CanCollide
        }

        -- 2. Expand the root part hit area cleanly
        root.Size = Vector3.new(HitboxModule.HitboxSize, HitboxModule.HitboxSize, HitboxModule.HitboxSize)
        root.Transparency = 1 -- Keep it perfectly invisible so it doesn't block your view
        root.CanCollide = false

        -- 3. Create a clean visual box outline so you can "taste" the size
        local visualBox
        if HitboxModule.ShowVisualBox then
            visualBox = Instance.new("SelectionBox")
            visualBox.Name = "HitboxVisual"
            visualBox.Adornee = root
            visualBox.Color3 = Color3.fromRGB(255, 0, 100) -- Clean neon pink outline
            visualBox.LineThickness = 0.05
            visualBox.Transparency = 0.3
            visualBox.Parent = root
        end

        -- 4. Anti-Reset: If the game tries to shrink it back down, force our size
        local propertyConnection
        propertyConnection = root:GetPropertyChangedSignal("Size"):Connect(function()
            if HitboxModule.Active and root.Parent then
                root.Size = Vector3.new(HitboxModule.HitboxSize, HitboxModule.HitboxSize, HitboxModule.HitboxSize)
            else
                propertyConnection:Disconnect()
            end
        end)
    end

    if player.Character then task.spawn(setupCharacter, player.Character) end
    Connections[player] = player.CharacterAdded:Connect(setupCharacter)
end

function HitboxModule:Toggle(state)
    self.Active = state
    
    if not state then
        -- Clean up player listeners
        for player, connection in pairs(Connections) do
            connection:Disconnect()
        end
        table.clear(Connections)
        
        -- Safely revert all characters to native configuration
        for character, original in pairs(ModifiedTrackers) do
            pcall(function()
                local root = character:FindFirstChild("HumanoidRootPart")
                if root then
                    -- Remove our visual outline box
                    local visual = root:FindFirstChild("HitboxVisual")
                    if visual then visual:Destroy() end
                    
                    -- Reset properties
                    root.Size = original.Size
                    root.Transparency = original.Transparency
                    root.CanCollide = original.CanCollide
                end
            end)
        end
        table.clear(ModifiedTrackers)
        print("[ChrisM] Hitbox framework safely suspended.")
        return
    end
    
    print("[ChrisM] Stable Visual Expanders Active.")
    
    -- Hook current players
    for _, player in ipairs(Players:GetPlayers()) do
        applyCleanHitbox(player)
    end
    
    -- Hook future players
    Connections["PlayerAdded"] = Players.PlayerAdded:Connect(applyCleanHitbox)
end

-- Allocation hook for executor environment
_G.Hitbox = HitboxModule
return HitboxModule
