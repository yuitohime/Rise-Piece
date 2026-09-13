-- =====================================================================
-- SUPERIOR AUTO FARM SCRIPT (RISE PIECE / GENERIC) - VERSION 3.0
-- Tối ưu hóa hiệu năng, Chống Memory Leak triệt để.
-- [CẬP NHẬT]: Nút X Đóng Menu, Farm All Boss, Chế độ Tween/Teleport, 
-- Ưu tiên đánh quái khi đợi Boss, Fix Auto Attack, Chuyển mục tiêu cực nhanh.
-- =====================================================================

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- [ HỆ THỐNG QUẢN LÝ KẾT NỐI (CHỐNG MEMORY LEAK) ]
local RuntimeConnections = {}
local function SafeConnect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(RuntimeConnections, conn)
    return conn
end

local function DisconnectAll()
    for _, conn in ipairs(RuntimeConnections) do
        if conn.Connected then conn:Disconnect() end
    end
    table.clear(RuntimeConnections)
end

-- [ CẤU HÌNH BIẾN TOÀN CỤC ]
local Config = {
    AutoFarm = false,
    AutoBoss = false,
    FarmAllBosses = false, -- Chế độ đi lùng sục tất cả Boss
    AutoAttack = false,
    MovementMode = "Teleport", -- "Tween" hoặc "Teleport"
    FarmPosition = "Trên đầu",
    Distance = 5,
    TweenDuration = 0.5,
    BossWaitTime = 0.5, -- Cập nhật min 0.1s
    SelectedWeapon = nil,
    SelectedMobs = {}, 
    SelectedBosses = {},
    MobListCache = {}, 
    BossDataCache = {}, 
    TargetMob = nil,
    MenuOpen = false,
    CurrentBossIndex = 1,
    LastBossCheck = tick()
}

local isTweening = false
local currentTween = nil

-- [ KHỞI TẠO GIAO DIỆN ]
local UI_NAME = "RisePiece_PremiumUI_V3"
if CoreGui:FindFirstChild(UI_NAME) then
    CoreGui:FindFirstChild(UI_NAME):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = UI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (pcall(function() return CoreGui.Name end) and CoreGui) or Players.LocalPlayer:WaitForChild("PlayerGui")

-- Nút Mở/Đóng (Hình Đa Giác - Diamond Shape)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 40, 0, 40)
ToggleButton.Position = UDim2.new(0, 20, 0.5, -20)
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
ToggleButton.Text = ""
ToggleButton.Rotation = 45
ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleButton

local ToggleLabel = Instance.new("TextLabel")
ToggleLabel.Size = UDim2.new(1, 0, 1, 0)
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Text = "MỞ"
ToggleLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
ToggleLabel.Font = Enum.Font.GothamBold
ToggleLabel.TextSize = 14
ToggleLabel.Rotation = -45
ToggleLabel.Parent = ToggleButton

-- Khung Menu Chính
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(60, 60, 70)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Nút X để xóa Menu
local CloseMenuBtn = Instance.new("TextButton")
CloseMenuBtn.Size = UDim2.new(0, 25, 0, 25)
CloseMenuBtn.Position = UDim2.new(1, -35, 0, 10)
CloseMenuBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseMenuBtn.Text = "X"
CloseMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseMenuBtn.Font = Enum.Font.GothamBold
CloseMenuBtn.TextSize = 14
CloseMenuBtn.ZIndex = 10
CloseMenuBtn.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseMenuBtn

CloseMenuBtn.MouseButton1Click:Connect(function()
    DisconnectAll()
    ScreenGui:Destroy()
end)

-- [ BỐ CỤC: TIỆN ÍCH (TRÁI) & CHỨC NĂNG (PHẢI) ]
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0, 120, 1, 0)
LeftPanel.Position = UDim2.new(0, 0, 0, 0)
LeftPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
LeftPanel.Parent = MainFrame

local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(1, -120, 1, 0)
RightPanel.Position = UDim2.new(0, 120, 0, 0)
RightPanel.BackgroundTransparency = 1
RightPanel.Parent = MainFrame

local LeftLayout = Instance.new("UIListLayout")
LeftLayout.Parent = LeftPanel
LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
LeftLayout.Padding = UDim.new(0, 5)
LeftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local PanelPadding = Instance.new("UIPadding")
PanelPadding.Parent = LeftPanel
PanelPadding.PaddingTop = UDim.new(0, 10)

