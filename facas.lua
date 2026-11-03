task.wait(2)
-- ╔══════════════════════════════════════════════════════╗
-- ║        KD SUITE — Knife Duels | Delta Mobile        ║
-- ║  ESP · Hitbox · Aimbot · Safe Mode · FPS Boost      ║
-- ╚══════════════════════════════════════════════════════╝

if getgenv().KDSUITE_LOADED then return end
getgenv().KDSUITE_LOADED = true

-- ── Services ──────────────────────────────────────────────
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local UIS          = game:GetService("UserInputService")

local LP   = Players.LocalPlayer
local Cam  = workspace.CurrentCamera

math.randomseed(os.time())

-- ── Config ────────────────────────────────────────────────
local CFG = {
    ESP = {
        On        = false,
        BoxColor  = Color3.fromRGB(0, 200, 255),
        NameColor = Color3.fromRGB(255, 255, 255),
        ShowBox   = true,
        ShowName  = true,
        ShowHP    = true,
        Thickness = 1.5,
    },
    Hitbox = {
        On   = false,
        Size = 8,
    },
    Aimbot = {
        On         = false,
        Smooth     = 0.12,
        SafeMode   = false,
        HeadChance = 40,
    },
    FPS = { On = false },
}

-- ── Utils ─────────────────────────────────────────────────
local function Char(p)  return p and p.Character end
local function Root(p)  local c = Char(p) return c and c:FindFirstChild("HumanoidRootPart") end
local function Head(p)  local c = Char(p) return c and c:FindFirstChild("Head") end
local function Hum(p)   local c = Char(p) return c and c:FindFirstChildOfClass("Humanoid") end

local function W2S(pos)
    local s, vis = Cam:WorldToViewportPoint(pos)
    return Vector2.new(s.X, s.Y), vis, s.Z
end

local function Closest()
    local best, bestD = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local h  = Head(p)
        local hm = Hum(p)
        if h and hm and hm.Health > 0 then
            local _, vis, d = W2S(h.Position)
            if vis and d < bestD then bestD, best = d, p end
        end
    end
    return best
end

-- ── ESP ───────────────────────────────────────────────────
local ESPPool = {}

local function NewESP(p)
    local e = {}

    e.box = Drawing.new("Square")
    e.box.Filled    = false
    e.box.Thickness = CFG.ESP.Thickness
    e.box.Color     = CFG.ESP.BoxColor
    e.box.Visible   = false

    e.name = Drawing.new("Text")
    e.name.Font    = Drawing.Fonts.UI
    e.name.Size    = 13
    e.name.Color   = CFG.ESP.NameColor
    e.name.Outline = true
    e.name.Center  = true
    e.name.Visible = false

    e.hp = Drawing.new("Text")
    e.hp.Font    = Drawing.Fonts.UI
    e.hp.Size    = 11
    e.hp.Outline = true
    e.hp.Center  = true
    e.hp.Visible = false

    e.barBG = Drawing.new("Square")
    e.barBG.Filled  = true
    e.barBG.Color   = Color3.fromRGB(25, 25, 25)
    e.barBG.Visible = false

    e.barFill = Drawing.new("Square")
    e.barFill.Filled  = true
    e.barFill.Visible = false

    e.tracer = Drawing.new("Line")
    e.tracer.Color     = Color3.fromRGB(0, 200, 255)
    e.tracer.Thickness = 1
    e.tracer.Visible   = false

    ESPPool[p] = e
end

local function ClearESP(p)
    if ESPPool[p] then
        for _, d in pairs(ESPPool[p]) do pcall(d.Remove, d) end
        ESPPool[p] = nil
    end
end

