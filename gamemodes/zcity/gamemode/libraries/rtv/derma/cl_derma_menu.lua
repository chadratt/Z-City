--
local PANEL = {}

local blurMat = Material("pp/blurscreen")
local Dynamic = 0

BlurBackground = hg.DrawBlur

function PANEL:Paint( w, h )

    local text = "Time to Rock The Vote"

	BlurBackground(self)

	surface.SetFont( "ZB_InterfaceMediumLarge" )
	surface.SetTextColor( color_white )
	local lengthX, lengthY = surface.GetTextSize( text )
	surface.SetTextPos( w / 2 - lengthX/2,20 )
	surface.DrawText( text )

	if self.EndTime then
		local remaining = math.max(0, math.ceil(self.EndTime - CurTime()))
		local timeText = remaining .. "s"

		surface.SetFont( "ZB_InterfaceMediumLarge" )
		local tw, th = surface.GetTextSize( timeText )
		surface.SetTextColor( remaining <= 5 and Color(255, 60, 60, 255) or color_white )
		surface.SetTextPos( w / 2 - tw / 2, 20 + lengthY + 4 )
		surface.DrawText( timeText )
	end

	surface.SetDrawColor( 255, 0, 0, 128)
    surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )

end

vgui.Register( "ZB_RTVMenu", PANEL, "ZFrame")