local function AddPlayerModel( name, model )

    list.Set( "PlayerOptionsModel", name, model )
	player_manager.AddValidModel( name, model )
    player_manager.AddValidHands( "WB_PM", "models/jinroh/c_arms_jin_roh.mdl", 0, "00000000" )	
		
end

AddPlayerModel( "WB_PM", "models/jinroh/wolf_brigade_model_playermodel.mdl" )


//list.Set( "PlayerOptionsAnimations", "WB_PM", { "idle_knife" } )

