-- extlover UI Library Template
-- File: 82jd2q9d8q2md2q.lua
-- Minimal, well-documented template for building the extlover UI library.
-- Replace placeholders and extend functions as needed.

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

---------------------------------------------------------------------
-- Basic Theme (matcha)
---------------------------------------------------------------------
Library.Themes = {
    Matcha = {
        Background    = Color3.fromRGB(28,34,30),
        BackgroundAlt = Color3.fromRGB(36,44,40),
        Border        = Color3.fromRGB(70,90,78),
        AccentPink    = Color3.fromRGB(255,150,200),
        AccentGreen   = Color3.fromRGB(150,220,170),
        Text          = Color3.fromRGB(245,250,240),
        TextDim       = Color3.fromRGB(190,200,190)
    }
}
Library.Theme = Library.Themes.Matcha

---------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------
local function Round(instance, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = instance
    return c
end

local function Stroke(instance, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Parent = instance
    return s
end

local function SafeParentGui(gui)
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        gui.Parent = LocalPlayer.PlayerGui
    else
        gui.Parent = CoreGui
    end
    if gui:IsA("ScreenGui") then
        pcall(function() gui.DisplayOrder = 10000 end)
    end
end

---------------------------------------------------------------------
-- Core UI container
---------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "extloverUI"
ScreenGui.ResetOnSpawn = false
SafeParentGui(ScreenGui)
Library._ScreenGui = ScreenGui
Library._UIVisible = true

---------------------------------------------------------------------
-- Basic state and registration
---------------------------------------------------------------------
Library.Elements = {}          -- element registry for configs
Library._Notifications = {}    -- notification queue
Library.ConfigFolder = "extlover/configs"
Library.ToggleKey = Enum.KeyCode.RightShift

local function registerElement(group, name, element)
    Library.Elements[group .. "." .. name] = element
end

---------------------------------------------------------------------
-- Minimal notification (wraps text)
---------------------------------------------------------------------
function Library:Notify(text, duration)
    duration = duration or 3
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 56)
    frame.Position = UDim2.new(1, -340, 0, 12 + (#self._Notifications * 64))
    frame.BackgroundColor3 = self.Theme.Background
    frame.BorderSizePixel = 0
    frame.Parent = ScreenGui
    Round(frame, 8)
    Stroke(frame, self.Theme.Border, 1)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -12)
    label.Position = UDim2.new(0, 10, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = tostring(text or "")
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 13
    label.TextColor3 = self.Theme.Text
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    table.insert(self._Notifications, frame)
    task.spawn(function()
        task.wait(duration)
        pcall(function() frame:Destroy() end)
        for i, v in ipairs(self._Notifications) do
            if v == frame then table.remove(self._Notifications, i); break end
        end
    end)
end

---------------------------------------------------------------------
-- Watermark (small pill, no text)
---------------------------------------------------------------------
function Library:Watermark(opts)
    if self._Watermark then return end
    opts = opts or {}
    local size = opts.size or 18
    local color = opts.color or self.Theme.AccentPink

    local gui = Instance.new("ScreenGui")
    gui.Name = "extloverWatermark"
    gui.ResetOnSpawn = false
    SafeParentGui(gui)

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, size, 0, size)
    pill.Position = UDim2.new(0, 12, 0, 12)
    pill.BackgroundColor3 = color
    pill.BorderSizePixel = 0
    pill.Parent = gui
    Round(pill, size/2)
    Stroke(pill, self.Theme.Border, 0.6)

    -- draggable
    do
        local dragging, startPos, startMouse = false, nil, nil
        pill.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                startMouse = input.Position
                startPos = pill.Position
            end
        end)
        pill.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - startMouse
                pill.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    self._Watermark = pill
end

---------------------------------------------------------------------
-- Simple window + tab template
---------------------------------------------------------------------
function Library:Window(title)
    local Window = {}

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 640, 0, 420)
    main.Position = UDim2.new(0.5, -320, 0.5, -210)
    main.BackgroundColor3 = self.Theme.Background
    main.BorderSizePixel = 0
    main.Parent = ScreenGui
    Round(main, 10)
    Stroke(main, self.Theme.Border, 1)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 32)
    top.BackgroundColor3 = self.Theme.BackgroundAlt
    top.Parent = main
    Round(top, 10)
    Stroke(top, self.Theme.Border, 1)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -12, 1, 0)
    titleLabel.Position = UDim2.new(0, 8, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or "extlover"
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = self.Theme.Text
    titleLabel.Parent = top

    -- tab area (simple)
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(0, 140, 1, -32)
    tabBar.Position = UDim2.new(0, 0, 0, 32)
    tabBar.BackgroundColor3 = self.Theme.BackgroundAlt
    tabBar.Parent = main
    Round(tabBar, 8)
    Stroke(tabBar, self.Theme.Border, 1)

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -160, 1, -40)
    content.Position = UDim2.new(0, 160, 0, 40)
    content.BackgroundTransparency = 1
    content.Parent = main

    -- simple tab creation
    local currentTab
    function Window:Tab(name)
        local tab = {}
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -12, 0, 28)
        btn.BackgroundColor3 = self.Theme.Background
        btn.Text = name
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.TextColor3 = self.Theme.TextDim
        btn.Parent = tabBar
        Round(btn, 6)

        local page = Instance.new("Frame")
        page.Size = UDim2.new(1, -12, 1, -12)
        page.Position = UDim2.new(0, 6, 0, 6)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = content

        btn.MouseButton1Click:Connect(function()
            if currentTab then currentTab.Visible = false end
            page.Visible = true
            currentTab = page
        end)

        -- group helper
        function tab:Group(groupName, side)
            local parent = page
            local groupFrame = Instance.new("Frame")
            groupFrame.Size = UDim2.new(1, -12, 0, 200)
            groupFrame.BackgroundColor3 = self.Theme.Background
            groupFrame.Parent = parent
            Round(groupFrame, 8)
            Stroke(groupFrame, self.Theme.Border, 1)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -12, 0, 20)
            label.Position = UDim2.new(0, 6, 0, 6)
            label.BackgroundTransparency = 1
            label.Text = groupName
            label.Font = Enum.Font.GothamSemibold
            label.TextSize = 14
            label.TextColor3 = self.Theme.Text
            label.Parent = groupFrame

            -- simple API for adding elements (extend as needed)
            local api = {}
            function api:Toggle(text, default, cb)
                local f = Instance.new("Frame")
                f.Size = UDim2.new(1, -12, 0, 28)
                f.BackgroundTransparency = 1
                f.Parent = groupFrame

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -40, 1, 0)
                lbl.Position = UDim2.new(0, 8, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = text
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextColor3 = Library.Theme.Text
                lbl.Parent = f

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 28, 0, 20)
                btn.Position = UDim2.new(1, -36, 0.5, -10)
                btn.BackgroundColor3 = Library.Theme.BackgroundAlt
                btn.Text = default and "ON" or "OFF"
                btn.Parent = f
                Round(btn, 6)

                local state = default or false
                btn.MouseButton1Click:Connect(function()
                    state = not state
                    btn.Text = state and "ON" or "OFF"
                    if cb then pcall(cb, state) end
                end)

                -- register for config
                registerElement(groupName, text, { type = "toggle", set = function(v) state = v; btn.Text = v and "ON" or "OFF" end, get = function() return state end })
                return { set = function(v) state = v; btn.Text = v and "ON" or "OFF" end, get = function() return state end }
            end

            return api
        end

        return tab
    end

    Window.Main = main
    return Window
