if CLIENT then
    local isMenuOpen = nil
    zb.availableModes = zb.availableModes or {}
    zb.RoundList = zb.RoundList or {}
    zb.nextround = zb.nextround or nil
    zb.forcemode = zb.forcemode or "random"
    local queueManagerInstance = nil
    local COL_BG        = Color(28, 28, 28, 240)
    local COL_BORDER    = Color(75, 75, 75, 255)
    local COL_CAT       = Color(60, 60, 60, 255)
    local COL_CATBAR    = Color(42, 42, 42, 255)
    local COL_ROW       = Color(43, 43, 43, 235)
    local COL_ROW_HOV   = Color(56, 56, 56, 240)
    local COL_ROWBAR    = Color(47, 47, 47, 235)
    local COL_ACCENT    = Color(160, 45, 45, 255)
    local COL_ACCENT_H  = Color(190, 60, 60, 255)
    local COL_GREEN     = Color(80, 125, 65, 255)
    local COL_GREEN_H   = Color(100, 150, 85, 255)
    local COL_ORANGE    = Color(220, 150, 45, 255)
    local COL_TEXT      = Color(235, 235, 235, 235)
    local COL_TEXT_DIM  = Color(140, 140, 140, 220)
    local COL_TOGGLE_BG = Color(28, 28, 28, 255)
    local menufont = "Bahnschrift"
    surface.CreateFont("ZB_QM_Title",    {font = menufont, size = 26, weight = 500, antialias = true})
    surface.CreateFont("ZB_QM_Category", {font = menufont, size = 21, weight = 400, antialias = true})
    surface.CreateFont("ZB_QM_Item",     {font = menufont, size = 19, weight = 400, antialias = true})
    surface.CreateFont("ZB_QM_Small",    {font = menufont, size = 14, weight = 300, antialias = true})
    surface.CreateFont("ZB_QM_Btn",      {font = menufont, size = 16, weight = 500, antialias = true})
    local SND_CLICK   = "shitty/tap_depress.wav"
    local SND_RELEASE = "shitty/tap_release.wav"
    local SND_HOVER   = "shitty/tap-resonant.wav"
    net.Receive("ZB_SendModesInfo", function()
        zb.availableModes = net.ReadTable()
        if IsValid(queueManagerInstance) then queueManagerInstance:RebuildModes() end
    end)
    net.Receive("ZB_SendRoundList", function()
        zb.RoundList = net.ReadTable()
        zb.nextround = net.ReadString()
        zb.forcemode = net.ReadString()
        table.insert(zb.RoundList, 1, zb.nextround)
        zb.nextround = nil
        if IsValid(queueManagerInstance) then queueManagerInstance:QueueUpdate() end
    end)
    net.Receive("ZB_NotifyRoundListChange", function()
        local playerName = net.ReadString()
        chat.AddText(Color(180, 180, 255), playerName, COL_TEXT, " has modified the game mode queue")
        net.Start("ZB_RequestRoundList")
        net.SendToServer()
    end)
    local function GetModeName(key)
        for _, mode in ipairs(zb.availableModes) do
            if mode.key == key then return mode.name end
        end
        return key
    end
    local function ForceActive()
        return zb.forcemode and zb.forcemode ~= "random" and zb.forcemode ~= ""
    end
    local function DrawFrameBG(self, w, h)
            if hg and hg.DrawBlur then hg.DrawBlur(self, 4) end
            surface.SetDrawColor(COL_BG)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(120, 120, 130, 12)
            local sp = 64
            local ox = (CurTime() * 18) % sp
            for x = 0, math.ceil(w / sp) do
                surface.DrawRect(x * sp - ox, 0, 1, h)
            end
            local oy = (CurTime() * 18) % sp
            for y = 0, math.ceil(h / sp) do
                surface.DrawRect(0, y * sp - oy + sp, w, 1)
            end
            surface.SetDrawColor(COL_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    local function ZcityBUTT(btn, base, hover, txtColor)
        base     = base     or COL_ROW
        hover    = hover    or COL_ROW_HOV
        txtColor = txtColor or COL_TEXT
        btn:SetFont("ZB_QM_Btn")
        btn:SetTextColor(txtColor)
        btn.OnCursorEntered = function() surface.PlaySound(SND_HOVER) end
        btn.Paint = function(self, w, h)
            local c = self:IsHovered() and hover or base
            draw.RoundedBox(0, 0, 0, w, h, c)
            surface.SetDrawColor(0, 0, 0, 55)
            surface.DrawRect(0, h - 3, w, 3)
        end
    end
    local function CreateToggle(parent, getState, onClick)
        local toggle = vgui.Create("DButton", parent)
        toggle:SetText("")
        toggle:SetSize(52, 24)
        local animProgress = getState() and 1 or 0
        toggle.Paint = function(self, w, h)
                local target = getState() and 1 or 0
                animProgress = Lerp(FrameTime() * 10, animProgress, target)
                local bgColor = Color(
                    Lerp(animProgress, 180, 80),
                    Lerp(animProgress, 30, 120),
                    Lerp(animProgress, 30, 50)
                )
            draw.RoundedBox(0, 0, 0, w, h, COL_TOGGLE_BG)
            draw.RoundedBox(0, 2, 2, w - 4, h - 4, Color(0, 0, 0, 30))
            local slsize = h - 12
            local slPos = Lerp(animProgress, 6, w - slsize - 6)
            draw.RoundedBox(0, slPos, 6, slsize, slsize, bgColor)
            surface.SetDrawColor(0, 0, 0, Lerp(animProgress, 150, 40))
            surface.DrawRect(slPos, slsize + 4, slsize, 3)
        end
        toggle.OnCursorEntered = function() surface.PlaySound(SND_HOVER) end
        toggle.DoClick = function()
            surface.PlaySound(SND_CLICK)
            onClick()
        end
        return toggle
    end
    local function StyleScroll(scroll)
            local bar = scroll:GetVBar()
            bar:SetWide(8)
            bar:SetHideButtons(true)
            bar.Paint = function(self, w, h)
                surface.SetDrawColor(0, 0, 0, 70)
                surface.DrawRect(1, 0, w - 2, h)
            end
        bar.btnGrip.Paint = function(self, w, h)
            surface.SetDrawColor(self:IsHovered() and Color(120, 120, 120) or Color(90, 90, 90))
            surface.DrawRect(1, 0, w - 2, h)
        end
    end
    local function CreateCategoryBar(parent, text)
        local bar = vgui.Create("DPanel", parent)
        bar:Dock(TOP)
        bar:SetTall(38)
        bar:DockMargin(0, 0, 0, 8)
        bar.Paint = function(self, w, h)
            surface.SetDrawColor(COL_CAT)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(COL_CATBAR)
            surface.DrawRect(0, h - 5, w, 5)
            draw.SimpleText(text, "ZB_QM_Category", w / 2, h / 2 - 2, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return bar
    end
    local function AddCloseButton(parent, frame)
        local btn = vgui.Create("DButton", parent)
        btn:SetSize(38, 38)
        btn:Dock(RIGHT)
        btn:DockMargin(0, 1, 6, 1)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            local col = self:IsHovered() and Color(255, 110, 110) or COL_TEXT
            local m = 12
            surface.SetDrawColor(col)
            for i = -1, 1 do
                surface.DrawLine(m, m + i, w - m, h - m + i)
                surface.DrawLine(w - m, m + i, m, h - m + i)
            end
        end
        btn.OnCursorEntered = function() surface.PlaySound(SND_HOVER) end
        btn.DoClick = function()
            surface.PlaySound(SND_RELEASE)
            frame:Close()
        end
        return btn
    end
    local function MakeContent(frame)
        local content = vgui.Create("DPanel", frame)
        content.Paint = nil
        frame.PerformLayout = function(_, w, h)
            content:SetPos(2, 2)
            content:SetSize(w - 4, h - 4)
        end
        return content
    end
    local function CreateAvailableRow(parent, mode, manager)
        local row = vgui.Create("DPanel", parent)
        row:SetTall(54)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 8)
        local statusText, statusCol
            if mode.canlaunch == 1 then
                statusText, statusCol = "Ready to launch", COL_GREEN_H
            elseif mode.canlaunch == 0 then
                statusText, statusCol = "Cannot launch (no points / blocked)", COL_ACCENT_H
            else
                statusText, statusCol = mode.key, COL_TEXT_DIM
            end
        row.Paint = function(self, w, h)
            local forced = (zb.forcemode == mode.key)
            surface.SetDrawColor(self:IsHovered() and COL_ROW_HOV or COL_ROW)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(forced and COL_ORANGE or COL_ROWBAR)
            surface.DrawRect(0, h - 3, w, 3)
            draw.RoundedBox(0, 16, h / 2 - 4, 8, 8, statusCol)
            draw.SimpleText(mode.name, "ZB_QM_Item", 34, h / 2 - 8, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local toggle = CreateToggle(row,
            function() return zb.forcemode == mode.key end,
            function()
                local target = (zb.forcemode == mode.key) and "random" or mode.key
                net.Start("AdminSetGameMode")
                    net.WriteString("setforcemode")
                    net.WriteString(target)
                    net.WriteBool(false)
                net.SendToServer()
                zb.forcemode = target
            end)
        toggle:Dock(RIGHT)
        toggle:DockMargin(10, 15, 16, 15)
        toggle:SetTooltip("Force this mode every round")
        local addBtn = vgui.Create("DButton", row)
        addBtn:SetWide(90)
        addBtn:Dock(RIGHT)
        addBtn:DockMargin(8, 12, 0, 12)
        addBtn:SetText("+ Queue")
        ZcityBUTT(addBtn, COL_GREEN, COL_GREEN_H)
        addBtn.DoClick = function()
            table.insert(zb.RoundList, mode.key)
            surface.PlaySound(SND_CLICK)
            manager:QueueUpdate()
        end
        return row
    end
    local ROW_H, ROW_GAP = 44, 8
    local STRIDE = ROW_H + ROW_GAP
    local function OpenQueueManager()
        if IsValid(queueManagerInstance) then queueManagerInstance:Close() end
        local frame = vgui.Create("ZFrame")
        frame:SetSize(math.Clamp(ScrW() * 0.62, 900, 1280), math.Clamp(ScrH() * 0.72, 560, 780))
        frame:Center()
        frame:SetTitle("")
        frame:SetDraggable(true)
        frame:ShowCloseButton(false)
        frame:SetBorder(false)
        frame:MakePopup()
        frame.Paint = DrawFrameBG
        queueManagerInstance = frame
        local content = MakeContent(frame)
        local header = vgui.Create("DPanel", content)
        header:Dock(TOP)
        header:SetTall(42)
        header:DockMargin(0, 0, 0, 10)
        header.Paint = function(self, w, h)
            surface.SetDrawColor(COL_CAT)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(COL_CATBAR)
            surface.DrawRect(0, h - 5, w, 5)
            draw.SimpleText("Game Mode Queue", "ZB_QM_Title", w / 2, h / 2 - 2, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        AddCloseButton(header, frame)
        local body = vgui.Create("DPanel", content)
        body:Dock(FILL)
        body.Paint = nil
        local leftPanel = vgui.Create("DPanel", body)
        leftPanel:Dock(LEFT)
        leftPanel:SetWide(frame:GetWide() * 0.55)
        leftPanel:DockMargin(0, 0, 6, 0)
        leftPanel.Paint = nil
        CreateCategoryBar(leftPanel, "Available Game Modes")
        local searchBar = vgui.Create("DTextEntry", leftPanel)
        searchBar:Dock(TOP)
        searchBar:DockMargin(0, 0, 0, 8)
        searchBar:SetTall(32)
        searchBar:SetFont("ZB_QM_Item")
        searchBar.Paint = function(self, w, h)
            surface.SetDrawColor(COL_TOGGLE_BG)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(70, 70, 70, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            self:DrawTextEntryText(COL_TEXT, Color(120, 120, 120), COL_TEXT)
            if self:GetText() == "" then
                draw.SimpleText("Search game modes...", "ZB_QM_Item", 8, h / 2, COL_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
        local dscroll = vgui.Create("DScrollPanel", leftPanel)
        dscroll:Dock(FILL)
        StyleScroll(dscroll)
        local queuePanel = vgui.Create("DPanel", body)
        queuePanel:Dock(FILL)
        queuePanel:DockMargin(6, 0, 0, 0)
        queuePanel.Paint = nil
        CreateCategoryBar(queuePanel, "Round Queue")
        local btnBar = vgui.Create("DPanel", queuePanel)
        btnBar:Dock(BOTTOM)
        btnBar:SetTall(38)
        btnBar:DockMargin(0, 8, 0, 0)
        btnBar.Paint = nil
        local applyBtn = vgui.Create("DButton", btnBar)
        applyBtn:SetText("Apply Queue")
        ZcityBUTT(applyBtn, COL_GREEN, COL_GREEN_H)
        applyBtn.DoClick = function()
            net.Start("ZB_UpdateRoundList")
                net.WriteTable(table.Copy(zb.RoundList))
                net.WriteBool(true)
            net.SendToServer()
            chat.AddText(COL_GREEN_H, "Game mode queue has been set!")
            surface.PlaySound(SND_CLICK)
        end
        local clearBtn = vgui.Create("DButton", btnBar)
        clearBtn:SetText("Clear Queue")
        ZcityBUTT(clearBtn, COL_ACCENT, COL_ACCENT_H)
        clearBtn.DoClick = function()
            zb.RoundList = {}
            frame:QueueUpdate()
            surface.PlaySound(SND_CLICK)
            chat.AddText(COL_ORANGE, "Queue cleared (press Apply to save)")
        end
        btnBar.PerformLayout = function(self, w, h)
            local half = (w - 8) / 2
            applyBtn:SetPos(0, 0)
            applyBtn:SetSize(half, h)
            clearBtn:SetPos(half + 8, 0)
            clearBtn:SetSize(half, h)
        end
        local queueList = vgui.Create("DPanel", queuePanel)
        queueList:Dock(FILL)
        queueList.rows = {}
        queueList.scroll = 0
        queueList.scrollTarget = 0
        queueList.dragging = nil
        queueList.dragIndex = nil
        queueList.grabDY = 0
        queueList.Paint = function(self, w, h)
            if #self.rows == 0 then
                draw.SimpleText("Queue is empty, modes are picked randomly.", "ZB_QM_Item", 6, 12, COL_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
        end
        queueList.PaintOver = function(self, w, h)
            local contentH = #self.rows * STRIDE
            if contentH > h + 2 then
                local barH = math.max(24, h * (h / contentH))
                local maxScroll = contentH - h
                local barY = maxScroll > 0 and (self.scroll / maxScroll) * (h - barH) or 0
                surface.SetDrawColor(0, 0, 0, 60)
                surface.DrawRect(w - 5, 0, 4, h)
                surface.SetDrawColor(110, 110, 110, 255)
                surface.DrawRect(w - 5, barY, 4, barH)
            end
        end
        queueList.OnMouseWheeled = function(self, delta)
            self.scrollTarget = self.scrollTarget - delta * STRIDE * 0.9
            return true
        end
        queueList.Think = function(self)
            local h = self:GetTall()
            local w = self:GetWide()
            local contentH = #self.rows * STRIDE
            local maxScroll = math.max(0, contentH - h)
            if self.dragging and IsValid(self.dragging) then
                local _, my = self:LocalCursorPos()
                local desiredY = math.Clamp(my - self.grabDY, -ROW_H * 0.5, h - ROW_H * 0.5)
                self.dragging.animY = desiredY
                self.dragging:SetPos(0, desiredY)
                self.dragging:MoveToFront()
                local minIndex = ForceActive() and 2 or 1
                local newIndex = math.Clamp(math.Round((desiredY + self.scroll) / STRIDE) + 1, minIndex, #self.rows)
                if newIndex ~= self.dragIndex then
                    local rowObj = table.remove(self.rows, self.dragIndex)
                    table.insert(self.rows, newIndex, rowObj)
                    local key = table.remove(zb.RoundList, self.dragIndex)
                    table.insert(zb.RoundList, newIndex, key)
                    self.dragIndex = newIndex
                    surface.PlaySound(SND_HOVER)
                end
                if my < 26 then self.scrollTarget = self.scrollTarget - 8 end
                if my > h - 26 then self.scrollTarget = self.scrollTarget + 8 end
            end
            self.scrollTarget = math.Clamp(self.scrollTarget, 0, maxScroll)
            self.scroll = Lerp(FrameTime() * 12, self.scroll, self.scrollTarget)
            if math.abs(self.scroll - self.scrollTarget) < 0.4 then self.scroll = self.scrollTarget end
            for i, row in ipairs(self.rows) do
                if not IsValid(row) then continue end
                row.queueIndex = i
                if row:GetWide() ~= w then row:SetSize(w, ROW_H) end
                local wantCursor = row:IsLocked() and "arrow" or "sizeall"
                if row.curCursor ~= wantCursor then
                    row:SetCursor(wantCursor)
                    row.curCursor = wantCursor
                end
                if row ~= self.dragging then
                    local targetY = (i - 1) * STRIDE - self.scroll
                    row.animY = Lerp(FrameTime() * 16, row.animY or targetY, targetY)
                    if math.abs(row.animY - targetY) < 0.4 then row.animY = targetY end
                    row:SetPos(0, row.animY)
                end
            end
        end
        local function MakeQueueRow(modeKey)
            local row = vgui.Create("DPanel", queueList)
            row:SetTall(ROW_H)
            row:SetCursor("sizeall")
            row.animY = 0
            row.Paint = function(self, w, h)
                local idx = self.queueIndex or 1
                local isNext = (idx == 1)
                local forced = isNext and ForceActive()
                local dragging = (queueList.dragging == self)
                local bg
                if dragging then bg = Color(72, 72, 72, 250)
                elseif forced then bg = Color(62, 52, 34, 235)
                elseif isNext then bg = Color(50, 62, 46, 235)
                else bg = self:IsHovered() and COL_ROW_HOV or COL_ROW end
                surface.SetDrawColor(bg)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(forced and COL_ORANGE or (isNext and COL_GREEN_H or COL_ROWBAR))
                surface.DrawRect(0, h - 3, w, 3)
                if forced then
                    surface.SetDrawColor(COL_ORANGE)
                    surface.DrawRect(13, h / 2 - 2, 12, 9)
                    surface.DrawOutlinedRect(15, h / 2 - 8, 8, 8, 2)
                else
                    surface.SetDrawColor(dragging and 190 or 110, dragging and 190 or 110, dragging and 190 or 110)
                    for gy = 0, 2 do
                        for gx = 0, 1 do
                            surface.DrawRect(14 + gx * 5, h / 2 - 7 + gy * 6, 3, 3)
                        end
                    end
                end
                local label = isNext and (forced and "FORCE" or "NEXT") or ("#" .. idx)
                local lcol = forced and COL_ORANGE or (isNext and COL_GREEN_H or COL_TEXT_DIM)
                draw.SimpleText(label, "ZB_QM_Small", 34, h / 2, lcol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(GetModeName(modeKey), "ZB_QM_Item", 92, h / 2, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if dragging then
                    surface.SetDrawColor(COL_GREEN_H)
                    surface.DrawOutlinedRect(0, 0, w, h, 2)
                end
            end
            row.IsLocked = function(self)
                return ForceActive() and (self.queueIndex or 1) == 1
            end
            row.OnMousePressed = function(self, code)
                if code ~= MOUSE_LEFT then return end
                if self:IsLocked() then
                    surface.PlaySound(SND_RELEASE)
                    return
                end
                queueList.dragging = self
                queueList.dragIndex = self.queueIndex
                local _, my = queueList:LocalCursorPos()
                queueList.grabDY = my - self.animY
                self:MouseCapture(true)
                surface.PlaySound(SND_CLICK)
            end
            row.OnMouseReleased = function(self, code)
                if queueList.dragging == self then
                    queueList.dragging = nil
                    queueList.dragIndex = nil
                    self:MouseCapture(false)
                    surface.PlaySound(SND_RELEASE)
                end
            end
            local removeBtn = vgui.Create("DButton", row)
            removeBtn:SetWide(30)
            removeBtn:Dock(RIGHT)
            removeBtn:DockMargin(4, 9, 12, 9)
            removeBtn:SetText("✕")
            removeBtn:SetCursor("hand")
            ZcityBUTT(removeBtn, COL_ACCENT, COL_ACCENT_H)
            removeBtn.Think = function(self)
                self:SetVisible(not row:IsLocked())
            end
            removeBtn.DoClick = function()
                if row:IsLocked() then return end
                table.remove(zb.RoundList, row.queueIndex or 1)
                frame:QueueUpdate()
            end
            return row
        end
        local allowedModes = {
            ["tdm"] = true, ["cstrike"] = true, ["hmcd"] = true,
            ["hl2dm"] = true, ["riot"] = true, ["gwars"] = true,
            ["criresp"] = true,
        }
        function frame:RebuildModes()
            dscroll:Clear()
            local filter = (IsValid(searchBar) and searchBar:GetValue() or ""):lower()
            for i, mode in SortedPairsByMemberValue(zb.availableModes, "canlaunch", true) do
                if not LocalPlayer():IsSuperAdmin() and not allowedModes[mode.key] then continue end
                if filter ~= "" and not string.find(mode.name:lower(), filter, 1, true) then continue end
                CreateAvailableRow(dscroll, mode, self)
            end
        end
        function frame:QueueUpdate()
            for _, r in ipairs(queueList.rows) do
                if IsValid(r) then r:Remove() end
            end
            queueList.rows = {}
            queueList.dragging = nil
            queueList.dragIndex = nil
            local w = queueList:GetWide()
            for idx, modeKey in ipairs(zb.RoundList) do
                local row = MakeQueueRow(modeKey)
                row.queueIndex = idx
                row.animY = (idx - 1) * STRIDE - queueList.scroll
                row:SetSize(w, ROW_H)
                row:SetPos(0, row.animY)
                queueList.rows[idx] = row
            end
            local maxScroll = math.max(0, #zb.RoundList * STRIDE - queueList:GetTall())
            queueList.scrollTarget = math.Clamp(queueList.scrollTarget, 0, maxScroll)
        end
        searchBar.OnChange = function()
            frame:RebuildModes()
        end
        frame:RebuildModes()
        frame:QueueUpdate()
        frame.OnClose = function()
            queueManagerInstance = nil
        end
        net.Start("ZB_RequestRoundList")
        net.SendToServer()
    end
    local function BuildGeneralTab(parent, frame)
        local tab = vgui.Create("DPanel", parent)
        tab.Paint = nil
        local function BigButton(text, base, hover)
            local btn = vgui.Create("DButton", tab)
            btn:Dock(TOP)
            btn:DockMargin(14, 12, 14, 0)
            btn:SetTall(52)
            btn:SetText(text)
            btn:SetFont("ZB_QM_Category")
            btn:SetTextColor(COL_TEXT)
            btn.OnCursorEntered = function() surface.PlaySound(SND_HOVER) end
            btn.Paint = function(self, w, h)
                surface.SetDrawColor(self:IsHovered() and hover or base)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(0, 0, 0, 55)
                surface.DrawRect(0, h - 3, w, 3)
            end
            return btn
        end
        local manageBtn = BigButton("Manage Game Mode Queue", COL_ROW, COL_ROW_HOV)
        manageBtn.DoClick = function()
            surface.PlaySound(SND_CLICK)
            OpenQueueManager()
        end
        local endBtn = BigButton("End Round", COL_ACCENT, COL_ACCENT_H)
        endBtn.DoClick = function()
            surface.PlaySound(SND_CLICK)
            net.Start("AdminEndRound")
            net.SendToServer()
            frame:Close()
        end
        return tab
    end
    surface.CreateFont("ZB_QM_MapName", {font = menufont, size = 18, weight = 500, antialias = true})
    surface.CreateFont("ZB_QM_MapBig",  {font = menufont, size = 44, weight = 500, antialias = true})
    local COL_RTV_RED   = Color(239, 47, 47, 180)
    local COL_RTV_RED_H = Color(255, 80, 80, 230)
    local MAP_TILE_MIN_W = 190
    local MAP_TILE_GAP   = 8
    local MAP_TILE_RATIO = 0.62
    local MAP_MAX_CHIPS  = 9
    zb.MapSelect = zb.MapSelect or {}
    zb.MapSelect.Maps = zb.MapSelect.Maps or {}
    zb.MapSelect.Current = zb.MapSelect.Current or game.GetMap()
    local mapConfirmInstance = nil
    local mapIconCache = {}
    net.Receive("ZB_MapSel_List", function()
        zb.MapSelect.Current = net.ReadString()
        local count = net.ReadUInt(16)
        local maps = {}
        for i = 1, count do
            maps[i] = net.ReadString()
        end
        zb.MapSelect.Maps = maps
        if zb.MapSelect.OnList then zb.MapSelect.OnList() end
    end)
    local function RequestMapList()
        net.Start("ZB_MapSel_Request")
        net.SendToServer()
    end
    local function GetMapPrefix(map)
        local prefix = string.match(map, "^([^_]+)_")
        return prefix and prefix:lower() or nil
    end
    local function FormatMapName(map)
        local parts = string.Explode("_", map)
        if #parts > 1 then table.remove(parts, 1) end
        for i, p in ipairs(parts) do
            parts[i] = string.upper(string.Left(p, 1)) .. string.sub(p, 2)
        end
        return table.concat(parts, " ")
    end
    local function GetMapIcon(map)
        local cached = mapIconCache[map]
        if cached ~= nil then return cached or nil end
        for _, path in ipairs({"maps/thumb/" .. map .. ".png", "maps/" .. map .. ".png"}) do
            local mat = Material(path, "smooth")
            if mat and not mat:IsError() then
                mapIconCache[map] = mat
                return mat
            end
        end
        mapIconCache[map] = false
        return nil
    end
    local function DrawMapCover(mat, x, y, w, h, alpha)
        local tw, th = mat:Width(), mat:Height()
        local u0, v0, u1, v1 = 0, 0, 1, 1
        if tw > 0 and th > 0 then
            local boxAspect, imgAspect = w / h, tw / th
            if imgAspect > boxAspect then
                local f = boxAspect / imgAspect
                u0 = (1 - f) / 2
                u1 = 1 - u0
            else
                local f = imgAspect / boxAspect
                v0 = (1 - f) / 2
                v1 = 1 - v0
            end
        end
        surface.SetDrawColor(255, 255, 255, alpha or 255)
        surface.SetMaterial(mat)
        surface.DrawTexturedRectUV(x, y, w, h, u0, v0, u1, v1)
    end
    local function DrawMapPicture(map, w, h, hovered)
        surface.SetDrawColor(15, 15, 15, 255)
        surface.DrawRect(0, 0, w, h)
        local icon = GetMapIcon(map)
        if icon then
            DrawMapCover(icon, 0, 0, w, h)
        else
            local prefix = GetMapPrefix(map)
            draw.SimpleText(prefix and prefix:upper() or "?", "ZB_QM_MapBig", w / 2, h / 2 - 6, Color(255, 255, 255, 40), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("no preview", "ZB_QM_Small", w / 2, h / 2 + 22, Color(255, 255, 255, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        surface.SetDrawColor(0, 0, 0, hovered and 60 or 120)
        surface.DrawRect(0, 0, w, h)
    end
    local function OpenMapConfirm(map, adminFrame)
        if IsValid(mapConfirmInstance) then mapConfirmInstance:Remove() end
        local isCurrent = (map == zb.MapSelect.Current)
        local pop = vgui.Create("ZFrame")
        mapConfirmInstance = pop
        pop:SetSize(480, 420)
        pop:Center()
        pop:SetTitle("")
        pop:SetDraggable(false)
        pop:ShowCloseButton(false)
        pop:SetBorder(false)
        pop:MakePopup()
        pop.Paint = DrawFrameBG
        if IsValid(adminFrame) then adminFrame:SetMouseInputEnabled(false) end
        local content = MakeContent(pop)
        local header = vgui.Create("DPanel", content)
        header:Dock(TOP)
        header:SetTall(42)
        header.Paint = function(self, w, h)
            surface.SetDrawColor(COL_CAT)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(COL_CATBAR)
            surface.DrawRect(0, h - 5, w, 5)
            draw.SimpleText("Change Map", "ZB_QM_Title", w / 2, h / 2 - 2, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        AddCloseButton(header, pop)
        local preview = vgui.Create("DPanel", content)
        preview:Dock(TOP)
        preview:DockMargin(14, 14, 14, 0)
        preview:SetTall(200)
        preview.Paint = function(self, w, h)
            DrawMapPicture(map, w, h, true)
            surface.SetDrawColor(0, 0, 0, 170)
            surface.DrawRect(0, h - 46, w, 46)
            draw.SimpleText(FormatMapName(map), "ZB_QM_MapName", 12, h - 32, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(map, "ZB_QM_Small", 12, h - 13, COL_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(COL_RTV_RED)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
        local btnBar = vgui.Create("DPanel", content)
        btnBar:Dock(BOTTOM)
        btnBar:SetTall(42)
        btnBar:DockMargin(14, 0, 14, 14)
        btnBar.Paint = nil
        local yesBtn = vgui.Create("DButton", btnBar)
        yesBtn:SetText("Yes")
        ZcityBUTT(yesBtn, COL_GREEN, COL_GREEN_H)
        yesBtn.DoClick = function()
            surface.PlaySound(SND_CLICK)
            net.Start("ZB_MapSel_Change")
                net.WriteString(map)
            net.SendToServer()
            pop:Close()
            if IsValid(adminFrame) then adminFrame:Close() end
        end
        local noBtn = vgui.Create("DButton", btnBar)
        noBtn:SetText("No")
        ZcityBUTT(noBtn, COL_ACCENT, COL_ACCENT_H)
        noBtn.DoClick = function()
            surface.PlaySound(SND_RELEASE)
            pop:Close()
        end
        btnBar.PerformLayout = function(self, w, h)
            local half = math.floor((w - 8) / 2)
            yesBtn:SetPos(0, 0)
            yesBtn:SetSize(half, h)
            noBtn:SetPos(w - half, 0)
            noBtn:SetSize(half, h)
        end
        local question = vgui.Create("DPanel", content)
        question:Dock(FILL)
        question.Paint = function(self, w, h)
            local q = isCurrent and "Are you sure you would like to reload this map?"
                or "Are you sure you would like to switch to this map?"
            draw.SimpleText(q, "ZB_QM_Item", w / 2, h / 2 - 11, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Everyone on the server will be moved over after a short countdown.", "ZB_QM_Small", w / 2, h / 2 + 13, COL_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        pop.OnRemove = function()
            if mapConfirmInstance == pop then mapConfirmInstance = nil end
            if IsValid(adminFrame) and not adminFrame.Closing then
                adminFrame:SetMouseInputEnabled(true)
            end
        end
        return pop
    end
    local function CreateMapTile(parent, map, adminFrame)
        local tile = vgui.Create("DButton", parent)
        tile:SetText("")
        tile:SetCursor("hand")
        tile.Map = map
        tile.DisplayName = FormatMapName(map)
        tile.Prefix = GetMapPrefix(map)
        tile.SearchKey = (map .. " " .. tile.DisplayName):lower()
        tile.OnCursorEntered = function() surface.PlaySound(SND_HOVER) end
        tile.Paint = function(self, w, h)
            local hovered = self:IsHovered()
            local isCurrent = (self.Map == zb.MapSelect.Current)
            DrawMapPicture(self.Map, w, h, hovered)
            local stripH = 30
            surface.SetDrawColor(0, 0, 0, 170)
            surface.DrawRect(0, 0, w, stripH)
            draw.SimpleText(self.DisplayName, "ZB_QM_MapName", 10, stripH / 2, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(0, 0, 0, 150)
            surface.DrawRect(0, h - 22, w, 22)
            draw.SimpleText(self.Map, "ZB_QM_Small", 10, h - 11, COL_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            if isCurrent then
                surface.SetFont("ZB_QM_Small")
                local tw = surface.GetTextSize("CURRENT")
                draw.RoundedBox(0, w - tw - 18, h - 20, tw + 12, 18, COL_GREEN)
                draw.SimpleText("CURRENT", "ZB_QM_Small", w - tw - 12, h - 11, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            local border
            if isCurrent then
                border = hovered and COL_GREEN_H or COL_GREEN
            else
                border = hovered and COL_RTV_RED_H or COL_RTV_RED
            end
            surface.SetDrawColor(border)
            surface.DrawOutlinedRect(0, 0, w, h, hovered and 3 or 2)
        end
        tile.DoClick = function(self)
            surface.PlaySound(SND_CLICK)
            OpenMapConfirm(self.Map, adminFrame)
        end
        return tile
    end
    local function BuildMapsTab(parent, frame)
        local tab = vgui.Create("DPanel", parent)
        tab.Paint = nil
        local tiles, visible = {}, {}
        local activePrefix = nil
        local loaded = #zb.MapSelect.Maps > 0
        local toolbar = vgui.Create("DPanel", tab)
        toolbar:Dock(TOP)
        toolbar:SetTall(32)
        toolbar:DockMargin(8, 8, 8, 6)
        toolbar.Paint = nil
        local refreshBtn = vgui.Create("DButton", toolbar)
        refreshBtn:Dock(RIGHT)
        refreshBtn:SetWide(96)
        refreshBtn:DockMargin(8, 0, 0, 0)
        refreshBtn:SetText("Refresh")
        ZcityBUTT(refreshBtn)
        local countLabel = vgui.Create("DPanel", toolbar)
        countLabel:Dock(RIGHT)
        countLabel:SetWide(130)
        countLabel.Paint = function(self, w, h)
            local txt = loaded and (#visible .. " / " .. #tiles .. " maps") or "loading..."
            draw.SimpleText(txt, "ZB_QM_Small", w - 4, h / 2, COL_TEXT_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        local searchBar = vgui.Create("DTextEntry", toolbar)
        searchBar:Dock(FILL)
        searchBar:SetFont("ZB_QM_Item")
        searchBar:SetUpdateOnType(true)
        searchBar.Paint = function(self, w, h)
            surface.SetDrawColor(COL_TOGGLE_BG)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(70, 70, 70, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            self:DrawTextEntryText(COL_TEXT, Color(120, 120, 120), COL_TEXT)
            if self:GetText() == "" then
                draw.SimpleText("Search maps...", "ZB_QM_Item", 8, h / 2, COL_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
        local chipRow = vgui.Create("DPanel", tab)
        chipRow:Dock(TOP)
        chipRow:SetTall(26)
        chipRow:DockMargin(8, 0, 8, 8)
        chipRow.Paint = nil
        local scroll = vgui.Create("DScrollPanel", tab)
        scroll:Dock(FILL)
        scroll:DockMargin(8, 0, 8, 8)
        StyleScroll(scroll)
        local grid = vgui.Create("DPanel", scroll)
        grid:Dock(TOP)
        grid:SetTall(80)
        grid.Paint = function(self, w, h)
            if #visible > 0 then return end
            local msg = loaded and "No maps match your search." or "Loading map list from the server..."
            draw.SimpleText(msg, "ZB_QM_Item", w / 2, 30, COL_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        grid.PerformLayout = function(self, w, h)
            if w <= 0 then return end
            local cols = math.max(2, math.floor((w + MAP_TILE_GAP) / (MAP_TILE_MIN_W + MAP_TILE_GAP)))
            local tileW = math.floor((w - MAP_TILE_GAP * (cols - 1)) / cols)
            local tileH = math.floor(tileW * MAP_TILE_RATIO)
            for i, tile in ipairs(visible) do
                local col = (i - 1) % cols
                local row = math.floor((i - 1) / cols)
                tile:SetPos(col * (tileW + MAP_TILE_GAP), row * (tileH + MAP_TILE_GAP))
                tile:SetSize(tileW, tileH)
            end
            local rows = math.ceil(#visible / cols)
            local newH = rows > 0 and (rows * (tileH + MAP_TILE_GAP) - MAP_TILE_GAP) or 80
            if self:GetTall() ~= newH then
                self:SetTall(newH)
                scroll:InvalidateLayout()
            end
        end
        local function ApplyFilter()
            local query = string.Trim(searchBar:GetValue() or ""):lower()
            visible = {}
            for _, tile in ipairs(tiles) do
                local ok = (not activePrefix or tile.Prefix == activePrefix)
                    and (query == "" or string.find(tile.SearchKey, query, 1, true) ~= nil)
                tile:SetVisible(ok)
                if ok then visible[#visible + 1] = tile end
            end
            grid:InvalidateLayout(true)
            scroll:InvalidateLayout()
        end
        local function MakeChip(label, prefix, count)
            local chip = vgui.Create("DButton", chipRow)
            chip:Dock(LEFT)
            chip:DockMargin(0, 0, 6, 0)
            chip:SetText("")
            surface.SetFont("ZB_QM_Small")
            local txt = count and (label .. "  " .. count) or label
            chip:SetWide(surface.GetTextSize(txt) + 20)
            chip.OnCursorEntered = function() surface.PlaySound(SND_HOVER) end
            chip.Paint = function(self, w, h)
                local active = (activePrefix == prefix)
                surface.SetDrawColor(active and COL_ACCENT or (self:IsHovered() and COL_ROW_HOV or COL_ROW))
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(0, 0, 0, 55)
                surface.DrawRect(0, h - 2, w, 2)
                draw.SimpleText(txt, "ZB_QM_Small", w / 2, h / 2 - 1, active and COL_TEXT or COL_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            chip.DoClick = function()
                surface.PlaySound(SND_CLICK)
                activePrefix = prefix
                ApplyFilter()
            end
            return chip
        end
        local function Populate()
            for _, t in ipairs(tiles) do
                if IsValid(t) then t:Remove() end
            end
            tiles = {}
            chipRow:Clear()
            local prefixCount = {}
            for _, map in ipairs(zb.MapSelect.Maps) do
                tiles[#tiles + 1] = CreateMapTile(grid, map, frame)
                local p = GetMapPrefix(map)
                if p then prefixCount[p] = (prefixCount[p] or 0) + 1 end
            end
            local prefixes = {}
            for p, c in pairs(prefixCount) do prefixes[#prefixes + 1] = {p = p, c = c} end
            table.sort(prefixes, function(a, b)
                if a.c == b.c then return a.p < b.p end
                return a.c > b.c
            end)
            MakeChip("ALL", nil, #tiles)
            local stillActive = (activePrefix == nil)
            for i = 1, math.min(MAP_MAX_CHIPS, #prefixes) do
                MakeChip(prefixes[i].p:upper(), prefixes[i].p, prefixes[i].c)
                if prefixes[i].p == activePrefix then stillActive = true end
            end
            if not stillActive then activePrefix = nil end
            ApplyFilter()
        end
        searchBar.OnValueChange = function() ApplyFilter() end
        refreshBtn.DoClick = function()
            surface.PlaySound(SND_CLICK)
            RequestMapList()
        end
        local function OnList()
            if not IsValid(tab) then return end
            loaded = true
            Populate()
        end
        zb.MapSelect.OnList = OnList
        if loaded then Populate() end
        RequestMapList()
        tab.OnRemove = function()
            if zb.MapSelect.OnList == OnList then zb.MapSelect.OnList = nil end
            if IsValid(mapConfirmInstance) then mapConfirmInstance:Remove() end
        end
        return tab
    end
    local function OpenAdminMenu()
        if IsValid(isMenuOpen) then return end
        local frame = vgui.Create("ZFrame")
        isMenuOpen = frame
        frame:SetSize(math.min(1180, ScrW() - 80), math.min(760, ScrH() - 80))
        frame:Center()
        frame:SetTitle("")
        frame:SetDraggable(true)
        frame:ShowCloseButton(false)
        frame:SetBorder(false)
        frame:MakePopup()
        frame.Paint = DrawFrameBG
        local content = MakeContent(frame)
        local header = vgui.Create("DPanel", content)
        header:Dock(TOP)
        header:SetTall(42)
        header:DockMargin(0, 0, 0, 12)
        header.Paint = function(self, w, h)
            surface.SetDrawColor(COL_CAT)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(COL_CATBAR)
            surface.DrawRect(0, h - 5, w, 5)
            draw.SimpleText("Admin Panel", "ZB_QM_Title", w / 2, h / 2 - 2, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        AddCloseButton(header, frame)
        local sheet = vgui.Create("DPropertySheet", content)
        sheet:Dock(FILL)
        sheet:DockMargin(0, 0, 0, 0)
        sheet.Paint = function(self, w, h)
            surface.SetDrawColor(COL_CAT)
            surface.DrawRect(0, 0, w, h)
        end
        sheet:AddSheet("GENERAL", BuildGeneralTab(sheet, frame), nil, false, false, "General admin actions")
        if zb.AO and zb.AO.BuildMapTab then
            sheet:AddSheet("MAP", zb.AO.BuildMapTab(sheet), nil, false, false, "Live map overview")
        end
        if zb.AO and zb.AO.BuildRoundTab then
            sheet:AddSheet("ROUND", zb.AO.BuildRoundTab(sheet), nil, false, false, "Players in this round")
        end
        sheet:AddSheet("MAPS", BuildMapsTab(sheet, frame), nil, false, false, "Change the server map")
        if zb.AO and zb.AO.Subscribe then
            zb.AO.Subscribe(true)
        end
        frame.OnClose = function()
            isMenuOpen = false
            if zb.AO and zb.AO.Subscribe then
                zb.AO.Subscribe(false)
            end
        end
    end
    hook.Add("InitPostEntity", "RequestModeData", function()
        if LocalPlayer():IsAdmin() then
            timer.Simple(2, function()
                net.Start("ZB_RequestRoundList")
                net.SendToServer()
            end)
        end
    end)
    local f6Key = KEY_F6
    hook.Add("PlayerButtonDown", "OpenAdminMenuF6", function(ply, key)
        if key == f6Key and LocalPlayer():IsAdmin() and not IsValid(isMenuOpen) then
            OpenAdminMenu()
        end
    end)
end
