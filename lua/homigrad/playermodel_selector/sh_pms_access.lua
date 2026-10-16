hg = hg or {}
hg.PMS = hg.PMS or {}
local PMS = hg.PMS

PMS.AllowedGroups = {
	vip = true,
}

PMS.AllowedModes = {
	PALEMAN = true,
	hmcd = true,
	event = true,
	hitman = true,
}

local function IsSandbox()
	return engine.ActiveGamemode() == "sandbox"
end

function PMS.HasGroupAccess(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if ply:IsAdmin() or ply:IsSuperAdmin() then return true end

	local group = string.lower(ply:GetUserGroup() or "")
	if PMS.AllowedGroups[group] then return true end

	if ply.CheckGroup then
		for g in pairs(PMS.AllowedGroups) do
			if ply:CheckGroup(g) or ply:CheckGroup(string.upper(g)) then return true end
		end
	end

	return false
end

if SERVER then
	function PMS.GetModeName()
		if not zb then return nil end
		local r = zb.CROUND
		if not r or r == "" then return nil end
		if zb.GetMode then
			return zb:GetMode(r) or r
		end
		return r
	end

	local function IsAllowedMode(name)
		local seen = {}
		while name and not seen[name] do
			if PMS.AllowedModes[name] then return true end
			seen[name] = true
			local mode = zb.modes and zb.modes[name]
			name = mode and mode.base or nil
		end
		return false
	end

	function PMS.IsModeAllowed()
		if IsSandbox() then return true end
		return IsAllowedMode(PMS.GetModeName())
	end

	timer.Create("ZC_PMS_ModeSync", 1, 0, function()
		SetGlobal2Bool("ZC_PMS_ModeAllowed", PMS.IsModeAllowed())
	end)
else
	function PMS.IsModeAllowed()
		if IsSandbox() then return true end
		return GetGlobal2Bool("ZC_PMS_ModeAllowed", false)
	end
end

function PMS.CanUse(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if IsSandbox() then return true end
	return PMS.HasGroupAccess(ply) and PMS.IsModeAllowed()
end
