-- =====================================================================
-- SUPERIOR AUTO FARM SCRIPT (YUIHUB / MULTI-GAME) - [PRO VERSION]
-- Giao diện được thiết kế lại chuẩn YuiHuB (Maru Hub Style).
-- Tối ưu hóa hiệu năng, Chống Memory Leak triệt để. Đầy đủ chức năng gốc.
-- [UPDATE]: Cải tiến quét Quái/Boss toàn bản đồ, Thêm Skill (Z,X,C,V,B,N,E,F,T,J).
-- Thêm Hàng chờ Tọa Độ (Lưu & Teleport 3 vị trí).
-- =====================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Đợi LocalPlayer load xong để tránh đơ
while not Players.LocalPlayer do task.wait() end
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

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
    FarmAllBosses = false, 
    AutoEgg = false,
    EggESP = false,
    SelectedEggRarity = "Tất cả",
    AutoAttack = false,
    FastAttack = false,
    AutoFishing = false, 
    -- Skills
    AutoSkillZ = false, AutoSkillX = false, AutoSkillC = false, AutoSkillV = false, 
    AutoSkillB = false, AutoSkillN = false, AutoSkillE = false, AutoSkillF = false, 
    AutoSkillT = false, AutoSkillJ = false,
    
    MovementMode = "Teleport", 
    FarmPosition = "Trên đầu",
    Distance = 5,
    TweenDuration = 0.5,
    BossWaitTime = 0.5, 
    
    SelectedWeapons = {}, 
    SelectedMobs = {}, 
    SelectedBosses = {},
    MobListCache = {}, 
    BossDataCache = {}, 
    MobDataCache = {},
    
    MenuOpen = true,
    CurrentBossIndex = 1,
    LastBossCheck = tick(),
    
    -- Player Config
    WalkSpeedEnabled = false,
    WalkSpeed = 50,
    JumpPowerEnabled = false,
    JumpPower = 100,
    InfJump = false,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,
    WalkOnWater = false,
    
    -- Coordinate Saver
    SavedPos1 = nil,
    SavedPos2 = nil,
    SavedPos3 = nil
}

local isTweening = false
local currentTween = nil
local activelyFarming = false 

-- [ TẠO GIAO DIỆN YUIHUB (MARU HUB STYLE) ]
local UI_NAME = "YuiHuB_Premium_UI"
local targetParent = nil
pcall(function()
    if get_hidden_gui or gethui then
        targetParent = (get_hidden_gui or gethui)()
    elseif game:GetService("CoreGui") then
        targetParent = game:GetService("CoreGui")
    end
end)

if not targetParent then
    targetParent = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
end

if targetParent:FindFirstChild(UI_NAME) then
    targetParent:FindFirstChild(UI_NAME):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = UI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = targetParent

-- Nút Toggle Góc Màn Hình
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Position = UDim2.new(0, 15, 0.5, -22)
ToggleButton.BackgroundColor3 = Color3.fromRGB(26, 29, 36)
ToggleButton.Text = "YUI"
ToggleButton.TextColor3 = Color3.fromRGB(100, 170, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 14
ToggleButton.Parent = ScreenGui
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ToggleButton).Color = Color3.fromRGB(60, 65, 80)

-- Main Frame (Giống Maru Hub)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 700, 0, 450)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(17, 19, 24) -- Dark theme base
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Sidebar (Bên trái)
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 60)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "  YuiHuB"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 22
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Sidebar

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.new(1, -20, 0, 20)
VersionLabel.Position = UDim2.new(0, 20, 0, 40)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text = "Multi-Game Script"
VersionLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
VersionLabel.Font = Enum.Font.Gotham
VersionLabel.TextSize = 11
VersionLabel.TextXAlignment = Enum.TextXAlignment.Left
VersionLabel.Parent = Sidebar

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Size = UDim2.new(1, 0, 1, -70)
SidebarScroll.Position = UDim2.new(0, 0, 0, 70)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.ScrollBarThickness = 2
SidebarScroll.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 2)
SidebarLayout.Parent = SidebarScroll

-- Content Area (Bên phải)
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -180, 1, 0)
ContentArea.Position = UDim2.new(0, 180, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local Topbar = Instance.new("Frame")
Topbar.Size = UDim2.new(1, 0, 0, 50)
Topbar.BackgroundTransparency = 1
Topbar.Parent = ContentArea

local CurrentTabTitle = Instance.new("TextLabel")
CurrentTabTitle.Size = UDim2.new(1, -20, 1, 0)
CurrentTabTitle.Position = UDim2.new(0, 20, 0, 0)
CurrentTabTitle.BackgroundTransparency = 1
CurrentTabTitle.Text = "Overview"
CurrentTabTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
CurrentTabTitle.Font = Enum.Font.GothamBold
CurrentTabTitle.TextSize = 18
CurrentTabTitle.TextXAlignment = Enum.TextXAlignment.Left
CurrentTabTitle.Parent = Topbar

local CloseMenuBtn = Instance.new("TextButton")
CloseMenuBtn.Size = UDim2.new(0, 30, 0, 30)
CloseMenuBtn.Position = UDim2.new(1, -40, 0, 10)
CloseMenuBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseMenuBtn.Text = "X"
CloseMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseMenuBtn.Font = Enum.Font.GothamBold
CloseMenuBtn.Parent = Topbar
Instance.new("UICorner", CloseMenuBtn).CornerRadius = UDim.new(0, 6)
CloseMenuBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy(); DisconnectAll() end)

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, 0, 1, -50)
ContentContainer.Position = UDim2.new(0, 0, 0, 50)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = ContentArea

