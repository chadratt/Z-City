if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_base"
SWEP.PrintName = "Suit"
SWEP.Instructions = "A simple costume, along with a mask, can help hide your identity, your clothes will stay in the suitcase in the future you can put them back on."
SWEP.Category = "ZCity Other"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.HoldType = "normal"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/props_c17/SuitCase_Passenger_Physics.mdl"
SWEP.Model = "models/props_c17/SuitCase_Passenger_Physics.mdl"

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_mask")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_mask"
	SWEP.BounceWeaponIcon = false
end

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Slot = 5
SWEP.SlotPos = 99
SWEP.WorkWithFake = false
SWEP.offsetVec = Vector(5, -1.5, -0.6)
SWEP.offsetAng = Angle(-90, 0, 0)
SWEP.ModelScale = 0.8

SWEP.Costume = {
	Title = "Cultist",                       
	Name = "???",                           
	Model = "models/trepang/playerm/cultist.mdl",
	Description = "To display yourself as one of the pale mans faithful ones.\nNo one will know who you are.",
	Color = Color(255, 255, 255),
	Attachments = {}
}

SWEP.IsCostumeActive = false

if SERVER then
	util.PrecacheModel(SWEP.Costume.Model)
end

function SWEP:DrawWorldModel()
	self.model = IsValid(self.model) and self.model or ClientsideModel(self.WorldModel)
	local WorldModel = self.model
	local owner = self:GetOwner()
	WorldModel:SetNoDraw(true)
	WorldModel:SetModelScale(self.ModelScale)
	if IsValid(owner) then
		local offsetVec = self.offsetVec
		local offsetAng = self.offsetAng
		local boneid = owner:LookupBone("ValveBiped.Bip01_L_Hand")
		if not boneid then return end
		local matrix = owner:GetBoneMatrix(boneid)
		if not matrix then return end
		local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
		WorldModel:SetPos(newPos)
		WorldModel:SetAngles(newAng)
		WorldModel:SetupBones()
	else
		WorldModel:SetPos(self:GetPos())
		WorldModel:SetAngles(self:GetAngles())
	end

	WorldModel:DrawModel()
end

function SWEP:SetHold(value)
	self:SetWeaponHoldType(value)
	self:SetHoldType(value)
	self.holdtype = value
end

function SWEP:Think()
	self:SetHold(self.HoldType)
end

function SWEP:GetEyeTrace()
	return hg.eyeTrace( self:GetOwner() )
end

