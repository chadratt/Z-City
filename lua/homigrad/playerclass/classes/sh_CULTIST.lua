local CLASS = player.RegClass("CULTIST")

function CLASS.Off(self)
    if CLIENT then return end
end

local cryptidman_subclasses = {
    default = {
        color = Color(0,220,220),
        models = Model("models/trepang/playerm/cultist.mdl"),

    }
}

function CLASS.On(self)
    if CLIENT then return end

        ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    Appearance.AAttachments = ""
    Appearance.AColthes = ""

    local sub = self.subClass or "default"
    local cfg = cryptidman_subclasses[sub] or cryptidman_subclasses["default"]
    local useModel = istable(cfg.models) and cfg.models[math.random(#cfg.models)] or cfg.models
    self:SetModel(useModel)
    self:SetSubMaterial()
    self:SetNetVar("Accessories", "")
    self:SetPlayerColor(cfg.color:ToVector())
end

CLASS.CanUseDefaultPhrase = false
CLASS.CanEmitRNDSound = false
CLASS.CanUseGestures = true


if SERVER then
	local cultist_phrases = {
		"cultist/cultist_1.wav",
		"cultist/cultist_2.wav",
        "cultist/cultist_3.wav",
        "cultist/cultist_4.wav",
        "cultist/cultist_5.wav",
        "cultist/cultist_6.wav",
        "cultist/cultist_7.wav",
        "cultist/cultist_8.wav",
        "cultist/cultist_9.wav",
        "cultist/cultist_10.wav",
        "cultist/cultist_11.wav",
        "cultist/cultist_12.wav",
        "cultist/cultist_13.wav",
        "cultist/cultist_14.wav",
        "cultist/cultist_15.wav",
        "cultist/cultist_16.wav",
        "cultist/cultist_17.wav"
	}

	hook.Add("HG_ReplacePhrase", "CULTIST_PHRASE", function(ply, phrase, muffed, pitch)
		if IsValid(ply) and ply.PlayerClassName == "CULTIST" then
			return ply, cultist_phrases[math.random(#cultist_phrases)], muffed, pitch
		end
	end)
end




function CLASS.Guilt(self, Victim)
    if CLIENT then return end
end

