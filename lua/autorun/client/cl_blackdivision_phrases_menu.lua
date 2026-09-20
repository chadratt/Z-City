

local blackdivPhraseCategories = {
    {id = "contact", name = "Contact"},
    {id = "fight", name = "Fight"},
    {id = "spread", name = "Taking Fire / Spread Out"},
    {id = "lostvisual", name = "Lost Visual"},
    {id = "enemy_grenade", name = "Enemy Grenade"},
    {id = "enemy_down", name = "Enemy Down"},
    {id = "friendly_down", name = "Man Down"},
    {id = "grenade", name = "Frag Out"},
    {id = "weap_reload", name = "Reloading"},
    {id = "hit", name = "Taking Hits"},
    {id = "death", name = "Death"},
}

local function IsBlackDiv()
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end
    return ply.PlayerClassName == "BLACK_DIVISION_TARKOV"
end

local function SendBlackdivPhrase(id)
    net.Start("blackdiv_voice_cmd")
    net.WriteString(id)
    net.SendToServer()
end

local function OpenCategoryMenu()

    local commands = {}

    for i, cat in ipairs(blackdivPhraseCategories) do
        commands[i] = {
            [1] = function()
                SendBlackdivPhrase(cat.id)
            end,
            [2] = cat.name
        }
    end

    if hg and hg.CreateRadialMenu then
        hg.CreateRadialMenu(commands)
    end
end

hook.Add("radialOptions","zzz_blackdiv_remove_duplicates",function()

    if !IsBlackDiv() then return end

    if hg and hg.radialOptions then

        local count = 0
        local last = 0

        for i,option in ipairs(hg.radialOptions) do

            if option and option[2] then

                local txt = tostring(option[2]):lower()

                if string.find(txt,"phrase") then
                    count = count + 1
                    last = i
                end

            end

        end

        if count > 1 then

            for i = #hg.radialOptions,1,-1 do

                local option = hg.radialOptions[i]

                if option and option[2] then

                    local txt = tostring(option[2]):lower()

                    if string.find(txt,"phrase") and i != last then
                        table.remove(hg.radialOptions,i)
                    end

                end
            end
        end
    end
end)

--hook
hook.Add("radialOptions", "blackdiv_phrases_menu", function()

    local ply = LocalPlayer()
    if !IsValid(ply) or !ply:Alive() then return end
    if !IsBlackDiv() then return end

    local organism = ply.organism or {}
    if organism.otrub then return end

    local tbl = {
        function(mouseClick)

            if mouseClick == 2 then
                OpenCategoryMenu()

            elseif mouseClick == 1 then

                local randomCat = table.Random(blackdivPhraseCategories)
                SendBlackdivPhrase(randomCat.id)

            end
        end,

        "Do Phrase\nRMB - Menu"
    }

    hg = hg or {}
    hg.radialOptions = hg.radialOptions or {}
    hg.radialOptions[#hg.radialOptions + 1] = tbl
end)
