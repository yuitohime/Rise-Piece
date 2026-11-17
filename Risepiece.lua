-- =====================================================================
-- SUPERIOR AUTO FARM SCRIPT (YUIHUB / MARU STYLE) - [ULTIMATE V13]
-- BẢN CHUẨN 100% FULL SOURCE - KHÔNG GỘP DÒNG - KHÔNG CẮT XÉN.
-- 1. Khôi phục hàm Quét Quái & Boss cực chuẩn từ V7 (Không dính NPC).
-- 2. Đã sửa "Kiểu Đánh" thành quét Tool/Melee trong Balo + Auto Đổi Vũ Khí.
-- 3. Giao diện Mobile (600x380), có nút Ghim (📌) và Thu nhỏ (-).
-- 4. Auto Skill mượt mà, ESP Trái Ác Quỷ, Teleport Đảo đầy đủ.
-- =====================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Đợi LocalPlayer load xong để tránh đơ
while not Players.LocalPlayer do
    task.wait()
end

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
        if conn.Connected then
            conn:Disconnect()
        end
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
    FruitESP = false,
    AutoAttack = false,
    FastAttack = false,
    AutoFishing = false, 
    
    AutoSkillZ = false,
    AutoSkillX = false,
    AutoSkillC = false,
    AutoSkillV = false,
    AutoSkillB = false,
    AutoSkillN = false,
    AutoSkillE = false,
    AutoSkillF = false,
    AutoSkillT = false,
    AutoSkillJ = false,
    
    MovementMode = "Teleport", 
    FarmPosition = "Trên đầu",
    Distance = 5,
    TweenDuration = 0.5,
    BossWaitTime = 0.5, 
    
    -- Tính năng Đổi Kiểu Đánh (Vũ Khí)
    AutoSwapWeapons = false,
    SwapInterval = 5,
    
    SelectedWeapons = {}, 
    SelectedMobs = {}, 
    SelectedBosses = {},
    
    MobListCache = {}, 
    BossDataCache = {}, 
    MobDataCache = {},
    
    MenuOpen = true,
    CurrentBossIndex = 1,
    LastBossCheck = tick(),
    
    WalkSpeedEnabled = false,
    WalkSpeed = 50,
    JumpPowerEnabled = false,
    JumpPower = 100,
    InfJump = false,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,
    WalkOnWater = false,
    
    SavedPos1 = nil,
    SavedPos2 = nil,
    SavedPos3 = nil
}

local isTweening = false
local currentTween = nil
local activelyFarming = false 

-- =====================================================================
-- [ UI LIBRARY: YUIHUB MOBILE OPTIMIZED (MARU STYLE) ]
-- =====================================================================
local UI_NAME = "YuiHuB_Mobile_V13_FullSource"
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

if targetParent:FindFirstChild(UI_NAME) then
    targetParent:FindFirstChild(UI_NAME):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = UI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = targetParent

-- Nút Mở/Đóng (Toggle Logo)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Position = UDim2.new(0, 10, 0.5, -22)
ToggleButton.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
ToggleButton.BackgroundTransparency = 0.2
ToggleButton.Text = "YUI"
ToggleButton.TextColor3 = Color3.fromRGB(100, 170, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 14
ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(50, 55, 70)
ToggleStroke.Parent = ToggleButton

-- Khung Menu Chính (Mobile Size 600x380)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 600, 0, 380)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 15, 20)
MainFrame.BackgroundTransparency = 0.12
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 50, 65)
MainStroke.Parent = MainFrame

-- Cột chức năng bên trái (Sidebar)
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 150, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
Sidebar.BackgroundTransparency = 0.5
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarDivider = Instance.new("Frame")
SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
SidebarDivider.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
SidebarDivider.BorderSizePixel = 0
SidebarDivider.Parent = Sidebar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 50)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "  YuiHuB"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Sidebar

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Size = UDim2.new(1, 0, 1, -50)
SidebarScroll.Position = UDim2.new(0, 0, 0, 50)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.ScrollBarThickness = 2
SidebarScroll.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 4)
SidebarLayout.Parent = SidebarScroll

-- Khu vực nội dung bên phải (Content Area)
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -150, 1, 0)
ContentArea.Position = UDim2.new(0, 150, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local Topbar = Instance.new("Frame")
Topbar.Size = UDim2.new(1, 0, 0, 40)
Topbar.BackgroundTransparency = 1
Topbar.Parent = ContentArea

local TopbarDivider = Instance.new("Frame")
TopbarDivider.Size = UDim2.new(1, 0, 0, 1)
TopbarDivider.Position = UDim2.new(0, 0, 1, -1)
TopbarDivider.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
TopbarDivider.BorderSizePixel = 0
TopbarDivider.Parent = Topbar

local CurrentTabTitle = Instance.new("TextLabel")
CurrentTabTitle.Size = UDim2.new(1, -100, 1, 0)
CurrentTabTitle.Position = UDim2.new(0, 15, 0, 0)
CurrentTabTitle.BackgroundTransparency = 1
CurrentTabTitle.Text = "Overview"
CurrentTabTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
CurrentTabTitle.Font = Enum.Font.GothamBold
CurrentTabTitle.TextSize = 16
CurrentTabTitle.TextXAlignment = Enum.TextXAlignment.Left
CurrentTabTitle.Parent = Topbar

-- NÚT ĐÓNG (X)
local CloseMenuBtn = Instance.new("TextButton")
CloseMenuBtn.Size = UDim2.new(0, 25, 0, 25)
CloseMenuBtn.Position = UDim2.new(1, -30, 0, 7)
CloseMenuBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseMenuBtn.Text = "X"
CloseMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseMenuBtn.Font = Enum.Font.GothamBold
CloseMenuBtn.Parent = Topbar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseMenuBtn

CloseMenuBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    DisconnectAll()
end)

-- NÚT THU NHỎ (-)
local isMinimized = false
local MinMenuBtn = Instance.new("TextButton")
MinMenuBtn.Size = UDim2.new(0, 25, 0, 25)
MinMenuBtn.Position = UDim2.new(1, -60, 0, 7)
MinMenuBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
MinMenuBtn.Text = "-"
MinMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinMenuBtn.Font = Enum.Font.GothamBold
MinMenuBtn.Parent = Topbar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 4)
MinCorner.Parent = MinMenuBtn

MinMenuBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 600, 0, 40)
        Sidebar.Visible = false
        for _, child in pairs(ContentArea:GetChildren()) do
            if child ~= Topbar then
                child.Visible = false
            end
        end
    else
        MainFrame.Size = UDim2.new(0, 600, 0, 380)
        Sidebar.Visible = true
        for _, child in pairs(ContentArea:GetChildren()) do
            if child ~= Topbar then
                child.Visible = true
            end
        end
    end
