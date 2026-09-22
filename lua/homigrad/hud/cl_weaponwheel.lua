hg = hg or {}
hg.WeaponWheel = hg.WeaponWheel or {}
local WW = hg.WeaponWheel

WW.Panel = nil
WW.Items = {}
WW.Center = nil
WW.HoverIndex = 0
WW.HoverSince = 0
WW.BoxHoverLerp = {}
WW.DescHeightLerp = 24
WW.OpenLerp = 0

local NAME_FONT = "HomigradFontMedium"
local DESC_FONT = "HomigradFontMedium"

local colBackdrop = Color(0, 0, 0, 120)
local colBoxBG = Color(0, 0, 0, 77)
local colBoxBorder = Color(255, 255, 255, 255)
local colLine = Color(255, 255, 255, 140)
local colText = Color(255, 255, 255, 255)
local colDescBG = Color(0, 0, 0, 190)
local colDescBorder = Color(255, 255, 255, 200)

local OPEN_SOUNDS = {
	"anarchy_core/backpack/inventory1.wav",
	"anarchy_core/backpack/inventory2.wav",
	"anarchy_core/backpack/inventory3.wav",
	"anarchy_core/backpack/inventory4.wav",
	"anarchy_core/backpack/inventory5.wav",
	"anarchy_core/backpack/inventory6.wav",
}

local function EdgePoint(cx0, cy0, halfW, halfH, tx, ty)
	local dx, dy = tx - cx0, ty - cy0
	if dx == 0 and dy == 0 then return cx0, cy0 end

	local scaleX = dx ~= 0 and (halfW / math.abs(dx)) or math.huge
	local scaleY = dy ~= 0 and (halfH / math.abs(dy)) or math.huge
	local scale = math.min(scaleX, scaleY)

	return cx0 + dx * scale, cy0 + dy * scale
end

local function GetWeaponIcon(class)
	local wepTable = weapons.Get(class)

	if wepTable then
		local icon = wepTable.WepSelectIcon2

		if type(icon) ~= "IMaterial" then
			icon = wepTable.WepSelectIcon
		end

		if type(icon) == "IMaterial" then
			return icon
		end
	end

	local mat = Material("spawnicons/" .. class .. ".png", "smooth")
	if not mat or mat:IsError() then return nil end
	return mat
end

local function GetWeaponDescription(class)
	local wepTable = weapons.Get(class)
	if not wepTable then return "" end

	local desc = wepTable.Instructions
	if not desc or desc == "" then desc = wepTable.Purpose end

	return desc or ""
end

