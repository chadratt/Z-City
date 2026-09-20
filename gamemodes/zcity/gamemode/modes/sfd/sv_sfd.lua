local MODE = MODE

MODE.name = "superfighters"
MODE.PrintName = "Superfighters 3D"
MODE.LootSpawn = true
MODE.GuiltDisabled = true
MODE.randomSpawns = true
MODE.noBoxes = true

MODE.GuiltDisabled = true
MODE.ForBigMaps = false
MODE.Chance = 0.04

local radius = nil
local mapsize = 7500
-- MODE.MapSize = mapsize

util.AddNetworkString("supfight_start")
util.AddNetworkString("supfight_end")

function MODE:CanLaunch()
    return true//(zb.GetWorldSize() >= ZBATTLE_BIGMAP)
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

	local rndpoints = zb.GetMapPoints("RandomSpawns")
	zonepoint = table.Random(rndpoints)

	net.Start("supfight_start")
		net.WriteVector(zonepoint.pos)
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	local AlivePlyTbl = {
	}
	for _, ply in player.Iterator() do
		if not ply:Alive() then continue end
		if ply.organism and ply.organism.incapacitated then continue end
		AlivePlyTbl[#AlivePlyTbl + 1] = ply
	end
	return AlivePlyTbl
end

function MODE:ShouldRoundEnd()
	return (#zb:CheckAlive(true) <= 1)
end

function MODE:RoundStart()
	for _, ply in player.Iterator() do
		if not ply:Alive() then continue end
		ply:SetSuppressPickupNotices(true)
		ply.noSound = true
		local hands = ply:Give("weapon_hands_sh")

		local inv = ply:GetNetVar("Inventory")
		inv["Weapons"]["hg_sling"] = true
		ply:SetNetVar("Inventory",inv)

		ply:Give("weapon_walkie_talkie")

		ply:SelectWeapon("weapon_hands_sh")

		if ply.organism then
			ply.organism.recoilmul = 0.25
			ply.organism.superfighter = true
			ply.organism.berserk = 2
		end

		timer.Simple(0.1,function()
			ply.noSound = false
		end)

		ply:SetSuppressPickupNotices(false)
		zb.GiveRole(ply, "Superfighter", Color(190,15,15))
	end
end

function MODE:GiveWeapons()
end

function MODE:GiveEquipment()
end

MODE.LootTable = {
	{15, {
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
	{45,{
		{24,"weapon_hammer"},
		{12,"weapon_brick"},
		{20,"weapon_pocketknife"},
		{12,"weapon_kitchenknife"},

		{8,"weapon_bat"},
		{5,"weapon_batmetal"},
		{8,"weapon_leadpipe"},
		{6,"weapon_hg_extinguisher"},
		{4,"weapon_hg_wrench"},

		{6,"weapon_hg_crowbar"},
		{3,"weapon_hg_skateboard"},
		{2.4,"weapon_hg_cinderblock"},
		{3,"weapon_tomahawk"},
		{2,"weapon_hg_crossbow"},
		{2,"weapon_hatchet"},
		{1.8,"weapon_hg_axe"},
		{1.6,"weapon_hg_pitchfork"},
		{1.2,"weapon_eft_melee_taiga"},
		{1.2,"weapon_eft_melee_sp8"},
		{1,"weapon_eft_melee_a2607d"},
		{1,"weapon_eft_melee_a2607"},
		{1,"weapon_eft_melee_wycc"},
		{1,"weapon_eft_melee_6x5"},
		{1,"weapon_hg_machete"},
		{0.9,"weapon_eft_melee_taran"},
		{0.8,"weapon_hg_sledgehammer"},
		{0.7,"weapon_drill"},

		{0.4,"hg_brassknuckles"},
		{0.36,"weapon_hg_fubar"},
		{0.26,"weapon_hg_spear"},
		{0.26, "weapon_hg_spear_pro"},
		{0.24,"weapon_hg_chainsaw"},
		{0.06,"weapon_hg_fiberwire"},
	}},
	{8,{
		{10,"*sight*"},
		{7,"*barrel*"},

		{7,"ent_armor_helmet7"},
		{5,"ent_armor_vest7"},
		{8, "ent_armor_helmet2"},
	}},
	{16,{
		{6,"*sight*"},
		{5,"*barrel*"},

		{15,"weapon_mp-80"},
		{8,"weapon_makarov"},
		{7,"weapon_ruger"},
		{6,"weapon_revolver357"},
		{6,"weapon_glock18c"},
		{4,"weapon_revolver2"},
		{4,"weapon_px4beretta"},
		{3.5,"weapon_m1911"},
		{3,"weapon_m9beretta"},
		{2,"weapon_fn45"},
	}},
	{10, {
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
	{3,{
		{5,"ent_armor_vest3"},
		{5,"ent_armor_helmet1"},
		{2,"ent_armor_vest4"},
		{2, "ent_armor_helmet5"},
	}},
	{30, {
		{9,"*ammo*"},

		{4,"weapon_remington870"},
		{6,"weapon_xm1014"},

		{4,"weapon_hg_molotov_tpik"},
		{4,"weapon_hg_pipebomb_tpik"},
		{5,"weapon_claymore"},
		{5,"weapon_hg_f1_tpik"},
		{5,"weapon_traitor_ied"},
		{5,"weapon_hg_slam"},
		{5,"weapon_hg_legacy_grenade_shg"},
		{5,"weapon_hg_grenade_tpik"},

		{3,"weapon_mini14"},
		{3,"weapon_kar98"},
		{3,"weapon_ar_pistol"},
		{3,"weapon_draco"},
		{3,"weapon_mp5"},
		{3,"weapon_m16a2"},

		{5,"weapon_mp7"},
		{5,"weapon_sks"},
		{2,"weapon_ar15"},
		{2,"weapon_ac556"},

		{1,"weapon_vpo136"},
		{1,"weapon_musket"},
		{3,"weapon_sr25"},

		{5,"weapon_ptrd"},
		{5,"weapon_akm"},
		{5,"weapon_m98b"},
		{2,"weapon_hg_rpg"},
	}},
}

function MODE:RoundThink()
	if (self.nextBoxesThink or 0) < CurTime() then
		self.nextBoxesThink = CurTime() + 2

		hook.Run("Boxes Think")

		for _, ply in player.Iterator() do
			if not ply:Alive() then continue end
			if ply.organism then
				ply.organism.berserk = 2
			end
		end
	end
end

function MODE:PlayerDeath(ply)
end

function MODE:CanSpawn()
end

function MODE:EndRound()
	timer.Simple(2,function()
		net.Start("supfight_end")
		local ent = zb:CheckAlive(true)[1]
		net.WriteEntity(IsValid(ent) and ent:Alive() and ent or NULL)
		net.Broadcast()
	end)
end