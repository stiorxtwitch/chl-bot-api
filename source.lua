--[[

    Rayfield Interface Suite
    by Sirius

    shlex  | Designing + Programming
    iRay   | Programming
    Max    | Programming
    Damian | Programming

]]

if debugX then
    warn('Initialising Rayfield')
end



local function getService(name)
    local service = game:GetService(name)
    return if cloneref then cloneref(service) else service
end

-- Services
local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")

-- Loads and executes a function hosted on a remote URL. Cancels the request if the requested URL takes too long to respond.
-- Errors with the function are caught and logged to the output
local function loadWithTimeout(url: string, timeout: number?): ...any
    assert(type(url) == "string", "Expected string, got " .. type(url))
    timeout = timeout or 5
    local requestCompleted = false
    local success, result = false, nil

    local requestThread = task.spawn(function()
        local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url) -- game:HttpGet(url)
        -- If the request fails the content can be empty, even if fetchSuccess is true
        if not fetchSuccess or #fetchResult == 0 then
            if #fetchResult == 0 then
                fetchResult = "Empty response" -- Set the error message
            end
            success, result = false, fetchResult
            requestCompleted = true
            return
        end
        local content = fetchResult -- Fetched content
        local execSuccess, execResult = pcall(function()
            return loadstring(content)()
        end)
        success, result = execSuccess, execResult
        requestCompleted = true
    end)

    local timeoutThread = task.delay(timeout, function()
        if not requestCompleted then
            warn("Request for " .. url .. " timed out after " .. tostring(timeout) .. " seconds")
            task.cancel(requestThread)
            result = "Request timed out"
            requestCompleted = true
        end
    end)

    -- Wait for completion or timeout
    while not requestCompleted do
        task.wait()
    end
    -- Cancel timeout thread if still running when request completes
    if coroutine.status(timeoutThread) ~= "dead" then
        task.cancel(timeoutThread)
    end
    if not success then
        warn("Failed to process " .. tostring(url) .. ": " .. tostring(result))
    end
    return if success then result else nil
end

local _getgenv = rawget(_G, "getgenv")
local requestsDisabled = false
local customAssetId = nil
local secureMode = false
if _getgenv then
    local ok, result = pcall(function() return _getgenv().DISABLE_RAYFIELD_REQUESTS end)
    if ok and result then requestsDisabled = true end
    local ok2, result2 = pcall(function() return _getgenv().RAYFIELD_ASSET_ID end)
    if ok2 and type(result2) == "number" then customAssetId = result2 end
    local ok3, result3 = pcall(function() return _getgenv().RAYFIELD_SECURE end)
    if ok3 and result3 then secureMode = true end
end

if secureMode then
    local _error = error
    local _assert = assert
    warn = function(...) end
    print = function(...) end
    error = function(_, level) _error("", level) end
    assert = function(v, ...) return _assert(v) end
end

local secureWarnings = {}
local customAssets = {}

local function secureNotify(wType, title, content)
    if secureWarnings[wType] then return end
    secureWarnings[wType] = true
    task.spawn(function()
        while not RayfieldLibrary or not RayfieldLibrary.Notify do task.wait(0.5) end
        RayfieldLibrary:Notify({
            Title = title,
            Content = content,
            Duration = 8,
        })
    end)
