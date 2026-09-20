local CLASS = player.RegClass("BLACK_DIVISION_TARKOV")


local combine_models = {
    "models/eft/bosses/black_division.mdl"
}


local callsigns = {
    "Bastion","Citadel","Reaper","Specter"
}


local primary_weapons = {
    "weapon_mp7"
}


local combine_subclasses = {
    default = {
        color = Color(24,24,24),
        models = combine_models,
        loadout = {
            {weapon = "weapon_medkit_sh"},
            {weapon = "weapon_morphine"},
            {weapon = "weapon_adrenaline"},
            {weapon = "weapon_naloxone"},
            {weapon = "weapon_bigbandage_sh"},
            {weapon = "weapon_tourniquet"},
            {weapon = "weapon_handcuffs"},
            {weapon = "weapon_handcuffs_key"},
            {weapon = "weapon_walkie_talkie"},
            {weapon = "weapon_sogknife"},
            {
                weapon = "weapon_m4a1",
                ammo_mult = 5
            },
            {
                weapon = "weapon_hk_usp",
                ammo_mult = 5
            }
        },
    }
}

local combines = {
    "npc_combine_s",
    "npc_strider",
    "npc_metropolice",
    "npc_hunter",
    "npc_rollermine",
    "npc_cscanner",
    "npc_combinegunship",
    "npc_combinedropship",
    "npc_clawscanner",
    "npc_manhack",
    "npc_turret_ceiling",
    "npc_turret_floor",
    "npc_vj_eft_blackdiv"
}

local rebels = {
    "npc_alyx",
    "npc_barney",
    "npc_citizen",
    "npc_eli",
    "npc_fisherman",
    "npc_kleiner",
    "npc_magnusson",
    "npc_mossman",
    "npc_odessa",
    "npc_rollermine_hacked",
    "npc_turret_floor_resistance",
    "npc_vortigaunt"
}

