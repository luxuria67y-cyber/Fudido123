-- ============================================================
--  VOID.LAZY v5.0 | KNIFE DUELS | MOBILE ULTIMATE
--  Senha: leyzepidao
-- ============================================================

task.wait(2)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
    SafeMode = true,
    AimFOV = 250,
    HitboxSize = 6,
    Smoothness = 0.18, -- Valor menor = mais suave (0.1 a 0.3)
    ChanceHead = 60,   -- 60% de chance de mirar na cabeça no modo seguro
    ChanceBody = 25,   -- 25% de chance de mirar no corpo
    ChanceMiss = 15,   -- 15% de chance de errar de propósito
}

-- ============================================================
-- ESTADO
-- ============================================================
local AimbotTarget = nil
local ESPTags = {}
local Hitboxes = {}
local isDead = false
local ScreenGui = nil

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
-- ESP
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
-- HITBOX EXPANDER (CORRIGIDO)
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
-- AIMBOT (COM SUAVIZAÇÃO E SISTEMA DE CHANCES)
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
    if not Config.Aimbot or isDead then
        AimbotTarget = nil
        return
    end

    local targetPlayer = getClosestPlayer()
    if not targetPlayer then return end

    local targetPart = getHead(targetPlayer)
    if not targetPart then return end

    -- Sistema de Chances (Safe Mode)
    if Config.SafeMode then
        local roll = math.random(1, 100)
        if roll <= Config.ChanceHead then
            -- Mira na cabeça (padrão)
            targetPart = getHead(targetPlayer)
        elseif roll <= (Config.ChanceHead + Config.ChanceBody) then
            -- Mira no corpo
            targetPart = getTorso(targetPlayer)
        elseif roll <= (Config.ChanceHead + Config.ChanceBody + Config.ChanceMiss) then
            -- Erra de propósito
            local offset = Vector3.new(math.random(-6, 6), math.random(-6, 6), math.random(-6, 6))
            local fakePos = targetPart.Position + offset
            local lookAt = CFrame.new(Camera.CFrame.Position, fakePos)
            Camera.CFrame = Camera.CFrame:Lerp(lookAt, Config.Smoothness)
            return
        end
    end

    -- Aplica a mira com suavização (Lerp)
    if targetPart then
        local lookAt = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        Camera.CFrame = Camera.CFrame:Lerp(lookAt, Config.Smoothness)
    end
end

-- ============================================================
-- DETECÇÃO DE MORTE (DESATIVA AIMBOT AUTOMATICAMENTE)
-- ============================================================
local function setupDeathDetection()
    local char = LP.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Died:Connect(function()
            isDead = true
            Config.Aimbot = false
            if ScreenGui then
                local btn = ScreenGui:FindFirstChild("AimbotBtn", true)
                if btn then
                    btn.Text = "Aimbot: OFF"
                    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                end
            end
        end)
    end
end

LP.CharacterAdded:Connect(function()
    isDead = false
    setupDeathDetection()
end)
setupDeathDetection()

-- ============================================================
-- FARM DE MOEDAS (TENTATIVA VIA REMOTE)
-- ============================================================
local function tryFarmCoins()
    -- Procura por remotes relacionados a moedas no ReplicatedStorage
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("coin") or name:find("money") or name:find("reward") or name:find("cash") then
                pcall(function()
                    if obj:IsA("RemoteEvent") then
                        obj:FireServer()
                    else
                        obj:InvokeServer()
                    end
                end)
            end
        end
    end
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
-- INTERFACE (BOLHA FLUTUANTE + MENU)
-- ============================================================
local parentGui = gethui and gethui() or game:GetService("CoreGui")
ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VOID_KD"
ScreenGui.Parent = parentGui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999

-- Bolha Flutuante
local Bubble = Instance.new("TextButton")
Bubble.Name = "Bubble"
Bubble.Size = UDim2.new(0, 50, 0, 50)
Bubble.Position = UDim2.new(0, 20, 0.5, -25)
Bubble.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
Bubble.Text = "V"
Bubble.TextColor3 = Color3.fromRGB(255, 255, 255)
Bubble.TextSize = 24
Bubble.Font = Enum.Font.GothamBold
Bubble.Parent = ScreenGui
Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)

-- Arrastar a bolha
local draggingBubble = false
local bubbleStart = nil
Bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingBubble = true
        bubbleStart = input.Position
    end
end)
Bubble.InputChanged:Connect(function(input)
    if draggingBubble and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - bubbleStart
        Bubble.Position = UDim2.new(Bubble.Position.X.Scale, Bubble.Position.X.Offset + delta.X, Bubble.Position.Y.Scale, Bubble.Position.Y.Offset + delta.Y)
        bubbleStart = input.Position
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingBubble = false
    end
end)

-- Menu Principal
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 260, 0, 320)
Main.Position = UDim2.new(0.5, -130, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Visible = false
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

-- Botão de fechar o menu (X)
local CloseMenu = Instance.new("TextButton")
CloseMenu.Size = UDim2.new(0, 30, 0, 30)
CloseMenu.Position = UDim2.new(1, -35, 0, 5)
CloseMenu.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
CloseMenu.Text = "X"
CloseMenu.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseMenu.Font = Enum.Font.GothamBold
CloseMenu.TextScaled = true
CloseMenu.Parent = Title
Instance.new("UICorner", CloseMenu).CornerRadius = UDim.new(0, 6)

-- Função para criar Toggles
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
    return btn
end

local AimbotBtn = createToggle("Aimbot (Cabeça)", 50, function(s) Config.Aimbot = s end)
local ESPBtn = createToggle("ESP (Jogadores)", 95, function(s) Config.ESP = s; if not s then clearESP() end end)
local HitboxBtn = createToggle("Hitbox (Aumentar)", 140, function(s) Config.Hitbox = s; if not s then clearHitboxes() end end)
local SafeModeBtn = createToggle("Modo Seguro (Legit)", 185, function(s) Config.SafeMode = s end)

-- Botão de Farm de Moedas
local CoinBtn = Instance.new("TextButton")
CoinBtn.Size = UDim2.new(0.9, 0, 0, 35)
CoinBtn.Position = UDim2.new(0.05, 0, 0, 230)
CoinBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
CoinBtn.Text = "💰 Tentar Farm de Moedas"
CoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CoinBtn.Font = Enum.Font.GothamBold
CoinBtn.TextScaled = true
CoinBtn.Parent = Main
Instance.new("UICorner", CoinBtn).CornerRadius = UDim.new(0, 6)

CoinBtn.MouseButton1Click:Connect(function()
    CoinBtn.Text = "⏳ Tentando..."
    CoinBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    tryFarmCoins()
    task.wait(1)
    CoinBtn.Text = "💰 Tentar Farm de Moedas"
    CoinBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
end)

-- Botão de Fechar (Desativa tudo)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0.9, 0, 0, 35)
CloseBtn.Position = UDim2.new(0.05, 0, 0, 275)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
CloseBtn.Text = "DESATIVAR TUDO"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextScaled = true
CloseBtn.Parent = Main
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Lógica de abrir/fechar o menu com a bolha
Bubble.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

CloseMenu.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Config.Aimbot = false
    Config.ESP = false
    Config.Hitbox = false
    AimbotBtn.Text = "Aimbot (Cabeça): OFF"
    AimbotBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    ESPBtn.Text = "ESP (Jogadores): OFF"
    ESPBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    HitboxBtn.Text = "Hitbox (Aumentar): OFF"
    HitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    clearESP()
    clearHitboxes()
end)

print("[VOID.LAZY] Knife Duels v5.0 carregado.")
