-- LuaLibrary Module - Universal Drag (PC & Mobile), PascalCase, Dark/Transparent Theme, STABLE
-- EXECUTE BUTTON REMOVED for a cleaner interface.

local Library = {}

-- Secure service references with error handling
local function GetService(ServiceName)
    local Success, Result = pcall(function()
        return game:GetService(ServiceName)
    end)
    return Success and Result or error("Failed to get service: " .. ServiceName)
end

local Players = GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = GetService("TweenService")
local UserInputService = GetService("UserInputService")

-- Configuration and Theme
local Config = {
    Name = "LuaLibrary",
    Theme = {
        Background = Color3.fromRGB(30, 30, 30), 
        Accent = Color3.fromRGB(0, 0, 0),
        Frame = Color3.fromRGB(30, 30, 30),
        Text = Color3.fromRGB(255, 255, 255),
        Transparency = 0.650, -- Controls transparency for buttons, tabs, etc.
        CornerRadius = 5,
        WindowSize = UDim2.new(0, 333, 0, 189),
        TitleHeight = 35,
        ElementHeight = 27,
        Padding = 8,
        TabWidth = 100,
    }
}

-- Library State
local State = {
    ScreenGui = nil,
    MainFrame = nil,
    TabFrame = nil,     
    PageContainer = nil,
    Pages = {},         
    CurrentTabButton = nil,
    RequiredGroupId = nil,
    GroupChecked = false,
    IsInGroup = false,
}

----------------------------------------------------------------------
-- SECURE UTILITY FUNCTIONS
----------------------------------------------------------------------

local function CreateInstance(ClassName, Properties)
    local Success, Instance_ = pcall(function()
        local Obj = Instance.new(ClassName)
        for Prop, Value in pairs(Properties) do
            local SetSuccess = pcall(function()
                Obj[Prop] = Value
            end)
            if not SetSuccess then
                warn("Failed to set property " .. tostring(Prop) .. " on " .. ClassName)
            end
        end
        return Obj
    end)
    
    if not Success then
        error("Failed to create instance: " .. ClassName)
        return nil
    end
    
    -- Apply general transparency safely
    if Instance_ and Instance_:IsA("GuiObject") and not Properties.BackgroundTransparency then
        pcall(function()
            Instance_.BackgroundTransparency = Config.Theme.Transparency -- Applies 0.650
        end)
    end
    
    return Instance_
end

local function ApplyCorner(Instance_, Radius)
    return CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, Radius or Config.Theme.CornerRadius),
        Parent = Instance_,
    })
end

-- Universal Drag Support (PC & Mobile) - Obfuscation Safe
local function SetupDragging(DragInstance, MainInstance)
    local Dragging = false
    local DragStart = nil
    local FrameStart = nil
    
    local function IsDragInput(Input)
        return Input.UserInputType == Enum.UserInputType.MouseButton1 
            or Input.UserInputType == Enum.UserInputType.Touch
    end

    local function SafeTween(Position)
        pcall(function()
            TweenService:Create(MainInstance, TweenInfo.new(0.1), {Position = Position}):Play()
        end)
    end

    pcall(function()
        DragInstance.InputBegan:Connect(function(Input)
            if IsDragInput(Input) then
                Dragging = true
                DragStart = Input.Position
                FrameStart = MainInstance.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(Input)
            if Dragging and IsDragInput(Input) then
                local Delta = Input.Position - DragStart
                local NewPos = UDim2.new(
                    FrameStart.X.Scale, FrameStart.X.Offset + Delta.X,
                    FrameStart.Y.Scale, FrameStart.Y.Offset + Delta.Y
                )
                SafeTween(NewPos)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(Input)
            if IsDragInput(Input) and Dragging then
                Dragging = false
            end
        end)
    end)
end

-- Group Verification System
local function CheckGroupMembership(GroupId)
    local inGroup = false
    pcall(function()
        if LocalPlayer then
            inGroup = LocalPlayer:IsInGroup(GroupId)
        end
    end)
    return inGroup
end

