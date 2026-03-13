-- extlover UI Library (full rebuild)
-- File: 82jd2q9d8q2md2q.lua
-- Single-file, self-contained, user-friendly, pink theme, persistent watermark, Save As required,
-- function import API, dropdown fixes, debug mode.

local Library = {}

---------------------------------------------------------------------
-- Services
---------------------------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

---------------------------------------------------------------------
-- Config
---------------------------------------------------------------------
Library.Name = "extlover<3"
Library.ConfigFolder = "extlover/configs"
Library.ToggleKey = Enum.KeyCode.RightShift
Library.Debug = false -- set true to print debug logs
Library.ThemeName = "Pink"

---------------------------------------------------------------------
-- Themes (pink default)
---------------------------------------------------------------------
Library.Themes = {
    Pink = {
        Background     = Color3.fromRGB(30, 30, 36),
        BackgroundAlt  = Color3.fromRGB(24, 24, 28),
        Border         = Color3.fromRGB(80, 80, 95),
        Accent         = Color3.fromRGB(255, 150, 200),
        AccentDark     = Color3.fromRGB(220, 120, 170),
        AccentGreen    = Color3.fromRGB(150, 220, 170),
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
Library.Theme = Library.Themes[Library.ThemeName]

---------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------
local function dbg(...)
    if Library.Debug then
        print("[extlover-debug]", ...)
    end
end

local function Round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
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
    local pg = (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")) or nil
    if pg then gui.Parent = pg else gui.Parent = CoreGui end
    if gui:IsA("ScreenGui") then pcall(function() gui.DisplayOrder = 10095 end) end
end

local function SafePing()
    local ok, val = pcall(function()
        local item = Stats.Network and Stats.Network.ServerStatsItem and Stats.Network.ServerStatsItem["Data Ping"]
        if item then return math.floor(item:GetValue()) end
        return 0
    end)
    if ok and val then return val end
    return 0
end

local function setClipboardSafe(text)
    local ok, err = pcall(function() setclipboard(text) end)
    return ok, err
end

local function EnsureFolder()
    if not isfolder("extlover") then
        pcall(function() makefolder("extlover") end)
    end
    if not isfolder(Library.ConfigFolder) then
        pcall(function() makefolder(Library.ConfigFolder) end)
    end
end

local function trim(s)
    s = tostring(s or "")
    return s:match("^%s*(.-)%s*$") or ""
end

---------------------------------------------------------------------
-- Core GUI + State
---------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "extloverUILib"
ScreenGui.ResetOnSpawn = false
SafeParentGui(ScreenGui)

Library._ScreenGui = ScreenGui
Library._UIVisible = true
Library.Elements = {}
Library._Notifications = {}
Library._OpenDropdown = nil
Library._Watermark = nil
Library._BlurEnabled = false
Library._Functions = {}

local function RegisterElement(group, name, element)
    Library.Elements[group .. "." .. name] = element
    dbg("Registered element", group .. "." .. name)
end

---------------------------------------------------------------------
-- Config I/O
---------------------------------------------------------------------
function Library:GetConfigs()
    EnsureFolder()
    local files = listfiles(Library.ConfigFolder)
    local configs = {}
    for _, f in ipairs(files) do
        if f:sub(-4) == ".txt" then
            local name = f:match("([^/\\]+)%.txt$")
            if name then table.insert(configs, name) end
        end
    end
    table.sort(configs)
    return configs
end

function Library:SaveConfig(name)
    name = trim(name)
    if name == "" then
        self:Notify("Invalid config name.", 2)
        return false, "invalid name"
    end
    EnsureFolder()
    local path = self.ConfigFolder .. "/" .. name .. ".txt"
    local lines = {}
    for key, element in pairs(self.Elements) do
        local ok, value = pcall(function() return element.get() end)
        if not ok then value = nil end
        if typeof(value) == "boolean" then
            table.insert(lines, key .. " = " .. tostring(value))
        elseif typeof(value) == "number" then
            table.insert(lines, key .. " = " .. tostring(value))
        elseif typeof(value) == "string" then
            table.insert(lines, key .. " = " .. value)
        elseif typeof(value) == "Color3" then
            local r,g,b = math.floor(value.R*255), math.floor(value.G*255), math.floor(value.B*255)
            table.insert(lines, key .. " = " .. r .. "," .. g .. "," .. b)
        end
    end
    local ok, err = pcall(function() writefile(path, table.concat(lines, "\n")) end)
    if not ok then
        self:Notify("Failed to save config: " .. tostring(err), 4)
        warn("[extlover] SaveConfig writefile failed:", err, "path:", path)
        return false, err
    end
    self:Notify("Saved config: " .. tostring(name), 3)
    dbg("Saved config", name, "->", path)
    return true
end

function Library:LoadConfig(name)
    name = trim(name)
    if name == "" then
        self:Notify("Invalid config name.", 2)
        return false, "invalid name"
    end
    EnsureFolder()
    local path = self.ConfigFolder .. "/" .. name .. ".txt"
    if not isfile(path) then
        self:Notify("Config not found: " .. tostring(name), 3)
        return false, "not found"
    end
    local data = readfile(path)
    for line in data:gmatch("[^\r\n]+") do
        local key, value = line:match("^(.-)%s*=%s*(.+)$")
        if key and value then
            local element = self.Elements[key]
            if element then
                if element.type == "toggle" then pcall(function() element.set(value == "true") end)
                elseif element.type == "slider" then pcall(function() element.set(tonumber(value)) end)
                elseif element.type == "dropdown" or element.type == "searchdropdown" then pcall(function() element.set(value) end)
                elseif element.type == "keybind" then pcall(function() element.set(value) end)
                elseif element.type == "colorpicker" then
                    local r,g,b = value:match("(%d+),(%d+),(%d+)")
                    if r and g and b then pcall(function() element.set(Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))) end) end
                end
            end
        end
    end
    self:Notify("Loaded config: " .. tostring(name), 3)
    dbg("Loaded config", name, "from", path)
    return true
end

---------------------------------------------------------------------
-- Blur
---------------------------------------------------------------------
local blurEffect
function Library:SetBlur(enabled)
    if enabled then
        if not blurEffect then
            blurEffect = Instance.new("BlurEffect")
            blurEffect.Size = 12
            blurEffect.Parent = Lighting
            self._BlurEnabled = true
        end
    else
        if blurEffect then blurEffect:Destroy(); blurEffect = nil end
        self._BlurEnabled = false
    end
end

---------------------------------------------------------------------
-- Notifications & Info
---------------------------------------------------------------------
function Library:Notify(text, duration)
    duration = duration or 3
    local Notif = Instance.new("Frame")
    Notif.Name = "Notification"
    Notif.Size = UDim2.new(0, 360, 0, 56)
    Notif.Position = UDim2.new(1, -380, 0, 12 + (#self._Notifications * 64))
    Notif.BackgroundColor3 = self.Theme.Background
    Notif.BorderSizePixel = 0
    Notif.Parent = ScreenGui
    Round(Notif, 10)
    Stroke(Notif, self.Theme.Border, 1)
    Notif.ZIndex = 10080

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 1, -12)
    Label.Position = UDim2.new(0, 10, 0, 6)
    Label.BackgroundTransparency = 1
    Label.Text = tostring(text or "")
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 13
    Label.TextColor3 = self.Theme.Text
    Label.TextWrapped = true
    Label.TextYAlignment = Enum.TextYAlignment.Top
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Notif
    Label.TextStrokeTransparency = 0.85
    Label.TextStrokeColor3 = Color3.fromRGB(0,0,0)

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
            if v == Notif then idx = i; break end
        end
        if idx then
            table.remove(self._Notifications, idx)
            for i = idx, #self._Notifications do
                local n = self._Notifications[i]
                n:TweenPosition(UDim2.new(1, -380, 0, 12 + (i - 1) * 64), "Out", "Quad", 0.18, true)
            end
        end

        Notif:Destroy()
    end)
end

function Library:ShowInfoInline(titleText, bodyText, duration)
    duration = duration or 4
    local container = Instance.new("Frame")
    container.Name = "ExtloverInfoInline"
    container.Size = UDim2.new(0, 420, 0, 96)
    container.Position = UDim2.new(0.5, -210, 0.12, 0)
    container.BackgroundColor3 = self.Theme.Background
    container.BorderSizePixel = 0
    container.Parent = ScreenGui
    Round(container, 10)
    Stroke(container, self.Theme.Border, 1)
    container.ZIndex = 10085

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 0, 24)
    title.Position = UDim2.new(0, 12, 0, 8)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 16
    title.TextColor3 = self.Theme.Text
    title.Text = titleText or ""
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -24, 1, -44)
    body.Position = UDim2.new(0, 12, 0, 36)
    body.BackgroundTransparency = 1
    body.Font = Enum.Font.Gotham
    body.TextSize = 14
    body.TextColor3 = self.Theme.Text
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Text = bodyText or ""
    body.Parent = container

    task.spawn(function()
        task.wait(duration)
        pcall(function() container:Destroy() end)
    end)

    return container
