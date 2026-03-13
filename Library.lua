local Library = {}

-- THEME (your pastel pink defaults)
Library.Theme = {
    Accent       = Color3.fromRGB(255, 170, 200),
    AccentDark   = Color3.fromRGB(210, 130, 165),
    Background   = Color3.fromRGB(25, 20, 25),
    Main         = Color3.fromRGB(20, 16, 20),
    Topbar       = Color3.fromRGB(30, 25, 30),
    Border       = Color3.fromRGB(255, 170, 200),
    Text         = Color3.fromRGB(255, 255, 255)
}

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KittywareUI"
ScreenGui.Parent = game:GetService("CoreGui")

-- WINDOW CREATION
function Library:Window(title)
    local Window = {}

    -- Main frame
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 600, 0, 450)
    Main.Position = UDim2.new(0.5, -300, 0.5, -225)
    Main.BackgroundColor3 = self.Theme.Main
    Main.BorderColor3 = self.Theme.Border
    Main.Parent = ScreenGui

    -- Topbar
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 30)
    Topbar.BackgroundColor3 = self.Theme.Topbar
    Topbar.BorderColor3 = self.Theme.Border
    Topbar.Parent = Main

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -10, 1, 0)
    Title.Position = UDim2.new(0, 5, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = title
    Title.Font = Enum.Font.Code
    Title.TextSize = 16
    Title.TextColor3 = self.Theme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Topbar

    -- Dragging
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

    game:GetService("UserInputService").InputChanged:Connect(function(input)
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

    -- Store references
    Window.Main = Main
    Window.Topbar = Topbar

    -- Tabs will be added later
    function Window:Tab(name)
        -- placeholder, implemented in Step 2
    end

    return Window
end

-- TAB SYSTEM
function Library:CreateTabButton(name, parent)
    local Button = Instance.new("TextButton")
    Button.Name = name .. "_TabButton"
    Button.Size = UDim2.new(0, 100, 1, 0)
    Button.BackgroundTransparency = 1
    Button.Text = name
    Button.Font = Enum.Font.Code
    Button.TextSize = 15
    Button.TextColor3 = self.Theme.Text
    Button.Parent = parent
    return Button
end

function Library:Window(title)
    local Window = {}

    -- (this part stays the same from Step 1)
    -- Window.Main, Window.Topbar, dragging, etc.

    -- TAB BAR
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(1, 0, 0, 30)
    TabBar.Position = UDim2.new(0, 0, 0, 30)
    TabBar.BackgroundColor3 = self.Theme.Background
    TabBar.BorderColor3 = self.Theme.Border
    TabBar.Parent = Window.Main

    local TabButtons = Instance.new("Frame")
    TabButtons.Name = "TabButtons"
    TabButtons.Size = UDim2.new(1, -10, 1, 0)
    TabButtons.Position = UDim2.new(0, 5, 0, 0)
    TabButtons.BackgroundTransparency = 1
    TabButtons.Parent = TabBar

    local UIList = Instance.new("UIListLayout")
    UIList.FillDirection = Enum.FillDirection.Horizontal
    UIList.Padding = UDim.new(0, 10)
    UIList.Parent = TabButtons

    Window.Tabs = {}

    function Window:Tab(name)
        local Tab = {}

        -- Create tab button
        local Button = Library:CreateTabButton(name, TabButtons)

        -- Tab content frame
        local Content = Instance.new("Frame")
        Content.Name = name .. "_Content"
        Content.Size = UDim2.new(1, 0, 1, -60)
        Content.Position = UDim2.new(0, 0, 0, 60)
        Content.BackgroundTransparency = 1
        Content.Visible = false
        Content.Parent = Window.Main

        -- LEFT COLUMN
        local Left = Instance.new("Frame")
        Left.Name = "LeftColumn"
        Left.Size = UDim2.new(0.5, -10, 1, 0)
        Left.Position = UDim2.new(0, 10, 0, 0)
        Left.BackgroundTransparency = 1
        Left.Parent = Content

        -- RIGHT COLUMN
        local Right = Instance.new("Frame")
        Right.Name = "RightColumn"
        Right.Size = UDim2.new(0.5, -10, 1, 0)
        Right.Position = UDim2.new(0.5, 0, 0, 0)
        Right.BackgroundTransparency = 1
        Right.Parent = Content

        -- Store references
        Tab.Button = Button
        Tab.Content = Content
        Tab.Left = Left
        Tab.Right = Right

        -- Tab switching
        Button.MouseButton1Click:Connect(function()
            for _, t in pairs(Window.Tabs) do
                t.Content.Visible = false
                t.Button.TextColor3 = Library.Theme.Text
            end
            Content.Visible = true
            Button.TextColor3 = Library.Theme.Accent
        end)

        table.insert(Window.Tabs, Tab)

        -- First tab auto-select
        if #Window.Tabs == 1 then
            Content.Visible = true
            Button.TextColor3 = Library.Theme.Accent
        end

        -- Groupbox creation (Step 3)
        function Tab:Group(name, side)
            -- placeholder, implemented next
        end

        return Tab
    end

    return Window
end
-- GROUPBOX SYSTEM
function Library:CreateGroupbox(name, parent)
    local Box = {}

    -- Outer frame
    local Frame = Instance.new("Frame")
    Frame.Name = name .. "_Groupbox"
    Frame.Size = UDim2.new(1, -10, 0, 200) -- fixed height like Linoria
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
    Scroll.ScrollBarThickness = 2 -- thin Linoria-style scrollbar
    Scroll.ScrollBarImageColor3 = self.Theme.Accent
    Scroll.Parent = Frame

    -- Layout inside scroll area
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 8)
    Layout.Parent = Scroll

    -- Auto-update scroll size
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y)
    end)

    -- Store references
    Box.Frame = Frame
    Box.Scroll = Scroll

    -- ELEMENTS (added in Step 4)
    function Box:Toggle(text, default, callback)
        -- placeholder
    end

    function Box:Keybind(text, defaultKey, mode, callback)
        -- placeholder
    end
    function Box:Slider(text, min, max, default, callback)
       return Library:CreateSlider(text, min, max, default, callback, self.Scroll)
    end

    return Box