end)

-- NÚT GHIM (📌)
local isPinned = false
local PinMenuBtn = Instance.new("TextButton")
PinMenuBtn.Size = UDim2.new(0, 25, 0, 25)
PinMenuBtn.Position = UDim2.new(1, -90, 0, 7)
PinMenuBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
PinMenuBtn.Text = "📌"
PinMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PinMenuBtn.Font = Enum.Font.GothamBold
PinMenuBtn.Parent = Topbar

local PinCorner = Instance.new("UICorner")
PinCorner.CornerRadius = UDim.new(0, 4)
PinCorner.Parent = PinMenuBtn

PinMenuBtn.MouseButton1Click:Connect(function()
    isPinned = not isPinned
    MainFrame.Draggable = not isPinned
    if isPinned then
        PinMenuBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
    else
        PinMenuBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
    end
end)

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, 0, 1, -40)
ContentContainer.Position = UDim2.new(0, 0, 0, 40)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = ContentArea

-- Hệ thống Tab
local Tabs = {}
local TabContents = {}

local function CreateCategory(name)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -15, 0, 20)
    lbl.Position = UDim2.new(0, 15, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text = name:upper()
    lbl.TextColor3 = Color3.fromRGB(110, 115, 130)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = SidebarScroll
end

local function SwitchTab(tabName)
    CurrentTabTitle.Text = tabName
    for name, content in pairs(TabContents) do
        if name == tabName then
            content.Visible = true
        else
            content.Visible = false
        end
    end
    for name, btn in pairs(Tabs) do
        if name == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
            btn.TextColor3 = Color3.fromRGB(150, 155, 170)
        end
    end
end

local function CreateTabButton(name)
    local btnFrame = Instance.new("Frame")
    btnFrame.Size = UDim2.new(1, 0, 0, 28)
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = SidebarScroll
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 1, 0)
    btn.Position = UDim2.new(0, 10, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(150, 155, 170)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = btnFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn
    
    local scrollContent = Instance.new("ScrollingFrame")
    scrollContent.Size = UDim2.new(1, 0, 1, 0)
    scrollContent.BackgroundTransparency = 1
    scrollContent.ScrollBarThickness = 2
    scrollContent.Visible = false
    scrollContent.Parent = ContentContainer
    
    -- Bố cục 2 Cột
    local LeftCol = Instance.new("Frame")
    LeftCol.Size = UDim2.new(0.5, -15, 1, 0)
    LeftCol.Position = UDim2.new(0, 10, 0, 10)
    LeftCol.BackgroundTransparency = 1
    LeftCol.Parent = scrollContent
    
    local LeftLayout = Instance.new("UIListLayout")
    LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LeftLayout.Padding = UDim.new(0, 8)
    LeftLayout.Parent = LeftCol
    
    local RightCol = Instance.new("Frame")
    RightCol.Size = UDim2.new(0.5, -15, 1, 0)
    RightCol.Position = UDim2.new(0.5, 5, 0, 10)
    RightCol.BackgroundTransparency = 1
    RightCol.Parent = scrollContent
    
    local RightLayout = Instance.new("UIListLayout")
    RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    RightLayout.Padding = UDim.new(0, 8)
    RightLayout.Parent = RightCol
    
    Tabs[name] = btn
    TabContents[name] = scrollContent
    
    btn.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)
    
    local function UpdateCanvas()
        local maxVal = math.max(LeftLayout.AbsoluteContentSize.Y, RightLayout.AbsoluteContentSize.Y)
        scrollContent.CanvasSize = UDim2.new(0, 0, 0, maxVal + 30)
    end
    
    LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    
    return LeftCol, RightCol
end

-- =====================================================================
-- [ UI COMPONENTS ĐẦY ĐỦ ]
-- =====================================================================
local function CreateCard(parent, title)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 30)
    card.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
    card.BackgroundTransparency = 0.3
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = card
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(45, 50, 65)
    cardStroke.Parent = card
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -16, 0, 28)
    titleLbl.Position = UDim2.new(0, 8, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card
    
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 0, 28)
    divider.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
    divider.BorderSizePixel = 0
    divider.Parent = card
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -29)
    contentFrame.Position = UDim2.new(0, 0, 0, 29)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = card
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 2)
    contentLayout.Parent = contentFrame
    
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        card.Size = UDim2.new(1, 0, 0, contentLayout.AbsoluteContentSize.Y + 33)
    end)
    
    return contentFrame
end

local function CreateToggle(parent, text, configKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -45, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local switchBg = Instance.new("TextButton")
    switchBg.Size = UDim2.new(0, 32, 0, 16)
    switchBg.Position = UDim2.new(1, -40, 0.5, -8)
    switchBg.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
    switchBg.Text = ""
    switchBg.Parent = frame
    
    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBg
    
    local switchStroke = Instance.new("UIStroke")
    switchStroke.Color = Color3.fromRGB(55, 60, 75)
    switchStroke.Parent = switchBg
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 12, 0, 12)
    circle.Position = UDim2.new(0, 2, 0.5, -6)
    circle.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
    circle.Parent = switchBg
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle
    
    local function UpdateUI()
        local toggled = Config[configKey]
        local goalPos = UDim2.new(0, 2, 0.5, -6)
        local goalCol = Color3.fromRGB(150, 150, 160)
        local bgCol = Color3.fromRGB(35, 40, 50)
        
        if toggled then
            goalPos = UDim2.new(1, -14, 0.5, -6)
            goalCol = Color3.fromRGB(255, 255, 255)
            bgCol = Color3.fromRGB(60, 130, 220)
        end
        
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
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 26)
    btn.Position = UDim2.new(0, 8, 0.5, -13)
    btn.BackgroundColor3 = Color3.fromRGB(45, 90, 180)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    
    return btn
end

