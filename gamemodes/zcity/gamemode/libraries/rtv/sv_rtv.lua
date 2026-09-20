--;; ===================================
--;; RTV Modded RTVded :troll:
--;; ===================================
util.AddNetworkString("ZB_RockTheVote_start")
util.AddNetworkString("ZB_RockTheVote_vote")
util.AddNetworkString("ZB_RockTheVote_voteCLreg")
util.AddNetworkString("ZB_RockTheVote_end")
zb = zb or {}
local cooldown = {}
local votes = {}
zb.votestarted = false
local playervote = {}

local mappull = {}
local playerVoteWeight = {}

local mapWhitelist = {
    ["gm_construct"]                  = true,
    ["ttt_houndpitspub_a1"]           = true,
    ["gm_asylum"]                     = true,
    ["gm_montauk"]                    = true,
    ["mu_alone_v2"]                   = true,
    ["hmcd_rooftops_snow"]            = true,
    ["hmcd_metropolis_extended_ring"] = true,
}

local function GetMapFamily(map)
    if string.find(string.lower(map), "smalltown") then
        return "smalltown"
    end
    return nil
end

local function GetFamilyMaps(family)
    local familyMaps = {}
    for _, map in ipairs(mappull) do
        if GetMapFamily(map) == family then
            table.insert(familyMaps, map)
        end
    end
    return familyMaps
end

local prefixWeights = {
    ["ttt"] = 18, ["hmcd"] = 19, ["mu"] = 18, ["ze"] = 0,
    ["zs"] = 9,  ["tdm"] = 5,  ["zb"] = 0,  ["zbattle"] = 0,
    ["gm"] = 20, ["ph"] = 11, ["cs"] = 1,  ["de"] = 1
}

local function GetSafeServerName()
    local hostname = GetConVar("hostname"):GetString() or "unknown"
    hostname = hostname:gsub("[^%w_-]", "_"):sub(1, 20)
    return hostname
end


local function GetDataPath(fileName)
    local serverName = GetSafeServerName()
    return "zbattle/" .. serverName .. "/" .. fileName
end


local function EnsureDataDirectory()
    local serverName = GetSafeServerName()
    if not file.Exists("zbattle", "DATA") then
        file.CreateDir("zbattle")
    end
    if not file.Exists("zbattle/" .. serverName, "DATA") then
        file.CreateDir("zbattle/" .. serverName)
    end
end


EnsureDataDirectory()

local mapPopularity = {}
local popularityPath = GetDataPath("MapPopularity.json")
if file.Exists(popularityPath, "DATA") then
    local data = file.Read(popularityPath, "DATA")
    mapPopularity = util.JSONToTable(data) or {}
end

local function getmaps()
    table.Empty(mappull)

    for map, allowed in pairs(mapWhitelist) do
        if allowed and file.Exists("maps/" .. map .. ".bsp", "GAME") then
            table.insert(mappull, map)
        end
    end
end

local function getWeightedRandomMapPrefix()
    local totalWeight = 0
    for prefix, weight in pairs(prefixWeights) do
        totalWeight = totalWeight + weight
    end

    local randomWeight = math.random() * totalWeight
    for prefix, weight in pairs(prefixWeights) do
        if randomWeight < weight then
            return prefix
        end
        randomWeight = randomWeight - weight
    end
end

local function getMapsByPrefix(prefix)
    local prefixMaps = {}
    for _, map in ipairs(mappull) do
        if map:StartWith(prefix) then
            table.insert(prefixMaps, map)
        end
    end
    return prefixMaps
end

hook.Add("InitPostEntity", "zb_GetMaps", function()
    zb.votestarted = false
    getmaps()
end)

local function BuildVotersByMap()
    local voters = {}
    for idx, map in pairs(playervote) do
        local voter = Entity(idx)
        if IsValid(voter) and voter:IsPlayer() then
            voters[map] = voters[map] or {}
            table.insert(voters[map], voter:SteamID64())
        end
    end
    return voters
end

function zb.BroadcastRTVState()
    net.Start("ZB_RockTheVote_voteCLreg")
        net.WriteTable(votes)
        net.WriteTable(BuildVotersByMap())
    net.Broadcast()
end

