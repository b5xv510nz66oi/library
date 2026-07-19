--[[
    Thugsense UI Library (haze fork) — LINED variant 2
    Based on samet / Thugsense — gamesense chrome (not Thugsense boxes)

    Lined chrome (gamesense style):
    - Window: dark nested borders + 1px top accent hairline (not pink ring)
    - Top tabs: text + accent underline + separators
    - MultiSection: titled groupbox + internal text tabs with underline
    - Sections: thin 1px groupboxes, title on border
    - Controls: flat checkbox / thin slider / flat dropdown / flat buttons
    Upload as library_lined.lua and load when UI Style = Lined.

    Assign different flags to each element to prevent from configs overriding eachother
    Example script is at the bottom

    Fork notes (haze-1.4 + lined):
    - Dropdowns support MaxSize + native scroll (long lists)
    - Opening a dropdown closes other open dropdowns (Library:CloseDropdowns)
    - Toggle:Set(false) / config load fixed; Colorpicker table alpha fixed
    - SaveConfig path fixed; Init/LoadConfig hardened
    - Fade completion nil-safe (Library:AfterFade); close allowed while animating
    - Subtabs scoped per Page; lighter subtab fade
    - Built-in Themes presets + theme file profiles (Library:AddThemeUI)
    - Emblem system + ESP Preview (bundles/dances) moved in: Library:CreateEmblem /
      Library:CreateEspPreview / Library:AddEmblemUI / Library:AddEspPreviewUI
    - World Player ESP: Library:CreatePlayerEsp / Library:AddEspUI
    - Load via loadstring(HttpGet(...))() — keep returning Library at the end

    Documentation:
    function Library:Window(Data: table
        Name/name: string,
        GameName/gamename: string, -- right side of title bar
        Size/size: UDim2
    )
    Window:SetGameName(name)

    Themes:
    Library.Themes / Library:ApplyTheme(name) / Library:AddThemeUI(page, {Default=...})
    Library:CreateThemeFile / LoadThemeFile / SaveThemeFile / DeleteThemeFile / SetThemeAutoload
    Library:AddThemeHook(callback) — fires when theme colors change

    Emblem / ESP Preview:
    Library:CreateEmblem(Window, Options?) -> Emblem
        Options: Parent (CoreGui/gethui), IsUnloaded (function), Name (ScreenGui name)
    Library:CreateEspPreview(Window, Options?) -> EspPreview
        Options: Parent, IsUnloaded, Name, DanceProxyName
    Library:AddEmblemUI(Page, Emblem, { DanceTarget = EspPreview? })
    Library:AddEspPreviewUI(Page, EspPreview)
    Library:CreatePlayerEsp(Options?) -> PlayerEsp  -- real players (Drawing + Highlight)
    Library:AddEspUI(Page, { Preview = EspPreview, World = PlayerEsp })

    function Window:Page(Data: table
        Name/name: string,
        Columns/columns: number,
        SubTabs/subtabs: boolean
    )

    function Page:SubPage(Data: table
        Icon/icon: string,
        Columns/columns: number
    )

    function Page:Section(Data: table
        Name/name: string,
        Side/side: number,
    )

    function Page:MultiSection(Data: table
        Sections/sections: table,
        Side/side: number
    )

    function Page:ScrollableSection(Data: table
        Name/name: string,
        Side/side: number,
        Size/size: number
    )

    function Section:Divider()

    function Section:Label(Data: table
        Name/name: string,
        Alignment/alignment: string
    )

    function Section:Toggle(Data: table
        Name/name: string,
        Default/default: boolean,
        Flag/flag: string,
        Callback/callback: function
    )

    function Section:Button(Data: table
        Name/name: string,
        Callback/callback: function
    )

    function Section:Slider(Data: table
        Name/name: string,
        Min/min: number,
        Max/max: number,
        Decimals/decimals: number,
        Default/default: number,
        Suffix/suffix: string,
        Flag/flag: string,
        Callback/callback: function
    )

    function Section:Textbox(Data: table
        Name/name: string,
        Default/default: string,
        Placeholder/placeholder: string,
        Flag/flag: string,
        Callback/callback: function
    )

    function Section:Dropdown(Data: table
        Name/name: string,
        Items/items: table,
        Default/default: string,
        Flag/flag: string,
        Multi/multi: boolean,
        MaxSize/maxsize: number, -- max open list height (px), default 168; scrolls when longer
        Callback/callback: function
    )
    Dropdown:SetMaxSize(n)
    Library:CloseDropdowns(Except?)
    Library:AfterFade(tween, callback)

    function Section:Listbox(Data: table
        Size/size: number,
        Items/items: table,
        Default/default: string,
        Multi/multi: boolean,
        Flag/flag: string,
        Callback/callback: function
    )

    function Label:Keybind(Data: table
        Name/name: string,
        Mode/mode: string,
        Default/default: EnumItem,
        Flag/flag: string,
        Callback/callback: function
    )

    function Label:Colorpicker(Data: table
        Name/name: string,
        Default/default: Color3,
        Alpha/alpha: boolean,
        Flag/flag: string,
        Callback/callback: function
    )

    function Toggle:Colorpicker(Data: table
        Name/name: string,
        Default/default: Color3,
        Alpha/alpha: boolean,
        Flag/flag: string,
        Callback/callback: function
    )

    function Toggle:Keybind(Data: table
        Name/name: string,
        Mode/mode: string,
        Default/default: EnumItem,
        Flag/flag: string,
        Callback/callback: function
    )

    function Sections:Textbox(Data: table
        Name/name: string,
        Default/default: string,
        Placeholder/placeholder: string,
        Flag/flag: string,
        Callback/callback: function
    )

    function Library:Watermark(Name: string)
    function Library:Notification(Text: string, Duration: number, Color: Color3, Icon: table)
    function Library:KeybindList()
]]

local LoadingTick = os.clock()

if getgenv().Library then 
    getgenv().Library:Unload()
end