local function CreateSlider(parent, text, min, max, default, configKey, isDecimal)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 15)
    label.Position = UDim2.new(0, 8, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local sliderBg = Instance.new("TextButton")
    sliderBg.Size = UDim2.new(1, -16, 0, 6)
    sliderBg.Position = UDim2.new(0, 8, 0, 24)
    sliderBg.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
    sliderBg.Text = ""
    sliderBg.Parent = frame
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(60, 130, 220)
    sliderFill.Parent = sliderBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill
    
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

local function CreateDropdown(parent, titleText)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 32)
    container.BackgroundColor3 = Color3.fromRGB(30, 34, 45)
    container.BackgroundTransparency = 0.2
    container.ClipsDescendants = true
    container.Parent = parent
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 4)
    containerCorner.Parent = container
    
    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = Color3.fromRGB(45, 50, 65)
    containerStroke.Parent = container
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 0, 32)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = "  " .. titleText .. "  ▼"
    toggleBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 10
    toggleBtn.TextXAlignment = Enum.TextXAlignment.Left
    toggleBtn.Parent = container
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -6, 1, -36)
    scrollFrame.Position = UDim2.new(0, 3, 0, 32)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 2
    scrollFrame.Visible = false
    scrollFrame.Parent = container
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scrollFrame
    
    local isOpen = false
    toggleBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        scrollFrame.Visible = isOpen
        
        if isOpen then
            toggleBtn.Text = "  " .. titleText .. "  ▲"
            container.Size = UDim2.new(1, 0, 0, 180)
        else
            toggleBtn.Text = "  " .. titleText .. "  ▼"
            container.Size = UDim2.new(1, 0, 0, 32)
        end
    end)
    
    return scrollFrame, layout, container
end

-- =====================================================================
-- [ KHÔI PHỤC HÀM TÌM KIẾM QUÁI & BOSS TỪ BẢN V7 ]
-- =====================================================================
local function TeleportToPos(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

local function GetMobFolders()
    local folders = {}
    local mapa = Workspace:FindFirstChild("Mapa") or Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("map")
    if mapa and mapa:FindFirstChild("Enemies") then
        table.insert(folders, mapa.Enemies)
    end
    
    local monsters = Workspace:FindFirstChild("Monsters") or Workspace:FindFirstChild("monsters")
    if monsters then
        table.insert(folders, monsters)
    end
    
    if #folders == 0 then
        table.insert(folders, Workspace)
    end
    return folders
end

local function IsAlive(mob)
    if mob and mob:FindFirstChild("Humanoid") then
        if mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
            return true
        end
    end
    return false
end

-- ĐÂY LÀ HÀM SCAN CỦA BẢN GỐC V7 MÀ BẠN MUỐN (CHUẨN 100%)
local function ScanObj(obj)
    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj ~= LocalPlayer.Character then
        local lowerName = obj.Name:lower()
        if string.match(lowerName, "^spawnner") or string.match(lowerName, "^spawner") then return end
        
        local isDirectWorkspace = (obj.Parent == Workspace)
        
        if string.match(lowerName, "boss$") or (isDirectWorkspace and string.match(lowerName, "lv%.%s*%d+")) then
            Config.BossDataCache[obj.Name] = obj.HumanoidRootPart.Position
        else
            Config.MobListCache[obj.Name] = true
            Config.MobDataCache[obj.Name] = obj.HumanoidRootPart.Position
        end
    end
end

-- =====================================================================
-- [ KHỞI TẠO TABS VÀ CÁC THẺ CARD ]
-- =====================================================================
CreateCategory("Workspace")
local OverviewLeft, OverviewRight = CreateTabButton("Overview")
local FarmLeft, FarmRight = CreateTabButton("Farming")

-- CHUYỂN SETTINGS XUỐNG DƯỚI FARMING
local SettingsLeft, SettingsRight = CreateTabButton("Settings")

CreateCategory("Combat")
local BossLeft, BossRight = CreateTabButton("Bosses")

CreateCategory("World")
local TravelLeft, TravelRight = CreateTabButton("Islands & NPCs")
local ItemLeft, ItemRight = CreateTabButton("Eggs & Fruits")

CreateCategory("Activities")
local PlayerLeft, PlayerRight = CreateTabButton("Player Mods")


-- =========================================================
-- [ TAB: OVERVIEW ]
-- =========================================================
local InfoCard = CreateCard(OverviewLeft, "Thông Tin YuiHuB")

local InfoLbl = Instance.new("TextLabel")
InfoLbl.Size = UDim2.new(1, -16, 0, 80)
InfoLbl.Position = UDim2.new(0, 8, 0, 0)
InfoLbl.BackgroundTransparency = 1
InfoLbl.Text = "- KHÔI PHỤC HÀM QUÉT V7 (KHÔNG LỖI).\n- Auto Đổi Kiểu Đánh (Vũ Khí) + Cất Vũ Khí chuẩn.\n- Auto Skill Cực Mượt (Hold Key).\n- Ghim (📌) và Thu Nhỏ (-) Menu."
InfoLbl.TextColor3 = Color3.fromRGB(180, 180, 190)
InfoLbl.Font = Enum.Font.Gotham
InfoLbl.TextSize = 10
InfoLbl.TextWrapped = true
InfoLbl.TextXAlignment = Enum.TextXAlignment.Left
InfoLbl.Parent = InfoCard

-- =========================================================
-- [ TAB: FARMING (QUÁI & KỸ NĂNG) ]
-- =========================================================
local FarmCard = CreateCard(FarmLeft, "Cài Đặt Đánh Quái")
CreateToggle(FarmCard, "Bật Auto Farm", "AutoFarm")

CreateButton(FarmCard, "Quét Làm Mới Bản Đồ", function()
    table.clear(Config.MobListCache)
    table.clear(Config.MobDataCache)
    table.clear(Config.BossDataCache)
    
    local folders = GetMobFolders()
    if #folders > 0 and folders[1] ~= Workspace then
        for _, folder in ipairs(folders) do
            for _, obj in pairs(folder:GetDescendants()) do
                ScanObj(obj)
            end
        end
    else
        local allDescendants = Workspace:GetDescendants()
        for i, obj in pairs(allDescendants) do 
            ScanObj(obj) 
            if i % 1000 == 0 then task.wait() end 
        end
    end
    for _, obj in pairs(Workspace:GetChildren()) do ScanObj(obj) end
    
    UpdateMobUIList()
    UpdateBossUIList()
end)

local MobListContainer, MobListLayout, MobWrap = CreateDropdown(FarmCard, "Chọn Quái Vật")

function UpdateMobUIList()
    for _, child in pairs(MobListContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    for mobName, _ in pairs(Config.MobListCache) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 22)
        
        if Config.SelectedMobs[mobName] then
            btn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
        else
            btn.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
        end
        
        btn.Text = "  " .. mobName
        btn.TextColor3 = Color3.fromRGB(200, 200, 210)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 10
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = MobListContainer
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            if Config.SelectedMobs[mobName] then
                Config.SelectedMobs[mobName] = nil
                btn.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
            else
                Config.SelectedMobs[mobName] = true
                btn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
            end
        end)
    end
    
    MobListContainer.CanvasSize = UDim2.new(0, 0, 0, MobListLayout.AbsoluteContentSize.Y)
end

