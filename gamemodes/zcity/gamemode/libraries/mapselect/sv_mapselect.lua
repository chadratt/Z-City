zb = zb or {}
zb.MapSelect = zb.MapSelect or {}

util.AddNetworkString("ZB_MapSel_Request")
util.AddNetworkString("ZB_MapSel_List")
util.AddNetworkString("ZB_MapSel_Change")
util.AddNetworkString("ZB_MapSel_Cancel")

local CHANGE_DELAY = 5

local ignoredMaps = {
    ["background01"] = true, ["background02"] = true, ["background03"] = true,
    ["background04"] = true, ["background05"] = true, ["background06"] = true,
    ["background07"] = true, ["devtest"] = true, ["credits"] = true,
    ["test_hardware"] = true, ["test_speakers"] = true, ["styleguide"] = true,
    ["intro"] = true,
}

local cachedMaps
local cachedAt = 0

local function IsValidMapName(map)
    return isstring(map) and map ~= "" and #map <= 64 and string.match(map, "^[%w_%-%.]+$") ~= nil
end

function zb.MapSelect.GetMaps(forceRefresh)
    if cachedMaps and not forceRefresh and cachedAt > CurTime() - 60 then
        return cachedMaps
    end

    local seen, list = {}, {}
    local files = file.Find("maps/*.bsp", "GAME") or {}

    for _, f in ipairs(files) do
        local map = string.StripExtension(string.lower(f))
        if not seen[map] and not ignoredMaps[map] and not string.StartWith(map, "background")
            and IsValidMapName(map) then
            seen[map] = true
            list[#list + 1] = map
        end
    end

    table.sort(list)
    cachedMaps = list
    cachedAt = CurTime()
    return list
end

local requestCD = {}
net.Receive("ZB_MapSel_Request", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    if (requestCD[ply] or 0) > CurTime() then return end
    requestCD[ply] = CurTime() + 2

    local maps = zb.MapSelect.GetMaps()

    net.Start("ZB_MapSel_List")
        net.WriteString(game.GetMap())
        net.WriteUInt(#maps, 16)
        for _, map in ipairs(maps) do
            net.WriteString(map)
        end
    net.Send(ply)
end)

local function Announce(msg)
    for _, v in player.Iterator() do
        v:ChatPrint(msg)
    end
end

net.Receive("ZB_MapSel_Change", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local map = string.lower(net.ReadString() or "")
    if not IsValidMapName(map) or not file.Exists("maps/" .. map .. ".bsp", "GAME") then
        ply:ChatPrint("[Maps] That map is not installed on the server.")
        return
    end

    zb.MapSelect.Pending = map
    Announce("[Maps] " .. ply:Nick() .. " is changing the map to " .. map .. " in " .. CHANGE_DELAY .. " seconds.")
    ServerLog(string.format("[Maps] %s (%s) changed the map to %s\n", ply:Nick(), ply:SteamID(), map))
    ply:ChatPrint("[Maps] Type !cancelmap to cancel.")

    timer.Create("ZB_MapSel_ChangeLevel", CHANGE_DELAY, 1, function()
        local target = zb.MapSelect.Pending
        zb.MapSelect.Pending = nil
        if target then
            RunConsoleCommand("changelevel", target)
        end
    end)
end)

local function CancelPending(ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    if not zb.MapSelect.Pending then
        ply:ChatPrint("[Maps] There is no pending map change.")
        return
    end

    timer.Remove("ZB_MapSel_ChangeLevel")
    Announce("[Maps] " .. ply:Nick() .. " cancelled the map change to " .. zb.MapSelect.Pending .. ".")
    zb.MapSelect.Pending = nil
end

net.Receive("ZB_MapSel_Cancel", function(len, ply)
    CancelPending(ply)
end)

COMMANDS = COMMANDS or {}
COMMANDS.cancelmap = {function(ply, args)
    if not ply:IsAdmin() then ply:ChatPrint("You don't have access") return end
    CancelPending(ply)
end, 0}

hook.Add("PlayerDisconnected", "ZB_MapSel_ClearCD", function(ply)
    requestCD[ply] = nil
end)
