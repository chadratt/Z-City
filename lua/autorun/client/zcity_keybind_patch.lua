if SERVER then return end

local PATCH_NAME = "ZCity_Keybind_ANARCHY"

local SAVE_FILE = "zcity_keybinds.txt"

local TEXTS = {
    help_title = "Keybind Help",
    help_header = [[
Custom bind means the key you assigned in the console using the "bind" command.
You can unbind a key using the "unbind" command.
Type "key_listboundkeys" in the console to see all your binds from the "bind" command (and Gmod settings).

General key hints:
Key [Alt] + Key [E]: Snap neck from behind
Key [Alt] + Key [R]: Disguise as corpse clothing
Key [E] + Key [LMB]: Melee with weapon butt
Key [RMB] + Key [E]: Loot items
In ragdoll + Key [E]: Control head
In ragdoll + Key [Shift]: Left hand grab
In ragdoll + Key [Alt]: Right hand grab
]],
    links_header = "Related Links",
    tab_title = "Keybinds",
    gameplay_header = "Gameplay",
    btn_help = "Help",
    btn_clear = "Clear",
    native_bind = "Native bind",
    msg_reload = "Configuration reloaded",
    msg_reset = "Default keys restored",
    tab_added = "Tab added",
    loaded = "Loaded",
    bind_kick = "Kick",
    bind_fake = "Ragdoll",
    bind_laser = "Toggle weapon laser",
    bind_leanleft = "Lean left",
    bind_leanright = "Lean right",
    bind_breath = "Hold breath",
    bind_look = "Look around",
    bind_zoom = "Zoom camera",
    bind_weaponwheel = "Weapon wheel"
}

local function GetText(key, ...)
    local text = TEXTS[key]
    if not text then return "[" .. key .. "]" end

    if select("#", ...) > 0 then
        return string.format(text, ...)
    end
    return text
end

local Binds = {
    {
        command = "hg_kick",
        key = KEY_NONE,
        hold = false
    },
    {
        command = "fake",
        key = KEY_NONE,
        hold = false
    },
    {
        command = "hmcd_togglelaser",
        key = KEY_NONE,
        hold = false
    },
    {
        command = "+alt1",
        key = KEY_NONE,
        hold = true
    },
    {
        command = "+alt2",
        key = KEY_NONE,
        hold = true
    },
    {
        command = "+hmcd_holdbreath",
        key = KEY_NONE,
        hold = true
    },
    {
        command = "+altlook",
        key = KEY_NONE,
        hold = true
    },
    {
        command = "+hg_zoom",
        key = KEY_NONE,
        hold = true
    },
    {
        command = "+hg_weaponwheel",
        key = KEY_TAB,
        hold = true
    }
}

local function GetBindTitle(command)
    local titles = {
        hg_kick = "bind_kick",
        fake = "bind_fake",
        hmcd_togglelaser = "bind_laser",
        ["+alt1"] = "bind_leanleft",
        ["+alt2"] = "bind_leanright",
        ["+hmcd_holdbreath"] = "bind_breath",
        ["+altlook"] = "bind_look",
        ["+hg_zoom"] = "bind_zoom",
        ["+hg_weaponwheel"] = "bind_weaponwheel"
    }
    return GetText(titles[command] or command)
end

local function SaveKeyBinds()
    local data = {}
    for _, bind in ipairs(Binds) do
        data[bind.command] = bind.key
    end
    file.Write(SAVE_FILE, util.TableToJSON(data, true))
end

local function LoadKeyBinds()
    if not file.Exists(SAVE_FILE, "DATA") then
        SaveKeyBinds()
        return
    end
    local content = file.Read(SAVE_FILE, "DATA")
    if not content then return end
    local data = util.JSONToTable(content)
    if not data then return end
    for _, bind in ipairs(Binds) do
        local savedKey = data[bind.command]
        if savedKey then
            bind.key = tonumber(savedKey) or bind.key
        end
    end
end

local function SyncWeaponWheelKey()
    for _, bind in ipairs(Binds) do
        if bind.command == "+hg_weaponwheel" then
            hg = hg or {}
            hg.WeaponWheel = hg.WeaponWheel or {}
            hg.WeaponWheel.Key = bind.key
            return
        end
    end
