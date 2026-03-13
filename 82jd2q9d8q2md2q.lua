--// securewatch-ui Library (Modern, Fixed: Configs + Watermark + Extras)
-- Full single-file library with fixes for config dropdown nil errors,
-- watermark visibility fallback to PlayerGui, dynamic config dropdown,
-- notification queue, blur, theme switcher, color picker, searchable dropdown,
-- drag + resize, and AttachConfigTab improvements.

local Library = {}

---------------------------------------------------------------------
-- SERVICES
---------------------------------------------------------------------

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")

---------------------------------------------------------------------
-- THEMES
---------------------------------------------------------------------

Library.Themes = {
    Pastel = {
        Background     = Color3.fromRGB(32, 32, 38),
        BackgroundAlt  = Color3.fromRGB(26, 26, 32),
        Border         = Color3.fromRGB(80, 80, 95),
        Accent         = Color3.fromRGB(255, 160, 200),
        AccentDark     = Color3.fromRGB(210, 120, 170),
        Text           = Color3.fromRGB(245, 240, 250),
        TextDim        = Color3.fromRGB(190, 185, 200)
    },
    Dark = {
        Background     = Color3.fromRGB(18, 18, 22),
        BackgroundAlt  = Color3.fromRGB(14, 14, 18),
        Border         = Color3.fromRGB(60, 60, 70),
        Accent         = Color3.fromRGB(120, 180, 255),
        AccentDark     = Color3.fromRGB(80, 130, 210),
        Text           = Color3.fromRGB(235, 235, 245),
        TextDim        = Color3.fromRGB(170, 170, 190)
    }
}

Library.Theme = Library.Themes.Pastel

---------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------

local function Round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
    return c
end

local function Stroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function SafeParentGui(gui)
    -- Try PlayerGui first (more compatible), fallback to CoreGui
    local pg = (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")) or nil
    if pg then
        gui.Parent = pg
    else
        gui.Parent = CoreGui
    end
    -- Ensure it's on top
    if gui:IsA("ScreenGui") then
        pcall(function() gui.DisplayOrder = 9999 end)
    end
end

local function SafePing()
    local ok, val = pcall(function()
        local item = Stats.Network and Stats.Network.ServerStatsItem and Stats.Network.ServerStatsItem["Data Ping"]
        if item then
            return math.floor(item:GetValue())
        end
        return 0
    end)
    if ok and val then
        return val
    end
    return 0
end

---------------------------------------------------------------------
-- MAIN SCREEN GUI
---------------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "securewatchUILib"
ScreenGui.ResetOnSpawn = false
SafeParentGui(ScreenGui)

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
            local name = f:match("([^/\\]+)%.txt$")
            if name then
                table.insert(configs, name)
            end
        end
    end
    table.sort(configs)
    return configs
end

function Library:SaveConfig(name)
    EnsureFolder()
    local path = Library.ConfigFolder .. "/" .. name .. ".txt"

    local lines = {}

    for key, element in pairs(Library.Elements) do
        local ok, value = pcall(function() return element.get() end)
        if not ok then value = nil end

        if typeof(value) == "boolean" then
            table.insert(lines, key .. " = " .. tostring(value))
        elseif typeof(value) == "number" then
            table.insert(lines, key .. " = " .. tostring(value))
        elseif typeof(value) == "string" then
            table.insert(lines, key .. " = " .. value)
        elseif typeof(value) == "Color3" then
            local r, g, b = math.floor(value.R * 255), math.floor(value.G * 255), math.floor(value.B * 255)
            table.insert(lines, key .. " = " .. r .. "," .. g .. "," .. b)
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
                    pcall(function() element.set(value == "true") end)
                elseif element.type == "slider" then
                    pcall(function() element.set(tonumber(value)) end)
                elseif element.type == "dropdown" or element.type == "searchdropdown" then
                    pcall(function() element.set(value) end)
                elseif element.type == "keybind" then
                    pcall(function() element.set(value) end)
                elseif element.type == "colorpicker" then
                    local r, g, b = value:match("(%d+),(%d+),(%d+)")
                    if r and g and b then
                        pcall(function() element.set(Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))) end)
                    end
                end
            end
        end
    end

    Library:Notify("Loaded config: " .. name, 3)
