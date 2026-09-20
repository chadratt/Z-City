MODE.name = "rampage"
MODE.PrintName = "Rampage"

MODE.ForBigMaps = false
MODE.ROUND_TIME = 300

MODE.Chance = 0.07


MODE.LootSpawn = true
MODE.LootOnTime = true

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
	{35,{
		{12,"weapon_hammer"},
		{6,"weapon_brick"},
		{10,"weapon_pocketknife"},
		{8,"weapon_kitchenknife"},

		{4,"weapon_bat"},
		{4,"weapon_batmetal"},
		{4,"weapon_leadpipe"},
		{3,"weapon_hg_extinguisher"},
		{3,"weapon_hg_wrench"},

		{15,"weapon_hg_crowbar"},
		{2.5,"weapon_hg_skateboard"},
		{2,"weapon_hg_cinderblock"},
		{1,"weapon_hatchet"},
		{5,"weapon_hg_axe"},
		{1.5,"weapon_hg_pitchfork"},
		{5,"weapon_hg_machete"},
		{5,"weapon_hg_sledgehammer"},
		{1,"weapon_eft_melee_taiga"},
		{1,"weapon_eft_melee_sp8"},
		{0.9,"weapon_eft_melee_a2607d"},
		{0.9,"weapon_eft_melee_a2607"},
		{0.9,"weapon_eft_melee_wycc"},
		{0.9,"weapon_eft_melee_6x5"},
		{0.8,"weapon_eft_melee_taran"},
		{0.7,"weapon_drill"},

		{25,"hg_brassknuckles"},
		{0.3,"weapon_hg_fubar"},
		{0.13,"weapon_hg_spear"},
		{0.13, "weapon_hg_spear_pro"},
		{0.25,"weapon_hg_chainsaw"},
		{0.08,"weapon_hg_fiberwire"},
	}},
	{11,{
		{10,"*sight*"},
		{7,"*barrel*"},

		{7,"ent_armor_helmet7"},
		{5,"ent_armor_vest7"},
		{8, "ent_armor_helmet2"},
	}},
	{40,{
		{6,"*sight*"},
		{5,"*barrel*"},

		{15,"weapon_mp-80"},
		{8,"weapon_makarov"},
		{7,"weapon_ruger"},
		{35,"weapon_revolver2"},
		{4,"weapon_px4beretta"},
		{10,"weapon_m1911"},
		{3,"weapon_m9beretta"},
		{2,"weapon_fn45"},
	}},
	{10, {
		{20,"weapon_hk_usp"},
		{10,"weapon_glock17"},
		{15,"weapon_cz75"},
		{9,"weapon_px4beretta"},

		{6,"weapon_deagle"},
		{6,"weapon_colt9mm"},

		{5,"weapon_doublebarrel_short"},
		{5,"weapon_doublebarrel"},
		{4, "weapon_flintlock"},
	}},
	{4,{
		{8,"ent_armor_vest3"},
		{6,"ent_armor_helmet1"},
		{2,"ent_armor_vest4"},
		{2, "ent_armor_helmet5"},
	}},
	{8, {
		{4,"weapon_remington870"},

		{4,"weapon_hg_molotov_tpik"},
		{4,"weapon_hg_pipebomb_tpik"},

		{3,"weapon_mini14"},
		{3,"weapon_kar98"},
		{3,"weapon_ar_pistol"},
		{3,"weapon_draco"},
		{3,"weapon_mp5"},
		{3,"weapon_m16a2"},

		{2,"weapon_mp7"},
		{2,"weapon_sks"},
		{2,"weapon_ar15"},
		{2,"weapon_ac556"},

		{1,"weapon_vpo136"},
		{1,"weapon_musket"},
		{1,"weapon_vpo136"},
		{1,"weapon_sr25"},
	}},
}

