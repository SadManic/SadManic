-- =====================
-- MODULE: ItemESP
-- =====================
local Workspace         = game:GetService("Workspace")
local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer

local ItemESP = {}

ItemESP.Enabled     = true
ItemESP.Accessories = true
ItemESP.MaxDistance = 500

local ESP_COLOR  = Color3.fromRGB(255, 0, 100)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)

-- Known R6 and R15 body part names — these are NEVER items
local BODY_PARTS = {
    ["Head"] = true,
    ["Torso"] = true, ["UpperTorso"] = true, ["LowerTorso"] = true,
    ["HumanoidRootPart"] = true,
    ["Left Arm"] = true, ["Right Arm"] = true,
    ["Left Leg"] = true, ["Right Leg"] = true,
    ["LeftUpperArm"] = true, ["LeftLowerArm"] = true, ["LeftHand"] = true,
    ["RightUpperArm"] = true, ["RightLowerArm"] = true, ["RightHand"] = true,
    ["LeftUpperLeg"] = true, ["LeftLowerLeg"] = true, ["LeftFoot"] = true,
    ["RightUpperLeg"] = true, ["RightLowerLeg"] = true, ["RightFoot"] = true,
}

-- Accessory-style prefixes (for the sub-toggle)
local ACCESSORY_PREFIXES = { "accessory", "belt", "hat", "hair", "vest", "shirt", "pants", "backpack", "knapsack", "gear" }

local CharactersFolder = Workspace:WaitForChild("Characters", 5)

local function checkIsAccessory(name)
    -- Reject anything that is a known body part name
    if BODY_PARTS[name] then return false end
    local lowerName = name:lower()
    for _, prefix in ipairs(ACCESSORY_PREFIXES) do
        if string.sub(lowerName, 1, #prefix) == prefix then return true end
    end
    return false
end

local function isWornByPlayer(instance)
    if not instance or not instance.Parent then return false end

    -- Reject models whose name is a body part — these are limb meshes, not gear
    if BODY_PARTS[instance.Name] then return false end

    -- Must be a Model with at least one BasePart to be a wearable item
    if not instance:IsA("Model") then return false end
    if not (instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart") or instance:FindFirstChildWhichIsA("MeshPart")) then
        return false
    end

    -- Check A: inside Characters folder but not a top-level character model
    if CharactersFolder and instance:IsDescendantOf(CharactersFolder) then
        -- Top-level entries in Characters are the player models themselves — skip them
        if instance.Parent == CharactersFolder then return false end
        -- Must not be LocalPlayer's own character
        if LocalPlayer.Character and instance:IsDescendantOf(LocalPlayer.Character) then return false end
        return true
    end

    -- Check B: traverse up looking for an Equipment folder or a Humanoid
    -- (covers games that don't use a Characters folder)
    local cur   = instance.Parent
    local loops = 0
    while cur and cur ~= Workspace and loops < 6 do
        if not cur.Parent then break end
        -- If we find an Equipment folder or a model containing a Humanoid,
        -- this instance is worn/held by someone
        if cur.Name == "Equipment" then
            if LocalPlayer.Character and not instance:IsDescendantOf(LocalPlayer.Character) then
                return true
            end
        end
        if cur:FindFirstChildOfClass("Humanoid") then
            -- Make sure it's not our own character
            if cur ~= LocalPlayer.Character then
                return true
            end
        end
        cur   = cur.Parent
        loops = loops + 1
    end

    return false
end

local function applyESP(model)
    if model:FindFirstChild("_ItemESP") then return end

    local anchorPart = model.PrimaryPart
        or model:FindFirstChild("Base")
        or model:FindFirstChildWhichIsA("MeshPart")
        or model:FindFirstChildWhichIsA("BasePart")
    if not anchorPart then return end

    local hl = Instance.new("Highlight")
    hl.Name                = "_ItemESP"
    hl.FillColor           = ESP_COLOR
    hl.FillTransparency    = 0.5
    hl.OutlineColor        = ESP_COLOR
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee             = model
    hl.Parent              = model

    local bb = Instance.new("BillboardGui")
    bb.Name          = "_ItemESPBB"
    bb.Size          = UDim2.new(0, 200, 0, 50)
    bb.AlwaysOnTop   = true
    bb.ExtentsOffset = Vector3.new(0, 1, 0)
    bb.Adornee       = anchorPart
    bb.Parent        = model

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = TEXT_COLOR
    lbl.TextSize               = 13
    lbl.Font                   = Enum.Font.SourceSansBold
    lbl.TextStrokeTransparency = 0
    lbl.Parent                 = bb

    task.spawn(function()
        while model and model.Parent and anchorPart and anchorPart.Parent do
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

            if not ItemESP.Enabled then
                hl.Enabled = false
                bb.Enabled = false
            elseif myRoot then
                local dist    = math.floor((myRoot.Position - anchorPart.Position).Magnitude)
                local inRange = dist <= ItemESP.MaxDistance

                local isAcc = checkIsAccessory(model.Name)
                if isAcc and not ItemESP.Accessories then
                    hl.Enabled = false
                    bb.Enabled = false
                else
                    hl.Enabled = inRange
                    bb.Enabled = inRange
                    if inRange then
                        lbl.Text = model.Name .. " [" .. dist .. "m]"
                    end
                end
            end
            task.wait(0.3)
        end
    end)
end

local function removeESP(model)
    local hl = model:FindFirstChild("_ItemESP")
    local bb = model:FindFirstChild("_ItemESPBB")
    if hl then hl:Destroy() end
    if bb then bb:Destroy() end
end

local function evaluate(instance)
    if not instance or not instance.Parent then return end
    if not instance:IsA("Model") then return end
    if BODY_PARTS[instance.Name] then return end  -- fast reject body parts

    if isWornByPlayer(instance) then
        applyESP(instance)
    else
        removeESP(instance)
    end
end

local function scanAll()
    for _, desc in ipairs(Workspace:GetDescendants()) do
        pcall(function() evaluate(desc) end)
    end
end

function ItemESP:SetEnabled(state)
    self.Enabled = state
end

function ItemESP:SetAccessories(state)
    self.Accessories = state
end

function ItemESP:Init()
    scanAll()

    Workspace.DescendantAdded:Connect(function(desc)
        task.wait(0.1)
        pcall(function() evaluate(desc) end)
    end)

    Workspace.DescendantRemoving:Connect(function(desc)
        if desc:IsA("Model") then removeESP(desc) end
    end)
end

function ItemESP:Destroy()
    self.Enabled = false
end

return ItemESP