local SkillCard = CreateCard(FarmRight, "Kỹ Năng Dropdown")
local SkillContainer, SkillLayout, SkillWrap = CreateDropdown(SkillCard, "Danh Sách Skills")

CreateToggle(SkillContainer, "Auto Skill Z", "AutoSkillZ")
CreateToggle(SkillContainer, "Auto Skill X", "AutoSkillX")
CreateToggle(SkillContainer, "Auto Skill C", "AutoSkillC")
CreateToggle(SkillContainer, "Auto Skill V", "AutoSkillV")
CreateToggle(SkillContainer, "Auto Skill B", "AutoSkillB")
CreateToggle(SkillContainer, "Auto Skill N", "AutoSkillN")
CreateToggle(SkillContainer, "Auto Skill E", "AutoSkillE")
CreateToggle(SkillContainer, "Auto Skill F", "AutoSkillF")
CreateToggle(SkillContainer, "Auto Skill T", "AutoSkillT")
CreateToggle(SkillContainer, "Auto Skill J", "AutoSkillJ")

SkillContainer.CanvasSize = UDim2.new(0, 0, 0, 320)

-- =========================================================
-- [ TAB: SETTINGS ]
-- =========================================================
local SettingCard = CreateCard(SettingsLeft, "Cài Đặt Đánh Chung")
CreateButton(SettingCard, "Đổi Mode: " .. Config.MovementMode, function(btn)
    if Config.MovementMode == "Tween" then
        Config.MovementMode = "Teleport"
    else
        Config.MovementMode = "Tween"
    end
    btn.Text = "Đổi Mode: " .. Config.MovementMode
end)

CreateSlider(SettingCard, "Khoảng Cách", 0, 50, 5, "Distance", false)
CreateSlider(SettingCard, "Tốc Độ Tween", 0.1, 10, 0.5, "TweenDuration", true)
CreateToggle(SettingCard, "Auto Click", "AutoAttack")
CreateToggle(SettingCard, "FAST ATTACK", "FastAttack")

local AutoPosCard = CreateCard(SettingsLeft, "Vị Trí Đứng Đánh")
local PosContainer, PosLayout, PosWrap = CreateDropdown(AutoPosCard, "Vị Trí: " .. Config.FarmPosition)
local PositionsList = {"Trên đầu", "Đằng sau", "Đằng trước", "Dưới chân"}

for _, posName in ipairs(PositionsList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 22)
    
    if Config.FarmPosition == posName then
        btn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
    else
        btn.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
    end
    
    btn.Text = "  " .. posName
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 10
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = PosContainer
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        Config.FarmPosition = posName
        
        local toggleBtn = PosWrap:FindFirstChildWhichIsA("TextButton")
        if toggleBtn then
            toggleBtn.Text = "  Vị Trí: " .. posName .. "  ▼"
        end
        
        for _, b in pairs(PosContainer:GetChildren()) do
            if b:IsA("TextButton") then
                if b.Text:match(posName) then
                    b.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
                else
                    b.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
                end
            end
        end
    end)
end
PosContainer.CanvasSize = UDim2.new(0, 0, 0, PosLayout.AbsoluteContentSize.Y)


local WeaponCard = CreateCard(SettingsRight, "Kiểu Đánh (Vũ Khí Balo)")

-- Nút Bật/Tắt Auto Đổi Kiểu Đánh (Vũ Khí)
CreateToggle(WeaponCard, "Bật Auto Đổi Kiểu Đánh", "AutoSwapWeapons")
CreateSlider(WeaponCard, "Thời gian chuyển (s)", 1, 60, 5, "SwapInterval", false)

local WeaponListContainer, WeaponListLayout, WeaponWrap = CreateDropdown(WeaponCard, "Chọn Kiểu Đánh / Vũ Khí")

CreateButton(WeaponCard, "Quét Balo Vũ Khí", function()
    for _, child in pairs(WeaponListContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local tools = {}
    local backpack = LocalPlayer.Backpack
    
    if backpack then
        local bpChildren = backpack:GetChildren()
        for _, tool in ipairs(bpChildren) do
            if tool:IsA("Tool") then
                tools[tool.Name] = tool
            end
        end
    end
    
    local char = LocalPlayer.Character
    if char then
        local charChildren = char:GetChildren()
        for _, tool in ipairs(charChildren) do
            if tool:IsA("Tool") then
                tools[tool.Name] = tool
            end
        end
    end
    
    for toolName, _ in pairs(tools) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 22)
        
        if Config.SelectedWeapons[toolName] then
            btn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
        else
            btn.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
        end
        
        btn.Text = "  " .. toolName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 10
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = WeaponListContainer
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            if Config.SelectedWeapons[toolName] then
                Config.SelectedWeapons[toolName] = nil
                btn.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
                
                -- LỖI CẤT VŨ KHÍ FIX TẠI ĐÂY: Tháo vũ khí bị bỏ chọn ra khỏi tay ngay lập tức
                local character = LocalPlayer.Character
                local pBackpack = LocalPlayer:FindFirstChild("Backpack")
                if character and pBackpack then
                    local holdTool = character:FindFirstChild(toolName)
                    if holdTool then
                        holdTool.Parent = pBackpack
                    end
                end
            else
                Config.SelectedWeapons[toolName] = true
                btn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
            end
        end)
    end
    
    WeaponListContainer.CanvasSize = UDim2.new(0, 0, 0, WeaponListLayout.AbsoluteContentSize.Y)
end)


-- =========================================================
-- [ TAB: BOSSES ]
-- =========================================================
local BossCard = CreateCard(BossLeft, "Cài Đặt Đánh Boss")
CreateToggle(BossCard, "Bật Auto Boss", "AutoBoss")
CreateToggle(BossCard, "Farm Tất Cả Boss", "FarmAllBosses")
CreateSlider(BossCard, "Thời gian chờ Boss", 0.1, 60, 0.5, "BossWaitTime", true)

CreateButton(BossCard, "Quét Tìm Boss", function()
    table.clear(Config.BossDataCache)
    
    local allDescendants = Workspace:GetDescendants()
    for _, obj in ipairs(allDescendants) do
        ScanObj(obj)
    end
    
    UpdateBossUIList()
end)

local BossListCard = CreateCard(BossRight, "Danh Sách Boss")
local BossListContainer, BossListLayout, BossWrap = CreateDropdown(BossListCard, "Chọn Boss")

function UpdateBossUIList()
    for _, child in pairs(BossListContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    for bossName, coords in pairs(Config.BossDataCache) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 22)
        
        if Config.SelectedBosses[bossName] then
            btn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        else
            btn.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
        end
        
        btn.Text = "  [BOSS] " .. bossName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = BossListContainer
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            if Config.SelectedBosses[bossName] then
                Config.SelectedBosses[bossName] = nil
                btn.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
            else
                Config.SelectedBosses[bossName] = true
                btn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            end
        end)
    end
    
    BossListContainer.CanvasSize = UDim2.new(0, 0, 0, BossListLayout.AbsoluteContentSize.Y)
