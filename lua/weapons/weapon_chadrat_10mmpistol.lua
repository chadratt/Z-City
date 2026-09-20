SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "10mm pistol"
SWEP.Author = "Chadrat"
SWEP.Instructions = "A Colt 6520 10mm autoloading pistol. Each pull of the trigger will automatically reload the firearm until the magazine is empty. Single shot only, using the powerful 10mm round."
SWEP.Category = "[chadrat] pistols"
SWEP.Slot = 2
SWEP.SlotPos = 10

-- ========== МОДЕЛИ ==========
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_10mm.mdl"
SWEP.WorldModelFake = "models/weapons/c_10mmPistol.mdl"
SWEP.MagModel = "models/weapons/largemagazine.mdl"


SWEP.NoWINCHESTERFIRE = true

-- ========== ПОЛОЖЕНИЕ РУК ==========
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(0, -0.0062, 7.9152)
SWEP.RHandPos = Vector(-14, -1, 3)
SWEP.LHandPos = false
SWEP.RHPos = Vector(5.8, -5.5, 3.5)
SWEP.RHAng = Angle(0, 5, 90)
SWEP.LHPos = Vector(7.5, -1, -3.5)
SWEP.LHAng = Angle(-40, 10, -90)
SWEP.handsAng = Angle(-10, 5, 0)
SWEP.FakePos = Vector(-12, 2.4, 8.5)
SWEP.FakeAng = Angle(1.0, 0.5, 0)
SWEP.holsteredBone = "ValveBiped.Bip01_Spine2"
SWEP.holsteredPos = Vector(0, 10, -7)
SWEP.holsteredAng = Angle(210, -5, 180)

-- ========== МИРОВАЯ МОДЕЛЬ ==========
SWEP.WorldPos = Vector(3.7, -0.5, 2.5)
SWEP.WorldAng = Angle(2, 0.7, 0)
SWEP.UseCustomWorldModel = true

-- ========== SPRAY ==========
SWEP.Spray = {}
for i = 1, 30 do
    SWEP.Spray[i] = Angle(-0.01 - math.cos(i) * 0.02, math.cos(i * 8) * 0.02, 0) * 1
end

-- ========== БОЕВЫЕ ХАРАКТЕРИСТИКИ ==========
SWEP.Primary.ClipSize = 12
SWEP.Primary.DefaultClip = 12
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "10mm Auto"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 35
SWEP.Primary.Spread = 0
SWEP.Primary.Force = 50
SWEP.Primary.Wait = 0.11
SWEP.Primary.Sound = {"10mm/10mm.wav", 75, 120, 130}
SWEP.SupressedSound = {"mp5k/mp5k_suppressed_tp.wav", 55, 90, 100}

-- ========== ОТДАЧА ==========
SWEP.ShockMultiplier = 500
SWEP.ViewPunchDiv = 2000
SWEP.weight = 1.5
SWEP.Ergonomics = 1.5
SWEP.Penetration = 2
SWEP.lengthSub = 10
SWEP.OpenBolt = true

-- ========== ЗВУКИ ==========
SWEP.FakeReloadSounds = {
    [0.3] = "10mm/10mm_reload_magout_01.wav",
    [0.8] = "10mm/10mm_reload_magin_01.wav",
}

SWEP.FakeEmptyReloadSounds = {
    [0.3] = "10mm/10mm_reload_magout_01.wav",
    [0.7] = "10mm/10mm_reload_magin_01.wav",
    [0.85] = "10mm/10mm_reload_boltclose_02.wav",
}

SWEP.ReloadSoundes = {
    "none", "none", "pwb/weapons/tmp/clipout.wav", "none", "none",
    "pwb/weapons/tmp/clipin.wav", "none", "none", "weapons/tfa_ins2/mp7/boltback.wav",
    "none", "weapons/tfa_ins2/mp7/boltrelease.wav", "none", "none", "none", "none"
}
SWEP.ReloadTime = 4
SWEP.DistSound = "10mm/10mm_distance1.wav"

-- ========== ВИЗУАЛЬНЫЕ ЭФФЕКТЫ ==========
SWEP.CustomShell = "9x19"
SWEP.LocalMuzzlePos = Vector(22.2, 0.3, 5.200)
SWEP.LocalMuzzleAng = Angle(1.0, 0.5, 0)
SWEP.WeaponEyeAngles = Angle(-1.5, -0.5, 0)

-- ========== АТТАЧМЕНТЫ ==========
SWEP.AttachmentPos = Vector(9.5, 0.5, 0.45)
SWEP.AttachmentAng = Angle(0, 0, 0)
SWEP.availableAttachments = {
}

-- ========== АНИМАЦИИ ==========
SWEP.AnimList = {
    ["idle"] = "base_idle",
    ["reload"] = "base_reload",
    ["reload_empty"] = "base_reload_empty",
}

SWEP.ShootAnimMul = 8
SWEP.animposmul = 2
SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_UpperArm"
SWEP.FakeMagDropBone = 73

