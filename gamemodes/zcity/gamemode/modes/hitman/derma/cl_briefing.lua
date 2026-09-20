local PANEL = {}

function PANEL:Init()
	if IsValid(zb.FurBriefing) then
		zb.FurBriefing:Remove()
	end

	zb.FurBriefing = self
	self.alpha = 255

	self:SetSize(ScrW(), ScrH())

	self.dialogue = self:Add("ZB_HitmanDialogue")
	self.dialogue:SetPos(ScrW() / 2 - self.dialogue:GetWide() / 2, ScrH() / 2 - self.dialogue:GetTall() / 2)

	self.dialogue:SetText("You may be wondering why you all are here. Each of you have been paired with another guest, Hunter and Hunted. Track down your Quarry but beware, another is coming for you. Two of you will be making it out alive. . . .", 2)
	timer.Simple(18, function()
		if !IsValid(self) then return end
		self.dialogue:SetText("Kill or be killed! what better sport could you wish for!")

		self:SetKeyboardInputEnabled(false)

		self:CreateAnimation(1, {
			index = 1,
			target = {
				alpha = 0
			},
			easing = "linear",
			bIgnoreConfig = true,
		})

		self.dialogue:CreateAnimation(1, {
			index = 1,
			target = {
				x = ScrW() * 0.07,
				y = ScrH() * 0.07
			},
			easing = "outQuint",
			bIgnoreConfig = true,
			Think = function()
				self.dialogue:SetPos(self.dialogue.x, self.dialogue.y)
			end
		})

		timer.Simple(5, function()
			if !IsValid(self) then return end
			self.dialogue:Close()
			timer.Simple(1, function()
				if !IsValid(self) then return end
				self:Remove()
			end)
		end)
	end)

	self:RequestFocus()
	self:MakePopup()

	self:SetKeyboardInputEnabled(true)
	self:SetMouseInputEnabled(false)

	sound.PlayFile("sound/zbattle/briefing.ogg", "", function() end)
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(0, 0, 0, self.alpha)
	surface.DrawRect(0, 0, w, h)

	
end

vgui.Register("ZB_HitmanBriefing", PANEL, "EditablePanel")