end

-- =========================================================
-- [ TAB: WORLD TRAVEL (ĐẢO, TỌA ĐỘ, NPC) ]
-- =========================================================
local IslandCard = CreateCard(TravelLeft, "Teleport Đảo (Islands)")
local IslandContainer, IslandLayout, IslandWrap = CreateDropdown(IslandCard, "Chọn Đảo")

CreateButton(IslandCard, "Quét Tìm Đảo/Spawn", function()
    for _, child in pairs(IslandContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local foundIslands = {}
    
    local allDescendants = Workspace:GetDescendants()
    for _, obj in ipairs(allDescendants) do
        if obj:IsA("SpawnLocation") then
            local displayName = "Spawn: " .. obj.Name
            if obj.Name == "SpawnLocation" and obj.Parent then
                displayName = "Spawn: " .. obj.Parent.Name
            end
            table.insert(foundIslands, {Name = displayName, Pos = obj.Position})
            
        elseif obj:IsA("Model") then
            local lower = obj.Name:lower()
            if lower:match("island") or lower:match("town") or lower:match("sea") or lower:match("village") then
                local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if p then
                    table.insert(foundIslands, {Name = obj.Name, Pos = p.Position})
                end
            end
        end
    end
    
    for _, data in ipairs(foundIslands) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -4, 0, 25)
        itemFrame.BackgroundTransparency = 1
        itemFrame.Parent = IslandContainer
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.65, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 5, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = data.Name
        nameLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 10
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = itemFrame
        
        local teleBtn = Instance.new("TextButton")
        teleBtn.Size = UDim2.new(0, 40, 0, 20)
        teleBtn.Position = UDim2.new(1, -45, 0.5, -10)
        teleBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 180)
        teleBtn.Text = "Tele"
        teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        teleBtn.Font = Enum.Font.GothamBold
        teleBtn.TextSize = 9
        teleBtn.Parent = itemFrame
        
        local teleCorner = Instance.new("UICorner")
        teleCorner.CornerRadius = UDim.new(0, 4)
        teleCorner.Parent = teleBtn
        
        teleBtn.MouseButton1Click:Connect(function()
            TeleportToPos(data.Pos)
        end)
    end
    
    IslandContainer.CanvasSize = UDim2.new(0, 0, 0, IslandLayout.AbsoluteContentSize.Y)
end)

local CoordCard = CreateCard(TravelLeft, "Lưu Tọa Độ")

local function CreateCoordRow(parent, title, configKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0.5, 0, 1, 0)
    status.Position = UDim2.new(0, 8, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = title .. ": Trống"
    status.TextColor3 = Color3.fromRGB(180, 180, 190)
    status.Font = Enum.Font.GothamSemibold
    status.TextSize = 10
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = frame
    
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0, 35, 0, 18)
    saveBtn.Position = UDim2.new(1, -85, 0.5, -9)
    saveBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
    saveBtn.Text = "Lưu"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 9
    saveBtn.Parent = frame
    
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 4)
    saveCorner.Parent = saveBtn
    
    local teleBtn = Instance.new("TextButton")
    teleBtn.Size = UDim2.new(0, 35, 0, 18)
    teleBtn.Position = UDim2.new(1, -45, 0.5, -9)
    teleBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 180)
    teleBtn.Text = "Tele"
    teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleBtn.Font = Enum.Font.GothamBold
    teleBtn.TextSize = 9
    teleBtn.Parent = frame
    
    local teleCorner = Instance.new("UICorner")
    teleCorner.CornerRadius = UDim.new(0, 4)
    teleCorner.Parent = teleBtn
    
    saveBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            Config[configKey] = char.HumanoidRootPart.CFrame
            status.Text = title .. ": Đã Lưu"
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
    end)
    
    teleBtn.MouseButton1Click:Connect(function()
        if Config[configKey] then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = Config[configKey]
            end
        end
    end)
end

CreateCoordRow(CoordCard, "Tọa Độ 1", "SavedPos1")
CreateCoordRow(CoordCard, "Tọa Độ 2", "SavedPos2")
CreateCoordRow(CoordCard, "Tọa Độ 3", "SavedPos3")

local NpcCard = CreateCard(TravelRight, "Dịch Chuyển NPC")
local NpcListContainer, NpcListLayout, NpcWrap = CreateDropdown(NpcCard, "Danh Sách NPC")

CreateButton(NpcCard, "Quét Đầy Đủ NPC", function()
    for _, child in pairs(NpcListContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local foundNPCs = {}
    
    local allDescendants = Workspace:GetDescendants()
    for _, obj in ipairs(allDescendants) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character and obj:FindFirstChild("HumanoidRootPart") then
            local ln = obj.Name:lower()
            
            local hasPrompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            
            if ln:match("npc") or ln:match("shop") or ln:match("quest") or ln:match("dealer") or ln:match("vendor") or hasPrompt then
                table.insert(foundNPCs, {Name = obj.Name, Pos = obj.HumanoidRootPart.Position})
            end
        end
    end
    
    for _, data in ipairs(foundNPCs) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -4, 0, 25)
        itemFrame.BackgroundTransparency = 1
        itemFrame.Parent = NpcListContainer
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 8, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = data.Name
        nameLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 10
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = itemFrame
        
        local teleBtn = Instance.new("TextButton")
        teleBtn.Size = UDim2.new(0, 40, 0, 20)
        teleBtn.Position = UDim2.new(1, -45, 0.5, -10)
        teleBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 180)
        teleBtn.Text = "Tele"
        teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        teleBtn.Font = Enum.Font.GothamBold
        teleBtn.TextSize = 9
        teleBtn.Parent = itemFrame
        
        local teleCorner = Instance.new("UICorner")
        teleCorner.CornerRadius = UDim.new(0, 4)
        teleCorner.Parent = teleBtn
        
        teleBtn.MouseButton1Click:Connect(function()
            TeleportToPos(data.Pos)
        end)
    end
    
    NpcListContainer.CanvasSize = UDim2.new(0, 0, 0, NpcListLayout.AbsoluteContentSize.Y)
end)

-- =========================================================
-- [ TAB: EGGS & FRUITS (WITH ESP) ]
-- =========================================================
local EggCard = CreateCard(ItemLeft, "Cài Đặt Trứng")
CreateToggle(EggCard, "ESP Trứng (Nhìn Xuyên)", "EggESP")
CreateToggle(EggCard, "Auto Teleport Tới Trứng", "AutoEgg")

