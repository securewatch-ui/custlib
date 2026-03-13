--// securewatch-ui Linoria-style Library

local Library = {}

-- THEME
Library.Theme = {
    Background = Color3.fromRGB(20, 20, 25),
    Border     = Color3.fromRGB(60, 60, 70),
    Accent     = Color3.fromRGB(255, 170, 200), -- pastel pink
    Text       = Color3.fromRGB(235, 235, 245)
}

-- SCREEN GUI
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "securewatchUILib"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

Library._UIVisible = true

---------------------------------------------------------------------
-- WINDOW + TOPBAR + DRAGGING + TAB CONTAINER
---------------------------------------------------------------------

function Library:Window(title)
    local Window = {}

    -- Main window frame
    local Main = Instance.new("Frame")
    Main.Name = "MainWindow"
    Main.Size = UDim2.new(0, 600, 0, 400)
    Main.Position = UDim2.new(0.5, -300, 0.5, -200)
    Main.BackgroundColor3 = self.Theme.Background
    Main.BorderColor3 = self.Theme.Border
    Main.Active = true
    Main.Draggable = false
    Main.Parent = ScreenGui

    -- Topbar
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 28)
    Topbar.BackgroundColor3 = self.Theme.Background
    Topbar.BorderColor3 = self.Theme.Border
    Topbar.Parent = Main

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, -10, 1, 0)
    TitleLabel.Position = UDim2.new(0, 5, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title or "securewatch-ui"
    TitleLabel.Font = Enum.Font.Code
    TitleLabel.TextSize = 16
    TitleLabel.TextColor3 = self.Theme.Text
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Topbar

    -- Dragging
    do
        local dragging = false
        local dragStart, startPos

        Topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position
            end
        end)

        Topbar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- Tab buttons container
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(0, 120, 1, -28)
    TabBar.Position = UDim2.new(0, 0, 0, 28)
    TabBar.BackgroundColor3 = self.Theme.Background
    TabBar.BorderColor3 = self.Theme.Border
    TabBar.Parent = Main

    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 4)
    TabList.FillDirection = Enum.FillDirection.Vertical
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Parent = TabBar

    -- Tab content area
    local TabContentHolder = Instance.new("Frame")
    TabContentHolder.Name = "TabContentHolder"
    TabContentHolder.Size = UDim2.new(1, -120, 1, -28)
    TabContentHolder.Position = UDim2.new(0, 120, 0, 28)
    TabContentHolder.BackgroundColor3 = self.Theme.Background
    TabContentHolder.BorderColor3 = self.Theme.Border
    TabContentHolder.Parent = Main

    local currentTab

    -----------------------------------------------------------------
    -- TAB CREATION
    -----------------------------------------------------------------
    function Window:Tab(name)
        local Tab = {}

        -- Tab button
        local Button = Instance.new("TextButton")
        Button.Name = name .. "_TabButton"
        Button.Size = UDim2.new(1, 0, 0, 24)
        Button.BackgroundColor3 = Library.Theme.Background
        Button.BorderColor3 = Library.Theme.Border
        Button.Text = name
        Button.Font = Enum.Font.Code
        Button.TextSize = 14
        Button.TextColor3 = Library.Theme.Text
        Button.Parent = TabBar

        -- Tab content frame
        local Content = Instance.new("Frame")
        Content.Name = name .. "_Content"
        Content.Size = UDim2.new(1, -10, 1, -10)
        Content.Position = UDim2.new(0, 5, 0, 5)
        Content.BackgroundTransparency = 1
        Content.Visible = false
        Content.Parent = TabContentHolder

        -- Left and Right columns
        local Left = Instance.new("Frame")
        Left.Name = "Left"
        Left.Size = UDim2.new(0.5, -6, 1, 0)
        Left.Position = UDim2.new(0, 0, 0, 0)
        Left.BackgroundTransparency = 1
        Left.Parent = Content

        local Right = Instance.new("Frame")
        Right.Name = "Right"
        Right.Size = UDim2.new(0.5, -6, 1, 0)
        Right.Position = UDim2.new(0.5, 6, 0, 0)
        Right.BackgroundTransparency = 1
        Right.Parent = Content

        Tab.Left = Left
        Tab.Right = Right
        Tab.Button = Button
        Tab.Content = Content

        -- Tab switching
        Button.MouseButton1Click:Connect(function()
            if currentTab then
                currentTab.Content.Visible = false
                currentTab.Button.BackgroundColor3 = Library.Theme.Background
            end
            currentTab = Tab
            currentTab.Content.Visible = true
            currentTab.Button.BackgroundColor3 = Library.Theme.Border
        end)

        -- Default to first tab
        if not currentTab then
            currentTab = Tab
            currentTab.Content.Visible = true
            currentTab.Button.BackgroundColor3 = Library.Theme.Border
        end

        -- Groupbox creation
        function Tab:Group(gname, side)
            local parent = (side == "Right") and Right or Left
            return Library:CreateGroupbox(gname, parent)
        end

        return Tab
    end

    return Window
