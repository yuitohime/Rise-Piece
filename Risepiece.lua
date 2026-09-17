-- =====================================================================
-- SUPERIOR AUTO FARM SCRIPT (RISE PIECE / GENERIC) - [V4]
-- Tối ưu hóa hiệu năng, Chống Memory Leak triệt để.
-- [V4 UPDATE]: Thêm Tab Player (Fly, Noclip, WalkSpeed, Inf Jump, Walk On Water)
-- Thêm Fast Attack siêu tốc, Trang bị nhiều vũ khí, Fix lỗi kéo UI.
-- UI Dropdown (Thu gọn danh sách), Fix lỗi kẹt máu khi Reset Character.
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
    AutoAttack = false,
    FastAttack = false,
    AutoSkillZ = false,
    AutoSkillX = false,
    AutoSkillC = false,
    AutoSkillV = false,
    AutoSkillE = false,
    MovementMode = "Teleport", 
    FarmPosition = "Trên đầu",
    Distance = 5,
    TweenDuration = 0.5,
    BossWaitTime = 0.5, 
    SelectedWeapons = {}, -- V4: Hỗ trợ chọn nhiều vũ khí
    SelectedMobs = {}, 
    SelectedBosses = {},
    MobListCache = {}, 
    BossDataCache = {}, 
    MobDataCache = {},
    MenuOpen = false,
    CurrentBossIndex = 1,
    LastBossCheck = tick(),
    -- V4 Player Configs
    WalkSpeedEnabled = false,
    WalkSpeed = 50,
    JumpPowerEnabled = false,
    JumpPower = 100,
    InfJump = false,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,
    WalkOnWater = false
}

local isTweening = false
local currentTween = nil
local activelyFarming = false -- Biến kiểm soát trạng thái có đang đánh quái không

-- [ HỆ THỐNG GẮN UI SIÊU AN TOÀN ]
local UI_NAME = "RisePiece_PremiumUI_V4"
local targetParent = nil
pcall(function()
    if get_hidden_gui or gethui then
        local hiddenUI = get_hidden_gui or gethui
        targetParent = hiddenUI()
    elseif game:GetService("CoreGui") then
        targetParent = game:GetService("CoreGui")
    end
end)

if not targetParent then
    targetParent = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
end

if not targetParent then 
    warn("[V4] LỖI: Không thể tải UI, vui lòng đợi game load xong rồi chạy lại!")
    return
end

if targetParent:FindFirstChild(UI_NAME) then
    targetParent:FindFirstChild(UI_NAME):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = UI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = targetParent

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
MainFrame.Active = true
MainFrame.Draggable = true -- Hỗ trợ kéo thả mượt mà của Roblox
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

-- Tiêu đề Menu (Hiển thị V4)
local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size = UDim2.new(1, 0, 0, 30)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text = "TIỆN ÍCH [V4]"
MenuTitle.TextColor3 = Color3.fromRGB(0, 255, 128)
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextSize = 15
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
local PlayerTab = CreateTabButton("Player") -- V4 Tab
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

-- Tối ưu hóa UI: V4 Khung Dropdown thu gọn
local function CreateDropdown(parent, titleText)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 35)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    container.ClipsDescendants = true
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 0, 35)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = "▼ " .. titleText
    toggleBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 14
    toggleBtn.Parent = container
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 0, 150)
    scrollFrame.Position = UDim2.new(0, 0, 0, 35)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.Visible = false
    scrollFrame.Parent = container
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame
    
    local isOpen = false
    toggleBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        scrollFrame.Visible = isOpen
        toggleBtn.Text = (isOpen and "▲ " or "▼ ") .. titleText
        if isOpen then
            container.Size = UDim2.new(1, 0, 0, 185)
        else
            container.Size = UDim2.new(1, 0, 0, 35)
        end
    end)
    
    return scrollFrame, layout
end

