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
    IsMinimized = false,
    MinimizeButton = nil,
    SearchEnabled = false,
    SearchFrame = nil,
    SearchTextBox = nil,
    SearchButton = nil,
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

local function ApplyStroke(Instance_)
    return CreateInstance("UIStroke", {
        Parent = Instance_,
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
        Transparency = 0.25,
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

-- Minimize/Maximize Function
local function ToggleMinimize()
    if not State.MainFrame or not State.MinimizeButton then return end
    
    State.IsMinimized = not State.IsMinimized
    
    if State.IsMinimized then
        -- Minimize: Hide content, show only title bar
        State.MinimizeButton.Text = "+"
        TweenService:Create(State.MainFrame, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 200, 0, Config.Theme.TitleHeight)
        }):Play()
        
        -- Hide content
        State.TabFrame.Visible = false
        State.PageContainer.Visible = false
        if State.SearchFrame then
            State.SearchFrame.Visible = false
            State.SearchEnabled = false
        end
    else
        -- Maximize: Show full content
        State.MinimizeButton.Text = "-"
        TweenService:Create(State.MainFrame, TweenInfo.new(0.3), {
            Size = Config.Theme.WindowSize
        }):Play()
        
        -- Show content
        State.TabFrame.Visible = true
        State.PageContainer.Visible = true
    end
end

-- Search Function
local function ToggleSearch()
    if not State.MainFrame then return end
    
    State.SearchEnabled = not State.SearchEnabled
    
    if State.SearchEnabled then
        -- Create search frame if it doesn't exist
        if not State.SearchFrame then
            State.SearchFrame = CreateInstance("Frame", {
                Name = "SearchFrame",
                Parent = State.MainFrame,
                BackgroundColor3 = Config.Theme.Frame,
                Size = UDim2.new(0, 150, 0, 25),
                Position = UDim2.new(1, -45, 0, 5), -- Start hidden behind search button
                BorderSizePixel = 0,
                Visible = false,
            })
            ApplyCorner(State.SearchFrame)
            
            State.SearchTextBox = CreateInstance("TextBox", {
                Name = "SearchTextBox",
                Parent = State.SearchFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -25, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                Text = "",
                PlaceholderText = "Search...",
                TextColor3 = Config.Theme.Text,
                Font = Enum.Font.SourceSans,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
            })
            ApplyStroke(State.SearchTextBox)
            
            local SearchIcon = CreateInstance("ImageLabel", {
                Name = "SearchIcon",
                Parent = State.SearchFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(1, -18, 0.5, -8),
                Image = "http://www.roblox.com/asset/?id=91605987285644",
                ScaleType = Enum.ScaleType.Fit,
            })
            
            -- Connect focus lost event to close search
            pcall(function()
                State.SearchTextBox.FocusLost:Connect(function()
                    wait(0.1) -- Small delay to prevent immediate closing
                    if State.SearchEnabled then
                        ToggleSearch()
                    end
                end)
            end)
            
            -- Connect text changed to perform search
            pcall(function()
                State.SearchTextBox:GetPropertyChangedSignal("Text"):Connect(function()
                    PerformSearch(State.SearchTextBox.Text)
                end)
            end)
        end
        
        -- Show search frame with tween (slide out from behind search button)
        State.SearchFrame.Visible = true
        State.SearchFrame.Position = UDim2.new(1, -45, 0, 5) -- Start behind search button
        
        TweenService:Create(State.SearchFrame, TweenInfo.new(0.3), {
            Position = UDim2.new(1, -150, 0, 5) -- Slide out to the left
        }):Play()
        
        -- Focus on textbox after tween
        delay(0.3, function()
            if State.SearchTextBox then
                State.SearchTextBox:CaptureFocus()
            end
        end)
    else
        -- Hide search frame with tween (slide back behind search button)
        if State.SearchFrame then
            TweenService:Create(State.SearchFrame, TweenInfo.new(0.3), {
                Position = UDim2.new(1, -45, 0, 5) -- Tween back to hide behind search button
            }):Play()
            
            -- Hide after tween and clear text
            delay(0.3, function()
                if State.SearchFrame then
                    State.SearchFrame.Visible = false
                    State.SearchTextBox.Text = ""
                end
            end)
        end
    end
end

