local Helpers = require("lnxLib/TF2/Helpers")

local WEntity = {
    Entity = nil
}
WEntity.__index = WEntity
setmetatable(WEntity, {
    __index = function(self, key, ...)
        return function(t, ...)
            local entity = rawget(t, "Entity")
            return entity[key](entity, ...)
        end
    end
})

function WEntity.FromEntity(entity)
    assert(entity, "WEntity.FromEntity: entity is nil")

    local self = setmetatable({}, WEntity)
    self:SetEntity(entity)

    return self
end

function WEntity:SetEntity(entity)
    self.Entity = entity
end

function WEntity:Unwrap()
    return self.Entity
end

function WEntity:Equals(other)
    return self:GetIndex() == other:GetIndex()
end

function WEntity:DistTo(other)
    return (other:GetAbsOrigin() - self:GetAbsOrigin()):Length()
end

function WEntity:GetSimulationTime()
    return self:GetPropFloat("m_flSimulationTime")
end

function WEntity:Extrapolate(t)
    return self:GetAbsOrigin() + self:EstimateAbsVelocity() * t
end

function WEntity:IsVisible(fromEntity)
    return Helpers.VisPos(self, fromEntity:GetAbsOrigin(), self:GetAbsOrigin())
end

return WEntity