local FruitCard = CreateCard(ItemRight, "Trái Ác Quỷ (Fruits)")
CreateToggle(FruitCard, "Bật ESP Trái Ác Quỷ", "FruitESP")

local FruitListContainer, FruitListLayout, FruitWrap = CreateDropdown(FruitCard, "Trái Đang Rơi")

local function GetFruits()
    local fruits = {}
    local children = Workspace:GetChildren()
    for _, obj in ipairs(children) do
        if (obj:IsA("Tool") or obj:IsA("Model")) and string.match(obj.Name:lower(), "fruit") then
            local part = nil
            if obj:IsA("Model") then
                part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            else
                part = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
            end
            
            if part then
                table.insert(fruits, {Obj = obj, Name = obj.Name, Part = part})
            end
        end
    end
    return fruits
end

CreateButton(FruitCard, "Quét Tìm Trái Ác Quỷ", function()
    for _, child in pairs(FruitListContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local foundFruits = GetFruits()
    
    if #foundFruits > 0 then
        for _, data in ipairs(foundFruits) do
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, -4, 0, 25)
            itemFrame.BackgroundTransparency = 1
            itemFrame.Parent = FruitListContainer
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
            nameLabel.Position = UDim2.new(0, 8, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = data.Name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
            nameLabel.Font = Enum.Font.GothamSemibold
            nameLabel.TextSize = 10
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = itemFrame
            
            local teleBtn = Instance.new("TextButton")
            teleBtn.Size = UDim2.new(0, 40, 0, 20)
            teleBtn.Position = UDim2.new(1, -45, 0.5, -10)
            teleBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 180)
            teleBtn.Text = "Tele"
            teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            teleBtn.Font = Enum.Font.GothamBold
            teleBtn.TextSize = 9
            teleBtn.Parent = itemFrame
            
            local teleCorner = Instance.new("UICorner")
            teleCorner.CornerRadius = UDim.new(0, 4)
            teleCorner.Parent = teleBtn
            
            teleBtn.MouseButton1Click:Connect(function()
                TeleportToPos(data.Part.Position)
            end)
        end
    end
    
    FruitListContainer.CanvasSize = UDim2.new(0, 0, 0, FruitListLayout.AbsoluteContentSize.Y)
end)

-- =========================================================
-- [ LOGIC HIỂN THỊ ESP TRỨNG & TRÁI ÁC QUỶ TÍCH HỢP ]
-- =========================================================
local EspFolder = Instance.new("Folder")
EspFolder.Name = "YuiHuB_ESP_Folder"
EspFolder.Parent = targetParent

local espCache = {}

local function GetEggs()
    local eggs = {}
    local allDescendants = Workspace:GetDescendants()
    for _, obj in ipairs(allDescendants) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Name:lower():match("egg") then
            table.insert(eggs, obj)
        end
    end
    return eggs
end

SafeConnect(RunService.Heartbeat, function()
    local currentTargets = {}
    local char = LocalPlayer.Character
    local hrp = nil
    if char then
        hrp = char:FindFirstChild("HumanoidRootPart")
    end
    
    if hrp then
        if Config.EggESP then
            local allEggs = GetEggs()
            for _, egg in ipairs(allEggs) do
                local part = nil
                if egg:IsA("Model") then
                    part = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
                else
                    part = egg
                end
                
                if part then
                    currentTargets[egg] = {
                        Part = part,
                        Name = egg.Name,
                        Color = Color3.fromRGB(255, 200, 50)
                    }
                end
            end
        end
        
        if Config.FruitESP then
            local allFruits = GetFruits()
            for _, data in ipairs(allFruits) do
                currentTargets[data.Obj] = {
                    Part = data.Part,
                    Name = data.Name,
                    Color = Color3.fromRGB(100, 255, 100)
                }
            end
        end
        
        for obj, data in pairs(currentTargets) do
            local dist = (hrp.Position - data.Part.Position).Magnitude
            
            if not espCache[obj] then
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 150, 0, 40)
                bb.AlwaysOnTop = true
                bb.Adornee = data.Part
                
                local txt = Instance.new("TextLabel")
                txt.Size = UDim2.new(1, 0, 1, 0)
                txt.BackgroundTransparency = 1
                txt.TextColor3 = data.Color
                txt.TextStrokeTransparency = 0
                txt.Font = Enum.Font.GothamBold
                txt.TextSize = 11
                txt.Parent = bb
                
                bb.Parent = EspFolder
                espCache[obj] = {Gui = bb, Text = txt}
            end
            
            espCache[obj].Text.Text = string.format("%s [%d m]", data.Name, math.floor(dist))
        end
    end
    
    for obj, cache in pairs(espCache) do
        if not currentTargets[obj] or not obj.Parent then
            cache.Gui:Destroy()
            espCache[obj] = nil
        end
    end
end)

-- =========================================================
-- [ TAB: PLAYER MODS & SETTINGS ]
-- =========================================================
local PlayerCard = CreateCard(PlayerLeft, "Nhân Vật")
CreateToggle(PlayerCard, "Bật Tốc Độ Chạy", "WalkSpeedEnabled")
CreateSlider(PlayerCard, "Tốc Độ", 16, 300, 50, "WalkSpeed", false)
CreateToggle(PlayerCard, "Bật Sức Bật (Nhảy)", "JumpPowerEnabled")
CreateSlider(PlayerCard, "Sức Bật", 50, 500, 100, "JumpPower", false)
CreateToggle(PlayerCard, "Nhảy Vô Hạn", "InfJump")
CreateToggle(PlayerCard, "Đi Trên Mặt Nước", "WalkOnWater")

local MoveCard = CreateCard(PlayerRight, "Bay & Noclip")
CreateToggle(MoveCard, "Xuyên Tường (Noclip)", "Noclip")
CreateToggle(MoveCard, "Bay Tự Do (Fly)", "Fly")
CreateSlider(MoveCard, "Tốc Độ Bay", 16, 500, 50, "FlySpeed", false)

local FishCard = CreateCard(PlayerRight, "Câu Cá Tự Động")
CreateToggle(FishCard, "Bật Auto Câu Cá", "AutoFishing")


SwitchTab("Overview")

-- Logic Mở/Đóng Giao Diện
ToggleButton.MouseButton1Click:Connect(function()
    Config.MenuOpen = not Config.MenuOpen
    if Config.MenuOpen then
        MainFrame.Visible = true
    else
        MainFrame.Visible = false
    end
end)