MODE.LootTableStandard = {
	{65, {
		{15,"weapon_smallconsumable"},
		{12,"weapon_bigconsumable"},
		{8,"weapon_tourniquet"},
		{8,"weapon_bandage_sh"},
		{7,"weapon_ducttape"},
		{6,"weapon_painkillers"},
		{5,"weapon_bloodbag"},
		{4,"hg_flashlight"},
		{1,"weapon_matches"},--for dumbasses
	}},
	{35, {
		{1,"weapon_hammer"},
		{1,"weapon_brick"},
		{1,"weapon_pocketknife"},
		{0.32,"weapon_bat"},
		{0.3,"weapon_leadpipe"},

		{0.15,"weapon_hg_extinguisher"},
		{0.14,"weapon_hg_crowbar"},

		{0.12,"weapon_hatchet"},
		{0.10,"weapon_hg_axe"},
		{0.09,"weapon_hg_sledgehammer"},
		{0.07,"weapon_hg_machete"},
	}},
}

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true--returning true so guilt bans
end

function shuffle(tbl)
	local len = #tbl
	for i = len, 2, -1 do
	  local j = math.random(i)
	  tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

function MODE:AssignTeams()
	local players = player.GetAll()
	local numPlayers = #players
	local numSWAT = 1

	shuffle(players)

	for i = 1, numSWAT do
		if IsValid(players[i]) then 
			players[i]:SetTeam(0)
		end
	end

	for i = numSWAT + 1, numPlayers do
		if IsValid(players[i]) then 
			players[i]:SetTeam(1)
		end
	end
end

util.AddNetworkString("rampage_start")
function MODE:Intermission()
	game.CleanUpMap()
    
    self:AssignTeams()
	
	for k, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR or ply:Team() == 0 then ply:KillSilent() continue end
		ply:SetupTeam(ply:Team())
	end

	net.Start("rampage_start")
	net.Broadcast()

end

function MODE:CheckAlivePlayers()
	local swatPlayers = {}
	local banditPlayers = {}

	for _, ply in ipairs(team.GetPlayers(0)) do
		if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
			table.insert(swatPlayers, ply)
		end
	end

	for _, ply in ipairs(team.GetPlayers(1)) do
		if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
			table.insert(banditPlayers, ply)
		end
	end

	return {swatPlayers, banditPlayers}
end

function MODE:ShouldRoundEnd()
	local aliveTeams = self:CheckAlivePlayers()
	local endround, winner = zb:CheckWinner(aliveTeams)
	return endround
end



function MODE:RoundStart()
    
end

local tblweps = {
	[0] = { 
		{"weapon_hk416", {} }, 
		{"weapon_ak74", {} },
		{"weapon_ak12", {} },
		{"weapon_ttibenelli", {} },
		{"weapon_mini30762", {} }
	},
	[1] = {
		{"weapon_mp-80", {} }
	}
}

local tblotheritems = {
	[0] = { 
		"weapon_medkit_sh", 
		"weapon_tourniquet",
		"weapon_walkie_talkie",
        "weapon_melee",
		"weapon_handcuffs",
		"weapon_hg_flashbang_tpik"
	},
	[1] = {}
}


local tblarmors = {
	[0] = { 
		{"ent_armor_vest1","ent_armor_mask1"} 
	},
	[1] = {}
}

