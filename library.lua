local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local ws = game:GetService("Workspace")
local http_service = game:GetService("HttpService")
local gui_service = game:GetService("GuiService")
local lighting = game:GetService("Lighting")
local run = game:GetService("RunService")
local stats = game:GetService("Stats")
local coregui = game:GetService("CoreGui")
local debris = game:GetService("Debris")
local tween_service = game:GetService("TweenService")
local rs = game:GetService("ReplicatedStorage")

local vec2 = Vector2.new
local vec3 = Vector3.new
local dim2 = UDim2.new
local dim = UDim.new
local rect = Rect.new
local cfr = CFrame.new

local color = Color3.new
local rgb = Color3.fromRGB
local hex = Color3.fromHex
local hsv = Color3.fromHSV
local rgbseq = ColorSequence.new
local rgbkey = ColorSequenceKeypoint.new

local camera = ws.CurrentCamera
local lp = players.LocalPlayer
local mouse = lp:GetMouse()
local gui_offset = gui_service:GetGuiInset().Y

local max = math.max
local floor = math.floor
local min = math.min
local abs = math.abs

if getgenv().library then
	getgenv().library:unload()
end

-- library init
getgenv().library = {
	flags = {},
	config_flags = {},
	connections = {},
	notifications = {},
	instances = {},
	main_frame = {},
	config_holder,
	current_tab,
	current_element_open,
	dock_button_holder,
	gui,
	sin = 0,
	keybind_path,
	panel_open = false,

	directory = "haze.best",
	folders = {
		"/fonts",
		"/configs",
	},
	font,
	rev = 6, -- bump when loader must invalidate stale executor cache
}

local flags = library.flags
local config_flags = library.config_flags

local themes = {
	preset = {
		["outline"] = rgb(32, 32, 38), --
		["inline"] = rgb(60, 55, 75), --
		["accent"] = rgb(179, 100, 122), --
		["contrast"] = rgb(35, 35, 47),
		["text"] = rgb(170, 170, 170),
		["unselected_text"] = rgb(90, 90, 90),
		["text_outline"] = rgb(0, 0, 0),
		["glow"] = rgb(179, 100, 122),
	},

	utility = {
		["outline"] = {
			["BackgroundColor3"] = {},
			["Color"] = {},
		},
		["inline"] = {
			["BackgroundColor3"] = {},
		},
		["accent"] = {
			["BackgroundColor3"] = {},
			["TextColor3"] = {},
			["ImageColor3"] = {},
			["BorderColor3"] = {},
			["ScrollBarImageColor3"] = {},
		},
		["contrast"] = {
			["Color"] = {},
		},
		["text"] = {
			["TextColor3"] = {},
			["ImageColor3"] = {},
		},
		["unselected_text"] = {
			["TextColor3"] = {},
			["ImageColor3"] = {},
		},
		["text_outline"] = {
			["Color"] = {},
		},
		["glow"] = {
			["ImageColor3"] = {},
		},
	},
}

local keys = {
	[Enum.KeyCode.LeftShift] = "LS",
	[Enum.KeyCode.RightShift] = "RS",
	[Enum.KeyCode.LeftControl] = "LC",
	[Enum.KeyCode.RightControl] = "RC",
	[Enum.KeyCode.Insert] = "INS",
	[Enum.KeyCode.Backspace] = "BS",
	[Enum.KeyCode.Return] = "Ent",
	[Enum.KeyCode.LeftAlt] = "LA",
	[Enum.KeyCode.RightAlt] = "RA",
	[Enum.KeyCode.CapsLock] = "CAPS",
	[Enum.KeyCode.One] = "1",
	[Enum.KeyCode.Two] = "2",
	[Enum.KeyCode.Three] = "3",
	[Enum.KeyCode.Four] = "4",
	[Enum.KeyCode.Five] = "5",
	[Enum.KeyCode.Six] = "6",
	[Enum.KeyCode.Seven] = "7",
	[Enum.KeyCode.Eight] = "8",
	[Enum.KeyCode.Nine] = "9",
	[Enum.KeyCode.Zero] = "0",
	[Enum.KeyCode.KeypadOne] = "Num1",
	[Enum.KeyCode.KeypadTwo] = "Num2",
	[Enum.KeyCode.KeypadThree] = "Num3",
	[Enum.KeyCode.KeypadFour] = "Num4",
	[Enum.KeyCode.KeypadFive] = "Num5",
	[Enum.KeyCode.KeypadSix] = "Num6",
	[Enum.KeyCode.KeypadSeven] = "Num7",
	[Enum.KeyCode.KeypadEight] = "Num8",
	[Enum.KeyCode.KeypadNine] = "Num9",
	[Enum.KeyCode.KeypadZero] = "Num0",
	[Enum.KeyCode.Minus] = "-",
	[Enum.KeyCode.Equals] = "=",
	[Enum.KeyCode.Tilde] = "~",
	[Enum.KeyCode.LeftBracket] = "[",
	[Enum.KeyCode.RightBracket] = "]",
	[Enum.KeyCode.RightParenthesis] = ")",
	[Enum.KeyCode.LeftParenthesis] = "(",
	[Enum.KeyCode.Semicolon] = ",",
	[Enum.KeyCode.Quote] = "'",
	[Enum.KeyCode.BackSlash] = "\\",
	[Enum.KeyCode.Comma] = ",",
	[Enum.KeyCode.Period] = ".",
	[Enum.KeyCode.Slash] = "/",
	[Enum.KeyCode.Asterisk] = "*",
	[Enum.KeyCode.Plus] = "+",
	[Enum.KeyCode.Period] = ".",
	[Enum.KeyCode.Backquote] = "`",
	[Enum.UserInputType.MouseButton1] = "MB1",
	[Enum.UserInputType.MouseButton2] = "MB2",
	[Enum.UserInputType.MouseButton3] = "MB3",
	[Enum.KeyCode.Escape] = "ESC",
	[Enum.KeyCode.Space] = "SPC",
}

library.__index = library

for _, path in next, library.folders do
	makefolder(library.directory .. path)
end

if not isfile(library.directory .. "/fonts/main.ttf") then
	writefile(
		library.directory .. "/fonts/main.ttf",
		game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/fs-tahoma-8px.ttf")
	)
end

local tahoma = {
	name = "SmallestPixel7",
	faces = {
		{
			name = "Regular",
			weight = 400,
			style = "normal",
			assetId = getcustomasset(library.directory .. "/fonts/main.ttf"),
		},
	},
}

if not isfile(library.directory .. "/fonts/main_encoded.ttf") then
	writefile(library.directory .. "/fonts/main_encoded.ttf", http_service:JSONEncode(tahoma))
end

library.font = Font.new(getcustomasset(library.directory .. "/fonts/main_encoded.ttf"), Enum.FontWeight.Regular)
--

-- functions
-- misc functions
function library.to_screen_point(position)
	return camera:WorldToViewportPoint(position)
end

function library:unload()
	library.gui:Destroy()

	for _, connection in library.connections do
		connection:Disconnect()
	end

	for _, item in library.instances do
		item:Destroy()
	end

	getgenv().library = nil
end

function library:convert_string_rgb(str)
	local values = {}

	for value in string.gmatch(str, "[^,]+") do
		table.insert(values, tonumber(value))
	end

	if #values == 4 then
		local r, g, b, a = values[1], values[2], values[3], values[4]

		return r, g, b, a
	else
		library:notification({ text = "Input a correct RGBA value (in the format 255, 255, 255, 0.5)" })
	end
end

function library:connection(signal, callback)
	local connection = signal:Connect(callback)

	table.insert(library.connections, connection)

	return connection
end

function library:make_resizable(frame)
	local Frame = Instance.new("TextButton")
	Frame.Position = dim2(1, -10, 1, -10)
	Frame.BorderColor3 = rgb(0, 0, 0)
	Frame.Size = dim2(0, 10, 0, 10)
	Frame.BorderSizePixel = 0
	Frame.BackgroundColor3 = rgb(255, 255, 255)
	Frame.Parent = frame
	Frame.BackgroundTransparency = 1
	Frame.Text = ""

	local resizing = false
	local start_size
	local start
	local og_size = frame.Size

	Frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			start = input.Position
			start_size = frame.Size
		end
	end)

	Frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)

	library:connection(uis.InputChanged, function(input, game_event)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mouse_pos = vec2(mouse.X, mouse.Y)
			local viewport_x = camera.ViewportSize.X
			local viewport_y = camera.ViewportSize.Y

			current_size = dim2(
				start_size.X.Scale,
				math.clamp(start_size.X.Offset + (input.Position.X - start.X), og_size.X.Offset, viewport_x),
				start_size.Y.Scale,
				math.clamp(start_size.Y.Offset + (input.Position.Y - start.Y), og_size.Y.Offset, viewport_y)
			)
			frame.Size = current_size
		end
	end)
end

function library:new_item(class, properties)
	local ins = Instance.new(class)

	for _, v in next, properties do
		ins[_] = v
	end

	table.insert(library.instances, ins)

	return ins
end

function library:animation(text)
	local pattern = {}
	for i = 1, tonumber(text:len()) do
		table.insert(pattern, string.sub(text, 1, i))
	end
	for i = tonumber(text:len()) - 1, 0, -1 do
		table.insert(pattern, string.sub(text, 1, i))
	end
	return pattern
end

function library:convert_enum(enum)
	local enum_parts = {}

	for part in string.gmatch(enum, "[%w_]+") do
		table.insert(enum_parts, part)
	end

	local enum_table = Enum
	for i = 2, #enum_parts do
		local enum_item = enum_table[enum_parts[i]]

		enum_table = enum_item
	end

	return enum_table
end

