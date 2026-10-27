--[================================================================[
    PROJECT: APEX_SYS // STANDALONE GUI LIBRARY ENGINE (V3.6 PLUS)
    DESIGN: Precision Terminal HUD & Advanced Modular Framework
    BASE:   APEX_SYS V3.5 (core visual style preserved)
    EXTENSIONS:
        - CreateButton
        - CreateSectionLabel
        - CreateListCard (dynamic scrollable list)
        - Component handles: Set/Get/SetColor
        - Fixed color picker initialization + RGB input handling
        - Color popup manager (closes on tab switch / hide)
        - Unload callbacks for user scripts
        - Keybind listening guard
    NOTE: This is a separate library file. The original V3.5 file is not modified.
]================================================================]--

-- // Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- // Variables
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ConfigFile = "ApexLibrary_Config.json"

-- // Cleanup existing instances if re-running
if PlayerGui:FindFirstChild("ApexSystemControl") then
    PlayerGui.ApexSystemControl:Destroy()
end
if PlayerGui:FindFirstChild("ApexMobileButtonGui") then
    PlayerGui.ApexMobileButtonGui:Destroy()
end

-- // Config System Logic (Safeguarded with pcall)
local function SaveConfig(configData)
    pcall(function()
        if writefile then
            writefile(ConfigFile, HttpService:JSONEncode(configData))
        end
    end)
end

local function LoadConfig()
    local success, result = pcall(function()
        if isfile and isfile(ConfigFile) then
            return HttpService:JSONDecode(readfile(ConfigFile))
        end
    end)
    if success and result then
        return result
    end
    return nil
end

local loadedConfigData = LoadConfig()

-- // Shared visual helpers
local function applyToggleVisual(thumb, stroke, enabled, accent)
    local targetPos = enabled and UDim2.new(1, -21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    local thumbColor = enabled and accent or Color3.fromRGB(110, 120, 135)
    local strokeColor = enabled and accent or Color3.fromRGB(45, 45, 58)
    TweenService:Create(thumb, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Position = targetPos,
        BackgroundColor3 = thumbColor
    }):Play()
    TweenService:Create(stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Color = strokeColor
    }):Play()
end

local function applySideToggleVisual(thumb, stroke, enabled, accent)
    local targetPos = enabled and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    local thumbColor = enabled and accent or Color3.fromRGB(110, 120, 135)
    local strokeColor = enabled and accent or Color3.fromRGB(45, 45, 58)
    TweenService:Create(thumb, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Position = targetPos,
        BackgroundColor3 = thumbColor
    }):Play()
    TweenService:Create(stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Color = strokeColor
    }):Play()
end

-- =================================================================
-- APEX GUI LIBRARY ENGINE IMPLEMENTATION
-- =================================================================

local ApexLibrary = {}
ApexLibrary.__index = ApexLibrary
ApexLibrary.Version = "APEX_SYS V3.6 PLUS"

function ApexLibrary.new(config)
    local self = setmetatable({}, ApexLibrary)
    config = config or {}

    self.Title = config.Title or "APEX // LIBRARY"
    self.SaveFileName = config.SaveFileName or ConfigFile
    self.CurrentHideKey = config.HideKey or Enum.KeyCode.P
    self.IsButtonLocked = false
    self.LoadedButtonPos = UDim2.new(0, 24, 0, 100)
    self.AccentColor = config.AccentColor or Color3.fromRGB(0, 160, 255)
    self.MobileButtonRef = nil
    self.AccentUpdateCallbacks = {}
    self.ColorPopups = {}
    self.UnloadCallbacks = {}
    self.IsListeningForKey = false
    self.IsUnloaded = false

    if type(loadedConfigData) == "table" then
        if loadedConfigData.AccentColor then
            self.AccentColor = Color3.fromRGB(
                loadedConfigData.AccentColor.R or 0,
                loadedConfigData.AccentColor.G or 160,
                loadedConfigData.AccentColor.B or 255
            )
        end
        if loadedConfigData.HideKey then
            pcall(function()
                local key = Enum.KeyCode[loadedConfigData.HideKey]
                if key then
                    self.CurrentHideKey = key
                end
            end)
        end
        if loadedConfigData.IsButtonLocked ~= nil then
            self.IsButtonLocked = loadedConfigData.IsButtonLocked
        end
        if loadedConfigData.ButtonPosition then
            pcall(function()
                local p = loadedConfigData.ButtonPosition
                self.LoadedButtonPos = UDim2.new(
                    p.X.Scale or 0,
                    p.X.Offset or 24,
                    p.Y.Scale or 0,
                    p.Y.Offset or 100
                )
            end)
        end
    end

    self:BuildGUI()
    return self
end

function ApexLibrary:RegisterAccentListener(callback)
    table.insert(self.AccentUpdateCallbacks, callback)
end

function ApexLibrary:RegisterColorPopup(popup)
    table.insert(self.ColorPopups, popup)
end

function ApexLibrary:RegisterUnloadCallback(callback)
    table.insert(self.UnloadCallbacks, callback)
end

function ApexLibrary:CloseColorPopupsExcept(exceptPopup)
    for _, popup in ipairs(self.ColorPopups) do
        if popup and popup.Parent and popup ~= exceptPopup then
            popup.Visible = false
        end
    end
end

function ApexLibrary:CloseColorPopups()
    self:CloseColorPopupsExcept(nil)
end

function ApexLibrary:GetAccentColor()
    return self.AccentColor
end

function ApexLibrary:SetAccentColor(newColor)
    if typeof(newColor) ~= "Color3" then
        return
    end
    self.AccentColor = newColor
    for _, callback in ipairs(self.AccentUpdateCallbacks) do
        pcall(callback, newColor)
    end
    self:SaveSettings()
end

function ApexLibrary:SaveSettings()
    SaveConfig({
        AccentColor = {
            R = math.floor(self.AccentColor.R * 255 + 0.5),
            G = math.floor(self.AccentColor.G * 255 + 0.5),
            B = math.floor(self.AccentColor.B * 255 + 0.5)
        },
        HideKey = self.CurrentHideKey.Name,
        IsButtonLocked = self.IsButtonLocked,
        ButtonPosition = self.MobileButtonRef and {
            X = {
                Scale = self.MobileButtonRef.Position.X.Scale,
                Offset = self.MobileButtonRef.Position.X.Offset
            },
            Y = {
                Scale = self.MobileButtonRef.Position.Y.Scale,
                Offset = self.MobileButtonRef.Position.Y.Offset
            }
        } or {
            X = { Scale = 0, Offset = 24 },
            Y = { Scale = 0, Offset = 100 }
        }
    })
end

