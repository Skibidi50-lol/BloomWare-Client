--esp = chat gpt
--Voxelized = ez

loadstring(game:HttpGet("https://raw.githubusercontent.com/Skibidi50-lol/BloomWare-Client/refs/heads/main/Client-Main/Client_Loader.lua"))()

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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP_ENABLED = false
local BOX_COLOR     = Color3.fromRGB(255, 255, 0)
local TRACER_COLOR  = Color3.fromRGB(255, 255, 0)
local TEXT_COLOR    = Color3.fromRGB(255, 255, 255)

local SHOW_BOX      = false
local SHOW_TRACERS  = false
local SHOW_NAME     = false
local SHOW_DISTANCE = false

local espObjects = {}

local function getModelName(model)
    local name = model.Name or "Unknown"
    if name:lower():find("drop") or name:find("Collector") then
        return "DROP"
    end
    return name
end

local function removeESPForModel(model)
    if espObjects[model] then
        for _, drawing in pairs(espObjects[model]) do
            if drawing and drawing.Remove then
                pcall(drawing.Remove, drawing)
            end
        end
        espObjects[model] = nil
    end
end

local function createESP(model)
    if espObjects[model] or model == LocalPlayer.Character then
        return
    end

    local root = model:FindFirstChild("HumanoidRootPart") 
              or model:FindFirstChild("HumanoidoidRootPart") 
              or model:FindFirstChild("TorsoPart")
              or model.PrimaryPart

    local head = model:FindFirstChild("HeadPart") 
              or model:FindFirstChild("HeadLayer") 
              or model:FindFirstChild("Head")

    if not root or not head then return end

    local bottom = root
    for _, name in {"LeftLeg", "RightLeg", "TorsoPart", "VisibleTorso"} do
        local p = model:FindFirstChild(name)
        if p then bottom = p break end
    end

    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Transparency = 1
    box.Color = BOX_COLOR

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1.5
    tracer.Transparency = 1
    tracer.Color = TRACER_COLOR

    local nameLabel = Drawing.new("Text")
    nameLabel.Size = 15
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.Color = TEXT_COLOR
    nameLabel.Font = Drawing.Fonts.UI

    espObjects[model] = {
        Box = box,
        Tracer = tracer,
        Name = nameLabel,
        Root = root,
        Head = head,
        Bottom = bottom,
        ModelName = getModelName(model)
    }

    -- Cleanup when model is destroyed/removed
    local ancestryConn
    ancestryConn = model.AncestryChanged:Connect(function(_, newParent)
        if not newParent then
            removeESPForModel(model)
            ancestryConn:Disconnect()
        end
    end)
end

local function updateESP()
    if not ESP_ENABLED then
        for _, data in pairs(espObjects) do
            data.Box.Visible = false
            data.Tracer.Visible = false
            data.Name.Visible = false
        end
        return
    end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local myPos = myRoot.Position

    for model, data in pairs(espObjects) do
        local root = data.Root
        local head = data.Head
        local bottom = data.Bottom

        if not (root and root.Parent and head and head.Parent) then
            data.Box.Visible = false
            data.Tracer.Visible = false
            data.Name.Visible = false
            continue
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.8, 0))
        local bottomPos = Camera:WorldToViewportPoint(bottom.Position - Vector3.new(0, 0.8, 0))

        local depthOk = rootPos.Z > 0

        if not (onScreen and depthOk) then
            data.Box.Visible = false
            data.Tracer.Visible = false
            data.Name.Visible = false
            continue
        end

        local top    = Vector2.new(headPos.X, headPos.Y)
        local bot    = Vector2.new(bottomPos.X, bottomPos.Y)
        local height = math.max((bot.Y - top.Y), 20)
        local width  = height * 0.55

        data.Box.Size     = Vector2.new(width, height)
        data.Box.Position = Vector2.new(rootPos.X - width/2, top.Y)
        data.Box.Visible  = SHOW_BOX

        if SHOW_TRACERS then
            data.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            data.Tracer.To   = Vector2.new(rootPos.X, bot.Y)
            data.Tracer.Visible = true
        else
            data.Tracer.Visible = false
        end

        if SHOW_NAME then
            local text = data.ModelName
            if SHOW_DISTANCE then
                local dist = (root.Position - myPos).Magnitude
                text = text .. " [" .. math.floor(dist) .. "]"
            end
            data.Name.Text     = text
            data.Name.Position = Vector2.new(rootPos.X, top.Y - 18)
            data.Name.Visible  = true
        else
            data.Name.Visible = false
        end
    end
end