function library:config_list_update()
	if not library.config_holder then
		return
	end

	local list = {}

	for idx, file in next, listfiles(library.directory .. "/configs") do
		local name = file.split(file, "/configs/")[2]
		name = name.split(name, ".cfg")[1]
		list[#list + 1] = name
	end

	library.config_holder:refresh_options(list)
end

function library:get_config()
	local Config = {}

	for _, v in flags do
		if type(v) == "table" and v.key then
			Config[_] = { active = v.active, mode = v.mode, key = tostring(v.key) }
		elseif type(v) == "table" and v["Transparency"] and v["Color"] then
			Config[_] = { Transparency = v["Transparency"], Color = v["Color"]:ToHex() }
		else
			Config[_] = v
		end
	end

	return http_service:JSONEncode(Config)
end

function library:load_config(config_json)
	local config = http_service:JSONDecode(config_json)

	for _, v in next, config do
		local function_set = library.config_flags[_]

		if function_set then
			if type(v) == "table" and v["Transparency"] and v["Color"] then
				function_set(hex(v["Color"]), v["Transparency"])
			elseif type(v) == "table" and v["active"] then
				function_set(v)
			else
				function_set(v)
			end
		end
	end
end

function library:round(number, float)
	local multiplier = 1 / (float or 1)
	return math.floor(number * multiplier + 0.5) / multiplier
end

function library:apply_theme(instance, theme, property)
	local bucket = themes.utility[theme]
	if not bucket then
		return
	end
	if not bucket[property] then
		bucket[property] = {}
	end
	table.insert(bucket[property], instance)
end

function library:update_theme(theme, color)
	for _, property in next, themes.utility[theme] do
		for m, object in next, property do
			if object[_] == themes.preset[theme] or object.ClassName == "UIGradient" then
				object[_] = color
			end
		end
	end

	themes.preset[theme] = color
end

function library:connection(signal, callback)
	local connection = signal:Connect(callback)

	table.insert(library.connections, connection)

	return connection
end

function library:create(instance, options)
	local ins = Instance.new(instance)

	for prop, value in next, options do
		ins[prop] = value
	end

	return ins
end
--

library.gui = library:create("ScreenGui", {
	Enabled = true,
	Parent = coregui,
	Name = "",
	DisplayOrder = 2,
	ZIndexBehavior = 1,
})

-- library functions
function library:window(properties)
	local cfg = {
		name = properties.Name or properties.name or properties.Title or properties.title or "sp4m.wtf",
		size = properties.Size or properties.size or dim2(0, 500, 0, 650),
	}

	local animated_text = library:animation(cfg.name .. " | private")
	-- nested chrome eats ~50px; pixel font ~7px/char ΓÇö keep text inside the inner outline
	local function watermark_need(text)
		return math.max(140, (#tostring(text) * 7) + 56)
	end
	local watermark_width = 140
	for _, frame_text in next, animated_text do
		watermark_width = math.max(watermark_width, watermark_need(frame_text))
	end

	-- watermark
	local __holder = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0, 20),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		ZIndex = 2,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})

	local inline1 = library:create("Frame", {
		Parent = __holder,
		Name = "",
		Active = true,
		Draggable = true,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(0, watermark_width, 0, 40),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})

	local accent_line = library:create("Frame", {
		Parent = inline1,
		Name = "",
		BorderColor3 = Color3.fromRGB(34, 34, 34),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
	})

	library:apply_theme(accent_line, "accent", "BackgroundColor3")

	local depth = library:create("Frame", {
		Parent = inline1,
		Name = "",
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	local inline2 = library:create("Frame", {
		Parent = inline1,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	local main = library:create("Frame", {
		Parent = inline2,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(57, 57, 57),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	local tab_inline = library:create("Frame", {
		Parent = main,
		Name = "",
		Position = UDim2.new(0, 6, 0, 6),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -12, 1, -12),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(19, 19, 19),
	})

	local tabs = library:create("Frame", {
		Parent = tab_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local name = library:create("TextLabel", {
		Parent = tabs,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "haze.best",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local TEXT_ANIMATION_GRADIENT = library:create("UIGradient", {
		Parent = name,
		Name = "",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.01, themes.preset.accent),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		}),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = tabs,
		Name = "",
		PaddingRight = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 0),
	})

	local glow = library:create("ImageLabel", {
		Parent = accent_line,
		Name = "",
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.8999999761581421,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 0, 42),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})

	library:apply_theme(glow, "accent", "ImageColor3")

	task.spawn(function()
		while true do
			if __holder.Visible then
				for i = 1, #animated_text do
					task.wait(0.2)
					name.Text = animated_text[i]
					local need = watermark_need(animated_text[i])
					if inline1.Size.X.Offset < need then
						inline1.Size = UDim2.new(0, need, 0, 40)
					end
				end
			end
			task.wait(0.2)
		end
	end)
	--

	-- window
	local inline1 = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		Active = true,
		Draggable = true,
		Position = UDim2.new(0.5, -cfg.size.X.Offset / 2, 0.5, -cfg.size.Y.Offset / 2),
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		ZIndex = 2,
		Size = cfg.size,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})
	table.insert(library.main_frame, inline1)
	local WINDOW_PATH = inline1
	cfg._main_frame = inline1
	cfg.IsOpen = true
	library:make_resizable(inline1)

	local inline2 = library:create("Frame", {
		Parent = inline1,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	local main = library:create("Frame", {
		Parent = inline2,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(57, 57, 57),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	local tab_buttons = library:create("Frame", {
		Parent = main,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 4),
		Size = UDim2.new(1, -32, 0, 0),
		ZIndex = 2,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	cfg["tab_holder"] = tab_buttons

	local list = library:create("UIListLayout", {
		Parent = tab_buttons,
		Name = "",
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local tab_inline = library:create("Frame", {
		Parent = main,
		Name = "",
		Position = UDim2.new(0, 15, 0, 33),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -30, 1, -48),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(19, 19, 19),
	})

	local tabs = library:create("Frame", {
		Parent = tab_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	cfg["tab_instance_holder"] = tabs

	local accent_line = library:create("Frame", {
		Parent = inline1,
		Name = "",
		BorderColor3 = Color3.fromRGB(34, 34, 34),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
	})

	library:apply_theme(accent_line, "accent", "BackgroundColor3")

	local name = library:create("TextLabel", {
		Parent = inline1,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local glow = library:create("ImageLabel", {
		Parent = inline1,
		Name = "",
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.8999999761581421,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 0, 42),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	library:apply_theme(glow, "accent", "ImageColor3")

	local depth = library:create("Frame", {
		Parent = inline1,
		Name = "",
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	local holder = library:create("Frame", {
		Parent = inline1,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 20, 0, 0),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		ZIndex = 2,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})

	task.spawn(function()
		while true do
			if flags["color_picker_anim_speed"] then
				library.sin = math.abs(math.sin(tick() * flags["color_picker_anim_speed"]))

				TEXT_ANIMATION_GRADIENT.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(math.abs(math.sin(tick())), themes.preset.accent),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
				})
			end
			task.wait()
		end
	end)
	--

	-- esp preview
	local esp_preview = library:create("Frame", {
		Parent = library.gui,
		Name = "builtin_esp_unused",
		Visible = false,
		Active = true,
		Draggable = true,
		Position = UDim2.new(
			0,
			inline1.AbsolutePosition.X + inline1.AbsoluteSize.X + 8,
			0,
			inline1.AbsolutePosition.Y + 1
		),
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		Size = UDim2.new(0, 328, 0, 376),
		BackgroundColor3 = Color3.fromRGB(56, 56, 56),
	})
	library:make_resizable(esp_preview)

	local name = library:create("TextLabel", {
		Parent = esp_preview,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "esp preview",
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = name,
		Name = "",
	})

	local main = library:create("Frame", {
		Parent = esp_preview,
		Name = "",
		Position = UDim2.new(0, 4, 0, 4),
		BorderColor3 = Color3.fromRGB(26, 26, 26),
		Size = UDim2.new(1, -8, 1, -8),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	library:create("UIStroke", {
		Parent = main,
		Name = "",
		Color = Color3.fromRGB(57, 57, 57),
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local tabs = library:create("Frame", {
		Parent = main,
		Name = "",
		Position = UDim2.new(0, 8, 0, 8),
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		Size = UDim2.new(1, -16, 1, -16),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	library:create("UIStroke", {
		Parent = tabs,
		Name = "",
		Color = Color3.fromRGB(57, 57, 57),
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local hitpart = library:create("Frame", {
		Parent = tabs,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 20),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local head = library:create("Frame", {
		Parent = hitpart,
		Name = "",
		Position = UDim2.new(0.5, -25, 0, 16),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(0, 50, 0, 44),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local torso = library:create("Frame", {
		Parent = hitpart,
		Name = "",
		Position = UDim2.new(0.5, -42, 0, 64),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(0, 84, 0, 90),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local l_arm = library:create("Frame", {
		Parent = hitpart,
		Name = "",
		Position = UDim2.new(0.5, -86, 0, 64),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(0, 40, 0, 90),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local r_arm = library:create("Frame", {
		Parent = hitpart,
		Name = "",
		Position = UDim2.new(0.5, 46, 0, 64),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(0, 40, 0, 90),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local r_leg = library:create("Frame", {
		Parent = hitpart,
		Name = "",
		Position = UDim2.new(0.5, 2, 0, 158),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(0, 40, 0, 90),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local l_leg = library:create("Frame", {
		Parent = hitpart,
		Name = "",
		Position = UDim2.new(0.5, -42, 0, 158),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(0, 40, 0, 90),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local hrp_out = library:create("Frame", {
		Parent = hitpart,
		Name = "",
		Position = UDim2.new(0.5, -10, 0, 99),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(0, 20, 0, 20),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local hrp = library:create("Frame", {
		Parent = hrp_out,
		Name = "",
		Position = UDim2.new(0, 4, 0, 4),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -8, 1, -8),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local glow_patterns = {}

	for _, v in next, hitpart:GetChildren() do
		local glow = library:create("ImageLabel", {
			Parent = v,
			Name = "",
			Visible = false,
			ImageColor3 = themes.preset.accent,
			ScaleType = Enum.ScaleType.Slice,
			ImageTransparency = 0.8999999761581421,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Image = "http://www.roblox.com/asset/?id=18245826428",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, -20, 0, -20),
			Size = UDim2.new(1, 40, 1, 40),
			ZIndex = 2,
			BorderSizePixel = 0,
			SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
		})

		library:apply_theme(glow, "accent", "ImageColor3")

		table.insert(glow_patterns, glow)
	end

	function cfg.preview_chams(bool)
		for _, glow in next, glow_patterns do
			glow.Visible = bool
		end

		for _, part in next, hitpart:GetChildren() do
			part.BackgroundColor3 = bool and themes.preset.accent or Color3.fromRGB(38, 38, 38)
		end
	end

	local player = library:create("Frame", {
		Parent = tabs,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 43, 0, 28),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -86, 1, -106),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local line_holder = library:create("Frame", {
		Parent = player,
		Name = "",
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 50,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local box_outline = library:create("Frame", {
		Parent = line_holder,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -1, 0, -1),
		ZIndex = 50,
		Size = UDim2.new(1, 2, 1, 2),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local BoxLine2 = library:create("UIStroke", {
		Parent = box_outline,
		Name = "",
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local box_color = library:create("UIStroke", {
		Parent = line_holder,
		Name = "",
		Color = Color3.fromRGB(255, 255, 255),
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local corner_box = library:create("Frame", {
		Parent = line_holder,
		Name = "",
		Visible = false,
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local top_left = library:create("Frame", {
		Parent = corner_box,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 50,
		Size = UDim2.new(0, 1, 0.30000001192092896, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local top_right = library:create("Frame", {
		Parent = corner_box,
		Name = "",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 50,
		Size = UDim2.new(0, 1, 0.30000001192092896, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local bottom_left = library:create("Frame", {
		Parent = corner_box,
		Name = "",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 50,
		Size = UDim2.new(0.4000000059604645, 0, 0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local bottom_right = library:create("Frame", {
		Parent = corner_box,
		Name = "",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -1, 1, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 50,
		Size = UDim2.new(0.4000000059604645, 0, 0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local bottom_left2 = library:create("Frame", {
		Parent = corner_box,
		Name = "",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 50,
		Size = UDim2.new(0, 1, 0.30000001192092896, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local bottom_right2 = library:create("Frame", {
		Parent = corner_box,
		Name = "",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 50,
		Size = UDim2.new(0, 1, 0.30000001192092896, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local top_left2 = library:create("Frame", {
		Parent = corner_box,
		Name = "",
		AnchorPoint = Vector2.new(0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 50,
		Size = UDim2.new(0.4000000059604645, 0, 0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local top_right2 = library:create("Frame", {
		Parent = corner_box,
		Name = "",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -1, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 50,
		Size = UDim2.new(0.4000000059604645, 0, 0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	function cfg.preview_corner_boxes(bool)
		corner_box.Visible = bool == "Corner" and true or false
		BoxLine2.Enabled = bool == "Corner" and false or true
		box_outline.Visible = bool == "Corner" and false or true
		box_color.Enabled = bool == "Corner" and false or true
	end

	function cfg.preview_bounding_box(bool)
		BoxLine2.Enabled = bool
		box_outline.Visible = bool
		box_color.Enabled = bool
	end

	local bottom_holder = library:create("Frame", {
		Parent = line_holder,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -1, 1, 3),
		Size = UDim2.new(1, 2, 0, 0),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local UIListLayout = library:create("UIListLayout", {
		Parent = bottom_holder,
		Name = "",
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local UIPadding = library:create("UIPadding", {
		Parent = bottom_holder,
		Name = "",
		PaddingTop = UDim.new(0, 1),
	})

	local bar_holder = library:create("Frame", {
		Parent = bottom_holder,
		Name = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 4),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local reload_bar = library:create("Frame", {
		Parent = bar_holder,
		Name = "",
		Size = UDim2.new(1, 0, 0, 4),
		ZIndex = 50,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	function cfg.preview_reload_bar(bool)
		bar_holder.Visible = bool
	end

	local reload_slider = library:create("Frame", {
		Parent = reload_bar,
		Name = "",
		Size = UDim2.new(0.5, -2, 0, 2),
		Position = UDim2.new(0, 1, 0, 1),
		ZIndex = 50,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(28, 145, 255),
	})

	local gradient = library:create("UIGradient", {
		Parent = reload_slider,
		Name = "",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 238)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 238)),
		}),
	})

	local weapon = library:create("TextLabel", {
		Parent = bottom_holder,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "double barrel",
		TextStrokeTransparency = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.031031031161546707, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 50,
		TextSize = 12,
		Size = UDim2.new(1, 0, 0, 4),
	})

	function cfg.preview_weapon(bool)
		weapon.Visible = bool
	end

	local UIStroke = library:create("UIStroke", {
		Parent = weapon,
		Name = "",
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local image_holder = library:create("Frame", {
		Parent = bottom_holder,
		Name = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	function cfg.preview_icons(bool)
		image_holder.Visible = bool
	end

	local ImageLabel = library:create("ImageLabel", {
		Parent = image_holder,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Image = "rbxassetid://130516018594923",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0, 64, 0, 27),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local armor = library:create("Frame", {
		Parent = line_holder,
		Name = "",
		Position = UDim2.new(0, -14, 0, -2),
		Size = UDim2.new(0, 4, 1, 4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	function cfg.preview_armor(bool)
		armor.Visible = bool
	end

	local armor_slider = library:create("Frame", {
		Parent = armor,
		Name = "",
		Position = UDim2.new(0, 1, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(0.5, 0, 1, -2),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 13, 255),
	})

	local armor_gradient = library:create("UIGradient", {
		Parent = armor_slider,
		Name = "",
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 242, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 17, 255)),
		}),
		Enabled = false,
	})

	local armor_text = library:create("TextLabel", {
		Parent = armor_slider,
		Name = "",
		ZIndex = 99,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(0, 13, 255),
		Text = "100",
		Position = UDim2.new(0, -2, 0.75, -2),
		TextStrokeTransparency = 0,
		AnchorPoint = Vector2.new(1, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Right,
		Active = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(26, 255, 0),
	})

	library:create("UIStroke", {
		Parent = armor_text,
		Name = "",
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local health = library:create("Frame", {
		Parent = line_holder,
		Name = "",
		Position = UDim2.new(0, -8, 0, -2),
		Size = UDim2.new(0, 4, 1, 4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	function cfg.preview_health(bool)
		health.Visible = bool
	end

	local health_slider = library:create("Frame", {
		Parent = health,
		Name = "",
		Position = UDim2.new(0, 1, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(0.5, 0, 1, -2),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 255, 42),
	})

	local health_text = library:create("TextLabel", {
		Parent = health_slider,
		Name = "",
		Visible = false,
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(0, 255, 0),
		Text = "100",
		ZIndex = 99,
		TextStrokeTransparency = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, -4, 0.5, -2),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Right,
		Active = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(26, 255, 0),
	})

	local UIStroke = library:create("UIStroke", {
		Parent = health_text,
		Name = "",
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local box_inline = library:create("Frame", {
		Parent = line_holder,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 1),
		ZIndex = 50,
		Size = UDim2.new(1, -2, 1, -2),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local BoxLine3 = library:create("UIStroke", {
		Parent = box_inline,
		Name = "",
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local gradient = library:create("UIGradient", {
		Parent = line_holder,
		Name = "",
		Rotation = -180,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 0.5),
		}),
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
		}),
	})

	function cfg.preview_filler(bool)
		line_holder.BackgroundTransparency = bool and 0 or 1
		gradient.Enabled = bool
	end

	local top_holder = library:create("Frame", {
		Parent = line_holder,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -2, 0, -4),
		Size = UDim2.new(1, 4, 0, 0),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	library:create("UIListLayout", {
		Parent = top_holder,
		Name = "",
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	library:create("UIPadding", {
		Parent = top_holder,
		Name = "",
		PaddingTop = UDim.new(0, 1),
	})

	local player_name = library:create("TextLabel", {
		Parent = top_holder,
		Name = "",
		RichText = true,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "hello there",
		FontFace = library.font,
		AnchorPoint = Vector2.new(0, 1),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, -2),
		BorderSizePixel = 0,
		ZIndex = 50,
		TextSize = 12,
		Size = UDim2.new(1, 0, 0, 0),
	})

	function cfg.preview_names(bool)
		player_name.Visible = bool
	end

	local UIStroke = library:create("UIStroke", {
		Parent = player_name,
		Name = "",
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local accent_line = library:create("Frame", {
		Parent = esp_preview,
		Name = "",
		BorderColor3 = Color3.fromRGB(34, 34, 34),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
	})

	library:apply_theme(accent_line, "accent", "BackgroundColor3")

	local depth = library:create("Frame", {
		Parent = esp_preview,
		Name = "",
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	local glow = library:create("ImageLabel", {
		Parent = esp_preview,
		Name = "",
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.8999999761581421,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 0, 42),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})

	library:apply_theme(glow, "accent", "ImageColor3")
	--

	-- playerlist
	local selected_button
	local selected_player
	local player_buttons = {}

	function library.get_priority(player)
		return player_buttons[player.Name].priority.Text
	end

	local playerlist = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		Active = true,
		Draggable = true,
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, inline1.AbsolutePosition.X - 358 - 8, 0, inline1.AbsolutePosition.Y + 1),
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		Size = UDim2.new(0, 358, 0, 328),
		BackgroundColor3 = Color3.fromRGB(56, 56, 56),
	})
	library:make_resizable(playerlist)

	table.insert(library.main_frame, playerlist)

	local name = library:create("TextLabel", {
		Parent = playerlist,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "playerlist",
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = name,
		Name = "",
	})

	local main = library:create("Frame", {
		Parent = playerlist,
		Name = "",
		Position = UDim2.new(0, 4, 0, 4),
		BorderColor3 = Color3.fromRGB(26, 26, 26),
		Size = UDim2.new(1, -8, 1, -8),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	library:create("UIStroke", {
		Parent = main,
		Name = "",
		Color = Color3.fromRGB(57, 57, 57),
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local tabs = library:create("Frame", {
		Parent = main,
		Name = "",
		Position = UDim2.new(0, 8, 0, 8),
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		Size = UDim2.new(1, -16, 1, -16),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	library:create("UIStroke", {
		Parent = tabs,
		Name = "",
		Color = Color3.fromRGB(57, 57, 57),
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local list = library:create("Frame", {
		Parent = tabs,
		Name = "",
		Position = UDim2.new(0, 14, 0, 14),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -28, 0.75, -28),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local inline = library:create("Frame", {
		Parent = list,
		Name = "",
		Position = UDim2.new(0, 1, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -2, 1, -2),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(57, 57, 57),
	})

	local background = library:create("Frame", {
		Parent = inline,
		Name = "",
		Position = UDim2.new(0, 1, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -2, 1, -2),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local UIGradient = library:create("UIGradient", {
		Parent = background,
		Name = "",
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(167, 167, 167)),
		}),
	})

	local contrast = library:create("Frame", {
		Parent = background,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local __ScrollingFrame = library:create("ScrollingFrame", {
		Parent = contrast,
		Name = "",
		ScrollBarImageColor3 = themes.preset.accent,
		MidImage = "rbxassetid://18406573371",
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		TopImage = "rbxassetid://18406573371",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1.0099999904632568,
		BottomImage = "rbxassetid://18406573371",
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	})

	library:apply_theme(__ScrollingFrame, "accent", "ScrollBarImageColor3")

	local UIPadding = library:create("UIPadding", {
		Parent = __ScrollingFrame,
		Name = "",
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
	})

	local UIListLayout = library:create("UIListLayout", {
		Parent = __ScrollingFrame,
		Name = "",
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local info = library:create("Frame", {
		Parent = tabs,
		Name = "",
		Position = UDim2.new(0, 14, 0.75, -5),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -28, 0.30000001192092896, -23),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local inline = library:create("Frame", {
		Parent = info,
		Name = "",
		Position = UDim2.new(0, 1, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -2, 1, -2),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(57, 57, 57),
	})

	local background = library:create("Frame", {
		Parent = inline,
		Name = "",
		Position = UDim2.new(0, 1, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -2, 1, -2),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local UIGradient = library:create("UIGradient", {
		Parent = background,
		Name = "",
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(167, 167, 167)),
		}),
	})

	local contrast = library:create("Frame", {
		Parent = background,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local ScrollingFrame = library:create("ScrollingFrame", {
		Parent = contrast,
		Name = "",
		ScrollBarImageColor3 = Color3.fromRGB(155, 125, 175),
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		BackgroundTransparency = 1.0099999904632568,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = ScrollingFrame,
		Name = "",
		PaddingTop = UDim.new(0, 7),
		PaddingBottom = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 10),
	})

	local UIListLayout = library:create("UIListLayout", {
		Parent = ScrollingFrame,
		Name = "",
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local display_name_label = library:create("TextLabel", {
		Parent = ScrollingFrame,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(180, 180, 180),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "Display Name: ...",
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AutomaticSize = Enum.AutomaticSize.XY,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	library:create("UIStroke", {
		Parent = display_name_label,
		Name = "",
	})

	local name_label = library:create("TextLabel", {
		Parent = ScrollingFrame,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(180, 180, 180),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "Name: ...",
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AutomaticSize = Enum.AutomaticSize.XY,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	library:create("UIStroke", {
		Parent = name_label,
		Name = "",
	})

	local priority_label = library:create("TextLabel", {
		Parent = ScrollingFrame,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(180, 180, 180),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "Priority: Friendly",
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AutomaticSize = Enum.AutomaticSize.XY,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	library:create("UIStroke", {
		Parent = priority_label,
		Name = "",
	})

	local Frame = library:create("Frame", {
		Parent = contrast,
		Name = "",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -10, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -200, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local button_inline = library:create("Frame", {
		Parent = Frame,
		Name = "",
		Position = UDim2.new(0, -15, 0, 2),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local button = library:create("TextButton", {
		Parent = button_inline,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "Neutral",
		TextStrokeTransparency = 0.5,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	button.MouseButton1Click:Connect(function()
		player_buttons[selected_player.Name].priority.Text = "Neutral"
		player_buttons[selected_player.Name].priority.TextColor3 = rgb(180, 180, 180)
	end)

	local button_inline = library:create("Frame", {
		Parent = Frame,
		Name = "",
		Position = UDim2.new(0, -15, 0, 2),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local button = library:create("TextButton", {
		Parent = button_inline,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "Friendly",
		TextStrokeTransparency = 0.5,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	button.MouseButton1Click:Connect(function()
		player_buttons[selected_player.Name].priority.Text = "Friendly"
		player_buttons[selected_player.Name].priority.TextColor3 = rgb(15, 179, 255)
	end)

	local button_inline = library:create("Frame", {
		Parent = Frame,
		Name = "",
		Position = UDim2.new(0, -15, 0, 2),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local button = library:create("TextButton", {
		Parent = button_inline,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "Enemy",
		TextStrokeTransparency = 0.5,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	button.MouseButton1Click:Connect(function()
		player_buttons[selected_player.Name].priority.Text = "Enemy"
		player_buttons[selected_player.Name].priority.TextColor3 = rgb(255, 44, 44)
	end)

	local UIListLayout = library:create("UIListLayout", {
		Parent = Frame,
		Name = "",
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		Padding = UDim.new(0, 4),
	})

	local accent_line = library:create("Frame", {
		Parent = playerlist,
		Name = "",
		BorderColor3 = Color3.fromRGB(34, 34, 34),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
	})

	library:apply_theme(accent_line, "accent", "BackgroundColor3")

	local depth = library:create("Frame", {
		Parent = playerlist,
		Name = "",
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	local glow = library:create("ImageLabel", {
		Parent = playerlist,
		Name = "",
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.8999999761581421,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 0, 42),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})

	library:apply_theme(glow, "accent", "ImageColor3")

	local function create_player(player)
		local TextButton = library:create("TextButton", {
			Parent = __ScrollingFrame,
			Name = "",
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		player_buttons[player.Name] = {}
		player_buttons[player.Name].instance = TextButton

		local TextLabel = library:create("TextLabel", {
			Parent = TextButton,
			Name = "",
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Text = player.Name,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		library:create("UIStroke", {
			Parent = TextLabel,
			Name = "",
		})

		local TextLabel = library:create("TextLabel", {
			Parent = TextButton,
			Name = "",
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Text = player.Team and tostring(player.Team) or "None",
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		library:create("UIStroke", {
			Parent = TextLabel,
			Name = "",
		})

		local Frame = library:create("Frame", {
			Parent = TextLabel,
			Name = "",
			Position = UDim2.new(0, -10, 0, 0),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 1, 0, 12),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(32, 32, 38),
		})

		local TextLabel = library:create("TextLabel", {
			Parent = TextButton,
			Name = "",
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Text = "Neutral",
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		player_buttons[player.Name].priority = TextLabel

		library:create("UIStroke", {
			Parent = TextLabel,
			Name = "",
		})

		local Frame = library:create("Frame", {
			Parent = TextLabel,
			Name = "",
			Position = UDim2.new(0, -10, 0, 0),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 1, 0, 12),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(32, 32, 38),
		})

		local UIListLayout = library:create("UIListLayout", {
			Parent = TextButton,
			Name = "",
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
		})

		local UIPadding = library:create("UIPadding", {
			Parent = TextButton,
			Name = "",
			PaddingRight = UDim.new(0, 2),
			PaddingLeft = UDim.new(0, 2),
		})

		local line = library:create("Frame", {
			Parent = tabs,
			Name = "",
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(32, 32, 38),
		})

		TextButton.MouseButton1Click:Connect(function()
			if selected_button then
				selected_button.BackgroundTransparency = 1
			end

			selected_button = TextButton
			selected_player = player
			TextButton.BackgroundTransparency = 0.85

			priority_label.Text = "Priority: " .. library.get_priority(player)
			name_label.Text = "Name: " .. player.Name
			display_name_label.Text = "Display: " .. player.DisplayName
		end)
	end

	for _, player in next, players:GetPlayers() do
		create_player(player)
	end

	library:connection(players.PlayerAdded, function(player)
		create_player(player)
	end)

	library:connection(players.PlayerRemoving, function(player)
		player_buttons[player.Name].instance:Destroy()
	end)
	--

	-- keybind list
	local old_kblist = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0.5, 0),
		ZIndex = 2,
		Active = true,
		Draggable = true,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})

	local glow = library:create("ImageLabel", {
		Parent = old_kblist,
		Name = "",
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.8999999761581421,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 0, 42),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})

	library:apply_theme(glow, "accent", "ImageColor3")

	local inline1 = library:create("Frame", {
		Parent = old_kblist,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})

	local accent_line = library:create("Frame", {
		Parent = inline1,
		Name = "",
		BorderColor3 = Color3.fromRGB(34, 34, 34),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
	})

	library:apply_theme(accent_line, "accent", "BackgroundColor3")

	local name = library:create("TextLabel", {
		Parent = inline1,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "keybinds",
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local inline2 = library:create("Frame", {
		Parent = inline1,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	local main = library:create("Frame", {
		Parent = inline2,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(57, 57, 57),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	local tab_inline = library:create("Frame", {
		Parent = main,
		Name = "",
		Position = UDim2.new(0, 6, 0, 6),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -12, 1, -12),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(19, 19, 19),
	})

	local tabs = library:create("Frame", {
		Parent = tab_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = tabs,
		Name = "",
		PaddingBottom = UDim.new(0, 22),
		PaddingRight = UDim.new(0, 20),
		PaddingLeft = UDim.new(0, 20),
	})

	local UIListLayout = library:create("UIListLayout", {
		Parent = tabs,
		Name = "",
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 3),
	})

	local UIStroke = library:create("UIStroke", {
		Parent = tabs,
		Name = "",
		Color = Color3.fromRGB(57, 57, 57),
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local depth = library:create("Frame", {
		Parent = inline1,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	library.keybind_path = tabs
	--

	function cfg.toggle_list(bool)
		old_kblist.Visible = bool
	end

	function cfg.toggle_playerlist(bool)
		playerlist.Visible = bool
	end

	function cfg.toggle_watermark(bool)
		__holder.Visible = bool
	end

	function cfg.set_menu_visibility(bool, pl)
		WINDOW_PATH.Visible = bool
		cfg.IsOpen = bool and true or false

		playerlist.Visible = flags["player_list"] and bool or false
	end

	function cfg.set_open(bool)
		cfg.set_menu_visibility(bool)
	end

	return setmetatable(cfg, library)
end

function library:new_keybind(properties)
	local cfg = {
		text = properties.name or properties.text or "aimbot",
		key = properties.key or nil,
		mode = properties.mode or "hold",
	}

	local keybind_text = library:create("TextLabel", {
		Parent = library.keybind_path,
		Name = "",
		FontFace = library.font,
		LineHeight = 1.2000000476837158,
		TextStrokeTransparency = 0.5,
		AnchorPoint = Vector2.new(0.5, 0),
		TextSize = 12,
		Size = UDim2.new(0, 0, 0, 11),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 8),
		BorderSizePixel = 0,
		Visible = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = keybind_text,
		Name = "",
		PaddingTop = UDim.new(0, 6),
	})

	function cfg.set_visible(bool)
		keybind_text.Visible = bool
	end

	function cfg.change_text(text)
		keybind_text.Text = text
	end

	function keyName(key)
		local text = tostring(key) ~= "Enums" and (keys[key] or tostring(key):gsub("Enum.", "")) or nil
		local __text = text and (tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", ""))

		return __text or "..."
	end

	-- Shit ass function
	function cfg.update(n_properties)
		cfg.change_text(
			"["
				.. tostring(keyName(n_properties.key))
				.. "] "
				.. tostring(n_properties.text)
				.. " ("
				.. tostring(n_properties.mode)
				.. ")"
		)
	end

	cfg.change_text(
		"[" .. tostring(keyName(cfg.key)) .. "] " .. tostring(cfg.text) .. " (" .. tostring(cfg.mode) .. ")"
	)

	return cfg
end

function library:notification(properties)
	local cfg = {
		time = properties.time or 5,
		text = properties.text or properties.name or "ledger.live is pasted",
	}

	-- 28 offset

	function cfg:refresh_notifications()
		for _, notif in next, library.notifications do
			tween_service
				:Create(
					notif,
					TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut),
					{ Position = dim2(0, 20, 0, 72 + (_ * 28)) }
				)
				:Play()
		end
	end

	-- Instances
	local holder = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0, 72 + (#library.notifications * 28)),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		ZIndex = 2,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		AnchorPoint = Vector2.new(1, 0),
	})

	local inline1 = library:create("Frame", {
		Parent = holder,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(0, 0, 0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})

	local inline2 = library:create("Frame", {
		Parent = inline1,
		Name = "",
		Position = UDim2.new(0, 0, 0, 2),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	local main = library:create("Frame", {
		Parent = inline2,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(57, 57, 57),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	local tab_inline = library:create("Frame", {
		Parent = main,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(19, 19, 19),
	})

	local name = library:create("TextLabel", {
		Parent = tab_inline,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = cfg.text,
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = tab_inline,
		Name = "",
		PaddingRight = UDim.new(0, 14),
	})

	local depth = library:create("Frame", {
		Parent = inline1,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		ZIndex = 2,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	local accent_line = library:create("Frame", {
		Parent = inline1,
		Name = "",
		BorderColor3 = Color3.fromRGB(34, 34, 34),
		Size = UDim2.new(0, 2, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = themes.preset.accent,
	})

	library:apply_theme(accent_line, "accent", "BackgroundColor3")

	local glow = library:create("ImageLabel", {
		Parent = holder,
		Name = "",
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.8999999761581421,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, 0),
		Size = UDim2.new(0, 42, 1, 40),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})

	library:apply_theme(glow, "accent", "ImageColor3")
	--

	task.spawn(function()
		tween_service
			:Create(
				holder,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ AnchorPoint = Vector2.new(0, 0) }
			)
			:Play()

		task.wait(cfg.time)

		tween_service
			:Create(
				holder,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ AnchorPoint = Vector2.new(1, 0) }
			)
			:Play()
		for _, v in next, holder:GetDescendants() do
			if v:IsA("TextLabel") then
				tween_service
					:Create(
						v,
						TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
						{ TextTransparency = 1 }
					)
					:Play()
			elseif v:IsA("Frame") then
				tween_service
					:Create(
						v,
						TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
						{ BackgroundTransparency = 1 }
					)
					:Play()
			elseif v:IsA("ImageLabel") then
				tween_service
					:Create(
						v,
						TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
						{ ImageTransparency = 1 }
					)
					:Play()
			end
		end
	end)

	task.delay(cfg.time + 0.1, function()
		table.remove(library.notifications, table.find(library.notifications, holder))
		cfg:refresh_notifications()
		task.wait(0.5)
		holder:Destroy()
	end)

	table.insert(library.notifications, holder)
end

local function library_make_columns(parent)
	local scrolling_columns = library:create("Frame", {
		Parent = parent,
		Name = "",
		ClipsDescendants = true,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	library:create("UIListLayout", {
		Parent = scrolling_columns,
		Name = "",
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local left = library:create("ScrollingFrame", {
		Parent = scrolling_columns,
		Name = "",
		ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		Size = UDim2.new(0.5, -64, 1, 0),
		ClipsDescendants = false,
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	})

	left:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if library.current_element_open then
			library.current_element_open.set_visible(false)
			library.current_element_open.open = false
			library.current_element_open = nil
		end
	end)

	library:create("UIListLayout", {
		Parent = left,
		Name = "",
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	library:create("UIPadding", {
		Parent = left,
		Name = "",
		PaddingBottom = UDim.new(0, 15),
	})

	local right = library:create("ScrollingFrame", {
		Parent = scrolling_columns,
		Name = "",
		ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		Size = UDim2.new(0.5, -64, 1, 0),
		ClipsDescendants = false,
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	})

	right:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if library.current_element_open then
			library.current_element_open.set_visible(false)
			library.current_element_open.open = false
			library.current_element_open = nil
		end
	end)

	library:create("UIListLayout", {
		Parent = right,
		Name = "",
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	library:create("UIPadding", {
		Parent = right,
		Name = "",
		PaddingBottom = UDim.new(0, 15),
	})

	return scrolling_columns, left, right
end

function library:tab(properties)
	local cfg = {
		name = properties.name or "tab",
		icon = properties.icon or properties.Icon or nil,
		has_subtabs = properties.subtabs or properties.Subtabs or false,
		enabled = false,
		subtabs = {},
		current_subtab = nil,
	}

	-- Button
	local TAB_BUTTON = library:create("TextButton", {
		Parent = self.tab_holder,
		Name = "",
		FontFace = library.font,
		TextColor3 = themes.preset.unselected_text,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = cfg.icon and "" or cfg.name,
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		BorderSizePixel = 0,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	if cfg.icon then
		local icon_id = tostring(cfg.icon):gsub("rbxassetid://", "")
		local tab_icon = library:create("ImageLabel", {
			Parent = TAB_BUTTON,
			Name = "Icon",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			Size = UDim2.new(0, 14, 0, 14),
			Image = "rbxassetid://" .. icon_id,
			ImageColor3 = themes.preset.unselected_text,
			ScaleType = Enum.ScaleType.Fit,
		})
		library:apply_theme(tab_icon, "text", "ImageColor3")
		cfg._tab_icon = tab_icon

		local tab_label = library:create("TextLabel", {
			Parent = TAB_BUTTON,
			Name = "Label",
			FontFace = library.font,
			TextColor3 = themes.preset.unselected_text,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = cfg.name,
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -26, 1, 0),
			Position = UDim2.new(0, 24, 0, 0),
			TextSize = 12,
		})
		library:apply_theme(tab_label, "text", "TextColor3")
		cfg._tab_label = tab_label
	end

	local line = library:create("Frame", {
		Parent = TAB_BUTTON,
		Name = "",
		Position = UDim2.new(0, 0, 1, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = rgb(57, 57, 57),
	})

	library:apply_theme(line, "accent", "BackgroundColor3")

	local glow = library:create("ImageLabel", {
		Parent = line,
		Name = "",
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.8999999761581421,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 1, 40),
		ZIndex = 2,
		Visible = false,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})

	library:apply_theme(glow, "accent", "ImageColor3")

	library:create("Frame", {
		Parent = line,
		Name = "",
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	-- Tab Instances
	local TAB = library:create("Frame", {
		Parent = self.tab_instance_holder,
		Name = "",
		Visible = false,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	if cfg.has_subtabs then
		local sub_bar = library:create("Frame", {
			Parent = TAB,
			Name = "SubTabs",
			BorderColor3 = Color3.fromRGB(8, 8, 8),
			BackgroundColor3 = Color3.fromRGB(19, 19, 19),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 6, 0, 6),
			Size = UDim2.new(1, -12, 0, 40),
		})

		local sub_inner = library:create("Frame", {
			Parent = sub_bar,
			Name = "",
			Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(1, -4, 1, -4),
			BorderColor3 = Color3.fromRGB(56, 56, 56),
			BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		})

		library:create("UIListLayout", {
			Parent = sub_inner,
			Name = "",
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		library:create("UIPadding", {
			Parent = sub_inner,
			Name = "",
			PaddingLeft = UDim.new(0, 2),
			PaddingRight = UDim.new(0, 2),
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 2),
		})

		cfg.subtab_holder = sub_inner

		local content = library:create("Frame", {
			Parent = TAB,
			Name = "SubContent",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 6, 0, 50),
			Size = UDim2.new(1, -12, 1, -56),
		})
		cfg.sub_content = content
		cfg.column_holder = content
	else
		local scrolling_columns, left, right = library_make_columns(TAB)
		scrolling_columns.Position = UDim2.new(0, 6, 0, 6)
		scrolling_columns.Size = UDim2.new(1, -12, 1, -12)
		cfg.column_holder = scrolling_columns
		cfg.left = left
		cfg.right = right
	end

	function cfg.open_tab()
		if library.current_tab and library.current_tab[1] ~= TAB_BUTTON then
			local button = library.current_tab[1]
			button.TextColor3 = themes.preset.unselected_text

			local parent = button:FindFirstChildOfClass("Frame")
			if parent then
				parent.BackgroundColor3 = rgb(57, 57, 57)
				local glow_img = parent:FindFirstChildOfClass("ImageLabel")
				if glow_img then
					glow_img.Visible = false
				end
			end

			local old_icon = button:FindFirstChild("Icon")
			if old_icon then
				old_icon.ImageColor3 = themes.preset.unselected_text
			end
			local old_label = button:FindFirstChild("Label")
			if old_label then
				old_label.TextColor3 = themes.preset.unselected_text
			end

			library.current_tab[2].Visible = false
		end

		library.current_tab = {
			TAB_BUTTON,
			TAB,
		}

		line.BackgroundColor3 = themes.preset.accent
		glow.Visible = true
		TAB_BUTTON.TextColor3 = themes.preset.text
		TAB.Visible = true
		if cfg._tab_icon then
			cfg._tab_icon.ImageColor3 = themes.preset.accent
		end
		if cfg._tab_label then
			cfg._tab_label.TextColor3 = themes.preset.text
		end

		if library.current_element_open and library.current_element_open ~= cfg then
			library.current_element_open.set_visible(false)
			library.current_element_open.open = false
			library.current_element_open = nil
		end

		if cfg.current_subtab and cfg.current_subtab.open_subtab then
			cfg.current_subtab.open_subtab()
		end
	end

	TAB_BUTTON.MouseButton1Click:Connect(cfg.open_tab)

	return setmetatable(cfg, library)
end

function library:subtab(properties)
	local parent_tab = self
	if not parent_tab.has_subtabs or not parent_tab.subtab_holder then
		error("[library] subtab requires tab({ subtabs = true })")
	end

	local cfg = {
		name = properties.name or properties.Name or "Sub",
		icon = properties.icon or properties.Icon or "6031280882",
		parent_tab = parent_tab,
		active = false,
	}

	local icon_id = tostring(cfg.icon):gsub("rbxassetid://", "")

	local button = library:create("TextButton", {
		Parent = parent_tab.subtab_holder,
		Name = "",
		Text = "",
		AutoButtonColor = false,
		BorderColor3 = Color3.fromRGB(10, 10, 10),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(28, 28, 28),
	})
	library:apply_theme(button, "outline", "BackgroundColor3")

	local icon = library:create("ImageLabel", {
		Parent = button,
		Name = "Icon",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -4),
		Size = UDim2.new(0, 18, 0, 18),
		Image = "rbxassetid://" .. icon_id,
		ImageColor3 = themes.preset.unselected_text,
		ImageTransparency = 0.25,
		ScaleType = Enum.ScaleType.Fit,
	})

	local label = library:create("TextLabel", {
		Parent = button,
		Name = "Label",
		FontFace = library.font,
		Text = cfg.name,
		TextColor3 = themes.preset.unselected_text,
		TextTransparency = 0.25,
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -2),
		Size = UDim2.new(1, -4, 0, 10),
		TextSize = 10,
	})

	local underline = library:create("Frame", {
		Parent = button,
		Name = "Line",
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = themes.preset.accent,
		Visible = false,
	})
	library:apply_theme(underline, "accent", "BackgroundColor3")

	local page = library:create("Frame", {
		Parent = parent_tab.sub_content,
		Name = "",
		Visible = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
	})

	local _, left, right = library_make_columns(page)
	cfg.left = left
	cfg.right = right
	cfg.page = page
	cfg.button = button

	function cfg.open_subtab()
		for _, other in next, parent_tab.subtabs do
			other.active = false
			other.page.Visible = false
			other.button.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
			local o_icon = other.button:FindFirstChild("Icon")
			local o_label = other.button:FindFirstChild("Label")
			local o_line = other.button:FindFirstChild("Line")
			if o_icon then
				o_icon.ImageColor3 = themes.preset.unselected_text
				o_icon.ImageTransparency = 0.25
			end
			if o_label then
				o_label.TextColor3 = themes.preset.unselected_text
				o_label.TextTransparency = 0.25
			end
			if o_line then
				o_line.Visible = false
			end
		end

		cfg.active = true
		page.Visible = true
		underline.Visible = true
		underline.BackgroundColor3 = themes.preset.accent
		button.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
		icon.ImageColor3 = themes.preset.accent
		icon.ImageTransparency = 0
		label.TextColor3 = themes.preset.text
		label.TextTransparency = 0
		parent_tab.current_subtab = cfg
		parent_tab.left = cfg.left
		parent_tab.right = cfg.right

		if library.current_element_open then
			library.current_element_open.set_visible(false)
			library.current_element_open.open = false
			library.current_element_open = nil
		end
	end

	button.MouseButton1Click:Connect(cfg.open_subtab)

	table.insert(parent_tab.subtabs, cfg)
	if #parent_tab.subtabs == 1 then
		cfg.open_subtab()
	end

	return setmetatable(cfg, library)
end

function library:section(properties)
	local cfg = {
		name = properties.name or properties.Name or "Section",
		side = properties.side or properties.Side or "left",
	}

	-- Instances
	local section = library:create("Frame", {
		Parent = self[cfg.side],
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = 2,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local section_inline = library:create("Frame", {
		Parent = section,
		Name = "",
		Position = UDim2.new(0, 0, 0, 4),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, 0, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local name = library:create("TextLabel", {
		Parent = section_inline,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 0),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local section = library:create("Frame", {
		Parent = section_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local elements = library:create("Frame", {
		Parent = section,
		Name = "",
		Position = UDim2.new(0, 12, 0, 12),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -24, 0, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local UIListLayout = library:create("UIListLayout", {
		Parent = elements,
		Name = "",
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 3),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = section,
		Name = "",
		PaddingBottom = UDim.new(0, 13),
	})
	--

	cfg["holder"] = elements

	return setmetatable(cfg, library)
end

function library:hitpart_picker(properties)
	local cfg = {
		name = properties.name or properties.Name or "Hitpart",
		side = properties.side or properties.Side or "left",
		flag = properties.flag or "Hitpart",
		default = properties.default or { "Head" },
		type_char = properties.type or "R6",
		multi = properties.multi or false,
		callback = properties.callback or function() end,
		previous_holder = self,
	}

	flags[cfg.flag] = {}

	local bodyparts = {}
	local bools = {}

	local r15_hitpart_holder = library:create("Frame", {
		Parent = self[cfg.side],
		Name = "",
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 272),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local hitpart_inline = library:create("Frame", {
		Parent = r15_hitpart_holder,
		Name = "",
		Position = UDim2.new(0, 0, 0, 4),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, 0, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local hitpart = library:create("Frame", {
		Parent = hitpart_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	if cfg.type_char == "R15" then
		bodyparts.Head = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, -25, 0, 16),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 50, 0, 44),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.UpperTorso = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, -42, 0, 64),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 84, 0, 76),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.LeftUpperArm = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, -86, 0, 64),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 34),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.RightUpperArm = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, 46, 0, 64),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 34),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.LeftUpperLeg = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, -42, 0, 158),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 34),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.LeftLowerLeg = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, -42, 0, 196),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 42),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.RightFoot = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, 2, 0, 242),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 6),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.LeftFoot = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, -42, 0, 242),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 6),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.RightLowerLeg = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, 2, 0, 196),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 42),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.RightUpperLeg = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, 2, 0, 158),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 34),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.LeftHand = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, -86, 0, 148),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 6),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.RightHand = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, 46, 0, 148),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 6),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.LowerTorso = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, -42, 0, 144),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 84, 0, 10),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.RightLowerArm = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, 46, 0, 102),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 42),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.LeftLowerArm = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, -86, 0, 102),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 42),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		local outline = library:create("TextButton", {
			Text = "",
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, -10, 0, 96),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 20, 0, 20),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		})

		bodyparts.HumanoidRootPart = library:create("TextButton", {
			Text = "",
			Parent = outline,
			Name = "",
			Position = UDim2.new(0, 4, 0, 4),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(1, -8, 1, -8),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})
	else
		bodyparts.Head = library:create("TextButton", {
			Parent = hitpart,
			Name = "",
			Text = "",
			Position = UDim2.new(0.5, -25, 0, 16),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 50, 0, 44),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.Torso = library:create("TextButton", {
			Parent = hitpart,
			Name = "",
			Text = "",
			Position = UDim2.new(0.5, -42, 0, 64),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 84, 0, 90),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.LeftArm = library:create("TextButton", {
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, -86, 0, 64),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 90),
			BorderSizePixel = 0,
			Text = "",
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.RightArm = library:create("TextButton", {
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, 46, 0, 64),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 90),
			Text = "",
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.RightLeg = library:create("TextButton", {
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, 2, 0, 158),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 90),
			BorderSizePixel = 0,
			Text = "",
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		bodyparts.LeftLeg = library:create("TextButton", {
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, -42, 0, 158),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 40, 0, 90),
			BorderSizePixel = 0,
			Text = "",
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		local hrp_out = library:create("TextButton", {
			Parent = hitpart,
			Name = "",
			Position = UDim2.new(0.5, -10, 0, 99),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 20, 0, 20),
			BorderSizePixel = 0,
			Text = "",
			BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		})

		bodyparts.HumanoidRootPart = library:create("TextButton", {
			Parent = hrp_out,
			Name = "",
			Position = UDim2.new(0, 4, 0, 4),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(1, -8, 1, -8),
			BorderSizePixel = 0,
			Text = "",
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})
	end

	local name = library:create("TextLabel", {
		Parent = hitpart_inline,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 0),
		ZIndex = 2,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	function cfg.set(parts)
		flags[cfg.flag] = {}
		for name, button in pairs(bodyparts) do
			bools[name] = false
			local glow = button:FindFirstChildOfClass("ImageLabel")
			if glow then
				glow.Visible = false
			end
			button.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
		end

		for _, part in pairs(parts) do
			if bodyparts[part] then
				bools[part] = true
				table.insert(flags[cfg.flag], part)
				local glow = bodyparts[part]:FindFirstChildOfClass("ImageLabel")
				if glow then
					glow.Visible = true
				end
				bodyparts[part].BackgroundColor3 = themes.preset.accent
			end
		end

		cfg.callback(flags[cfg.flag])
	end

	for name, button in next, bodyparts do
		bools[name] = false

		library:apply_theme(button, "accent", "BackgroundColor3")

		local glow = library:create("ImageLabel", {
			Parent = button,
			Name = "",
			Visible = false,
			ImageColor3 = themes.preset.accent,
			ScaleType = Enum.ScaleType.Slice,
			ImageTransparency = 0.8999999761581421,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Image = "http://www.roblox.com/asset/?id=18245826428",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, -20, 0, -20),
			Size = UDim2.new(1, 40, 1, 40),
			ZIndex = 2,
			BorderSizePixel = 0,
			SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
		})

		library:apply_theme(glow, "accent", "ImageColor3")

		library:connection(button.MouseButton1Click, function()
			if not cfg.multi then
				cfg.set({ name })
			else
				bools[name] = not bools[name]

				if bools[name] then
					table.insert(flags[cfg.flag], name)
				else
					local index = table.find(flags[cfg.flag], name)
					table.remove(flags[cfg.flag], index)
				end

				glow.Visible = bools[name]
				button.BackgroundColor3 = bools[name] and themes.preset.accent or Color3.fromRGB(38, 38, 38)

				cfg.callback(flags[cfg.flag])
			end
		end)
	end

	if #cfg.default > 1 and not cfg.multi then
		cfg.default = { cfg.default[1] }
	end

	cfg.set(cfg.default)
	config_flags[cfg.flag] = cfg.set
	return setmetatable(cfg, library)
end

function library:toggle(properties)
	local cfg = {
		enabled = properties.enabled or nil,
		name = properties.name or "Toggle",
		flag = properties.flag or tostring(math.random(1, 9999999)),
		callback = properties.callback or function() end,
		default = properties.default or false,
		previous_holder = self,
	}

	-- Instances
	local object = library:create("TextButton", {
		Parent = self.holder,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -26, 0, 12),
		ZIndex = 1,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local right_components = library:create("Frame", {
		Parent = object,
		Name = "",
		Position = UDim2.new(1, 15, 0, 1),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(0, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local list = library:create("UIListLayout", {
		Parent = right_components,
		Name = "",
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local icon_inline = library:create("TextButton", {
		Parent = object,
		Name = "",
		Position = UDim2.new(0, -15, 0, 1),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(0, 10, 0, 10),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local icon = library:create("Frame", {
		Parent = icon_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local icon_2 = library:create("Frame", {
		Parent = icon,
		Name = "",
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = themes.preset.accent,
	})
	library:apply_theme(icon_2, "accent", "BackgroundColor3")

	local glow = library:create("ImageLabel", {
		Parent = icon_inline,
		Name = "",
		Visible = false,
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.75,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -12, 0, -12),
		Size = UDim2.new(1, 24, 1, 24),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})

	library:apply_theme(glow, "accent", "ImageColor3")

	local bottom_components = library:create("Frame", {
		Parent = object,
		Name = "",
		Visible = true,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Position = UDim2.new(0, 0, 0, 13),
		Size = UDim2.new(1, 26, 0, 0),
		ZIndex = 2,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local list = library:create("UIListLayout", {
		Parent = bottom_components,
		Name = "",
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	--

	function cfg.set(bool)
		icon_2.Visible = bool
		glow.Visible = bool

		flags[cfg.flag] = bool

		cfg.callback(bool)
	end

	library:connection(object.MouseButton1Click, function()
		cfg.enabled = not cfg.enabled

		cfg.set(cfg.enabled)
	end)

	library:connection(icon_inline.MouseButton1Click, function()
		cfg.enabled = not cfg.enabled

		cfg.set(cfg.enabled)
	end)

	cfg.set(cfg.default)

	self.previous_holder = left_components
	self.bottom_holder = bottom_components
	self.right_holder = right_components

	config_flags[cfg.flag] = cfg.set

	return setmetatable(cfg, library)
end

function library:slider(properties)
	local cfg = {
		name = properties.name or nil,
		suffix = properties.suffix or "",
		flag = properties.flag or tostring(2 ^ 789),
		callback = properties.callback or function() end,

		min = properties.min or properties.minimum or 0,
		max = properties.max or properties.maximum or 100,
		intervals = properties.interval or properties.decimal or 1,
		default = properties.default or 10,

		dragging = false,
		value = properties.default or 10,

		previous_holder = self,
	}

	local bottom_components
	if cfg.name then
		object = library:create("TextLabel", {
			Parent = self.holder,
			Name = "",
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Text = cfg.name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, -26, 0, 12),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		bottom_components = library:create("Frame", {
			Parent = object,
			Name = "",
			Visible = true,
			Position = UDim2.new(0, 0, 0, 13),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(1, 26, 0, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		local list = library:create("UIListLayout", {
			Parent = bottom_components,
			Name = "",
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
	else
		self.bottom_holder.Parent.AutomaticSize = Enum.AutomaticSize.Y
		self.bottom_holder.Parent.TextYAlignment = Enum.TextYAlignment.Top
	end

	local slider_holder = library:create("Frame", {
		Parent = cfg.name and bottom_components or self.bottom_holder,
		Name = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local slider_inline = library:create("TextButton", {
		Parent = slider_holder,
		Name = "",
		Position = UDim2.new(0, 0, 0, 1),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 8),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local fill_inline = library:create("Frame", {
		Parent = slider_inline,
		Name = "",
		Size = UDim2.new(0.5, 0, 1, 0),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		ZIndex = 2,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(19, 19, 19),
	})

	local fill = library:create("Frame", {
		Parent = fill_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, 0, 1, -4),
		BackgroundColor3 = themes.preset.accent,
	})

	library:apply_theme(fill, "accent", "BackgroundColor3")
	library:apply_theme(fill, "accent", "BorderColor3")

	local VALUE_TEXT = library:create("TextLabel", {
		Parent = fill_inline,
		Name = "",
		RichText = true,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 1, 0, 11),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		FontFace = library.font,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local glow = library:create("ImageLabel", {
		Parent = fill_inline,
		Name = "",
		ImageColor3 = themes.preset.accent,
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.8999999761581421,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -18, 0, -18),
		Size = UDim2.new(1, 36, 1, 36),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})

	library:apply_theme(glow, "accent", "ImageColor3")

	local add = library:create("TextButton", {
		Parent = slider_inline,
		Name = "",
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "+",
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 5, 0, -1),
		Size = UDim2.new(0, 8, 0, 8),
		FontFace = library.font,
		TextSize = 8,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local sub = library:create("TextButton", {
		Parent = slider_inline,
		Name = "",
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "-",
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -15, 0, -1),
		Size = UDim2.new(0, 8, 0, 8),
		FontFace = library.font,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local slider = library:create("Frame", {
		Parent = slider_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local pad = library:create("UIPadding", {
		Parent = slider_holder,
		Name = "",
		PaddingBottom = UDim.new(0, -17),
	})

	function cfg.set(value)
		if type(value) ~= "number" then
			return
		end

		cfg.value = math.clamp(library:round(value, cfg.intervals), cfg.min, cfg.max)

		fill_inline.Size = dim2((cfg.value - cfg.min) / (cfg.max - cfg.min), 0, 1, 0)
		VALUE_TEXT.Text = tostring(cfg.value) .. cfg.suffix
		flags[cfg.flag] = cfg.value

		cfg.callback(flags[cfg.flag])
	end

	library:connection(uis.InputChanged, function(input)
		if cfg.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local size_x = (input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X
			local value = ((cfg.max - cfg.min) * size_x) + cfg.min
			cfg.set(value)
		end
	end)

	library:connection(uis.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			cfg.dragging = false
		end
	end)

	slider_inline.MouseButton1Down:Connect(function()
		cfg.dragging = true
	end)

	add.MouseButton1Down:Connect(function()
		cfg.value += cfg.intervals
		cfg.set(cfg.value)
	end)

	sub.MouseButton1Down:Connect(function()
		cfg.value -= cfg.intervals
		cfg.set(cfg.value)
	end)

	cfg.set(cfg.default)

	config_flags[cfg.flag] = cfg.set

	library.config_flags[cfg.flag] = cfg.set

	return setmetatable(cfg, library)
end

function library:dropdown(properties)
	local cfg = {
		name = properties.name or nil,
		flag = properties.flag or tostring(math.random(1, 9999999)),

		items = properties.items or { "1", "2", "3" },
		callback = properties.callback or function() end,
		multi = properties.multi or false,

		open = false,
		option_instances = {},
		multi_items = {},

		previous_holder = self,
	}
	cfg.default = properties.default or (cfg.multi and { cfg.items[1] }) or cfg.items[1] or nil

	local bottom_components
	local object
	if cfg.name then
		object = library:create("TextLabel", {
			Parent = self.holder,
			Name = "",
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Text = cfg.name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, -26, 0, 12),
			BorderSizePixel = 0,
			ZIndex = 2,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		bottom_components = library:create("Frame", {
			Parent = object,
			Name = "",
			Visible = true,
			Position = UDim2.new(0, 0, 0, 13),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(1, 26, 0, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		local list = library:create("UIListLayout", {
			Parent = bottom_components,
			Name = "",
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
	else
		self.bottom_holder.Parent.AutomaticSize = Enum.AutomaticSize.Y
		self.bottom_holder.Parent.TextYAlignment = Enum.TextYAlignment.Top
	end

	-- Instances
	local dropdown_inline = library:create("Frame", {
		Parent = cfg.name and bottom_components or self.bottom_holder,
		Name = "",
		Position = UDim2.new(0, -15, 0, 2),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local dropdown = library:create("TextButton", {
		Parent = dropdown_inline,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "option 1, option 3",
		TextStrokeTransparency = 0.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.new(0, 2, 0, 2),
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = dropdown,
		Name = "",
		PaddingLeft = UDim.new(0, 5),
	})

	local icon = library:create("TextLabel", {
		Parent = dropdown,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "+",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -6, 0, -1),
		BorderSizePixel = 0,
		TextSize = 8,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local content_inline = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(0, dropdown_inline.AbsoluteSize.X, 0, 0),
		Position = UDim2.new(
			0,
			dropdown_inline.AbsolutePosition.X,
			0,
			dropdown_inline.AbsolutePosition.Y + dropdown_inline.AbsoluteSize.Y + 2
		),
		BorderSizePixel = 0,
		ZIndex = 2,
		Visible = false,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	dropdown_inline:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		content_inline.Position = UDim2.new(
			0,
			dropdown_inline.AbsolutePosition.X,
			0,
			dropdown_inline.AbsolutePosition.Y + dropdown_inline.AbsoluteSize.Y + 2
		)
	end)

	dropdown_inline:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		content_inline.Size = UDim2.new(0, dropdown_inline.AbsoluteSize.X, 0, 0)
	end)

	local content = library:create("Frame", {
		Parent = content_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local options = library:create("Frame", {
		Parent = content,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
	})

	local UIListLayout = library:create("UIListLayout", {
		Parent = options,
		Name = "",
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local UIPadding = library:create("UIPadding", {
		Parent = options,
		Name = "",
		PaddingBottom = UDim.new(0, 4),
	})

	-- local op3 = library:create("TextButton", {
	--     Parent = options,
	--     Name = "",
	--     FontFace = library.font,
	--     TextColor3 = Color3.fromRGB(170, 170, 170),
	--     BorderColor3 = Color3.fromRGB(56, 56, 56),
	--     Text = "option 3",
	--     TextStrokeTransparency = 0.5,
	--     Size = UDim2.new(1, 0, 0, 14),
	--     TextXAlignment = Enum.TextXAlignment.Left,
	--     Position = UDim2.new(0, 2, 0, 2),
	--     BorderSizePixel = 0,
	--     TextSize = 12,
	--     BackgroundColor3 = Color3.fromRGB(65, 65, 65)
	-- })

	-- local UIPadding = library:create("UIPadding", {
	--     Parent = op3,
	--     Name = "",
	--     PaddingLeft = UDim.new(0, 5)
	-- })
	--

	function cfg.set_visible(bool)
		content_inline.Visible = bool

		icon.Text = bool and "-" or "+"
		icon.TextSize = bool and 12 or 8

		if cfg.name then
			object.ZIndex = bool and 9999 or 3
		end

		if bool then
			if library.current_element_open and library.current_element_open ~= cfg then
				library.current_element_open.set_visible(false)
				library.current_element_open.open = false
			end

			library.current_element_open = cfg
		end
	end

	function cfg.set(value)
		local selected = {}

		local is_table = type(value) == "table"

		for _, v in next, cfg.option_instances do
			if v.Text == value or (is_table and table.find(value, v.Text)) then
				table.insert(selected, v.Text)
				cfg.multi_items = selected
				v.BackgroundTransparency = 0
			else
				v.BackgroundTransparency = 1
			end
		end

		dropdown.Text = is_table and table.concat(selected, ",  ") or selected[1] or ""
		flags[cfg.flag] = is_table and selected or selected[1]
		cfg.callback(flags[cfg.flag])
	end

	function cfg:refresh_options(refreshed_list)
		for _, v in next, cfg.option_instances do
			v:Destroy()
		end

		cfg.option_instances = {}

		for i, v in next, refreshed_list do
			local op3 = library:create("TextButton", {
				Parent = options,
				Name = "",
				FontFace = library.font,
				TextColor3 = Color3.fromRGB(170, 170, 170),
				BorderColor3 = Color3.fromRGB(56, 56, 56),
				Text = v,
				BackgroundTransparency = 1,
				TextStrokeTransparency = 0.5,
				Size = UDim2.new(1, 0, 0, 14),
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 2, 0, 2),
				BorderSizePixel = 0,
				TextSize = 12,
				BackgroundColor3 = Color3.fromRGB(65, 65, 65),
			})

			local UIPadding = library:create("UIPadding", {
				Parent = op3,
				Name = "",
				PaddingLeft = UDim.new(0, 5),
			})

			table.insert(cfg.option_instances, op3)

			op3.MouseButton1Down:Connect(function()
				if cfg.multi then
					local selected_index = table.find(cfg.multi_items, op3.Text)

					if selected_index then
						table.remove(cfg.multi_items, selected_index)
					else
						table.insert(cfg.multi_items, op3.Text)
					end

					cfg.set(cfg.multi_items)
				else
					cfg.set_visible(false)
					cfg.open = false

					cfg.set(op3.Text)
				end
			end)
		end

		dropdown.Text = ""
	end

	dropdown.MouseButton1Click:Connect(function()
		cfg.open = not cfg.open

		cfg.set_visible(cfg.open)
	end)

	cfg:refresh_options(cfg.items)

	cfg.set(cfg.default)

	library.config_flags[cfg.flag] = cfg.set

	return setmetatable(cfg, library)
end

function library:colorpicker(properties)
	local cfg = {
		name = properties.name or nil,
		flag = properties.flag or tostring(2 ^ 789),
		color = properties.color or properties.default or Color3.new(1, 1, 1), -- Default to white color if not provided
		alpha = properties.alpha or 1,
		callback = properties.callback or function() end,
		animation = "normal",
		saved_color,
		right_holder = self.right_holder or nil,
		holder = self.holder or nil,
	}

	flags[cfg.flag] = {}

	local dragging_sat = false
	local dragging_hue = false
	local dragging_alpha = false

	local h, s, v = cfg.color:ToHSV()
	local a = cfg.alpha

	-- Button Instances
	local right_components
	if cfg.name then
		local object = library:create("TextLabel", {
			Parent = self.holder,
			Name = "",
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Text = cfg.name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, -26, 0, 12),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		right_components = library:create("Frame", {
			Parent = object,
			Name = "",
			Position = UDim2.new(1, 15, 0, 1),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 0, 1, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		local list = library:create("UIListLayout", {
			Parent = right_components,
			Name = "",
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
	end

	local icon_inline = library:create("TextButton", {
		Parent = cfg.name and right_components or self.right_holder,
		Name = "",
		Text = "",
		Size = UDim2.new(0, 16, 0, 10),
		Position = UDim2.new(0, -15, 0, 1),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		ZIndex = 3,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(9, 9, 44),
	})

	local icon = library:create("Frame", {
		Parent = icon_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(22, 22, 108),
		ZIndex = 2,
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(41, 41, 204),
	})

	local glow = library:create("ImageLabel", {
		Parent = icon_inline,
		Name = "",
		ImageColor3 = Color3.fromRGB(41, 41, 204),
		ScaleType = Enum.ScaleType.Slice,
		ImageTransparency = 0.8999999761581421,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "http://www.roblox.com/asset/?id=18245826428",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -20, 0, -20),
		Size = UDim2.new(1, 40, 1, 40),
		ZIndex = 2,
		BorderSizePixel = 0,
		SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79)),
	})
	--

	-- Colorpicker Instances
	local picker_inline = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		Size = UDim2.new(0, 142, 0, 146),
		Position = dim2(0, icon_inline.AbsolutePosition.X + 1, 0, icon_inline.AbsolutePosition.Y + 17),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		ZIndex = 9999,
		BorderSizePixel = 0,
		Visible = false,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local picker = library:create("Frame", {
		Parent = picker_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local sat_inline = library:create("TextButton", {
		Parent = picker,
		Name = "",
		Text = "",
		Position = UDim2.new(0, 4, 0, 4),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -8, 1, -50),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local sat = library:create("Frame", {
		Parent = sat_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
	})

	local sat_white = library:create("Frame", {
		Parent = sat,
		Name = "",
		Size = UDim2.new(1, 0, 1, 0),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		ZIndex = 2,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local UIGradient = library:create("UIGradient", {
		Parent = sat_white,
		Name = "",
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})

	local sat_black = library:create("Frame", {
		Parent = sat_white,
		Name = "",
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local UIGradient = library:create("UIGradient", {
		Parent = sat_black,
		Name = "",
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
		}),
	})

	local sat_black_cursor = library:create("Frame", {
		Parent = sat_black,
		Name = "",
		Position = UDim2.new(0.800000011920929, 0, 0.20000000298023224, 0),
		BorderColor3 = Color3.fromRGB(108, 22, 22),
		Size = UDim2.new(0, 1, 0, 1),
		BackgroundColor3 = Color3.fromRGB(204, 41, 41),
	})

	local preview_inline = library:create("Frame", {
		Parent = picker,
		Name = "",
		Position = UDim2.new(1, -20, 1, -20),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(0, 16, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
	})

	local preview = library:create("Frame", {
		Parent = preview_inline,
		Name = "",
		BackgroundTransparency = 0,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 2,
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(204, 41, 41),
	})

	local preview_image = library:create("ImageLabel", {
		Parent = preview_inline,
		Name = "",
		ScaleType = Enum.ScaleType.Tile,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Image = "http://www.roblox.com/asset/?id=18274452449",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		TileSize = UDim2.new(0, 6, 0, 6),
		BorderSizePixel = 0,
		ZIndex = 3,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local hue_inline = library:create("TextButton", {
		Parent = picker,
		Text = "",
		Name = "",
		Position = UDim2.new(0, 4, 1, -44),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -8, 0, 10),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local hue_border = library:create("Frame", {
		Parent = hue_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local hue = library:create("Frame", {
		Parent = hue_border,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local UIGradient = library:create("UIGradient", {
		Parent = hue,
		Name = "",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.16699999570846558, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.3330000042915344, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.6669999957084656, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.8330000042915344, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
	})

	local hue_cursor = library:create("Frame", {
		Parent = hue,
		Name = "",
		BorderColor3 = Color3.fromRGB(108, 22, 22),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Color3.fromRGB(204, 41, 41),
	})

	local input_inline = library:create("Frame", {
		Parent = picker,
		Name = "",
		Position = UDim2.new(0, 4, 1, -20),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local __input = library:create("TextBox", {
		Parent = input_inline,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "204, 41, 41, 0.5",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, -4, 1, -4),
		PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
		Position = UDim2.new(0, 2, 0, 2),
		PlaceholderText = "r, g, b, a",
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local alpha_inline = library:create("TextButton", {
		Parent = picker,
		Name = "",
		Text = "",
		Position = UDim2.new(0, 4, 1, -32),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -8, 0, 10),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local alpha = library:create("Frame", {
		Parent = alpha_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(204, 41, 41),
	})

	local alpha_image = library:create("ImageLabel", {
		Parent = alpha,
		Name = "",
		ScaleType = Enum.ScaleType.Tile,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Image = "http://www.roblox.com/asset/?id=18343135386",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TileSize = UDim2.new(0, 6, 0, 6),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local UIGradient = library:create("UIGradient", {
		Parent = alpha_image,
		Name = "",
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
	})

	local alpha_cursor = library:create("Frame", {
		Parent = alpha_image,
		Name = "",
		Position = UDim2.new(0.5, 0, 0, 0),
		BorderColor3 = Color3.fromRGB(108, 22, 22),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Color3.fromRGB(204, 41, 41),
	})

	--

	-- Animation Handling
	local content_inline = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(0, 73, 0, 0),
		Position = dim2(0, icon_inline.AbsolutePosition.X + 20, 0, icon_inline.AbsolutePosition.Y),
		BorderSizePixel = 0,
		ZIndex = 2,
		Visible = false,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local content = library:create("Frame", {
		Parent = content_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local options = library:create("Frame", {
		Parent = content,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
	})

	local UIListLayout = library:create("UIListLayout", {
		Parent = options,
		Name = "",
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local normal = library:create("TextButton", {
		Parent = options,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "normal",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 12),
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 2, 0, 2),
		BorderSizePixel = 0,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(65, 65, 65),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = normal,
		Name = "",
		PaddingBottom = UDim.new(0, 1),
		PaddingLeft = UDim.new(0, 5),
	})

	local rainbow = library:create("TextButton", {
		Parent = options,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "rainbow",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 2, 0, 2),
		BorderSizePixel = 0,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(65, 65, 65),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = rainbow,
		Name = "",
		PaddingBottom = UDim.new(0, 1),
		PaddingLeft = UDim.new(0, 5),
	})

	local fade = library:create("TextButton", {
		Parent = options,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "fade",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 2, 0, 2),
		BorderSizePixel = 0,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(65, 65, 65),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = fade,
		Name = "",
		PaddingBottom = UDim.new(0, 1),
		PaddingLeft = UDim.new(0, 5),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = options,
		Name = "",
		PaddingBottom = UDim.new(0, 4),
	})

	local fade_alpha = library:create("TextButton", {
		Parent = options,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "fade alpha",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 2, 0, 2),
		BorderSizePixel = 0,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(65, 65, 65),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = fade_alpha,
		Name = "",
		PaddingBottom = UDim.new(0, 1),
		PaddingLeft = UDim.new(0, 5),
	})
	--

	function cfg.set_visible(bool)
		picker_inline.Visible = bool
		content_inline.Visible = false

		if bool then
			if library.current_element_open and library.current_element_open ~= cfg then
				library.current_element_open.set_visible(false)
				library.current_element_open.open = false
			end

			library.current_element_open = cfg
		end

		picker_inline.Position = dim2(0, icon_inline.AbsolutePosition.X + 1, 0, icon_inline.AbsolutePosition.Y + 17)
		content_inline.Position = dim2(0, icon_inline.AbsolutePosition.X + 20, 0, icon_inline.AbsolutePosition.Y)
	end

	icon_inline.MouseButton1Click:Connect(function()
		cfg.open = not cfg.open

		cfg.set_visible(cfg.open)
	end)

	icon_inline.MouseButton2Click:Connect(function()
		if cfg.open then
			cfg.open = false
			cfg.set_visible(false)
		end

		content_inline.Visible = not content_inline.Visible

		picker_inline.Position = dim2(0, icon_inline.AbsolutePosition.X + 1, 0, icon_inline.AbsolutePosition.Y + 17)
		content_inline.Position = dim2(0, icon_inline.AbsolutePosition.X + 20, 0, icon_inline.AbsolutePosition.Y)
	end)

	function cfg.set(color, alpha)
		if color then
			h, s, v = color:ToHSV()
		else
			cfg.saved_color = hsv(s, s, v)
		end

		if alpha then
			a = alpha
		end

		local visual = alpha_inline:FindFirstChildOfClass("Frame")

		if not visual then
			return
		end

		local hsv_position = Color3.fromHSV(h, s, v)
		local Color = Color3.fromHSV(h, s, v)

		local value = h
		local offset = (value < 1) and 0 or -4
		hue_cursor.Position = dim2(value, offset, 0, 0)

		local offset = (a < 1) and 0 or -4
		alpha_cursor.Position = dim2(a, offset, 0, 0)

		visual.BackgroundColor3 = Color
		glow.ImageColor3 = Color

		local RGB_Format = visual.BackgroundColor3

		icon_inline.BackgroundColor3 = Color3.fromRGB(RGB_Format.R / 4, RGB_Format.G / 4, RGB_Format.B / 4)
		icon.BorderColor3 = Color3.fromRGB(
			math.floor((Color.R * 255) + 0.5) / 2,
			math.floor((Color.G * 255) + 0.5) / 2,
			math.floor((Color.B * 255) + 0.5) / 2
		)
		icon.BackgroundColor3 = Color

		__input.Text = math.floor(RGB_Format.R * 255)
			.. ", "
			.. math.floor(RGB_Format.G * 255)
			.. ", "
			.. math.floor(RGB_Format.B * 255)
			.. ", "
			.. library:round(a, 0.01)
		preview.BackgroundColor3 = Color
		preview_image.ImageTransparency = 1 - a

		sat.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

		local s_offset = (s < 1) and 0 or -3
		local v_offset = (1 - v < 1) and 0 or -3
		sat_black_cursor.Position = dim2(s, s_offset, 1 - v, v_offset)

		cfg.color = Color
		cfg.alpha = a

		flags[cfg.flag] = {
			Color = Color,
			Transparency = a,
		}
		cfg.saved_color = hsv(s, s, v)

		cfg.callback(Color, a)
	end

	__input.FocusLost:Connect(function()
		local text = __input.Text
		local r, g, b, a = library:convert_string_rgb(text)

		if r and g and b and a then
			cfg.set(rgb(r, g, b), a)
		end
	end)

	function cfg.update_color()
		local mouse = uis:GetMouseLocation()

		if dragging_sat then
			s = math.clamp(
				(vec2(mouse.X, mouse.Y - gui_offset) - sat_white.AbsolutePosition).X / sat_white.AbsoluteSize.X,
				0,
				1
			)
			v = 1
				- math.clamp(
					(vec2(mouse.X, mouse.Y - gui_offset) - sat_black.AbsolutePosition).Y / sat_black.AbsoluteSize.Y,
					0,
					1
				)
		elseif dragging_hue then
			h = 1
				- math.clamp(
					1
						- (vec2(mouse.X, mouse.Y - gui_offset) - hue_inline.AbsolutePosition).X
							/ hue_inline.AbsoluteSize.X,
					0,
					1
				)
		elseif dragging_alpha then
			a = math.clamp(
				(vec2(mouse.X, mouse.Y - gui_offset) - alpha_inline.AbsolutePosition).X / alpha_inline.AbsoluteSize.X,
				0,
				1
			)
		end

		cfg.set(nil, nil)
	end

	alpha_inline.MouseButton1Down:Connect(function()
		dragging_alpha = true
	end)

	hue_inline.MouseButton1Down:Connect(function()
		dragging_hue = true
	end)

	sat_inline.MouseButton1Down:Connect(function()
		dragging_sat = true
	end)

	cfg.saved_color = hsv(h, s, v)
	local selected = normal
	flags[cfg.flag]["animation"] = "normal"

	rainbow.MouseButton1Down:Connect(function()
		selected.BackgroundTransparency = 1
		selected = "rainbow"
		rainbow.BackgroundTransparency = 0

		flags[cfg.flag]["animation"] = "rainbow"
		cfg.saved_color = hsv(s, s, v)
	end)

	fade_alpha.MouseButton1Down:Connect(function()
		selected.BackgroundTransparency = 1
		selected = "fade_alpha"
		fade_alpha.BackgroundTransparency = 0

		flags[cfg.flag]["animation"] = "fade_alpha"
		cfg.saved_color = hsv(s, s, v)
	end)

	fade.MouseButton1Down:Connect(function()
		selected.BackgroundTransparency = 1
		selected = "fade"
		fade.BackgroundTransparency = 0

		flags[cfg.flag]["animation"] = "fade"
		cfg.saved_color = hsv(s, s, v)
	end)

	normal.MouseButton1Down:Connect(function()
		selected.BackgroundTransparency = 1
		selected = "normal"
		normal.BackgroundTransparency = 0

		flags[cfg.flag]["animation"] = "normal"
		cfg.set(cfg.saved_color)
	end)

	uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging_sat = false
			dragging_hue = false
			dragging_alpha = false
		end
	end)

	uis.InputChanged:Connect(function(input)
		if
			(dragging_sat or dragging_hue or dragging_alpha)
			and input.UserInputType == Enum.UserInputType.MouseMovement
		then
			cfg.update_color()
		end
	end)

	cfg.set(cfg.color, cfg.alpha)

	self.previous_holder = parent

	library.config_flags[cfg.flag] = cfg.set

	task.spawn(function()
		while true do
			if selected ~= "normal" then
				cfg.set(
					hsv(
						selected == "rainbow" and library.sin or h,
						selected == "rainbow" and 1 or s,
						selected == "fade" and library.sin or v
					),
					selected == "fade_alpha" and library.sin
				)
			end
			task.wait()
		end
	end)

	return setmetatable(cfg, library)
end

function library:keybind(properties)
	local cfg = {
		flag = properties.flag or tostring(2 ^ math.random(1, 30) * 3),
		keybind_name = properties.keybind_name or nil,
		callback = properties.callback or function() end,
		open = false,
		binding = nil,
		name = properties.name or nil,
		key = properties.default or properties.key or nil,
		mode = properties.mode or "toggle",
		active = properties.default or false,
		display = properties.displayName or properties.display or properties.name or nil,
		hold_instances = {},
	}

	flags[cfg.flag] = {}

	local key = library:new_keybind({
		text = cfg.display,
		key = cfg.key,
		mode = cfg.mode,
	})

	-- Instances
	local right_components
	if cfg.name then
		local object = library:create("TextLabel", {
			Parent = self.holder,
			Name = "",
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Text = cfg.name,
			TextStrokeTransparency = 0.5,
			Size = UDim2.new(1, -26, 0, 12),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		right_components = library:create("Frame", {
			Parent = object,
			Name = "",
			Position = UDim2.new(1, 15, 0, 1),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(0, 0, 1, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		})

		local list = library:create("UIListLayout", {
			Parent = right_components,
			Name = "",
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
	end

	local keybind = library:create("TextButton", {
		Parent = cfg.name and right_components or self.right_holder,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "ERROR",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(0, 16, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local content_inline = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(0, 57, 0, 0),
		Position = dim2(0, keybind.AbsolutePosition.X, 0, keybind.AbsolutePosition.Y - 5),
		BorderSizePixel = 0,
		ZIndex = 2,
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	keybind:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		content_inline.Position = UDim2.new(0, keybind.AbsolutePosition.X, 0, keybind.AbsolutePosition.Y + 15)
	end)

	local content = library:create("Frame", {
		Parent = content_inline,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	local options = library:create("Frame", {
		Parent = content,
		Name = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -4, 1, -4),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
	})

	local UIListLayout = library:create("UIListLayout", {
		Parent = options,
		Name = "",
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local press = library:create("TextButton", {
		Parent = options,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "press",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 2, 0, 2),
		BorderSizePixel = 0,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(65, 65, 65),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = press,
		Name = "",
		PaddingBottom = UDim.new(0, 1),
		PaddingLeft = UDim.new(0, 5),
	})

	local hold = library:create("TextButton", {
		Parent = options,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "hold",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 2, 0, 2),
		BorderSizePixel = 0,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(65, 65, 65),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = hold,
		Name = "",
		PaddingBottom = UDim.new(0, 1),
		PaddingLeft = UDim.new(0, 5),
	})

	local always = library:create("TextButton", {
		Parent = options,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "always",
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 2, 0, 2),
		BorderSizePixel = 0,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(65, 65, 65),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = always,
		Name = "",
		PaddingBottom = UDim.new(0, 1),
		PaddingLeft = UDim.new(0, 5),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = options,
		Name = "",
		PaddingBottom = UDim.new(0, 4),
	})
	--

	function cfg.set_visible(bool)
		content_inline.Visible = bool

		if bool then
			if library.current_element_open and library.current_element_open ~= cfg then
				library.current_element_open.set_visible(false)
				library.current_element_open.open = false
			end

			library.current_element_open = cfg
		end
	end

	function cfg.set_mode(mode)
		cfg.mode = mode

		if mode == "always" then
			cfg.set(true)
		elseif mode == "hold" then
			cfg.set(false)
		end

		flags[cfg.flag] = {
			mode = cfg.mode,
			key = cfg.key,
			active = cfg.active,
		}

		flags[cfg.flag]["mode"] = mode
	end

	function cfg.set(input)
		if type(input) == "boolean" then
			local __cached = input

			if cfg.mode == "always" then
				__cached = true
			end

			cfg.active = __cached
			flags[cfg.flag]["active"] = __cached
			cfg.callback(__cached)

			flags[cfg.flag] = {
				mode = cfg.mode,
				key = cfg.key,
				active = cfg.active,
			}
		elseif tostring(input):find("Enum") then
			input = input.Name == "Escape" and "..." or input

			cfg.key = input or "..."

			local _text = keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")
			local _text2 = (tostring(_text):gsub("KeyCode.", ""):gsub("UserInputType.", "")) or "..."
			cfg.key_name = _text2

			flags[cfg.flag]["mode"] = cfg.mode
			flags[cfg.flag]["key"] = cfg.key

			keybind.Text = "[" .. string.lower(_text2) .. "]"

			cfg.callback(cfg.active or false)

			flags[cfg.flag] = {
				mode = cfg.mode,
				key = cfg.key,
				active = cfg.active,
			}
		elseif table.find({ "toggle", "hold", "always" }, input) then
			cfg.set_mode(input)

			if input == "always" then
				cfg.active = true
			end

			cfg.callback(cfg.active or false)

			flags[cfg.flag] = {
				mode = cfg.mode,
				key = cfg.key,
				active = cfg.active,
			}
		elseif type(input) == "table" then
			input.key = type(input.key) == "string" and input.key ~= "..." and library:convert_enum(input.key)
				or input.key

			input.key = input.key == Enum.KeyCode.Escape and "..." or input.key
			cfg.key = input.key or "..."

			cfg.mode = input.mode or "toggle"

			if input.active then
				cfg.active = input.active
			end

			flags[cfg.flag] = {
				mode = cfg.mode,
				key = cfg.key,
				active = cfg.active,
			}

			local text = tostring(cfg.key) ~= "Enums" and (keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")) or nil
			local __text = text and (tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", ""))

			keybind.Text = "[" .. string.lower(__text) .. "]" or "..."
			cfg.key_name = __text
		end

		if cfg.keybind_name then
			key.change_text(keybind.Text .. " " .. cfg.keybind_name .. " (" .. flags[cfg.flag].mode .. ")")
			key.set_visible(cfg.active)
		end
	end

	local selected

	hold.MouseButton1Click:Connect(function()
		if selected then
			selected.BackgroundTransparency = 1
		end
		selected = hold
		hold.BackgroundTransparency = 0

		cfg.set_mode("hold")
		cfg.set_visible(false)
		cfg.open = false

		key.update({
			text = cfg.display,
			key = cfg.key,
			mode = cfg.mode,
		})
	end)

	press.MouseButton1Click:Connect(function()
		if selected then
			selected.BackgroundTransparency = 1
		end
		selected = press
		press.BackgroundTransparency = 0

		cfg.set_mode("toggle")
		cfg.set_visible(false)
		cfg.open = false

		key.update({
			text = cfg.display,
			key = cfg.key,
			mode = cfg.mode,
		})
	end)

	always.MouseButton1Click:Connect(function()
		if selected then
			selected.BackgroundTransparency = 1
		end
		selected = always

		always.BackgroundTransparency = 0
		cfg.set_mode("always")
		cfg.set_visible(false)
		cfg.open = false

		key.update({
			text = cfg.display,
			key = cfg.key,
			mode = cfg.mode,
		})
	end)

	keybind.MouseButton2Click:Connect(function()
		cfg.open = not cfg.open

		cfg.set_visible(cfg.open)
	end)

	keybind.MouseButton1Down:Connect(function()
		task.wait()
		keybind.Text = "..."

		cfg.binding = library:connection(uis.InputBegan, function(input, game_event)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				cfg.set(input.KeyCode)
			elseif
				input.UserInputType == Enum.UserInputType.MouseButton1
				or Enum.UserInputType.MouseButton2
				or Enum.UserInputType.MouseButton3
			then
				-- I put this giant elseif to avoid having "mousemovement" as a keybind

				cfg.set(input.UserInputType)
			end

			key.update({
				text = cfg.display,
				key = cfg.key,
				mode = cfg.mode,
			})
			cfg.binding:Disconnect()
			cfg.binding = nil
		end)
	end)

	library:connection(uis.InputBegan, function(input, game_event)
		if not game_event then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == cfg.key then
					if cfg.mode == "toggle" then
						toggled = not toggled
						cfg.set(toggled)
					elseif cfg.mode == "hold" then
						cfg.set(true)
					end
				end
			else
				if input.UserInputType == cfg.key then
					if cfg.mode == "toggle" then
						toggled = not toggled
						cfg.set(toggled)
					elseif cfg.mode == "hold" then
						cfg.set(true)
					end
				end
			end
		end
	end)

	library:connection(uis.InputEnded, function(input, game_event)
		if game_event then
			return
		end

		local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType

		if selected_key == cfg.key then
			if cfg.mode == "hold" then
				cfg.set(false)
			end
		end
	end)

	cfg.set({ mode = cfg.mode, active = cfg.active, key = cfg.key })
	key.update({
		text = cfg.display,
		key = cfg.key,
		mode = cfg.mode,
	})

	library.config_flags[cfg.flag] = cfg.set

	return setmetatable(cfg, library)
end

function library:button(properties)
	local cfg = {
		callback = properties.callback or function() end,
		name = properties.text or properties.name or "Button",
	}

	local button_inline = library:create("Frame", {
		Parent = self.holder,
		Name = "",
		Position = UDim2.new(0, -15, 0, 2),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local button = library:create("TextButton", {
		Parent = button_inline,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = cfg.name,
		TextStrokeTransparency = 0.5,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	button.MouseButton1Click:Connect(function()
		cfg.callback()
	end)

	return setmetatable(cfg, library)
end

function library:textbox(properties)
	local cfg = {
		placeholder = properties.placeholder
			or properties.placeholdertext
			or properties.holder
			or properties.holdertext
			or "type here...",
		default = properties.default,
		clear_on_focus = properties.clearonfocus or false,
		flag = properties.flag or "...",
		callback = properties.callback or function() end,
	}

	local textbox_inline = library:create("Frame", {
		Parent = self.holder,
		Name = "",
		Position = UDim2.new(0, -15, 0, 2),
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		Size = UDim2.new(1, -26, 0, 16),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	})

	local textbox = library:create("TextBox", {
		Parent = textbox_inline,
		Name = "",
		FontFace = library.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		Text = "",
		TextStrokeTransparency = 0.5,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		ClearTextOnFocus = cfg.clear_on_focus,
		PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
		CursorPosition = -1,
		PlaceholderText = cfg.placeholder,
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
	})

	textbox:GetPropertyChangedSignal("Text"):Connect(function()
		flags[cfg.flag] = textbox.text
		cfg.callback(textbox.text)
	end)

	function cfg.set(text)
		flags[cfg.flag] = text
		textbox.Text = text
		cfg.callback(text)
	end

	if cfg.default then
		cfg.set(cfg.default)
	end

	library.config_flags[cfg.flag] = cfg.set

	return setmetatable(cfg, library)
end

function library:panel(properties)
	if library.__panel == true then
		return
	end

	library.__panel = true

	local cfg = {
		name = properties.name or "Are you sure?",
		options = properties.options or { "Confirm", "Discard" },
		callback = properties.callback or function() end,
	}

	local panel_main_frame = library:create("Frame", {
		Parent = library.gui,
		Name = "",
		BackgroundTransparency = 0.4000000059604645,
		Size = UDim2.new(1, 0, 1, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 3,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})

	local holder = library:create("Frame", {
		Parent = panel_main_frame,
		Name = "",
		BorderColor3 = Color3.fromRGB(19, 19, 19),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		ZIndex = 4,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	})

	local inline1 = library:create("Frame", {
		Parent = holder,
		Name = "",
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(56, 56, 56),
	})

	local main = library:create("Frame", {
		Parent = inline1,
		Name = "",
		Position = UDim2.new(0, 4, 0, 4),
		BorderColor3 = Color3.fromRGB(26, 26, 26),
		Size = UDim2.new(1, -8, 1, -8),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
	})

	local UIStroke = library:create("UIStroke", {
		Parent = main,
		Name = "",
		Color = Color3.fromRGB(57, 57, 57),
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local tabs = library:create("Frame", {
		Parent = main,
		Name = "",
		Position = UDim2.new(0, 8, 0, 8),
		BorderColor3 = Color3.fromRGB(8, 8, 8),
		Size = UDim2.new(1, -16, 1, -16),
		BorderSizePixel = 2,
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
	})

	local UIStroke = library:create("UIStroke", {
		Parent = tabs,
		Name = "",
		Color = Color3.fromRGB(57, 57, 57),
		LineJoinMode = Enum.LineJoinMode.Miter,
	})

	local UIPadding = library:create("UIPadding", {
		Parent = tabs,
		Name = "",
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 22),
		PaddingRight = UDim.new(0, 20),
		PaddingLeft = UDim.new(0, 20),
	})

	local aimbot = library:create("TextLabel", {
		Parent = tabs,
		Name = "",
		FontFace = library.font,
		LineHeight = 1.2000000476837158,
		TextStrokeTransparency = 0.5,
		AnchorPoint = Vector2.new(0.5, 0),
		TextSize = 12,
		Size = UDim2.new(0, 0, 0, 11),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = cfg.name,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 8),
		BorderSizePixel = 0,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = aimbot,
		Name = "",
		PaddingTop = UDim.new(0, 6),
	})

	local UIListLayout = library:create("UIListLayout", {
		Parent = tabs,
		Name = "",
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 4),
	})

	local Frame = library:create("Frame", {
		Parent = tabs,
		Name = "",
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})

	local UIListLayout = library:create("UIListLayout", {
		Parent = Frame,
		Name = "",
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 3),
	})

	local UIPadding = library:create("UIPadding", {
		Parent = Frame,
		Name = "",
	})

	-- local textbox_inline = library:create("Frame", {
	--     Parent = Frame,
	--     Name = "",
	--     Position = UDim2.new(0, -15, 0, 2),
	--     BorderColor3 = Color3.fromRGB(19, 19, 19),
	--     Size = UDim2.new(0, 130, 0, 16),
	--     BorderSizePixel = 0,
	--     BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	-- })

	-- local textbox = library:create("TextBox", {
	--     Parent = textbox_inline,
	--     Name = "",
	--     FontFace = library.font,
	--     TextColor3 = Color3.fromRGB(170, 170, 170),
	--     BorderColor3 = Color3.fromRGB(56, 56, 56),
	--     Text = "",
	--     TextStrokeTransparency = 0.5,
	--     Size = UDim2.new(1, -4, 1, -4),
	--     PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
	--     Position = UDim2.new(0, 2, 0, 2),
	--     PlaceholderText = "name",
	--     TextSize = 12,
	--     BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	-- })

	for _, v in next, cfg.options do
		local button_inline = library:create("Frame", {
			Parent = Frame,
			Name = "",
			Position = UDim2.new(0, 0, 0, 4),
			BorderColor3 = Color3.fromRGB(19, 19, 19),
			Size = UDim2.new(0, 130, 0, 16),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(8, 8, 8),
		})

		local button = library:create("TextButton", {
			Parent = button_inline,
			Name = "",
			FontFace = library.font,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			BorderColor3 = Color3.fromRGB(56, 56, 56),
			Text = v,
			TextStrokeTransparency = 0.5,
			Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(1, -4, 1, -4),
			TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		})

		button.MouseButton1Click:Connect(function()
			cfg.callback(v)
			panel_main_frame:Destroy()
			library.__panel = false
		end)
	end
end
--
--

-- haze.best: 3D emblem + ESP preview
function library:create_emblem(Window, Options)
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
        if library.gui then
            library.gui.DisplayOrder = math.max(library.gui.DisplayOrder or 0, 50)
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
        if EmblemUseAccent and themes.preset.accent then
            return themes.preset.accent
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

    library.Emblem = Emblem
    return Emblem
end

-- ============================================================================
-- ESP preview (3D frame outside the menu ΓÇö styled like a standalone ESP PREVIEW panel)
-- Includes character bundle models + catalog dance/emote playback.
-- ============================================================================

function library:create_esp_preview(Window, Options)
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
        local Holder = library.gui
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
        local Holder = library.gui
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
        local Main = Window._main_frame or (library.main_frame and library.main_frame[1])
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
    PanelStroke.Thickness = 0.5
    PanelStroke.Color = themes.preset.outline or Color3.fromRGB(57, 57, 57)
    PanelStroke.Parent = Panel

    local Accent = Instance.new("Frame")
    Accent.Name = "Accent"
    Accent.Size = UDim2.new(1, 0, 0, 1)
    Accent.BorderSizePixel = 0
    Accent.BackgroundColor3 = themes.preset.accent
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
        -- GetAppliedDescription() (all 0s) ΓåÆ grey dummy, and nest a custom
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
        -- catalog emote id ΓåÆ real AnimationId (GetObjects)
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
    HealthGradient.Rotation = 90 -- top ΓåÆ bottom
    -- classic ESP degradado (green ΓåÆ yellow ΓåÆ red)
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

    -- healthbar only: bottom ΓåÆ top fill loop + fixed gradient reveal
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
        -- fill bottomΓåÆtop, hold, drain, repeat
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
        Accent.BackgroundColor3 = themes.preset.accent or Color3.fromRGB(125, 211, 252)
        PanelStroke.Color = themes.preset.outline or Color3.fromRGB(57, 57, 57)
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
            local Holder = library.gui
            if Holder then
                local Panel2 = Holder:FindFirstChild("EspPreviewPanel", true)
                if Panel2 then
                    Panel2:Destroy()
                end
            end
        end)
    end

    library.EspPreview = EspPreview
    return EspPreview
end

-- ============================================================================
-- Settings/ESP UI builders (same pattern as Library:AddThemeUI)
-- ============================================================================


return library
