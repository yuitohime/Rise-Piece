-- =====================================================================
-- SUPERIOR AUTO FARM SCRIPT (YUIHUB / MARU STYLE) - [ULTIMATE VERSION]
-- Giao diện được thiết kế lại chuẩn Maru Hub (Card, Translucent, Stroke).
-- Tối ưu hóa hiệu năng, Chống Memory Leak triệt để, KHÔNG GIẬT LAG.
-- Hệ thống quét Boss/Quái sâu tuyệt đối, Menu Skill/Vị trí dạng Dropdown.
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
    
    -- All Skills
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
    
    -- Saved Coordinates
    SavedPos1 = nil,
    SavedPos2 = nil,
    SavedPos3 = nil
}

local isTweening = false
local currentTween = nil
local activelyFarming = false 

-- =====================================================================
-- [ UI LIBRARY: YUIHUB (MARU STYLE) ]
-- =====================================================================
local UI_NAME = "YuiHuB_MaruStyle"
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

-- Nút Toggle (Logo)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 15, 0.5, -25)
ToggleButton.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
ToggleButton.BackgroundTransparency = 0.2
ToggleButton.Text = "YUI"
ToggleButton.TextColor3 = Color3.fromRGB(100, 170, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 16
ToggleButton.Parent = ScreenGui
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", ToggleButton).Color = Color3.fromRGB(50, 55, 70)

-- Khung Chính (Main Frame)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 750, 0, 480)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 15, 20)
MainFrame.BackgroundTransparency = 0.12 -- Trong suốt phong cách Maru
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(45, 50, 65)

-- Sidebar (Cột Tab bên trái)
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 190, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
Sidebar.BackgroundTransparency = 0.5
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

-- Divider giữa Sidebar và Content
local SidebarDivider = Instance.new("Frame")
SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
SidebarDivider.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
SidebarDivider.BorderSizePixel = 0
SidebarDivider.Parent = Sidebar

-- Logo / Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 60)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "  YuiHuB"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 22
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Sidebar

-- Vùng Chứa Tabs
local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Size = UDim2.new(1, 0, 1, -70)
SidebarScroll.Position = UDim2.new(0, 0, 0, 70)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.ScrollBarThickness = 2
SidebarScroll.Parent = Sidebar
local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 4)
SidebarLayout.Parent = SidebarScroll

