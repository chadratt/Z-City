local CLASS = player.RegClass("bulldozer")

function CLASS.Off(self)
    if CLIENT then return end
end

local models = {
    "models/mark2580/payday2/pd2_bulldozer_player.mdl"
}

if SERVER then
	local bulldozer_phrases = {
    "dozer/civil1.mp3",
	"dozer/civil2.mp3",
	"dozer/civil3.mp3",
	"dozer/comeout.mp3",
	"dozer/fullhealth1.mp3",
	"dozer/fullhealth2.mp3",
	"dozer/headcrab1.mp3",
	"dozer/hellodozer1.mp3",
	"dozer/idle2.mp3",
	"dozer/idle3.mp3",
	"dozer/laugh1.mp3",
	"dozer/laugh2.mp3",
	"dozer/moveit1.mp3",
	"dozer/moveit4.mp3",
	"dozer/outofammo1.mp3",
	"dozer/reload1.mp3",
	"dozer/reload2.mp3",
	"dozer/reload3.mp3",
	"dozer/scanner2.mp3",
	"dozer/sorry1.mp3",
	"dozer/spawn1.mp3",
	"dozer/spawn2.mp3",
	"dozer/spawn3.mp3",
	"dozer/spawn4.mp3",
	"dozer/spawn5.mp3",
	"dozer/spawn6.mp3",
	"dozer/spawn7.mp3",
	"dozer/taunt1.mp3",
	"dozer/taunt2.mp3",
	"dozer/taunt3.mp3",
	"dozer/taunt4.mp3",
	"dozer/taunt5.mp3",
	"dozer/taunt6.mp3",
	"dozer/taunt8.mp3",
	"dozer/threaten1.mp3",
	"dozer/threaten2.mp3",
	"dozer/zombie1.mp3",
	"dozer/zombie3.mp3"
}

	hook.Add("HG_ReplacePhrase", "bulldozer_phrase", function(ply, phrase, muffed, pitch)
		if IsValid(ply) and ply.PlayerClassName == "bulldozer" then
			return ply, bulldozer_phrases[math.random(#bulldozer_phrases)], muffed, pitch
		end
	end)
	
	hook.Add("HG_PlayerFootstep","bulldozer_footsteps",function(ply)
        local chr = hg.GetCurrentCharacter(ply)
        if ply:Alive() and ply.PlayerClassName == "bulldozer" then
            --;; Если есть ragdoll и т.п.
            ply.bulldozerLerpedFootStep = LerpFT(0.5,ply.bulldozerLerpedFootStep or 60, (not ply:IsSprinting() and (ply:KeyDown(IN_DUCK) or ply:KeyDown(IN_WALK))) and 20 or 60)
            if IsValid(ply.FakeRagdoll) and ply:GetNetVar("lastFake") == 0 then return end
            chr:EmitSound("npc/combine_soldier/gear" .. math.random(1,6) .. ".wav",
                ply.bulldozerLerpedFootStep
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

	

    hook.Add("HGReloading","bulldozer_reloadalert",function(wep)
        local ply = wep:GetOwner()
        if not IsValid(ply) then return end
        local nearPlayers = ents.FindInSphere(ply:GetPos(),300)
        for _,mate in ipairs(nearPlayers) do
            if mate:IsPlayer() and mate ~= ply and mate:Alive() and mate.PlayerClassName == "bulldozer" then
                if ply:Alive() and not ply.organism.otrub and ply.PlayerClassName == "bulldozer" and wep.ShellEject ~= "ShotgunShellEject" then
                    local phrase = (math.random(1,2) == 2) and "dozer/reload1.mp3" or "dozer/reload2.mp3"
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