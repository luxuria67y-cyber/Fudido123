-- ============================================================
--  VOID.LAZY | Knife Duels | AIMBOT + ESP + HITBOX
--  Delta Mobile | Senha: leyzepidao
-- ============================================================

task.wait(2)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LP = Players.LocalPlayer
if not LP then return end

-- ============================================================
-- CONFIGURAÇÕES
-- ============================================================
local Config = {
    Aimbot = false,
    ESP = false,
    Hitbox = false,
    SafeMode = true, -- Modo Legit (erra de propósito às vezes)
    AimFOV = 250, -- Distância máxima para travar
    HitboxSize = 6, -- Tamanho da hitbox da cabeça
    Smoothness = 0.25, -- Velocidade do aimbot (0.1 = rápido, 1 = lento)
}

local AimbotTarget = nil
local ESPTags = {}
local Hitboxes = {}

-- ============================================================
-- UTILITÁRIOS
-- ============================================================
local function getCharacter(player)
    return player.Character or player.CharacterAdded:Wait()
end

local function getHead(player)
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function getTorso(player)
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- ESP (Billboard)
-- ============================================================
local function createESP(player)
    if player == LP then return end
    local head = getHead(player)
    if not head then return end
    if head:FindFirstChild("VOID_ESP") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "VOID_ESP"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
    distLabel.TextStrokeTransparency = 0.5
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextScaled = true
    distLabel.Parent = billboard

    table.insert(ESPTags, billboard)

    task.spawn(function()
        while billboard.Parent and Config.ESP do
            local char = player.Character
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if char and char:FindFirstChild("Head") and hrp then
                local dist = (char.Head.Position - hrp.Position).Magnitude
                distLabel.Text = string.format("[%d m]", math.floor(dist))
            end
            task.wait(0.2)
        end
        billboard:Destroy()
    end)
end

local function clearESP()
    for _, tag in ipairs(ESPTags) do
        pcall(function() tag:Destroy() end)
    end
    ESPTags = {}
end

-- ============================================================
-- HITBOX EXPANDER
-- ============================================================
local function applyHitbox(player)
    if player == LP then return end
    local head = getHead(player)
    if not head then return end
    if Hitboxes[player] and Hitboxes[player].Parent then return end

    local hitbox = Instance.new("Part")
    hitbox.Name = "VOID_Hitbox"
    hitbox.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
    hitbox.Transparency = 0.7
    hitbox.Color = Color3.fromRGB(255, 0, 0)
    hitbox.CanCollide = false
    hitbox.Massless = true
    hitbox.Parent = head

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hitbox
    weld.Part1 = head
    weld.Parent = hitbox

    Hitboxes[player] = hitbox
end

local function clearHitboxes()
    for _, hb in pairs(Hitboxes) do
        pcall(function() hb:Destroy() end)
    end
    Hitboxes = {}
end

-- ============================================================
-- AIMBOT (Camera Lock)
-- ============================================================
local function getClosestPlayer()
    local closest = nil
    local minDist = Config.AimFOV
    local myChar = LP.Character
    if not myChar then return nil end
    local myHead = myChar:FindFirstChild("Head")
    if not myHead then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local dist = (head.Position - myHead.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

local function updateAimbot()
    if not Config.Aimbot then
        AimbotTarget = nil
        return
    end

    local targetPlayer = getClosestPlayer()
    if not targetPlayer then return end

    local targetPart = getHead(targetPlayer)
    if not targetPart then return end

    -- Modo Seguro: 40% de chance de mirar no peito ou errar
    if Config.SafeMode then
        local chance = math.random()
        if chance < 0.4 then
            -- Mira no peito
            targetPart = getTorso(targetPlayer)
        elseif chance < 0.6 then
            -- Erra de propósito (offset aleatório)
            local offset = Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
            local fakePos = targetPart.Position + offset
            local lookAt = CFrame.new(Camera.CFrame.Position, fakePos)
            Camera.CFrame = Camera.CFrame:Lerp(lookAt, Config.Smoothness)
            return
        end
    end

    -- Mira na cabeça
    local lookAt = CFrame.new(Camera.CFrame.Position, targetPart.Position)
    Camera.CFrame = Camera.CFrame:Lerp(lookAt, Config.Smoothness)
end

-- ============================================================
-- LOOPS
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        if Config.ESP then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP then
                    createESP(player)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if Config.Hitbox then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP then
                    applyHitbox(player)
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    pcall(updateAimbot)
end)

-- ============================================================
-- INTERFACE (Simples e Mobile)
-- ============================================================
local parentGui = gethui and gethui() or game:GetService("CoreGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VOID_KD"
ScreenGui.Parent = parentGui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 250, 0, 300)
Main.Position = UDim2.new(0.5, -125, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Title.Text = "VOID.LAZY | Knife Duels"
Title.TextColor3 = Color3.fromRGB(200, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true
Title.Parent = Main
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local function createToggle(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.Text = text .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    btn.Parent = Main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 40)
        callback(state)
    end)
end

createToggle("Aimbot (Cabeça)", 50, function(s) Config.Aimbot = s end)
createToggle("ESP (Jogadores)", 95, function(s) Config.ESP = s; if not s then clearESP() end end)
createToggle("Hitbox (Aumentar)", 140, function(s) Config.Hitbox = s; if not s then clearHitboxes() end end)
createToggle("Modo Seguro (Legit)", 185, function(s) Config.SafeMode = s end)

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0.9, 0, 0, 35)
Close.Position = UDim2.new(0.05, 0, 0, 240)
Close.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
Close.Text = "FECHAR"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.Font = Enum.Font.GothamBold
Close.TextScaled = true
Close.Parent = Main
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)
Close.MouseButton1Click:Connect(function()
    Main.Visible = false
    Config.Aimbot = false
    Config.ESP = false
    Config.Hitbox = false
    clearESP()
    clearHitboxes()
end)

print("[VOID.LAZY] Knife Duels script carregado.")
