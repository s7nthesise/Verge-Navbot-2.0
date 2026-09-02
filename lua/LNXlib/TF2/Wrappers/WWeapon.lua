local WEntity = require("lnxLib/TF2/Wrappers/WEntity")

local Math = require("lnxLib/Utils/Math")

local WWeapon = {}
WWeapon.__index = WWeapon
setmetatable(WWeapon, WEntity)

local projInfo = {
    [414] = { 1540, 0 }, -- Liberty Launcher
    [308] = { 1513.3, 0.4 }, -- Loch n' Load
    [595] = { 3000, 0.2 }, -- Manmelter
}

local projInfoID = {
    [E_WeaponBaseID.ROCKETLAUNCHER] = { 1100, 0 },
    [E_WeaponBaseID.DIRECTHIT] = { 1980, 0 },
    [E_WeaponBaseID.GRENADELAUNCHER] = { 1216.6, 0.5 },
    [E_WeaponBaseID.PIPEBOMBLAUNCHER] = { 1100, 0 },
    [E_WeaponBaseID.SYRINGEGUN_MEDIC] = { 1000, 0.2 },
    [E_WeaponBaseID.FLAMETHROWER] = { 1000, 0.2, 0.33 },
    [E_WeaponBaseID.FLAREGUN] = { 2000, 0.3 },
    [E_WeaponBaseID.CLEAVER] = { 3000, 0.2 }, -- Flying Guillotine
    [E_WeaponBaseID.CROSSBOW] = { 2400, 0.2 }, -- Crusader's Crossbow
    [E_WeaponBaseID.SHOTGUN_BUILDING_RESCUE] = { 2400, 0.2 }, -- Rescue Ranger
    [E_WeaponBaseID.CANNON] = { 1453.9, 0.4 }, -- Loose Cannon
}

function WWeapon.FromEntity(entity)
    assert(entity, "WWeapon.FromEntity: entity is nil")
    assert(entity:IsWeapon(), "WWeapon.FromEntity: entity is not a weapon")

    local self = setmetatable({}, WWeapon)
    self:SetEntity(entity)

    return self
end

function WWeapon:GetOwner()
    return self:GetPropEntity("m_hOwner")
end

function WWeapon:GetDefIndex()
    return self:GetPropInt("m_iItemDefinitionIndex")
end

function WWeapon:GetNextPrimaryAttack()
    return self:GetPropFloat("m_flNextPrimaryAttack")
end

function WWeapon:GetChargeBeginTime()
    return self:GetPropFloat("m_flChargeBeginTime")
end

function WWeapon:GetChargedDamage()
    return self:GetPropFloat("m_flChargedDamage")
end

function WWeapon:GetProjectileInfo()
    local id = self:GetWeaponID()
    local defIndex = self:GetDefIndex()

    if id == E_WeaponBaseID.COMPOUND_BOW then
        local charge = globals.CurTime() - self:GetChargeBeginTime()
        return { Math.RemapValClamped(charge, 0.0, 1.0, 1800, 2600),
                 Math.RemapValClamped(charge, 0.0, 1.0, 0.5, 0.1) }
    elseif id == E_WeaponBaseID.PIPEBOMBLAUNCHER then
        local charge = globals.CurTime() - self:GetChargeBeginTime()
        return { Math.RemapValClamped(charge, 0.0, 4.0, 900, 2400),
                 Math.RemapValClamped(charge, 0.0, 4.0, 0.5, 0.0) }
    end

    return projInfo[defIndex] or projInfoID[id]
end

return WWeapon
