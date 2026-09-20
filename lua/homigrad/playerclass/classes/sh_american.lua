
local CLASS = player.RegClass("americanww2")

function CLASS.Off(self)
    if CLIENT then return end
end

local models = {
    "models/dodhacks/usmale01.mdl",
    "models/dodhacks/usmale02.mdl",
    "models/dodhacks/usmale04.mdl",
    "models/dodhacks/usmale07.mdl"
}

local subnames = {
    "Private  ",
    "Private First Class ",
    "Corporal  ",
	"Sergeant "
}

function CLASS.On(self)
    if CLIENT then return end

    ApplyAppearance(self, nil, nil, nil, true)

    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    Appearance.AAttachments = ""
    Appearance.AColthes = ""

    self:SetNWString("PlayerName", subnames[math.random(#subnames)] .. Appearance.AName)
    self:SetPlayerColor(Color(165,0,0):ToVector())
    self:SetModel(models[math.random(#models)])

    for _, bg in ipairs(self:GetBodyGroups()) do
        self:SetBodygroup(bg.id, math.random(0, bg.num))
    end

    local inv = self:GetNetVar("Inventory", {})
    inv["Weapons"] = inv["Weapons"] or {}
    inv["Weapons"]["hg_sling"] = true
    self:SetNetVar("Inventory", inv)

    self:SetSubMaterial()

    self.CurAppearance = Appearance
end

if SERVER then
    local ww2american_phrases = {}
    local files, _ = file.Find("sound/ww2american/*.wav", "GAME")

    for k, v in ipairs(files) do
        ww2american_phrases[k] = "ww2american/" .. v
    end

    hook.Add("HG_ReplacePhrase", "ww2american_phrase", function(ply, phrase, muffed, pitch)
        if IsValid(ply) and ply.PlayerClassName == "americanww2" then
            if #ww2american_phrases == 0 then return end
            return ply, ww2american_phrases[math.random(#ww2american_phrases)], muffed, pitch
        end
    end)
end
