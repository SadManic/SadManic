-- =====================
-- MODULE: EventESP
-- =====================
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer

local EventESP = {}

EventESP.Enabled     = false
EventESP.MaxDistance = 1000

local EVENT_COLOR = Color3.fromRGB(185, 0, 255)

-- ── Registry (built synchronously at top level) ────────────
local ActiveEventRegistry = {}
local ok, eventsFolder = pcall(function()
    return ReplicatedStorage:WaitForChild("Map", 1):WaitForChild("RandomEvents", 1)
end)

if ok and eventsFolder then
    for _, template in ipairs(eventsFolder:GetChildren()) do
        ActiveEventRegistry[template.Name:lower()] = true
    end
    print("EventESP: Registry built with " .. tostring(#eventsFolder:GetChildren()) .. " events")
else
    -- Silently fallback to prevent the framework injector loop from crashing
    ActiveEventRegistry["__empty_fallback__"] = true
end

-- ── Apply / remove ─────────────────────────────────────────
local function applyESP(model)
    if model:FindFirstChild("_EventESP") then return end

    local anchorPart = model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart")
        or model:FindFirstChildWhichIsA("MeshPart")
    if not anchorPart then return end

    local hl = Instance.new("Highlight")
    hl.Name                = "_EventESP"
    hl.FillColor           = EVENT_COLOR
    hl.FillTransparency    = 0.7
    hl.OutlineColor        = EVENT_COLOR
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee             = model
    hl.Parent              = model

    local bb = Instance.new("BillboardGui")
    bb.Name          = "_EventESPBB"
    bb.Size          = UDim2.new(0, 250, 0, 50)
    bb.AlwaysOnTop   = true
    bb.ExtentsOffset = Vector3.new(0, 5, 0)
    bb.Adornee       = anchorPart
    bb.Parent        = model

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = EVENT_COLOR
    lbl.TextSize               = 14
    lbl.Font                   = Enum.Font.SourceSansBold
    lbl.TextStrokeTransparency = 0
    lbl.Parent                 = bb

    task.spawn(function()
        while model and model.Parent and anchorPart and anchorPart.Parent do
            if not EventESP.Enabled then
                hl.Enabled = false
                bb.Enabled = false
                task.wait(0.5)
            else
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local dist    = math.floor((myRoot.Position - anchorPart.Position).Magnitude)
                    local inRange = dist <= EventESP.MaxDistance
                    hl.Enabled    = inRange
                    bb.Enabled    = inRange
                    if inRange then
                        lbl.Text = "🚨 " .. model.Name:upper() .. " [" .. dist .. "m]"
                    end
                end
                task.wait(0.5)
            end
        end
    end)
end

local function removeESP(model)
    local hl = model:FindFirstChild("_EventESP")
    local bb = model:FindFirstChild("_EventESPBB")
    if hl then hl:Destroy() end
    if bb then bb:Destroy() end
end

local function evaluate(instance)
    if not instance:IsA("Model") then return end
    if not EventESP.Enabled then return end
    if ActiveEventRegistry[instance.Name:lower()] then
        applyESP(instance)
    end
end

local function scanAll()
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("Model") then
            if EventESP.Enabled and ActiveEventRegistry[desc.Name:lower()] then
                applyESP(desc)
            else
                removeESP(desc)
            end
        end
    end
end

-- ── Public API ─────────────────────────────────────────────
function EventESP:SetEnabled(state)
    self.Enabled = state
    scanAll()
end

function EventESP:Init()
    scanAll()

    Workspace.DescendantAdded:Connect(function(desc)
        if not EventESP.Enabled then return end
        task.wait(0.2)
        evaluate(desc)
    end)
end

function EventESP:Destroy()
    self.Enabled = false
    scanAll()
end

return EventESP
