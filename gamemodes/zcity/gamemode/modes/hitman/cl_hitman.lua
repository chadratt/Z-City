MODE.name = "hitman"

local MODE = MODE

local roundend = false


local hitman_currentTarget = nil



local targetModelPanel = nil
local lastModelTarget  = nil

local function RemoveTargetModel()
	if IsValid(targetModelPanel) then
		targetModelPanel:Remove()
	end
	targetModelPanel = nil
	lastModelTarget  = nil
end





local lastScrH    = 0
local hudFont     = nil   
local hudFontSmall = nil  

local function EnsureHudFonts()
	local h = ScrH()
	if h == lastScrH then return end
	lastScrH = h

	local scale   = h / 1080
	local bigSz   = math.max(10, math.floor(22 * scale))
	local smallSz = math.max(8,  math.floor(14 * scale))

	surface.CreateFont("HM_TargetName_" .. h, {
		font   = "Bahnschrift",
		size   = bigSz,
		weight = 700,
	})
	surface.CreateFont("HM_TargetLabel_" .. h, {
		font   = "Bahnschrift",
		size   = smallSz,
		weight = 500,
	})

	hudFont      = "HM_TargetName_"  .. h
	hudFontSmall = "HM_TargetLabel_" .. h
end



local function GetCharacterName(ply)
	if not IsValid(ply) then return "???" end
	local charName = ply:GetNWString("PlayerName", "")
	if charName ~= "" then return charName end
	return ply:GetPlayerName()
end



net.Receive("hitman_start", function()
	roundend              = false
	hitman_currentTarget  = nil
	RemoveTargetModel()
	zb.RemoveFade()
end)

net.Receive("hitman_briefing", function()
	vgui.Create("ZB_HitmanBriefing")
end)



net.Receive("hitman_set_target", function()
	local ent            = net.ReadEntity()
	hitman_currentTarget = IsValid(ent) and ent or nil
end)





local IDLE_SEQUENCES = { "idle_all_01", "idle_subtle", "idle", "cidle_all", "menu_walk", "walk_all" }



local function AppearanceSource(target)
	if hg and hg.GetCurrentCharacter then
		local char = hg.GetCurrentCharacter(target)
		if IsValid(char) and char:GetModel() and char:GetModel() ~= "" then
			return char
		end
	end
	return target
end

local function ApplyTargetAppearance(card, target, targetChanged)
	if not (IsValid(card) and IsValid(card.modelPanel) and IsValid(target)) then return end

	local mdlPanel = card.modelPanel
	local src      = AppearanceSource(target)
	local mdl      = src:GetModel()
	if not mdl or mdl == "" then return end

	
	if mdlPanel:GetModel() ~= mdl then
		mdlPanel:SetModel(mdl)
	end

	local ent = mdlPanel.Entity
	if not IsValid(ent) then return end

	
	
	
	mdlPanel.targetEnt = target
	if targetChanged and istable(ent.modelAccess) then
		for _, m in pairs(ent.modelAccess) do
			if IsValid(m) then m:Remove() end
		end
		ent.modelAccess = nil
	end

	
	pcall(function()
		ent:SetSkin(src:GetSkin() or 0)

		for i = 0, ent:GetNumBodyGroups() - 1 do
			ent:SetBodygroup(i, src:GetBodygroup(i))
		end

		
		ent:SetSubMaterial()
		local mats = src:GetMaterials() or {}
		for i = 1, #mats do
			local sm = src:GetSubMaterial(i - 1)
			if sm and sm ~= "" then
				ent:SetSubMaterial(i - 1, sm)
			end
		end

		
		
		
		
		
		
		local col = target.GetPlayerColor and target:GetPlayerColor() or nil
		if not col or (col.x == 0 and col.y == 0 and col.z == 0) then
			col = src.GetPlayerColor and src:GetPlayerColor() or col
		end
		if col then
			ent:SetNWVector("PlayerColor", col)
			if ent.SetPlayerColor then ent:SetPlayerColor(col) end
		end

		local seq = -1
		for _, name in ipairs(IDLE_SEQUENCES) do
			local s = ent:LookupSequence(name)
			if s and s >= 0 then seq = s break end
		end
		if seq >= 0 then ent:ResetSequence(seq) end
	end)

	
	local mins, maxs = ent:GetRenderBounds()
	local topZ   = math.max(maxs.z, 64)
	local lookZ  = topZ * 0.62
	mdlPanel:SetFOV(36)
	mdlPanel:SetCamPos(Vector(topZ * 0.95, 0, lookZ))
	mdlPanel:SetLookAt(Vector(0, 0, lookZ))
