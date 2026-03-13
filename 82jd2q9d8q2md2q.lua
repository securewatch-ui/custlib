--// securewatch-ui Linoria-style Library (with Config System)

local Library = {}

---------------------------------------------------------------------
-- THEME
---------------------------------------------------------------------

Library.Theme = {
    Background = Color3.fromRGB(20, 20, 25),
    Border     = Color3.fromRGB(60, 60, 70),
    Accent     = Color3.fromRGB(255, 170, 200),
    Text       = Color3.fromRGB(235, 235, 245)
}

---------------------------------------------------------------------
-- SERVICES
---------------------------------------------------------------------

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

---------------------------------------------------------------------
-- SCREEN GUI
---------------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "securewatchUILib"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

Library._UIVisible = true

---------------------------------------------------------------------
-- ELEMENT REGISTRATION FOR CONFIGS
---------------------------------------------------------------------

Library.Elements = {} -- [ "Group.Element" ] = { type="toggle", set=function(val) end, get=function() end }

local function RegisterElement(group, name, element)
    Library.Elements[group .. "." .. name] = element
end

---------------------------------------------------------------------
-- CONFIG SYSTEM (.txt)
---------------------------------------------------------------------

Library.ConfigFolder = "securewatch-ui/configs"

local function EnsureFolder()
    if not isfolder("securewatch-ui") then
        makefolder("securewatch-ui")
    end
    if not isfolder(Library.ConfigFolder) then
        makefolder(Library.ConfigFolder)
    end
end

function Library:GetConfigs()
    EnsureFolder()
    local files = listfiles(Library.ConfigFolder)
    local configs = {}
    for _, f in ipairs(files) do
        if f:sub(-4) == ".txt" then
            table.insert(configs, f:match("([^/]+)%.txt$"))
        end
    end
    return configs
end

function Library:SaveConfig(name)
    EnsureFolder()
    local path = Library.ConfigFolder .. "/" .. name .. ".txt"

    local lines = {}

    for key, element in pairs(Library.Elements) do
        local value = element.get()

        if typeof(value) == "boolean" then
            table.insert(lines, key .. " = " .. tostring(value))
        elseif typeof(value) == "number" then
            table.insert(lines, key .. " = " .. tostring(value))
        elseif typeof(value) == "string" then
            table.insert(lines, key .. " = " .. value)
        end
    end

    writefile(path, table.concat(lines, "\n"))
    Library:Notify("Saved config: " .. name, 3)
end

function Library:LoadConfig(name)
    EnsureFolder()
    local path = Library.ConfigFolder .. "/" .. name .. ".txt"

    if not isfile(path) then
        Library:Notify("Config not found: " .. name, 3)
        return
    end

    local data = readfile(path)
    for line in data:gmatch("[^\r\n]+") do
        local key, value = line:match("^(.-)%s*=%s*(.+)$")
        if key and value then
            local element = Library.Elements[key]
            if element then
                if element.type == "toggle" then
                    element.set(value == "true")
                elseif element.type == "slider" then
                    element.set(tonumber(value))
                elseif element.type == "dropdown" then
                    element.set(value)
                elseif element.type == "keybind" then
                    element.set(value)
                end
            end
        end
    end

    Library:Notify("Loaded config: " .. name, 3)
end

---------------------------------------------------------------------
-- WINDOW + TOPBAR + DRAGGING + TABS
---------------------------------------------------------------------

function Library:Window(title)
    local Window = {}

    local Main = Instance.new("Frame")
    Main.Name = "MainWindow"
    Main.Size = UDim2.new(0, 600, 0, 400)
    Main.Position = UDim2.new(0.5, -300, 0.5, -200)
    Main.BackgroundColor3 = self.Theme.Background
    Main.BorderColor3 = self.Theme.Border
    Main.Active = true
    Main.Parent = ScreenGui

    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 28)
    Topbar.BackgroundColor3 = self.Theme.Background
    Topbar.BorderColor3 = self.Theme.Border
    Topbar.Parent = Main

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -10, 1, 0)
    TitleLabel.Position = UDim2.new(0, 5, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
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

    -- Tab bar
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(0, 120, 1, -28)
    TabBar.Position = UDim2.new(0, 0, 0, 28)
    TabBar.BackgroundColor3 = self.Theme.Background
    TabBar.BorderColor3 = self.Theme.Border
    TabBar.Parent = Main

    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 4)
    TabList.Parent = TabBar

    local TabContentHolder = Instance.new("Frame")
    TabContentHolder.Size = UDim2.new(1, -120, 1, -28)
    TabContentHolder.Position = UDim2.new(0, 120, 0, 28)
    TabContentHolder.BackgroundColor3 = self.Theme.Background
    TabContentHolder.BorderColor3 = self.Theme.Border
    TabContentHolder.Parent = Main

    local currentTab

    function Window:Tab(name)
        local Tab = {}

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, 0, 0, 24)
        Button.BackgroundColor3 = Library.Theme.Background
        Button.BorderColor3 = Library.Theme.Border
        Button.Text = name
        Button.Font = Enum.Font.Code
        Button.TextSize = 14
        Button.TextColor3 = Library.Theme.Text
        Button.Parent = TabBar

        local Content = Instance.new("Frame")
        Content.Size = UDim2.new(1, -10, 1, -10)
        Content.Position = UDim2.new(0, 5, 0, 5)
        Content.BackgroundTransparency = 1
        Content.Visible = false
        Content.Parent = TabContentHolder

        local Left = Instance.new("Frame")
        Left.Size = UDim2.new(0.5, -6, 1, 0)
        Left.BackgroundTransparency = 1
        Left.Parent = Content

        local Right = Instance.new("Frame")
        Right.Size = UDim2.new(0.5, -6, 1, 0)
        Right.Position = UDim2.new(0.5, 6, 0, 0)
        Right.BackgroundTransparency = 1
        Right.Parent = Content

        Tab.Left = Left
        Tab.Right = Right
        Tab.Button = Button
        Tab.Content = Content

        Button.MouseButton1Click:Connect(function()
            if currentTab then
                currentTab.Content.Visible = false
                currentTab.Button.BackgroundColor3 = Library.Theme.Background
            end
            currentTab = Tab
            currentTab.Content.Visible = true
            currentTab.Button.BackgroundColor3 = Library.Theme.Border
        end)

        if not currentTab then
            currentTab = Tab
            currentTab.Content.Visible = true
            currentTab.Button.BackgroundColor3 = Library.Theme.Border
        end

        function Tab:Group(gname, side)
            local parent = (side == "Right") and Right or Left
            return Library:CreateGroupbox(gname, parent)
        end

        return Tab
    end

    return Window
