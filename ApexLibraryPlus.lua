--[================================================================[
    PROJECT: APEX_SYS // STANDALONE GUI LIBRARY ENGINE (V3.7 PLUS)
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

-- Desktop gets larger native font sizes instead of fractional UI scaling.
-- Keeping whole pixel sizes renders text sharply; touch layout is unchanged.
local IS_DESKTOP = not UserInputService.TouchEnabled
local function FontSize(baseSize, maxBoost)
    if not IS_DESKTOP then
        return baseSize
    end
    local boost = baseSize <= 10 and 2 or 1
    if maxBoost and boost > maxBoost then
        boost = maxBoost
    end
    return baseSize + boost
end

-- UIStroke defaults to Contextual, which outlines text instead of the control.
-- All strokes in this library are borders, so force Border mode everywhere.
local function CreateStroke(parent)
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

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

-- // Terminal theme sampled from the SYSTEM_CONTROL reference.
local Theme = {
    Window      = Color3.fromRGB(26, 29, 35),   -- #1A1D23
    Header      = Color3.fromRGB(34, 38, 48),   -- #222630
    Card        = Color3.fromRGB(34, 38, 48),   -- #222630
    TabBar      = Color3.fromRGB(22, 24, 29),   -- #16181D
    TabActive   = Color3.fromRGB(25, 28, 34),   -- #191C22
    Input       = Color3.fromRGB(18, 20, 23),   -- #121417
    Footer      = Color3.fromRGB(18, 20, 23),   -- #121417
    Border      = Color3.fromRGB(46, 52, 64),   -- #2E3440
    Divider     = Color3.fromRGB(37, 41, 50),   -- #252932
    Text        = Color3.fromRGB(255, 255, 255),
    Muted       = Color3.fromRGB(138, 146, 160), -- #8A92A0
    Section     = Color3.fromRGB(131, 137, 152), -- #838998
    Body        = Color3.fromRGB(160, 168, 182),
    Green       = Color3.fromRGB(52, 211, 153),  -- #34D399
    Red         = Color3.fromRGB(255, 107, 107),
    RedDim      = Color3.fromRGB(252, 165, 165),
    RedBg       = Color3.fromRGB(44, 21, 25),    -- #2C1519
    RedBorder   = Color3.fromRGB(92, 31, 36),    -- #5C1F24
    Accent      = Color3.fromRGB(255, 85, 0),    -- #FF5500
    Thumb       = Color3.fromRGB(124, 133, 149), -- #7C8595
}

-- // Shared visual helpers
local function applyToggleVisual(thumb, stroke, enabled, accent)
    local targetPos = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    local thumbColor = enabled and accent or Theme.Thumb
    local strokeColor = enabled and accent or Theme.Border
    TweenService:Create(thumb, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Position = targetPos,
        BackgroundColor3 = thumbColor
    }):Play()
    TweenService:Create(stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Color = strokeColor
    }):Play()
end

local function applySideToggleVisual(thumb, stroke, enabled, accent)
    local targetPos = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    local thumbColor = enabled and accent or Theme.Thumb
    local strokeColor = enabled and accent or Theme.Border
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
ApexLibrary.Version = "APEX_SYS V3.7 PLUS"
-- Bump this when a script depends on a layout fix that older copies lack.
-- 3: overflow tab bar gains left/right navigation arrows.
-- 4: desktop 120% whole-UI scaling (reverted in 5).
-- 5: desktop text uses larger native sizes without scaling the window.
-- 6: desktop card descriptions match the larger native text sizes.
-- 7: every UIStroke is border-only so button text is no longer outlined.
ApexLibrary.LayoutRevision = 7
local CONFIG_VERSION = 2

ApexLibrary.Theme = Theme

