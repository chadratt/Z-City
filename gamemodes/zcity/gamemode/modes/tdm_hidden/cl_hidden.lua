MODE.name = "hidden"

local MODE = MODE

local teams = {
	[0] = {
		objective = "You are a genetic experiment gone wrong and the I.R.I.S soldiers want to capture you, dont let them take you.",
		name = "the Hidden",
		color1 = Color(190, 0, 0),
		color2 = Color(190, 0, 0)
	},
	[1] = {
		objective = "You are an I.R.I.S soldier, your task is to capture a biologically engineered super human in an experiment gone wrong and is on the loose.",
		name = "an I.R.I.S Soldier",
		color1 = Color(0, 120, 190),
		color2 = Color(0, 120, 190)
	},
}

local tutorialText = {
	[0] = "You can latch onto walls by jumping and holding space bar and you can use W or S to climb up or down. if you want to launch off the wall, look to where you want to launch to and press Shift. You can also eat corpses by picking them up and pressing R to regain lost health",
	[1] = "You can turn your radar off and on in the radial menu by pressing Q",
}

surface.CreateFont("ZB_HiddenTutorial", {
	font = "Bahnschrift",
	size = ScreenScale(6),
	extended = true,
	weight = 400,
	antialias = true,
	scanlines = 2
})

surface.CreateFont("ZB_HiddenTutorialTitle", {
	font = "Bahnschrift",
	size = ScreenScale(10),
	extended = true,
	weight = 400,
	antialias = true,
	scanlines = 2
})

surface.CreateFont("ZB_HiddenTutorialMark", {
	font = "Bahnschrift",
	size = ScreenScale(34),
	extended = true,
	weight = 800,
	antialias = true
})

local PANEL = {}

local tutorialGlow = Material("zbattle/borderglow2.png")
local tutorialColor = Color(255, 220, 0)