local function UpdateESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if not ESPPool[p] then NewESP(p) end

        local e  = ESPPool[p]
        local hm = Hum(p)
        local rt = Root(p)
        local hd = Head(p)

        if not CFG.ESP.On or not hm or not rt or not hd or hm.Health <= 0 then
            for _, d in pairs(e) do d.Visible = false end
            continue
        end

        local sRoot, visR    = W2S(rt.Position)
        local sHead, visH, _ = W2S(hd.Position + Vector3.new(0, 0.6, 0))

        if not visR and not visH then
            for _, d in pairs(e) do d.Visible = false end
            continue
        end

        local h     = math.abs(sHead.Y - sRoot.Y) * 2.1
        local w     = h * 0.45
        local topY  = math.min(sHead.Y, sRoot.Y) - h * 0.08
        local leftX = sRoot.X - w * 0.5
        local botY  = topY + h

        -- Box
        e.box.Size     = Vector2.new(w, h)
        e.box.Position = Vector2.new(leftX, topY)
        e.box.Color    = CFG.ESP.BoxColor
        e.box.Visible  = CFG.ESP.ShowBox

        -- Name
        e.name.Text     = p.DisplayName
        e.name.Position = Vector2.new(sRoot.X, topY - 15)
        e.name.Visible  = CFG.ESP.ShowName

        -- HP text
        local ratio = math.clamp(hm.Health / hm.MaxHealth, 0, 1)
        e.hp.Text     = math.floor(hm.Health) .. "hp"
        e.hp.Color    = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
        e.hp.Position = Vector2.new(sRoot.X, botY + 2)
        e.hp.Visible  = CFG.ESP.ShowHP

        -- HP bar (left side of box)
        local bW, bH = 3, h
        local bX     = leftX - bW - 2
        e.barBG.Size     = Vector2.new(bW, bH)
        e.barBG.Position = Vector2.new(bX, topY)
        e.barBG.Visible  = CFG.ESP.ShowHP

        e.barFill.Size     = Vector2.new(bW, bH * ratio)
        e.barFill.Position = Vector2.new(bX, topY + bH * (1 - ratio))
        e.barFill.Color    = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
        e.barFill.Visible  = CFG.ESP.ShowHP

        -- Tracer (screen bottom center → enemy feet)
        local vp = Cam.ViewportSize
        e.tracer.From    = Vector2.new(vp.X * 0.5, vp.Y)
        e.tracer.To      = Vector2.new(sRoot.X, botY)
        e.tracer.Visible = CFG.ESP.ShowBox
    end
end

Players.PlayerRemoving:Connect(ClearESP)

-- ── Hitbox Expander ───────────────────────────────────────
local OrigSizes = {}

local function SetHitbox(p, on)
    local ch  = Char(p) if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart") if not hrp then return end
    if on then
        if not OrigSizes[p] then OrigSizes[p] = hrp.Size end
        hrp.Size         = Vector3.new(CFG.Hitbox.Size, CFG.Hitbox.Size, CFG.Hitbox.Size)
        hrp.Transparency = 0.5
        hrp.Color        = Color3.fromRGB(255, 50, 50)
        hrp.Material     = Enum.Material.Neon
    else
        if OrigSizes[p] then
            hrp.Size     = OrigSizes[p]
            OrigSizes[p] = nil
        end
    end
end

local function UpdateHitboxes()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then SetHitbox(p, CFG.Hitbox.On) end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        if CFG.Hitbox.On then SetHitbox(p, true) end
    end)
end)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        p.CharacterAdded:Connect(function()
            task.wait(1)
            if CFG.Hitbox.On then SetHitbox(p, true) end
        end)
    end
end

-- ── Aimbot ────────────────────────────────────────────────
local function PickAimPart(t)
    if not t then return nil end
    if CFG.Aimbot.SafeMode then
        local r = math.random(1, 100)
        if r <= CFG.Aimbot.HeadChance then
            return Head(t)
        elseif r <= CFG.Aimbot.HeadChance + 30 then
            return Root(t) -- peito aproximado
        else
            return nil     -- miss intencional
        end
    end
    return Head(t)
end

-- Camera smooth aimbot (RenderStepped)
local function CamAimbot()
    if not CFG.Aimbot.On then return end
    local t  = Closest() if not t then return end
    local hd = Head(t)   if not hd then return end
    local cf = CFrame.new(Cam.CFrame.Position, hd.Position)
    Cam.CFrame = Cam.CFrame:Lerp(cf, CFG.Aimbot.Smooth)
end

-- Knife velocity redirect (post-spawn no workspace)
local KnifeKW = {"knife","faca","blade","dagger","throw","weapon","projectile"}
local function IsKnife(name)
    local n = name:lower()
    for _, kw in ipairs(KnifeKW) do
        if n:find(kw) then return true end
    end
    return false
end

local function RedirectKnifeVelocity(kBase, aimPart)
    if not kBase or not aimPart then return end
    local speed = kBase.AssemblyLinearVelocity.Magnitude
    if speed < 5 then speed = 85 end

    local dist  = (aimPart.Position - kBase.Position).Magnitude
    local tTime = dist / speed
    local lead  = Vector3.zero
    local rt    = Root(Closest())
    if rt then lead = rt.AssemblyLinearVelocity * tTime * 0.45 end

    local dir = ((aimPart.Position + lead) - kBase.Position).Unit
    kBase.AssemblyLinearVelocity = dir * speed

    local elapsed = 0
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed > 0.45 or not kBase.Parent or not aimPart.Parent then
            conn:Disconnect() return
        end
        kBase.AssemblyLinearVelocity = (aimPart.Position - kBase.Position).Unit * speed
    end)
