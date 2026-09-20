local CLASS = player.RegClass("juggernaut")

function CLASS.Off(self)
    if CLIENT then return end
end

local models = {
    "models/tfusion/playermodels/mw3/juggernaut_novisor_b.mdl"
}

if SERVER then
	local juggernaut_phrases = {
    "juggernaut/voicelines/juggernautline1.mp3",
    "juggernaut/voicelines/juggernautline2.mp3",
    "juggernaut/voicelines/juggernautline3.mp3",
    "juggernaut/voicelines/juggernautline4.mp3",
    "juggernaut/voicelines/juggernautline5.mp3",
    "juggernaut/voicelines/juggernautline6.mp3",
    "juggernaut/voicelines/juggernautline7.mp3",
    "juggernaut/voicelines/juggernautline8.mp3",
    "juggernaut/voicelines/juggernautline9.mp3",
    "juggernaut/voicelines/juggernautline10.mp3",
    "juggernaut/voicelines/juggernautline11.mp3",
    "juggernaut/voicelines/juggernautline12.mp3",
    "juggernaut/voicelines/juggernautline13.mp3",
    "juggernaut/voicelines/juggernautline14.mp3",
    "juggernaut/voicelines/juggernautline15.mp3",
    "juggernaut/voicelines/juggernautline16.mp3",
    "juggernaut/voicelines/juggernautline17.mp3",
    "juggernaut/voicelines/juggernautline18.mp3",
    "juggernaut/voicelines/juggernautline19.mp3",
    "juggernaut/voicelines/juggernautline20.mp3",
    "juggernaut/voicelines/juggernautline21.mp3",
    "juggernaut/voicelines/juggernautline22.mp3",
    "juggernaut/voicelines/juggernautline23.mp3",
    "juggernaut/voicelines/juggernautline24.mp3",
    "juggernaut/voicelines/juggernautline25.mp3"
}

	hook.Add("HG_ReplacePhrase", "juggernaut_phrase", function(ply, phrase, muffed, pitch)
		if IsValid(ply) and ply.PlayerClassName == "juggernaut" then
			return ply, juggernaut_phrases[math.random(#juggernaut_phrases)], muffed, pitch
		end
	end)
	
	hook.Add("HG_PlayerFootstep","juggernaut_footsteps",function(ply)
        local chr = hg.GetCurrentCharacter(ply)
        if ply:Alive() and ply.PlayerClassName == "juggernaut" then
            --;; Если есть ragdoll и т.п.
            ply.juggernautLerpedFootStep = LerpFT(0.5,ply.juggernautLerpedFootStep or 60, (not ply:IsSprinting() and (ply:KeyDown(IN_DUCK) or ply:KeyDown(IN_WALK))) and 20 or 60)
            if IsValid(ply.FakeRagdoll) and ply:GetNetVar("lastFake") == 0 then return end
            chr:EmitSound("npc/combine_soldier/gear" .. math.random(1,6) .. ".wav",
                ply.juggernautLerpedFootStep
            )
        end
    end)

    local hitgroups_sounds = {
        [HITGROUP_STOMACH] = true,
        [HITGROUP_CHEST]   = true,
        [HITGROUP_LEFTARM] = true,
        [HITGROUP_RIGHTARM] = true,
        [HITGROUP_RIGHTLEG] = true,
        [HITGROUP_LEFTLEG]  = true
    }

	

    hook.Add("HGReloading","juggernaut_reloadalert",function(wep)
        local ply = wep:GetOwner()
        if not IsValid(ply) then return end
        local nearPlayers = ents.FindInSphere(ply:GetPos(),300)
        for _,mate in ipairs(nearPlayers) do
            if mate:IsPlayer() and mate ~= ply and mate:Alive() and mate.PlayerClassName == "juggernaut" then
                if ply:Alive() and not ply.organism.otrub and ply.PlayerClassName == "juggernaut" and wep.ShellEject ~= "ShotgunShellEject" then
                    local phrase = (math.random(1,2) == 2) and "juggernaut/voicelines/juggernautline10.mp3" or "juggernaut/voicelines/juggernautline12.mp3"
                    ply:EmitSound(phrase,75,ply.VoicePitch)
                    ply.phrCld = CurTime() + (SoundDuration(phrase) or 0)
                    ply.lastPhr = phrase
                    return
                end
            end
        end
    end)
end

function CLASS.On(self)
    if CLIENT then return end
    ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    Appearance.AAttachments = ""
    Appearance.AColthes = ""
    self:SetPlayerColor(Color(0,165,0):ToVector())
    self:SetModel(models[math.random(#models)])
	for _, bg in ipairs(self:GetBodyGroups()) do
		self:SetBodygroup(bg.id, math.random(0, bg.num))
	end
	
	self.armors = {}
    self.armors["torso"] = "cmb_armor"
    self.armors["head"] = "cmb_helmet"
    self:SyncArmor()
    
    local inv = self:GetNetVar("Inventory", {})
    inv["Weapons"] = inv["Weapons"] or {}
    inv["Weapons"]["hg_sling"] = true
    self:SetNetVar("Inventory", inv)

    self:SetSubMaterial()
    self.CurAppearance = Appearance
end