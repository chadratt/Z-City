local CLASS = player.RegClass("mafia")

function CLASS.Off(self)
    if CLIENT then return end
end

local models = {
    -- Male
    ["male 01"] = "models/sentry/sentryoldmob/mafia/sentrymobmale2pm.mdl",
    ["male 03"] = "models/sentry/sentryoldmob/mafia/sentrymobmale4pm.mdl",
    ["male 04"] = "models/sentry/sentryoldmob/mafia/sentrymobmale4pm.mdl",
    ["male 05"] = "models/sentry/sentryoldmob/mafia/sentrymobmale6pm.mdl",
    ["male 07"] = "models/sentry/sentryoldmob/mafia/sentrymobmale7pm.mdl",
    ["male 08"] = "models/sentry/sentryoldmob/mafia/sentrymobmale8pm.mdl",
    ["male 09"] = "models/sentry/sentryoldmob/mafia/sentrymobmale9pm.mdl",
    -- FEMKI
}

local ranks = {
    {name = "Capofamiglia ", chance = 5},
    {name = "Vicecapo .", chance = 5},
    {name = "Caporegime .", chance = 15},
    {name = "Soldati ", chance = 45},
    {name = "Associati ", chance = 80}
}

local clr = Color(10, 10, 100):ToVector()
function CLASS.On(self)
    if CLIENT then return end
    ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance
    Appearance.AAttachments = ""
    Appearance.AColthes = ""

    local randomValue = math.random(100)
    local cumulativeChance = 0
    local rank = "Associati"

    for _, rankInfo in ipairs(ranks) do
        cumulativeChance = cumulativeChance + rankInfo.chance
        if randomValue <= cumulativeChance then
            rank = rankInfo.name
            break
        end
    end

    self:SetNWString("PlayerName", rank .. " " .. Appearance.AName)
    self:SetPlayerColor(clr)
    self:SetModel(models[string.lower(Appearance.AModel)] or table.Random(models))
    self:SetBodyGroups("000000000000000000")
    self:SetSubMaterial()
    self:SetNetVar("Accessories", Appearance.AAttachmets or "none")
    self.CurAppearance = Appearance
end


if SERVER then
	local mafia_phrases = {
    "zcitymafia/voicelines/mafia/followme1.wav",
    "zcitymafia/voicelines/mafia/followme2.wav",
    "zcitymafia/voicelines/mafia/followme3.wav",
    "zcitymafia/voicelines/mafia/followme4.wav",
    "zcitymafia/voicelines/mafia/followme5.wav",
    "zcitymafia/voicelines/mafia/forget1.wav",
    "zcitymafia/voicelines/mafia/forget2.wav",
    "zcitymafia/voicelines/mafia/forget3.wav",
    "zcitymafia/voicelines/mafia/forget4.wav",
    "zcitymafia/voicelines/mafia/forget5.wav",
    "zcitymafia/voicelines/mafia/forget6.wav",
    "zcitymafia/voicelines/mafia/getout1.wav",
    "zcitymafia/voicelines/mafia/getout2.wav",
    "zcitymafia/voicelines/mafia/getout3.wav",
    "zcitymafia/voicelines/mafia/getout4.wav",
    "zcitymafia/voicelines/mafia/getout5.wav",
    "zcitymafia/voicelines/mafia/getout6.wav",
    "zcitymafia/voicelines/mafia/getout7.wav",
    "zcitymafia/voicelines/mafia/holdfire1.wav",
    "zcitymafia/voicelines/mafia/holdfire2.wav",
    "zcitymafia/voicelines/mafia/holdfire3.wav",
    "zcitymafia/voicelines/mafia/holdfire4.wav",
    "zcitymafia/voicelines/mafia/holdfire5.wav",
    "zcitymafia/voicelines/mafia/holdfire6.wav",
    "zcitymafia/voicelines/mafia/jump.wav",
    "zcitymafia/voicelines/mafia/no1.wav",
    "zcitymafia/voicelines/mafia/no2.wav",
    "zcitymafia/voicelines/mafia/no3.wav",
    "zcitymafia/voicelines/mafia/no4.wav",
    "zcitymafia/voicelines/mafia/no5.wav",
    "zcitymafia/voicelines/mafia/no6.wav",
    "zcitymafia/voicelines/mafia/sorry1.wav",
    "zcitymafia/voicelines/mafia/sorry2.wav"
}

	hook.Add("HG_ReplacePhrase", "mafia_phrase", function(ply, phrase, muffed, pitch)
		if IsValid(ply) and ply.PlayerClassName == "mafia" then
			return ply, mafia_phrases[math.random(#mafia_phrases)], muffed, pitch
		end
	end)
end

function CLASS.Guilt(self, Victim)
    if CLIENT then return end

    if Victim:GetPlayerClass() == self:GetPlayerClass() then
        --self:ChatPrint("You killed your teammate!")
        return 1
    end

    if CurrentRound().name == "hmcd" then
        return zb.ForcesAttackedInnocent(self, Victim)
    end

    return 1
end

