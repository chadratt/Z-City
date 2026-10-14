local MODE = MODE

MODE.start_time = 10
MODE.ROUND_TIME = 300
MODE.Chance = 0.04
MODE.ForBigMaps = false
MODE.buymenu = false
MODE.Rounds = 2

util.AddNetworkString("hidden_start")
util.AddNetworkString("hidden_roundend")

function MODE:CanLaunch()
	local hiddenSpawns = zb.GetMapPoints("HMCD_TDM_T")
	local irisSpawns = zb.GetMapPoints("HMCD_TDM_CT")

	return hiddenSpawns ~= nil and irisSpawns ~= nil and #hiddenSpawns > 0 and #irisSpawns > 0
end

function MODE:OverrideBalance()
	local plys = {}

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		plys[#plys + 1] = ply
	end

	table.Shuffle(plys)

	local count = math.min(self.HiddenCount or 1, math.max(#plys - 1, 1))

	local last = self.LastHiddens or {}
	if #plys - table.Count(last) >= count then
		table.sort(plys, function(a, b)
			return (last[a] and 1 or 0) < (last[b] and 1 or 0)
		end)
	end

	self.LastHiddens = {}

	for i, ply in ipairs(plys) do
		ply:SetTeam(i <= count and 0 or 1)

		if i <= count then
			self.LastHiddens[ply] = true
		end
	end

	return true
end

function MODE:RoundStartPost()
	if (self.RoundsLeft or 0) > 1 then
		if zb.nextround and zb.nextround ~= self.name and zb.RoundList then
			table.insert(zb.RoundList, 1, zb.nextround)
		end

		NextRound(self.name)
	end
end

function MODE:Intermission()
	game.CleanUpMap()

	local continuing = (self.RoundsLeft or 0) > 0 and self.LastRoundCount == zb.Roundscount
	if not continuing then
		self.RoundsLeft = self.Rounds or 2
	end

	local total = self.Rounds or 2
	PrintMessage(HUD_PRINTTALK, "The Hidden: Round " .. (total - self.RoundsLeft + 1) .. " of " .. total)

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		ply:SetupTeam(ply:Team())
		ply:SetNWInt("TDM_Money", 0)
	end

	net.Start("hidden_start")
		net.WriteUInt(total - self.RoundsLeft + 1, 4)
	net.Broadcast()
end

util.AddNetworkString("hidden_combat")

local function NotifyCombat(ply)
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
	if (ply.HiddenCombatNet or 0) > CurTime() then return end
	ply.HiddenCombatNet = CurTime() + 1

	net.Start("hidden_combat")
	net.Send(ply)
end

function MODE:PreHomigradDamage(ent, dmgInfo)
	if not IsValid(ent) or dmgInfo:GetDamage() <= 0 then return end

	local victim = ent:IsPlayer() and ent or hg.RagdollOwner(ent)
	local attacker = dmgInfo:GetAttacker()

	if not IsValid(victim) or not victim:IsPlayer() then return end
	if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then return end

	NotifyCombat(victim)
	NotifyCombat(attacker)
end

local irisArmor = {"ent_armor_vest8", "ent_armor_helmet6"}

local irisItems = {
	"weapon_bigbandage_sh",
	"weapon_painkillers",
	"weapon_medkit_sh",
}

local irisPrimaries = {
	"weapon_remington870oiblyat",
	"weapon_sr25",
	"weapon_remingtonacr",
	"weapon_fn2000",
	"weapon_mk18",
	"weapon_f90ron",
	"weapon_sa58",
	"weapon_hk53",
}

local function PickPrimary()
	local available = {}

	for _, class in ipairs(irisPrimaries) do
		if weapons.GetStored(class) then
			available[#available + 1] = class
		end
	end

	return available[math.random(#available)]
end

local function GiveGun(ply, class)
	if not class or not weapons.GetStored(class) then return end

	local gun = ply:Give(class)
	if not IsValid(gun) then return end

	if gun.GetMaxClip1 and gun:GetMaxClip1() > 0 then
		ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
	end

	return gun
end

function MODE:GiveEquipment()
	timer.Simple(0.1, function()
		for _, ply in player.Iterator() do
			if not ply:Alive() then continue end

			local inv = ply:GetNetVar("Inventory")
			inv["Weapons"]["hg_sling"] = true
			ply:SetNetVar("Inventory", inv)

			ply:SetSuppressPickupNotices(true)
			ply.noSound = true

			local equip

			if ply:Team() == 0 then
				ply:SetPlayerClass("the_hidden")
				zb.GiveRole(ply, "The Hidden", Color(190, 0, 0))

				local knife = ply:Give("weapon_sogknife")
				equip = IsValid(knife) and "weapon_sogknife" or nil
			else
				ply:SetPlayerClass("swat")
				zb.GiveRole(ply, "I.R.I.S Soldier", Color(0, 120, 190))
				ply:SetNWString("PlayerName", "I.R.I.S " .. ((ply.CurAppearance and ply.CurAppearance.AName) or ply:Name()))

				hg.AddArmor(ply, irisArmor)

				local sidearm = GiveGun(ply, "weapon_p250")
				local primary = GiveGun(ply, PickPrimary())

				if IsValid(primary) then
					equip = primary:GetClass()
				elseif IsValid(sidearm) then
					equip = sidearm:GetClass()
				end

				for _, class in ipairs(irisItems) do
					ply:Give(class)
				end

				local Radio = ply:Give("weapon_walkie_talkie")
				if IsValid(Radio) then
					Radio.Frequency = math.Round(math.Rand(88, 95), 1)
				end
			end

			ply.organism.allowholster = true

			ply:Give("weapon_hands_sh")
			ply:SelectWeapon(equip or "weapon_hands_sh")

			if equip then
				timer.Simple(0.2, function()
					if IsValid(ply) and ply:Alive() and ply:HasWeapon(equip) then
						ply:SelectWeapon(equip)
					end
				end)
			end

			timer.Simple(0.1, function()
				if IsValid(ply) then ply.noSound = false end
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

function MODE:ShowSpare1(ply)
end

function MODE:EndRound()
	self.RoundsLeft = math.max((self.RoundsLeft or 1) - 1, 0)
	self.LastRoundCount = zb.Roundscount

	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())

	if not endround then
		local alive = self:CheckAlivePlayers()
		if alive[0] and #alive[0] > 0 then
			winner = 0
		end
	end

	timer.Simple(2, function()
		net.Start("hidden_roundend")
			net.WriteInt(winner or 3, 4)
		net.Broadcast()

		net.Start("tdm_roundend")
		net.Broadcast()
	end)

	for _, ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15, 30))
			ply:GiveSkill(math.Rand(0.1, 0.15))
		else
			ply:GiveSkill(-math.Rand(0.05, 0.1))
		end
	end
end

util.AddNetworkString("hidden_radar")

function MODE:Think()
	if (self.NextRadar or 0) > CurTime() then return end
	self.NextRadar = CurTime() + (self.RadarPulse or 3)

	local blips = {}
	local receivers = {}

	for _, ply in player.Iterator() do
		if not ply:Alive() then continue end

		local team_ = ply:Team()
		if team_ ~= 0 and team_ ~= 1 then continue end

		local chr = hg.GetCurrentCharacter(ply)
		blips[#blips + 1] = {
			index = ply:EntIndex(),
			pos = IsValid(chr) and chr:GetPos() or ply:GetPos(),
			hidden = team_ == 0,
		}

		if team_ == 1 then
			receivers[#receivers + 1] = ply
		end
	end

	if #receivers == 0 then return end

	local range = self.RadarRange or 1500
	local rangeSqr = range * range

	for _, receiver in ipairs(receivers) do
		local origin = receiver:GetPos()
		local visible = {}

		for _, blip in ipairs(blips) do
			if blip.hidden then
				local dx, dy = blip.pos.x - origin.x, blip.pos.y - origin.y
				if dx * dx + dy * dy > rangeSqr then continue end
			end

			visible[#visible + 1] = blip
		end

		net.Start("hidden_radar", true)
			net.WriteUInt(#visible, 8)
			for _, blip in ipairs(visible) do
				net.WriteUInt(blip.index, 8)
				net.WriteVector(blip.pos)
				net.WriteBool(blip.hidden)
			end
		net.Send(receiver)
	end
end
