MODE.name = "worldwar2"
MODE.PrintName = "World War 2 TDM"

MODE.ForBigMaps = false
MODE.ROUND_TIME = 300

MODE.Chance = 0.01

MODE.OverideSpawnPos = true
MODE.LootSpawn = false

function MODE:CanLaunch()
	return true
	--[[local points = zb.GetMapPoints( "HMCD_TDM_T" )
	local points2 = zb.GetMapPoints( "HMCD_TDM_CT" )
    return (#points > 0) and (#points2 > 0)--]]
end

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true--returning true so guilt bans
end

util.AddNetworkString("ww2_start")
function MODE:Intermission()
	game.CleanUpMap()

	self.CTPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_TDM_CT" ),self.CTPoints)
	self.TPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_TDM_T" ),self.TPoints)
	
	for i, ply in player.Iterator() do
		ply:SetupTeam(ply:Team())
	end

	net.Start("ww2_start")
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	return zb:CheckAliveTeams(true)
end

function MODE:ShouldRoundEnd()
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())

	return endround or boringround
end

function MODE:BoringRoundFunction()		
	timer.Simple(2, function()
		//PrintMessage(HUD_PRINTTALK, "IT IS A GANG SHOOTOUT FFS...")
	end)
end

local swatSpawned = false

function MODE:RoundStart()
    swatSpawned = false 
end

local tblweps = {
	[0] = {
		"weapon_m3greasegun",
		"weapon_thompson",
		"weapon_m1911",
	},
	[1] = {
		"weapon_mp40",
		"weapon_mg34",
		"weapon_m712",
		"weapon_p38",
	}
}


--[[local tblatts = {
	[0] = {
		{"optic4"},
	},
	[1] = {
		{"holo14","laser2","grip3"}
	}
}]]

local tblarmors = {
	[0] = {
		{"ent_armor_helmet2"}
	},
	[1] = {
		{"ent_armor_helmet1"}
	}
}

function MODE:GetPlySpawn(ply)
end

function MODE:GiveEquipment()
	self.CTPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_TDM_CT" ),self.CTPoints)
	self.TPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_TDM_T" ),self.TPoints)
	timer.Simple(0.1,function()
		local teamArmorCount = { [0] = 0, [1] = 0 } 

		for _, ply in player.Iterator() do
			if not ply:Alive() then continue end
			ply:SetSuppressPickupNotices(true)
			ply.noSound = true

			if ply:Team() == 0 then
				ply:SetPlayerClass("americanww2")
				zb.GiveRole(ply, "American", Color(190,0,0))
				ply:SetNetVar("CurPluv", "pluvred")
			else
				ply:SetPlayerClass("germanww2")
				zb.GiveRole(ply, "German", Color(0,190,0))
				ply:SetNetVar("CurPluv", "pluvgreen")
			end

			local tbl = tblweps[ply:Team()]
			local wep = ply:Give(tbl[math.random(#tbl)])
			ply:GiveAmmo(wep:GetMaxClip1() * 3, wep:GetPrimaryAmmoType())

			if wep.SetDeagleSkin then
				//wep:SetDeagleSkin(4)
				//wep:SetDeagleBodygroup(1)
			end

			ply:Give("weapon_bandage_sh")
			ply:Give("weapon_tourniquet")

			local hands = ply:Give("weapon_hands_sh")
			ply:SelectWeapon("weapon_hands_sh")

			timer.Simple(0.1,function()
				ply.noSound = false
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

function MODE:RoundThink()
    if not swatSpawned and (CurTime() - zb.ROUND_BEGIN) >= 180 then
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

                ply:SetPlayerClass("germanww2")
				zb.GiveRole(ply, "German", Color(0,0,122))
				local gun = ply:Give("weapon_mp40")
                ply:GiveAmmo(gun:GetMaxClip1() * 4, gun:GetPrimaryAmmoType(), true)
                ply:Give("weapon_medkit_sh")
                ply:Give("weapon_tourniquet")
                ply:Give("weapon_walkie_talkie")
                ply:Give("weapon_hg_flashbang_tpik")
				ply:Give("weapon_hg_rgd_tpik")
                hg.AddArmor(ply, "ent_armor_helmet1")

                local hands = ply:Give("weapon_hands_sh")
                ply:SelectWeapon("weapon_hands_sh")
            //end
        end

        swatSpawned = true
    end
end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_T" )), zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_CT" ))
end

function MODE:CanSpawn()
end

util.AddNetworkString("gwars_roundend")
function MODE:EndRound()
	timer.Simple(2,function()
		net.Start("gwars_roundend")
		net.Broadcast()
	end)

	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	for k,ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15,30))
			ply:GiveSkill(math.Rand(0.1,0.15))
			--print("give",ply)
		else
			--print("take",ply)
			ply:GiveSkill(-math.Rand(0.05,0.1))
		end
	end
end

function MODE:PlayerDeath(ply)
end