end

local function HookWorkspace()
    workspace.DescendantAdded:Connect(function(obj)
        if not CFG.Aimbot.On then return end
        if not obj:IsA("BasePart") then return end
        if not IsKnife(obj.Name) then return end

        task.spawn(function()
            task.wait()
            local t       = Closest()
            local aimPart = PickAimPart(t)
            RedirectKnifeVelocity(obj, aimPart)
        end)
    end)
end

-- FireServer hook: substitui Vector3 de direção nos args
local function HookFireServer()
    local mt  = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and CFG.Aimbot.On then
            local args = {...}
            local t       = Closest()
            local aimPart = PickAimPart(t)
            if aimPart then
                local ch    = LP.Character
                local lroot = ch and ch:FindFirstChild("HumanoidRootPart")
                if lroot then
                    local dir = (aimPart.Position - lroot.Position).Unit
                    for i, v in ipairs(args) do
                        if typeof(v) == "Vector3" and v.Magnitude > 0.05 then
                            args[i] = dir
                        end
                    end
                end
            end
            return old(self, table.unpack(args))
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end

-- ── FPS Boost ─────────────────────────────────────────────
local function ApplyFPS()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    Lighting.GlobalShadows = false
    Lighting.FogEnd        = 9e4
    Lighting.Brightness    = 2
    for _, v in ipairs(Lighting:GetChildren()) do
        pcall(function()
            if v:IsA("PostEffect") or v:IsA("Atmosphere") then v.Enabled = false end
        end)
    end
    for _, v in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end)
    end
end

local function RemoveFPS()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    Lighting.GlobalShadows = true
    for _, v in ipairs(Lighting:GetChildren()) do
        pcall(function()
            if v:IsA("PostEffect") or v:IsA("Atmosphere") then v.Enabled = true end
        end)
    end
end

-- ── UI ────────────────────────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name             = "KDSuite"
SG.ResetOnSpawn     = false
SG.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset   = true
SG.Parent           = (pcall(gethui) and gethui()) or LP:WaitForChild("PlayerGui")

-- Main frame
local Main = Instance.new("Frame", SG)
Main.Name              = "Main"
Main.Size              = UDim2.new(0, 282, 0, 348)
Main.Position          = UDim2.new(0, 18, 0.28, 0)
Main.BackgroundColor3  = Color3.fromRGB(13, 13, 18)
Main.BorderSizePixel   = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 9)

-- Shadow layer
local Shad = Instance.new("Frame", Main)
Shad.Size                   = UDim2.new(1, 12, 1, 12)
Shad.Position               = UDim2.new(0, -6, 0, -6)
Shad.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
Shad.BackgroundTransparency = 0.65
Shad.ZIndex                 = Main.ZIndex - 1
Shad.BorderSizePixel        = 0
Instance.new("UICorner", Shad).CornerRadius = UDim.new(0, 12)

-- Title bar
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size             = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
TitleBar.BorderSizePixel  = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 9)
-- fill round bottom corners of title bar
local TFix = Instance.new("Frame", TitleBar)
TFix.Size             = UDim2.new(1, 0, 0, 9)
TFix.Position         = UDim2.new(0, 0, 1, -9)
TFix.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
TFix.BorderSizePixel  = 0

local TLabel = Instance.new("TextLabel", TitleBar)
TLabel.Size              = UDim2.new(1, -72, 1, 0)
TLabel.Position          = UDim2.new(0, 10, 0, 0)
TLabel.BackgroundTransparency = 1
TLabel.Text              = "⚔  KD Suite"
TLabel.Font              = Enum.Font.GothamBold
TLabel.TextSize          = 14
TLabel.TextColor3        = Color3.fromRGB(0, 200, 255)
TLabel.TextXAlignment    = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size             = UDim2.new(0, 28, 0, 22)
MinBtn.Position         = UDim2.new(1, -62, 0.5, -11)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
MinBtn.Text             = "─"
MinBtn.TextColor3       = Color3.fromRGB(210, 210, 210)
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.TextSize         = 14
MinBtn.BorderSizePixel  = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 5)

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size             = UDim2.new(0, 28, 0, 22)
CloseBtn.Position         = UDim2.new(1, -30, 0.5, -11)
CloseBtn.BackgroundColor3 = Color3.fromRGB(190, 40, 40)
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 14
CloseBtn.BorderSizePixel  = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)

