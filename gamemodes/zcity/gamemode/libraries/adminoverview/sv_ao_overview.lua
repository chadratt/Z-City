zb = zb or {}
zb.AO = zb.AO or {}
util.AddNetworkString("ZB_AO_Subscribe")
util.AddNetworkString("ZB_AO_Snapshot")
util.AddNetworkString("ZB_AO_KickBan")
util.AddNetworkString("ZB_AO_Notify")
zb.AO.Subscribers = zb.AO.Subscribers or {}
zb.AO.DeathInfo = zb.AO.DeathInfo or {}
local function ResolveKiller(victim, hookAttacker)
    local best, bestHarm = nil, 0
    local harmTable = zb.HarmDone and zb.HarmDone[victim]
    if harmTable then
        for attacker, harm in pairs(harmTable) do
            if IsValid(attacker) and harm > bestHarm then
                best, bestHarm = attacker, harm
            end
        end
    end
    if not IsValid(best) and IsValid(hookAttacker) then
        best = hookAttacker
    end
    if not IsValid(best) then
        return { name = "World / Environment", steamid = "N/A" }
    end
    if best == victim then
        return { name = victim:Nick() .. " (Suicide)", steamid = victim:SteamID() or "N/A" }
    end
    if best:IsPlayer() then
        return { name = best:Nick(), steamid = best:SteamID() or "N/A" }
    elseif best.GetClass then
        return { name = best:GetClass(), steamid = "N/A" }
    end
    return { name = "Unknown", steamid = "N/A" }
end
hook.Add("PlayerDeath", "ZB_AO_TrackDeath", function(victim, inflictor, attacker)
    timer.Simple(0.2, function()
        if not IsValid(victim) then return end
        zb.AO.DeathInfo[victim] = ResolveKiller(victim, attacker)
    end)
end)
hook.Add("PlayerSpawn", "ZB_AO_ClearDeath", function(ply)
    zb.AO.DeathInfo[ply] = nil
end)
hook.Add("PlayerDisconnected", "ZB_AO_ClearSubscriber", function(ply)
    zb.AO.Subscribers[ply] = nil
    zb.AO.DeathInfo[ply] = nil
end)
local function GetDisplayPos(ply)
    if not ply:Alive() then
        local corpse = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll
            or (hg.ragdollFake and IsValid(hg.ragdollFake[ply]) and hg.ragdollFake[ply])
        if IsValid(corpse) then
            return corpse:GetPos()
        end
    end
    return ply:GetPos()
end
local function BuildAndSendSnapshot(targets)
    if not targets then
        targets = {}
        for ply in pairs(zb.AO.Subscribers) do
            if IsValid(ply) and ply:IsAdmin() then
                targets[#targets + 1] = ply
            end
        end
        if #targets == 0 then return end
    end
    local plys = player.GetAll()
    net.Start("ZB_AO_Snapshot")
        net.WriteUInt(#plys, 8)
        for _, p in ipairs(plys) do
            local alive = p:Alive()
            local death = (not alive) and zb.AO.DeathInfo[p]
            net.WriteEntity(p)
            net.WriteString(p:SteamID() or "N/A")
            net.WriteString(p:Nick())
            net.WriteString(zb.AO.GetCharacterName(p))
            net.WriteString(zb.AO.GetClassName(p))
            net.WriteBool(alive)
            net.WriteVector(GetDisplayPos(p))
            net.WriteBool(death and true or false)
            if death then
                net.WriteString(death.name)
                net.WriteString(death.steamid)
            end
        end
    net.Send(targets)
end
zb.AO.PushSnapshot = BuildAndSendSnapshot
net.Receive("ZB_AO_Subscribe", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local subscribing = net.ReadBool()
    if subscribing then
        zb.AO.Subscribers[ply] = true
        BuildAndSendSnapshot({ ply })
    else
        zb.AO.Subscribers[ply] = nil
    end
end)
timer.Create("ZB_AO_SnapshotTick", 0.5, 0, function()
    BuildAndSendSnapshot()
end)
net.Receive("ZB_AO_KickBan", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local action = net.ReadString()
    local minutes = net.ReadString()
    local reason = net.ReadString()
    local count = net.ReadUInt(8)
    local targets = {}
    for i = 1, count do
        local target = net.ReadEntity()
        if IsValid(target) and target:IsPlayer() then
            targets[#targets + 1] = target
        end
    end
    for _, target in ipairs(targets) do
        if action == "kick" then
            concommand.Run(ply, "ulx", { "kick", target:SteamID(), reason })
        elseif action == "ban" then
            concommand.Run(ply, "ulx", { "ban", target:SteamID(), minutes, reason })
        end
    end
end)
net.Receive("ZB_AO_Notify", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local msg = net.ReadString()
    local clr = net.ReadColor()
    local shaky = net.ReadBool()
    local count = net.ReadUInt(8)
    for i = 1, count do
        local target = net.ReadEntity()
        if IsValid(target) and target:IsPlayer() and hg.AdminNotify then
            hg.AdminNotify(target, msg, clr, shaky)
        end
    end
end)