if CLIENT then
	function SWEP:DrawHUD()
	end

	local color_white = Color(255, 255, 255)
	local color_desc = Color(200, 200, 200)

	function SWEP:OpenCostumeMenu()
		if self.IsCostumeActive then
			notification.AddLegacy("You must remove your current costume first!", NOTIFY_ERROR, 3)
			return
		end

		if IsValid(self.CostumeMenu) then
			self.CostumeMenu:Remove()
		end

		local costume = self.Costume
		local menuW, menuH = 360, 520

		local font = "ZB_InterfaceSmall"
		local titleFont = "ZB_InterfaceMedium"
		if engine.ActiveGamemode() == "sandbox" then
			font = "ZCity_Fixed_SuperTiny"
			titleFont = "ZCity_Fixed_Medium"
		end

		local menu = vgui.Create("ZFrame")
		self.CostumeMenu = menu
		menu:SetSize(menuW, menuH)
		menu:Center()
		menu:SetTitle("Costume Selection")
		menu:SetDraggable(true)
		menu:ShowCloseButton(true)
		menu:MakePopup()

		menu.Paint = function(pnl, w, h)
			draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 20, 230))
			draw.RoundedBox(8, 5, 5, w - 10, h - 10, Color(40, 0, 0, 180))
			draw.RoundedBox(0, 0, 0, w, 30, Color(60, 0, 0, 200))
			surface.SetDrawColor(180, 0, 0, 255)
			surface.DrawOutlinedRect(0, 0, w, h, 2)
		end

		menu.lblTitle:SetFont(font)
		menu.lblTitle:SetTextColor(color_white)

		local pad = 15
		local cardW, cardH = menuW - pad * 2, menuH - 30 - pad * 2
		local card = vgui.Create("DPanel", menu)
		card:SetSize(cardW, cardH)
		card:SetPos(pad, 30 + pad)

		local modelTop, modelSize = 44, cardW - 40
		local descY = modelTop + modelSize + 10

		card.Paint = function(pnl, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(60, 0, 0, 180))
			draw.RoundedBox(4, 2, 2, w - 4, h - 4, Color(30, 30, 30, 200))
			draw.RoundedBox(0, 0, 0, w, 36, Color(100, 0, 0, 200))
			surface.SetDrawColor(120, 0, 0, 255)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText(costume.Title, titleFont, w / 2, 18, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.DrawText(costume.Description, font, w / 2, descY, color_desc, TEXT_ALIGN_CENTER)
		end

		local modelPanel = vgui.Create("DModelPanel", card)
		modelPanel:SetSize(modelSize, modelSize)
		modelPanel:SetPos((cardW - modelSize) / 2, modelTop)
		modelPanel:SetModel(costume.Model)

		if IsValid(modelPanel.Entity) then
			local mn, mx = modelPanel.Entity:GetRenderBounds()
			local center = (mn + mx) * 0.5
			local size = math.max(math.abs(mn.x) + math.abs(mx.x), math.abs(mn.y) + math.abs(mx.y), math.abs(mn.z) + math.abs(mx.z))
			modelPanel:SetFOV(40)
			modelPanel:SetCamPos(center + Vector(size * 1.5, 0, size * 0.1))
			modelPanel:SetLookAt(center)
		end

		function modelPanel:LayoutEntity(ent)
			ent:SetAngles(Angle(0, RealTime() * 30 % 360, 0))
		end

		local btnW, btnH = 140, 32
		local selectButton = vgui.Create("DButton", card)
		selectButton:SetSize(btnW, btnH)
		selectButton:SetPos((cardW - btnW) / 2, cardH - btnH - 14)
		selectButton:SetText("Select")
		selectButton:SetFont(font)
		selectButton:SetTextColor(color_white)

		selectButton.Paint = function(pnl, w, h)
			local buttonColor = pnl:IsHovered() and Color(180, 0, 0, 200) or Color(120, 0, 0, 200)
			draw.RoundedBox(4, 0, 0, w, h, buttonColor)
			surface.SetDrawColor(200, 0, 0, 255)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end

		selectButton.DoClick = function()
			if IsValid(menu) then menu:Close() end

			net.Start("CultistSuitSelected")
			net.SendToServer()
		end
	end

	net.Receive("CultistSuitStatus", function()
		local active = net.ReadBool()
		local wep = LocalPlayer():GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == "weapon_traitor_suit_cultist" then
			wep.IsCostumeActive = active
		end
	end)
end

if SERVER then
	util.AddNetworkString("CultistSuitSelected")
	util.AddNetworkString("CultistSuitStatus")

	net.Receive("CultistSuitSelected", function(len, ply)
		if not IsValid(ply) or not ply:Alive() then return end
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "weapon_traitor_suit_cultist" then return end
		if wep.IsCostumeActive then return end

		local costume = wep.Costume

		if ply.CurAppearance and ply.CurAppearance.AModel then
			wep.StoredIdentity = table.Copy(ply.CurAppearance)
		else
			local col = ply:GetPlayerColor() * 255
			wep.StoredIdentity = {
				AName = ply:GetNWString("PlayerName", ply:Nick()),
				AModel = ply:GetModel(),
				AColor = Color(col.x, col.y, col.z),
				AClothes = {},
				AAttachments = ply:GetNetVar("Accessories", {}) or {}
			}
		end

		local newIdentity = {
			AName = costume.Name,
			AClothes = {},
			AModel = costume.Model,
			AColor = costume.Color,
			AAttachments = table.Copy(costume.Attachments or {})
		}

		hg.Appearance.ForceApplyAppearance(ply, newIdentity)

		wep.IsCostumeActive = true

		net.Start("CultistSuitStatus")
			net.WriteBool(true)
		net.Send(ply)

		wep:EmitSound("snds_jack_gmod/equip" .. math.random(1, 5) .. ".wav")

		wep.StoredPluv = ply:GetNetVar("CurPluv", "pluv")
		ply:SetNetVar("CurPluv", "pluv51")
	end)
end

function SWEP:SecondaryAttack()
	if SERVER then
		local owner = self:GetOwner()
		if not IsValid(owner) then return end

		if self.IsCostumeActive and self.StoredIdentity then
			hg.Appearance.ForceApplyAppearance(owner, self.StoredIdentity)
			self:EmitSound("snds_jack_gmod/equip" .. math.random(1, 5) .. ".wav")

			self.IsCostumeActive = false

			net.Start("CultistSuitStatus")
				net.WriteBool(false)
			net.Send(owner)

			owner:SetNetVar("CurPluv", self.StoredPluv or "pluv")
		else
			net.Start("CultistSuitStatus")
				net.WriteBool(false)
			net.Send(owner)
		end
	end
end

function SWEP:Initialize()
	self:SetHold(self.HoldType)
	self.IsCostumeActive = false
end

function SWEP:PrimaryAttack()
	if self.CD and self.CD > CurTime() then return end

	if CLIENT then
		self:OpenCostumeMenu()
	end

	self.CD = CurTime() + 1.5
end

function SWEP:Reload()
end