local function setupPlayerESP(player)
    if player == LocalPlayer then return end

    local function onCharacterAdded(char)
        -- Wait a tiny bit for character to fully load
        task.wait(0.5)

        -- Remove old ESP if any (previous character)
        removeESPForModel(player.Character)  -- just in case

        -- Create new ESP
        createESP(char)
    end

    -- If character already exists
    if player.Character then
        onCharacterAdded(player.Character)
    end

    -- Listen for future respawns
    player.CharacterAdded:Connect(onCharacterAdded)

    -- Also remove ESP when player leaves
    player.CharacterRemoving:Connect(function(oldChar)
        removeESPForModel(oldChar)
    end)
end

-- Setup for all current players
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayerESP(player)
end

-- New players
Players.PlayerAdded:Connect(setupPlayerESP)

task.spawn(function()
    while task.wait(2) do
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character then
                if obj.Name:lower():find("drop") 
                or obj:FindFirstChild("HumanoidRootPart") 
                or obj:FindFirstChild("HumanoidoidRootPart") then
                    createESP(obj)
                end
            end
        end
    end
end)


RunService.RenderStepped:Connect(updateESP)

local repo = 'https://raw.githubusercontent.com/Skibidi50-lol/BloomWare-Client/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local speed = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stratxgy/Lua-Speed/refs/heads/main/speed.lua"))()

