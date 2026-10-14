local MODE = MODE

util.AddNetworkString("HMCD_BeingVictimOfNeckBreak")	--; А тут я значит рещил без скобок да крутой кодинг стиль вопросы?
util.AddNetworkString("HMCD_BreakingOtherNeck")
util.AddNetworkString("HMCD_BeingVictimOfDisarmament")
util.AddNetworkString("HMCD_DisarmingOther")
util.AddNetworkString("HMCD_UpdateChemicalResistance")

--\\Chemical resistance
	function MODE.NetworkChemicalResistanceOfPlayer(ply)
		ply.PassiveAbility_ChemicalAccumulation = ply.PassiveAbility_ChemicalAccumulation or {}
		
		net.Start("HMCD_UpdateChemicalResistance")
		
		for chemical_name, amt in pairs(ply.PassiveAbility_ChemicalAccumulation) do
			net.WriteString(chemical_name)
			net.WriteUInt(math.Round(amt), MODE.NetSize_ChemicalResistanceBits)
		end
		
		net.WriteString("")
		net.Send(ply)
	end
--//

hook.Add("PlayerPostThink", "HMCD_SubRoles_Abilities", function(ply)
	if(MODE.RoleChooseRoundTypes[MODE.Type])then
		if(ply:Alive() and ply.organism and not ply.organism.otrub)then
			if(ply.SubRole == "traitor_infiltrator" or ply.SubRole == "traitor_infiltrator_soe")then
				if(ply:KeyDown(IN_WALK))then
					if(ply:KeyPressed(IN_RELOAD))then
						local aim_ent, other_ply = hg.eyeTrace(ply,85).Entity
						other_ply = hg.RagdollOwner(aim_ent) or aim_ent
						
						if(IsValid(aim_ent) and aim_ent:IsRagdoll())then	--; REDO
							local other_appearance = aim_ent.CurAppearance
							local your_appearance = ply.CurAppearance

							local aMdl1,aMdl2 = your_appearance.AModel,other_appearance.AModel
							
							other_appearance.AModel = aMdl1
							your_appearance.AModel = aMdl2

							local aFace1,aFace2 = your_appearance.AFacemaps,other_appearance.AFacemaps

							other_appearance.AFacemaps = aFace1
							your_appearance.AFacemaps = aFace2

							hg.Appearance.ForceApplyAppearance(ply, other_appearance, true)
							local char = hg.GetCurrentCharacter(ply)
							if char:IsRagdoll() then
								hg.Appearance.ForceApplyAppearance(char, other_appearance, true)
							end
							ply:EmitSound("snd_jack_hmcd_disguise.wav",35,math.random(90,110),0.5)

							--local duplicator_data = duplicator.CopyEntTable(ply)
							--duplicator.DoGeneric(aim_ent, duplicator_data)
							aim_ent.CurAppearance = your_appearance

							hg.Appearance.ForceApplyAppearance(aim_ent, your_appearance, true)
							
							if other_ply:IsPlayer() and other_ply:Alive() then
								hg.Appearance.ForceApplyAppearance(other_ply, your_appearance, true)
							end
						end
					end
					
					if(ply:KeyPressed(IN_USE))then
						local aim_ent, other_ply = MODE.GetPlayerTraceToOther(ply)
						
						if(IsValid(aim_ent))then
							if(other_ply and MODE.CanPlayerBreakOtherNeck(ply, aim_ent))then
								MODE.StartBreakingOtherNeck(ply, other_ply)
							end
						end
					elseif(ply:KeyDown(IN_USE))then
						if(ply.Ability_NeckBreak)then
							MODE.ContinueBreakingOtherNeck(ply)
						end
					end
					
					if(ply:KeyReleased(IN_USE))then
						MODE.StopBreakingOtherNeck(ply)
					end
				else
					MODE.StopBreakingOtherNeck(ply)
				end
			end
			
			if(ply.SubRole == "traitor_assasin" or ply.SubRole == "traitor_assasin_soe")then
				if(ply:KeyDown(IN_WALK))then
					if(ply:KeyPressed(IN_USE))then
						local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOther(ply, nil, MODE.DisarmReach)
						
						if(IsValid(aim_ent))then
							if(other_ply and MODE.CanPlayerDisarmOther(ply, aim_ent, MODE.DisarmReach) and MODE.CanPlayerDisarmOtherPly(ply, other_ply, MODE.DisarmReach))then
								MODE.StartDisarmingOther(ply, other_ply)
							end
						end
					elseif(ply:KeyDown(IN_USE))then
						if(ply.Ability_Disarm)then
							MODE.ContinueDisarmingOther(ply)
						end
					end
					
					if(ply:KeyReleased(IN_USE))then
						MODE.StopDisarmingOther(ply)
					end
				else
					MODE.StopDisarmingOther(ply)
				end
			end
			
			if(ply.SubRole == "traitor_zombie")then
				if(ply:KeyDown(IN_WALK))then
					
				end
			end

			if(ply.SubRole == "traitor_chemist")then
				DegradeChemicalsOfPlayer(ply)
				
				if(!ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime or ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime <= CurTime())then
					MODE.NetworkChemicalResistanceOfPlayer(ply)

					ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime = CurTime() + 1
				end
			end
		end
	end
end)