-- =========================================================
-- [ HỆ THỐNG AUTO ĐỔI KIỂU ĐÁNH / VŨ KHÍ THEO THỜI GIAN ]
-- =========================================================
local lastSwapTime = tick()
local currentWeaponIndex = 1

SafeConnect(RunService.Heartbeat, function()
    local currentTime = tick()
    
    if currentTime - lastSwapTime >= Config.SwapInterval then
        lastSwapTime = currentTime
        
        -- Logic Auto Đổi Kiểu Đánh (Vũ Khí)
        if Config.AutoSwapWeapons then
            local activeWeapons = {}
            for name, isSelected in pairs(Config.SelectedWeapons) do
                if isSelected then
                    table.insert(activeWeapons, name)
                end
            end
            
            if #activeWeapons > 0 then
                currentWeaponIndex = currentWeaponIndex + 1
                if currentWeaponIndex > #activeWeapons then
                    currentWeaponIndex = 1
                end
                
                local nextWeapon = activeWeapons[currentWeaponIndex]
                
                local char = LocalPlayer.Character
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                
                if char and backpack then
                    -- Cất hết vũ khí không phải là nextWeapon
                    for _, tool in ipairs(char:GetChildren()) do
                        if tool:IsA("Tool") and tool.Name ~= nextWeapon then
                            tool.Parent = backpack
                        end
                    end
                    
                    -- Lấy vũ khí tiếp theo ra
                    local newTool = backpack:FindFirstChild(nextWeapon)
                    if newTool then
                        newTool.Parent = char
                    end
                end
            end
        end
    end
end)


-- =========================================================
-- [ CORE FARMING LOGIC (MƯỢT MÀ KHÔNG GIẬT) ]
-- =========================================================
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

local function GetBestMobTarget()
    local bestTarget = nil
    local highestLevel = -1
    local shortestDist = math.huge
    
    local char = LocalPlayer.Character
    local hrp = nil
    local myPos = Vector3.new(0, 0, 0)
    
    if char then
        hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            myPos = hrp.Position
        end
    end

    local folders = GetMobFolders()
    if #folders > 0 and folders[1] ~= Workspace then
        for _, folder in ipairs(folders) do
            for _, obj in pairs(folder:GetDescendants()) do
                if obj:IsA("Model") and IsAlive(obj) and obj ~= char then
                    if Config.SelectedMobs[obj.Name] then
                        local levelString = obj.Name:match("%d+")
                        local level = 1
                        
                        if levelString then
                            level = tonumber(levelString)
                        end
                        
                        local root = obj:FindFirstChild("HumanoidRootPart")
                        if root then
                            local dist = (root.Position - myPos).Magnitude
                            
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
        end
    else
        local allDescendants = Workspace:GetDescendants()
        for _, obj in ipairs(allDescendants) do
            if obj:IsA("Model") and IsAlive(obj) and obj ~= char then
                if Config.SelectedMobs[obj.Name] then
                    local levelString = obj.Name:match("%d+")
                    local level = 1
                    
                    if levelString then
                        level = tonumber(levelString)
                    end
                    
                    local root = obj:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (root.Position - myPos).Magnitude
                        
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
    end
    
    return bestTarget
end

local function TeleportTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char then return end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local hum = char:FindFirstChild("Humanoid")
    if hum and hum.Health <= 0 then return end 
    
    if Config.MovementMode == "Teleport" then
        if currentTween then
            currentTween:Cancel()
            currentTween = nil
            isTweening = false
        end
        rootPart.CFrame = targetCFrame
    else
        local dist = (rootPart.Position - targetCFrame.Position).Magnitude
        
        if dist > 15 then
            if not isTweening then
                isTweening = true
                if currentTween then
                    currentTween:Cancel()
                end
                
                local tweenInfo = TweenInfo.new(Config.TweenDuration, Enum.EasingStyle.Linear)
                currentTween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
                currentTween:Play()
                
                currentTween.Completed:Connect(function()
                    isTweening = false
                end)
            end
        else
            isTweening = false
            if currentTween then
                currentTween:Cancel()
                currentTween = nil
            end
            rootPart.CFrame = targetCFrame
        end
    end
end

local function EquipWeaponsFast()
    -- Bỏ qua thao tác equip tay nếu đang dùng Auto Swap Vũ Khí để tránh đụng độ
    if Config.AutoSwapWeapons then
        return
    end
    
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    if not char or not backpack then
        return
    end
    
    -- Cất đi những vũ khí chưa được chọn
    local currentTools = char:GetChildren()
    for _, tool in ipairs(currentTools) do
        if tool:IsA("Tool") and not Config.SelectedWeapons[tool.Name] then
            tool.Parent = backpack
        end
    end
    
    -- Mặc lên những vũ khí đã được chọn
    for toolName, isSelected in pairs(Config.SelectedWeapons) do
        if isSelected then
            local toolInBp = backpack:FindFirstChild(toolName)
            if toolInBp then
                toolInBp.Parent = char
            end
        end
    end
end

SafeConnect(RunService.RenderStepped, function()
    local char = LocalPlayer.Character
    if not char then return end
    
    if Config.FastAttack or Config.AutoAttack then
        EquipWeaponsFast() 
        
        local children = char:GetChildren()
        for i = 1, #children do
            local tool = children[i]
            
            if tool:IsA("Tool") then
                if Config.FastAttack then
                    for j = 1, 3 do
                        tool:Activate()
                    end
                else
                    tool:Activate()
                end
            end
        end
    end
end)

-- =========================================================
-- [ AUTO SKILL SIÊU MƯỢT (FIXED HOLD KEY 0.05S) ]
-- =========================================================
local lastSkillTrigger = tick()
SafeConnect(RunService.Heartbeat, function()
    local currentTime = tick()
    
    if currentTime - lastSkillTrigger > 0.2 then
        lastSkillTrigger = currentTime
        
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
                -- Spawn luồng mới để bấm và giữ phím 0.05 giây, giúp game nhận chiêu chắc chắn 100%
                task.spawn(function()
                    VirtualInputManager:SendKeyEvent(true, key, false, game)
                    task.wait(0.05) 
                    VirtualInputManager:SendKeyEvent(false, key, false, game)
                end)
            end
        end
    end
end)