end

LoadKeyBinds()
SyncWeaponWheelKey()

local function GetNativeBind(command)
    local native = input.LookupBinding(command)
    if not native then return nil end
    return string.upper(native)
end

local ZoomDown = false

hook.Add("PlayerButtonDown", PATCH_NAME .. "_Down", function(ply, button)
    if ply ~= LocalPlayer() then return end
    if gui.IsGameUIVisible() then return end
    local focus = vgui.GetKeyboardFocus()
    if IsValid(focus) then return end

    for _, bind in ipairs(Binds) do
        if bind.command == "+hg_weaponwheel" then continue end
        if bind.key == KEY_NONE then continue end
        if button ~= bind.key then continue end

        if bind.hold then
            if not ZoomDown then
                ZoomDown = true
                RunConsoleCommand(bind.command)
            end
        else
            RunConsoleCommand(bind.command)
        end
        return
    end
end)

hook.Add("PlayerButtonUp", PATCH_NAME .. "_Up", function(ply, button)
    if ply ~= LocalPlayer() then return end

    for _, bind in ipairs(Binds) do
        if bind.command == "+hg_weaponwheel" then continue end
        if not bind.hold then continue end
        if bind.key == KEY_NONE then continue end
        if button ~= bind.key then continue end

        if ZoomDown then
            ZoomDown = false
            local cmd = bind.command
            if string.StartWith(cmd, "+") then
                RunConsoleCommand("-" .. string.sub(cmd, 2))
            end
        end
    end
end)

local HELP_LINKS = {
    {
        name = "Addon Link ENG/RU",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3737887777"
    },
    {
        name = "Original Link CN",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3736711821"
    },
    {
        name = "Author",
        url = "https://steamcommunity.com/profiles/76561198211540476/"
    },
    {
        name = "Other Author",
        url = "https://steamcommunity.com/id/illnk1/"
    }
}

local function OpenHelpWindow()
    if IsValid(ZCityKeybindHelpFrame) then
        ZCityKeybindHelpFrame:Remove()
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(700, 500)
    frame:Center()
    frame:SetTitle(GetText("help_title"))
    frame:MakePopup()
    ZCityKeybindHelpFrame = frame

    local left = vgui.Create("DPanel", frame)
    left:Dock(FILL)
    left:DockMargin(5, 5, 5, 5)
    left.Paint = function(self, w, h)
        surface.SetDrawColor(35, 35, 35, 255)
        surface.DrawRect(0, 0, w, h)
    end

    local text = vgui.Create("RichText", left)
    text:Dock(TOP)
    text:SetTall(250)
    function text:PerformLayout()
        self:SetFontInternal("DermaDefault")
        self:SetFGColor(Color(255, 255, 255))
    end
    function text:Paint(w, h)
        surface.SetDrawColor(25, 25, 25, 255)
        surface.DrawRect(0, 0, w, h)
        self:DrawTextEntryText(color_white, color_white, color_white)
    end
    text:SetVerticalScrollbarEnabled(true)
    text:InsertColorChange(255, 255, 255, 255)
    text:AppendText(GetText("help_header"))

    local header = vgui.Create("DLabel", left)
    header:Dock(TOP)
    header:DockMargin(5, 10, 5, 10)
    header:SetText(GetText("links_header"))
    header:SetFont("DermaLarge")
    header:SizeToContents()

    for _, linkData in ipairs(HELP_LINKS) do
        local btn = vgui.Create("DButton", left)
        btn:Dock(TOP)
        btn:DockMargin(5, 0, 5, 5)
        btn:SetTall(30)
        btn:SetText(linkData.name)

        btn.DoClick = function()
            gui.OpenURL(linkData.url)
        end
    end
end