local vector_full = Vector(1,1,1)
local vector_origin = Vector(0,0,0)

SWEP.FakeReloadEvents = {
    [0.2] = function(self, timeMul) 
        if CLIENT and self:Clip1() < 1 then
        end 
    end,
    [0.4] = function(self) 
        if CLIENT and self:Clip1() < 1 then
            hg.CreateMag(self, Vector(0,0,-55))
            self:GetWM():ManipulateBoneScale(73, vector_origin)
        end 
    end,
    [0.6] = function(self) 
        if CLIENT and self:Clip1() < 1 then
            self:GetWM():ManipulateBoneScale(73, vector_full)
        end 
    end,
}

SWEP.lmagpos = Vector(0, 0, 0)
SWEP.lmagang = Angle(0, 0, 0)
SWEP.lmagpos2 = Vector(0, -1.1, 3.5)
SWEP.lmagang2 = Angle(0, 0, -17)

SWEP.ReloadAnimLH = { Vector(0,0,0) }
SWEP.ReloadAnimLHAng = { Angle(0,0,0) }
SWEP.ReloadAnimRH = {
    Vector(0,0,0), Vector(0,2,4), Vector(0,0,5), Vector(-5,-3,9), Vector(-15,-15,2),
    Vector(-15,-15,2), Vector(-2,1,8), Vector(0,0,4), Vector(0,0,4), Vector(0,0,4),
    "fastreload", Vector(-4,1,-3), Vector(-8,1,-3), Vector(-8,1,-3), Vector(-4,4,-1),
    "reloadend", "reloadend"
}
SWEP.ReloadAnimRHAng = { Angle(0,0,0) }
SWEP.ReloadAnimWepAng = {
    Angle(0,0,0), Angle(-25,25,-44), Angle(-15,25,-45), Angle(-25,25,-45), Angle(-35,26,-44),
    Angle(-35,25,-45), Angle(-25,25,-44), Angle(-25,25,-44), Angle(-45,45,-55), Angle(-35,45,-55),
    Angle(-25,25,-44), Angle(0,0,0)
}
SWEP.ReloadSlideAnim = {
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,5,5,0,0,0,0,0,0
}

SWEP.InspectAnimLH = { Vector(0,0,0) }
SWEP.InspectAnimLHAng = { Angle(0,0,0) }
SWEP.InspectAnimRH = { Vector(0,0,0) }
SWEP.InspectAnimRHAng = { Angle(0,0,0) }
SWEP.InspectAnimWepAng = {
    Angle(0,0,0), Angle(15,15,15), Angle(15,15,24), Angle(15,15,24), Angle(15,15,24),
    Angle(15,7,24), Angle(10,3,-5), Angle(2,3,-15), Angle(0,4,-22), Angle(0,3,-45),
    Angle(0,3,-45), Angle(0,-2,-2), Angle(0,0,0)
}

-- ========== ИКОНКИ ==========
SWEP.WepSelectIcon2 = Material("entities/arc9_f4_10mm.png")
SWEP.WepSelectIcon2box = true
SWEP.IconOverride = "entities/arc9_f4_10mm.png"

-- ========== ОСТАЛЬНЫЕ ПАРАМЕТРЫ ==========
SWEP.ScrappersSlot = "Primary"
SWEP.weaponInvCategory = 1
SWEP.GetDebug = false
SWEP.CanEpicRun = true
SWEP.EpicRunPos = Vector(2, 10, 2)
SWEP.SetSupressor = false
SWEP.dwr_customIsSuppressed = true
SWEP.attPos = Vector(-9, -0.5, -0.5)
SWEP.attAng = Angle(-0.03, -0.3, 0)

-- ========== ФУНКЦИИ ==========
function SWEP:AnimHoldPost(model)
end

function SWEP:DrawPost()
    local wep = self:GetWeaponEntity()
    if CLIENT and IsValid(wep) then
        self.shooanim = LerpFT(0.4,self.shooanim or 0,((self:Clip1() > 0 or self.reload) and 0) or 1.8)
        wep:ManipulateBonePosition(118,Vector(-1*self.shooanim,0 ,0 ),false)
        local mul = self:Clip1() > 0 and 1 or 0
        --wep:ManipulateBoneScale(12,Vector(mul,mul,mul),false)
    end
end

-- Правильное выбрасывание оружия (как в ППШ)
function SWEP:WeaponDropped()
    if SERVER then
        local wep = self
        timer.Simple(0.1, function()
            if IsValid(wep) then
                wep:SetParent(nil)
                wep:SetSolid(SOLID_VPHYSICS)
                wep:SetMoveType(MOVETYPE_VPHYSICS)
                local phys = wep:GetPhysicsObject()
                if IsValid(phys) then
                    phys:EnableMotion(true)
                    phys:SetMass(2.5)
                    phys:ApplyForceCenter(Vector(0, 0, 50) + (wep:GetForward() * 20))
                end
            end
        end)
    end
end