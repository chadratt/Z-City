local MODE = MODE

MODE.name = "hitman"
MODE.PrintName = "Hitman"
MODE.LootSpawn = true
MODE.GuiltDisabled = false
MODE.randomSpawns = true

MODE.ForBigMaps = false
MODE.Chance = 0.03
MODE.ROUND_TIME = 600
MODE.MinPlayers = 10

MODE.EndLogicType = 2

util.AddNetworkString("hitman_start")
util.AddNetworkString("hitman_end")
util.AddNetworkString("hitman_briefing")
util.AddNetworkString("hitman_set_target")
util.AddNetworkString("hitman_dialogue")

MODE.LootTable = {
	{30, {
		{15, "weapon_smallconsumable"},
		{12, "weapon_bigconsumable"},
		{8, "weapon_tourniquet"},
		{8, "weapon_bandage_sh"},
		{7, "weapon_ducttape"},
		{6, "weapon_painkillers"},
		{5, "weapon_bloodbag"},
		{4, "weapon_walkie_talkie"},
		{3, "hg_flashlight"},
		{3, "weapon_bigbandage_sh"},
		{2, "weapon_medkit_sh"},

		{1, "weapon_matches"},

		{0.2, "weapon_morphine"},
		{0.2, "weapon_mannitol"},
		{0.5, "weapon_naloxone"},
		{0.1, "weapon_fentanyl"},
		{0.9, "weapon_betablock"},
		{0.5, "weapon_adrenaline"},

		{0.65, "ent_armor_mask2"},
		{0.27, "ent_armor_helmet2"},
	}},
	{35, {
		{24, "weapon_hammer"},
		{12, "weapon_brick"},
		{20, "weapon_pocketknife"},
		{12, "weapon_kitchenknife"},

		{8, "weapon_bat"},
		{5, "weapon_batmetal"},
		{8, "weapon_leadpipe"},
		{6, "weapon_hg_extinguisher"},
		{4, "weapon_hg_wrench"},

		{4, "weapon_hg_crowbar"},
		{3, "weapon_hg_skateboard"},
		{2.4, "weapon_hg_cinderblock"},
		{2, "weapon_hatchet"},
		{1.8, "weapon_hg_axe"},
		{1.6, "weapon_hg_pitchfork"},
		{1.2, "weapon_eft_melee_taiga"},
		{1.2, "weapon_eft_melee_sp8"},
		{1, "weapon_eft_melee_a2607d"},
		{1, "weapon_eft_melee_a2607"},
		{1, "weapon_eft_melee_wycc"},
		{1, "weapon_eft_melee_6x5"},
		{1, "weapon_hg_machete"},
		{0.9, "weapon_eft_melee_taran"},
		{0.8, "weapon_hg_sledgehammer"},
		{0.7, "weapon_drill"},

		{0.4, "hg_brassknuckles"},
		{0.36, "weapon_hg_fubar"},
		{0.26, "weapon_hg_spear"},
		{0.26, "weapon_hg_spear_pro"},
		{0.24, "weapon_hg_chainsaw"},
		{0.06, "weapon_hg_fiberwire"},
	}},
	{11, {
		{10, "*sight*"},
		{7, "*barrel*"},

		{7, "ent_armor_helmet7"},
		{5, "ent_armor_vest7"},
		{8, "ent_armor_helmet2"},
	}},
	{22, {
		{12, "*sight*"},
		{10, "*barrel*"},

		{30, "weapon_mp-80"},
		{16, "weapon_makarov"},
		{14, "weapon_ruger"},
		{8, "weapon_revolver2"},
		{8, "weapon_px4beretta"},
		{7, "weapon_m1911"},
		{6, "weapon_m9beretta"},
		{4, "weapon_fn45"},
	}},
	{15, {
		{18, "weapon_hk_usp"},
		{18, "weapon_glock17"},
		{18, "weapon_cz75"},
		{18, "weapon_px4beretta"},

		{12, "weapon_deagle"},
		{12, "weapon_colt9mm"},

		{10, "weapon_doublebarrel_short"},
		{10, "weapon_doublebarrel"},
		{8, "weapon_flintlock"},
	}},
	{4, {
		{5, "ent_armor_vest3"},
		{5, "ent_armor_helmet1"},
		{2, "ent_armor_vest4"},
		{2, "ent_armor_helmet5"},
	}},
	{6, {
		{8, "weapon_remington870"},

		{8, "weapon_hg_molotov_tpik"},
		{8, "weapon_hg_pipebomb_tpik"},

		{6, "weapon_mini14"},
		{6, "weapon_kar98"},
		{6, "weapon_ar_pistol"},
		{6, "weapon_draco"},
		{6, "weapon_mp5"},
		{6, "weapon_m16a2"},

		{4, "weapon_mp7"},
		{4, "weapon_sks"},
		{4, "weapon_ar15"},
		{4, "weapon_ac556"},

		{2, "weapon_vpo136"},
		{2, "weapon_musket"},
		{2, "weapon_vpo136"},
		{2, "weapon_sr25"},
	}},
}