end

---------------------------------------------------------------------
-- Watermark (persistent pill with hover tooltip)
---------------------------------------------------------------------
function Library:Watermark(opts)
    if self._Watermark and self._Watermark.Parent then return self._Watermark end
    opts = opts or {}
    local bgColor = opts.bgColor or self.Theme.Accent
    local size = opts.size or 18

    local MarkGui = Instance.new("ScreenGui")
    MarkGui.Name = "extloverWatermark"
    MarkGui.ResetOnSpawn = false
    local pg = (Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui"))
    MarkGui.Parent = pg or CoreGui
    pcall(function() MarkGui.DisplayOrder = 10095 end)

    local Mark = Instance.new("Frame")
    Mark.Name = "Watermark"
    Mark.Size = UDim2.new(0, size, 0, size)
    Mark.Position = UDim2.new(0, 12, 0, 12)
    Mark.BackgroundColor3 = bgColor
    Mark.BorderSizePixel = 0
    Mark.Parent = MarkGui
    Round(Mark, size/2)
    Stroke(Mark, self.Theme.Border, 0.6)
    Mark.ZIndex = 10095

    local tip = Instance.new("TextLabel")
    tip.Size = UDim2.new(0, 140, 0, 20)
    tip.Position = UDim2.new(0, size + 12, 0, 0)
    tip.BackgroundColor3 = Color3.fromRGB(20,20,20)
    tip.BackgroundTransparency = 0.12
    tip.TextColor3 = Color3.fromRGB(255,255,255)
    tip.Font = Enum.Font.Gotham
    tip.TextSize = 12
    tip.Text = ""
    tip.Visible = false
    tip.Parent = Mark
    Round(tip, 6)
    Stroke(tip, Color3.fromRGB(0,0,0), 0.6)
    tip.ZIndex = 10096

    local updating = false
    local function updateTip()
        if updating then return end
        updating = true
        task.spawn(function()
            while tip and tip.Parent and tip.Visible do
                local fps = math.floor(1 / math.max(1/60, RunService.RenderStepped:Wait()) + 0.5)
                local ping = SafePing()
                tip.Text = ("FPS: %d  Ping: %dms"):format(fps, ping)
                task.wait(0.25)
            end
            updating = false
        end)
    end

    do
        local dragging, dragStart, startPos = false, nil, nil
        Mark.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Mark.Position
            end
        end)
        Mark.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                Mark.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        Mark.MouseEnter:Connect(function()
            tip.Visible = true
            updateTip()
        end)
        Mark.MouseLeave:Connect(function()
            tip.Visible = false
        end)
    end

    self._Watermark = Mark
    return Mark
