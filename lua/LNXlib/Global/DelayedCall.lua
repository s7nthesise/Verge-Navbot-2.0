local delayedCalls = {}

function _G.DelayedCall(delay, func)
    table.insert(delayedCalls, {
        time = globals.RealTime() + delay,
        func = func
    })
end

local function OnDraw()
    local curTime = globals.RealTime()
    for i, call in ipairs(delayedCalls) do
        if curTime > call.time then
            table.remove(delayedCalls, i)
            call.func()
        end
    end
end

Internal.RegisterCallback("Draw", OnDraw, "DelayedCall")
