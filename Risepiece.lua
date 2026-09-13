-- =====================================================================
-- SUPERIOR AUTO FARM SCRIPT (RISE PIECE / GENERIC)
-- Tối ưu hóa hiệu năng, Không Memory Leak, UI Hoạt ảnh mượt mà
-- =====================================================================

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- [ CẤU HÌNH BIẾN TOÀN CỤC ]
local Config = {
    AutoFarm = false,
    AutoAttack = false,
    FarmPosition = "Trên đầu",
    SelectedWeapon = nil,
    SelectedMobs = {}, 
    MobListCache = {}, 
    TargetMob = nil,
    MenuOpen = false
}

local Positions = {
    ["Trên đầu"] = CFrame.new(0, 10, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Đằng sau"] = CFrame.new(0, 0, 5),
    ["Đằng trước"] = CFrame.new(0, 0, -5),
    ["Dưới chân"] = CFrame.new(0, -10, 0) * CFrame.Angles(math.rad(90), 0, 0)
}

-- [ KHỞI TẠO GIAO DIỆN ]
local UI_NAME = "RisePiece_PremiumUI"
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
ToggleButton.Text = "R"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 20
ToggleButton.Rotation = 45 -- Tạo hình thoi (đa giác)
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
ToggleLabel.Rotation = -45 -- Chữ đứng thẳng lại
ToggleLabel.Parent = ToggleButton

-- Khung Menu Chính (Hình Chữ Nhật)
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
    
    btn.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)
    
    return content
end

local MainTab = CreateTabButton("Main")
local SettingTab = CreateTabButton("Setting")

-- [ COMPONENTS HỖ TRỢ ]
local function CreateToggle(parent, text, configKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
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
    switchBg.BackgroundTransparency = 0.5 -- Trong suốt
    switchBg.Text = ""
    switchBg.Parent = frame
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = switchBg
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = UDim2.new(0, 2, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    circle.Parent = switchBg
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle
    
    local toggled = Config[configKey]
    
    local function UpdateUI()
        local goalPos = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        local goalCol = toggled and Color3.fromRGB(0, 255, 128) or Color3.fromRGB(200, 200, 200)
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = goalPos, BackgroundColor3 = goalCol}):Play()
    end
    
    switchBg.MouseButton1Click:Connect(function()
        toggled = not toggled
        Config[configKey] = toggled
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
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- [ XÂY DỰNG TAB: MAIN ]
CreateButton(MainTab, "Quét Quái Toàn Map", function()
    local oldList = Config.MobListCache
    Config.MobListCache = {}
    
    -- Thu thập mob, ưu tiên những con có Humanoid
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 and obj ~= LocalPlayer.Character then
            if not Config.MobListCache[obj.Name] then
                Config.MobListCache[obj.Name] = true
            end
        end
    end
    
    -- Giữ lại những mob đã lưu trong danh sách từ trước
    for name, _ in pairs(Config.SelectedMobs) do
        Config.MobListCache[name] = true
    end
    
    -- Cập nhật UI
    UpdateMobUIList()
end)

local MobListContainer = Instance.new("ScrollingFrame")
MobListContainer.Size = UDim2.new(1, 0, 0, 150)
MobListContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MobListContainer.ScrollBarThickness = 4
MobListContainer.Parent = MainTab

local MobListLayout = Instance.new("UIListLayout")
MobListLayout.SortOrder = Enum.SortOrder.LayoutOrder
MobListLayout.Parent = MobListContainer

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

CreateToggle(MainTab, "Bật/Tắt Auto Farm", "AutoFarm")

-- [ XÂY DỰNG TAB: SETTING ]
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

local posButtons = {}
for posName, _ in pairs(Positions) do
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = (Config.FarmPosition == posName) and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(30, 30, 35)
    btn.Text = posName
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = PosContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    posButtons[posName] = btn
    
    btn.MouseButton1Click:Connect(function()
        Config.FarmPosition = posName
        for n, b in pairs(posButtons) do
            b.BackgroundColor3 = (n == posName) and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(30, 30, 35)
        end
    end)
end

CreateToggle(SettingTab, "Bật/Tắt Auto Attack", "AutoAttack")

CreateButton(SettingTab, "Quét Vũ Khí", function()
    UpdateWeaponList()
end)

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
            UpdateWeaponList() -- Refresh UI
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
        TweenService:Create(MainFrame, info, {Size = UDim2.new(0, 500, 0, 320)}):Play()
    else
        ToggleLabel.Text = "MỞ"
        ToggleLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
        TweenService:Create(MainFrame, info, {Size = UDim2.new(0, 0, 0, 0)}):Play()
    end
end)

