hg = hg or {}
hg.WeaponSelector = hg.WeaponSelector or {}
local WS = hg.WeaponSelector

function WS.GetPrintName( self )
	local class = self:GetClass()
	local phrase = language.GetPhrase(class)
	return phrase ~= class and phrase or self:GetPrintName()
end

function WS.GetWeaponTable( ply )
	if not IsValid( ply ) or not ply:Alive() then return end
	local WeaponsGet = ply:GetWeapons()
	local FormatedTable = {
		[0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {},
	}

	table.sort(WeaponsGet, function(a, b) return (a.SlotPos or 0) > (b.SlotPos or 0) end)

	for k,wep in ipairs(WeaponsGet) do
		local tTbl = FormatedTable[wep.Slot or 0]
		local iMinPos = math.min( (wep.SlotPos and wep.SlotPos) or 1, ((#tTbl or 0) + 1)) - 1
		local iPos = tTbl[ iMinPos ] and #tTbl + 1 or iMinPos
		tTbl[ iPos ] = wep
	end
	return FormatedTable
end

local tBlockedBinds = {
	["slot1"] = true,
	["slot2"] = true,
	["slot3"] = true,
	["slot4"] = true,
	["slot5"] = true,
	["slot6"] = true,
	["invnext"] = true,
	["invprev"] = true,
	["lastinv"] = true,
}

hook.Add( "PlayerBindPress", "WeaponSelector_BlockLegacySwitching", function( ply, bind, pressed )
	if tBlockedBinds[ bind ] then
		return true
	end
end)

local tHideElements = {
	["CHudWeaponSelection"] = true
}

hook.Add("HUDShouldDraw", "WeaponSelector_HUDShouldDraw", function(sElementName)
	if tHideElements[sElementName] then return false end
end)