end

-- Attach groupbox creation to tabs
function Library:Window(title)
    local Window = {}

    -- (Window + Topbar + Tabs from Step 1 & 2)

    function Window:Tab(name)
        local Tab = {}

        -- (Tab button + content + columns from Step 2)

        function Tab:Group(name, side)
            local parent = (side == "Right") and Tab.Right or Tab.Left
            return Library:CreateGroupbox(name, parent)
        end

        return Tab
    end

    return Window
end
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
        if callback then callback(state) end
    end

    Button.MouseButton1Click:Connect(function()
        state = not state
        Update()
    end)

    Update()

    Toggle.Frame = Frame
    Toggle.Set = function(_, val)
        state = val
        Update()
    end

    return Toggle
end

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
    Button.Text = defaultKey
    Button.Font = Enum.Font.Code
    Button.TextSize = 14
    Button.TextColor3 = Library.Theme.Text
    Button.Parent = Frame

    local binding = false
    local currentKey = Enum.KeyCode[defaultKey] or Enum.KeyCode.Q

    Button.MouseButton1Click:Connect(function()
        binding = true
        Button.Text = "..."
    end)

    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if binding then
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                currentKey = input.KeyCode
                Button.Text = input.KeyCode.Name
                binding = false
            end
        else
            if input.KeyCode == currentKey then
                if callback then callback() end
            end
        end
    end)

    return Keybind
end

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
        if callback then callback() end
    end)

    return Button
end

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
        if callback then callback(value) end
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            Update(input.Position.X)
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            Update(input.Position.X)
        end
    end)

    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return Slider
end

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
    Label.Text = text .. ": " .. default
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
            if callback then callback(item) end
        end)
    end

    Frame.MouseButton1Click:Connect(function()
        Open = not Open
        ListFrame.Visible = Open
    end)

    return Dropdown
end

-- NOTIFICATION SYSTEM
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

    -- Fade in
    Notif.BackgroundTransparency = 1
    Label.TextTransparency = 1

    task.spawn(function()
        for i = 1, 10 do
            Notif.BackgroundTransparency = 1 - (i / 10)
            Label.TextTransparency = 1 - (i / 10)
            task.wait(0.02)
        end

        task.wait(duration)

        -- Fade out
        for i = 1, 10 do
            Notif.BackgroundTransparency = i / 10
            Label.TextTransparency = i / 10
            task.wait(0.02)
        end

        Notif:Destroy()
    end)
end

-- WATERMARK
function Library:Watermark(text)
    if self._Watermark then
        self._Watermark.Text = text
        return
    end

    local Mark = Instance.new("TextLabel")
    Mark.Name = "Watermark"
    Mark.Size = UDim2.new(0, 200, 0, 20)
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

-- UI TOGGLE KEYBIND
Library.ToggleKey = Enum.KeyCode.RightShift  -- default key

function Library:SetToggleKey(keycode)
    self.ToggleKey = keycode
end

function Library:ToggleUI()
    if not self._UIVisible then
        self._UIVisible = true
        ScreenGui.Enabled = true
    else
        self._UIVisible = false
        ScreenGui.Enabled = false
    end
end




return Library
