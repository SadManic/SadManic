-- =====================
-- MODULE: Fullbright
-- =====================
local Lighting = game:GetService("Lighting")

local Fullbright = {}

Fullbright.Enabled = false

-- Snapshot original values on module load (before any changes)
local Original = {
    Brightness     = Lighting.Brightness,
    ClockTime      = Lighting.ClockTime,
    FogEnd         = Lighting.FogEnd,
    GlobalShadows  = Lighting.GlobalShadows,
    Ambient        = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

local removedEffects = {}  -- [Instance] = originalParent

function Fullbright:Apply()
    -- Strip PostEffects, Sky, and Atmosphere
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Sky") or effect:IsA("Atmosphere") then
            removedEffects[effect] = effect.Parent
            effect.Parent = nil
        end
    end

    Lighting.Brightness     = 2
    Lighting.ClockTime      = 14
    Lighting.FogEnd         = 100000
    Lighting.GlobalShadows  = false
    Lighting.Ambient        = Color3.fromRGB(178, 178, 178)
    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
end

function Fullbright:Remove()
    for effect, parent in pairs(removedEffects) do
        pcall(function() effect.Parent = parent end)
    end
    removedEffects = {}

    Lighting.Brightness     = Original.Brightness
    Lighting.ClockTime      = Original.ClockTime
    Lighting.FogEnd         = Original.FogEnd
    Lighting.GlobalShadows  = Original.GlobalShadows
    Lighting.Ambient        = Original.Ambient
    Lighting.OutdoorAmbient = Original.OutdoorAmbient
end

function Fullbright:SetEnabled(state)
    self.Enabled = state
    if state then self:Apply() else self:Remove() end
end

return Fullbright