end

local function EnsureTargetModel()
	if IsValid(targetModelPanel) then return targetModelPanel end

	
	local card = vgui.Create("DPanel")
	if not IsValid(card) then return nil end
	card:SetMouseInputEnabled(false)
	card.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(10, 10, 10, 200))
		draw.RoundedBoxEx(6, 0, 0, math.max(2, w * 0.03), h, Color(210, 30, 30, 220), true, false, true, false)
	end

	
	local mdlPanel = vgui.Create("DModelPanel", card)
	mdlPanel:SetMouseInputEnabled(false)
	mdlPanel:SetAnimated(true)
	mdlPanel:SetAmbientLight(Color(150, 150, 150))
	mdlPanel:SetDirectionalLight(BOX_TOP,   Color(255, 255, 255))
	mdlPanel:SetDirectionalLight(BOX_FRONT, Color(220, 220, 220))
	mdlPanel:SetColor(Color(255, 255, 255))

	function mdlPanel:LayoutEntity(ent)
		if self.bAnimated then self:RunAnimation() end
		ent:SetAngles(Angle(0, (RealTime() * 25) % 360, 0))  
	end

	
	
	
	
	function mdlPanel:PostDrawModel(ent)
		if not IsValid(ent) then return end
		local tgt = self.targetEnt
		if not IsValid(tgt) then return end
		if not (DrawAccesories and hg and hg.Accessories) then return end

		local acc = tgt:GetNetVar("Accessories")
		if not acc or acc == "none" then return end

		local function drawOne(key)
			local data = hg.Accessories[key]
			if not data then return end
			
			
			pcall(DrawAccesories, ent, ent, key, data, false, true)
		end

		if istable(acc) then
			for i = 1, #acc do drawOne(acc[i]) end
		else
			drawOne(acc)
		end

		ent:SetupBones()
	end

	card.modelPanel = mdlPanel

	targetModelPanel = card
	lastModelTarget  = nil
	return card
end


local nextPortraitRefresh = 0
hook.Add("Think", "hitman_target_model", function()
	local me   = IsValid(lply) and lply or LocalPlayer()
	local show =
		zb.ROUND_STATE == 1
		and IsValid(me) and me:Alive()
		and (zb.ROUND_START + 8.5 <= CurTime())
		and IsValid(hitman_currentTarget)

	if not show then
		if IsValid(targetModelPanel) then targetModelPanel:SetVisible(false) end
		return
	end

	local card = EnsureTargetModel()
	if not IsValid(card) then return end

	
	
	if lastModelTarget ~= hitman_currentTarget then
		ApplyTargetAppearance(card, hitman_currentTarget, true)
		lastModelTarget   = hitman_currentTarget
		nextPortraitRefresh = CurTime() + 0.4
	elseif CurTime() >= nextPortraitRefresh then
		ApplyTargetAppearance(card, hitman_currentTarget, false)
		nextPortraitRefresh = CurTime() + 0.4
	end

	
	local screenW, screenH = ScrW(), ScrH()
	local scale  = screenH / 1080
	local panelW = math.floor(260 * scale)
	local panelH = math.floor(54  * scale)
	local panelX = math.floor(screenW / 2 - panelW / 2)
	local panelY = math.floor(screenH * 0.88)

	local mw = math.floor(120 * scale)
	local mh = math.floor(180 * scale)
	local mx = math.max(math.floor(4 * scale), panelX - mw - math.floor(10 * scale))
	local my = (panelY + panelH) - mh

	card:SetVisible(true)
	card:SetSize(mw, mh)
	card:SetPos(mx, my)

	if IsValid(card.modelPanel) then
		local inset = math.floor(4 * scale)
		card.modelPanel:SetPos(inset, inset)
		card.modelPanel:SetSize(mw - inset * 2, mh - inset * 2)
	end
end)





