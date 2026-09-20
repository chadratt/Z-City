local MODE = MODE

MODE.name = "hitman"
MODE.PrintName = "Hitman"
MODE.LootSpawn = true
MODE.GuiltDisabled = true
MODE.randomSpawns = true

MODE.ForBigMaps = true
MODE.Chance = 0

MODE.EndLogicType = 2

util.AddNetworkString("hitman_start")
util.AddNetworkString("hitman_end")
util.AddNetworkString("hitman_briefing")
util.AddNetworkString("hitman_set_target")   






MODE.LootTable = {
	{35, {
		{15,"weapon_smallconsumable"},
		{12,"weapon_bigconsumable"},
		{8,"weapon_tourniquet"},
		{8,"weapon_bandage_sh"},
		{7,"weapon_ducttape"},
		{6,"weapon_painkillers"},
		{5,"weapon_bloodbag"},
		{4,"weapon_walkie_talkie"},
		{3,"hg_flashlight"},
		{3,"weapon_bigbandage_sh"},
		{2,"weapon_medkit_sh"},

		{1,"weapon_matches"},

		{0.2,"weapon_morphine"},
		{0.2,"weapon_mannitol"},
		{0.5,"weapon_naloxone"},
		{0.1,"weapon_fentanyl"},
		{0.9,"weapon_betablock"},
		{0.5,"weapon_adrenaline"},

		{0.65,"ent_armor_mask2"},
		{0.27, "ent_armor_helmet2"},
	}},
	{27,{
		{12,"weapon_hammer"},
		{6,"weapon_brick"},
		{10,"weapon_pocketknife"},

		{4,"weapon_bat"},
		{4,"weapon_leadpipe"},
		{3,"weapon_hg_extinguisher"},

		{2,"weapon_hg_crowbar"},
		{1,"weapon_hatchet"},
		{0.9,"weapon_hg_axe"},
		{0.5,"weapon_hg_machete"},
		{0.4,"weapon_hg_sledgehammer"},

		{0.2,"hg_brassknuckles"},
		{0.13,"weapon_hg_spear"},
		{0.13, "weapon_hg_spear_pro"},
	}},
	{11,{
		{10,"*sight*"},
		{7,"*barrel*"},

		{7,"ent_armor_helmet7"},
		{5,"ent_armor_vest7"},
		{8, "ent_armor_helmet2"},
	}},
	{17,{
		{6,"*sight*"},
		{5,"*barrel*"},

		{15,"weapon_mp-80"},
		{8,"weapon_makarov"},
		{7,"weapon_ruger"},
		{4,"weapon_revolver2"},
		{4,"weapon_px4beretta"},
		{3.5,"weapon_m1911"},
		{3,"weapon_m9beretta"},
		{2,"weapon_fn45"},
	}},
	{6, {
		{9,"weapon_hk_usp"},
		{9,"weapon_glock17"},
		{9,"weapon_cz75"},
		{9,"weapon_px4beretta"},

		{6,"weapon_deagle"},
		{6,"weapon_colt9mm"},

		{5,"weapon_doublebarrel_short"},
		{5,"weapon_doublebarrel"},
		{4, "weapon_flintlock"},
	}},
	{8,{
		{5,"ent_armor_vest3"},
		{5,"ent_armor_helmet1"},
		{2,"ent_armor_vest4"},
		{2, "ent_armor_helmet5"},
	}},
	{2, {
		{4,"weapon_remington870"},

		{4,"weapon_hg_molotov_tpik"},

		{3,"weapon_mini14"},
		{3,"weapon_kar98"},
		{3,"weapon_ar_pistol"},
		{3,"weapon_draco"},
		{3,"weapon_mp5"},
		{3,"weapon_m16a2"},

		{1,"weapon_vpo136"},
		{1,"weapon_musket"},
		{1,"weapon_vpo136"},
		{1,"weapon_sr25"},
	}},
}




local HitmanTargets = {}
local HITMAN_WRONG_KILL_KARMA = 15      
local ATTACKER_MEMORY         = 12      




hook.Add("EntityTakeDamage", "hitman_track_attacker", function(ent, dmgInfo)
	if (zb.CROUND_MAIN or zb.CROUND) ~= "hitman" then return end
	if zb.ROUND_STATE ~= 1 then return end
	if not (IsValid(ent) and ent:IsPlayer()) then return end

	local att = dmgInfo:GetAttacker()
	if not (IsValid(att) and att:IsPlayer()) then
		local inf = dmgInfo:GetInflictor()
		if IsValid(inf) and inf.GetOwner then
			local owner = inf:GetOwner()
			if IsValid(owner) and owner:IsPlayer() then att = owner end
		end
	end

	if IsValid(att) and att:IsPlayer() and att ~= ent then
		ent.hitman_lastAttacker     = att
		ent.hitman_lastAttackerTime = CurTime()
	end
end)



local function ResolveKiller(victim, attacker)
	if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
		return attacker
	end

	local la = victim.hitman_lastAttacker
	local lt = victim.hitman_lastAttackerTime or 0
	if IsValid(la) and la:IsPlayer() and la ~= victim and (CurTime() - lt) <= ATTACKER_MEMORY then
		return la
	end

	return nil
end


