local CLASS = player.RegClass("MEAT")


local subclasses = {
    default = {
        color = Color(120, 20, 20),
        models = {
            "models/wild/skinhoarder/skinhoarder01_pm.mdl"
        },
        loadout = {
            {weapon = "weapon_hands_sh"}
        }
    }
}

local function giveSubClassLoadout(ply, subclass)
    if CLIENT then
        return
    end
    if not IsValid(ply) or not ply:IsPlayer() then
        return
    end

    ply:StripWeapons()

    for _, item in ipairs(subclass.loadout or {}) do
        if item.weapon then
            ply:Give(item.weapon)
        end
    end
end


local function MeatSpawnGore(ply)
    if not SERVER then
        return
    end
    if not IsValid(ply) then
        return
    end

    local pos = ply:GetPos() + Vector(0, 0, 40)

    for i = 1, 20 do
        util.Decal("Blood", pos + VectorRand(-18, 18), pos + VectorRand(18, 18), ply)
    end

    if SpawnMeatGore then
        SpawnMeatGore(ply, pos, math.random(12, 18), VectorRand() * 160, 1.3)
    end

    timer.Simple(
        0.05,
        function()
            if not IsValid(ply) then
                return
            end

            local snd = "player/zombie_head_explode_01.wav"

            local soundEnt = ents.Create("env_speaker")
            if not IsValid(soundEnt) then
                return
            end

            soundEnt:SetPos(ply:GetPos())
            soundEnt:SetKeyValue("volstart", "100")
            soundEnt:SetKeyValue("spinup", "0")
            soundEnt:SetKeyValue("spindown", "0")
            soundEnt:SetKeyValue("preset", "0")
            soundEnt:Spawn()
            soundEnt:Activate()

            soundEnt:EmitSound(snd, 90, 100)

            util.ScreenShake(ply:GetPos(), 20, 15, 1.0, 99999)

            timer.Simple(
                0.3,
                function()
                    if IsValid(ply) then
                        util.ScreenShake(ply:GetPos(), 3, 3, 0.6, 99999)
                    end
                end
            )

            SafeRemoveEntityDelayed(soundEnt, 2)
        end
    )

    timer.Simple(
        0.7,
        function()
            if not IsValid(ply) then
                return
            end

            local snd = "cryptid/roar2.wav"

            local soundEnt = ents.Create("env_speaker")
            if not IsValid(soundEnt) then
                return
            end

            soundEnt:SetPos(ply:GetPos())
            soundEnt:SetKeyValue("volstart", "100")
            soundEnt:SetKeyValue("spinup", "0")
            soundEnt:SetKeyValue("spindown", "0")
            soundEnt:SetKeyValue("preset", "0")
            soundEnt:Spawn()
            soundEnt:Activate()

            soundEnt:EmitSound(snd, 90, math.random(90, 110))

            SafeRemoveEntityDelayed(soundEnt, 2)
        end
    )
end


function CLASS.On(self, data)
    if CLIENT then
        return
    end
    if not IsValid(self) or not self:IsPlayer() then
        return
    end

    -- DROP EVERYTHING BEFORE TRANSFORMATION
    if self.DropWeapon then
        for _, wep in ipairs(self:GetWeapons()) do
            if IsValid(wep) then
                self:DropWeapon(wep)
            end
        end
    end


    self:StripWeapons()

    local sub = subclasses.default
    local useModel = table.Random(sub.models or {})

    giveSubClassLoadout(self, sub)

    self:SetNWString("PlayerClassName", "MEAT")

    if self.organism then
        self.organism.superfighter = true
        self.organism.recoilmul = 0.25
    end

    self.noSound = true
    timer.Simple(
        0.1,
        function()
            if IsValid(self) then
                self.noSound = false
            end
        end
    )

    if self.SelectWeapon then
        self:SelectWeapon("weapon_hands_sh")
    end

    if zb.GiveRole then
        zb.GiveRole(self, "MEAT", Color(120, 20, 20))
    end

    timer.Simple(
        0,
        function()
            if IsValid(self) and useModel then
                util.PrecacheModel(useModel)
                self:SetModel(useModel)
            end
        end
    )

    self:SetPlayerColor(Vector(sub.color.r / 255, sub.color.g / 255, sub.color.b / 255))

    timer.Simple(
        0.05,
        function()
            if IsValid(self) then
                MeatSpawnGore(self)
            end
        end
    )
end