function ApexLibrary.new(config)
    local self = setmetatable({}, ApexLibrary)
    config = config or {}

    self.Title = config.Title or "SYSTEM_CONTROL // ENGINE"
    self.BrandText = config.BrandText or "APEX_SYS // RH"
    self.StatusText = config.StatusText or "READY"
    self.SaveFileName = config.SaveFileName or ConfigFile
    self.CurrentHideKey = config.HideKey or Enum.KeyCode.RightControl
    self.IsButtonLocked = false
    self.LoadedButtonPos = UDim2.new(0, 24, 0, 100)
    self.AccentColor = config.AccentColor or Theme.Accent
    self.MobileButtonRef = nil
    self.AccentUpdateCallbacks = {}
    self.ColorPopups = {}
    self.UnloadCallbacks = {}
    self.IsListeningForKey = false
    self.IsUnloaded = false
    self.ConfigVersion = CONFIG_VERSION

    local savedConfigVersion = 0
    if type(loadedConfigData) == "table" then
        savedConfigVersion = tonumber(loadedConfigData.ConfigVersion) or 0
        -- Version 1 and older used the blue APEX theme and the P hide key.
        -- Migrate those configs to the terminal theme instead of carrying the
        -- old look forward. Mobile-button settings are safe to keep.
        if savedConfigVersion >= CONFIG_VERSION then
            if loadedConfigData.AccentColor then
                self.AccentColor = Color3.fromRGB(
                    loadedConfigData.AccentColor.R or 255,
                    loadedConfigData.AccentColor.G or 85,
                    loadedConfigData.AccentColor.B or 0
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
    if savedConfigVersion < CONFIG_VERSION then
        self:SaveSettings()
    end
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

function ApexLibrary:SetStatus(text)
    self.StatusText = tostring(text or "READY")
    if self.StatusValueLabel then
        self.StatusValueLabel.Text = self.StatusText
    end
end

function ApexLibrary:Unload()
    if self.IsUnloaded then
        return
    end
    self.IsUnloaded = true
    for _, callback in ipairs(self.UnloadCallbacks) do
        pcall(callback)
    end
    self:CloseColorPopups()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    local mobile = PlayerGui:FindFirstChild("ApexMobileButtonGui")
    if mobile then
        mobile:Destroy()
    end
end

function ApexLibrary:SaveSettings()
    SaveConfig({
        ConfigVersion = CONFIG_VERSION,
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

    local WINDOW_W, WINDOW_H = 392, 397
    self.WindowWidth = WINDOW_W
    self.WindowHeight = WINDOW_H
    self.ContentFullHeight = 216
    self.ContentKillHeight = 160

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ApexSystemControl"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999999
    ScreenGui.Parent = PlayerGui

    local MainFrame = Instance.new("CanvasGroup")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Theme.Window
    MainFrame.BorderSizePixel = 0
    MainFrame.GroupTransparency = 0
    MainFrame.Parent = ScreenGui

    -- Keep the fixed terminal layout usable on phones and small windows.
    -- Desktop text is enlarged at its native size instead of scaling the UI.
    local UIScale = Instance.new("UIScale")
    UIScale.Parent = MainFrame
    local function UpdateUIScale()
        if not UIScale or not UIScale.Parent then
            return
        end
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local scale = math.min((viewport.X - 24) / WINDOW_W, (viewport.Y - 24) / WINDOW_H)
        UIScale.Scale = math.min(math.max(scale, 0.6), 1)
    end
    UpdateUIScale()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateUIScale)
    end

    local MainStroke = CreateStroke(MainFrame)
    MainStroke.Color = Theme.Border
    MainStroke.Thickness = 1

    -- Header Bar
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Name = "HeaderBar"
    HeaderBar.Size = UDim2.new(1, 0, 0, 42)
    HeaderBar.BackgroundColor3 = Theme.Header
    HeaderBar.BorderSizePixel = 0
    HeaderBar.Parent = MainFrame

    local HeaderDivider = Instance.new("Frame")
    HeaderDivider.Name = "HeaderDivider"
    HeaderDivider.Size = UDim2.new(1, 0, 0, 1)
    HeaderDivider.Position = UDim2.new(0, 0, 1, -1)
    HeaderDivider.BackgroundColor3 = Theme.Divider
    HeaderDivider.BorderSizePixel = 0
    HeaderDivider.Parent = HeaderBar

    local AccentBox = Instance.new("Frame")
    AccentBox.Name = "AccentBox"
    AccentBox.Size = UDim2.new(0, 9, 0, 9)
    AccentBox.Position = UDim2.new(0, 14, 0.5, -4)
    AccentBox.BackgroundColor3 = self.AccentColor
    AccentBox.BorderSizePixel = 0
    AccentBox.Parent = HeaderBar

    self:RegisterAccentListener(function(col)
        AccentBox.BackgroundColor3 = col
    end)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -112, 1, 0)
    TitleLabel.Position = UDim2.new(0, 32, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.RobotoMono
    TitleLabel.Text = self.Title
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextSize = FontSize(14)
    TitleLabel.TextStrokeColor3 = Theme.Text
    TitleLabel.TextStrokeTransparency = IS_DESKTOP and 1 or 0.75
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    TitleLabel.Parent = HeaderBar

    local LuaBadge = Instance.new("TextLabel")
    LuaBadge.Name = "LuaBadge"
    LuaBadge.Size = UDim2.new(0, 37, 0, 20)
    LuaBadge.Position = UDim2.new(1, -50, 0.5, -10)
    LuaBadge.BackgroundColor3 = Theme.Input
    LuaBadge.BorderSizePixel = 0
    LuaBadge.Font = Enum.Font.RobotoMono
    LuaBadge.Text = "LUAU"
    LuaBadge.TextColor3 = Theme.Muted
    LuaBadge.TextSize = FontSize(10)
    LuaBadge.Parent = HeaderBar

    -- Equal-width tab bar. The first tab is created by the caller.
    local TabBar = Instance.new("ScrollingFrame")
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(1, 0, 0, 38)
    TabBar.Position = UDim2.new(0, 0, 0, 42)
    TabBar.BackgroundColor3 = Theme.TabBar
    TabBar.BorderSizePixel = 0
    TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabBar.AutomaticCanvasSize = Enum.AutomaticSize.None
    TabBar.ScrollingDirection = Enum.ScrollingDirection.X
    TabBar.ScrollingEnabled = false
    TabBar.ScrollBarThickness = 0
    TabBar.Parent = MainFrame

    -- Left/right navigation appears only when the tab bar overflows.
    local TabScrollLeft = Instance.new("TextButton")
    TabScrollLeft.Name = "TabScrollLeft"
    TabScrollLeft.Size = UDim2.new(0, 22, 0, 38)
    TabScrollLeft.Position = UDim2.new(0, 0, 0, 42)
    TabScrollLeft.BackgroundColor3 = Theme.TabBar
    TabScrollLeft.BorderSizePixel = 0
    TabScrollLeft.Font = Enum.Font.RobotoMono
    TabScrollLeft.Text = "<"
    TabScrollLeft.TextColor3 = Theme.Muted
    TabScrollLeft.TextSize = FontSize(14)
    TabScrollLeft.TextTransparency = 0.55
    TabScrollLeft.AutoButtonColor = false
    TabScrollLeft.Visible = false
    TabScrollLeft.ZIndex = 5
    TabScrollLeft.Parent = MainFrame

    local TabScrollRight = Instance.new("TextButton")
    TabScrollRight.Name = "TabScrollRight"
    TabScrollRight.Size = UDim2.new(0, 22, 0, 38)
    TabScrollRight.Position = UDim2.new(1, -22, 0, 42)
    TabScrollRight.BackgroundColor3 = Theme.TabBar
    TabScrollRight.BorderSizePixel = 0
    TabScrollRight.Font = Enum.Font.RobotoMono
    TabScrollRight.Text = ">"
    TabScrollRight.TextColor3 = Theme.Muted
    TabScrollRight.TextSize = FontSize(14)
    TabScrollRight.TextTransparency = 0.55
    TabScrollRight.AutoButtonColor = false
    TabScrollRight.Visible = false
    TabScrollRight.ZIndex = 5
    TabScrollRight.Parent = MainFrame

    local TabDivider = Instance.new("Frame")
    TabDivider.Name = "TabDivider"
    TabDivider.Size = UDim2.new(1, 0, 0, 1)
    TabDivider.Position = UDim2.new(0, 0, 0, 80)
    TabDivider.BackgroundColor3 = Theme.Divider
    TabDivider.BorderSizePixel = 0
    TabDivider.Parent = MainFrame

    -- Section Title Header
    local SectionHeader = Instance.new("TextLabel")
    SectionHeader.Size = UDim2.new(1, -36, 0, 14)
    SectionHeader.Position = UDim2.new(0, 18, 0, 97)
    SectionHeader.BackgroundTransparency = 1
    SectionHeader.Font = Enum.Font.RobotoMono
    SectionHeader.Text = "INTERFACE PREFERENCES"
    SectionHeader.TextColor3 = Theme.Section
    SectionHeader.TextSize = FontSize(10)
    SectionHeader.TextXAlignment = Enum.TextXAlignment.Left
    SectionHeader.Parent = MainFrame

    -- Footer
    local FooterBar = Instance.new("Frame")
    FooterBar.Name = "FooterBar"
    FooterBar.Size = UDim2.new(1, 0, 0, 30)
    FooterBar.Position = UDim2.new(0, 0, 1, -30)
    FooterBar.BackgroundColor3 = Theme.Footer
    FooterBar.BorderSizePixel = 0
    FooterBar.Parent = MainFrame

    local FooterDivider = Instance.new("Frame")
    FooterDivider.Name = "FooterDivider"
    FooterDivider.Size = UDim2.new(1, 0, 0, 1)
    FooterDivider.Position = UDim2.new(0, 0, 0, 0)
    FooterDivider.BackgroundColor3 = Theme.Divider
    FooterDivider.BorderSizePixel = 0
    FooterDivider.Parent = FooterBar

    local StatusPrefix = Instance.new("TextLabel")
    StatusPrefix.Size = UDim2.new(0, IS_DESKTOP and 54 or 48, 1, 0)
    StatusPrefix.Position = UDim2.new(0, 13, 0, 0)
    StatusPrefix.BackgroundTransparency = 1
    StatusPrefix.Font = Enum.Font.RobotoMono
    StatusPrefix.Text = "STATUS:"
    StatusPrefix.TextColor3 = Theme.Muted
    StatusPrefix.TextSize = FontSize(10)
    StatusPrefix.TextXAlignment = Enum.TextXAlignment.Left
    StatusPrefix.Parent = FooterBar

    local StatusValue = Instance.new("TextLabel")
    StatusValue.Size = UDim2.new(0, IS_DESKTOP and 96 or 100, 1, 0)
    StatusValue.Position = UDim2.new(0, IS_DESKTOP and 66 or 60, 0, 0)
    StatusValue.BackgroundTransparency = 1
    StatusValue.Font = Enum.Font.RobotoMono
    StatusValue.Text = self.StatusText
    StatusValue.TextColor3 = Theme.Muted
    StatusValue.TextSize = FontSize(10)
    StatusValue.TextXAlignment = Enum.TextXAlignment.Left
    StatusValue.Parent = FooterBar
    self.StatusValueLabel = StatusValue

    local BrandLabel = Instance.new("TextLabel")
    BrandLabel.Size = UDim2.new(0, 160, 1, 0)
    BrandLabel.AnchorPoint = Vector2.new(1, 0)
    BrandLabel.Position = UDim2.new(1, -13, 0, 0)
    BrandLabel.BackgroundTransparency = 1
    BrandLabel.Font = Enum.Font.RobotoMono
    BrandLabel.Text = self.BrandText
    BrandLabel.TextColor3 = Theme.Muted
    BrandLabel.TextSize = FontSize(10)
    BrandLabel.TextXAlignment = Enum.TextXAlignment.Right
    BrandLabel.Parent = FooterBar

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
    self.TabScrollLeft = TabScrollLeft
    self.TabScrollRight = TabScrollRight
    self.TabScrollWidth = 88
    self.SectionHeader = SectionHeader
    self.TabCount = 0
    self.TabButtonsList = {}
    self.IsUIVisible = true
    self.IsAnimating = false

    TabScrollLeft.Activated:Connect(function()
        self:ScrollTabs(-1)
    end)
    TabScrollRight.Activated:Connect(function()
        self:ScrollTabs(1)
    end)
    TabBar:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        self:UpdateTabScrollButtons()
    end)

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
                Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H),
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

    -- Mobile T-Rex Claw Button Setup. This is the only rounded element.
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
        MobileButton.BackgroundColor3 = Theme.Input
        MobileButton.AutoButtonColor = false
        MobileButton.Text = ""
        MobileButton.Parent = MobileScreenGui

        self.MobileButtonRef = MobileButton

        local MobileStroke = CreateStroke(MobileButton)
        MobileStroke.Color = self.AccentColor
        MobileStroke.Thickness = 1.5

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
    Popup.BackgroundColor3 = Theme.Header
    Popup.Visible = false
    Popup.ZIndex = 60
    local popupStroke = CreateStroke(Popup)
    popupStroke.Color = Theme.Border
    popupStroke.Thickness = 1
    parentLib:RegisterColorPopup(Popup)

    local pTitle = Instance.new("TextLabel", Popup)
    pTitle.Size = UDim2.new(1, -48, 0, 24)
    pTitle.Position = UDim2.new(0, 12, 0, 8)
    pTitle.BackgroundTransparency = 1
    pTitle.Font = Enum.Font.RobotoMono
    pTitle.Text = "PALETTE // " .. tostring(name)
    pTitle.TextColor3 = Theme.Text
    pTitle.TextSize = FontSize(10)
    pTitle.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", Popup)
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -28, 0, 8)
    CloseBtn.BackgroundColor3 = Theme.Input
    CloseBtn.AutoButtonColor = false
    CloseBtn.Font = Enum.Font.RobotoMono
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Theme.Muted
    CloseBtn.TextSize = FontSize(11)
    local closeStroke = CreateStroke(CloseBtn)
    closeStroke.Color = Theme.Border
    closeStroke.Thickness = 1

    local SVBox = Instance.new("TextButton", Popup)
    SVBox.Size = UDim2.new(1, -24, 0, 100)
    SVBox.Position = UDim2.new(0, 12, 0, 34)
    SVBox.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    SVBox.AutoButtonColor = false
    SVBox.Text = ""

    local WhiteOverlay = Instance.new("Frame", SVBox)
    WhiteOverlay.Size = UDim2.new(1, 0, 1, 0)
    WhiteOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    WhiteOverlay.BorderSizePixel = 0
    local whiteGradient = Instance.new("UIGradient", WhiteOverlay)
    whiteGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })

    local BlackOverlay = Instance.new("Frame", SVBox)
    BlackOverlay.Size = UDim2.new(1, 0, 1, 0)
    BlackOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BlackOverlay.BorderSizePixel = 0
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
    CreateStroke(SVHandle).Color = Color3.fromRGB(0, 0, 0)

    local HueBar = Instance.new("TextButton", Popup)
    HueBar.Size = UDim2.new(1, -24, 0, 14)
    HueBar.Position = UDim2.new(0, 12, 0, 142)
    HueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HueBar.AutoButtonColor = false
    HueBar.Text = ""

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
    CreateStroke(HueHandle).Color = Color3.fromRGB(0, 0, 0)

    local function createRGBInput(labelName, posX)
        local label = Instance.new("TextLabel", Popup)
        label.Size = UDim2.new(0, 72, 0, 14)
        label.Position = UDim2.new(0, posX, 0, 164)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.RobotoMono
        label.Text = labelName
        label.TextColor3 = Theme.Section
        label.TextSize = FontSize(10)
        label.TextXAlignment = Enum.TextXAlignment.Left

        local box = Instance.new("TextBox", Popup)
        box.Size = UDim2.new(0, 72, 0, 24)
        box.Position = UDim2.new(0, posX, 0, 180)
        box.BackgroundColor3 = Theme.Input
        box.BorderSizePixel = 0
        box.Font = Enum.Font.RobotoMono
        box.Text = "255"
        box.TextColor3 = Theme.Text
        box.TextSize = FontSize(12)
        local boxStroke = CreateStroke(box)
        boxStroke.Color = Theme.Border
        boxStroke.Thickness = 1
        return box
    end

    local rBox = createRGBInput("R", 12)
    local gBox = createRGBInput("G", 94)
    local bBox = createRGBInput("B", 176)

    local ApplyBtn = Instance.new("TextButton", Popup)
    ApplyBtn.Size = UDim2.new(1, -24, 0, 32)
    ApplyBtn.Position = UDim2.new(0, 12, 0, 214)
    ApplyBtn.BackgroundColor3 = Theme.Input
    ApplyBtn.AutoButtonColor = false
    ApplyBtn.Font = Enum.Font.RobotoMono
    ApplyBtn.Text = "APPLY COLOR"
    ApplyBtn.TextColor3 = parentLib.AccentColor
    ApplyBtn.TextSize = FontSize(11)
    local applyStroke = CreateStroke(ApplyBtn)
    applyStroke.Color = parentLib.AccentColor
    applyStroke.Thickness = 1

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

