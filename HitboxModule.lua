-- =============================================================================
-- GHOST HITBOX SYSTEM (STABLE HYBRID ENGINE) - ROOT ONLY CLEAN
-- =============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Global fallback connection for game-specific folders
local CharactersFolder = _G.CharactersFolder or workspace:FindFirstChild("Characters")

local HitboxModule = {
	Active = false,
	HitboxSize = 10,
}

local hitboxConnection = nil

-- Schema: [character] = { rootSize = Vector3 }
local ModifiedTrackers = {}

local function applyHitboxExpansion(character)
	-- Physical Root Part Scale Modification
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
						if root then
							ModifiedTrackers[character] = {
								rootSize = root.Size
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