end

-- create watermark immediately
pcall(function() Library:Watermark() end)

---------------------------------------------------------------------
-- Function import / registration API
---------------------------------------------------------------------
function Library:RegisterFunction(name, fn)
    if type(name) ~= "string" or type(fn) ~= "function" then
        error("RegisterFunction expects (string, function)")
    end
    self._Functions[name] = fn
    dbg("Registered function", name)
end

function Library:ImportFunctions(tbl, prefix)
    prefix = prefix or ""
    if type(tbl) ~= "table" then return end
    for k, v in pairs(tbl) do
        if type(k) == "string" and type(v) == "function" then
            local name = prefix .. k
            self._Functions[name] = v
            dbg("Imported function", name)
        end
    end
end

function Library:CallFunction(name, ...)
    local fn = self._Functions[name]
    if type(fn) ~= "function" then
        error("Function not found: " .. tostring(name))
    end
    return pcall(fn, ...)
end

function Library:ListFunctions()
    local out = {}
    for k, v in pairs(self._Functions) do table.insert(out, k) end
    table.sort(out)
    return out
end

---------------------------------------------------------------------
-- UI primitives: Window, Tabs, Groupbox, Elements
---------------------------------------------------------------------
function Library:Window(title)
    local Window = {}

    local Main = Instance.new("Frame")
    Main.Name = "MainWindow"
    Main.Size = UDim2.new(0, 680, 0, 460)
    Main.Position = UDim2.new(0.5, -340, 0.5, -230)
    Main.BackgroundColor3 = self.Theme.Background
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Parent = ScreenGui
    Round(Main, 12)
    Stroke(Main, self.Theme.Border, 1.4)

    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 36)
    Topbar.BackgroundColor3 = self.Theme.BackgroundAlt
    Topbar.BorderSizePixel = 0
    Topbar.Parent = Main
    Round(Topbar, 12)
    Stroke(Topbar, self.Theme.Border, 1)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -12, 1, 0)
    TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = (title or Library.Name)
    TitleLabel.Font = Enum.Font.GothamSemibold
    TitleLabel.TextSize = 18
    TitleLabel.TextColor3 = self.Theme.Text
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Topbar
    TitleLabel.TextStrokeTransparency = 0.85
    TitleLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)

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
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- Resize grip
    local ResizeGrip = Instance.new("Frame")
    ResizeGrip.Size = UDim2.new(0, 18, 0, 18)
    ResizeGrip.Position = UDim2.new(1, -22, 1, -22)
    ResizeGrip.BackgroundColor3 = self.Theme.BackgroundAlt
    ResizeGrip.BorderSizePixel = 0
    ResizeGrip.Parent = Main
    Round(ResizeGrip, 6)
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local newX = math.max(520, startSize.X.Offset + delta.X)
            local newY = math.max(380, startSize.Y.Offset + delta.Y)
            Main.Size = UDim2.new(0, newX, 0, newY)
        end
    end)

    -- Tab bar
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(0, 150, 1, -36)
    TabBar.Position = UDim2.new(0, 0, 0, 36)
    TabBar.BackgroundColor3 = self.Theme.BackgroundAlt
    TabBar.BorderSizePixel = 0
    TabBar.Parent = Main
    Round(TabBar, 12)
    Stroke(TabBar, self.Theme.Border, 1)

    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 6)
    TabList.FillDirection = Enum.FillDirection.Vertical
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabList.VerticalAlignment = Enum.VerticalAlignment.Top
    TabList.Parent = TabBar

    local TabContentHolder = Instance.new("Frame")
    TabContentHolder.Size = UDim2.new(1, -170, 1, -48)
    TabContentHolder.Position = UDim2.new(0, 170, 0, 44)
    TabContentHolder.BackgroundColor3 = self.Theme.BackgroundAlt
    TabContentHolder.BorderSizePixel = 0
    TabContentHolder.Parent = Main
    Round(TabContentHolder, 10)
    Stroke(TabContentHolder, self.Theme.Border, 1)

    local currentTab
    function Window:Tab(name)
        local Tab = {}
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, -18, 0, 30)
        Button.BackgroundColor3 = Library.Theme.Background
        Button.BorderSizePixel = 0
        Button.Text = name
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 14
        Button.TextColor3 = Library.Theme.TextDim
        Button.Parent = TabBar
        Round(Button, 8)

        Button.MouseEnter:Connect(function()
            if currentTab ~= Tab then Button.BackgroundColor3 = Library.Theme.BackgroundAlt end
        end)
        Button.MouseLeave:Connect(function()
            if currentTab ~= Tab then Button.BackgroundColor3 = Library.Theme.Background end
        end)

        local Content = Instance.new("Frame")
        Content.Size = UDim2.new(1, -18, 1, -18)
        Content.Position = UDim2.new(0, 8, 0, 8)
        Content.BackgroundTransparency = 1
        Content.Visible = false
        Content.Parent = TabContentHolder

        local Left = Instance.new("Frame")
        Left.Size = UDim2.new(0.5, -8, 1, 0)
        Left.BackgroundTransparency = 1
        Left.Parent = Content

        local Right = Instance.new("Frame")
        Right.Size = UDim2.new(0.5, -8, 1, 0)
        Right.Position = UDim2.new(0.5, 8, 0, 0)
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
            currentTab.Button.BackgroundColor3 = Library.Theme.Accent
            currentTab.Button.TextColor3 = Color3.new(1,1,1)
        end

        Button.MouseButton1Click:Connect(Activate)
        if not currentTab then Activate() end

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