-- Hệ thống Quản lý Tab
local Tabs = {}
local TabContents = {}

local function CreateCategory(name)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 25)
    lbl.Position = UDim2.new(0, 20, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name:upper()
    lbl.TextColor3 = Color3.fromRGB(120, 120, 130)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = SidebarScroll
end

local function SwitchTab(tabName)
    CurrentTabTitle.Text = tabName
    for name, content in pairs(TabContents) do
        content.Visible = (name == tabName)
    end
    for name, btn in pairs(Tabs) do
        if name == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
            btn.TextColor3 = Color3.fromRGB(180, 180, 190)
        end
    end
end

local function CreateTabButton(name)
    local btnFrame = Instance.new("Frame")
    btnFrame.Size = UDim2.new(1, 0, 0, 35)
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = SidebarScroll
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 1, 0)
    btn.Position = UDim2.new(0, 10, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(180, 180, 190)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = btnFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -30, 1, -10)
    content.Position = UDim2.new(0, 15, 0, 0)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 3
    content.Visible = false
    content.Parent = ContentContainer
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 12)
    layout.Parent = content
    
    Tabs[name] = btn
    TabContents[name] = content
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    
    -- Tự động resize scrolling frame
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    return content
end

-- [ CÁC HÀM UI COMPONENTS CƠ BẢN GIỐNG MARU HUB ]
local function CreateSection(parent, title)
    local sec = Instance.new("Frame")
    sec.Size = UDim2.new(1, 0, 0, 30)
    sec.BackgroundTransparency = 1
    sec.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = sec
    return sec
end

local function CreateToggle(parent, text, configKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(28, 31, 38)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 240)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local switchBg = Instance.new("TextButton")
    switchBg.Size = UDim2.new(0, 44, 0, 22)
    switchBg.Position = UDim2.new(1, -60, 0.5, -11)
    switchBg.BackgroundColor3 = Color3.fromRGB(45, 48, 55)
    switchBg.Text = ""
    switchBg.Parent = frame
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 18, 0, 18)
    circle.Position = UDim2.new(0, 2, 0.5, -9)
    circle.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
    circle.Parent = switchBg
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    
    local function UpdateUI()
        local toggled = Config[configKey]
        local goalPos = toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        local goalCol = toggled and Color3.fromRGB(100, 170, 255) or Color3.fromRGB(200, 200, 210)
        local bgCol = toggled and Color3.fromRGB(40, 60, 100) or Color3.fromRGB(45, 48, 55)
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = goalPos, BackgroundColor3 = goalCol}):Play()
        TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = bgCol}):Play()
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
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(45, 90, 180)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function CreateSlider(parent, text, min, max, default, configKey, isDecimal)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(28, 31, 38)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 0, 30)
    label.Position = UDim2.new(0, 15, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(230, 230, 240)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local sliderBg = Instance.new("TextButton")
    sliderBg.Size = UDim2.new(1, -30, 0, 8)
    sliderBg.Position = UDim2.new(0, 15, 0, 40)
    sliderBg.BackgroundColor3 = Color3.fromRGB(45, 48, 55)
    sliderBg.Text = ""
    sliderBg.Parent = frame
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(100, 170, 255)
    sliderFill.Parent = sliderBg
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = min + (max - min) * pos
        if not isDecimal then value = math.floor(value) else value = math.floor(value * 10) / 10 end
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        label.Text = text .. ": " .. tostring(value)
        Config[configKey] = value
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; updateSlider(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateSlider(input) end
    end)
    Config[configKey] = default
    return frame
end

local function CreateDropdown(parent, titleText)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 45)
    container.BackgroundColor3 = Color3.fromRGB(28, 31, 38)
    container.ClipsDescendants = true
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 0, 45)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = "   ▼ " .. titleText
    toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 13
    toggleBtn.TextXAlignment = Enum.TextXAlignment.Left
    toggleBtn.Parent = container
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 1, -50)
    scrollFrame.Position = UDim2.new(0, 5, 0, 45)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 3
    scrollFrame.Visible = false
    scrollFrame.Parent = container
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = scrollFrame
    
    local isOpen = false
    toggleBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        scrollFrame.Visible = isOpen
        toggleBtn.Text = (isOpen and "   ▲ " or "   ▼ ") .. titleText
        container.Size = isOpen and UDim2.new(1, 0, 0, 220) or UDim2.new(1, 0, 0, 45)
    end)
    return scrollFrame, layout, container
end

-- [ KHỞI TẠO CÁC DANH MỤC & TAB YUIHUB ]
CreateCategory("Workspace")
local OverviewTab = CreateTabButton("Overview")
local FarmingTab = CreateTabButton("Farming")

CreateCategory("Bosses")
local BossesTab = CreateTabButton("Bosses")

CreateCategory("World")
local WorldTravelTab = CreateTabButton("Travel & Coords")
local WorldItemsTab = CreateTabButton("Eggs & Fruits")

CreateCategory("Activities")
local PlayerTab = CreateTabButton("Player Mods")
local FishingTab = CreateTabButton("Fishing")

