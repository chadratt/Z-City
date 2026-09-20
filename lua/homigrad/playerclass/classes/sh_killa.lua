local CLASS = player.RegClass("KILLA")

function CLASS.Off(self)
    if CLIENT then return end
end

local cryptidman_subclasses = {
    default = {
        color = Color(0,220,220),
        models = Model("models/kerry/killa_suka_blat/killa_blat.mdl"),

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
    self.armors["head"] = "cmb_helmet"
    self:SyncArmor()

    local sub = self.subClass or "default"
    local cfg = cryptidman_subclasses[sub] or cryptidman_subclasses["default"]
    local useModel = istable(cfg.models) and cfg.models[math.random(#cfg.models)] or cfg.models
    self:SetModel(useModel)
    self:SetSubMaterial()
    self:SetNetVar("Accessories", "")
    self:SetPlayerColor(cfg.color:ToVector())
end

CLASS.CanUseDefaultPhrase = true
CLASS.CanEmitRNDSound = false
CLASS.CanUseGestures = true

function CLASS.Guilt(self, Victim)
    if CLIENT then return end
end