function CLASS.Off(self)
    if CLIENT then
        return
    end
    if not IsValid(self) or not self:IsPlayer() then
        return
    end

    self:StripWeapons()
    self:SetNWString("PlayerClassName", nil)

    if self.organism then
        self.organism.superfighter = nil
        self.organism.recoilmul = nil
    end

    if self.organism and self.organism.stamina then
        self.organism.stamina[1] = self.organism.stamina.max
        self.organism.stamina.sub = 0
        self.organism.stamina.subadd = 0
    end

    self.StaminaExhaustMul = 1
end


if SERVER then
    local function IsMeat(ply)
        return IsValid(ply) and ply:IsPlayer() and ply.PlayerClassName == "MEAT"
    end

    hook.Add(
        "Think",
        "MEAT_InfiniteStamina",
        function()
            for _, ply in ipairs(player.GetAll()) do
                if IsMeat(ply) and ply.organism then
                    ply.organism.stamina[1] = ply.organism.stamina.max
                    ply.organism.stamina.sub = 0
                    ply.organism.stamina.subadd = 0
                    ply.StaminaExhaustMul = 0
                end
            end
        end
    )
    hook.Add("PlayerCanPickupWeapon", "MEAT_BlockWeaponPickup", function(ply, weapon)
    if IsValid(ply) and ply.PlayerClassName == "MEAT" then
        local class = isstring(weapon) and weapon or weapon:GetClass()

        if class == "weapon_hands_sh" then
            return true 
        end

        return false
    end
end)

    hook.Add(
        "FinishMove",
        "MEAT_NoJumpStamina",
        function(ply)
            if IsMeat(ply) and ply.organism then
                ply.organism.stamina[1] = ply.organism.stamina.max
            end
        end
    )
end