CreateCategory("System")
local SettingsTab = CreateTabButton("Settings")

-- =========================================================
-- [ LÕI LOGIC: HÀM QUÉT SIÊU VIỆT & TÌM KIẾM ]
-- =========================================================
local function TeleportToPos(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

local function GetMobFolders()
    local folders = {}
    local possibleNames = {"mapa", "map", "enemies", "monsters", "mobs", "npcs", "spawns"}
    for _, name in ipairs(possibleNames) do
        local f = Workspace:FindFirstChild(name) or Workspace:FindFirstChild(name:upper()) or Workspace:FindFirstChild(name:sub(1,1):upper()..name:sub(2))
        if f then table.insert(folders, f) end
    end
    if #folders == 0 then table.insert(folders, Workspace) end
    return folders
end

local function IsAlive(mob)
    return mob and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart")
end

local function ScanObj(obj)
    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj ~= LocalPlayer.Character then
        local lowerName = obj.Name:lower()
        if lowerName:match("^spawnner") or lowerName:match("^spawner") then return end
        
        -- Nâng cấp nhận diện Quái/Boss đa tựa game
        if lowerName:match("boss") then
            Config.BossDataCache[obj.Name] = obj.HumanoidRootPart.Position
        elseif lowerName:match("monster") or lowerName:match("enemy") or lowerName:match("mob") or lowerName:match("npc") or lowerName:match("lv") or lowerName:match("level") then
            Config.MobListCache[obj.Name] = true
            Config.MobDataCache[obj.Name] = obj.HumanoidRootPart.Position
        else
            -- Lấy dự phòng tất cả model có Humanoid
            Config.MobListCache[obj.Name] = true
            Config.MobDataCache[obj.Name] = obj.HumanoidRootPart.Position
        end
    end
end

-- =========================================================
-- [ TAB: OVERVIEW (Giao diện tổng quan mẫu) ]
-- =========================================================
CreateSection(OverviewTab, "Chào mừng đến với YuiHuB")
local InfoLbl = Instance.new("TextLabel")
InfoLbl.Size = UDim2.new(1, 0, 0, 60)
InfoLbl.BackgroundTransparency = 1
InfoLbl.Text = "YuiHuB Premium Script\nHỗ trợ Auto Farm, Auto Boss, Lưu Tọa độ, Quét mở rộng đa tựa game.\nSử dụng các Tab bên trái để điều hướng."
InfoLbl.TextColor3 = Color3.fromRGB(180, 180, 190)
InfoLbl.Font = Enum.Font.Gotham
InfoLbl.TextSize = 13
InfoLbl.TextWrapped = true
InfoLbl.TextXAlignment = Enum.TextXAlignment.Left
InfoLbl.Parent = OverviewTab

-- =========================================================
-- [ TAB: FARMING (Quái & Kỹ năng) ]
-- =========================================================
CreateSection(FarmingTab, "Cài Đặt Farm Quái")
CreateButton(FarmingTab, "Quét Lại Quái Bản Đồ", function()
    local folders = GetMobFolders()
    for _, folder in ipairs(folders) do
        for _, obj in pairs(folder:GetDescendants()) do ScanObj(obj) end
    end
    for _, obj in pairs(Workspace:GetChildren()) do ScanObj(obj) end
    UpdateMobUIList()
end)

local MobListContainer, MobListLayout = CreateDropdown(FarmingTab, "Danh Sách Quái")
function UpdateMobUIList()
    for _, child in pairs(MobListContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for mobName, _ in pairs(Config.MobListCache) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Config.SelectedMobs[mobName] and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(35, 38, 45)
        btn.Text = "   " .. mobName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = MobListContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(function()
            Config.SelectedMobs[mobName] = not Config.SelectedMobs[mobName]
            btn.BackgroundColor3 = Config.SelectedMobs[mobName] and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(35, 38, 45)
        end)
    end
    MobListContainer.CanvasSize = UDim2.new(0, 0, 0, MobListLayout.AbsoluteContentSize.Y)
end

CreateToggle(FarmingTab, "Bật Auto Farm Quái", "AutoFarm")

CreateSection(FarmingTab, "Tự Động Tung Kỹ Năng (Skills)")
CreateToggle(FarmingTab, "Auto Skill [Z]", "AutoSkillZ")
CreateToggle(FarmingTab, "Auto Skill [X]", "AutoSkillX")
CreateToggle(FarmingTab, "Auto Skill [C]", "AutoSkillC")
CreateToggle(FarmingTab, "Auto Skill [V]", "AutoSkillV")
CreateToggle(FarmingTab, "Auto Skill [B]", "AutoSkillB")
CreateToggle(FarmingTab, "Auto Skill [N]", "AutoSkillN")
CreateToggle(FarmingTab, "Auto Skill [E]", "AutoSkillE")
CreateToggle(FarmingTab, "Auto Skill [F]", "AutoSkillF")
CreateToggle(FarmingTab, "Auto Skill [T]", "AutoSkillT")
CreateToggle(FarmingTab, "Auto Skill [J]", "AutoSkillJ")

-- =========================================================
-- [ TAB: BOSSES ]
-- =========================================================
CreateSection(BossesTab, "Cài Đặt Đánh Boss")
CreateButton(BossesTab, "Quét Lại Boss", function()
    local folders = GetMobFolders()
    for _, folder in ipairs(folders) do
        for _, obj in pairs(folder:GetDescendants()) do ScanObj(obj) end
    end
    for _, obj in pairs(Workspace:GetChildren()) do ScanObj(obj) end
    UpdateBossUIList()
end)

local BossListContainer, BossListLayout = CreateDropdown(BossesTab, "Danh Sách Boss")
function UpdateBossUIList()
    for _, child in pairs(BossListContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for bossName, coords in pairs(Config.BossDataCache) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Config.SelectedBosses[bossName] and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(35, 38, 45)
        btn.Text = "   [BOSS] " .. bossName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = BossListContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(function()
            Config.SelectedBosses[bossName] = not Config.SelectedBosses[bossName]
            btn.BackgroundColor3 = Config.SelectedBosses[bossName] and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(35, 38, 45)
        end)
    end
    BossListContainer.CanvasSize = UDim2.new(0, 0, 0, BossListLayout.AbsoluteContentSize.Y)
end

CreateToggle(BossesTab, "Bật Auto Boss", "AutoBoss")
CreateToggle(BossesTab, "Farm Tất Cả Boss (Lùng Sục)", "FarmAllBosses")
CreateSlider(BossesTab, "Thời gian chờ Boss (s)", 0.1, 60, 0.5, "BossWaitTime", true)

-- =========================================================
-- [ TAB: WORLD TRAVEL & COORDS (Chức năng Lưu Tọa Độ Mới) ]
-- =========================================================
CreateSection(WorldTravelTab, "Hệ Thống Dịch Chuyển Tọa Độ")

local function CreateCoordRow(parent, title, configKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(28, 31, 38)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0.5, 0, 1, 0)
    status.Position = UDim2.new(0, 15, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = title .. ": Chưa Lưu"
    status.TextColor3 = Color3.fromRGB(200, 200, 210)
    status.Font = Enum.Font.GothamSemibold
    status.TextSize = 12
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = frame
    
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0, 60, 0, 25)
    saveBtn.Position = UDim2.new(1, -140, 0.5, -12.5)
    saveBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
    saveBtn.Text = "Lưu"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.Parent = frame
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)
    
    local teleBtn = Instance.new("TextButton")
    teleBtn.Size = UDim2.new(0, 60, 0, 25)
    teleBtn.Position = UDim2.new(1, -70, 0.5, -12.5)
    teleBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 180)
    teleBtn.Text = "Tele"
    teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleBtn.Font = Enum.Font.GothamBold
    teleBtn.Parent = frame
    Instance.new("UICorner", teleBtn).CornerRadius = UDim.new(0, 6)
    
    saveBtn.MouseButton1Click:Connect(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            Config[configKey] = hrp.CFrame
            status.Text = title .. ": Đã Lưu"
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
    end)
    
    teleBtn.MouseButton1Click:Connect(function()
        if Config[configKey] then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = Config[configKey] end
        end
    end)
end

CreateCoordRow(WorldTravelTab, "Tọa Độ 1", "SavedPos1")
CreateCoordRow(WorldTravelTab, "Tọa Độ 2", "SavedPos2")
CreateCoordRow(WorldTravelTab, "Tọa Độ 3", "SavedPos3")

CreateSection(WorldTravelTab, "Dịch Chuyển NPC")
local NpcListContainer, NpcListLayout = CreateDropdown(WorldTravelTab, "Danh Sách NPC")
CreateButton(WorldTravelTab, "Quét Tìm NPC", function()
    for _, child in pairs(NpcListContainer:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    local foundNPCs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():match("npc") and obj:FindFirstChild("HumanoidRootPart") then
            table.insert(foundNPCs, {Name = obj.Name, Pos = obj.HumanoidRootPart.Position})
        end
    end
    for _, data in ipairs(foundNPCs) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, 0, 0, 35)
        itemFrame.BackgroundColor3 = Color3.fromRGB(35, 38, 45)
        itemFrame.Parent = NpcListContainer
        Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 4)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = data.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = itemFrame
        
        local teleBtn = Instance.new("TextButton")
        teleBtn.Size = UDim2.new(0, 50, 0, 25)
        teleBtn.Position = UDim2.new(1, -60, 0.5, -12.5)
        teleBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 180)
        teleBtn.Text = "Tele"
        teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        teleBtn.Font = Enum.Font.GothamBold
        teleBtn.Parent = itemFrame
        Instance.new("UICorner", teleBtn).CornerRadius = UDim.new(0, 4)
        teleBtn.MouseButton1Click:Connect(function() TeleportToPos(data.Pos) end)
    end
    NpcListContainer.CanvasSize = UDim2.new(0, 0, 0, NpcListLayout.AbsoluteContentSize.Y)
