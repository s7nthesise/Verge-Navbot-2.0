local Utils = {
    Conversion = require("lnxLib/Utils/Conversion"),
    FileSystem = require("lnxLib/Utils/FileSystem"),
    Input = require("lnxLib/Utils/Input"),
    KeyHelper = require("lnxLib/Utils/KeyHelper"),
    KeyValues = require("lnxLib/Utils/KeyValues"),
    Logger = require("lnxLib/Utils/Logger"),
    Math = require("lnxLib/Utils/Math"),
    Timer = require("lnxLib/Utils/Timer"),
    Config = require("lnxLib/Utils/Config"),
    Commands = require("lnxLib/Utils/Commands")
}

function Utils.Sanitize(str)
    str = string.gsub(str, "[%p%c]", "")
    str = string.gsub(str, '"', "'")
    return str
end

function Utils.Rainbow(offset)
    local r = math.floor(math.sin(offset + 0) * 127 + 128)
    local g = math.floor(math.sin(offset + 2) * 127 + 128)
    local b = math.floor(math.sin(offset + 4) * 127 + 128)
    return r, g, b
end

function Utils.UnloadPackages(libName)
    local unloadCount = 0
    for name, _ in pairs(package.loaded) do
        if string.find(name, libName) then
            print(string.format("Unloading package '%s'...", name))
            package.loaded[name] = nil
            unloadCount = unloadCount + 1
        end
    end

    warn(string.format("All packages of '%s' have been unloaded!", libName))
    return unloadCount
end

return Utils
