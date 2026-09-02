local Common = {}

local libLoaded, Lib = pcall(require, "LNXlib")
assert(libLoaded, "LNXlib not found, please install it!")

Common.Lib = Lib
Common.Utils = Common.Lib.Utils
Common.Notify = Lib.UI.Notify
Common.TF2 = Common.Lib.TF2

Common.Math, Common.Conversion = Common.Utils.Math, Common.Utils.Conversion
Common.WPlayer, Common.PR = Common.TF2.WPlayer, Common.TF2.PlayerResource
Common.Helpers = Common.TF2.Helpers
Common.WalkTo = Common.Helpers.WalkTo

Common.Json = require("lnxLib/Libs/dkjson")
Common.Log = Common.Utils.Logger.new("Navbot")
Common.Log.Level = 0

-- Is node b a DIRECT connection of node a (a shared nav-mesh edge)?
function Common.hasDirectEdge(a, b)
    if not (a and b and a.c) then return false end
    for _, connData in pairs(a.c) do
        if connData and connData.connections then
            for _, connId in ipairs(connData.connections) do
                if connId == b.id then return true end
            end
        end
    end
    return false
end

local HULL_MIN = Vector3(-24, -24, 0)
local HULL_MAX = Vector3(24, 24, 82)
local PROBE_MIN = Vector3(-8, -8, 0)
local PROBE_MAX = Vector3(8, 8, 60)
local STEP_UP = Vector3(0, 0, 18)
function Common.straightLineClear(from, to)
    local tr = engine.TraceHull(from + STEP_UP, to + STEP_UP, HULL_MIN, HULL_MAX, MASK_PLAYERSOLID_BRUSHONLY)
    return tr and tr.fraction >= 1.0
end

-- Steer toward the clear side; both blocked = no steer.
function Common.AvoidSteer(from, target)
    local fwd = target - from
    fwd.z = 0
    local len = fwd:Length()
    if len < 1 then return target end
    fwd = fwd * (1 / len)
    local left = Vector3(-fwd.y, fwd.x, 0)
    local lt = engine.TraceHull(from + left * 16 + STEP_UP, from + left * 16 + fwd * 50 + STEP_UP, PROBE_MIN, PROBE_MAX, MASK_PLAYERSOLID_BRUSHONLY)
    local rt = engine.TraceHull(from - left * 16 + STEP_UP, from - left * 16 + fwd * 50 + STEP_UP, PROBE_MIN, PROBE_MAX, MASK_PLAYERSOLID_BRUSHONLY)
    local leftClear = lt.fraction >= 1
    local rightClear = rt.fraction >= 1
    if leftClear and not rightClear then
        local d = fwd * 0.5 + left * math.max(0, math.min(1, 1 - rt.fraction))
        local dl = d:Length()
        if dl > 0.01 then
            return from + d * (100 / dl)
        end
    elseif rightClear and not leftClear then
        local d = fwd * 0.5 - left * math.max(0, math.min(1, 1 - lt.fraction))
        local dl = d:Length()
        if dl > 0.01 then
            return from + d * (100 / dl)
        end
    end
    return target
end


function Common.Normalize(vec)
    return vec / vec:Length()
end

-- pcall wrapper: surface and log callback errors to navbot_err.log
function Common.safeCall(name, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        local cur = filesystem.ReadFile("navbot_err.log") or ""
        filesystem.WriteFile("navbot_err.log", cur .. "[" .. name .. "] " .. tostring(err) .. "\n")
        print("[" .. name .. "] error: " .. tostring(err))
    end
    return ok, err
end

local function OnUnload()
    UnloadLib()
    client.Command('play "ui/buttonclickrelease"', true)
end

callbacks.Unregister("Unload", "CD_Unload")
callbacks.Register("Unload", "CD_Unload", OnUnload)

return Common