-- Search functionality
local function PerformSearch(searchText)
    if not searchText or string.len(searchText) == 0 then
        print("Search cleared")
        return
    end
    
    searchText = string.lower(searchText)
    print("Searching for: " .. searchText)
    
    -- Search through all pages and elements
    for pageName, pageObj in pairs(State.Pages) do
        if pageObj and pageObj.Page then
            for elementName, elementData in pairs(pageObj.Elements) do
                -- Search in element text
                if elementData.Text and string.find(string.lower(elementData.Text), searchText) then
                    print("Found: " .. elementData.Text .. " in page: " .. pageName)
                end
            end
        end
    end
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
    
    -- Add group join buttons to Join tab
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
    
    -- Title Label (takes 100% width - CENTERED)
    CreateInstance("TextLabel", {
        Parent = TitleBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = Title or Config.Name,
        TextColor3 = Config.Theme.Text,
        Font = Enum.Font.SourceSansBold,
        TextSize = 20, -- Smaller font size
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.new(0, 0, 0, 0),
    })

    -- Search Button (positioned in top right next to minimize) - smaller size
    State.SearchButton = CreateInstance("ImageButton", {
        Name = "SearchButton",
        Parent = TitleBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -45, 0.5, -10),
        Image = "http://www.roblox.com/asset/?id=91605987285644",
        ScaleType = Enum.ScaleType.Fit,
    })

    -- Minimize Button (positioned in top right) - smaller size
    State.MinimizeButton = CreateInstance("TextButton", {
        Name = "MinimizeButton",
        Parent = TitleBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20, 0.5, -10),
        Text = "-",
        TextColor3 = Config.Theme.Text,
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
    })

    pcall(function()
        State.SearchButton.MouseButton1Click:Connect(function()
            ToggleSearch()
        end)
        
        State.MinimizeButton.MouseButton1Click:Connect(function()
            ToggleMinimize()
        end)
    end)

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
        return { 
            AddButton = function() return end, 
            AddToggle = function() return end, 
            AddSlider = function() return end, 
            AddTextbox = function() return end, 
            AddDropdown = function() return end, 
            AddGroupVerification = function() return end 
        }
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
    
    self.Elements[Text] = { Type = "Button", Text = Text }
    
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
    
    self.Elements[Text] = { Type = "Toggle", Text = Text, State = State_ }
    
    return self
end

-- 3. Slider
function PageModule:AddSlider(Text, Min, Max, InitialValue, Callback)
    local ElementFrame = CreateElementFrame(self, 1.5)
    
    local Value = InitialValue or Min
    local Range = Max - Min
    local SliderActive = false
    local Scale = (Value - Min) / Range

    self.Elements[Text] = { Type = "Slider", Text = Text, CurrentValue = Value }
    
    CreateInstance("TextLabel", {
        Name = "Label",
        Parent = ElementFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, 0, 0, Config.Theme.ElementHeight * 0.5),
        Text = Text,
        TextColor3 = Config.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, Config.Theme.Padding, 0, 0),
    })
    
    local ValueLabel = CreateInstance("TextLabel", {
        Name = "ValueLabel",
        Parent = ElementFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.4, 0, 0, Config.Theme.ElementHeight * 0.5),
        Text = string.format("%.1f", Value),
        TextColor3 = Config.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(0.5, -Config.Theme.Padding, 0, 0),
    })
    
    local SliderBackground = CreateInstance("Frame", {
        Name = "SliderBackground",
        Parent = ElementFrame,
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        Size = UDim2.new(1, -2 * Config.Theme.Padding, 0, 8),
        Position = UDim2.new(0, Config.Theme.Padding, 0, Config.Theme.ElementHeight * 0.8),
        BorderSizePixel = 0,
    })
    ApplyCorner(SliderBackground, 4)
    SliderBackground.BackgroundTransparency = Config.Theme.Transparency + 0.1 -- Uses 0.650 + 0.1
    
    local SliderBar = CreateInstance("Frame", {
        Name = "SliderBar",
        Parent = SliderBackground,
        BackgroundColor3 = Color3.fromRGB(0, 255, 0),
        Size = UDim2.new(Scale, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
    })
    ApplyCorner(SliderBar, 4)
    SliderBar.BackgroundTransparency = Config.Theme.Transparency -- Uses 0.650

    local Handle = CreateInstance("Frame", {
        Name = "Handle",
        Parent = SliderBackground,
        BackgroundColor3 = Config.Theme.Text,
        Size = UDim2.new(0, 15, 0, 15),
        Position = UDim2.new(Scale, -7.5, 0.5, -7.5),
        BorderSizePixel = 0,
    })
    ApplyCorner(Handle, 7)
    
    local Dragging = false

    local function UpdateSlider(XPos)
        local SliderWidth = SliderBackground.AbsoluteSize.X
        local RelativeX = math.max(0, math.min(SliderWidth, XPos - SliderBackground.AbsolutePosition.X))
        local Progress = RelativeX / SliderWidth
        
        local NewValue = Min + (Range * Progress)
        Value = math.floor(NewValue * 10) / 10

        Scale = (Value - Min) / Range
        
        SliderBar.Size = UDim2.new(Scale, 0, 1, 0)
        Handle.Position = UDim2.new(Scale, -7.5, 0.5, -7.5)
        ValueLabel.Text = string.format("%.1f", Value)
        
        self.Elements[Text].CurrentValue = Value

        -- Safe callback execution
        if Callback then
            pcall(function()
                Callback(Value)
            end)
        end
    end

    local function OnInputChanged(Input)
        if (Dragging or SliderActive) and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(Input.Position.X)
        end
    end

    local function OnInputEnded(Input)
        if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
            Dragging = false
            SliderActive = false
        end
    end

    pcall(function()
        Handle.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
            end
        end)
        
        SliderBackground.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                SliderActive = true
                UpdateSlider(Input.Position.X)
            end
        end)
        
        UserInputService.InputChanged:Connect(OnInputChanged)
        UserInputService.InputEnded:Connect(OnInputEnded)
    end)

    return self
