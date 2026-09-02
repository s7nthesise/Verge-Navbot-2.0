local KeyValues = {}

local function SerializeKV(name, data, indent)
    local bodyData = {}

    for key, value in pairs(data) do
        if type(value) == "table" then
            table.insert(bodyData, SerializeKV(key, value, indent .. "\t"))
        else
            table.insert(bodyData, string.format("\t%s\"%s\"\t\"%s\"", indent, key, value))
        end
    end

    local body = table.concat(bodyData, "\n")
    return string.format("%s\"%s\"\n%s{\n%s\n%s}", indent, name, indent, body, indent)
end

local function DeserializeKV(data)
    local result = {}

    for key, value in data:gmatch('"(.-)"%s*"(.-)"') do
        result[key] = value
    end

    return result
end

function KeyValues.Serialize(name, data)
    data = data or {}

    return SerializeKV(name, data, "")
end

function KeyValues.Deserialize(data)
    local name, content = data:match('"(.-)"%s*{([^}]-)}')
    return name, DeserializeKV(content)
end

return KeyValues
