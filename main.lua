-- =============================================================================
-- MAIN ENTRY INITIALIZATION LAUNCHER
-- =============================================================================

-- 1. Ensure Filesystem Integrity (Fallback Creation)
if not isfile("esp_module.lua") or not isfile("teleport_module.lua") then
    warn("Core modules missing from workspace disk! Generating production fallbacks...")
    
    -- In case you haven't saved them manually yet, this keeps the script from crashing
    pcall(function()
        if not isfile("esp_module.lua") then
            writefile("esp_module.lua", game:HttpGet("https://raw.githubusercontent.com/YourRepo/Project/main/esp_module.lua"))
        end
        if not isfile("teleport_module.lua") then
            writefile("teleport_module.lua", game:HttpGet("https://raw.githubusercontent.com/YourRepo/Project/main/teleport_module.lua"))
        end
    end)
end

-- 2. Secure Execution Routine via Protected Calls
local success, ESP, Teleport = pcall(function()
    local espObj = loadstring(readfile("esp_module.lua"))()
    local tpObj = loadstring(readfile("teleport_module.lua"))()
    return espObj, tpObj
end)

if not success or not ESP or not Teleport then
    error("CRITICAL BOOT FAILURE: Workspace modules failed to compile cleanly from disk layout.")
    return
end

-- 3. Initialize Engine Subsystems
_G.ESP = ESP
ESP:Init()
Teleport:Init()

-- 4. Build Rayfield Interface Environment
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "🎯 Professional Combat Engine",
    Icon = 0,
    LoadingTitle = "Mapping Core Logic Streams...",
    LoadingSubtitle = "Production Integration",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = false }
})

-- =============================================================================
-- INTERFACE LAYER: TAB 1 - VISUALS OVERLAY
-- =============================================================================
local Tab1 = Window:CreateTab("👁️ Player ESP", nil)

Tab1:CreateToggle({
    Name = "Master Player Toggle",
    CurrentValue = ESP.Enabled,
    Callback = function(v) ESP:SetEnabled(v) end
})

Tab1:CreateToggle({
    Name = "Bounding Boxes",
    CurrentValue = ESP.Boxes,
    Callback = function(v) ESP.Boxes = v end
})

Tab1:CreateToggle({
    Name = "Player Name Labels",
    CurrentValue = ESP.Names,
    Callback = function(v) ESP.Names = v end
})

Tab1:CreateToggle({
    Name = "Show Weapon Overlays",
    CurrentValue = ESP.WeaponText,
    Callback = function(v) ESP.WeaponText = v end
})

Tab1:CreateToggle({
    Name = "Chams Framework",
    CurrentValue = ESP.Chams,
    Callback = function(v) ESP:SetChams(v) end
})

Tab1:CreateToggle({
    Name = "Health Status Bars",
    CurrentValue = ESP.HealthBars,
    Callback = function(v) ESP.HealthBars = v end
})

Tab1:CreateToggle({
    Name = "Skeleton Frames",
    CurrentValue = ESP.Skeleton,
    Callback = function(v) ESP:SetSkeleton(v) end
})

Tab1:CreateInput({
    Name = "Max Render Depth Radius (Meters)",
    PlaceholderText = "500",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local num = tonumber(text)
        if num then ESP.MaxDistance = num end
    end
})

-- =============================================================================
-- INTERFACE LAYER: TAB 2 - POSITION MANIPULATION
-- =============================================================================
local Tab2 = Window:CreateTab("🎯 Combat Teleport", nil)
local TargetInputString = ""

local StatusLabel = Tab2:CreateLabel("System State: Idle")
Teleport:OnStatusChange(function(msg, color)
    StatusLabel:Set("System State: " .. msg)
end)

Tab2:CreateInput({
    Name = "Target Player Name / Filter",
    PlaceholderText = "Username...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text) TargetInputString = text end
})

Tab2:CreateSlider({
    Name = "Behind Tracking Distance Offset",
    Info = "Distance in studs positioned directly behind the target.",
    Min = 5,
    Max = 30,
    CurrentValue = Teleport.BehindOffset,
    Callback = function(value) Teleport.BehindOffset = value end
})

Tab2:CreateButton({
    Name = "Instant Snap Position (Once)",
    Callback = function() Teleport:Once(TargetInputString) end
})

Tab2:CreateToggle({
    Name = "Engage Constant Tracking Loop",
    CurrentValue = Teleport.IsTracking,
    Callback = function(state)
        if state then
            Teleport:StartTracking(TargetInputString)
        else
            Teleport:StopTracking()
        end
    end
})

print("Main orchestration engine loaded successfully.")