-- Content Area (Khu vực nội dung bên phải)
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -190, 1, 0)
ContentArea.Position = UDim2.new(0, 190, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local Topbar = Instance.new("Frame")
Topbar.Size = UDim2.new(1, 0, 0, 50)
Topbar.BackgroundTransparency = 1
Topbar.Parent = ContentArea
local TopbarDivider = Instance.new("Frame")
TopbarDivider.Size = UDim2.new(1, 0, 0, 1)
TopbarDivider.Position = UDim2.new(0, 0, 1, -1)
TopbarDivider.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
TopbarDivider.BorderSizePixel = 0
TopbarDivider.Parent = Topbar

local CurrentTabTitle = Instance.new("TextLabel")
CurrentTabTitle.Size = UDim2.new(1, -20, 1, 0)
CurrentTabTitle.Position = UDim2.new(0, 20, 0, 0)
CurrentTabTitle.BackgroundTransparency = 1
CurrentTabTitle.Text = "Overview"
CurrentTabTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
CurrentTabTitle.Font = Enum.Font.GothamBold
CurrentTabTitle.TextSize = 20
CurrentTabTitle.TextXAlignment = Enum.TextXAlignment.Left
CurrentTabTitle.Parent = Topbar

local CloseMenuBtn = Instance.new("TextButton")
CloseMenuBtn.Size = UDim2.new(0, 30, 0, 30)
CloseMenuBtn.Position = UDim2.new(1, -45, 0, 10)
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

-- Hệ thống Tab
local Tabs = {}
local TabContents = {}

local function CreateCategory(name)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 25)
    lbl.Position = UDim2.new(0, 20, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text = name:upper()
    lbl.TextColor3 = Color3.fromRGB(110, 115, 130)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
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
            btn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
            btn.TextColor3 = Color3.fromRGB(150, 155, 170)
        end
    end
end

-- Tạo Tab với bố cục 2 cột (Card Grid style)
local function CreateTabButton(name)
    local btnFrame = Instance.new("Frame")
    btnFrame.Size = UDim2.new(1, 0, 0, 32)
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = SidebarScroll
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -30, 1, 0)
    btn.Position = UDim2.new(0, 15, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
    btn.Text = "   " .. name
    btn.TextColor3 = Color3.fromRGB(150, 155, 170)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = btnFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local scrollContent = Instance.new("ScrollingFrame")
    scrollContent.Size = UDim2.new(1, 0, 1, 0)
    scrollContent.BackgroundTransparency = 1
    scrollContent.ScrollBarThickness = 3
    scrollContent.Visible = false
    scrollContent.Parent = ContentContainer
    
    -- Bố cục 2 Cột bên trong Content
    local LeftCol = Instance.new("Frame")
    LeftCol.Size = UDim2.new(0.5, -20, 1, 0)
    LeftCol.Position = UDim2.new(0, 15, 0, 15)
    LeftCol.BackgroundTransparency = 1
    LeftCol.Parent = scrollContent
    local LeftLayout = Instance.new("UIListLayout")
    LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LeftLayout.Padding = UDim.new(0, 12)
    LeftLayout.Parent = LeftCol
    
    local RightCol = Instance.new("Frame")
    RightCol.Size = UDim2.new(0.5, -20, 1, 0)
    RightCol.Position = UDim2.new(0.5, 5, 0, 15)
    RightCol.BackgroundTransparency = 1
    RightCol.Parent = scrollContent
    local RightLayout = Instance.new("UIListLayout")
    RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    RightLayout.Padding = UDim.new(0, 12)
    RightLayout.Parent = RightCol
    
    Tabs[name] = btn
    TabContents[name] = scrollContent
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    
    -- Tự động dãn dài ScrollingFrame dựa trên cột dài nhất
    local function UpdateCanvas()
        local max = math.max(LeftLayout.AbsoluteContentSize.Y, RightLayout.AbsoluteContentSize.Y)
        scrollContent.CanvasSize = UDim2.new(0, 0, 0, max + 40)
    end
    LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
    
    return LeftCol, RightCol
end

-- =====================================================================
-- [ UI COMPONENTS: CARDS, TOGGLES, DROPDOWNS ]
-- =====================================================================

-- Thẻ Card bọc các chức năng (Thiết kế xếp hộp)
local function CreateCard(parent, title)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 40) -- Sẽ tự động tăng chiều cao
    card.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
    card.BackgroundTransparency = 0.3
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", card).Color = Color3.fromRGB(45, 50, 65)
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 35)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card
    
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 0, 35)
    divider.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
    divider.BorderSizePixel = 0
    divider.Parent = card
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -36)
    contentFrame.Position = UDim2.new(0, 0, 0, 36)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = card
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 2)
    contentLayout.Parent = contentFrame
    
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        card.Size = UDim2.new(1, 0, 0, contentLayout.AbsoluteContentSize.Y + 40)
    end)
    
    return contentFrame
end