local function WrapText(text, font, maxWidth)
	local lines = {}
	if not text or text == "" then return lines end

	surface.SetFont(font)

	for _, paragraph in ipairs(string.Explode("\n", text)) do
		local words = string.Explode(" ", paragraph)
		local current = ""

		for _, word in ipairs(words) do
			local test = current == "" and word or (current .. " " .. word)
			local tw = surface.GetTextSize(test)

			if tw > maxWidth and current ~= "" then
				lines[#lines + 1] = current
				current = word
			else
				current = test
			end
		end

		lines[#lines + 1] = current
	end

	return lines
end

local function BuildItems(ply, descW)
	local items = {}
	local center

	if not IsValid(ply) then return items, center end

	local plyWeapons = ply:GetWeapons()
	local sectors = {}

	for i, wep in ipairs(plyWeapons) do
		if not IsValid(wep) then continue end

		if wep:GetClass() == "weapon_hands_sh" then
			center = wep
		else
			sectors[#sectors + 1] = wep
		end
	end

	table.sort(sectors, function(a, b)
		local aSlot, bSlot = (a.Slot or 0), (b.Slot or 0)
		if aSlot == bSlot then
			return (a.SlotPos or 0) < (b.SlotPos or 0)
		end
		return aSlot < bSlot
	end)

	for i, wep in ipairs(sectors) do
		local class = wep:GetClass()
		local desc = GetWeaponDescription(class)

		items[#items + 1] = {
			wep = wep,
			class = class,
			name = hg.WeaponSelector.GetPrintName(wep),
			icon = GetWeaponIcon(class),
			desc = desc,
			lines = WrapText(desc, DESC_FONT, descW - 20),
		}
	end

	return items, center
end

local function EquipHovered()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	local idx = WW.HoverIndex

	if idx and idx > 0 and WW.Items[idx] and IsValid(WW.Items[idx].wep) then
		input.SelectWeapon(WW.Items[idx].wep)
	elseif IsValid(WW.Center) then
		input.SelectWeapon(WW.Center)
	else
		input.SelectWeapon("weapon_hands_sh")
	end
end

local function ClosePanel()
	local panel = WW.Panel
	WW.Panel = nil

	if IsValid(panel) then
		panel:AlphaTo(0, 0.08, 0, function()
			if IsValid(panel) then
				panel:Remove()
			end
		end)
	end
end

local function DropHovered()
	if not IsValid(WW.Panel) then return end

	local idx = WW.HoverIndex
	local item = idx and idx > 0 and WW.Items[idx]

	if item and IsValid(item.wep) then
		net.Start("HG_DropSpecificWeapon")
		net.WriteEntity(item.wep)
		net.SendToServer()
	end

	ClosePanel()
end

function WW.Show()
	local ply = LocalPlayer()

	if not IsValid(ply) or not ply:Alive() then return end
	if ply.organism and ply.organism.otrub then return end

	if IsValid(WW.Panel) then
		WW.Panel:Remove()
		WW.Panel = nil
	end

	local scrW, scrH = ScrW(), ScrH()
	local descW, descMaxH = scrW * 0.21, scrH * 0.24

	WW.Items, WW.Center = BuildItems(ply, descW)
	WW.HoverIndex = 0
	WW.HoverSince = CurTime()
	WW.BoxHoverLerp = {}
	WW.DescHeightLerp = 24
	WW.OpenLerp = 0

	local panel = vgui.Create("DPanel")
	WW.Panel = panel
	panel:SetPos(0, 0)
	panel:SetSize(scrW, scrH)
	panel:MakePopup()
	panel:SetKeyboardInputEnabled(false)
	panel:SetAlpha(0)
	panel:AlphaTo(255, 0.12)

	surface.PlaySound(OPEN_SOUNDS[math.random(#OPEN_SOUNDS)])

	input.SetCursorPos(scrW / 2, scrH / 2)

	local boxW, boxH = scrW * 0.11, scrH * 0.17
	local centerW, centerH = boxW * 0.62, boxH * 0.62
	local radius = math.min(scrW, scrH) * 0.30
	local cx, cy = scrW / 2, scrH / 2
	local count = #WW.Items

	local angles = {}
	for i = 1, count do
		angles[i] = math.rad((360 / count) * (i - 1))
	end

	panel.OnMousePressed = function(self, mcode)
		if mcode == MOUSE_LEFT then
			WW.Hide()
		elseif mcode == MOUSE_RIGHT then
			DropHovered()
		end
	end

	panel.Paint = function(self, w, h)
		WW.OpenLerp = LerpFT(self:GetAlpha() > 100 and 0.09 or 0.28, WW.OpenLerp, (self:GetAlpha() / 255))
		local viewLerp = Lerp(math.ease.OutExpo(WW.OpenLerp), 0, 1)

		local curRadius = radius * viewLerp
		local sizeLerp = math.Clamp(viewLerp * 1.2, 0.05, 1)
		local curBoxW, curBoxH = boxW * sizeLerp, boxH * sizeLerp
		local curCenterW, curCenterH = centerW * sizeLerp, centerH * sizeLerp

		surface.SetDrawColor(colBackdrop)
		surface.DrawRect(0, 0, w, h)

		local mx, my = input.GetCursorPos()

		local positions = {}
		for i = 1, count do
			local px = cx + math.sin(angles[i]) * curRadius
			local py = cy - math.cos(angles[i]) * curRadius
			positions[i] = {
				x = px - curBoxW / 2,
				y = py - curBoxH / 2,
				w = curBoxW,
				h = curBoxH,
			}
		end

		surface.SetDrawColor(colLine)
		for i, pos in ipairs(positions) do
			local boxCx, boxCy = pos.x + pos.w / 2, pos.y + pos.h / 2

			local hx, hy = EdgePoint(cx, cy, curCenterW / 2, curCenterH / 2, boxCx, boxCy)
			local wx, wy = EdgePoint(boxCx, boxCy, pos.w / 2, pos.h / 2, cx, cy)

			surface.DrawLine(hx, hy, wx, wy)
		end

		local hovered = 0

		if viewLerp > 0.9 then
			if mx > cx - curCenterW / 2 and mx < cx + curCenterW / 2 and my > cy - curCenterH / 2 and my < cy + curCenterH / 2 then
				hovered = -1
			end

			for i, pos in ipairs(positions) do
				if mx > pos.x and mx < pos.x + pos.w and my > pos.y and my < pos.y + pos.h then
					hovered = i
				end
			end
		end

		if hovered ~= WW.HoverIndex then
			WW.HoverIndex = hovered
			WW.HoverSince = CurTime()
			WW.DescHeightLerp = 24
		end

		local hcx, hcy = cx - curCenterW / 2, cy - curCenterH / 2
		local centerHoverLerp = WW.BoxHoverLerp[-1] or 0
		centerHoverLerp = LerpFT(0.15, centerHoverLerp, hovered == -1 and 1 or 0)
		WW.BoxHoverLerp[-1] = centerHoverLerp

		local centerPop = 1 + centerHoverLerp * 0.06

		surface.SetDrawColor(colBoxBG)
		surface.DrawRect(cx - (curCenterW * centerPop) / 2, cy - (curCenterH * centerPop) / 2, curCenterW * centerPop, curCenterH * centerPop)
		surface.SetDrawColor(colBoxBorder)
		surface.DrawOutlinedRect(cx - (curCenterW * centerPop) / 2, cy - (curCenterH * centerPop) / 2, curCenterW * centerPop, curCenterH * centerPop, hovered == -1 and 2 or 1)

		local centerHeaderH = draw.GetFontHeight(NAME_FONT) + 10

		draw.SimpleText("Hands", NAME_FONT, cx, cy - (curCenterH * centerPop) / 2 + 6, colText, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

		if IsValid(WW.Center) then
			local icon = GetWeaponIcon(WW.Center:GetClass())
			if icon then
				local bodyTop = cy - (curCenterH * centerPop) / 2 + centerHeaderH
				local bodyH = (curCenterH * centerPop) - centerHeaderH
				local ih = math.min(bodyH * 0.85, (curCenterW * 0.8) / 1.35)
				local iw = ih * 1.35

				surface.SetMaterial(icon)
				surface.SetDrawColor(color_white)
				surface.DrawTexturedRect(cx - iw / 2, bodyTop + bodyH / 2 - ih / 2, iw, ih)
			end
		end

		for i, pos in ipairs(positions) do
			local item = WW.Items[i]

			local hoverLerp = WW.BoxHoverLerp[i] or 0
			hoverLerp = LerpFT(0.15, hoverLerp, hovered == i and 1 or 0)
			WW.BoxHoverLerp[i] = hoverLerp

			local pop = 1 + hoverLerp * 0.06
			local bw, bh = pos.w * pop, pos.h * pop
			local bx, by = pos.x - (bw - pos.w) / 2, pos.y - (bh - pos.h) / 2

			surface.SetDrawColor(colBoxBG)
			surface.DrawRect(bx, by, bw, bh)
			surface.SetDrawColor(colBoxBorder)
			surface.DrawOutlinedRect(bx, by, bw, bh, hovered == i and 2 or 1)

			draw.SimpleText(item.name, NAME_FONT, bx + bw / 2, by + 6, colText, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			if item.icon then
				local headerH = draw.GetFontHeight(NAME_FONT) + 10
				local bodyTop = by + headerH
				local bodyH = bh - headerH

				local ih = math.min(bodyH * 0.8, (bw * 0.8) / 1.35)
				local iw = ih * 1.35

				surface.SetMaterial(item.icon)
				surface.SetDrawColor(color_white)
				surface.DrawTexturedRect(bx + bw / 2 - iw / 2, bodyTop + bodyH / 2 - ih / 2, iw, ih)
			end

			positions[i] = {x = bx, y = by, w = bw, h = bh}
		end

		if hovered > 0 and viewLerp > 0.9 then
			local item = WW.Items[hovered]
			local pos = positions[hovered]

			if item and #item.lines > 0 then
				local elapsed = CurTime() - WW.HoverSince
				local charsPerSecond = 70
				local shownChars = math.floor(elapsed * charsPerSecond)
				local remaining = shownChars
				local visibleLines = {}

				for _, line in ipairs(item.lines) do
					if remaining <= 0 then break end
					local lineLen = string.len(line)
					visibleLines[#visibleLines + 1] = string.sub(line, 1, remaining)
					remaining = remaining - lineLen
				end

				local lineH = draw.GetFontHeight(DESC_FONT) + 4
				local targetDescH = math.min(math.max(lineH + 16, #visibleLines * lineH + 16), descMaxH)

				WW.DescHeightLerp = LerpFT(0.22, WW.DescHeightLerp, targetDescH)
				local descH = WW.DescHeightLerp

				local dx = (pos.x + pos.w / 2) - cx
				local dy = (pos.y + pos.h / 2) - cy

				local dPosX, dPosY

				if math.abs(dx) >= math.abs(dy) then
					dPosX = pos.x + pos.w / 2 - descW / 2
					dPosY = pos.y + pos.h + 8
				else
					if dx >= 0 then
						dPosX = pos.x + pos.w + 8
					else
						dPosX = pos.x - descW - 8
					end
					dPosY = pos.y + pos.h / 2 - descH / 2
				end

				dPosX = math.Clamp(dPosX, 4, scrW - descW - 4)
				dPosY = math.Clamp(dPosY, 4, scrH - descH - 4)

				surface.SetDrawColor(colDescBG)
				surface.DrawRect(dPosX, dPosY, descW, descH)
				surface.SetDrawColor(colDescBorder)
				surface.DrawOutlinedRect(dPosX, dPosY, descW, descH, 1)

				local ly = dPosY + 8
				for _, shownLine in ipairs(visibleLines) do
					if ly + lineH > dPosY + descH then break end
					draw.SimpleText(shownLine, DESC_FONT, dPosX + 10, ly, colText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					ly = ly + lineH
				end
			end
		end
	end
end

function WW.Hide()
	if not IsValid(WW.Panel) then return end

	EquipHovered()
	ClosePanel()
end

WW.Key = WW.Key or KEY_TAB

hook.Add("PlayerBindPress", "WeaponWheel_TabIntercept", function(ply, bind, pressed)
	if bind ~= "+showscores" then return end

	if WW.Key == KEY_TAB then
		if pressed then
			WW.Show()
		else
			WW.Hide()
		end
	end

	return true
end)

hook.Add("PlayerButtonDown", "WeaponWheel_KeyDown", function(ply, button)
	if WW.Key == KEY_TAB then return end
	if ply ~= LocalPlayer() then return end
	if button ~= WW.Key then return end
	if gui.IsGameUIVisible() then return end

	WW.Show()
end)

hook.Add("PlayerButtonUp", "WeaponWheel_KeyUp", function(ply, button)
	if WW.Key == KEY_TAB then return end
	if ply ~= LocalPlayer() then return end
	if button ~= WW.Key then return end

	WW.Hide()
end)
