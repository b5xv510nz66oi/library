--[[
    haze.best — single-file UI (Tauri look, no HttpGet)
]]

if getgenv().HazeUI then
    pcall(function()
        getgenv().HazeUI:Unload()
    end)
end

--[[
    haze.ui — from-scratch Roblox UI matching the haze.best Tauri menu
    No Thugsense. Colors/layout from src/styles.css
]]

local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Camera = workspace.CurrentCamera

local function ParentGui(gui)
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
        end
        if protect_gui then
            protect_gui(gui)
        end
    end)
    local ok = pcall(function()
        if gethui then
            gui.Parent = gethui()
        else
            gui.Parent = game:GetService("CoreGui")
        end
    end)
    if not ok or not gui.Parent then
        local pg = LocalPlayer:WaitForChild("PlayerGui", 5)
        gui.Parent = pg
    end
end

local Theme = {
    Accent = Color3.fromRGB(142, 132, 255),
    Shell = Color3.fromRGB(8, 8, 14),
    Content = Color3.fromRGB(12, 12, 18),
    Panel = Color3.fromRGB(16, 16, 24),
    PanelStroke = Color3.fromRGB(22, 21, 31),
    Element = Color3.fromRGB(21, 21, 29),
    ElementActive = Color3.fromRGB(37, 36, 53),
    KnobOff = Color3.fromRGB(41, 41, 53),
    Text = Color3.fromRGB(104, 104, 120),
    TextHov = Color3.fromRGB(160, 160, 176),
    TextActive = Color3.fromRGB(255, 255, 255),
    Border = Color3.fromRGB(40, 38, 58),
}

local Library = {
    Theme = Theme,
    Flags = {},
    Connections = {},
    Unloaded = false,
    MenuKey = Enum.KeyCode.Insert,
    Open = true,
}

local function New(class, props)
    local i = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            i[k] = v
        end
    end
    if props.Parent then
        i.Parent = props.Parent
    end
    return i
end

local function Corner(parent, r)
    return New("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = parent })
end

local function Stroke(parent, color, t)
    return New("UIStroke", {
        Color = color or Theme.PanelStroke,
        Thickness = t or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function Pad(parent, t, r, b, l)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft = UDim.new(0, l or 0),
        Parent = parent,
    })
end

local function Tween(obj, info, goal)
    local tw = TS:Create(obj, info or TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
    tw:Play()
    return tw
end

local function Connect(sig, fn)
    local c = sig:Connect(fn)
    table.insert(Library.Connections, c)
    return c
end

local function Drag(frame, handle)
    handle = handle or frame
    local dragging, start, startPos
    Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    Connect(UIS.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - start
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

--------------------------------------------------------------------
-- ScreenGui
--------------------------------------------------------------------
pcall(function()
    local root = gethui and gethui() or game:GetService("CoreGui")
    local old = root:FindFirstChild("haze_best_ui")
    if old then
        old:Destroy()
    end
end)
pcall(function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local old = pg:FindFirstChild("haze_best_ui")
        if old then
            old:Destroy()
        end
    end
end)

local Gui = New("ScreenGui", {
    Name = "haze_best_ui",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
    IgnoreGuiInset = true,
})
ParentGui(Gui)
print("[haze.ui] ScreenGui ->", Gui.Parent and Gui.Parent:GetFullName() or "nil")

local Holder = New("Frame", {
    Name = "Holder",
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Parent = Gui,
})

--------------------------------------------------------------------
-- Watermark
--------------------------------------------------------------------
function Library:Watermark(Items)
    local Frame = New("Frame", {
        Name = "Watermark",
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 36),
        Position = UDim2.new(1, -16, 0, 14),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = Theme.Content,
        Parent = Holder,
    })
    Corner(Frame, 4)
    Stroke(Frame, Theme.PanelStroke)
    Pad(Frame, 10, 12, 10, 12)
    Drag(Frame)

    local Lay = New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 20),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Frame,
    })

    local Labels = {}
    for i, text in ipairs(Items) do
        local L = New("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 16),
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            Text = text,
            TextColor3 = i == 1 and Theme.TextActive or Theme.Text,
            Parent = Frame,
        })
        Labels[i] = L
    end

    return {
        SetVisibility = function(_, v)
            Frame.Visible = v
        end,
        SetItems = function(_, list)
            for i, L in ipairs(Labels) do
                L.Text = list[i] or ""
            end
        end,
        Instance = Frame,
    }