local Window = Library:CreateWindow({
    Title = 'Voxelized | BLOOMWARE CLIENT | discord.gg/4y7es694AQ',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Combat = Window:AddTab('Combat'),
    Duping = Window:AddTab('Duping'),
    Player = Window:AddTab('Player'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

--Killaura
local killBox = Tabs.Combat:AddLeftGroupbox('Kill Aura')

killBox:AddToggle('AuraToggle', {
    Text = 'Kill Aura',
    Default = false, -- Default value (true / false)
    Tooltip = 'Killing Everything Around You', -- Information shown when you hover over the toggle

    Callback = function(Value)
        KILL_AURA_ENABLED = Value
        Library:Notify("Kill Aura: " .. Value, 4)
    end
})

killBox:AddLabel('Keybind'):AddKeyPicker('AuraKeybind', {
    Default = 'I',       -- Default keybind (MB1, MB2 for mouse buttons or keyboard keys)
    SyncToggleState = true, -- Syncs with the Kill Aura toggle

    Mode = 'Toggle',        -- Modes: Always, Toggle, Hold
    Text = 'Kill Aura Keybind',
    NoUI = false,           -- Show in keybind menu

    Callback = function(Value)
        -- This triggers when you press the key
        KILL_AURA_ENABLED = Value
        Library:Notify("Kill Aura: " .. tostring(Value), 4)
    end,

    ChangedCallback = function(New)
        print('[cb] Kill Aura Keybind changed to:', New)
    end
})


killBox:AddDropdown('ItemSlotAuraDropdown', {
    Values = { '1', '2', '3', '4', '5', '6', '7', '8', '9' },
    Default = 1, -- number index of the value / string
    Multi = false, -- true / false, allows multiple choices to be selected

    Text = 'Item Slot',
    Tooltip = 'Choose The Slot The Kill Aura Will Active At', -- Information shown when you hover over the dropdown

    Callback = function(Value)
        ATTACK_SLOT = Value
    end
})


killBox:AddDivider()

killBox:AddToggle('MobAuraToggle', {
    Text = 'Target Entities/Mobs',
    Default = false, -- Default value (true / false)
    Tooltip = 'Enable Mobs Killing', -- Information shown when you hover over the toggle

    Callback = function(Value)
        TARGET_ENTITIES = Value
    end
})

killBox:AddSlider('DelayAuraSlider', {
    Text = 'Attack Delay',
    Default = 0.15,
    Min = 0.1,
    Max = 1,
    Rounding = 2,
    Compact = false,

    Callback = function(Value)
        ATTACK_DELAY = Value
    end
})

killBox:AddSlider('RangeAuraSlider', {
    Text = 'Attack Range',
    Default = 100,
    Min = 50,
    Max = 200,
    Rounding = 0,
    Compact = false,

    Callback = function(Value)
        AURA_RANGE = Value
    end
})


killBox:AddDivider()

local Players = game:GetService("Players")

killBox:AddInput('Whitelist', {
    Default = nil,
    Numeric = false,
    Finished = true,

    Text = 'White List Player',
    Tooltip = 'Bro Just Typing Shit',
    Placeholder = 'UserName',

    Callback = function(Value)
        if Value == "" then return end

        local cleaned = Value:lower():match("^%s*(.-)%s*$")

        if cleaned == "" then return end

        -- check if player is in this server
        local foundPlayer = nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Name:lower() == cleaned then
                foundPlayer = plr
                break
            end
        end

        if not foundPlayer then
            Library:Notify("Player is not in this server.", 4)
            return
        end

        if not table.find(WHITELIST, cleaned) then
            table.insert(WHITELIST, cleaned)
            Library:Notify("Added to whitelist: " .. foundPlayer.Name, 4)
        end
    end
})

killBox:AddButton({
    Text = 'Clear Whitelist',
    Func = function()
        WHITELIST = {}
        Library:Notify("Whitelist cleared", 3)
    end
})
--duping wwww
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

if _G.InvisConnections then
    for _, conn in pairs(_G.InvisConnections) do
        pcall(conn.Disconnect, conn)
    end
    _G.InvisConnections = nil
end

local ENABLE_KEYBIND = true
local DEFAULT_KEY = Enum.KeyCode.G
local INVIS_ALPHA = 0.5

local isInvisible = false
local bodyParts = {}
local connections = {}
local guiButton = nil
local currentKey = DEFAULT_KEY

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local function collectBodyParts()
    bodyParts = {}
    for _, v in character:GetDescendants() do
        if v:IsA("BasePart") and v.Transparency < 0.1 then
            table.insert(bodyParts, v)
        end
    end
end

local function setInvis(state)
    local t = state and INVIS_ALPHA or 0
    for _, part in bodyParts do
        if part and part.Parent then
            part.Transparency = t
        end
    end
end

local function onHeartbeat()
    if not isInvisible then return end
    if not rootPart or not humanoid then return end

    local origCFrame = rootPart.CFrame
    local origOffset = humanoid.CameraOffset

    local fakeCFrame = origCFrame * CFrame.new(0, -200000, 0)
    rootPart.CFrame = fakeCFrame
    humanoid.CameraOffset = (fakeCFrame:ToObjectSpace(origCFrame)).Position

    task.defer(function()
        RunService.RenderStepped:Wait()
        if rootPart and rootPart.Parent then
            rootPart.CFrame = origCFrame
        end
        if humanoid and humanoid.Parent then
            humanoid.CameraOffset = origOffset
        end
    end)
end

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if not ENABLE_KEYBIND then return end
    if input.KeyCode == currentKey then
        isInvisible = not isInvisible
        setInvis(isInvisible)
        if guiButton then
            guiButton.Text = isInvisible and "Visible" or "Invisible"
            guiButton.BackgroundColor3 = isInvisible and Color3.fromRGB(70, 200, 90) or Color3.fromRGB(220, 70, 70)
        end
    end
end

local function createGUI()

    local sg = Instance.new("ScreenGui")
    sg.Name = "InvisGUI"
    sg.ResetOnSpawn = false
    sg.Parent = player:WaitForChild("PlayerGui")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 50)
    btn.Position = UDim2.new(0.5, -60, 0.12, 0)
    btn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    btn.Text = "Invisible"
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = sg

    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

    local function updateInput(input)
        local delta = input.Position - dragStart
        btn.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateInput(input)
        end
    end)

    btn.MouseButton1Click:Connect(function()
        isInvisible = not isInvisible
        setInvis(isInvisible)
        btn.Text = isInvisible and "Visible" or "Invisible"
        btn.BackgroundColor3 = isInvisible and Color3.fromRGB(70, 200, 90) or Color3.fromRGB(220, 70, 70)
    end)

    guiButton = btn
end

player.CharacterAdded:Connect(function(newChar)
    isInvisible = false
    setInvis(false)

    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")

    collectBodyParts()

    if guiButton then
        guiButton.Text = "Invisible"
        guiButton.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    end
end)

collectBodyParts()

table.insert(connections, RunService.Heartbeat:Connect(onHeartbeat))
if ENABLE_KEYBIND then
    table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))
end

_G.InvisConnections = connections

local dupeBox = Tabs.Duping:AddLeftGroupbox('Items Duper')

dupeBox:AddButton({
    Text = 'Dupe UI',
    Func = function()
        createGUI()
    end,
    DoubleClick = false,
    Tooltip = 'Show Dupe GUI'
})

dupeBox:AddLabel('How to Dupe : ')
dupeBox:AddLabel('1.Press The Keybind(G)/UI')
dupeBox:AddLabel('2.Drop The Item You Want')
dupeBox:AddLabel('3.Completed')
dupeBox:AddLabel('4.Do Step 1 Again To Be Visible')
--esp
local espBox = Tabs.Combat:AddRightGroupbox('ESP')

