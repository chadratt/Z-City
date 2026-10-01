local MODE = MODE

MODE.base = "tdm"
MODE.name = "hidden"
MODE.PrintName = "The Hidden"
MODE.HiddenCount = 1
MODE.PrepTime = 10
MODE.RadarRange = 1500

function MODE:HG_MovementCalc_2(mul, ply, cmd, mv)
    if (zb.ROUND_START or 0) + self.PrepTime > CurTime() and cmd then
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_FORWARD)
        cmd:RemoveKey(IN_BACK)
        cmd:RemoveKey(IN_MOVELEFT)
        cmd:RemoveKey(IN_MOVERIGHT)

        if mv then
            mv:RemoveKey(IN_ATTACK)
            mv:RemoveKey(IN_FORWARD)
            mv:RemoveKey(IN_BACK)
            mv:RemoveKey(IN_MOVELEFT)
            mv:RemoveKey(IN_MOVERIGHT)
        end

        mul[1] = 0
    end
end