function Library:CreateGroupbox(name, parent)
    local Box = {}
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -12, 0, 220)
    Frame.BackgroundColor3 = self.Theme.Background
    Frame.BorderSizePixel = 0
    Frame.Parent = parent
    Round(Frame, 10)
    Stroke(Frame, self.Theme.Border, 1)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -16, 0, 22)
    Title.Position = UDim2.new(0, 8, 0, 6)
    Title.BackgroundTransparency = 1
    Title.Text = name
    Title.Font = Enum.Font.GothamSemibold
    Title.TextSize = 15
    Title.TextColor3 = self.Theme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame
    Title.TextStrokeTransparency = 0.85
    Title.TextStrokeColor3 = Color3.fromRGB(0,0,0)

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -12, 1, -36)
    Scroll.Position = UDim2.new(0, 6, 0, 30)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.CanvasSize = UDim2.new(0,0,0,0)
    Scroll.ScrollBarThickness = 6
    Scroll.ScrollBarImageColor3 = self.Theme.Accent
    Scroll.Parent = Frame

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 8)
    Layout.Parent = Scroll
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y)
    end)

    Box.Frame = Frame
    Box.Scroll = Scroll

    function Box:Toggle(text, default, callback) return Library:CreateToggle(name, text, default, callback, Scroll) end
    function Box:Slider(text, min, max, default, callback) return Library:CreateSlider(name, text, min, max, default, callback, Scroll) end
    function Box:Dropdown(text, list, default, callback) return Library:CreateDropdown(name, text, list, default, callback, Scroll) end
    function Box:SearchDropdown(text, list, default, callback) return Library:CreateSearchDropdown(name, text, list, default, callback, Scroll) end
    function Box:Keybind(text, defaultKey, mode, callback) return Library:CreateKeybind(name, text, defaultKey, mode, callback, Scroll) end
    function Box:Button(text, callback) return Library:CreateButton(name, text, callback, Scroll) end
    function Box:ColorPicker(text, default, callback) return Library:CreateColorPicker(name, text, default, callback, Scroll) end

    return Box
end