end

---------------------------------------------------------------------
-- GROUPBOX SYSTEM
---------------------------------------------------------------------

function Library:CreateGroupbox(name, parent)
    local Box = {}

    -- Outer frame
    local Frame = Instance.new("Frame")
    Frame.Name = name .. "_Groupbox"
    Frame.Size = UDim2.new(1, -10, 0, 200) -- fixed height
    Frame.BackgroundColor3 = self.Theme.Background
    Frame.BorderColor3 = self.Theme.Border
    Frame.Parent = parent

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -10, 0, 20)
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = name
    Title.Font = Enum.Font.Code
    Title.TextSize = 15
    Title.TextColor3 = self.Theme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame

    -- Scroll area
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Name = "ScrollArea"
    Scroll.Size = UDim2.new(1, -10, 1, -30)
    Scroll.Position = UDim2.new(0, 5, 0, 25)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.ScrollBarThickness = 2
    Scroll.ScrollBarImageColor3 = self.Theme.Accent
    Scroll.Parent = Frame

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 8)
    Layout.Parent = Scroll

    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y)
    end)

    Box.Frame = Frame
    Box.Scroll = Scroll

    -----------------------------------------------------------------
    -- GROUPBOX ELEMENT BINDINGS
    -----------------------------------------------------------------

    function Box:Toggle(text, default, callback)
        return Library:CreateToggle(text, default, callback, self.Scroll)
    end

    function Box:Keybind(text, defaultKey, mode, callback)
        return Library:CreateKeybind(text, defaultKey, mode, callback, self.Scroll)
    end

    function Box:Button(text, callback)
        return Library:CreateButton(text, callback, self.Scroll)
    end

    function Box:Slider(text, min, max, default, callback)
        return Library:CreateSlider(text, min, max, default, callback, self.Scroll)
    end

    function Box:Dropdown(text, list, default, callback)
        return Library:CreateDropdown(text, list, default, callback, self.Scroll)
    end

    return Box
end

---------------------------------------------------------------------
-- ELEMENTS
---------------------------------------------------------------------