local function CreateGroupJoinGUI(GroupId)
    if State.MainFrame then
        State.MainFrame:Destroy()
        State.MainFrame = nil
    end
    
    -- Create new interface for group join
    local PlayerGui
    pcall(function()
        PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    end)
    
    if not PlayerGui then return end
    
    local LibraryGui = CreateInstance("ScreenGui", {
        Name = "GroupJoinInterface",
        Parent = PlayerGui,
        DisplayOrder = 100,
    })
    
    local MainFrame = CreateInstance("Frame", {
        Name = "Main",
        Parent = LibraryGui,
        BackgroundColor3 = Config.Theme.Background,
        Size = UDim2.new(0, 300, 0, 200),
        Position = UDim2.new(0.5, -150, 0.5, -100),
        BorderSizePixel = 0,
    })
    ApplyCorner(MainFrame)
    State.MainFrame = MainFrame

    -- Title Bar
    local TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Parent = MainFrame,
        BackgroundColor3 = Config.Theme.Accent,
        BackgroundTransparency = 0.3,
        Size = UDim2.new(1, 0, 0, Config.Theme.TitleHeight),
        BorderSizePixel = 0,
    })
    
    CreateInstance("TextLabel", {
        Parent = TitleBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "Group",
        TextColor3 = Config.Theme.Text,
        Font = Enum.Font.SourceSansBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    SetupDragging(TitleBar, MainFrame)

    -- Tab Container
    local TabFrame = CreateInstance("Frame", {
        Name = "TabFrame",
        Parent = MainFrame,
        BackgroundColor3 = Config.Theme.Frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, Config.Theme.TabWidth, 1, -Config.Theme.TitleHeight),
        Position = UDim2.new(0, 0, 0, Config.Theme.TitleHeight),
        BorderSizePixel = 0,
    })
    
    -- Page Container
    local PageContainer = CreateInstance("Frame", {
        Name = "PageContainer",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -Config.Theme.TabWidth, 1, -Config.Theme.TitleHeight),
        Position = UDim2.new(0, Config.Theme.TabWidth, 0, Config.Theme.TitleHeight),
        BorderSizePixel = 0,
    })
    
    -- Create Join Tab
    local JoinTabButton = CreateInstance("TextButton", {
        Name = "JoinTab",
        Parent = TabFrame,
        BackgroundColor3 = Config.Theme.Frame,
        Size = UDim2.new(1, 0, 0, Config.Theme.ElementHeight),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Join",
        TextColor3 = Config.Theme.Text,
        Font = Enum.Font.SourceSansBold,
        TextSize = 15,
        BorderSizePixel = 0,
    })
    
    -- Create Join Page
    local JoinPage = CreateInstance("ScrollingFrame", {
        Name = "JoinPage",
        Parent = PageContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Active = true,
        Visible = true,
        ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200),
        ScrollBarThickness = 6,
    })
    
    local YOffset = Config.Theme.Padding
    
    local function AddButton(Text, Callback, HeightMultiplier)
        local ElementFrame = CreateInstance("Frame", {
            Name = "ElementFrame",
            Parent = JoinPage,
            BackgroundColor3 = Config.Theme.Frame,
            Size = UDim2.new(1, -2 * Config.Theme.Padding, 0, Config.Theme.ElementHeight * (HeightMultiplier or 1)),
            Position = UDim2.new(0, Config.Theme.Padding, 0, YOffset),
            BorderSizePixel = 0,
        })
        ApplyCorner(ElementFrame)
        
        local Button = CreateInstance("TextButton", {
            Name = "Button",
            Parent = ElementFrame,
            BackgroundColor3 = Config.Theme.Frame,
            Size = UDim2.new(1, 0, 1, 0),
            Text = Text,
            Font = Enum.Font.SourceSans,
            TextSize = 14,
            TextColor3 = Config.Theme.Text,
        })
        
        if Callback then
            pcall(function()
                Button.MouseButton1Click:Connect(function()
                    pcall(Callback)
                end)
            end)
        end
        
        YOffset = YOffset + Config.Theme.ElementHeight * (HeightMultiplier or 1) + Config.Theme.Padding
        JoinPage.CanvasSize = UDim2.new(0, 0, 0, YOffset + Config.Theme.Padding)
        
        return Button
    end
    
AddButton("Copy Group Link", function()
    local groupLink = "https://www.roblox.com/groups/" .. tostring(GroupId)
    if setclipboard then
        setclipboard(groupLink)
    elseif writeclipboard then
        writeclipboard(groupLink)
    end
end)

return LibraryGui
end
----------------------------------------------------------------------
-- CORE WINDOW & TAB MANAGEMENT
----------------------------------------------------------------------

function Library.SetGroup(GroupId)
    State.RequiredGroupId = GroupId
    State.GroupChecked = false
    State.IsInGroup = false
    return Library