local HitmanTargets = {}
local HitmanRing    = {}
local HitmanDuel    = false

local function IsHitmanActive()
	return (zb.CROUND_MAIN or zb.CROUND) == "hitman"
end

function MODE:SetupChances()
	local saved = zb.ModesChances[self.name]
	if saved == nil or saved == 0 then
		zb.ModesChances[self.name] = self.Chance
	end
end

local WRONG_KILL_LINES = {
	"What the hell are you doing?",
	"Wrong Target.",
	"Stop shooting the wrong target!",
	"Fucking idiot. Stop shooting the wrong target!",
}

local IDLE_LINES = {
	"What are you doing? get to murdering!",
	"What are you fucking around? get to killing!",
	"Im not gonna sit here and watch some asshole do nothing. Kill your target or else im gonna kill you myself!",
	"Get to killing you idiot.",
	"I didnt let all these good people pay to see someone fuck around. Kill. Your. Target.",
}

local IDLE_TIME       = 60
local ATTACKER_MEMORY = 60

local function SendDialogue(ply, lines)
	if not IsValid(ply) then return end
	net.Start("hitman_dialogue")
		net.WriteString(lines[math.random(#lines)])
	net.Send(ply)
end

local function ResolvePlayer(ent)
	if not IsValid(ent) then return nil end
	if ent:IsPlayer() then return ent end
	if hg and hg.RagdollOwner then
		local owner = hg.RagdollOwner(ent)
		if IsValid(owner) and owner:IsPlayer() then return owner end
	end
	return nil
end

local function ResolveAttacker(dmgInfo)
	local att = ResolvePlayer(dmgInfo:GetAttacker())
	if IsValid(att) then return att end

	local inf = dmgInfo:GetInflictor()
	if IsValid(inf) then
		if inf:IsPlayer() then return inf end
		if inf.GetOwner then
			local owner = inf:GetOwner()
			if IsValid(owner) and owner:IsPlayer() then return owner end
		end
	end

	return nil
end

local function RecordAttacker(victimEnt, dmgInfo)
	if not IsHitmanActive() or zb.ROUND_STATE ~= 1 then return end

	local victim = ResolvePlayer(victimEnt)
	if not IsValid(victim) then return end

	local att = ResolveAttacker(dmgInfo)
	if IsValid(att) and att ~= victim then
		victim.hitman_lastAttacker     = att
		victim.hitman_lastAttackerTime = CurTime()
	end
end

hook.Add("EntityTakeDamage", "hitman_track_attacker", function(ent, dmgInfo)
	RecordAttacker(ent, dmgInfo)
end)

hook.Add("HomigradDamage", "hitman_track_attacker", function(ply, dmgInfo)
	RecordAttacker(ply, dmgInfo)
end)

local function ResolveKiller(victim, attacker)
	if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
		return attacker
	end

	local last = victim.hitman_lastAttacker
	if IsValid(last) and last ~= victim and (CurTime() - (victim.hitman_lastAttackerTime or 0)) <= ATTACKER_MEMORY then
		return last
	end

	return nil
end

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	if HitmanTargets[Attacker] == Victim then return 0 end
	if HitmanTargets[Victim] == Attacker then return 0 end
	return 1
end

local function CountPlaying()
	local n = 0
	for _, ply in player.Iterator() do
		if ply:Team() ~= TEAM_SPECTATOR then n = n + 1 end
	end
	return n
end

function MODE:CanLaunch()
	return CountPlaying() >= (self.MinPlayers or 3)
end

function MODE:Intermission()
	game.CleanUpMap()

	HitmanTargets = {}
	HitmanRing    = {}
	HitmanDuel    = false

	for k, ply in player.Iterator() do
		ply.won = nil

		if ply:Team() == TEAM_SPECTATOR then
			continue
		end

		ApplyAppearance(ply, nil, nil, nil, true)
		ply:SetupTeam(0)
	end

	net.Start("hitman_start")
	net.Broadcast()
end

function MODE:ShouldRoundEnd()
	return #zb:CheckAlive() <= 1
end

local function SendTargetToPlayer(ply)
	if not IsValid(ply) then return end
	local target = HitmanTargets[ply]
	net.Start("hitman_set_target")
		net.WriteEntity(IsValid(target) and target or NULL)
		net.WriteBool(HitmanDuel and IsValid(target))
	net.Send(ply)
end

local function RecalcTargets(exclude)
	local living = {}
	for _, p in ipairs(HitmanRing) do
		if IsValid(p) and p ~= exclude and p:Alive() then
			living[#living + 1] = p
		end
	end

	local newTargets = {}
	local n = #living
	if n >= 2 then
		for i = 1, n do
			newTargets[living[i]] = living[(i % n) + 1]
		end
	end

	local old = HitmanTargets
	HitmanTargets = newTargets

	local duel     = (n == 2)
	local duelFlip = (duel ~= HitmanDuel)
	HitmanDuel = duel

	for hunter, tgt in pairs(newTargets) do
		if duelFlip or old[hunter] ~= tgt then SendTargetToPlayer(hunter) end
	end

	for hunter in pairs(old) do
		if IsValid(hunter) and newTargets[hunter] == nil then
			SendTargetToPlayer(hunter)
		end
	end
end

function MODE:RoundStart()
	HitmanTargets = {}
	HitmanRing    = {}
	HitmanDuel    = false

	local players = {}
	for _, ply in player.Iterator() do
		ply.won = nil
		ply.hitman_firstTarget     = nil
		ply.hitman_idleAt          = nil
		ply.hitman_lastAttacker     = nil
		ply.hitman_lastAttackerTime = nil
		if ply:Team() == TEAM_SPECTATOR or not ply:Alive() then continue end
		players[#players + 1] = ply
	end

	for i = #players, 2, -1 do
		local j = math.random(1, i)
		players[i], players[j] = players[j], players[i]
	end

	HitmanRing = players

	for _, ply in ipairs(players) do
		ply:SetSuppressPickupNotices(true)
		ply.noSound = true
		ply:Give("weapon_hands_sh")
		ply:SelectWeapon("weapon_hands_sh")

		timer.Simple(0.1, function()
			if IsValid(ply) then ply.noSound = false end
		end)

		ply:SetSuppressPickupNotices(false)

		zb.GiveRole(ply, GetGlobalString("ZB_EventRole", "Hitman"), Color(165, 35, 35))

		net.Start("hitman_briefing")
		net.Send(ply)
	end

	timer.Simple(0.5, function()
		if not IsHitmanActive() or zb.ROUND_STATE ~= 1 then return end
		HitmanTargets = {}
		HitmanDuel    = false
		RecalcTargets()

		for hunter, tgt in pairs(HitmanTargets) do
			hunter.hitman_firstTarget = tgt
			hunter.hitman_idleAt      = CurTime() + IDLE_TIME
		end
	end)
end

function MODE:GiveWeapons()
end

function MODE:GiveEquipment()
end

function MODE:RoundThink()
	local now = CurTime()

	for _, ply in player.Iterator() do
		if not ply.hitman_idleAt or now < ply.hitman_idleAt then continue end

		ply.hitman_idleAt = nil

		local first = ply.hitman_firstTarget
		if ply:Alive() and IsValid(first) and first:Alive() then
			SendDialogue(ply, IDLE_LINES)
		end
	end
end

function MODE:PlayerDeath(victim, inflictor, attacker)
	if zb.ROUND_STATE ~= 1 then return end
	if not IsValid(victim) then return end

	local killer = ResolveKiller(victim, attacker)

	if IsValid(killer) and killer:Alive()
		and HitmanTargets[killer] ~= victim
		and HitmanTargets[victim] ~= killer then
		SendDialogue(killer, WRONG_KILL_LINES)
	end

	RecalcTargets(victim)

	victim.hitman_lastAttacker     = nil
	victim.hitman_lastAttackerTime = nil
end

hook.Add("PlayerDisconnected", "hitman_disconnect", function(ply)
	if not IsHitmanActive() or zb.ROUND_STATE ~= 1 then return end
	RecalcTargets(ply)
end)

hook.Add("SetupPlayerVisibility", "hitman_target_pvs", function(ply)
	if not IsHitmanActive() or zb.ROUND_STATE ~= 1 then return end
	local target = HitmanTargets[ply]
	if not (IsValid(target) and target:Alive()) then return end

	local char = hg and hg.GetCurrentCharacter and hg.GetCurrentCharacter(target) or target
	if not IsValid(char) then char = target end
	AddOriginToPVS(char:GetPos())
end)

function MODE:CanSpawn()
end

function MODE:EndRound()
	HitmanTargets = {}
	HitmanRing    = {}
	HitmanDuel    = false

	timer.Simple(2, function()
		net.Start("hitman_end")
		local ent = zb:CheckAlive()[1]
		net.WriteEntity(IsValid(ent) and ent:Alive() and ent or NULL)
		net.Broadcast()
	end)
end

concommand.Add("zb_hitman_name", function(ply, _, _, args)
	if IsValid(ply) and not ply:IsAdmin() then return end
	SetGlobalString("ZB_EventName", args)
end)

concommand.Add("zb_hitman_role", function(ply, _, _, args)
	if IsValid(ply) and not ply:IsAdmin() then return end
	SetGlobalString("ZB_EventRole", args)
end)

concommand.Add("zb_hitman_objective", function(ply, _, _, args)
	if IsValid(ply) and not ply:IsAdmin() then return end
	SetGlobalString("ZB_EventObjective", args)
end)

concommand.Add("zb_hitman_end", function(ply, _, _, _)
	if IsValid(ply) and not ply:IsAdmin() then return end

	local function msg(t) if IsValid(ply) then ply:ChatPrint(t) else print(t) end end

	if IsHitmanActive() and zb.ROUND_STATE == 1 then
		zb:EndRound()
		msg("Ending the hitman round...")
	else
		msg("No hitman round is currently active.")
	end
end)