end

---------------------------------------------------------------------
-- GROUPBOX
---------------------------------------------------------------------

function Library:CreateGroupbox(name, parent)
    local Box = {}

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 200)
    Frame.BackgroundColor3 = self.Theme.Background
    Frame.BorderColor3 = self.Theme.Border
    Frame.Parent = parent

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -10, 0, 20)
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = name
    Title.Font = Enum.Font.Code
    Title.TextSize = 15
    Title.TextColor3 = self.Theme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame

    local Scroll = Instance.new("ScrollingFrame")
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

    function Box:Toggle(text, default, callback)
        return Library:CreateToggle(name, text, default, callback, Scroll)
    end

    function Box:Slider(text, min, max, default, callback)
        return Library:CreateSlider(name, text, min, max, default, callback, Scroll)
    end

    function Box:Dropdown(text, list, default, callback)
        return Library:CreateDropdown(name, text, list, default, callback, Scroll)
    end

    function Box:Keybind(text, defaultKey, mode, callback)
        return Library:CreateKeybind(name, text, defaultKey, mode, callback, Scroll)
    end

    function Box:Button(text, callback)
        return Library:CreateButton(name, text, callback, Scroll)
    end

    return Box
end

---------------------------------------------------------------------
-- ELEMENTS
---------------------------------------------------------------------

-- TOGGLE
function Library:CreateToggle(group, text, default, callback, parent)
    local Toggle = {}

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 22)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 1, 0)
    Button.BackgroundTransparency = 1
    Button.Text = ""
    Button.Parent = Frame

    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(0, 16, 0, 16)
    Box.Position = UDim2.new(0, 0, 0.5, -8)
    Box.BackgroundColor3 = Library.Theme.Background
    Box.BorderColor3 = Library.Theme.Border
    Box.Parent = Frame

    local Label = Instance.new("TextLabel")
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

    Toggle.set = function(val)
        state = val
        Update()
    end

    Toggle.get = function()
        return state
    end

    Toggle.type = "toggle"

    RegisterElement(group, text, Toggle)

    return Toggle
end

---------------------------------------------------------------------
-- SLIDER
---------------------------------------------------------------------

function Library:CreateSlider(group, text, min, max, default, callback, parent)
    local Slider = {}

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 40)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 16)
    Label.BackgroundTransparency = 1
    Label.Text = text .. " (" .. default .. ")"
    Label.Font = Enum.Font.Code
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, 0, 0, 6)
    Bar.Position = UDim2.new(0, 0, 0, 22)
    Bar.BackgroundColor3 = Library.Theme.Background
    Bar.BorderColor3 = Library.Theme.Border
    Bar.Parent = Frame

    local Fill = Instance.new("Frame")
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

    Slider.set = function(val)
        value = val
        local rel = (val - min) / (max - min)
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Label.Text = text .. " (" .. value .. ")"
    end

    Slider.get = function()
        return value
    end

    Slider.type = "slider"

    RegisterElement(group, text, Slider)

    return Slider
end

---------------------------------------------------------------------
-- DROPDOWN
---------------------------------------------------------------------

function Library:CreateDropdown(group, text, list, default, callback, parent)
    local Dropdown = {}

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 26)
    Frame.BackgroundColor3 = Library.Theme.Background
    Frame.BorderColor3 = Library.Theme.Border
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 1, 0)
    Label.Position = UDim2.new(0, 5, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. (default or list[1])
    Label.Font = Enum.Font.Code
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Open = false

    local ListFrame = Instance.new("Frame")
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

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Open = not Open
            ListFrame.Visible = Open
        end
    end)

    Dropdown.set = function(val)
        Label.Text = text .. ": " .. val
    end

    Dropdown.get = function()
        return Label.Text:sub(#text + 3)
    end

    Dropdown.type = "dropdown"

    RegisterElement(group, text, Dropdown)

    return Dropdown
end

---------------------------------------------------------------------
-- KEYBIND
---------------------------------------------------------------------

function Library:CreateKeybind(group, text, defaultKey, mode, callback, parent)
    local Keybind = {}

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 22)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.5, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.Code
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Button = Instance.new("TextButton")
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
                if callback then callback() end
            end
        end
    end)

    Keybind.set = function(val)
        currentKey = Enum.KeyCode[val] or Enum.KeyCode.Q
        Button.Text = val
    end

    Keybind.get = function()
        return Button.Text
    end

    Keybind.type = "keybind"

    RegisterElement(group, text, Keybind)

    return Keybind
end

---------------------------------------------------------------------
-- BUTTON
---------------------------------------------------------------------

function Library:CreateButton(group, text, callback, parent)
    local Button = Instance.new("TextButton")
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
