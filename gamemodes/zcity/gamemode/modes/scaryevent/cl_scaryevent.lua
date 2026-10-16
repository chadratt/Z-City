MODE.name = "PALEMAN"

local MODE = MODE

local roundend = false

local PALEMAN_ScarySounds = {
	"mumbling.wav",
	"blow.mp3",
	"knock.mp3",
	"HUSK/voices/voice1.wav",
	"HUSK/voices/voice2.wav",
	"HUSK/voices/voice3.wav",
	"HUSK/voices/voice4.wav",
	"HUSK/voices/voice5.wav",
	"HUSK/voices/voice6.wav",
	"HUSK/voices/voice7.wav",
	"HUSK/voices/voice8.wav",
	"HUSK/voices/voice9.wav",
	"HUSK/voices/voice10.wav",
	"HUSK/voices/voice11.wav",
	"HUSK/voices/voice12.wav",
	"HUSK/voices/voice13.wav",
	"HUSK/voices/voice14.wav",
	"HUSK/voices/voice15.wav",
}

local PALEMAN_SOUND_TIMER = "PALEMAN_ScarySounds"

local function PALEMAN_StopScarySounds()
	timer.Remove(PALEMAN_SOUND_TIMER)
end

local function PALEMAN_StartScarySounds()
	PALEMAN_StopScarySounds()

	timer.Create(PALEMAN_SOUND_TIMER, 12, 0, function()
		local lp = LocalPlayer()
		if not IsValid(lp) then return end

		local snd = table.Random(PALEMAN_ScarySounds)

		if snd == "knock.mp3" then
			surface.PlaySound("knock.mp3")
			timer.Adjust(PALEMAN_SOUND_TIMER, math.Rand(20, 60))

			return
		end

		local pos = lp:GetPos() + Vector(math.Rand(-512, 512), math.Rand(-512, 512), math.Rand(0, 512))
		EmitSound(snd, pos, 0, nil)
		timer.Adjust(PALEMAN_SOUND_TIMER, math.Rand(40, 90))
	end)
end

local musicStation
local musicToken = 0

local function PALEMAN_StopMusic()
	if IsValid(musicStation) then
		musicStation:Stop()
	end
	musicStation = nil
end

local function PALEMAN_PlayMusic(path)
	PALEMAN_StopMusic()

	musicToken = musicToken + 1
	local myToken = musicToken

	sound.PlayFile("sound/" .. path, "mono noblock", function(station)
		if not IsValid(station) then return end

		if myToken ~= musicToken then
			station:Stop()
			return
		end

		PALEMAN_StopMusic()
		musicStation = station
		station:Play()
	end)
end

local PALEMAN_ROUNDMUSIC_DELAY = 140

net.Receive("scaryevent_start", function()
	roundend = false

	PALEMAN_StartScarySounds()

	PALEMAN_PlayMusic("HUSK/intermission.wav")

	timer.Create("PALEMAN_RoundMusic", PALEMAN_ROUNDMUSIC_DELAY, 1, function()
		PALEMAN_PlayMusic("HUSK/roundmusic.mp3")
	end)

    StartTime = CurTime()
end)

net.Receive("paleman_finalduel", function()
	timer.Remove("PALEMAN_RoundMusic")
	PALEMAN_PlayMusic("HUSK/marchingupstream.mp3")
end)

local slugcat = {
    name = "Husk",
    color1 = Color(190,15,15)
}

local SCRAMBLE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?@#%&*/\\<>"
local scrambleTitle = { text = "", nextUpdate = 0 }

local function GetScrambledTitle()
    if CurTime() >= scrambleTitle.nextUpdate then
        local s = ""
        for i = 1, 10 do
            local n = math.random(1, #SCRAMBLE_CHARS)
            s = s .. SCRAMBLE_CHARS:sub(n, n)
        end
        scrambleTitle.text = s
        scrambleTitle.nextUpdate = CurTime() + 0.06
    end

    return scrambleTitle.text
end

function MODE:RenderScreenspaceEffects()
    if not zb.ROUND_START or zb.ROUND_START + 7.5 < CurTime() then return end
	
    local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(),0,1)

    surface.SetDrawColor(0,0,0,255 * fade)
    surface.DrawRect(-1,-1,ScrW() + 1,ScrH() + 1)
end