-- Tab bar
local TabBar = Instance.new("Frame", Main)
TabBar.Size             = UDim2.new(1, 0, 0, 30)
TabBar.Position         = UDim2.new(0, 0, 0, 38)
TabBar.BackgroundColor3 = Color3.fromRGB(17, 17, 23)
TabBar.BorderSizePixel  = 0
local TBLayout = Instance.new("UIListLayout", TabBar)
TBLayout.FillDirection = Enum.FillDirection.Horizontal
TBLayout.Padding       = UDim.new(0, 2)
local TBPad = Instance.new("UIPadding", TabBar)
TBPad.PaddingLeft  = UDim.new(0, 2)
TBPad.PaddingRight = UDim.new(0, 2)

-- Content
local Content = Instance.new("Frame", Main)
Content.Size                 = UDim2.new(1, 0, 1, -70)
Content.Position             = UDim2.new(0, 0, 0, 70)
Content.BackgroundTransparency = 1
Content.ClipsDescendants     = true

-- Tab separator line
local Sep = Instance.new("Frame", Main)
Sep.Size             = UDim2.new(1, 0, 0, 1)
Sep.Position         = UDim2.new(0, 0, 0, 68)
Sep.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
Sep.BorderSizePixel  = 0

-- ── Tab builder ───────────────────────────────────────────
local Tabs    = {}
local TabBtns = {}
local ActiveTab = nil
local TAB_NAMES  = {"ESP","Hitbox","Aimbot","FPS"}
local TAB_COLORS = {
    ESP    = Color3.fromRGB(0, 200, 255),
    Hitbox = Color3.fromRGB(255, 80,  80),
    Aimbot = Color3.fromRGB(80,  255, 120),
    FPS    = Color3.fromRGB(255, 200, 0),
}

for _, name in ipairs(TAB_NAMES) do
    local btn = Instance.new("TextButton", TabBar)
    btn.Size             = UDim2.new(0.25, -2, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 33)
    btn.Text             = name
    btn.TextColor3       = Color3.fromRGB(130, 130, 155)
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 11
    btn.BorderSizePixel  = 0

    local page = Instance.new("ScrollingFrame", Content)
    page.Size                   = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness     = 3
    page.ScrollBarImageColor3   = Color3.fromRGB(55, 55, 75)
    page.CanvasSize             = UDim2.new(0, 0, 0, 0)
    page.Visible                = false

    local pl = Instance.new("UIListLayout", page)
    pl.Padding             = UDim.new(0, 5)
    pl.HorizontalAlignment = Enum.HorizontalAlignment.Center
    pl.SortOrder           = Enum.SortOrder.LayoutOrder

    local pp = Instance.new("UIPadding", page)
    pp.PaddingLeft   = UDim.new(0, 7)
    pp.PaddingRight  = UDim.new(0, 7)
    pp.PaddingTop    = UDim.new(0, 7)
    pp.PaddingBottom = UDim.new(0, 7)

    pl.Changed:Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pl.AbsoluteContentSize.Y + 14)
    end)

    Tabs[name]    = page
    TabBtns[name] = btn
end

local function SwitchTab(name)
    if ActiveTab == name then return end
    ActiveTab = name
    for n, page in pairs(Tabs) do page.Visible = (n == name) end
    for n, btn in pairs(TabBtns) do
        if n == name then
            btn.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
            btn.TextColor3       = TAB_COLORS[n]
        else
            btn.BackgroundColor3 = Color3.fromRGB(24, 24, 33)
            btn.TextColor3       = Color3.fromRGB(130, 130, 155)
        end
    end
end
for _, n in ipairs(TAB_NAMES) do TabBtns[n].MouseButton1Click:Connect(function() SwitchTab(n) end) end
SwitchTab("ESP")

-- ── Widget helpers ────────────────────────────────────────
local function SectionLabel(parent, text)
    local l = Instance.new("TextLabel", parent)
    l.Size             = UDim2.new(1, 0, 0, 18)
    l.BackgroundTransparency = 1
    l.Text             = "  " .. text:upper()
    l.Font             = Enum.Font.GothamBold
    l.TextSize         = 10
    l.TextColor3       = Color3.fromRGB(90, 90, 120)
    l.TextXAlignment   = Enum.TextXAlignment.Left
    return l