function MODE:CanLaunch()
	local points = zb.GetMapPoints( "HMCD_TDM_CT" )
	local points2 = zb.GetMapPoints( "HMCD_TDM_T" )
	local plramount = zb:CheckPlaying()
    return (#points > 3) and (#points2 > 0) and (#plramount > 5)
end

function MODE:GiveEquipment()
	timer.Simple(0.5,function()
		local swatPlayers = {} 

		for i, ply in player.Iterator() do
			if ply:Team() == TEAM_SPECTATOR then continue end

			if ply:Team() == 0 then
					if !IsValid(ply) or ply:Team() == TEAM_SPECTATOR then return end
					ply:Spawn()
					ply:SetSuppressPickupNotices(true)
					ply.noSound = true

					ply:SetupTeam(ply:Team())

					ply:SetPlayerClass("terrorist")

					local inv = ply:GetNetVar("Inventory")
					inv["Weapons"]["hg_sling"] = true
					ply:SetNetVar("Inventory",inv)

					hg.AddArmor(ply, tblarmors[ply:Team()][math.random(#tblarmors[ply:Team()])]) 

					zb.GiveRole(ply, "Killer", Color(0,0,190))

					table.insert(swatPlayers, ply) 

					local wep = tblweps[ply:Team()][math.random(#tblweps[ply:Team()])]
					local gun = ply:Give(wep[1])
					if IsValid(gun) and gun.GetMaxClip1 then
						hg.AddAttachmentForce(ply,gun,wep[2])
						ply:GiveAmmo(gun:GetMaxClip1() * 3,gun:GetPrimaryAmmoType(),true)
					else
						print("WTH???")
					end

					local gun = ply:Give("weapon_glock17")
					if IsValid(gun) and gun.GetMaxClip1 then
						ply:GiveAmmo(gun:GetMaxClip1() * 3,gun:GetPrimaryAmmoType(),true)
					end

					for _, item in ipairs(tblotheritems[ply:Team()]) do
						ply:Give(item)
					end

					local hands = ply:Give("weapon_hands_sh")

					ply:SetSuppressPickupNotices(false)
					ply.noSound = false
			else
				ply:SetSuppressPickupNotices(true)
				ply.noSound = true

				ply:SetPlayerClass("default")

				zb.GiveRole(ply, "Civilian", Color(190,0,0))

				local hands = ply:Give("weapon_hands_sh")

				ply:SetSuppressPickupNotices(false)
				ply.noSound = false
			end

			timer.Simple(0.5,function()
				ply.noSound = false
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

function MODE:RoundThink()
    if not swatSpawned and (CurTime() - zb.ROUND_BEGIN) >= 130 then
        local deadPlayers = {}

        for _, ply in player.Iterator() do
            if not ply:Alive() and ply:Team() != TEAM_SPECTATOR then
                table.insert(deadPlayers, ply)
            end
        end

		local startpos = self.TPoints and #self.TPoints > 0 and self.TPoints[1].pos or zb:GetRandomSpawn()

		for i = 1, math.min(4, #deadPlayers) do
            local ply = deadPlayers[i]

            //if self.TPoints and #self.TPoints > 0 then
                ply:Spawn()
				ply:SetTeam(2)
				if !startpos then
					startpos = ply:GetPos()
				else
					hg.tpPlayer(startpos, ply, i, 0)
				end

                ply:SetPlayerClass("swat")
				zb.GiveRole(ply, "SWAT", Color(0,0,122))
				local gun = ply:Give("weapon_ar15")
                ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
                ply:Give("weapon_medkit_sh")
                ply:Give("weapon_tourniquet")
                ply:Give("weapon_walkie_talkie")
                ply:Give("weapon_hg_flashbang_tpik")
                hg.AddArmor(ply, "ent_armor_helmet1")
                hg.AddArmor(ply, "ent_armor_vest4")

                local hands = ply:Give("weapon_hands_sh")
                ply:SelectWeapon("weapon_hands_sh")
            //end
        end

        swatSpawned = true
    end
end

function MODE:GetTeamSpawn()
	return {zb:GetRandomSpawn()}, {zb:GetRandomSpawn()}
end

function MODE:CanSpawn()
end

util.AddNetworkString("rampage_end")
function MODE:EndRound()
	for k,ply in player.Iterator() do
		if timer.Exists("SWATSpawn"..ply:EntIndex()) then
			timer.Remove("SWATSpawn"..ply:EntIndex())
		end
	end
	if timer.Exists("SWATSpawn") then
		timer.Remove("SWATSpawn")
	end

	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())

	timer.Simple(2,function()
		net.Start("rampage_end")
			net.WriteBool(winner)
		net.Broadcast()
	end)

	for k,ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15,30))
			ply:GiveSkill(math.Rand(0.1,0.15))
		else
			ply:GiveSkill(-math.Rand(0.05,0.1))
		end
	end
end

function MODE:PlayerDeath(ply)
end