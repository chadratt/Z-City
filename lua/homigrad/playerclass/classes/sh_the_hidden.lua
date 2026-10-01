local CLASS = player.RegClass("the_hidden")

local HIDDEN_MODEL = "models/player/soldier_stripped.mdl"
local HIDDEN_HEALTH = 300

util.PrecacheModel(HIDDEN_MODEL)
local ALPHA_HIDDEN = 0.04
local ALPHA_REVEALED = 0.4
local REVEAL_TIME = 5
local FADE_SPEED = 3
local CLIMB_SPEED = 70
local LAUNCH_SPEED = 700
local CONSUME_HEAL = 25
local STICK_DIST = 10

local painSounds = {
    "player/hidden/voice/617-303pain01.mp3",
    "player/hidden/voice/617-303pain02.mp3",
    "player/hidden/voice/617-303pain03.mp3",
    "player/hidden/voice/617-303pain04.mp3",
    "player/hidden/voice/617-303pain05.mp3",
    "player/hidden/voice/617-303pain06.mp3",
    "player/hidden/voice/617-303pain07.mp3",
    "player/hidden/voice/617-303pain08.mp3",
}

local painDurations = {}

for _, snd in ipairs(painSounds) do
    util.PrecacheSound(snd)
end

local function IsHidden(ply)
    return IsValid(ply) and ply.PlayerClassName == "the_hidden" and ply:IsPlayer()
end

local function Unstick(ply)
    if ply:GetNW2Bool("HiddenStuck", false) then
        ply:SetNW2Bool("HiddenStuck", false)
    end
end

function CLASS.On(self)
    self.HiddenAlphaCur = ALPHA_HIDDEN
    self:SetNW2Bool("HiddenStuck", false)

    if CLIENT then return end

    ApplyAppearance(self, nil, nil, nil, true)

    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    Appearance.AAttachments = ""
    Appearance.AColthes = ""
    self.CurAppearance = Appearance
    self:SetNetVar("Accessories", "")
    self:SetModel(HIDDEN_MODEL)
    self:SetSubMaterial()
    self:SetPlayerColor(Color(20, 20, 20):ToVector())

    timer.Simple(0, function()
        if not IsValid(self) or self.PlayerClassName ~= "the_hidden" then return end
        if self:GetModel() ~= HIDDEN_MODEL then
            self:SetModel(HIDDEN_MODEL)
        end
        self:SetSubMaterial()
        self:SetBodyGroups("00000000000")
    end)

    local inv = self:GetNetVar("Inventory", {})
    inv["Weapons"] = inv["Weapons"] or {}
    inv["Weapons"]["hg_sling"] = true
    self:SetNetVar("Inventory", inv)

    self:SetNWString("PlayerName", "Subject 617")
    self:SetNW2Float("HiddenHurt", -100)

    if self.organism then
        self.organism.superfighter = true
        self.organism.recoilmul = 0.25
    end

    self:SetMaxHealth(HIDDEN_HEALTH)
    self:SetHealth(HIDDEN_HEALTH)
end

function CLASS.Off(self)
    self:SetNW2Bool("HiddenStuck", false)

    if CLIENT then
        self.HiddenAlphaCur = nil
        self.HiddenShadowEnt = nil
        self:DrawShadow(true)
        local chr = hg.GetCurrentCharacter and hg.GetCurrentCharacter(self)
        if IsValid(chr) then chr:DrawShadow(true) end
        return
    end

    self:SetNW2Float("HiddenHurt", -100)

    if self.organism then
        self.organism.superfighter = false
        self.organism.recoilmul = nil
    end

    self:SetMaxHealth(100)
    if self:Health() > 100 then
        self:SetHealth(100)
    end
end

function CLASS.FallDmgFunc(self, speed, tr)
    if CLIENT then return end
    if speed > 250 and IsValid(tr.Entity) and tr.Entity:IsPlayer() then
        hg.drop(tr.Entity)
        hg.LightStunPlayer(tr.Entity, 2)
    end