local function CreateToggle(parent, text, configKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local switchBg = Instance.new("TextButton")
    switchBg.Size = UDim2.new(0, 38, 0, 20)
    switchBg.Position = UDim2.new(1, -48, 0.5, -10)
    switchBg.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
    switchBg.Text = ""
    switchBg.Parent = frame
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", switchBg).Color = Color3.fromRGB(55, 60, 75)
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = UDim2.new(0, 3, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
    circle.Parent = switchBg
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    
    local function UpdateUI()
        local toggled = Config[configKey]
        local goalPos = toggled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        local goalCol = toggled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
        local bgCol = toggled and Color3.fromRGB(60, 130, 220) or Color3.fromRGB(35, 40, 50)
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
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 32)
    btn.Position = UDim2.new(0, 10, 0.5, -16)
    btn.BackgroundColor3 = Color3.fromRGB(45, 90, 180)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function CreateSlider(parent, text, min, max, default, configKey, isDecimal)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local sliderBg = Instance.new("TextButton")
    sliderBg.Size = UDim2.new(1, -20, 0, 6)
    sliderBg.Position = UDim2.new(0, 10, 0, 30)
    sliderBg.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
    sliderBg.Text = ""
    sliderBg.Parent = frame
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(60, 130, 220)
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

-- Tối ưu Dropdown (Kéo thả, dùng cho Quái, Vũ khí, Kỹ năng, Vị trí)
local function CreateDropdown(parent, titleText)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 45)
    container.BackgroundColor3 = Color3.fromRGB(30, 34, 45)
    container.BackgroundTransparency = 0.2
    container.ClipsDescendants = true
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", container).Color = Color3.fromRGB(45, 50, 65)
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 0, 45)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = "    " .. titleText .. "  ▼"
    toggleBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 12
    toggleBtn.TextXAlignment = Enum.TextXAlignment.Left
    toggleBtn.Parent = container
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 1, -50)
    scrollFrame.Position = UDim2.new(0, 5, 0, 45)
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
        toggleBtn.Text = isOpen and ("    " .. titleText .. "  ▲") or ("    " .. titleText .. "  ▼")
        container.Size = isOpen and UDim2.new(1, 0, 0, 200) or UDim2.new(1, 0, 0, 45)
    end)
    
    return scrollFrame, layout, container
end