local Library do
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local HttpService = game:GetService("HttpService")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")

    gethui = gethui or function()
        return CoreGui
    end

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera
    local Mouse = LocalPlayer:GetMouse()

    local FromRGB = Color3.fromRGB
    local FromHSV = Color3.fromHSV
    local FromHex = Color3.fromHex

    local RGBSequence = ColorSequence.new
    local RGBSequenceKeypoint = ColorSequenceKeypoint.new

    local NumSequence = NumberSequence.new
    local NumSequenceKeypoint = NumberSequenceKeypoint.new

    local UDim2New = UDim2.new
    local UDim2FromOffset = UDim2.fromOffset
    local UDimNew = UDim.new
    local Vector2New = Vector2.new

    local InstanceNew = Instance.new

    local MathClamp = math.clamp
    local MathFloor = math.floor

    local TableInsert = table.insert
    local TableFind = table.find
    local TableRemove = table.remove
    local TableConcat = table.concat
    local TableUnpack = table.unpack

    local StringFormat = string.format
    local StringFind = string.find
    local StringGSub = string.gsub

    local IsMobile = UserInputService.TouchEnabled or false

    Library = {
        Flags = { },
        
        Theme = {
            ["Background"] = FromHex("#121212"),
            ["Inline"] = FromHex("#171717"),
            ["Page Background"] = FromHex("#222222"),
            ["Border"] = FromHex("#0a0a0a"),
            ["Outline"] = FromHex("#2a2a2a"),
            ["Accent"] = FromHex("#b3647a"),
            ["Element"] = FromHex("#1c1c1c"),
            ["Hovered Element"] = FromHex("#2a2a2a"),
            ["Text"] = FromHex("#d0d0d0"),
            ["Text Border"] = FromRGB(0, 0, 0)
        },

        MenuKeybind = Enum.KeyCode.Z, 

        Tween = {
            Time = 0.3,
            Style = Enum.EasingStyle.Exponential,
            Direction = Enum.EasingDirection.Out
        },

        Folders = {
            Directory = "scriptname",
            Configs = "scriptname/Configs",
            Assets = "scriptname/Assets",
            Themes = "scriptname/Themes",
        },

        ThemeKeys = {
            "Background",
            "Inline",
            "Page Background",
            "Border",
            "Outline",
            "Accent",
            "Element",
            "Hovered Element",
            "Text",
            "Text Border",
        },

        Themes = { },
        ThemeHooks = { },

        Images = { -- you're welcome to reupload the images and replace it with your own links
            ["Saturation"] = {"Saturation.png", "https://github.com/sametexe001/images/blob/main/saturation.png?raw=true" },
            ["Value"] = { "Value.png", "https://github.com/sametexe001/images/blob/main/value.png?raw=true" },
            ["Hue"] = { "Hue.png", "https://github.com/sametexe001/images/blob/main/hue.png?raw=true" },
            ["Scrollbar"] =  { "Scrollbar.png", "https://github.com/sametexe001/images/blob/main/scrollbar.png?raw=true" },
            ["Checkers"] = { "Checkers.png", "https://github.com/sametexe001/images/blob/main/checkers.png?raw=true" },
            ["Resize"] = { "Resize.png", "https://github.com/sametexe001/images/blob/main/resize.png?raw=true" },
        },

        -- Ignore below
        Version = "haze-1.5",
        Pages = { },
        Sections = { },
        Connections = { },
        Threads = { },
        ThemeMap = { },
        ThemeItems = { },
        Dropdowns = { },

        SetFlags = { },

        UnnamedConnections = 0,
        UnnamedFlags = 0,

        Holder = nil,
        NotifHolder = nil,
        Font = nil,
        KeyList = nil,

        CurrentColorpicker = nil
    }

    Library.__index = Library
    Library.Sections.__index = Library.Sections
    Library.Pages.__index = Library.Pages

    local Keys = {
        ["Unknown"]           = "Unknown",
        ["Backspace"]         = "Back",
        ["Tab"]               = "Tab",
        ["Clear"]             = "Clear",
        ["Return"]            = "Return",
        ["Pause"]             = "Pause",
        ["Escape"]            = "Escape",
        ["Space"]             = "Space",
        ["QuotedDouble"]      = '"',
        ["Hash"]              = "#",
        ["Dollar"]            = "$",
        ["Percent"]           = "%",
        ["Ampersand"]         = "&",
        ["Quote"]             = "'",
        ["LeftParenthesis"]   = "(",
        ["RightParenthesis"]  = " )",
        ["Asterisk"]          = "*",
        ["Plus"]              = "+",
        ["Comma"]             = ",",
        ["Minus"]             = "-",
        ["Period"]            = ".",
        ["Slash"]             = "`",
        ["Three"]             = "3",
        ["Seven"]             = "7",
        ["Eight"]             = "8",
        ["Colon"]             = ":",
        ["Semicolon"]         = ";",
        ["LessThan"]          = "<",
        ["GreaterThan"]       = ">",
        ["Question"]          = "?",
        ["Equals"]            = "=",
        ["At"]                = "@",
        ["LeftBracket"]       = "LeftBracket",
        ["RightBracket"]      = "RightBracked",
        ["BackSlash"]         = "BackSlash",
        ["Caret"]             = "^",
        ["Underscore"]        = "_",
        ["Backquote"]         = "`",
        ["LeftCurly"]         = "{",
        ["Pipe"]              = "|",
        ["RightCurly"]        = "}",
        ["Tilde"]             = "~",
        ["Delete"]            = "Delete",
        ["End"]               = "End",
        ["KeypadZero"]        = "Keypad0",
        ["KeypadOne"]         = "Keypad1",
        ["KeypadTwo"]         = "Keypad2",
        ["KeypadThree"]       = "Keypad3",
        ["KeypadFour"]        = "Keypad4",
        ["KeypadFive"]        = "Keypad5",
        ["KeypadSix"]         = "Keypad6",
        ["KeypadSeven"]       = "Keypad7",
        ["KeypadEight"]       = "Keypad8",
        ["KeypadNine"]        = "Keypad9",
        ["KeypadPeriod"]      = "KeypadP",
        ["KeypadDivide"]      = "KeypadD",
        ["KeypadMultiply"]    = "KeypadM",
        ["KeypadMinus"]       = "KeypadM",
        ["KeypadPlus"]        = "KeypadP",
        ["KeypadEnter"]       = "KeypadE",
        ["KeypadEquals"]      = "KeypadE",
        ["Insert"]            = "Insert",
        ["Home"]              = "Home",
        ["PageUp"]            = "PageUp",
        ["PageDown"]          = "PageDown",
        ["RightShift"]        = "RightShift",
        ["LeftShift"]         = "LeftShift",
        ["RightControl"]      = "RightControl",
        ["LeftControl"]       = "LeftControl",
        ["LeftAlt"]           = "LeftAlt",
        ["RightAlt"]          = "RightAlt"
    }

    -- Files 
    for _, FileName in Library.Folders do
        if not isfolder(FileName) then
            makefolder(FileName)
        end
    end

    if not isfile(Library.Folders.Directory .. "/autoload.json") then
        writefile(Library.Folders.Directory .. "/autoload.json", "")
    end

    for _, ImageData in Library.Images do
        local ImageName = ImageData[1]
        local ImageLink = ImageData[2]
        
        if not isfile(Library.Folders.Assets .. "/" .. ImageName) then
            writefile(Library.Folders.Assets .. "/" .. ImageName, game:HttpGet(ImageLink))
        end
    end

    local Tween = { } do
        Tween.__index = Tween

        Tween.Create = function(self, Item, Info, Goal, IsRawItem)
            Item = IsRawItem and Item or Item.Instance
            Info = Info or TweenInfo.new(Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction)

            local NewTween = {
                Tween = TweenService:Create(Item, Info, Goal),
                Info = Info,
                Goal = Goal,
                Item = Item
            }

            NewTween.Tween:Play()

            setmetatable(NewTween, Tween)

            return NewTween
        end

        Tween.Get = function(self)
            if not self.Tween then 
                return
            end

            return self.Tween, self.Info, self.Goal
        end

        Tween.Pause = function(self)
            if not self.Tween then 
                return
            end

            self.Tween:Pause()
        end

        Tween.Play = function(self)
            if not self.Tween then 
                return
            end

            self.Tween:Play()
        end

        Tween.Clean = function(self)
            if not self.Tween then 
                return
            end

            Tween:Pause()
            self = nil
        end
    end

    local Instances = { } do
        Instances.__index = Instances

        Instances.Create = function(self, Class, Properties)
            local NewItem = {
                Instance = InstanceNew(Class),
                Properties = Properties,
                Class = Class
            }

            setmetatable(NewItem, Instances)

            for Property, Value in NewItem.Properties do
                NewItem.Instance[Property] = Value
            end

            return NewItem
        end

        Instances.FadeItem = function(self, Visibility, Speed)
            local Item = self.Instance

            if Visibility == true then 
                Item.Visible = true
            end

            local Descendants = Item:GetDescendants()
            TableInsert(Descendants, Item)

            local NewTween

            for Index, Value in Descendants do 
                local TransparencyProperty = Tween:GetProperty(Value)

                if not TransparencyProperty then 
                    continue
                end

                if type(TransparencyProperty) == "table" then 
                    for _, Property in TransparencyProperty do 
                        NewTween = Tween:FadeItem(Value, Property, not Visibility, Speed)
                    end
                else
                    NewTween = Tween:FadeItem(Value, TransparencyProperty, not Visibility, Speed)
                end
            end
        end

        Instances.AddToTheme = function(self, Properties)
            if not self.Instance then 
                return
            end

            Library:AddToTheme(self, Properties)
        end

        Instances.ChangeItemTheme = function(self, Properties)
            if not self.Instance then 
                return
            end

            Library:ChangeItemTheme(self, Properties)
        end

        Instances.Connect = function(self, Event, Callback, Name)
            if not self.Instance then 
                return
            end

            if not self.Instance[Event] then 
                return
            end

            if IsMobile then 
                if Event == "MouseButton1Down" or Event == "MouseButton1Click" then
                    Event = "TouchTap"
                elseif Event == "MouseButton2Down" or Event == "MouseButton2Click" then
                    Event = "TouchLongPress"
                end
            end

            return Library:Connect(self.Instance[Event], Callback, Name)
        end

        Instances.Tween = function(self, Info, Goal)
            if not self.Instance then 
                return
            end

            return Tween:Create(self, Info, Goal)
        end

        Instances.Disconnect = function(self, Name)
            if not self.Instance then 
                return
            end

            return Library:Disconnect(Name)
        end

        Instances.Clean = function(self)
            if not self.Instance then 
                return
            end

            self.Instance:Destroy()
            self = nil
        end

        Instances.MakeDraggable = function(self)
            if not self.Instance then 
                return
            end
        
            local Gui = self.Instance
            local Dragging = false 
            local DragStart
            local StartPosition 
        
            local Set = function(Input)
                local DragDelta = Input.Position - DragStart
                local NewX = StartPosition.X.Offset + DragDelta.X
                local NewY = StartPosition.Y.Offset + DragDelta.Y

                local ScreenSize = Gui.Parent.AbsoluteSize
                local GuiSize = Gui.AbsoluteSize
        
                NewX = MathClamp(NewX, 0, ScreenSize.X - GuiSize.X)
                NewY = MathClamp(NewY, 0, ScreenSize.Y - GuiSize.Y)
        
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0, NewX, 0, NewY)})
            end
        
            local InputChanged
        
            self:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    DragStart = Input.Position
                    StartPosition = Gui.Position
        
                    if InputChanged then 
                        return
                    end
        
                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Dragging = false
                            InputChanged:Disconnect()
                            InputChanged = nil
                        end
                    end)
                end
            end)
        
            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dragging then
                        Set(Input)
                    end
                end
            end)
        
            return Dragging
        end

        Instances.MakeResizeable = function(self, Minimum, Maximum)
            if not self.Instance then 
                return
            end

            local Gui = self.Instance

            local Resizing = false 
            local CurrentSide = nil

            local StartMouse = nil 
            local StartPosition = nil 
            local StartSize = nil
            
            local EdgeThickness = 2

            local MakeEdge = function(Name, Position, Size)
                local Button = Instances:Create("TextButton", {
                    Name = "\0",
                    Size = Size,
                    Position = Position,
                    BackgroundColor3 = FromRGB(166, 147, 243),
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Parent = Gui,
                    ZIndex = 99999,
                })  Button:AddToTheme({BackgroundColor3 = "Accent"})

                return Button
            end

            local Edges = {
                {Button = MakeEdge(
                    "Left", 
                    UDim2New(0, 0, 0, 0), 
                    UDim2New(0, EdgeThickness, 1, 0)), 
                    Side = "L"
                },

                {Button = MakeEdge(
                    "Right", 
                    UDim2New(1, -EdgeThickness, 0, 0), 
                    UDim2New(0, EdgeThickness, 1, 0)), 
                    Side = "R"
                },

                {Button = MakeEdge(
                    "Top", UDim2New(0, 0, 0, 0), 
                    UDim2New(1, 0, 0, EdgeThickness)), 
                    Side = "T"
                },

                {Button = MakeEdge(
                    "Bottom", 
                    UDim2New(0, 0, 1, -EdgeThickness), 
                    UDim2New(1, 0, 0, EdgeThickness)), 
                    Side = "B"
                },
            }

            local BeginResizing = function(Side)
                Resizing = true 
                CurrentSide = Side 

                StartMouse = UserInputService:GetMouseLocation()

                -- store offsets, not absolute screen pos
                StartPosition = Vector2New(Gui.Position.X.Offset, Gui.Position.Y.Offset)
                StartSize = Vector2New(Gui.Size.X.Offset, Gui.Size.Y.Offset)
                
                for Index, Value in Edges do 
                    Value.Button.Instance.BackgroundTransparency = (Value.Side == Side) and 0 or 1
                end
            end

            local EndResizing = function()
                Resizing = false 
                CurrentSide = nil

                for Index, Value in Edges do 
                    Value.Button.Instance.BackgroundTransparency = 1
                end
            end

            for Index, Value in Edges do 
                Value.Button:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        BeginResizing(Value.Side)
                    end
                end)
            end

            Library:Connect(UserInputService.InputEnded, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    if Resizing then
                        EndResizing()
                    end
                end
            end)

            Library:Connect(RunService.RenderStepped, function()
                if not Resizing or not CurrentSide then 
                    return 
                end

                local MouseLocation = UserInputService:GetMouseLocation()
                local dx = MouseLocation.X - StartMouse.X
                local dy = MouseLocation.Y - StartMouse.Y
            
                local x, y = StartPosition.X, StartPosition.Y
                local w, h = StartSize.X, StartSize.Y

                if CurrentSide == "L" then
                    x = StartPosition.X + dx
                    w = StartSize.X - dx
                elseif CurrentSide == "R" then
                    w = StartSize.X + dx
                elseif CurrentSide == "T" then
                    y = StartPosition.Y + dy
                    h = StartSize.Y - dy
                elseif CurrentSide == "B" then
                    h = StartSize.Y + dy
                end
            
                if w < Minimum.X then
                    if CurrentSide == "L" then
                        x = x - (Minimum.X - w)
                    end
                    w = Minimum.X
                end
                if h < Minimum.Y then
                    if CurrentSide == "T" then
                        y = y - (Minimum.Y - h)
                    end
                    h = Minimum.Y
                end
            
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2FromOffset(x, y)})
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2FromOffset(w, h)})
            end)
        end

        Instances.OnHover = function(self, Function)
            if not self.Instance then 
                return
            end
            
            return Library:Connect(self.Instance.MouseEnter, Function)
        end

        Instances.OnHoverLeave = function(self, Function)
            if not self.Instance then 
                return
            end
            
            return Library:Connect(self.Instance.MouseLeave, Function)
        end
    end

    local CustomFont = { } do
        function CustomFont:New(Name, Weight, Style, Data)
            if isfile(Library.Folders.Assets .. "/" .. Name .. ".json") then
                return Font.new(getcustomasset(Library.Folders.Assets .. "/" .. Name .. ".json"))
            end

            if not isfile(Library.Folders.Assets .. "/" .. Name .. ".ttf") then 
                writefile(Library.Folders.Assets .. "/" .. Name .. ".ttf", game:HttpGet(Data.Url))
            end

            local FontData = {
                name = Name,
                faces = { {
                    name = "Regular",
                    weight = Weight,
                    style = Style,
                    assetId = getcustomasset(Library.Folders.Assets .. "/" .. Name .. ".ttf")
                } }
            }

            writefile(Library.Folders.Assets .. "/" .. Name .. ".json", HttpService:JSONEncode(FontData))
            return Font.new(getcustomasset(Library.Folders.Assets .. "/" .. Name .. ".json"))
        end

        function CustomFont:Get(Name)
            if isfile(Library.Folders.Assets .. "/" .. Name .. ".json") then
                return Font.new(getcustomasset(Library.Folders.Assets .. "/" .. Name .. ".json"))
            end
        end

        CustomFont:New("Windows-XP-Tahoma", 200, "Regular", {
            Url = "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/windows-xp-tahoma.ttf"
        })

        Library.Font = CustomFont:Get("Windows-XP-Tahoma")
    end

    Library.Holder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ResetOnSpawn = false
    })

    Library.NotifHolder = Instances:Create("Frame", {
        Parent = Library.Holder.Instance,
        BorderColor3 = FromRGB(0, 0, 0),
        AnchorPoint = Vector2New(0.5, 0),
        BackgroundTransparency = 1,
        Position = UDim2New(0.5, 0, 0, 0),
        Name = "\0",
        Size = UDim2New(0.34, 0, 1, -14),
        BorderSizePixel = 0,
        BackgroundColor3 = FromRGB(255, 255, 255)
    }) 
    
    Instances:Create("UIListLayout", {
        Parent = Library.NotifHolder.Instance,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDimNew(0, 10)
    }) 

    Library.GetImage = function(self, Image)
        local ImageData = self.Images[Image]

        if not ImageData then 
            return
        end

        return getcustomasset(self.Folders.Assets .. "/" .. ImageData[1])
    end

    Library.Round = function(self, Number, Float)
        local Multiplier = 1 / (Float or 1)
        return MathFloor(Number * Multiplier) / Multiplier
    end

    Library.GetTransparencyPropertyFromItem = function(self, Item)
        if Item:IsA("Frame") then
            return { "BackgroundTransparency" }
        elseif Item:IsA("TextLabel") or Item:IsA("TextButton") then
            return { "TextTransparency", "BackgroundTransparency" }
        elseif Item:IsA("ImageLabel") or Item:IsA("ImageButton") then
            return { "BackgroundTransparency", "ImageTransparency" }
        elseif Item:IsA("ScrollingFrame") then
            return { "BackgroundTransparency", "ScrollBarImageTransparency" }
        elseif Item:IsA("TextBox") then
            return { "TextTransparency", "BackgroundTransparency" }
        elseif Item:IsA("UIStroke") then 
            return { "Transparency" }
        end
    end

    local function HasNoFadeAncestor(Item)
        local Current = Item
        while Current do
            if Current:GetAttribute("haze_nofade") then
                return true
            end
            Current = Current.Parent
        end
        return false
    end

    Library.FadeItem = function(self, Item, Property, Visibility, Speed)
        if HasNoFadeAncestor(Item) then
            return nil
        end

        local OldTransparency = Item[Property]
        Item[Property] = Visibility and 1 or OldTransparency

        local NewTween = Tween:Create(Item, TweenInfo.new(Speed or Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction), {
            [Property] = Visibility and OldTransparency or 1
        }, true)

        local Connection
        Connection = NewTween.Tween.Completed:Connect(function()
            if Connection then
                Connection:Disconnect()
            end
            if not Visibility then 
                task.wait()
                Item[Property] = OldTransparency
            end
        end)

        return NewTween
    end

    Library.AfterFade = function(self, NewTween, Callback)
        if NewTween and NewTween.Tween then
            local Connection
            Connection = NewTween.Tween.Completed:Connect(function()
                if Connection then
                    Connection:Disconnect()
                end
                Callback()
            end)
        else
            Callback()
        end
    end

    Library.CloseDropdowns = function(self, Except)
        for _, Dropdown in self.Dropdowns do
            if Dropdown ~= Except and Dropdown.IsOpen then
                Dropdown:SetOpen(false)
            end
        end
    end

    Library.Unload = function(self)
        for Index, Value in self.Connections do 
            Value.Connection:Disconnect()
        end

        for Index, Value in self.Threads do 
            coroutine.close(Value)
        end

        if self.Holder then 
            self.Holder:Clean()
        end

        self.Dropdowns = { }

        Library = nil 
        getgenv().Library = nil
    end

    Library.Thread = function(self, Function)
        local NewThread = coroutine.create(Function)
        
        coroutine.wrap(function()
            coroutine.resume(NewThread)
        end)()

        TableInsert(self.Threads, NewThread)

        return NewThread
    end
    
    Library.SafeCall = function(self, Function, ...)
        local Arguements = { ... }
        local Success, Result = pcall(Function, TableUnpack(Arguements))

        if not Success then
            Library:Notification("Error caught in function, report this to the devs:\n"..Result, 5, FromRGB(255, 0, 0))
            warn(Result)
            return false
        end

        return Success
    end

    Library.Connect = function(self, Event, Callback, Name)
        Name = Name or StringFormat("Connection_%s_%s", self.UnnamedConnections + 1, HttpService:GenerateGUID(false))

        local NewConnection = {
            Event = Event,
            Callback = Callback,
            Name = Name,
            Connection = nil
        }

        Library:Thread(function()
            NewConnection.Connection = Event:Connect(Callback)
        end)

        TableInsert(self.Connections, NewConnection)
        return NewConnection
    end

    Library.Disconnect = function(self, Name)
        for _, Connection in self.Connections do 
            if Connection.Name == Name then
                Connection.Connection:Disconnect()
                break
            end
        end
    end

    Library.NextFlag = function(self)
        local FlagNumber = self.UnnamedFlags + 1
        return StringFormat("Flag Number %s %s", FlagNumber, HttpService:GenerateGUID(false))
    end

    Library.AddToTheme = function(self, Item, Properties)
        Item = Item.Instance or Item 

        local ThemeData = {
            Item = Item,
            Properties = Properties,
        }

        for Property, Value in ThemeData.Properties do
            if type(Value) == "string" then
                Item[Property] = self.Theme[Value]
            end
        end

        TableInsert(self.ThemeItems, ThemeData)
        self.ThemeMap[Item] = ThemeData
    end

    Library.GetConfig = function(self)
        local Config = { } 

        local Success, Result = Library:SafeCall(function()
            for Index, Value in Library.Flags do 
                if type(Value) == "table" and Value.Key then
                    Config[Index] = {Key = tostring(Value.Key), Mode = Value.Mode}
                elseif type(Value) == "table" and Value.Color then
                    Config[Index] = {Color = "#" .. Value.HexValue, Alpha = Value.Alpha}
                else
                    Config[Index] = Value
                end
            end
        end)

        return HttpService:JSONEncode(Config)
    end

    Library.LoadConfig = function(self, Config)
        local DecodeOk, Decoded = pcall(function()
            return HttpService:JSONDecode(Config)
        end)

        if not DecodeOk or type(Decoded) ~= "table" then
            Library:Notification("Failed to load config", 5, Color3.fromRGB(255, 0, 0))
            return false
        end

        local Success = Library:SafeCall(function()
            for Index, Value in Decoded do 
                local SetFunction = Library.SetFlags[Index]

                if not SetFunction then
                    continue
                end

                if type(Value) == "table" and Value.Key then 
                    SetFunction(Value)
                elseif type(Value) == "table" and Value.Color then
                    SetFunction(Value.Color, Value.Alpha)
                else
                    SetFunction(Value)
                end
            end
        end)

        if Success then 
            Library:Notification("Successfully loaded config", 5, Color3.fromRGB(0, 255, 0))
            return true
        end

        Library:Notification("Failed to apply config", 5, Color3.fromRGB(255, 0, 0))
        return false
    end

    Library.DeleteConfig = function(self, Config)
        if isfile(Library.Folders.Configs .. "/" .. Config) then 
            delfile(Library.Folders.Configs .. "/" .. Config)
            Library:Notification("Deleted config " .. Config .. ".json", 5, Color3.fromRGB(0, 255, 0))
        end
    end

    Library.SaveConfig = function(self, Config)
        local Path = Library.Folders.Configs .. "/" .. Config .. ".json"
        if isfile(Path) then
            writefile(Path, Library:GetConfig())
            Library:Notification("Saved config " .. Config .. ".json", 5, Color3.fromRGB(0, 255, 0))
        end
    end

    Library.RefreshConfigsList = function(self, Element)
        local List = { }

        local ConfigFolderName = StringGSub(Library.Folders.Configs, Library.Folders.Directory .. "/", "")

        for Index, Value in listfiles(Library.Folders.Configs) do
            local FileName = StringGSub(Value, Library.Folders.Directory .. "\\" .. ConfigFolderName .. "\\", "")
            FileName = StringGSub(FileName, Library.Folders.Directory .. "/" .. ConfigFolderName .. "/", "")
            List[Index] = FileName
        end

        Element:Refresh(List)
    end

    Library.ChangeItemTheme = function(self, Item, Properties)
        Item = Item.Instance or Item

        if not self.ThemeMap[Item] then 
            return
        end

        self.ThemeMap[Item].Properties = Properties
        self.ThemeMap[Item] = self.ThemeMap[Item]
    end

    Library.ChangeTheme = function(self, Theme, Color)
        self.Theme[Theme] = Color

        for _, Item in self.ThemeItems do
            for Property, Value in Item.Properties do
                if type(Value) == "string" and Value == Theme then
                    Item.Item[Property] = Color
                end
            end
        end
    end

    -- Theme presets + file profiles (used by AddThemeUI / ApplyTheme)
    do
        local function ThemeHex(Hex)
            return FromHex((tostring(Hex or "000000")):gsub("#", ""))
        end

        Library.Themes = {
            ["Lined"] = {
                ["Background"] = ThemeHex("#121212"),
                ["Inline"] = ThemeHex("#171717"),
                ["Page Background"] = ThemeHex("#222222"),
                ["Border"] = ThemeHex("#0a0a0a"),
                ["Outline"] = ThemeHex("#2a2a2a"),
                ["Accent"] = ThemeHex("#b3647a"),
                ["Element"] = ThemeHex("#1c1c1c"),
                ["Hovered Element"] = ThemeHex("#2a2a2a"),
                ["Text"] = ThemeHex("#d0d0d0"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Dark"] = {
                ["Background"] = ThemeHex("#0a0a0a"),
                ["Inline"] = ThemeHex("#111111"),
                ["Page Background"] = ThemeHex("#1a1a1a"),
                ["Border"] = ThemeHex("#050505"),
                ["Outline"] = ThemeHex("#1f1f1f"),
                ["Accent"] = ThemeHex("#ffffff"),
                ["Element"] = ThemeHex("#161616"),
                ["Hovered Element"] = ThemeHex("#222222"),
                ["Text"] = ThemeHex("#c8c8c8"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Blue"] = {
                ["Background"] = ThemeHex("#0d1117"),
                ["Inline"] = ThemeHex("#121820"),
                ["Page Background"] = ThemeHex("#1b2430"),
                ["Border"] = ThemeHex("#0a0e14"),
                ["Outline"] = ThemeHex("#1e2836"),
                ["Accent"] = ThemeHex("#58a6ff"),
                ["Element"] = ThemeHex("#161b22"),
                ["Hovered Element"] = ThemeHex("#21262d"),
                ["Text"] = ThemeHex("#a9b4c0"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Green"] = {
                ["Background"] = ThemeHex("#0c1210"),
                ["Inline"] = ThemeHex("#111816"),
                ["Page Background"] = ThemeHex("#1a2620"),
                ["Border"] = ThemeHex("#090e0c"),
                ["Outline"] = ThemeHex("#1c2922"),
                ["Accent"] = ThemeHex("#7ee787"),
                ["Element"] = ThemeHex("#15201b"),
                ["Hovered Element"] = ThemeHex("#1f2d26"),
                ["Text"] = ThemeHex("#a8b8ad"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Purple"] = {
                ["Background"] = ThemeHex("#100e16"),
                ["Inline"] = ThemeHex("#15121d"),
                ["Page Background"] = ThemeHex("#221c2e"),
                ["Border"] = ThemeHex("#0c0a12"),
                ["Outline"] = ThemeHex("#241e30"),
                ["Accent"] = ThemeHex("#c084fc"),
                ["Element"] = ThemeHex("#1a1624"),
                ["Hovered Element"] = ThemeHex("#261f33"),
                ["Text"] = ThemeHex("#b4a9c4"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Red"] = {
                ["Background"] = ThemeHex("#140e0e"),
                ["Inline"] = ThemeHex("#1a1212"),
                ["Page Background"] = ThemeHex("#2a1c1c"),
                ["Border"] = ThemeHex("#100a0a"),
                ["Outline"] = ThemeHex("#2a1f1f"),
                ["Accent"] = ThemeHex("#ff6b6b"),
                ["Element"] = ThemeHex("#221616"),
                ["Hovered Element"] = ThemeHex("#302020"),
                ["Text"] = ThemeHex("#b8a0a0"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["haze.best"] = {
                ["Background"] = ThemeHex("#0f1115"),
                ["Inline"] = ThemeHex("#14181f"),
                ["Page Background"] = ThemeHex("#1c2330"),
                ["Border"] = ThemeHex("#0b0d11"),
                ["Outline"] = ThemeHex("#222a38"),
                ["Accent"] = ThemeHex("#7dd3fc"),
                ["Element"] = ThemeHex("#181d27"),
                ["Hovered Element"] = ThemeHex("#242b38"),
                ["Text"] = ThemeHex("#a8b3c4"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Ocean"] = {
                ["Background"] = ThemeHex("#0a1218"),
                ["Inline"] = ThemeHex("#0f1a22"),
                ["Page Background"] = ThemeHex("#162833"),
                ["Border"] = ThemeHex("#071015"),
                ["Outline"] = ThemeHex("#1c303c"),
                ["Accent"] = ThemeHex("#2dd4bf"),
                ["Element"] = ThemeHex("#132028"),
                ["Hovered Element"] = ThemeHex("#1c2e38"),
                ["Text"] = ThemeHex("#9db8c4"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Sunset"] = {
                ["Background"] = ThemeHex("#14100e"),
                ["Inline"] = ThemeHex("#1a1411"),
                ["Page Background"] = ThemeHex("#2a2018"),
                ["Border"] = ThemeHex("#100c0a"),
                ["Outline"] = ThemeHex("#2e241c"),
                ["Accent"] = ThemeHex("#fb923c"),
                ["Element"] = ThemeHex("#221a14"),
                ["Hovered Element"] = ThemeHex("#30241c"),
                ["Text"] = ThemeHex("#c4b09a"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Rose"] = {
                ["Background"] = ThemeHex("#140f12"),
                ["Inline"] = ThemeHex("#1a1318"),
                ["Page Background"] = ThemeHex("#2a1c24"),
                ["Border"] = ThemeHex("#100a0e"),
                ["Outline"] = ThemeHex("#2e2028"),
                ["Accent"] = ThemeHex("#f472b6"),
                ["Element"] = ThemeHex("#22161c"),
                ["Hovered Element"] = ThemeHex("#302028"),
                ["Text"] = ThemeHex("#c4a8b4"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Gold"] = {
                ["Background"] = ThemeHex("#12100a"),
                ["Inline"] = ThemeHex("#18150e"),
                ["Page Background"] = ThemeHex("#262018"),
                ["Border"] = ThemeHex("#0e0c08"),
                ["Outline"] = ThemeHex("#2a2418"),
                ["Accent"] = ThemeHex("#fbbf24"),
                ["Element"] = ThemeHex("#1e1a12"),
                ["Hovered Element"] = ThemeHex("#2c2618"),
                ["Text"] = ThemeHex("#c4b896"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Mint"] = {
                ["Background"] = ThemeHex("#0c1412"),
                ["Inline"] = ThemeHex("#111a18"),
                ["Page Background"] = ThemeHex("#1a2824"),
                ["Border"] = ThemeHex("#080f0d"),
                ["Outline"] = ThemeHex("#1e2e2a"),
                ["Accent"] = ThemeHex("#5eead4"),
                ["Element"] = ThemeHex("#15201c"),
                ["Hovered Element"] = ThemeHex("#1f2e28"),
                ["Text"] = ThemeHex("#a8c0b8"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Crimson"] = {
                ["Background"] = ThemeHex("#120a0c"),
                ["Inline"] = ThemeHex("#180e12"),
                ["Page Background"] = ThemeHex("#28141a"),
                ["Border"] = ThemeHex("#0e080a"),
                ["Outline"] = ThemeHex("#2c1820"),
                ["Accent"] = ThemeHex("#e11d48"),
                ["Element"] = ThemeHex("#1e1014"),
                ["Hovered Element"] = ThemeHex("#2c181e"),
                ["Text"] = ThemeHex("#c49aa4"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Ice"] = {
                ["Background"] = ThemeHex("#0e1216"),
                ["Inline"] = ThemeHex("#13181e"),
                ["Page Background"] = ThemeHex("#1c2630"),
                ["Border"] = ThemeHex("#0a0e12"),
                ["Outline"] = ThemeHex("#222e38"),
                ["Accent"] = ThemeHex("#a5f3fc"),
                ["Element"] = ThemeHex("#171e26"),
                ["Hovered Element"] = ThemeHex("#222c36"),
                ["Text"] = ThemeHex("#b0c4d0"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Lava"] = {
                ["Background"] = ThemeHex("#120c0a"),
                ["Inline"] = ThemeHex("#18100c"),
                ["Page Background"] = ThemeHex("#281a14"),
                ["Border"] = ThemeHex("#0e0806"),
                ["Outline"] = ThemeHex("#2c1e16"),
                ["Accent"] = ThemeHex("#f97316"),
                ["Element"] = ThemeHex("#1e1410"),
                ["Hovered Element"] = ThemeHex("#2c1e16"),
                ["Text"] = ThemeHex("#c4a890"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Violet"] = {
                ["Background"] = ThemeHex("#100e18"),
                ["Inline"] = ThemeHex("#151220"),
                ["Page Background"] = ThemeHex("#221c32"),
                ["Border"] = ThemeHex("#0c0a14"),
                ["Outline"] = ThemeHex("#261e36"),
                ["Accent"] = ThemeHex("#a78bfa"),
                ["Element"] = ThemeHex("#1a1628"),
                ["Hovered Element"] = ThemeHex("#261f36"),
                ["Text"] = ThemeHex("#b4a8cc"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Nord"] = {
                ["Background"] = ThemeHex("#1a1e26"),
                ["Inline"] = ThemeHex("#20242e"),
                ["Page Background"] = ThemeHex("#2c3340"),
                ["Border"] = ThemeHex("#14181e"),
                ["Outline"] = ThemeHex("#343c4a"),
                ["Accent"] = ThemeHex("#88c0d0"),
                ["Element"] = ThemeHex("#242933"),
                ["Hovered Element"] = ThemeHex("#303848"),
                ["Text"] = ThemeHex("#d8dee9"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Matcha"] = {
                ["Background"] = ThemeHex("#10140e"),
                ["Inline"] = ThemeHex("#151a12"),
                ["Page Background"] = ThemeHex("#222a1c"),
                ["Border"] = ThemeHex("#0c100a"),
                ["Outline"] = ThemeHex("#263020"),
                ["Accent"] = ThemeHex("#a3e635"),
                ["Element"] = ThemeHex("#1a2016"),
                ["Hovered Element"] = ThemeHex("#262e1e"),
                ["Text"] = ThemeHex("#b4c4a0"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Midnight"] = {
                ["Background"] = ThemeHex("#080810"),
                ["Inline"] = ThemeHex("#0e0e18"),
                ["Page Background"] = ThemeHex("#161624"),
                ["Border"] = ThemeHex("#06060c"),
                ["Outline"] = ThemeHex("#1c1c2c"),
                ["Accent"] = ThemeHex("#818cf8"),
                ["Element"] = ThemeHex("#12121c"),
                ["Hovered Element"] = ThemeHex("#1c1c2a"),
                ["Text"] = ThemeHex("#a8a8c4"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Cherry"] = {
                ["Background"] = ThemeHex("#140c10"),
                ["Inline"] = ThemeHex("#1a1014"),
                ["Page Background"] = ThemeHex("#2a1820"),
                ["Border"] = ThemeHex("#10080c"),
                ["Outline"] = ThemeHex("#2e1c24"),
                ["Accent"] = ThemeHex("#fb7185"),
                ["Element"] = ThemeHex("#221418"),
                ["Hovered Element"] = ThemeHex("#301c24"),
                ["Text"] = ThemeHex("#c4a0a8"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
            ["Cyber"] = {
                ["Background"] = ThemeHex("#0a0e0e"),
                ["Inline"] = ThemeHex("#0e1414"),
                ["Page Background"] = ThemeHex("#162020"),
                ["Border"] = ThemeHex("#080c0c"),
                ["Outline"] = ThemeHex("#1c2828"),
                ["Accent"] = ThemeHex("#22d3ee"),
                ["Element"] = ThemeHex("#121a1a"),
                ["Hovered Element"] = ThemeHex("#1c2828"),
                ["Text"] = ThemeHex("#9ec8c8"),
                ["Text Border"] = FromRGB(0, 0, 0),
            },
        }
    end

    Library.GetThemesFolder = function(self)
        return self.Folders.Themes or (self.Folders.Directory .. "/Themes")
    end

    Library.GetThemeAutoloadPath = function(self)
        return self.Folders.Directory .. "/theme_autoload.json"
    end

    Library.EnsureThemeFolders = function(self)
        self.Folders.Themes = self.Folders.Directory .. "/Themes"
        if not isfolder(self.Folders.Themes) then
            makefolder(self.Folders.Themes)
        end
        local Autoload = self:GetThemeAutoloadPath()
        if not isfile(Autoload) then
            writefile(Autoload, "")
        end
    end

    Library.AddThemeHook = function(self, Callback)
        if type(Callback) == "function" then
            TableInsert(self.ThemeHooks, Callback)
        end
    end

    Library.FireThemeHooks = function(self, Key)
        for _, Callback in self.ThemeHooks do
            pcall(Callback, Key)
        end
    end

    -- UI chrome style: "Default" (boxed icon subtabs) or "Lined" (text + accent underline).
    -- Scripts may listen via ThemeHooks / their own ApplyUIStyle; this stores the choice.
    Library.UIStyle = "Lined"
    Library.SetUIStyle = function(self, Style)
        self.UIStyle = "Lined"
        self:FireThemeHooks("UIStyle")
        return "Lined"
    end

    Library.ResolveThemeColor = function(self, Value)
        if typeof(Value) == "Color3" then
            return Value
        end
        if type(Value) == "string" then
            local Hex = Value:gsub("#", "")
            if #Hex == 6 then
                return FromHex(Hex)
            end
        end
        return nil
    end

    Library.ApplyThemeColors = function(self, Theme, UpdatePickers)
        if type(Theme) ~= "table" then
            return false
        end

        for _, Index in self.ThemeKeys do
            local Color = self:ResolveThemeColor(Theme[Index])
            if not Color then
                continue
            end

            self.Theme[Index] = Color
            self:ChangeTheme(Index, Color)

            if UpdatePickers and self.SetFlags["Theme" .. Index] then
                self.SetFlags["Theme" .. Index](Color)
            end
        end

        self:FireThemeHooks(nil)
        return true
    end

    Library.ApplyTheme = function(self, Name, UpdatePickers)
        return self:ApplyThemeColors(self.Themes[Name], UpdatePickers)
    end

    Library.GetThemeData = function(self)
        local Data = { }
        for _, Index in self.ThemeKeys do
            local Color = self.Theme[Index]
            if typeof(Color) == "Color3" then
                Data[Index] = "#" .. Color:ToHex()
            end
        end
        return HttpService:JSONEncode(Data)
    end

    Library.LoadThemeData = function(self, Raw, UpdatePickers)
        local Ok, Decoded = pcall(function()
            return HttpService:JSONDecode(Raw)
        end)
        if Ok and type(Decoded) == "table" then
            return self:ApplyThemeColors(Decoded, UpdatePickers)
        end
        return false
    end

    Library.GetPresetThemeNames = function(self, PreferredFirst)
        local Names = { }
        for Name in pairs(self.Themes) do
            if Name ~= PreferredFirst then
                TableInsert(Names, Name)
            end
        end
        table.sort(Names)
        if PreferredFirst and self.Themes[PreferredFirst] then
            TableInsert(Names, 1, PreferredFirst)
        end
        return Names
    end

    Library.GetThemeFileName = function(self, Path)
        local Normalized = StringGSub(tostring(Path), "\\", "/")
        return string.match(Normalized, "([^/]+)$") or Path
    end

    Library.RefreshThemesList = function(self, Element)
        local List = { }
        local Folder = self:GetThemesFolder()
        if isfolder(Folder) then
            for _, Path in listfiles(Folder) do
                TableInsert(List, self:GetThemeFileName(Path))
            end
        end
        Element:Refresh(List)
    end

    Library.CreateThemeFile = function(self, Name)
        self:EnsureThemeFolders()
        if not Name or Name == "" then
            self:Notification("Enter a theme name", 3, FromRGB(255, 0, 0))
            return false
        end
        local Path = self:GetThemesFolder() .. "/" .. Name .. ".json"
        if isfile(Path) then
            self:Notification("Theme '" .. Name .. ".json' already exists", 3, FromRGB(255, 0, 0))
            return false
        end
        writefile(Path, self:GetThemeData())
        self:Notification("Created theme '" .. Name .. ".json'", 3, FromRGB(0, 255, 0))
        return true
    end

    Library.LoadThemeFile = function(self, FileName, UpdatePickers)
        if not FileName then
            return false
        end
        local Path = self:GetThemesFolder() .. "/" .. FileName
        if not isfile(Path) then
            return false
        end
        local Ok, Content = pcall(readfile, Path)
        if not Ok or not self:LoadThemeData(Content, UpdatePickers ~= false) then
            self:Notification("Failed to load theme " .. FileName, 3, FromRGB(255, 0, 0))
            return false
        end
        self:Notification("Loaded theme " .. FileName, 3, FromRGB(0, 255, 0))
        return true
    end

    Library.SaveThemeFile = function(self, FileName)
        if not FileName then
            return false
        end
        local Path = self:GetThemesFolder() .. "/" .. FileName
        writefile(Path, self:GetThemeData())
        self:Notification("Saved theme " .. FileName, 3, FromRGB(0, 255, 0))
        return true
    end

    Library.DeleteThemeFile = function(self, FileName)
        if not FileName then
            return false
        end
        local Path = self:GetThemesFolder() .. "/" .. FileName
        if not isfile(Path) then
            return false
        end
        delfile(Path)
        self:Notification("Deleted theme " .. FileName, 3, FromRGB(0, 255, 0))
        return true
    end

    Library.SetThemeAutoload = function(self, FileName)
        self:EnsureThemeFolders()
        local Autoload = self:GetThemeAutoloadPath()
        if not FileName or FileName == "" then
            writefile(Autoload, "")
            self:Notification("Theme autoload removed", 3, FromRGB(0, 255, 0))
            return true
        end
        local Path = self:GetThemesFolder() .. "/" .. FileName
        if not isfile(Path) then
            return false
        end
        writefile(Autoload, readfile(Path))
        self:Notification("Theme set as autoload", 3, FromRGB(0, 255, 0))
        return true
    end

    Library.LoadThemeAutoload = function(self, UpdatePickers)
        local Path = self:GetThemeAutoloadPath()
        if not isfile(Path) then
            return false
        end
        local Ok, Content = pcall(readfile, Path)
        if Ok and type(Content) == "string" and Content ~= "" then
            return self:LoadThemeData(Content, UpdatePickers ~= false)
        end
        return false
    end

    Library.AddThemeUI = function(self, Page, Data)
        Data = Data or { }
        local Default = Data.Default or Data.default or "haze.best"
        if not self.Themes[Default] then
            Default = "haze.best"
        end

        self:EnsureThemeFolders()

        local ThemesSection = Page:Section({Name = "Theme Profiles", Side = 1})
        local PresetsSection = Page:Section({Name = "Presets", Side = 2})
        local ColorsSection = Page:Section({Name = "Customize UI", Side = 2})

        local ThemeName
        local ThemeSelected

        local ThemesListbox = ThemesSection:Listbox({Items = { }, Name = "Themes", Flag = "Themes List", Callback = function(Value)
            ThemeSelected = Value
        end})

        ThemesSection:Textbox({Name = "Theme Name", Placeholder = ". .", Flag = "Theme Name", Callback = function(Value)
            ThemeName = Value
        end})

        ThemesSection:Button({Name = "Create Theme", Callback = function()
            if self:CreateThemeFile(ThemeName) then
                self:RefreshThemesList(ThemesListbox)
            end
        end})

        ThemesSection:Button({Name = "Load Theme", Callback = function()
            self:LoadThemeFile(ThemeSelected, true)
        end})

        ThemesSection:Button({Name = "Delete Theme", Callback = function()
            if self:DeleteThemeFile(ThemeSelected) then
                ThemeSelected = nil
                self:RefreshThemesList(ThemesListbox)
            end
        end})

        ThemesSection:Button({Name = "Save Theme", Callback = function()
            self:SaveThemeFile(ThemeSelected)
        end})

        ThemesSection:Button({Name = "Refresh Themes", Callback = function()
            self:RefreshThemesList(ThemesListbox)
        end})

        ThemesSection:Divider()

        ThemesSection:Button({Name = "Set As Autoload", Callback = function()
            self:SetThemeAutoload(ThemeSelected)
        end})

        ThemesSection:Button({Name = "Remove Autoload", Callback = function()
            self:SetThemeAutoload(nil)
        end})

        self:RefreshThemesList(ThemesListbox)

        PresetsSection:Dropdown({
            Name = "Theme",
            Flag = "UI Theme",
            Default = Default,
            MaxSize = 168,
            Items = self:GetPresetThemeNames(Default),
            Callback = function(Value)
                self:ApplyTheme(Value, true)
            end
        })

        for _, Key in self.ThemeKeys do
            ColorsSection:Label({Name = Key, Alignment = "Left"}):Colorpicker({
                Name = Key,
                Default = self.Theme[Key],
                Flag = "Theme" .. Key,
                Callback = function(Color)
                    self.Theme[Key] = Color
                    self:ChangeTheme(Key, Color)
                    self:FireThemeHooks(Key)
                end
            })
        end
    end

    Library.IsMouseOverFrame = function(self, Frame)
        Frame = Frame.Instance

        local MousePosition = Vector2New(Mouse.X, Mouse.Y)

        return MousePosition.X >= Frame.AbsolutePosition.X and MousePosition.X <= Frame.AbsolutePosition.X + Frame.AbsoluteSize.X 
        and MousePosition.Y >= Frame.AbsolutePosition.Y and MousePosition.Y <= Frame.AbsolutePosition.Y + Frame.AbsoluteSize.Y
    end

    Library.Watermark = function(self, Name)
        local Watermark = { } 

        local Items = { } do 
            Items["Watermark"] = Instances:Create("Frame", {
                Parent = Library.Holder.Instance,
                Size = UDim2New(0, 0, 0, 20),
                Name = "\0",
                Position = UDim2New(0, 15, 0, 15),
                BorderColor3 = FromRGB(10, 10, 10),
                BorderSizePixel = 2,
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = FromRGB(15, 15, 20)
            })  Items["Watermark"]:AddToTheme({BackgroundColor3 = "Background", BorderColor3 = "Border"})

            Items["Watermark"]:MakeDraggable()
            
            Instances:Create("UIStroke", {
                Parent = Items["Watermark"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"})
            
            Instances:Create("UIPadding", {
                Parent = Items["Watermark"].Instance,
                PaddingTop = UDimNew(0, 2),
                PaddingRight = UDimNew(0, 5),
                PaddingLeft = UDimNew(0, 5)
            }) 
            
            Items["Title"] = Instances:Create("TextLabel", {
                Parent = Items["Watermark"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Name,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 15),
                BackgroundTransparency = 1,
                Position = UDim2New(0, 0, 0, 1),
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Title"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Title"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})
            
            Items["AccentLine"] = Instances:Create("Frame", {
                Parent = Items["Watermark"].Instance,
                Name = "\0",
                Position = UDim2New(0, -5, 0, -2),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 10, 0, 2),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(235, 157, 255)
            })  Items["AccentLine"]:AddToTheme({BackgroundColor3 = "Accent"})
            
            Instances:Create("UIGradient", {
                Parent = Items["AccentLine"].Instance,
                Rotation = 90,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(65, 65, 65))}
            })             
        end

        function Watermark:SetVisibility(Bool)
            Items["Watermark"].Instance.Visible = Bool
        end
        
        return Watermark
    end

    Library.Notification = function(self, Text, Duration, Color, Icon)
        local Items = { } do
            Items["Notification"] = Instances:Create("Frame", {
                Parent = Library.NotifHolder.Instance,
                Name = "\0",
                Size = UDim2New(0, 0, 0, 22),
                BorderColor3 = FromRGB(10, 10, 10),
                BorderSizePixel = 2,
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = FromRGB(15, 15, 20)
            })  Items["Notification"]:AddToTheme({BackgroundColor3 = "Background", BorderColor3 = "Border"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Notification"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"}) 
            
            Instances:Create("UIPadding", {
                Parent = Items["Notification"].Instance,
                PaddingTop = UDimNew(0, 1),
                PaddingRight = UDimNew(0, 8),
                PaddingLeft = UDimNew(0, 5)
            }) 
            
            Items["Title"] = Instances:Create("TextLabel", {
                Parent = Items["Notification"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Text,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 15),
                BackgroundTransparency = 1,
                Position = UDim2New(0, 13, 0, 2),
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Title"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Title"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})

            Items["AccentLine"] = Instances:Create("Frame", {
                Parent = Items["Notification"].Instance,
                Name = "\0",
                Position = UDim2New(0, -5, 0, -1),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 13, 0, 2),
                BorderSizePixel = 0,
                BackgroundColor3 = Color
            })  
            
            Instances:Create("UIGradient", {
                Parent = Items["AccentLine"].Instance,
                Rotation = 90,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(65, 65, 65))}
            })
            
            Items["Icon"] = Instances:Create("ImageLabel", {
                Parent = Items["Notification"].Instance,
                ImageColor3 = FromRGB(255, 255, 255),
                ScaleType = Enum.ScaleType.Fit,
                BorderColor3 = FromRGB(0, 0, 0),
                Name = "\0",
                Image = "rbxassetid://94324346713012",
                BackgroundTransparency = 1,
                Position = UDim2New(0, -2, 0, 3),
                Size = UDim2New(0, 13, 0, 13),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 

            if not Icon then 
                Items["Icon"]:Clean()
                Items["Title"].Instance.Position = UDim2New(0, 1, 0, 2)
            else
                Items["Icon"].Instance.Image = Icon[1]
                Items["Icon"].Instance.ImageColor3 = Icon[2] or FromRGB(255, 255, 255)
            end
        end

        Items["Notification"].Instance.BackgroundTransparency = 1
        Items["Notification"].Instance.Size = UDim2New(0, 0, 0, 0)
        for Index, Value in Items["Notification"].Instance:GetDescendants() do
            if Value:IsA("UIStroke") then 
                Value.Transparency = 1
            elseif Value:IsA("TextLabel") then 
                Value.TextTransparency = 1
            elseif Value:IsA("ImageLabel") then 
                Value.ImageTransparency = 1
            elseif Value:IsA("Frame") then 
                Value.BackgroundTransparency = 1
            end
        end

        Library:Thread(function()
            Items["Notification"]:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0, 0, 0, 22)})
            
            task.wait(0.06)

            for Index, Value in Items["Notification"].Instance:GetDescendants() do
                if Value:IsA("UIStroke") then
                    Tween:Create(Value, nil, {Transparency = 0}, true)
                elseif Value:IsA("TextLabel") then
                    Tween:Create(Value, nil, {TextTransparency = 0}, true)
                elseif Value:IsA("ImageLabel") then
                    Tween:Create(Value, nil, {ImageTransparency = 0}, true)
                elseif Value:IsA("Frame") then
                    Tween:Create(Value, nil, {BackgroundTransparency = 0}, true)
                end
            end

            task.delay(Duration + 0.1, function()
                for Index, Value in Items["Notification"].Instance:GetDescendants() do
                    if Value:IsA("UIStroke") then
                        Tween:Create(Value, nil, {Transparency = 1}, true)
                    elseif Value:IsA("TextLabel") then
                        Tween:Create(Value, nil, {TextTransparency = 1}, true)
                    elseif Value:IsA("ImageLabel") then
                        Tween:Create(Value, nil, {ImageTransparency = 1}, true)
                    elseif Value:IsA("Frame") then
                        Tween:Create(Value, nil, {BackgroundTransparency = 1}, true)
                    end
                end

                task.wait(0.06)

                Items["Notification"]:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 0, 0, 0)})

                task.wait(0.5)
                Items["Notification"]:Clean()
            end)
        end)
    end

    Library.KeybindList = function(self)
        local KeybindList = { }
        self.KeyList = KeybindList

        local Items = { } do
            Items["KeybindList"] = Instances:Create("Frame", {
                Parent = Library.Holder.Instance,
                BorderColor3 = FromRGB(10, 10, 10),
                AnchorPoint = Vector2New(0, 0.5),
                Name = "\0",
                Position = UDim2New(0, 15, 0.5, 0),
                Size = UDim2New(0, 0, 0, 18),
                BorderSizePixel = 2,
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundColor3 = FromRGB(15, 15, 20)
            })  Items["KeybindList"]:AddToTheme({BackgroundColor3 = "Background", BorderColor3 = "Border"})

            Items["KeybindList"]:MakeDraggable()
            
            Instances:Create("UIStroke", {
                Parent = Items["KeybindList"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"})
            
            Items["AccentLine"] = Instances:Create("Frame", {
                Parent = Items["KeybindList"].Instance,
                Name = "\0",
                Position = UDim2New(0, -5, 0, -5),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 10, 0, 2),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(235, 157, 255)
            })  Items["AccentLine"]:AddToTheme({BackgroundColor3 = "Accent"})
            
            Instances:Create("UIGradient", {
                Parent = Items["AccentLine"].Instance,
                Rotation = 90,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(65, 65, 65))}
            }) 
            
            Instances:Create("UIPadding", {
                Parent = Items["KeybindList"].Instance,
                PaddingTop = UDimNew(0, 5),
                PaddingBottom = UDimNew(0, 5),
                PaddingRight = UDimNew(0, 5),
                PaddingLeft = UDimNew(0, 5)
            }) 
            
            Items["Title"] = Instances:Create("TextLabel", {
                Parent = Items["KeybindList"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "Keybinds",
                Name = "\0",
                Size = UDim2New(0, 100, 0, 15),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2New(0, 0, 0, -1),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Title"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Title"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})
            
            Items["Content"] = Instances:Create("Frame", {
                Parent = Items["KeybindList"].Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                Position = UDim2New(0, 5, 0, 19),
                BorderColor3 = FromRGB(0, 0, 0),
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Instances:Create("UIListLayout", {
                Parent = Items["Content"].Instance,
                Padding = UDimNew(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder
            }) 
        end

        function KeybindList:Add(Mode, Name, Key)
            local NewKey = Instances:Create("TextLabel", {
                Parent = Items["Content"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "(" .. Mode .. ") " .. Name .. " - " .. Key,
                Name = "\0",
                Size = UDim2New(0, 0, 0, 15),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  NewKey:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = NewKey.Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})
        
            function NewKey:Set(Mode, Name, Key)
                NewKey.Instance.Text = "(" .. Mode .. ") " .. Name .. " - " .. Key
            end

            function NewKey:SetStatus(Status)
                if Status == "Active" then 
                    NewKey:Tween(nil, {TextColor3 = Library.Theme.Accent})
                    NewKey:ChangeItemTheme({TextColor3 = "Accent"})
                else 
                    NewKey:Tween(nil, {TextColor3 = Library.Theme.Text})
                    NewKey:ChangeItemTheme({TextColor3 = "Text"})
                end
            end

            return NewKey
        end

        function KeybindList:SetVisibility(Bool)
            Items["KeybindList"].Instance.Visible = Bool
        end

        return KeybindList
    end

    Library.CreateColorpicker = function(self, Data)
        local Colorpicker = {
            Hue = 0,
            Saturation = 0,
            Value = 0,

            Alpha = 0,

            HexValue = "",
            
            IsOpen = false,

            Color = FromRGB(0, 0, 0),

            Class = "Colorpicker"
        }

        Library.Flags[Data.Flag] = { }

        local Items = { } do
            Items["ColorpickerButton"] = Instances:Create("TextButton", {
                Parent = Data.Parent.Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(0, 0, 0),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "",
                AutoButtonColor = false,
                AnchorPoint = Vector2New(1, 0.5),
                Name = "\0",
                Position = UDim2New(1, 0, 0.5, 0),
                Size = UDim2New(0, 20, 0, 10),
                BorderSizePixel = 0,
                TextSize = 14,
                BackgroundColor3 = FromRGB(255, 0, 0)
            }) 


            Colorpicker.CalculateCount = function(self, Index, YScale, YOffset)
                local MaxButtonsAdded = 5

                local Column = Index % MaxButtonsAdded
            
                local ButtonSize = Items["ColorpickerButton"].Instance.AbsoluteSize
                local Spacing = 4
            
                local XPosition = (ButtonSize.X + Spacing) * Column - Spacing - 21
            
                Items["ColorpickerButton"].Instance.Position = UDim2New(1, -XPosition, YScale or 0.5, YOffset or 0)
            end

            Colorpicker:CalculateCount(Data.Count)
            
            Instances:Create("UIStroke", {
                Parent = Items["ColorpickerButton"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"})
            
            Instances:Create("UIGradient", {
                Parent = Items["ColorpickerButton"].Instance,
                Rotation = 90,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(100, 100, 100))}
            })             

            Items["ColorpickerWindow"] = Instances:Create("TextButton", {
                Parent = Library.Holder.Instance,
                AutoButtonColor = false,
                Text = "",
                Name = "\0",
                Position = UDim2New(0, Data.Parent.Instance.AbsolutePosition.X, 0, Data.Parent.Instance.AbsolutePosition.Y + 15),
                BorderColor3 = FromRGB(10, 10, 10),
                Visible = false,
                Size = UDim2New(0, 238, 0, 224),
                BorderSizePixel = 2,
                BackgroundColor3 = FromRGB(15, 15, 20)
            })  Items["ColorpickerWindow"]:AddToTheme({BackgroundColor3 = "Background"})
            
            Items["ColorpickerWindow"]:MakeDraggable()
            Items["ColorpickerWindow"]:MakeResizeable(Vector2New(200, 180), Vector2New(9999, 9999))

            Instances:Create("UIStroke", {
                Parent = Items["ColorpickerWindow"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"})
            
            Items["Title"] = Instances:Create("TextLabel", {
                Parent = Items["ColorpickerWindow"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Data.Name,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 15),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2New(0, -2, 0, -3),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Title"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Title"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})
            
            Items["AccentLine"] = Instances:Create("Frame", {
                Parent = Items["ColorpickerWindow"].Instance,
                Name = "\0",
                Position = UDim2New(0, -6, 0, -6),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 12, 0, 2),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(235, 157, 255)
            })  Items["AccentLine"]:AddToTheme({BackgroundColor3 = "Accent"})
            
            Instances:Create("UIGradient", {
                Parent = Items["AccentLine"].Instance,
                Rotation = 90,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(65, 65, 65))}
            }) 
            
            Instances:Create("UIPadding", {
                Parent = Items["ColorpickerWindow"].Instance,
                PaddingTop = UDimNew(0, 6),
                PaddingBottom = UDimNew(0, 6),
                PaddingRight = UDimNew(0, 6),
                PaddingLeft = UDimNew(0, 6)
            }) 
            
            Items["Palette"] = Instances:Create("TextButton", {
                Parent = Items["ColorpickerWindow"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(0, 0, 0),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "",
                AutoButtonColor = false,
                Name = "\0",
                Position = UDim2New(0, 0, 0, 15),
                Size = UDim2New(1, -26, 1, -40),
                BorderSizePixel = 0,
                TextSize = 14,
                BackgroundColor3 = FromRGB(255, 0, 0)
            }) 
            
            Items["Saturation"] = Instances:Create("ImageLabel", {
                Parent = Items["Palette"].Instance,
                BorderColor3 = FromRGB(0, 0, 0),
                Image = Library:GetImage("Saturation"),
                BackgroundTransparency = 1,
                Name = "\0",
                Size = UDim2New(1, 0, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Items["Value"] = Instances:Create("ImageLabel", {
                Parent = Items["Palette"].Instance,
                BorderColor3 = FromRGB(0, 0, 0),
                Image = Library:GetImage("Value"),
                BackgroundTransparency = 1,
                Name = "\0",
                Size = UDim2New(1, 0, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Instances:Create("UIStroke", {
                Parent = Items["Palette"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"})
            
            Items["PaletteDragger"] = Instances:Create("Frame", {
                Parent = Items["Palette"].Instance,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(0, 2, 0, 2),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Instances:Create("UIStroke", {
                Parent = Items["PaletteDragger"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"})
            
            Items["Hue"] = Instances:Create("ImageButton", {
                Parent = Items["ColorpickerWindow"].Instance,
                BorderColor3 = FromRGB(0, 0, 0),
                AutoButtonColor = false,
                AnchorPoint = Vector2New(1, 0),
                Image = Library:GetImage("Hue"),
                Name = "\0",
                Position = UDim2New(1, 0, 0, 15),
                Size = UDim2New(0, 18, 1, -15),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Items["HueDragger"] = Instances:Create("Frame", {
                Parent = Items["Hue"].Instance,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 1),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Instances:Create("UIStroke", {
                Parent = Items["HueDragger"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Hue"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"})
            
            Items["Alpha"] = Instances:Create("TextButton", {
                Parent = Items["ColorpickerWindow"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(0, 0, 0),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "",
                AutoButtonColor = false,
                AnchorPoint = Vector2New(0, 1),
                Name = "\0",
                Position = UDim2New(0, 0, 1, 0),
                Size = UDim2New(1, -26, 0, 18),
                BorderSizePixel = 0,
                TextSize = 14,
                BackgroundColor3 = FromRGB(255, 0, 0)
            }) 
            
            Instances:Create("UIStroke", {
                Parent = Items["Alpha"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"})
            
            Items["Checkers"] = Instances:Create("ImageLabel", {
                Parent = Items["Alpha"].Instance,
                ScaleType = Enum.ScaleType.Tile,
                BorderColor3 = FromRGB(0, 0, 0),
                Image = Library:GetImage("Checkers"),
                TileSize = UDim2New(0, 6, 0, 6),
                Name = "\0",
                Size = UDim2New(1, 0, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Instances:Create("UIGradient", {
                Parent = Items["Checkers"].Instance,
                Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(1, 0)}
            }) 
            
            Instances:Create("UIGradient", {
                Parent = Items["Alpha"].Instance,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(0, 0, 0))}
            }) 
            
            Items["AlphaDragger"] = Instances:Create("Frame", {
                Parent = Items["Alpha"].Instance,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(0, 1, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Instances:Create("UIStroke", {
                Parent = Items["AlphaDragger"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"})
        end

        local SlidingPalette = false
        local SlidingHue = false
        local SlidingAlpha = false

        local Debounce = false

        function Colorpicker:SetOpen(Bool)
            if Debounce then 
                return 
            end

            Colorpicker.IsOpen = Bool

            Debounce = true 

            if Bool then 
                Items["ColorpickerWindow"].Instance.Visible = true
                Items["ColorpickerWindow"].Instance.Position = UDim2New(0, Data.Parent.Instance.AbsolutePosition.X, 0, Data.Parent.Instance.AbsolutePosition.Y + 15)

                if Library.CurrentColorpicker then
                    Library.CurrentColorpicker:SetOpen(false)
                    Library.CurrentColorpicker = nil 
                end

                if not Library.CurrentColorpicker then 
                    Library.CurrentColorpicker = Colorpicker
                end
            else
                Library.CurrentColorpicker = nil
            end

            local Descendants = Items["ColorpickerWindow"].Instance:GetDescendants()
            TableInsert(Descendants, Items["ColorpickerWindow"].Instance)

            local NewTween
            for Index, Value in Descendants do 
                local ValueIndex = Library:GetTransparencyPropertyFromItem(Value)

                if not ValueIndex then 
                    continue
                end

                if not StringFind(Value.ClassName, "UI") then 
                    Value.ZIndex = Bool and 10001 or 1
                end

                if type(ValueIndex) == "table" then
                    for _, Property in ValueIndex do 
                        NewTween = Library:FadeItem(Value, Property, Bool, Data.FadeSpeed)
                    end
                else
                    NewTween = Library:FadeItem(Value, ValueIndex, Bool, Data.FadeSpeed)
                end
            end

            Library:Connect(NewTween.Tween.Completed, function()
                Debounce = false
                Items["ColorpickerWindow"].Instance.Visible = Bool
            end)
        end

        function Colorpicker:Get()
            return Colorpicker.Value
        end

        function Colorpicker:SetVisibility(Bool)
           Data.Parent.Instance.Visible = Bool 
        end

        function Colorpicker:Set(Color, Alpha)
            if type(Color) == "table" then 
                local TableAlpha = Color.Alpha or Color[4]
                if type(Color[1]) == "number" then
                    Color = FromRGB(Color[1], Color[2], Color[3])
                elseif type(Color.Color) == "string" then
                    Color = FromHex(Color.Color)
                elseif typeof(Color.Color) == "Color3" then
                    Color = Color.Color
                end
                Alpha = TableAlpha or Alpha
            elseif type(Color) == "string" then 
                Color = FromHex(Color)
            end

            self.Hue, self.Saturation, self.Value = Color:ToHSV()
            self.Alpha = Alpha or 0

            self.Color = FromHSV(self.Hue, self.Saturation, self.Value)
            self.HexValue = self.Color:ToHex()

            Library.Flags[Data.Flag] = {
                Color = self.Color,
                HexValue =  self.HexValue,
                Alpha = self.Alpha
            }

            local ColorPositionX = MathClamp(1 - self.Saturation, 0, 0.989)
            local ColorPositionY = MathClamp(1 - self.Value, 0, 0.989)

            Items["PaletteDragger"]:Tween(TweenInfo.new(0.17, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(ColorPositionX, 0, ColorPositionY, 0)})

            local HuePositionY = MathClamp(self.Hue, 0, 0.994)

            Items["HueDragger"]:Tween(TweenInfo.new(0.17, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, HuePositionY, 0)})

            local AlphaPositionX = MathClamp(self.Alpha, 0, 0.994)

            Items["AlphaDragger"]:Tween(TweenInfo.new(0.17, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(AlphaPositionX, 0, 0, 0)})

            self:Update()
        end

        function Colorpicker:Update(IsFromAlpha)
            self.Color = FromHSV(self.Hue, self.Saturation, self.Value)
            self.HexValue = self.Color:ToHex()

            Library.Flags[Data.Flag] = {
                Color = self.Color,
                HexValue =  self.HexValue,
                Alpha = self.Alpha
            }

            Items["ColorpickerButton"]:Tween(TweenInfo.new(0.17, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = self.Color})
            Items["Palette"]:Tween(TweenInfo.new(0.17, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = FromHSV(self.Hue, 1, 1)})

            if not IsFromAlpha then 
                Items["Alpha"]:Tween(TweenInfo.new(0.17, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = self.Color})
            end

            if Data.Callback then 
                Library:SafeCall(Data.Callback, self.Color, self.Alpha)
            end
        end

        function Colorpicker:SlidePalette(Input)
            if not Input or not SlidingPalette then 
                return
            end

            local ValueX = MathClamp(1 - (Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 1)
            local ValueY = MathClamp(1 - (Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 1)

            self.Saturation = ValueX
            self.Value = ValueY

            local SlideX = MathClamp((Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 0.989)
            local SlideY = MathClamp((Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 0.989)

            Items["PaletteDragger"]:Tween(TweenInfo.new(0.17, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, SlideY, 0)})
            self:Update()            
        end

        function Colorpicker:SlideHue(Input)
            if not Input or not SlidingHue then 
                return
            end

            local ValueY = MathClamp((Input.Position.Y - Items["Hue"].Instance.AbsolutePosition.Y) / Items["Hue"].Instance.AbsoluteSize.Y, 0, 1)

            self.Hue = ValueY

            local PositionY = MathClamp((Input.Position.Y - Items["Hue"].Instance.AbsolutePosition.Y) / Items["Hue"].Instance.AbsoluteSize.Y, 0, 0.994)

            Items["HueDragger"]:Tween(TweenInfo.new(0.17, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, PositionY, 0)})
            self:Update()
        end

        function Colorpicker:SlideAlpha(Input)
            if not Input or not SlidingAlpha then 
                return
            end

            local ValueX = MathClamp((Input.Position.X - Items["Alpha"].Instance.AbsolutePosition.X) / Items["Alpha"].Instance.AbsoluteSize.X, 0, 1)
            
            self.Alpha = ValueX

            local PositionX = MathClamp((Input.Position.X - Items["Alpha"].Instance.AbsolutePosition.X) / Items["Alpha"].Instance.AbsoluteSize.X, 0, 0.994)

            Items["AlphaDragger"]:Tween(TweenInfo.new(0.17, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(PositionX, 0, 0, 0)})
            self:Update(true)
        end

        Items["ColorpickerButton"]:Connect("MouseButton1Down", function()
            Colorpicker:SetOpen(not Colorpicker.IsOpen)
        end)

        local PaletteChanged

        Items["Palette"]:Connect("InputBegan", function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                SlidingPalette = true
                Colorpicker:SlidePalette(Input)

                if PaletteChanged then
                    return
                end

                PaletteChanged = Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        SlidingPalette = false

                        PaletteChanged:Disconnect()
                        PaletteChanged = nil
                    end
                end) 
            end
        end)

        local HueChanged

        Items["Hue"]:Connect("InputBegan", function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                SlidingHue = true
                Colorpicker:SlideHue(Input)

                if HueChanged then
                    return
                end

                HueChanged = Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        SlidingHue = false

                        HueChanged:Disconnect()
                        HueChanged = nil
                    end
                end)
            end
        end)

        local AlphaChanged

        Items["Alpha"]:Connect("InputBegan", function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                SlidingAlpha = true
                Colorpicker:SlideAlpha(Input)
                
                if AlphaChanged then
                    return
                end

                AlphaChanged = Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        SlidingAlpha = false

                        AlphaChanged:Disconnect()
                        AlphaChanged = nil
                    end
                end)
            end
        end)

        Library:Connect(UserInputService.InputChanged, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                if SlidingPalette then
                    Colorpicker:SlidePalette(Input)
                end

                if SlidingHue then
                    Colorpicker:SlideHue(Input)
                end

                if SlidingAlpha then
                    Colorpicker:SlideAlpha(Input)
                end
            end
        end)

        Library:Connect(UserInputService.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                if not Colorpicker.IsOpen  then
                    return
                end

                if Library:IsMouseOverFrame(Items["ColorpickerWindow"]) then
                    return
                end

                Colorpicker:SetOpen(false)
            end
        end)

        if Data.Default then 
            Colorpicker:Set(Data.Default, Data.Alpha)
        end

        Library.SetFlags[Data.Flag] = function(Color, Alpha)
            Colorpicker:Set(Color, Alpha)
        end

        return Colorpicker
    end

    Library.CreateKeybind = function(self, Data)
        local Keybind = {
            Key = nil,
            Value = "",
            Mode = "",

            Toggled = false,
            IsOpen = false,

            Picking = false,

            Class = "Keybind"
        }

        Library.Flags[Data.Flag] = { }

        local KeyListItem

        local Items = { } do 
            Items["KeyButton"] = Instances:Create("TextButton", {
                Parent = Data.Parent.Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(0, 0, 0),
                BorderColor3 = FromRGB(27, 27, 32),
                Text = "",
                AutoButtonColor = false,
                AnchorPoint = Vector2New(1, 0),
                Size = UDim2New(0, 0, 1, 1),
                Name = "\0",
                Position = UDim2New(1, 0, 0, 0),
                BorderSizePixel = 2,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 14,
                BackgroundColor3 = FromRGB(15, 15, 20)
            })  Items["KeyButton"]:AddToTheme({BackgroundColor3 = "Background", BorderColor3 = "Outline"})

            if Library.KeyList then 
                KeyListItem = Library.KeyList:Add(Keybind.Mode, Data.Name, Keybind.Value)
            end
            
            Instances:Create("UIStroke", {
                Parent = Items["KeyButton"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(10, 10, 10)
            }):AddToTheme({Color = "Border"})
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["KeyButton"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "MB2",
                Name = "\0",
                BackgroundTransparency = 1,
                Position = UDim2New(0, 1, 0, 0),
                Size = UDim2New(1, 0, 1, 0),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Text"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})
            
            Instances:Create("UIPadding", {
                Parent = Items["KeyButton"].Instance,
                PaddingRight = UDimNew(0, 3),
                PaddingLeft = UDimNew(0, 3),
                PaddingBottom = UDimNew(0, 2)
            })             

            Items["Window"] = Instances:Create("Frame", {
                Parent = Data.Parent.Instance,
                BorderColor3 = FromRGB(10, 10, 10),
                AnchorPoint = Vector2New(1, 0),
                Name = "\0",
                Position = UDim2New(1, 0, 1, 5),
                Size = UDim2New(0, 50, 0, 48),
                BorderSizePixel = 2,
                Visible = false,
                BackgroundColor3 = FromRGB(15, 15, 20)
            })  Items["Window"]:AddToTheme({BackgroundColor3 = "Background", BorderColor3 = "Border"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Window"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"})
            
            Items["Toggle"] = Instances:Create("TextButton", {
                Parent = Items["Window"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(235, 157, 255),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "Toggle",
                AutoButtonColor = false,
                Name = "\0",
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 1, 0, 0),
                Size = UDim2New(1, 0, 0, 15),
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Toggle"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Toggle"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})
            
            Items["Hold"] = Instances:Create("TextButton", {
                Parent = Items["Window"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "Hold",
                AutoButtonColor = false,
                Name = "\0",
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 1, 0, 15),
                Size = UDim2New(1, 0, 0, 15),
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Hold"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Hold"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})
            
            Items["Always"] = Instances:Create("TextButton", {
                Parent = Items["Window"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "Always",
                AutoButtonColor = false,
                Name = "\0",
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 1, 0, 30),
                Size = UDim2New(1, 0, 0, 15),
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Always"]:AddToTheme({TextColor3 = "Text"})
             
            Instances:Create("UIStroke", {
                Parent = Items["Always"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})
        end

        local Modes = {
            ["Toggle"] = Items["Toggle"],
            ["Hold"] = Items["Hold"],
            ["Always"] = Items["Always"]
        }

        local Update = function()
            if KeyListItem then
                KeyListItem:Set(Keybind.Mode, Data.Name, Keybind.Value)
                KeyListItem:SetStatus(Keybind.Toggled and "Active" or "Inactive")
            end
        end

        function Keybind:Get()
           return Keybind.Toggled, Keybind.Key, Keybind.Mode 
        end

        function Keybind:SetVisibility(Bool)
            Data.Parent.Instance.Visible = Bool
        end

        local Debounce = false

        function Keybind:SetOpen(Bool)
            Keybind.IsOpen = Bool

            if Bool then 
                Debounce = true
                Items["Window"].Instance.Visible = true
                Items["Window"].Instance.ZIndex = 16
                Items["Window"]:Tween(nil, {BackgroundTransparency = 0})

                task.wait(0.1)

                for Index, Value in Items["Window"].Instance:GetDescendants() do 
                    if Value:IsA("UIStroke") then
                        Tween:Create(Value, nil, {Transparency = 0}, true)
                    elseif Value:IsA("TextButton") then
                        Tween:Create(Value, nil, {TextTransparency = 0}, true)
                        Value.ZIndex = 16
                    end
                end
            else 
                for Index, Value in Items["Window"].Instance:GetDescendants() do 
                    if Value:IsA("UIStroke") then
                        Tween:Create(Value, nil, {Transparency = 1}, true)
                    elseif Value:IsA("TextButton") then
                        Tween:Create(Value, nil, {TextTransparency = 1}, true)
                        Value.ZIndex = 1
                    end
                end

                task.wait(0.1)

                Items["Window"]:Tween(nil, {BackgroundTransparency = 1})
                Items["Window"].Instance.ZIndex = 1
                task.wait(0.1)
                Items["Window"].Instance.Visible = false
            end

            Debounce = false
        end

        function Keybind:Set(Key)
            if StringFind(tostring(Key), "Enum") then 
                Keybind.Key = tostring(Key)

                Key = Key.Name == "Backspace" and "None" or Key.Name

                local KeyString = Keys[Keybind.Key] or StringGSub(Key, "Enum.", "") or "None"
                local TextToDisplay = StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "None"

                Keybind.Value = TextToDisplay
                Items["Text"].Instance.Text = TextToDisplay
    
                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end
           elseif TableFind({"Toggle", "Hold", "Always"}, Key) then 
                Keybind.Mode = Key
                
                Keybind:SetMode(Key)

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end
            elseif type(Key) == "table" then 
                local RealKey = Key.Key == "Backspace" and "None" or Key.Key
                Keybind.Key = tostring(Key.Key)

                if Key.Mode then
                    Keybind.Mode = Key.Mode
                    Keybind:SetMode(Key.Mode)
                else
                    Keybind.Mode = "Toggle"
                    Keybind:SetMode("Toggle")
                end

                local KeyString = Keys[Keybind.Key] or StringGSub(tostring(RealKey), "Enum.", "") or RealKey
                local TextToDisplay = KeyString and StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "None"

                TextToDisplay = StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "")

                Keybind.Value = TextToDisplay
                Items["Text"].Instance.Text = TextToDisplay

                if Keybind.Callback then 
                    Library:SafeCall(Keybind.Callback, Keybind.Toggled)
                end
            end

            Keybind.Picking = false
            Items["Text"]:Tween(nil, {TextColor3 = Library.Theme.Text})
            Items["Text"]:ChangeItemTheme({TextColor3 = "Text"})
            Items["Text"].Instance.Size = UDim2New(0, Items["Text"].Instance.TextBounds.X, 1, 1)
            Update()
        end

        function Keybind:SetMode(Mode)
            for Index, Value in Modes do 
                if Index == Mode then 
                    Value:Tween(nil, {TextColor3 = Library.Theme.Accent})
                    Value:ChangeItemTheme({TextColor3 = "Accent"})
                else
                    Value:Tween(nil, {TextColor3 = Library.Theme.Text})
                    Value:ChangeItemTheme({TextColor3 = "Text"})
                end
            end

            if Keybind.Mode == "Always" then 
                Keybind.Toggled = true
            else
                Keybind.Toggled = false
            end

            Library.Flags[Data.Flag] = {
                Mode = Keybind.Mode,
                Key = Keybind.Key,
                Toggled = Keybind.Toggled
            }

            if Data.Callback then 
                Library:SafeCall(Data.Callback, Keybind.Toggled)
            end

            Update()
        end

        function Keybind:Press(Bool)
            if Keybind.Mode == "Toggle" then
                Keybind.Toggled = not Keybind.Toggled
            elseif Keybind.Mode == "Hold" then
                Keybind.Toggled = Bool
            elseif Keybind.Mode == "Always" then
                Keybind.Toggled = true
            end

            Library.Flags[Data.Flag] = {
                Mode = Keybind.Mode,
                Key = Keybind.Key,
                Toggled = Keybind.Toggled
            }

            if Data.Callback then 
                Library:SafeCall(Data.Callback, Keybind.Toggled)
            end

            Update()
        end

        Items["KeyButton"]:Connect("MouseButton1Click", function()
            if Keybind.Picking then 
                return
            end

            Keybind.Picking = true

            Items["Text"]:Tween(nil, {TextColor3 = Library.Theme.Accent})
            Items["Text"]:ChangeItemTheme({TextColor3 = "Accent"})

            local InputBegan 
            InputBegan = UserInputService.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.Keyboard then 
                    Keybind:Set(Input.KeyCode)
                else
                    Keybind:Set(Input.UserInputType)
                end

                InputBegan:Disconnect()
                InputBegan = nil
            end)
        end)

        Items["KeyButton"]:Connect("MouseButton2Down", function()
            Keybind:SetOpen(not Keybind.IsOpen)
        end)

        Library:Connect(UserInputService.InputBegan, function(Input)
            if tostring(Input.KeyCode) == Keybind.Key or tostring(Input.UserInputType) == Keybind.Key then
                if Keybind.Mode == "Toggle" then 
                    Keybind:Press()
                elseif Keybind.Mode == "Hold" then 
                    Keybind:Press(true)
                end
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                if not Keybind.IsOpen then 
                    return 
                end

                if Library:IsMouseOverFrame(Items["Window"]) then
                    return
                end

                Keybind:SetOpen(false)
            end
        end)

        Library:Connect(UserInputService.InputEnded, function(Input)
            if tostring(Input.KeyCode) == Keybind.Key or tostring(Input.UserInputType) == Keybind.Key then
                if Keybind.Mode == "Hold" then 
                    Keybind:Press(false)
                end
            end
        end)

        Items["Toggle"]:Connect("MouseButton1Down", function()
            Keybind.Mode = "Toggle"
            Keybind:SetMode("Toggle")
        end)

        Items["Always"]:Connect("MouseButton1Down", function()
            Keybind.Mode = "Always"
            Keybind:SetMode("Always")
        end)

        Items["Hold"]:Connect("MouseButton1Down", function()
            Keybind.Mode = "Hold"
            Keybind:SetMode("Hold")
        end)

        if Data.Default then 
            Keybind:Set({
                Key = Data.Default,
                Mode = Data.Mode or "Toggle"
            })
        end

        Library.SetFlags[Data.Flag] = function(Value)
            Keybind:Set(Value)
        end

        return Keybind
    end

    Library.Window = function(self, Data)
        Data = Data or { }

        local Window = {
            Name = Data.Name or Data.name or "Window",
            GameName = Data.GameName or Data.gamename or Data.SubTitle or Data.subtitle or "",
            Size = Data.Size or Data.size or UDim2New(0, 500, 0, 600),

            FadeSpeed = Data.FadeSpeed or Data.fadespeed or 0.25,

            Pages = { },
            SubPages = { },
            Elements = { },

            IsOpen = true
        }

        local Items = { } do 
            Items["MainFrame"] = Instances:Create("Frame", {
                Parent = Library.Holder.Instance,
                AnchorPoint = Vector2New(0, 0),
                Name = "\0",
                Position = UDim2New(0, 0, 0, 0),
                BorderColor3 = FromRGB(10, 10, 10),
                Size = Window.Size,
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(18, 18, 18)
            })  Items["MainFrame"]:AddToTheme({BackgroundColor3 = "Background", BorderColor3 = "Border"})

            Items["MainFrame"].Instance.Position = UDim2New(0, Camera.ViewportSize.X / 4, 0, Camera.ViewportSize.Y / 4)

            Items["MainFrame"]:MakeDraggable()
            Items["MainFrame"]:MakeResizeable(Vector2New(Window.Size.X.Offset, Window.Size.Y.Offset), Vector2New(9999, 9999))

            if IsMobile then
                Instances:Create("UIScale", {
                    Parent = Library.Holder.Instance,
                    Scale = 0.7
                })
            end

            -- gamesense: dark nested borders; accent only as a 1px top hairline
            Items["AccentBorder"] = Instances:Create("UIStroke", {
                Parent = Items["MainFrame"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Thickness = 1,
                Name = "\0",
                Color = FromRGB(10, 10, 10)
            })  Items["AccentBorder"]:AddToTheme({Color = "Border"})

            Items["TopAccent"] = Instances:Create("Frame", {
                Parent = Items["MainFrame"].Instance,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 1),
                Position = UDim2New(0, 0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 20,
                BackgroundColor3 = FromRGB(179, 100, 122)
            })  Items["TopAccent"]:AddToTheme({BackgroundColor3 = "Accent"})

            Items["OuterPad"] = Instances:Create("Frame", {
                Parent = Items["MainFrame"].Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                Size = UDim2New(1, -4, 1, -4),
                Position = UDim2New(0, 2, 0, 2),
                BorderSizePixel = 0
            })

            Instances:Create("UIStroke", {
                Parent = Items["OuterPad"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Thickness = 1,
                Name = "\0",
                Color = FromRGB(42, 42, 42)
            }):AddToTheme({Color = "Outline"})
            
            Items["Title"] = Instances:Create("TextLabel", {
                Parent = Items["MainFrame"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Window.Name,
                Name = "\0",
                Visible = false,
                Size = UDim2New(0.5, -10, 0, 1),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2New(0, 6, 0, 0),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Title"]:AddToTheme({TextColor3 = "Text"})

            Items["GameName"] = Instances:Create("TextLabel", {
                Parent = Items["MainFrame"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Window.GameName or "",
                Name = "\0",
                Visible = false,
                AnchorPoint = Vector2New(1, 0),
                Size = UDim2New(0.5, -10, 0, 1),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2New(1, -6, 0, 0),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["GameName"]:AddToTheme({TextColor3 = "Text"})
            
            Items["Inline"] = Instances:Create("Frame", {
                Parent = Items["OuterPad"].Instance,
                Name = "\0",
                Position = UDim2New(0, 4, 0, 4),
                BorderColor3 = FromRGB(27, 27, 32),
                Size = UDim2New(1, -8, 1, -8),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(23, 23, 23)
            })  Items["Inline"]:AddToTheme({BackgroundColor3 = "Inline", BorderColor3 = "Outline"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Inline"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Color = Library.Theme.Outline,
                Name = "\0"
            }):AddToTheme({Color = "Outline"})
            
            Items["Pages"] = Instances:Create("Frame", {
                Parent = Items["Inline"].Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                Position = UDim2New(0, 4, 0, 4),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, -8, 0, 22),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })
            
            Instances:Create("UIListLayout", {
                Parent = Items["Pages"].Instance,
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalFlex = Enum.UIFlexAlignment.None,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDimNew(0, 0),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            Items["TabLine"] = Instances:Create("Frame", {
                Parent = Items["Inline"].Instance,
                Name = "\0",
                Position = UDim2New(0, 4, 0, 26),
                Size = UDim2New(1, -8, 0, 1),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(42, 42, 42)
            })  Items["TabLine"]:AddToTheme({BackgroundColor3 = "Outline"})

            Items["Content"] = Instances:Create("Frame", {
                Parent = Items["Inline"].Instance,
                Name = "\0",
                Position = UDim2New(0, 4, 0, 28),
                BorderColor3 = FromRGB(10, 10, 10),
                Size = UDim2New(1, -8, 1, -32),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(18, 18, 18)
            })  Items["Content"]:AddToTheme({BackgroundColor3 = "Background", BorderColor3 = "Border"})
        
            Instances:Create("UIStroke", {
                Parent = Items["Content"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Color = Library.Theme.Outline,
                Name = "\0"
            }):AddToTheme({Color = "Outline"})

            if IsMobile then
                Items["FloatingButton"] = Instances:Create("TextButton", {
                    Parent = Library.Holder.Instance,
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    Position = UDim2New(0.5, 0, 0, 20),
                    AnchorPoint = Vector2New(0.5, 0),
                    Visible = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 50, 0, 50),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0,
                    ZIndex = 127,
                    BackgroundColor3 = Library.Theme.Background
                })  Items["FloatingButton"]:AddToTheme({BackgroundColor3 = "Background"})

                --
                local Gui = Items["FloatingButton"].Instance

                local Dragging = false 
                local DragStart
                local StartPosition 

                local Set = function(Input)
                    local DragDelta = Input.Position - DragStart
                    Items["FloatingButton"]:Tween(TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(StartPosition.X.Scale, StartPosition.X.Offset + DragDelta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + DragDelta.Y)})
                end

                Items["FloatingButton"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true

                        DragStart = Input.Position
                        StartPosition = Gui.Position

                        Input.Changed:Connect(function()
                            if Input.UserInputState == Enum.UserInputState.End then
                                Dragging = false
                            end
                        end)
                    end
                end)

                Library:Connect(UserInputService.InputChanged, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                        if Dragging then
                            Set(Input)
                        end
                    end
                end)

                Instances:Create("TextLabel", {
                    Parent = Items["FloatingButton"].Instance,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Name = "\0",
                    TextSize = 12,
                    Text = "Close",
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 127,
                    Size = UDim2New(1, -25, 1, -25),
                    BorderSizePixel = 0,
                    TextColor3 = FromRGB(255, 255, 255),
                    FontFace = Library.Font,
                    TextTransparency = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                }):AddToTheme({TextColor3 = "Text"})

                Instances:Create("UICorner", {
                    Parent = Items["FloatingButton"].Instance,
                    CornerRadius = UDimNew(1, 0)
                }) 
            end
        end

        local Debounce = false

        function Window:SetOpen(Bool)
            if Debounce and Bool then 
                return 
            end

            Window.IsOpen = Bool

            Debounce = true 

            if Bool then 
                Items["MainFrame"].Instance.Visible = true
            else
                Library:CloseDropdowns()
            end

            local Descendants = Items["MainFrame"].Instance:GetDescendants()
            TableInsert(Descendants, Items["MainFrame"].Instance)

            local NewTween
            for Index, Value in Descendants do 
                local ValueIndex = Library:GetTransparencyPropertyFromItem(Value)

                if not ValueIndex then 
                    continue
                end

                if type(ValueIndex) == "table" then
                    for _, Property in ValueIndex do 
                        NewTween = Library:FadeItem(Value, Property, Bool, Window.FadeSpeed)
                    end
                else
                    NewTween = Library:FadeItem(Value, ValueIndex, Bool, Window.FadeSpeed)
                end
            end

            Library:AfterFade(NewTween, function()
                Debounce = false
                Items["MainFrame"].Instance.Visible = Bool
                if Bool then
                    for _, Page in Window.Pages do
                        if not Page.HasSubtabs then
                            continue
                        end
                        for _, SubPage in Page.SubPages do
                            local SubItems = SubPage.Elements
                            local Text = SubItems and SubItems["Text"] and SubItems["Text"].Instance
                            local Hide = SubItems and SubItems["Hide"] and SubItems["Hide"].Instance
                            local Inactive = SubItems and SubItems["Inactive"] and SubItems["Inactive"].Instance
                            if SubPage.Active then
                                if Text then
                                    Text.TextTransparency = 0
                                    Text.TextColor3 = FromRGB(235, 235, 235)
                                end
                                if Hide then
                                    Hide.Visible = true
                                    Hide.BackgroundColor3 = Library.Theme.Accent
                                end
                                if Inactive then
                                    Inactive.BackgroundTransparency = 1
                                end
                            else
                                if Text then
                                    Text.TextTransparency = 0.35
                                    Text.TextColor3 = Library.Theme.Text
                                end
                                if Hide then
                                    Hide.Visible = false
                                end
                                if Inactive then
                                    Inactive.BackgroundTransparency = 1
                                end
                            end
                        end
                    end
                end
            end)
        end

        Library:Connect(UserInputService.InputBegan, function(Input)
            if tostring(Input.KeyCode) == Library.MenuKeybind or tostring(Input.UserInputType) == Library.MenuKeybind then
                Window:SetOpen(not Window.IsOpen)
            end
        end)

        if IsMobile then
            Items["FloatingButton"]:Connect("MouseButton1Down", function()
                Window:SetOpen(not Window.IsOpen)
            end)
        end

        function Window:SetGameName(Name)
            Window.GameName = tostring(Name or "")
            if Items["GameName"] and Items["GameName"].Instance then
                Items["GameName"].Instance.Text = Window.GameName
            end
        end

        Window.Elements = Items

        return setmetatable(Window, Library)
    end

    Library.Page = function(self, Data)
        Data = Data or { }

        local Page = {
            Window = self,

            Name = Data.Name or Data.name or "Page",
            Columns = Data.Columns or Data.columns or 2,

            HasSubtabs = Data.Subtabs or Data.subtabs or false,

            Active = false,
            ColumnsData = { },
            Elements = { },
            SubPages = { },
        }

        local Items = { } do 
            local PageTabWidth = math.max(44, (#Page.Name * 7) + 20)

            Items["Inactive"] = Instances:Create("TextButton", {
                Parent = Page.Window.Elements["Pages"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(0, 0, 0),
                BorderColor3 = FromRGB(10, 10, 10),
                Text = "",
                AutoButtonColor = false,
                Name = "\0",
                Size = UDim2New(0, PageTabWidth, 1, 0),
                BorderSizePixel = 0,
                TextSize = 14,
                BackgroundTransparency = 1,
                BackgroundColor3 = FromRGB(28, 28, 28)
            })

            Instances:Create("UIStroke", {
                Parent = Items["Inactive"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Color = Library.Theme.Outline,
                Name = "\0",
                Enabled = false
            }):AddToTheme({Color = "Outline"})
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Inactive"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(160, 160, 160),
                TextTransparency = 0.2,
                Text = Page.Name,
                Name = "\0",
                Size = UDim2New(1, 0, 1, -2),
                BackgroundTransparency = 1,
                Position = UDim2New(0, 0, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = FromRGB(0, 0, 0),
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Text"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Enabled = false
            }):AddToTheme({Color = "Text Border"})
            
            -- accent underline under active tab text
            Items["Hide"] = Instances:Create("Frame", {
                Parent = Items["Inactive"].Instance,
                Visible = false,
                BorderColor3 = FromRGB(0, 0, 0),
                AnchorPoint = Vector2New(0, 1),
                Name = "\0",
                Position = UDim2New(0, 4, 1, 0),
                Size = UDim2New(1, -8, 0, 1),
                ZIndex = 3,
                BorderSizePixel = 0,
                BackgroundColor3 = Library.Theme.Accent
            })  Items["Hide"]:AddToTheme({BackgroundColor3 = "Accent"})
            
            Items["MiscPixel1"] = Instances:Create("Frame", {
                Parent = Items["Hide"].Instance,
                Visible = false,
                Size = UDim2New(0, 1, 0, 1),
                Name = "\0",
                BorderSizePixel = 0,
                BackgroundTransparency = 1
            })
            
            Items["MiscPixel2"] = Instances:Create("Frame", {
                Parent = Items["Hide"].Instance,
                Visible = false,
                Size = UDim2New(0, 1, 0, 1),
                Name = "\0",
                BorderSizePixel = 0,
                BackgroundTransparency = 1
            })

            Items["Sep"] = Instances:Create("Frame", {
                Parent = Items["Inactive"].Instance,
                AnchorPoint = Vector2New(1, 0.5),
                Position = UDim2New(1, 0, 0.5, 0),
                Size = UDim2New(0, 1, 0, 10),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(42, 42, 42),
                ZIndex = 2
            })  Items["Sep"]:AddToTheme({BackgroundColor3 = "Outline"})
            
            Items["UIGradient"] = Instances:Create("UIGradient", {
                Parent = Items["Inactive"].Instance,
                Rotation = 90,
                Enabled = false,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(140, 140, 140))}
            })            

            Items["Page"] = Instances:Create("Frame", {
                Parent = Page.Window.Elements["Content"].Instance,
                BackgroundTransparency = 1,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255),
                Visible = false
            })
            
            if not Page.HasSubtabs then 
                Instances:Create("UIListLayout", {
                    Parent = Items["Page"].Instance,
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalFlex = Enum.UIFlexAlignment.Fill
                })
                
                for Index = 1, Page.Columns do
                    local NewColumn = Instances:Create("ScrollingFrame", {
                        Parent = Items["Page"].Instance,
                        ScrollBarImageColor3 = FromRGB(235, 157, 255),
                        Active = true,
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        ScrollBarThickness = 1,
                        Name = "\0",
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 100, 0, 100),
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        BottomImage = Library:GetImage("Scrollbar"),
                        MidImage = Library:GetImage("Scrollbar"),
                        TopImage = Library:GetImage("Scrollbar"),
                        CanvasSize = UDim2New(0, 0, 0, 0)
                    })  NewColumn:AddToTheme({ScrollBarImageColor3 = "Accent"})
                    
                    -- extra top pad so groupbox titles on the border are not clipped
                    Instances:Create("UIPadding", {
                        Parent = NewColumn.Instance,
                        PaddingTop = UDimNew(0, 12),
                        PaddingBottom = UDimNew(0, 6),
                        PaddingRight = UDimNew(0, 6),
                        PaddingLeft = UDimNew(0, 6)
                    })
                    
                    Instances:Create("UIListLayout", {
                        Parent = NewColumn.Instance,
                        Padding = UDimNew(0, 10),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }) 

                    Page.ColumnsData[Index] = NewColumn
                end
            else
                Items["Columns"] = Instances:Create("Frame", {
                    Parent = Items["Page"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 4, 0, 28),
                    BorderColor3 = FromRGB(10, 10, 10),
                    Size = UDim2New(1, -8, 1, -32),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(18, 18, 18)
                })

                Items["SubTabs"] = Instances:Create("Frame", {
                    Parent = Items["Page"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 6, 0, 4),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -12, 0, 20),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                Items["SubTabs"].Instance:SetAttribute("haze_nofade", true)

                Items["SubTabLine"] = Instances:Create("Frame", {
                    Parent = Items["Page"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 4, 0, 24),
                    Size = UDim2New(1, -8, 0, 1),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(42, 42, 42)
                })  Items["SubTabLine"]:AddToTheme({BackgroundColor3 = "Outline"})

                Instances:Create("UIListLayout", {
                    Parent = Items["SubTabs"].Instance,
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.None,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    Padding = UDimNew(0, 14),
                    SortOrder = Enum.SortOrder.LayoutOrder
                }) 
            end
        end

        local Debounce = false

        function Page:Turn(Bool)
            if Debounce and Bool then 
                return 
            end

            Page.Active = Bool

            Debounce = true 

            if Bool then 
                Items["Page"].Instance.Visible = true
                Items["Text"]:Tween(nil, {TextColor3 = FromRGB(235, 235, 235), TextTransparency = 0})
                Items["Hide"].Instance.Visible = true
                Items["Hide"].Instance.BackgroundColor3 = Library.Theme.Accent
                Items["Text"]:ChangeItemTheme({TextColor3 = "Text"})
            else
                Items["Text"]:Tween(nil, {TextColor3 = Library.Theme.Text, TextTransparency = 0.35})
                Items["Hide"].Instance.Visible = false
                Items["Text"]:ChangeItemTheme({TextColor3 = "Text"})
                Library:CloseDropdowns()
            end

            local SubTabsRoot = Items["SubTabs"] and Items["SubTabs"].Instance
            local Descendants = Items["Page"].Instance:GetDescendants()
            TableInsert(Descendants, Items["Page"].Instance)

            local NewTween
            for Index, Value in Descendants do 
                -- Subtab icons use partial ImageTransparency; fading them washes to 1 permanently.
                if SubTabsRoot and (Value == SubTabsRoot or Value:IsDescendantOf(SubTabsRoot)) then
                    continue
                end

                local ValueIndex = Library:GetTransparencyPropertyFromItem(Value)

                if not ValueIndex then 
                    continue
                end

                if type(ValueIndex) == "table" then
                    for _, Property in ValueIndex do 
                        NewTween = Library:FadeItem(Value, Property, Bool, Page.Window.FadeSpeed or 0.5)
                    end
                else
                    NewTween = Library:FadeItem(Value, ValueIndex, Bool, Page.Window.FadeSpeed or 0.5)
                end
            end

            local function RefreshSubTabIcons()
                if not Page.HasSubtabs then
                    return
                end
                for _, SubPage in Page.SubPages do
                    local SubItems = SubPage.Elements
                    local Text = SubItems and SubItems["Text"] and SubItems["Text"].Instance
                    local Hide = SubItems and SubItems["Hide"] and SubItems["Hide"].Instance
                    local Inactive = SubItems and SubItems["Inactive"] and SubItems["Inactive"].Instance
                    if SubPage.Active then
                        if Text then
                            Text.TextTransparency = 0
                            Text.TextColor3 = FromRGB(235, 235, 235)
                        end
                        if Hide then
                            Hide.Visible = true
                            Hide.BackgroundColor3 = Library.Theme.Accent
                        end
                        if Inactive then
                            Inactive.BackgroundTransparency = 1
                        end
                    else
                        if Text then
                            Text.TextTransparency = 0.35
                            Text.TextColor3 = Library.Theme.Text
                        end
                        if Hide then
                            Hide.Visible = false
                        end
                        if Inactive then
                            Inactive.BackgroundTransparency = 1
                        end
                    end
                end
            end

            if Bool then
                RefreshSubTabIcons()
            end

            Library:AfterFade(NewTween, function()
                Debounce = false
                Items["Page"].Instance.Visible = Bool
                if Bool then
                    RefreshSubTabIcons()
                end
            end)
        end

        Items["Inactive"]:Connect("MouseButton1Down", function()
            for Index, Value in Page.Window.Pages do
                Value:Turn(Value == Page)
            end
        end)

        if #Page.Window.Pages == 0 then 
            Page:Turn(true)
        end

        Page.Elements = Items

        TableInsert(Page.Window.Pages, Page)
        return setmetatable(Page, Library.Pages)
    end

    Library.Pages.SubPage = function(self, Data)
        Data = Data or { }

        local SubPage = {
            Window = self.Window,
            Page = self,

            Name = Data.Name or Data.name or Data.TabName or Data.tabname or "Tab",
            Icon = Data.Icon or Data.icon or "9080568477801",
            Columns = Data.Columns or Data.columns or 2,

            Active = false,
            ColumnsData = { },
            Elements = { }
        }

        local TabWidth = math.max(44, (#SubPage.Name * 7) + 8)

        local Items = { } do
            Items["Inactive"] = Instances:Create("TextButton", {
                Parent = SubPage.Page.Elements["SubTabs"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(0, 0, 0),
                BorderColor3 = FromRGB(10, 10, 10),
                Text = "",
                AutoButtonColor = false,
                Name = "\0",
                Size = UDim2New(0, TabWidth, 1, 0),
                BorderSizePixel = 0,
                TextSize = 14,
                BackgroundTransparency = 1,
                BackgroundColor3 = FromRGB(28, 28, 28)
            })
            Items["Inactive"].Instance:SetAttribute("haze_nofade", true)

            Instances:Create("UIStroke", {
                Parent = Items["Inactive"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(42, 42, 42),
                Enabled = false
            }):AddToTheme({Color = "Outline"})

            Items["Hide"] = Instances:Create("Frame", {
                Parent = Items["Inactive"].Instance,
                Visible = false,
                BorderColor3 = FromRGB(0, 0, 0),
                AnchorPoint = Vector2New(0, 1),
                Name = "\0",
                Position = UDim2New(0, 0, 1, 0),
                Size = UDim2New(1, 0, 0, 1),
                ZIndex = 5,
                BorderSizePixel = 0,
                BackgroundColor3 = Library.Theme.Accent
            })  Items["Hide"]:AddToTheme({BackgroundColor3 = "Accent"})

            Items["MiscPixel1"] = Instances:Create("Frame", {
                Parent = Items["Hide"].Instance,
                Size = UDim2New(0, 1, 0, 1),
                Name = "\0",
                Position = UDim2New(0, -1, 0, 1),
                BorderColor3 = FromRGB(0, 0, 0),
                ZIndex = 5,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                BackgroundColor3 = FromRGB(27, 27, 32)
            }) 

            Items["MiscPixel2"] = Instances:Create("Frame", {
                Parent = Items["Hide"].Instance,
                BorderColor3 = FromRGB(0, 0, 0),
                AnchorPoint = Vector2New(1, 0),
                Name = "\0",
                Position = UDim2New(1, 1, 0, 1),
                Size = UDim2New(0, 1, 0, 1),
                ZIndex = 5,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                BackgroundColor3 = FromRGB(27, 27, 32)
            }) 

            Items["Icon"] = Instances:Create("ImageLabel", {
                Parent = Items["Inactive"].Instance,
                ScaleType = Enum.ScaleType.Fit,
                ImageTransparency = 1,
                BorderColor3 = FromRGB(0, 0, 0),
                Name = "\0",
                Visible = false,
                AnchorPoint = Vector2New(0.5, 0.5),
                Image = "rbxassetid://"..SubPage.Icon,
                BackgroundTransparency = 1,
                Position = UDim2New(0.5, 0, 0.5, 0),
                Size = UDim2New(0, 30, 0, 30),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })

            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Inactive"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(160, 160, 160),
                TextTransparency = 0.2,
                Text = SubPage.Name,
                Name = "\0",
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 1, -2),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
            Items["Text"].Instance:SetAttribute("haze_nofade", true)

            Instances:Create("UIGradient", {
                Parent = Items["Inactive"].Instance,
                Rotation = 90,
                Enabled = false,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(140, 140, 140))}
            }) 

            Items["Subtab"] = Instances:Create("Frame", {
                Parent = SubPage.Page.Elements["Columns"].Instance,
                BackgroundTransparency = 1,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 

            Instances:Create("UIPadding", {
                Parent = Items["Subtab"].Instance,
                PaddingTop = UDimNew(0, 6),
                PaddingRight = UDimNew(0, 6),
                PaddingLeft = UDimNew(0, 6)
            }) 

            Instances:Create("UIListLayout", {
                Parent = Items["Subtab"].Instance,
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalFlex = Enum.UIFlexAlignment.Fill,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalFlex = Enum.UIFlexAlignment.Fill
            }) 

            for Index = 1, SubPage.Columns do
                local NewColumn = Instances:Create("ScrollingFrame", {
                    Parent = Items["Subtab"].Instance,
                    ScrollBarImageColor3 = FromRGB(235, 157, 255),
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 1,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 100, 0, 100),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                })  NewColumn:AddToTheme({ScrollBarImageColor3 = "Accent"})

                Instances:Create("UIPadding", {
                    Parent = NewColumn.Instance,
                    PaddingTop = UDimNew(0, 12),
                    PaddingBottom = UDimNew(0, 6),
                    PaddingRight = UDimNew(0, 6),
                    PaddingLeft = UDimNew(0, 6)
                }) 

                Instances:Create("UIListLayout", {
                    Parent = NewColumn.Instance,
                    Padding = UDimNew(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder
                }) 

                SubPage.ColumnsData[Index] = NewColumn
            end
        end

        local Debounce = false

        function SubPage:Turn(Bool)
            if Debounce and Bool then 
                return 
            end

            SubPage.Active = Bool

            Debounce = true 

            if Bool then 
                Items["Subtab"].Instance.Visible = true
                Items["Hide"].Instance.Visible = true
                Items["Hide"].Instance.BackgroundColor3 = Library.Theme.Accent
                if Items["Text"] then
                    Items["Text"]:Tween(nil, {TextColor3 = FromRGB(235, 235, 235), TextTransparency = 0})
                    Items["Text"]:ChangeItemTheme({TextColor3 = "Text"})
                end
            else
                Items["Hide"].Instance.Visible = false
                if Items["Text"] then
                    Items["Text"]:Tween(nil, {TextColor3 = Library.Theme.Text, TextTransparency = 0.35})
                    Items["Text"]:ChangeItemTheme({TextColor3 = "Text"})
                end
            end

            Items["Subtab"].Instance.Visible = Bool
            task.delay(SubPage.Window.FadeSpeed or 0.25, function()
                Debounce = false
                Items["Subtab"].Instance.Visible = Bool
            end)
        end

        Items["Inactive"]:Connect("MouseButton1Down", function()
            local Group = SubPage.Page.SubPages
            if not Group or #Group == 0 then
                Group = SubPage.Window.SubPages
            end
            for Index, Value in Group do
                Value:Turn(Value == SubPage)
            end
        end)

        if #SubPage.Page.SubPages == 0 then 
            SubPage:Turn(true)
        end

        SubPage.Elements = Items

        TableInsert(SubPage.Page.SubPages, SubPage)
        TableInsert(SubPage.Window.SubPages, SubPage)
        return setmetatable(SubPage, Library.Pages)
    end

    Library.Pages.Section = function(self, Data)
        Data = Data or { }

        local Section = {
            Window = self.Window,
            Page = self,

            Name = Data.Name or Data.name or "Section",
            Side = Data.Side or Data.side or 1,

            Elements = { }
        }

        local Items = { } do
            local TitleWidth = math.max(28, (#Section.Name * 7) + 12)

            Items["Section"] = Instances:Create("Frame", {
                Parent = Section.Page.ColumnsData[Section.Side].Instance,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 25),
                BorderColor3 = FromRGB(42, 42, 42),
                BorderSizePixel = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = false,
                BackgroundColor3 = FromRGB(17, 17, 17)
            })  Items["Section"]:AddToTheme({BackgroundColor3 = "Inline", BorderColor3 = "Outline"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Section"].Instance,
                Color = FromRGB(42, 42, 42),
                Thickness = 1,
                Name = "\0",
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }):AddToTheme({Color = "Outline"})
            
            Instances:Create("UIPadding", {
                Parent = Items["Section"].Instance,
                PaddingTop = UDimNew(0, 4),
                PaddingBottom = UDimNew(0, 6)
            })
            
            Items["AccentLine"] = Instances:Create("Frame", {
                Parent = Items["Section"].Instance,
                Name = "\0",
                Visible = false,
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 1),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(235, 157, 255)
            })  Items["AccentLine"]:AddToTheme({BackgroundColor3 = "Accent"})
            
            Instances:Create("UIGradient", {
                Parent = Items["AccentLine"].Instance,
                Rotation = 90,
                Enabled = false,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(65, 65, 65))}
            })

            -- gamesense-style title sitting on the top border
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Section"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Section.Name,
                Name = "\0",
                Size = UDim2New(0, TitleWidth, 0, 14),
                BackgroundTransparency = 0,
                TextXAlignment = Enum.TextXAlignment.Center,
                Position = UDim2New(0, 8, 0, -7),
                BorderSizePixel = 0,
                ZIndex = 3,
                TextSize = 12,
                BackgroundColor3 = FromRGB(17, 17, 17)
            })  Items["Text"]:AddToTheme({TextColor3 = "Text", BackgroundColor3 = "Inline"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Text"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Enabled = false
            }):AddToTheme({Color = "Text Border"})
            
            Items["Content"] = Instances:Create("Frame", {
                Parent = Items["Section"].Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                Position = UDim2New(0, 7, 0, 12),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, -14, 1, -14),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })
            
            Instances:Create("UIListLayout", {
                Parent = Items["Content"].Instance,
                Padding = UDimNew(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
        end

        Section.Elements = Items

        return setmetatable(Section, Library.Sections)
    end

    Library.Pages.MultiSection = function(self, Data)
        local MultiSection = {
            Window = self.Window,
            Page = self,

            Name = Data.Name or Data.name or nil,
            Sections = Data.Sections or Data.sections or { "Section 1", "Section 2", "Section 3" },
            Side = Data.Side or Data.side or 1,

            SectionContents = { },

            Elements = { }
        }

        local TabBarY = MultiSection.Name and 14 or 4
        local ContentY = TabBarY + 22

        local Items = { } do
            Items["MultiSection"] = Instances:Create("Frame", {
                Parent = MultiSection.Page.ColumnsData[MultiSection.Side].Instance,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 25),
                BorderColor3 = FromRGB(42, 42, 42),
                BorderSizePixel = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = false,
                BackgroundColor3 = FromRGB(17, 17, 17)
            })  Items["MultiSection"]:AddToTheme({BackgroundColor3 = "Inline", BorderColor3 = "Outline"})

            Instances:Create("UIStroke", {
                Parent = Items["MultiSection"].Instance,
                Color = FromRGB(42, 42, 42),
                Thickness = 1,
                Name = "\0",
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }):AddToTheme({Color = "Outline"})

            Instances:Create("UIPadding", {
                Parent = Items["MultiSection"].Instance,
                PaddingTop = UDimNew(0, MultiSection.Name and 4 or 0),
                PaddingBottom = UDimNew(0, 6)
            })

            Items["AccentLine"] = Instances:Create("Frame", {
                Parent = Items["MultiSection"].Instance,
                Name = "\0",
                Visible = false,
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 1),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(235, 157, 255)
            })  Items["AccentLine"]:AddToTheme({BackgroundColor3 = "Accent"})

            if MultiSection.Name then
                local TitleWidth = math.max(28, (#MultiSection.Name * 7) + 12)
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["MultiSection"].Instance,
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(215, 215, 215),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = MultiSection.Name,
                    Name = "\0",
                    Size = UDim2New(0, TitleWidth, 0, 14),
                    BackgroundTransparency = 0,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Position = UDim2New(0, 8, 0, -7),
                    BorderSizePixel = 0,
                    ZIndex = 3,
                    TextSize = 12,
                    BackgroundColor3 = FromRGB(17, 17, 17)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text", BackgroundColor3 = "Inline"})
            end

            Items["Sections"] = Instances:Create("Frame", {
                Parent = Items["MultiSection"].Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                Position = UDim2New(0, 6, 0, TabBarY),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, -12, 0, 18),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })

            Instances:Create("UIListLayout", {
                Parent = Items["Sections"].Instance,
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalFlex = Enum.UIFlexAlignment.None,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                Padding = UDimNew(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            Items["TabLine"] = Instances:Create("Frame", {
                Parent = Items["MultiSection"].Instance,
                Name = "\0",
                Position = UDim2New(0, 6, 0, TabBarY + 18),
                Size = UDim2New(1, -12, 0, 1),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(42, 42, 42)
            })  Items["TabLine"]:AddToTheme({BackgroundColor3 = "Outline"})

            Items["Content"] = Instances:Create("Frame", {
                Parent = Items["MultiSection"].Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                Position = UDim2New(0, 7, 0, ContentY),
                BorderColor3 = FromRGB(10, 10, 10),
                Size = UDim2New(1, -14, 1, -(ContentY - 2)),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(15, 15, 20)
            })
        end

        for Index, Value in MultiSection.Sections do
            local NewSection = {
                Window = MultiSection.Window,
                Page = MultiSection.Page,
                MultiSection = MultiSection,

                Name = Value,

                Elements = { },

                Active = false,
            }

            local TabWidth = math.max(40, (#NewSection.Name * 7) + 8)

            local SubItems = { } do
                SubItems["Inactive"] = Instances:Create("TextButton", {
                    Parent = Items["Sections"].Instance,
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(10, 10, 10),
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    Size = UDim2New(0, TabWidth, 1, 0),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(28, 28, 28)
                })

                SubItems["Text"] = Instances:Create("TextLabel", {
                    Parent = SubItems["Inactive"].Instance,
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(160, 160, 160),
                    TextTransparency = 0.35,
                    Text = NewSection.Name,
                    Name = "\0",
                    Size = UDim2New(1, 0, 1, -2),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 0),
                    BorderSizePixel = 0,
                    BorderColor3 = FromRGB(0, 0, 0),
                    TextSize = 12,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  SubItems["Text"]:AddToTheme({TextColor3 = "Text"})

                Instances:Create("UIStroke", {
                    Parent = SubItems["Text"].Instance,
                    LineJoinMode = Enum.LineJoinMode.Miter,
                    Name = "\0",
                    Enabled = false
                }):AddToTheme({Color = "Text Border"})

                SubItems["Hide"] = Instances:Create("Frame", {
                    Parent = SubItems["Inactive"].Instance,
                    Visible = false,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    Name = "\0",
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 1),
                    ZIndex = 5,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Library.Theme.Accent
                })  SubItems["Hide"]:AddToTheme({BackgroundColor3 = "Accent"})

                SubItems["Content"] = Instances:Create("Frame", {
                    Parent = Items["Content"].Instance,
                    BackgroundTransparency = 1,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    Visible = false,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = SubItems["Content"].Instance,
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            local Debounce = false

            function NewSection:Turn(Bool)
                if Debounce then
                    return
                end

                NewSection.Active = Bool

                Debounce = true

                if Bool then
                    SubItems["Content"].Instance.Visible = true
                    SubItems["Hide"].Instance.Visible = true
                    SubItems["Hide"].Instance.BackgroundColor3 = Library.Theme.Accent
                    SubItems["Text"]:Tween(nil, {TextColor3 = FromRGB(235, 235, 235), TextTransparency = 0})
                    SubItems["Text"]:ChangeItemTheme({TextColor3 = "Text"})
                else
                    SubItems["Hide"].Instance.Visible = false
                    SubItems["Text"]:Tween(nil, {TextColor3 = Library.Theme.Text, TextTransparency = 0.35})
                    SubItems["Text"]:ChangeItemTheme({TextColor3 = "Text"})
                end

                local Descendants = SubItems["Content"].Instance:GetDescendants()
                TableInsert(Descendants, SubItems["Content"].Instance)

                local NewTween
                for Index, Value in Descendants do
                    local ValueIndex = Library:GetTransparencyPropertyFromItem(Value)

                    if not ValueIndex then
                        continue
                    end

                    if type(ValueIndex) == "table" then
                        for _, Property in ValueIndex do
                            NewTween = Library:FadeItem(Value, Property, Bool, MultiSection.Window.FadeSpeed or 0.5)
                        end
                    else
                        NewTween = Library:FadeItem(Value, ValueIndex, Bool, MultiSection.Window.FadeSpeed or 0.5)
                    end
                end

                if NewTween and NewTween.Tween then
                    Library:Connect(NewTween.Tween.Completed, function()
                        Debounce = false
                        SubItems["Content"].Instance.Visible = Bool
                    end)
                else
                    Debounce = false
                    SubItems["Content"].Instance.Visible = Bool
                end
            end

            SubItems["Inactive"]:Connect("MouseButton1Down", function()
                for Index, Value in MultiSection.SectionContents do
                    Value:Turn(Value == NewSection)
                end
            end)

            if #MultiSection.SectionContents == 0 then
                NewSection:Turn(true)
            end

            NewSection.Elements = SubItems

            MultiSection.SectionContents[#MultiSection.SectionContents+1] = setmetatable(NewSection, Library.Sections)
        end

        MultiSection.SectionContents[1]:Turn(true)
        MultiSection.Window.Sections[#MultiSection.Window.Sections+1] = MultiSection
        return TableUnpack(MultiSection.SectionContents)
    end

    Library.Pages.ScrollableSection = function(self, Data)
        Data = Data or { }

        local Section = {
            Window = self.Window,
            Page = self,

            Name = Data.Name or Data.name or "Section",
            Side = Data.Side or Data.side or 1,
            Size = Data.Size or Data.size or 175,

            Elements = { }
        }

        local Items = { } do 
            Items["Section"] = Instances:Create("Frame", {
                Parent = Section.Page.ColumnsData[Section.Side].Instance,
                Name = "\0",
                Size = UDim2New(1, 0, 0, Section.Size),
                BorderColor3 = FromRGB(27, 27, 32),
                BorderSizePixel = 2,
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = FromRGB(20, 20, 25)
            })  Items["Section"]:AddToTheme({BackgroundColor3 = "Inline", BorderColor3 = "Outline"})

            Items["Fade"] = Instances:Create("Frame", {
                Parent = Items["Section"].Instance,
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 20),
                AnchorPoint = Vector2New(0, 1),
                Position = UDim2New(0, 0, 1, 2),
                BorderSizePixel = 0,
                ZIndex = 15,
                BackgroundColor3 = FromRGB(27, 27, 32)
            })  Items["Fade"]:AddToTheme({BackgroundColor3 = "Inline"})

            Instances:Create("UIGradient", {
                Parent = Items["Fade"].Instance,
                Rotation = -90,
                Transparency = NumSequence{NumSequenceKeypoint(0, 0), NumSequenceKeypoint(0.718, 0.768750011920929), NumSequenceKeypoint(1, 1)}
            })
            
            Instances:Create("UIStroke", {
                Parent = Items["Section"].Instance,
                Color = FromRGB(10, 10, 10),
                Name = "\0",
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }):AddToTheme({Color = "Border"})
            
            Instances:Create("UIPadding", {
                Parent = Items["Section"].Instance,
                PaddingBottom = UDimNew(0, 6)
            })
            
            Items["AccentLine"] = Instances:Create("Frame", {
                Parent = Items["Section"].Instance,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 2),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(235, 157, 255)
            })  Items["AccentLine"]:AddToTheme({BackgroundColor3 = "Accent"})
            
            Instances:Create("UIGradient", {
                Parent = Items["AccentLine"].Instance,
                Rotation = 90,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(65, 65, 65))}
            })
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Section"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Section.Name,
                Name = "\0",
                Size = UDim2New(1, -12, 0, 15),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2New(0, 4, 0, 2),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Text"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})
            
            Items["Content"] = Instances:Create("ScrollingFrame", {
                Parent = Items["Section"].Instance,
                Name = "\0",
                ScrollBarThickness = 3,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                CanvasSize = UDim2New(0, 0, 0, 0),
                ScrollBarImageColor3 = FromRGB(235, 157, 255),
                MidImage = Library:GetImage("Scrollbar"),
                TopImage = Library:GetImage("Scrollbar"),
                BottomImage = Library:GetImage("Scrollbar"),
                Active = true,
                BackgroundTransparency = 1,
                ZIndex = 16,
                Position = UDim2New(0, 0, 0, 21),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, -5, 1, -20),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Content"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

            Instances:Create("UIPadding", {
                Parent = Items["Content"].Instance,
                PaddingTop = UDimNew(0, 0),
                PaddingBottom = UDimNew(0, 8),
                PaddingRight = UDimNew(0, 11),
                PaddingLeft = UDimNew(0, 8)
            })
            
            Instances:Create("UIListLayout", {
                Parent = Items["Content"].Instance,
                Padding = UDimNew(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
        end

        Section.Elements = Items

        return setmetatable(Section, Library.Sections)
    end

    Library.Sections.Divider = function(self)
        local Divider = {
            Window = self.Window,
            Page = self.Page,
            Section = self,
        }

        local Items = { } do
            Items["Divider"] = Instances:Create("Frame", {
                Parent = Divider.Section.Elements["Content"].Instance,
                BackgroundTransparency = 1,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 10),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 

            Items["RealDivider"] = Instances:Create("Frame", {
                Parent = Items["Divider"].Instance,
                AnchorPoint = Vector2New(0, 0.5),
                Name = "\0",
                Position = UDim2New(0, 0, 0.5, 0),
                BorderColor3 = FromRGB(10, 10, 10),
                Size = UDim2New(1, 0, 0, 3),
                BorderSizePixel = 2,
                BackgroundColor3 = FromRGB(15, 15, 20)
            })  Items["RealDivider"]:AddToTheme({BackgroundColor3 = "Background", BorderColor3 = "Border"})

            Instances:Create("UIStroke", {
                Parent = Items["RealDivider"].Instance,
                Color = FromRGB(27, 27, 32),
                Name = "\0",
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }):AddToTheme({Color = "Outline"})
        end
        
        function Divider:SetVisibility(Bool)
            Items["Divider"].Instance.Visible = Bool
        end

        return Divider
    end

    Library.Sections.Toggle = function(self, Data)
        Data = Data or { }

        local Toggle = {
            Window = self.Window,
            Page = self.Page,
            Section = self,

            Name = Data.Name or Data.name or "Toggle",
            Flag = Data.Flag or Data.flag or Library:NextFlag(),
            Default = Data.Default or Data.default or false,
            Callback = Data.Callback or Data.callback or function() end,

            Value = false,
            Class = "Toggle",

            Count = 0
        }

        local Items = { } do 
            Items["Toggle"] = Instances:Create("TextButton", {
                Parent = Toggle.Section.Elements["Content"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(0, 0, 0),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Name = "\0",
                Size = UDim2New(1, 0, 0, 11),
                BorderSizePixel = 0,
                TextSize = 14,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Items["Indicator"] = Instances:Create("Frame", {
                Parent = Items["Toggle"].Instance,
                Name = "\0",
                BorderColor3 = FromRGB(40, 40, 40),
                Size = UDim2New(0, 9, 0, 9),
                BorderSizePixel = 1,
                BackgroundColor3 = FromRGB(22, 22, 22)
            })  Items["Indicator"]:AddToTheme({BackgroundColor3 = "Element", BorderColor3 = "Outline"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Indicator"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(50, 50, 50)
            }):AddToTheme({Color = "Outline"})
            
            Instances:Create("UIGradient", {
                Parent = Items["Indicator"].Instance,
                Rotation = 90,
                Enabled = false,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(100, 100, 100))}
            }) 
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Toggle"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                TextTransparency = 0.48,
                Text = Toggle.Name,
                Name = "\0",
                Size = UDim2New(1, 0, 1, 0),
                Position = UDim2New(0, 18, 0, -1),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                BorderColor3 = FromRGB(0, 0, 0),
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Text"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})

            Items["Toggle"]:OnHover(function()
                if Toggle.Value then 
                    return 
                end

                Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library.Theme["Hovered Element"]})
                Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Hovered Element", BorderColor3 = "Border"})
            end)

            Items["Toggle"]:OnHoverLeave(function()
                if Toggle.Value then 
                    return 
                end

                Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library.Theme["Element"]})
                Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Element", BorderColor3 = "Border"})
            end)
        end
        
        function Toggle:Get()
            return Toggle.Value
        end

        function Toggle:Set(Bool)
            if Bool == nil then
                Toggle.Value = not Toggle.Value
            else
                Toggle.Value = Bool and true or false
            end

            Library.Flags[Toggle.Flag] = Toggle.Value

            if Toggle.Value then 
                Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Accent"})

                Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})
                Items["Text"]:Tween(nil, {TextTransparency = 0})
            else
                Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Element"})

                Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
                Items["Text"]:Tween(nil, {TextTransparency = 0.48})
            end

            if Toggle.Callback then 
                Library:SafeCall(Toggle.Callback, Toggle.Value)
            end
        end

        function Toggle:SetVisiblity(Bool)
            Items["Toggle"].Instance.Visible = Bool
        end

        function Toggle:SetVisibility(Bool)
            Toggle:SetVisiblity(Bool)
        end

        function Toggle:Colorpicker(Data)
            Data = Data or { }

            local Colorpicker = {
                Window = self.Window,
                Tab = self.Tab,
                Section = self.Section,

                Parent = Items["Toggle"],
                Name = Data.Name or Data.name or "Colorpicker",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                Callback = Data.Callback or Data.callback or function() end,
                Alpha = Data.Alpha or Data.alpha or false,
                Count = Toggle.Count,

                FadeSpeed = self.Window.FadeSpeed
            }

            Toggle.Count += 1
            Colorpicker.Count = Toggle.Count

            local Extension = Library:CreateColorpicker(Colorpicker)
            Library.Flags[Colorpicker.Flag] = Extension

            return Colorpicker
        end

        function Toggle:Keybind(Data)
            Data = Data or { }

            local Keybind = {
                Window = self.Window,
                Tab = self.Tab,
                Section = self.Section,

                Parent = Items["Toggle"],
                Name = Data.Name or Data.name or "Keybind",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or "MB2",
                Mode = Data.Mode or Data.mode or "Toggle",
                Callback = Data.Callback or Data.callback or function() end,
            }

            local Extension = Library:CreateKeybind(Keybind)
            Library.Flags[Keybind.Flag] = Extension

            return Keybind, Extension
        end

        Items["Toggle"]:Connect("MouseButton1Down", function()
            Toggle:Set()
        end)

        if Toggle.Default ~= nil then 
            Toggle:Set(Toggle.Default)
        end

        Library.SetFlags[Toggle.Flag] = function(Value)
            Toggle:Set(Value)
        end

        return Toggle
    end

    Library.Sections.Button = function(self, Data)
        Data = Data or { }

        local Button = {
            Window = self.Window,
            Page = self.Page,
            Section = self,

            Name = Data.Name or Data.name,
            Callback = Data.Callback or Data.callback or function() end,
        }

        local Items = { } do 
            Items["Button"] = Instances:Create("TextButton", {
                Parent = Button.Section.Elements["Content"].Instance,
                BorderColor3 = FromRGB(42, 42, 42),
                AutoButtonColor = false,
                Name = "\0",
                Position = UDim2New(0, 0, 1, 0),
                Size = UDim2New(1, 0, 0, 16),
                Selectable = false,
                BorderSizePixel = 1,
                BackgroundColor3 = FromRGB(22, 22, 22)
            })  Items["Button"]:AddToTheme({BackgroundColor3 = "Element", BorderColor3 = "Outline"})

            Instances:Create("UIGradient", {
                Parent = Items["Button"].Instance,
                Rotation = 90,
                Enabled = false,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(100, 100, 100))}
            }) 
            
            Instances:Create("UIStroke", {
                Parent = Items["Button"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(42, 42, 42)
            }):AddToTheme({Color = "Outline"}) 
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Button"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Button.Name,
                Name = "\0",
                Size = UDim2New(1, 0, 1, 0),
                BackgroundTransparency = 1,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2New(0, 0, 0, -1),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
            
            Items["TextBorder"] = Instances:Create("UIStroke", {
                Parent = Items["Text"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Enabled = false
            }):AddToTheme({Color = "Text Border"})

            Items["Button"]:OnHover(function()
                Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme["Hovered Element"]})
                Items["Button"]:ChangeItemTheme({BackgroundColor3 = "Hovered Element", BorderColor3 = "Outline"})
            end)

            Items["Button"]:OnHoverLeave(function()
                Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme["Element"]})
                Items["Button"]:ChangeItemTheme({BackgroundColor3 = "Element", BorderColor3 = "Outline"})
            end)
        end

        function Button:Press()
            Library:SafeCall(Button.Callback)

            -- gamesense: brief brighten, never flood the button with Accent
            Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme["Hovered Element"]})
            Items["Text"]:Tween(nil, {TextTransparency = 0})

            task.wait(0.08)

            Items["Button"]:ChangeItemTheme({BackgroundColor3 = "Element", BorderColor3 = "Outline"})
            Items["Text"]:ChangeItemTheme({TextColor3 = "Text"})
            Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
            Items["Text"]:Tween(nil, {TextColor3 = Library.Theme.Text})
        end

        function Button:SetVisiblity(Bool)
            Items["Button"].Instance.Visible = Bool
        end

        Items["Button"]:Connect("MouseButton1Down", function()
            Button:Press()
        end)

        return Button
    end

    Library.Sections.Slider = function(self, Data)
        Data = Data or { }

        local Slider = {
            Window = self.Window,
            Page = self.Page,
            Section = self,

            Name = Data.Name or Data.name or "Slider",
            Flag = Data.Flag or Data.flag or Library:NextFlag(),
            Min = Data.Min or Data.min or 0,
            Default = Data.Default or Data.default or 0,
            Max = Data.Max or Data.max or 100,
            Suffix = Data.Suffix or Data.suffix or "",
            Decimals = Data.Decimals or Data.decimals or 1,
            Callback = Data.Callback or Data.callback or function() end,
            Compact = Data.Compact or Data.compact or false,

            Value = 0,
            Sliding = false,
            Class = "Slider",
        }

        local Items = { } do 
            Items["Slider"] = Instances:Create("Frame", {
                Parent = Slider.Section.Elements["Content"].Instance,
                BackgroundTransparency = 1,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 24),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Slider"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Slider.Name,
                Name = "\0",
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2New(1, -40, 0, 13),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Text"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Enabled = false
            }):AddToTheme({Color = "Text Border"})

            Items["Value"] = Instances:Create("TextLabel", {
                Parent = Items["Slider"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "0",
                Name = "\0",
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Right,
                Position = UDim2New(1, 0, 0, 0),
                AnchorPoint = Vector2New(1, 0),
                Size = UDim2New(0, 40, 0, 13),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Value"]:AddToTheme({TextColor3 = "Text"})
            
            Items["RealSlider"] = Instances:Create("TextButton", {
                Parent = Items["Slider"].Instance,
                AnchorPoint = Vector2New(0, 1),
                Name = "\0",
                Position = UDim2New(0, 0, 1, 0),
                BorderColor3 = FromRGB(42, 42, 42),
                Text = "",
                AutoButtonColor = false,
                Size = UDim2New(1, 0, 0, 7),
                BorderSizePixel = 1,
                BackgroundColor3 = FromRGB(22, 22, 22)
            })  Items["RealSlider"]:AddToTheme({BackgroundColor3 = "Element", BorderColor3 = "Outline"})
            
            Instances:Create("UIStroke", {
                Parent = Items["RealSlider"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(42, 42, 42)
            }):AddToTheme({Color = "Outline"})
            
            Instances:Create("UIGradient", {
                Parent = Items["RealSlider"].Instance,
                Rotation = 90,
                Enabled = false,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(100, 100, 100))}
            }) 
            
            Items["Indicator"] = Instances:Create("Frame", {
                Parent = Items["RealSlider"].Instance,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(0.5, 0, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(179, 100, 122)
            })  Items["Indicator"]:AddToTheme({BackgroundColor3 = "Accent"})
            
            Instances:Create("UIGradient", {
                Parent = Items["Indicator"].Instance,
                Rotation = 90,
                Enabled = false,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(100, 100, 100))}
            }) 

            if Slider.Compact then 
                Items["Value"]:Clean()
                Items["Value"] = nil

                Items["Slider"].Instance.Size = UDim2New(1,0,0,10)
                Items["Text"].Instance.Parent = Items["RealSlider"].Instance
                Items["Text"].Instance.Position = UDim2New(0,0,0,-2)
                Items["Text"].Instance.Size = UDim2New(1, 0, 1, 0)
                Items["Text"].Instance.TextXAlignment = Enum.TextXAlignment.Center
            end

            Items["RealSlider"]:OnHover(function()
                Items["RealSlider"]:Tween(nil, {BackgroundColor3 = Library.Theme["Hovered Element"]})
                Items["RealSlider"]:ChangeItemTheme({BackgroundColor3 = "Hovered Element", BorderColor3 = "Outline"})
            end)

            Items["RealSlider"]:OnHoverLeave(function()
                Items["RealSlider"]:Tween(nil, {BackgroundColor3 = Library.Theme["Element"]})
                Items["RealSlider"]:ChangeItemTheme({BackgroundColor3 = "Element", BorderColor3 = "Outline"})
            end)
        end

        function Slider:Set(Value)
            Slider.Value = MathClamp(Library:Round(Value, Slider.Decimals), Slider.Min, Slider.Max)

            Library.Flags[Slider.Flag] = Slider.Value
            
            if Slider.Compact then
                Items["Text"].Instance.Text = `{Slider.Name}: {Slider.Value}{Slider.Suffix}`
            else
                Items["Value"].Instance.Text = `{Slider.Value}{Slider.Suffix}`
            end

            Items["Indicator"]:Tween(TweenInfo.new(0.17, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0)})

            if Slider.Callback then 
                Library:SafeCall(Slider.Callback, Slider.Value)
            end
        end

        function Slider:Get()
            return Slider.Value
        end

        function Slider:SetVisibility(Bool)
            Items["Slider"].Instance.Visible = Bool
        end

        Items["RealSlider"]:Connect("MouseButton1Down", function()
            Slider.Sliding = true

            local MousePos = UserInputService:GetMouseLocation()

            local SizeX = (MousePos.X - Items["RealSlider"].Instance.AbsolutePosition.X) / Items["RealSlider"].Instance.AbsoluteSize.X
            local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

            Slider:Set(Value)
        end)

        Items["RealSlider"]:Connect("InputEnded", function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Slider.Sliding = false
            end
        end)

        Library:Connect(UserInputService.InputChanged, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement and Slider.Sliding then
                local MousePos = UserInputService:GetMouseLocation()

                local SizeX = (MousePos.X - Items["RealSlider"].Instance.AbsolutePosition.X) / Items["RealSlider"].Instance.AbsoluteSize.X
                local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                Slider:Set(Value)
            end
        end)

        if Slider.Default then
            Slider:Set(Slider.Default)
        end

        Library.SetFlags[Slider.Flag] = function(Value)
            Slider:Set(Value)
        end

        return Slider
    end

    Library.Sections.Dropdown = function(self, Data)
        Data = Data or { }

        local Dropdown = {
            Window = self.Window,
            Page = self.Page,
            Section = self,

            Name = Data.Name or Data.name or "Dropdown",
            Flag = Data.Flag or Data.flag or Library:NextFlag(),
            Items = Data.Items or Data.items or { "One", "Two", "Three" },
            Default = Data.Default or Data.default or nil,
            Callback = Data.Callback or Data.callback or function() end,
            Multi = Data.Multi or Data.multi or false,
            MaxSize = Data.MaxSize or Data.maxsize or 168,

            Value = { },
            IsOpen = false,
            Options = { },
            Class = "Dropdown",
        }

        local OptionRowHeight = 15

        local Items = { } do
            Items["Dropdown"] = Instances:Create("Frame", {
                Parent = Dropdown.Section.Elements["Content"].Instance,
                BackgroundTransparency = 1,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 34),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Dropdown"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Dropdown.Name,
                Name = "\0",
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2New(1, 0, 0, 13),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

            Instances:Create("UIStroke", {
                Parent = Items["Text"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})
            
            Items["RealDropdown"] = Instances:Create("Frame", {
                Parent = Items["Dropdown"].Instance,
                AnchorPoint = Vector2New(0, 1),
                Name = "\0",
                Position = UDim2New(0, 0, 1, 0),
                BorderColor3 = FromRGB(42, 42, 42),
                Size = UDim2New(1, 0, 0, 16),
                BorderSizePixel = 1,
                BackgroundColor3 = FromRGB(22, 22, 22)
            })  Items["RealDropdown"]:AddToTheme({BackgroundColor3 = "Element", BorderColor3 = "Outline"})
            
            Instances:Create("UIGradient", {
                Parent = Items["RealDropdown"].Instance,
                Rotation = 90,
                Enabled = false,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(100, 100, 100))}
            }) 
            
            Instances:Create("UIStroke", {
                Parent = Items["RealDropdown"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(42, 42, 42)
            }):AddToTheme({Color = "Outline"})
            
            Items["Open"] = Instances:Create("TextButton", {
                Parent = Items["RealDropdown"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "v",
                AutoButtonColor = false,
                Name = "\0",
                Size = UDim2New(1, 0, 1, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Right,
                Position = UDim2New(0, -4, 0, -1),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Open"]:AddToTheme({TextColor3 = "Text"})

            Instances:Create("UIStroke", {
                Parent = Items["Open"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"}) 
            
            Items["Value"] = Instances:Create("TextLabel", {
                Parent = Items["RealDropdown"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "--",
                Name = "\0",
                Size = UDim2New(1, -25, 1, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2New(0, 5, 0, -1),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Value"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Value"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})
            
            Items["OptionHolder"] = Instances:Create("Frame", {
                Parent = Items["Dropdown"].Instance,
                Visible = false,
                BorderColor3 = FromRGB(10, 10, 10),
                Name = "\0",
                Position = UDim2New(0, 0, 1, 5),
                Size = UDim2New(1, 0, 0, 0),
                BorderSizePixel = 2,
                ClipsDescendants = true,
                BackgroundColor3 = FromRGB(20, 20, 25)
            })  Items["OptionHolder"]:AddToTheme({BackgroundColor3 = "Inline", BorderColor3 = "Border"})
            
            Instances:Create("UIStroke", {
                Parent = Items["OptionHolder"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"})

            Items["OptionScroll"] = Instances:Create("ScrollingFrame", {
                Parent = Items["OptionHolder"].Instance,
                Name = "\0",
                Active = true,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 1, 0),
                CanvasSize = UDim2New(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = FromRGB(235, 157, 255),
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ZIndex = 16,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["OptionScroll"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

            Instances:Create("UIListLayout", {
                Parent = Items["OptionScroll"].Instance,
                SortOrder = Enum.SortOrder.LayoutOrder
            }) 
            
            Instances:Create("UIPadding", {
                Parent = Items["OptionScroll"].Instance,
                PaddingBottom = UDimNew(0, 2)
            })

            Items["RealDropdown"]:OnHover(function()
                Items["RealDropdown"]:Tween(nil, {BackgroundColor3 = Library.Theme["Hovered Element"]})
                Items["RealDropdown"]:ChangeItemTheme({BackgroundColor3 = "Hovered Element", BorderColor3 = "Border"})
            end)

            Items["RealDropdown"]:OnHoverLeave(function()
                Items["RealDropdown"]:Tween(nil, {BackgroundColor3 = Library.Theme["Background"]})
                Items["RealDropdown"]:ChangeItemTheme({BackgroundColor3 = "Background", BorderColor3 = "Border"})
            end)
        end

        local function RefreshDropdownHeight()
            local Count = 0
            for _ in Dropdown.Options do
                Count += 1
            end

            local ContentHeight = (Count * OptionRowHeight) + 2
            local Height = math.clamp(ContentHeight, 0, Dropdown.MaxSize)
            Items["OptionHolder"].Instance.Size = UDim2New(1, 0, 0, Height)
            Items["OptionScroll"].Instance.ScrollingEnabled = ContentHeight > Dropdown.MaxSize
        end

        function Dropdown:Set(Option)
            if Dropdown.Multi then 
                if type(Option) ~= "table" then 
                    return
                end

                Dropdown.Value = Option

                for Index, Value in Option do 
                    local OptionData = Dropdown.Options[Value]
                    
                    if not OptionData then 
                        return
                    end

                    OptionData.Selected = true
                    OptionData:Toggle("Active")
                end

                Library.Flags[Dropdown.Flag] = Dropdown.Value

                Items["Value"].Instance.Text = TableConcat(Option, ", ")
            else
                if not Dropdown.Options[Option] then 
                    return
                end

                local OptionData = Dropdown.Options[Option]

                Dropdown.Value = OptionData.Name

                OptionData.Selected = true
                OptionData:Toggle("Active")

                for Index, Value in Dropdown.Options do 
                    if Value ~= OptionData then 
                        Value.Selected = false
                        Value:Toggle("Inactive")
                    end
                end

                Library.Flags[Dropdown.Flag] = Dropdown.Value

                Items["Value"].Instance.Text = Option
            end

            if Dropdown.Callback then 
                Library:SafeCall(Dropdown.Callback, Option)
            end
        end

        function Dropdown:Get()
            return Dropdown.Value
        end

        function Dropdown:SetVisibility(Bool)
            Items["Dropdown"].Instance.Visible = Bool
        end

        function Dropdown:Add(Option)
            local OptionButton = Instances:Create("TextButton", {
                Parent = Items["OptionScroll"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(0, 0, 0),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "",
                AutoButtonColor = false,
                Name = "\0",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2New(1, 0, 0, OptionRowHeight),
                ZIndex = 5,
                TextSize = 14,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            local OptionText = Instances:Create("TextLabel", {
                Parent = OptionButton.Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                TextTransparency = 0.48,
                Text = Option,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, -5, 1, 0),
                Position = UDim2New(0, 5, 0, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                ZIndex = 5,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            OptionText:AddToTheme({TextColor3 = "Text"})

            Instances:Create("UIStroke", {
                Parent = OptionText.Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})

            local OptionData = {
                Selected = false,
                Name = Option,
                Text = OptionText,
                Button = OptionButton
            }

            function OptionData:Toggle(State)
                if State == "Active" then 
                    OptionData.Text:ChangeItemTheme({TextColor3 = "Accent"})
                    OptionData.Text:Tween(nil, {TextColor3 = Library.Theme.Accent, TextTransparency = 0})
                else
                    OptionData.Text:ChangeItemTheme({TextColor3 = "Text"})
                    OptionData.Text:Tween(nil, {TextColor3 = Library.Theme.Text, TextTransparency = 0.48})
                end
            end

            function OptionData:Set()
                OptionData.Selected = not OptionData.Selected

                if Dropdown.Multi then
                    local Index = TableFind(Dropdown.Value, OptionData.Name)

                    if Index then 
                        TableRemove(Dropdown.Value, Index)
                    else
                        TableInsert(Dropdown.Value, OptionData.Name)
                    end

                    Library.Flags[Dropdown.Flag] = Dropdown.Value

                    OptionData:Toggle(Index and "Inactive" or "Active")

                    local TextFormat = #Dropdown.Value > 0 and TableConcat(Dropdown.Value, ", ") or "--"

                    Items["Value"].Instance.Text = TextFormat
                else
                    if OptionData.Selected then
                        Dropdown.Value = OptionData.Name

                        Library.Flags[Dropdown.Flag] = Dropdown.Value

                        OptionData:Toggle("Active")
                        Items["Value"].Instance.Text = OptionData.Name

                        for Index, Value in Dropdown.Options do 
                            if Value ~= OptionData then 
                                Value.Selected = false
                                Value:Toggle("Inactive")
                            end
                        end
                    else
                        Dropdown.Value = nil

                        OptionData:Toggle("Inactive")
                        Items["Value"].Instance.Text = "--"
                    end
                end

                if Dropdown.Callback then 
                    Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                end
            end

            OptionButton:Connect("MouseButton1Down", function()
                OptionData:Set()
            end)

            Dropdown.Options[Option] = OptionData
            RefreshDropdownHeight()
            return OptionData
        end

        function Dropdown:Remove(Option)
            if Dropdown.Options[Option] then 
                Dropdown.Options[Option].Button:Clean()
                Dropdown.Options[Option] = nil
                RefreshDropdownHeight()
            end
        end

        function Dropdown:Refresh(List)
            local OldNames = { }
            for Name in Dropdown.Options do
                TableInsert(OldNames, Name)
            end

            for _, Name in OldNames do
                Dropdown:Remove(Name)
            end

            for _, Value in List do
                Dropdown:Add(Value)
            end

            RefreshDropdownHeight()
        end

        local Debounce = false

        function Dropdown:SetMaxSize(Size)
            Dropdown.MaxSize = math.max(30, tonumber(Size) or Dropdown.MaxSize)
            RefreshDropdownHeight()
        end

        function Dropdown:SetOpen(Bool)
            -- allow close while animating; only block stacked opens
            if Debounce and Bool then 
                return 
            end

            if Bool then
                Library:CloseDropdowns(Dropdown)
            end

            Dropdown.IsOpen = Bool

            Debounce = true 

            if Bool then 
                RefreshDropdownHeight()
                Items["OptionHolder"].Instance.Visible = true
                Items["OptionHolder"].Instance.ZIndex = 15
                Items["OptionScroll"].Instance.ZIndex = 16
                Items["Open"].Instance.Text = "-"
                Items["Open"].Instance.Position = UDim2New(0, -5, 0, -1)
            else
                Items["Open"].Instance.Text = "+"
                Items["Open"].Instance.Position = UDim2New(0, -4, 0, -1)
            end

            local Descendants = Items["OptionHolder"].Instance:GetDescendants()
            TableInsert(Descendants, Items["OptionHolder"].Instance)

            local NewTween
            for Index, Value in Descendants do 
                local ValueIndex = Library:GetTransparencyPropertyFromItem(Value)

                if not ValueIndex then 
                    continue
                end

                if not StringFind(Value.ClassName, "UI") then 
                    Value.ZIndex = Bool and 15 or 1
                end

                if type(ValueIndex) == "table" then
                    for _, Property in ValueIndex do 
                        NewTween = Library:FadeItem(Value, Property, Bool, Dropdown.Window.FadeSpeed)
                    end
                else
                    NewTween = Library:FadeItem(Value, ValueIndex, Bool, Dropdown.Window.FadeSpeed)
                end
            end

            Library:AfterFade(NewTween, function()
                Debounce = false
                Items["OptionHolder"].Instance.Visible = Bool
                Items["OptionHolder"].Instance.ZIndex = Bool and 15 or 1
            end)
        end

        for Index, Value in Dropdown.Items do 
            Dropdown:Add(Value)
        end

        RefreshDropdownHeight()
        TableInsert(Library.Dropdowns, Dropdown)

        Items["Open"]:Connect("MouseButton1Down", function()
            Dropdown:SetOpen(not Dropdown.IsOpen)
        end)

        Library:Connect(UserInputService.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                if not Dropdown.IsOpen then
                    return 
                end

                if Library:IsMouseOverFrame(Items["OptionHolder"]) or Library:IsMouseOverFrame(Items["OptionScroll"]) then
                    return
                end

                -- don't close when clicking the dropdown header itself (toggle handles that)
                if Library:IsMouseOverFrame(Items["RealDropdown"]) then
                    return
                end

                Dropdown:SetOpen(false)
            end
        end)

        if Dropdown.Default then 
            Dropdown:Set(Dropdown.Default)
        end

        Library.SetFlags[Dropdown.Flag] = function(Value)
            Dropdown:Set(Value)            
        end

        return Dropdown
    end

    Library.Sections.Label = function(self, Data)
        Data = Data or { }

        local Label = {
            Window = self.Window,
            Page = self.Page,
            Section = self,

            Name = Data.Name or Data.name,
            Alignment = Data.Alignment or Data.alignment or "Left",

            Count = 0
        }

        local Items = { } do 
            Items["Label"] = Instances:Create("Frame", {
                Parent = Label.Section.Elements["Content"].Instance,
                BackgroundTransparency = 1,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 15),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Label"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Label.Name,
                Name = "\0",
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment[Label.Alignment],
                Size = UDim2New(1, 0, 1, 0),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

            Instances:Create("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Parent = Items["Text"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
            }):AddToTheme({Color = "Text Border"})
        end

        function Label:Colorpicker(Data)
            Data = Data or { }

            local Colorpicker = {
                Window = self.Window,
                Tab = self.Tab,
                Section = self.Section,

                Parent = Items["Label"],
                Name = Data.Name or Data.name or "Colorpicker",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                Callback = Data.Callback or Data.callback or function() end,
                Alpha = Data.Alpha or Data.alpha or false,
                Count = Label.Count,
                FadeSpeed = self.Window.FadeSpeed
            }

            Label.Count += 1
            Colorpicker.Count = Label.Count

            local Extension = Library:CreateColorpicker(Colorpicker)
            
            return Colorpicker, Extension
        end

        function Label:Keybind(Data)
            Data = Data or { }

            local Keybind = {
                Window = self.Window,
                Tab = self.Tab,
                Section = self.Section,

                Parent = Items["Label"],
                Name = Data.Name or Data.name or "Keybind",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or "MB2",
                Mode = Data.Mode or Data.mode or "Toggle",
                Callback = Data.Callback or Data.callback or function() end,
            }

            local Extension = Library:CreateKeybind(Keybind)

            return Keybind, Extension
        end

        return Label
    end

    Library.Sections.Textbox = function(self, Data)
        Data = Data or { }

        local Textbox = {
            Window = self.Window,
            Tab = self.Tab,
            Section = self,

            Name = Data.Name or Data.name or "Textbox",
            Flag = Data.Flag or Data.flag or Library:NextFlag(),
            Placeholder = Data.Placeholder or Data.placeholder or "...",
            Default = Data.Default or Data.default or "",
            Callback = Data.Callback or Data.callback or function() end,

            Value = "",
            Class = "Textbox"
        }

        local Items = { } do 
            Items["Textbox"] = Instances:Create("Frame", {
                Parent = Textbox.Section.Elements["Content"].Instance,
                BackgroundTransparency = 1,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 34),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Textbox"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = Textbox.Name,
                Name = "\0",
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2New(1, 0, 0, 13),
                BorderSizePixel = 0,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIStroke", {
                Parent = Items["Text"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})
            
            Items["Background"] = Instances:Create("Frame", {
                Parent = Items["Textbox"].Instance,
                AnchorPoint = Vector2New(0, 1),
                Name = "\0",
                Position = UDim2New(0, 0, 1, 0),
                BorderColor3 = FromRGB(10, 10, 10),
                Size = UDim2New(1, 0, 0, 17),
                BorderSizePixel = 2,
                BackgroundColor3 = FromRGB(33, 33, 36)
            })  Items["Background"]:AddToTheme({BackgroundColor3 = "Element", BorderColor3 = "Border"})
            
            Instances:Create("UIGradient", {
                Parent = Items["Background"].Instance,
                Rotation = 90,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(100, 100, 100))}
            }) 
            
            Instances:Create("UIStroke", {
                Parent = Items["Background"].Instance,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0",
                Color = FromRGB(27, 27, 32)
            }):AddToTheme({Color = "Outline"})
            
            Items["Inline"] = Instances:Create("TextBox", {
                Parent = Items["Background"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "",
                Name = "\0",
                Size = UDim2New(1, 0, 1, 0),
                BorderSizePixel = 0,
                ClearTextOnFocus = false,
                BackgroundTransparency = 1,
                PlaceholderColor3 = FromRGB(178, 178, 178),
                TextXAlignment = Enum.TextXAlignment.Left,
                PlaceholderText = Textbox.Placeholder,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Inline"]:AddToTheme({TextColor3 = "Text"})
            
            Instances:Create("UIPadding", {
                Parent = Items["Inline"].Instance,
                PaddingBottom = UDimNew(0, 3),
                PaddingLeft = UDimNew(0, 5)
            }) 
            
            Instances:Create("UIStroke", {
                Parent = Items["Inline"].Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})

            Items["Background"]:OnHover(function()
                Items["Background"]:Tween(nil, {BackgroundColor3 = Library.Theme["Hovered Element"]})
                Items["Background"]:ChangeItemTheme({BackgroundColor3 = "Hovered Element", BorderColor3 = "Border"})
            end)

            Items["Background"]:OnHoverLeave(function()
                Items["Background"]:Tween(nil, {BackgroundColor3 = Library.Theme["Element"]})
                Items["Background"]:ChangeItemTheme({BackgroundColor3 = "Element", BorderColor3 = "Border"})
            end)
        end

        function Textbox:Get()
            return Textbox.Value
        end

        function Textbox:SetVisibility(Bool)
            Items["Textbox"].Instance.Visible = Bool
        end

        function Textbox:Set(Value)
            Textbox.Value = Value
            
            Items["Inline"].Instance.Text = Textbox.Value
            Items["Inline"]:Tween(nil, {TextColor3 = Library.Theme.Text})
            Items["Inline"]:ChangeItemTheme({TextColor3 = "Text"})

            Library.Flags[Textbox.Flag] = Textbox.Value

            if Textbox.Callback then
                Library:SafeCall(Textbox.Callback, Textbox.Value)
            end
        end

        Items["Inline"]:Connect("Focused", function()
            Items["Inline"]:ChangeItemTheme({TextColor3 = "Accent"})
            Items["Inline"]:Tween(nil, {TextColor3 = Library.Theme.Accent})
        end)

        Items["Inline"]:Connect("FocusLost", function()
            Items["Inline"]:ChangeItemTheme({TextColor3 = "Text"})
            Items["Inline"]:Tween(nil, {TextColor3 = Library.Theme.Text})

            Textbox:Set(Items["Inline"].Instance.Text)
        end)

        if Textbox.Default then
            Textbox:Set(Textbox.Default)
        end

        Library.SetFlags[Textbox.Flag] = function(Value)
            Textbox:Set(Value)
        end

        return Textbox
    end
    
    Library.Sections.Listbox = function(self, Data)
        Data = Data or {}

        local Listbox = {
            Window = self.Window,
            Page = self.Page,
            Section = self,

            Items = Data.Items or Data.items or { },
            Multi = Data.Multi or Data.multi or false,
            Default = Data.Default or Data.default or 1,
            Flag = Data.Flag or Data.flag or Library:NextFlag(),
            Callback = Data.Callback or Data.callback or function() end,
            Size = Data.Size or Data.size or 175,

            Value = { },
            Options = { },
            Class = "Listbox",
        }

        local Items = { } do 
            Items["Listbox"] = Instances:Create("Frame", {
                Parent = Listbox.Section.Elements["Content"].Instance,
                Name = "\0",
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 0, Listbox.Size),
                BorderColor3 = FromRGB(0, 0, 0),
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            Items["RealListbox"] = Instances:Create("ScrollingFrame", {
                Parent = Items["Listbox"].Instance,
                ScrollBarImageColor3 = FromRGB(235, 157, 255),
                Active = true,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 1,
                AnchorPoint = Vector2New(0, 1),
                Size = UDim2New(1, 0, 1, 0),
                Name = "\0",
                Position = UDim2New(0, 0, 1, 0),
                BackgroundColor3 = FromRGB(15, 15, 20),
                BorderColor3 = FromRGB(10, 10, 10),
                BorderSizePixel = 2,
                CanvasSize = UDim2New(0, 0, 0, 0)
            })  Items["RealListbox"]:AddToTheme({ScrollBarImageColor3 = "Accent", BackgroundColor3 = "Background", BorderColor3 = "Border"})
            
            Instances:Create("UIStroke", {
                Parent = Items["RealListbox"].Instance,
                Color = FromRGB(27, 27, 32),
                Name = "\0",
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }):AddToTheme({Color = "Outline"}) 
            
            Instances:Create("UIListLayout", {
                Parent = Items["RealListbox"].Instance,
                SortOrder = Enum.SortOrder.LayoutOrder
            }) 

            Instances:Create("UIPadding", {
                Parent = Items["RealListbox"].Instance,
                PaddingBottom = UDimNew(0, 5),
                PaddingTop = UDimNew(0, 2)
            }) 
        end

        function Listbox:Set(Option)
            if Listbox.Multi then 
                if type(Option) ~= "table" then 
                    return
                end

                Listbox.Value = Option

                Library.Flags[Listbox.Flag] = Listbox.Value

                for Index, Value in Option do 
                    local OptionData = Listbox.Options[Value]
                    
                    if not OptionData then 
                        return
                    end

                    OptionData.Selected = true
                    OptionData:Toggle("Active")
                end
            else
                if not Listbox.Options[Option] then 
                    return
                end

                local OptionData = Listbox.Options[Option]

                Listbox.Value = OptionData.Name
                
                Library.Flags[Listbox.Flag] = Listbox.Value

                OptionData.Selected = true
                OptionData:Toggle("Active")

                for Index, Value in Listbox.Options do 
                    if Value ~= OptionData then 
                        Value.Selected = false
                        Value:Toggle("Inactive")
                    end
                end
            end

            if Listbox.Callback then 
                Library:SafeCall(Listbox.Callback, Option)
            end
        end

        function Listbox:Get()
            return Listbox.Value
        end

        function Listbox:SetVisibility(Bool)
            Items["Listbox"].Instance.Visible = Bool
        end

        function Listbox:Remove(Option)
            if Listbox.Options[Option] then 
                Listbox.Options[Option].Button:Clean()
            end
        end

        function Listbox:Refresh(List)
            for Index, Value in Listbox.Options do 
                Listbox:Remove(Value.Name)
            end

            for Index, Value in List do 
                Listbox:Add(Value)
            end
        end

        function Listbox:Add(Option)
            local OptionButton = Instances:Create("TextButton", {
                Parent = Items["RealListbox"].Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(0, 0, 0),
                BorderColor3 = FromRGB(0, 0, 0),
                Text = "",
                AutoButtonColor = false,
                Name = "\0",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2New(1, 0, 0, 15),
                ZIndex = 5,
                TextSize = 14,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            local OptionText = Instances:Create("TextLabel", {
                Parent = OptionButton.Instance,
                FontFace = Library.Font,
                TextColor3 = FromRGB(215, 215, 215),
                TextTransparency = 0.48,
                Text = Option,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, -5, 1, 0),
                Position = UDim2New(0, 5, 0, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Center,
                BorderSizePixel = 0,
                ZIndex = 5,
                TextSize = 12,
                BackgroundColor3 = FromRGB(255, 255, 255)
            }) 
            
            OptionText:AddToTheme({TextColor3 = "Text"})

            Instances:Create("UIStroke", {
                Parent = OptionText.Instance,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Name = "\0"
            }):AddToTheme({Color = "Text Border"})

            local OptionData = {
                Selected = false,
                Name = Option,
                Text = OptionText,
                Button = OptionButton
            }

            function OptionData:Toggle(State)
                if State == "Active" then 
                    OptionData.Text:ChangeItemTheme({TextColor3 = "Accent"})
                    OptionData.Text:Tween(nil, {TextColor3 = Library.Theme.Accent, TextTransparency = 0})
                else
                    OptionData.Text:ChangeItemTheme({TextColor3 = "Text"})
                    OptionData.Text:Tween(nil, {TextColor3 = Library.Theme.Text, TextTransparency = 0.48})
                end
            end

            function OptionData:Set()
                OptionData.Selected = not OptionData.Selected

                if Listbox.Multi then
                    local Index = TableFind(Listbox.Value, OptionData.Name)

                    if Index then 
                        TableRemove(Listbox.Value, Index)
                    else
                        TableInsert(Listbox.Value, OptionData.Name)
                    end

                    OptionData:Toggle(Index and "Inactive" or "Active")

                    local TextFormat = #Listbox.Value > 0 and TableConcat(Listbox.Value, ", ") or "--"
                else
                    if OptionData.Selected then
                        Listbox.Value = OptionData.Name

                        OptionData:Toggle("Active")

                        for Index, Value in Listbox.Options do 
                            if Value ~= OptionData then 
                                Value.Selected = false
                                Value:Toggle("Inactive")
                            end
                        end
                    else
                        Listbox.Value = nil

                        OptionData:Toggle("Inactive")
                    end
                end

                if Listbox.Callback then 
                    Library:SafeCall(Listbox.Callback, Listbox.Value)
                end
            end

            OptionButton:Connect("MouseButton1Down", function()
                OptionData:Set()
            end)

            Listbox.Options[Option] = OptionData
            return OptionData
        end

        for Index, Value in Listbox.Items do 
            Listbox:Add(Value)
        end

        if Listbox.Default then 
            Listbox:Set(Listbox.Default)
        end

        Library.SetFlags[Listbox.Flag] = function(Value)
            Listbox:Set(Value)
        end

        return Listbox
    end

    Library.CreateSettingsPage = function(self, Window, Watermark, KeybindList)
        local SettingsTab = Window:Page({Name = "Settings", Columns = 2, Subtabs = false})

        do -- Settings Tab
            local SettingsSection = SettingsTab:Section({Name = "Settings", Side = 2})
            local ConfigsSection = SettingsTab:Section({Name = "Profiles", Side = 1})
        
            for Index, Value in Library.Theme do 
                SettingsSection:Label({Name = Index, Alignment = "Left"}):Colorpicker({ Name = Index, Default = Value, Flag = "Theme"..Index, Callback = function(Color) 
                    Library.Theme[Index] = Color
                    Library:ChangeTheme(Index, Color)
                end})
            end
        
            SettingsSection:Label({Name = "Menu Keybind", Alignment = "Left"}):Keybind({Name = "Menu Keybind", Flag = "Menu Keybind", Default = Enum.KeyCode.RightControl, Mode = "Toggle", Callback = function(Value)
                Library.MenuKeybind = Library.Flags["Menu Keybind"].Key
            end})
        
            SettingsSection:Toggle({Name = "Watermark", Flag = "Watermark", Default = false, Callback = function(Value)
                Watermark:SetVisibility(Value)
            end})
        
            SettingsSection:Toggle({Name = "Keybind List", Flag = "Keybind List", Default = false, Callback = function(Value)
                KeybindList:SetVisibility(Value)
            end})
        
            SettingsSection:Dropdown({Name = "Tweening Style", Flag = "Tweening Style", Default = "Exponential", Items = {"Linear", "Sine", "Quad", "Cubic", "Quart", "Quint", "Exponential", "Circular", "Back", "Elastic", "Bounce"}, Callback = function(Value)
                Library.Tween.Style = Enum.EasingStyle[Value]
            end})
        
            SettingsSection:Dropdown({Name = "Tweening Direction", Flag = "Tweening Direction", Default = "Out", Items = {"In", "Out", "InOut"}, Callback = function(Value)
                Library.Tween.Direction = Enum.EasingDirection[Value]
            end})
        
            SettingsSection:Slider({Name = "Tweening Time", Min = 0, Max = 5, Default = 0.25, Decimals = 0.01, Flag = "Tweening Time", Callback = function(Value)
                Library.Tween.Time = Value
            end})
        
            SettingsSection:Button({Name = "Notification test", Callback = function()
                Library:Notification("This is a notification This is a notification This is a notification This is a notification", 5, Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255)))
            end})
        
            SettingsSection:Button({Name = "Unload library", Callback = function()
                Library:Unload()
            end})
        
            local ConfigName 
            local ConfigSelected
        
            local ConfigsListbox = ConfigsSection:Listbox({Items = { }, Name = "Configs", Flag = "Configs List", Callback = function(Value)
                ConfigSelected = Value
            end})
        
            ConfigsSection:Textbox({Name = "Config Name", Placeholder = ". .", Flag = "Config Name", Callback = function(Value)
                ConfigName = Value
            end})
        
            ConfigsSection:Button({Name = "Create Config", Callback = function()
                if not isfile(Library.Folders.Configs .. "/" .. ConfigName .. ".json") then
                    writefile(Library.Folders.Configs .. "/" .. ConfigName .. ".json", Library:GetConfig())
        
                    Library:RefreshConfigsList(ConfigsListbox)
                else
                    Library:Notification("Config '" .. ConfigName .. ".json' already exists", 3, Color3.fromRGB(255, 0, 0))
                    return
                end
            end})
        
            ConfigsSection:Button({Name = "Load Config", Callback = function()
                if ConfigSelected then
                    Library:LoadConfig(readfile(Library.Folders.Configs .. "/" .. ConfigSelected))
                end
        
                    task.wait(0.1)
        
                    for Index, Value in Library.Theme do 
                        local ThemeFlag = Library.Flags["Theme"..Index]
                        if ThemeFlag and ThemeFlag.Color then
                            Library.Theme[Index] = ThemeFlag.Color
                            Library:ChangeTheme(Index, ThemeFlag.Color)
                        end
                    end    
            end})
        
            ConfigsSection:Button({Name = "Delete Config", Callback = function()
                if ConfigSelected then
                    Library:DeleteConfig(ConfigSelected)
        
                    Library:RefreshConfigsList(ConfigsListbox)
                end
            end})
        
            ConfigsSection:Button({Name = "Save Config", Callback = function()
                if ConfigSelected then
                    Library:SaveConfig(ConfigSelected)
                end
            end})
        
            ConfigsSection:Button({Name = "Refresh Configs", Callback = function()
                Library:RefreshConfigsList(ConfigsListbox)
            end})

            ConfigsSection:Divider()

            ConfigsSection:Button({Name = "Set As Autoload", Callback = function()
                if ConfigSelected then 
                    writefile(Library.Folders.Directory .. "/autoload.json", readfile(Library.Folders.Configs .. "/" .. ConfigSelected))
                end
            end})

            ConfigsSection:Button({Name = "Remove Autoload", Callback = function()
                writefile(Library.Folders.Directory .. "/autoload.json", "")
            end})
        
            Library:RefreshConfigsList(ConfigsListbox)
        end

    end
end

-- ============================================================================
-- Emblem system (same idea as Unnamed Enhancements / premium Rivals UIs):
-- ViewportFrame + WorldModel, preset brand meshes/parts, no Sketchfab/ID fields.
-- ============================================================================
Library.CreateEmblem = function(self, Window, Options)
    Options = Options or {}

    local RunService = game:GetService("RunService")
    local Hui = Options.Parent or (gethui and gethui() or game:GetService("CoreGui"))
    local GuiName = Options.Name or "haze_best_emblem"

    local Emblem = {}
    Emblem.Alive = true

    local function IsUnloaded()
        if not Emblem.Alive then
            return true
        end
        if Options.IsUnloaded then
            local Ok, Result = pcall(Options.IsUnloaded)
            if Ok and Result then
                return true
            end
        end
        return false
    end

    local EmblemEnabled = true
    local EmblemShape = "Cross"
    local EmblemColor = Color3.fromRGB(200, 200, 205)
    local EmblemMaterial = "Plastic"
    local EmblemSpeed = 50
    local EmblemVisibility = 1
    local EmblemSize = 7
    local EmblemUseAccent = false
    local EmblemRainbow = false
    local EmblemRainbowHue = 0
    local EmblemGlow = 1
    local EmblemKeepTextures = true

    -- Presets: Mesh = single CreateMeshPartAsync; Model = multi MeshPart assembly (from .rbxm).
    local EmblemPresets = {
        Cross = {
            Type = "Mesh",
            MeshId = "rbxassetid://11468548833",
            TextureId = "",
            Scale = 7,
            Orientation = CFrame.Angles(0, 0, 0),
        },
        Sword = {
            Type = "Mesh",
            MeshId = "rbxassetid://13662643071",
            TextureId = "rbxassetid://13662522227",
            Scale = 7,
            SizeMul = 1.45,
            Orientation = CFrame.Angles(0, 0, 0),
        },
        ["tung tung"] = {
            Type = "Mesh",
            MeshId = "rbxassetid://82464974337955",
            TextureId = "rbxassetid://105445253181063",
            Scale = 7,
            Orientation = CFrame.Angles(0, 0, 0),
        },
        ["67 Kid"] = {
            Type = "Mesh",
            MeshId = "rbxassetid://133310753400388",
            TextureId = "rbxassetid://73676263597561",
            Scale = 7,
            Orientation = CFrame.Angles(0, 0, 0),
        },
        Gun = {
            Type = "Model",
            Span = 5.0,
            SizeMul = 1.45,
            Parts = {
                {MeshId = "453276303", Size = Vector3.new(1.011213, 0.223500, 0.286198), Offset = CFrame.new(0.258118, 0.156050, 0.011934) * CFrame.fromEulerAnglesYXZ(0, math.rad(180), 0)},
                {MeshId = "455704535", Size = Vector3.new(0.186146, 0.288760, 1.044802), Offset = CFrame.new(0.196274, 0.372149, -0.003561) * CFrame.fromEulerAnglesYXZ(0, math.rad(-90), 0)},
                {MeshId = "453250464", Size = Vector3.new(0.124258, 1.024903, 0.470746), Offset = CFrame.new(-0.118881, -0.465418, 0.011934) * CFrame.fromEulerAnglesYXZ(0, math.rad(-90), 0)},
                {MeshId = "453290424", Size = Vector3.new(1.950758, 0.653867, 0.284516), Offset = CFrame.new(0.651138, -0.056962, -0.023039) * CFrame.fromEulerAnglesYXZ(0, math.rad(180), 0)},
                {MeshId = "453276973", Size = Vector3.new(1.101982, 0.474286, 0.289528), Offset = CFrame.new(0.222092, -0.088943, -0.033056) * CFrame.fromEulerAnglesYXZ(0, math.rad(180), 0)},
                {MeshId = "453270448", Size = Vector3.new(1.308157, 0.561810, 0.290284), Offset = CFrame.new(-1.059925, 0.229051, 0.011934) * CFrame.fromEulerAnglesYXZ(0, math.rad(180), 0)},
                {MeshId = "453285796", Size = Vector3.new(1.790145, 0.974910, 0.196797), Offset = CFrame.new(1.306122, -0.254966, 0.011927) * CFrame.fromEulerAnglesYXZ(0, math.rad(180), 0)},
                {MeshId = "453268328", Size = Vector3.new(2.266772, 0.279449, 0.279451), Offset = CFrame.new(-1.454937, 0.109041, 0.011927) * CFrame.fromEulerAnglesYXZ(0, math.rad(180), 0)},
            },
        },
    }

    local OldEmblem = Hui:FindFirstChild(GuiName)
    if OldEmblem then
        OldEmblem:Destroy()
    end

    local EmblemGui = Instance.new("ScreenGui")
    EmblemGui.Name = GuiName
    EmblemGui.IgnoreGuiInset = true
    EmblemGui.DisplayOrder = -100
    EmblemGui.ResetOnSpawn = false
    EmblemGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    EmblemGui.Parent = Hui

    pcall(function()
        if self.Holder and self.Holder.Instance then
            self.Holder.Instance.DisplayOrder = math.max(self.Holder.Instance.DisplayOrder or 0, 50)
        end
    end)

    local Viewport = Instance.new("ViewportFrame")
    Viewport.Name = "EmblemViewport"
    Viewport.BackgroundTransparency = 1
    Viewport.Size = UDim2.new(0, 640, 0, 640)
    Viewport.AnchorPoint = Vector2.new(0.5, 0.5)
    Viewport.Position = UDim2.new(0.5, 0, 0.5, 0)
    Viewport.Ambient = Color3.fromRGB(70, 72, 80)
    Viewport.LightColor = Color3.fromRGB(255, 255, 255)
    Viewport.LightDirection = Vector3.new(-0.55, -1, -0.35)
    Viewport.ImageTransparency = 0
    Viewport.Active = false
    Viewport.Parent = EmblemGui

    local World = Instance.new("WorldModel")
    World.Parent = Viewport

    local EmblemCamera = Instance.new("Camera")
    EmblemCamera.FieldOfView = 40
    EmblemCamera.Parent = Viewport
    Viewport.CurrentCamera = EmblemCamera
    EmblemCamera.CFrame = CFrame.new(Vector3.new(0, 0, 16), Vector3.zero)

    local EmblemModel = nil
    local EmblemAngle = 0
    local EmblemBaseRotation = CFrame.new()
    local EmblemNativeSize = nil
    local EmblemNativeSpan = 5.5
    local EmblemAssembly = {}
    local EmblemBusy = false

    local MaterialMap = {
        Plastic = Enum.Material.Plastic,
        Neon = Enum.Material.Neon,
        ForceField = Enum.Material.ForceField,
    }

    local function GetEmblemMaterial()
        return MaterialMap[EmblemMaterial] or Enum.Material.Plastic
    end

    local function GetEmblemColor()
        if EmblemRainbow then
            return Color3.fromHSV(EmblemRainbowHue % 1, 1, 1)
        end
        if EmblemUseAccent and self.Theme and self.Theme.Accent then
            return self.Theme.Accent
        end
        return EmblemColor
    end

    local function GetPresetSizeMul()
        local Preset = EmblemPresets[EmblemShape]
        if Preset and Preset.SizeMul then
            return Preset.SizeMul
        end
        return 1
    end

    local function ScaleLightColor(Color, Mul)
        return Color3.new(
            math.clamp(Color.R * Mul, 0, 1),
            math.clamp(Color.G * Mul, 0, 1),
            math.clamp(Color.B * Mul, 0, 1)
        )
    end

    local function UpdateEmblemViewportLight()
        local Glow = math.clamp(tonumber(EmblemGlow) or 1, 0, 2)
        local Tint = GetEmblemColor()
        local Ambient
        local Light
        local Direction

        if EmblemMaterial == "Neon" then
            Ambient = Color3.fromRGB(25, 25, 30)
            Light = Color3.fromRGB(255, 255, 255):Lerp(Tint, math.clamp(0.2 + Glow * 0.35, 0, 0.85))
            Direction = Vector3.new(-0.15, -1, -0.25)
            Ambient = ScaleLightColor(Ambient, 0.55 + Glow * 0.7)
            Light = ScaleLightColor(Light, 0.55 + Glow * 0.95)
        elseif EmblemMaterial == "ForceField" then
            Ambient = Color3.fromRGB(20, 25, 40)
            Light = Color3.fromRGB(160, 210, 255):Lerp(Tint, math.clamp(Glow * 0.25, 0, 0.6))
            Direction = Vector3.new(-0.5, -1, -0.2)
            Ambient = ScaleLightColor(Ambient, 0.55 + Glow * 0.65)
            Light = ScaleLightColor(Light, 0.55 + Glow * 0.85)
        else
            Ambient = Color3.fromRGB(95, 95, 100)
            Light = Color3.fromRGB(255, 255, 255)
            Direction = Vector3.new(-0.4, -1, -0.5)
            Ambient = ScaleLightColor(Ambient, 0.45 + Glow * 0.55)
            Light = ScaleLightColor(Light, 0.45 + Glow * 0.7)
        end

        Viewport.Ambient = Ambient
        Viewport.LightColor = Light
        Viewport.LightDirection = Direction
    end

    local function NormalizeAssetId(Value)
        if not Value then
            return ""
        end
        Value = tostring(Value):gsub("%s", "")
        Value = Value:gsub("rbxassetid://", "")
        Value = Value:gsub("rbxasset://", "")
        Value = Value:match("(%d+)") or Value
        return Value
    end

    local function RememberPartTexture(Part, TextureId)
        local Normalized = NormalizeAssetId(TextureId)
        if Normalized ~= "" then
            Part:SetAttribute("EmblemTexture", "rbxassetid://" .. Normalized)
        end
    end

    local function ApplyPartTexture(Part)
        local Tex = Part:GetAttribute("EmblemTexture")
        local UseTex = EmblemKeepTextures and type(Tex) == "string" and Tex ~= ""

        if Part:IsA("MeshPart") then
            pcall(function()
                Part.TextureID = UseTex and Tex or ""
            end)
        end

        local Mesh = Part:FindFirstChildOfClass("SpecialMesh")
        if Mesh then
            Mesh.TextureId = UseTex and Tex or ""
        end
    end

    local function StyleEmblemPart(Part)
        Part.Anchored = true
        Part.CanCollide = false
        Part.CanQuery = false
        Part.CanTouch = false
        Part.CastShadow = false
        pcall(function()
            Part.MaterialVariant = ""
        end)

        local Color = GetEmblemColor()
        Part.Material = GetEmblemMaterial()
        Part.Color = Color
        Part.Reflectance = 0

        local FileMesh = Part:FindFirstChildOfClass("SpecialMesh")
        if FileMesh and FileMesh.MeshType == Enum.MeshType.FileMesh then
            Part.Transparency = 1
        elseif EmblemMaterial == "ForceField" then
            Part.Transparency = 0.2
        else
            Part.Transparency = 0
        end

        ApplyPartTexture(Part)
    end

    local function FitEmblemCamera()
        if not EmblemModel or not EmblemModel.Parent then
            return
        end

        -- Frame max Size with room for spin tilt (stops Gun mag/stock clipping).
        local MaxSpan = 9
        local Padding = 1.9
        local HalfFov = math.rad(EmblemCamera.FieldOfView * 0.5)
        local Distance = ((MaxSpan * 0.5) * Padding) / math.tan(HalfFov)

        local Ok, _, Size = pcall(function()
            return EmblemModel:GetBoundingBox()
        end)
        if Ok and Size then
            local Longest = math.max(Size.X, Size.Y, Size.Z, 0.1)
            local Needed = ((Longest * 0.5) * Padding) / math.tan(HalfFov)
            if Needed > Distance then
                Distance = Needed
            end
        end

        EmblemCamera.CFrame = CFrame.new(Vector3.new(0, 0, Distance), Vector3.zero)
    end

    local function CenterEmblemModel()
        if not EmblemModel or not EmblemModel.Parent then
            return
        end

        local Ok, Cf = pcall(function()
            return EmblemModel:GetBoundingBox()
        end)
        if not Ok or not Cf then
            return
        end

        local Offset = Cf.Position
        if Offset.Magnitude < 1e-4 then
            return
        end

        for _, Part in EmblemModel:GetDescendants() do
            if Part:IsA("BasePart") and Part.Name ~= "Root" then
                Part.CFrame = CFrame.new(-Offset) * Part.CFrame
            end
        end
    end

    local function GetEmblemOrientation()
        local Preset = EmblemPresets[EmblemShape]
        if Preset and Preset.Orientation then
            return Preset.Orientation
        end
        return CFrame.new()
    end

    local function ApplyEmblemSize()
        if not EmblemModel or not EmblemModel.Parent then
            return
        end

        local Target = math.clamp(tonumber(EmblemSize) or 7, 1, 9) * GetPresetSizeMul()
        EmblemSize = math.clamp(tonumber(EmblemSize) or 7, 1, 9)
        local Span = EmblemNativeSpan > 0 and EmblemNativeSpan or 7
        local Factor = Target / Span

        if #EmblemAssembly > 0 then
            for _, Entry in ipairs(EmblemAssembly) do
                local Part = Entry.Part
                if Part and Part.Parent then
                    local Base = Entry.BaseOffset
                    Part.CFrame = CFrame.new(Base.Position * Factor) * (Base - Base.Position)
                    if Entry.SpecialMesh and Entry.NativeMeshScale then
                        local S = Entry.NativeMeshScale * Factor
                        Entry.SpecialMesh.Scale = Vector3.new(S, S, S)
                    else
                        Part.Size = Entry.NativeSize * Factor
                    end
                end
            end
            FitEmblemCamera()
            return
        end

        for _, Part in EmblemModel:GetDescendants() do
            if Part:IsA("MeshPart") and Part.Name == "EmblemPart" then
                local Native = EmblemNativeSize
                if not Native or Native.Magnitude < 0.001 then
                    Native = Part.MeshSize
                    EmblemNativeSize = Native
                end
                if Native and Native.Magnitude >= 0.001 then
                    local Longest = math.max(Native.X, Native.Y, Native.Z, 0.001)
                    Part.Size = Native * (Target / Longest)
                end
            elseif Part:IsA("BasePart") and Part.Name == "EmblemPart" then
                local Mesh = Part:FindFirstChildOfClass("SpecialMesh")
                if Mesh and Mesh.MeshType == Enum.MeshType.FileMesh then
                    local S = Target / 831
                    Mesh.Scale = Vector3.new(S, S, S)
                elseif not Part:IsA("MeshPart") then
                    local Scale = Target / 5.5
                    if Part.Size.Y > Part.Size.X then
                        Part.Size = Vector3.new(0.78 * Scale, 4.35 * Scale, 1.05 * Scale)
                    else
                        Part.Size = Vector3.new(3.35 * Scale, 0.78 * Scale, 1.05 * Scale)
                        Part.CFrame = CFrame.new(0, 0.72 * Scale, 0) * (Part.CFrame - Part.CFrame.Position)
                    end
                end
            end
        end

        FitEmblemCamera()
    end

    local function BuildPresetMesh(Parent, Preset)
        EmblemAssembly = {}
        local MeshId = NormalizeAssetId(Preset.MeshId)
        if MeshId == "" then
            return false
        end

        local Uri = "rbxassetid://" .. MeshId
        local Target = math.clamp(tonumber(EmblemSize) or Preset.Scale or 7, 1, 9) * (Preset.SizeMul or 1)
        local Orient = Preset.Orientation or CFrame.new()

        local Ok, MeshPart = pcall(function()
            return game:GetService("AssetService"):CreateMeshPartAsync(Content.fromUri(Uri))
        end)

        if Ok and MeshPart then
            local Native = MeshPart.MeshSize
            if Native.Magnitude < 0.001 then
                Native = MeshPart.Size
            end
            EmblemNativeSize = Native
            EmblemNativeSpan = math.max(Native.X, Native.Y, Native.Z, 0.001)

            local Longest = EmblemNativeSpan
            MeshPart.Name = "EmblemPart"
            MeshPart.Size = Native * (Target / Longest)
            MeshPart.CFrame = Orient
            RememberPartTexture(MeshPart, Preset.TextureId)
            StyleEmblemPart(MeshPart)
            MeshPart.Parent = Parent
            return true
        end

        EmblemNativeSize = nil
        EmblemNativeSpan = 5.5

        local Part = Instance.new("Part")
        Part.Name = "EmblemPart"
        Part.Size = Vector3.new(1, 1, 1)
        Part.Transparency = 1
        Part.CFrame = Orient
        StyleEmblemPart(Part)
        Part.Transparency = 1

        local Mesh = Instance.new("SpecialMesh")
        Mesh.MeshType = Enum.MeshType.FileMesh
        Mesh.MeshId = Uri
        local S = Target / 831
        Mesh.Scale = Vector3.new(S, S, S)
        local Color = GetEmblemColor()
        Mesh.VertexColor = Vector3.new(Color.R, Color.G, Color.B)
        Mesh.Parent = Part
        RememberPartTexture(Part, Preset.TextureId)
        ApplyPartTexture(Part)
        Part.Parent = Parent
        return true
    end

    local function BuildModelPreset(Parent, Preset)
        EmblemAssembly = {}
        EmblemNativeSize = nil
        EmblemNativeSpan = Preset.Span or 2.76

        local AssetService = game:GetService("AssetService")
        local Built = 0

        for _, Info in ipairs(Preset.Parts or {}) do
            local MeshId = NormalizeAssetId(Info.MeshId)
            if MeshId ~= "" then
                local TextureId = NormalizeAssetId(Info.TextureId)
                local Offset = Info.Offset or CFrame.new()
                local Made = false

                if not Info.FileMesh then
                    local Ok, MeshPart = pcall(function()
                        return AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. MeshId))
                    end)

                    if Ok and MeshPart then
                        local Native = Info.Size or MeshPart.MeshSize
                        MeshPart.Name = "EmblemPart"
                        MeshPart.Size = Native
                        MeshPart.CFrame = Offset
                        RememberPartTexture(MeshPart, TextureId)
                        StyleEmblemPart(MeshPart)
                        MeshPart.Parent = Parent

                        table.insert(EmblemAssembly, {
                            Part = MeshPart,
                            NativeSize = Native,
                            BaseOffset = Offset,
                        })
                        Built += 1
                        Made = true
                    end
                end

                if not Made then
                    local Part = Instance.new("Part")
                    Part.Name = "EmblemPart"
                    Part.Size = Info.Size or Vector3.new(1, 1, 1)
                    Part.Transparency = 1
                    Part.CFrame = Offset
                    StyleEmblemPart(Part)
                    Part.Transparency = 1

                    local BaseScale = Info.MeshScale or 0.1
                    local Mesh = Instance.new("SpecialMesh")
                    Mesh.MeshType = Enum.MeshType.FileMesh
                    Mesh.MeshId = "rbxassetid://" .. MeshId
                    Mesh.Scale = Vector3.new(BaseScale, BaseScale, BaseScale)
                    Mesh.Parent = Part
                    RememberPartTexture(Part, TextureId)
                    ApplyPartTexture(Part)
                    Part.Parent = Parent

                    table.insert(EmblemAssembly, {
                        Part = Part,
                        NativeSize = Info.Size or Vector3.new(1, 1, 1),
                        BaseOffset = Offset,
                        SpecialMesh = Mesh,
                        NativeMeshScale = BaseScale,
                    })
                    Built += 1
                end
            end
        end

        if Built > 0 then
            ApplyEmblemSize()
            return true
        end

        EmblemAssembly = {}
        return false
    end

    local function BuildEmblemShape(Parent)
        EmblemAssembly = {}
        local Preset = EmblemPresets[EmblemShape]
        if not Preset then
            EmblemNativeSize = nil
            EmblemNativeSpan = 5.5
            return false
        end

        if Preset.Type == "Model" then
            if BuildModelPreset(Parent, Preset) then
                return true
            end
        end

        if Preset.Type == "Mesh" then
            if BuildPresetMesh(Parent, Preset) then
                return true
            end
        end

        EmblemNativeSize = nil
        EmblemNativeSpan = 5.5
        return false
    end

    local function RebuildEmblem()
        if EmblemBusy then
            return
        end
        EmblemBusy = true

        local Ok, Err = pcall(function()
            if EmblemModel then
                EmblemModel:Destroy()
                EmblemModel = nil
            end

            EmblemModel = Instance.new("Model")
            EmblemModel.Name = "EmblemModel"
            EmblemModel.Parent = World

            local Root = Instance.new("Part")
            Root.Name = "Root"
            Root.Anchored = true
            Root.CanCollide = false
            Root.Transparency = 1
            Root.Size = Vector3.new(0.2, 0.2, 0.2)
            Root.CFrame = CFrame.new()
            Root.Parent = EmblemModel
            EmblemModel.PrimaryPart = Root

            BuildEmblemShape(EmblemModel)
            EmblemBaseRotation = GetEmblemOrientation()
            CenterEmblemModel()
            EmblemAngle = 0
            if EmblemModel and EmblemModel.Parent then
                EmblemModel:PivotTo(CFrame.Angles(math.rad(5), 0, math.rad(-2)))
                FitEmblemCamera()
            end
        end)

        EmblemBusy = false
        if not Ok then
            warn("[haze.best] Emblem rebuild failed:", Err)
        end
    end

    local function ApplyEmblemStyle()
        if not EmblemModel then
            return
        end

        local Color = GetEmblemColor()
        UpdateEmblemViewportLight()

        for _, Part in EmblemModel:GetDescendants() do
            if Part:IsA("BasePart") and Part.Name ~= "Root" then
                StyleEmblemPart(Part)
            elseif Part:IsA("SpecialMesh") then
                Part.VertexColor = Vector3.new(Color.R, Color.G, Color.B)
            end
        end
    end

    local function RefreshEmblemTheme()
        if EmblemUseAccent and not EmblemRainbow then
            ApplyEmblemStyle()
        end
    end

    local function ApplyEmblemVisibility()
        Viewport.ImageTransparency = 1 - EmblemVisibility
    end

    local function UpdateEmblem()
        local Show = EmblemEnabled and Window.IsOpen and not IsUnloaded()
        EmblemGui.Enabled = Show
        ApplyEmblemVisibility()
    end

    RebuildEmblem()
    UpdateEmblem()

    local EmblemConnection = RunService.RenderStepped:Connect(function(Delta)
        if IsUnloaded() then
            return
        end

        UpdateEmblem()

        if not EmblemEnabled or not Window.IsOpen or not EmblemModel or not EmblemModel.Parent or EmblemBusy then
            return
        end

        if EmblemRainbow then
            EmblemRainbowHue = (EmblemRainbowHue + Delta * 0.35) % 1
            ApplyEmblemStyle()
        end

        EmblemAngle += math.rad(EmblemSpeed) * Delta
        EmblemModel:PivotTo(CFrame.Angles(math.rad(5), EmblemAngle, math.rad(-2)))
    end)

    Emblem.SetEnabled = function(_, Value)
        EmblemEnabled = Value
        UpdateEmblem()
    end

    Emblem.SetShape = function(_, Value)
        if Value == "None" or Value == nil or Value == "" or Value == "-" then
            EmblemShape = ""
        else
            EmblemShape = Value
        end
        RebuildEmblem()
        ApplyEmblemStyle()
    end

    Emblem.SetSpeed = function(_, Value)
        EmblemSpeed = Value
    end

    Emblem.SetSize = function(_, Value)
        EmblemSize = math.clamp(tonumber(Value) or 7, 1, 9)
        ApplyEmblemSize()
    end

    Emblem.SetVisibility = function(_, Value)
        EmblemVisibility = math.clamp(tonumber(Value) or 1, 0, 1)
        ApplyEmblemVisibility()
    end

    Emblem.SetColor = function(_, Color)
        EmblemColor = Color
        if not EmblemRainbow and not EmblemUseAccent then
            ApplyEmblemStyle()
        end
    end

    Emblem.SetMaterial = function(_, Value)
        EmblemMaterial = Value
        ApplyEmblemStyle()
    end

    Emblem.SetUseAccent = function(_, Value)
        EmblemUseAccent = Value
        if not EmblemRainbow then
            ApplyEmblemStyle()
        end
    end

    Emblem.SetRainbow = function(_, Value)
        EmblemRainbow = Value
        ApplyEmblemStyle()
    end

    Emblem.SetGlow = function(_, Value)
        EmblemGlow = math.clamp(tonumber(Value) or 1, 0, 2)
        UpdateEmblemViewportLight()
    end

    Emblem.SetKeepTextures = function(_, Value)
        EmblemKeepTextures = Value
        ApplyEmblemStyle()
    end

    Emblem.Rebuild = function(_)
        RebuildEmblem()
    end

    Emblem.Update = function(_)
        UpdateEmblem()
    end

    Emblem.ApplyStyle = function(_)
        ApplyEmblemStyle()
    end

    Emblem.ApplySize = function(_)
        ApplyEmblemSize()
    end

    Emblem.ApplyVisibility = function(_)
        ApplyEmblemVisibility()
    end

    Emblem.RefreshTheme = function(_)
        RefreshEmblemTheme()
    end

    Emblem.GetShapeNames = function(_)
        local Items = {"None"}
        for Name in pairs(EmblemPresets) do
            table.insert(Items, Name)
        end
        table.sort(Items, function(A, B)
            if A == "None" then
                return true
            end
            if B == "None" then
                return false
            end
            return A < B
        end)
        return Items
    end

    Emblem.Presets = EmblemPresets

    Emblem.Destroy = function(_)
        if not Emblem.Alive then
            return
        end
        Emblem.Alive = false
        pcall(function()
            EmblemConnection:Disconnect()
        end)
        pcall(function()
            EmblemGui:Destroy()
        end)
    end

    self.Emblem = Emblem
    return Emblem
end

-- ============================================================================
-- ESP preview (3D frame outside the menu — styled like a standalone ESP PREVIEW panel)
-- Includes character bundle models + catalog dance/emote playback.
-- ============================================================================
Library.CreateEspPreview = function(self, Window, Options)
    Options = Options or {}

    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    local ContentProvider = game:GetService("ContentProvider")

    local Hui = Options.Parent or (gethui and gethui() or game:GetService("CoreGui"))
    local GuiName = Options.Name or "haze_best_esp_preview"
    local DanceProxyName = Options.DanceProxyName or "haze_esp_dance_proxy"

    local EspPreview = {}
    EspPreview.Alive = true

    local function IsUnloaded()
        if not EspPreview.Alive then
            return true
        end
        if Options.IsUnloaded then
            local Ok, Result = pcall(Options.IsUnloaded)
            if Ok and Result then
                return true
            end
        end
        return false
    end

    local EspBoxEnabled = false
    local EspNameEnabled = false
    local EspHealthEnabled = false
    local EspChamsEnabled = false
    local EspPreviewColor = Color3.fromRGB(125, 211, 252)
    local EspHealthValue = 0.72
    local EspPreviewAngle = 0
    local RequestEspHealthAnim
    local SetEspPreviewDance
    local SetEspPreviewDanceSpeed
    local SetEspPreviewDanceById
    local SetEspPreviewModel
    local UpdateEspPreview
    local ApplyEspPreviewOverlays

    -- stop previous preview loop before destroying its WorldModel (hot-reload safety)
    pcall(function()
        if getgenv().HazeEspPreviewConnection then
            getgenv().HazeEspPreviewConnection:Disconnect()
            getgenv().HazeEspPreviewConnection = nil
        end
    end)

    local EspPreviewConnection

    -- cleanup previous preview (own ScreenGui + leftover panel on library holder)
    local OldEsp = Hui:FindFirstChild(GuiName)
    if OldEsp then
        OldEsp:Destroy()
    end
    pcall(function()
        local Holder = self.Holder and self.Holder.Instance
        if Holder then
            local Leftover = Holder:FindFirstChild("EspPreviewPanel")
            if Leftover then
                Leftover:Destroy()
            end
        end
    end)

    local EspGui = Instance.new("ScreenGui")
    EspGui.Name = GuiName
    EspGui.IgnoreGuiInset = false
    EspGui.DisplayOrder = 120
    EspGui.ResetOnSpawn = false
    EspGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    EspGui.Enabled = false
    EspGui.Parent = Hui

    pcall(function()
        local Holder = self.Holder and self.Holder.Instance
        if Holder then
            EspGui.IgnoreGuiInset = Holder.IgnoreGuiInset
            Holder.DisplayOrder = math.max(Holder.DisplayOrder or 0, 50)
            local Leftover = Holder:FindFirstChild("EspPreviewPanel", true)
            if Leftover then
                Leftover:Destroy()
            end
        end
    end)

    local PanelW, PanelH = 300, 400
    local PartLooks = {}
    local EspDockOffsetX = 6
    local EspDockOffsetY = -1
    local EspDraggingPanel = false
    local EspDraggingOrbit = false
    local EspDragStart
    local EspPanelStart
    local EspOrbitLast

    local Panel = Instance.new("Frame")
    Panel.Name = "EspPreviewPanel"
    Panel.AnchorPoint = Vector2.new(0, 0)
    Panel.Position = UDim2.fromOffset(24, 120)
    Panel.Size = UDim2.fromOffset(PanelW, PanelH)
    Panel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Panel.BackgroundTransparency = 0
    Panel.BorderSizePixel = 0
    Panel.Active = true
    Panel.Visible = true
    Panel.ClipsDescendants = true
    Panel.Parent = EspGui

    local function GetMainWindowFrame()
        local Main = Window.Elements and Window.Elements["MainFrame"] and Window.Elements["MainFrame"].Instance
        if Main and Main.Parent then
            return Main
        end
        return nil
    end

    local function AlignEspToWindow()
        if EspDraggingPanel then
            return
        end

        local Main = GetMainWindowFrame()
        if not Main then
            return
        end

        if Panel.Parent ~= EspGui then
            Panel.Parent = EspGui
        end

        if Main.AbsoluteSize.X < 50 then
            return
        end

        local Screen = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
        local Gap = math.abs(EspDockOffsetX)
        local PlaceRight = Main.AbsolutePosition.X + Main.AbsoluteSize.X + Gap + PanelW <= Screen.X - 6

        local TargetX
        if PlaceRight then
            TargetX = Main.AbsolutePosition.X + Main.AbsoluteSize.X + Gap
        else
            -- keep same gap on the left so it doesn't tuck into the main UI
            TargetX = Main.AbsolutePosition.X - PanelW - Gap
        end
        local TargetY = Main.AbsolutePosition.Y + EspDockOffsetY

        local Cur = Panel.AbsolutePosition
        if math.abs(TargetY - Cur.Y) > 80 or math.abs(TargetX - Cur.X) > 80 then
            local SeedX = PlaceRight
                and (Main.Position.X.Offset + Main.Size.X.Offset + Gap)
                or (Main.Position.X.Offset - PanelW - Gap)
            Panel.Position = UDim2.fromOffset(SeedX, Main.Position.Y.Offset + EspDockOffsetY)
            Cur = Panel.AbsolutePosition
        end

        Panel.Position = UDim2.fromOffset(
            math.floor(Panel.Position.X.Offset + (TargetX - Cur.X) + 0.5),
            math.floor(Panel.Position.Y.Offset + (TargetY - Cur.Y) + 0.5)
        )
        Panel.Size = UDim2.fromOffset(PanelW, PanelH)
        Panel.BackgroundTransparency = 0
    end

    task.defer(AlignEspToWindow)
    task.delay(0.2, AlignEspToWindow)
    task.delay(0.5, AlignEspToWindow)

    local PanelStroke = Instance.new("UIStroke")
    PanelStroke.Thickness = 1
    PanelStroke.Color = self.Theme.Outline or Color3.fromRGB(42, 42, 42)
    PanelStroke.Parent = Panel

    local Accent = Instance.new("Frame")
    Accent.Name = "Accent"
    Accent.Size = UDim2.new(1, 0, 0, 1)
    Accent.BorderSizePixel = 0
    Accent.BackgroundColor3 = self.Theme.Accent
    Accent.ZIndex = 32
    Accent.Parent = Panel

    local Header = Instance.new("TextButton")
    Header.Name = "Header"
    Header.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Header.BackgroundTransparency = 0
    Header.Position = UDim2.new(0, 0, 0, 1)
    Header.Size = UDim2.new(1, 0, 0, 24)
    Header.Text = ""
    Header.AutoButtonColor = false
    Header.Active = true
    Header.ZIndex = 30
    Header.Parent = Panel

    local HeaderLine = Instance.new("Frame")
    HeaderLine.Name = "HeaderLine"
    HeaderLine.AnchorPoint = Vector2.new(0, 1)
    HeaderLine.Position = UDim2.new(0, 0, 1, 0)
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    HeaderLine.BorderSizePixel = 0
    HeaderLine.ZIndex = 31
    HeaderLine.Parent = Header

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.fromOffset(10, 4)
    Title.Size = UDim2.new(1, -20, 0, 14)
    Title.Font = Enum.Font.Code
    Title.TextSize = 11
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextColor3 = Color3.fromRGB(210, 210, 218)
    Title.TextTransparency = 0
    Title.Text = "ESP PREVIEW"
    Title.Active = false
    Title.ZIndex = 31
    Title.Parent = Header

    -- Full-bleed viewport under header (no nested card)
    local ViewportHolder = Instance.new("Frame")
    ViewportHolder.Name = "ViewportHolder"
    ViewportHolder.Position = UDim2.new(0, 0, 0, 25)
    ViewportHolder.Size = UDim2.new(1, 0, 1, -25)
    ViewportHolder.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    ViewportHolder.BorderSizePixel = 0
    ViewportHolder.ClipsDescendants = true
    ViewportHolder.Active = true
    ViewportHolder.Parent = Panel

    local EspViewport = Instance.new("ViewportFrame")
    EspViewport.Name = "EspViewport"
    EspViewport.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    EspViewport.BackgroundTransparency = 0
    EspViewport.ImageTransparency = 0
    EspViewport.Size = UDim2.new(1, 0, 1, 0)
    EspViewport.Ambient = Color3.fromRGB(90, 95, 110)
    EspViewport.LightColor = Color3.fromRGB(255, 255, 255)
    EspViewport.LightDirection = Vector3.new(-0.45, -1, -0.65)
    EspViewport.Active = true
    EspViewport.Parent = ViewportHolder

    local EspWorld = Instance.new("WorldModel")
    EspWorld.Parent = EspViewport

    local EspCamera = Instance.new("Camera")
    EspCamera.FieldOfView = 32
    EspCamera.Parent = EspViewport
    EspViewport.CurrentCamera = EspCamera

    local DummyRoot = Instance.new("Model")
    DummyRoot.Name = "EspDummy"
    DummyRoot.Parent = EspWorld

    local ViewportNeedsReload = false

    local function EnsureViewportWorld()
        if IsUnloaded() or not EspViewport or not EspViewport.Parent then
            return false
        end

        -- Destroyed WorldModels lock Parent; recreate instead of reparenting
        if not EspWorld or EspWorld.Parent ~= EspViewport then
            local ReparentOk = false
            if EspWorld then
                ReparentOk = pcall(function()
                    EspWorld.Parent = EspViewport
                end)
            end
            if not ReparentOk or not EspWorld or EspWorld.Parent ~= EspViewport then
                EspWorld = Instance.new("WorldModel")
                local Ok = pcall(function()
                    EspWorld.Parent = EspViewport
                end)
                if not Ok or EspWorld.Parent ~= EspViewport then
                    return false
                end
                DummyRoot = nil
                ViewportNeedsReload = true
            end
        end

        if not EspCamera or EspCamera.Parent ~= EspViewport then
            if not EspCamera or not pcall(function()
                EspCamera.Parent = EspViewport
            end) then
                EspCamera = Instance.new("Camera")
                EspCamera.FieldOfView = 32
                pcall(function()
                    EspCamera.Parent = EspViewport
                end)
            end
        end

        if DummyRoot and DummyRoot.Parent ~= EspWorld then
            if not pcall(function()
                DummyRoot.Parent = EspWorld
            end) then
                DummyRoot = nil
                ViewportNeedsReload = true
            end
        end

        EspViewport.CurrentCamera = EspCamera
        EspViewport.ImageTransparency = 0
        EspViewport.BackgroundTransparency = 0
        return true
    end

    local EspPreviewBasePivot = CFrame.new()
    local EspCamLook = Vector3.new(0, 1.15, 0)
    local EspBaseDist = 8
    local EspZoom = 1

    local BodyPartNames = {
        Head = true,
        Torso = true,
        ["Left Arm"] = true,
        ["Right Arm"] = true,
        ["Left Leg"] = true,
        ["Right Leg"] = true,
        UpperTorso = true,
        LowerTorso = true,
        LeftUpperArm = true,
        LeftLowerArm = true,
        LeftHand = true,
        RightUpperArm = true,
        RightLowerArm = true,
        RightHand = true,
        LeftUpperLeg = true,
        LeftLowerLeg = true,
        LeftFoot = true,
        RightUpperLeg = true,
        RightLowerLeg = true,
        RightFoot = true,
    }

    local function GetBodyBounds(Model)
        local MinV, MaxV
        local function AddPart(Part)
            if not Part:IsA("BasePart") or Part.Name == "HumanoidRootPart" or Part.Transparency >= 0.95 then
                return
            end
            local Cf = Part.CFrame
            local Half = Part.Size * 0.5
            for _, Corner in ipairs({
                Vector3.new(-Half.X, -Half.Y, -Half.Z),
                Vector3.new(-Half.X, -Half.Y, Half.Z),
                Vector3.new(-Half.X, Half.Y, -Half.Z),
                Vector3.new(-Half.X, Half.Y, Half.Z),
                Vector3.new(Half.X, -Half.Y, -Half.Z),
                Vector3.new(Half.X, -Half.Y, Half.Z),
                Vector3.new(Half.X, Half.Y, -Half.Z),
                Vector3.new(Half.X, Half.Y, Half.Z),
            }) do
                local World = Cf:PointToWorldSpace(Corner)
                if not MinV then
                    MinV, MaxV = World, World
                else
                    MinV = Vector3.new(math.min(MinV.X, World.X), math.min(MinV.Y, World.Y), math.min(MinV.Z, World.Z))
                    MaxV = Vector3.new(math.max(MaxV.X, World.X), math.max(MaxV.Y, World.Y), math.max(MaxV.Z, World.Z))
                end
            end
        end

        for _, Part in Model:GetDescendants() do
            if BodyPartNames[Part.Name] then
                AddPart(Part)
            end
        end
        -- custom meshes (Homer, etc.)
        if not MinV then
            for _, Part in Model:GetDescendants() do
                AddPart(Part)
            end
        end

        if not MinV then
            return Vector3.new(0, 1.2, 0), Vector3.new(2, 5, 1)
        end

        local Size = MaxV - MinV
        local Center = (MinV + MaxV) * 0.5
        return Center, Size
    end

    local function RefreshCamera()
        local Dist = math.clamp(EspBaseDist * EspZoom, 2.6, 22)
        EspCamera.FieldOfView = 32
        -- mostly frontal so the face/hat read clearly
        local Offset = Vector3.new(Dist * 0.04, Dist * 0.08 + 0.2, Dist)
        EspCamera.CFrame = CFrame.new(EspCamLook + Offset, EspCamLook)
    end

    local function SetZoom(Next)
        EspZoom = math.clamp(Next, 0.32, 3.2)
        RefreshCamera()
    end

    local function ApplyPreviewPivot(Model, Angle)
        Angle = Angle or EspPreviewAngle
        if not Model or not Model.Parent then
            return
        end
        Model:PivotTo(CFrame.Angles(0, Angle, 0) * EspPreviewBasePivot)
    end

    local function CenterAndFace(Model)
        local Center = GetBodyBounds(Model)
        local Pivot = Model:GetPivot()
        Model:PivotTo(CFrame.new(-Center) * Pivot)

        Center = GetBodyBounds(Model)
        Pivot = Model:GetPivot()
        if Center.Magnitude > 0.05 then
            Model:PivotTo(CFrame.new(-Center) * Pivot)
        end

        RefreshCamera()
        local Pos = Model:GetPivot().Position
        local CamPos = EspCamera.CFrame.Position
        local LookAt = Vector3.new(CamPos.X, Pos.Y, CamPos.Z)
        if (LookAt - Pos).Magnitude < 0.05 then
            LookAt = Pos + Vector3.new(0, 0, 1)
        end
        -- face the camera (chest / face toward viewer)
        Model:PivotTo(CFrame.lookAt(Pos, LookAt))
        EspPreviewBasePivot = Model:GetPivot()
        EspPreviewAngle = 0
        ApplyPreviewPivot(Model, 0)
    end

    local function FitCamera(Model)
        local _, Size = GetBodyBounds(Model)
        local Height = math.clamp(Size.Y, 4, 7.2)
        local Width = math.clamp(math.max(Size.X, Size.Z), 1.4, 4.5)

        -- center a bit lower so feet aren't clipped into a fake "platform" band
        EspCamLook = Vector3.new(0, Height * 0.02, 0)
        local HalfFov = math.rad(32 * 0.5)
        local DistH = ((Height * 0.55) * 1.42) / math.tan(HalfFov)
        local DistW = ((Width * 0.5) * 1.55) / math.tan(HalfFov)
        EspBaseDist = math.clamp(math.max(DistH, DistW), 6.2, 14.5)
        -- keep the user's scroll zoom (don't reset to 1 on dance / reload)
        RefreshCamera()
    end

    local function CachePartLooks(Model)
        table.clear(PartLooks)
        for _, Part in Model:GetDescendants() do
            if Part:IsA("BasePart") then
                PartLooks[Part] = {
                    Color = Part.Color,
                    Material = Part.Material,
                    Transparency = Part.Transparency,
                }
            end
        end
    end

    local function StripScripts(Model, ForDance)
        local Root = Model:FindFirstChild("HumanoidRootPart")
        for _, Child in Model:GetDescendants() do
            if Child:IsA("BaseScript") or Child:IsA("LocalScript") or Child:IsA("Script") then
                Child:Destroy()
            elseif Child:IsA("BasePart") then
                if ForDance then
                    Child.Anchored = (Child == Root)
                else
                    Child.Anchored = true
                end
                Child.CanCollide = false
                Child.CanQuery = false
                Child.CanTouch = false
                Child.CastShadow = false
            end
        end

        if Root and Root:IsA("BasePart") then
            Root.Anchored = true
            Root.Transparency = 1
            Root.LocalTransparencyModifier = 1
        end

        local Animate = Model:FindFirstChild("Animate")
        if Animate then
            Animate:Destroy()
        end
    end

    local function ResetIdlePose(Model)
        -- Cloned characters keep the live walk/run Motor6D pose; snap back to bind pose.
        local Hum = Model:FindFirstChildOfClass("Humanoid")
        if Hum then
            local Animator = Hum:FindFirstChildOfClass("Animator")
            if Animator then
                for _, Track in Animator:GetPlayingAnimationTracks() do
                    pcall(function()
                        Track:Stop(0)
                    end)
                end
            end
        end

        local Root = Model:FindFirstChild("HumanoidRootPart")
        for _, Part in Model:GetDescendants() do
            if Part:IsA("BasePart") then
                Part.Anchored = (Part == Root)
                Part.CanCollide = false
            end
        end

        for _, Motor in Model:GetDescendants() do
            if Motor:IsA("Motor6D") then
                pcall(function()
                    Motor.Transform = CFrame.new()
                end)
            end
        end

        -- one frame so WorldModel applies joint bind poses before we freeze
        task.wait()

        for _, Part in Model:GetDescendants() do
            if Part:IsA("BasePart") then
                Part.Anchored = true
            end
        end
        if Root and Root:IsA("BasePart") then
            Root.Anchored = true
            Root.Transparency = 1
            Root.LocalTransparencyModifier = 1
        end
    end

    local EspDanceName = "None"
    local EspDanceSpeed = 1
    local EspSpinEnabled = true
    local EspPreviewModelMode = "Avatar"
    local CurrentDanceTrack = nil

    -- Bundle models for ESP Preview (bundleId + fallback outfitId)
    local EspPreviewBundles = {
        ["Homer"] = {
            Bundle = 165947147598778,
            Outfit = 2384272480563334,
        },
        ["Mini Skeleton"] = {
            Bundle = 207380569083132,
            Outfit = 3272644562096681,
        },
        ["Banana Bro"] = {
            Bundle = 600498,
            Outfit = 665222063604577,
        },
        ["Tired Depressed SpongeBob"] = {
            Bundle = 202718690054997,
            Outfit = 2668521187590890,
        },
        ["Peely"] = {
            Bundle = 247992144265771,
            Outfit = 1030066363910995,
        },
        ["Kermit The Frog"] = {
            Bundle = 272740147009759,
            Outfit = 1682885137426127,
        },
        ["Tuff Trollface Spongebob"] = {
            Bundle = 184181553788045,
            Outfit = 6493152179404236,
        },
        ["Skinwalker Anomaly"] = {
            Bundle = 115677962344385,
            Outfit = 5355402959910568,
        },
        ["Tom and Jerry"] = {
            Bundle = 212354003120539,
            Outfit = 2062854793752157,
        },
        ["Funny Ben"] = {
            Bundle = 37537184526782,
            Outfit = 5167602345021025,
        },
        ["Smirking Spongebob"] = {
            Bundle = 260650943313748,
            Outfit = 6084577130801091,
        },
        ["Perry 2D"] = {
            Bundle = 203275699394538,
            Outfit = 1496798899118389,
        },
        ["CJ GTA San Andreas"] = {
            Bundle = 147560561555974,
            Outfit = 1726166931986917,
        },
        ["Israel Tung Tung Sahur"] = {
            Bundle = 200433974847944,
            Outfit = 6671890568914250,
        },
        ["Tuff Doctor Pigeon Surgeon"] = {
            Bundle = 36549537714490,
            Outfit = 4712115037825922,
        },
        ["Tung Tung Devil Demon"] = {
            Bundle = 145871576301740,
            Outfit = 5392680228003092,
        },
        ["Tung Tung GOD"] = {
            Bundle = 136575294706685,
            Outfit = 5386561910236658,
        },
        ["TUNG Tung Sahur Triple T"] = {
            Bundle = 164815366314625,
            Outfit = 5016826056399617,
        },
    }

    local function BuildBundleModel(BundleName)
        local Entry = EspPreviewBundles[BundleName]
        if not Entry then
            return nil
        end

        local BundleId = Entry.Bundle
        local OutfitId = Entry.Outfit

        pcall(function()
            local Details = game:GetService("AssetService"):GetBundleDetailsAsync(BundleId)
            if type(Details) == "table" and type(Details.Items) == "table" then
                for _, Item in Details.Items do
                    if Item.Type == "UserOutfit" and Item.Id then
                        OutfitId = Item.Id
                        break
                    end
                end
            end
        end)

        local OkDesc, Desc = pcall(function()
            return Players:GetHumanoidDescriptionFromOutfitId(OutfitId)
        end)
        if not OkDesc or not Desc then
            return nil
        end

        local OkModel, Model = pcall(function()
            return Players:CreateHumanoidModelFromDescription(Desc, Enum.HumanoidRigType.R15)
        end)
        if OkModel and Model then
            return Model
        end
        return nil
    end

    local function IsBundlePreviewModel(Mode)
        return EspPreviewBundles[Mode] ~= nil
    end

    local function CloneLiveCharacter()
        local Char = LocalPlayer and LocalPlayer.Character
        if not (Char and Char:FindFirstChildOfClass("Humanoid")) then
            return nil
        end
        local Ok, Clone = pcall(function()
            Char.Archivable = true
            local Copy = Char:Clone()
            Char.Archivable = false
            return Copy
        end)
        if Ok then
            return Clone
        end
        return nil
    end

    local function DescriptionLooksEmpty(Desc)
        if not Desc then
            return true
        end
        local Ok, Empty = pcall(function()
            local Hat = tostring(Desc.HatAccessory or "")
            local Hair = tostring(Desc.HairAccessory or "")
            local FaceAcc = tostring(Desc.FaceAccessory or "")
            return (tonumber(Desc.Shirt) or 0) == 0
                and (tonumber(Desc.Pants) or 0) == 0
                and (tonumber(Desc.GraphicTShirt) or 0) == 0
                and (tonumber(Desc.Face) or 0) == 0
                and Hat == ""
                and Hair == ""
                and FaceAcc == ""
        end)
        return (not Ok) or Empty
    end

    local function CreateAppearanceModel(PreferR15)
        -- Prefer catalog avatar from UserId. Games like Animal Hospital wipe
        -- GetAppliedDescription() (all 0s) → grey dummy, and nest a custom
        -- CharacterModel (bunny) that cannot play catalog emotes.
        local Desc
        local OkUser, FromUser = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
        end)
        if OkUser then
            Desc = FromUser
        end

        local Char = LocalPlayer and LocalPlayer.Character
        local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
        if Hum then
            local OkApplied, Applied = pcall(function()
                return Hum:GetAppliedDescription()
            end)
            if OkApplied and Applied and not DescriptionLooksEmpty(Applied) then
                Desc = Applied
            end
        end

        if not Desc then
            return nil
        end

        local Rig = Enum.HumanoidRigType.R15
        if not PreferR15 and Hum and Hum.RigType == Enum.HumanoidRigType.R6 then
            Rig = Enum.HumanoidRigType.R6
        end

        local Ok, Model = pcall(function()
            return Players:CreateHumanoidModelFromDescription(Desc, Rig)
        end)
        if Ok then
            return Model
        end
        return nil
    end

    local function SanitizePreviewModel(Model)
        -- drop game-only visual rigs that block Humanoid emotes
        local Nested = Model:FindFirstChild("CharacterModel")
        if Nested then
            Nested:Destroy()
        end
        for _, Child in Model:GetDescendants() do
            if Child:IsA("AnimationController") and not Child:FindFirstAncestorWhichIsA("Humanoid") then
                -- keep Animator under Humanoid only
            end
        end
        return Model
    end

    local EspDances = {
        ["None"] = nil,
        -- catalog emote id → real AnimationId (GetObjects)
        ["Jamal Brazil"] = {
            Catalog = 104131847054135,
            Animation = 83796130837213,
        },
        ["Needy Circle Shake"] = {
            Catalog = 127793648830483,
            Animation = 122244106178521,
        },
        ["Chinese Dance"] = {
            Catalog = 104539498095025,
            Animation = 131564504226925,
        },
        ["King Nas"] = {
            Catalog = 72939632950458,
            Animation = 111547449908469,
        },
        ["Street Glide"] = {
            Catalog = 137284968787523,
            Animation = 82378883639086,
        },
        ["HYPER SHAKE"] = {
            Catalog = 93969193899575,
            Animation = 72884652153223,
        },
        ["Blue Shirt Kid Sturdy"] = {
            Catalog = 93659771713494,
            Animation = 87489884051688,
        },
        ["Cristiano Ronaldo SIU"] = {
            Catalog = 115392964685334,
            Animation = 123155768388003,
        },
        ["w zesty sturdy"] = {
            Catalog = 104278650550369,
            Animation = 115992344778101,
        },
        ["NLE WISH DANCE"] = {
            Catalog = 133293268056643,
            Animation = 139505173512234,
        },
    }

    local EspCustomAnimId = nil

    local function ResolveAssetToAnimationId(AssetId)
        AssetId = tonumber(tostring(AssetId or ""):match("%d+"))
        if not AssetId then
            return nil
        end

        local Resolved = AssetId
        pcall(function()
            local Objects
            if game.GetObjects then
                Objects = game:GetObjects("rbxassetid://" .. tostring(AssetId))
            elseif getobjects then
                Objects = getobjects("rbxassetid://" .. tostring(AssetId))
            end
            if type(Objects) ~= "table" then
                return
            end
            for _, Obj in Objects do
                local Found = Obj
                if not Found:IsA("Animation") then
                    Found = Obj:FindFirstChildWhichIsA("Animation", true)
                end
                if Found and Found:IsA("Animation") then
                    local Id = tostring(Found.AnimationId):match("%d+")
                    if Id then
                        Resolved = tonumber(Id) or Resolved
                    end
                    break
                end
            end
        end)

        return Resolved
    end

    local function ResolveDanceAnimationId(Entry)
        if type(Entry) == "number" then
            return ResolveAssetToAnimationId(Entry)
        end
        if type(Entry) ~= "table" then
            return nil
        end

        local Resolved = Entry.Animation or Entry.Catalog
        pcall(function()
            local AssetId = Entry.Catalog or Entry.Animation
            if not AssetId then
                return
            end
            local FromAsset = ResolveAssetToAnimationId(AssetId)
            if FromAsset then
                Resolved = FromAsset
            end
        end)

        return Resolved
    end

    local function StopDance()
        if CurrentDanceTrack then
            pcall(function()
                CurrentDanceTrack:Stop(0)
            end)
            CurrentDanceTrack = nil
        end

        local Subject = DummyRoot
        if Subject and Subject.Parent then
            -- put back in viewport and freeze for idle spin
            if Subject.Parent ~= EspWorld then
                Subject.Parent = EspWorld
            end
            StripScripts(Subject, false)
            for _, Motor in Subject:GetDescendants() do
                if Motor:IsA("Motor6D") then
                    pcall(function()
                        Motor.Transform = CFrame.new()
                    end)
                end
            end
            Subject:PivotTo(EspPreviewBasePivot)
        end

        local Proxy = workspace:FindFirstChild(DanceProxyName)
        if Proxy then
            pcall(function()
                Proxy:Destroy()
            end)
        end

        EspSpinEnabled = true
    end

    local function GetPreviewSubject()
        if DummyRoot and DummyRoot.Parent and DummyRoot:FindFirstChildOfClass("Humanoid") then
            return DummyRoot
        end
        local Subject = EspWorld:FindFirstChild("Character")
        if Subject and Subject:IsA("Model") then
            return Subject
        end
        return nil
    end

    local function PlayDance(Name)
        if type(Name) == "table" then
            Name = Name[1] or Name.Name or "None"
        end
        EspDanceName = tostring(Name or "None")

        local AnimId
        if EspDanceName == "Custom" and EspCustomAnimId then
            AnimId = ResolveAssetToAnimationId(EspCustomAnimId)
        else
            EspCustomAnimId = nil
            AnimId = ResolveDanceAnimationId(EspDances[EspDanceName])
        end

        -- stop previous track but keep current preview visible until the new dancer is ready
        if CurrentDanceTrack then
            pcall(function()
                CurrentDanceTrack:Stop(0)
            end)
            CurrentDanceTrack = nil
        end
        local Leftover = workspace:FindFirstChild(DanceProxyName)
        if Leftover then
            pcall(function()
                Leftover:Destroy()
            end)
        end

        if not AnimId then
            EspSpinEnabled = true
            local Subject = GetPreviewSubject()
            if Subject then
                StripScripts(Subject, false)
                CenterAndFace(Subject)
            end
            return
        end

        -- Prefer selected preview model (Avatar / catalog bundles)
        local Dancer
        if IsBundlePreviewModel(EspPreviewModelMode) then
            Dancer = BuildBundleModel(EspPreviewModelMode)
        end
        if not Dancer then
            Dancer = CreateAppearanceModel(true)
        end
        if not Dancer then
            Dancer = CloneLiveCharacter()
            if Dancer then
                SanitizePreviewModel(Dancer)
            end
        end
        if not Dancer then
            return
        end

        SanitizePreviewModel(Dancer)

        -- Animations must start in Workspace, then move into WorldModel (keeps playing).
        StripScripts(Dancer, true)
        Dancer.Name = DanceProxyName
        Dancer.Parent = workspace

        local Root = Dancer:FindFirstChild("HumanoidRootPart")
        if Root and Root:IsA("BasePart") then
            Root.Anchored = true
            Root.CFrame = CFrame.new(0, -2500, 0)
        end

        local Hum = Dancer:FindFirstChildOfClass("Humanoid")
        if not Hum then
            Dancer:Destroy()
            return
        end
        Hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        Hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        Hum.AutoRotate = false
        pcall(function()
            Hum.PlatformStand = true
        end)

        local Animator = Hum:FindFirstChildOfClass("Animator")
        if not Animator then
            Animator = Instance.new("Animator")
            Animator.Parent = Hum
        end

        local Anim = Instance.new("Animation")
        Anim.Name = "EspDance"
        Anim.AnimationId = "rbxassetid://" .. tostring(AnimId)
        Anim.Parent = Hum

        pcall(function()
            ContentProvider:PreloadAsync({Anim})
        end)

        local Track
        local Ok = pcall(function()
            Track = Animator:LoadAnimation(Anim)
        end)
        if not Ok or not Track then
            Ok = pcall(function()
                Track = Hum:LoadAnimation(Anim)
            end)
        end
        if not Ok or not Track then
            Dancer:Destroy()
            return
        end

        Track.Looped = true
        Track.Priority = Enum.AnimationPriority.Action4
        Track:Play(0.05, 1, EspDanceSpeed)

        local Started = false
        for _ = 1, 40 do
            if Track.Length and Track.Length > 0 and Track.IsPlaying then
                Started = true
                break
            end
            task.wait(0.05)
            if IsUnloaded() then
                Dancer:Destroy()
                return
            end
        end

        if not Started then
            Track:Stop(0)
            Dancer:Destroy()
            return
        end

        -- swap into viewport; track keeps playing inside WorldModel
        if DummyRoot and DummyRoot.Parent then
            DummyRoot:Destroy()
        end
        table.clear(PartLooks)

        Dancer.Name = "Character"
        Dancer.Parent = EspWorld
        DummyRoot = Dancer

        CenterAndFace(Dancer)
        CachePartLooks(Dancer)
        FitCamera(Dancer)
        DummyRoot:SetAttribute("Ready", true)

        if Root and Root:IsA("BasePart") then
            Root.Anchored = true
        end

        CurrentDanceTrack = Track
        EspSpinEnabled = true
    end

    local function PlaceModel(Model)
        EnsureViewportWorld()
        StopDance()

        if DummyRoot and DummyRoot.Parent then
            DummyRoot:Destroy()
        end
        table.clear(PartLooks)

        Model.Name = "Character"
        Model.Parent = EspWorld
        DummyRoot = Model
        SanitizePreviewModel(Model)
        StripScripts(Model, false)
        ResetIdlePose(Model)

        CenterAndFace(Model)
        CachePartLooks(Model)
        FitCamera(Model)
        DummyRoot:SetAttribute("Ready", true)
        RefreshCamera()

        if EspDanceName ~= "None" then
            task.defer(function()
                PlayDance(EspDanceName)
            end)
        end
    end

    local function BuildFallbackDummy()
        EnsureViewportWorld()
        StopDance()

        if DummyRoot and DummyRoot.Parent then
            DummyRoot:Destroy()
        end
        table.clear(PartLooks)

        local Fallback = Instance.new("Model")
        Fallback.Name = "Character"
        Fallback.Parent = EspWorld
        DummyRoot = Fallback

        local function Limb(Name, Size, At, Color)
            local Part = Instance.new("Part")
            Part.Name = Name
            Part.Anchored = true
            Part.CanCollide = false
            Part.Material = Enum.Material.SmoothPlastic
            Part.Color = Color
            Part.Size = Size
            Part.CFrame = At
            Part.Parent = Fallback
            return Part
        end

        local Skin = Color3.fromRGB(204, 142, 105)
        Limb("Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 2.4, 0), Skin)
        Limb("Torso", Vector3.new(2, 2, 1), CFrame.new(0, 1.1, 0), Color3.fromRGB(40, 40, 45))
        Limb("Left Arm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 1.1, 0), Skin)
        Limb("Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 1.1, 0), Skin)
        Limb("Left Leg", Vector3.new(1, 2, 1), CFrame.new(-0.5, -0.9, 0), Color3.fromRGB(30, 30, 34))
        Limb("Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, -0.9, 0), Color3.fromRGB(30, 30, 34))
        Fallback.PrimaryPart = Fallback:FindFirstChild("Torso")
        CenterAndFace(Fallback)
        CachePartLooks(Fallback)
        FitCamera(Fallback)
        RefreshCamera()
        Fallback:SetAttribute("Ready", true)
    end

    local function LoadCharacter()
        EnsureViewportWorld()
        local Loaded = false

        if IsBundlePreviewModel(EspPreviewModelMode) then
            local BundleModel = BuildBundleModel(EspPreviewModelMode)
            if BundleModel then
                PlaceModel(BundleModel)
                return
            end
            -- fall through to avatar if bundle fails
        end

        -- Appearance model starts in default stand pose (avoids cloning mid-walk)
        local Model = CreateAppearanceModel(true)
        if Model then
            PlaceModel(Model)
            Loaded = true
        end

        if not Loaded then
            local Clone = CloneLiveCharacter()
            if Clone then
                PlaceModel(Clone)
                Loaded = true
            end
        end

        if not Loaded then
            BuildFallbackDummy()
        end
    end

    SetEspPreviewModel = function(Mode)
        if type(Mode) == "table" then
            Mode = Mode[1] or Mode.Name or "Avatar"
        end
        EspPreviewModelMode = tostring(Mode or "Avatar")
        if IsBundlePreviewModel(EspPreviewModelMode) then
            -- keep current emote; R15 bundles can dance
            StopDance()
        end
        LoadCharacter()
    end

    SetEspPreviewDance = function(Name)
        task.spawn(function()
            if type(Name) == "table" then
                Name = Name[1] or Name.Name or "None"
            end
            Name = tostring(Name or "None")
            if Name == "None" or Name == "" then
                EspDanceName = "None"
                EspCustomAnimId = nil
                StopDance()
                -- rebuild standing preview (don't keep walk/dance pose)
                LoadCharacter()
                return
            end
            EspCustomAnimId = nil
            PlayDance(Name)
        end)
    end

    SetEspPreviewDanceById = function(Raw)
        task.spawn(function()
            local Digits = tostring(Raw or ""):match("%d+")
            local Id = tonumber(Digits)
            if not Id then
                EspDanceName = "None"
                EspCustomAnimId = nil
                StopDance()
                LoadCharacter()
                return
            end
            EspCustomAnimId = Id
            PlayDance("Custom")
        end)
    end

    SetEspPreviewDanceSpeed = function(Speed)
        EspDanceSpeed = math.clamp(tonumber(Speed) or 1, 0.1, 3)
        if CurrentDanceTrack then
            pcall(function()
                CurrentDanceTrack:AdjustSpeed(EspDanceSpeed)
            end)
        end
    end

    BuildFallbackDummy()
    task.spawn(LoadCharacter)
    local CharAddedConnection
    if LocalPlayer then
        CharAddedConnection = LocalPlayer.CharacterAdded:Connect(function()
            if not IsUnloaded() then
                task.defer(LoadCharacter)
            end
        end)
    end
    task.delay(1, function()
        if IsUnloaded() then
            return
        end
        if not DummyRoot or DummyRoot:GetAttribute("Ready") ~= true or not DummyRoot:FindFirstChildOfClass("Humanoid") then
            LoadCharacter()
        end
    end)

    local Overlay = Instance.new("Frame")
    Overlay.Name = "EspOverlay"
    Overlay.BackgroundTransparency = 1
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.ZIndex = 5
    Overlay.Parent = EspViewport

    local Box = Instance.new("Frame")
    Box.Name = "Box"
    Box.AnchorPoint = Vector2.new(0, 0)
    Box.Position = UDim2.fromOffset(0, 0)
    Box.Size = UDim2.fromOffset(110, 240)
    Box.BackgroundTransparency = 1
    Box.BorderSizePixel = 0
    Box.Visible = false
    Box.ZIndex = 6
    Box.Parent = Overlay

    local BoxWhite = Color3.fromRGB(255, 255, 255)
    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.Name = "BoxStroke"
    BoxStroke.Thickness = 1
    BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    BoxStroke.LineJoinMode = Enum.LineJoinMode.Miter
    BoxStroke.Color = BoxWhite
    BoxStroke.Parent = Box

    local NameTag = Instance.new("TextLabel")
    NameTag.Name = "NameTag"
    NameTag.AnchorPoint = Vector2.new(0.5, 1)
    NameTag.Position = UDim2.new(0.5, 0, 0, -4)
    NameTag.Size = UDim2.new(1, 24, 0, 14)
    NameTag.BackgroundTransparency = 1
    NameTag.Font = Enum.Font.Code
    NameTag.TextSize = 11
    NameTag.TextColor3 = EspPreviewColor
    NameTag.TextStrokeTransparency = 0.35
    NameTag.Text = LocalPlayer and LocalPlayer.DisplayName or "enemy"
    NameTag.Visible = false
    NameTag.ZIndex = 7
    NameTag.Parent = Box

    -- Classic healthbar: black outline + clipped multi-color gradient (degradado)
    local HealthOutline = Instance.new("Frame")
    HealthOutline.Name = "HealthOutline"
    HealthOutline.AnchorPoint = Vector2.new(1, 0)
    HealthOutline.Position = UDim2.new(0, -4, 0, 0)
    HealthOutline.Size = UDim2.new(0, 4, 1, 0)
    HealthOutline.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    HealthOutline.BorderSizePixel = 0
    HealthOutline.Visible = false
    HealthOutline.ZIndex = 7
    HealthOutline.Parent = Box

    local HealthBack = Instance.new("Frame")
    HealthBack.Name = "HealthBack"
    HealthBack.AnchorPoint = Vector2.new(0.5, 0.5)
    HealthBack.Position = UDim2.new(0.5, 0, 0.5, 0)
    HealthBack.Size = UDim2.new(1, -2, 1, -2)
    HealthBack.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    HealthBack.BorderSizePixel = 0
    HealthBack.ClipsDescendants = true
    HealthBack.ZIndex = 8
    HealthBack.Parent = HealthOutline

    local HealthClip = Instance.new("Frame")
    HealthClip.Name = "HealthClip"
    HealthClip.AnchorPoint = Vector2.new(0, 1)
    HealthClip.Position = UDim2.new(0, 0, 1, 0)
    HealthClip.Size = UDim2.new(1, 0, 0, 0)
    HealthClip.BackgroundTransparency = 1
    HealthClip.BorderSizePixel = 0
    HealthClip.ClipsDescendants = true
    HealthClip.ZIndex = 9
    HealthClip.Parent = HealthBack

    local HealthSpectrum = Instance.new("Frame")
    HealthSpectrum.Name = "HealthSpectrum"
    HealthSpectrum.AnchorPoint = Vector2.new(0, 1)
    HealthSpectrum.Position = UDim2.new(0, 0, 1, 0)
    HealthSpectrum.Size = UDim2.new(1, 0, 1, 0)
    HealthSpectrum.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HealthSpectrum.BorderSizePixel = 0
    HealthSpectrum.ZIndex = 10
    HealthSpectrum.Parent = HealthClip

    local HealthGradient = Instance.new("UIGradient")
    HealthGradient.Name = "HealthGradient"
    HealthGradient.Rotation = 90 -- top → bottom
    -- classic ESP degradado (green → yellow → red)
    HealthGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
    })
    HealthGradient.Parent = HealthSpectrum

    local DistanceTag = Instance.new("TextLabel")
    DistanceTag.Name = "Distance"
    DistanceTag.AnchorPoint = Vector2.new(0.5, 0)
    DistanceTag.Position = UDim2.new(0.5, 0, 1, 2)
    DistanceTag.Size = UDim2.new(1, 20, 0, 12)
    DistanceTag.BackgroundTransparency = 1
    DistanceTag.Font = Enum.Font.Code
    DistanceTag.TextSize = 10
    DistanceTag.TextColor3 = Color3.fromRGB(190, 190, 198)
    DistanceTag.TextStrokeTransparency = 0.45
    DistanceTag.Text = "42m"
    DistanceTag.Visible = false
    DistanceTag.ZIndex = 7
    DistanceTag.Parent = Box

    -- healthbar only: bottom → top fill loop + fixed gradient reveal
    local EspAnimClock = 0

    local function AnyEspOverlay()
        return EspBoxEnabled or EspNameEnabled or EspHealthEnabled
    end

    local function Smoothstep(T)
        T = math.clamp(T, 0, 1)
        return T * T * (3 - 2 * T)
    end

    RequestEspHealthAnim = function()
        EspAnimClock = 0
        EspHealthValue = 0.05
    end

    local function AutoHealthAmount(Clock)
        -- fill bottom→top, hold, drain, repeat
        local Cycle = Clock % 3.2
        local Amount
        if Cycle < 1.35 then
            Amount = Smoothstep(Cycle / 1.35)
        elseif Cycle < 2.05 then
            Amount = 1
        else
            Amount = 1 - Smoothstep((Cycle - 2.05) / 1.15)
        end
        return 0.08 + Amount * 0.92
    end

    local function ApplyHealthBarVisuals()
        HealthOutline.Visible = EspHealthEnabled
        if not EspHealthEnabled then
            HealthClip.Size = UDim2.new(1, 0, 0, 0)
            return
        end

        local Amount = math.clamp(EspHealthValue, 0.001, 1)
        HealthClip.Size = UDim2.new(1, 0, Amount, 0)
        -- keep full-bar gradient fixed while clip reveals from bottom
        HealthSpectrum.Size = UDim2.new(1, 0, 1 / Amount, 0)
    end

    local function ApplyOverlayVisibility()
        Box.Visible = AnyEspOverlay()
        BoxStroke.Enabled = EspBoxEnabled
        BoxStroke.Transparency = EspBoxEnabled and 0 or 1
        BoxStroke.Color = BoxWhite

        NameTag.Visible = EspNameEnabled
        DistanceTag.Visible = EspNameEnabled
        NameTag.TextTransparency = EspNameEnabled and 0 or 1
        NameTag.TextStrokeTransparency = EspNameEnabled and 0.35 or 1
        DistanceTag.TextTransparency = EspNameEnabled and 0 or 1
        DistanceTag.TextStrokeTransparency = EspNameEnabled and 0.45 or 1

        ApplyHealthBarVisuals()
    end

    local function IsOver(GuiObject, Position)
        local AbsPos = GuiObject.AbsolutePosition
        local AbsSize = GuiObject.AbsoluteSize
        return Position.X >= AbsPos.X
            and Position.X <= AbsPos.X + AbsSize.X
            and Position.Y >= AbsPos.Y
            and Position.Y <= AbsPos.Y + AbsSize.Y
    end

    Header.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            EspDraggingPanel = true
            EspDragStart = Input.Position
            EspPanelStart = Panel.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(Input)
        if not EspDraggingPanel then
            return
        end
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            EspDraggingPanel = false
        end
    end)

    EspViewport.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            EspDraggingOrbit = true
            EspOrbitLast = Input.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(Input)
        if EspDraggingOrbit and (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
            EspDraggingOrbit = false
        end
    end)

    UserInputService.InputChanged:Connect(function(Input)
        if IsUnloaded() or not EspGui.Enabled then
            return
        end

        if EspDraggingPanel and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
            local Delta = Input.Position - EspDragStart
            Panel.Position = UDim2.new(
                EspPanelStart.X.Scale,
                EspPanelStart.X.Offset + Delta.X,
                EspPanelStart.Y.Scale,
                EspPanelStart.Y.Offset + Delta.Y
            )
            return
        end

        if EspDraggingOrbit and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
            local Delta = Input.Position - EspOrbitLast
            EspOrbitLast = Input.Position
            EspPreviewAngle += Delta.X * 0.01
            ApplyPreviewPivot(DummyRoot, EspPreviewAngle)
            return
        end

        if Input.UserInputType == Enum.UserInputType.MouseWheel then
            local Mouse = UserInputService:GetMouseLocation()
            if IsOver(ViewportHolder, Mouse) then
                SetZoom(EspZoom - Input.Position.Z * 0.18)
            end
        end
    end)

    local CornerOffsets = {
        Vector3.new(-1, -1, -1),
        Vector3.new(-1, -1, 1),
        Vector3.new(-1, 1, -1),
        Vector3.new(-1, 1, 1),
        Vector3.new(1, -1, -1),
        Vector3.new(1, -1, 1),
        Vector3.new(1, 1, -1),
        Vector3.new(1, 1, 1),
    }

    local function WorldToOverlay(WorldPos)
        local ViewSize = EspViewport.AbsoluteSize
        if ViewSize.X < 2 or ViewSize.Y < 2 then
            return nil
        end

        local Relative = EspCamera.CFrame:PointToObjectSpace(WorldPos)
        -- camera looks down -Z; visible points have Relative.Z < 0
        if Relative.Z >= -0.05 then
            return nil
        end

        local Aspect = ViewSize.X / ViewSize.Y
        local TanHalf = math.tan(math.rad(EspCamera.FieldOfView * 0.5))
        local NdcX = (Relative.X / -Relative.Z) / (TanHalf * Aspect)
        local NdcY = (Relative.Y / -Relative.Z) / TanHalf
        local ScreenX = (NdcX + 1) * 0.5 * ViewSize.X
        local ScreenY = (1 - NdcY) * 0.5 * ViewSize.Y
        return Vector2.new(ScreenX, ScreenY)
    end

    local function UpdateEspBox()
        if not AnyEspOverlay() or not DummyRoot or not DummyRoot.Parent then
            return
        end

        local ViewportSize = EspViewport.AbsoluteSize
        if ViewportSize.X < 2 or ViewportSize.Y < 2 then
            return
        end

        local MinX, MinY = math.huge, math.huge
        local MaxX, MaxY = -math.huge, -math.huge
        local Hits = 0

        for _, Part in DummyRoot:GetDescendants() do
            if not Part:IsA("BasePart") then
                continue
            end
            if Part.Name == "HumanoidRootPart" or Part.Transparency >= 0.95 then
                continue
            end

            local Half = Part.Size * 0.5
            local Cf = Part.CFrame
            for _, Corner in CornerOffsets do
                local World = Cf:PointToWorldSpace(Vector3.new(
                    Corner.X * Half.X,
                    Corner.Y * Half.Y,
                    Corner.Z * Half.Z
                ))
                local Screen = WorldToOverlay(World)
                if Screen then
                    Hits += 1
                    MinX = math.min(MinX, Screen.X)
                    MaxX = math.max(MaxX, Screen.X)
                    MinY = math.min(MinY, Screen.Y)
                    MaxY = math.max(MaxY, Screen.Y)
                end
            end
        end

        if Hits < 2 or MinX == math.huge then
            return
        end

        local PadX, PadY = 10, 18
        MinX = math.clamp(MinX - PadX, 8, ViewportSize.X - 8)
        MaxX = math.clamp(MaxX + PadX, 8, ViewportSize.X - 8)
        MinY = math.clamp(MinY - PadY, 16, ViewportSize.Y - 16)
        MaxY = math.clamp(MaxY + PadY, 16, ViewportSize.Y - 16)

        if MaxX < MinX then
            MinX, MaxX = MaxX, MinX
        end
        if MaxY < MinY then
            MinY, MaxY = MaxY, MinY
        end

        local Width = math.max(12, MaxX - MinX)
        local Height = math.max(12, MaxY - MinY)
        -- keep name / distance tags inside the preview
        local TopRoom = 16
        local BottomRoom = 14
        if MinY < TopRoom then
            local Shift = TopRoom - MinY
            MinY += Shift
            MaxY = math.min(ViewportSize.Y - BottomRoom, MaxY + Shift)
            Height = math.max(12, MaxY - MinY)
        end
        if MaxY > ViewportSize.Y - BottomRoom then
            Height = math.max(12, (ViewportSize.Y - BottomRoom) - MinY)
        end

        Box.AnchorPoint = Vector2.new(0, 0)
        Box.Position = UDim2.fromOffset(MinX, MinY)
        Box.Size = UDim2.fromOffset(Width, Height)
        ApplyOverlayVisibility()
    end

    ApplyEspPreviewOverlays = function()
        Accent.BackgroundColor3 = self.Theme.Accent or Color3.fromRGB(179, 100, 122)
        -- gamesense: panel outline stays dark; accent is only the top hairline
        PanelStroke.Color = self.Theme.Outline or Color3.fromRGB(42, 42, 42)
        BoxStroke.Color = BoxWhite
        NameTag.TextColor3 = EspPreviewColor
        NameTag.Text = LocalPlayer and LocalPlayer.DisplayName or "enemy"
        if AnyEspOverlay() then
            UpdateEspBox()
        else
            ApplyOverlayVisibility()
        end

        for _, Part in DummyRoot:GetDescendants() do
            if not Part:IsA("BasePart") then
                continue
            end

            local Look = PartLooks[Part]
            if not Look then
                Look = {
                    Color = Part.Color,
                    Material = Part.Material,
                    Transparency = Part.Transparency,
                }
                PartLooks[Part] = Look
            end

            if EspChamsEnabled then
                Part.Material = Enum.Material.ForceField
                Part.Color = EspPreviewColor
                Part.Transparency = 0.3
            else
                Part.Material = Look.Material
                Part.Color = Look.Color
                Part.Transparency = Look.Transparency
            end
        end
    end

    UpdateEspPreview = function()
        local Show = Window.IsOpen and not IsUnloaded()
        EspGui.Enabled = Show and true or false
        AlignEspToWindow()
        Panel.BackgroundTransparency = 0
        if not EnsureViewportWorld() then
            return
        end
        if ViewportNeedsReload then
            ViewportNeedsReload = false
            task.defer(LoadCharacter)
            return
        end
        if Show then
            ApplyEspPreviewOverlays()
        end
    end

    ApplyEspPreviewOverlays()

    EspPreviewConnection = RunService.RenderStepped:Connect(function(Delta)
        if IsUnloaded() then
            return
        end

        UpdateEspPreview()

        if not EspGui.Enabled then
            return
        end

        if EspSpinEnabled and DummyRoot and DummyRoot.Parent then
            EspPreviewAngle += Delta * 0.42
            ApplyPreviewPivot(DummyRoot, EspPreviewAngle)
        end
        RefreshCamera()

        if EspHealthEnabled then
            EspAnimClock += Delta
            EspHealthValue = AutoHealthAmount(EspAnimClock)
            ApplyHealthBarVisuals()
        end

        if AnyEspOverlay() then
            UpdateEspBox()
        end
    end)
    getgenv().HazeEspPreviewConnection = EspPreviewConnection

    EspPreview.SetModel = function(_, Value)
        SetEspPreviewModel(Value)
    end

    EspPreview.SetDance = function(_, Value)
        SetEspPreviewDance(Value)
    end

    EspPreview.SetDanceById = function(_, Value)
        SetEspPreviewDanceById(Value)
    end

    EspPreview.SetDanceSpeed = function(_, Value)
        SetEspPreviewDanceSpeed(Value)
    end

    EspPreview.SetBoxEnabled = function(_, Value)
        EspBoxEnabled = Value
        ApplyEspPreviewOverlays()
    end

    EspPreview.SetNameEnabled = function(_, Value)
        EspNameEnabled = Value
        ApplyEspPreviewOverlays()
    end

    EspPreview.SetHealthEnabled = function(_, Value)
        EspHealthEnabled = Value
        if Value then
            RequestEspHealthAnim()
        end
        ApplyEspPreviewOverlays()
    end

    EspPreview.SetChamsEnabled = function(_, Value)
        EspChamsEnabled = Value
        ApplyEspPreviewOverlays()
    end

    EspPreview.SetColor = function(_, Color)
        EspPreviewColor = Color
        ApplyEspPreviewOverlays()
    end

    EspPreview.Update = function(_)
        UpdateEspPreview()
    end

    EspPreview.ApplyOverlays = function(_)
        ApplyEspPreviewOverlays()
    end

    EspPreview.RequestHealthAnim = function(_)
        RequestEspHealthAnim()
    end

    EspPreview.GetModelNames = function(_)
        local Items = {}
        for Name in pairs(EspPreviewBundles) do
            table.insert(Items, Name)
        end
        table.sort(Items)
        return Items
    end

    EspPreview.GetDanceNames = function(_)
        local Items = {}
        for Name in pairs(EspDances) do
            if Name ~= "None" then
                table.insert(Items, Name)
            end
        end
        table.sort(Items)
        return Items
    end

    EspPreview.Destroy = function(_)
        if not EspPreview.Alive then
            return
        end
        EspPreview.Alive = false

        pcall(function()
            if CharAddedConnection then
                CharAddedConnection:Disconnect()
            end
        end)

        pcall(function()
            EspPreviewConnection:Disconnect()
        end)

        pcall(function()
            if getgenv().HazeEspPreviewConnection then
                getgenv().HazeEspPreviewConnection:Disconnect()
                getgenv().HazeEspPreviewConnection = nil
            end
        end)

        pcall(function()
            local Proxy = workspace:FindFirstChild(DanceProxyName)
            if Proxy then
                Proxy:Destroy()
            end
        end)

        pcall(function()
            EspGui:Destroy()
        end)

        pcall(function()
            local Holder = self.Holder and self.Holder.Instance
            if Holder then
                local Panel2 = Holder:FindFirstChild("EspPreviewPanel", true)
                if Panel2 then
                    Panel2:Destroy()
                end
            end
        end)
    end

    self.EspPreview = EspPreview
    return EspPreview
end

-- ============================================================================
-- Settings/ESP UI builders (same pattern as Library:AddThemeUI)
-- ============================================================================
Library.AddEmblemUI = function(self, Page, Emblem, Data)
    Data = Data or {}
    local DanceTarget = Data.DanceTarget

    local EmblemSection = Page:Section({Name = "Emblem", Side = 1})
    local StyleSection = Page:Section({Name = "Style", Side = 2})

    EmblemSection:Toggle({Name = "Enabled", Flag = "Center Emblem", Default = true, Callback = function(Value)
        Emblem:SetEnabled(Value)
    end})

    EmblemSection:Dropdown({
        Name = "Shape",
        Flag = "Emblem Shape",
        Default = "Cross",
        Items = Emblem:GetShapeNames(),
        Callback = function(Value)
            Emblem:SetShape(Value)
        end
    })

    EmblemSection:Slider({Name = "Speed", Min = -480, Max = 480, Default = 50, Decimals = 1, Flag = "Emblem Speed", Callback = function(Value)
        Emblem:SetSpeed(Value)
    end})

    EmblemSection:Slider({Name = "Size", Min = 1, Max = 9, Default = 7, Decimals = 1, Flag = "Emblem Scale", Callback = function(Value)
        Emblem:SetSize(Value)
    end})

    EmblemSection:Slider({Name = "Visibility", Min = 0, Max = 1, Default = 1, Decimals = 0.01, Flag = "Emblem Visibility", Callback = function(Value)
        Emblem:SetVisibility(Value)
    end})

    if DanceTarget then
        local DanceSection = Page:Section({Name = "Dance", Side = 1})

        local ModelItems = {"Avatar"}
        for _, Name in ipairs(DanceTarget:GetModelNames()) do
            table.insert(ModelItems, Name)
        end

        DanceSection:Dropdown({
            Name = "Model",
            Flag = "ESP Preview Model",
            MaxSize = 168,
            Items = ModelItems,
            Default = "Avatar",
            Callback = function(Value)
                DanceTarget:SetModel(Value)
            end
        })

        local DanceItems = {"None"}
        for _, Name in ipairs(DanceTarget:GetDanceNames()) do
            table.insert(DanceItems, Name)
        end

        DanceSection:Dropdown({
            Name = "Emote",
            Flag = "ESP Preview Dance",
            MaxSize = 140,
            Items = DanceItems,
            Default = "None",
            Callback = function(Value)
                DanceTarget:SetDance(Value)
            end
        })

        DanceSection:Textbox({
            Name = "Emote ID",
            Placeholder = "paste catalog / animation id",
            Flag = "ESP Preview Dance ID",
            Callback = function(Value)
                DanceTarget:SetDanceById(Value)
            end
        })

        DanceSection:Slider({
            Name = "Emote Speed",
            Min = 0.1,
            Max = 3,
            Default = 1,
            Decimals = 1,
            Flag = "ESP Preview Dance Speed",
            Callback = function(Value)
                DanceTarget:SetDanceSpeed(Value)
            end
        })
    end

    StyleSection:Label({Name = "Color", Alignment = "Left"}):Colorpicker({
        Name = "Emblem Color",
        Default = Color3.fromRGB(200, 200, 205),
        Flag = "Emblem Color",
        Callback = function(Color)
            Emblem:SetColor(Color)
        end
    })

    StyleSection:Toggle({Name = "Use Accent Color", Flag = "Emblem Use Accent", Default = false, Callback = function(Value)
        Emblem:SetUseAccent(Value)
    end})

    StyleSection:Toggle({Name = "Rainbow", Flag = "Emblem Rainbow", Default = false, Callback = function(Value)
        Emblem:SetRainbow(Value)
    end})

    StyleSection:Dropdown({
        Name = "Material",
        Flag = "Emblem Material",
        Default = "Plastic",
        Items = {"Plastic", "Neon", "ForceField"},
        Callback = function(Value)
            Emblem:SetMaterial(Value)
        end
    })

    StyleSection:Slider({Name = "Glow", Min = 0, Max = 2, Default = 1, Decimals = 0.01, Flag = "Emblem Glow", Callback = function(Value)
        Emblem:SetGlow(Value)
    end})

    StyleSection:Toggle({Name = "Keep Textures", Flag = "Emblem Keep Textures", Default = true, Callback = function(Value)
        Emblem:SetKeepTextures(Value)
    end})
end

Library.CreatePlayerEsp = function(self, Options)
    Options = Options or {}

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    local DrawLib = nil
    pcall(function()
        DrawLib = Drawing
    end)
    if type(DrawLib) ~= "table" and getgenv then
        DrawLib = getgenv().Drawing
    end

    local function IsUnloaded()
        if type(Options.IsUnloaded) == "function" then
            return Options.IsUnloaded()
        end
        return false
    end

    local PlayerEsp = {
        Alive = true,
        BoxEnabled = false,
        NameEnabled = false,
        HealthEnabled = false,
        DistanceEnabled = false,
        TracerEnabled = false,
        SkeletonEnabled = false,
        ChamsEnabled = false,
        TeamCheck = false,
        MaxDistance = 1000,
        Color = Color3.fromRGB(125, 211, 252),
        Entries = {},
        Connection = nil,
    }

    local SkeletonPairs = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"},
        -- R6
        {"Head", "Torso"},
        {"Torso", "Left Arm"},
        {"Torso", "Right Arm"},
        {"Torso", "Left Leg"},
        {"Torso", "Right Leg"},
    }

    local function HasDrawing()
        return type(DrawLib) == "table" and type(DrawLib.new) == "function"
    end

    local function NewDrawing(Class, Props)
        if not HasDrawing() then
            return nil
        end
        local Obj = DrawLib.new(Class)
        for Key, Value in Props or {} do
            Obj[Key] = Value
        end
        return Obj
    end

    local function DestroyDrawing(Obj)
        if Obj then
            pcall(function()
                Obj.Visible = false
                Obj:Remove()
            end)
        end
    end

    local function HealthColor(Amount)
        Amount = math.clamp(Amount, 0, 1)
        return Color3.fromRGB(
            math.floor(255 - 255 * Amount + 0.5),
            math.floor(255 * Amount + 0.5),
            0
        )
    end

    local function HideEntry(Entry)
        if not Entry then
            return
        end
        for _, Obj in pairs(Entry.Drawings) do
            if type(Obj) == "table" then
                for _, Line in pairs(Obj) do
                    if Line then
                        Line.Visible = false
                    end
                end
            elseif Obj then
                Obj.Visible = false
            end
        end
        if Entry.Chams and Entry.Chams.Parent then
            Entry.Chams.Enabled = false
        end
    end

    local function RemoveEntry(Player)
        local Entry = PlayerEsp.Entries[Player]
        if not Entry then
            return
        end
        for _, Obj in pairs(Entry.Drawings) do
            if type(Obj) == "table" then
                for _, Line in pairs(Obj) do
                    DestroyDrawing(Line)
                end
            else
                DestroyDrawing(Obj)
            end
        end
        if Entry.Chams then
            pcall(function()
                Entry.Chams:Destroy()
            end)
        end
        PlayerEsp.Entries[Player] = nil
    end

    local function EnsureEntry(Player)
        local Entry = PlayerEsp.Entries[Player]
        if Entry then
            return Entry
        end

        local SkeletonLines = {}
        if HasDrawing() then
            for Index = 1, #SkeletonPairs do
                SkeletonLines[Index] = NewDrawing("Line", {
                    Thickness = 1,
                    Color = PlayerEsp.Color,
                    Visible = false,
                })
            end
        end

        Entry = {
            Drawings = {
                BoxOutline = NewDrawing("Square", {
                    Filled = false,
                    Thickness = 3,
                    Color = Color3.new(0, 0, 0),
                    Visible = false,
                }),
                Box = NewDrawing("Square", {
                    Filled = false,
                    Thickness = 1,
                    Color = PlayerEsp.Color,
                    Visible = false,
                }),
                Name = NewDrawing("Text", {
                    Center = true,
                    Outline = true,
                    Size = 13,
                    Font = (DrawLib and DrawLib.Fonts and DrawLib.Fonts.Plex) or 2,
                    Color = PlayerEsp.Color,
                    Visible = false,
                }),
                Distance = NewDrawing("Text", {
                    Center = true,
                    Outline = true,
                    Size = 12,
                    Font = (DrawLib and DrawLib.Fonts and DrawLib.Fonts.Plex) or 2,
                    Color = Color3.fromRGB(200, 200, 210),
                    Visible = false,
                }),
                HealthOutline = NewDrawing("Square", {
                    Filled = false,
                    Thickness = 3,
                    Color = Color3.new(0, 0, 0),
                    Visible = false,
                }),
                Health = NewDrawing("Square", {
                    Filled = true,
                    Thickness = 1,
                    Color = Color3.fromRGB(0, 255, 0),
                    Visible = false,
                }),
                Tracer = NewDrawing("Line", {
                    Thickness = 1,
                    Color = PlayerEsp.Color,
                    Visible = false,
                }),
                Skeleton = SkeletonLines,
            },
            Chams = nil,
        }

        PlayerEsp.Entries[Player] = Entry
        return Entry
    end

    local function EnsureChams(Entry, Character)
        if not PlayerEsp.ChamsEnabled then
            if Entry.Chams then
                Entry.Chams.Enabled = false
            end
            return
        end

        if not Entry.Chams or not Entry.Chams.Parent then
            local Highlight = Instance.new("Highlight")
            Highlight.Name = "haze_player_esp_chams"
            Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            Highlight.FillTransparency = 0.55
            Highlight.OutlineTransparency = 0
            Highlight.Parent = Character
            Entry.Chams = Highlight
        end

        Entry.Chams.Adornee = Character
        Entry.Chams.Parent = Character
        Entry.Chams.Enabled = true
        Entry.Chams.FillColor = PlayerEsp.Color
        Entry.Chams.OutlineColor = PlayerEsp.Color
    end

    local function GetRoot(Character)
        return Character:FindFirstChild("HumanoidRootPart")
            or Character:FindFirstChild("Torso")
            or Character:FindFirstChild("UpperTorso")
    end

    local function WorldToScreen(Position)
        local Screen, OnScreen = Camera:WorldToViewportPoint(Position)
        return Vector2.new(Screen.X, Screen.Y), OnScreen, Screen.Z
    end

    local function GetCharacterBounds(Character)
        local Parts = {}
        for _, Part in Character:GetChildren() do
            if Part:IsA("BasePart") and Part.Name ~= "HumanoidRootPart" then
                table.insert(Parts, Part)
            end
        end
        if #Parts == 0 then
            return nil
        end

        local MinX, MinY = math.huge, math.huge
        local MaxX, MaxY = -math.huge, -math.huge
        local AnyOnScreen = false
        local Behind = false

        for _, Part in Parts do
            local Size = Part.Size * 0.5
            local Cf = Part.CFrame
            for _, Ox in {-1, 1} do
                for _, Oy in {-1, 1} do
                    for _, Oz in {-1, 1} do
                        local World = Cf:PointToWorldSpace(Vector3.new(Size.X * Ox, Size.Y * Oy, Size.Z * Oz))
                        local Screen, OnScreen, Depth = WorldToScreen(World)
                        if Depth < 0 then
                            Behind = true
                        elseif OnScreen or (Screen.X > -200 and Screen.X < Camera.ViewportSize.X + 200) then
                            AnyOnScreen = AnyOnScreen or OnScreen
                            MinX = math.min(MinX, Screen.X)
                            MinY = math.min(MinY, Screen.Y)
                            MaxX = math.max(MaxX, Screen.X)
                            MaxY = math.max(MaxY, Screen.Y)
                        end
                    end
                end
            end
        end

        if MinX == math.huge or Behind then
            return nil
        end

        return {
            X = MinX,
            Y = MinY,
            W = math.max(2, MaxX - MinX),
            H = math.max(2, MaxY - MinY),
            OnScreen = AnyOnScreen,
        }
    end

    local function SameTeam(Player)
        if not PlayerEsp.TeamCheck then
            return false
        end
        if not LocalPlayer or not Player then
            return false
        end
        if LocalPlayer.Team and Player.Team then
            return LocalPlayer.Team == Player.Team
        end
        return LocalPlayer.TeamColor == Player.TeamColor
    end

    local function UpdatePlayer(Player)
        if not PlayerEsp.Alive or IsUnloaded() or Player == LocalPlayer then
            return
        end

        local Character = Player.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local Root = Character and GetRoot(Character)
        local Entry = EnsureEntry(Player)

        if not Character or not Humanoid or Humanoid.Health <= 0 or not Root then
            HideEntry(Entry)
            return
        end

        if SameTeam(Player) then
            HideEntry(Entry)
            return
        end

        local LocalRoot = LocalPlayer.Character and GetRoot(LocalPlayer.Character)
        local Distance = LocalRoot and (Root.Position - LocalRoot.Position).Magnitude or 0
        if Distance > PlayerEsp.MaxDistance then
            HideEntry(Entry)
            return
        end

        local Bounds = GetCharacterBounds(Character)
        if not Bounds then
            HideEntry(Entry)
            return
        end

        local Color = PlayerEsp.Color
        local HealthFrac = math.clamp(Humanoid.Health / math.max(Humanoid.MaxHealth, 1), 0, 1)
        local Drawings = Entry.Drawings

        if PlayerEsp.BoxEnabled and Drawings.Box then
            Drawings.BoxOutline.Size = Vector2.new(Bounds.W, Bounds.H)
            Drawings.BoxOutline.Position = Vector2.new(Bounds.X, Bounds.Y)
            Drawings.BoxOutline.Visible = true

            Drawings.Box.Size = Vector2.new(Bounds.W, Bounds.H)
            Drawings.Box.Position = Vector2.new(Bounds.X, Bounds.Y)
            Drawings.Box.Color = Color
            Drawings.Box.Visible = true
        else
            if Drawings.Box then
                Drawings.Box.Visible = false
                Drawings.BoxOutline.Visible = false
            end
        end

        if PlayerEsp.NameEnabled and Drawings.Name then
            Drawings.Name.Text = Player.DisplayName ~= Player.Name
                and (Player.DisplayName .. " (" .. Player.Name .. ")")
                or Player.Name
            Drawings.Name.Position = Vector2.new(Bounds.X + Bounds.W * 0.5, Bounds.Y - 16)
            Drawings.Name.Color = Color
            Drawings.Name.Visible = true
        elseif Drawings.Name then
            Drawings.Name.Visible = false
        end

        if PlayerEsp.DistanceEnabled and Drawings.Distance then
            Drawings.Distance.Text = string.format("%dm", math.floor(Distance + 0.5))
            Drawings.Distance.Position = Vector2.new(Bounds.X + Bounds.W * 0.5, Bounds.Y + Bounds.H + 2)
            Drawings.Distance.Visible = true
        elseif Drawings.Distance then
            Drawings.Distance.Visible = false
        end

        if PlayerEsp.HealthEnabled and Drawings.Health then
            local BarX = Bounds.X - 6
            local BarH = Bounds.H
            local FillH = math.max(1, BarH * HealthFrac)
            Drawings.HealthOutline.Size = Vector2.new(3, BarH)
            Drawings.HealthOutline.Position = Vector2.new(BarX - 1, Bounds.Y)
            Drawings.HealthOutline.Visible = true
            Drawings.Health.Size = Vector2.new(2, FillH)
            Drawings.Health.Position = Vector2.new(BarX, Bounds.Y + (BarH - FillH))
            Drawings.Health.Color = HealthColor(HealthFrac)
            Drawings.Health.Visible = true
        elseif Drawings.Health then
            Drawings.Health.Visible = false
            Drawings.HealthOutline.Visible = false
        end

        if PlayerEsp.TracerEnabled and Drawings.Tracer then
            local From = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y)
            local To = Vector2.new(Bounds.X + Bounds.W * 0.5, Bounds.Y + Bounds.H)
            Drawings.Tracer.From = From
            Drawings.Tracer.To = To
            Drawings.Tracer.Color = Color
            Drawings.Tracer.Visible = true
        elseif Drawings.Tracer then
            Drawings.Tracer.Visible = false
        end

        if PlayerEsp.SkeletonEnabled and Drawings.Skeleton then
            for Index, Pair in ipairs(SkeletonPairs) do
                local Line = Drawings.Skeleton[Index]
                local A = Character:FindFirstChild(Pair[1])
                local B = Character:FindFirstChild(Pair[2])
                if Line and A and B and A:IsA("BasePart") and B:IsA("BasePart") then
                    local SA, OA = WorldToScreen(A.Position)
                    local SB, OB = WorldToScreen(B.Position)
                    if OA and OB then
                        Line.From = SA
                        Line.To = SB
                        Line.Color = Color
                        Line.Visible = true
                    else
                        Line.Visible = false
                    end
                elseif Line then
                    Line.Visible = false
                end
            end
        elseif Drawings.Skeleton then
            for _, Line in Drawings.Skeleton do
                if Line then
                    Line.Visible = false
                end
            end
        end

        EnsureChams(Entry, Character)
    end

    local function RefreshAll()
        if not PlayerEsp.Alive or IsUnloaded() then
            return
        end
        Camera = workspace.CurrentCamera
        for _, Player in Players:GetPlayers() do
            UpdatePlayer(Player)
        end
    end

    PlayerEsp.SetBoxEnabled = function(_, Value)
        PlayerEsp.BoxEnabled = Value and true or false
    end
    PlayerEsp.SetNameEnabled = function(_, Value)
        PlayerEsp.NameEnabled = Value and true or false
    end
    PlayerEsp.SetHealthEnabled = function(_, Value)
        PlayerEsp.HealthEnabled = Value and true or false
    end
    PlayerEsp.SetDistanceEnabled = function(_, Value)
        PlayerEsp.DistanceEnabled = Value and true or false
    end
    PlayerEsp.SetTracerEnabled = function(_, Value)
        PlayerEsp.TracerEnabled = Value and true or false
    end
    PlayerEsp.SetSkeletonEnabled = function(_, Value)
        PlayerEsp.SkeletonEnabled = Value and true or false
    end
    PlayerEsp.SetChamsEnabled = function(_, Value)
        PlayerEsp.ChamsEnabled = Value and true or false
        if not PlayerEsp.ChamsEnabled then
            for _, Entry in pairs(PlayerEsp.Entries) do
                if Entry.Chams then
                    Entry.Chams.Enabled = false
                end
            end
        end
    end
    PlayerEsp.SetTeamCheck = function(_, Value)
        PlayerEsp.TeamCheck = Value and true or false
    end
    PlayerEsp.SetMaxDistance = function(_, Value)
        PlayerEsp.MaxDistance = math.max(50, tonumber(Value) or 1000)
    end
    PlayerEsp.SetColor = function(_, Color)
        if typeof(Color) == "Color3" then
            PlayerEsp.Color = Color
        end
    end

    PlayerEsp.Destroy = function(_)
        PlayerEsp.Alive = false
        if PlayerEsp.Connection then
            PlayerEsp.Connection:Disconnect()
            PlayerEsp.Connection = nil
        end
        for Player in pairs(PlayerEsp.Entries) do
            RemoveEntry(Player)
        end
        if Library.PlayerEsp == PlayerEsp then
            Library.PlayerEsp = nil
        end
    end

    Players.PlayerRemoving:Connect(function(Player)
        RemoveEntry(Player)
    end)

    PlayerEsp.Connection = RunService.RenderStepped:Connect(RefreshAll)
    Library.PlayerEsp = PlayerEsp

    if not HasDrawing() then
        warn("[haze] Drawing library missing — box/name/health/tracer/skeleton need Drawing; chams still work")
    end

    return PlayerEsp
end

Library.AddEspUI = function(self, Page, Data)
    Data = Data or {}
    local EspPreview = Data.Preview or Data.EspPreview
    local World = Data.World or Data.PlayerEsp

    local EspSection = Page:Section({Name = "ESP", Side = 1})
    local OptionsSection = Page:Section({Name = "Options", Side = 1})
    local PreviewSection = Page:Section({Name = "Preview", Side = 2})

    local function Sync(SetterPreview, SetterWorld, Value)
        if SetterPreview then
            SetterPreview(EspPreview, Value)
        end
        if SetterWorld then
            SetterWorld(World, Value)
        end
    end

    EspSection:Toggle({Name = "Box", Flag = "ESP Box", Default = false, Callback = function(Value)
        Sync(EspPreview and EspPreview.SetBoxEnabled, World and World.SetBoxEnabled, Value)
    end})

    EspSection:Toggle({Name = "Name", Flag = "ESP Name", Default = false, Callback = function(Value)
        Sync(EspPreview and EspPreview.SetNameEnabled, World and World.SetNameEnabled, Value)
    end})

    EspSection:Toggle({Name = "Health bar", Flag = "ESP Health", Default = false, Callback = function(Value)
        Sync(EspPreview and EspPreview.SetHealthEnabled, World and World.SetHealthEnabled, Value)
    end})

    EspSection:Toggle({Name = "Distance", Flag = "ESP Distance", Default = false, Callback = function(Value)
        if World then
            World:SetDistanceEnabled(Value)
        end
    end})

    EspSection:Toggle({Name = "Tracer", Flag = "ESP Tracer", Default = false, Callback = function(Value)
        if World then
            World:SetTracerEnabled(Value)
        end
    end})

    EspSection:Toggle({Name = "Skeleton", Flag = "ESP Skeleton", Default = false, Callback = function(Value)
        if World then
            World:SetSkeletonEnabled(Value)
        end
    end})

    EspSection:Toggle({Name = "Chams", Flag = "ESP Chams", Default = false, Callback = function(Value)
        Sync(EspPreview and EspPreview.SetChamsEnabled, World and World.SetChamsEnabled, Value)
    end})

    OptionsSection:Toggle({Name = "Team Check", Flag = "ESP Team Check", Default = false, Callback = function(Value)
        if World then
            World:SetTeamCheck(Value)
        end
    end})

    OptionsSection:Slider({
        Name = "Max Distance",
        Min = 50,
        Max = 5000,
        Default = 1000,
        Decimals = 1,
        Flag = "ESP Max Distance",
        Callback = function(Value)
            if World then
                World:SetMaxDistance(Value)
            end
        end
    })

    OptionsSection:Label({Name = "Color", Alignment = "Left"}):Colorpicker({
        Name = "ESP Color",
        Default = Color3.fromRGB(125, 211, 252),
        Flag = "ESP Color",
        Callback = function(Color)
            if EspPreview then
                EspPreview:SetColor(Color)
            end
            if World then
                World:SetColor(Color)
            end
        end
    })

    if EspPreview then
        PreviewSection:Label({Name = "Preview mirrors Box / Name / Health / Chams", Alignment = "Left"})
    end
end

Library.AddEspPreviewUI = function(self, Page, EspPreview)
    self:AddEspUI(Page, { Preview = EspPreview, World = self.PlayerEsp })
end

Library.Init = function(self)
    local Path = self.Folders.Directory .. "/autoload.json"
    if isfile(Path) then
        local Ok, Content = pcall(readfile, Path)
        if Ok and type(Content) == "string" and Content ~= "" then
            self:LoadConfig(Content)
        end
    end

    self:EnsureThemeFolders()
    task.defer(function()
        self:LoadThemeAutoload(true)
    end)
end

getgenv().Library = Library
return Library
