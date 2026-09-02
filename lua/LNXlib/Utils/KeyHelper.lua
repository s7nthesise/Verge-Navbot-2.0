local KeyHelper = {
    Key = 0,
    _LastState = false
}
KeyHelper.__index = KeyHelper
setmetatable(KeyHelper, KeyHelper)

function KeyHelper.new(key)
    local self = setmetatable({}, KeyHelper)
    self.Key = key
    self._LastState = false

    return self
end

function KeyHelper:Down()
    local isDown = input.IsButtonDown(self.Key)
    return isDown
end

function KeyHelper:Pressed()
    local shouldCheck = self._LastState == false
    self._LastState = self:Down()
    return self._LastState and shouldCheck
end

function KeyHelper:Released()
    local shouldCheck = self._LastState == true
    self._LastState = self:Down()
    return self._LastState == false and shouldCheck
end

return KeyHelper
