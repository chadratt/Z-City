hg = hg or {}

local gradient_d = Material("vgui/gradient-d")
local gradient_l = Material("vgui/gradient-l")

local colBg = Color(18, 18, 18, 255)
local colHeaderBg = Color(35, 35, 35, 200)
local colBorder = Color(140, 140, 140, 128)
local colRowA = Color(35, 35, 35, 200)
local colRowB = Color(28, 28, 28, 200)
local colRowHover = Color(70, 70, 70, 220)
local colText = Color(235, 235, 235, 255)
local colMuted = Color(150, 150, 150, 255)
local colKarmaHigh = Color(90, 220, 90, 255)
local colKarmaMid = Color(230, 200, 60, 255)
local colKarmaLow = Color(220, 70, 70, 255)

local function KarmaColor(karma)
	if karma >= 70 then return colKarmaHigh end
	if karma >= 30 then return colKarmaMid end
	return colKarmaLow
end

local function CreateRow(parent, ply, w)
	local row = vgui.Create("DButton", parent)
	row:SetText("")
	row:SetSize(w, ScreenScaleH(20))
	row:Dock(TOP)
	row:DockMargin(0, 0, 0, 2)

	local muteBtn = vgui.Create("DImageButton", row)
	muteBtn:SetSize(ScreenScale(12), ScreenScale(12))
	muteBtn:Dock(RIGHT)
	muteBtn:DockMargin(6, 4, 8, 4)
	muteBtn:SetImage(not ply:IsMuted() and "icon16/sound.png" or "icon16/sound_mute.png")

	muteBtn.DoClick = function()
		local nowMuted = not ply:IsMuted()
		ply:SetMuted(nowMuted)

		hg.playerInfo = hg.playerInfo or {}
		hg.playerInfo[ply:SteamID()] = {nowMuted, nowMuted and 0 or 1}

		muteBtn:SetImage(not ply:IsMuted() and "icon16/sound.png" or "icon16/sound_mute.png")
	end

	row.Paint = function(self, w, h)
		surface.SetDrawColor(self:IsHovered() and colRowHover or (ply:EntIndex() % 2 == 0 and colRowA or colRowB))
		surface.DrawRect(0, 0, w, h)

		local plyColor = ply:GetPlayerColor():ToColor()

		surface.SetDrawColor(plyColor)
		surface.DrawRect(0, 0, 3, h)

		draw.SimpleText(ply:Name() or "unconnected", "ZB_InterfaceMedium", 12, h / 2, colText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		local karma = ply:GetNetVar("Karma", 100)
		draw.SimpleText("K " .. math.Round(karma), "ZB_InterfaceSmall", w * 0.52, h / 2, KarmaColor(karma), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		draw.SimpleText((ply:Frags() or 0) .. " / " .. (ply:Deaths() or 0), "ZB_InterfaceSmall", w * 0.68, h / 2, colText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		draw.SimpleText(tostring(ply:Ping() or 0), "ZB_InterfaceSmall", w * 0.86, h / 2, colMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	row.DoClick = function()
		if ply:IsBot() then chat.AddText(Color(255,0,0), "no, you can't") return end
		gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
	end

	row.DoRightClick = function()
		local menu = DermaMenu()

		menu:AddOption("Account", function()
			zb.Experience.AccountMenu(ply)
		end)

		menu:AddOption("Copy SteamID", function()
			SetClipboardText(ply:SteamID())
		end)

		menu:Open()
	end

	return row
end

function hg.DrawLeaderboardMenu(ParentPanel)
	if not IsValid(ParentPanel) then return end

	ParentPanel:SetAlpha(0)
	ParentPanel:AlphaTo(255, 0.15, 0)

	ParentPanel.Paint = function(self, w, h)
		surface.SetDrawColor(colBg)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(colHeaderBg)
		surface.SetMaterial(gradient_d)
		surface.DrawTexturedRect(0, 0, w, ScreenScaleH(30))

		surface.SetDrawColor(colBorder)
		surface.DrawOutlinedRect(0, 0, w, h, 1.5)

		draw.SimpleText("LEADERBOARD", "ZB_InterfaceLarge", 15, ScreenScaleH(15), colText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		local plyCount, specCount = 0, 0
		for _, ply in player.Iterator() do
			if ply:Team() == TEAM_SPECTATOR then specCount = specCount + 1 else plyCount = plyCount + 1 end
		end

		draw.SimpleText(plyCount .. " Players  /  " .. specCount .. " Spectators", "ZB_InterfaceSmall", w - 15, ScreenScaleH(15), colMuted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	local colW = (ParentPanel:GetWide() - 30) / 2

	local playersHeader = vgui.Create("DLabel", ParentPanel)
	playersHeader:SetPos(10, ScreenScaleH(38))
	playersHeader:SetSize(colW, ScreenScaleH(14))
	playersHeader:SetFont("ZB_InterfaceSmall")
	playersHeader:SetTextColor(colMuted)
	playersHeader:SetText("PLAYERS")

	local spectatorsHeader = vgui.Create("DLabel", ParentPanel)
	spectatorsHeader:SetPos(20 + colW, ScreenScaleH(38))
	spectatorsHeader:SetSize(colW, ScreenScaleH(14))
	spectatorsHeader:SetFont("ZB_InterfaceSmall")
	spectatorsHeader:SetTextColor(colMuted)
	spectatorsHeader:SetText("SPECTATORS")

	local playersScroll = vgui.Create("DScrollPanel", ParentPanel)
	playersScroll:SetPos(10, ScreenScaleH(54))
	playersScroll:SetSize(colW, ParentPanel:GetTall() - ScreenScaleH(64) - ScreenScaleH(26))

	local spectatorsScroll = vgui.Create("DScrollPanel", ParentPanel)
	spectatorsScroll:SetPos(20 + colW, ScreenScaleH(54))
	spectatorsScroll:SetSize(colW, ParentPanel:GetTall() - ScreenScaleH(64) - ScreenScaleH(26))

	local players, spectators = {}, {}

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then
			spectators[#spectators + 1] = ply
		else
			players[#players + 1] = ply
		end
	end

	table.sort(players, function(a, b) return (a:Frags() or 0) > (b:Frags() or 0) end)

	for _, ply in ipairs(players) do
		CreateRow(playersScroll, ply, colW)
	end

	for _, ply in ipairs(spectators) do
		CreateRow(spectatorsScroll, ply, colW)
	end

	surface.SetFont("ZB_InterfaceSmall")
	local muteLabel = "MUTE SPECTATORS"
	local labelW = surface.GetTextSize(muteLabel)
	local btnW, btnH = labelW + ScreenScale(16), ScreenScaleH(18)

	local muteSpectBtn = vgui.Create("DButton", ParentPanel)
	muteSpectBtn:SetText("")
	muteSpectBtn:SetSize(btnW, btnH)
	muteSpectBtn:SetPos(ParentPanel:GetWide() - btnW - 10, ParentPanel:GetTall() - btnH - 10)

	muteSpectBtn.Paint = function(self, w, h)
		surface.SetDrawColor(hg.mutespect and colText or colHeaderBg)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(colBorder)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText(muteLabel, "ZB_InterfaceSmall", w / 2, h / 2, hg.mutespect and colBg or colText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	muteSpectBtn.DoClick = function()
		hg.mutespect = not hg.mutespect

		for _, ply in player.Iterator() do
			if ply:Alive() then continue end

			if hg.mutespect then
				ply:SetVoiceVolumeScale(0)
			else
				ply:SetVoiceVolumeScale(not hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
			end
		end
	end
end