end)

-- =========================================================
-- [ TAB: EGGS & FRUITS ]
-- =========================================================
CreateSection(WorldItemsTab, "Trứng (Eggs)")
local function GetEggs()
    local eggs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Name:lower():match("egg") then
            table.insert(eggs, obj)
        end
    end
    return eggs
end

CreateToggle(WorldItemsTab, "Bật ESP Trứng (Nhìn xuyên tường)", "EggESP")
CreateToggle(WorldItemsTab, "Auto Teleport Tới Trứng (Khi rơi)", "AutoEgg")

local EggRarityList = {"Tất cả", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine"}
CreateButton(WorldItemsTab, "Lọc Trứng: " .. Config.SelectedEggRarity, function(btn)
    local currentIndex = table.find(EggRarityList, Config.SelectedEggRarity) or 1
    currentIndex = currentIndex + 1
    if currentIndex > #EggRarityList then currentIndex = 1 end
    Config.SelectedEggRarity = EggRarityList[currentIndex]
    btn.Text = "Lọc Trứng: " .. Config.SelectedEggRarity
end)

CreateSection(WorldItemsTab, "Trái Ác Quỷ (Fruits)")
local FruitListContainer, FruitListLayout = CreateDropdown(WorldItemsTab, "Trái Ác Quỷ Đang Rơi")
CreateButton(WorldItemsTab, "Quét Tìm Trái Ác Quỷ", function()
    for _, child in pairs(FruitListContainer:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    local foundFruits = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if (obj:IsA("Tool") or obj:IsA("Model")) and string.match(obj.Name:lower(), "fruit") then
            local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
            if part then table.insert(foundFruits, {Name = obj.Name, Pos = part.Position}) end
        end
    end
    if #foundFruits == 0 then
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, 0, 0, 30); msg.BackgroundTransparency = 1; msg.Text = "Không có Trái Ác Quỷ nào trong map."
        msg.TextColor3 = Color3.fromRGB(200, 100, 100); msg.Font = Enum.Font.Gotham; msg.TextSize = 12; msg.Parent = FruitListContainer
    else
        for _, data in ipairs(foundFruits) do
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, 0, 0, 35); itemFrame.BackgroundColor3 = Color3.fromRGB(35, 38, 45); itemFrame.Parent = FruitListContainer
            Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 4)
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.7, 0, 1, 0); nameLabel.Position = UDim2.new(0, 10, 0, 0); nameLabel.BackgroundTransparency = 1
            nameLabel.Text = data.Name; nameLabel.TextColor3 = Color3.fromRGB(255, 255, 100); nameLabel.Font = Enum.Font.GothamSemibold
            nameLabel.TextSize = 12; nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.Parent = itemFrame
            local teleBtn = Instance.new("TextButton")
            teleBtn.Size = UDim2.new(0, 50, 0, 25); teleBtn.Position = UDim2.new(1, -60, 0.5, -12.5); teleBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 180)
            teleBtn.Text = "Tele"; teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); teleBtn.Font = Enum.Font.GothamBold; teleBtn.Parent = itemFrame
            Instance.new("UICorner", teleBtn).CornerRadius = UDim.new(0, 4)
            teleBtn.MouseButton1Click:Connect(function() TeleportToPos(data.Pos) end)
        end
    end
    FruitListContainer.CanvasSize = UDim2.new(0, 0, 0, FruitListLayout.AbsoluteContentSize.Y)
