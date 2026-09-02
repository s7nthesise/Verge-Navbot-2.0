-- Author: LNX (github.com/lnx00)

local BinPack = {}

function BinPack.pack(...)
    local args = { ... }
    local result = {}

    for _, arg in ipairs(args) do
        table.insert(result, string.len(arg) .. "\0")
        table.insert(result, arg)
    end

    return table.concat(result)
end

function BinPack.unpack(data)
    local result = {}
    local offset = 1

    while offset <= string.len(data) do
        local dataOffset = string.find(data, "\0", offset, true)
        if not dataOffset then return nil end
        local length = tonumber(string.sub(data, offset, dataOffset - 1))
        if not length then return nil end
        local value = string.sub(data, dataOffset + 1, dataOffset + length)

        offset = dataOffset + length + 1
        table.insert(result, value)
    end

    return result
end

function BinPack.save(path, ...)
    local data = BinPack.pack(...)
    if not data then return false end
    return filesystem.WriteFile(path, data)
end

function BinPack.load(path)
    local data = filesystem.ReadFile(path)
    if not data then return nil end
    return BinPack.unpack(data)
end

function BinPack.packFiles(outPath, ...)
    local paths = { ... }
    local files = {}

    for _, path in ipairs(paths) do
        local data = filesystem.ReadFile(path)
        if not data then return false end
        table.insert(files, data)
    end

    return BinPack.save(outPath, table.unpack(files))
end

return BinPack