function MODE:HUDPaint()
	local introEnd = zb.ROUND_START + 140
	local roundEnd = introEnd + 600

	if CurTime() < introEnd then
		draw.SimpleText( string.FormattedTime(introEnd - CurTime(), "%02i:%02i:%02i"	), "ZB_HomicideMedium", sw * 0.5, sh * 0.75, Color(255,55,55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	elseif CurTime() < roundEnd then
		draw.SimpleText( string.FormattedTime(roundEnd - CurTime(), "%02i:%02i:%02i"	), "ZB_HomicideMedium", sw * 0.5, sh * 0.75, Color(255,55,55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if not lply:Alive() then return end
    if zb.ROUND_START + 8.5 < CurTime() then return end
	zb.RemoveFade()
    local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(),0,1)
    
    draw.SimpleText(GetScrambledTitle(), "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0,162,255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local roleText = (CurTime() >= zb.ROUND_START + 7) and "You are a Husk" or "You are a survivor"
	local ColorRole = slugcat.color1
    ColorRole.a = 255 * fade
    draw.SimpleText(roleText, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local Objective = slugcat.objective
    local ColorObj = slugcat.color1
    ColorObj.a = 255 * fade

end

local CreateEndMenu = nil
local wonply = nil

net.Receive("scaryevent_end", function()
	local ent = net.ReadEntity()
	wonply = nil
	if IsValid(ent) then
		ent.won = true
		wonply = ent
	end
	
	roundend = CurTime()

	PALEMAN_StopScarySounds()
	PALEMAN_StopMusic()
	timer.Remove("PALEMAN_RoundMusic")

    CreateEndMenu()
end)

local colGray = Color(85,85,85,255)
local colRed = Color(217,201,99)
local colRedUp = Color(207,181,59)

local colBlue = Color(10,10,160)
local colBlueUp = Color(40,40,160)
local col = Color(255,255,255,255)

local colSpect1 = Color(75,75,75,255)
local colSpect2 = Color(255,255,255)

local colorBG = Color(55,55,55,255)
local colorBGBlacky = Color(40,40,40,255)

local blurMat = Material("pp/blurscreen")
local Dynamic = 0

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
    hmcdEndMenu:Remove()
    hmcdEndMenu = nil
end

CreateEndMenu = function()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
	Dynamic = 0
	hmcdEndMenu = vgui.Create("ZFrame")

    surface.PlaySound("ambient/alarms/warningbell1.wav")

	local sizeX,sizeY = ScrW() / 2.5 ,ScrH() / 1.2
	local posX,posY = ScrW() / 1.3 - sizeX / 2,ScrH() / 2 - sizeY / 2

	hmcdEndMenu:SetPos(posX,posY)
	hmcdEndMenu:SetSize(sizeX,sizeY)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)

	local closebutton = vgui.Create("DButton",hmcdEndMenu)
	closebutton:SetPos(5,5)
	closebutton:SetSize(ScrW() / 20,ScrH() / 30)
	closebutton:SetText("")
	
	closebutton.DoClick = function()
		if IsValid(hmcdEndMenu) then
			hmcdEndMenu:Close()
			hmcdEndMenu = nil
		end
	end

	closebutton.Paint = function(self,w,h)
		surface.SetDrawColor( 122, 122, 122, 255)
        surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
		surface.SetFont( "ZB_InterfaceMedium" )
		surface.SetTextColor(col.r,col.g,col.b,col.a)
		local lengthX, lengthY = surface.GetTextSize("Close")
		surface.SetTextPos( lengthX - lengthX/1.1, 4)
		surface.DrawText("Close")
	end

    hmcdEndMenu.Paint = function(self,w,h)
		BlurBackground(self)
		local txt = (wonply and wonply:GetPlayerName() or "Nobody").." won!"
		surface.SetFont( "ZB_InterfaceMediumLarge" )
		surface.SetTextColor(col.r,col.g,col.b,col.a)
		local lengthX, lengthY = surface.GetTextSize(txt)
		surface.SetTextPos(w / 2 - lengthX/2,20)
		surface.DrawText(txt)

		surface.SetDrawColor( 255, 0, 0, 128)
        surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	end
	
	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)
	function DScrollPanel:Paint( w, h )
		BlurBackground(self)

		surface.SetDrawColor( 255, 0, 0, 128)
        surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	end

	for i,ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		local but = vgui.Create("DButton",DScrollPanel)
		but:SetSize(100,50)
		but:Dock(TOP)
		but:DockMargin( 8, 6, 8, -1 )
		but:SetText("")
		but.Paint = function(self,w,h)
			local col1 = (ply.won and colRed) or (ply:Alive() and colBlue) or colGray
            local col2 = (ply.won and colRedUp) or (ply:Alive() and colBlueUp) or colSpect1
			
			surface.SetDrawColor(col1.r,col1.g,col1.b,col1.a)
			surface.DrawRect(0,0,w,h)
			surface.SetDrawColor(col2.r,col2.g,col2.b,col2.a)
			surface.DrawRect(0,h/2,w,h/2)

            local col = ply:GetPlayerColor():ToColor()
			surface.SetFont( "ZB_InterfaceMediumLarge" )
			local lengthX, lengthY = surface.GetTextSize( ply:GetPlayerName() or "He quited..." )
			
			surface.SetTextColor(0,0,0,255)
			surface.SetTextPos(w / 2 + 1,h/2 - lengthY/2 + 1)
			surface.DrawText(ply:GetPlayerName() or "He quited...")

			surface.SetTextColor(col.r,col.g,col.b,col.a)
			surface.SetTextPos(w / 2,h/2 - lengthY/2)
			surface.DrawText(ply:GetPlayerName() or "He quited...")

			local col = colSpect2
			surface.SetFont( "ZB_InterfaceMediumLarge" )
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local lengthX, lengthY = surface.GetTextSize( ply:GetPlayerName() or "He quited..." )
			surface.SetTextPos(15,h/2 - lengthY/2)
			surface.DrawText((ply:Name() .. (not ply:Alive() and " - died" or "")) or "He quited...")

			surface.SetFont( "ZB_InterfaceMediumLarge" )
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local lengthX, lengthY = surface.GetTextSize( ply:Frags() or "He quited..." )
			surface.SetTextPos(w - lengthX -15,h/2 - lengthY/2)
			surface.DrawText(ply:Frags() or "He quited...")
		end

		function but:DoClick()
			if ply:IsBot() then chat.AddText(Color(255,0,0), "no, you can't") return end
			gui.OpenURL("https://steamcommunity.com/profiles/"..ply:SteamID64())
		end

		DScrollPanel:AddItem(but)
	end

	return true
end

function MODE:RoundStart()
    for i, ply in player.Iterator() do
		ply.won = nil
    end

    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end