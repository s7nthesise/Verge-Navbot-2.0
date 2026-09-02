local Commands = {
    _Commands = {}
}

function Commands.Register(name, callback)
    if Commands._Commands[name] ~= nil then
        warn(string.format("Command '%s' already exists and will be overwritten!", name))
    end
    Commands._Commands[name] = callback
end

function Commands.Unregister(name)
    Commands._Commands[name] = nil
end

local function OnStringCmd(stringCmd)
    local args = Deque.new(string.split(stringCmd:Get(), " "))
    local cmd = args:popFront()

    if Commands._Commands[cmd] then
        stringCmd:Set("")
        Commands._Commands[cmd](args)
    end
end

Internal.RegisterCallback("SendStringCmd", OnStringCmd, "Utils", "Commands")

return Commands
