local Prediction = {}

local fFalse = function () return false end

function Prediction.Player(player, t, d, shouldHitEntity)
    local gravity = client.GetConVar("sv_gravity")
    local stepSize = player:GetPropFloat("m_flStepSize")
    if not gravity or not stepSize then return nil end

    local vUp = Vector3(0, 0, 1)
    local vHitbox = { Vector3(-20, -20, 0), Vector3(20, 20, 80) }
    local vStep = Vector3(0, 0, stepSize)
    shouldHitEntity = shouldHitEntity or fFalse

    local _out = {
        pos = { [0] = player:GetAbsOrigin() },
        vel = { [0] = player:EstimateAbsVelocity() },
        onGround = { [0] = player:IsOnGround() }
    }

    for i = 1, t do
        local lastP, lastV, lastG = _out.pos[i - 1], _out.vel[i - 1], _out.onGround[i - 1]

        local pos = lastP + lastV * globals.TickInterval()
        local vel = lastV
        local onGround = lastG

        if d then
            local ang = vel:Angles()
            ang.y = ang.y + d
            vel = ang:Forward() * vel:Length()
        end

        local wallTrace = engine.TraceHull(lastP + vStep, pos + vStep, vHitbox[1], vHitbox[2], MASK_PLAYERSOLID, shouldHitEntity)
        if wallTrace.fraction < 1 then
            local normal = wallTrace.plane
            local angle = math.deg(math.acos(normal:Dot(vUp)))

            if angle > 55 then
                local dot = vel:Dot(normal)
                vel = vel - normal * dot
            end

            pos.x, pos.y = wallTrace.endpos.x, wallTrace.endpos.y
        end

        local downStep = vStep
        if not onGround then downStep = Vector3() end

        local groundTrace = engine.TraceHull(pos + vStep, pos - downStep, vHitbox[1], vHitbox[2], MASK_PLAYERSOLID, shouldHitEntity)
        if groundTrace.fraction < 1 then
            local normal = groundTrace.plane
            local angle = math.deg(math.acos(normal:Dot(vUp)))

            if angle < 45 then
                pos = groundTrace.endpos
                onGround = true
            elseif angle < 55 then
                vel.x, vel.y, vel.z = 0, 0, 0
                onGround = false
            else
                local dot = vel:Dot(normal)
                vel = vel - normal * dot
                onGround = true
            end

            if onGround then vel.z = 0 end
        else
            onGround = false
        end

        if not onGround then
            vel.z = vel.z - gravity * globals.TickInterval()
        end

        _out.pos[i], _out.vel[i], _out.onGround[i] = pos, vel, onGround
    end

    return _out
end

function Prediction.Projectile(player, speed, gravity, t)
    local shootPos = player:GetEyePos()
    local shootAngles = player:GetEyeAngles()
    local shootDir = shootAngles:Forward()
    local _, sv_gravity = client.GetConVar("sv_gravity")
    gravity = sv_gravity * gravity

    local _out = {
        pos = { [0] = shootPos },
        vel = { [0] = shootDir * speed }
    }

    for i = 1, t do
        local lastP, lastV = _out.pos[i - 1], _out.vel[i - 1]

        local pos = lastP + lastV * globals.TickInterval()
        local vel = lastV

        vel.z = vel.z - gravity * globals.TickInterval()

        _out.pos[i], _out.vel[i] = pos, vel
    end

    return _out
end

return Prediction