local DrawingSupported = pcall(function()
    local test = Drawing.new("Square")
    test:Remove()
end)

if not DrawingSupported then
    espBox:AddLabel('Unsupported')
else
    espBox:AddToggle('ESPToggle', {
        Text = 'ESP',
        Default = false,
        Tooltip = 'Tracking Players',
        Callback = function(Value)
            ESP_ENABLED = Value
        end
    })

    espBox:AddDivider()

    espBox:AddToggle('BoxESPToggle', {
        Text = 'Boxes',
        Default = false,
        Tooltip = 'Create Boxes',
        Callback = function(Value)
            SHOW_BOX = Value
        end
    })

    espBox:AddToggle('DistanceESPToggle', {
        Text = 'Distance',
        Default = false,
        Tooltip = 'Create Distance',
        Callback = function(Value)
            SHOW_DISTANCE = Value
        end
    })

    espBox:AddToggle('NameESPToggle', {
        Text = 'Names',
        Default = false,
        Tooltip = 'Create Names',
        Callback = function(Value)
            SHOW_NAME = Value
        end
    })

    espBox:AddToggle('TracersESPToggle', {
        Text = 'Tracers',
        Default = false,
        Tooltip = 'Create Tracers',
        Callback = function(Value)
            SHOW_TRACERS = Value
        end
    })
end
--speed
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local toggleKey = Enum.KeyCode.P
local tpSpeed = 2

local tpWalkEnabled = false

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == toggleKey then
		tpWalkEnabled = not tpWalkEnabled
	end
end)

RunService.Heartbeat:Connect(function()
	if not tpWalkEnabled then return end

	local character = getCharacter()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then return end

	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude > 0 then
		root.CFrame = root.CFrame + (moveDir * tpSpeed)
	end
end)

local speedBox = Tabs.Player:AddLeftGroupbox('Speed')

speedBox:AddToggle('SpeedToggle', {
    Text = 'Speed Master Switch',
    Default = false,
    Tooltip = 'Change Your Player WalkSpeed',
    Callback = function(Value)
        tpWalkEnabled = Value
    end
})

speedBox:AddDivider()

speedBox:AddSlider('SpeedSlider', {
    Text = 'Speed Ammount',
    Default = 2,
    Min = 0,
    Max = 10,
    Rounding = 2,
    Compact = false,

    Callback = function(Value)
        tpSpeed = Value
    end
})

speedBox:AddLabel('Speed Toggle Button'):AddKeyPicker('Speed Toggle Button', {
    Default = 'P', -- String as the name of the keybind (MB1, MB2 for mouse buttons)
    Text = 'Speed Keybind', -- Text to display in the keybind menu
    NoUI = false, -- Set to true if you want to hide from the Keybind menu
    -- Occurs when the keybind itself is changed, `New` is a KeyCode Enum OR a UserInputType Enum
    ChangedCallback = function(New)
        toggleKey = New
    end
})

local jumpinfBox = Tabs.Player:AddLeftGroupbox('Infinite Jump')

local InfiniteJumpEnabled = false
game:GetService("UserInputService").JumpRequest:connect(function()
	if InfiniteJumpEnabled then
		game:GetService"Players".LocalPlayer.Character:FindFirstChildOfClass'Humanoid':ChangeState("Jumping")
	end
end)

jumpinfBox:AddToggle('InfJumpToggle', {
    Text = 'Infinite Jump',
    Default = false,
    Tooltip = 'Makes You Can Jump Infinitely',
    Callback = function(Value)
        InfiniteJumpEnabled = Value
    end
})


--fall damage
local fallDameBox = Tabs.Player:AddRightGroupbox('Fall Damage')

fallDameBox:AddButton({
    Text = 'No Fall',
    Func = function()
        local fallDamageRemote = game.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("CombatSystem"):WaitForChild("Network"):WaitForChild("FallDamage")
        fallDamageRemote:Destroy()
    end,
    DoubleClick = false,
    Tooltip = 'Disable Fall Damage Completely'
})

Library:SetWatermarkVisibility(true)

local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1;

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter;
        FrameTimer = tick();
        FrameCounter = 0;
    end;

    Library:SetWatermark(('BloomWare Client | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ));
end);

Library.KeybindFrame.Visible = true; -- todo: add a function for this

Library:OnUnload(function()
    WatermarkConnection:Disconnect()

    print('Unloaded!')
    Library.Unloaded = true
end)

-- UI Settings
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

-- I set NoUI so it does not show up in the keybinds menu
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'RightShift', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
--load auto load configs
SaveManager:LoadAutoloadConfig()
