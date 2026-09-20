if not CLIENT then return end
zb = zb or {}
zb.AO = zb.AO or {}
zb.AO.LastSnapshot = zb.AO.LastSnapshot or {}
surface.CreateFont("ZB_AO_MapSmall", {
    font = "Bahnschrift",
    size = 13,
    weight = 400,
    antialias = true,
})
local function ReadSnapshot()
    local n = net.ReadUInt(8)
    local list = {}
    for i = 1, n do
        local data = {}
        data.ent = net.ReadEntity()
        data.steamid = net.ReadString()
        data.nick = net.ReadString()
        data.charname = net.ReadString()
        data.class = net.ReadString()
        data.alive = net.ReadBool()
        data.pos = net.ReadVector()
        data.hasKiller = net.ReadBool()
        if data.hasKiller then
            data.killerName = net.ReadString()
            data.killerSteamID = net.ReadString()
        end
        list[#list + 1] = data
    end
    return list
end
net.Receive("ZB_AO_Snapshot", function()
    zb.AO.LastSnapshot = ReadSnapshot()
    if zb.AO.OnSnapshotUpdated then zb.AO.OnSnapshotUpdated() end
end)
function zb.AO.Subscribe(state)
    net.Start("ZB_AO_Subscribe")
        net.WriteBool(state)
    net.SendToServer()
end
local COL_DOT_ALIVE = Color(90, 210, 120, 255)
local COL_DOT_DEAD = Color(230, 60, 60, 255)
local COL_PIN_RING = Color(255, 210, 70, 255)
local COL_PANEL_BG = Color(16, 16, 16, 255)
local COL_TOOLTIP_BG = Color(15, 15, 15, 235)
local DOT_HALF = 8
local HOVER_RADIUS = 20
local function Dist2D(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end
local function BuildTooltipLines(data)
    local lines = {
        data.nick,
        "SteamID: " .. data.steamid,
        "Character: " .. data.charname,
        "Class: " .. data.class,
    }
    if not data.alive then
        lines[#lines + 1] = "Killed by: " .. (data.killerName or "Unknown")
        lines[#lines + 1] = "Killer SteamID: " .. (data.killerSteamID or "N/A")
    end
    return lines
end
local function DrawTooltip(lines, sx, sy, w, h)
    surface.SetFont("ZB_AO_MapSmall")
    local tw, th = 0, 0
    for _, l in ipairs(lines) do
        local lw, lh = surface.GetTextSize(l)
        tw = math.max(tw, lw)
        th = th + lh + 2
    end
    local bx, by = sx + 14, sy - th / 2
    bx = math.Clamp(bx, 4, w - tw - 16)
    by = math.Clamp(by, 4, h - th - 12)
    draw.RoundedBox(4, bx - 6, by - 6, tw + 12, th + 12, COL_TOOLTIP_BG)
    local yy = by
    for i, l in ipairs(lines) do
        local col = (i == 1) and color_white or Color(200, 200, 200, 255)
        draw.SimpleText(l, "ZB_AO_MapSmall", bx, yy, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local _, lh = surface.GetTextSize(l)
        yy = yy + lh + 2
    end
end
function zb.AO.BuildMapTab(parent)
    local mapView = vgui.Create("DPanel", parent)
    mapView:Dock(FILL)
    mapView:DockMargin(8, 8, 8, 8)
    mapView.camPos = Vector(0, 0, 0)
    mapView.camHeight = 3000
    mapView.centered = false
    mapView.dragging = false
    mapView.dragDistance = 0
    mapView.hovered = nil
    mapView.pinned = {}
    mapView.Think = function(self)
        if not self.centered and IsValid(LocalPlayer()) and LocalPlayer():GetPos() then
            local p = LocalPlayer():GetPos()
            self.camPos = Vector(p.x, p.y, 0)
            self.centered = true
        end
    end
    mapView.OnMousePressed = function(self, code)
        if code == MOUSE_LEFT then
            self.dragging = true
            self.dragDistance = 0
            self.dragLastX, self.dragLastY = self:CursorPos()
            self.pressHover = self.hovered
            self:MouseCapture(true)
        end
    end
    mapView.OnMouseReleased = function(self, code)
        if code == MOUSE_LEFT then
            if self.dragging and self.dragDistance < 6 and self.pressHover then
                local steamid = self.pressHover.steamid
                if self.pinned[steamid] then
                    self.pinned[steamid] = nil
                else
                    self.pinned[steamid] = true
                end
            end
            self.dragging = false
            self:MouseCapture(false)
        end
    end
    mapView.OnCursorMoved = function(self, x, y)
        if self.dragging then
            local dx, dy = x - (self.dragLastX or x), y - (self.dragLastY or y)
            self.dragDistance = self.dragDistance + math.abs(dx) + math.abs(dy)
            local scale = self.camHeight * 0.0028
            self.camPos = self.camPos + Vector(-dy * scale, -dx * scale, 0)
            self.dragLastX, self.dragLastY = x, y
        end
    end
    mapView.OnMouseWheeled = function(self, delta)
        self.camHeight = math.Clamp(self.camHeight - delta * (self.camHeight * 0.12), 200, 30000)
    end
    mapView.Paint = function(self, w, h)
        surface.SetDrawColor(COL_PANEL_BG)
        surface.DrawRect(0, 0, w, h)
        local px, py = self:LocalToScreen(0, 0)
        local origin = self.camPos + Vector(0, 0, self.camHeight)
        local ang = Angle(90, 0, 0)
        local fov = 75
        local zFar = self.camHeight + 6000
        render.RenderView({
            origin = origin,
            angles = ang,
            x = px,
            y = py,
            w = w,
            h = h,
            fov = fov,
            znear = 4,
            zfar = zFar,
            drawviewmodel = false,
            drawhud = false,
        })
        local screens = {}
        cam.Start3D(origin, ang, fov, px, py, w, h, 4, zFar)
            for _, data in ipairs(zb.AO.LastSnapshot) do
                if IsValid(data.ent) then
                    local s = data.pos:ToScreen()
                    screens[data] = {
                        x = s.x - px,
                        y = s.y - py,
                        visible = (s.visible ~= false),
                    }
                end
            end
        cam.End3D()
        local mx, my = self:CursorPos()
        self.hovered = nil
        self.hoveredScreen = nil
        local toDraw = {}
        for data, s in pairs(screens) do
            if s.visible and s.x > -20 and s.x < w + 20 and s.y > -20 and s.y < h + 20 then
                if Dist2D(mx, my, s.x, s.y) <= HOVER_RADIUS then
                    self.hovered = data
                    self.hoveredScreen = s
                end
                local isPinned = self.pinned[data.steamid]
                if isPinned then
                    surface.SetDrawColor(COL_PIN_RING)
                    surface.DrawOutlinedRect(s.x - DOT_HALF - 3, s.y - DOT_HALF - 3, DOT_HALF * 2 + 6, DOT_HALF * 2 + 6, 2)
                end
                if data.alive then
                    surface.SetDrawColor(COL_DOT_ALIVE)
                    surface.DrawRect(s.x - DOT_HALF, s.y - DOT_HALF, DOT_HALF * 2, DOT_HALF * 2)
                    surface.SetDrawColor(0, 0, 0, 200)
                    surface.DrawOutlinedRect(s.x - DOT_HALF, s.y - DOT_HALF, DOT_HALF * 2, DOT_HALF * 2, 2)
                else
                    surface.SetDrawColor(COL_DOT_DEAD)
                    local r = DOT_HALF
                    surface.DrawLine(s.x - r, s.y - r, s.x + r, s.y + r)
                    surface.DrawLine(s.x - r, s.y + r, s.x + r, s.y - r)
                    surface.DrawLine(s.x - r - 1, s.y - r, s.x + r - 1, s.y + r)
                    surface.DrawLine(s.x - r - 1, s.y + r, s.x + r - 1, s.y - r)
                end
                if isPinned or data == self.hovered then
                    toDraw[#toDraw + 1] = { data = data, s = s }
                end
            end
        end
        for _, entry in ipairs(toDraw) do
            DrawTooltip(BuildTooltipLines(entry.data), entry.s.x, entry.s.y, w, h)
        end
        draw.SimpleText("Drag to pan  ·  Scroll to zoom  ·  Click a player to pin their info", "ZB_AO_MapSmall", 6, h - 18, Color(255, 255, 255, 120))
    end
    return mapView
end