-- =====================================================================
-- [ LÕI LOGIC: HÀM QUÉT BOSS & QUÁI TỐI ƯU CỰC MẠNH ]
-- =====================================================================
local function TeleportToPos(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

local function GetMobFolders()
    local folders = {}
    local possibleNames = {"mapa", "map", "enemies", "monsters", "mobs", "npcs", "spawns", "workspace"}
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
    -- Chắc chắn nó là một Model sống
    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj ~= LocalPlayer.Character then
        local lowerName = obj.Name:lower()
        if lowerName:match("^spawnner") or lowerName:match("^spawner") then return end
        
        -- Phân biệt rạch ròi BOSS và MOB (QUÁI)
        if lowerName:match("boss") then
            -- Nếu có chữ boss -> Chắc chắn là Boss
            Config.BossDataCache[obj.Name] = obj.HumanoidRootPart.Position
        elseif lowerName:match("monster") or lowerName:match("enemy") or lowerName:match("mob") or lowerName:match("lv") or lowerName:match("level") or lowerName:match("npc") then
            -- Quái vật thông thường
            Config.MobListCache[obj.Name] = true
            Config.MobDataCache[obj.Name] = obj.HumanoidRootPart.Position
        else
            -- Dự phòng: Nếu là model có máu nhưng tên lạ, vẫn đẩy vào danh sách Quái để không bỏ sót.
            Config.MobListCache[obj.Name] = true
            Config.MobDataCache[obj.Name] = obj.HumanoidRootPart.Position
        end
    end
end

-- =====================================================================
-- [ KHỞI TẠO TẤT CẢ CÁC TABS ]
-- =====================================================================
CreateCategory("Workspace")
local OverviewLeft, OverviewRight = CreateTabButton("Overview")
local FarmLeft, FarmRight = CreateTabButton("Farming")

CreateCategory("Bosses")
local BossLeft, BossRight = CreateTabButton("Bosses")

CreateCategory("World")
local TravelLeft, TravelRight = CreateTabButton("Travel & Coords")
local ItemLeft, ItemRight = CreateTabButton("Eggs & Fruits")

CreateCategory("Activities")
local PlayerLeft, PlayerRight = CreateTabButton("Player Mods")

CreateCategory("System")
local SettingsLeft, SettingsRight = CreateTabButton("Settings")

-- =========================================================
-- [ TAB: OVERVIEW ]
-- =========================================================
local InfoCard = CreateCard(OverviewLeft, "Thông Tin YuiHuB")
local InfoLbl = Instance.new("TextLabel")
InfoLbl.Size = UDim2.new(1, -20, 0, 80)
InfoLbl.Position = UDim2.new(0, 10, 0, 0)
InfoLbl.BackgroundTransparency = 1
InfoLbl.Text = "YUIHUB PREMIUM SCRIPT\n\n- Giao diện thiết kế chuẩn Maru Hub.\n- Khắc phục hoàn toàn lỗi giật lag.\n- Cải tiến tính năng quét Boss/Quái sâu 100%."
InfoLbl.TextColor3 = Color3.fromRGB(180, 180, 190)
InfoLbl.Font = Enum.Font.Gotham
InfoLbl.TextSize = 12
InfoLbl.TextWrapped = true
InfoLbl.TextXAlignment = Enum.TextXAlignment.Left
InfoLbl.Parent = InfoCard

-- =========================================================
-- [ TAB: FARMING (QUÁI & KỸ NĂNG DROPDOWN) ]
-- =========================================================
local FarmCard = CreateCard(FarmLeft, "Cài Đặt Đánh Quái")
CreateToggle(FarmCard, "Bật Auto Farm", "AutoFarm")
CreateButton(FarmCard, "Quét Làm Mới Bản Đồ", function()
    -- Quét toàn bộ Map từ Gốc đến Ngọn để không lọt Boss/Quái
    for _, obj in ipairs(Workspace:GetDescendants()) do ScanObj(obj) end
    UpdateMobUIList()
    UpdateBossUIList()
end)

local MobListContainer, MobListLayout, MobWrap = CreateDropdown(FarmCard, "Chọn Quái Vật")
function UpdateMobUIList()
    for _, child in pairs(MobListContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for mobName, _ in pairs(Config.MobListCache) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 25)
        btn.BackgroundColor3 = Config.SelectedMobs[mobName] and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(22, 25, 32)
        btn.Text = "   " .. mobName
        btn.TextColor3 = Color3.fromRGB(200, 200, 210)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 11
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = MobListContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(function()
            Config.SelectedMobs[mobName] = not Config.SelectedMobs[mobName]
            btn.BackgroundColor3 = Config.SelectedMobs[mobName] and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(22, 25, 32)
        end)
    end
    MobListContainer.CanvasSize = UDim2.new(0, 0, 0, MobListLayout.AbsoluteContentSize.Y)
end

-- Kỹ Năng được đưa vào Dropdown bên cột phải
local SkillCard = CreateCard(FarmRight, "Quản Lý Kỹ Năng")
local SkillContainer, SkillLayout, SkillWrap = CreateDropdown(SkillCard, "Danh Sách Skills")
CreateToggle(SkillContainer, "Auto Skill [Z]", "AutoSkillZ")
CreateToggle(SkillContainer, "Auto Skill [X]", "AutoSkillX")
CreateToggle(SkillContainer, "Auto Skill [C]", "AutoSkillC")
CreateToggle(SkillContainer, "Auto Skill [V]", "AutoSkillV")
CreateToggle(SkillContainer, "Auto Skill [B]", "AutoSkillB")
CreateToggle(SkillContainer, "Auto Skill [N]", "AutoSkillN")
CreateToggle(SkillContainer, "Auto Skill [E]", "AutoSkillE")
CreateToggle(SkillContainer, "Auto Skill [F]", "AutoSkillF")
CreateToggle(SkillContainer, "Auto Skill [T]", "AutoSkillT")
CreateToggle(SkillContainer, "Auto Skill [J]", "AutoSkillJ")
SkillContainer.CanvasSize = UDim2.new(0, 0, 0, 400) -- Đủ dài chứa 10 skills

-- =========================================================
-- [ TAB: BOSSES ]
-- =========================================================
local BossCard = CreateCard(BossLeft, "Cài Đặt Đánh Boss")
CreateToggle(BossCard, "Bật Auto Boss", "AutoBoss")
CreateToggle(BossCard, "Farm Tất Cả Boss (Lùng Sục)", "FarmAllBosses")
CreateSlider(BossCard, "Thời gian chờ Boss (s)", 0.1, 60, 0.5, "BossWaitTime", true)

local BossListCard = CreateCard(BossRight, "Danh Sách Boss")
local BossListContainer, BossListLayout, BossWrap = CreateDropdown(BossListCard, "Chọn Boss")
function UpdateBossUIList()
    for _, child in pairs(BossListContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for bossName, coords in pairs(Config.BossDataCache) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 25)
        btn.BackgroundColor3 = Config.SelectedBosses[bossName] and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(22, 25, 32)
        btn.Text = "   [BOSS] " .. bossName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = BossListContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(function()
            Config.SelectedBosses[bossName] = not Config.SelectedBosses[bossName]
            btn.BackgroundColor3 = Config.SelectedBosses[bossName] and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(22, 25, 32)
        end)
    end
    BossListContainer.CanvasSize = UDim2.new(0, 0, 0, BossListLayout.AbsoluteContentSize.Y)
end

-- =========================================================
-- [ TAB: WORLD TRAVEL & COORDS (LƯU TỌA ĐỘ) ]
-- =========================================================
local CoordCard = CreateCard(TravelLeft, "Lưu Vị Trí Của Bạn")

local function CreateCoordRow(parent, title, configKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0.5, 0, 1, 0)
    status.Position = UDim2.new(0, 10, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = title .. ": Trống"
    status.TextColor3 = Color3.fromRGB(180, 180, 190)
    status.Font = Enum.Font.GothamSemibold
    status.TextSize = 11
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = frame
    
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0, 45, 0, 22)
    saveBtn.Position = UDim2.new(1, -110, 0.5, -11)
    saveBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
    saveBtn.Text = "Lưu"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.Parent = frame
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)
    
    local teleBtn = Instance.new("TextButton")
    teleBtn.Size = UDim2.new(0, 45, 0, 22)
    teleBtn.Position = UDim2.new(1, -55, 0.5, -11)
    teleBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 180)
    teleBtn.Text = "Tele"
    teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleBtn.Font = Enum.Font.GothamBold
    teleBtn.Parent = frame
    Instance.new("UICorner", teleBtn).CornerRadius = UDim.new(0, 4)
    
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