SafeConnect(RunService.Heartbeat, function()
    local char = LocalPlayer.Character
    if not char then
        activelyFarming = false
        return
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        activelyFarming = false
        return
    end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        activelyFarming = false
        if isTweening and currentTween then
            currentTween:Cancel()
            currentTween = nil
            isTweening = false
        end
        return
    end
    
    local activeBosses = {}
    for name, _ in pairs(Config.SelectedBosses) do
        table.insert(activeBosses, name)
    end
    
    local bossToFight = nil

    if (Config.AutoBoss or Config.FarmAllBosses) and #activeBosses > 0 then
        for _, bossName in ipairs(activeBosses) do
            local bInst = nil
            local allDescendants = Workspace:GetDescendants()
            
            for _, obj in ipairs(allDescendants) do
                if obj:IsA("Model") and obj.Name == bossName and IsAlive(obj) then
                    bInst = obj
                    break
                end
            end
            
            if bInst then
                bossToFight = bInst
                
                local index = table.find(activeBosses, bossName)
                if index then
                    Config.CurrentBossIndex = index
                else
                    Config.CurrentBossIndex = 1
                end
                break
            end
        end
    end

    if bossToFight then
        activelyFarming = true
        if humanoid then
            humanoid:ChangeState(11)
        end
        
        Config.LastBossCheck = tick()
        local bossRoot = bossToFight:FindFirstChild("HumanoidRootPart")
        if bossRoot then
            local targetPos = GetOffsetCFrame(bossRoot.CFrame)
            TeleportTo(targetPos)
        end
        return
    end
    
    if Config.AutoEgg then
        local eggs = GetEggs()
        local targetEgg = nil
        
        for _, egg in ipairs(eggs) do
            if Config.SelectedEggRarity == "Tất cả" then
                targetEgg = egg
                break
            else
                local lowerName = egg.Name:lower()
                local lowerRarity = Config.SelectedEggRarity:lower()
                
                if string.match(lowerName, lowerRarity) then
                    targetEgg = egg
                    break
                end
            end
        end
        
        if targetEgg then
            local part = nil
            if targetEgg:IsA("Model") then
                part = targetEgg.PrimaryPart or targetEgg:FindFirstChildWhichIsA("BasePart")
            else
                part = targetEgg
            end
            
            if part then
                activelyFarming = true
                if humanoid then
                    humanoid:ChangeState(11)
                end
                
                local targetCFrame = part.CFrame * CFrame.new(0, 3, 0)
                TeleportTo(targetCFrame)
                return
            end
        end
    end

    if Config.AutoFarm then
        local targetMob = GetBestMobTarget()
        
        if targetMob and IsAlive(targetMob) then
            activelyFarming = true
            if humanoid then
                humanoid:ChangeState(11)
            end
            
            local mobRoot = targetMob:FindFirstChild("HumanoidRootPart")
            if mobRoot then
                local targetPos = GetOffsetCFrame(mobRoot.CFrame)
                TeleportTo(targetPos)
            end
            return
        else
            local roamingTargetPos = nil
            
            for selectedMob, _ in pairs(Config.SelectedMobs) do
                if Config.MobDataCache[selectedMob] then
                    roamingTargetPos = Config.MobDataCache[selectedMob]
                    break
                end
            end
            
            if roamingTargetPos then
                activelyFarming = true
                if humanoid then
                    humanoid:ChangeState(11)
                end
                
                local waitCFrame = GetOffsetCFrame(CFrame.new(roamingTargetPos))
                TeleportTo(waitCFrame)
                return
            end
        end
    end

    if (Config.AutoBoss or Config.FarmAllBosses) and #activeBosses > 0 then
        activelyFarming = true
        if humanoid then
            humanoid:ChangeState(11)
        end
        
        if Config.CurrentBossIndex > #activeBosses then
            Config.CurrentBossIndex = 1
        end
        
        local targetBossName = activeBosses[Config.CurrentBossIndex]
        local savedPos = Config.BossDataCache[targetBossName]
        
        if savedPos then
            local waitCFrame = GetOffsetCFrame(CFrame.new(savedPos))
            TeleportTo(waitCFrame)
            
            local timeDiff = tick() - Config.LastBossCheck
            if timeDiff >= Config.BossWaitTime then
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

-- =========================================================
-- [ PLAYER MODS LOGIC ]
-- =========================================================
local flyBv = nil
local flyBg = nil

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
        if Config.WalkSpeedEnabled then
            hum.WalkSpeed = Config.WalkSpeed
        end
        
        if Config.JumpPowerEnabled then
            hum.JumpPower = Config.JumpPower
        end
        
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
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end
            
            flyBv.Velocity = moveDir * Config.FlySpeed
            flyBg.CFrame = CFrame.new(hrp.Position, hrp.Position + Camera.CFrame.LookVector)
        else
            if flyBv then
                flyBv:Destroy()
                flyBv = nil
            end
            if flyBg then
                flyBg:Destroy()
                flyBg = nil
            end
            
            if hum.PlatformStand and not activelyFarming then
                hum.PlatformStand = false
            end
        end
        
        if Config.Noclip and not activelyFarming then
            local descendants = char:GetDescendants()
            for _, part in ipairs(descendants) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
        
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
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
            end
        end
    end
end)

SafeConnect(UserInputService.JumpRequest, function()
    if Config.InfJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

local lastFishingCast = tick()
SafeConnect(RunService.Heartbeat, function()
    if Config.AutoFishing then
        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChild("Backpack")
        
        if not char then return end
        
        local rod = nil
        
        local charChildren = char:GetChildren()
        for _, tool in ipairs(charChildren) do
            if tool:IsA("Tool") and tool.Name:lower():match("rod$") then
                rod = tool
                break
            end
        end
        
        if not rod and bp then
            local bpChildren = bp:GetChildren()
            for _, tool in ipairs(bpChildren) do
                if tool:IsA("Tool") and tool.Name:lower():match("rod$") then
                    rod = tool
                    break
                end
            end
        end
        
        if rod then
            if rod.Parent ~= char then
                local charTools = char:GetChildren()
                for _, t in ipairs(charTools) do
                    if t:IsA("Tool") then
                        t.Parent = bp
                    end
                end
                rod.Parent = char
            end
            
            local isCast = false
            local tip = rod:FindFirstChild("Tip")
            
            if tip then
                local att = tip:FindFirstChild("TipAttachment") or tip:FindFirstChildWhichIsA("Attachment")
                if att then
                    local descendants = workspace:GetDescendants()
                    for _, obj in ipairs(descendants) do
                        local isConstraint = obj:IsA("Constraint") or obj:IsA("Beam") or obj:IsA("RopeConstraint")
                        if isConstraint then
                            if obj.Attachment0 == att or obj.Attachment1 == att then
                                isCast = true
                                break
                            end
                        end
                    end
                end
            end
            
            if not isCast then
                local timeDiff = tick() - lastFishingCast
                if timeDiff > 3 then
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

print("YuiHuB Mobile V13 Loaded - 100% UNCOMPRESSED SOURCE CODE - FIXED ALL BUGS!")