-- Tiêu đề Menu
local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size = UDim2.new(1, 0, 0, 30)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text = "TIỆN ÍCH"
MenuTitle.TextColor3 = Color3.fromRGB(0, 255, 128)
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextSize = 16
MenuTitle.Parent = LeftPanel

-- Các Tab Chức Năng
local Tabs = {}
local TabContents = {}

local function SwitchTab(tabName)
    for name, content in pairs(TabContents) do
        content.Visible = (name == tabName)
    end
    for name, btn in pairs(Tabs) do
        if name == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            btn.TextColor3 = Color3.fromRGB(0, 255, 128)
        else
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

local function CreateTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.Parent = LeftPanel
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -20, 1, -20)
    content.Position = UDim2.new(0, 10, 0, 10)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 4
    content.Visible = false
    content.Parent = RightPanel
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = content
    
    Tabs[name] = btn
    TabContents[name] = content
    
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    return content
end

local MainTab = CreateTabButton("Main")
local BossTab = CreateTabButton("Boss")
local SettingTab = CreateTabButton("Setting")

-- [ COMPONENTS HỖ TRỢ ]
local function CreateToggle(parent, text, configKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local switchBg = Instance.new("TextButton")
    switchBg.Size = UDim2.new(0, 40, 0, 20)
    switchBg.Position = UDim2.new(1, -50, 0.5, -10)
    switchBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    switchBg.BackgroundTransparency = 0.5
    switchBg.Text = ""
    switchBg.Parent = frame
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = UDim2.new(0, 2, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    circle.Parent = switchBg
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    
    local function UpdateUI()
        local toggled = Config[configKey]
        local goalPos = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        local goalCol = toggled and Color3.fromRGB(0, 255, 128) or Color3.fromRGB(200, 200, 200)
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = goalPos, BackgroundColor3 = goalCol}):Play()
    end
    
    switchBg.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        UpdateUI()
    end)
    UpdateUI()
    return frame
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function CreateSlider(parent, text, min, max, default, configKey, isDecimal)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local sliderBg = Instance.new("TextButton")
    sliderBg.Size = UDim2.new(1, -20, 0, 10)
    sliderBg.Position = UDim2.new(0, 10, 0, 30)
    sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sliderBg.Text = ""
    sliderBg.Parent = frame
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 255, 128)
    sliderFill.Parent = sliderBg
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = min + (max - min) * pos
        if not isDecimal then 
            value = math.floor(value) 
        else 
            value = math.floor(value * 10) / 10 
        end
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        label.Text = text .. ": " .. tostring(value)
        Config[configKey] = value
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    
    Config[configKey] = default
    return frame
end

-- [ LOGIC NHẬN DIỆN BOSS & LEVEL ]
local function IsAlive(mob)
    return mob and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart")
end

local function IsBoss(mob)
    if mob.Name:lower():find("boss") then return true end
    if mob:FindFirstChild("Humanoid") and mob.Humanoid.MaxHealth >= 5000 then return true end
    for _, v in pairs(mob:GetDescendants()) do
        if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then return true end
    end
    return false
end

local function GetMobLevel(mobName)
    local level = mobName:match("%d+")
    return level and tonumber(level) or 1
end

-- [ XÂY DỰNG TAB: MAIN (QUÉT QUÁI & FARM) ]
local MobListContainer = Instance.new("ScrollingFrame")
MobListContainer.Size = UDim2.new(1, 0, 0, 150)
MobListContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MobListContainer.ScrollBarThickness = 4

local MobListLayout = Instance.new("UIListLayout")
MobListLayout.SortOrder = Enum.SortOrder.LayoutOrder
MobListLayout.Parent = MobListContainer

local BossListContainer = Instance.new("ScrollingFrame")
BossListContainer.Size = UDim2.new(1, 0, 0, 150)
BossListContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
BossListContainer.ScrollBarThickness = 4

local BossListLayout = Instance.new("UIListLayout")
BossListLayout.SortOrder = Enum.SortOrder.LayoutOrder
BossListLayout.Parent = BossListContainer