end
local InterfaceBuild = 'UU2NX'
local Release = "Build 1.746"
local RayfieldFolder = "Rayfield"
local ConfigurationFolder = RayfieldFolder.."/Configurations"
local ConfigurationExtension = ".rfld"
local settingsTable = {
    General = {
        -- if needs be in order just make getSetting(name)
        rayfieldOpen = {Type = 'bind', Value = 'K', Name = 'Rayfield Keybind'},
        -- buildwarnings
        -- rayfieldprompts

    },
    System = {
        usageAnalytics = {Type = 'toggle', Value = true, Name = 'A...
    }
}
			-- Validate prompt loaded correctly
if not prompt and not useStudio then
    warn("Failed to load prompt library, using fallback")
    prompt = {
        create = function() end -- No-op fallback
    }
end


-- The function below provides a safe alternative for calling error-prone functions
-- Especially useful for filesystem function (writefile, makefolder, etc.)
local function callSafely(func, ...)
    if func then
        local success, result = pcall(func, ...)
        if not success then
            warn("Rayfield | Function failed with error: ", result)
            return false
        else
            return result
        end
    end
end

-- Ensures a folder exists by creating it if needed
local function ensureFolder(folderPath)
    if isfolder and not callSafely(isfolder, folderPath) then
        callSafely(makefolder, folderPath)
    end
end

local function loadSettings()
    local file = nil

    local success, result =	pcall(function()
        if callSafely(isfolder, RayfieldFolder) then
            if callSafely(isfile, RayfieldFolder..'/settings'..ConfigurationExtension) then
                file = callSafely(readfile, RayfieldFolder..'/settings'..ConfigurationExtension)
            end
        end

        -- for debug in studio
        if useStudio then
            file = [[
        {"General":{"rayfieldOpen":{"Value":"K","Type":"bind","Name":"Rayfield Keybind","Element":{"HoldToInteract":false,"Ext":true,"Name":"Rayfield Keybind","Set":null,"CallOnChange":true,"Callback":null,"CurrentKeybind":"K"}}},"System":{"usageAnalytics":{"Value":false,"Type":"toggle","Name":"A...
        ]]
        end

        if file then
            local decodeSuccess, decodedFile = pcall(function() return HttpService:JSONDecode(file) end)
            if decodeSuccess then
                file = decodedFile
            else
                file = {}
            end
        else
            file = {}
        end


        if not settingsCreated then
            return
        end

        if next(file) ~= nil then
            for categoryName, settingCategory in pairs(settingsTable) do
                if file[categoryName] then
                    for settingName, setting in pairs(settingCategory) do
                        if file[categoryName][settingName] then
                            setting.Value = file[categoryName][settingName].Value
                            setting.Element:Set(getSetting(categoryName, settingName))
                        end
                    end
                end
            end
        -- If no settings saved, apply overridden settings only
        else
            for settingName, settingValue in overriddenSettings do
                local split = string.split(settingName, ".")
                assert(#split == 2, "Rayfield | Invalid overridden setting name: " .. settingName)
                local categoryName = split[1]
                local settingNameOnly = split[2]
                if settingsTable[categoryName] and settingsTable[categoryName][settingNameOnly] then
                    settingsTable[categoryName][settingNameOnly].Element:Set(settingValue)
                end
            end
        end
        settingsInitialized = true
    end)

    if not success then 
        if writefile then
            warn('Rayfield had an issue accessing configuration saving capability.')
        end
    end
end

if debugX then
    warn('Now Loading Settings Configuration')
end

loadSettings()

if debugX then
    warn('Settings Loaded')
end

local ANALYTICS_TOKEN = "05de7f9fd320d3b8428cd1c77014a337b85b6c8efee2c5914f5ab5700c354b9a"

local reporter = nil
if not requestsDisabled and not useStudio then
    local fetchSuccess, fetchResult = pcall((game :: any).HttpGet, game, "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/reporter.lua")
    if fetchSuccess and #fetchResult > 0 then
        local execSuccess, Analytics = pcall(function()
            return (loadstring(fetchResult) :: any)()
        end)
        if execSuccess and Analytics then
            pcall(function()
                reporter = Analytics.new({
                    url          = "https://rayfield-collect.sirius-software-ltd.workers.dev",
                    token        = ANALYTICS_TOKEN,
                    product_name = "Rayfield",
                    category     = "UILibrary",
                })
            end)
        end
    end
end

local promptUser = 2

if promptUser == 1 and prompt and type(prompt.create) == "function" then
    prompt.create(
        'Be cautious when running scripts',
        [[Please be careful when running scripts from unknown developers. This script has already been ran.

<font transparency='0.3'>Some scripts may steal your items or in-game goods.</font>]],
        'Okay',
        '',
        function()

        end
    )
end

if debugX then
    warn('Moving on to continue initialisation')
end

local RayfieldLibrary = {
    Flags = {},
    Theme = {
        Default = {
            TextColor = Color3.fromRGB(240, 240, 240),

            Background = Color3.fromRGB(25, 25, 25),
            Topbar = Color3.fromRGB(34, 34, 34),
            Shadow = Color3.fromRGB(20, 20, 20),

            NotificationBackground = Color3.fromRGB(20, 20, 20),
            NotificationActionsBackground = Color3.fromRGB(230, 230, 230),

            TabBackground = Color3.fromRGB(80, 80, 80),
            TabStroke = Color3.fromRGB(85, 85, 85),
            TabBackgroundSelected = Color3.fromRGB(210, 210, 210),
            TabTextColor = Color3.fromRGB(240, 240, 240),
            SelectedTabTextColor = Color3.fromRGB(50, 50, 50),

            ElementBackground = Color3.fromRGB(35, 35, 35),
            ElementBackgroundHover = Color3.fromRGB(40, 40, 40),
            SecondaryElementBackground = Color3.fromRGB(25, 25, 25),
            ElementStroke = Color3.fromRGB(50, 50, 50),
            SecondaryElementStroke = Color3.fromRGB(40, 40, 40),

            SliderBackground = Color3.fromRGB(50, 138, 220),
            SliderProgress = Color3.fromRGB(50, 138, 220),
            SliderStroke = Color3.fromRGB(58, 163, 255),

            ToggleBackground = Color3.fromRGB(30, 30, 30),
            ToggleEnabled = Color3.fromRGB(0, 146, 214),
            ToggleDisabled = Color3.fromRGB(100, 100, 100),
            ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
            ToggleDisabledStroke = Color3.fromRGB(125, 125, 125),
            ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
            ToggleDisabledOuterStroke = Color3.fromRGB(65, 65, 65),

            DropdownSelected = Color3.fromRGB(40, 40, 40),
            DropdownUnselected = Color3.fromRGB(30, 30, 30),

            InputBackground = Color3.fromRGB(30, 30, 30),
            InputStroke = Color3.fromRGB(65, 65, 65),
            PlaceholderColor = Color3.fromRGB(178, 178, 178)
        },

        Ocean = {
            TextColor = Color3.fromRGB(230, 240, 240),

            Background = Color3.fromRGB(20, 30, 30),
            Topbar = Color3.fromRGB(25, 40, 40),
            Shadow = Color3.fromRGB(15, 20, 20),

            NotificationBackground = Color3.fromRGB(25, 35, 35),
            NotificationActionsBackground = Color3.fromRGB(230, 240, 240),

            TabBackground = Color3.fromRGB(40, 60, 60),
            TabStroke = Color3.fromRGB(50, 70, 70),
            TabBackgroundSelected = Color3.fromRGB(100, 180, 180),
            TabTextColor = Color3.fromRGB(210, 230, 230),
            SelectedTabTextColor = Color3.fromRGB(20, 50, 50),

            ElementBackground = Color3.fromRGB(30, 50, 50),
            ElementBackgroundHover = Color3.fromRGB(40, 60, 60),
            SecondaryElementBackground = Color3.fromRGB(30, 45, 45),
            ElementStroke = Color3.fromRGB(45, 70, 70),
            SecondaryElementStroke = Color3.fromRGB(40, 65, 65),

            SliderBackground = Color3.fromRGB(0, 110, 110),
            SliderProgress = Color3.fromRGB(0, 140, 140),
            SliderStroke = Color3.fromRGB(0, 160, 160),

            ToggleBackground = Color3.fromRGB(30, 50, 50),
            ToggleEnabled = Color3.fromRGB(0, 130, 130),
            ToggleDisabled = Color3.fromRGB(70, 90, 90),
            ToggleEnabledStroke = Color3.fromRGB(0, 160, 160),
            ToggleDisabledStroke = Color3.fromRGB(85, 105, 105),
            ToggleEnabledOuterStroke = Color3.fromRGB(50, 100, 100),
            ToggleDisabledOuterStroke = Color3.fromRGB(45, 65, 65),

            DropdownSelected = Color3.fromRGB(30, 60, 60),
            DropdownUnselected = Color3.fromRGB(25, 40, 40),

            InputBackground = Color3.fromRGB(30, 50, 50),
            InputStroke = Color3.fromRGB(50, 70, 70),
            PlaceholderColor = Color3.fromRGB(140, 160, 160)
        },

        AmberGlow = {
            TextColor = Color3.fromRGB(255, 245, 230),

            Background = Color3.fromRGB(45, 30, 20),
            Topbar = Color3.fromRGB(55, 40, 25),
            Shadow = Color3.fromRGB(35, 25, 15),

            NotificationBackground = Color3.fromRGB(50, 35, 25),
            NotificationActionsBackground = Color3.fromRGB(245, 230, 215),

            TabBackground = Color3.fromRGB(75, 50, 35),
            TabStroke = Color3.fromRGB(90, 60, 45),
            TabBackgroundSelected = Color3.fromRGB(230, 180, 100),
            TabTextColor = Color3.fromRGB(250, 220, 200),
            SelectedTabTextColor = Color3.fromRGB(50, 30, 10),

            ElementBackground = Color3.fromRGB(60, 45, 35),
            ElementBackgroundHover = Color3.fromRGB(70, 50, 40),
            SecondaryElementBackground = Color3.fromRGB(55, 40, 30),
            ElementStroke = Color3.fromRGB(85, 60, 45),
            SecondaryElementStroke = Color3.fromRGB(75, 50, 35),

            SliderBackground = Color3.fromRGB(220, 130, 60),
            SliderProgress = Color3.fromRGB(250, 150, 75),
            SliderStroke = Color3.fromRGB(255, 170, 85),

            ToggleBackground = Color3.fromRGB(55, 40, 30),
            ToggleEnabled = Color3.fromRGB(240, 130, 30),
            ToggleDisabled = Color3.fromRGB(90, 70, 60),
            ToggleEnabledStroke = Color3.fromRGB(255, 160, 50),
            ToggleDisabledStroke = Color3.fromRGB(110, 85, 75),
            ToggleEnabledOuterStroke = Color3.fromRGB(200, 100, 50),
            ToggleDisabledOuterStroke = Color3.fromRGB(75, 60, 55),

            DropdownSelected = Color3.fromRGB(70, 50, 40),
            DropdownUnselected = Color3.fromRGB(55, 40, 30),

            InputBackground = Color3.fromRGB(60, 45, 35),
            InputStroke = Color3.fromRGB(90, 65, 50),
            PlaceholderColor = Color3.fromRGB(190, 150, 130)
        },

        Light = {
            TextColor = Color3.fromRGB(40, 40, 40),

            Background = Color3.fromRGB(245, 245, 245),
            Topbar = Color3.fromRGB(230, 230, 230),
            Shadow = Color3.fromRGB(200, 200, 200),

            NotificationBackground = Color3.fromRGB(250, 250, 250),
            NotificationActionsBackground = Color3.fromRGB(240, 240, 240),

            TabBackground = Color3.fromRGB(235, 235, 235),
            TabStroke = Color3.fromRGB(215, 215, 215),
            TabBackgroundSelected = Color3.fromRGB(255, 255, 255),
            TabTextColor = Color3.fromRGB(80, 80, 80),
            SelectedTabTextColor = Color3.fromRGB(0, 0, 0),

            ElementBackground = Color3.fromRGB(240, 240, 240),
            ElementBackgroundHover = Color3.fromRGB(225, 225, 225),
            SecondaryElementBackground = Color3.fromRGB(235, 235, 235),
            ElementStroke = Color3.fromRGB(210, 210, 210),
            SecondaryElementStroke = Color3.fromRGB(210, 210, 210),

            SliderBackground = Color3.fromRGB(150, 180, 220),
            SliderProgress = Color3.fromRGB(100, 150, 200), 
            SliderStroke = Color3.fromRGB(120, 170, 220),

            ToggleBackground = Color3.fromRGB(220, 220, 220),
            ToggleEnabled = Color3.fromRGB(0, 146, 214),
            ToggleDisabled = Color3.fromRGB(150, 150, 150),
            ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
            ToggleDisabledStroke = Color3.fromRGB(170, 170, 170),
            ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
            ToggleDisabledOuterStroke = Color3.fromRGB(180, 180, 180),

            DropdownSelected = Color3.fromRGB(230, 230, 230),
            DropdownUnselected = Color3.fromRGB(220, 220, 220),

            InputBackground = Color3.fromRGB(240, 240, 240),
            InputStroke = Color3.fromRGB(180, 180, 180),
            PlaceholderColor = Color3.fromRGB(140, 140, 140)
        },
    }
}
			-- Object Variables

local Main = Rayfield.Main
local MPrompt = Rayfield:FindFirstChild('Prompt')
local Topbar = Main.Topbar
local Elements = Main.Elements
local LoadingFrame = Main.LoadingFrame
local TabList = Main.TabList
local dragBar = Rayfield:FindFirstChild('Drag')
local dragInteract = dragBar and dragBar.Interact or nil
local dragBarCosmetic = dragBar and dragBar.Drag or nil

local dragOffset = 255
local dragOffsetMobile = 150

Rayfield.DisplayOrder = 100
LoadingFrame.Version.Text = Release

-- Thanks to Latte Softworks for the Lucide integration for Roblox
local Icons = useStudio and require(script.Parent.icons) or loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua')
-- Variables

local CFileName = nil
local CEnabled = false
local Minimised = false
local Hidden = false
local Debounce = false
local searchOpen = false
local Notifications = Rayfield.Notifications
local keybindConnections = {} -- For storing keybind connections to disconnect when Rayfield is destroyed

local SelectedTheme = RayfieldLibrary.Theme.Default

local function ChangeTheme(Theme)
    if typeof(Theme) == 'string' then
        SelectedTheme = RayfieldLibrary.Theme[Theme]
    elseif typeof(Theme) == 'table' then
        SelectedTheme = Theme
    end

    Rayfield.Main.BackgroundColor3 = SelectedTheme.Background
    Rayfield.Main.Topbar.BackgroundColor3 = SelectedTheme.Topbar
    Rayfield.Main.Topbar.CornerRepair.BackgroundColor3 = SelectedTheme.Topbar
    Rayfield.Main.Shadow.Image.ImageColor3 = SelectedTheme.Shadow

    Rayfield.Main.Topbar.ChangeSize.ImageColor3 = SelectedTheme.TextColor
    Rayfield.Main.Topbar.Hide.ImageColor3 = SelectedTheme.TextColor
    Rayfield.Main.Topbar.Search.ImageColor3 = SelectedTheme.TextColor
    if Topbar:FindFirstChild('Settings') then
        Rayfield.Main.Topbar.Settings.ImageColor3 = SelectedTheme.TextColor
        Rayfield.Main.Topbar.Divider.BackgroundColor3 = SelectedTheme.ElementStroke
    end

    Main.Search.BackgroundColor3 = SelectedTheme.TextColor
    Main.Search.Shadow.ImageColor3 = SelectedTheme.TextColor
    Main.Search.Search.ImageColor3 = SelectedTheme.TextColor
    Main.Search.Input.PlaceholderColor3 = SelectedTheme.TextColor
    Main.Search.UIStroke.Color = SelectedTheme.SecondaryElementStroke

    if Main:FindFirstChild('Notice') then
        Main.Notice.BackgroundColor3 = SelectedTheme.Background
    end

    for _, text in ipairs(Rayfield:GetDescendants()) do
        if text.Parent.Parent ~= Notifications then
            if text:IsA('TextLabel') or text:IsA('TextBox') then text.TextColor3 = SelectedTheme.TextColor end
        end
    end

    for _, TabPage in ipairs(Elements:GetChildren()) do
        for _, Element in ipairs(TabPage:GetChildren()) do
            if Element.ClassName == "Frame" and Element.Name ~= "Placeholder" and Element.Name ~= "SectionSpacing" and Element.Name ~= "Divider" and Element.Name ~= "SectionTitle" and Element.Name ~= "SearchTitle-fsefsefesfsefesfesfThanks" then
                Element.BackgroundColor3 = SelectedTheme.ElementBackground
                Element.UIStroke.Color = SelectedTheme.ElementStroke
            end
        end
    end
end

local function getIcon(name : string): {id: number, imageRectSize: Vector2, imageRectOffset: Vector2}
    if not Icons then
        warn("Lucide Icons: Cannot use icons as icons library is not loaded")
        return
    end
    name = string.match(string.lower(name), "^%s*(.*)%s*$") :: string
    local sizedicons = Icons['48px']
    local r = sizedicons[name]
    if not r then
        error("Lucide Icons: Failed to find icon by the name of \"" .. name .. "\"", 2)
    end

    local rirs = r[2]
    local riro = r[3]

    if type(r[1]) ~= "number" or type(rirs) ~= "table" or type(riro) ~= "table" then
        error("Lucide Icons: Internal error: Invalid auto-generated asset entry")
    end

    local irs = Vector2.new(rirs[1], rirs[2])
    local iro = Vector2.new(riro[1], riro[2])

    local asset = {
        id = r[1],
        imageRectSize = irs,
        imageRectOffset = iro,
    }

    return asset
end
local function getAssetUri(id: any): string
    local assetUri = ""
    if type(id) == "number" then
        assetUri = "rbxassetid://" .. id
    elseif type(id) == "string" and not Icons then
        warn("Rayfield | Cannot use Lucide icons as icons library is not loaded")
    else
        warn("Rayfield | The icon argument must either be an icon ID (number) or a Lucide icon name (string)")
    end
    return assetUri
end

local function isCustomAsset(value)
    return type(value) == "string" and (string.find(value, "rbxasset://") == 1 or string.find(value, "rbxthumb://") == 1)
end

local function resolveIcon(icon)
    if not icon or icon == 0 then
        return "", nil, nil
    end

    if isCustomAsset(icon) then
        return icon, nil, nil
    end

    if secureMode then
        secureNotify("icon_blocked", "Secure Mode", "Element icons using asset IDs or Lucide names are blocked. Use getcustomasset() for icons to stay undetected.")
        return "", nil, nil
    end

    if typeof(icon) == "string" and Icons then
        local asset = getIcon(icon)
        return "rbxassetid://" .. asset.id, asset.imageRectOffset, asset.imageRectSize
    else
        return getAssetUri(icon), nil, nil
    end
end

local function makeDraggable(object, dragObject, enableTaptic, tapticOffset)
    local dragging = false
    local relative = nil

    local offset = Vector2.zero
    local screenGui = object:FindFirstAncestorWhichIsA("ScreenGui")
    if screenGui and screenGui.IgnoreGuiInset then
        offset += getService('GuiService'):GetGuiInset()
    end

    local function connectFunctions()
        if dragBar and enableTaptic then
            dragBar.MouseEnter:Connect(function()
                if not dragging and not Hidden then
                    TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5, Size = UDim2.new(0, 120, 0, 4)}):Play()
                end
            end)

            dragBar.MouseLeave:Connect(function()
                if not dragging and not Hidden then
                    TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7, Size = UDim2.new(0, 100, 0, 4)}):Play()
                end
            end)
        end
    end

    connectFunctions()

    dragObject.InputBegan:Connect(function(input, processed)
        if processed then return end

        local inputType = input.UserInputType.Name
        if inputType == "MouseButton1" or inputType == "Touch" then
            dragging = true

            relative = object.AbsolutePosition + object.AbsoluteSize * object.AnchorPoint - UserInputService:GetMouseLocation()
            if enableTaptic and not Hidden then
                TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 110, 0, 4), BackgroundTransparency = 0}):Play()
            end
        end
    end)

    local inputEnded = UserInputService.InputEnded:Connect(function(input)
        if not dragging then return end

        local inputType = input.UserInputType.Name
        if inputType == "MouseButton1" or inputType == "Touch" then
            dragging = false

            if enableTaptic and not Hidden then
                TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 100, 0, 4), BackgroundTransparency = 0.7}):Play()
            end
        end
    end)

    local renderStepped = RunService.RenderStepped:Connect(function()
        if dragging and not Hidden then
            local position = UserInputService:GetMouseLocation() + relative + offset
            if enableTaptic and tapticOffset then
                TweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(position.X, position.Y)}):Play()
                TweenService:Create(dragBar, TweenInfo.new(0.05, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(position.X, position.Y + ((useMobileSizing and tapticOffset[2]) or tapticOffset[1]))}):Play()
            else
                if dragBar and tapticOffset then
                    dragBar.Position = UDim2.fromOffset(position.X, position.Y + ((useMobileSizing and tapticOffset[2]) or tapticOffset[1]))
                end
                object.Position = UDim2.fromOffset(position.X, position.Y)
            end
        end
    end)

    object.Destroying:Connect(function()
        if inputEnded then inputEnded:Disconnect() end
        if renderStepped then renderStepped:Disconnect() end
    end)
