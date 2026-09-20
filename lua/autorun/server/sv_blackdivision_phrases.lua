
local function IsBlackDiv(ply)
    return IsValid(ply) and ply.PlayerClassName == "BLACK_DIVISION_TARKOV"
end

local bd_sounds = {
	contact = {
		"vj_eft/black_division_1/black_division_enemy_contact_01_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_02_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_03_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_04_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_05_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_06_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_07_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_08_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_09_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_10_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_11_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_12_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_13_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_14_n.wav",
		"vj_eft/black_division_1/black_division_enemy_contact_15_n.wav",
	},
	death = {
		"vj_eft/black_division_1/black_division_death_01.wav",
		"vj_eft/black_division_1/black_division_death_02.wav",
		"vj_eft/black_division_1/black_division_death_03.wav",
		"vj_eft/black_division_1/black_division_death_04.wav",
		"vj_eft/black_division_1/black_division_death_05.wav",
		"vj_eft/black_division_1/black_division_death_06.wav",
		"vj_eft/black_division_1/black_division_death_07.wav",
		"vj_eft/black_division_1/black_division_death_08.wav",
		"vj_eft/black_division_1/black_division_death_09.wav",
		"vj_eft/black_division_1/black_division_death_10.wav",
	},
	enemy_down = {
		"vj_eft/black_division_1/black_division_enemy_down_01_n.wav",
		"vj_eft/black_division_1/black_division_enemy_down_02_n.wav",
		"vj_eft/black_division_1/black_division_enemy_down_03_n.wav",
		"vj_eft/black_division_1/black_division_enemy_down_04_n.wav",
		"vj_eft/black_division_1/black_division_enemy_down_05_n.wav",
		"vj_eft/black_division_1/black_division_enemy_down_06_n.wav",
		"vj_eft/black_division_1/black_division_enemy_down_07_n.wav",
		"vj_eft/black_division_1/black_division_enemy_down_11_n.wav",
		"vj_eft/black_division_1/black_division_enemy_down_12_n.wav",
	},
	enemy_grenade = {
		"vj_eft/black_division_1/black_division_enemy_grenade_01_n.wav",
		"vj_eft/black_division_1/black_division_enemy_grenade_02_n.wav",
		"vj_eft/black_division_1/black_division_enemy_grenade_03_n.wav",
		"vj_eft/black_division_1/black_division_enemy_grenade_04_n.wav",
		"vj_eft/black_division_1/black_division_enemy_grenade_05_n.wav",
		"vj_eft/black_division_1/black_division_enemy_grenade_06_n.wav",
	},
	fight = {
		"vj_eft/black_division_1/black_division_fight_01_n.wav",
		"vj_eft/black_division_1/black_division_fight_02_n.wav",
		"vj_eft/black_division_1/black_division_fight_03_n.wav",
		"vj_eft/black_division_1/black_division_fight_04_n.wav",
		"vj_eft/black_division_1/black_division_fight_05_n.wav",
		"vj_eft/black_division_1/black_division_fight_06_n.wav",
		"vj_eft/black_division_1/black_division_fight_07_n.wav",
		"vj_eft/black_division_1/black_division_fight_08_n.wav",
		"vj_eft/black_division_1/black_division_fight_09_n.wav",
		"vj_eft/black_division_1/black_division_fight_10_n.wav",
		"vj_eft/black_division_1/black_division_fight_11_n.wav",
		"vj_eft/black_division_1/black_division_fight_12_n.wav",
		"vj_eft/black_division_1/black_division_fight_13_n.wav",
		"vj_eft/black_division_1/black_division_fight_14_n.wav",
		"vj_eft/black_division_1/black_division_fight_15_n.wav",
		"vj_eft/black_division_1/black_division_fight_16_n.wav",
		"vj_eft/black_division_1/black_division_fight_17_n.wav",
		"vj_eft/black_division_1/black_division_fight_18_n.wav",
		"vj_eft/black_division_1/black_division_fight_19_n.wav",
		"vj_eft/black_division_1/black_division_fight_20_n.wav",
		"vj_eft/black_division_1/black_division_fight_21_n.wav",
		"vj_eft/black_division_1/black_division_fight_22_n.wav",
		"vj_eft/black_division_1/black_division_fight_23_n.wav",
		"vj_eft/black_division_1/black_division_fight_24_n.wav",
		"vj_eft/black_division_1/black_division_fight_25_n.wav",
		"vj_eft/black_division_1/black_division_fight_26_n.wav",
		"vj_eft/black_division_1/black_division_fight_27_n.wav",
	},
	friendly_down = {
		"vj_eft/black_division_1/black_division_friendly_down_01_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_02_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_03_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_04_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_05_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_06_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_07_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_08_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_09_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_10_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_11_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_12_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_13_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_14_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_15_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_16_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_17_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_18_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_19_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_20_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_21_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_22_n.wav",
		"vj_eft/black_division_1/black_division_friendly_down_23_n.wav",
	},
	grenade = {
		"vj_eft/black_division_1/black_division_grenade_01_n.wav",
		"vj_eft/black_division_1/black_division_grenade_02_n.wav",
		"vj_eft/black_division_1/black_division_grenade_03_n.wav",
		"vj_eft/black_division_1/black_division_grenade_04_n.wav",
	},
	hit = {
		"vj_eft/black_division_1/black_division_hit_01.wav",
		"vj_eft/black_division_1/black_division_hit_02.wav",
		"vj_eft/black_division_1/black_division_hit_03.wav",
		"vj_eft/black_division_1/black_division_hit_04.wav",
		"vj_eft/black_division_1/black_division_hit_05.wav",
		"vj_eft/black_division_1/black_division_hit_06.wav",
		"vj_eft/black_division_1/black_division_hit_07.wav",
		"vj_eft/black_division_1/black_division_hit_08.wav",
		"vj_eft/black_division_1/black_division_hit_09.wav",
		"vj_eft/black_division_1/black_division_hit_10.wav",
		"vj_eft/black_division_1/black_division_hit_11.wav",
		"vj_eft/black_division_1/black_division_hit_12.wav",
		"vj_eft/black_division_1/black_division_hit_13.wav",
	},
	lostvisual = {
		"vj_eft/black_division_1/black_division_lostvisual_01_n.wav",
		"vj_eft/black_division_1/black_division_lostvisual_02_n.wav",
		"vj_eft/black_division_1/black_division_lostvisual_03_n.wav",
		"vj_eft/black_division_1/black_division_lostvisual_04_n.wav",
		"vj_eft/black_division_1/black_division_lostvisual_05_n.wav",
		"vj_eft/black_division_1/black_division_lostvisual_06_n.wav",
		"vj_eft/black_division_1/black_division_lostvisual_07_n.wav",
		"vj_eft/black_division_1/black_division_lostvisual_08_n.wav",
		"vj_eft/black_division_1/black_division_lostvisual_09_l.wav",
		"vj_eft/black_division_1/black_division_lostvisual_10_n.wav",
		"vj_eft/black_division_1/black_division_lostvisual_11_n.wav",
		"vj_eft/black_division_1/black_division_lostvisual_12_n.wav",
		"vj_eft/black_division_1/black_division_lostvisual_13_n.wav",
	},
	spread = {
		"vj_eft/black_division_1/black_division_spread_01_n.wav",
		"vj_eft/black_division_1/black_division_spread_02_n.wav",
		"vj_eft/black_division_1/black_division_spread_03_n.wav",
		"vj_eft/black_division_1/black_division_spread_04_n.wav",
		"vj_eft/black_division_1/black_division_spread_05_n.wav",
	},
	weap_reload = {
		"vj_eft/black_division_1/black_division_weap_reload_01_n.wav",
		"vj_eft/black_division_1/black_division_weap_reload_02_n.wav",
		"vj_eft/black_division_1/black_division_weap_reload_03_n.wav",
		"vj_eft/black_division_1/black_division_weap_reload_04_n.wav",
		"vj_eft/black_division_1/black_division_weap_reload_05_n.wav",
		"vj_eft/black_division_1/black_division_weap_reload_06_l.wav",
		"vj_eft/black_division_1/black_division_weap_reload_07_l.wav",
		"vj_eft/black_division_1/black_division_weap_reload_08_l.wav",
		"vj_eft/black_division_1/black_division_weap_reload_09_l.wav",
	},
}


util.AddNetworkString("blackdiv_voice_cmd")

net.Receive("blackdiv_voice_cmd", function(_, ply)

    if !IsBlackDiv(ply) then return end
    if !ply:Alive() then return end
    if (ply.phrCldBD or 0) > CurTime() then return end

    local cat = net.ReadString()

    local soundList = bd_sounds[cat]
    if !soundList or #soundList == 0 then return end

    local phrase = table.Random(soundList)

    local ent = (hg and hg.GetCurrentCharacter(ply)) or ply
    if !IsValid(ent) then return end

    local muffed = ply.armors and ply.armors["face"] == "mask2"

    ent:EmitSound(
        phrase,
        muffed and 65 or 75,
        ply.VoicePitch or 100,
        1,
        CHAN_AUTO,
        0,
        muffed and 16 or 0
    )

    local dur = SoundDuration(phrase)
    if dur <= 0.1 then dur = 1 end

    ply.phrCldBD = CurTime() + dur
    ply.lastPhrBD = phrase
end)

print("[blackdivision] Phrase server loaded (" .. table.Count(bd_sounds) .. " categories)")
