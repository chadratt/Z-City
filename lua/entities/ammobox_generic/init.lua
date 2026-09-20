AddCSLuaFile( "cl_init.lua" ) 
AddCSLuaFile( "shared.lua" ) 
include( 'shared.lua' )     


local MAGS = 6

local FALLBACK_AMMO = 120

local USE_SOUND = "items/ammo_pickup.wav"

local Anim_Open = nil

function ENT:Initialize()
	self:SetModel( "models/Items/ammocrate_smg1.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )

	Anim_Open = self:LookupSequence( "Open" )

	self.Used = {}
end

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 16

	local ent = ents.Create( "ammobox_generic" )
	ent:SetAngles( ply:GetAngles() + Angle( 0, 180, 0 ) )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Activate()
	return ent
end


local function PlayerKey( ply )
	return ply:SteamID64() or ply:SteamID() or ( "uid_" .. ply:UserID() )
end


function ENT:GiveMaxAmmo( ply )
	for _, wep in ipairs( ply:GetWeapons() ) do
		if not IsValid( wep ) then continue end


		local ammoType = wep:GetPrimaryAmmoType()
		if ammoType and ammoType >= 0 then
			local clip = wep:GetMaxClip1()
			if clip and clip > 0 then
				wep:SetClip1( clip ) -- top off the loaded magazine
				ply:SetAmmo( math.max( ply:GetAmmoCount( ammoType ), clip * MAGS ), ammoType )
			else
				ply:SetAmmo( math.max( ply:GetAmmoCount( ammoType ), FALLBACK_AMMO ), ammoType )
			end
		end

		local ammoType2 = wep:GetSecondaryAmmoType()
		if ammoType2 and ammoType2 >= 0 then
			local clip2 = wep:GetMaxClip2()
			if clip2 and clip2 > 0 then
				wep:SetClip2( clip2 )
				ply:SetAmmo( math.max( ply:GetAmmoCount( ammoType2 ), clip2 * MAGS ), ammoType2 )
			else
				ply:SetAmmo( math.max( ply:GetAmmoCount( ammoType2 ), FALLBACK_AMMO ), ammoType2 )
			end
		end
	end
end

function ENT:Use( Activator, Caller )
	if not IsValid( Activator ) or not Activator:IsPlayer() then return end

	local key = PlayerKey( Activator )


	if self.Used[ key ] then
		Activator:ChatPrint( "This ammo crate has already been used by you." )
		return
	end

	self.Used[ key ] = true
	self:GiveMaxAmmo( Activator )


	Activator:EmitSound( USE_SOUND )
	Activator:ChatPrint( "Ammo refilled: all weapons topped up to " .. MAGS .. " magazines." )


	if Anim_Open then
		self:SetSequence( Anim_Open )
	end
end

function ENT:Think()
	self:NextThink( CurTime() )
	return true
end