-- [ TỐI ƯU HÓA: HỆ THỐNG LẤY THƯ MỤC QUÁI ]
local function GetMobFolders()
    local folders = {}
    local mapa = Workspace:FindFirstChild("Mapa")
    if mapa and mapa:FindFirstChild("Enemies") then
        table.insert(folders, mapa.Enemies)
    end
    local monsters = Workspace:FindFirstChild("Monsters")
    if monsters then
        table.insert(folders, monsters)
    end
    
    if #folders == 0 then
        table.insert(folders, Workspace)
    end
    return folders
end

-- [ LOGIC NHẬN DIỆN MỤC TIÊU ]
local function IsAlive(mob)
    return mob and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart")
end

local function GetMobLevel(mobName)
    local level = mobName:match("%d+")
    return level and tonumber(level) or 1
end

-- Hàm Quét Chung
local function ScanObj(obj)
    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj ~= LocalPlayer.Character then
        local lowerName = obj.Name:lower()
        if string.match(lowerName, "^spawnner") or string.match(lowerName, "^spawner") then return end
        
        if string.match(lowerName, "boss$") then
            Config.BossDataCache[obj.Name] = obj.HumanoidRootPart.Position
        else
            Config.MobListCache[obj.Name] = true
            Config.MobDataCache[obj.Name] = obj.HumanoidRootPart.Position
        end
    end
end

-- [ XÂY DỰNG TAB: MAIN & BOSS (Sử dụng Dropdown) ]
local MobListContainer, MobListLayout = CreateDropdown(MainTab, "Danh sách Quái Bản Đồ")
local BossListContainer, BossListLayout = CreateDropdown(BossTab, "Danh sách Boss Bản Đồ")

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

local function ScanAllMap()
    local folders = GetMobFolders()
    if #folders > 0 and folders[1] ~= Workspace then
        for _, folder in ipairs(folders) do
            for _, obj in pairs(folder:GetDescendants()) do ScanObj(obj) end
        end
    else
        local allDescendants = Workspace:GetDescendants()
        for i, obj in pairs(allDescendants) do 
            ScanObj(obj) 
            if i % 1000 == 0 then task.wait() end 
        end
    end
    for name, _ in pairs(Config.SelectedMobs) do Config.MobListCache[name] = true end
    for name, _ in pairs(Config.SelectedBosses) do 
        if Config.BossDataCache[name] then Config.SelectedBosses[name] = true end
    end
    UpdateMobUIList(); UpdateBossUIList()
end

CreateButton(MainTab, "Quét Quái Bản Đồ", function()
    ScanAllMap()
end)

CreateToggle(MainTab, "Bật/Tắt Auto Farm Quái", "AutoFarm")
CreateToggle(MainTab, "Auto Skill [Z]", "AutoSkillZ")
CreateToggle(MainTab, "Auto Skill [X]", "AutoSkillX")
CreateToggle(MainTab, "Auto Skill [C]", "AutoSkillC")
CreateToggle(MainTab, "Auto Skill [V]", "AutoSkillV")
CreateToggle(MainTab, "Auto Skill [E]", "AutoSkillE")

CreateButton(BossTab, "Quét Boss Bản Đồ", function() ScanAllMap() end)
CreateToggle(BossTab, "Bật/Tắt Auto Boss", "AutoBoss")
CreateToggle(BossTab, "Farm Tất Cả Boss (Lùng Sục)", "FarmAllBosses")
CreateSlider(BossTab, "Thời gian chờ Boss (s)", 0.1, 60, 0.5, "BossWaitTime", true)

