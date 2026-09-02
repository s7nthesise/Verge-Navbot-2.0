local oldInternal = rawget(_G, "Internal")

_G.Internal = {}

function Internal.RegisterCallback(id, callback, ...)
    local name = table.concat({ "lnxLib", ..., id }, ".")
    callbacks.Unregister(id, name)
    callbacks.Register(id, name, callback)
end

function Internal.Cleanup()
    _G.Internal = oldInternal
end