local function CreateBindRow(parent, bind)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:DockMargin(10, 5, 10, 0)
    row:SetTall(72)

    row.Paint = function(self, w, h)
        surface.SetDrawColor(40, 40, 40, 220)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText(GetBindTitle(bind.command), "DermaDefaultBold", 10, 10, color_white)
        draw.SimpleText(bind.command, "DermaDefault", 10, 28, Color(180, 180, 180))

        local nativeBind = GetNativeBind(bind.command)
        if nativeBind then
            draw.SimpleText(GetText("native_bind") .. ": " .. nativeBind, "DermaDefault", 10, 46, Color(180, 180, 180))
        end
    end

    local binder = vgui.Create("DBinder", row)
    local oldPaint = binder.Paint
    binder.Paint = function(self, w, h)
        if oldPaint then oldPaint(self, w, h) end
        surface.SetDrawColor(180, 0, 0, 255)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    binder:Dock(RIGHT)
    binder:DockMargin(0, 8, 10, 8)
    binder:SetWide(150)
    binder:SetValue(bind.key)

    function binder:OnChange(key)
        if not key then return end
        bind.key = key
        SaveKeyBinds()
        SyncWeaponWheelKey()
    end

    local clear = vgui.Create("DButton", row)
    clear:Dock(RIGHT)
    clear:DockMargin(0, 8, 5, 8)
    clear:SetWide(60)
    clear:SetText(GetText("btn_clear"))

    local clearOldPaint = clear.Paint
    clear.Paint = function(self, w, h)
        if clearOldPaint then clearOldPaint(self, w, h) end
        surface.SetDrawColor(180, 0, 0, 255)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    clear.DoClick = function()
        bind.key = KEY_NONE
        SaveKeyBinds()
        SyncWeaponWheelKey()
        binder:SetValue(KEY_NONE)
    end
end

local function DrawKeyBindings(parent)
    parent:Clear()

    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)
    local canvas = scroll:GetCanvas()

    local header = vgui.Create("DPanel", canvas)
    header:Dock(TOP)
    header:DockMargin(10, 10, 10, 10)
    header:SetTall(40)
    header.Paint = function(self, w, h)
        surface.SetDrawColor(60, 60, 60, 220)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText(GetText("gameplay_header"), "DermaDefaultBold", 15, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local helpBtn = vgui.Create("DButton", header)
    helpBtn:Dock(RIGHT)
    helpBtn:DockMargin(0, 5, 5, 5)
    helpBtn:SetWide(80)
    helpBtn:SetText(GetText("btn_help"))
    helpBtn.DoClick = function()
        OpenHelpWindow()
    end

    for _, bind in ipairs(Binds) do
        CreateBindRow(canvas, bind)
    end
end

local function AddKeybindTab(menu)
    if not IsValid(menu) then return end
    if menu.ZCityKeybindAdded then return end

    menu.ZCityKeybindAdded = true

    menu:AddSelect(menu.lDock, GetText("tab_title"), {
        Func = function(luaMenu, page)
            menu.ZCityKeybindPage = page
            DrawKeyBindings(page)
        end
    })

    print("[ZCity Keybind Patch] " .. GetText("tab_added"))
end

hook.Add("Think", PATCH_NAME .. "_MenuWatcher", function()
    local menu = MainMenu
    if not IsValid(menu) then return end
    AddKeybindTab(menu)
end)

hook.Add("ShutDown", PATCH_NAME .. "_Shutdown", function()
    SaveKeyBinds()
end)

concommand.Add("zcity_keybind_reload", function()
    LoadKeyBinds()
    SyncWeaponWheelKey()
    chat.AddText(Color(0, 255, 0), GetText("msg_reload"))
end)

concommand.Add("zcity_keybind_reset", function()
    local defaults = {
        hg_kick = KEY_G,
        fake = KEY_F,
        ["+hg_zoom"] = KEY_LALT,
        ["+hg_weaponwheel"] = KEY_TAB
    }
    for _, bind in ipairs(Binds) do
        local key = defaults[bind.command]
        if key then bind.key = key end
    end
    SaveKeyBinds()
    SyncWeaponWheelKey()
    chat.AddText(Color(255, 200, 0), GetText("msg_reset"))
end)

concommand.Add("zcity_keybind_dump", function()
    print("========== ZCity Keybinds ==========")
    for _, bind in ipairs(Binds) do
        print(GetBindTitle(bind.command), bind.command, bind.key)
    end
    print("=====================================")
end)

print("[ZCity Keybind Patch] V012 " .. GetText("loaded"))