function ApexLibrary:GetTabScrollMax()
    local count = #(self.TabButtonsList or {})
    local tabWidth = self.TabScrollWidth or 88
    local viewWidth = (self.WindowWidth or 392) - 44
    return math.max(0, count * tabWidth - viewWidth)
end

function ApexLibrary:UpdateTabScrollButtons()
    if not self.TabBar or not self.TabScrollLeft or not self.TabScrollRight then
        return
    end

    local useScroll = self.TabBar.ScrollingEnabled == true
    self.TabScrollLeft.Visible = useScroll
    self.TabScrollRight.Visible = useScroll
    if not useScroll then
        return
    end

    local canvas = self.TabBar.CanvasPosition
    local current = canvas and canvas.X or 0
    local maxScroll = self:GetTabScrollMax()
    local canGoLeft = current > 0.5
    local canGoRight = current < maxScroll - 0.5

    self.TabScrollLeft.TextColor3 = canGoLeft and Theme.Text or Theme.Muted
    self.TabScrollLeft.TextTransparency = canGoLeft and 0 or 0.55
    self.TabScrollRight.TextColor3 = canGoRight and Theme.Text or Theme.Muted
    self.TabScrollRight.TextTransparency = canGoRight and 0 or 0.55
end

function ApexLibrary:ScrollTabs(direction)
    if not self.TabBar or not self.TabBar.ScrollingEnabled then
        return
    end

    local tabWidth = self.TabScrollWidth or 88
    local canvas = self.TabBar.CanvasPosition
    local current = canvas and canvas.X or 0
    local maxScroll = self:GetTabScrollMax()
    local target = math.clamp(current + (direction or 1) * tabWidth * 3, 0, maxScroll)
    if target ~= current then
        self.TabBar.CanvasPosition = Vector2.new(target, 0)
    end
    self:UpdateTabScrollButtons()
