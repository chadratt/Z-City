
if SERVER then
    AddCSLuaFile()
    return
end


if jit.arch == "x64" then return end


local MESSAGE =
    "You are not on the x86-64 bit branch of Garry's Mod. " ..
    "You will experience poor performance and will miss out on any new content " ..
    "that requires the build.\n\n" ..
    "Please go to the Discord and look at the top of the FAQ channel to see how to do it."


surface.CreateFont("BranchNotice_Body", {
    font   = "Tahoma",
    size   = 18,
    weight = 500,
})

local activeFrame 

local function ShowBranchPopup()
    if IsValid(activeFrame) then return end

    local frame = vgui.Create("DFrame")
    activeFrame = frame
    frame:SetSize(520, 260)
    frame:Center()
    frame:SetTitle("Wrong Garry's Mod Branch")
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)  
    frame:MakePopup()


    local msg = vgui.Create("DLabel", frame)
    msg:Dock(FILL)
    msg:DockMargin(16, 8, 16, 8)
    msg:SetText(MESSAGE)
    msg:SetWrap(true)
    msg:SetContentAlignment(7)    
    msg:SetFont("BranchNotice_Body")
    msg:SetTextColor(color_white)


    local close = vgui.Create("DButton", frame)
    close:Dock(BOTTOM)
    close:DockMargin(16, 4, 16, 12)
    close:SetTall(36)
    close:SetText("Close")
    close.DoClick = function()
        frame:Close()
    end
end


hook.Add("InitPostEntity", "BranchNotice_Show", function()
    timer.Simple(2, function()
        if not IsValid(LocalPlayer()) then return end
        ShowBranchPopup()
    end)
end)