function ApexLibrary:BuildGUI()
    -- If the class table is reused in the same executor session, make sure a
    -- previous ScreenGui/mobile button cannot stack on top of the new one.
    local oldScreen = PlayerGui:FindFirstChild("ApexSystemControl")
    if oldScreen then
        oldScreen:Destroy()
    end
    local oldMobile = PlayerGui:FindFirstChild("ApexMobileButtonGui")
    if oldMobile then
        oldMobile:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ApexSystemControl"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999999
    ScreenGui.Parent = PlayerGui

    local MainFrame = Instance.new("CanvasGroup")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 420, 0, 500)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
    MainFrame.BorderSizePixel = 0
    MainFrame.GroupTransparency = 0
    MainFrame.Parent = ScreenGui

    -- Keep the fixed layout usable on phones and small windows by scaling the
    -- whole window instead of clipping the footer.
    local UIScale = Instance.new("UIScale")
    UIScale.Parent = MainFrame
    local function UpdateUIScale()
        if not UIScale or not UIScale.Parent then
            return
        end
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local scale = math.min((viewport.X - 24) / 420, (viewport.Y - 24) / 500)
        UIScale.Scale = math.min(math.max(scale, 0.6), 1)
    end
    UpdateUIScale()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateUIScale)
    end

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(45, 45, 58)
    MainStroke.Thickness = 1
    MainStroke.Parent = MainFrame

    -- Header Bar
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Name = "HeaderBar"
    HeaderBar.Size = UDim2.new(1, 0, 0, 42)
    HeaderBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    HeaderBar.BorderSizePixel = 0
    HeaderBar.Parent = MainFrame

    local HeaderStroke = Instance.new("UIStroke")
    HeaderStroke.Color = Color3.fromRGB(45, 45, 58)
    HeaderStroke.Thickness = 1
    HeaderStroke.Parent = HeaderBar

    local AccentBox = Instance.new("Frame")
    AccentBox.Name = "AccentBox"
    AccentBox.Size = UDim2.new(0, 10, 0, 10)
    AccentBox.Position = UDim2.new(0, 14, 0.5, -5)
    AccentBox.BackgroundColor3 = self.AccentColor
    AccentBox.BorderSizePixel = 0
    AccentBox.Parent = HeaderBar

    self:RegisterAccentListener(function(col)
        AccentBox.BackgroundColor3 = col
    end)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -100, 1, 0)
    TitleLabel.Position = UDim2.new(0, 32, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = self.Title
    TitleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = HeaderBar

    -- Horizontal Scrolling Tab Bar Area
    local TabBar = Instance.new("ScrollingFrame")
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(1, 0, 0, 36)
    TabBar.Position = UDim2.new(0, 0, 0, 42)
    TabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    TabBar.BorderSizePixel = 0
    TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    TabBar.ScrollingDirection = Enum.ScrollingDirection.X
    TabBar.ScrollBarThickness = 2
    TabBar.ScrollBarImageColor3 = Color3.fromRGB(50, 60, 75)
    TabBar.Parent = MainFrame

    local TabListLayout = Instance.new("UIListLayout", TabBar)
    TabListLayout.FillDirection = Enum.FillDirection.Horizontal
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 0)

    local TabStroke = Instance.new("UIStroke")
    TabStroke.Color = Color3.fromRGB(45, 45, 58)
    TabStroke.Thickness = 1
    TabStroke.Parent = TabBar

    -- Section Title Header
    local SectionHeader = Instance.new("TextLabel")
    SectionHeader.Size = UDim2.new(1, -32, 0, 24)
    SectionHeader.Position = UDim2.new(0, 16, 0, 92)
    SectionHeader.BackgroundTransparency = 1
    SectionHeader.Font = Enum.Font.GothamBold
    SectionHeader.Text = "GENERAL"
    SectionHeader.TextColor3 = Color3.fromRGB(150, 150, 165)
    SectionHeader.TextSize = 12
    SectionHeader.TextXAlignment = Enum.TextXAlignment.Left
    SectionHeader.Parent = MainFrame

    -- Footer & Kill Switch
    local FooterBar = Instance.new("Frame")
    FooterBar.Size = UDim2.new(1, 0, 0, 32)
    FooterBar.Position = UDim2.new(0, 0, 1, -32)
    FooterBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    FooterBar.BorderSizePixel = 0
    FooterBar.Parent = MainFrame

    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(0.5, -16, 1, 0)
    StatusText.Position = UDim2.new(0, 16, 0, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Font = Enum.Font.GothamMedium
    StatusText.Text = "STATUS: ACTIVE"
    StatusText.TextColor3 = Color3.fromRGB(120, 135, 155)
    StatusText.TextSize = 11
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.Parent = FooterBar

    local KillButton = Instance.new("TextButton")
    KillButton.Size = UDim2.new(1, -32, 0, 34)
    KillButton.Position = UDim2.new(0, 16, 1, -74)
    KillButton.BackgroundColor3 = Color3.fromRGB(45, 20, 25)
    KillButton.AutoButtonColor = false
    KillButton.Font = Enum.Font.GothamBold
    KillButton.Text = "UNLOAD LIBRARY"
    KillButton.TextColor3 = Color3.fromRGB(255, 80, 80)
    KillButton.TextSize = 12
    KillButton.Parent = MainFrame

    local KillCorner = Instance.new("UICorner")
    KillCorner.CornerRadius = UDim.new(0, 3)
    KillCorner.Parent = KillButton

    KillButton.Activated:Connect(function()
        if self.IsUnloaded then
            return
        end
        self.IsUnloaded = true
        for _, callback in ipairs(self.UnloadCallbacks) do
            pcall(callback)
        end
        self:CloseColorPopups()
        ScreenGui:Destroy()
        local mobile = PlayerGui:FindFirstChild("ApexMobileButtonGui")
        if mobile then
            mobile:Destroy()
        end
    end)

    -- Draggable Window Logic
    local dragging, dragStart, startPos = false, nil, nil
    HeaderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if self.IsUnloaded or not MainFrame.Parent then
            return
        end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    self.ScreenGui = ScreenGui
    self.MainFrame = MainFrame
    self.TabBar = TabBar
    self.SectionHeader = SectionHeader
    self.TabCount = 0
    self.TabButtonsList = {}
    self.IsUIVisible = true
    self.IsAnimating = false

    function self:SetVisible(visible)
        if self.IsUnloaded or not self.ScreenGui or not self.ScreenGui.Parent then
            return
        end
        if self.IsAnimating then
            return
        end
        self.IsAnimating = true

        if visible then
            MainFrame.Visible = true
            local startPos = self.MobileButtonRef and UDim2.new(
                0,
                self.MobileButtonRef.AbsolutePosition.X + 27,
                0,
                self.MobileButtonRef.AbsolutePosition.Y + 27
            ) or UDim2.new(0.5, 0, 0.5, 0)
            MainFrame.Position = startPos
            MainFrame.Size = UDim2.new(0, 54, 0, 54)
            MainFrame.GroupTransparency = 1

            local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 420, 0, 500),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                GroupTransparency = 0
            })
            tween:Play()
            tween.Completed:Wait()
            self.IsUIVisible = true
            self.IsAnimating = false
        else
            self:CloseColorPopups()
            local targetPos = self.MobileButtonRef and UDim2.new(
                0,
                self.MobileButtonRef.AbsolutePosition.X + 27,
                0,
                self.MobileButtonRef.AbsolutePosition.Y + 27
            ) or UDim2.new(0.5, 0, 0.5, 0)
            local tween = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 54, 0, 54),
                Position = targetPos,
                GroupTransparency = 1
            })
            tween:Play()
            tween.Completed:Wait()
            MainFrame.Visible = false
            self.IsUIVisible = false
            self.IsAnimating = false
        end
    end

    -- Keybind Toggle (PC)
    if not UserInputService.TouchEnabled then
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if self.IsUnloaded then
                return
            end
            if not gameProcessed and not self.IsListeningForKey and input.KeyCode == self.CurrentHideKey then
                self:SetVisible(not self.IsUIVisible)
            end
        end)
    end

    -- Mobile T-Rex Claw Button Setup
    if UserInputService.TouchEnabled then
        local MobileScreenGui = Instance.new("ScreenGui")
        MobileScreenGui.Name = "ApexMobileButtonGui"
        MobileScreenGui.ResetOnSpawn = false
        MobileScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        MobileScreenGui.DisplayOrder = 999999
        MobileScreenGui.Parent = PlayerGui

        local MobileButton = Instance.new("TextButton")
        MobileButton.Name = "MobileClawToggle"
        MobileButton.Size = UDim2.new(0, 54, 0, 54)
        MobileButton.Position = self.LoadedButtonPos
        MobileButton.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        MobileButton.AutoButtonColor = false
        MobileButton.Text = ""
        MobileButton.Parent = MobileScreenGui

        self.MobileButtonRef = MobileButton

        local MobileStroke = Instance.new("UIStroke")
        MobileStroke.Color = self.AccentColor
        MobileStroke.Thickness = 1.5
        MobileStroke.Parent = MobileButton

        local MobileCorner = Instance.new("UICorner")
        MobileCorner.CornerRadius = UDim.new(0, 6)
        MobileCorner.Parent = MobileButton

        local ClawContainer = Instance.new("Frame")
        ClawContainer.Size = UDim2.new(1, 0, 1, 0)
        ClawContainer.BackgroundTransparency = 1
        ClawContainer.Parent = MobileButton

        local scratches = {}
        local function createScratch(offX, height, rotation)
            local scratch = Instance.new("Frame")
            scratch.Size = UDim2.new(0, 3, 0, height)
            scratch.Position = UDim2.new(0.5, offX, 0.5, 0)
            scratch.AnchorPoint = Vector2.new(0.5, 0.5)
            scratch.BackgroundColor3 = self.AccentColor
            scratch.BorderSizePixel = 0
            scratch.Rotation = rotation
            scratch.Parent = ClawContainer
            Instance.new("UICorner", scratch).CornerRadius = UDim.new(1, 0)
            table.insert(scratches, scratch)
        end
        createScratch(-9, 28, -35)
        createScratch(0, 38, -35)
        createScratch(9, 30, -35)

        self:RegisterAccentListener(function(col)
            MobileStroke.Color = col
            for _, scratch in ipairs(scratches) do
                scratch.BackgroundColor3 = col
            end
        end)

        local mobileDragging, mobileStart, mobilePos, moved = false, nil, nil, 0
        MobileButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                mobileDragging = true
                mobileStart = input.Position
                mobilePos = MobileButton.Position
                moved = 0
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if self.IsUnloaded or not MobileButton.Parent then
                return
            end
            if mobileDragging and not self.IsButtonLocked and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - mobileStart
                moved = delta.Magnitude
                MobileButton.Position = UDim2.new(
                    mobilePos.X.Scale,
                    mobilePos.X.Offset + delta.X,
                    mobilePos.Y.Scale,
                    mobilePos.Y.Offset + delta.Y
                )
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if self.IsUnloaded or not MobileButton.Parent then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if mobileDragging then
                    if moved < 6 then
                        self:SetVisible(not self.IsUIVisible)
                    else
                        self:SaveSettings()
                    end
                end
                mobileDragging = false
            end
        end)
    end
