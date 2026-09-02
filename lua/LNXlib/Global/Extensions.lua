function math.clamp(n, low, high)
    return math.min(math.max(n, low), high)
end

function math.round(n)
    return math.floor(n + 0.5)
end

function math.lerp(a, b, t)
    return a + (b - a) * t
end

function table.readOnly(t)
    local proxy = {}
    setmetatable(proxy, {
        __index = t,
        __newindex = function(u, k, v)
            error("Attempt to modify read-only table", 2)
        end
    })

    return proxy
end

function table.find(t, value)
    for k, v in pairs(t) do
        if v == value then return k end
    end

    return nil
end

function table.contains(t, value)
    return table.find(t, value) ~= nil
end

function string.split(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end

    table.insert(result, string.sub(str, from))
    return result
end
