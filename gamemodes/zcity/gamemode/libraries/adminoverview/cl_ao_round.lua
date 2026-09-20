if not CLIENT then return end
zb = zb or {}
zb.AO = zb.AO or {}
local COL_ROW = Color(43, 43, 43, 235)
local COL_ROW_HOV = Color(56, 56, 56, 240)
local COL_ROW_OPEN = Color(120, 70, 40, 245)
local COL_EXPAND = Color(20, 20, 20, 240)
local COL_TEXT = Color(235, 235, 235, 235)
local COL_TEXT_DIM = Color(150, 150, 150, 220)
local COL_ACCENT = Color(160, 45, 45, 255)
local COL_ACCENT_H = Color(190, 60, 60, 255)
local COL_GREEN = Color(80, 125, 65, 255)
local COL_GREEN_H = Color(100, 150, 85, 255)
local COL_NEUTRAL = Color(70, 70, 70, 255)
local COL_NEUTRAL_H = Color(85, 85, 85, 255)
local function StyledButton(parent, text, base, hover)
    local btn = vgui.Create("DButton", parent)
    btn:SetText(text)
    btn:SetTextColor(COL_TEXT)
    btn.Paint = function(self, w, h)
        surface.SetDrawColor(self:IsHovered() and hover or base)
        surface.DrawRect(0, 0, w, h)
    end
    return btn
