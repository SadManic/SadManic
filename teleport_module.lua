local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Teleport = {
    BehindOffset = 15,
    IsTracking = false,
    _currentTarget = nil
}

local CharactersFolder = Workspace:WaitForChild("Characters", 5)
local trackingConnection = nil
local onStatusChange = nil

local function setStatus(msg, color)
    if onStatusChange then
        onStatusChange(msg, color or Color3.new(0.5, 0.5, 0.5))
    end
end

local function getTargetCharacterModel(player)
    if CharactersFolder then
        local target = CharactersFolder:FindFirstChild(player.Name)
        if target then return target end
    end
    return player.Character
end

local function findPlayer(name)
    if name == "" then return nil end
    local lower = string.lower(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if string.sub(string.lower(p.Name), 1, #lower) == lower
        or string.sub(string.lower(p.DisplayName), 1, #lower) == lower then
            return p
        end
    end
    return nil
end

local function safeCFrame(targetRoot, targetChar, myChar)
    local cf = targetRoot.CFrame
    local offset = math.max(5, math.abs(Teleport.BehindOffset))
    local ideal = (cf * CFrame.new(0, 0, offset)).Position

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { myChar, targetChar, Workspace.CurrentCamera, Players }
    params.IgnoreWater = true

    local wallHit = Workspace:Raycast(cf.Position, ideal - cf.Position, params)
    local pos = wallHit and (wallHit.Position + wallHit.Normal * 2.5) or ideal

    local floorHit = Workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -12, 0), params)
    if floorHit then pos = Vector3.new(pos.X, floorHit.Position.Y + 3, pos.Z) end

    return CFrame.new(pos, pos + cf.LookVector)
end

local function doTeleport()
    local targetPlayer = Teleport._currentTarget
    local targetChar = targetPlayer and getTargetCharacterModel(targetPlayer)
    local myChar = getTargetCharacterModel(LocalPlayer)
    
    if not (targetPlayer and targetChar and myChar) then return end

    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local myHuman = myChar:FindFirstChildOfClass("Humanoid")
    local tgtRoot = targetChar:FindFirstChild("HumanoidRootPart")

    if not (myRoot and myHuman and tgtRoot) then return end

    if myHuman:GetState() ~= Enum.HumanoidStateType.Physics then
        myHuman.PlatformStand = true
        myHuman:ChangeState(Enum.HumanoidStateType.Physics)
    end

    myRoot.CFrame = safeCFrame(tgtRoot, targetChar, myChar)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero
end

function Teleport:OnStatusChange(callback)
    onStatusChange = callback
end

function Teleport:Once(targetName, onDone)
    if self.IsTracking then self:StopTracking() end

    local target = findPlayer(targetName)
    local targetChar = target and getTargetCharacterModel(target)
    local myChar = getTargetCharacterModel(LocalPlayer)
    
    if not target or not targetChar then
        setStatus("Player not found.", Color3.fromRGB(255, 80, 80))
        if onDone then onDone(false) end
        return
    end

    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHuman = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local tgtRoot = targetChar:FindFirstChild("HumanoidRootPart")

    if not (myRoot and myHuman and tgtRoot) then
        if onDone then onDone(false) end
        return
    end

    myRoot.Anchored = true
    myHuman.PlatformStand = true
    myHuman:ChangeState(Enum.HumanoidStateType.Physics)

    if LocalPlayer.RequestStreamAroundAsync then
        pcall(function() LocalPlayer:RequestStreamAroundAsync(tgtRoot.Position) end)
    end

    myRoot.CFrame = safeCFrame(tgtRoot, targetChar, myChar)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero

    RunService.Heartbeat:Wait()
    RunService.Heartbeat:Wait()

    myHuman.PlatformStand = false
    myHuman:ChangeState(Enum.HumanoidStateType.Running)
    myRoot.Anchored = false

    setStatus("Teleported to " .. target.Name .. ".", Color3.fromRGB(0, 200, 80))
    if onDone then onDone(true) end
end

function Teleport:StartTracking(targetName, onSuccess, onFail)
    if self.IsTracking then return end

    local target = findPlayer(targetName)
    if not target then
        setStatus("Player not found.", Color3.fromRGB(255, 80, 80))
        if onFail then onFail() end
        return
    end

    self._currentTarget = target
    self.IsTracking = true

    setStatus("Tracking " .. target.Name .. "...", Color3.fromRGB(0, 213, 255))
    if onSuccess then onSuccess(target) end

    trackingConnection = RunService.Heartbeat:Connect(function()
        local ok, err = pcall(doTeleport)
        if not ok then warn("Tracking error: " .. tostring(err)) end
    end)
end

function Teleport:StopTracking()
    self.IsTracking = false
    self._currentTarget = nil

    if trackingConnection then
        trackingConnection:Disconnect()
        trackingConnection = nil
    end

    local myChar = getTargetCharacterModel(LocalPlayer)
    if myChar then
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        local myHuman = myChar:FindFirstChildOfClass("Humanoid")
        if myRoot and myHuman then
            myRoot.Anchored = true
            myHuman.PlatformStand = false
            myHuman:ChangeState(Enum.HumanoidStateType.GettingUp)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
            RunService.Heartbeat:Wait()
            RunService.Heartbeat:Wait()
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
            myHuman:ChangeState(Enum.HumanoidStateType.Running)
            myRoot.Anchored = false
        end
    end

    setStatus("Idle", Color3.fromRGB(150, 150, 150))
end

function Teleport:Init()
    Players.PlayerRemoving:Connect(function(p)
        if self.IsTracking and self._currentTarget == p then
            setStatus("Target left.", Color3.fromRGB(255, 80, 80))
            self:StopTracking()
        end
    end)
end

return Teleport