end

---------------------------------------------------------------------
-- BLUR / GLASS MODE
---------------------------------------------------------------------

local blurEffect

function Library:SetBlur(enabled)
    if enabled then
        if not blurEffect then
            blurEffect = Instance.new("BlurEffect")
            blurEffect.Size = 12
            blurEffect.Parent = Lighting
        end
    else
        if blurEffect then
            blurEffect:Destroy()
            blurEffect = nil
        end
    end
end

---------------------------------------------------------------------
-- WINDOW + TOPBAR + DRAGGING + RESIZING + TABS
---------------------------------------------------------------------

function Library:Window(title)
    local Window = {}

    local Main = Instance.new("Frame")
    Main.Name = "MainWindow"
    Main.Size = UDim2.new(0, 620, 0, 420)
    Main.Position = UDim2.new(0.5, -310, 0.5, -210)
    Main.BackgroundColor3 = self.Theme.Background
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Parent = ScreenGui
    Round(Main, 10)
    Stroke(Main, self.Theme.Border, 1.2)

    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 30)
    Topbar.BackgroundColor3 = self.Theme.BackgroundAlt
    Topbar.BorderSizePixel = 0
    Topbar.Parent = Main
    Round(Topbar, 10)
    Stroke(Topbar, self.Theme.Border, 1)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -10, 1, 0)
    TitleLabel.Position = UDim2.new(0, 8, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.Font = Enum.Font.GothamSemibold
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

    -- Resize grip
    local ResizeGrip = Instance.new("Frame")
    ResizeGrip.Size = UDim2.new(0, 16, 0, 16)
    ResizeGrip.Position = UDim2.new(1, -18, 1, -18)
    ResizeGrip.BackgroundColor3 = self.Theme.BackgroundAlt
    ResizeGrip.BorderSizePixel = 0
    ResizeGrip.Parent = Main
    Round(ResizeGrip, 4)
    Stroke(ResizeGrip, self.Theme.Border, 1)

    local resizing = false
    local resizeStart, startSize

    ResizeGrip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            startSize = Main.Size
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local newX = math.max(500, startSize.X.Offset + delta.X)
            local newY = math.max(350, startSize.Y.Offset + delta.Y)
            Main.Size = UDim2.new(0, newX, 0, newY)
        end
    end)

    -- Tab bar
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(0, 130, 1, -30)
    TabBar.Position = UDim2.new(0, 0, 0, 30)
    TabBar.BackgroundColor3 = self.Theme.BackgroundAlt
    TabBar.BorderSizePixel = 0
    TabBar.Parent = Main
    Round(TabBar, 10)
    Stroke(TabBar, self.Theme.Border, 1)

    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 4)
    TabList.FillDirection = Enum.FillDirection.Vertical
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabList.VerticalAlignment = Enum.VerticalAlignment.Top
    TabList.Parent = TabBar

    local TabContentHolder = Instance.new("Frame")
    TabContentHolder.Size = UDim2.new(1, -140, 1, -40)
    TabContentHolder.Position = UDim2.new(0, 140, 0, 35)
    TabContentHolder.BackgroundColor3 = self.Theme.BackgroundAlt
    TabContentHolder.BorderSizePixel = 0
    TabContentHolder.Parent = Main
    Round(TabContentHolder, 10)
    Stroke(TabContentHolder, self.Theme.Border, 1)

    local currentTab

    function Window:Tab(name)
        local Tab = {}

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, -16, 0, 26)
        Button.BackgroundColor3 = Library.Theme.Background
        Button.BorderSizePixel = 0
        Button.Text = name
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 14
        Button.TextColor3 = Library.Theme.TextDim
        Button.Parent = TabBar
        Round(Button, 6)

        Button.MouseEnter:Connect(function()
            if currentTab ~= Tab then
                Button.BackgroundColor3 = Library.Theme.BackgroundAlt
            end
        end)

        Button.MouseLeave:Connect(function()
            if currentTab ~= Tab then
                Button.BackgroundColor3 = Library.Theme.Background
            end
        end)

        local Content = Instance.new("Frame")
        Content.Size = UDim2.new(1, -16, 1, -16)
        Content.Position = UDim2.new(0, 8, 0, 8)
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

        local function Activate()
            if currentTab then
                currentTab.Content.Visible = false
                currentTab.Button.BackgroundColor3 = Library.Theme.Background
                currentTab.Button.TextColor3 = Library.Theme.TextDim
            end
            currentTab = Tab
            currentTab.Content.Visible = true
            currentTab.Button.BackgroundColor3 = Library.Theme.AccentDark
            currentTab.Button.TextColor3 = Color3.new(1, 1, 1)
        end

        Button.MouseButton1Click:Connect(Activate)

        if not currentTab then
            Activate()
        end

        function Tab:Group(gname, side)
            local parent = (side == "Right") and Right or Left
            return Library:CreateGroupbox(gname, parent)
        end

        return Tab
    end

    Window.Main = Main
    Window.TabContentHolder = TabContentHolder

    return Window
