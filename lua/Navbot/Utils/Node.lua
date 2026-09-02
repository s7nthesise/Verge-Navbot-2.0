local Node = {}

local G = require("navbot.Utils.Globals")


function Node.SetNodes(nodes)
    G.Navigation.nodes = nodes
    Node._invalidateClosestCache()
end

-- drop the closest-node cache when the node set changes (nav ids can collide across maps)
function Node._invalidateClosestCache()
    G.Navigation._closestTick = nil
    G.Navigation._closestNode = nil
    G.Navigation._closestPos = nil
end

function Node.GetNodes()
    return G.Navigation.nodes
end

function Node.currentNodePos()
    return G.Navigation.currentNodePos
end

function Node.create(area)
    local cX = (area.north_west.x + area.south_east.x) / 2
    local cY = (area.north_west.y + area.south_east.y) / 2
    local cZ = (area.north_west.z + area.south_east.z) / 2

    return {
        pos = Vector3(cX, cY, cZ),
        id = area.id,
        c = area.connections or {},
        corners = {
            nw = area.north_west,
            se = area.south_east,
            ne_z = area.north_east_z,
            sw_z = area.south_west_z,
        },
    }
end

-- bilinear floor height over the 4 corner heights
function Node.GetZ(node, x, y)
    local c = node.corners
    local nw, se = c.nw, c.se
    local minX, maxX = math.min(nw.x, se.x), math.max(nw.x, se.x)
    local minY, maxY = math.min(nw.y, se.y), math.max(nw.y, se.y)
    local u = maxX > minX and (x - minX) / (maxX - minX) or 0
    local v = maxY > minY and (y - minY) / (maxY - minY) or 0
    u = math.max(0, math.min(1, u))
    v = math.max(0, math.min(1, v))
    local neZ, swZ = c.ne_z or nw.z, c.sw_z or se.z
    local northZ = nw.z + u * (neZ - nw.z)
    local southZ = swZ + u * (se.z - swZ)
    return northZ + v * (southZ - northZ)
end

-- closest reachable point on the 2D footprint; z floored to the surface
function Node.ClosestPointOnArea(node, pos)
    local c = node.corners
    local nw, se = c.nw, c.se
    local minX, maxX = math.min(nw.x, se.x), math.max(nw.x, se.x)
    local minY, maxY = math.min(nw.y, se.y), math.max(nw.y, se.y)
    local x = math.max(minX, math.min(maxX, pos.x))
    local y = math.max(minY, math.min(maxY, pos.y))
    return Vector3(x, y, Node.GetZ(node, x, y))
end

function Node.GetClosest(pos)
    -- prefer nodes with connections; skip blocked nodes; cache ~10 ticks / <100u
    local nav = G.Navigation
    if nav._closestTick and (globals.TickCount() - nav._closestTick) < 10 then
        if nav._closestPos and (pos - nav._closestPos):Length() < 100 then
            local cached = nav._closestNode
            if cached and not (nav.blockedNodes or {})[cached.id] then
                return cached
            end
        end
    end

    local closestDist = math.huge
    local fallbackDist = math.huge
    local nodes = Node.GetNodes()
    local blocked = nav.blockedNodes or {}
    local closestNode, fallbackNode = nil, nil

    if nodes then
        for _, node in pairs(nodes) do
            if node and node.pos and not blocked[node.id] then
                local dist = (node.pos - pos):Length()
                local conns = 0
                for _, d in pairs(node.c or {}) do conns = conns + #(d.connections or {}) end
                if conns > 0 then
                    if dist < closestDist then
                        closestNode = node
                        closestDist = dist
                    end
                elseif dist < fallbackDist then
                    fallbackNode = node
                    fallbackDist = dist
                end
            end
        end
    end

    local result = closestNode or fallbackNode
    nav._closestTick = globals.TickCount()
    nav._closestPos = pos
    nav._closestNode = result
    return result
end

return Node