end


local function PackColor(Color)
    return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end    

local function UnpackColor(Color)
    return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadConfiguration(Configuration)
    local success, Data = pcall(function() return HttpService:JSONDecode(Configuration) end)
    local changed

    if not success then warn('Rayfield had an issue decoding the configuration file, please try delete the file and reopen Rayfield.') return end

    -- Iterate through current UI elements' flags
    for FlagName, Flag in pairs(RayfieldLibrary.Flags) do
        local FlagValue = Data[FlagName]

        if (typeof(FlagValue) == 'boolean' and FlagValue == false) or FlagValue then
            task.spawn(function()
                if Flag.Type == "ColorPicker" then
                    changed = true
                    Flag:Set(UnpackColor(FlagValue))
                else
                    if (Flag.CurrentValue or Flag.CurrentKeybind or Flag.CurrentOption or Flag.Color) ~= FlagValue then 
                        changed = true
                        Flag:Set(FlagValue)   
                    end
                end
            end)
        else
            warn("Rayfield | Unable to find '"..FlagName.. "' in the save file.")
            print("The error above may not be an issue if new elements have been added or not been set values.")
            --RayfieldLibrary:Notify({Title = "Rayfield Flags", Content = "Rayfield was unable to find '"..FlagName.. "' in the save file. Check sirius.menu/discord for help.", Image = 3944688398})
        end
    end

    return changed