-- Toggle
function Library:CreateToggle(group, text, default, callback, parent)
    local Toggle = {}
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -12, 0, 26)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1,0,1,0)
    Button.BackgroundTransparency = 1
    Button.Text = ""
    Button.Parent = Frame

    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(0,20,0,20)
    Box.Position = UDim2.new(0,0,0.5,-10)
    Box.BackgroundColor3 = Library.Theme.BackgroundAlt
    Box.BorderSizePixel = 0
    Box.Parent = Frame
    Round(Box,6)
    Stroke(Box, Library.Theme.Border, 1)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1,-30,1,0)
    Label.Position = UDim2.new(0,28,0,0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    Label.TextStrokeTransparency = 0.85
    Label.TextStrokeColor3 = Color3.fromRGB(0,0,0)

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

    Button.MouseButton1Click:Connect(function() state = not state; Update() end)
    Button.MouseEnter:Connect(function() Label.TextColor3 = Library.Theme.Accent end)
    Button.MouseLeave:Connect(function() Label.TextColor3 = Library.Theme.Text end)
    Update()

    Toggle.set = function(val) state = val; Update() end
    Toggle.get = function() return state end
    Toggle.type = "toggle"
    RegisterElement(group, text, Toggle)
    return Toggle
end

-- Slider
function Library:CreateSlider(group, text, min, max, default, callback, parent)
    local Slider = {}
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1,-12,0,48)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1,0,0,18)
    Label.BackgroundTransparency = 1
    Label.Text = text .. " (" .. default .. ")"
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    Label.TextStrokeTransparency = 0.85
    Label.TextStrokeColor3 = Color3.fromRGB(0,0,0)

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1,0,0,10)
    Bar.Position = UDim2.new(0,0,0,28)
    Bar.BackgroundColor3 = Library.Theme.BackgroundAlt
    Bar.BorderSizePixel = 0
    Bar.Parent = Frame
    Round(Bar,6)
    Stroke(Bar, Library.Theme.Border, 1)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    Fill.BackgroundColor3 = Library.Theme.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar
    Round(Fill,6)

    local dragging = false
    local value = default
    local function Update(inputX)
        local rel = math.clamp((inputX - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max-min)*rel + 0.5)
        Fill.Size = UDim2.new(rel,0,1,0)
        Label.Text = text .. " (" .. value .. ")"
        if callback then pcall(callback, value) end
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; Update(input.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then Update(input.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    Slider.set = function(val) value = val; local rel = (val-min)/(max-min); Fill.Size = UDim2.new(rel,0,1,0); Label.Text = text .. " (" .. value .. ")" end
    Slider.get = function() return value end
    Slider.type = "slider"
    RegisterElement(group, text, Slider)
    return Slider
end

-- Dropdown (absolute, single-open, debounce)
local openDebounce = false
local function debounceOpen(fn)
    return function(...)
        if openDebounce then return end
        openDebounce = true
        fn(...)
        task.delay(0.08, function() openDebounce = false end)
    end
end

function Library:CreateDropdown(group, text, list, default, callback, parent)
    local Dropdown = {}
    list = list or {}
    default = default or (list[1] or "None")

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1,-12,0,30)
    Frame.BackgroundColor3 = Library.Theme.BackgroundAlt
    Frame.BorderSizePixel = 0
    Frame.Parent = parent
    Round(Frame,8)
    Stroke(Frame, Library.Theme.Border,1)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1,-36,1,0)
    Label.Position = UDim2.new(0,8,0,0)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. default
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    Label.TextStrokeTransparency = 0.85
    Label.TextStrokeColor3 = Color3.fromRGB(0,0,0)

    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0,20,1,0)
    Arrow.Position = UDim2.new(1,-24,0,0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "▼"
    Arrow.Font = Enum.Font.Gotham
    Arrow.TextSize = 14
    Arrow.TextColor3 = Library.Theme.TextDim
    Arrow.TextXAlignment = Enum.TextXAlignment.Center
    Arrow.Parent = Frame

    local Open = false

    local ListFrame = Instance.new("Frame")
    ListFrame.Size = UDim2.new(0, 0, 0, 0)
    ListFrame.Position = UDim2.new(0, 0, 0, 0)
    ListFrame.BackgroundColor3 = Library.Theme.Background
    ListFrame.BorderSizePixel = 0
    ListFrame.Visible = false
    ListFrame.Parent = ScreenGui
    Round(ListFrame,8)
    Stroke(ListFrame, Library.Theme.Border,1)
    ListFrame.ZIndex = 10090

    local Layout = Instance.new("UIListLayout")
    Layout.Parent = ListFrame

    local function BuildList(newList)
        newList = newList or {}
        for _, child in ipairs(ListFrame:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
        end
        for _, item in ipairs(newList) do
            local Option = Instance.new("TextButton")
            Option.Size = UDim2.new(1,0,0,26)
            Option.BackgroundTransparency = 1
            Option.Text = item
            Option.Font = Enum.Font.GothamSemibold
            Option.TextSize = 14
            Option.TextColor3 = Library.Theme.Text
            Option.Parent = ListFrame
            Option.TextStrokeTransparency = 0.9
            Option.TextStrokeColor3 = Color3.fromRGB(0,0,0)

            Option.MouseEnter:Connect(function() Option.TextColor3 = Library.Theme.Accent end)
            Option.MouseLeave:Connect(function() Option.TextColor3 = Library.Theme.Text end)
            Option.MouseButton1Click:Connect(function()
                Label.Text = text .. ": " .. item
                ListFrame.Visible = false
                Open = false
                Arrow.Text = "▼"
                Library._OpenDropdown = nil
                if callback then pcall(callback, item) end
            end)
        end
        local total = #newList * 26
        ListFrame.Size = UDim2.new(0, Frame.AbsoluteSize.X, 0, total)
    end

    BuildList(list)

    local function OpenList()
        if Library._OpenDropdown and Library._OpenDropdown.ListFrame then
            pcall(function() Library._OpenDropdown.ListFrame.Visible = false end)
            pcall(function() Library._OpenDropdown.Arrow.Text = "▼" end)
        end
        if not ListFrame then return end
        local absPos = Frame.AbsolutePosition
        local absSize = Frame.AbsoluteSize
        local width = math.max(220, absSize.X)
        local height = math.min(220, (#list * 26))
        ListFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 6)
        ListFrame.Size = UDim2.new(0, width, 0, height)
        ListFrame.Visible = true
        ListFrame.ZIndex = 10090
        Library._OpenDropdown = { ListFrame = ListFrame, Arrow = Arrow }
    end

    Frame.InputBegan:Connect(debounceOpen(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Open = not Open
            if Open then
                BuildList(list)
                OpenList()
                Arrow.Text = "▲"
            else
                ListFrame.Visible = false
                Arrow.Text = "▼"
                Library._OpenDropdown = nil
            end
        end
    end))

    Dropdown.set = function(val)
        if val == nil then val = "None" end
        Label.Text = text .. ": " .. val
    end

    Dropdown.get = function() return Label.Text:sub(#text + 3) end

    Dropdown.setList = function(newList)
        list = newList or {}
        if #list == 0 then Dropdown.set("None") else Dropdown.set(list[1]) end
        BuildList(list)
    end

    Dropdown.type = "dropdown"
    RegisterElement(group, text, Dropdown)
    return Dropdown
end

-- Searchable dropdown
function Library:CreateSearchDropdown(group, text, list, default, callback, parent)
    local Dropdown = {}
    list = list or {}
    default = default or (list[1] or "None")

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1,-12,0,30)
    Frame.BackgroundColor3 = Library.Theme.BackgroundAlt
    Frame.BorderSizePixel = 0
    Frame.Parent = parent
    Round(Frame,8)
    Stroke(Frame, Library.Theme.Border,1)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1,-36,1,0)
    Label.Position = UDim2.new(0,8,0,0)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. default
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    Label.TextStrokeTransparency = 0.85
    Label.TextStrokeColor3 = Color3.fromRGB(0,0,0)

    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0,20,1,0)
    Arrow.Position = UDim2.new(1,-24,0,0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "▼"
    Arrow.Font = Enum.Font.Gotham
    Arrow.TextSize = 14
    Arrow.TextColor3 = Library.Theme.TextDim
    Arrow.TextXAlignment = Enum.TextXAlignment.Center
    Arrow.Parent = Frame

    local Open = false
    local ListFrame = Instance.new("Frame")
    ListFrame.Size = UDim2.new(0,0,0,0)
    ListFrame.Position = UDim2.new(0,0,0,0)
    ListFrame.BackgroundColor3 = Library.Theme.Background
    ListFrame.BorderSizePixel = 0
    ListFrame.Visible = false
    ListFrame.Parent = ScreenGui
    Round(ListFrame,8)
    Stroke(ListFrame, Library.Theme.Border,1)
    ListFrame.ZIndex = 10090

    local SearchBox = Instance.new("TextBox")
    SearchBox.Size = UDim2.new(1,-12,0,22)
    SearchBox.Position = UDim2.new(0,6,0,6)
    SearchBox.BackgroundColor3 = Library.Theme.BackgroundAlt
    SearchBox.BorderSizePixel = 0
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 13
    SearchBox.TextColor3 = Library.Theme.Text
    SearchBox.PlaceholderText = "Search..."
    SearchBox.PlaceholderColor3 = Library.Theme.TextDim
    SearchBox.Text = ""
    SearchBox.Parent = ListFrame
    Round(SearchBox,6)

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1,-12,1,-36)
    Scroll.Position = UDim2.new(0,6,0,34)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.CanvasSize = UDim2.new(0,0,0,0)
    Scroll.ScrollBarThickness = 6
    Scroll.ScrollBarImageColor3 = Library.Theme.Accent
    Scroll.Parent = ListFrame

    local Layout = Instance.new("UIListLayout")
    Layout.Parent = Scroll

    local function Refresh(filter)
        for _, child in ipairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        for _, item in ipairs(list) do
            if not filter or filter == "" or string.find(string.lower(item), string.lower(filter), 1, true) then
                local Option = Instance.new("TextButton")
                Option.Size = UDim2.new(1,0,0,24)
                Option.BackgroundTransparency = 1
                Option.Text = item
                Option.Font = Enum.Font.GothamSemibold
                Option.TextSize = 13
                Option.TextColor3 = Library.Theme.Text
                Option.Parent = Scroll
                Option.TextStrokeTransparency = 0.9
                Option.TextStrokeColor3 = Color3.fromRGB(0,0,0)

                Option.MouseEnter:Connect(function() Option.TextColor3 = Library.Theme.Accent end)
                Option.MouseLeave:Connect(function() Option.TextColor3 = Library.Theme.Text end)
                Option.MouseButton1Click:Connect(function()
                    Label.Text = text .. ": " .. item
                    ListFrame.Visible = false
                    Open = false
                    Arrow.Text = "▼"
                    Library._OpenDropdown = nil
                    if callback then pcall(callback, item) end
                end)
            end
        end
        Scroll.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y)
    end

    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y)
    end)

    Refresh()

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Refresh(SearchBox.Text)
    end)

    local function OpenList()
        if Library._OpenDropdown and Library._OpenDropdown.ListFrame then
            pcall(function() Library._OpenDropdown.ListFrame.Visible = false end)
            pcall(function() Library._OpenDropdown.Arrow.Text = "▼" end)
        end
        local absPos = Frame.AbsolutePosition
        local absSize = Frame.AbsoluteSize
        ListFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 6)
        ListFrame.Size = UDim2.new(0, absSize.X, 0, 200)
        ListFrame.Visible = true
        ListFrame.ZIndex = 10090
        Library._OpenDropdown = { ListFrame = ListFrame, Arrow = Arrow }
    end

    Frame.InputBegan:Connect(debounceOpen(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Open = not Open
            if Open then OpenList(); Arrow.Text = "▲" else ListFrame.Visible = false; Arrow.Text = "▼"; Library._OpenDropdown = nil end
        end
    end))

    Dropdown = Dropdown or {}
    Dropdown.set = function(val) if val == nil then val = "None" end; Label.Text = text .. ": " .. val end
    Dropdown.get = function() return Label.Text:sub(#text + 3) end
    Dropdown.setList = function(newList) list = newList or {}; if #list == 0 then Dropdown.set("None") else Dropdown.set(list[1]) end; Refresh() end

    Dropdown.type = "searchdropdown"
    RegisterElement(group, text, Dropdown)
    return Dropdown
end

-- Keybind
function Library:CreateKeybind(group, text, defaultKey, mode, callback, parent)
    local Keybind = {}
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1,-12,0,26)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.5,0,1,0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    Label.TextStrokeTransparency = 0.85
    Label.TextStrokeColor3 = Color3.fromRGB(0,0,0)

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.5,-6,1,0)
    Button.Position = UDim2.new(0.5,6,0,0)
    Button.BackgroundColor3 = Library.Theme.BackgroundAlt
    Button.BorderSizePixel = 0
    Button.Text = defaultKey or "Q"
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 14
    Button.TextColor3 = Library.Theme.Text
    Button.Parent = Frame
    Round(Button,8)
    Stroke(Button, Library.Theme.Border,1)

    local binding = false
    local currentKey = Enum.KeyCode[defaultKey] or Enum.KeyCode.Q

    Button.MouseButton1Click:Connect(function() binding = true; Button.Text = "..." end)
    Button.MouseEnter:Connect(function() Button.BackgroundColor3 = Library.Theme.Background end)
    Button.MouseLeave:Connect(function() if not binding then Button.BackgroundColor3 = Library.Theme.BackgroundAlt end end)

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
            if input.KeyCode == currentKey then if callback then pcall(callback) end end
        end
    end)

    Keybind.set = function(val) currentKey = Enum.KeyCode[val] or Enum.KeyCode.Q; Button.Text = val end
    Keybind.get = function() return Button.Text end
    Keybind.type = "keybind"
    RegisterElement(group, text, Keybind)
    return Keybind