net.Receive("ZB_RockTheVote_vote", function(len, ply)
    if not zb.votestarted then return end
    if cooldown[ply:EntIndex()] and cooldown[ply:EntIndex()] > CurTime() then return end

    cooldown[ply:EntIndex()] = CurTime() + 1

    local playerIdx = ply:EntIndex()

    if playervote[playerIdx] and votes[playervote[playerIdx]] then
        votes[playervote[playerIdx]] = votes[playervote[playerIdx]] - (playerVoteWeight[playerIdx] or 1)
        if votes[playervote[playerIdx]] <= 0 then
            votes[playervote[playerIdx]] = nil
        end
    end

    local map = net.ReadString()
    if not map or map == "" then return end
    if not table.HasValue(mappull, map) then return end
    playervote[playerIdx] = map

    playerVoteWeight[playerIdx] = 1

    votes[map] = (votes[map] or 0) + playerVoteWeight[playerIdx]

    zb.BroadcastRTVState()
end)

hook.Add("PlayerDisconnected", "ZB_RTV_ClearVoteOnDisconnect", function(ply)
    local idx = ply:EntIndex()
    if playervote[idx] then
        local map = playervote[idx]
        if votes[map] then
            votes[map] = math.max((votes[map] or 0) - (playerVoteWeight[idx] or 1), 0)
            if votes[map] <= 0 then votes[map] = nil end
        end
        playervote[idx] = nil
        playerVoteWeight[idx] = nil

        if zb.votestarted then
            zb.BroadcastRTVState()
        end
    end
end)


local endStarted = false