end

--------------------------------------------------------------------
-- Notification
--------------------------------------------------------------------
local NotifHost = New("Frame", {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 20),
    Size = UDim2.new(0, 420, 0, 200),
    Parent = Holder,
})
New("UIListLayout", {
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Padding = UDim.new(0, 8),
    Parent = NotifHost,
})

function Library:Notify(Text, Duration)
    Duration = Duration or 4
    local Card = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(0, 360, 0, 0),
        BackgroundColor3 = Theme.Content,
        Parent = NotifHost,
    })
    Corner(Card, 6)
    Stroke(Card, Theme.PanelStroke)
    Pad(Card, 12, 12, 12, 12)

    New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Theme.TextActive,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = Text,
        Parent = Card,
    })

    local BarBg = New("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        Parent = Card,
    })
    Corner(BarBg, 2)
    local Bar = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = BarBg,
    })
    Corner(Bar, 2)

    Tween(Bar, TweenInfo.new(Duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) })
    task.delay(Duration, function()
        if Card.Parent then
            Card:Destroy()
        end
    end)
end

Library.Notification = Library.Notify

--------------------------------------------------------------------
-- Window
--------------------------------------------------------------------
local TAB_ICONS = {
    Aim = "rbxassetid://7734053426",
    Move = "rbxassetid://7743871082",
    Misc = "rbxassetid://7734055803",
    Visuals = "rbxassetid://7734068321",
    Configs = "rbxassetid://7743867738",
    Settings = "rbxassetid://7734053495",
}

