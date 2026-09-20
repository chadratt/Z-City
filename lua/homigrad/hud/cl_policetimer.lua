hook.Add("HUDPaint", "HG_PoliceSpawnTimer", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if ply:Alive() then return end

	if not GetGlobalBool("HG_PoliceAllowed", false) then return end
	if GetGlobalBool("HG_PoliceSpawned", false) then return end

	local spawnTime = GetGlobalFloat("HG_PoliceSpawnTime", 0)
	local remaining = spawnTime - CurTime()

	if remaining <= 0 then return end

	local mins = math.floor(remaining / 60)
	local secs = math.floor(remaining % 60)
	local text = string.format("Police arrive in %d:%02d", mins, secs)

	local w, h = ScrW(), ScrH()
	local x, y = w / 2, h - ScreenScaleH(76)

	draw.SimpleText(text, "HomigradFont", x + 1, y + 1, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(text, "HomigradFont", x, y, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