end

-- Button
function Library:CreateButton(group, text, callback, parent)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1,-12,0,30)
    Button.BackgroundColor3 = Library.Theme.Accent
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.Font = Enum.Font.GothamSemibold
    Button.TextSize = 14
    Button.TextColor3 = Color3.fromRGB(20,20,20)
    Button.Parent = parent
    Round(Button,8)
    Stroke(Button, Library.Theme.Border,1)

    Button.MouseEnter:Connect(function() Button.BackgroundColor3 = Library.Theme.AccentDark end)
    Button.MouseLeave:Connect(function() Button.BackgroundColor3 = Library.Theme.Accent end)
    Button.MouseButton1Click:Connect(function() if callback then pcall(callback) end end)
    return Button
end

-- Color picker (simple cycle)
function Library:CreateColorPicker(group, text, default, callback, parent)
    local Picker = {}
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1,-12,0,26)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.5,0,1,0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 14
    Label.TextColor3 = Library.Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    Label.TextStrokeTransparency = 0.85
    Label.TextStrokeColor3 = Color3.fromRGB(0,0,0)

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.5,-6,1,0)
    Button.Position = UDim2.new(0.5,6,0,0)
    Button.BackgroundColor3 = default or Library.Theme.Accent
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.Parent = Frame
    Round(Button,8)
    Stroke(Button, Library.Theme.Border,1)

    local value = Button.BackgroundColor3
    Button.MouseButton1Click:Connect(function()
        local colors = {
            Library.Theme.Accent,
            Library.Theme.AccentDark,
            Library.Theme.AccentGreen,
            Color3.fromRGB(255,220,120)
        }
        local idx = 1
        for i,c in ipairs(colors) do if c == value then idx = i; break end end
        idx = idx % #colors + 1
        value = colors[idx]
        Button.BackgroundColor3 = value
        if callback then pcall(callback, value) end
    end)

    Picker.set = function(val) value = val; Button.BackgroundColor3 = val; if callback then pcall(callback, val) end end
    Picker.get = function() return value end
    Picker.type = "colorpicker"
    RegisterElement(group, text, Picker)
    return Picker
