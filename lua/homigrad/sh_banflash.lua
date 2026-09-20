if SERVER then

	util.AddNetworkString("ZB_BanFlash")

	local function ExtractAdminName(raw)
		if not raw or raw == "" or raw == "(Console)" then return "Console" end
		local name = string.match(raw, "^(.-)%(.+%)$")
		if name and name ~= "" then return name end
		return raw
	end

	local function FormatExpiration(unban)
		unban = tonumber(unban) or 0
		if unban <= 0 then return "Never (Permanent)" end
		return os.date("%b %d, %Y - %I:%M %p", unban)
	end

	local function BroadcastBanFlash(bannedName, reason, expiration, adminName)
		net.Start("ZB_BanFlash")
			net.WriteString(bannedName or "Unknown")
			net.WriteString(reason or "No reason given")
			net.WriteString(expiration or "Never (Permanent)")
			net.WriteString(adminName or "Console")
		net.Broadcast()
	end

	hook.Add("ULibPlayerBanned", "ZB_BanFlash_ULibBan", function(steamid, banData)
		if not istable(banData) then return end

		local bannedName = banData.name or steamid or "Unknown"
		local reason = banData.reason or "No reason given"
		local expiration = FormatExpiration(banData.unban)
		local adminName = ExtractAdminName(banData.modified_admin or banData.admin)

		BroadcastBanFlash(bannedName, reason, expiration, adminName)
	end)

	concommand.Add("zb_banflash_test", function(ply, cmd, args)
		if IsValid(ply) and not ply:IsAdmin() then return end
		BroadcastBanFlash(
			args[1] or "TestSubject",
			args[2] or "Being a test dummy",
			args[3] or "Never (Permanent)",
			IsValid(ply) and ply:Nick() or "Console"
		)
	end)