function Library:Window(Opts)
    Opts = Opts or {}
    local W, H = Opts.Width or 840, Opts.Height or 630
    local BrandW = 110

    local Menu = New("Frame", {
        Name = "Menu",
        Size = UDim2.fromOffset(W, H),
        Position = UDim2.fromOffset(
            math.floor(Camera.ViewportSize.X / 2 - W / 2),
            math.floor(Camera.ViewportSize.Y / 2 - H / 2)
        ),
        BackgroundColor3 = Theme.Shell,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Holder,
    })
    Corner(Menu, 12)
    Stroke(Menu, Theme.Border, 1)
    Drag(Menu)

    -- accent hairlines
    New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        ZIndex = 20,
        Parent = Menu,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        ZIndex = 20,
        Parent = Menu,
    })

    -- Brand rail
    local Brand = New("Frame", {
        Name = "Brand",
        Size = UDim2.new(0, BrandW, 1, 0),
        BackgroundTransparency = 1,
        Active = true,
        Parent = Menu,
    })

    local Mark = New("Frame", {
        Name = "Mark",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = Brand,
    })

    local function VertLabel(yScale, yOff)
        local L = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(16, 140),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, yScale, yOff),
            Rotation = -90,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            Text = "haze.best",
            TextColor3 = Theme.Accent,
            Parent = Mark,
        })
        return L
    end
    VertLabel(0.5, -90)
    VertLabel(0.5, 90)

    New("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(26, 26),
        Image = "rbxassetid://7733960981",
        ImageColor3 = Theme.Accent,
        ScaleType = Enum.ScaleType.Fit,
        Parent = Mark,
    })

    local Tabs = New("Frame", {
        Name = "Tabs",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = Brand,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = Tabs,
    })

    Connect(Brand.MouseEnter, function()
        Mark.Visible = false
        Tabs.Visible = true
    end)
    Connect(Brand.MouseLeave, function()
        Mark.Visible = true
        Tabs.Visible = false
    end)

    -- Content shell
    local Content = New("Frame", {
        Name = "Content",
        Position = UDim2.new(0, BrandW, 0, 15),
        Size = UDim2.new(1, -(BrandW + 15), 1, -30),
        BackgroundColor3 = Theme.Content,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Menu,
    })
    Corner(Content, 8)
    Stroke(Content, Theme.PanelStroke)

    local PagesHost = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 15),
        Size = UDim2.new(1, -30, 1, -30),
        Parent = Content,
    })

    local Window = {
        Menu = Menu,
        Pages = {},
        Active = nil,
    }

    function Window:SetOpen(v)
        Library.Open = v and true or false
        Menu.Visible = Library.Open
    end

    function Window:Page(Data)
        Data = Data or {}
        local Name = Data.Name or "Page"
        local PageFrame = New("Frame", {
            Name = Name,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            Parent = PagesHost,
        })

        local Cols = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = PageFrame,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 15),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Cols,
        })

        local Columns = {}
        for i = 1, Data.Columns or 2 do
            local Col = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(0.5, -8, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 0,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Parent = Cols,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 15),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Col,
            })
            Columns[i] = Col
        end

        -- tab button
        local TabBtn = New("TextButton", {
            Size = UDim2.fromOffset(42, 42),
            BackgroundColor3 = Theme.ElementActive,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = Tabs,
        })
        Corner(TabBtn, 8)

        local Icon = New("ImageLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(20, 20),
            Image = Data.Icon or TAB_ICONS[Name] or TAB_ICONS.Settings,
            ImageColor3 = Theme.Text,
            ScaleType = Enum.ScaleType.Fit,
            Parent = TabBtn,
        })

        local Tip = New("TextLabel", {
            BackgroundColor3 = Theme.Content,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 22),
            Position = UDim2.new(1, 10, 0.5, -11),
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            Text = Name,
            TextColor3 = Theme.TextActive,
            Visible = false,
            ZIndex = 50,
            Parent = TabBtn,
        })
        Corner(Tip, 4)
        Stroke(Tip, Theme.PanelStroke)
        Pad(Tip, 0, 8, 0, 8)

        local Page = {
            Name = Name,
            Frame = PageFrame,
            Columns = Columns,
            TabBtn = TabBtn,
            Icon = Icon,
        }

        function Page:Show(on)
            PageFrame.Visible = on
            TabBtn.BackgroundTransparency = on and 0 or 1
            Icon.ImageColor3 = on and Theme.Accent or Theme.Text
        end

        Connect(TabBtn.MouseEnter, function()
            Tip.Visible = true
            if Window.Active ~= Page then
                TabBtn.BackgroundTransparency = 0
                Icon.ImageColor3 = Theme.TextHov
            end
        end)
        Connect(TabBtn.MouseLeave, function()
            Tip.Visible = false
            if Window.Active ~= Page then
                TabBtn.BackgroundTransparency = 1
                Icon.ImageColor3 = Theme.Text
            end
        end)
        Connect(TabBtn.MouseButton1Click, function()
            for _, P in ipairs(Window.Pages) do
                P:Show(P == Page)
            end
            Window.Active = Page
        end)

        function Page:Panel(Side)
            local Host = Columns[Side or 1]
            local Panel = New("Frame", {
                BackgroundColor3 = Theme.Panel,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BorderSizePixel = 0,
                Parent = Host,
            })
            Corner(Panel, 4)
            Stroke(Panel, Theme.PanelStroke)
            Pad(Panel, 10, 10, 10, 10)
            New("UIListLayout", {
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Panel,
            })

            local API = {}

            local function Row()
                local R = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = Panel,
                })
                return R
            end

            function API:Sep()
                New("Frame", {
                    BackgroundColor3 = Theme.PanelStroke,
                    Size = UDim2.new(1, 0, 0, 1),
                    BorderSizePixel = 0,
                    Parent = Panel,
                })
            end

            function API:Toggle(O)
                O = O or {}
                local R = Row()
                local Label = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -90, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = O.Name or "Toggle",
                    TextColor3 = Theme.Text,
                    Parent = R,
                })

                local Trail = New("Frame", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(70, 22),
                    Parent = R,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    Parent = Trail,
                })

                local KeyChip
                if O.Keybind then
                    KeyChip = New("TextButton", {
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2.fromOffset(22, 22),
                        BackgroundColor3 = Theme.Element,
                        Font = Enum.Font.GothamMedium,
                        TextSize = 11,
                        TextColor3 = Theme.TextHov,
                        Text = O.Keybind.Name and string.sub(O.Keybind.Name, 1, 1) or "?",
                        AutoButtonColor = false,
                        Parent = Trail,
                    })
                    Corner(KeyChip, 6)
                    Stroke(KeyChip, Theme.PanelStroke)
                    Pad(KeyChip, 0, 6, 0, 6)
                    local Listening = false
                    Connect(KeyChip.MouseButton1Click, function()
                        Listening = true
                        KeyChip.Text = "..."
                        KeyChip.TextColor3 = Theme.Accent
                    end)
                    Connect(UIS.InputBegan, function(input, gpe)
                        if not Listening then
                            return
                        end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            Listening = false
                            O.Keybind = input.KeyCode
                            KeyChip.Text = string.sub(input.KeyCode.Name, 1, 1)
                            KeyChip.TextColor3 = Theme.TextHov
                            if O.Flag then
                                Library.Flags[O.Flag .. " Key"] = input.KeyCode
                            end
                        end
                    end)
                end

                local Switch = New("TextButton", {
                    Size = UDim2.fromOffset(40, 22),
                    BackgroundColor3 = Theme.Element,
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = 2,
                    Parent = Trail,
                })
                Corner(Switch, 100)
                local Knob = New("Frame", {
                    Size = UDim2.fromOffset(12, 12),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 6, 0.5, 0),
                    BackgroundColor3 = Theme.KnobOff,
                    BorderSizePixel = 0,
                    Parent = Switch,
                })
                Corner(Knob, 100)

                local On = O.Default and true or false
                local function Paint()
                    if On then
                        Switch.BackgroundColor3 = Theme.ElementActive
                        Knob.BackgroundColor3 = Theme.Accent
                        Tween(Knob, nil, { Position = UDim2.new(0, 22, 0.5, 0) })
                        Label.TextColor3 = Theme.TextActive
                    else
                        Switch.BackgroundColor3 = Theme.Element
                        Knob.BackgroundColor3 = Theme.KnobOff
                        Tween(Knob, nil, { Position = UDim2.new(0, 6, 0.5, 0) })
                        Label.TextColor3 = Theme.Text
                    end
                end
                Paint()

                local function Set(v, fire)
                    On = v and true or false
                    if O.Flag then
                        Library.Flags[O.Flag] = On
                    end
                    Paint()
                    if fire ~= false and O.Callback then
                        task.spawn(O.Callback, On)
                    end
                end

                Connect(Switch.MouseButton1Click, function()
                    Set(not On)
                end)
                Connect(R.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Set(not On)
                    end
                end)
                Connect(R.MouseEnter, function()
                    if not On then
                        Label.TextColor3 = Theme.TextHov
                    end
                end)
                Connect(R.MouseLeave, function()
                    if not On then
                        Label.TextColor3 = Theme.Text
                    end
                end)

                if O.Flag then
                    Library.Flags[O.Flag] = On
                end
                return { Set = Set, Get = function()
                    return On
                end }
            end

            function API:Slider(O)
                O = O or {}
                local Min, Max = O.Min or 0, O.Max or 100
                local Value = O.Default or Min
                local Dec = O.Decimals or 0
                local Suffix = O.Suffix or ""

                local R = Row()
                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -120, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = O.Name or "Slider",
                    TextColor3 = Theme.Text,
                    Parent = R,
                })

                local Val = New("TextLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -63, 0.5, 0),
                    Size = UDim2.fromOffset(52, 22),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextColor3 = Theme.Text,
                    Text = "",
                    Parent = R,
                })

                local Track = New("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(55, 22),
                    BackgroundColor3 = Theme.Element,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = R,
                })
                Corner(Track, 8)

                local Bars = {}
                for i = 1, 5 do
                    local B = New("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.new(0, 6 + (i - 1) * 9, 0.5, 0),
                        Size = UDim2.fromOffset(3, 8 + i),
                        BackgroundColor3 = Theme.Accent,
                        BackgroundTransparency = 0.82,
                        BorderSizePixel = 0,
                        Parent = Track,
                    })
                    Corner(B, 100)
                    Bars[i] = B
                end

                local function Fmt(v)
                    if Dec <= 0 then
                        return tostring(math.floor(v + 0.5)) .. Suffix
                    end
                    local m = 10 ^ Dec
                    return string.format("%." .. Dec .. "f", math.floor(v * m + 0.5) / m) .. Suffix
                end

                local function Paint()
                    local pct = Max == Min and 0 or (Value - Min) / (Max - Min)
                    pct = math.clamp(pct, 0, 1)
                    Val.Text = Fmt(Value)
                    local lit = pct <= 0 and 0 or math.clamp(math.ceil(pct * 5), 1, 5)
                    for i, B in ipairs(Bars) do
                        local on = i <= lit
                        B.BackgroundTransparency = on and 0 or 0.82
                        B.Size = UDim2.fromOffset(3, on and (10 + i * 1.2) or (7 + i * 0.5))
                    end
                end

                local function Set(v, fire)
                    local step = Dec > 0 and (10 ^ -Dec) or 1
                    Value = math.clamp(math.floor(v / step + 0.5) * step, Min, Max)
                    if O.Flag then
                        Library.Flags[O.Flag] = Value
                    end
                    Paint()
                    if fire ~= false and O.Callback then
                        task.spawn(O.Callback, Value)
                    end
                end

                local sliding = false
                local function FromX(x)
                    local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    Set(Min + (Max - Min) * rel)
                end
                Connect(Track.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        FromX(input.Position.X)
                    end
                end)
                Connect(UIS.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)
                Connect(UIS.InputChanged, function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        FromX(input.Position.X)
                    end
                end)

                Set(Value, false)
                return { Set = Set, Get = function()
                    return Value
                end }
            end

            function API:Dropdown(O)
                O = O or {}
                local Items = O.Items or { "None" }
                local Value = O.Default or Items[1]
                local Open = false

                local Wrap = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = Panel,
                })
                New("UIListLayout", {
                    Padding = UDim.new(0, 4),
                    Parent = Wrap,
                })

                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = O.Name or "Dropdown",
                    TextColor3 = Theme.TextHov,
                    Parent = Wrap,
                })

                local Btn = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Theme.Element,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = Wrap,
                })
                Corner(Btn, 8)
                Stroke(Btn, Theme.PanelStroke)

                local Val = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -30, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = Value,
                    TextColor3 = Theme.TextActive,
                    Parent = Btn,
                })
                New("TextLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.fromOffset(12, 12),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    Text = "▾",
                    TextColor3 = Theme.TextHov,
                    Parent = Btn,
                })

                local List = New("Frame", {
                    BackgroundColor3 = Theme.Panel,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Visible = false,
                    ZIndex = 40,
                    Parent = Wrap,
                })
                Corner(List, 8)
                Stroke(List, Theme.PanelStroke)
                Pad(List, 4, 4, 4, 4)
                New("UIListLayout", { Padding = UDim.new(0, 2), Parent = List })

                local function Set(v, fire)
                    Value = v
                    Val.Text = v
                    if O.Flag then
                        Library.Flags[O.Flag] = v
                    end
                    if fire ~= false and O.Callback then
                        task.spawn(O.Callback, v)
                    end
                end

                for _, item in ipairs(Items) do
                    local It = New("TextButton", {
                        Size = UDim2.new(1, 0, 0, 26),
                        BackgroundColor3 = Theme.Element,
                        BackgroundTransparency = 1,
                        Text = item,
                        Font = Enum.Font.GothamMedium,
                        TextSize = 13,
                        TextColor3 = Theme.TextHov,
                        AutoButtonColor = false,
                        ZIndex = 41,
                        Parent = List,
                    })
                    Corner(It, 6)
                    Connect(It.MouseButton1Click, function()
                        Set(item)
                        Open = false
                        List.Visible = false
                    end)
                    Connect(It.MouseEnter, function()
                        It.BackgroundTransparency = 0
                        It.TextColor3 = Theme.Accent
                    end)
                    Connect(It.MouseLeave, function()
                        It.BackgroundTransparency = 1
                        It.TextColor3 = Theme.TextHov
                    end)
                end

                Connect(Btn.MouseButton1Click, function()
                    Open = not Open
                    List.Visible = Open
                end)

                Set(Value, false)
                return { Set = Set, Get = function()
                    return Value
                end }
            end

            function API:Button(O)
                O = O or {}
                local B = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Theme.Element,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 13,
                    Text = O.Name or "Button",
                    TextColor3 = Theme.TextHov,
                    AutoButtonColor = false,
                    Parent = Panel,
                })
                Corner(B, 8)
                Stroke(B, Theme.PanelStroke)
                Connect(B.MouseEnter, function()
                    B.BackgroundColor3 = Theme.ElementActive
                    B.TextColor3 = Theme.TextActive
                end)
                Connect(B.MouseLeave, function()
                    B.BackgroundColor3 = Theme.Element
                    B.TextColor3 = Theme.TextHov
                end)
                Connect(B.MouseButton1Click, function()
                    if O.Callback then
                        task.spawn(O.Callback)
                    end
                end)
            end

            function API:Label(O)
                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 22),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = (O and O.Name) or "",
                    TextColor3 = Theme.TextHov,
                    Parent = Panel,
                })
            end

            return API
        end

        -- alias Section -> Panel (untitled, Tauri style)
        function Page:Section(Data)
            return Page:Panel(Data and Data.Side or 1)
        end

        table.insert(Window.Pages, Page)
        if #Window.Pages == 1 then
            Page:Show(true)
            Window.Active = Page
        end
        return Page
    end

    Connect(UIS.InputBegan, function(input, gpe)
        if gpe then
            return
        end
        if input.KeyCode == Library.MenuKey then
            Window:SetOpen(not Library.Open)
        end
    end)

    return Window
