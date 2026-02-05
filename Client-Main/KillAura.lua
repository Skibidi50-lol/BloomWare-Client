local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Systems = ReplicatedStorage:WaitForChild("Systems")
local ActionsSystem = Systems:WaitForChild("ActionsSystem")
local Network = ActionsSystem:WaitForChild("Network")
local AttackRemote = Network:WaitForChild("Attack")

local KILL_AURA_ENABLED = false
local AURA_RANGE = 100
local ATTACK_DELAY = 0.15
local ATTACK_SLOT = "1"
local TARGET_PLAYERS = true
local TARGET_ENTITIES = false
local ONLY_LIVING_TARGETS = false


local WHITELIST = {}

local function isWhitelisted(name)
    name = name:lower()
    for _, protected in ipairs(WHITELIST) do
        if name == protected:lower() then
            return true
        end
    end
    return false
end

local function getMyPosition()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart.Position
    end
    return nil
end

local connection
connection = RunService.Heartbeat:Connect(function()
    if not KILL_AURA_ENABLED then 
        return 
    end
    
    local myPos = getMyPosition()
    if not myPos then 
        return 
    end
    
    if TARGET_PLAYERS then
        for _, player in Players:GetPlayers() do
            if player == LocalPlayer then continue end
            if isWhitelisted(player.Name) then continue end
            
            local targetChar = player.Character
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and targetChar:FindFirstChild("Humanoid") then
                if ONLY_LIVING_TARGETS and targetChar.Humanoid.Health <= 0 then continue end
                
                local dist = (myPos - targetChar.HumanoidRootPart.Position).Magnitude
                if dist <= AURA_RANGE then
                    pcall(function()
                        AttackRemote:InvokeServer(targetChar, ATTACK_SLOT)
                    end)
                end
            end
        end
    end
    
    if TARGET_ENTITIES then
        local entities = workspace:FindFirstChild("Entities")
        if entities then
            for _, entity in entities:GetChildren() do
                if entity:IsA("Model") and entity:FindFirstChild("HumanoidRootPart") and entity:FindFirstChild("Humanoid") then
                    if ONLY_LIVING_TARGETS and entity.Humanoid.Health <= 0 then continue end
                    
                    local dist = (myPos - entity.HumanoidRootPart.Position).Magnitude
                    if dist <= AURA_RANGE then
                        pcall(function()
                            AttackRemote:InvokeServer(entity, ATTACK_SLOT)
                        end)
                    end
                end
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
end)