-- [ XÂY DỰNG TAB: PLAYER (V4 TÍNH NĂNG MỚI) ]
CreateToggle(PlayerTab, "Bật WalkSpeed", "WalkSpeedEnabled")
CreateSlider(PlayerTab, "Tốc độ chạy", 16, 300, 50, "WalkSpeed", false)
CreateToggle(PlayerTab, "Bật JumpPower", "JumpPowerEnabled")
CreateSlider(PlayerTab, "Độ cao nhảy", 50, 500, 100, "JumpPower", false)
CreateToggle(PlayerTab, "Nhảy vô hạn (Inf Jump)", "InfJump")
CreateToggle(PlayerTab, "Đi xuyên tường (Noclip)", "Noclip")
CreateToggle(PlayerTab, "Đi trên mặt nước", "WalkOnWater")
CreateToggle(PlayerTab, "Bay tự do (Fly)", "Fly")
CreateSlider(PlayerTab, "Tốc độ Bay", 16, 500, 50, "FlySpeed", false)

-- [ XÂY DỰNG TAB: SETTING ]
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
CreateToggle(SettingTab, "Bật Auto Attack Thường", "AutoAttack")
CreateToggle(SettingTab, "Bật FAST ATTACK (Siêu nhanh)", "FastAttack")

CreateButton(SettingTab, "Quét Vũ Khí (Chọn nhiều cái)", function() UpdateWeaponList() end)

-- Danh sách vũ khí đổi thành Dropdown để gọn
local WeaponListContainer, WeaponListLayout = CreateDropdown(SettingTab, "Danh Sách Vũ Khí")

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
        -- V4: Hiển thị xanh nếu nằm trong SelectedWeapons
        btn.BackgroundColor3 = Config.SelectedWeapons[toolName] and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(40, 40, 45)
        btn.Text = " " .. toolName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = WeaponListContainer
        
        btn.MouseButton1Click:Connect(function()
            if Config.SelectedWeapons[toolName] then
                Config.SelectedWeapons[toolName] = nil
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            else
                Config.SelectedWeapons[toolName] = true
                btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
            end
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
    local folders = GetMobFolders()
    for _, folder in ipairs(folders) do
        for _, obj in pairs(folder:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == name then
                if requireAlive and not IsAlive(obj) then continue end
                return obj
            end
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

    local folders = GetMobFolders()
    for _, folder in ipairs(folders) do
        for _, obj in pairs(folder:GetDescendants()) do
            if obj:IsA("Model") and IsAlive(obj) and obj ~= LocalPlayer.Character then
                if Config.SelectedMobs[obj.Name] and not string.match(obj.Name:lower(), "boss$") then
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
    end
    return bestTarget
end

local function TeleportTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = char.HumanoidRootPart
    local hum = char:FindFirstChild("Humanoid")
    if hum and hum.Health <= 0 then return end -- V4 Fix kẹt xác
    
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

-- V4: Hỗ trợ cầm CÙNG LÚC nhiều vũ khí
local function EquipWeapons()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack then return end
    
    -- Cất vũ khí không được chọn
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and not Config.SelectedWeapons[tool.Name] then
            tool.Parent = backpack
        end
    end
    
    -- Lấy tất cả vũ khí được chọn đưa vào Character (Cầm nhiều vũ khí)
    for toolName, _ in pairs(Config.SelectedWeapons) do
        local tool = backpack:FindFirstChild(toolName)
        if tool then
            tool.Parent = char
        end
    end
end

-- V4: Fast Attack siêu tốc, Không đụng UI
SafeConnect(RunService.RenderStepped, function()
    if not LocalPlayer.Character then return end
    
    if Config.FastAttack or Config.AutoAttack then
        EquipWeapons()
        
        -- Chỉ ép click chuột ảo khi đang thực sự đánh mục tiêu (Tránh kẹt menu)
        if activelyFarming then
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
        end
        
        -- Dùng Activate thẳng vào Tool để tăng tốc độ chém
        for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                if Config.FastAttack then
                    -- Ép activate 5 lần 1 frame không cooldown
                    for i = 1, 5 do tool:Activate() end
                else
                    tool:Activate()
                end
            end
        end
    end
end)

-- Vòng lặp bắn SKILL an toàn
local lastSkillTime = tick()
SafeConnect(RunService.Heartbeat, function()
    if tick() - lastSkillTime > 0.5 then
        lastSkillTime = tick()
        if activelyFarming and (Config.AutoFarm or Config.AutoBoss) then
            if Config.AutoSkillZ then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Z, false, game); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Z, false, game) end
            if Config.AutoSkillX then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.X, false, game); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.X, false, game) end
            if Config.AutoSkillC then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game) end
            if Config.AutoSkillV then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.V, false, game); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.V, false, game) end
            if Config.AutoSkillE then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game) end
        end
    end
