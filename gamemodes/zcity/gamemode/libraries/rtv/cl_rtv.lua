-- Values
local maps = {}
local time = 0
local votes = {}
local voters = {}
local winmap = ""
local rtvStarted = false
local rtvEnded = false

local VoteCD = 0

local RTV_VOTE_DURATION = 15

local COLS, ROWS = 3, 2
local GRID_SPACING = 8

-- RTV CL Functions
local RTVMenu
local GridHolder
local tiles = {}
local activeTiles = {}

local function FormatMapName(map)
    local txt = string.Explode("_", map)
    table.remove(txt, 1)
    if #txt == 0 then return map end
    txt[1] = string.upper(string.Left(txt[1], 1)) .. string.sub(txt[1], 2)
    return table.concat(txt, " ")
end

local function GetMapIcon(map)
    local icon = Material("maps/thumb/" .. map .. ".png")
    if icon:IsError() then
        return nil
    end
    return icon
end

local function LayoutGrid()
    if not IsValid(GridHolder) then return end

    local w, h = GridHolder:GetSize()

    local tileW = (w - GRID_SPACING * (COLS - 1)) / COLS
    local tileH = (h - GRID_SPACING * (ROWS - 1)) / ROWS

    for i, tile in ipairs(tiles) do
        if IsValid(tile) then
            local col = (i - 1) % COLS
            local row = math.floor((i - 1) / COLS)
            tile:SetPos(col * (tileW + GRID_SPACING), row * (tileH + GRID_SPACING))
            tile:SetSize(tileW, tileH)
        end
    end
end

function zb.SyncTiles()
    for map, tile in pairs(activeTiles) do
        if IsValid(tile) then
            tile:SetVoteCount(votes[map] or 0)
            tile:SetVoters(voters[map] or {})
            tile:SetWinning(winmap ~= "" and map == winmap)
        end
    end
end

function zb.RTVMenu()
    if IsValid(RTVMenu) then
        RTVMenu:Remove()
    end

    table.Empty(tiles)
    table.Empty(activeTiles)

    system.FlashWindow()

    RTVMenu = vgui.Create("ZB_RTVMenu")
    RTVMenu:SetSize(math.min(ScrW() * 0.8, 1600), ScrH() * 0.85)
    RTVMenu:Center()
    RTVMenu:SetTitle("")
    RTVMenu:SetBackgroundBlur(true)
    RTVMenu:ShowCloseButton(false)
    RTVMenu:SetDraggable(false)
    RTVMenu:MakePopup()
    RTVMenu:SetKeyboardInputEnabled(false)
    RTVMenu.EndTime = CurTime() + RTV_VOTE_DURATION

    GridHolder = vgui.Create("DPanel", RTVMenu)
    GridHolder:Dock(FILL)
    GridHolder:DockMargin(15, ScrH() * 0.08, 15, 15)
    GridHolder.Paint = function() end
    GridHolder.PerformLayout = function(self, w, h) LayoutGrid() end

    for i = 1, COLS * ROWS do
        local tile = vgui.Create("ZB_RTVMapTile", GridHolder)
        local map = maps[i]

        if map then
            tile:SetMapData(map, FormatMapName(map), GetMapIcon(map))
            activeTiles[map] = tile

            function tile:DoClick()
                if self.Disabled then return end
                if VoteCD > CurTime() then return end

                net.Start("ZB_RockTheVote_vote")
                    net.WriteString(self.Map)
                net.SendToServer()

                VoteCD = CurTime() + 1
            end
        else
            tile:SetTileDisabled(true)
        end

        tiles[i] = tile
    end

    zb.SyncTiles()
end

function zb.StartRTV()
    maps = net.ReadTable()
    time = net.ReadFloat()

    votes = {}
    voters = {}
    winmap = ""

    zb.RTVMenu()
    rtvStarted = true
    rtvEnded = false
end

net.Receive("RTVMenu", function()
    zb.RTVMenu()
end)

function zb.RTVregVote()
    votes = net.ReadTable()
    voters = net.ReadTable()
    zb.SyncTiles()
end

function zb.EndRTV()
    winmap = net.ReadString()
    rtvEnded = true

    zb.SyncTiles()

    if IsValid(RTVMenu) then
        timer.Simple(2, function()
            if IsValid(RTVMenu) then
                RTVMenu:Remove()
            end
        end)
    end
end

-- NETWORKING

net.Receive("ZB_RockTheVote_start", zb.StartRTV)
net.Receive("ZB_RockTheVote_voteCLreg", zb.RTVregVote)
net.Receive("ZB_RockTheVote_end", zb.EndRTV)