if SERVER then
    local meat_phrases = {}

    local files, _ = file.Find("sound/cryptid/*.wav", "GAME")
    for k, v in ipairs(files) do
        meat_phrases[k] = "cryptid/" .. v
    end

    hook.Add(
        "HG_ReplacePhrase",
        "meat_phrase",
        function(ply, phrase, muffed, pitch)
            if IsValid(ply) and ply.PlayerClassName == "MEAT" then
                if #meat_phrases == 0 then
                    return
                end
                return ply, meat_phrases[math.random(#meat_phrases)], muffed, pitch
            end
        end
    )
end


local meatFootstepSounds = {
    "npc/antlion_guard/foot_heavy1.wav",
    "npc/antlion_guard/foot_heavy2.wav",
    "npc/antlion_guard/foot_light1.wav"
}

hook.Add(
    "HG_PlayerFootstep",
    "Combine_footsteps",
    function(ply)
        local chr = hg.GetCurrentCharacter(ply)

        if ply:Alive() and ply.PlayerClassName == "MEAT" then
            ply.MEATLerpedFootStep =
                LerpFT(
                0.5,
                ply.MEATLerpedFootStep or 60,
                (not ply:IsSprinting() and (ply:KeyDown(IN_DUCK) or ply:KeyDown(IN_WALK))) and 20 or 60
            )

            if IsValid(ply.FakeRagdoll) and ply:GetNetVar("lastFake") == 0 then
                return
            end

            ply.MEATStepIndex = (ply.MEATStepIndex or 0) + 1

            local soundPath = meatFootstepSounds[(ply.MEATStepIndex - 1) % #meatFootstepSounds + 1]

            chr:EmitSound(soundPath, ply.MEATLerpedFootStep)
        end
    end
)


if CLIENT then
    local meatMat = Material("effects/shaders/zb_grain2")
    local meatMat_Add = Material("effects/shaders/zb_heat")

    hook.Add(
        "Post Post Processing",
        "MEAT_Shader",
        function()
            local lply = LocalPlayer()
            if not IsValid(lply) then
                return
            end
            if lply.PlayerClassName ~= "MEAT" then
                return
            end
            if not lply:Alive() then
                return
            end
            if GetViewEntity() ~= lply then
                return
            end

            render.UpdateScreenEffectTexture()

            meatMat_Add:SetFloat("$c0_x", -CurTime() * 0.5)
            meatMat_Add:SetFloat("$c0_y", 0.05)
            meatMat_Add:SetFloat("$c2_x", 1.5)

            render.SetMaterial(meatMat_Add)
            render.DrawScreenQuad()

            render.UpdateScreenEffectTexture()
            render.UpdateFullScreenDepthTexture()

            local pulse = math.Clamp(math.sin(CurTime() * 1.5), 0.7, 1)

            meatMat:SetFloat("$c0_x", CurTime())
            meatMat:SetFloat("$c0_y", -0.8)
            meatMat:SetFloat("$c0_z", 2)
            meatMat:SetFloat("$c1_x", 15)
            meatMat:SetFloat("$c1_y", 0.15)
            meatMat:SetFloat("$c1_z", 0.1)
            meatMat:SetFloat("$c2_x", 0.4 * pulse)
            meatMat:SetFloat("$c2_y", 0.05)
            meatMat:SetFloat("$c2_z", 0)
            meatMat:SetFloat("$c3_x", 0)

            render.SetMaterial(meatMat)
            render.DrawScreenQuad()
        end
    )
end

local scancolor = Color(60, 199, 220)

local scanRadius = 0
local scanActive = false
local scanPos = Vector()
local scanCD = 0
local foundPrey = {}

local glow = Material("sprites/light_ignorez")


local function IsInSphere(ent, spherePos, radius)
    if not IsValid(ent) then return false end
    return ent:GetPos():DistToSqr(spherePos) <= radius * radius
end


local function DrawScanSphere(color, pos, radius)
    render.SetColorMaterial()
    render.DrawSphere(pos, radius, 32, 32, color)
end


function StartMEATScan()
    local lply = LocalPlayer()

    if not IsValid(lply) then return end
    if lply.PlayerClassName ~= "MEAT" then return end
    if scanCD > CurTime() then return end

    surface.PlaySound("voicelines/growl/growl.wav")

    scanCD = CurTime() + 20

    timer.Simple(2.5, function()
        if not IsValid(lply) then return end

        scanRadius = 0
        scanPos = lply:EyePos()
        foundPrey = {}
        scanActive = true

        surface.PlaySound("zbattle/sonar.ogg")

        for i = 1, 30 do
            timer.Simple(i / 60, function()
                if IsValid(lply) then
                    ViewPunch(AngleRand(-0.3, 0.3))
                end
            end)
        end

        timer.Simple(20, function()
            scanActive = false
            foundPrey = {}

            surface.PlaySound("voicelines/growl/focusgrowl.wav")
        end)
    end)
end

hook.Add("PostDrawTranslucentRenderables", "MEATScanDetect", function()
    local lply = LocalPlayer()

    if not IsValid(lply) then return end
    if lply.PlayerClassName ~= "MEAT" then return end
    if not scanActive then return end

    scanRadius = math.Approach(scanRadius, 100000, FrameTime() * 1000)

    DrawScanSphere(
        ColorAlpha(scancolor, 255 - math.min(scanRadius / 30, 255)),
        scanPos,
        scanRadius
    )

    for _, ply in player.Iterator() do
        if ply == lply then continue end
        if not ply:Alive() then continue end
        if foundPrey[ply] then continue end

        if IsInSphere(ply, scanPos, scanRadius) then
            local color

            if ply.PlayerClassName ~= "MEAT" then
                color = Color(255, 0, 0)
            else
                color = scancolor
            end

            foundPrey[ply] = {
                pos = ply:GetPos(),
                color = color,
                time = CurTime() + 5
            }

            surface.PlaySound("zbattle/sonarping.ogg")
        end
    end
end)


hook.Add("HUDPaint", "MEATScanMarkers", function()
    local lply = LocalPlayer()

    if not IsValid(lply) then return end
    if lply.PlayerClassName ~= "MEAT" then return end

    local sw, sh = ScrW(), ScrH()

    for _, data in pairs(foundPrey) do
        local pos = data.pos:ToScreen()

        local x = math.Clamp(pos.x, sh * .1, sw - sh * .1)
        local y = math.Clamp(pos.y, sh * .1, sh - sh * .1)

        local alpha = math.max(0, (data.time - CurTime()) * 100)

        surface.SetDrawColor(ColorAlpha(data.color, alpha))
        surface.SetMaterial(glow)
        surface.DrawTexturedRect(x - 50, y - 50, 100, 100)
    end
end)


hook.Add("radialOptions", "MEATScanOption", function()
    local lply = LocalPlayer()

    if not IsValid(lply) then return end
    if not lply:Alive() then return end
    if lply.PlayerClassName ~= "MEAT" then return end

    hg.radialOptions[#hg.radialOptions + 1] = {
        StartMEATScan,
        "Scan"
    }
end)

return CLASS