end

---------------------------------------------------------------------
-- Config helpers (simple Save As prompt)
---------------------------------------------------------------------
function Library:PromptSaveConfig(defaultName)
    defaultName = defaultName or "default"
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
    box.Size = UDim2.new(0, 360, 0, 120)
    box.Position = UDim2.new(0.5, -180, 0.5, -60)
    box.BackgroundColor3 = self.Theme.Background
    box.Parent = modal
    Round(box, 8)
    Stroke(box, self.Theme.Border, 1)

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 0, 32)
    input.Position = UDim2.new(0, 10, 0, 40)
    input.Text = defaultName
    input.Parent = box

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.5, -12, 0, 28)
    saveBtn.Position = UDim2.new(0, 10, 1, -40)
    saveBtn.Text = "Save"
    saveBtn.Parent = box

    saveBtn.MouseButton1Click:Connect(function()
        local name = tostring(input.Text or ""):gsub("%s+", "")
        if name ~= "" then
            -- call SaveConfig (implement SaveConfig to write files)
            if Library.SaveConfig then pcall(function() Library:SaveConfig(name) end) end
            pcall(function() modal:Destroy() end)
        else
            Library:Notify("Enter a valid name", 2)
        end
    end)
end

---------------------------------------------------------------------
-- Toggle UI key
---------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Library.ToggleKey then
        Library._UIVisible = not Library._UIVisible
        ScreenGui.Enabled = Library._UIVisible
    end
end)

---------------------------------------------------------------------
-- Return
---------------------------------------------------------------------
return Library