end

function ApexLibrary:EnsureTabVisible(entry)
    if not self.TabBar or not self.TabBar.ScrollingEnabled or not entry then
        return
    end

    local tabWidth = self.TabScrollWidth or 88
    local viewWidth = (self.WindowWidth or 392) - 44
    local canvas = self.TabBar.CanvasPosition
    local current = canvas and canvas.X or 0
    local left = entry.Button.Position.X.Offset
    local target = current

    if left < current then
        target = left
    elseif left + tabWidth > current + viewWidth then
        target = left + tabWidth - viewWidth
    end

    target = math.clamp(target, 0, self:GetTabScrollMax())
    if target ~= current then
        self.TabBar.CanvasPosition = Vector2.new(target, 0)
    end
    self:UpdateTabScrollButtons()
end

function ApexLibrary:UpdateTabSizes()
    local count = math.max(#self.TabButtonsList, 1)
    -- Six equal tabs match the reference. Once a script adds more than six,
    -- keep each tab readable and let the bar scroll horizontally instead of
    -- squeezing every label into an unusable width.
    local useScroll = count > 6
    local scrollTabWidth = 88
    local scrollArrowWidth = 22

    self.TabScrollWidth = scrollTabWidth

    if self.TabBar then
        self.TabBar.Position = UDim2.new(0, useScroll and scrollArrowWidth or 0, 0, 42)
        self.TabBar.Size = UDim2.new(1, useScroll and -(scrollArrowWidth * 2) or 0, 0, 38)
        self.TabBar.ScrollingEnabled = useScroll
        self.TabBar.ScrollBarThickness = useScroll and 2 or 0
        self.TabBar.AutomaticCanvasSize = useScroll and Enum.AutomaticSize.X or Enum.AutomaticSize.None
        self.TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
        if not useScroll then
            self.TabBar.CanvasPosition = Vector2.new(0, 0)
        end
    end

    for index, entry in ipairs(self.TabButtonsList) do
        if useScroll then
            entry.Button.Position = UDim2.new(0, (index - 1) * scrollTabWidth, 0, 0)
            entry.Button.Size = UDim2.new(0, scrollTabWidth, 1, 0)
            entry.Button.TextSize = FontSize(11, 1)
            entry.Line.Position = UDim2.new(0, 0, 1, -4)
        else
            entry.Button.Position = UDim2.new((index - 1) / count, 0, 0, 0)
            entry.Button.Size = UDim2.new(1 / count, 0, 1, 0)
            entry.Button.TextSize = FontSize(count >= 4 and 10 or 12, 1)
            entry.Line.Position = UDim2.new(0, 0, 1, -2)
        end
    end

    self:UpdateTabScrollButtons()
end

function ApexLibrary:ActivateTab(entry, silent)
    if self.IsUnloaded or not entry then
        return
    end

    for _, tab in ipairs(self.TabButtonsList) do
        tab.Button.BackgroundColor3 = Theme.TabBar
        tab.Button.TextColor3 = Theme.Muted
        tab.Line.Visible = false
        tab.Container.Visible = false
        tab.Container.Size = UDim2.new(1, -36, 0, self.ContentFullHeight)
        if tab.KillButton then
            tab.KillButton.Visible = false
        end
    end

    entry.Button.BackgroundColor3 = Theme.TabActive
    entry.Button.TextColor3 = Theme.Text
    entry.Line.BackgroundColor3 = self.AccentColor
    entry.Line.Visible = true
    entry.Container.Visible = true
    if entry.KillButton then
        entry.KillButton.Visible = true
        entry.Container.Size = UDim2.new(1, -36, 0, entry.KillContentHeight or self.ContentKillHeight)
    end
    self.SectionHeader.Text = entry.SectionTitle
    self.ActiveTabName = entry.Name
    self:EnsureTabVisible(entry)
    self:CloseColorPopups()
end

function ApexLibrary:SelectTab(tabName, silent)
    for _, entry in ipairs(self.TabButtonsList or {}) do
        if entry.Name == tabName then
            self:ActivateTab(entry, silent)
            return true
        end
    end
    return false
end

function ApexLibrary:CreateTab(tabName, sectionTitle)
    local parentLib = self

    local container = Instance.new("ScrollingFrame")
    container.Size = UDim2.new(1, -36, 0, self.ContentFullHeight)
    container.Position = UDim2.new(0, 18, 0, 141)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.CanvasSize = UDim2.new(0, 0, 0, 0)
    container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    container.ScrollBarThickness = 2
    container.ScrollBarImageColor3 = Theme.Border
    container.Visible = false
    container.Parent = self.MainFrame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 14)
    layout.Parent = container

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 120, 1, 0)
    button.BackgroundColor3 = Theme.TabBar
    button.BorderSizePixel = 0
    button.Font = Enum.Font.RobotoMono
    button.Text = tabName
    button.TextColor3 = Theme.Muted
    button.TextSize = FontSize(12, 1)
    button.TextStrokeColor3 = Theme.Text
    button.TextStrokeTransparency = IS_DESKTOP and 1 or 0.85
    button.AutoButtonColor = false
    button.Parent = self.TabBar

    local activeLine = Instance.new("Frame")
    activeLine.Size = UDim2.new(1, 0, 0, 2)
    activeLine.Position = UDim2.new(0, 0, 1, -2)
    activeLine.BackgroundColor3 = parentLib.AccentColor
    activeLine.BorderSizePixel = 0
    activeLine.Visible = false
    activeLine.Parent = button

    parentLib:RegisterAccentListener(function(col)
        if activeLine.Visible then
            activeLine.BackgroundColor3 = col
        end
    end)

    local entry = {
        Name = tabName,
        SectionTitle = sectionTitle or "GENERAL",
        Button = button,
        Line = activeLine,
        Container = container,
        KillButton = nil,
    }

    table.insert(self.TabButtonsList, entry)
    self.TabCount = self.TabCount + 1
    self:UpdateTabSizes()

    button.Activated:Connect(function()
        parentLib:ActivateTab(entry)
    end)

    -- The first tab is selected immediately. Keep the section header in sync
    -- without requiring the user to click the tab first.
    if self.TabCount == 1 then
        self:ActivateTab(entry, true)
    end

    local TabObj = {}

    function TabObj:GetContainer()
        return container
    end

    function TabObj:Select()
        parentLib:ActivateTab(entry)
    end

    function TabObj:GetName()
        return tabName
    end

    -- Section label inside a tab
    function TabObj:CreateSectionLabel(text)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 18)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.RobotoMono
        label.Text = tostring(text)
        label.TextColor3 = Theme.Section
        label.TextSize = FontSize(10)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = container
        return label
    end

    -- Action button card
    function TabObj:CreateButton(name, description, callback)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 64)
        Card.BackgroundColor3 = Theme.Card
        Card.BorderSizePixel = 0
        Card.Parent = container

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -112, 0, 22)
        title.Position = UDim2.new(0, 12, 0, 9)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.Roboto
        title.Text = name
        title.TextColor3 = Theme.Text
        title.TextSize = FontSize(14)
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", Card)
        desc.Size = UDim2.new(1, -112, 0, IS_DESKTOP and 30 or 26)
        desc.Position = UDim2.new(0, 12, 0, 31)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Roboto
        desc.Text = description
        desc.TextColor3 = Theme.Muted
        desc.TextSize = FontSize(11)
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top

        local action = Instance.new("TextButton", Card)
        action.Size = UDim2.new(0, 84, 0, 26)
        action.Position = UDim2.new(1, -96, 0.5, -13)
        action.BackgroundColor3 = Theme.Input
        action.AutoButtonColor = false
        action.Font = Enum.Font.RobotoMono
        action.Text = "RUN"
        action.TextColor3 = parentLib.AccentColor
        action.TextSize = FontSize(11)
        local actionStroke = CreateStroke(action)
        actionStroke.Color = parentLib.AccentColor
        actionStroke.Thickness = 1

        parentLib:RegisterAccentListener(function(col)
            action.TextColor3 = col
            actionStroke.Color = col
        end)

        action.MouseEnter:Connect(function()
            if action.Parent then
                action.BackgroundColor3 = Theme.TabBar
            end
        end)
        action.MouseLeave:Connect(function()
            if action.Parent then
                action.BackgroundColor3 = Theme.Input
            end
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
        Card.BackgroundColor3 = Theme.Card
        Card.BorderSizePixel = 0
        Card.Parent = container

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -24, 0, 18)
        title.Position = UDim2.new(0, 12, 0, 8)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.RobotoMono
        title.Text = titleText
        title.TextColor3 = parentLib.AccentColor
        title.TextSize = FontSize(11)
        title.TextXAlignment = Enum.TextXAlignment.Left

        parentLib:RegisterAccentListener(function(col)
            title.TextColor3 = col
        end)

        local desc
        if description and description ~= "" then
            desc = Instance.new("TextLabel", Card)
            desc.Size = UDim2.new(1, -24, 0, IS_DESKTOP and 16 or 14)
            desc.Position = UDim2.new(0, 12, 0, 26)
            desc.BackgroundTransparency = 1
            desc.Font = Enum.Font.Roboto
            desc.Text = description
            desc.TextColor3 = Theme.Muted
            desc.TextSize = FontSize(11)
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
        scroll.ScrollBarImageColor3 = Theme.Border
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
            label.Font = Enum.Font.Roboto
            label.Text = tostring(text)
            label.TextColor3 = color or Theme.Body
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
            button.BackgroundColor3 = Theme.Input
            button.AutoButtonColor = false
            button.Font = Enum.Font.RobotoMono
            button.Text = tostring(text)
            button.TextColor3 = color or Theme.Text
            button.TextSize = FontSize(11)
            button.LayoutOrder = order
            button.Parent = scroll
            local stroke = CreateStroke(button)
            stroke.Color = color or Theme.Border
            stroke.Transparency = 0.35

            button.MouseEnter:Connect(function()
                if not button.Parent then
                    return
                end
                TweenService:Create(button, TweenInfo.new(0.12), {
                    BackgroundColor3 = Theme.TabBar
                }):Play()
            end)
            button.MouseLeave:Connect(function()
                if not button.Parent then
                    return
                end
                TweenService:Create(button, TweenInfo.new(0.12), {
                    BackgroundColor3 = Theme.Input
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
        Card.BackgroundColor3 = Theme.Card
        Card.BorderSizePixel = 0
        Card.Parent = container

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -96, 0, 20)
        title.Position = UDim2.new(0, 12, 0, 9)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamMedium
        title.Text = name
        title.TextColor3 = Theme.Text
        title.TextSize = FontSize(13)
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", Card)
        desc.Size = UDim2.new(1, -96, 0, IS_DESKTOP and 30 or 26)
        desc.Position = UDim2.new(0, 12, 0, 31)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Roboto
        desc.Text = description
        desc.TextColor3 = Theme.Muted
        desc.TextSize = FontSize(11)
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top

        local inputBox = Instance.new("TextBox", Card)
        inputBox.Size = UDim2.new(0, 58, 0, 28)
        inputBox.Position = UDim2.new(1, -70, 0.5, -14)
        inputBox.BackgroundColor3 = Theme.Input
        inputBox.BorderSizePixel = 0
        inputBox.Font = Enum.Font.RobotoMono
        inputBox.Text = tostring(defaultValue or 16)
        inputBox.TextColor3 = Theme.Text
        inputBox.TextSize = FontSize(12)
        inputBox.ClearTextOnFocus = false
        local inputStroke = CreateStroke(inputBox)
        inputStroke.Color = Theme.Border
        inputStroke.Thickness = 1

        inputBox.Focused:Connect(function()
            inputStroke.Color = parentLib.AccentColor
        end)

        inputBox.FocusLost:Connect(function()
            inputStroke.Color = Theme.Border
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
        Card.BackgroundColor3 = Theme.Card
        Card.BorderSizePixel = 0
        Card.Parent = container

        local titleLabel = Instance.new("TextLabel", Card)
        titleLabel.Size = UDim2.new(1, -24, 0, 16)
        titleLabel.Position = UDim2.new(0, 12, 0, 8)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.RobotoMono
        titleLabel.Text = title
        titleLabel.TextColor3 = parentLib.AccentColor
        titleLabel.TextSize = FontSize(10)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left

        parentLib:RegisterAccentListener(function(col)
            titleLabel.TextColor3 = col
        end)

        local bodyLabel = Instance.new("TextLabel", Card)
        bodyLabel.Size = UDim2.new(1, -24, 1, -32)
        bodyLabel.Position = UDim2.new(0, 12, 0, 26)
        bodyLabel.BackgroundTransparency = 1
        bodyLabel.Font = Enum.Font.Roboto
        bodyLabel.Text = bodyText
        bodyLabel.TextColor3 = Theme.Body
        bodyLabel.TextSize = 11
        bodyLabel.TextWrapped = true
        bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
        bodyLabel.TextYAlignment = Enum.TextYAlignment.Top

        return bodyLabel
    end

    -- Column Layout (Side-by-side arrangement)
    function TabObj:CreateColumnLayout(callback)
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, 0, 0, 56)
        Row.BackgroundTransparency = 1
        Row.BorderSizePixel = 0
        Row.Parent = container

        local rowLayout = Instance.new("UIListLayout", Row)
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rowLayout.Padding = UDim.new(0, 10)

        local ColumnAPI = {}

        function ColumnAPI:CreateSideToggle(name, initialState, callback)
            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(0.5, -5, 1, 0)
            Card.BackgroundColor3 = Theme.Card
            Card.BorderSizePixel = 0
            Card.Parent = Row

            local title = Instance.new("TextLabel", Card)
            title.Size = UDim2.new(1, -54, 1, 0)
            title.Position = UDim2.new(0, 10, 0, 0)
            title.BackgroundTransparency = 1
            title.Font = Enum.Font.GothamMedium
            title.Text = name
            title.TextColor3 = Theme.Text
            title.TextSize = FontSize(11)
            title.TextXAlignment = Enum.TextXAlignment.Left

            local switchTrack = Instance.new("TextButton", Card)
            switchTrack.Size = UDim2.new(0, 38, 0, 20)
            switchTrack.Position = UDim2.new(1, -46, 0.5, -10)
            switchTrack.BackgroundColor3 = Theme.Input
            switchTrack.AutoButtonColor = false
            switchTrack.Text = ""
            local trackStroke = CreateStroke(switchTrack)
            trackStroke.Color = Theme.Border
            trackStroke.Thickness = 1

            local switchThumb = Instance.new("Frame", switchTrack)
            switchThumb.Size = UDim2.new(0, 16, 0, 16)
            switchThumb.Position = UDim2.new(0, 2, 0.5, -8)
            switchThumb.BackgroundColor3 = Theme.Thumb
            switchThumb.BorderSizePixel = 0

            local enabled = initialState or false
            if enabled then
                switchThumb.Position = UDim2.new(1, -18, 0.5, -8)
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
        Card.BackgroundColor3 = Theme.Card
        Card.BorderSizePixel = 0
        Card.Parent = container

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -80, 0, 20)
        title.Position = UDim2.new(0, 12, 0, 9)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamMedium
        title.Text = name
        title.TextColor3 = Theme.Text
        title.TextSize = FontSize(13)
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", Card)
        desc.Size = UDim2.new(1, -80, 0, IS_DESKTOP and 30 or 26)
        desc.Position = UDim2.new(0, 12, 0, 31)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Roboto
        desc.Text = description
        desc.TextColor3 = Theme.Muted
        desc.TextSize = FontSize(11)
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top

        local switchTrack = Instance.new("TextButton", Card)
        switchTrack.Size = UDim2.new(0, 40, 0, 20)
        switchTrack.Position = UDim2.new(1, -52, 0.5, -10)
        switchTrack.BackgroundColor3 = Theme.Input
        switchTrack.AutoButtonColor = false
        switchTrack.Text = ""
        local trackStroke = CreateStroke(switchTrack)
        trackStroke.Color = Theme.Border
        trackStroke.Thickness = 1

        local switchThumb = Instance.new("Frame", switchTrack)
        switchThumb.Size = UDim2.new(0, 16, 0, 16)
        switchThumb.Position = UDim2.new(0, 2, 0.5, -8)
        switchThumb.BackgroundColor3 = Theme.Thumb
        switchThumb.BorderSizePixel = 0

        local enabled = initialState or false
        if enabled then
            switchThumb.Position = UDim2.new(1, -18, 0.5, -8)
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
        Card.BackgroundColor3 = Theme.Card
        Card.BorderSizePixel = 0
        Card.Parent = container

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -130, 0, 20)
        title.Position = UDim2.new(0, 12, 0, 9)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamMedium
        title.Text = name
        title.TextColor3 = Theme.Text
        title.TextSize = FontSize(13)
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", Card)
        desc.Size = UDim2.new(1, -130, 0, IS_DESKTOP and 30 or 26)
        desc.Position = UDim2.new(0, 12, 0, 31)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Roboto
        desc.Text = description
        desc.TextColor3 = Theme.Muted
        desc.TextSize = FontSize(11)
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top

        local inputBox = Instance.new("TextBox", Card)
        inputBox.Size = UDim2.new(0, 50, 0, 26)
        inputBox.Position = UDim2.new(1, -114, 0.5, -13)
        inputBox.BackgroundColor3 = Theme.Input
        inputBox.BorderSizePixel = 0
        inputBox.Font = Enum.Font.RobotoMono
        inputBox.Text = tostring(defaultValue or 24)
        inputBox.TextColor3 = Theme.Text
        inputBox.TextSize = FontSize(12)
        inputBox.ClearTextOnFocus = false
        local inputStroke = CreateStroke(inputBox)
        inputStroke.Color = Theme.Border
        inputStroke.Thickness = 1

        inputBox.Focused:Connect(function()
            inputStroke.Color = parentLib.AccentColor
        end)

        inputBox.FocusLost:Connect(function()
            inputStroke.Color = Theme.Border
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
        switchTrack.Size = UDim2.new(0, 40, 0, 20)
        switchTrack.Position = UDim2.new(1, -52, 0.5, -10)
        switchTrack.BackgroundColor3 = Theme.Input
        switchTrack.AutoButtonColor = false
        switchTrack.Text = ""
        local trackStroke = CreateStroke(switchTrack)
        trackStroke.Color = Theme.Border
        trackStroke.Thickness = 1

        local switchThumb = Instance.new("Frame", switchTrack)
        switchThumb.Size = UDim2.new(0, 16, 0, 16)
        switchThumb.Position = UDim2.new(0, 2, 0.5, -8)
        switchThumb.BackgroundColor3 = Theme.Thumb
        switchThumb.BorderSizePixel = 0

        local enabled = initialState or false
        if enabled then
            switchThumb.Position = UDim2.new(1, -18, 0.5, -8)
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
        Card.BackgroundColor3 = Theme.Card
        Card.BorderSizePixel = 0
        Card.Parent = container

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -120, 0, 20)
        title.Position = UDim2.new(0, 12, 0, 9)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamMedium
        title.Text = name
        title.TextColor3 = Theme.Text
        title.TextSize = FontSize(13)
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", Card)
        desc.Size = UDim2.new(1, -120, 0, IS_DESKTOP and 30 or 26)
        desc.Position = UDim2.new(0, 12, 0, 31)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Roboto
        desc.Text = description
        desc.TextColor3 = Theme.Muted
        desc.TextSize = FontSize(11)
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top

        local paletteButton = Instance.new("TextButton", Card)
        paletteButton.Size = UDim2.new(0, 28, 0, 22)
        paletteButton.Position = UDim2.new(1, -96, 0.5, -11)
        paletteButton.BackgroundColor3 = defaultColor or parentLib.AccentColor
        paletteButton.AutoButtonColor = false
        paletteButton.Text = ""
        local paletteStroke = CreateStroke(paletteButton)
        paletteStroke.Color = Theme.Text
        paletteStroke.Thickness = 1

        local colorAPI = CreateColorPopup(parentLib, name, defaultColor, colorCallback, paletteButton)

        local switchTrack = Instance.new("TextButton", Card)
        switchTrack.Size = UDim2.new(0, 40, 0, 20)
        switchTrack.Position = UDim2.new(1, -52, 0.5, -10)
        switchTrack.BackgroundColor3 = Theme.Input
        switchTrack.AutoButtonColor = false
        switchTrack.Text = ""
        local trackStroke = CreateStroke(switchTrack)
        trackStroke.Color = Theme.Border
        trackStroke.Thickness = 1

        local switchThumb = Instance.new("Frame", switchTrack)
        switchThumb.Size = UDim2.new(0, 16, 0, 16)
        switchThumb.Position = UDim2.new(0, 2, 0.5, -8)
        switchThumb.BackgroundColor3 = Theme.Thumb
        switchThumb.BorderSizePixel = 0

        local enabled = initialState or false
        if enabled then
            switchThumb.Position = UDim2.new(1, -18, 0.5, -8)
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
        Card.BackgroundColor3 = Theme.Card
        Card.BorderSizePixel = 0
        Card.Parent = container

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -80, 0, 20)
        title.Position = UDim2.new(0, 12, 0, 9)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamMedium
        title.Text = name
        title.TextColor3 = Theme.Text
        title.TextSize = FontSize(13)
        title.TextXAlignment = Enum.TextXAlignment.Left

        local desc = Instance.new("TextLabel", Card)
        desc.Size = UDim2.new(1, -80, 0, IS_DESKTOP and 30 or 26)
        desc.Position = UDim2.new(0, 12, 0, 31)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Roboto
        desc.Text = description
        desc.TextColor3 = Theme.Muted
        desc.TextSize = FontSize(11)
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top

        local paletteButton = Instance.new("TextButton", Card)
        paletteButton.Size = UDim2.new(0, 34, 0, 26)
        paletteButton.Position = UDim2.new(1, -46, 0.5, -13)
        paletteButton.BackgroundColor3 = defaultColor or parentLib.AccentColor
        paletteButton.AutoButtonColor = false
        paletteButton.Text = ""
        local paletteStroke = CreateStroke(paletteButton)
        paletteStroke.Color = Theme.Text
        paletteStroke.Thickness = 1

        return CreateColorPopup(parentLib, name, defaultColor, callback, paletteButton)
    end

    -- 5. Keybind Card Component (PC) -- matches the reference layout exactly.
    function TabObj:CreateKeybindCard()
        local Card = Instance.new("Frame")
        Card.Name = "KeybindCard"
        Card.Size = UDim2.new(1, 0, 0, 76)
        Card.BackgroundColor3 = Theme.Card
        Card.BorderSizePixel = 0
        Card.Parent = container

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(1, -24, 0, 20)
        title.Position = UDim2.new(0, 12, 0, 12)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamMedium
        title.Text = "Keybind Activation"
        title.TextColor3 = Theme.Text
        title.TextSize = FontSize(14)
        title.TextXAlignment = Enum.TextXAlignment.Left

        local keybindButton = Instance.new("TextButton", Card)
        keybindButton.Name = "KeybindButton"
        keybindButton.Size = UDim2.new(0, 112, 0, 26)
        keybindButton.Position = UDim2.new(0, 12, 0, 40)
        keybindButton.BackgroundColor3 = Theme.Input
        keybindButton.AutoButtonColor = false
        keybindButton.Font = Enum.Font.RobotoMono
        keybindButton.Text = parentLib.CurrentHideKey.Name
        keybindButton.TextColor3 = parentLib.AccentColor
        keybindButton.TextSize = FontSize(12)
        local keyStroke = CreateStroke(keybindButton)
        keyStroke.Color = Theme.Border
        keyStroke.Thickness = 1

        local hint = Instance.new("TextLabel", Card)
        hint.Size = UDim2.new(1, -148, 0, 26)
        hint.Position = UDim2.new(0, 136, 0, 40)
        hint.BackgroundTransparency = 1
        hint.Font = Enum.Font.Gotham
        hint.Text = "Press to minimize"
        hint.TextColor3 = Theme.Muted
        hint.TextSize = FontSize(12)
        hint.TextXAlignment = Enum.TextXAlignment.Left

        parentLib:RegisterAccentListener(function(col)
            if not parentLib.IsListeningForKey then
                keybindButton.TextColor3 = col
                keyStroke.Color = Theme.Border
            end
        end)

        local listening = false
        local function stopListening()
            listening = false
            parentLib.IsListeningForKey = false
            keybindButton.Text = parentLib.CurrentHideKey.Name
            keybindButton.TextColor3 = parentLib.AccentColor
            keyStroke.Color = Theme.Border
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
            keyStroke.Color = Color3.fromRGB(255, 200, 50)
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
            keyStroke.Color = Theme.Border
            listening = false
            parentLib.IsListeningForKey = false
            parentLib:SaveSettings()
        end)

        local API = {}
        function API:GetKey()
            return parentLib.CurrentHideKey
        end
        function API:GetButton()
            return keybindButton
        end
        return API
    end

    -- 6. Kill Script Button. Sits above the footer with a clear gap so it
    -- never covers the status/brand row or scrolls with the tab content.
    function TabObj:CreateKillButton(text, callback, contentHeight)
        local button = Instance.new("TextButton")
        button.Name = "KillScriptButton"
        button.Size = UDim2.new(1, -36, 0, 36)
        button.Position = UDim2.new(0, 18, 1, -86)
        button.BackgroundColor3 = Theme.RedBg
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Text = ""
        button.Visible = false
        button.Parent = parentLib.MainFrame

        local stroke = CreateStroke(button)
        stroke.Color = Theme.RedBorder
        stroke.Thickness = 1

        local icon = Instance.new("Frame")
        icon.Name = "KillIcon"
        icon.Size = UDim2.new(0, 14, 0, 14)
        icon.Position = UDim2.new(0.5, -92, 0.5, -7)
        icon.BackgroundTransparency = 1
        icon.Parent = button

        local iconStroke = CreateStroke(icon)
        iconStroke.Color = Theme.RedDim
        iconStroke.Thickness = 1

        local slash = Instance.new("Frame")
        slash.Size = UDim2.new(0, 18, 0, 1)
        slash.AnchorPoint = Vector2.new(0.5, 0.5)
        slash.Position = UDim2.new(0.5, 0, 0.5, 0)
        slash.Rotation = -45
        slash.BackgroundColor3 = Theme.RedDim
        slash.BorderSizePixel = 0
        slash.Parent = icon

        local label = Instance.new("TextLabel", button)
        label.Size = UDim2.new(0, 200, 1, 0)
        label.AnchorPoint = Vector2.new(0.5, 0)
        label.Position = UDim2.new(0.5, 11, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.RobotoMono
        label.Text = text or "KILL SCRIPT & CLEANUP"
        label.TextColor3 = Theme.RedDim
        label.TextSize = FontSize(13)
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextTruncate = Enum.TextTruncate.AtEnd

        button.MouseEnter:Connect(function()
            if button.Parent then
                button.BackgroundColor3 = Color3.fromRGB(56, 25, 30)
                stroke.Color = Color3.fromRGB(124, 42, 48)
            end
        end)
        button.MouseLeave:Connect(function()
            if button.Parent then
                button.BackgroundColor3 = Theme.RedBg
                stroke.Color = Theme.RedBorder
            end
        end)
        button.Activated:Connect(function()
            if callback then
                pcall(callback)
            else
                parentLib:Unload()
            end
        end)

        entry.KillButton = button
        if contentHeight then
            entry.KillContentHeight = math.max(40, math.min(parentLib.ContentKillHeight, contentHeight))
        end
        return button
    end

    -- 7. Info Card Component
    function TabObj:CreateInfoCard(labelName, valueText)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 40)
        Card.BackgroundColor3 = Theme.Card
        Card.BorderSizePixel = 0
        Card.Parent = container

        local title = Instance.new("TextLabel", Card)
        title.Size = UDim2.new(0.5, 0, 1, 0)
        title.Position = UDim2.new(0, 12, 0, 0)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.RobotoMono
        title.Text = labelName
        title.TextColor3 = Theme.Section
        title.TextSize = FontSize(10)
        title.TextXAlignment = Enum.TextXAlignment.Left

        local value = Instance.new("TextLabel", Card)
        value.Size = UDim2.new(0.5, -24, 1, 0)
        value.Position = UDim2.new(0.5, 12, 0, 0)
        value.BackgroundTransparency = 1
        value.Font = Enum.Font.RobotoMono
        value.Text = valueText
        value.TextColor3 = Theme.Muted
        value.TextSize = FontSize(11)
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