end

-- // Extended Color Picker Popup
local function CreateColorPopup(parentLib, name, defaultColor, callback, previewButton)
    local appliedColor = defaultColor
    if typeof(appliedColor) ~= "Color3" then
        appliedColor = parentLib.AccentColor
    end
    local selectedColor = appliedColor

    local Popup = Instance.new("Frame", parentLib.ScreenGui)
    Popup.Name = "ColorPopup_" .. tostring(name)
    Popup.Size = UDim2.new(0, 260, 0, 265)
    Popup.Position = UDim2.new(0.5, -130, 0.5, -132)
    Popup.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    Popup.Visible = false
    Popup.ZIndex = 60
    Instance.new("UICorner", Popup).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", Popup).Color = Color3.fromRGB(45, 45, 58)
    parentLib:RegisterColorPopup(Popup)

    local pTitle = Instance.new("TextLabel", Popup)
    pTitle.Size = UDim2.new(1, -48, 0, 24)
    pTitle.Position = UDim2.new(0, 12, 0, 8)
    pTitle.BackgroundTransparency = 1
    pTitle.Font = Enum.Font.GothamBold
    pTitle.Text = "PALETTE // " .. tostring(name)
    pTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
    pTitle.TextSize = 11
    pTitle.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", Popup)
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -28, 0, 8)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    CloseBtn.AutoButtonColor = false
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 195)
    CloseBtn.TextSize = 11
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", CloseBtn).Color = Color3.fromRGB(45, 45, 58)

    local SVBox = Instance.new("TextButton", Popup)
    SVBox.Size = UDim2.new(1, -24, 0, 100)
    SVBox.Position = UDim2.new(0, 12, 0, 34)
    SVBox.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    SVBox.AutoButtonColor = false
    SVBox.Text = ""
    Instance.new("UICorner", SVBox).CornerRadius = UDim.new(0, 4)

    local WhiteOverlay = Instance.new("Frame", SVBox)
    WhiteOverlay.Size = UDim2.new(1, 0, 1, 0)
    WhiteOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    WhiteOverlay.BorderSizePixel = 0
    Instance.new("UICorner", WhiteOverlay).CornerRadius = UDim.new(0, 4)
    local whiteGradient = Instance.new("UIGradient", WhiteOverlay)
    whiteGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })

    local BlackOverlay = Instance.new("Frame", SVBox)
    BlackOverlay.Size = UDim2.new(1, 0, 1, 0)
    BlackOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BlackOverlay.BorderSizePixel = 0
    Instance.new("UICorner", BlackOverlay).CornerRadius = UDim.new(0, 4)
    local blackGradient = Instance.new("UIGradient", BlackOverlay)
    blackGradient.Rotation = 90
    blackGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    })

    local SVHandle = Instance.new("Frame", SVBox)
    SVHandle.Size = UDim2.new(0, 12, 0, 12)
    SVHandle.AnchorPoint = Vector2.new(0.5, 0.5)
    SVHandle.Position = UDim2.new(1, 0, 0, 0)
    SVHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", SVHandle).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", SVHandle).Color = Color3.fromRGB(0, 0, 0)

    local HueBar = Instance.new("TextButton", Popup)
    HueBar.Size = UDim2.new(1, -24, 0, 14)
    HueBar.Position = UDim2.new(0, 12, 0, 142)
    HueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HueBar.AutoButtonColor = false
    HueBar.Text = ""
    Instance.new("UICorner", HueBar).CornerRadius = UDim.new(1, 0)

    local hueGradient = Instance.new("UIGradient", HueBar)
    hueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 0, 0))
    })

    local HueHandle = Instance.new("Frame", HueBar)
    HueHandle.Size = UDim2.new(0, 6, 0, 18)
    HueHandle.AnchorPoint = Vector2.new(0.5, 0.5)
    HueHandle.Position = UDim2.new(0, 0, 0.5, 0)
    HueHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", HueHandle).CornerRadius = UDim.new(0, 2)
    Instance.new("UIStroke", HueHandle).Color = Color3.fromRGB(0, 0, 0)

    local function createRGBInput(labelName, posX)
        local label = Instance.new("TextLabel", Popup)
        label.Size = UDim2.new(0, 72, 0, 14)
        label.Position = UDim2.new(0, posX, 0, 164)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamMedium
        label.Text = labelName
        label.TextColor3 = Color3.fromRGB(150, 150, 165)
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left

        local box = Instance.new("TextBox", Popup)
        box.Size = UDim2.new(0, 72, 0, 24)
        box.Position = UDim2.new(0, posX, 0, 180)
        box.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        box.Font = Enum.Font.GothamMedium
        box.Text = "255"
        box.TextColor3 = Color3.fromRGB(240, 245, 255)
        box.TextSize = 12
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", box).Color = Color3.fromRGB(45, 45, 58)
        return box
    end

    local rBox = createRGBInput("R", 12)
    local gBox = createRGBInput("G", 94)
    local bBox = createRGBInput("B", 176)

    local ApplyBtn = Instance.new("TextButton", Popup)
    ApplyBtn.Size = UDim2.new(1, -24, 0, 32)
    ApplyBtn.Position = UDim2.new(0, 12, 0, 214)
    ApplyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
    ApplyBtn.AutoButtonColor = false
    ApplyBtn.Font = Enum.Font.GothamBold
    ApplyBtn.Text = "APPLY COLOR"
    ApplyBtn.TextColor3 = parentLib.AccentColor
    ApplyBtn.TextSize = 12
    Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 4)
    local applyStroke = Instance.new("UIStroke", ApplyBtn)
    applyStroke.Color = parentLib.AccentColor

    parentLib:RegisterAccentListener(function(col)
        ApplyBtn.TextColor3 = col
        applyStroke.Color = col
    end)

    local currentHue, currentSat, currentVal = appliedColor:ToHSV()

    local function setHSVFromColor(color)
        currentHue, currentSat, currentVal = color:ToHSV()
        SVBox.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
        SVHandle.Position = UDim2.new(currentSat, 0, 1 - currentVal, 0)
        HueHandle.Position = UDim2.new(currentHue, 0, 0.5, 0)
    end

    local function updatePreview(color)
        selectedColor = color
        if previewButton and previewButton.Parent then
            previewButton.BackgroundColor3 = color
        end
        rBox.Text = tostring(math.floor(color.R * 255 + 0.5))
        gBox.Text = tostring(math.floor(color.G * 255 + 0.5))
        bBox.Text = tostring(math.floor(color.B * 255 + 0.5))
    end

    local function updateFromHSV()
        updatePreview(Color3.fromHSV(currentHue, currentSat, currentVal))
    end

    local function applyRGBInputs()
        local r = math.clamp(tonumber(rBox.Text) or math.floor(selectedColor.R * 255 + 0.5), 0, 255)
        local g = math.clamp(tonumber(gBox.Text) or math.floor(selectedColor.G * 255 + 0.5), 0, 255)
        local b = math.clamp(tonumber(bBox.Text) or math.floor(selectedColor.B * 255 + 0.5), 0, 255)
        local color = Color3.fromRGB(r, g, b)
        updatePreview(color)
        setHSVFromColor(color)
    end

    rBox.FocusLost:Connect(applyRGBInputs)
    gBox.FocusLost:Connect(applyRGBInputs)
    bBox.FocusLost:Connect(applyRGBInputs)

    local function updateHueFromInput(input)
        local pos = math.clamp((input.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
        currentHue = pos
        HueHandle.Position = UDim2.new(pos, 0, 0.5, 0)
        SVBox.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
        updateFromHSV()
    end

    local function updateSVFromInput(input)
        local xPos = math.clamp((input.Position.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
        local yPos = math.clamp((input.Position.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
        currentSat = xPos
        currentVal = 1 - yPos
        SVHandle.Position = UDim2.new(xPos, 0, yPos, 0)
        updateFromHSV()
    end

    local hueDragging, svDragging = false, false
    HueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
            updateHueFromInput(input)
        end
    end)
    SVBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = true
            updateSVFromInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not Popup.Parent or not Popup.Visible then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if hueDragging then
                updateHueFromInput(input)
            elseif svDragging then
                updateSVFromInput(input)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = false
            svDragging = false
        end
    end)

    setHSVFromColor(appliedColor)
    updatePreview(appliedColor)

    CloseBtn.Activated:Connect(function()
        Popup.Visible = false
    end)

    ApplyBtn.Activated:Connect(function()
        appliedColor = selectedColor
        Popup.Visible = false
        if previewButton and previewButton.Parent then
            previewButton.BackgroundColor3 = appliedColor
        end
        if callback then
            pcall(callback, appliedColor)
        end
    end)

    if previewButton then
        previewButton.Activated:Connect(function()
            if Popup.Visible then
                Popup.Visible = false
            else
                setHSVFromColor(appliedColor)
                updatePreview(appliedColor)
                parentLib:CloseColorPopupsExcept(Popup)
                Popup.Visible = true
            end
        end)
    end

    Popup:GetPropertyChangedSignal("Visible"):Connect(function()
        if not Popup.Visible then
            selectedColor = appliedColor
            if previewButton and previewButton.Parent then
                previewButton.BackgroundColor3 = appliedColor
            end
            setHSVFromColor(appliedColor)
        end
    end)

    local API = {}
    function API:SetColor(color)
        if typeof(color) ~= "Color3" then
            return
        end
        appliedColor = color
        selectedColor = color
        if previewButton and previewButton.Parent then
            previewButton.BackgroundColor3 = color
        end
        if Popup.Visible then
            setHSVFromColor(color)
        end
    end
    function API:GetColor()
        return appliedColor
    end
    function API:Open()
        setHSVFromColor(appliedColor)
        updatePreview(appliedColor)
        parentLib:CloseColorPopupsExcept(Popup)
        Popup.Visible = true
    end
    function API:Close()
        Popup.Visible = false
    end

    return API
end

function ApexLibrary:CreateTab(tabName, sectionTitle)
    local parentLib = self

    local container = Instance.new("ScrollingFrame")
    container.Size = UDim2.new(1, -32, 0, 260)
    container.Position = UDim2.new(0, 16, 0, 122)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.CanvasSize = UDim2.new(0, 0, 0, 0)
    container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    container.ScrollBarThickness = 2
    container.ScrollBarImageColor3 = Color3.fromRGB(50, 60, 75)
    container.Visible = (self.TabCount == 0)
    container.Parent = self.MainFrame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = container

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 120, 1, 0)
    button.BackgroundColor3 = (self.TabCount == 0) and Color3.fromRGB(30, 30, 40) or Color3.fromRGB(20, 20, 28)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamMedium
    button.Text = tabName
    button.TextColor3 = (self.TabCount == 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 165)
    button.TextSize = 11
    button.LayoutOrder = self.TabCount
    button.Parent = self.TabBar

    local activeLine = Instance.new("Frame")
    activeLine.Size = UDim2.new(1, 0, 0, 2)
    activeLine.Position = UDim2.new(0, 0, 0, 0)
    activeLine.BackgroundColor3 = parentLib.AccentColor
    activeLine.BorderSizePixel = 0
    activeLine.Visible = (self.TabCount == 0)
    activeLine.Parent = button

    parentLib:RegisterAccentListener(function(col)
        if activeLine.Visible then
            activeLine.BackgroundColor3 = col
        end
    end)

    local sectionHeader = self.SectionHeader
    button.Activated:Connect(function()
        for _, tab in pairs(parentLib.TabButtonsList) do
            tab.Button.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
            tab.Button.TextColor3 = Color3.fromRGB(150, 150, 165)
            tab.Line.Visible = false
            tab.Container.Visible = false
        end
        button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        activeLine.BackgroundColor3 = parentLib.AccentColor
        activeLine.Visible = true
        container.Visible = true
        sectionHeader.Text = sectionTitle or "GENERAL"
        parentLib:CloseColorPopups()
    end)

    table.insert(self.TabButtonsList, {
        Button = button,
        Line = activeLine,
        Container = container
    })

    -- The first tab is selected immediately. Keep the section header in sync
    -- without requiring the user to click the tab first.
    if self.TabCount == 0 then
        self.SectionHeader.Text = sectionTitle or "GENERAL"
    end

    self.TabCount = self.TabCount + 1

    local TabObj = {}

    function TabObj:GetContainer()
        return container
    end

    -- Section label inside a tab
    function TabObj:CreateSectionLabel(text)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 22)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.Text = tostring(text)
        label.TextColor3 = Color3.fromRGB(150, 150, 165)
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = container
        return label
    end

    -- Action button card
    function TabObj:CreateButton(name, description, callback)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 64)
        Card.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
        Card.BorderSizePixel = 0
        Card.Parent = container
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", Card).Color = Color3.fromRGB(45, 45, 58)

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -112, 0, 22)
        title.Position = UDim2.new(0, 14, 0, 10)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = name
        title.TextColor3 = Color3.fromRGB(240, 245, 255)
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", Card)
        desc.Size = UDim2.new(1, -112, 0, 26)
        desc.Position = UDim2.new(0, 14, 0, 32)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.GothamMedium
        desc.Text = description
        desc.TextColor3 = Color3.fromRGB(140, 140, 155)
        desc.TextSize = 10
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top

        local action = Instance.new("TextButton", Card)
        action.Size = UDim2.new(0, 84, 0, 26)
        action.Position = UDim2.new(1, -98, 0.5, -13)
        action.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        action.AutoButtonColor = false
        action.Font = Enum.Font.GothamBold
        action.Text = "RUN"
        action.TextColor3 = parentLib.AccentColor
        action.TextSize = 11
        Instance.new("UICorner", action).CornerRadius = UDim.new(0, 4)
        local actionStroke = Instance.new("UIStroke", action)
        actionStroke.Color = parentLib.AccentColor

        parentLib:RegisterAccentListener(function(col)
            action.TextColor3 = col
            actionStroke.Color = col
        end)

        action.Activated:Connect(function()
            if callback then
                pcall(callback)
            end
        end)

        local API = {}
        function API:SetText(text)
            action.Text = tostring(text)
        end
        function API:SetEnabled(enabled)
            action.Active = enabled and true or false
            action.TextTransparency = enabled and 0 or 0.5
        end
        return API
    end

    -- Dynamic scrollable list card
    function TabObj:CreateListCard(titleText, description, height)
        local cardHeight = height or 200
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, cardHeight)
        Card.BackgroundColor3 = Color3.fromRGB(22, 22, 29)
        Card.BorderSizePixel = 0
        Card.Parent = container
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", Card).Color = Color3.fromRGB(45, 45, 58)

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -24, 0, 20)
        title.Position = UDim2.new(0, 12, 0, 8)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = titleText
        title.TextColor3 = parentLib.AccentColor
        title.TextSize = 12
        title.TextXAlignment = Enum.TextXAlignment.Left

        parentLib:RegisterAccentListener(function(col)
            title.TextColor3 = col
        end)

        local desc
        if description and description ~= "" then
            desc = Instance.new("TextLabel", Card)
            desc.Size = UDim2.new(1, -24, 0, 14)
            desc.Position = UDim2.new(0, 12, 0, 27)
            desc.BackgroundTransparency = 1
            desc.Font = Enum.Font.GothamMedium
            desc.Text = description
            desc.TextColor3 = Color3.fromRGB(135, 140, 155)
            desc.TextSize = 10
            desc.TextXAlignment = Enum.TextXAlignment.Left
        end

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, -16, 1, -52)
        scroll.Position = UDim2.new(0, 8, 0, 46)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ScrollBarThickness = 2
        scroll.ScrollBarImageColor3 = Color3.fromRGB(50, 60, 75)
        scroll.Parent = Card

        local listLayout = Instance.new("UIListLayout", scroll)
        listLayout.Padding = UDim.new(0, 4)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local padding = Instance.new("UIPadding", scroll)
        padding.PaddingBottom = UDim.new(0, 8)

        local order = 0
        local API = {}

        function API:Clear()
            for _, child in ipairs(scroll:GetChildren()) do
                if child:IsA("GuiObject") then
                    child:Destroy()
                end
            end
            order = 0
        end

        function API:AddLabel(text, color, labelHeight)
            order = order + 1
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamMedium
            label.Text = tostring(text)
            label.TextColor3 = color or Color3.fromRGB(180, 185, 200)
            label.TextSize = 11
            label.TextWrapped = true
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextYAlignment = Enum.TextYAlignment.Top
            label.LayoutOrder = order
            if labelHeight then
                label.Size = UDim2.new(1, -8, 0, labelHeight)
                label.AutomaticSize = Enum.AutomaticSize.None
            else
                label.Size = UDim2.new(1, -8, 0, 0)
                label.AutomaticSize = Enum.AutomaticSize.Y
            end
            label.Parent = scroll
            return label
        end

        function API:AddButton(text, color, callback)
            order = order + 1
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -8, 0, 28)
            button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            button.AutoButtonColor = false
            button.Font = Enum.Font.GothamMedium
            button.Text = tostring(text)
            button.TextColor3 = color or Color3.fromRGB(220, 225, 235)
            button.TextSize = 11
            button.LayoutOrder = order
            button.Parent = scroll
            Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)
            local stroke = Instance.new("UIStroke", button)
            stroke.Color = color or Color3.fromRGB(60, 60, 75)
            stroke.Transparency = 0.45

            button.MouseEnter:Connect(function()
                if not button.Parent then
                    return
                end
                TweenService:Create(button, TweenInfo.new(0.12), {
                    BackgroundColor3 = Color3.fromRGB(40, 40, 52)
                }):Play()
            end)
            button.MouseLeave:Connect(function()
                if not button.Parent then
                    return
                end
                TweenService:Create(button, TweenInfo.new(0.12), {
                    BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                }):Play()
            end)
            button.Activated:Connect(function()
                if callback then
                    pcall(callback)
                end
            end)
            return button
        end

        function API:AddSpacer(spacing)
            order = order + 1
            local spacer = Instance.new("Frame")
            spacer.Size = UDim2.new(1, 0, 0, spacing or 4)
            spacer.BackgroundTransparency = 1
            spacer.LayoutOrder = order
            spacer.Parent = scroll
            return spacer
        end

        function API:GetScrollFrame()
            return scroll
        end

        return API
    end

    -- Standalone Number Input Component (Without a toggle switch)
    function TabObj:CreateInputCard(name, description, defaultValue, callback)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 64)
        Card.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
        Card.BorderSizePixel = 0
        Card.Parent = container
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", Card).Color = Color3.fromRGB(45, 45, 58)

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -90, 0, 22)
        title.Position = UDim2.new(0, 14, 0, 10)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = name
        title.TextColor3 = Color3.fromRGB(240, 245, 255)
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", Card)
        desc.Size = UDim2.new(1, -90, 0, 26)
        desc.Position = UDim2.new(0, 14, 0, 32)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.GothamMedium
        desc.Text = description
        desc.TextColor3 = Color3.fromRGB(140, 140, 155)
        desc.TextSize = 10
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top

        local inputBox = Instance.new("TextBox", Card)
        inputBox.Size = UDim2.new(0, 60, 0, 26)
        inputBox.Position = UDim2.new(1, -74, 0.5, -13)
        inputBox.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        inputBox.Font = Enum.Font.GothamMedium
        inputBox.Text = tostring(defaultValue or 16)
        inputBox.TextColor3 = Color3.fromRGB(240, 245, 255)
        inputBox.TextSize = 12
        Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 4)
        local inputStroke = Instance.new("UIStroke", inputBox)
        inputStroke.Color = Color3.fromRGB(45, 45, 58)

        inputBox.Focused:Connect(function()
            inputStroke.Color = parentLib.AccentColor
        end)

        inputBox.FocusLost:Connect(function()
            inputStroke.Color = Color3.fromRGB(45, 45, 58)
            local number = tonumber(inputBox.Text)
            if number then
                defaultValue = number
                if callback then
                    pcall(callback, number)
                end
            else
                inputBox.Text = tostring(defaultValue or 16)
            end
        end)

        local API = {}
        function API:GetValue()
            return tonumber(inputBox.Text) or defaultValue or 0
        end
        function API:SetValue(value)
            defaultValue = value
            inputBox.Text = tostring(value)
        end
        return API
    end

    -- README / Info Panel Card Component
    function TabObj:CreateReadMeCard(title, bodyText, height)
        local cardHeight = height or 90
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, cardHeight)
        Card.BackgroundColor3 = Color3.fromRGB(22, 22, 29)
        Card.BorderSizePixel = 0
        Card.Parent = container
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", Card).Color = Color3.fromRGB(45, 45, 58)

        local titleLabel = Instance.new("TextLabel", Card)
        titleLabel.Size = UDim2.new(1, -24, 0, 22)
        titleLabel.Position = UDim2.new(0, 12, 0, 8)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = title
        titleLabel.TextColor3 = parentLib.AccentColor
        titleLabel.TextSize = 12
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left

        parentLib:RegisterAccentListener(function(col)
            titleLabel.TextColor3 = col
        end)

        local bodyLabel = Instance.new("TextLabel", Card)
        bodyLabel.Size = UDim2.new(1, -24, 1, -34)
        bodyLabel.Position = UDim2.new(0, 12, 0, 28)
        bodyLabel.BackgroundTransparency = 1
        bodyLabel.Font = Enum.Font.GothamMedium
        bodyLabel.Text = bodyText
        bodyLabel.TextColor3 = Color3.fromRGB(160, 165, 180)
        bodyLabel.TextSize = 11
        bodyLabel.TextWrapped = true
        bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
        bodyLabel.TextYAlignment = Enum.TextYAlignment.Top

        return bodyLabel
    end

    -- Column Layout (Side-by-side arrangement)
    function TabObj:CreateColumnLayout(callback)
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, 0, 0, 64)
        Row.BackgroundTransparency = 1
        Row.BorderSizePixel = 0
        Row.Parent = container

        local rowLayout = Instance.new("UIListLayout", Row)
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rowLayout.Padding = UDim.new(0, 8)

        local ColumnAPI = {}

        function ColumnAPI:CreateSideToggle(name, initialState, callback)
            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(0.5, -4, 1, 0)
            Card.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
            Card.BorderSizePixel = 0
            Card.Parent = Row
            Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
            Instance.new("UIStroke", Card).Color = Color3.fromRGB(45, 45, 58)

            local title = Instance.new("TextLabel", Card)
            title.Size = UDim2.new(1, -50, 1, 0)
            title.Position = UDim2.new(0, 10, 0, 0)
            title.BackgroundTransparency = 1
            title.Font = Enum.Font.GothamBold
            title.Text = name
            title.TextColor3 = Color3.fromRGB(240, 245, 255)
            title.TextSize = 11
            title.TextXAlignment = Enum.TextXAlignment.Left

            local switchTrack = Instance.new("TextButton", Card)
            switchTrack.Size = UDim2.new(0, 38, 0, 20)
            switchTrack.Position = UDim2.new(1, -46, 0.5, -10)
            switchTrack.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
            switchTrack.AutoButtonColor = false
            switchTrack.Text = ""
            local trackStroke = Instance.new("UIStroke", switchTrack)
            trackStroke.Color = Color3.fromRGB(45, 45, 58)

            local switchThumb = Instance.new("Frame", switchTrack)
            switchThumb.Size = UDim2.new(0, 16, 0, 14)
            switchThumb.Position = UDim2.new(0, 2, 0.5, -7)
            switchThumb.BackgroundColor3 = Color3.fromRGB(110, 120, 135)
            switchThumb.BorderSizePixel = 0

            local enabled = initialState or false
            if enabled then
                switchThumb.Position = UDim2.new(1, -18, 0.5, -7)
                switchThumb.BackgroundColor3 = parentLib.AccentColor
                trackStroke.Color = parentLib.AccentColor
            end

            parentLib:RegisterAccentListener(function(col)
                if enabled then
                    switchThumb.BackgroundColor3 = col
                    trackStroke.Color = col
                end
            end)

            switchTrack.Activated:Connect(function()
                enabled = not enabled
                applySideToggleVisual(switchThumb, trackStroke, enabled, parentLib.AccentColor)
                if callback then
                    pcall(callback, enabled)
                end
            end)

            local API = {}
            function API:Get()
                return enabled
            end
            function API:Set(state)
                enabled = state and true or false
                applySideToggleVisual(switchThumb, trackStroke, enabled, parentLib.AccentColor)
            end
            return API
        end

        if callback then
            pcall(callback, ColumnAPI)
        end
        return ColumnAPI
    end

    -- 1. Standard Toggle Component
    function TabObj:CreateToggle(name, description, initialState, callback)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 64)
        Card.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
        Card.BorderSizePixel = 0
        Card.Parent = container
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", Card).Color = Color3.fromRGB(45, 45, 58)

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -80, 0, 22)
        title.Position = UDim2.new(0, 14, 0, 10)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = name
        title.TextColor3 = Color3.fromRGB(240, 245, 255)
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", Card)
        desc.Size = UDim2.new(1, -80, 0, 26)
        desc.Position = UDim2.new(0, 14, 0, 32)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.GothamMedium
        desc.Text = description
        desc.TextColor3 = Color3.fromRGB(140, 140, 155)
        desc.TextSize = 10
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top

        local switchTrack = Instance.new("TextButton", Card)
        switchTrack.Size = UDim2.new(0, 48, 0, 22)
        switchTrack.Position = UDim2.new(1, -62, 0.5, -11)
        switchTrack.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        switchTrack.AutoButtonColor = false
        switchTrack.Text = ""
        local trackStroke = Instance.new("UIStroke", switchTrack)
        trackStroke.Color = Color3.fromRGB(45, 45, 58)

        local switchThumb = Instance.new("Frame", switchTrack)
        switchThumb.Size = UDim2.new(0, 18, 0, 16)
        switchThumb.Position = UDim2.new(0, 3, 0.5, -8)
        switchThumb.BackgroundColor3 = Color3.fromRGB(110, 120, 135)
        switchThumb.BorderSizePixel = 0

        local enabled = initialState or false
        if enabled then
            switchThumb.Position = UDim2.new(1, -21, 0.5, -8)
            switchThumb.BackgroundColor3 = parentLib.AccentColor
            trackStroke.Color = parentLib.AccentColor
        end

        parentLib:RegisterAccentListener(function(col)
            if enabled then
                switchThumb.BackgroundColor3 = col
                trackStroke.Color = col
            end
        end)

        local function setState(state, fireCallback)
            enabled = state and true or false
            applyToggleVisual(switchThumb, trackStroke, enabled, parentLib.AccentColor)
            if fireCallback and callback then
                pcall(callback, enabled)
            end
        end

        switchTrack.Activated:Connect(function()
            setState(not enabled, true)
        end)

        local API = {}
        function API:Get()
            return enabled
        end
        function API:Set(state)
            setState(state, false)
        end
        return API
    end

    -- 2. Toggle with Number Input Component
    function TabObj:CreateToggleWithInput(name, description, initialState, defaultValue, toggleCallback, inputCallback)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 64)
        Card.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
        Card.BorderSizePixel = 0
        Card.Parent = container
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", Card).Color = Color3.fromRGB(45, 45, 58)

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -135, 0, 22)
        title.Position = UDim2.new(0, 14, 0, 10)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = name
        title.TextColor3 = Color3.fromRGB(240, 245, 255)
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", Card)
        desc.Size = UDim2.new(1, -135, 0, 26)
        desc.Position = UDim2.new(0, 14, 0, 32)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.GothamMedium
        desc.Text = description
        desc.TextColor3 = Color3.fromRGB(140, 140, 155)
        desc.TextSize = 10
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top

        local inputBox = Instance.new("TextBox", Card)
        inputBox.Size = UDim2.new(0, 50, 0, 24)
        inputBox.Position = UDim2.new(1, -118, 0.5, -12)
        inputBox.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        inputBox.Font = Enum.Font.GothamMedium
        inputBox.Text = tostring(defaultValue or 24)
        inputBox.TextColor3 = Color3.fromRGB(240, 245, 255)
        inputBox.TextSize = 12
        Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", inputBox).Color = Color3.fromRGB(45, 45, 58)

        inputBox.FocusLost:Connect(function()
            local number = tonumber(inputBox.Text)
            if number then
                defaultValue = number
                if inputCallback then
                    pcall(inputCallback, number)
                end
            else
                inputBox.Text = tostring(defaultValue or 24)
            end
        end)

        local switchTrack = Instance.new("TextButton", Card)
        switchTrack.Size = UDim2.new(0, 48, 0, 22)
        switchTrack.Position = UDim2.new(1, -62, 0.5, -11)
        switchTrack.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        switchTrack.AutoButtonColor = false
        switchTrack.Text = ""
        local trackStroke = Instance.new("UIStroke", switchTrack)
        trackStroke.Color = Color3.fromRGB(45, 45, 58)

        local switchThumb = Instance.new("Frame", switchTrack)
        switchThumb.Size = UDim2.new(0, 18, 0, 16)
        switchThumb.Position = UDim2.new(0, 3, 0.5, -8)
        switchThumb.BackgroundColor3 = Color3.fromRGB(110, 120, 135)
        switchThumb.BorderSizePixel = 0

        local enabled = initialState or false
        if enabled then
            switchThumb.Position = UDim2.new(1, -21, 0.5, -8)
            switchThumb.BackgroundColor3 = parentLib.AccentColor
            trackStroke.Color = parentLib.AccentColor
        end

        parentLib:RegisterAccentListener(function(col)
            if enabled then
                switchThumb.BackgroundColor3 = col
                trackStroke.Color = col
            end
        end)

        local function setState(state, fireCallback)
            enabled = state and true or false
            applyToggleVisual(switchThumb, trackStroke, enabled, parentLib.AccentColor)
            if fireCallback and toggleCallback then
                pcall(toggleCallback, enabled)
            end
        end

        switchTrack.Activated:Connect(function()
            setState(not enabled, true)
        end)

        local API = {}
        function API:GetEnabled()
            return enabled
        end
        function API:SetEnabled(state)
            setState(state, false)
        end
        function API:GetValue()
            return tonumber(inputBox.Text) or defaultValue or 0
        end
        function API:SetValue(value)
            defaultValue = value
            inputBox.Text = tostring(value)
        end
        return API
    end

    -- 3. Toggle with Color Picker Component
    function TabObj:CreateToggleWithColor(name, description, initialState, defaultColor, toggleCallback, colorCallback)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 64)
        Card.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
        Card.BorderSizePixel = 0
        Card.Parent = container
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", Card).Color = Color3.fromRGB(45, 45, 58)

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -120, 0, 22)
        title.Position = UDim2.new(0, 14, 0, 10)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = name
        title.TextColor3 = Color3.fromRGB(240, 245, 255)
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", Card)
        desc.Size = UDim2.new(1, -120, 0, 26)
        desc.Position = UDim2.new(0, 14, 0, 32)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.GothamMedium
        desc.Text = description
        desc.TextColor3 = Color3.fromRGB(140, 140, 155)
        desc.TextSize = 10
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top

        local paletteButton = Instance.new("TextButton", Card)
        paletteButton.Size = UDim2.new(0, 30, 0, 22)
        paletteButton.Position = UDim2.new(1, -100, 0.5, -11)
        paletteButton.BackgroundColor3 = defaultColor or parentLib.AccentColor
        paletteButton.AutoButtonColor = false
        paletteButton.Text = ""
        Instance.new("UICorner", paletteButton).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", paletteButton).Color = Color3.fromRGB(255, 255, 255)

        local colorAPI = CreateColorPopup(parentLib, name, defaultColor, colorCallback, paletteButton)

        local switchTrack = Instance.new("TextButton", Card)
        switchTrack.Size = UDim2.new(0, 48, 0, 22)
        switchTrack.Position = UDim2.new(1, -62, 0.5, -11)
        switchTrack.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        switchTrack.AutoButtonColor = false
        switchTrack.Text = ""
        local trackStroke = Instance.new("UIStroke", switchTrack)
        trackStroke.Color = Color3.fromRGB(45, 45, 58)

        local switchThumb = Instance.new("Frame", switchTrack)
        switchThumb.Size = UDim2.new(0, 18, 0, 16)
        switchThumb.Position = UDim2.new(0, 3, 0.5, -8)
        switchThumb.BackgroundColor3 = Color3.fromRGB(110, 120, 135)
        switchThumb.BorderSizePixel = 0

        local enabled = initialState or false
        if enabled then
            switchThumb.Position = UDim2.new(1, -21, 0.5, -8)
            switchThumb.BackgroundColor3 = parentLib.AccentColor
            trackStroke.Color = parentLib.AccentColor
        end

        parentLib:RegisterAccentListener(function(col)
            if enabled then
                switchThumb.BackgroundColor3 = col
                trackStroke.Color = col
            end
        end)

        local function setState(state, fireCallback)
            enabled = state and true or false
            applyToggleVisual(switchThumb, trackStroke, enabled, parentLib.AccentColor)
            if fireCallback and toggleCallback then
                pcall(toggleCallback, enabled)
            end
        end

        switchTrack.Activated:Connect(function()
            setState(not enabled, true)
        end)

        local API = {}
        function API:GetEnabled()
            return enabled
        end
        function API:SetEnabled(state)
            setState(state, false)
        end
        function API:GetColor()
            return colorAPI:GetColor()
        end
        function API:SetColor(color)
            colorAPI:SetColor(color)
        end
        return API
    end

    -- 4. Standalone Color Picker Component
    function TabObj:CreateColorPicker(name, description, defaultColor, callback)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 64)
        Card.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
        Card.BorderSizePixel = 0
        Card.Parent = container
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", Card).Color = Color3.fromRGB(45, 45, 58)

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -80, 0, 22)
        title.Position = UDim2.new(0, 14, 0, 10)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = name
        title.TextColor3 = Color3.fromRGB(240, 245, 255)
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", Card)
        desc.Size = UDim2.new(1, -80, 0, 26)
        desc.Position = UDim2.new(0, 14, 0, 32)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.GothamMedium
        desc.Text = description
        desc.TextColor3 = Color3.fromRGB(140, 140, 155)
        desc.TextSize = 10
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top

        local paletteButton = Instance.new("TextButton", Card)
        paletteButton.Size = UDim2.new(0, 36, 0, 26)
        paletteButton.Position = UDim2.new(1, -50, 0.5, -13)
        paletteButton.BackgroundColor3 = defaultColor or parentLib.AccentColor
        paletteButton.AutoButtonColor = false
        paletteButton.Text = ""
        Instance.new("UICorner", paletteButton).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", paletteButton).Color = Color3.fromRGB(255, 255, 255)

        return CreateColorPopup(parentLib, name, defaultColor, callback, paletteButton)
    end

    -- 5. Keybind Card Component (PC)
    function TabObj:CreateKeybindCard()
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 64)
        Card.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
        Card.BorderSizePixel = 0
        Card.Parent = container
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", Card).Color = Color3.fromRGB(45, 45, 58)

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -120, 0, 22)
        title.Position = UDim2.new(0, 14, 0, 10)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = "TOGGLE_GUI_KEYBIND"
        title.TextColor3 = Color3.fromRGB(240, 245, 255)
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", Card)
        desc.Size = UDim2.new(1, -120, 0, 18)
        desc.Position = UDim2.new(0, 14, 0, 32)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.GothamMedium
        desc.Text = "PC key used to hide/show UI"
        desc.TextColor3 = Color3.fromRGB(140, 140, 155)
        desc.TextSize = 11
        desc.TextXAlignment = Enum.TextXAlignment.Left

        local keybindButton = Instance.new("TextButton", Card)
        keybindButton.Size = UDim2.new(0, 96, 0, 26)
        keybindButton.Position = UDim2.new(1, -110, 0.5, -13)
        keybindButton.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        keybindButton.AutoButtonColor = false
        keybindButton.Font = Enum.Font.GothamBold
        keybindButton.Text = parentLib.CurrentHideKey.Name
        keybindButton.TextColor3 = parentLib.AccentColor
        keybindButton.TextSize = 12
        Instance.new("UICorner", keybindButton).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", keybindButton).Color = Color3.fromRGB(45, 45, 58)

        parentLib:RegisterAccentListener(function(col)
            if not parentLib.IsListeningForKey then
                keybindButton.TextColor3 = col
            end
        end)

        local listening = false
        local function stopListening()
            listening = false
            parentLib.IsListeningForKey = false
            keybindButton.Text = parentLib.CurrentHideKey.Name
            keybindButton.TextColor3 = parentLib.AccentColor
        end

        keybindButton.Activated:Connect(function()
            if listening then
                stopListening()
                return
            end
            listening = true
            parentLib.IsListeningForKey = true
            keybindButton.Text = "PRESS KEY..."
            keybindButton.TextColor3 = Color3.fromRGB(255, 200, 50)
            -- Safety: never leave the main hide-key handler blocked forever.
            task.delay(5, function()
                if not listening then
                    return
                end
                if keybindButton.Parent then
                    stopListening()
                else
                    listening = false
                    parentLib.IsListeningForKey = false
                end
            end)
        end)

        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not listening then
                return
            end
            if not keybindButton.Parent then
                listening = false
                parentLib.IsListeningForKey = false
                return
            end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then
                return
            end
            if input.KeyCode == Enum.KeyCode.Escape then
                stopListening()
                return
            end
            if gameProcessed then
                return
            end
            parentLib.CurrentHideKey = input.KeyCode
            keybindButton.Text = parentLib.CurrentHideKey.Name
            keybindButton.TextColor3 = parentLib.AccentColor
            listening = false
            parentLib.IsListeningForKey = false
            parentLib:SaveSettings()
        end)
    end

    -- 6. Info Card Component
    function TabObj:CreateInfoCard(labelName, valueText)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 48)
        Card.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
        Card.BorderSizePixel = 0
        Card.Parent = container
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", Card).Color = Color3.fromRGB(45, 45, 58)

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(0.5, 0, 1, 0)
        title.Position = UDim2.new(0, 14, 0, 0)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = labelName
        title.TextColor3 = Color3.fromRGB(200, 210, 225)
        title.TextSize = 12
        title.TextXAlignment = Enum.TextXAlignment.Left

        local value = Instance.new("TextLabel", Card)
        value.Size = UDim2.new(0.5, -20, 1, 0)
        value.Position = UDim2.new(0.5, 0, 0, 0)
        value.BackgroundTransparency = 1
        value.Font = Enum.Font.GothamMedium
        value.Text = valueText
        value.TextColor3 = Color3.fromRGB(140, 140, 155)
        value.TextSize = 12
        value.TextXAlignment = Enum.TextXAlignment.Right

        local API = {}
        function API:SetValue(text)
            value.Text = tostring(text)
        end
        return API
    end

    return TabObj
end

-- // Export the library module
if getgenv then
    pcall(function()
        getgenv().ApexLibrary = ApexLibrary
    end)
end

return ApexLibrary