function MODE:RenderScreenspaceEffects()
	if zb.ROUND_START + 7.5 < CurTime() then return end

	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)

	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end





function MODE:HUDPaint()
	local screenW = ScrW()
	local screenH = ScrH()

	
	if lply:Alive() and zb.ROUND_START + 8.5 >= CurTime() then
		zb.RemoveFade()

		local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)

		local eventname = GetGlobalString("ZB_EventName", "Hitman")
		draw.SimpleText("Hitman", "ZB_HomicideMediumLarge", screenW * 0.5, screenH * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local rolename  = GetGlobalString("ZB_EventRole", "Hitman")
		draw.SimpleText("You are a " .. rolename, "ZB_HomicideMediumLarge", screenW * 0.5, screenH * 0.5, Color(0, 120, 190, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local objective = GetGlobalString("ZB_EventObjective", "")
		draw.SimpleText(objective, "ZB_HomicideMedium", screenW * 0.5, screenH * 0.9, Color(0, 120, 190, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	
	
	
	if zb.ROUND_STATE ~= 1 then return end
	if not lply:Alive()    then return end
	if zb.ROUND_START + 8.5 > CurTime() then return end  

	EnsureHudFonts()
	if not hudFont then return end

	local scale  = screenH / 1080

	
	local panelW  = math.floor(260 * scale)
	local panelH  = math.floor(54  * scale)
	local padX    = math.floor(12  * scale)
	local padY    = math.floor(6   * scale)
	local cornerR = math.floor(6   * scale)
	local accentW = math.floor(4   * scale)

	
	local posX = math.floor(screenW / 2 - panelW / 2)
	local posY = math.floor(screenH * 0.88)

	
	draw.RoundedBox(cornerR, posX, posY, panelW, panelH, Color(10, 10, 10, 190))

	
	draw.RoundedBoxEx(cornerR, posX, posY, accentW, panelH, Color(210, 30, 30, 220), true, false, true, false)

	
	surface.SetFont(hudFontSmall)
	surface.SetTextColor(180, 180, 180, 220)
	surface.SetTextPos(posX + accentW + padX, posY + padY)
	surface.DrawText("TARGET")

	
	local targetName = IsValid(hitman_currentTarget)
		and GetCharacterName(hitman_currentTarget)
		or  "Waiting..."

	local nameAlpha = IsValid(hitman_currentTarget) and 255 or 160

	
	local r, g, b = 160, 160, 160
	if IsValid(hitman_currentTarget) then
		local pulse = math.abs(math.sin(CurTime() * 2))
		r = math.floor(220 + 35 * pulse)
		g = 40
		b = 40
	end

	
	local _, labelH = surface.GetTextSize("TARGET")  

	surface.SetFont(hudFont)
	surface.SetTextColor(r, g, b, nameAlpha)
	surface.SetTextPos(posX + accentW + padX, posY + padY + labelH + math.floor(2 * scale))
	surface.DrawText(targetName)

	
	local iconX  = posX + panelW - padX - math.floor(10 * scale)
	local iconY  = posY + math.floor(panelH / 2)
	local iconR  = math.floor(7  * scale)
	local armLen = math.floor(3  * scale)
	local thick  = math.max(1, math.floor(1.5 * scale))

	surface.SetDrawColor(210, 30, 30, 180)
	surface.DrawOutlinedRect(iconX - iconR, iconY - iconR, iconR * 2, iconR * 2, thick)
	surface.DrawRect(iconX - iconR - armLen, iconY - thick, armLen,   thick * 2)
	surface.DrawRect(iconX + iconR,          iconY - thick, armLen,   thick * 2)
	surface.DrawRect(iconX - thick, iconY - iconR - armLen, thick * 2, armLen)
	surface.DrawRect(iconX - thick, iconY + iconR,          thick * 2, armLen)
end



local wonply = nil

local colGray   = Color(85, 85, 85, 255)
local colRed    = Color(217, 201, 99)
local colRedUp  = Color(207, 181, 59)
local colBlue   = Color(10, 10, 160)
local colBlueUp = Color(40, 40, 160)
local col       = Color(255, 255, 255, 255)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255)

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
	hmcdEndMenu:Remove()
	hmcdEndMenu = nil
end

local function CreateEndMenu()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

	hmcdEndMenu = vgui.Create("ZFrame")

	surface.PlaySound("ambient/alarms/warningbell1.wav")

	local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
	local posX, posY   = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2

	hmcdEndMenu:SetPos(posX, posY)
	hmcdEndMenu:SetSize(sizeX, sizeY)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)

	local closebutton = vgui.Create("DButton", hmcdEndMenu)
	closebutton:SetPos(5, 5)
	closebutton:SetSize(ScrW() / 20, ScrH() / 30)
	closebutton:SetText("")

	closebutton.DoClick = function()
		if IsValid(hmcdEndMenu) then
			hmcdEndMenu:Close()
			hmcdEndMenu = nil
		end
	end

	closebutton.Paint = function(self, w, h)
		surface.SetDrawColor(122, 122, 122, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
		surface.SetFont("ZB_InterfaceMedium")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX, _ = surface.GetTextSize("Close")
		surface.SetTextPos(lengthX - lengthX / 1.1, 4)
		surface.DrawText("Close")
	end

	hmcdEndMenu.PaintOver = function(self, w, h)
		
		local winnerName = (wonply and GetCharacterName(wonply)) or "Nobody"
		local txt = winnerName .. " won!"
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX, _ = surface.GetTextSize(txt)
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText(txt)
	end

	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)

	for i, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		local but = vgui.Create("DButton", DScrollPanel)
		but:SetSize(100, 50)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")

		but.Paint = function(self, w, h)
			local c1 = (ply.won and colRed)  or (ply:Alive() and colBlue)   or colGray
			local c2 = (ply.won and colRedUp) or (ply:Alive() and colBlueUp) or colSpect1

			surface.SetDrawColor(c1.r, c1.g, c1.b, c1.a)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(c2.r, c2.g, c2.b, c2.a)
			surface.DrawRect(0, h / 2, w, h / 2)

			
			local charName = GetCharacterName(ply)

			surface.SetFont("ZB_InterfaceMediumLarge")
			local lx, ly = surface.GetTextSize(charName)

			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 - lx / 2 + 1, h / 2 - ly / 2 + 1)
			surface.DrawText(charName)

			local pcol = ply:GetPlayerColor():ToColor()
			surface.SetTextColor(pcol.r, pcol.g, pcol.b, pcol.a)
			surface.SetTextPos(w / 2 - lx / 2, h / 2 - ly / 2)
			surface.DrawText(charName)

			
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
			local sx, sy = surface.GetTextSize(ply:GetPlayerName())
			surface.SetTextPos(15, h / 2 - sy / 2)
			surface.DrawText(ply:Name() .. (not ply:Alive() and " - died" or ""))

			
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
			local fx, fy = surface.GetTextSize(tostring(ply:Frags()))
			surface.SetTextPos(w - fx - 15, h / 2 - fy / 2)
			surface.DrawText(tostring(ply:Frags()))
		end

		function but:DoClick()
			if ply:IsBot() then chat.AddText(Color(255, 0, 0), "no, you can't") return end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end

		DScrollPanel:AddItem(but)
	end
end

net.Receive("hitman_end", function()
	local ent = net.ReadEntity()
	wonply    = nil
	if IsValid(ent) then
		ent.won = true
		wonply  = ent
	end

	hitman_currentTarget = nil
	roundend             = CurTime()

	RemoveTargetModel()

	CreateEndMenu()
end)

function MODE:RoundStart()
	hitman_currentTarget = nil
	RemoveTargetModel()

	for _, ply in player.Iterator() do
		ply.won = nil
	end

	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end