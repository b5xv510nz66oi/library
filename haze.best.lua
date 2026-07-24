--[[
    haze.best — Tauri menu port (from-scratch UI, no Thugsense)
]]

local UI_URLS = {
    "https://raw.githubusercontent.com/b5xv510nz66oi/library/16f3afa/haze.ui.lua",
    "https://cdn.jsdelivr.net/gh/b5xv510nz66oi/library@16f3afa/haze.ui.lua",
    "https://raw.githubusercontent.com/b5xv510nz66oi/library/main/haze.ui.lua",
}

local function LoadUI()
    local Load = loadstring or load
    assert(type(Load) == "function", "[haze.best] loadstring missing")

    local function ok(src)
        return type(src) == "string" and #src > 200 and src:find("haze.ui", 1, true) and src:find("Library:Window", 1, true)
    end

    -- prefer fresh remote
    for _, url in ipairs(UI_URLS) do
        local yes, body = pcall(function()
            return game:HttpGet(url)
        end)
        if yes and ok(body) then
            if writefile then
                pcall(makefolder, "haze.best")
                pcall(writefile, "haze.best/haze.ui.lua", body)
            end
            local fn, err = Load(body)
            assert(fn, "[haze.best] ui compile failed: " .. tostring(err))
            return fn()
        end
    end

    -- local cache
    for _, path in ipairs({ "haze.best/haze.ui.lua", "haze.ui.lua" }) do
        if isfile and isfile(path) then
            local yes, body = pcall(readfile, path)
            if yes and ok(body) then
                local fn, err = Load(body)
                assert(fn, "[haze.best] ui compile failed: " .. tostring(err))
                return fn()
            end
        end
    end

    error("[haze.best] failed to load haze.ui.lua — upload it to GitHub")
end

if getgenv().HazeUI then
    pcall(function()
        getgenv().HazeUI:Unload()
    end)
end

local t0 = os.clock()
local UI = LoadUI()

local Watermark = UI:Watermark({ "haze.best", "Server", "144FPS", "64PING", os.date("%I:%M %p") })
task.spawn(function()
    while not UI.Unloaded do
        Watermark:SetItems({ "haze.best", "Server", "144FPS", "64PING", os.date("%I:%M %p") })
        task.wait(1)
    end
end)

local Window = UI:Window({ Width = 840, Height = 630 })

--------------------------------------------------------------------
-- Aim
--------------------------------------------------------------------
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

--------------------------------------------------------------------
-- Move / Misc (empty like Tauri)
--------------------------------------------------------------------
Window:Page({ Name = "Move", Columns = 2 })
Window:Page({ Name = "Misc", Columns = 2 })

--------------------------------------------------------------------
-- Visuals
--------------------------------------------------------------------
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

--------------------------------------------------------------------
-- Configs
--------------------------------------------------------------------
local Configs = Window:Page({ Name = "Configs", Columns = 2 })
do
    local P = Configs:Panel(1)
    local NameBox = { Value = "" }
    P:Dropdown({
        Name = "Profile",
        Flag = "cfg_list",
        Items = { "default" },
        Default = "default",
    })
    P:Button({
        Name = "Create config",
        Callback = function()
            UI:Notify("Config system ready", 2)
        end,
    })
    P:Button({
        Name = "Load config",
        Callback = function()
            UI:Notify("Loaded", 2)
        end,
    })
    P:Button({
        Name = "Save config",
        Callback = function()
            UI:Notify("Saved", 2)
        end,
    })
end

--------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------
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
    P:Button({
        Name = "Notification test",
        Callback = function()
            UI:Notify("This is a notification", 4)
        end,
    })
    P:Sep()
    P:Button({
        Name = "Unload",
        Callback = function()
            UI:Unload()
        end,
    })
end

UI:Notify(string.format("haze.best loaded · %.2fs", os.clock() - t0), 3)
