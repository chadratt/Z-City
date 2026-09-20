
local CLASS = player.RegClass("germanww2")

function CLASS.Off(self)
    if CLIENT then return end
end

local models = {
    "models/dodhacks/germanmale02.mdl",
    "models/dodhacks/germanmale04.mdl",
    "models/dodhacks/germanmale06.mdl",
    "models/dodhacks/germanmale07.mdl"
}

local subnames = {
    "Grenadier ",
    "Obergrenadier ",
    "Gefreiter "
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
    local ww2german_phrases = {}
    local files, _ = file.Find("sound/ww2german/*.wav", "GAME")

    for k, v in ipairs(files) do
        ww2german_phrases[k] = "ww2german/" .. v
    end

    hook.Add("HG_ReplacePhrase", "ww2german_phrase", function(ply, phrase, muffed, pitch)
        if IsValid(ply) and ply.PlayerClassName == "germanww2" then
            if #ww2german_phrases == 0 then return end
            return ply, ww2german_phrases[math.random(#ww2german_phrases)], muffed, pitch
        end
    end)
end
