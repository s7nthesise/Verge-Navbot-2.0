local Logger = {
    Name = "",
    Level = 1
}
Logger.__index = Logger
setmetatable(Logger, Logger)

function Logger.new(name)
    local self = setmetatable({}, Logger)
    self.Name = name
    self.Level = 1

    return self
end

local logModes = {
    ["Debug"] = { Color = { 165, 175, 190 }, Level = 0 },
    ["Info"] = { Color = { 15, 185, 180 }, Level = 1 },
    ["Warn"] = { Color = { 225, 175, 45 }, Level = 2 },
    ["Error"] = { Color = { 230, 65, 25 }, Level = 3 }
}

for mode, data in pairs(logModes) do
    rawset(Logger, mode, function(self, ...)
        if data.Level < self.Level then return end

        local msg = string.format(...)

        local r, g, b = table.unpack(data.Color)
        local name = self.Name
        local time = os.date("%H:%M:%S")

        local logMsg = string.format("[%-6s%s] %s: %s", mode, time, name, msg)
        printc(r, g, b, 255, logMsg)
    end)
end

return Logger