end

---------------------------------------------------------------------
-- GROUPBOX
---------------------------------------------------------------------

function Library:CreateGroupbox(name, parent)
    local Box = {}

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 220)
    Frame.BackgroundColor3 = self.Theme.Background
    Frame.BorderSizePixel = 0
    Frame.Parent = parent
    Round(Frame, 8)
    Stroke(Frame, self.Theme.Border, 1)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -14, 0, 20)
    Title.Position = UDim2.new(0, 7, 0, 6)
    Title.BackgroundTransparency = 1
    Title.Text = name
    Title.Font = Enum.Font.GothamSemibold
    Title.TextSize = 14
    Title.TextColor3 = self.Theme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -10, 1, -32)
    Scroll.Position = UDim2.new(0, 5, 0, 26)
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

    function Box:SearchDropdown(text, list, default, callback)
        return Library:CreateSearchDropdown(name, text, list, default, callback, Scroll)
    end

    function Box:Keybind(text, defaultKey, mode, callback)
        return Library:CreateKeybind(name, text, defaultKey, mode, callback, Scroll)
    end

    function Box:Button(text, callback)
        return Library:CreateButton(name, text, callback, Scroll)
    end

    function Box:ColorPicker(text, default, callback)
        return Library:CreateColorPicker(name, text, default, callback, Scroll)
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
    Frame.Size = UDim2.new(1, -10, 0, 24)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 1, 0)
    Button.BackgroundTransparency = 1
    Button.Text = ""
    Button.Parent = Frame

    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(0, 18, 0, 18)
    Box.Position = UDim2.new(0, 0, 0.5, -9)
    Box.BackgroundColor3 = Library.Theme.BackgroundAlt
    Box.BorderSizePixel = 0
    Box.Parent = Frame
    Round(Box, 4)
    Stroke(Box, Library.Theme.Border, 1)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -26, 1, 0)
    Label.Position = UDim2.new(0, 26, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local state = default or false

    local function Update()
        if state then
            Box.BackgroundColor3 = Library.Theme.Accent
            if not Box:FindFirstChildOfClass("UIStroke") then Stroke(Box, Library.Theme.AccentDark, 1) end
            Box.UIStroke.Color = Library.Theme.AccentDark
        else
            Box.BackgroundColor3 = Library.Theme.BackgroundAlt
            if not Box:FindFirstChildOfClass("UIStroke") then Stroke(Box, Library.Theme.Border, 1) end
            Box.UIStroke.Color = Library.Theme.Border
        end
        if callback then pcall(callback, state) end
    end

    Button.MouseButton1Click:Connect(function()
        state = not state
        Update()
    end)

    Button.MouseEnter:Connect(function()
        Label.TextColor3 = Library.Theme.Accent
    end)

    Button.MouseLeave:Connect(function()
        Label.TextColor3 = Library.Theme.Text
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
    Frame.Size = UDim2.new(1, -10, 0, 44)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 18)
    Label.BackgroundTransparency = 1
    Label.Text = text .. " (" .. default .. ")"
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, 0, 0, 8)
    Bar.Position = UDim2.new(0, 0, 0, 24)
    Bar.BackgroundColor3 = Library.Theme.BackgroundAlt
    Bar.BorderSizePixel = 0
    Bar.Parent = Frame
    Round(Bar, 4)
    Stroke(Bar, Library.Theme.Border, 1)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Library.Theme.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar
    Round(Fill, 4)

    local dragging = false
    local value = default

    local function Update(inputX)
        local rel = math.clamp((inputX - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * rel + 0.5)
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Label.Text = text .. " (" .. value .. ")"
        if callback then pcall(callback, value) end
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
-- DROPDOWN (dynamic list support)
---------------------------------------------------------------------

function Library:CreateDropdown(group, text, list, default, callback, parent)
    local Dropdown = {}

    list = list or {}
    default = default or (list[1] or "None")

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 28)
    Frame.BackgroundColor3 = Library.Theme.BackgroundAlt
    Frame.BorderSizePixel = 0
    Frame.Parent = parent
    Round(Frame, 6)
    Stroke(Frame, Library.Theme.Border, 1)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 1, 0)
    Label.Position = UDim2.new(0, 6, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. default
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 16, 1, 0)
    Arrow.Position = UDim2.new(1, -18, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "▼"
    Arrow.Font = Enum.Font.Gotham
    Arrow.TextSize = 14
    Arrow.TextColor3 = Library.Theme.TextDim
    Arrow.TextXAlignment = Enum.TextXAlignment.Center
    Arrow.Parent = Frame

    local Open = false

    local ListFrame = Instance.new("Frame")
    ListFrame.Size = UDim2.new(1, 0, 0, 0)
    ListFrame.Position = UDim2.new(0, 0, 1, 4)
    ListFrame.BackgroundColor3 = Library.Theme.Background
    ListFrame.BorderSizePixel = 0
    ListFrame.Visible = false
    ListFrame.Parent = Frame
    Round(ListFrame, 6)
    Stroke(ListFrame, Library.Theme.Border, 1)

    local Layout = Instance.new("UIListLayout")
    Layout.Parent = ListFrame

    local function BuildList(newList)
        newList = newList or {}
        -- clear
        for _, child in ipairs(ListFrame:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        for _, item in ipairs(newList) do
            local Option = Instance.new("TextButton")
            Option.Size = UDim2.new(1, 0, 0, 24)
            Option.BackgroundTransparency = 1
            Option.Text = item
            Option.Font = Enum.Font.Gotham
            Option.TextSize = 14
            Option.TextColor3 = Library.Theme.Text
            Option.Parent = ListFrame

            Option.MouseEnter:Connect(function()
                Option.TextColor3 = Library.Theme.Accent
            end)

            Option.MouseLeave:Connect(function()
                Option.TextColor3 = Library.Theme.Text
            end)

            Option.MouseButton1Click:Connect(function()
                Label.Text = text .. ": " .. item
                ListFrame.Visible = false
                Open = false
                Arrow.Text = "▼"
                if callback then pcall(callback, item) end
            end)
        end

        -- adjust size
        local total = #newList * 24
        ListFrame.Size = UDim2.new(1, 0, 0, total)
    end

    BuildList(list)

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Open = not Open
            ListFrame.Visible = Open
            Arrow.Text = Open and "▲" or "▼"
        end
    end)

    Dropdown.set = function(val)
        if val == nil then val = "None" end
        Label.Text = text .. ": " .. val
    end

    Dropdown.get = function()
        return Label.Text:sub(#text + 3)
    end

    Dropdown.setList = function(newList)
        list = newList or {}
        if #list == 0 then
            Dropdown.set("None")
        else
            Dropdown.set(list[1])
        end
        BuildList(list)
    end

    Dropdown.type = "dropdown"

    RegisterElement(group, text, Dropdown)

    return Dropdown
end

---------------------------------------------------------------------
-- SEARCHABLE DROPDOWN
---------------------------------------------------------------------

function Library:CreateSearchDropdown(group, text, list, default, callback, parent)
    local Dropdown = {}

    list = list or {}
    default = default or (list[1] or "None")

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 28)
    Frame.BackgroundColor3 = Library.Theme.BackgroundAlt
    Frame.BorderSizePixel = 0
    Frame.Parent = parent
    Round(Frame, 6)
    Stroke(Frame, Library.Theme.Border, 1)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 1, 0)
    Label.Position = UDim2.new(0, 6, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. default
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 16, 1, 0)
    Arrow.Position = UDim2.new(1, -18, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "▼"
    Arrow.Font = Enum.Font.Gotham
    Arrow.TextSize = 14
    Arrow.TextColor3 = Library.Theme.TextDim
    Arrow.TextXAlignment = Enum.TextXAlignment.Center
    Arrow.Parent = Frame

    local Open = false

    local ListFrame = Instance.new("Frame")
    ListFrame.Size = UDim2.new(1, 0, 0, 150)
    ListFrame.Position = UDim2.new(0, 0, 1, 4)
    ListFrame.BackgroundColor3 = Library.Theme.Background
    ListFrame.BorderSizePixel = 0
    ListFrame.Visible = false
    ListFrame.Parent = Frame
    Round(ListFrame, 6)
    Stroke(ListFrame, Library.Theme.Border, 1)

    local SearchBox = Instance.new("TextBox")
    SearchBox.Size = UDim2.new(1, -8, 0, 20)
    SearchBox.Position = UDim2.new(0, 4, 0, 4)
    SearchBox.BackgroundColor3 = Library.Theme.BackgroundAlt
    SearchBox.BorderSizePixel = 0
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 13
    SearchBox.TextColor3 = Library.Theme.Text
    SearchBox.PlaceholderText = "Search..."
    SearchBox.PlaceholderColor3 = Library.Theme.TextDim
    SearchBox.Text = ""
    SearchBox.Parent = ListFrame
    Round(SearchBox, 4)

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -8, 1, -28)
    Scroll.Position = UDim2.new(0, 4, 0, 24)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.ScrollBarThickness = 2
    Scroll.ScrollBarImageColor3 = Library.Theme.Accent
    Scroll.Parent = ListFrame

    local Layout = Instance.new("UIListLayout")
    Layout.Parent = Scroll

    local function Refresh(filter)
        for _, child in ipairs(Scroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        for _, item in ipairs(list) do
            if not filter or filter == "" or string.find(string.lower(item), string.lower(filter), 1, true) then
                local Option = Instance.new("TextButton")
                Option.Size = UDim2.new(1, 0, 0, 22)
                Option.BackgroundTransparency = 1
                Option.Text = item
                Option.Font = Enum.Font.Gotham
                Option.TextSize = 13
                Option.TextColor3 = Library.Theme.Text
                Option.Parent = Scroll

                Option.MouseEnter:Connect(function()
                    Option.TextColor3 = Library.Theme.Accent
                end)

                Option.MouseLeave:Connect(function()
                    Option.TextColor3 = Library.Theme.Text
                end)

                Option.MouseButton1Click:Connect(function()
                    Label.Text = text .. ": " .. item
                    ListFrame.Visible = false
                    Open = false
                    Arrow.Text = "▼"
                    if callback then pcall(callback, item) end
                end)
            end
        end

        Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y)
    end

    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y)
    end)

    Refresh()

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Refresh(SearchBox.Text)
    end)

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Open = not Open
            ListFrame.Visible = Open
            Arrow.Text = Open and "▲" or "▼"
        end
    end)

    Dropdown.set = function(val)
        if val == nil then val = "None" end
        Label.Text = text .. ": " .. val
    end

    Dropdown.get = function()
        return Label.Text:sub(#text + 3)
    end

    Dropdown.setList = function(newList)
        list = newList or {}
        if #list == 0 then
            Dropdown.set("None")
        else
            Dropdown.set(list[1])
        end
        Refresh()
    end

    Dropdown.type = "searchdropdown"

    RegisterElement(group, text, Dropdown)

    return Dropdown
end

---------------------------------------------------------------------
-- KEYBIND
---------------------------------------------------------------------

function Library:CreateKeybind(group, text, defaultKey, mode, callback, parent)
    local Keybind = {}

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 24)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.5, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.5, -4, 1, 0)
    Button.Position = UDim2.new(0.5, 4, 0, 0)
    Button.BackgroundColor3 = Library.Theme.BackgroundAlt
    Button.BorderSizePixel = 0
    Button.Text = defaultKey or "Q"
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 14
    Button.TextColor3 = Library.Theme.Text
    Button.Parent = Frame
    Round(Button, 6)
    Stroke(Button, Library.Theme.Border, 1)

    local binding = false
    local currentKey = Enum.KeyCode[defaultKey] or Enum.KeyCode.Q

    Button.MouseButton1Click:Connect(function()
        binding = true
        Button.Text = "..."
    end)

    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Library.Theme.Background
    end)

    Button.MouseLeave:Connect(function()
        if not binding then
            Button.BackgroundColor3 = Library.Theme.BackgroundAlt
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end

        if binding then
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                currentKey = input.KeyCode
                Button.Text = input.KeyCode.Name
                binding = false
                Button.BackgroundColor3 = Library.Theme.BackgroundAlt
            end
        else
            if input.KeyCode == currentKey then
                if callback then pcall(callback) end
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
    Button.Size = UDim2.new(1, -10, 0, 28)
    Button.BackgroundColor3 = Library.Theme.BackgroundAlt
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 14
    Button.TextColor3 = Library.Theme.Text
    Button.Parent = parent
    Round(Button, 6)
    Stroke(Button, Library.Theme.Border, 1)

    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Library.Theme.Background
    end)

    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = Library.Theme.BackgroundAlt
    end)

    Button.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)

    return Button
