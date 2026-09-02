local Input = {}

local KeyNames = {
    [KEY_SEMICOLON] = "SEMICOLON",
    [KEY_APOSTROPHE] = "APOSTROPHE",
    [KEY_BACKQUOTE] = "BACKQUOTE",
    [KEY_COMMA] = "COMMA",
    [KEY_PERIOD] = "PERIOD",
    [KEY_SLASH] = "SLASH",
    [KEY_BACKSLASH] = "BACKSLASH",
    [KEY_MINUS] = "MINUS",
    [KEY_EQUAL] = "EQUAL",
    [KEY_ENTER] = "ENTER",
    [KEY_SPACE] = "SPACE",
    [KEY_BACKSPACE] = "BACKSPACE",
    [KEY_TAB] = "TAB",
    [KEY_CAPSLOCK] = "CAPSLOCK",
    [KEY_NUMLOCK] = "NUMLOCK",
    [KEY_ESCAPE] = "ESCAPE",
    [KEY_SCROLLLOCK] = "SCROLLLOCK",
    [KEY_INSERT] = "INSERT",
    [KEY_DELETE] = "DELETE",
    [KEY_HOME] = "HOME",
    [KEY_END] = "END",
    [KEY_PAGEUP] = "PAGEUP",
    [KEY_PAGEDOWN] = "PAGEDOWN",
    [KEY_BREAK] = "BREAK",
    [KEY_LSHIFT] = "LSHIFT",
    [KEY_RSHIFT] = "RSHIFT",
    [KEY_LALT] = "LALT",
    [KEY_RALT] = "RALT",
    [KEY_LCONTROL] = "LCONTROL",
    [KEY_RCONTROL] = "RCONTROL",
    [KEY_UP] = "UP",
    [KEY_LEFT] = "LEFT",
    [KEY_DOWN] = "DOWN",
    [KEY_RIGHT] = "RIGHT",
    [MOUSE_LEFT] = "LMB",
    [MOUSE_RIGHT] = "RMB",
    [MOUSE_MIDDLE] = "MMB",
    [MOUSE_4] = "MOUSE4",
    [MOUSE_5] = "MOUSE5",
    [MOUSE_WHEEL_UP] = "MWHEELUP",
    [MOUSE_WHEEL_DOWN] = "MWHEELDOWN",
}

local KeyValues = {
    [KEY_LBRACKET] = "[",
    [KEY_RBRACKET] = "]",
    [KEY_SEMICOLON] = ";",
    [KEY_APOSTROPHE] = "'",
    [KEY_BACKQUOTE] = "`",
    [KEY_COMMA] = ",",
    [KEY_PERIOD] = ".",
    [KEY_SLASH] = "/",
    [KEY_BACKSLASH] = "\\",
    [KEY_MINUS] = "-",
    [KEY_EQUAL] = "=",
    [KEY_SPACE] = " ",
}

local function D(x) return x, x end
for i = 1, 10 do KeyNames[i], KeyValues[i] = D(tostring(i - 1)) end
for i = 11, 36 do KeyNames[i], KeyValues[i] = D(string.char(i + 54)) end
for i = 37, 46 do KeyNames[i], KeyValues[i] = "KP_" .. (i - 37), tostring(i - 37) end
for i = 92, 103 do KeyNames[i] = "F" .. (i - 91) end

function Input.GetKeyName(key)
    return KeyNames[key]
end

function Input.KeyToChar(key)
    return KeyValues[key]
end

function Input.CharToKey(char)
    return table.find(KeyValues, string.upper(char))
end

function Input.GetPressedKey()
    for i = KEY_FIRST, KEY_LAST do
        if input.IsButtonDown(i) then return i end
    end

    return nil
end

function Input.GetPressedKeys()
    local keys = {}
    for i = KEY_FIRST, KEY_LAST do
        if input.IsButtonDown(i) then table.insert(keys, i) end
    end

    return keys
end

function Input.MouseInBounds(x1, y1, x2, y2)
    local mx, my = table.unpack(input.GetMousePos())
    return mx >= x1 and mx <= x2 and my >= y1 and my <= y2
end

return Input
