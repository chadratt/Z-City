zb = zb or {}
zb.AO = zb.AO or {}
function zb.AO.GetCharacterName(ent)
    if not IsValid(ent) then return "Unknown" end
    local fallback = (ent.Nick and ent:Nick()) or "Unknown"
    return ent:GetNWString("PlayerName", fallback)
end
function zb.AO.GetClassName(ply)
    if not IsValid(ply) then return "None" end
    if not ply.PlayerClassName or ply.PlayerClassName == "" then return "None" end
    return ply.PlayerClassName
end
