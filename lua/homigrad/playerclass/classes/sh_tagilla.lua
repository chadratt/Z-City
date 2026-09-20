local CLASS = player.RegClass("TAGILLA")

function CLASS.Off(self)
    if CLIENT then return end

    self.StaminaExhaustMul = nil
end

local cryptidman_subclasses = {
    default = {
        color = Color(0,220,220),
        models = Model("models/eft/bosses/tagilla.mdl"),

    }
}



function CLASS.On(self)
    if CLIENT then return end

        ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    Appearance.AAttachments = ""
    Appearance.AColthes = ""

    self.armors = {}
    self.armors["torso"] = "cmb_armor"
    self.armors["head"] = "metrocop_helmet"
    self:SyncArmor()

    local sub = self.subClass or "default"
    local cfg = cryptidman_subclasses[sub] or cryptidman_subclasses["default"]
    local useModel = istable(cfg.models) and cfg.models[math.random(#cfg.models)] or cfg.models
    self:SetModel(useModel)
    self:SetSubMaterial()
    self:SetNetVar("Accessories", "")
    self:SetPlayerColor(cfg.color:ToVector())


    self.StaminaExhaustMul = 0
end

CLASS.CanUseDefaultPhrase = false
CLASS.CanEmitRNDSound = false
CLASS.CanUseGestures = true

function CLASS.Guilt(self, Victim)
    if CLIENT then return end
end



if SERVER then

	hook.Add("Org Think", "TAGILLA_infstamina", function(owner, org, timeValue)
		if not IsValid(owner) or not owner:IsPlayer() then return end
		if owner.PlayerClassName ~= "TAGILLA" then return end
		if not org or not org.stamina then return end

		org.stamina.sub = 0
		org.stamina[1] = org.stamina.max
	end)

	local tagilla_phrases = {
		"adminfun/tagilla/tagilla1.wav",
        "adminfun/tagilla/tagilla2.wav",
        "adminfun/tagilla/tagilla3.wav",
        "adminfun/tagilla/tagilla4.wav",
        "adminfun/tagilla/tagilla5.wav",
        "adminfun/tagilla/tagilla6.wav",
        "adminfun/tagilla/tagilla7.wav",
        "adminfun/tagilla/tagilla8.wav",
        "adminfun/tagilla/tagilla9.wav",
        "adminfun/tagilla/tagilla10.wav",
        "adminfun/tagilla/tagilla11.wav",
        "adminfun/tagilla/tagilla12.wav",
        "adminfun/tagilla/tagilla13.wav",
        "adminfun/tagilla/tagilla14.wav",
        "adminfun/tagilla/tagilla15.wav"
	}

	hook.Add("HG_ReplacePhrase", "TAGILLA_phrase", function(ply, phrase, muffed, pitch)
		if IsValid(ply) and ply.PlayerClassName == "TAGILLA" then
			return ply, tagilla_phrases[math.random(#tagilla_phrases)], muffed, pitch
		end
	end)
end