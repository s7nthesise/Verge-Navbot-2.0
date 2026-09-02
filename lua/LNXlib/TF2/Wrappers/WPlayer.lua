local WEntity = require("lnxLib/TF2/Wrappers/WEntity")

local WWeapon = require("lnxLib/TF2/Wrappers/WWeapon")

local WPlayer = {}
WPlayer.__index = WPlayer
setmetatable(WPlayer, WEntity)

function WPlayer.FromEntity(entity)
    assert(entity, "WPlayer.FromEntity: entity is nil")
    assert(entity:IsPlayer(), "WPlayer.FromEntity: entity is not a player")

    local self = setmetatable({}, WPlayer)
    self:SetEntity(entity)

    return self
end

function WPlayer.GetLocal()
    local lp = entities.GetLocalPlayer()
    return lp ~= nil and WPlayer.FromEntity(lp) or nil
end

function WPlayer:IsOnGround()
    local pFlags = self:GetPropInt("m_fFlags")
    return (pFlags & FL_ONGROUND) == 1
end

function WPlayer:GetActiveWeapon()
    local wpn = self:GetPropEntity("m_hActiveWeapon")
    return wpn ~= nil and WWeapon.FromEntity(wpn) or nil
end

function WPlayer:GetObserverMode()
    return self:GetPropInt("m_iObserverMode")
end

function WPlayer:GetObserverTarget()
    return WPlayer.FromEntity(self:GetPropEntity("m_hObserverTarget"))
end

function WPlayer:GetNextAttack()
    return self:GetPropFloat("m_flNextAttack")
end

function WPlayer:GetHitboxPos(hitboxID)
    local hitbox = self:GetHitboxes()[hitboxID]
    if not hitbox then return nil end

    return (hitbox[1] + hitbox[2]) * 0.5
end

function WPlayer:GetViewOffset()
    return self:GetPropVector("localdata", "m_vecViewOffset[0]")
end

function WPlayer:GetEyePos()
    return self:GetAbsOrigin() + self:GetViewOffset()
end

function WPlayer:GetEyeAngles()
    local angles = self:GetPropVector("tfnonlocaldata", "m_angEyeAngles[0]")
    return EulerAngles(angles.x, angles.y, angles.z)
end

function WPlayer:GetViewPos()
    local eyePos = self:GetEyePos()
    local targetPos = eyePos + self:GetEyeAngles():Forward() * 8192
    local trace = engine.TraceLine(eyePos, targetPos, MASK_SHOT)

    return trace.endpos
end

return WPlayer
