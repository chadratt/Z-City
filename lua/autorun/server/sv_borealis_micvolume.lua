--[[
	Borealis Mic Volume
	--------------------
	Adds a DayZ-style voice range control (Whisper / Normal / Shout) on top of
	ZCity's existing voice chat system.

	This file does NOT modify or replace anything in homigrad/sv_comunication.lua.
	It only listens to the extension hook "HG_PlayerCanHearPlayersVoice" that the
	base voice code already calls at the end of its own "PlayerCanHearPlayersVoice"
	handler (see hook.Add("PlayerCanHearPlayersVoice", "RealisticVoice", ...) in
	homigrad/sv_comunication.lua). Returning nil from our hook lets the vanilla
	logic run completely untouched - which is exactly what happens whenever the
	player is on the "Normal" range.
]]--

util.AddNetworkString("Borealis_SetVoiceRange")

-- lua/autorun/client/ is supposed to auto-send without this, but forcing it
-- explicitly is harmless and rules out any environment where that automatic
-- behavior isn't kicking in.
AddCSLuaFile("autorun/client/cl_borealis_micvolume.lua")

print("[Borealis MicVolume] Server-side script loaded, net string registered.")

-- 1 = Whisper, 2 = Normal, 3 = Shout
local RANGE_WHISPER = 1
local RANGE_NORMAL  = 2
local RANGE_SHOUT    = 3

local cvEnabled     = CreateConVar("borealis_voice_range_enabled", "1", FCVAR_ARCHIVE, "Enable the whisper/normal/shout voice range system.", 0, 1)
local cvWhisperDist = CreateConVar("borealis_voice_whisper_range", "36",   FCVAR_ARCHIVE, "Whisper voice range in units (~12 units = 1 foot). Default ~3ft.")
local cvShoutDist   = CreateConVar("borealis_voice_shout_range",   "2160", FCVAR_ARCHIVE, "Shout voice range in units (~12 units = 1 foot). Default ~180ft.")

local function IsValidRange(n)
	return n == RANGE_WHISPER or n == RANGE_NORMAL or n == RANGE_SHOUT
end

net.Receive("Borealis_SetVoiceRange", function(len, ply)
	if not IsValid(ply) then return end
	local range = net.ReadUInt(2)

	if not IsValidRange(range) then return end

	ply.Borealis_VoiceRange = range
	print("[Borealis MicVolume] " .. ply:Nick() .. " set voice range to " .. range)
end)

hook.Add("PlayerSpawn", "Borealis_MicVolume_Reset", function(ply)
	ply.Borealis_VoiceRange = RANGE_NORMAL
end)

hook.Add("PlayerInitialSpawn", "Borealis_MicVolume_Init", function(ply)
	ply.Borealis_VoiceRange = RANGE_NORMAL
end)

-- Mirrors the same physiological/PVS gating the base ChatLogic() function
-- uses, just with our own distance value plugged in instead of the fixed
-- normal/whisper distances from sv_comunication.lua.
local function Borealis_CanHear(output, input, dist)
	if not IsValid(output) or not IsValid(input) then return false end

	local orgOut = output.organism
	local orgIn  = input.organism

	if output:Alive() and input:Alive() then
		if orgOut and orgOut.otrub then return false end
		if orgIn  and orgIn.otrub  then return false end
		if orgOut and orgOut.o2 and orgOut.o2[1] and orgOut.o2[1] < 15 then return false end
		if orgOut and orgOut.holdingbreath then return false end
		if not input:TestPVS(output) then return false end

		return input:GetPos():Distance(output:GetPos()) < dist
	elseif not output:Alive() and not input:Alive() then
		return true
	else
		if not input:Alive() and output:Alive() then
			if not input:TestPVS(output) then return false end
			return input:GetPos():Distance(output:GetPos()) < dist
		end

		if not output:Alive() and IsValid(input) and input:Team() == 1002 and input:Alive() then return true end

		return false
	end
end

hook.Add("HG_PlayerCanHearPlayersVoice", "Borealis_MicVolume_Range", function(listener, speaker)
	if not cvEnabled:GetBool() then return end
	if not IsValid(speaker) then return end

	local range = speaker.Borealis_VoiceRange or RANGE_NORMAL

	-- Normal range: don't touch anything, let the vanilla ChatLogic() result
	-- (from sv_comunication.lua) stand as-is.
	if range == RANGE_NORMAL then return end

	local dist
	if range == RANGE_WHISPER then
		dist = cvWhisperDist:GetFloat()
	else
		dist = cvShoutDist:GetFloat()
	end

	local canHear = Borealis_CanHear(speaker, listener, dist)

	-- Second value = "is3D" (positioned in the 3D world with normal distance
	-- falloff, same as vanilla proximity voice) rather than flat "radio"
	-- volume. Requires the matching 1-line patch to sv_comunication.lua that
	-- forwards this second return value - see README.
	return canHear, true
end)