function zb.EndRTV()
    if endStarted then return end

    local winmap = table.GetWinningKey(votes)
    if not winmap then
		winmap = "random"
	end

    if winmap == "random" then
        winmap = mappull[math.random(#mappull)]
    end

    local mapFamily = GetMapFamily(winmap)
    
    mapPopularity[winmap] = math.min((mapPopularity[winmap] or 0) + 5, 100)
    
    local PlayedMaps = {}
    local playedMapsPath = GetDataPath("PlayedMaps.json")
    if file.Exists(playedMapsPath, "DATA") then
        PlayedMaps = util.JSONToTable(file.Read(playedMapsPath, "DATA")) or {}
    end
    
    if not table.HasValue(PlayedMaps, winmap) then
        table.insert(PlayedMaps, 1, winmap)
        
        if mapFamily then
            local familyMaps = GetFamilyMaps(mapFamily)
            for _, familyMap in ipairs(familyMaps) do
                if familyMap ~= winmap and not table.HasValue(PlayedMaps, familyMap) then
                    table.insert(PlayedMaps, 1, familyMap)
                    mapPopularity[familyMap] = math.min((mapPopularity[familyMap] or 0) + 5, 100)
                end
            end
        end

        if #PlayedMaps > 20 then
            local lastFiveMaps = {}
            for i = math.max(1, #PlayedMaps - 5 + 1), #PlayedMaps do
                if i > 1 then 
                    table.insert(lastFiveMaps, PlayedMaps[i])
                end
            end
            
            PlayedMaps = {winmap}
            for _, map in ipairs(lastFiveMaps) do
                table.insert(PlayedMaps, map)
            end
        end
        
        file.Write(playedMapsPath, util.TableToJSON(PlayedMaps))
    end
    
    for map, pop in pairs(mapPopularity) do
        if map ~= winmap and not table.HasValue(PlayedMaps, map) then
            mapPopularity[map] = math.max(pop - 2, 0)
        end
    end
    
    file.Write(popularityPath, util.TableToJSON(mapPopularity))

    net.Start("ZB_RockTheVote_end")
        net.WriteString(winmap)
    net.Broadcast()

    endStarted = true

    timer.Simple(3, function()
        --zb.votestarted = false
        table.Empty(votes)
        table.Empty(playervote)
        table.Empty(playerVoteWeight) 
        RunConsoleCommand("changelevel", winmap) --;; Gavnoooooo
    end)
end

local rtvtime = 0
function zb.ThinkRTV()
    if not zb.votestarted then return end
    if rtvtime < CurTime() then
        zb.EndRTV()
    end
end

--;; ===================================
--;; ВЕЛИКАЯ МЕГА СИСТЕМА ГОВНА:
--;; Функция для выбора "уникальных" префиксов
--;; с учётом того, что у них есть >=4 доступных карт
--;; (т. е. не в PlayedMaps)
--;; ===================================
local function getUniquePrefixes(playedMaps)
    local chosen = {}
    local attempts = 0

    while #chosen < 3 do
        local prefix = getWeightedRandomMapPrefix()
        if prefix then
            if not table.HasValue(chosen, prefix) then
                local prefixMaps = getMapsByPrefix(prefix)
                local validCount = 0
                for _, m in ipairs(prefixMaps) do
                    if not table.HasValue(playedMaps, m) then
                        validCount = validCount + 1
                    end
                end

                if validCount >= 2 then
                    table.insert(chosen, prefix)
                end
            end
        end

        attempts = attempts + 1
        if attempts > 300 then
            break
        end
    end

    return chosen
end

local function getMapWeight(map)
    local pop = mapPopularity[map] or 0
    return 1 - (pop / 100) 
end

local MAPS_IN_POOL = 6
local MAPS_PER_PREFIX = 2

function zb.StartRTV(time)
    if zb.votestarted then return end
    
    getmaps()

    rtvtime = CurTime() + (time or 15)

    local PlayedMaps = {}
    local playedMapsPath = GetDataPath("PlayedMaps.json")
    if file.Exists(playedMapsPath, "DATA") then
        PlayedMaps = util.JSONToTable(file.Read(playedMapsPath, "DATA"))
    end
    if not PlayedMaps then
        PlayedMaps = {}
    end

    --;; Сначала попытаемся выбрать 3 "уникальных" префикса 
    --;; через взвешенный рандом. В каждом должно быть >=4 карт, 
    --;; которые НЕ в PlayedMaps.
    local selectedPrefixes = getUniquePrefixes(PlayedMaps)

    if #selectedPrefixes < 3 then
        local possible = {}
        for prefix, weight in pairs(prefixWeights) do
            if weight > 0 then
                local prefixMaps = getMapsByPrefix(prefix)
                local validCount = 0
                for _, m in ipairs(prefixMaps) do
                    if not table.HasValue(PlayedMaps, m) then
                        validCount = validCount + 1
                    end
                end
                if validCount >= 2 then
                    table.insert(possible, prefix)
                end
            end
        end

        selectedPrefixes = {}
        table.SortByKey(possible)
        for i = 1, 3 do
            if possible[i] then
                table.insert(selectedPrefixes, possible[i])
            end
        end
    end

    if #selectedPrefixes < 3 then
        selectedPrefixes = {"gm", "ttt", "cs"}
    end

    local finalmaps = {}
    for _, prefix in ipairs(selectedPrefixes) do
        local prefixMaps = getMapsByPrefix(prefix)
        local validMaps = {}
        for _, m in ipairs(prefixMaps) do
            if not table.HasValue(PlayedMaps, m) then
                table.insert(validMaps, m)
            end
        end
        for i = 1, MAPS_PER_PREFIX do
            if #validMaps == 0 then break end

            local totalWeight = 0
            for _, m in ipairs(validMaps) do
                totalWeight = totalWeight + getMapWeight(m)
            end

            local rnd = math.random() * totalWeight
            local selectedIndex = nil
            for idx, m in ipairs(validMaps) do
                local weight = getMapWeight(m)
                if rnd < weight then
                    selectedIndex = idx
                    break
                else
                    rnd = rnd - weight
                end
            end

            if selectedIndex then
                table.insert(finalmaps, validMaps[selectedIndex])
                table.remove(validMaps, selectedIndex)
            end
        end
    end

    if #finalmaps < MAPS_IN_POOL then
        local remaining = {}
        for _, m in ipairs(mappull) do
            if not table.HasValue(finalmaps, m) and not table.HasValue(PlayedMaps, m) then
                table.insert(remaining, m)
            end
        end

        if #remaining == 0 then
            for _, m in ipairs(mappull) do
                if not table.HasValue(finalmaps, m) then
                    table.insert(remaining, m)
                end
            end
        end

        local attempts = 0
        while #finalmaps < MAPS_IN_POOL and #remaining > 0 do
            attempts = attempts + 1
            if attempts > 300 then
                break
            end

            local totalWeight = 0
            for _, m in ipairs(remaining) do
                totalWeight = totalWeight + getMapWeight(m)
            end

            local rnd = math.random() * totalWeight
            local selectedIndex = nil
            for idx, m in ipairs(remaining) do
                local weight = getMapWeight(m)
                if rnd < weight then
                    selectedIndex = idx
                    break
                else
                    rnd = rnd - weight
                end
            end

            if not selectedIndex then selectedIndex = 1 end

            table.insert(finalmaps, remaining[selectedIndex])
            table.remove(remaining, selectedIndex)
        end
    end

    if #finalmaps == 0 and #mappull > 0 then
        table.insert(finalmaps, mappull[math.random(#mappull)])
    end

    while #finalmaps > MAPS_IN_POOL do
        table.remove(finalmaps)
    end

    net.Start("ZB_RockTheVote_start")
        net.WriteTable(finalmaps)
        net.WriteFloat(rtvtime)
    net.Broadcast()

    zb.votestarted = true
    endStarted = false


    hook.Add("Think", "RTVThink", zb.ThinkRTV)
end

util.AddNetworkString("RTVMenu")
function zb.RTVMenu(ply)
    net.Start("RTVMenu")
    net.Send(ply)
end


COMMANDS.forcertv = {function(ply, args)
	if not ply:IsAdmin() then ply:ChatPrint("You don't have access") return end
		zb.StartRTV(15)
	end,
	0
}

--;; чут чут переписал 
local rtvVotes = {} -- Dagestani fleas heard lezginka and trampled a cat to death
local rtvTimeout = nil


function zb.ClearRTVVotes()
    rtvVotes = {}
    if rtvTimeout then
        timer.Remove("RTVTimeout")
        rtvTimeout = nil
    end
end

-- ДЕКА КАК ТЫ ТАК СМОГ СДЕЛАТЬ, ЧТО ОНО СРЕТ БЕЗ ОСТНАОВКИ МНЕ ПРИНТОМ, ЧТО РТВ СОСТОИТСЯ, ГДЕ ТЫ НАСРАЛ 
function zb.CheckRTVVotes(needPrint)
    local votesNeeded = math.ceil(#player.GetAll() / 2)
    local votes = table.Count(rtvVotes)
    
    if votes >= votesNeeded then
        if needPrint then
            for _, v in player.Iterator() do
                v:ChatPrint("Enough votes to change the map. RTV will be on next round.")
            end
        end
        
        return true
    end
    
    return false
end
local function rtv(ply, args)
    --print(zb.votestarted)
	if zb.votestarted then
		zb.RTVMenu(ply)
		return
	end

    local steamID = ply:SteamID()
    
    if rtvVotes[steamID] then
        rtvVotes[steamID] = nil
        ply:ChatPrint("You canceled your vote for map change.")
        
        local votesNeeded = math.ceil(#player.GetAll() / 2)
        local votes = table.Count(rtvVotes)
        local remaining = votesNeeded - votes
        
        --for _, v in pairs(player.GetAll()) do
        --    if v ~= ply then БЕСМЫСЛЕННЫЙ СПАМ
        --        v:ChatPrint(ply:Nick() .. " canceled their vote for map change. " .. remaining .. " more votes needed.")
        --    end
        --end
        
        return
    end
    --;; Дебилы
    --[[if table.Count(rtvVotes) == 0 and not rtvTimeout then
        rtvTimeout = true
        timer.Create("RTVTimeout", 1800, 1, function()
            if table.Count(rtvVotes) > 0 then
                for _, v in pairs(player.GetAll()) do
                    v:ChatPrint("Map change votes have been reset due to timeout (30 minutes).")
                end
                zb.ClearRTVVotes()
            end
        end)
    end--]]
	
    rtvVotes[steamID] = true
    
    local votesNeeded = math.ceil(#player.GetAll() / 2)
    local votes = table.Count(rtvVotes)
    local remaining = votesNeeded - votes
    
    for _, v in player.Iterator() do
        if remaining != 0 then
            v:ChatPrint(
                ply:Nick() .. " voted for map change. " .. 
                remaining .. " more votes needed. Type !rtv again to cancel your vote."
            )
        end
    end

    if zb.CheckRTVVotes(true) then
        return
    end 
end

COMMANDS.rtv = {rtv, 0}
COMMANDS.кем = {rtv, 0}

hook.Add("ShutDown", "ResetRTVVotesOnMapChange", zb.ClearRTVVotes)
hook.Add("PostGamemodeLoaded", "InitializeRTVSystem", function()
    zb.ClearRTVVotes()
end)

hook.Add("PlayerDisconnected", "CheckRTVAfterDisconnect", function(ply)
    if rtvVotes[ply:SteamID()] then
        rtvVotes[ply:SteamID()] = nil
        
        --for _, v in pairs(player.GetAll()) do
        --   v:ChatPrint(ply:Nick() .. " left the server (their RTV vote was removed).")
        --end
        
        timer.Simple(0.1, zb.CheckRTVVotes)
    end
end)