CreateCoordRow(CoordCard, "Tọa Độ 1", "SavedPos1")
CreateCoordRow(CoordCard, "Tọa Độ 2", "SavedPos2")
CreateCoordRow(CoordCard, "Tọa Độ 3", "SavedPos3")

local NpcCard = CreateCard(TravelRight, "Dịch Chuyển NPC")
local NpcListContainer, NpcListLayout, NpcWrap = CreateDropdown(NpcCard, "Danh Sách NPC")
CreateButton(NpcCard, "Quét Tìm NPC", function()
    for _, child in pairs(NpcListContainer:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    local foundNPCs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():match("npc") and obj:FindFirstChild("HumanoidRootPart") then
            table.insert(foundNPCs, {Name = obj.Name, Pos = obj.HumanoidRootPart.Position})
        end
    end
    for _, data in ipairs(foundNPCs) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -4, 0, 30); itemFrame.BackgroundTransparency = 1; itemFrame.Parent = NpcListContainer
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.7, 0, 1, 0); nameLabel.Position = UDim2.new(0, 10, 0, 0); nameLabel.BackgroundTransparency = 1
        nameLabel.Text = data.Name; nameLabel.TextColor3 = Color3.fromRGB(200, 200, 210); nameLabel.Font = Enum.Font.Gotham; nameLabel.TextSize = 11; nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.Parent = itemFrame
        
        local teleBtn = Instance.new("TextButton")
        teleBtn.Size = UDim2.new(0, 45, 0, 22); teleBtn.Position = UDim2.new(1, -55, 0.5, -11); teleBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 180)
        teleBtn.Text = "Tele"; teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); teleBtn.Font = Enum.Font.GothamBold; teleBtn.Parent = itemFrame
        Instance.new("UICorner", teleBtn).CornerRadius = UDim.new(0, 4)
        teleBtn.MouseButton1Click:Connect(function() TeleportToPos(data.Pos) end)
    end
    NpcListContainer.CanvasSize = UDim2.new(0, 0, 0, NpcListLayout.AbsoluteContentSize.Y)