end

local function MakeToggle(parent, label, state, cb)
    local fr = Instance.new("Frame", parent)
    fr.Size             = UDim2.new(1, 0, 0, 36)
    fr.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    fr.BorderSizePixel  = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 7)

    local lbl = Instance.new("TextLabel", fr)
    lbl.Size             = UDim2.new(0.68, 0, 1, 0)
    lbl.Position         = UDim2.new(0, 9, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = label
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 12
    lbl.TextColor3       = Color3.fromRGB(195, 195, 210)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left

    local pill = Instance.new("TextButton", fr)
    pill.Size             = UDim2.new(0, 44, 0, 24)
    pill.Position         = UDim2.new(1, -50, 0.5, -12)
    pill.BackgroundColor3 = state and Color3.fromRGB(0, 165, 95) or Color3.fromRGB(55, 28, 28)
    pill.Text             = ""
    pill.BorderSizePixel  = 0
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", pill)
    knob.Size             = UDim2.new(0, 18, 0, 18)
    knob.Position         = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel  = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local on = state
    local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
    pill.MouseButton1Click:Connect(function()
        on = not on
        TweenService:Create(pill, ti, {
            BackgroundColor3 = on and Color3.fromRGB(0, 165, 95) or Color3.fromRGB(55, 28, 28)
        }):Play()
        TweenService:Create(knob, ti, {
            Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        }):Play()
        cb(on)
    end)
    return fr
end

local function MakeSlider(parent, label, min, max, cur, step, cb)
    local fr = Instance.new("Frame", parent)
    fr.Size             = UDim2.new(1, 0, 0, 52)
    fr.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    fr.BorderSizePixel  = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 7)

    local lbl = Instance.new("TextLabel", fr)
    lbl.Size           = UDim2.new(0.62, 0, 0, 22)
    lbl.Position       = UDim2.new(0, 9, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text           = label
    lbl.Font           = Enum.Font.Gotham
    lbl.TextSize       = 12
    lbl.TextColor3     = Color3.fromRGB(195, 195, 210)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", fr)
    valLbl.Size           = UDim2.new(0.35, -9, 0, 22)
    valLbl.Position       = UDim2.new(0.65, 0, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.Text           = tostring(cur)
    valLbl.Font           = Enum.Font.GothamBold
    valLbl.TextSize       = 12
    valLbl.TextColor3     = Color3.fromRGB(0, 200, 255)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame", fr)
    track.Size             = UDim2.new(1, -18, 0, 6)
    track.Position         = UDim2.new(0, 9, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
    track.BorderSizePixel  = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new((cur - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local hdl = Instance.new("TextButton", track)
    hdl.Size             = UDim2.new(0, 14, 0, 14)
    hdl.Position         = UDim2.new((cur - min) / (max - min), -7, 0.5, -7)
    hdl.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hdl.Text             = ""
    hdl.BorderSizePixel  = 0
    Instance.new("UICorner", hdl).CornerRadius = UDim.new(1, 0)

    local dragging = false
    hdl.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement and
           inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local abs   = track.AbsolutePosition
        local sz    = track.AbsoluteSize
        local ratio = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
        local val   = math.floor((min + (max - min) * ratio) / step + 0.5) * step
        fill.Size         = UDim2.new(ratio, 0, 1, 0)
        hdl.Position      = UDim2.new(ratio, -7, 0.5, -7)
        valLbl.Text       = tostring(val)
        cb(val)
    end)

    return fr
end

local function InfoBox(parent, text)
    local fr = Instance.new("TextLabel", parent)
    fr.Size             = UDim2.new(1, 0, 0, 54)
    fr.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    fr.Text             = text
    fr.Font             = Enum.Font.Gotham
    fr.TextSize         = 11
    fr.TextColor3       = Color3.fromRGB(100, 100, 135)
    fr.TextWrapped      = true
    fr.BorderSizePixel  = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 7)
    return fr
end

-- ── ESP Tab ───────────────────────────────────────────────
SectionLabel(Tabs["ESP"], "Visual")
MakeToggle(Tabs["ESP"], "ESP Ativado", false, function(v)
    CFG.ESP.On = v
    if not v then
        for _, e in pairs(ESPPool) do
            for _, d in pairs(e) do d.Visible = false end
        end
    end
end)
MakeToggle(Tabs["ESP"], "Mostrar Caixa + Tracer", true, function(v) CFG.ESP.ShowBox = v end)
MakeToggle(Tabs["ESP"], "Mostrar Nome", true, function(v) CFG.ESP.ShowName = v end)
MakeToggle(Tabs["ESP"], "Mostrar HP", true, function(v) CFG.ESP.ShowHP = v end)

-- ── Hitbox Tab ────────────────────────────────────────────
SectionLabel(Tabs["Hitbox"], "Hitbox Expander")
MakeToggle(Tabs["Hitbox"], "Hitbox Expander", false, function(v)
    CFG.Hitbox.On = v
    UpdateHitboxes()
end)
MakeSlider(Tabs["Hitbox"], "Tamanho (studs)", 2, 20, 8, 1, function(v)
    CFG.Hitbox.Size = v
    if CFG.Hitbox.On then UpdateHitboxes() end
end)
InfoBox(Tabs["Hitbox"], "Expande o HumanoidRootPart dos inimigos — mais fácil de acertar a faca.")

-- ── Aimbot Tab ────────────────────────────────────────────
SectionLabel(Tabs["Aimbot"], "Aimbot")
MakeToggle(Tabs["Aimbot"], "Aimbot Cabeça", false, function(v) CFG.Aimbot.On = v end)
SectionLabel(Tabs["Aimbot"], "Safe Mode")
MakeToggle(Tabs["Aimbot"], "Modo Seguro", false, function(v) CFG.Aimbot.SafeMode = v end)
MakeSlider(Tabs["Aimbot"], "Chance Cabeça (safe %)", 10, 90, 40, 5, function(v) CFG.Aimbot.HeadChance = v end)
SectionLabel(Tabs["Aimbot"], "Camera")
MakeSlider(Tabs["Aimbot"], "Suavidade Camera", 1, 25, 12, 1, function(v) CFG.Aimbot.Smooth = v / 100 end)
InfoBox(Tabs["Aimbot"], "Safe Mode: mistura cabeça, peito e erros intencionais conforme o % definido.")

-- ── FPS Tab ───────────────────────────────────────────────
SectionLabel(Tabs["FPS"], "Performance")
MakeToggle(Tabs["FPS"], "FPS Boost", false, function(v)
    CFG.FPS.On = v
    if v then ApplyFPS() else RemoveFPS() end
end)
InfoBox(Tabs["FPS"], "Remove partículas, sombras, névoa e efeitos de pós-processamento.\nQualidade de render reduzida ao mínimo.")

-- ── Drag ──────────────────────────────────────────────────
do
    local drag, dStart, dPos = false, nil, nil
    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            drag   = true
            dStart = inp.Position
            dPos   = Main.Position
        end
    end)
    TitleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if not drag then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement and
           inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = inp.Position - dStart
        Main.Position = UDim2.new(
            dPos.X.Scale, dPos.X.Offset + d.X,
            dPos.Y.Scale, dPos.Y.Offset + d.Y
        )
    end)
end

-- Minimize
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(Main, TweenInfo.new(0.18), {
        Size = minimized and UDim2.new(0, 282, 0, 38) or UDim2.new(0, 282, 0, 348)
    }):Play()
    MinBtn.Text = minimized and "□" or "─"
end)

-- Close → reopen button
local ReopenBtn = Instance.new("TextButton", SG)
ReopenBtn.Size             = UDim2.new(0, 76, 0, 30)
ReopenBtn.Position         = UDim2.new(0, 18, 0.28, 0)
ReopenBtn.BackgroundColor3 = Color3.fromRGB(0, 165, 95)
ReopenBtn.Text             = "⚔ KD"
ReopenBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
ReopenBtn.Font             = Enum.Font.GothamBold
ReopenBtn.TextSize         = 13
ReopenBtn.Visible          = false
ReopenBtn.BorderSizePixel  = 0
Instance.new("UICorner", ReopenBtn).CornerRadius = UDim.new(0, 7)

CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible      = false
    ReopenBtn.Visible = true
end)
ReopenBtn.MouseButton1Click:Connect(function()
    Main.Visible      = true
    ReopenBtn.Visible = false
end)

-- ── Main loops ────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    UpdateESP()
    CamAimbot()
end)

RunService.Heartbeat:Connect(function()
    if CFG.Hitbox.On then UpdateHitboxes() end
end)

-- ── Init ──────────────────────────────────────────────────
HookFireServer()
HookWorkspace()

print("[KD Suite] Carregado — use a interface para ativar os módulos.")