end

-- 4. Textbox
function PageModule:AddTextbox(Text, Placeholder, Callback)
    local ElementFrame = CreateElementFrame(self)
    
    CreateInstance("TextLabel", {
        Name = "Label",
        Parent = ElementFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.4, 0, 1, 0),
        Text = Text,
        TextColor3 = Config.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, Config.Theme.Padding, 0, 0),
    })

    local TextBox = CreateInstance("TextBox", {
        Name = "TextBox",
        Parent = ElementFrame,
        BackgroundColor3 = Config.Theme.Frame,
        BackgroundTransparency = 0.3, -- Slightly more transparent for input field
        Size = UDim2.new(0.55, 0, 0.7, 0),
        Position = UDim2.new(0.4, Config.Theme.Padding, 0.15, 0),
        Text = "",
        PlaceholderText = Placeholder or "Enter text...",
        TextColor3 = Config.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        ClearTextOnFocus = false,
    })
    ApplyCorner(TextBox)
    ApplyStroke(TextBox)

    self.Elements[Text] = { Type = "Textbox", Text = Text, Placeholder = Placeholder }

    -- Safe callback execution on focus lost (Enter key or click away)
    if Callback then
        pcall(function()
            TextBox.FocusLost:Connect(function(enterPressed)
                pcall(function()
                    Callback(TextBox.Text, enterPressed)
                end)
            end)
        end)
    end
    
    return self
end

-- 5. Dropdown
function PageModule:AddDropdown(Text, Options, Default, Callback)
    local ElementFrame = CreateElementFrame(self)
    local IsOpen = false
    local Selected = Default or Options[1] or "Select..."
    
    CreateInstance("TextLabel", {
        Name = "Label",
        Parent = ElementFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.4, 0, 1, 0),
        Text = Text,
        TextColor3 = Config.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, Config.Theme.Padding, 0, 0),
    })

    local DropdownButton = CreateInstance("TextButton", {
        Name = "DropdownButton",
        Parent = ElementFrame,
        BackgroundColor3 = Config.Theme.Frame,
        Size = UDim2.new(0.55, 0, 0.7, 0),
        Position = UDim2.new(0.4, Config.Theme.Padding, 0.15, 0),
        Text = Selected,
        TextColor3 = Config.Theme.Text,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
    })
    ApplyCorner(DropdownButton)

    local DropdownFrame = CreateInstance("Frame", {
        Name = "DropdownFrame",
        Parent = ElementFrame,
        BackgroundColor3 = Config.Theme.Frame,
        Size = UDim2.new(0.55, 0, 0, #Options * Config.Theme.ElementHeight),
        Position = UDim2.new(0.4, Config.Theme.Padding, 0.85, 0),
        Visible = false,
        BorderSizePixel = 0,
    })
    ApplyCorner(DropdownFrame)
    
    local function ToggleDropdown()
        IsOpen = not IsOpen
        DropdownFrame.Visible = IsOpen
        
        if IsOpen then
            -- Clear previous options
            for _, child in pairs(DropdownFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            -- Create new options
            for i, option in ipairs(Options) do
                local OptionButton = CreateInstance("TextButton", {
                    Name = "Option_" .. option,
                    Parent = DropdownFrame,
                    BackgroundColor3 = Config.Theme.Frame,
                    Size = UDim2.new(1, 0, 0, Config.Theme.ElementHeight),
                    Position = UDim2.new(0, 0, 0, (i-1) * Config.Theme.ElementHeight),
                    Text = option,
                    TextColor3 = Config.Theme.Text,
                    Font = Enum.Font.SourceSans,
                    TextSize = 12,
                })
                
                pcall(function()
                    OptionButton.MouseButton1Click:Connect(function()
                        Selected = option
                        DropdownButton.Text = Selected
                        IsOpen = false
                        DropdownFrame.Visible = false
                        
                        if Callback then
                            pcall(function()
                                Callback(Selected)
                            end)
                        end
                    end)
                end)
            end
        end
    end

    pcall(function()
        DropdownButton.MouseButton1Click:Connect(function()
            ToggleDropdown()
        end)
    end)
    
    self.Elements[Text] = { Type = "Dropdown", Text = Text, Options = Options, Selected = Selected }
    
    return self
end

return Library
