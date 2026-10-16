local CLASS = player.RegClass("cryptidman2")

function CLASS.Off(self)
    if CLIENT then return end
end

local cryptidman_subclasses = {
    default = {
        color = Color(0,220,220),
        models = Model("models/panman/arc_future.mdl"),

    }
}

function CLASS.On(self)
    if CLIENT then return end

        ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    Appearance.AAttachments = ""
    Appearance.AColthes = ""

    local sub = self.subClass or "default"
    local cfg = cryptidman_subclasses[sub] or cryptidman_subclasses["default"]
    local useModel = istable(cfg.models) and cfg.models[math.random(#cfg.models)] or cfg.models
    self:SetModel(useModel)
    self:SetSubMaterial()
    self:SetNetVar("Accessories", "")
    self:SetPlayerColor(cfg.color:ToVector())
end

CLASS.CanUseDefaultPhrase = true
CLASS.CanEmitRNDSound = true
CLASS.CanUseGestures = true

function CLASS.Guilt(self, Victim)
    if CLIENT then return end
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

function Startcryptidman2Scan()
    local lply = LocalPlayer()

    if not IsValid(lply) then return end
    if lply.PlayerClassName ~= "cryptidman2" then return end
    if scanCD > CurTime() then return end

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

        end)
    end)
end

hook.Add("PostDrawTranslucentRenderables", "cryptidman2ScanDetect", function()
    local lply = LocalPlayer()

    if not IsValid(lply) then return end
    if lply.PlayerClassName ~= "cryptidman2" then return end
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

            if ply.PlayerClassName ~= "cryptidman2" then
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

hook.Add("HUDPaint", "cryptidman2ScanMarkers", function()
    local lply = LocalPlayer()

    if not IsValid(lply) then return end
    if lply.PlayerClassName ~= "cryptidman2" then return end

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

hook.Add("radialOptions", "cryptidman2ScanOption", function()
    local lply = LocalPlayer()

    if not IsValid(lply) then return end
    if not lply:Alive() then return end
    if lply.PlayerClassName ~= "cryptidman2" then return end

    hg.radialOptions[#hg.radialOptions + 1] = {
        Startcryptidman2Scan,
        "Scan"
    }
end)