end

---------------------------------------------------------------------
-- COLOR PICKER (simple)
---------------------------------------------------------------------

function Library:CreateColorPicker(group, text, default, callback, parent)
    local Picker = {}

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 24)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.5, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.5, -4, 1, 0)
    Button.Position = UDim2.new(0.5, 4, 0, 0)
    Button.BackgroundColor3 = default or Color3.fromRGB(255, 160, 200)
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.Parent = Frame
    Round(Button, 6)
    Stroke(Button, Library.Theme.Border, 1)

    local value = Button.BackgroundColor3

    Button.MouseButton1Click:Connect(function()
        -- simple cycle through a few colors
        local colors = {
            Color3.fromRGB(255, 160, 200),
            Color3.fromRGB(120, 180, 255),
            Color3.fromRGB(120, 255, 180),
            Color3.fromRGB(255, 220, 120)
        }
        local idx = 1
        for i, c in ipairs(colors) do
            if c == value then
                idx = i
                break
            end
        end
        idx = idx % #colors + 1
        value = colors[idx]
        Button.BackgroundColor3 = value
        if callback then pcall(callback, value) end
    end)

    Picker.set = function(val)
        value = val
        Button.BackgroundColor3 = val
        if callback then pcall(callback, val) end
    end

    Picker.get = function()
        return value
    end

    Picker.type = "colorpicker"

    RegisterElement(group, text, Picker)

    return Picker
