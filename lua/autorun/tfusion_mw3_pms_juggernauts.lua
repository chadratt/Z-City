local models =
{
	{ "MW3 Juggernaut Light", "models/tfusion/playermodels/mw3/juggernaut_c.mdl", "models/tfusion/playermodels/mw3/c_arms_juggernaut_c.mdl", 0, "00000000" },
	{ "MW3 Juggernaut Riot", "models/tfusion/playermodels/mw3/juggernaut_novisor_b.mdl", "models/tfusion/playermodels/mw3/c_arms_juggernaut_novisor_b.mdl", 0, "00000000" },
	{ "MW3 Juggernaut Armored OpFor", "models/tfusion/playermodels/mw3/mp_fullbody_opforce_juggernaut.mdl", "models/tfusion/playermodels/mw3/c_arms_juggernaut_opforce.mdl", 0, "00000000" },
	{ "MW3 Juggernaut Armored Allied", "models/tfusion/playermodels/mw3/mp_fullbody_ally_juggernaut.mdl", "models/tfusion/playermodels/mw3/c_arms_juggernaut_ally.mdl", 0, "00000000" },
	{ "MW3 Juggernaut Armored Explosive", "models/tfusion/playermodels/mw3/juggernaut_explosive_so.mdl", "models/tfusion/playermodels/mw3/c_arms_juggernaut_explosive_so.mdl", 0, "00000000" },
	{ "MW3 Juggernaut Mercenary", "models/tfusion/playermodels/mw3/sp_juggernaut.mdl", "models/tfusion/playermodels/mw3/c_arms_sp_juggernaut.mdl", 0, "00000000" },
}

for _, info in ipairs(models) do
	local friendlyName = info[1]
	local playermodelMdl = info[2]
	local viewmodelHandsMdl = info[3]
	local viewmodelSkin = info[4]
	local viewmodelBodygroups = info[5]
	player_manager.AddValidModel(friendlyName, playermodelMdl)
	player_manager.AddValidHands(friendlyName, viewmodelHandsMdl, viewmodelSkin, viewmodelBodygroups)
	list.Set("PlayerOptionsModel", friendlyName, playermodelMdl)
end