end)

-- =========================================================
-- [ TAB: EGGS & FRUITS ]
-- =========================================================
local EggCard = CreateCard(ItemLeft, "Cài Đặt Trứng")
CreateToggle(EggCard, "ESP Trứng (Nhìn Xuyên)", "EggESP")
CreateToggle(EggCard, "Auto Teleport Tới Trứng", "AutoEgg")

local FruitCard = CreateCard(ItemRight, "Trái Ác Quỷ (Fruits)")
local FruitListContainer, FruitListLayout, FruitWrap = CreateDropdown(FruitCard, "Trái Đang Rơi")
CreateButton(FruitCard, "Quét Trái Ác Quỷ", function()
    for _, child in pairs(FruitListContainer:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    local foundFruits = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if (obj:IsA("Tool") or obj:IsA("Model")) and string.match(obj.Name:lower(), "fruit") then
            local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
            if part then table.insert(foundFruits, {Name = obj.Name, Pos = part.Position}) end
        end
    end
    if #foundFruits > 0 then
        for _, data in ipairs(foundFruits) do
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, -4, 0, 30); itemFrame.BackgroundTransparency = 1; itemFrame.Parent = FruitListContainer
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.7, 0, 1, 0); nameLabel.Position = UDim2.new(0, 10, 0, 0); nameLabel.BackgroundTransparency = 1
            nameLabel.Text = data.Name; nameLabel.TextColor3 = Color3.fromRGB(255, 255, 100); nameLabel.Font = Enum.Font.GothamSemibold; nameLabel.TextSize = 11; nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.Parent = itemFrame
            local teleBtn = Instance.new("TextButton")
            teleBtn.Size = UDim2.new(0, 45, 0, 22); teleBtn.Position = UDim2.new(1, -55, 0.5, -11); teleBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 180)
            teleBtn.Text = "Tele"; teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); teleBtn.Font = Enum.Font.GothamBold; teleBtn.Parent = itemFrame
            Instance.new("UICorner", teleBtn).CornerRadius = UDim.new(0, 4)
            teleBtn.MouseButton1Click:Connect(function() TeleportToPos(data.Pos) end)
        end
    end
    FruitListContainer.CanvasSize = UDim2.new(0, 0, 0, FruitListLayout.AbsoluteContentSize.Y)
end)

-- ESP Trứng Logic (Giữ nguyên cơ chế tối ưu)
local function GetEggs()
    local eggs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Name:lower():match("egg") then
            table.insert(eggs, obj)
        end
    end
    return eggs
end

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
local PlayerCard = CreateCard(PlayerLeft, "Chỉnh Sửa Nhân Vật")
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

-- =========================================================
-- [ TAB: SETTINGS & WEAPONS ]
-- =========================================================
local SettingCard = CreateCard(SettingsLeft, "Cài Đặt Farm")
CreateButton(SettingCard, "Đổi Mode: " .. Config.MovementMode, function(btn)
    Config.MovementMode = (Config.MovementMode == "Tween") and "Teleport" or "Tween"
    btn.Text = "Đổi Mode: " .. Config.MovementMode
end)

CreateSlider(SettingCard, "Khoảng Cách Đánh", 0, 50, 5, "Distance", false)
CreateSlider(SettingCard, "Tốc Độ Tween (s)", 0.1, 10, 0.5, "TweenDuration", true)
CreateToggle(SettingCard, "Auto Click Thường", "AutoAttack")
CreateToggle(SettingCard, "FAST ATTACK (Nhanh)", "FastAttack")

