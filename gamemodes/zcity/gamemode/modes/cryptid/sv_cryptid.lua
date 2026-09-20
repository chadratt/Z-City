MODE.name = "cryptidhns"
MODE.PrintName = "Cryptid hide and seek"

MODE.ForBigMaps = false
MODE.ROUND_TIME = 480

MODE.randomSpawns = true
MODE.OverrideSpawn = true

MODE.LootSpawn = true
MODE.LootOnTime = true

MODE.Chance = 0.01

function MODE:CanLaunch()
    return false
end

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true
end

function shuffle(tbl)
	local len = #tbl
	for i = len, 2, -1 do
	  local j = math.random(i)
	  tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

-- ONLY 1 SWAT NOW
function MODE:AssignTeams()
	local players = player.GetAll()
	local numPlayers = #players

	local swatIndex = math.random(numPlayers)

	for i = 1, numPlayers do
		if IsValid(players[i]) then
			if i == swatIndex then
				players[i]:SetTeam(0) -- SWAT (1 player only)
			else
				players[i]:SetTeam(1) -- criminals
			end
		end
	end
end

util.AddNetworkString("cryptid_start")
function MODE:Intermission()
	game.CleanUpMap()
    
    self:AssignTeams()

	for k, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then ply:KillSilent() continue end
		ply:SetupTeam(ply:Team())
	end

	net.Start("cryptid_start")
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
	if zb.ROUND_START + 91 > CurTime() then return end
	local aliveTeams = self:CheckAlivePlayers()
	local endround, winner = zb:CheckWinner(aliveTeams)
	return endround
end

function MODE:RoundStart()
end

local tblarmors = {
	[0] = {{"ent_armor_vest8","ent_armor_helmet6"}},
	[1] = {{"ent_armor_vest8","ent_armor_helmet6"}}
}

function MODE:GiveEquipment()
	timer.Simple(0.5, function()

		for _, ply in player.Iterator() do
			if ply:Team() == TEAM_SPECTATOR then continue end


			if ply:Team() == 0 then

				ply:SetSuppressPickupNotices(true)
				ply.noSound = true


				ply:SetPlayerClass("default")
				zb.GiveRole(ply, "SWAT", Color(0,0,190))


				timer.Simple(90, function()
					if not IsValid(ply) then return end
					if ply:Team() ~= 0 then return end

					ply:SetPlayerClass("MEAT")
				end)
				
				ply:Give("weapon_hands_sh")

				ply:SetSuppressPickupNotices(false)
				ply.noSound = false


			else
				ply:SetSuppressPickupNotices(true)
				ply.noSound = true

				ply:SetPlayerClass("default")
				zb.GiveRole(ply, "Suspect", Color(190,0,0))

				ply:Give("weapon_hands_sh")

				ply:SetSuppressPickupNotices(false)
				ply.noSound = false
			end

			timer.Simple(0.5, function()
				ply.noSound = false
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

function MODE:RoundThink()
end

function MODE:GetTeamSpawn()
	return {zb:GetRandomSpawn()}, {zb:GetRandomSpawn()}
end

function MODE:CanSpawn()
end

util.AddNetworkString("cri_roundend")
function MODE:EndRound()
	for k, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
	end

	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())

	timer.Simple(2, function()
		net.Start("cri_roundend")
			net.WriteBool(winner)
		net.Broadcast()
	end)

	for k, ply in player.Iterator() do
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