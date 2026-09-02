-- lnxLib: utility library for the Navbot

require("lnxLib/Global/Global")

local lnxLib = {
    TF2 = require("lnxLib/TF2/TF2"),
    UI = require("lnxLib/UI/UI"),
    Utils = require("lnxLib/Utils/Utils"),
}

function lnxLib.GetVersion()
    return 1.000
end

function UnloadLib()
    lnxLib.Utils.UnloadPackages("lnxLib")
    lnxLib.Utils.UnloadPackages("LNXlib")
end

printc(75, 210, 55, 255, string.format("lnxLib Loaded (v%.3f)", lnxLib.GetVersion()))
lnxLib.UI.Notify.Simple("lnxLib loaded", string.format("Version: %.3f", lnxLib.GetVersion()))

Internal.Cleanup()
return lnxLib