hook.Add("HG_PlayerFootstep", "HMCD_Latcher_SilentFootsteps", function(ply)
	if(MODE.RoleChooseRoundTypes[MODE.Type] and ply:Alive() and (ply.SubRole == "traitor_latcher" or ply.SubRole == "traitor_latcher_soe"))then
		return true
	end
end)

local function HMCD_IsCultist(ply)
	return IsValid(ply) and (ply.SubRole == "traitor_cultist" or ply.SubRole == "traitor_cultist_soe")
end

local function HMCD_GetRandomZCityWeapon(ply)
	local based = weapons.IsBasedOn
	local pool = {}
	for _, wep in ipairs(weapons.GetList()) do
		local classname = wep.ClassName
		if classname and wep.Spawnable and (based(classname, "homigrad_base") or based(classname, "weapon_melee")) and not ply:HasWeapon(classname) then
			pool[#pool + 1] = classname
		end
	end
	if #pool == 0 then return nil end
	return pool[math.random(#pool)]
end

local function HMCD_GiveCultistGift(ply)
	ply:Notify("The pale man has granted you a gift")
	local classname = HMCD_GetRandomZCityWeapon(ply)
	if not classname then return end
	local wep = ply:Give(classname)
	if IsValid(wep) and wep.GetPrimaryAmmoType and wep:GetPrimaryAmmoType() >= 0 and wep:GetMaxClip1() > 0 then
		ply:GiveAmmo(wep:GetMaxClip1() * 2, wep:GetPrimaryAmmoType(), true)
	end
end

hook.Add("HomigradDamage", "HMCD_Cultist_TrackAttacker", function(ply, dmgInfo)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	local attacker = dmgInfo:GetAttacker()
	if not IsValid(attacker) or not attacker:IsPlayer() then
		attacker = ply:GetPhysicsAttacker()
	end
	if IsValid(attacker) and attacker:IsPlayer() and attacker != ply then
		ply.HMCD_CultistLastAttacker = attacker
		ply.HMCD_CultistLastAttackTime = CurTime()
	end
end)

hook.Add("PlayerDeath", "HMCD_Cultist_KillCounter", function(victim, inflictor, attacker)
	if not IsValid(victim) then return end
	local killer = attacker
	if not IsValid(killer) or not killer:IsPlayer() or killer == victim then
		if IsValid(victim.HMCD_CultistLastAttacker) and (victim.HMCD_CultistLastAttackTime or 0) + 30 > CurTime() then
			killer = victim.HMCD_CultistLastAttacker
		else
			killer = nil
		end
	end
	victim.HMCD_CultistLastAttacker = nil
	victim.HMCD_CultistLastAttackTime = nil
	if not MODE.RoleChooseRoundTypes[MODE.Type] then return end
	if not IsValid(killer) or killer == victim or not HMCD_IsCultist(killer) then return end
	if killer.HMCD_CultistGiftUsed then return end
	killer.HMCD_CultistKills = (killer.HMCD_CultistKills or 0) + 1
	if killer.HMCD_CultistKills >= 7 and killer:Alive() then
		killer.HMCD_CultistGiftUsed = true
		HMCD_GiveCultistGift(killer)
	end
end)
