local Textures = {}

local byteMap = {}
for i = 0, 255 do byteMap[i] = string.char(i) end

local function UnpackColor(color)
    local r, g, b, a = table.unpack(color)
    a = a or 255
    return r, g, b, a
end

local function UnpackSize(size)
    return size[1] or 256, size[2] or 256
end

local function CreateTexture(width, height, data)
    local binaryData = table.concat(data)
    return draw.CreateTextureRGBA(binaryData, width, height)
end

-- PERFORMANCE INTENSIVE
function Textures.LinearGradient(startColor, endColor, size)
    local sR, sG, sB, sA = UnpackColor(startColor)
    local eR, eG, eB, eA = UnpackColor(endColor)
    local w, h = UnpackSize(size)

    local dataSize = w * h * 4
    local data, bm = {}, byteMap

    local i = 1
    while i < dataSize do
        local idx = (i / 4)
        local x, y = idx % w, idx // w

        data[i] = bm[sR + (eR - sR) * x // w]
        data[i + 1] = bm[sG + (eG - sG) * y // h]
        data[i + 2] = bm[sB + (eB - sB) * x // w]
        data[i + 3] = bm[sA + (eA - sA) * y // h]

        i = i + 4
    end

    return CreateTexture(w, h, data)
end

-- PERFORMANCE INTENSIVE
function Textures.Circle(radius, color)
    local r, g, b, a = UnpackColor(color)

    local diameter = radius * 2
    local dataSize = diameter * diameter * 4
    local data, bm = {}, byteMap

    local i = 1
    while i < dataSize do
        local idx = (i / 4)
        local x, y = idx % diameter, idx // diameter
        local dx, dy = x - radius, y - radius
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist <= radius then
            data[i] = bm[r]
            data[i + 1] = bm[g]
            data[i + 2] = bm[b]
            data[i + 3] = bm[a]
        else
            data[i] = bm[0]
            data[i + 1] = bm[0]
            data[i + 2] = bm[0]
            data[i + 3] = bm[0]
        end

        i = i + 4
    end

    return CreateTexture(diameter, diameter, data)
end

return Textures
