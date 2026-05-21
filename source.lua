--[[
    Repaired Rayfield Reconstruction
    Cleaned + Stabilized Version
]]

local function getService(name)
    local service = game:GetService(name)
    return cloneref and cloneref(service) or service
end

--// Services
local Players = getService("Players")
local TweenService = getService("TweenService")
local UserInputService = getService("UserInputService")
local RunService = getService("RunService")
local HttpService = getService("HttpService")
local CoreGui = getService("CoreGui")
local GuiService = getService("GuiService")

--// Variables
local debugX = false
local useStudio = false
local requestsDisabled = false
local secureMode = false
local settingsInitialized = false
local settingsCreated = true
local overriddenSettings = {}
local globalLoaded = true

--// Safe Call
local function callSafely(func, ...)
    if not func then
        return nil
    end

    local success, result = pcall(func, ...)

    if success then
        return result
    else
        warn("Rayfield Error:", result)
        return nil
    end
end

--// HTTP Loader
local function loadWithTimeout(url, timeout)
    timeout = timeout or 10

    local completed = false
    local result = nil

    local thread = task.spawn(function()
        local success, response = pcall(function()
            return game:HttpGet(url)
        end)

        if success and type(response) == "string" and #response > 0 then
            local ok, loaded = pcall(function()
                return loadstring(response)()
            end)

            if ok then
                result = loaded
            else
                warn("Execution Error:", loaded)
            end
        else
            warn("Failed Request:", response)
        end

        completed = true
    end)

    task.delay(timeout, function()
        if not completed then
            pcall(task.cancel, thread)
            completed = true
            warn("Request timed out:", url)
        end
    end)

    repeat task.wait() until completed

    return result
end

--// Theme System
local Themes = {
    Default = {
        TextColor = Color3.fromRGB(240,240,240),
        Background = Color3.fromRGB(25,25,25),
        Topbar = Color3.fromRGB(34,34,34),
        Shadow = Color3.fromRGB(20,20,20),
        ElementBackground = Color3.fromRGB(35,35,35),
        ElementStroke = Color3.fromRGB(50,50,50),
        Accent = Color3.fromRGB(0,170,255)
    },

    Light = {
        TextColor = Color3.fromRGB(30,30,30),
        Background = Color3.fromRGB(240,240,240),
        Topbar = Color3.fromRGB(220,220,220),
        Shadow = Color3.fromRGB(180,180,180),
        ElementBackground = Color3.fromRGB(255,255,255),
        ElementStroke = Color3.fromRGB(200,200,200),
        Accent = Color3.fromRGB(0,120,255)
    }
}

local SelectedTheme = Themes.Default

--// Main Library
local RayfieldLibrary = {
    Flags = {},
    Theme = Themes,
    Notifications = {}
}

--// GUI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Rayfield"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Parent = ScreenGui
Main.Size = UDim2.new(0, 600, 0, 400)
Main.Position = UDim2.new(0.5, -300, 0.5, -200)
Main.BackgroundColor3 = SelectedTheme.Background
Main.BorderSizePixel = 0

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = Main

local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Parent = Main
Topbar.Size = UDim2.new(1, 0, 0, 40)
Topbar.BackgroundColor3 = SelectedTheme.Topbar
Topbar.BorderSizePixel = 0

local Title = Instance.new("TextLabel")
Title.Parent = Topbar
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "Rayfield Repaired"
Title.TextColor3 = SelectedTheme.TextColor
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left

local Tabs = Instance.new("Frame")
Tabs.Name = "Tabs"
Tabs.Parent = Main
Tabs.Position = UDim2.new(0, 0, 0, 40)
Tabs.Size = UDim2.new(0, 140, 1, -40)
Tabs.BackgroundColor3 = SelectedTheme.Topbar
Tabs.BorderSizePixel = 0

local Elements = Instance.new("ScrollingFrame")
Elements.Parent = Main
Elements.Position = UDim2.new(0, 140, 0, 40)
Elements.Size = UDim2.new(1, -140, 1, -40)
Elements.BackgroundTransparency = 1
Elements.CanvasSize = UDim2.new(0,0,0,0)
Elements.ScrollBarThickness = 4

local Layout = Instance.new("UIListLayout")
Layout.Parent = Elements
Layout.Padding = UDim.new(0, 8)

--// Dragging
local dragging = false
local dragStart
local startPos

Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
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