end)

-- [ ESP TRỨNG (Chống Lag) ]
local EspFolder = Instance.new("Folder", targetParent)
EspFolder.Name = "YuiHuB_EggESP"
local espCache = {}
SafeConnect(RunService.Heartbeat, function()
    if Config.EggESP then
        local eggs = GetEggs()
        local currentEggs = {}
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        for _, egg in ipairs(eggs) do
            currentEggs[egg] = true
            local part = egg:IsA("Model") and (egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")) or egg
            if part and hrp then
                local dist = (hrp.Position - part.Position).Magnitude
                if not espCache[egg] then
                    local bb = Instance.new("BillboardGui")
                    bb.Size = UDim2.new(0, 150, 0, 40); bb.AlwaysOnTop = true; bb.Adornee = part
                    local txt = Instance.new("TextLabel")
                    txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.TextColor3 = Color3.fromRGB(255, 200, 50)
                    txt.TextStrokeTransparency = 0; txt.Font = Enum.Font.GothamBold; txt.TextSize = 12; txt.Parent = bb; bb.Parent = EspFolder
                    espCache[egg] = {Gui = bb, Text = txt}
                end
                espCache[egg].Text.Text = string.format("%s [%d m]", egg.Name, math.floor(dist))
            end
        end
        for egg, cache in pairs(espCache) do
            if not currentEggs[egg] or not egg.Parent then cache.Gui:Destroy(); espCache[egg] = nil end
        end
    else
        for egg, cache in pairs(espCache) do cache.Gui:Destroy() end
        table.clear(espCache)
    end
end)

-- =========================================================
-- [ TAB: PLAYER MODS & FISHING ]
-- =========================================================
CreateSection(PlayerTab, "Cài Đặt Nhân Vật")
CreateToggle(PlayerTab, "Bật Tốc Độ Chạy", "WalkSpeedEnabled")
CreateSlider(PlayerTab, "Tốc Độ", 16, 300, 50, "WalkSpeed", false)
CreateToggle(PlayerTab, "Bật Sức Bật (Nhảy cao)", "JumpPowerEnabled")
CreateSlider(PlayerTab, "Sức Bật", 50, 500, 100, "JumpPower", false)
CreateToggle(PlayerTab, "Nhảy Vô Hạn (Inf Jump)", "InfJump")
CreateToggle(PlayerTab, "Xuyên Tường (Noclip)", "Noclip")
CreateToggle(PlayerTab, "Đi Trên Mặt Nước", "WalkOnWater")
CreateToggle(PlayerTab, "Bay Tự Do (Fly)", "Fly")
CreateSlider(PlayerTab, "Tốc Độ Bay", 16, 500, 50, "FlySpeed", false)

CreateSection(FishingTab, "Cài Đặt Câu Cá")
CreateToggle(FishingTab, "Bật Auto Câu Cá", "AutoFishing")

-- =========================================================
-- [ TAB: SETTINGS ]
-- =========================================================
CreateSection(SettingsTab, "Hệ Thống Di Chuyển")
CreateButton(SettingsTab, "Chế Độ Di Chuyển: " .. Config.MovementMode, function(btn)
    Config.MovementMode = (Config.MovementMode == "Tween") and "Teleport" or "Tween"
    btn.Text = "Chế Độ Di Chuyển: " .. Config.MovementMode
end)

local PosLbl = Instance.new("TextLabel")
PosLbl.Size = UDim2.new(1, 0, 0, 25); PosLbl.BackgroundTransparency = 1; PosLbl.Text = "Vị trí Đánh Quái/Boss:"
PosLbl.TextColor3 = Color3.fromRGB(200, 200, 210); PosLbl.Font = Enum.Font.GothamSemibold; PosLbl.TextSize = 13
PosLbl.TextXAlignment = Enum.TextXAlignment.Left; PosLbl.Parent = SettingsTab

local PosContainer = Instance.new("Frame")
PosContainer.Size = UDim2.new(1, 0, 0, 45); PosContainer.BackgroundTransparency = 1; PosContainer.Parent = SettingsTab
local PosGrid = Instance.new("UIGridLayout")
PosGrid.CellSize = UDim2.new(0.23, 0, 0, 35); PosGrid.CellPadding = UDim2.new(0.02, 0, 0, 0); PosGrid.Parent = PosContainer

local PositionsList = {"Trên đầu", "Đằng sau", "Đằng trước", "Dưới chân"}
local posButtons = {}
for _, posName in ipairs(PositionsList) do
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = (Config.FarmPosition == posName) and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(35, 38, 45)
    btn.Text = posName; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Font = Enum.Font.Gotham; btn.TextSize = 11; btn.Parent = PosContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    posButtons[posName] = btn
    btn.MouseButton1Click:Connect(function()
        Config.FarmPosition = posName
        for n, b in pairs(posButtons) do b.BackgroundColor3 = (n == posName) and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(35, 38, 45) end
    end)
end

CreateSlider(SettingsTab, "Khoảng Cách Đánh", 0, 50, 5, "Distance", false)
CreateSlider(SettingsTab, "Tốc Độ Tween (s)", 0.1, 10, 0.5, "TweenDuration", true)
CreateSection(SettingsTab, "Cài Đặt Vũ Khí")
CreateToggle(SettingsTab, "Auto Click Thường", "AutoAttack")
CreateToggle(SettingsTab, "FAST ATTACK (Siêu nhanh)", "FastAttack")

local WeaponListContainer, WeaponListLayout = CreateDropdown(SettingsTab, "Chọn Vũ Khí Để Farm")
CreateButton(SettingsTab, "Quét Cập Nhật Vũ Khí", function()
    for _, child in pairs(WeaponListContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local tools = {}
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do if tool:IsA("Tool") then tools[tool.Name] = tool end end
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do if tool:IsA("Tool") then tools[tool.Name] = tool end end
    end
    for toolName, _ in pairs(tools) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30); btn.BackgroundColor3 = Config.SelectedWeapons[toolName] and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(35, 38, 45)
        btn.Text = "   " .. toolName; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Font = Enum.Font.Gotham; btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = WeaponListContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(function()
            if Config.SelectedWeapons[toolName] then
                Config.SelectedWeapons[toolName] = nil; btn.BackgroundColor3 = Color3.fromRGB(35, 38, 45)
            else
                Config.SelectedWeapons[toolName] = true; btn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
            end
        end)
    end
    WeaponListContainer.CanvasSize = UDim2.new(0, 0, 0, WeaponListLayout.AbsoluteContentSize.Y)
end)

-- Khởi tạo mặc định Tab đầu tiên
SwitchTab("Overview")

-- [ TOGGLE HIDE / SHOW UI ]
ToggleButton.MouseButton1Click:Connect(function()
    Config.MenuOpen = not Config.MenuOpen
    MainFrame.Visible = Config.MenuOpen
end)

-- =========================================================
-- [ VÒNG LẶP LOGIC CHÍNH: CORE FARMING SYSTEM ]
-- =========================================================
local function GetOffsetCFrame(baseCFrame)
    local dist = Config.Distance
    if Config.FarmPosition == "Trên đầu" then return baseCFrame * CFrame.new(0, dist, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    elseif Config.FarmPosition == "Đằng sau" then return baseCFrame * CFrame.new(0, 0, dist)
    elseif Config.FarmPosition == "Đằng trước" then return baseCFrame * CFrame.new(0, 0, -dist)
    elseif Config.FarmPosition == "Dưới chân" then return baseCFrame * CFrame.new(0, -dist, 0) * CFrame.Angles(math.rad(90), 0, 0)
    end
    return baseCFrame * CFrame.new(0, dist, 0)
end

local function FindMobInWorkspace(name, requireAlive)
    local folders = GetMobFolders()
    for _, folder in ipairs(folders) do
        for _, obj in pairs(folder:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == name then
                if requireAlive and not IsAlive(obj) then continue end
                return obj
            end
        end
    end
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name == name then
            if requireAlive and not IsAlive(obj) then continue end
            return obj
        end
    end
    return nil
end

local function GetMobLevel(mobName)
    local level = mobName:match("%d+")
    return level and tonumber(level) or 1
end

local function GetBestMobTarget()
    local bestTarget = nil
    local highestLevel = -1
    local shortestDist = math.huge
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myPos = hrp and hrp.Position or Vector3.new(0,0,0)

    local folders = GetMobFolders()
    for _, folder in ipairs(folders) do
        for _, obj in pairs(folder:GetDescendants()) do
            if obj:IsA("Model") and IsAlive(obj) and obj ~= LocalPlayer.Character then
                if Config.SelectedMobs[obj.Name] and not string.match(obj.Name:lower(), "boss$") then
                    local level = GetMobLevel(obj.Name)
                    local dist = (obj.HumanoidRootPart.Position - myPos).Magnitude
                    if level > highestLevel then
                        highestLevel = level; shortestDist = dist; bestTarget = obj
                    elseif level == highestLevel then
                        if dist < shortestDist then shortestDist = dist; bestTarget = obj end
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
    local hum = char:FindFirstChild("Humanoid")
    if hum and hum.Health <= 0 then return end 
    
    if Config.MovementMode == "Teleport" then
        if currentTween then currentTween:Cancel(); currentTween = nil; isTweening = false end
        rootPart.CFrame = targetCFrame
    else
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

local function EquipWeaponsFast()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack then return end
    for toolName, _ in pairs(Config.SelectedWeapons) do
        local toolInBp = backpack:FindFirstChild(toolName)
        if toolInBp then toolInBp.Parent = char end
    end
end

SafeConnect(RunService.RenderStepped, function()
    if not LocalPlayer.Character then return end
    if Config.FastAttack or Config.AutoAttack then
        EquipWeaponsFast() 
        local tools = LocalPlayer.Character:GetChildren()
        for i = 1, #tools do
            local tool = tools[i]
            if tool:IsA("Tool") then
                if Config.FastAttack then
                    for j = 1, 3 do tool:Activate() end 
                else tool:Activate() end
            end
        end
    end
end)

local lastSkillTime = tick()
SafeConnect(RunService.Heartbeat, function()
    if tick() - lastSkillTime > 0.5 then
        lastSkillTime = tick()
        if activelyFarming and (Config.AutoFarm or Config.AutoBoss) then
            local keys = {}
            if Config.AutoSkillZ then table.insert(keys, Enum.KeyCode.Z) end
            if Config.AutoSkillX then table.insert(keys, Enum.KeyCode.X) end
            if Config.AutoSkillC then table.insert(keys, Enum.KeyCode.C) end
            if Config.AutoSkillV then table.insert(keys, Enum.KeyCode.V) end
            if Config.AutoSkillB then table.insert(keys, Enum.KeyCode.B) end
            if Config.AutoSkillN then table.insert(keys, Enum.KeyCode.N) end
            if Config.AutoSkillE then table.insert(keys, Enum.KeyCode.E) end
            if Config.AutoSkillF then table.insert(keys, Enum.KeyCode.F) end
            if Config.AutoSkillT then table.insert(keys, Enum.KeyCode.T) end
            if Config.AutoSkillJ then table.insert(keys, Enum.KeyCode.J) end
            
            for _, key in ipairs(keys) do
                VirtualInputManager:SendKeyEvent(true, key, false, game)
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end
        end
    end
end)

SafeConnect(RunService.Heartbeat, function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then activelyFarming = false; return end
    local humanoid = char:FindFirstChild("Humanoid")
    
    if humanoid and humanoid.Health <= 0 then 
        activelyFarming = false
        if isTweening and currentTween then currentTween:Cancel(); currentTween = nil; isTweening = false end
        return 
    end
    
    local activeBosses = {}
    for name, _ in pairs(Config.SelectedBosses) do table.insert(activeBosses, name) end
    local bossToFight = nil

    if (Config.AutoBoss or Config.FarmAllBosses) and #activeBosses > 0 then
        for _, bossName in ipairs(activeBosses) do
            local bInst = FindMobInWorkspace(bossName, true)
            if bInst and IsAlive(bInst) then
                bossToFight = bInst
                Config.CurrentBossIndex = table.find(activeBosses, bossName) or 1
                break
            end
        end
    end

    if bossToFight then
        activelyFarming = true
        if humanoid then humanoid:ChangeState(11) end 
        Config.LastBossCheck = tick()
        local targetPos = GetOffsetCFrame(bossToFight.HumanoidRootPart.CFrame)
        TeleportTo(targetPos)
        return
    end
    
    if Config.AutoEgg then
        local eggs = GetEggs()
        local targetEgg = nil
        for _, egg in ipairs(eggs) do
            if Config.SelectedEggRarity == "Tất cả" or string.match(egg.Name:lower(), Config.SelectedEggRarity:lower()) then
                targetEgg = egg; break
            end
        end
        if targetEgg then
            local part = targetEgg:IsA("Model") and (targetEgg.PrimaryPart or targetEgg:FindFirstChildWhichIsA("BasePart")) or targetEgg
            if part then
                activelyFarming = true
                if humanoid then humanoid:ChangeState(11) end
                TeleportTo(part.CFrame * CFrame.new(0, 3, 0))
                return
            end
        end
    end

    if Config.AutoFarm then
        local targetMob = GetBestMobTarget()
        if targetMob and IsAlive(targetMob) then
            activelyFarming = true
            if humanoid then humanoid:ChangeState(11) end
            local targetPos = GetOffsetCFrame(targetMob.HumanoidRootPart.CFrame)
            TeleportTo(targetPos)
            return
        else
            local roamingTargetPos = nil
            for selectedMob, _ in pairs(Config.SelectedMobs) do
                if Config.MobDataCache[selectedMob] then
                    roamingTargetPos = Config.MobDataCache[selectedMob]; break
                end
            end
            if roamingTargetPos then
                activelyFarming = true
                if humanoid then humanoid:ChangeState(11) end
                local waitCFrame = GetOffsetCFrame(CFrame.new(roamingTargetPos))
                TeleportTo(waitCFrame)
                return
            end
        end
    end

    if (Config.AutoBoss or Config.FarmAllBosses) and #activeBosses > 0 then
        activelyFarming = true
        if humanoid then humanoid:ChangeState(11) end
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
    
    activelyFarming = false
end)

-- [ PLAYER TAB MODS ]
local flyBv, flyBg
local waterPlatform = Instance.new("Part")
waterPlatform.Size = Vector3.new(8, 1, 8); waterPlatform.Transparency = 1; waterPlatform.Anchored = true; waterPlatform.CanCollide = true
waterPlatform.Name = "AutoWaterPlatform"

SafeConnect(RunService.Stepped, function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if hum and hum.Health > 0 then
        if Config.WalkSpeedEnabled then hum.WalkSpeed = Config.WalkSpeed end
        if Config.JumpPowerEnabled then hum.JumpPower = Config.JumpPower end
        
        if Config.Fly and hrp and not activelyFarming then
            if not flyBv or not flyBv.Parent then
                flyBv = Instance.new("BodyVelocity"); flyBv.MaxForce = Vector3.new(9e9, 9e9, 9e9); flyBv.Parent = hrp
                flyBg = Instance.new("BodyGyro"); flyBg.P = 9e4; flyBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); flyBg.Parent = hrp
            end
            hum.PlatformStand = true
            local moveDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            flyBv.Velocity = moveDir * Config.FlySpeed
            flyBg.CFrame = CFrame.new(hrp.Position, hrp.Position + Camera.CFrame.LookVector)
        else
            if flyBv then flyBv:Destroy(); flyBv = nil end
            if flyBg then flyBg:Destroy(); flyBg = nil end
            if hum.PlatformStand and not activelyFarming then hum.PlatformStand = false end
        end
        
        if Config.Noclip and not activelyFarming then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end
        
        if Config.WalkOnWater and hrp then
            hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
            local ray = Ray.new(hrp.Position, Vector3.new(0, -6, 0))
            local hit, pos, norm, mat = workspace:FindPartOnRay(ray, char)
            if mat == Enum.Material.Water then
                waterPlatform.Position = Vector3.new(hrp.Position.X, pos.Y - 0.5, hrp.Position.Z); waterPlatform.Parent = workspace
            else waterPlatform.Parent = nil end
        else
            waterPlatform.Parent = nil
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) end
        end
    end
end)

SafeConnect(UserInputService.JumpRequest, function()
    if Config.InfJump then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local lastFishingCast = tick()
SafeConnect(RunService.Heartbeat, function()
    if Config.AutoFishing then
        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not char then return end
        
        local rod = nil
        for _, tool in ipairs(char:GetChildren()) do if tool:IsA("Tool") and tool.Name:lower():match("rod$") then rod = tool; break end end
        if not rod and bp then
            for _, tool in ipairs(bp:GetChildren()) do if tool:IsA("Tool") and tool.Name:lower():match("rod$") then rod = tool; break end end
        end
        
        if rod then
            if rod.Parent ~= char then
                for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then t.Parent = bp end end
                rod.Parent = char
            end
            
            local isCast = false
            local tip = rod:FindFirstChild("Tip")
            if tip then
                local att = tip:FindFirstChild("TipAttachment") or tip:FindFirstChildWhichIsA("Attachment")
                if att then
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if (obj:IsA("Constraint") or obj:IsA("Beam") or obj:IsA("RopeConstraint")) and (obj.Attachment0 == att or obj.Attachment1 == att) then
                            isCast = true; break
                        end
                    end
                end
            end
            
            if not isCast then
                if tick() - lastFishingCast > 3 then
                    lastFishingCast = tick()
                    rod:Activate()
                    pcall(function()
                        local center = Camera.ViewportSize / 2
                        VirtualInputManager:SendMouseButtonEvent(center.X, center.Y + 50, 0, true, game, 0)
                        task.wait(0.05)
                        VirtualInputManager:SendMouseButtonEvent(center.X, center.Y + 50, 0, false, game, 0)
                    end)
                end
            end
        end
    end
end)

SafeConnect(LocalPlayer.Idled, function()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end)

print("YuiHuB Premium Auto Farm - Successfully Loaded! (All Features Active)")