end

---------------------------------------------------------------------
-- NOTIFICATION QUEUE
---------------------------------------------------------------------

Library._Notifications = {}

function Library:Notify(text, duration)
    duration = duration or 3

    local Notif = Instance.new("Frame")
    Notif.Name = "Notification"
    Notif.Size = UDim2.new(0, 260, 0, 40)
    Notif.Position = UDim2.new(1, -280, 0, 12 + (#self._Notifications * 44))
    Notif.BackgroundColor3 = self.Theme.Background
    Notif.BorderSizePixel = 0
    Notif.Parent = ScreenGui
    Round(Notif, 8)
    Stroke(Notif, self.Theme.Border, 1)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -12, 1, 0)
    Label.Position = UDim2.new(0, 6, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextColor3 = self.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Notif

    table.insert(self._Notifications, Notif)

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

        local idx
        for i, v in ipairs(self._Notifications) do
            if v == Notif then
                idx = i
                break
            end
        end
        if idx then
            table.remove(self._Notifications, idx)
            for i = idx, #self._Notifications do
                local n = self._Notifications[i]
                n:TweenPosition(UDim2.new(1, -280, 0, 12 + (i - 1) * 44), "Out", "Quad", 0.2, true)
            end
        end

        Notif:Destroy()
    end)
end

---------------------------------------------------------------------
-- WATERMARK (FPS + PING, robust + always visible)
---------------------------------------------------------------------

function Library:Watermark(textBase)
    if self._Watermark then
        self._WatermarkBase = textBase or self._WatermarkBase
        return
    end

    local MarkGui = Instance.new("ScreenGui")
    MarkGui.Name = "securewatchWatermark"
    MarkGui.ResetOnSpawn = false
    -- prefer PlayerGui, fallback to CoreGui
    SafeParentGui(MarkGui)

    local Mark = Instance.new("TextLabel")
    Mark.Name = "Watermark"
    Mark.Size = UDim2.new(0, 320, 0, 20)
    Mark.Position = UDim2.new(0, 10, 0, 10)
    Mark.BackgroundColor3 = self.Theme.Background
    Mark.BorderSizePixel = 0
    Mark.Font = Enum.Font.Gotham
    Mark.TextSize = 14
    Mark.TextColor3 = self.Theme.Text
    Mark.TextXAlignment = Enum.TextXAlignment.Left
    Mark.Text = textBase or "kittyware.cc"
    Mark.Parent = MarkGui
    Round(Mark, 6)
    Stroke(Mark, self.Theme.Border, 1)

    -- ensure topmost
    pcall(function() Mark.ZIndex = 9999 end)

    self._Watermark = Mark
    self._WatermarkBase = textBase or "kittyware.cc"

    local accum = 0
    local last = tick()
    RunService.RenderStepped:Connect(function(dt)
        accum = accum + dt
        if accum >= 0.25 then
            accum = 0
            local now = tick()
            local fps = math.floor(1 / math.max(0.0001, now - last) + 0.5)
            last = now
            local ping = SafePing()
            local base = self._WatermarkBase or "kittyware.cc"
            pcall(function()
                Mark.Text = string.format("%s | %d FPS | %d ms", base, fps, ping)
            end)
        end
    end)
end

---------------------------------------------------------------------
-- THEME SWITCHER
---------------------------------------------------------------------

function Library:SetTheme(name)
    local theme = self.Themes[name]
    if not theme then return end
    self.Theme = theme
    -- Note: live re-theming of existing UI would require iterating instances.
    -- For simplicity, recommend rebuilding UI after theme change.
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
-- CONFIG TAB HELPER (fixed + dynamic dropdown)
---------------------------------------------------------------------

function Library:AttachConfigTab(Window, tabName)
    local Tab = Window:Tab(tabName or "Configs")
    local Box = Tab:Group("Configs", "Left")

    local currentConfig = nil

    local configs = self:GetConfigs()
    local ConfigDropdown = Box:Dropdown("Config", configs, (configs[1] or "None"), function(v)
        currentConfig = v
    end)

    -- ensure dropdown has dynamic list setter
    if ConfigDropdown and ConfigDropdown.setList then
        ConfigDropdown.setList(configs)
    end

    Box:Button("Refresh", function()
        local newConfigs = self:GetConfigs()
        if #newConfigs == 0 then
            self:Notify("No configs found.", 2)
            ConfigDropdown.setList({})
            currentConfig = nil
            ConfigDropdown.set("None")
            return
        end
        ConfigDropdown.setList(newConfigs)
        currentConfig = newConfigs[1]
        ConfigDropdown.set(currentConfig)
        self:Notify("Configs refreshed.", 2)
    end)

    Box:Button("Save", function()
        if not currentConfig or currentConfig == "None" then
            currentConfig = "default"
        end
        self:SaveConfig(currentConfig)
    end)

    Box:Button("Load", function()
        if currentConfig and currentConfig ~= "None" then
            self:LoadConfig(currentConfig)
        else
            self:Notify("Select a config first.", 2)
        end
    end)

    local ThemeBox = Tab:Group("Appearance", "Right")

    ThemeBox:Dropdown("Theme", {"Pastel", "Dark"}, "Pastel", function(v)
        self:SetTheme(v)
        self:Notify("Theme changed. Rebuild UI to apply fully.", 3)
    end)

    ThemeBox:Toggle("Blur Background", false, function(v)
        self:SetBlur(v)
    end)

    ThemeBox:Button("Open Config Folder", function()
        self:Notify("Config folder: securewatch-ui/configs", 3)
    end)
end

---------------------------------------------------------------------
-- RETURN LIBRARY
---------------------------------------------------------------------

return Library