-- TOGGLE
function Library:CreateToggle(text, default, callback, parent)
    local Toggle = {}

    local Frame = Instance.new("Frame")
    Frame.Name = text .. "_Toggle"
    Frame.Size = UDim2.new(1, -10, 0, 22)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Button = Instance.new("TextButton")
    Button.Name = "Button"
    Button.Size = UDim2.new(1, 0, 1, 0)
    Button.BackgroundTransparency = 1
    Button.Text = ""
    Button.Parent = Frame

    local Box = Instance.new("Frame")
    Box.Name = "Box"
    Box.Size = UDim2.new(0, 16, 0, 16)
    Box.Position = UDim2.new(0, 0, 0.5, -8)
    Box.BackgroundColor3 = Library.Theme.Background
    Box.BorderColor3 = Library.Theme.Border
    Box.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -24, 1, 0)
    Label.Position = UDim2.new(0, 24, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.Code
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local state = default or false

    local function Update()
        Box.BackgroundColor3 = state and Library.Theme.Accent or Library.Theme.Background
        if callback then
            task.spawn(callback, state)
        end
    end

    Button.MouseButton1Click:Connect(function()
        state = not state
        Update()
    end)

    Update()

    function Toggle:Set(val)
        state = val
        Update()
    end

    Toggle.Frame = Frame
    return Toggle
end

-- KEYBIND
function Library:CreateKeybind(text, defaultKey, mode, callback, parent)
    local Keybind = {}

    local Frame = Instance.new("Frame")
    Frame.Name = text .. "_Keybind"
    Frame.Size = UDim2.new(1, -10, 0, 22)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(0.5, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.Code
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Button = Instance.new("TextButton")
    Button.Name = "KeyButton"
    Button.Size = UDim2.new(0.5, -5, 1, 0)
    Button.Position = UDim2.new(0.5, 5, 0, 0)
    Button.BackgroundColor3 = Library.Theme.Background
    Button.BorderColor3 = Library.Theme.Border
    Button.Text = defaultKey or "Q"
    Button.Font = Enum.Font.Code
    Button.TextSize = 14
    Button.TextColor3 = Library.Theme.Text
    Button.Parent = Frame

    local binding = false
    local currentKey = Enum.KeyCode[defaultKey] or Enum.KeyCode.Q
    local bindMode = mode or "Toggle"

    Button.MouseButton1Click:Connect(function()
        binding = true
        Button.Text = "..."
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end

        if binding then
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                currentKey = input.KeyCode
                Button.Text = input.KeyCode.Name
                binding = false
            end
        else
            if input.KeyCode == currentKey then
                if callback then
                    task.spawn(callback)
                end
            end
        end
    end)

    Keybind.Frame = Frame
    return Keybind
end

-- BUTTON
function Library:CreateButton(text, callback, parent)
    local Button = Instance.new("TextButton")
    Button.Name = text .. "_Button"
    Button.Size = UDim2.new(1, -10, 0, 26)
    Button.BackgroundColor3 = Library.Theme.Background
    Button.BorderColor3 = Library.Theme.Border
    Button.Text = text
    Button.Font = Enum.Font.Code
    Button.TextSize = 14
    Button.TextColor3 = Library.Theme.Text
    Button.Parent = parent

    Button.MouseButton1Click:Connect(function()
        if callback then
            task.spawn(callback)
        end
    end)

    return Button
end

-- SLIDER
function Library:CreateSlider(text, min, max, default, callback, parent)
    local Slider = {}

    local Frame = Instance.new("Frame")
    Frame.Name = text .. "_Slider"
    Frame.Size = UDim2.new(1, -10, 0, 40)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, 0, 0, 16)
    Label.BackgroundTransparency = 1
    Label.Text = text .. " (" .. default .. ")"
    Label.Font = Enum.Font.Code
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Bar = Instance.new("Frame")
    Bar.Name = "Bar"
    Bar.Size = UDim2.new(1, 0, 0, 6)
    Bar.Position = UDim2.new(0, 0, 0, 22)
    Bar.BackgroundColor3 = Library.Theme.Background
    Bar.BorderColor3 = Library.Theme.Border
    Bar.Parent = Frame

    local Fill = Instance.new("Frame")
    Fill.Name = "Fill"
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Library.Theme.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar

    local dragging = false
    local value = default

    local function Update(inputX)
        local rel = math.clamp((inputX - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * rel)
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Label.Text = text .. " (" .. value .. ")"
        if callback then
            task.spawn(callback, value)
        end
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            Update(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            Update(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    Slider.Frame = Frame
    return Slider
end

-- DROPDOWN
function Library:CreateDropdown(text, list, default, callback, parent)
    local Dropdown = {}

    local Frame = Instance.new("Frame")
    Frame.Name = text .. "_Dropdown"
    Frame.Size = UDim2.new(1, -10, 0, 26)
    Frame.BackgroundColor3 = Library.Theme.Background
    Frame.BorderColor3 = Library.Theme.Border
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -10, 1, 0)
    Label.Position = UDim2.new(0, 5, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. (default or (list[1] or ""))
    Label.Font = Enum.Font.Code
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Open = false

    local ListFrame = Instance.new("Frame")
    ListFrame.Name = "List"
    ListFrame.Size = UDim2.new(1, 0, 0, #list * 22)
    ListFrame.Position = UDim2.new(0, 0, 1, 2)
    ListFrame.BackgroundColor3 = Library.Theme.Background
    ListFrame.BorderColor3 = Library.Theme.Border
    ListFrame.Visible = false
    ListFrame.Parent = Frame

    local Layout = Instance.new("UIListLayout")
    Layout.Parent = ListFrame

    for _, item in ipairs(list) do
        local Option = Instance.new("TextButton")
        Option.Size = UDim2.new(1, 0, 0, 22)
        Option.BackgroundTransparency = 1
        Option.Text = item
        Option.Font = Enum.Font.Code
        Option.TextSize = 14
        Option.TextColor3 = Library.Theme.Text
        Option.Parent = ListFrame

        Option.MouseButton1Click:Connect(function()
            Label.Text = text .. ": " .. item
            ListFrame.Visible = false
            Open = false
            if callback then
                task.spawn(callback, item)
            end
        end)
    end

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Open = not Open
            ListFrame.Visible = Open
        end
    end)

    Dropdown.Frame = Frame
    return Dropdown
end

---------------------------------------------------------------------
-- NOTIFICATION SYSTEM
---------------------------------------------------------------------

function Library:Notify(text, duration)
    duration = duration or 3

    local Notif = Instance.new("Frame")
    Notif.Name = "Notification"
    Notif.Size = UDim2.new(0, 250, 0, 40)
    Notif.Position = UDim2.new(1, -260, 0, 10)
    Notif.BackgroundColor3 = self.Theme.Background
    Notif.BorderColor3 = self.Theme.Border
    Notif.BackgroundTransparency = 0
    Notif.Parent = ScreenGui

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 1, 0)
    Label.Position = UDim2.new(0, 5, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.Code
    Label.TextSize = 14
    Label.TextColor3 = self.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Notif

    Notif.BackgroundTransparency = 1
    Label.TextTransparency = 1

    task.spawn(function()
        for i = 1, 10 do
            Notif.BackgroundTransparency = 1 - (i / 10)
            Label.TextTransparency = 1 - (i / 10)
            task.wait(0.02)
        end

        task.wait(duration)

        for i = 1, 10 do
            Notif.BackgroundTransparency = i / 10
            Label.TextTransparency = i / 10
            task.wait(0.02)
        end

        Notif:Destroy()
    end)
end

---------------------------------------------------------------------
-- WATERMARK
---------------------------------------------------------------------

function Library:Watermark(text)
    if self._Watermark then
        self._Watermark.Text = text
        return
    end

    local Mark = Instance.new("TextLabel")
    Mark.Name = "Watermark"
    Mark.Size = UDim2.new(0, 260, 0, 20)
    Mark.Position = UDim2.new(0, 10, 0, 10)
    Mark.BackgroundColor3 = self.Theme.Background
    Mark.BorderColor3 = self.Theme.Border
    Mark.Font = Enum.Font.Code
    Mark.TextSize = 14
    Mark.TextColor3 = self.Theme.Text
    Mark.TextXAlignment = Enum.TextXAlignment.Left
    Mark.Text = text
    Mark.Parent = ScreenGui

    self._Watermark = Mark
end

---------------------------------------------------------------------
-- UI TOGGLE KEYBIND
---------------------------------------------------------------------

Library.ToggleKey = Enum.KeyCode.RightShift

function Library:SetToggleKey(keycode)
    self.ToggleKey = keycode
end

function Library:ToggleUI()
    self._UIVisible = not self._UIVisible
    ScreenGui.Enabled = self._UIVisible
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Library.ToggleKey then
        Library:ToggleUI()
    end
end)

---------------------------------------------------------------------
-- RETURN LIBRARY
---------------------------------------------------------------------

return Library
