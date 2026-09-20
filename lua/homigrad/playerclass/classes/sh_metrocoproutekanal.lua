local CLASS = player.RegClass("metrocoproutekanal")

local callsigns = {
    "Alfa","Bravo","Charlie","Delta","Echo",
    "Foxtrot","Tango","Sierra","Uniform","Kilo","Yankee","Regent",
    "Zulu","Omega","Nova","Viper","Ghost","Raven",
}

local leader_callsigns = {"JUDGE", "VERDICT", "DEFENDER", "JURY", "VICTOR"}

local CombineSquads = {squads = {}, playerSquad = {}, usedCallsigns = {}, squadSize = 4}

local function GetSquadForCombine(ply)
    for name, data in pairs(CombineSquads.squads) do
        for i = #data.members, 1, -1 do
            local m = data.members[i]
            if not IsValid(m) or m.PlayerClassName ~= "metrocoproutekanal" then table.remove(data.members, i) end
        end
        if #data.members < CombineSquads.squadSize then return name end
    end
    
    local available = {}
    for _, cs in ipairs(callsigns) do
        if not CombineSquads.usedCallsigns[cs] then table.insert(available, cs) end
    end
    if #available == 0 then return callsigns[math.random(#callsigns)] end
    
    local newName = available[math.random(#available)]
    CombineSquads.usedCallsigns[newName] = true
    CombineSquads.squads[newName] = {members = {}, usedNumbers = {}}
    return newName
end

local function AssignCombineCallsign(ply, isLeader)
    if math.random(1, 1000) <= 1 then return "Scug" end
    
    if isLeader then return leader_callsigns[math.random(#leader_callsigns)] .. "-1" end
    
    local squadName = GetSquadForCombine(ply)
    local squad = CombineSquads.squads[squadName]
    if not squad then return callsigns[math.random(#callsigns)] .. "-" .. math.random(10, 99) end
    
    local num
    repeat num = math.random(10, 99) until not squad.usedNumbers[num]
    squad.usedNumbers[num] = true
    table.insert(squad.members, ply)
    CombineSquads.playerSquad[ply] = squadName
    
    return squadName .. "-" .. num
end

local function RemoveCombineFromSquad(ply)
    local name = CombineSquads.playerSquad[ply]
    if not name then return end
    local squad = CombineSquads.squads[name]
    if squad then
        for i, m in ipairs(squad.members) do
            if m == ply then table.remove(squad.members, i) break end
        end
        if #squad.members == 0 then
            CombineSquads.squads[name] = nil
            CombineSquads.usedCallsigns[name] = nil
        end
    end
    CombineSquads.playerSquad[ply] = nil
end

hook.Add("PostCleanupMap", "CombineSquads_Reset", function()
    CombineSquads.squads = {}
    CombineSquads.playerSquad = {}
    CombineSquads.usedCallsigns = {}
end)


local primary_weapons = {
    "weapon_mp7",
    "weapon_mp7"
}

--;; Реврайт сабклассов (бай дека)
--;; Теперь можно настроить нормально лодаут,
--;; цвет, модель, дополнительные настройки и т.д.
local combine_subclasses = {
    default = {
        models = Model("models/player/police.mdl"),
        loadout = {
		    {
                weapon = "weapon_hg_stunstick",
            },
            {
                weapon = "weapon_hk_usp",
                ammo_mult = 3
            }
        },
    },

    subgunner = {
        models = Model("models/player/police.mdl"),
        loadout = {
		    {
                weapon = "weapon_hg_stunstick",
            },
            {
                weapon = "weapon_hk_usp",
                ammo_mult = 3
            },
            {
                weapon = "weapon_mp7",
                ammo_mult = 3,
                extra_balls = 3 
            }
        }
    },
    shotgunner = {
        models = Model("models/player/police.mdl"),
        loadout = {
            {
                weapon = "weapon_hg_flashbang_tpik",
                count = 1
            },
            {
                weapon = "weapon_hg_stunstick",
                ammo_mult = 3
            },
            {
                weapon = "weapon_breachcharge",
                count = 1
            }
        }
    }
}

local combines = {
    "npc_combine_s",
    "npc_strider",
    "npc_metropolice",
    "npc_hunter",
    "npc_rollermine",
    "npc_cscanner",
    "npc_combinegunship",
    "npc_combinedropship",
    "npc_clawscanner",
    "npc_manhack",
    "npc_combine_camera",
    "npc_turret_ceiling",
    "npc_turret_floor"
}

local rebels = {
    "npc_alyx",
    "npc_barney",
    "npc_citizen",
    "npc_eli",
    "npc_fisherman",
    "npc_kleiner",
    "npc_magnusson",
    "npc_mossman",
    "npc_odessa",
    "npc_rollermine_hacked",
    "npc_turret_floor_resistance",
    "npc_vortigaunt"
}

function CLASS.Off(self)
    if CLIENT then return end

	if eightbit and eightbit.EnableEffect and self.UserID then
		eightbit.EnableEffect(self:UserID(), 0)
	end

    RemoveCombineFromSquad(self)

    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(combines,v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
        elseif table.HasValue(rebels,v:GetClass()) then
            v:AddEntityRelationship( self, D_LI, 0 )
        end
    end

	self:SetNWString("PlayerRole", nil)
	self:SetNWString("PlayerName", self.oldname_cmb or self:GetNWString("PlayerName"))
    self.organism.CantCheckPulse = nil
    self.leader = nil
	hook.Remove("OnEntityCreated", "relation_shipdo"..self:EntIndex())
end


CLASS.NoFreeze = true
CLASS.CanEmitRNDSound = false

local function giveSubClassLoadout(ply, subclass)
    local config = combine_subclasses[subclass] or combine_subclasses["default"]
    ply:StripWeapons()
    ply:Give("weapon_hands_sh")
    for _, item in ipairs(config.loadout or {}) do
        if item.weapon_random_pool then
            local randWep = item.weapon_random_pool[math.random(#item.weapon_random_pool)]
            local wep = ply:Give(randWep)
            if wep and item.ammo_mult then
                ply:GiveAmmo(wep:GetMaxClip1() * item.ammo_mult, wep:GetPrimaryAmmoType(), true)
            end
        else
            local wep = ply:Give(item.weapon)
            if IsValid(wep) then
                --;; патрончики
                if item.ammo_mult then
                    ply:GiveAmmo(wep:GetMaxClip1() * item.ammo_mult, wep:GetPrimaryAmmoType(), true)
                end
                --;; пример кастомной какахи 
                if item.count then
                    wep.count = item.count
                end
                if item.extra_balls then
                    wep:SetNWInt("Balls", item.extra_balls)
                end
            end
        end
    end
end

function CLASS.On(self, data)
    if CLIENT then return end

	if eightbit and eightbit.EnableEffect and self.UserID then
		eightbit.EnableEffect(self:UserID(), eightbit.EFF_PROOT) --!! placeholder
	end

    if IsValid(self.FakeRagdoll) then
        hg.FakeUp(self, nil, nil, true)
    end

    ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    Appearance.AAttachments = ""
    Appearance.AColthes = ""

    local sub = self.subClass or "default"
    local cfg = combine_subclasses[sub] or combine_subclasses["default"]
    local useModel = istable(cfg.models) and cfg.models[math.random(#cfg.models)] or cfg.models
    self:SetModel(useModel)
    self:SetSubMaterial()
	self:SetPlayerColor(Vector(0,0,0))
    self:SetNetVar("Accessories", "")

    if cfg.skin then
        self:SetSkin(cfg.skin)
    end

    if cfg.mat then
		for k, v in pairs(cfg.mat) do
        	self:SetSubMaterial(self:GetSubMaterialIdByName(k), v)
		end
    end

    self.organism.CantCheckPulse = true

    --;; Армор
    self.armors = {}
    self.armors["torso"] = "metrocop_armor"
    self.armors["head"] = "metrocop_helmet"
    self:SyncArmor()

    if not data.bNoEquipment then
        giveSubClassLoadout(self, sub)
    end

    self.subClass = nil
    self.organism.recoilmul = 0.6

    local isLeader = self.leader or (sub == "subgunner")
    local callsign = AssignCombineCallsign(self, isLeader)

    self.oldname_cmb = self:GetNWString("PlayerName")
    if zb.GiveRole then zb.GiveRole(self, self.leader and "High Rank" or "Judge", Color(89,230,255)) end
    self:SetNWString("PlayerName", callsign)

    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(combines,v:GetClass()) then
            v:AddEntityRelationship( self, D_LI, 0 )
            v:ClearEnemyMemory()
        elseif table.HasValue(rebels,v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
            v:ClearEnemyMemory()
        end
    end

    local index = self:EntIndex()
    hook.Add( "OnEntityCreated", "relation_shipdo"..index, function( ent )
        if not IsValid(self) then hook.Remove("OnEntityCreated","relation_shipdo"..index) return end
        if ( ent:IsNPC() ) then
            --print(ent:GetClass())
            if table.HasValue(combines,ent:GetClass()) then
                ent:AddEntityRelationship( self, D_LI, 0 )
            end

            if table.HasValue(rebels,ent:GetClass()) then
                ent:AddEntityRelationship( self, D_HT, 99 )
            end
        end
    end )

    self.CurAppearance = appearance
end

function CLASS.Guilt(self, victim)
    if CLIENT then return end

    if victim:GetPlayerClass() == self:GetPlayerClass() then
        return 1
    end
end

function CLASS.PlayerDeath(self)

    for k,v in ipairs(ents.FindByClass("npc_*")) do
        if table.HasValue(combines,v:GetClass()) then
            v:AddEntityRelationship( self, D_HT, 99 )
        elseif table.HasValue(rebels,v:GetClass()) then
            v:AddEntityRelationship( self, D_LI, 0 )
        end
    end

    hook.Remove( "OnEntityCreated", "relation_shipdo"..self:EntIndex())
end

if SERVER then
	local mtcop_phrases = {}
	local files,_ = file.Find("sound/npc/metropolice/vo/*.wav","GAME")
	for k,v in ipairs(files) do
		mtcop_phrases[k] = "npc/metropolice/vo/" .. v
	end

	hook.Add("HG_ReplacePhrase", "metropolice_phrase", function(ply, phrase, muffed, pitch)
		if IsValid(ply) and ply.PlayerClassName == "metrocoproutekanal" then
			return ply, mtcop_phrases[math.random(#mtcop_phrases)], muffed, pitch
		end
	end)
end


hook.Add("HG_CanThoughts", "CombineCantDumat", function(ply)
	if ply.PlayerClassName == "Combine" then
		return false
	end
end)

--;; Серверные хуки и звуки шагов/смерти
if SERVER then
    hook.Add("HG_PlayerFootstep","Combine_footsteps",function(ply)
        local chr = hg.GetCurrentCharacter(ply)
        if ply:Alive() and ply.PlayerClassName == "metrocoproutekanal" then
            --;; Если есть ragdoll и т.п.
            ply.CombineLerpedFootStep = LerpFT(0.5,ply.CombineLerpedFootStep or 60, (not ply:IsSprinting() and (ply:KeyDown(IN_DUCK) or ply:KeyDown(IN_WALK))) and 20 or 60)
            if IsValid(ply.FakeRagdoll) and ply:GetNetVar("lastFake") == 0 then return end
            chr:EmitSound("npc/combine_soldier/gear" .. math.random(1,6) .. ".wav",
                ply.CombineLerpedFootStep
            )
        end
    end)

    local hitgroups_sounds = {
        [HITGROUP_STOMACH] = true,
        [HITGROUP_CHEST]   = true,
        [HITGROUP_LEFTARM] = true,
        [HITGROUP_RIGHTARM] = true,
        [HITGROUP_RIGHTLEG] = true,
        [HITGROUP_LEFTLEG]  = true
    }
    hook.Add("HomigradDamage","Combine_painsounds",function(ply, dmgInfo, hitgroup, ent)
        --[[if ply.PlayerClassName == "Combine" then
            ply.painCD = ply.painCD or 0
            if hitgroups_sounds[hitgroup] and ply.painCD < CurTime() and ply.organism and not ply.organism.otrub and ply:Alive() then
                local snd = "npc/combine_soldier/pain" .. math.random(1,3) .. ".wav"
                ent:EmitSound(snd,80,ply.VoicePitch)
                ply.painCD = CurTime() + SoundDuration(snd)
                ply.lastPhr = snd
            end
        end--]]
    end)

    hook.Add("HGReloading","Combine_reloadalert",function(wep)
        local ply = wep:GetOwner()
        if not IsValid(ply) then return end
        local nearPlayers = ents.FindInSphere(ply:GetPos(),300)
        for _,mate in ipairs(nearPlayers) do
            if mate:IsPlayer() and mate ~= ply and mate:Alive() and mate.PlayerClassName == "Combine" then
                if ply:Alive() and not ply.organism.otrub and ply.PlayerClassName == "Combine" and wep.ShellEject ~= "ShotgunShellEject" then
                    local phrase = (math.random(1,2) == 2) and "npc/combine_soldier/vo/coverme.wav" or "npc/combine_soldier/vo/coverhurt.wav"
                    ply:EmitSound(phrase,75,ply.VoicePitch)
                    ply.phrCld = CurTime() + (SoundDuration(phrase) or 0)
                    ply.lastPhr = phrase
                    return
                end
            end
        end
    end)

    util.AddNetworkString("CombineRadioStart")
    util.AddNetworkString("CombineRadioEnd")
    util.AddNetworkString("CombineChatMessage")

    hook.Add("HG_PlayerCanHearPlayersVoice","CombineRadio",function(listener,talker)
        if talker.PlayerClassName == "Combine" and listener.PlayerClassName == "Combine" and talker:Alive() then
            return true,false
        end
    end)

    hook.Add("HG_PlayerSay","CombineChatMessage",function(ply, txtTbl, text)
        if ply.PlayerClassName == "Combine" and ply:Alive() and not ply.organism.otrub then
            ply:EmitSound("npc/metropolice/vo/on1.wav")
        end
    end)
end


if CLIENT then
    local radio_end_sound = Sound("npc/metropolice/vo/off4.wav")
    hook.Add("PlayerStartVoice","CombineRadioStart",function(ply)
        if ply.PlayerClassName == "Combine" and ply:Alive() then
            ply:EmitSound(radio_end_sound)
        end
    end)
    hook.Add("PlayerEndVoice","CombineRadioEnd",function(ply)
        if ply.PlayerClassName == "Combine" and ply:Alive() then
            ply:EmitSound(radio_end_sound)
        end
    end)

    hook.Add("HG_NoSoundproof","CombineNoSoundproof",function(pPly, lply)
        if pPly.PlayerClassName == "Combine" and pPly:Alive() and lply.PlayerClassName == "Combine" and lply:Alive() then
            return true 
        end
    end)
end

if CLIENT then
    local pnv_enabled = false
    local next_toggle_time = 0
    local toggle_cooldown = 1
    local transition_time = 1
    local transition_start = 0
    local transitioning = false
    local pnv_light = nil

    local pnv_color_1 = {
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0.07,
        ["$pp_colour_addb"] = 0.1,
        ["$pp_colour_brightness"] = 0.01,
        ["$pp_colour_contrast"] = 0.6,
        ["$pp_colour_colour"] = 0.08,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0.1,
        ["$pp_colour_mulb"] = 0.2
    }
    local pnv_color_2 = {
        ["$pp_colour_addr"] = 0.06,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0.05,
        ["$pp_colour_contrast"] = 0.6,
        ["$pp_colour_colour"] = 0.08,
        ["$pp_colour_mulr"] = 0.2,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    }

    local function togglePNV()
        local ply = LocalPlayer()
        if ply.PlayerClassName ~= "Combine" or not ply:Alive() then
            if pnv_enabled then
                pnv_enabled = false
                surface.PlaySound("items/nvg_off.wav")
                hook.Remove("RenderScreenspaceEffects","PNV_ColorCorrection")
                if IsValid(pnv_light) then
                    pnv_light:Remove()
                    pnv_light = nil
                end
            end
            return
        end

        pnv_enabled = not pnv_enabled
        transition_start = CurTime()

        if pnv_enabled then
            transitioning = true
            surface.PlaySound("items/nvg_on.wav")
            hook.Add("RenderScreenspaceEffects","PNV_ColorCorrection",function()
                if ply.PlayerClassName ~= "Combine" then return end
                local progress = math.min((CurTime() - transition_start)/transition_time,1)
                local class = ply:GetNWString("PlayerRole")
                local cc = (class == "Elite" or class == "Shotgunner") and table.Copy(pnv_color_2) or table.Copy(pnv_color_1)
                for k,v in pairs(cc) do
                    cc[k] = v * progress
                end
                DrawColorModify(cc)
                DrawBloom(0.1*progress,1*progress,2*progress,2*progress,1*progress,0.4*progress,1,1,1)
                if progress >= 1 then transitioning = false end
            end)
        else
            transitioning = false
            surface.PlaySound("items/nvg_off.wav")
            hook.Remove("RenderScreenspaceEffects","PNV_ColorCorrection")
        end
    end

    hook.Add("ZC_DisableShootTinnitus","NoCombineTinnitus",function(lply)
        if lply.PlayerClassName ~= "Combine" then return end
        return true
    end)

    hook.Add("ZC_BodyTemperature","CombineSuitWarming",function(ply, org, timeValue, changeRate, MaxWarmMul, warmLoseMul)
        if ply.PlayerClassName ~= "Combine" then return end
        return changeRate, MaxWarmMul + 0.5, warmLoseMul - 0.4
    end)

    hook.Add("PreDrawHalos","PNV_Light",function()
        local ply = LocalPlayer()
        if ply.PlayerClassName ~= "Combine" then return end
        if pnv_enabled then
            if not IsValid(pnv_light) then
                pnv_light = ProjectedTexture()
                pnv_light:SetTexture("effects/flashlight001")
                pnv_light:SetBrightness(2)
                pnv_light:SetEnableShadows(false)
                pnv_light:SetConstantAttenuation(0.02)
                pnv_light:SetNearZ(12)
                pnv_light:SetFOV(70)
            end
            pnv_light:SetPos(ply:EyePos())
            pnv_light:SetAngles(ply:EyeAngles())
            pnv_light:Update()
        elseif IsValid(pnv_light) then
            pnv_light:Remove()
            pnv_light = nil
        end
    end)

    hook.Add("Think","PNV_Think",function()
        local ply = LocalPlayer()
        if ply:Alive() and ply.PlayerClassName == "Combine" then
            if input.IsKeyDown(KEY_F) and not gui.IsGameUIVisible() and not IsValid(vgui.GetKeyboardFocus()) and (CurTime() > next_toggle_time) then
                togglePNV()
                next_toggle_time = CurTime() + toggle_cooldown
            end
        end
        if not ply:Alive() and pnv_enabled then togglePNV() end
        if ply.PlayerClassName ~= "Combine" and pnv_enabled then togglePNV() end

        if pnv_enabled and IsValid(pnv_light) then
            pnv_light:SetPos(ply:EyePos())
            pnv_light:SetAngles(ply:EyeAngles())
            pnv_light:Update()
        end
    end)
end


return CLASS