function CLASS.Off(self)
    if CLIENT then return end

	if eightbit and eightbit.EnableEffect and self.UserID then
		eightbit.EnableEffect(self:UserID(), 0)
	end

    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(combines,v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
        elseif table.HasValue(rebels,v:GetClass()) then
            v:AddEntityRelationship( self, D_LI, 0 )
        end
    end
	
	self:SetModelScale(1,0)

if hg and hg.Appearance and hg.Appearance.ClearTemporaryPlayerScale then
    hg.Appearance.ClearTemporaryPlayerScale(self)

    if hg.Appearance.ResetPlayerScale then
        hg.Appearance.ResetPlayerScale(self)
    end
end

	self:SetNWString("PlayerRole", nil)
    self.organism.CantCheckPulse = nil
    self.leader = nil
	self:SetNetVar("HideArmorRender", false)
	hook.Remove("OnEntityCreated", "relation_shipdo"..self:EntIndex())
end


CLASS.NoFreeze = true
CLASS.CanEmitRNDSound = false

local function giveSubClassLoadout(ply, subclass)
    local config = combine_subclasses[subclass] or combine_subclasses["default"]
    ply:StripWeapons()
    ply:Give("weapon_hands_sh")
    for _, item in ipairs(config.loadout or {}) do
        if item.weapon_random_pool then
            local randWep = item.weapon_random_pool[math.random(#item.weapon_random_pool)]
            local wep = ply:Give(randWep)
            if wep and item.ammo_mult then
                ply:GiveAmmo(wep:GetMaxClip1() * item.ammo_mult, wep:GetPrimaryAmmoType(), true)
            end
        else
            local wep = ply:Give(item.weapon)
            if IsValid(wep) then
                -- Force StartAtt (EOTech/suppressor on the M4A1, etc.) to apply
                -- immediately instead of relying only on SWEP:Initialize()'s own
                -- timing — ClearAttachments() is idempotent so calling it again
                -- here is safe, it just guarantees the attachments and their
                -- netvar sync fire right as the weapon is handed out at spawn.
                if wep.ClearAttachments then
                    wep:ClearAttachments()
                end

                --;; патрончики
                if item.ammo_mult then
                    ply:GiveAmmo(wep:GetMaxClip1() * item.ammo_mult, wep:GetPrimaryAmmoType(), true)
                end
                --;; пример кастомной какахи 
                if item.count then
                    wep.count = item.count
                end
                if item.extra_balls then
                    wep:SetNWInt("Balls", item.extra_balls)
                end
            end
        end
    end
end

function CLASS.On(self, data)
    if CLIENT then return end

	if eightbit and eightbit.EnableEffect and self.UserID then
		eightbit.EnableEffect(self:UserID(), eightbit.EFF_PROOT) --!! placeholder
	end

    if IsValid(self.FakeRagdoll) then
        hg.FakeUp(self, nil, nil, true)
    end

    -- Force skin 0; bodygroups get (re)randomized below, after the model
    -- is actually switched to the Black Division model.
    self:SetSkin(0)

    ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    Appearance.AAttachments = ""
    Appearance.AColthes = ""

    local sub = self.subClass or "default"
    local cfg = combine_subclasses[sub] or combine_subclasses["default"]
    local useModel = cfg.models[math.random(#cfg.models)]
    self:SetModel(useModel)
    self:SetSubMaterial()
    self:SetNetVar("Accessories", "")
    self:SetPlayerColor(cfg.color:ToVector())

    -- Randomize bodygroups (gear/kit variety) every time the class turns on.
    -- Same ranges npc_vj_eft_blackdiv/init.lua uses for this exact model
    -- (models/eft/bosses/black_division.mdl), so players end up dressed
    -- consistently with the Black Division NPCs.
    self:SetBodygroup( 0, math.random( 0, 7 ) )
    self:SetBodygroup( 1, math.random( 0, 4 ) )
    self:SetBodygroup( 2, math.random( 0, 1 ) )
    self:SetBodygroup( 3, math.random( 0, 3 ) )
    local faceCover = math.random( 1, 3 )
    if faceCover == 1 then
        self:SetBodygroup( 4, math.random( 0, 1 ) )
        self:SetBodygroup( 6, math.random( 0, 1 ) )
    elseif faceCover == 2 then
        self:SetBodygroup( 4, 2 )
        self:SetBodygroup( 5, math.random( 1, 2 ) )
        self:SetBodygroup( 6, math.random( 0, 1 ) )
    else
        self:SetBodygroup( 4, 2 )
        self:SetBodygroup( 5, 3 )
        self:SetBodygroup( 6, 2 )
    end
    self:SetBodygroup( 7, math.random( 0, 3 ) )
    self:SetBodygroup( 8, math.random( 0, 3 ) )
    local lowerSet = math.random( 0, 3 )
    self:SetBodygroup( 9, lowerSet )
    self:SetBodygroup( 10, lowerSet )
    self:SetBodygroup( 11, math.random( 0, 3 ) )

    if cfg.skin then
       self:SetSkin(cfg.skin)
    end
    self.organism.CantCheckPulse = true

    --;; Армор
    self.armors = {}
    self.armors["torso"] = "vest1" -- Plate Body Armor IV (Level 4)
    self.armors["head"] = "helmet6" -- SWAT Balistic Helmet
    self:SetNetVar("HideArmorRender", true) -- same flag the playermodel selector's armor toggle uses; keeps the vest/helmet models from drawing on the body
    self:SyncArmor()

    if not data.bNoEquipment then
        giveSubClassLoadout(self, sub)
    end

    self.subClass = nil
    self.organism.recoilmul = 0.50

    local callsign
    if math.random(1,1000) <= 1 then
        callsign = "Scug"
    else
        callsign = table.Random(callsigns) .. "-" .. math.random(1,25)
    end

    if zb.GiveRole then zb.GiveRole(self, "Officer", Color(89,230,255)) end
    self:SetNWString("PlayerName", callsign)

    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(combines,v:GetClass()) then
            v:AddEntityRelationship( self, D_LI, 0 )
            v:ClearEnemyMemory()
        elseif table.HasValue(rebels,v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
            v:ClearEnemyMemory()
        end
    end

    local index = self:EntIndex()
    hook.Add( "OnEntityCreated", "relation_shipdo"..index, function( ent )
        if not IsValid(self) then hook.Remove("OnEntityCreated","relation_shipdo"..index) return end
        if ( ent:IsNPC() ) then
            --print(ent:GetClass())
            if table.HasValue(combines,ent:GetClass()) then
                ent:AddEntityRelationship( self, D_LI, 0 )
            end

            if table.HasValue(rebels,ent:GetClass()) then
                ent:AddEntityRelationship( self, D_HT, 99 )
            end
        end
    end )

    self.CurAppearance = appearance
end

function CLASS.Guilt(self, victim)
    if CLIENT then return end

    if victim:GetPlayerClass() == self:GetPlayerClass() then
        return 1
    end
end


function CLASS.PlayerDeath(self)

    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(combines,v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
        elseif table.HasValue(rebels,v:GetClass()) then
            v:AddEntityRelationship( self, D_LI, 0 )
        end
    end

    EmitSound( "npc/metropolice/die" .. math.random(1,4) .. ".wav", self:GetPos() )

    hook.Remove( "OnEntityCreated", "relation_shipdo"..self:EntIndex())
end

return CLASS