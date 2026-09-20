local CLASS = player.RegClass("cryptidman")

function CLASS.Off(self)
    if CLIENT then return end
end

local cryptidman_subclasses = {
    default = {
        color = Color(0,220,220),
        models = Model("models/dejtriyev/scaryblackman.mdl"),
        skin = 1,
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

    if cfg.skin then
        self:SetSkin(cfg.skin)
    end
end

CLASS.CanUseDefaultPhrase = true
CLASS.CanEmitRNDSound = true
CLASS.CanUseGestures = true

function CLASS.Guilt(self, Victim)
    if CLIENT then return end
end