--// Notification System
function RayfieldLibrary:Notify(data)
    local Notification = Instance.new("Frame")
    Notification.Parent = ScreenGui
    Notification.Size = UDim2.new(0, 300, 0, 80)
    Notification.Position = UDim2.new(1, -320, 1, -100)
    Notification.BackgroundColor3 = SelectedTheme.Background
    Notification.BorderSizePixel = 0

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Notification

    local Text = Instance.new("TextLabel")
    Text.Parent = Notification
    Text.BackgroundTransparency = 1
    Text.Size = UDim2.new(1, -20, 1, -20)
    Text.Position = UDim2.new(0,10,0,10)
    Text.Font = Enum.Font.Gotham
    Text.TextColor3 = SelectedTheme.TextColor
    Text.TextWrapped = true
    Text.TextSize = 14
    Text.Text = tostring(data.Title or "Notification") .. "\n" .. tostring(data.Content or "")

    Notification.BackgroundTransparency = 1
    Text.TextTransparency = 1

    TweenService:Create(Notification, TweenInfo.new(0.3), {
        BackgroundTransparency = 0
    }):Play()

    TweenService:Create(Text, TweenInfo.new(0.3), {
        TextTransparency = 0
    }):Play()

    task.wait(data.Duration or 5)

    TweenService:Create(Notification, TweenInfo.new(0.3), {
        BackgroundTransparency = 1
    }):Play()

    TweenService:Create(Text, TweenInfo.new(0.3), {
        TextTransparency = 1
    }):Play()

    task.wait(0.35)
    Notification:Destroy()
end

--// Tabs
function RayfieldLibrary:CreateTab(name)
    local TabButton = Instance.new("TextButton")
    TabButton.Parent = Tabs
    TabButton.Size = UDim2.new(1, -10, 0, 35)
    TabButton.Position = UDim2.new(0,5,0,0)
    TabButton.BackgroundColor3 = SelectedTheme.ElementBackground
    TabButton.TextColor3 = SelectedTheme.TextColor
    TabButton.Text = name
    TabButton.Font = Enum.Font.Gotham
    TabButton.TextSize = 14

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.Parent = TabButton

    local Tab = {}

    function Tab:CreateButton(data)
        local Button = Instance.new("TextButton")
        Button.Parent = Elements
        Button.Size = UDim2.new(1, -10, 0, 40)
        Button.BackgroundColor3 = SelectedTheme.ElementBackground
        Button.TextColor3 = SelectedTheme.TextColor
        Button.Text = data.Name or "Button"
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 14

        local Corner = Instance.new("UICorner")
        Corner.Parent = Button

        Button.MouseButton1Click:Connect(function()
            if data.Callback then
                pcall(data.Callback)
            end
        end)
    end

    function Tab:CreateToggle(data)
        local Toggle = false

        local Button = Instance.new("TextButton")
        Button.Parent = Elements
        Button.Size = UDim2.new(1, -10, 0, 40)
        Button.BackgroundColor3 = SelectedTheme.ElementBackground
        Button.TextColor3 = SelectedTheme.TextColor
        Button.Text = data.Name or "Toggle"
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 14

        local Corner = Instance.new("UICorner")
        Corner.Parent = Button

        Button.MouseButton1Click:Connect(function()
            Toggle = not Toggle

            TweenService:Create(Button, TweenInfo.new(0.2), {
                BackgroundColor3 = Toggle and SelectedTheme.Accent or SelectedTheme.ElementBackground
            }):Play()

            if data.Callback then
                pcall(function()
                    data.Callback(Toggle)
                end)
            end
        end)
    end

    return Tab
end

--// Theme Change
function RayfieldLibrary:ChangeTheme(theme)
    if Themes[theme] then
        SelectedTheme = Themes[theme]

        Main.BackgroundColor3 = SelectedTheme.Background
        Topbar.BackgroundColor3 = SelectedTheme.Topbar
        Tabs.BackgroundColor3 = SelectedTheme.Topbar
        Title.TextColor3 = SelectedTheme.TextColor
    end
end

--// Search
function RayfieldLibrary:OpenSearch()
    self:Notify({
        Title = "Search",
        Content = "Search system opened.",
        Duration = 3
    })
end

--// Save Config
function RayfieldLibrary:SaveConfiguration(name)
    if not writefile then
        warn("writefile unsupported")
        return
    end

    local data = {}

    for i,v in pairs(self.Flags) do
        data[i] = v
    end

    writefile(name .. ".json", HttpService:JSONEncode(data))
end

--// Load Config
function RayfieldLibrary:LoadConfiguration(name)
    if not readfile or not isfile then
        warn("filesystem unsupported")
        return
    end

    if not isfile(name .. ".json") then
        return
    end

    local raw = readfile(name .. ".json")

    local success, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if success then
        self.Flags = decoded
    end
end

--// Example Usage
local MainTab = RayfieldLibrary:CreateTab("Main")

MainTab:CreateButton({
    Name = "Test Notification",
    Callback = function()
        RayfieldLibrary:Notify({
            Title = "Success",
            Content = "Rayfield repaired successfully.",
            Duration = 5
        })
    end
})