end

local function SaveConfiguration()
    if not CEnabled or not globalLoaded then return end

    if debugX then
        print('Saving')
    end

    local Data = {}
    for i, v in pairs(RayfieldLibrary.Flags) do
        if v.Type == "ColorPicker" then
            Data[i] = PackColor(v.Color)
        else
            if typeof(v.CurrentValue) == 'boolean' then
                if v.CurrentValue == false then
                    Data[i] = false
                else
                    Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
                end
            else
                Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
            end
        end
    end

    if useStudio then
        if script.Parent:FindFirstChild('configuration') then script.Parent.configuration:Destroy() end

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Parent = script.Parent
        ScreenGui.Name = 'configuration'

        local TextBox = Instance.new("TextBox")
        TextBox.Parent = ScreenGui
        TextBox.Size = UDim2.new(0, 800, 0, 50)
        TextBox.AnchorPoint = Vector2.new(0.5, 0)
        TextBox.Position = UDim2.new(0.5, 0, 0, 30)
        TextBox.Text = HttpService:JSONEncode(Data)
        TextBox.ClearTextOnFocus = false
    end

    if debugX then
        warn(HttpService:JSONEncode(Data))
    end


    callSafely(writefile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension, tostring(HttpService:JSONEncode(Data)))
end

function RayfieldLibrary:Notify(data) -- action e.g open messages
    task.spawn(function()

        -- Notification Object Creation
        local newNotification = Notifications.Template:Clone()
        newNotification.Name = data.Title or 'No Title Provided'
        newNotification.Parent = Notifications
        newNotification.LayoutOrder = #Notifications:GetChildren()
        newNotification.Visible = false

        -- Set Data
        newNotification.Title.Text = data.Title or "Unknown Title"
        newNotification.Description.Text = data.Content or "Unknown Content"

        if data.Image then
            local img, rectOffset, rectSize = resolveIcon(data.Image)
            newNotification.Icon.Image = img
            if rectOffset then newNotification.Icon.ImageRectOffset = rectOffset end
            if rectSize then newNotification.Icon.ImageRectSize = rectSize end
        else
            newNotification.Icon.Image = ""
        end

        -- Set initial transparency values

        newNotification.Title.TextColor3 = SelectedTheme.TextColor
        newNotification.Description.TextColor3 = SelectedTheme.TextColor
        newNotification.BackgroundColor3 = SelectedTheme.Background
        newNotification.UIStroke.Color = SelectedTheme.TextColor
        newNotification.Icon.ImageColor3 = SelectedTheme.TextColor

        newNotification.BackgroundTransparency = 1
        newNotification.Title.TextTransparency = 1
        newNotification.Description.TextTransparency = 1
        newNotification.UIStroke.Transparency = 1
        newNotification.Shadow.ImageTransparency = 1
        newNotification.Size = UDim2.new(1, 0, 0, 800)
        newNotification.Icon.ImageTransparency = 1
        newNotification.Icon.BackgroundTransparency = 1

        task.wait()

        newNotification.Visible = true

        if data.Actions then
            warn('Rayfield | Not seeing your actions in notifications?')
            print("Notification Actions are being sunset for now, keep up to date on when they're back in the discord. (sirius.menu/discord)")
        end

        -- Calculate textbounds and set initial values
        local bounds = {newNotification.Title.TextBounds.Y, newNotification.Description.TextBounds.Y}
        newNotification.Size = UDim2.new(1, -60, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)

        newNotification.Icon.Size = UDim2.new(0, 32, 0, 32)
        newNotification.Icon.Position = UDim2.new(0, 20, 0.5, 0)

        TweenService:Create(newNotification, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 0, math.max(bounds[1] + bounds[2] + 31, 60))}):Play()

        task.wait(0.15)
        TweenService:Create(newNotification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.45}):Play()
        TweenService:Create(newNotification.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

        task.wait(0.05)

        TweenService:Create(newNotification.Icon, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()

        task.wait(0.05)
        TweenService:Create(newNotification.Description, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.35}):Play()
        TweenService:Create(newNotification.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.95}):Play()
        TweenService:Create(newNotification.Shadow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.82}):Play()

        local waitDuration = math.min(math.max((#newNotification.Description.Text * 0.1) + 2.5, 3), 10)
        task.wait(data.Duration or waitDuration)

        newNotification.Icon.Visible = false
        TweenService:Create(newNotification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
        TweenService:Create(newNotification.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
        TweenService:Create(newNotification.Shadow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
        TweenService:Create(newNotification.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
        TweenService:Create(newNotification.Description, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

        TweenService:Create(newNotification, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -90, 0, 0)}):Play()

        task.wait(1)

        TweenService:Create(newNotification, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -90, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)}):Play()

        newNotification.Visible = false
        newNotification:Destroy()
    end)
end
end -- fin de la fonction Notify

local function openSearch()
    searchOpen = true

    Main.Search.BackgroundTransparency = 1
    Main.Search.Shadow.ImageTransparency = 1
    Main.Search.Input.TextTransparency = 1
    Main.Search.Search.ImageTransparency = 1
    Main.Search.UIStroke.Transparency = 1
    Main.Search.Size = UDim2.new(1, 0, 0, 80)
    Main.Search.Position = UDim2.new(0.5, 0, 0, 70)

    Main.Search.Input.Interactable = true

    Main.Search.Visible = true

    for _, tabbtn in ipairs(TabList:GetChildren()) do
        if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
            tabbtn.Interact.Visible = false
            TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
            TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
            TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
            TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
        end
    end

    Main.Search.Input:CaptureFocus()
    TweenService:Create(Main.Search.Shadow, TweenInfo.new(0.05, Enum.EasingStyle.Quint), {ImageTransparency = 0.95}):Play()
    TweenService:Create(Main.Search, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5, 0, 0, 57), BackgroundTransparency = 0.9}):Play()
    TweenService:Create(Main.Search.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.8}):Play()
    TweenService:Create(Main.Search.Input, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
end