end
function zb.AO.OpenBanDialog(targets)
    if not targets or #targets == 0 then return end
    local frame = vgui.Create("ZFrame")
    frame:SetSize(340, 230)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame:ShowCloseButton(false)
    local lbl = vgui.Create("DLabel", frame)
    lbl:SetText("Ban " .. #targets .. " player(s)")
    lbl:SetTextColor(COL_TEXT)
    lbl:SetFont("ZB_QM_Category")
    lbl:Dock(TOP)
    lbl:DockMargin(12, 12, 12, 8)
    lbl:SetContentAlignment(5)
    local minutesEntry = vgui.Create("DTextEntry", frame)
    minutesEntry:Dock(TOP)
    minutesEntry:DockMargin(14, 4, 14, 6)
    minutesEntry:SetTall(28)
    minutesEntry:SetPlaceholderText("Minutes (0 or blank = permanent)")
    minutesEntry:SetNumeric(true)
    local reasonEntry = vgui.Create("DTextEntry", frame)
    reasonEntry:Dock(TOP)
    reasonEntry:DockMargin(14, 4, 14, 10)
    reasonEntry:SetTall(28)
    reasonEntry:SetPlaceholderText("Reason")
    local confirmBtn = StyledButton(frame, "Confirm Ban", COL_ACCENT, COL_ACCENT_H)
    confirmBtn:Dock(BOTTOM)
    confirmBtn:DockMargin(14, 6, 14, 14)
    confirmBtn:SetTall(34)
    confirmBtn.DoClick = function()
        local minutes = minutesEntry:GetValue()
        if minutes == "" then minutes = "0" end
        local reason = reasonEntry:GetValue()
        if reason == "" then reason = "No reason given" end
        net.Start("ZB_AO_KickBan")
            net.WriteString("ban")
            net.WriteString(minutes)
            net.WriteString(reason)
            net.WriteUInt(#targets, 8)
            for _, ent in ipairs(targets) do net.WriteEntity(ent) end
        net.SendToServer()
        frame:Close()
    end
    return frame
end
function zb.AO.DoKick(targets)
    if not targets or #targets == 0 then return end
    Derma_StringRequest(
        "Kick " .. #targets .. " player(s)",
        "Reason",
        "",
        function(reason)
            if reason == "" then reason = "No reason given" end
            net.Start("ZB_AO_KickBan")
                net.WriteString("kick")
                net.WriteString("0")
                net.WriteString(reason)
                net.WriteUInt(#targets, 8)
                for _, ent in ipairs(targets) do net.WriteEntity(ent) end
            net.SendToServer()
        end
    )
end
function zb.AO.BuildRoundTab(parent)
    local panel = vgui.Create("DPanel", parent)
    panel:Dock(FILL)
    panel.Paint = nil
    local header = vgui.Create("DPanel", panel)
    header:Dock(TOP)
    header:SetTall(34)
    header.Paint = function(self, w, h)
        surface.SetDrawColor(40, 40, 40, 255)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText(
            "Current round: " .. tostring(zb.CROUND or "?"),
            "ZB_QM_Small", 10, h / 2, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
        )
    end
    local scroll = vgui.Create("DScrollPanel", panel)
    scroll:Dock(FILL)
    scroll:DockMargin(0, 4, 0, 0)
    local rowsBySteam = {}
    local expandedRow = nil
    local function BuildRow(data)
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(6, 0, 6, 4)
        row:SetTall(40)
        row.data = data
        row.expanded = false
        row.Paint = function(self, w, h)
            local col = self.expanded and COL_ROW_OPEN or (self:IsHovered() and COL_ROW_HOV or COL_ROW)
            surface.SetDrawColor(col)
            surface.DrawRect(0, 0, w, h)
            local statusCol = self.data.alive and COL_GREEN or COL_ACCENT
            surface.SetDrawColor(statusCol)
            surface.DrawRect(0, 0, 4, 40)
            draw.SimpleText(self.data.nick, "ZB_QM_Item", 14, 9, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(
                self.data.charname .. "  ·  " .. self.data.class .. (self.data.alive and "" or "  ·  DEAD"),
                "ZB_QM_Small", 14, 25, COL_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
            )
        end
        local expandPanel = vgui.Create("DPanel", row)
        expandPanel:Dock(BOTTOM)
        expandPanel:SetTall(0)
        expandPanel.Paint = function(self, w, h)
            surface.SetDrawColor(COL_EXPAND)
            surface.DrawRect(0, 0, w, h)
        end
        local idLbl = vgui.Create("DLabel", expandPanel)
        idLbl:Dock(TOP)
        idLbl:DockMargin(10, 6, 8, 2)
        idLbl:SetTextColor(COL_TEXT_DIM)
        idLbl.PerformLayout = function(self)
            self:SetText("SteamID: " .. row.data.steamid)
            self:SizeToContentsY()
        end
        local btnRow = vgui.Create("DPanel", expandPanel)
        btnRow:Dock(TOP)
        btnRow:SetTall(30)
        btnRow:DockMargin(8, 2, 8, 8)
        btnRow.Paint = nil
        local kBtn = StyledButton(btnRow, "Kick", COL_NEUTRAL, COL_NEUTRAL_H)
        kBtn:Dock(LEFT)
        kBtn:SetWide(70)
        kBtn.DoClick = function() zb.AO.DoKick({ row.data.ent }) end
        local bBtn = StyledButton(btnRow, "Ban", COL_ACCENT, COL_ACCENT_H)
        bBtn:Dock(LEFT)
        bBtn:DockMargin(4, 0, 0, 0)
        bBtn:SetWide(70)
        bBtn.DoClick = function() zb.AO.OpenBanDialog({ row.data.ent }) end
        local nBtn = StyledButton(btnRow, "Notify", COL_GREEN, COL_GREEN_H)
        nBtn:Dock(LEFT)
        nBtn:DockMargin(4, 0, 0, 0)
        nBtn:SetWide(70)
        nBtn.DoClick = function() zb.AO.OpenNotifyWindow({ row.data.ent }) end
        row.expandPanel = expandPanel
        function row:SetExpanded(state)
            self.expanded = state
            self.expandPanel:SetTall(state and 76 or 0)
            self:SetTall(40 + (state and 76 or 0))
        end
        row.OnMousePressed = function(self, code)
            if code ~= MOUSE_LEFT then return end
            if not IsValid(self.data.ent) then return end
            if self.expanded then
                self:SetExpanded(false)
                expandedRow = nil
            else
                if expandedRow and IsValid(expandedRow) then
                    expandedRow:SetExpanded(false)
                end
                self:SetExpanded(true)
                expandedRow = self
            end
        end
        return row
    end
    local function RebuildList()
        scroll:Clear(true)
        rowsBySteam = {}
        expandedRow = nil
        for _, data in ipairs(zb.AO.LastSnapshot) do
            if IsValid(data.ent) then
                local row = BuildRow(data)
                rowsBySteam[data.steamid] = row
            end
        end
    end
    local function RefreshFromSnapshot()
        local seen = {}
        local membershipChanged = false
        for _, data in ipairs(zb.AO.LastSnapshot) do
            if IsValid(data.ent) then
                seen[data.steamid] = true
                local row = rowsBySteam[data.steamid]
                if row and IsValid(row) then
                    row.data = data
                else
                    membershipChanged = true
                end
            end
        end
        for steamid in pairs(rowsBySteam) do
            if not seen[steamid] then
                membershipChanged = true
            end
        end
        if membershipChanged then
            RebuildList()
        end
    end
    zb.AO.OnSnapshotUpdated = RefreshFromSnapshot
    RebuildList()
    panel.OnRemove = function()
        if zb.AO.OnSnapshotUpdated == RefreshFromSnapshot then
            zb.AO.OnSnapshotUpdated = nil
        end
    end
    return panel
end
