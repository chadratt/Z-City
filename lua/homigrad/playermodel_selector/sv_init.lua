COMMANDS = COMMANDS or {}
hg = hg or {}

util.AddNetworkString("ZC_PMS_Apply")
util.AddNetworkString("ZC_PMS_Reset")
util.AddNetworkString("ZC_PMS_Open")
util.AddNetworkString("ZC_PMS_Armor")

local function CanUse(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if engine.ActiveGamemode() == "sandbox" then return true end
	return ply:IsAdmin()
end

hg.PMSOverrides = hg.PMSOverrides or {}

local function ApplyPMSOverride(ply, data)
	if not IsValid(ply) or not istable(data) then return end

	util.PrecacheModel(data.mdl)

	local Appearance = ply.CurAppearance or (hg.Appearance and hg.Appearance.GetRandomAppearance())
	if Appearance then Appearance.AColthes = "" end
	ply:SetNetVar("Accessories", "")
	ply:SetModel(data.mdl)
	ply:SetBodyGroups("00000000000000000000")
	ply:SetSubMaterial()
	ply:SetPlayerColor(ply:GetNWVector("PlayerColor", vector_origin))
	ply:SetSkin(math.Clamp(data.skin or 0, 0, math.max(ply:SkinCount() - 1, 0)))

	local groups = data.groups or {}
	for k = 0, ply:GetNumBodyGroups() - 1 do
		ply:SetBodygroup(k, groups[k + 1] or 0)
	end

	if data.nick and data.nick ~= "" and hg.Appearance and hg.Appearance.IsInvalidName and not hg.Appearance.IsInvalidName(data.nick) then
		ply:SetNWString("PlayerName", data.nick)
	end
end

local LOG_DIR = "PMselectorLogs"

local function LogPMSAction(ply, mdl, nick)
	if not IsValid(ply) then return end

	file.CreateDir(LOG_DIR)

	local fileName = LOG_DIR .. "/" .. os.date("%Y_%m_%d") .. ".txt"
	local line = string.format(
		"[%s] %s (%s) applied model '%s'%s\n",
		os.date("%H:%M:%S"),
		ply:Nick(),
		ply:SteamID(),
		mdl,
		(nick and nick ~= "") and (" | Custom name: '" .. nick .. "'") or ""
	)

	file.Append(fileName, line)
end

net.Receive("ZC_PMS_Apply", function(len, ply)
	if not CanUse(ply) then return end
	if not ply:Alive() then ply:ChatPrint("You must be alive to change your model") return end
	if (ply.zc_pms_next or 0) > CurTime() then return end
	ply.zc_pms_next = CurTime() + 0.15

	local mdl = net.ReadString()
	local skin = net.ReadUInt(8)
	local groupsStr = net.ReadString()
	local nick = net.ReadString()

	if not isstring(mdl) or not string.StartsWith(mdl, "models/") or not string.EndsWith(mdl, ".mdl") then return end
	if IsUselessModel(mdl) then return end

	local groupsExploded = string.Explode(" ", groupsStr or "")
	local groups = {}
	for i, v in ipairs(groupsExploded) do
		groups[i] = tonumber(v) or 0
	end

	local data = { mdl = mdl, skin = skin, groups = groups, nick = nick }

	ApplyPMSOverride(ply, data)

	hg.PMSOverrides[ply:SteamID64()] = data

	LogPMSAction(ply, mdl, nick)
end)

net.Receive("ZC_PMS_Armor", function(len, ply)
	if not CanUse(ply) then return end
	ply:SetNetVar("HideArmorRender", net.ReadBool())
end)

net.Receive("ZC_PMS_Reset", function(len, ply)
	if not CanUse(ply) then return end
	if not ply:Alive() then return end

	hg.PMSOverrides[ply:SteamID64()] = nil

	ApplyAppearance(ply, nil, nil, nil, true)
	ply:ChatPrint("Appearance restored")
end)

hook.Add("PlayerSpawn", "ZC_PMS_PersistAppearance", function(ply)
	local data = hg.PMSOverrides[ply:SteamID64()]
	if not data then return end

	timer.Simple(0, function()
		if not IsValid(ply) then return end
		ApplyPMSOverride(ply, data)
	end)
end)

local function OpenSelector(ply)
	if not CanUse(ply) then
		if IsValid(ply) then ply:ChatPrint("You don't have access") end
		return
	end

	net.Start("ZC_PMS_Open")
	net.Send(ply)
end

COMMANDS.models = {function(ply, args)
	OpenSelector(ply)
end, 0}

COMMANDS.pms = COMMANDS.models
COMMANDS.modelselector = COMMANDS.models