-- [ LOGIC AUTO FARM & LOGIC TÌM QUÁI THÔNG MINH ]

-- Hàm kiểm tra xem quái có phải Boss không (dựa vào HP hoặc UI)
local function IsBoss(mob)
    if mob.Name:lower():find("boss") then return true end
    if mob:FindFirstChild("Humanoid") and mob.Humanoid.MaxHealth >= 5000 then return true end
    for _, v in pairs(mob:GetDescendants()) do
        if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
            -- Nếu có thanh máu UI đính kèm thường là boss
            return true
        end
    end
    return false
end

-- Lấy Level từ tên quái (VD: "[Lv. 100] Bandit" -> 100)
local function GetMobLevel(mobName)
    local level = mobName:match("%d+")
    return level and tonumber(level) or 1
end

local function GetBestTarget()
    local bestTarget = nil
    local highestPriority = -1
    local highestLevel = -1
    local shortestDist = math.huge
    
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myPos = hrp and hrp.Position or Vector3.new(0,0,0)

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 and obj ~= LocalPlayer.Character then
            if Config.SelectedMobs[obj.Name] then
                local isBoss = IsBoss(obj)
                local level = GetMobLevel(obj.Name)
                local dist = (obj.HumanoidRootPart.Position - myPos).Magnitude
                
                -- Priority: Boss = 2, Thường = 1
                local priority = isBoss and 2 or 1
                
                if priority > highestPriority then
                    highestPriority = priority
                    highestLevel = level
                    shortestDist = dist
                    bestTarget = obj
                elseif priority == highestPriority then
                    if level > highestLevel then
                        highestLevel = level
                        shortestDist = dist
                        bestTarget = obj
                    elseif level == highestLevel then
                        -- Cùng level thì ưu tiên con gần nhất
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

local function EquipWeapon()
    if not Config.SelectedWeapon then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Nếu đang cầm tool khác thì cất đi (trừ phi đang cầm đúng tool)
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and currentTool.Name ~= Config.SelectedWeapon then
        currentTool.Parent = backpack
    end
    
    -- Trang bị tool
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
        tool:Activate()
        -- Dự phòng cho những game dùng Click
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0,0))
    end
end

-- Vòng lặp Farm Siêu Tốc (RunService)
RunService.Stepped:Connect(function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = LocalPlayer.Character.HumanoidRootPart
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    
    if Config.AutoFarm then
        Config.TargetMob = GetBestTarget()
        
        if Config.TargetMob and Config.TargetMob:FindFirstChild("HumanoidRootPart") then
            -- Chống rơi, chống kẹt (NoClip + Float)
            if humanoid then
                humanoid:ChangeState(11) -- Noclip an toàn
            end
            
            -- Tính toạ độ
            local offset = Positions[Config.FarmPosition] or Positions["Trên đầu"]
            local targetCFrame = Config.TargetMob.HumanoidRootPart.CFrame * offset
            
            -- Tween CFrame cho mượt tránh bị Kick do Teleport
            local dist = (rootPart.Position - targetCFrame.Position).Magnitude
            if dist > 50 then
                -- Nếu quá xa thì dùng Tween (Speed: ~300 studs/s)
                local tweenTime = dist / 300
                local tween = TweenService:Create(rootPart, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
                tween:Play()
            else
                -- Ở gần thì Teleport gắn liền luôn để farm
                rootPart.CFrame = targetCFrame
            end
        end
    end
    
    if Config.AutoFarm or Config.AutoAttack then
        if Config.TargetMob and Config.TargetMob:FindFirstChild("Humanoid") and Config.TargetMob.Humanoid.Health > 0 then
            EquipWeapon()
            Attack()
        elseif not Config.AutoFarm and Config.AutoAttack then
            -- Chỉ bật AutoAttack nhưng không AutoFarm (tự đánh chỗ đang đứng)
            EquipWeapon()
            Attack()
        end
    end
end)

-- Tạo Anti-AFK để không bị văng game khi cắm chuột
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

print("Rise Piece Superior Auto Farm Loaded. By Senior Luau Expert.")
