local AVATAR_SIZE = 42
local AVATAR_SPACING = 4

local PANEL = {}

function PANEL:Init()
    self.Map = nil
    self.DisplayName = ""
    self.MapIcon = nil

    self.Votes = 0
    self.VoterIDs = {}

    self.Disabled = false
    self.Win = false

    self.hovered = false
    self.alpha = 0
    self.BipCD = 0

    self:SetCursor("hand")
    self:SetText("")

    self.AvatarHolder = vgui.Create("DIconLayout", self)
    self.AvatarHolder:Dock(BOTTOM)
    self.AvatarHolder:DockMargin(8, 0, 8, 8)
    self.AvatarHolder:SetTall(AVATAR_SIZE + 4)
    self.AvatarHolder:SetSpaceX(AVATAR_SPACING)
    self.AvatarHolder:SetSpaceY(AVATAR_SPACING)
    self.AvatarHolder:SetStretchWidth(false)
    self.AvatarHolder.Paint = function() end
end

function PANEL:SetMapData(mapName, displayName, icon)
    self.Map = mapName
    self.DisplayName = displayName or mapName
    self.MapIcon = icon
end

function PANEL:SetTileDisabled(bool)
    self.Disabled = bool
    if bool then
        self:SetCursor("arrow")
    else
        self:SetCursor("hand")
    end
end

function PANEL:SetVoteCount(count)
    self.Votes = count or 0
end

function PANEL:SetWinning(bool)
    self.Win = bool
end

function PANEL:VotersChanged(list)
    local old = self.VoterIDs or {}
    if #old ~= #list then return true end

    local oldSet = {}
    for _, v in ipairs(old) do oldSet[v] = true end

    for _, v in ipairs(list) do
        if not oldSet[v] then return true end
    end

    return false
end

function PANEL:SetVoters(list)
    list = list or {}
    if not self:VotersChanged(list) then return end

    self.VoterIDs = list
    self.AvatarHolder:Clear()

    for _, steamID64 in ipairs(list) do
        local avatar = vgui.Create("AvatarImage", self.AvatarHolder)
        avatar:SetSize(AVATAR_SIZE, AVATAR_SIZE)
        avatar:SetSteamID(steamID64, 64)

        function avatar:PaintOver(w, h)
            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawOutlinedRect(0, 0, w, h)
        end
    end

    local availW = math.max(self:GetWide() - 16, AVATAR_SIZE)
    local perRow = math.max(1, math.floor((availW + AVATAR_SPACING) / (AVATAR_SIZE + AVATAR_SPACING)))
    local rows = math.max(1, math.ceil(math.max(#list, 1) / perRow))
    local newTall = rows * AVATAR_SIZE + (rows - 1) * AVATAR_SPACING + 4

    self.AvatarHolder:SetTall(newTall)
    self.AvatarHolder:InvalidateLayout(true)
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(15, 15, 15, 255)
    surface.DrawRect(0, 0, w, h)

    if self.MapIcon and not self.MapIcon:IsError() then
        surface.SetDrawColor(255, 255, 255, self.Disabled and 70 or 255)
        surface.SetMaterial(self.MapIcon)
        surface.DrawTexturedRect(0, 0, w, h)
    elseif not self.Disabled then
        surface.SetFont("ZB_InterfaceMediumLarge")
        surface.SetTextColor(255, 255, 255, 90)
        local qw, qh = surface.GetTextSize("?")
        surface.SetTextPos(w / 2 - qw / 2, h / 2 - qh / 2)
        surface.DrawText("?")
    end

    surface.SetDrawColor(0, 0, 0, self.hovered and 90 or 140)
    surface.DrawRect(0, 0, w, h)

    local stripH = math.max(24, h * 0.12)
    surface.SetDrawColor(0, 0, 0, 170)
    surface.DrawRect(0, 0, w, stripH)

    surface.SetFont("ZB_ScrappersMedium")
    if self.Disabled then
        surface.SetTextColor(255, 255, 255, 110)
        surface.SetTextPos(10, stripH / 2 - select(2, surface.GetTextSize("No Map")) / 2)
        surface.DrawText("No Map")
    else
        surface.SetTextColor(255, 255, 255, 255)
        surface.SetTextPos(10, stripH / 2 - select(2, surface.GetTextSize(self.DisplayName)) / 2)
        surface.DrawText(self.DisplayName)
    end

    if not self.Disabled and self.Votes and self.Votes > 0 then
        surface.SetFont("ZB_ScrappersMedium")
        local txt = "x" .. self.Votes
        local tw, th = surface.GetTextSize(txt)
        surface.SetDrawColor(169, 0, 0, 220)
        surface.DrawRect(w - tw - 16, (stripH - th - 6) / 2, tw + 10, th + 6)
        surface.SetTextColor(255, 255, 255, 255)
        surface.SetTextPos(w - tw - 11, (stripH - th) / 2)
        surface.DrawText(txt)
    end

    if self.Win and self.BipCD < CurTime() then
        self.alpha = 255
        surface.PlaySound("buttons/blip1.wav")
        self.BipCD = CurTime() + 1
        self:CreateAnimation(0.5, {
            index = 1,
            target = { alpha = 0 },
            easing = "inExpo",
            bIgnoreConfig = true
        })
    end

    surface.SetDrawColor(239, 47, 47, self.alpha or 0)
    surface.DrawRect(0, 0, w, h)

    local borderColor
    if self.Disabled then
        borderColor = Color(120, 120, 120, 150)
    elseif self.hovered then
        borderColor = Color(255, 80, 80, 230)
    else
        borderColor = Color(239, 47, 47, 180)
    end

    surface.SetDrawColor(borderColor)
    surface.DrawOutlinedRect(0, 0, w, h, self.hovered and 3 or 2)
end

function PANEL:OnCursorEntered()
    if self.Disabled then return end
    self.hovered = true
end

function PANEL:OnCursorExited()
    self.hovered = false
end

vgui.Register("ZB_RTVMapTile", PANEL, "DButton")