function PANEL:Init()
	local sw, sh = ScrW(), ScrH()

	self:SetPos(sw * 0.07, sh * 0.07)
	self:SetSize(sw * 0.22, sh * 0.12)

	if IsValid(zb.DialogueWindow) then
		zb.DialogueWindow:Remove()
	end

	zb.DialogueWindow = self

	self.textread = ""
	self.textpos = 0
	self.currenttext = ""

	surface.PlaySound("zbattle/dialogue/radio_talk.ogg")

	self.appearAlpha = 255
	self.appearProgress = 0

	self:CreateAnimation(1, {
		index = 1,
		target = {
			appearAlpha = 0,
			appearProgress = 1
		},
		easing = "linear",
		bIgnoreConfig = true,
		Think = function()
		end,
		OnComplete = function()
		end
	})

	self.CloseOnLast = false
	self.bClosing = false

	self.text = vgui.Create("DLabel", self)
	self.text:Dock(FILL)
	self.text:DockMargin(sw * 0.22 * 0.3 + ScreenScale(1), ScreenScale(10), 0, 0)
	self.text:SetText(self.currenttext)
	self.text:SetFont("ZB_HiddenTutorial")
	self.text:SetContentAlignment(4)
	self.text:SetTextColor(color_white)
	self.text:SetWrap(true)
	self.text:SetAutoStretchVertical(true)

	self.timebetween = SysTime() + 1.2
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(59, 9, 21, 235)
	surface.DrawRect(0, h * 0.2, w, h)

	surface.SetDrawColor(67, 10, 10, 50)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(33, 30, 56)
	surface.DrawRect(0, 0, w * 0.3, h)

	draw.SimpleText("?", "ZB_HiddenTutorialMark", w * 0.15, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	surface.SetDrawColor(0, 0, 0)
	surface.DrawOutlinedRect(0, 0, w * 0.3, h, ScreenScale(1))

	for i = 1, 10 do
		surface.SetDrawColor(144, 35, 62, 10)
		surface.DrawRect(0, ((h / 10 * i) + (CurTime() * 10)) % h, w * 0.3, ScreenScale(1))
	end

	surface.SetMaterial(tutorialGlow)

	DisableClipping(true)
		surface.SetDrawColor(0, 0, 0, self.appearProgress * 255)
		surface.DrawTexturedRect(-ScreenScale(4) - 1, -ScreenScale(4), w * 0.3 + ScreenScale(8) + 1, h + ScreenScale(8))
	DisableClipping(false)

	draw.GlowingText("Tutorial", "ZB_HiddenTutorialTitle", w * 0.31, 0 - ScreenScale(1), ColorAlpha(tutorialColor, 255), ColorAlpha(tutorialColor, 235), ColorAlpha(tutorialColor, 10), TEXT_ALIGN_LEFT)

	surface.SetDrawColor(255, 255, 255, self.appearAlpha * 4)
	surface.DrawRect(0, 0, w, h)
end

function PANEL:Think()
	if SysTime() > self.timebetween and self.textpos <= #self.textread then
		self.textpos = self.textpos + 1

		local newtext = string.sub(self.textread, 0, self.textpos)

		if self.currenttext ~= newtext then
			sound.PlayFile("sound/zbattle/dialogue/commander_talk2.ogg", "", function() end)
			self.currenttext = newtext
			self.text:SetText(newtext)
		end

		local last = string.Right(newtext, 1)

		if last == "." then
			self.timebetween = SysTime() + 1
		elseif last == "," or last == ":" then
			self.timebetween = SysTime() + 0.5
		else
			self.timebetween = SysTime() + 0.04
		end

		if self.CloseOnLast and self.textpos == #self.textread then
			timer.Simple(4, function()
				if IsValid(self) then
					self:Close()
				end
			end)
		end
	end
end

function PANEL:FitText(text)
	local sw, sh = ScrW(), ScrH()
	local maxW = sw * 0.22 * 0.7 - ScreenScale(2)

	surface.SetFont("ZB_HiddenTutorial")
	local _, lineH = surface.GetTextSize("A")

	local lines = 1
	local line = ""

	for word in string.gmatch(text, "%S+") do
		local test = line == "" and word or (line .. " " .. word)
		if surface.GetTextSize(test) > maxW and line ~= "" then
			lines = lines + 1
			line = word
		else
			line = test
		end
	end

	self:SetTall(math.max(sh * 0.12, (lines + 1) * lineH + ScreenScale(12)))
end

function PANEL:SetTextAutoClose(text)
	self:FitText(text)
	self.textread = text
	self.timebetween = SysTime() + 2

	self.textpos = 0
	self.CloseOnLast = true
end

function PANEL:Close()
	if self.bClosing then return end
	self.bClosing = true

	sound.PlayFile("sound/zbattle/dialogue/radio_off.wav", "", function() end)

	self:CreateAnimation(1, {
		index = 2,
		target = {
			appearAlpha = 255,
			appearProgress = 0
		},
		easing = "linear",
		bIgnoreConfig = true,
		Think = function()
			self:SetAlpha(255 * self.appearProgress / 2)
		end,
		OnComplete = function()
			self:Remove()
		end
	})
end

vgui.Register("ZB_HiddenTutorial", PANEL, "EditablePanel")

local MUSIC_FADE = 2
local MUSIC_COMBAT_TIME = 20

local musicIntro = "hidden/intro.mp3"
local musicAmbience = {"hidden/ambience1.mp3", "hidden/ambience2.mp3"}
local musicCombat = {"hidden/combat1.mp3", "hidden/combat2.mp3"}
local musicWin = {
	[0] = "hidden/hidden.mp3",
	[1] = "hidden/iris.mp3",
}

local musicChannels = {}
local musicLoading = {}
local musicFailed = {}
local musicDesired
local musicPhase
local musicAmbienceTrack = musicAmbience[1]
local musicCombatTrack = musicCombat[1]
local musicWinTrack
local musicCombatUntil = 0
local musicPhaseStart = 0
local musicVolumeCvar = GetConVar("snd_musicvolume")

local function StopZCityMusic()
	if hg.DynaMusic and hg.DynaMusic.Stop and hg.DynaMusic.Tracks and next(hg.DynaMusic.Tracks) then
		hg.DynaMusic:Stop()
	end

	local v2 = hg.DynamicMusicV2 and hg.DynamicMusicV2.Player
	if v2 and v2.Stop and v2.CurrentTrack and v2.CurrentTrack ~= "None" then
		v2.Stop()
	end
end

local musicStart = {}
local musicLength = {}
local musicResumeVolume = {}

local function MusicLoad(path, loop)
	if musicChannels[path] or musicLoading[path] or musicFailed[path] then return end

	local start, length = musicStart[path], musicLength[path]
	if start and length and length > 0 and not loop and RealTime() - start >= length then return end

	musicLoading[path] = true

	sound.PlayFile("sound/" .. path, "noblock noplay", function(channel)
		musicLoading[path] = nil

		if not IsValid(channel) then
			musicFailed[path] = true
			return
		end

		local len = channel:GetLength()
		local offset = 0
		local volume = 0

		musicLength[path] = len

		if musicStart[path] and len > 0 then
			offset = RealTime() - musicStart[path]
			if loop then offset = offset % len end

			if offset >= len then
				channel:Stop()
				return
			end

			volume = musicResumeVolume[path] or 0
		else
			musicStart[path] = RealTime()
		end

		musicResumeVolume[path] = nil

		local master = musicVolumeCvar and musicVolumeCvar:GetFloat() or 1

		channel:SetVolume(volume * master)
		channel:EnableLooping(loop)
		channel:Play()

		if offset > 0 then
			channel:SetTime(offset)
		end

		musicChannels[path] = {channel = channel, volume = volume, loop = loop}
	end)
end

local function MusicSet(path, loop)
	musicDesired = path
	if path then MusicLoad(path, loop) end
end

local function MusicForget(path)
	musicStart[path] = nil
	musicLength[path] = nil
	musicResumeVolume[path] = nil
end

local function MusicDrop(path)
	local data = musicChannels[path]
	if data and IsValid(data.channel) then data.channel:Stop() end
	musicChannels[path] = nil
	musicFailed[path] = nil
	MusicForget(path)
end

local function MusicFinished(path)
	if musicFailed[path] then return true end

	local start, length = musicStart[path], musicLength[path]

	if not start then
		return not musicLoading[path] and musicPhaseStart + 1 < CurTime()
	end

	if not length or length <= 0 then
		local data = musicChannels[path]
		return not data or not IsValid(data.channel) or data.channel:GetState() == GMOD_CHANNEL_STOPPED
	end

	return RealTime() - start >= length - MUSIC_FADE
end

local function MusicPhase(phase)
	musicPhase = phase
	musicPhaseStart = CurTime()
end

hook.Add("Think", "hidden_music", function()
	local active = zb and zb.CROUND == "hidden"

	if active then
		StopZCityMusic()

		if musicPhase == "intro" then
			MusicSet(musicIntro, false)
			if MusicFinished(musicIntro) then MusicPhase("play") end
		elseif musicPhase == "hold" then
			MusicSet(musicWinTrack, false)
			if not musicWinTrack or musicCombatUntil > CurTime() or MusicFinished(musicWinTrack) then MusicPhase("play") end
		elseif musicPhase == "win" then
			MusicSet(musicWinTrack, false)
		elseif musicPhase == "play" then
			if musicCombatUntil > CurTime() then
				MusicSet(musicCombatTrack, true)
			else
				MusicSet(musicAmbienceTrack, true)
			end
		else
			musicDesired = nil

			local lply = LocalPlayer()
			if IsValid(lply) and lply:Alive() and (lply:Team() == 0 or lply:Team() == 1) then
				MusicPhase("play")
			end
		end
	else
		musicDesired = nil
		musicPhase = nil
	end

	local master = musicVolumeCvar and musicVolumeCvar:GetFloat() or 1
	local step = FrameTime() / MUSIC_FADE

	for path, data in pairs(musicChannels) do
		if not IsValid(data.channel) or data.channel:GetState() == GMOD_CHANNEL_STOPPED then
			local length = musicLength[path] or 0
			local elapsed = RealTime() - (musicStart[path] or RealTime())

			musicChannels[path] = nil

			if path == musicDesired and length > 0 and (data.loop or elapsed < length - 0.5) then
				musicResumeVolume[path] = data.volume
				MusicLoad(path, data.loop)
			elseif path ~= musicDesired then
				MusicForget(path)
			end

			continue
		end

		local target = path == musicDesired and 1 or 0
		data.volume = math.Approach(data.volume, target, step)
		data.channel:SetVolume(data.volume * master)

		if data.volume <= 0 and target == 0 then
			data.channel:Stop()
			musicChannels[path] = nil
			MusicForget(path)
		end
	end
end)

net.Receive("hidden_combat", function()
	if musicCombatUntil < CurTime() then
		musicCombatTrack = musicCombat[math.random(#musicCombat)]
	end

	musicCombatUntil = CurTime() + MUSIC_COMBAT_TIME
end)

net.Receive("hidden_start", function()
	local round = net.ReadUInt(4)

	StopZCityMusic()
	zb.RemoveFade()

	musicAmbienceTrack = musicAmbience[math.random(#musicAmbience)]
	musicCombatUntil = 0
	musicFailed = {}

	if round <= 1 then
		MusicDrop(musicIntro)
		musicWinTrack = nil
		MusicPhase("intro")
	elseif musicWinTrack then
		MusicPhase("hold")
	else
		MusicPhase("play")
	end

	timer.Create("hidden_tutorial", 2, 1, function()
		local lply = LocalPlayer()
		if not IsValid(lply) or not lply:Alive() or zb.CROUND ~= "hidden" then return end

		local text = tutorialText[lply:Team()]
		if not text then return end

		local panel = vgui.Create("ZB_HiddenTutorial")
		panel:SetTextAutoClose(text)
	end)
end)

net.Receive("hidden_roundend", function()
	local winner = net.ReadInt(4)

	musicWinTrack = musicWin[winner]
	musicCombatUntil = 0
	if musicWinTrack then MusicDrop(musicWinTrack) end
	MusicPhase("win")

	if winner == 0 then
		chat.AddText(Color(190, 0, 0), "The Hidden ", color_white, "escaped capture.")
	elseif winner == 1 then
		chat.AddText(Color(0, 120, 190), "I.R.I.S ", color_white, "has eliminated the Hidden.")
	else
		chat.AddText(color_white, "Nobody survived.")
	end
end)

function MODE:HUDPaint()
	local sw, sh = ScrW(), ScrH()
	local lply = LocalPlayer()
	local StartTime = zb.ROUND_START or CurTime()
	local PrepTime = self.PrepTime or 10

	if StartTime + PrepTime > CurTime() then
		draw.SimpleText(string.FormattedTime(StartTime + PrepTime - CurTime(), "%02i:%02i:%02i"), "ZB_HomicideMedium", sw * 0.5, sh * 0.95, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		local time = string.FormattedTime(math.max(StartTime + (zb.ROUND_TIME or 300) - CurTime(), 0), "%02i:%02i:%02i")
		draw.SimpleText(time, "ZB_HomicideMedium", sw * 0.5, sh * 0.95, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if StartTime + PrepTime < CurTime() then return end

	if not lply:Alive() then return end
	zb.RemoveFade()
	local fade = math.Clamp(StartTime + 8 - CurTime(), 0, 1)
	local team_ = lply:Team()
	if not teams[team_] then return end

	draw.SimpleText(self.PrintName or "The Hidden", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	local Rolename = teams[team_].name
	local ColorRole = teams[team_].color1
	ColorRole.a = 255 * fade
	draw.SimpleText("You are " .. Rolename, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local Objective = teams[team_].objective
	local ColorObj = teams[team_].color2
	ColorObj.a = 255 * fade
	draw.SimpleText(Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

local RADAR_RANGE = 1500
local RADAR_PULSE = 5
local RADAR_SOUND = "hidden/radar.mp3"

local radarEnabled = true
local radarBlips = {}
local radarTime = -100

local colRadarBack = Color(0, 0, 0, 170)
local colRadarLine = Color(0, 120, 190, 200)
local colRadarGrid = Color(0, 120, 190, 60)
local colIris = Color(40, 130, 255)
local colHidden = Color(255, 220, 0)
local colRadarPulse = Color(255, 255, 255)

local function IsIris(ply)
	return IsValid(ply) and ply:Alive() and ply:Team() == 1 and zb.CROUND == "hidden"
end

net.Receive("hidden_radar", function()
	local count = net.ReadUInt(8)
	local lply = LocalPlayer()
	local blips = {}

	local valid = IsIris(lply)
	local origin = valid and lply:GetPos() or vector_origin
	local yaw = math.rad(valid and lply:EyeAngles().y or 0)
	local fx, fy = math.cos(yaw), math.sin(yaw)
	local selfIndex = valid and lply:EntIndex() or -1

	for i = 1, count do
		local index = net.ReadUInt(8)
		local pos = net.ReadVector()
		local hidden = net.ReadBool()

		if not valid or index == selfIndex then continue end
		if (pos.x - origin.x) * fx + (pos.y - origin.y) * fy <= 0 then continue end

		blips[#blips + 1] = {pos = pos, hidden = hidden}
	end

	if not valid or not radarEnabled then
		radarBlips = {}
		return
	end

	radarBlips = blips
	radarTime = CurTime()

	surface.PlaySound(RADAR_SOUND)
end)

local function DrawDisc(x, y, radius, segments, col, alpha)
	local verts = {}

	for i = 0, segments - 1 do
		local a = math.rad((i / segments) * -360)
		verts[#verts + 1] = {x = x + math.sin(a) * radius, y = y + math.cos(a) * radius}
	end

	draw.NoTexture()
	surface.SetDrawColor(col.r, col.g, col.b, alpha or col.a)
	surface.DrawPoly(verts)
end

local function ArcPoints(x, y, radius, segments)
	local verts = {}

	for i = 0, segments do
		local a = math.pi * (i / segments)
		verts[#verts + 1] = {x = x - math.cos(a) * radius, y = y - math.sin(a) * radius}
	end

	return verts
end

local function DrawArc(x, y, radius, segments, col, alpha)
	local verts = ArcPoints(x, y, radius, segments)

	surface.SetDrawColor(col.r, col.g, col.b, alpha or col.a)
	for i = 1, #verts - 1 do
		surface.DrawLine(verts[i].x, verts[i].y, verts[i + 1].x, verts[i + 1].y)
	end
end

local function DrawThickArc(x, y, radius, thickness, segments, col, alpha)
	local outer = ArcPoints(x, y, radius, segments)
	local inner = ArcPoints(x, y, math.max(radius - thickness, 0), segments)

	draw.NoTexture()
	surface.SetDrawColor(col.r, col.g, col.b, alpha or col.a)
	for i = 1, #outer - 1 do
		surface.DrawPoly({outer[i], outer[i + 1], inner[i + 1], inner[i]})
	end
end

function MODE:HUDPaintBackground()
	local lply = LocalPlayer()
	if not radarEnabled or not IsIris(lply) then return end

	local sh = ScrH()
	local radius = ScreenScale(48)
	local margin = ScreenScale(8)
	local cx = margin + radius
	local cy = sh - margin

	draw.NoTexture()
	surface.SetDrawColor(colRadarBack.r, colRadarBack.g, colRadarBack.b, colRadarBack.a)
	surface.DrawPoly(ArcPoints(cx, cy, radius, 32))

	DrawArc(cx, cy, radius, 32, colRadarLine)
	DrawArc(cx, cy, radius * 0.5, 24, colRadarGrid)
	surface.SetDrawColor(colRadarLine.r, colRadarLine.g, colRadarLine.b, colRadarLine.a)
	surface.DrawLine(cx - radius, cy, cx + radius, cy)
	surface.SetDrawColor(colRadarGrid.r, colRadarGrid.g, colRadarGrid.b, colRadarGrid.a)
	surface.DrawLine(cx, cy - radius, cx, cy)

	local dot = math.max(ScreenScale(1.6), 3)
	local age = CurTime() - radarTime

	if age >= 0 and age < 1 then
		DrawThickArc(cx, cy, radius * age, math.max(ScreenScale(1.5), 3), 32, colRadarPulse, 255 * (1 - age))
	end

	if age >= 0 and age < RADAR_PULSE then
		local alpha = 255 * math.Clamp((RADAR_PULSE - age) / (RADAR_PULSE * 0.6), 0, 1)
		local origin = lply:GetPos()
		local yaw = math.rad(EyeAngles().y)
		local fx, fy = math.cos(yaw), math.sin(yaw)
		local rx, ry = math.sin(yaw), -math.cos(yaw)
		local scale = radius / (self.RadarRange or RADAR_RANGE)
		local limit = radius - dot

		for pass = 1, 2 do
			for _, blip in ipairs(radarBlips) do
				if blip.hidden ~= (pass == 2) then continue end

				local dx, dy = blip.pos.x - origin.x, blip.pos.y - origin.y
				local px = (dx * rx + dy * ry) * scale
				local py = -(dx * fx + dy * fy) * scale
				if py > 0 then continue end

				local len = math.sqrt(px * px + py * py)
				if blip.hidden and len > radius then continue end
				if len > limit then
					px, py = px / len * limit, py / len * limit
				end

				if blip.hidden then
					DrawDisc(cx + px, cy + py, dot * 1.25, 12, colHidden, alpha)
				else
					DrawDisc(cx + px, cy + py, dot, 12, colIris, alpha)
				end
			end
		end
	end

	DrawDisc(cx, cy - dot, dot, 12, colIris)
end

local function ToggleRadar()
	radarEnabled = not radarEnabled

	if not radarEnabled then
		radarBlips = {}
		radarTime = -100
		LocalPlayer():StopSound(RADAR_SOUND)
	end
end

hook.Add("radialOptions", "hidden_radar_toggle", function()
	if not IsIris(LocalPlayer()) then return end

	hg.radialOptions[#hg.radialOptions + 1] = {
		ToggleRadar,
		radarEnabled and "Turn Radar Off" or "Turn Radar On"
	}
end)
