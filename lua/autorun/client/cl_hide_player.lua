if not CLIENT then return end

ZB_ScoreboardFilter = ZB_ScoreboardFilter or {}
ZB_ScoreboardFilter.predicates = ZB_ScoreboardFilter.predicates or {}
ZB_ScoreboardFilter.Register = ZB_ScoreboardFilter.Register or function(id, fn)
    ZB_ScoreboardFilter.predicates[id] = fn
end

ZB_ScoreboardFilter.Register("hidden", function(ply)
    return ply:GetNWBool("zb_hidden", false)
end)

hook.Add("PostDrawHUD", "zb_hide_player_spec_blank", function()
    local lp = LocalPlayer()
    if not IsValid(lp) or lp:Alive() then return end

    local spect = lp:GetNWEntity("spect")
    if not IsValid(spect) then return end
    if not spect:GetNWBool("zb_hidden", false) then return end

    cam.Start2D()
    surface.SetFont("HomigradFont")

    local txt1 = "Spectating player: Unknown"
    local w1, h1 = surface.GetTextSize(txt1)
    local x1 = ScrW() / 2 - w1 / 2
    local y1 = ScrH() / 8 * 7

    local txt2 = "In-game name: Unknown"
    local w2, h2 = surface.GetTextSize(txt2)
    local x2 = ScrW() / 2 - w2 / 2
    local y2 = y1 + h1

    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(math.min(x1, x2) - 6, y1 - 2, math.max(w1, w2) + 12, h1 + h2 + 4)

    surface.SetTextColor(255, 255, 255, 255)
    surface.SetTextPos(x1, y1)
    surface.DrawText(txt1)
    surface.SetTextPos(x2, y2)
    surface.DrawText(txt2)
    cam.End2D()
end)
-- designed and realized by alagri & omnissiah respectively
