
hook.Add("PlayerDeath", "FurDeathSound", function(ply)
	if ply.PlayerClassName == "MEAT" then
		ply:EmitSound("voicelines/cryptiddeath.wav")
	end
end)

local meat_pain = {
	"voicelines/pain/939pain1.wav",
	"voicelines/pain/939pain2.wav",
	"voicelines/pain/939pain3.wav",
}


hook.Add("HG_ReplacePhrase", "UwUPhrases", function(ply, phrase, muffed, pitch)
	if IsValid(ply) and ply.PlayerClassName == "MEAT" then
		local inpain = ply.organism.pain > 60
		local phr = (inpain and meat_pain[math.random(#meat_pain)])

		return ply, phr, muffed, pitch
	end
end)

hook.Add("HG_ReplaceBurnPhrase", "UwUBurnPhrases", function(ply, phrase)
	if ply.PlayerClassName == "MEAT" then
		return ply, meat_pain[math.random(#meat_pain)]
	end
end)

hook.Add("Org Think", "ItHurtsfrfr",function(owner, org, timeValue)
	if owner.PlayerClassName != "MEAT" then return end

	if (owner.lastPainSoundCD or 0) < CurTime() and !org.otrub and org.pain >= 30 and math.random(1, 50) == 1 then
		local phrase = table.Random(meat_pain)

		local muffed = owner.armors["face"] == "mask2"

		owner:EmitSound(phrase, muffed and 65 or 75,owner.VoicePitch or 100,1,CHAN_AUTO,0, pitch and 56 or muffed and 16 or 0)

		owner.lastPainSoundCD = CurTime() + math.Rand(10, 25)
		owner.lastPhr = phrase
	end
end)