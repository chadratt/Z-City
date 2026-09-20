ENT.Type 		= "anim"           
ENT.Base 		= "base_gmodentity"  
ENT.Category 		= "Ammo crate"      
ENT.Instructions	= "Press E to instantly refill all your weapons. One use per player, per crate."

ENT.PrintName	= "Max Ammo Crate" 
ENT.Author		= "Assaultboy"    
ENT.Contact		= ""              

ENT.Spawnable		= true 
ENT.AdminSpawnable	= true 

ENT.AutomaticFrameAdvance = true

function ENT:SetAutomaticFrameAdvance( bUsingAnim ) 
	self.AutomaticFrameAdvance = bUsingAnim
end