end

function Library:Unload()
    if Library.Unloaded then
        return
    end
    Library.Unloaded = true
    for _, c in ipairs(Library.Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end
    if Gui then
        Gui:Destroy()
    end
end

getgenv().HazeUI = Library


local UI = Library
local t0 = os.clock()

local Watermark = UI:Watermark({ "haze.best", "Server", "144FPS", "64PING", os.date("%I:%M %p") })
task.spawn(function()
    while not UI.Unloaded do
        pcall(function()
            Watermark:SetItems({ "haze.best", "Server", "144FPS", "64PING", os.date("%I:%M %p") })
        end)
        task.wait(1)
    end
end)

local Window = UI:Window({ Width = 840, Height = 630 })
print("[haze.best] window ok", Window.Menu and Window.Menu.Visible)

local Aim = Window:Page({ Name = "Aim", Columns = 2 })

do
    local P = Aim:Panel(1)
    P:Toggle({
        Name = "Enable ragebot",
        Flag = "ragebot",
        Default = true,
        Keybind = Enum.KeyCode.E,
        Callback = function(v)
            if v then
                UI:Notify("You have successfully summoned a notification!", 4)
            end
        end,
    })
    P:Sep()
    P:Toggle({ Name = "Silent aimbot", Flag = "silent", Default = false })
    P:Sep()
    P:Toggle({ Name = "Hit chance", Flag = "hit_chance_toggle", Default = false })
    P:Sep()
    P:Slider({ Name = "Field of view", Flag = "fov", Min = -180, Max = 180, Default = 90, Suffix = "°", Decimals = 0 })
end

do
    local P = Aim:Panel(1)
    P:Dropdown({ Name = "Body aimbot", Flag = "body", Items = { "Default", "Body" }, Default = "Default" })
    P:Dropdown({ Name = "Safe points", Flag = "safe", Items = { "On limbs", "None" }, Default = "On limbs" })
end

do
    local P = Aim:Panel(1)
    P:Toggle({ Name = "Enable recoil", Flag = "recoil", Default = true, Keybind = Enum.KeyCode.R })
    P:Sep()
    P:Slider({ Name = "Smoothness", Flag = "smooth", Min = 0, Max = 100, Default = 50, Suffix = "%", Decimals = 0 })
end

do
    local P = Aim:Panel(2)
    P:Slider({ Name = "Hit chance", Flag = "hit_chance", Min = 0, Max = 100, Default = 10, Suffix = "%", Decimals = 0 })
    P:Sep()
    P:Slider({ Name = "Max misses", Flag = "max_misses", Min = 0, Max = 100, Default = 50, Suffix = "%", Decimals = 0 })
    P:Sep()
    P:Toggle({ Name = "Static point scale", Flag = "point_scale", Default = true, Keybind = Enum.KeyCode.X })
    P:Sep()
    P:Toggle({ Name = "Head safety if lethal", Flag = "head_safety", Default = true })
end

do
    local P = Aim:Panel(2)
    P:Toggle({ Name = "Enable triggerbot", Flag = "trigger", Default = true, Keybind = Enum.KeyCode.T })
    P:Sep()
    P:Toggle({ Name = "Enable trigger in smoke", Flag = "trigger_smoke", Default = false })
    P:Sep()
    P:Button({
        Name = "Button",
        Callback = function()
            UI:Notify("Button pressed", 2)
        end,
    })
end

do
    local P = Aim:Panel(2)
    P:Slider({ Name = "Pitch", Flag = "pitch", Min = 0, Max = 1, Default = 0.5, Decimals = 3 })
    P:Sep()
    P:Slider({ Name = "Yaw", Flag = "yaw", Min = 0, Max = 1, Default = 0.5, Decimals = 3 })
    P:Sep()
    P:Toggle({ Name = "Static point scale", Flag = "aim_point_scale", Default = false, Keybind = Enum.KeyCode.C })
    P:Sep()
    P:Toggle({ Name = "Head safety if lethal", Flag = "aim_head_safety", Default = false })
end

Window:Page({ Name = "Move", Columns = 2 })
Window:Page({ Name = "Misc", Columns = 2 })

local Visuals = Window:Page({ Name = "Visuals", Columns = 2 })
do
    local P = Visuals:Panel(1)
    P:Toggle({ Name = "Enable ESP", Flag = "esp", Default = true, Keybind = Enum.KeyCode.F })
    P:Sep()
    P:Toggle({ Name = "Through walls", Flag = "esp_walls", Default = true })
    P:Sep()
    P:Dropdown({ Name = "Dynamic tracer", Flag = "esp_tracer", Items = { "Disabled", "In the field" }, Default = "Disabled" })
    P:Sep()
    P:Toggle({ Name = "Dynamic boxes", Flag = "esp_boxes", Default = false })
    P:Sep()
    P:Toggle({ Name = "In-Game radar", Flag = "esp_radar", Default = true })
end
do
    local P = Visuals:Panel(1)
    P:Toggle({ Name = "Enable glow", Flag = "glow", Default = true, Keybind = Enum.KeyCode.G })
    P:Sep()
    P:Slider({ Name = "The power of brightness", Flag = "glow_power", Min = 0, Max = 100, Default = 50, Suffix = "%", Decimals = 0 })
end
do
    local P = Visuals:Panel(1)
    P:Toggle({ Name = "Attachments", Flag = "attach", Default = false })
    P:Sep()
    P:Toggle({ Name = "Visible teammates", Flag = "teammates", Default = false, Keybind = Enum.KeyCode.V })
end
do
    local P = Visuals:Panel(2)
    P:Toggle({ Name = "Enable chams", Flag = "chams", Default = true, Keybind = Enum.KeyCode.H })
    P:Sep()
    P:Toggle({ Name = "Backtrack", Flag = "backtrack", Default = false })
    P:Sep()
    P:Toggle({ Name = "On shot", Flag = "onshot", Default = false })
    P:Sep()
    P:Toggle({ Name = "Ragdolls", Flag = "ragdolls", Default = false })
end
do
    local P = Visuals:Panel(2)
    P:Toggle({ Name = "Skeleton", Flag = "skeleton", Default = false })
    P:Sep()
    P:Dropdown({ Name = "Snaplines", Flag = "snaplines", Items = { "Top", "Bottom", "Left", "Right" }, Default = "Top" })
    P:Sep()
    P:Toggle({ Name = "Weapon", Flag = "weapon", Default = false })
    P:Sep()
    P:Toggle({ Name = "Nickname", Flag = "nickname", Default = false })
end

local Configs = Window:Page({ Name = "Configs", Columns = 2 })
do
    local P = Configs:Panel(1)
    P:Dropdown({ Name = "Profile", Flag = "cfg_list", Items = { "default" }, Default = "default" })
    P:Button({ Name = "Create config", Callback = function() UI:Notify("Config system ready", 2) end })
    P:Button({ Name = "Load config", Callback = function() UI:Notify("Loaded", 2) end })
    P:Button({ Name = "Save config", Callback = function() UI:Notify("Saved", 2) end })
end

local Settings = Window:Page({ Name = "Settings", Columns = 2 })
do
    local P = Settings:Panel(1)
    P:Label({ Name = "Menu keybind: Insert" })
    P:Sep()
    P:Toggle({
        Name = "Watermark",
        Flag = "wm",
        Default = true,
        Callback = function(v)
            Watermark:SetVisibility(v)
        end,
    })
    P:Sep()
    P:Button({ Name = "Notification test", Callback = function() UI:Notify("This is a notification", 4) end })
    P:Sep()
    P:Button({ Name = "Unload", Callback = function() UI:Unload() end })
end

UI:Notify(string.format("haze.best loaded · %.2fs", os.clock() - t0), 3)
print("[haze.best] ready")