end

function Library.Create(Title)
    if State.MainFrame then return Library end 
    
    -- Check group membership if required
    if State.RequiredGroupId and not State.GroupChecked then
        State.IsInGroup = CheckGroupMembership(State.RequiredGroupId)
        State.GroupChecked = true
    end
    
    -- If group is required and user is not in group, show group join GUI
    if State.RequiredGroupId and not State.IsInGroup then
        CreateGroupJoinGUI(State.RequiredGroupId)
        return Library
    end
    
    -- Normal library creation for users in group
    local PlayerGui
    pcall(function()
        PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    end)
    
    if not PlayerGui then
        warn("Failed to access PlayerGui")
        return Library
    end
    
    -- 1. ScreenGui
    local LibraryGui = CreateInstance("ScreenGui", {
        Name = Config.Name,
        Parent = PlayerGui,
        DisplayOrder = 100,
    })
    State.ScreenGui = LibraryGui

    -- 2. Main Frame (Window)
    local MainFrame = CreateInstance("Frame", {
        Name = "Main",
        Parent = LibraryGui,
        BackgroundColor3 = Config.Theme.Background,
        Size = Config.Theme.WindowSize,
        Position = UDim2.new(0.5, -Config.Theme.WindowSize.X.Offset / 2, 0.5, -Config.Theme.WindowSize.Y.Offset / 2),
        BorderSizePixel = 0,
    })
    ApplyCorner(MainFrame)
    State.MainFrame = MainFrame

    -- 3. Title Bar (Now acts as the full dragger)
    local TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Parent = MainFrame,
        BackgroundColor3 = Config.Theme.Accent,
        BackgroundTransparency = 0.3, -- Transparency of the drag bar (Player Utilities Part) is KEPT at 0.3
        Size = UDim2.new(1, 0, 0, Config.Theme.TitleHeight),
        BorderSizePixel = 0,
    })
    
    -- Title Label (takes 100% width)
    CreateInstance("TextLabel", {
        Parent = TitleBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = Title or Config.Name,
        TextColor3 = Config.Theme.Text,
        Font = Enum.Font.SourceSansBold,
        TextSize = 28,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.new(0, 0, 0, 0),
    })

    SetupDragging(TitleBar, MainFrame)

    -- 4. Tab Container (Left side)
    State.TabFrame = CreateInstance("Frame", {
        Name = "TabFrame",
        Parent = MainFrame,
        BackgroundColor3 = Config.Theme.Frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, Config.Theme.TabWidth, 1, -Config.Theme.TitleHeight),
        Position = UDim2.new(0, 0, 0, Config.Theme.TitleHeight),
        BorderSizePixel = 0,
    })
    
    -- 5. Page Container (Right side)
    State.PageContainer = CreateInstance("Frame", {
        Name = "PageContainer",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -Config.Theme.TabWidth, 1, -Config.Theme.TitleHeight),
        Position = UDim2.new(0, Config.Theme.TabWidth, 0, Config.Theme.TitleHeight),
        BorderSizePixel = 0,
    })
    
    return Library
end

function Library.SwitchPage(PageName, Button)
    pcall(function()
        for Name, PageObj in pairs(State.Pages) do
            if PageObj and PageObj.Page then
                PageObj.Page.Visible = (Name == PageName)
            end
        end
        
        if State.CurrentTabButton then
            State.CurrentTabButton.BackgroundTransparency = Config.Theme.Transparency + 0.1 -- Uses 0.650 + 0.1
        end
        if Button then
            Button.BackgroundTransparency = Config.Theme.Transparency -- Uses 0.650
            State.CurrentTabButton = Button
        end
    end)
end

----------------------------------------------------------------------
-- PAGE OBJECT (Element Stacker)
----------------------------------------------------------------------

local PageModule = {}

function PageModule.New(PageName)
    local Self = setmetatable({
        Name = PageName,
        YOffset = Config.Theme.Padding,
        Elements = {}, 
    }, {__index = PageModule})
    
    Self.Page = CreateInstance("ScrollingFrame", {
        Name = PageName .. "Page",
        Parent = State.PageContainer,
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Active = true,
        Visible = false,
        ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200),
        ScrollBarThickness = 6,
    })
    
    function Self:GetNextPosition(HeightMultiplier)
        local TotalHeight = Config.Theme.ElementHeight * (HeightMultiplier or 1) + Config.Theme.Padding
        local Pos = UDim2.new(0, Config.Theme.Padding, 0, Self.YOffset)
        
        Self.YOffset = Self.YOffset + TotalHeight
        Self.Page.CanvasSize = UDim2.new(0, 0, 0, Self.YOffset + Config.Theme.Padding)
        
        return Pos
    end
    
    State.Pages[PageName] = Self
    
    return Self
