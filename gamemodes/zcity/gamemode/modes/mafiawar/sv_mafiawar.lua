MODE.name = "mafiawars"
MODE.PrintName = "Mafia Wars"

MODE.ForBigMaps = false
MODE.ROUND_TIME = 215

MODE.Chance = 0.02

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

util.AddNetworkString("mafiawars_start")
function MODE:Intermission()
	game.CleanUpMap()

	self.CTPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_TDM_CT" ),self.CTPoints)
	self.TPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_TDM_T" ),self.TPoints)
	
	for i, ply in player.Iterator() do
		ply:SetupTeam(ply:Team())
	end

	net.Start("mafiawars_start")
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
		"weapon_ithaca37",
		"weapon_browninghp",
		"weapon_m1911",
		"weapon_thompson",
		"weapon_revolver2",
	},
	[1] = {
		"weapon_ithaca37",
		"weapon_browninghp",
		"weapon_m1911",
		"weapon_thompson",
		"weapon_revolver2",
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
		{}
	},
	[1] = {
		{}
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
				ply:SetPlayerClass("mafia")
				zb.GiveRole(ply, "Mafia", Color(190,0,0))
				ply:SetNetVar("CurPluv", "pluvred")
			else
				ply:SetPlayerClass("mafiapolice")
				zb.GiveRole(ply, "Police", Color(0,190,0))
				ply:SetNetVar("CurPluv", "pluvgreen")
			end

			local tbl = tblweps[ply:Team()]
			local wep = ply:Give(tbl[math.random(#tbl)])
			ply:GiveAmmo(wep:GetMaxClip1() * 3, wep:GetPrimaryAmmoType())

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
end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_T" )), zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_CT" ))
end

function MODE:CanSpawn()
end

util.AddNetworkString("mafiawars_roundend")
function MODE:EndRound()
	timer.Simple(2,function()
		net.Start("mafiawars_roundend")
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