end

---------------------------------------------------------------------
-- Config Tab helper (Save As enforced)
---------------------------------------------------------------------
function Library:AttachConfigTab(Window, tabName)
    local Tab = Window:Tab(tabName or "Configs")
    local Box = Tab:Group("Configs", "Left")

    local currentConfig = nil
    local configs = self:GetConfigs()
    local ConfigDropdown = Box:Dropdown("Config", configs, (configs[1] or "None"), function(v) currentConfig = v end)
    if ConfigDropdown and ConfigDropdown.setList then ConfigDropdown.setList(configs) end

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

    local function promptSaveConfig(defaultName)
        defaultName = defaultName or "myconfig"
        local modal = Instance.new("ScreenGui")
        modal.Name = "extloverSavePrompt"
        modal.ResetOnSpawn = false
        SafeParentGui(modal)

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1,0,1,0)
        bg.BackgroundTransparency = 0.5
        bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
        bg.Parent = modal

        local box = Instance.new("Frame")
        box.Size = UDim2.new(0, 380, 0, 120)
        box.Position = UDim2.new(0.5, -190, 0.5, -60)
        box.BackgroundColor3 = Library.Theme.Background
        box.Parent = modal
        Round(box, 10)
        Stroke(box, Library.Theme.Border, 1)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -20, 0, 24)
        title.Position = UDim2.new(0, 10, 0, 8)
        title.BackgroundTransparency = 1
        title.Text = "Save Config As"
        title.Font = Enum.Font.GothamSemibold
        title.TextSize = 16
        title.TextColor3 = Library.Theme.Text
        title.Parent = box

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(1, -20, 0, 34)
        input.Position = UDim2.new(0, 10, 0, 40)
        input.Text = defaultName
        input.PlaceholderText = "config name"
        input.Font = Enum.Font.Gotham
        input.TextSize = 14
        input.TextColor3 = Library.Theme.Text
        input.BackgroundColor3 = Library.Theme.BackgroundAlt
        input.Parent = box
        Round(input, 8)

        local saveBtn = Instance.new("TextButton")
        saveBtn.Size = UDim2.new(0.5, -14, 0, 30)
        saveBtn.Position = UDim2.new(0, 10, 1, -40)
        saveBtn.Text = "Save"
        saveBtn.Font = Enum.Font.GothamSemibold
        saveBtn.TextSize = 14
        saveBtn.BackgroundColor3 = Library.Theme.Accent
        saveBtn.TextColor3 = Color3.fromRGB(20,20,20)
        saveBtn.Parent = box
        Round(saveBtn, 8)

        local cancelBtn = Instance.new("TextButton")
        cancelBtn.Size = UDim2.new(0.5, -14, 0, 30)
        cancelBtn.Position = UDim2.new(0.5, 4, 1, -40)
        cancelBtn.Text = "Cancel"
        cancelBtn.Font = Enum.Font.Gotham
        cancelBtn.TextSize = 14
        cancelBtn.BackgroundColor3 = Library.Theme.BackgroundAlt
        cancelBtn.TextColor3 = Library.Theme.Text
        cancelBtn.Parent = box
        Round(cancelBtn, 8)

        local function cleanup() pcall(function() modal:Destroy() end) end

        local function doSave()
            local name = trim(input.Text or "")
            if name == "" then
                Library:Notify("Please enter a valid name.", 2)
                return
            end
            local ok, err = pcall(function() return Library:SaveConfig(name) end)
            if not ok then
                Library:Notify("Save failed: " .. tostring(err), 3)
                warn("[extlover] SaveConfig error:", err)
            else
                Library:Notify("Config saved: " .. name, 2)
            end
            cleanup()
        end

        saveBtn.MouseButton1Click:Connect(doSave)
        cancelBtn.MouseButton1Click:Connect(cleanup)
        input.FocusLost:Connect(function(enterPressed)
            if enterPressed then doSave() end
        end)
    end

    Box:Button("Save As...", function() promptSaveConfig("myconfig") end)

    Box:Button("Load", function()
        if currentConfig and currentConfig ~= "None" then
            self:LoadConfig(currentConfig)
        else
            self:Notify("Select a config first.", 2)
        end
    end)

    local ThemeBox = Tab:Group("Appearance", "Right")
    ThemeBox:Dropdown("Theme", {"Pink","Dark"}, "Pink", function(v)
        if v == "Pink" then self:SetTheme("Pink") else self:SetTheme("Dark") end
        self:Notify("Theme changed. Rebuild UI to apply fully.", 3)
    end)
    ThemeBox:Toggle("Blur Background", false, function(v)
        self:SetBlur(v and self._UIVisible)
    end)
    ThemeBox:Button("Open Config Folder", function()
        self:Notify("Config folder: " .. self.ConfigFolder, 3)
    end)
end

---------------------------------------------------------------------
-- Theme setter and toggle key
---------------------------------------------------------------------
function Library:SetTheme(name)
    local theme = self.Themes[name]
    if not theme then return end
    self.Theme = theme
    dbg("Theme set to", name)
end

function Library:SetToggleKey(keycode)
    self.ToggleKey = keycode
end

function Library:ToggleUI()
    self._UIVisible = not self._UIVisible
    ScreenGui.Enabled = self._UIVisible
    if self._UIVisible and self._BlurEnabled then
        self:SetBlur(true)
    else
        self:SetBlur(false)
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Library.ToggleKey then
        Library:ToggleUI()
    end
end)

---------------------------------------------------------------------
-- Finalize
---------------------------------------------------------------------
Library:Notify(Library.Name .. " loaded", 3)
dbg("Library loaded; elements:", (function() local c=0; for _ in pairs(Library.Elements) do c=c+1 end; return c end)())

return Library
