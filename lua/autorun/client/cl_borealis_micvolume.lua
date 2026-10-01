--[[
	Borealis Mic Volume (client)
	----------------------------
	Arrow Up   -> raise your voice range (Normal -> Shout)
	Arrow Down -> lower your voice range (Normal -> Whisper)

	Purely additive: doesn't touch any existing chat/voice UI or keybinds.
]]--

local RANGE_WHISPER = 1
local RANGE_NORMAL  = 2
local RANGE_SHOUT    = 3

local RANGE_DATA = {
	[RANGE_WHISPER] = { name = "Whisper", mat = Material("borealis_microphone/whisper.png",  "noclamp smooth") },
	[RANGE_NORMAL]  = { name = "Normal",  mat = Material("borealis_microphone/normal.png",   "noclamp smooth") },
	[RANGE_SHOUT]   = { name = "Shout",   mat = Material("borealis_microphone/shouting.png", "noclamp smooth") },
}

local Borealis_CurrentRange = RANGE_NORMAL
local Borealis_PopupUntil = 0

print("[Borealis MicVolume] Client-side script loaded.")

local POPUP_DURATION = 2.5
local FADE_TIME = 0.5
local ICON_SIZE = 48

local function Borealis_SendRange(range)
	net.Start("Borealis_SetVoiceRange")
		net.WriteUInt(range, 2)
	net.SendToServer()
end

local function Borealis_ShowPopup()
	Borealis_PopupUntil = CurTime() + POPUP_DURATION
end

hook.Add("PlayerSpawn", "Borealis_MicVolume_Reset", function(ply)
	if ply ~= LocalPlayer() then return end
	Borealis_CurrentRange = RANGE_NORMAL
end)

local wasUpDown, wasDownDown = false, false

hook.Add("Think", "Borealis_MicVolume_Input", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	-- Don't hijack the keys while the player is typing in chat/console or has
	-- a menu open - same spirit as the existing ChatWhisper Think hook.
	if vgui.GetKeyboardFocus() or gui.IsConsoleVisible() then
		wasUpDown, wasDownDown = false, false
		return
	end

	local upDown = input.IsKeyDown(KEY_UP)
	local downDown = input.IsKeyDown(KEY_DOWN)

	if upDown and not wasUpDown then
		if Borealis_CurrentRange < RANGE_SHOUT then
			Borealis_CurrentRange = Borealis_CurrentRange + 1
			Borealis_SendRange(Borealis_CurrentRange)
			Borealis_ShowPopup()
			surface.PlaySound("buttons/button15.wav")
			print("[Borealis MicVolume] Range raised to " .. RANGE_DATA[Borealis_CurrentRange].name)
		end
	end

	if downDown and not wasDownDown then
		if Borealis_CurrentRange > RANGE_WHISPER then
			Borealis_CurrentRange = Borealis_CurrentRange - 1
			Borealis_SendRange(Borealis_CurrentRange)
			Borealis_ShowPopup()
			surface.PlaySound("buttons/button15.wav")
			print("[Borealis MicVolume] Range lowered to " .. RANGE_DATA[Borealis_CurrentRange].name)
		end
	end

	wasUpDown, wasDownDown = upDown, downDown
end)

hook.Add("HUDPaint", "Borealis_MicVolume_HUD", function()
	local left = Borealis_PopupUntil - CurTime()
	if left <= 0 then return end

	local alpha = 255
	if left < FADE_TIME then
		alpha = 255 * (left / FADE_TIME)
	end

	local data = RANGE_DATA[Borealis_CurrentRange]
	if not data then return end

	local scrW, scrH = ScrW(), ScrH()
	local x = scrW / 2 - ICON_SIZE / 2
	local y = scrH - 160

	surface.SetDrawColor(255, 255, 255, alpha)
	surface.SetMaterial(data.mat)
	surface.DrawTexturedRect(x, y, ICON_SIZE, ICON_SIZE)

	draw.SimpleText(data.name, "DermaDefaultBold", scrW / 2, y + ICON_SIZE + 4, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)