end)

-- [ VÒNG LẶP DI CHUYỂN AUTO FARM & XỬ LÝ FIX LỖI DEAD CỦA V4 ]
SafeConnect(RunService.Heartbeat, function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then activelyFarming = false; return end
    local humanoid = char:FindFirstChild("Humanoid")
    
    -- V4 FIX: Nếu máu <= 0, Dừng mọi hoạt động Farm để game xử lý hồi sinh
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
        if humanoid then humanoid:ChangeState(11) end -- Chỉ Noclip 11 khi đang áp sát mục tiêu
        Config.LastBossCheck = tick()
        local targetPos = GetOffsetCFrame(bossToFight.HumanoidRootPart.CFrame)
        TeleportTo(targetPos)
        return
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
            -- Lùng sục tọa độ quái thường
            local roamingTargetPos = nil
            for selectedMob, _ in pairs(Config.SelectedMobs) do
                if Config.MobDataCache[selectedMob] then
                    roamingTargetPos = Config.MobDataCache[selectedMob]
                    break
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
    
    activelyFarming = false -- Nếu không farm gì, trả trạng thái về false để Player tự điều khiển
end)

-- [ PLAYER TAB FEATURES (V4) ]
local flyBv, flyBg
local waterPlatform = Instance.new("Part")
waterPlatform.Size = Vector3.new(8, 1, 8)
waterPlatform.Transparency = 1
waterPlatform.Anchored = true
waterPlatform.CanCollide = true
waterPlatform.Name = "AutoWaterPlatform"

SafeConnect(RunService.Stepped, function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if hum and hum.Health > 0 then
        -- WalkSpeed & JumpPower
        if Config.WalkSpeedEnabled then hum.WalkSpeed = Config.WalkSpeed end
        if Config.JumpPowerEnabled then hum.JumpPower = Config.JumpPower end
        
        -- Fly
        if Config.Fly and hrp and not activelyFarming then
            if not flyBv or not flyBv.Parent then
                flyBv = Instance.new("BodyVelocity")
                flyBv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                flyBv.Parent = hrp
                flyBg = Instance.new("BodyGyro")
                flyBg.P = 9e4
                flyBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                flyBg.Parent = hrp
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
        
        -- Noclip
        if Config.Noclip and not activelyFarming then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
        
        -- Walk On Water (Tạo sàn tàng hình dưới chân nếu gặp nước)
        if Config.WalkOnWater and hrp then
            hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
            local ray = Ray.new(hrp.Position, Vector3.new(0, -6, 0))
            local hit, pos, norm, mat = workspace:FindPartOnRay(ray, char)
            if mat == Enum.Material.Water then
                waterPlatform.Position = Vector3.new(hrp.Position.X, pos.Y - 0.5, hrp.Position.Z)
                waterPlatform.Parent = workspace
            else
                waterPlatform.Parent = nil
            end
        else
            waterPlatform.Parent = nil
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) end
        end
    end
end)

-- Inf Jump
SafeConnect(UserInputService.JumpRequest, function()
    if Config.InfJump then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Tạo Anti-AFK để không bị văng game
SafeConnect(LocalPlayer.Idled, function()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end)

print("Rise Piece Superior Auto Farm V4 Loaded successfully! (Added Player Tab, Fly, Noclip, FastAttack, Multiple Weapons, Bug Fixes)")