end

hook.Add("Move", "the_hidden_wallstick", function(ply, mv)
    if not IsHidden(ply) then return end

    if not ply:Alive() or IsValid(ply.FakeRagdoll) or ply:GetMoveType() ~= MOVETYPE_WALK then
        Unstick(ply)
        return
    end

    local origin = mv:GetOrigin()
    local mins, maxs
    if ply:Crouching() then
        mins, maxs = ply:GetHullDuck()
    else
        mins, maxs = ply:GetHull()
    end

    if not ply:GetNW2Bool("HiddenStuck", false) then
        if ply:OnGround() or not mv:KeyDown(IN_JUMP) then return end
        if (ply.HiddenStickCD or 0) > CurTime() then return end

        local dirs = {}

        local aim = mv:GetMoveAngles():Forward()
        aim.z = 0
        if aim:LengthSqr() > 0.01 then
            aim:Normalize()
            dirs[#dirs + 1] = aim
        end

        local vel = mv:GetVelocity()
        vel.z = 0
        if vel:LengthSqr() > 1 then
            vel:Normalize()
            dirs[#dirs + 1] = vel
        end

        for _, dir in ipairs(dirs) do
            local tr = util.TraceHull({
                start = origin,
                endpos = origin + dir * STICK_DIST,
                mins = mins,
                maxs = maxs,
                filter = ply,
                mask = MASK_PLAYERSOLID,
            })

            if tr.Hit and not tr.StartSolid and tr.HitWorld and math.abs(tr.HitNormal.z) < 0.7 then
                local normal = Vector(tr.HitNormal.x, tr.HitNormal.y, 0)
                normal:Normalize()

                ply:SetNW2Bool("HiddenStuck", true)
                ply:SetNW2Vector("HiddenWallNormal", normal)

                mv:SetOrigin(tr.HitPos)
                mv:SetVelocity(vector_origin)

                return true
            end
        end

        return
    end

    local normal = ply:GetNW2Vector("HiddenWallNormal", vector_origin)
    local pos = origin

    if mv:KeyPressed(IN_SPEED) then
        local aim = mv:GetAngles():Forward()

        Unstick(ply)
        ply.HiddenStickCD = CurTime() + 0.5
        mv:SetOrigin(pos)
        mv:SetVelocity(aim * LAUNCH_SPEED)

        return
    end

    local dirZ = 0
    if mv:KeyDown(IN_FORWARD) then dirZ = dirZ + 1 end
    if mv:KeyDown(IN_BACK) then dirZ = dirZ - 1 end

    if dirZ ~= 0 then
        local move = util.TraceHull({
            start = pos,
            endpos = pos + Vector(0, 0, dirZ * CLIMB_SPEED * FrameTime()),
            mins = mins,
            maxs = maxs,
            filter = ply,
            mask = MASK_PLAYERSOLID,
        })

        pos = move.HitPos

        if dirZ < 0 and move.Hit and move.HitNormal.z > 0.7 then
            Unstick(ply)
            ply.HiddenStickCD = CurTime() + 0.5
            mv:SetOrigin(pos)
            mv:SetVelocity(vector_origin)
            return true
        end
    end

    local wall = util.TraceHull({
        start = pos,
        endpos = pos - normal * STICK_DIST,
        mins = mins,
        maxs = maxs,
        filter = ply,
        mask = MASK_PLAYERSOLID,
    })

    if not wall.Hit then
        Unstick(ply)
        ply.HiddenStickCD = CurTime() + 0.5
        mv:SetOrigin(pos)
        if dirZ > 0 then
            mv:SetVelocity(-normal * 150 + Vector(0, 0, 220))
        else
            mv:SetVelocity(vector_origin)
        end
        return true
    end

    mv:SetOrigin(pos)
    mv:SetVelocity(vector_origin)

    return true
end)

if SERVER then
    local function Protected(ply)
        return IsHidden(ply) and ply:Alive()
    end

    local wrappedFake, wrappedStun, wrappedLightStun, wrappedAmputate

    local function WrapKnockdowns()
        if hg.Fake and hg.Fake ~= wrappedFake then
            local original = hg.Fake
            wrappedFake = function(ply, huyragdoll, no_freemove, force, ...)
                if Protected(ply) and not IsValid(huyragdoll) and not force then
                    local info = debug.getinfo(2, "S")
                    local src = info and info.short_src or ""
                    if not string.find(src, "fake/sv_input", 1, true) then return end
                end
                return original(ply, huyragdoll, no_freemove, force, ...)
            end
            hg.Fake = wrappedFake
        end

        if hg.organism and hg.organism.AmputateLimb and hg.organism.AmputateLimb ~= wrappedAmputate then
            local original = hg.organism.AmputateLimb
            wrappedAmputate = function(org, ...)
                if org and IsHidden(org.owner) then return end
                return original(org, ...)
            end
            hg.organism.AmputateLimb = wrappedAmputate
        end

        if hg.StunPlayer and hg.StunPlayer ~= wrappedStun then
            local original = hg.StunPlayer
            wrappedStun = function(ply, ...)
                if Protected(ply) then return end
                return original(ply, ...)
            end
            hg.StunPlayer = wrappedStun
        end

        if hg.LightStunPlayer and hg.LightStunPlayer ~= wrappedLightStun then
            local original = hg.LightStunPlayer
            wrappedLightStun = function(ply, ...)
                if Protected(ply) then return end
                return original(ply, ...)
            end
            hg.LightStunPlayer = wrappedLightStun
        end
    end

    WrapKnockdowns()
    hook.Add("InitPostEntity", "the_hidden_noknockdown", WrapKnockdowns)
    timer.Create("the_hidden_noknockdown", 5, 0, WrapKnockdowns)

    hook.Add("Org Think", "the_hidden_superfighter", function(owner, org)
        if not IsHidden(owner) then return end
        org.superfighter = true
        org.needfake = false
        org.stun = 0
        org.lightstun = 0
        org.shock = 0
        org.immobilization = 0
    end)

    local consumeLimbs = {"lleg", "rleg", "larm", "rarm"}

    local function CarriedBody(ply)
        local ent = ply:GetNetVar("carryent")
        if not IsValid(ent) then ent = ply:GetNetVar("carryent2") end

        if not IsValid(ent) then
            local last = ply.HiddenLastCarry
            if last and IsValid(last[1]) and last[2] + 0.25 > CurTime() then
                ent = last[1]
            end
        end

        if not IsValid(ent) or not ent:IsRagdoll() then return end
        if not ent.organism or ent.HiddenConsumed then return end
        if hg.RagdollOwner(ent) then return end

        return ent
    end

    local function ConsumeBody(ply, body)
        body.HiddenConsumed = true

        local org = body.organism
        local pos = body:WorldSpaceCenter()

        for _, limb in ipairs(consumeLimbs) do
            if org[limb .. "amputated"] == false then
                hg.organism.AmputateLimb(org, limb)
            end
        end

        if not body.headexploded and not org.headamputated and body:LookupBone("ValveBiped.Bip01_Head1") then
            hg.ExplodeHead(body)
        end

        if SpawnMeatGore then
            SpawnMeatGore(body, pos, 12, VectorRand() * 120, 1)
        end

        for i = 1, 14 do
            util.Decal("Blood", pos + VectorRand(-12, 12), pos + VectorRand(-40, 40) - Vector(0, 0, 60), body)
        end

        body:EmitSound("physics/flesh/flesh_bloody_break.wav", 75, math.random(90, 105))

        ply:SetHealth(math.min(ply:Health() + CONSUME_HEAL, ply:GetMaxHealth()))
    end

    hook.Add("Think", "the_hidden_carrytrack", function()
        for _, ply in player.Iterator() do
            if not IsHidden(ply) or not ply:Alive() then continue end

            local ent = ply:GetNetVar("carryent")
            if not IsValid(ent) then ent = ply:GetNetVar("carryent2") end

            if IsValid(ent) then
                ply.HiddenLastCarry = {ent, CurTime()}
            end
        end
    end)

    hook.Add("KeyPress", "the_hidden_consume", function(ply, key)
        if key ~= IN_RELOAD then return end
        if not IsHidden(ply) or not ply:Alive() or IsValid(ply.FakeRagdoll) then return end
        if (ply.HiddenConsumeCD or 0) > CurTime() then return end

        local body = CarriedBody(ply)
        if not body then return end

        ply.HiddenConsumeCD = CurTime() + 1
        ConsumeBody(ply, body)
    end)

    hook.Add("PlayerCanPickupWeapon", "the_hidden_nofirearms", function(ply, weapon)
        if not IsHidden(ply) then return end
        if IsValid(weapon) and weapon.ishgweapon then return false end
    end)

    hook.Add("PreHomigradDamage", "the_hidden_pain", function(ent, dmgInfo)
        if not IsValid(ent) then return end

        local ply = ent:IsPlayer() and ent or hg.RagdollOwner(ent)
        if not IsHidden(ply) or not ply:Alive() then return end
        if dmgInfo:GetDamage() <= 0 then return end

        ply:SetNW2Float("HiddenHurt", CurTime())

        if (ply.HiddenPainCD or 0) > CurTime() then return end
        if ply.organism and ply.organism.otrub then return end

        local chr = hg.GetCurrentCharacter(ply)
        if not IsValid(chr) then return end

        if ply.lastPhr then
            chr:StopSound(ply.lastPhr)
        end

        local snd = painSounds[math.random(#painSounds)]
        chr:EmitSound(snd, 80, 100, 1, CHAN_AUTO)

        local dur = painDurations[snd]
        if not dur then
            dur = math.max(SoundDuration(snd) or 0, 1)
            painDurations[snd] = dur
        end
        ply.HiddenPainCD = CurTime() + dur
        ply.phrCld = CurTime() + dur
        ply.lastPhr = snd
    end)
end

if CLIENT then
    local wrapped

    local function WrapRender()
        if not hg or not hg.renderOverride or hg.renderOverride == wrapped then return end

        local original = hg.renderOverride

        wrapped = function(self, ent, flags)
            if IsHidden(self) and self:Alive() then
                local old = render.GetBlend()
                render.SetBlend(self.HiddenAlphaCur or ALPHA_HIDDEN)
                original(self, ent, flags)
                render.SetBlend(old)
                return
            end

            return original(self, ent, flags)
        end

        hg.renderOverride = wrapped
    end

    WrapRender()
    hook.Add("InitPostEntity", "the_hidden_render", WrapRender)
    timer.Create("the_hidden_render", 1, 0, function()
        WrapRender()
        for _, ply in player.Iterator() do
            ply.HiddenShadowEnt = nil
        end
    end)

    hook.Add("Think", "the_hidden_alpha", function()
        local ft = FrameTime()
        local now = CurTime()
        local k = 1 - math.exp(-ft * FADE_SPEED)

        for _, ply in player.Iterator() do
            if ply.PlayerClassName ~= "the_hidden" or not ply:Alive() then continue end

            local revealed = (now - ply:GetNW2Float("HiddenHurt", -100)) < REVEAL_TIME
            local target = revealed and ALPHA_REVEALED or ALPHA_HIDDEN
            local cur = ply.HiddenAlphaCur or ALPHA_HIDDEN

            if math.abs(cur - target) > 0.001 then
                ply.HiddenAlphaCur = Lerp(k, cur, target)
            else
                ply.HiddenAlphaCur = target
            end

            local chr = hg.GetCurrentCharacter(ply)
            if ply.HiddenShadowEnt ~= chr then
                ply:DrawShadow(false)
                if IsValid(chr) then chr:DrawShadow(false) end
                ply.HiddenShadowEnt = chr
            end
        end
    end)
end

return CLASS