else -- CLIENT

	surface.CreateFont("ZB_BanFlashFontTitle", {
		font = "VCR OSD Mono",
		extended = true,
		size = ScreenScale(13),
		weight = 700,
		antialias = true,
	})

	surface.CreateFont("ZB_BanFlashFontBody", {
		font = "VCR OSD Mono",
		extended = true,
		size = ScreenScale(8),
		weight = 400,
		antialias = true,
	})

	local FLASH_IN_TIME = 0.06
	local FLASH_HOLD_TIME = 0.05
	local FLASH_OUT_TIME = 0.45
	local FLASH_MAX_ALPHA = 130
	local FLASH_COLOR = Color(190, 190, 190)

	local BANNER_SLIDE_TIME = 0.45
	local BANNER_HOLD_TIME = 5.5
	local BANNER_FADE_TIME = 0.6
	local BANNER_PADDING_X = 22
	local BANNER_PADDING_Y = 16
	local BANNER_LINE_GAP = 5
	local BANNER_TOP_MARGIN = 24

	local function EaseOutCubic(t) return 1 - (1 - t) ^ 3 end
	local function EaseInCubic(t) return t ^ 3 end
	local function EaseOutQuad(t) return 1 - (1 - t) ^ 2 end

	local flashStartTime = nil

	local function TriggerFlash()
		flashStartTime = CurTime()
	end

	local function GetFlashAlpha()
		if not flashStartTime then return 0 end
		local elapsed = CurTime() - flashStartTime
		local total = FLASH_IN_TIME + FLASH_HOLD_TIME + FLASH_OUT_TIME
		if elapsed >= total then
			flashStartTime = nil
			return 0
		end
		if elapsed <= FLASH_IN_TIME then
			return FLASH_MAX_ALPHA * EaseOutQuad(elapsed / FLASH_IN_TIME)
		elseif elapsed <= FLASH_IN_TIME + FLASH_HOLD_TIME then
			return FLASH_MAX_ALPHA
		else
			local t = (elapsed - FLASH_IN_TIME - FLASH_HOLD_TIME) / FLASH_OUT_TIME
			return FLASH_MAX_ALPHA * (1 - EaseInCubic(t))
		end
	end

	local function DrawBanFlash()
		local alpha = GetFlashAlpha()
		if alpha <= 0 then return end
		surface.SetDrawColor(FLASH_COLOR.r, FLASH_COLOR.g, FLASH_COLOR.b, alpha)
		surface.DrawRect(0, 0, ScrW(), ScrH())
	end

	ZB_BanFlash = ZB_BanFlash or {}
	ZB_BanFlash.Queue = ZB_BanFlash.Queue or {}
	ZB_BanFlash.Current = ZB_BanFlash.Current or nil

	local function PlayBanSound()
		sound.PlayFile("sound/anarchy_core/ban.mp3", "noblock noplay", function(station)
			if IsValid(station) then
				station:SetVolume(1)
				station:Play()
			end
		end)
	end

	net.Receive("ZB_BanFlash", function()
		local bannedName = net.ReadString()
		local reason = net.ReadString()
		local expiration = net.ReadString()
		local adminName = net.ReadString()

		TriggerFlash()
		PlayBanSound()

		table.insert(ZB_BanFlash.Queue, {
			name = bannedName,
			reason = reason,
			expiration = expiration,
			admin = adminName,
		})
	end)

	hook.Add("Think", "ZB_BanFlash_ProcessQueue", function()
		if ZB_BanFlash.Current then return end
		local nextData = table.remove(ZB_BanFlash.Queue, 1)
		if not nextData then return end
		nextData.startTime = CurTime()
		ZB_BanFlash.Current = nextData
	end)

	local function DrawBanBanner()
		local data = ZB_BanFlash.Current
		if not data then return end

		local elapsed = CurTime() - data.startTime
		local totalTime = BANNER_SLIDE_TIME + BANNER_HOLD_TIME + BANNER_FADE_TIME
		if elapsed >= totalTime then
			ZB_BanFlash.Current = nil
			return
		end

		local alpha, posT
		if elapsed <= BANNER_SLIDE_TIME then
			local t = EaseOutCubic(elapsed / BANNER_SLIDE_TIME)
			alpha, posT = t, t
		elseif elapsed <= BANNER_SLIDE_TIME + BANNER_HOLD_TIME then
			alpha, posT = 1, 1
		else
			local t = (elapsed - BANNER_SLIDE_TIME - BANNER_HOLD_TIME) / BANNER_FADE_TIME
			local eased = EaseInCubic(t)
			alpha = 1 - eased
			posT = 1 - eased * 0.6
		end

		local lines = {
			{ text = data.name .. " has been banned", font = "ZB_BanFlashFontTitle", color = Color(255, 255, 255) },
			{ text = "Reason: " .. data.reason, font = "ZB_BanFlashFontBody", color = Color(235, 235, 235) },
			{ text = "Expires: " .. data.expiration, font = "ZB_BanFlashFontBody", color = Color(235, 235, 235) },
			{ text = "Ban issued by " .. data.admin, font = "ZB_BanFlashFontBody", color = Color(190, 190, 190) },
		}

		local maxW, totalH = 0, 0
		for _, ln in ipairs(lines) do
			surface.SetFont(ln.font)
			local w, h = surface.GetTextSize(ln.text)
			ln.w, ln.h = w, h
			maxW = math.max(maxW, w)
			totalH = totalH + h + BANNER_LINE_GAP
		end
		totalH = totalH - BANNER_LINE_GAP

		local boxW = maxW + BANNER_PADDING_X * 2
		local boxH = totalH + BANNER_PADDING_Y * 2
		local x = ScrW() / 2 - boxW / 2
		local finalY = BANNER_TOP_MARGIN
		local startY = -boxH - 10
		local y = Lerp(posT, startY, finalY)

		draw.RoundedBox(8, x, y, boxW, boxH, Color(12, 12, 12, 185 * alpha))
		surface.SetDrawColor(255, 255, 255, 35 * alpha)
		surface.DrawOutlinedRect(x, y, boxW, boxH, 1)

		local curY = y + BANNER_PADDING_Y
		for _, ln in ipairs(lines) do
			draw.SimpleText(ln.text, ln.font, ScrW() / 2, curY, ColorAlpha(ln.color, 255 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			curY = curY + ln.h + BANNER_LINE_GAP
		end
	end

	hook.Add("HUDPaint", "ZB_BanFlash_Draw", function()
		DrawBanFlash()
		DrawBanBanner()
	end)

end