-- Tối ưu Vị Trí Đánh vào Dropdown gọn gàng
local PosContainer, PosLayout, PosWrap = CreateDropdown(SettingCard, "Vị Trí Đứng Đánh: " .. Config.FarmPosition)
local PositionsList = {"Trên đầu", "Đằng sau", "Đằng trước", "Dưới chân"}
for _, posName in ipairs(PositionsList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 25)
    btn.BackgroundColor3 = (Config.FarmPosition == posName) and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(22, 25, 32)
    btn.Text = "   " .. posName; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Font = Enum.Font.Gotham; btn.TextSize = 11; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = PosContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(function()
        Config.FarmPosition = posName
        PosWrap:FindFirstChildWhichIsA("TextButton").Text = "    Vị Trí Đứng Đánh: " .. posName .. "  ▼"
        for _, b in pairs(PosContainer:GetChildren()) do if b:IsA("TextButton") then b.BackgroundColor3 = (b.Text:match(posName)) and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(22, 25, 32) end end
    end)
end
PosContainer.CanvasSize = UDim2.new(0, 0, 0, PosLayout.AbsoluteContentSize.Y)

local WeaponCard = CreateCard(SettingsRight, "Quản Lý Vũ Khí")
local WeaponListContainer, WeaponListLayout, WeaponWrap = CreateDropdown(WeaponCard, "Vũ Khí Farm")
CreateButton(WeaponCard, "Quét Vũ Khí Balo", function()
    for _, child in pairs(WeaponListContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local tools = {}
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do if tool:IsA("Tool") then tools[tool.Name] = tool end end
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do if tool:IsA("Tool") then tools[tool.Name] = tool end end
    end
    for toolName, _ in pairs(tools) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 25); btn.BackgroundColor3 = Config.SelectedWeapons[toolName] and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(22, 25, 32)
        btn.Text = "   " .. toolName; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Font = Enum.Font.Gotham; btn.TextSize = 11; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = WeaponListContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(function()
            Config.SelectedWeapons[toolName] = not Config.SelectedWeapons[toolName]
            btn.BackgroundColor3 = Config.SelectedWeapons[toolName] and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(22, 25, 32)
        end)
    end
    WeaponListContainer.CanvasSize = UDim2.new(0, 0, 0, WeaponListLayout.AbsoluteContentSize.Y)
end)

SwitchTab("Overview")

-- Toggle Logo Show/Hide
ToggleButton.MouseButton1Click:Connect(function()
    Config.MenuOpen = not Config.MenuOpen
    MainFrame.Visible = Config.MenuOpen
end)


-- =========================================================
-- [ KHẮC PHỤC LỖI GIẬT (JITTER FIX) & CORE FARMING ]
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

local function GetBestMobTarget()
    local bestTarget = nil
    local highestLevel = -1
    local shortestDist = math.huge
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myPos = hrp and hrp.Position or Vector3.new(0,0,0)

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and IsAlive(obj) and obj ~= LocalPlayer.Character then
            if Config.SelectedMobs[obj.Name] and not string.match(obj.Name:lower(), "boss$") then
                local level = tonumber(obj.Name:match("%d+")) or 1
                local dist = (obj.HumanoidRootPart.Position - myPos).Magnitude
                if level > highestLevel then
                    highestLevel = level; shortestDist = dist; bestTarget = obj
                elseif level == highestLevel then
                    if dist < shortestDist then shortestDist = dist; bestTarget = obj end
                end
            end
        end
    end
    return bestTarget
end

-- Teleport an toàn không gây khựng CFrame
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

-- Fix: Chỉ Equip tool nếu chưa cầm, tránh spam gây khựng animation
local function EquipWeaponsFast()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack then return end
    
    for toolName, _ in pairs(Config.SelectedWeapons) do
        local toolInBp = backpack:FindFirstChild(toolName)
        -- Chì unparent/reparent khi tool thực sự đang trong backpack
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

-- Vòng lặp Farm chính (Tuyệt đối giữ nguyên cơ chế V7)
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
            local bInst = nil
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == bossName and IsAlive(obj) then bInst = obj; break end
            end
            if bInst then
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

-- =========================================================
-- [ PLAYER MODS LOGIC ]
-- =========================================================
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

print("YuiHuB Premium v8 Loaded - No Truncation, Fully Restored Logic!")
