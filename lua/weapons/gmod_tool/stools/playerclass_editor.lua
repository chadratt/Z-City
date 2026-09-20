TOOL.Category = "ZBattle"
TOOL.Name = "Player Class Editor"


pcEditor = pcEditor or {}
pcEditor.Classes = pcEditor.Classes or {
	{ name = "Rebel",          class = "Rebel" },
	{ name = "National Guard", class = "nationalguard" },
	{ name = "Refugee",        class = "Refugee" },
	{ name = "SWAT",           class = "swat" },
	{ name = "Black Division",           class = "BLACK_DIVISION_TARKOV" },
}

TOOL.ClientConVar["class"] = pcEditor.Classes[1].class

local function IsValidClass(name)
	for _, v in ipairs(pcEditor.Classes) do
		if v.class == name then return true end
	end

	return false
end


function TOOL:LeftClick(trace)
	local ply = self:GetOwner()
	if not ply:IsAdmin() then
		ply:ChatPrint("You are a furry")
		return false
	end

	if SERVER then
		local class = ply:GetInfo(self:GetMode() .. "_class")
		if not IsValidClass(class) then
			ply:ChatPrint("Pick a valid class from the tool menu first")
			return false
		end

		local target = trace.Entity
		if IsValid(target) and target:IsPlayer() then
			target:SetPlayerClass(class)
			ply:ChatPrint(target:Name() .. " -> " .. class)
		end
	end

	return true
end


function TOOL:RightClick(trace)
	local ply = self:GetOwner()
	if not ply:IsAdmin() then
		ply:ChatPrint("You are a furry")
		return false
	end

	if SERVER then
		timer.Simple(0.1, function()
			if not IsValid(ply) then return end
			if ply:KeyDown(IN_ATTACK2) then return end 

			local pos = trace.HitPos
			local closest_distance = 250
			local closest_ply

			for i, target in player.Iterator() do
				local dist = target:GetPos():Distance(pos)
				if dist <= closest_distance then
					closest_distance = dist
					closest_ply = target
				end
			end

			if IsValid(closest_ply) then
				closest_ply:SetPlayerClass() 
				ply:ChatPrint(closest_ply:Name() .. "'s class was cleared")
			end
		end)
	end

	return true
end


function TOOL:Think()
	self.IsHolding = self.IsHolding or false

	local ply = self:GetOwner()

	if ply:KeyDown(IN_ATTACK2) then
		if not self.LastHold then self.LastHold = CurTime() end
		if not self.Trace1 then self.Trace1 = util.QuickTrace(ply:EyePos(), ply:EyeAngles():Forward() * 999999, ply) end
		if CurTime() - self.LastHold >= 0.1 then self.IsHolding = true end
	else
		if SERVER and self.IsHolding then
			local trace2 = util.QuickTrace(ply:EyePos(), ply:EyeAngles():Forward() * 1000, ply)
			local radius = self.Trace1.HitPos:Distance(trace2.HitPos)

			local class = ply:GetInfo(self:GetMode() .. "_class")
			if IsValidClass(class) then
				local count = 0

				for i, target in player.Iterator() do
					if self.Trace1.HitPos:Distance(target:GetPos()) <= radius then
						target:SetPlayerClass(class)
						count = count + 1
					end
				end

				ply:ChatPrint("Set " .. count .. " player(s) to " .. class)
			end
		end

		self.LastHold = nil
		self.IsHolding = false
		self.Trace1 = nil
	end
end

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {
		Description = "LMB: set the class of the player you're looking at\nRMB: clear the nearest player's class\nHold RMB and look around to grow a sphere, release to set every player inside it to the selected class"
	})

	local scroll = vgui.Create("DScrollPanel")
	scroll:Dock(TOP)
	scroll:SetTall(220)
	CPanel:AddItem(scroll)

	for _, v in ipairs(pcEditor.Classes) do
		local btn = vgui.Create("DButton", scroll)
		btn:Dock(TOP)
		btn:DockMargin(0, 0, 0, 4)
		btn:SetTall(30)
		btn:SetText(v.name)
		btn.DoClick = function()
			RunConsoleCommand("playerclass_editor_class", v.class)
		end
	end
end

function TOOL:Allowed()
	return self:GetOwner():IsAdmin()
end

function TOOL:Deploy()
	if SERVER then
		local ply = self:GetOwner()
		ply:ChatPrint("Player Class Editor equipped.")
	end
end

local red = Color(255, 0, 0, 100)
function TOOL:DrawHUD()
	local lply = LocalPlayer()
	if not lply:IsAdmin() then return end

	if not self.IsHolding or not self.Trace1 then return end

	local trace2 = util.QuickTrace(EyePos(), EyeAngles():Forward() * 1000, lply)
	local radius = self.Trace1.HitPos:Distance(trace2.HitPos)

	cam.Start3D()
		render.SetColorMaterial() 
		render.DrawSphere(self.Trace1.HitPos, radius, 50, 50, red)
	cam.End3D()


	for i, target in player.Iterator() do
		if not IsValid(target) or target == lply then continue end
		if self.Trace1.HitPos:Distance(target:GetPos()) > radius then continue end

		local data = (target:GetPos() + Vector(0, 0, 75)):ToScreen()
		draw.SimpleTextOutlined(target:Name(), "ChatFont", data.x, data.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
	end
end