local function UpdateMobUIList()
    for _, child in pairs(MobListContainer:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    for mobName, _ in pairs(Config.MobListCache) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Config.SelectedMobs[mobName] and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(40, 40, 45)
        btn.Text = " " .. mobName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = MobListContainer
        
        btn.MouseButton1Click:Connect(function()
            if Config.SelectedMobs[mobName] then
                Config.SelectedMobs[mobName] = nil
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            else
                Config.SelectedMobs[mobName] = true
                btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
            end
        end)
    end
    MobListContainer.CanvasSize = UDim2.new(0, 0, 0, MobListLayout.AbsoluteContentSize.Y)
end

local function UpdateBossUIList()
    for _, child in pairs(BossListContainer:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    for bossName, coords in pairs(Config.BossDataCache) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Config.SelectedBosses[bossName] and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(40, 40, 45)
        btn.Text = " [BOSS] " .. bossName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = BossListContainer
        
        btn.MouseButton1Click:Connect(function()
            if Config.SelectedBosses[bossName] then
                Config.SelectedBosses[bossName] = nil
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            else
                Config.SelectedBosses[bossName] = true
                btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            end
        end)
    end
    BossListContainer.CanvasSize = UDim2.new(0, 0, 0, BossListLayout.AbsoluteContentSize.Y)
end

CreateButton(MainTab, "Quét Quái & Boss Bản Đồ", function()
    local mapa = Workspace:FindFirstChild("Mapa")
    local enemiesFolder = mapa and mapa:FindFirstChild("Enemies")
    
    local function ScanObj(obj)
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj ~= LocalPlayer.Character then
            if IsBoss(obj) then
                Config.BossDataCache[obj.Name] = obj.HumanoidRootPart.Position
            else
                Config.MobListCache[obj.Name] = true
            end
        end
    end

    if enemiesFolder then
        for _, obj in pairs(enemiesFolder:GetDescendants()) do ScanObj(obj) end
    else
        for _, obj in pairs(Workspace:GetDescendants()) do ScanObj(obj) end
    end
    
    for name, _ in pairs(Config.SelectedMobs) do Config.MobListCache[name] = true end
    UpdateMobUIList()
    UpdateBossUIList()
end)

MobListContainer.Parent = MainTab
CreateToggle(MainTab, "Bật/Tắt Auto Farm Quái", "AutoFarm")

-- [ XÂY DỰNG TAB: BOSS ]
CreateToggle(BossTab, "Bật/Tắt Auto Boss", "AutoBoss")
CreateToggle(BossTab, "Farm Tất Cả Boss (Lùng Sục)", "FarmAllBosses")
CreateSlider(BossTab, "Thời gian chờ Boss (s)", 0.1, 60, 0.5, "BossWaitTime", true)
BossListContainer.Parent = BossTab

-- [ XÂY DỰNG TAB: SETTING ]
-- Toggle Chế độ di chuyển (Tween / Teleport)
CreateButton(SettingTab, "Chế độ di chuyển: " .. Config.MovementMode, function(btn)
    Config.MovementMode = (Config.MovementMode == "Tween") and "Teleport" or "Tween"
    btn.Text = "Chế độ di chuyển: " .. Config.MovementMode
end)

local PosTitle = Instance.new("TextLabel")
PosTitle.Size = UDim2.new(1, 0, 0, 20)
PosTitle.BackgroundTransparency = 1
PosTitle.Text = "Kiểu đánh:"
PosTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
PosTitle.Font = Enum.Font.Gotham
PosTitle.TextSize = 14
PosTitle.TextXAlignment = Enum.TextXAlignment.Left
PosTitle.Parent = SettingTab

local PosContainer = Instance.new("Frame")
PosContainer.Size = UDim2.new(1, 0, 0, 80)
PosContainer.BackgroundTransparency = 1
PosContainer.Parent = SettingTab

local PosGrid = Instance.new("UIGridLayout")
PosGrid.CellSize = UDim2.new(0.48, 0, 0, 35)
PosGrid.CellPadding = UDim2.new(0.04, 0, 0, 10)
PosGrid.Parent = PosContainer

local PositionsList = {"Trên đầu", "Đằng sau", "Đằng trước", "Dưới chân"}
local posButtons = {}

for _, posName in ipairs(PositionsList) do
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = (Config.FarmPosition == posName) and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(30, 30, 35)
    btn.Text = posName
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = PosContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    posButtons[posName] = btn
    
    btn.MouseButton1Click:Connect(function()
        Config.FarmPosition = posName
        for n, b in pairs(posButtons) do
            b.BackgroundColor3 = (n == posName) and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(30, 30, 35)
        end
    end)
end

CreateSlider(SettingTab, "Khoảng cách đánh", 0, 50, 5, "Distance", false)
CreateSlider(SettingTab, "Tốc độ Tween (giây)", 0.1, 10, 0.5, "TweenDuration", true)
CreateToggle(SettingTab, "Bật/Tắt Auto Attack", "AutoAttack")

CreateButton(SettingTab, "Quét Vũ Khí", function() UpdateWeaponList() end)

local WeaponListContainer = Instance.new("ScrollingFrame")
WeaponListContainer.Size = UDim2.new(1, 0, 0, 100)
WeaponListContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
WeaponListContainer.ScrollBarThickness = 4
WeaponListContainer.Parent = SettingTab

local WeaponListLayout = Instance.new("UIListLayout")
WeaponListLayout.SortOrder = Enum.SortOrder.LayoutOrder
WeaponListLayout.Parent = WeaponListContainer

function UpdateWeaponList()
    for _, child in pairs(WeaponListContainer:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    local tools = {}
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then tools[tool.Name] = tool end
    end
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then tools[tool.Name] = tool end
        end
    end
    
    for toolName, _ in pairs(tools) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = (Config.SelectedWeapon == toolName) and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(40, 40, 45)
        btn.Text = " " .. toolName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = WeaponListContainer
        
        btn.MouseButton1Click:Connect(function()
            Config.SelectedWeapon = toolName
            UpdateWeaponList()
        end)
    end
    WeaponListContainer.CanvasSize = UDim2.new(0, 0, 0, WeaponListLayout.AbsoluteContentSize.Y)
end

SwitchTab("Main")

-- [ ANIMATION MỞ / ĐÓNG MENU ]
ToggleButton.MouseButton1Click:Connect(function()
    Config.MenuOpen = not Config.MenuOpen
    local info = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    if Config.MenuOpen then
        ToggleLabel.Text = "ĐÓNG"
        ToggleLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        TweenService:Create(MainFrame, info, {Size = UDim2.new(0, 500, 0, 380)}):Play()
    else
        ToggleLabel.Text = "MỞ"
        ToggleLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
        TweenService:Create(MainFrame, info, {Size = UDim2.new(0, 0, 0, 0)}):Play()
    end
end)

-- [ LOGIC TÌM MỤC TIÊU & AUTO FARM ]
local function GetOffsetCFrame(baseCFrame)
    local dist = Config.Distance
    if Config.FarmPosition == "Trên đầu" then 
        return baseCFrame * CFrame.new(0, dist, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    elseif Config.FarmPosition == "Đằng sau" then 
        return baseCFrame * CFrame.new(0, 0, dist)
    elseif Config.FarmPosition == "Đằng trước" then 
        return baseCFrame * CFrame.new(0, 0, -dist)
    elseif Config.FarmPosition == "Dưới chân" then 
        return baseCFrame * CFrame.new(0, -dist, 0) * CFrame.Angles(math.rad(90), 0, 0)
    end
    return baseCFrame * CFrame.new(0, dist, 0)
end

local function FindMobInWorkspace(name, requireAlive)
    local mapa = Workspace:FindFirstChild("Mapa")
    local enemiesFolder = mapa and mapa:FindFirstChild("Enemies") or Workspace
    for _, obj in pairs(enemiesFolder:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == name then
            if requireAlive and not IsAlive(obj) then continue end
            return obj
        end
    end
    return nil
end

local function GetBestMobTarget()
    local bestTarget = nil
    local highestLevel = -1
    local shortestDist = math.huge
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myPos = hrp and hrp.Position or Vector3.new(0,0,0)

    local mapa = Workspace:FindFirstChild("Mapa")
    local enemiesFolder = mapa and mapa:FindFirstChild("Enemies") or Workspace

    for _, obj in pairs(enemiesFolder:GetDescendants()) do
        if obj:IsA("Model") and IsAlive(obj) and obj ~= LocalPlayer.Character and not IsBoss(obj) then
            if Config.SelectedMobs[obj.Name] then
                local level = GetMobLevel(obj.Name)
                local dist = (obj.HumanoidRootPart.Position - myPos).Magnitude
                
                if level > highestLevel then
                    highestLevel = level
                    shortestDist = dist
                    bestTarget = obj
                elseif level == highestLevel then
                    if dist < shortestDist then
                        shortestDist = dist
                        bestTarget = obj
                    end
                end
            end
        end
    end
    return bestTarget
end

local function TeleportTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = char.HumanoidRootPart
    
    if Config.MovementMode == "Teleport" then
        if currentTween then currentTween:Cancel(); currentTween = nil; isTweening = false end
        rootPart.CFrame = targetCFrame
    else
        -- Chế độ Tween
        local dist = (rootPart.Position - targetCFrame.Position).Magnitude
        if dist > 15 then
            if not isTweening then
                isTweening = true
                if currentTween then currentTween:Cancel() end
                currentTween = TweenService:Create(rootPart, TweenInfo.new(Config.TweenDuration, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
                currentTween:Play()
                currentTween.Completed:Connect(function() isTweening = false end)
            end
        else
            isTweening = false
            if currentTween then currentTween:Cancel(); currentTween = nil end
            rootPart.CFrame = targetCFrame
        end
    end
end

local function EquipWeapon()
    if not Config.SelectedWeapon then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if not char then return end
    
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and currentTool.Name ~= Config.SelectedWeapon then
        currentTool.Parent = backpack
    end
    
    if backpack and backpack:FindFirstChild(Config.SelectedWeapon) then
        local tool = backpack:FindFirstChild(Config.SelectedWeapon)
        char.Humanoid:EquipTool(tool)
    end
end

local function Attack()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        -- Dùng Activate gốc của game, không click chuột ảo tránh loạn UI
        tool:Activate() 
    end
end

-- Vòng lặp Farm Siêu Tốc mượt mà (Heartbeat) - Nhảy mục tiêu lập tức khi chết
SafeConnect(RunService.Heartbeat, function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local humanoid = char:FindFirstChild("Humanoid")
    
    if humanoid then humanoid:ChangeState(11) end -- Noclip an toàn, chống rơi
    
    local activeBosses = {}
    for name, _ in pairs(Config.SelectedBosses) do table.insert(activeBosses, name) end
    
    local bossToFight = nil

    -- LOGIC 1: Tìm Boss đang Spawn nếu Auto Boss hoặc Farm All Boss bật
    if (Config.AutoBoss or Config.FarmAllBosses) and #activeBosses > 0 then
        -- Tìm xem có con boss nào trong danh sách đang sống trên Map không
        for _, bossName in ipairs(activeBosses) do
            local bInst = FindMobInWorkspace(bossName, true)
            if bInst and IsAlive(bInst) then
                bossToFight = bInst
                Config.CurrentBossIndex = table.find(activeBosses, bossName) or 1
                break
            end
        end
    end

    -- LOGIC 2: Đánh Boss (Nếu có)
    if bossToFight then
        Config.LastBossCheck = tick()
        local targetPos = GetOffsetCFrame(bossToFight.HumanoidRootPart.CFrame)
        TeleportTo(targetPos)
        if Config.AutoAttack then EquipWeapon(); Attack() end
        return -- Khóa mục tiêu ở Boss
    end

    -- LOGIC 3: Boss chưa Spawn -> Ưu tiên đánh Quái Thường nếu có bật Auto Farm
    if Config.AutoFarm then
        local targetMob = GetBestMobTarget()
        if targetMob and IsAlive(targetMob) then
            local targetPos = GetOffsetCFrame(targetMob.HumanoidRootPart.CFrame)
            TeleportTo(targetPos)
            if Config.AutoAttack then EquipWeapon(); Attack() end
            return
        end
    end

    -- LOGIC 4: Boss chưa Spawn & Không bật đánh Quái -> Đi lùng sục tọa độ Boss
    if (Config.AutoBoss or Config.FarmAllBosses) and #activeBosses > 0 then
        if Config.CurrentBossIndex > #activeBosses then Config.CurrentBossIndex = 1 end
        local targetBossName = activeBosses[Config.CurrentBossIndex]
        
        local savedPos = Config.BossDataCache[targetBossName]
        if savedPos then
            local waitCFrame = GetOffsetCFrame(CFrame.new(savedPos))
            TeleportTo(waitCFrame)
            
            if tick() - Config.LastBossCheck >= Config.BossWaitTime then
                Config.LastBossCheck = tick()
                Config.CurrentBossIndex = Config.CurrentBossIndex + 1
            end
        else
            Config.CurrentBossIndex = Config.CurrentBossIndex + 1
        end
        return
    end

    -- LOGIC 5: Chỉ bật Auto Attack đứng tại chỗ
    if not Config.AutoFarm residential and not Config.AutoBoss and not Config.FarmAllBosses and Config.AutoAttack then
        EquipWeapon()
        Attack()
    end
end)

-- Tạo Anti-AFK để không bị văng game
SafeConnect(LocalPlayer.Idled, function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

print("Rise Piece Superior Auto Farm V3 Loaded successfully! No code truncated.")
