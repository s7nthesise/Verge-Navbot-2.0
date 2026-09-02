local FileSystem = require("lnxLib/Utils/FileSystem")

local Json = require("lnxLib/Libs/dkjson")

local Config = {
    _Name = "",
    _Content = {},
    AutoSave = true,
    AutoLoad = false
}
Config.__index = Config
setmetatable(Config, Config)

local ConfigExtension = ".cfg"
local ConfigFolder = FileSystem.GetWorkDir() .. "/Configs/"

function Config.new(name)
    local self = setmetatable({}, Config)
    self._Name = name
    self._Content = {}
    self.AutoSave = true
    self.AutoLoad = false

    self:Load()

    return self
end

function Config:GetPath()
    if not FileSystem.Exists(ConfigFolder) then
        filesystem.CreateDirectory(ConfigFolder)
    end

    return ConfigFolder .. self._Name .. ConfigExtension
end

function Config:Load()
    local configPath = self:GetPath()
    if not FileSystem.Exists(configPath) then return false end

    local content = FileSystem.Read(self:GetPath())
    self._Content = Json.decode(content, 1, nil)
    return self._Content ~= nil
end

function Config:Delete()
    local configPath = self:GetPath()
    if not FileSystem.Exists(configPath) then return false end

    self._Content = {}
    return FileSystem.Delete(configPath)
end

function Config:Save()
    local content = Json.encode(self._Content, { indent = true })
    return FileSystem.Write(self:GetPath(), content)
end

function Config:SetValue(key, value)
    if self.AutoLoad then self:Load() end
    self._Content[key] = value
    if self.AutoSave then self:Save() end
end

function Config:GetValue(key, default)
    if self.AutoLoad then self:Load() end
    local value = self._Content[key]
    if value == nil then return default end

    return value
end

return Config
