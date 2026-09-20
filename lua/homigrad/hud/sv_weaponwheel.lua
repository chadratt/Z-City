util.AddNetworkString("HG_DropSpecificWeapon")

net.Receive("HG_DropSpecificWeapon", function(len, ply)
	local wep = net.ReadEntity()

	if not IsValid(ply) or not ply:Alive() then return end
	if not IsValid(wep) then return end
	if wep:GetOwner() ~= ply then return end
	if wep:GetClass() == "weapon_hands_sh" then return end

	ply:DropWeapon(wep)
end)
