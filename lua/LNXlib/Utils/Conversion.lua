-- [Credits: Link2006]
local Conversion = {}

function Conversion.ID3_to_ID64(steamID3)
    if tonumber(steamID3) then
        return tostring(tonumber(steamID3) + 0x110000100000000)
    elseif steamID3:match("(%[U:1:%d+%])") then
        return tostring(tonumber(steamID3:match("%[U:1:(%d+)%]")) + 0x110000100000000)
    end

     return false, "Invalid SteamID"
end

function Conversion.ID64_to_ID3(steamID64)
    if not tonumber(steamID64) then
        return false, "Invalid SteamID"
    end

    local steamID = tonumber(steamID64)
    if (steamID - 0x110000100000000) < 0 then
        return false, "Not a SteamID64"
    end

    return ("[U:1:%d]"):format(steamID - 0x110000100000000)
end

function Conversion.Hex_to_RGB(pHex)
    local r = tonumber(string.sub(pHex, 1, 2), 16)
    local g = tonumber(string.sub(pHex, 3, 4), 16)
    local b = tonumber(string.sub(pHex, 5, 6), 16)
    return r, g, b
end

function Conversion.RGB_to_Hex(r, g, b)
    return string.format("%02x%02x%02x", r, g, b)
end

function Conversion.HSV_to_RGB(h, s, v)
    local r, g, b

    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);

    i = i % 6

    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    elseif i == 5 then
        r, g, b = v, p, q
    end

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

function Conversion.RGB_to_HSV(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max

    local d = max - min
    if max == 0 then
        s = 0
    else
        s = d / max
    end

    if max == min then
        h = 0
    else
        if max == r then
            h = (g - b) / d
            if g < b then
                h = h + 6
            end
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, v
end

function Conversion.Time_to_Ticks(time)
    return math.floor(0.5 + time / globals.TickInterval())
end

function Conversion.Ticks_to_Time(ticks)
    return ticks * globals.TickInterval()
end

return Conversion