end

function Library.NewTab(PageName)
    -- If group is required and user is not in group, don't create tabs for main GUI
    if State.RequiredGroupId and not State.IsInGroup then
        return { AddButton = function() return end, AddToggle = function() return end, AddSlider = function() return end, AddTextbox = function() return end, AddDropdown = function() return end, AddGroupVerification = function() return end }
    end
    
    local PageCount = 0
    pcall(function()
        PageCount = #State.TabFrame:GetChildren()
    end)
    
    local TabButton = CreateInstance("TextButton", {
        Name = PageName .. "Tab",
        Parent = State.TabFrame,
        BackgroundColor3 = Config.Theme.Frame,
        Size = UDim2.new(1, 0, 0, Config.Theme.ElementHeight),
        Position = UDim2.new(0, 0, 0, PageCount * Config.Theme.ElementHeight),
        Text = PageName,
        TextColor3 = Config.Theme.Text,
        Font = Enum.Font.SourceSansBold,
        TextSize = 15,
        BorderSizePixel = 0,
    })
    
    local Page = PageModule.New(PageName)
    
    pcall(function()
        TabButton.MouseButton1Click:Connect(function()
            Library.SwitchPage(PageName, TabButton)
        end)
    end)
    
    if PageCount == 0 then
        Library.SwitchPage(PageName, TabButton)
    else
        TabButton.BackgroundTransparency = Config.Theme.Transparency + 0.1 -- Uses 0.650 + 0.1
    end
    
    return Page 
end

----------------------------------------------------------------------
-- ELEMENT BUILDERS
----------------------------------------------------------------------

local function CreateElementFrame(Page, HeightMultiplier)
    local Frame_ = CreateInstance("Frame", {
        Name = "ElementFrame",
        Parent = Page.Page,
        BackgroundColor3 = Config.Theme.Frame,
        Size = UDim2.new(1, -2 * Config.Theme.Padding, 0, Config.Theme.ElementHeight * (HeightMultiplier or 1)),
        Position = Page:GetNextPosition(HeightMultiplier),
        BorderSizePixel = 0,
    })
    ApplyCorner(Frame_)
    return Frame_
end

-- 1. Button
function PageModule:AddButton(Text, Callback)
    local ElementFrame = CreateElementFrame(self)
    
    local Button = CreateInstance("TextButton", {
        Name = "Button",
        Parent = ElementFrame,
        BackgroundColor3 = Config.Theme.Frame,
        Size = UDim2.new(1, 0, 1, 0),
        Text = Text,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        TextColor3 = Config.Theme.Text,
    })
    
    -- Safe callback execution
    if Callback then
        pcall(function()
            Button.MouseButton1Click:Connect(function()
                pcall(Callback)
            end)
        end)
    end
    
    return self
end

-- 2. Toggle
function PageModule:AddToggle(Text, InitialState, Callback)
    local State_ = InitialState or false
    local ElementFrame = CreateElementFrame(self)
    
    CreateInstance("TextLabel", {
        Name = "Label",
        Parent = ElementFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.8, 0, 1, 0),
        Text = Text,
        TextColor3 = Config.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, Config.Theme.Padding, 0, 0),
    })

    local ToggleButton = CreateInstance("TextButton", {
        Name = "Toggle",
        Parent = ElementFrame,
        BackgroundColor3 = Config.Theme.Frame,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20 - Config.Theme.Padding, 0.5, -10),
        Text = State_ and "✔" or "",
        TextColor3 = Color3.fromRGB(0, 255, 0),
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
    })
    ApplyCorner(ToggleButton)

    local function UpdateState(NewState)
        State_ = NewState
        ToggleButton.Text = State_ and "✔" or ""
        
        -- Safe callback execution
        if Callback then
            pcall(function()
                Callback(State_)
            end)
        end
    end

    pcall(function()
        ToggleButton.MouseButton1Click:Connect(function()
            UpdateState(not State_)
        end)
    end)
    
    return self
end
