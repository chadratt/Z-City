local PANEL = {}

local sw, sh = ScrW(), ScrH()

local text = "You may be wondering why you all are here. Each of you have been paired with another guest, Hunter and Hunted. Track down your Quarry but beware, another is coming for you."

local COMMANDER = Material("hitmanmode/contractor.png", "smooth")

surface.CreateFont("ZB_PathowogenDialogue", {
	font = "Bahnschrift",
	size = ScreenScale(6),
	extended = true,
	weight = 400,
	antialias = true,
	scanlines = 2
})

surface.CreateFont("ZB_PathowogenDialogueTitle", {
	font = "Bahnschrift",
	size = ScreenScale(10),
	extended = true,
	weight = 400,
	antialias = true,
	scanlines = 2
})

local zigCol1 = Color(255, 255, 255, 14)
local zigCol2 = Color(255, 255, 255, 6)

function zb.HitmanDrawZigZag(x, y, w, h, scale, alphaMul)
	scale = scale or 1
	alphaMul = alphaMul or 1

	local spacing = math.max(4, math.floor(9 * scale))
	local half    = spacing
	local amp     = math.floor(spacing * 0.5)
	local period  = half * 2

	local offX = (CurTime() * 14 * scale) % period
	local offY = (CurTime() * 7 * scale) % spacing

	local row = 0
	for baseY = y - spacing + offY, y + h + spacing, spacing do
		local col = (row % 2 == 0) and zigCol1 or zigCol2
		surface.SetDrawColor(col.r, col.g, col.b, col.a * alphaMul)

		local px, py = x - period + offX, baseY
		local up = true
		while px < x + w + period do
			local nx = px + half
			local ny = up and (baseY - amp) or baseY
			surface.DrawLine(px, py, nx, ny)
			px, py = nx, ny
			up = not up
		end

		row = row + 1
	end
end

function PANEL:Init()
	self:SetPos(sw * 0.07, sh * 0.07)
	self:SetSize(sw * 0.22, sh * 0.12)

	if IsValid(zb.HitmanDialogueWindow) then
		zb.HitmanDialogueWindow:Remove()
	end

	zb.HitmanDialogueWindow = self

	self.textread = ""
	self.textpos = 0
	self.currenttext = ""

	surface.PlaySound("zbattle/dialogue/radio_talk.ogg")

	
	
	
	
	
	
	
	
	
	

	
	
	
	
	
	
	
	
	
	

	self.appearAlpha = 255
	self.appearProgress = 0

	self:CreateAnimation(1, {
		index = 1,
		target = {
			appearAlpha = 0,
			appearProgress = 1
		},
		easing = "linear",
		bIgnoreConfig = true,
		Think = function()
			
			
		end,
		OnComplete = function()
		end
	})

	self.CloseOnLast = false
	self.bClosing = false

	self.text = vgui.Create("DLabel", self)
	self.text:Dock(FILL)
	self.text:DockMargin(sw * 0.22 * 0.3 + ScreenScale(1), ScreenScale(10), 0, 0)
	self.text:SetText(self.currenttext)
	self.text:SetFont("ZB_PathowogenDialogue")
	self.text:SetContentAlignment(4)
	self.text:SetTextColor(Color(215, 215, 215))
	self.text:SetWrap(true)
	self.text:SetAutoStretchVertical(true)

	self.timebetween = SysTime() + 1.2

	
	
	
end

local glow = Material("zbattle/borderglow2.png")

local red = Color(175, 30, 30)

function PANEL:Paint(w, h)
	surface.SetDrawColor(16, 16, 16, 235)
	surface.DrawRect(0, h * 0.2, w, h)

	surface.SetDrawColor(30, 30, 30, 60)
	surface.DrawRect(0, 0, w, h)

	local zx, zy = self:LocalToScreen(math.floor(w * 0.3), math.floor(h * 0.2))
	render.SetScissorRect(zx, zy, zx + math.ceil(w * 0.7), zy + math.ceil(h * 0.8), true)
		zb.HitmanDrawZigZag(w * 0.3, h * 0.2, w * 0.7, h * 0.8, ScrH() / 1080, 0.3)
	render.SetScissorRect(0, 0, 0, 0, false)

	surface.SetDrawColor(red.r, red.g, red.b, 200)
	surface.DrawRect(w * 0.3, h * 0.2, w * 0.7, math.max(1, ScreenScale(0.5)))

	surface.SetDrawColor(24, 24, 24)
	surface.DrawRect(0, 0, w * 0.3, h)

	surface.SetMaterial(COMMANDER)
	surface.SetDrawColor(220, 220, 220)
	surface.DrawTexturedRect(0, 0, w * 0.3, h)

	surface.SetDrawColor(0, 0, 0)
	surface.DrawOutlinedRect(0, 0, w * 0.3, h, ScreenScale(1))

	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial(glow)

	for i = 1, 10 do
		surface.SetDrawColor(200, 200, 200, 8)
		surface.DrawRect(0, ((h / 10 * i) + (CurTime() * 10)) % h, w * 0.3, ScreenScale(1))
	end

	DisableClipping(true)
		surface.SetDrawColor(0, 0, 0, self.appearProgress * 255)
		surface.DrawTexturedRect(-ScreenScale(4) - 1, -ScreenScale(4), w * 0.3 + ScreenScale(8) + 1, h + ScreenScale(8))
	DisableClipping(false)

	draw.GlowingText("The Captain", "ZB_PathowogenDialogueTitle", w * 0.31, 0 - ScreenScale(1), Color(225, 225, 225, 255), ColorAlpha(red, 200), ColorAlpha(red, 10), TEXT_ALIGN_LEFT)

	surface.SetDrawColor(255, 255, 255, self.appearAlpha * 4)
	surface.DrawRect(0, 0, w, h)
end

function PANEL:Think()
	if SysTime() > self.timebetween and self.textpos <= #self.textread then
		self.textpos = self.textpos + 1

		local newtext = string.sub(self.textread, 0, self.textpos)

		if self.currenttext != newtext then
			sound.PlayFile("sound/zbattle/dialogue/commander_talk2.ogg", "", function() end)
			self.currenttext = newtext
			self.text:SetText(newtext)
		end

		if string.Right(newtext, 1) == "." then
			self.timebetween = SysTime() + 1
		elseif string.Right(newtext, 1) == "," or string.Right(newtext, 1) == ":" then
			self.timebetween = SysTime() + 0.5
		else
			self.timebetween = SysTime() + 0.04
		end

		if self.CloseOnLast and self.textpos == #self.textread then
			timer.Simple(2, function()
				if IsValid(self) then
					self:Close()
				end
			end)
		end
	end
end

function PANEL:SetText(text, delay)
	self.textread = text
	self.timebetween = SysTime() + (delay or 0)

	self.textpos = 0
end

function PANEL:SetTextAutoClose(text)
	self.textread = text
	self.timebetween = SysTime() + 2

	self.textpos = 0
	self.CloseOnLast = true
end

function PANEL:Close()
	if self.bClosing then return end
	self.bClosing = true

	sound.PlayFile("sound/zbattle/dialogue/radio_off.wav", "", function() end)

	self:CreateAnimation(1, {
		index = 2,
		target = {
			appearAlpha = 255,
			appearProgress = 0
		},
		easing = "linear",
		bIgnoreConfig = true,
		Think = function()
			
			self:SetAlpha(255 * self.appearProgress / 2)
		end,
		OnComplete = function()
			self:Remove()
		end
	})
end

vgui.Register("ZB_HitmanDialogue", PANEL, "EditablePanel")