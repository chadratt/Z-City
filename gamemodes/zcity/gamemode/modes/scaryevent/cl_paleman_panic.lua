if SERVER then return end

local PANIC_DURATION = 10
local PANIC_FADE_IN  = 1.2
local PANIC_FADE_OUT = 2.5
local PANIC_FOV_ADD  = 14
local PANIC_SAT      = 0.12
local PANIC_LERP_SPEED  = 7

local CORPSE_SCAN_INTERVAL = 0.35
local CORPSE_RADIUS        = 600
local DEATH_RADIUS         = 700
local VIEW_DOT             = 0.62

local SND_CORPSE = "HUSK/Encounter_dead_body.wav"
local SND_DEATH  = "HUSK/Playerkilledinfrontofthem.wav"

local panic = { active = false, start = 0 }
local seenCorpses   = {}
local lastScan      = 0
local lastCacheClean = 0
local lastRoundStart = -1

local function PalemanActive()
	local cur = zb and (zb.CROUND_MAIN or zb.CROUND)
	return cur == "PALEMAN"
end

local function smooth(t)
	t = math.Clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function RawPanicIntensity()
	if not panic.active then return 0 end

	local e = CurTime() - panic.start
	if e >= PANIC_DURATION then
		panic.active = false
		return 0
	end

	local t
	if e < PANIC_FADE_IN then
		t = e / PANIC_FADE_IN
	elseif e < PANIC_DURATION - PANIC_FADE_OUT then
		t = 1
	else
		t = (PANIC_DURATION - e) / PANIC_FADE_OUT
	end

	return smooth(t)
end

local smoothIntensity = 0

hook.Add("Think", "PALEMAN_PanicInterp", function()
	local target
	if PalemanActive() then
		target = RawPanicIntensity()
	else
		panic.active = false
		target = 0
	end

	smoothIntensity = Lerp(math.Clamp(FrameTime() * PANIC_LERP_SPEED, 0, 1), smoothIntensity, target)

	if target <= 0 and smoothIntensity < 0.002 then
		smoothIntensity = 0
	end
end)

local function PanicIntensity()
	return smoothIntensity
end

local function TriggerPanic(snd)
	if panic.active then return end
	panic.active = true
	panic.start  = CurTime()
	if snd then surface.PlaySound(snd) end
end

local function ResetPanic()
	panic.active    = false
	seenCorpses     = {}
	smoothIntensity = 0
end

hook.Add("Think", "PALEMAN_CorpseWitness", function()
	if not PalemanActive() then return end

	if zb and zb.ROUND_START and zb.ROUND_START ~= lastRoundStart then
		lastRoundStart = zb.ROUND_START
		ResetPanic()
	end

	if CurTime() - lastScan < CORPSE_SCAN_INTERVAL then return end
	lastScan = CurTime()

	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	local eyepos = ply:EyePos()
	local aim    = ply:GetAimVector()
	local sawNewBody = false

	for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), CORPSE_RADIUS)) do
		if not IsValid(ent) then continue end

		local isRagdoll    = ent:IsRagdoll()
		local isDeadPlayer = ent:IsPlayer() and not ent:Alive()
		if not (isRagdoll or isDeadPlayer) then continue end

		if isRagdoll and hg and hg.RagdollOwner then
			local owner = hg.RagdollOwner(ent)
			if IsValid(owner) and owner:Alive() then continue end
		end

		local idx = ent:EntIndex()
		if seenCorpses[idx] then continue end

		local bodypos = ent:GetPos() + Vector(0, 0, 20)
		local dir     = bodypos - eyepos
		local dist    = dir:Length()
		if dist < 1 then continue end
		if aim:Dot(dir) / dist < VIEW_DOT then continue end

		local tr = util.TraceLine({ start = eyepos, endpos = bodypos, filter = { ply } })
		if tr.Fraction < 0.9 and tr.Entity ~= ent then continue end

		seenCorpses[idx] = true
		sawNewBody = true
	end

	if sawNewBody then
		TriggerPanic(SND_CORPSE)
	end
end)

hook.Add("Think", "PALEMAN_CleanCorpseCache", function()
	if CurTime() - lastCacheClean < 30 then return end
	lastCacheClean = CurTime()

	for idx in pairs(seenCorpses) do
		if not IsValid(Entity(idx)) then
			seenCorpses[idx] = nil
		end
	end
end)

hook.Add("Player_Death", "PALEMAN_DeathWitness", function(victim)
	if not PalemanActive() then return end

	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end
	if not IsValid(victim) or victim == ply then return end

	local vpos = victim:EyePos()
	if vpos == vector_origin then
		vpos = victim:GetPos() + Vector(0, 0, 40)
	end

	local eyepos = ply:EyePos()
	local dir    = vpos - eyepos
	local dist   = dir:Length()
	if dist < 1 or dist > DEATH_RADIUS then return end

	if ply:GetAimVector():Dot(dir) / dist < VIEW_DOT then return end

	local tr = util.TraceLine({ start = eyepos, endpos = vpos, filter = { ply, victim } })
	if tr.Fraction < 0.9 then return end

	TriggerPanic(SND_DEATH)
end)

local colmod = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0,
	["$pp_colour_brightness"] = 0,
	["$pp_colour_contrast"]   = 1,
	["$pp_colour_colour"]     = 1,
}

hook.Add("RenderScreenspaceEffects", "PALEMAN_PanicColour", function()
	local i = PanicIntensity()
	if i <= 0 then return end

	colmod["$pp_colour_colour"]     = Lerp(i, 1, PANIC_SAT)
	colmod["$pp_colour_contrast"]   = Lerp(i, 1, 1.12)
	colmod["$pp_colour_brightness"] = Lerp(i, 0, -0.03)
	DrawColorModify(colmod)
end)

hook.Add("HG_CalcView", "PALEMAN_PanicFOV", function(ply, origin, angles, fova)
	local i = PanicIntensity()
	if i <= 0 then return end
	if not istable(fova) then return end

	fova[1] = (fova[1] or 0) + i * PANIC_FOV_ADD
end)