local function ApplyWrongKillPenalty(ply)
	if not (IsValid(ply) and ply:IsPlayer()) then return end

	local before = ply.Karma or 100
	ply.Karma = math.Clamp(before - HITMAN_WRONG_KILL_KARMA, -60, zb.MaxKarma or 120)
	ply:SetNetVar("Karma", ply.Karma)

	ply:ChatPrint(string.format(
		"You killed the wrong target! Karma %d (-%d)",
		math.Round(ply.Karma), math.Round(before - ply.Karma)))
end

function MODE:CanLaunch()
	return true
end

function MODE:Intermission()
	game.CleanUpMap()

	for k, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then
			continue
		end

		ApplyAppearance(ply)
		ply:SetupTeam(0)
	end

	net.Start("hitman_start")
	net.Broadcast()
end

function MODE:ShouldRoundEnd()
	return (#zb:CheckAlive(true) <= 2)
end






local function BuildTargetAssignments(players)
	local n = #players
	if n < 2 then return {} end

	
	local order = {}
	for i, v in ipairs(players) do order[i] = v end
	for i = n, 2, -1 do
		local j = math.random(1, i)
		order[i], order[j] = order[j], order[i]
	end

	local assignments = {}
	for i = 1, n do
		assignments[order[i]] = order[(i % n) + 1]
	end
	return assignments
end


local function SendTargetToPlayer(ply)
	local target = HitmanTargets[ply]
	net.Start("hitman_set_target")
		if IsValid(target) then
			net.WriteEntity(target)
		else
			net.WriteEntity(NULL)
		end
	net.Send(ply)
end


local function FindHunterOf(ply)
	for hunter, target in pairs(HitmanTargets) do
		if IsValid(hunter) and target == ply then
			return hunter
		end
	end
	return nil
end




local function NextLivingInChain(start, avoid)
	local node  = start
	local guard = 0
	while guard < 128 do
		if not IsValid(node) then return nil end
		if node ~= avoid and node:Alive() then return node end
		node  = HitmanTargets[node]
		guard = guard + 1
	end
	return nil
end

function MODE:RoundStart()
	HitmanTargets = {}

	local alive = zb:CheckAlive(true)
	local assignments = BuildTargetAssignments(alive)

	for hunter, target in pairs(assignments) do
		HitmanTargets[hunter] = target
	end

	for _, ply in player.Iterator() do
		if not ply:Alive() then continue end

		ply:SetSuppressPickupNotices(true)
		ply.noSound = true
		local hands = ply:Give("weapon_hands_sh")
		ply:SelectWeapon("weapon_hands_sh")

		timer.Simple(0.1, function()
			ply.noSound = false
		end)

		ply:SetSuppressPickupNotices(false)

		zb.GiveRole(ply, GetGlobalString("ZB_EventRole", "Hitman"), Color(190, 15, 15))

		net.Start("hitman_briefing")
		net.Send(ply)
	end

	
	timer.Simple(0.5, function()
		for _, ply in player.Iterator() do
			if not ply:Alive() then continue end
			SendTargetToPlayer(ply)
		end
	end)
end

function MODE:GiveWeapons()
end

function MODE:GiveEquipment()
end

function MODE:RoundThink()
end





function MODE:PlayerDeath(victim, inflictor, attacker)
	if zb.ROUND_STATE ~= 1 then return end

	
	
	
	local killer            = ResolveKiller(victim, attacker)
	local killerTargetBefore = IsValid(killer) and HitmanTargets[killer] or nil

	
	local hunter        = FindHunterOf(victim)
	local victimsTarget = HitmanTargets[victim]

	
	HitmanTargets[victim] = nil

	if IsValid(hunter) and hunter ~= victim then
		
		
		local newTarget = NextLivingInChain(victimsTarget, hunter)

		HitmanTargets[hunter] = (IsValid(newTarget) and newTarget) or nil

		if hunter:Alive() then
			SendTargetToPlayer(hunter)
		end
	end

	
	
	if IsValid(killer) and killer:IsPlayer() and killer ~= victim
		and killerTargetBefore ~= victim then
		ApplyWrongKillPenalty(killer)
	end

	victim.hitman_lastAttacker     = nil
	victim.hitman_lastAttackerTime = nil
end

function MODE:CanSpawn()
end

function MODE:EndRound()
	HitmanTargets = {}

	timer.Simple(2, function()
		net.Start("hitman_end")
		local ent = zb:CheckAlive(true)[1]
		net.WriteEntity(IsValid(ent) and ent:Alive() and ent or NULL)
		net.Broadcast()
	end)
end

concommand.Add("zb_hitman_name", function(ply, _, _, args)
	if not ply:IsAdmin() then return end
	SetGlobalString("ZB_EventName", args)
end)

concommand.Add("zb_hitman_role", function(ply, _, _, args)
	if not ply:IsAdmin() then return end
	SetGlobalString("ZB_EventRole", args)
end)

concommand.Add("zb_hitman_objective", function(ply, _, _, args)
	if not ply:IsAdmin() then return end
	SetGlobalString("ZB_EventObjective", args)
end)

concommand.Add("zb_hitman_end", function(ply, _, _, _)
	if not ply:IsAdmin() then return end

	if zb.ROUND_PLAYING then
		MODE:EndRound()
		ply:ChatPrint("Ending the hitman round...")
	else
		ply:ChatPrint("No hitman round is currently active.")
	end
end)