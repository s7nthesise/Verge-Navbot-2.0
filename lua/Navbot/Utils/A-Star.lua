-- Based on Luafinding (github.com/GlorifiedPig/Luafinding)

local Heap = require("navbot.Utils.Heap")

local AStar = {}

local function HeuristicCostEstimate(nodeA, nodeB)
    return (nodeB.pos - nodeA.pos):Length()
end

local function ReconstructPath(current, previous)
    local path = { current }
    while previous[current.id] do
        current = previous[current.id]
        table.insert(path, current)
    end
    return path
end

local function isFlat(node)
    local z_nw = node.corners.nw.z
    local z_se = node.corners.se.z
    return math.abs(z_nw - z_se) <= 18
end

local MAX_HEIGHT_DIFFERENCE_UP = 72
-- allow deep drops; downward edges are real drops
local MAX_HEIGHT_DIFFERENCE_DOWN = 1500
local TOLERANCE = 18
local function isvalid(node, connode)


    local nodeIsFlat = isFlat(node)
    local conNodeIsFlat = isFlat(connode)

    if nodeIsFlat and conNodeIsFlat then
        local heightDifference = connode.pos.z - node.pos.z
        if heightDifference > 0 then
            return heightDifference <= MAX_HEIGHT_DIFFERENCE_UP
        else
            return math.abs(heightDifference) <= MAX_HEIGHT_DIFFERENCE_DOWN
        end
    else
        local node_corners_z = {node.corners.nw.z, node.corners.se.z}
        local connode_corners_z = {connode.corners.nw.z, connode.corners.se.z}

        local found_match = false
        for _, node_z in ipairs(node_corners_z) do
            for _, connode_z in ipairs(connode_corners_z) do
                if math.abs(node_z - connode_z) <= TOLERANCE then
                    found_match = true
                    break
                end
            end
            if found_match then
                break
            end
        end

        if found_match then
            return true
        else
            local heightDifference = connode.pos.z - node.pos.z
            if heightDifference > 0 then
                return heightDifference <= MAX_HEIGHT_DIFFERENCE_UP
            else
                return math.abs(heightDifference) <= MAX_HEIGHT_DIFFERENCE_DOWN
            end
        end
    end
end



local function GetAdjacentNodes(node, nodes, bStrict, blockedEdges, blockedNodes)
    local adjacentNodes = {}

    if not node or not node.c then
        print("Error: Node or its connections table (c) is missing.")
        return adjacentNodes
    end

    for dir, conDir in ipairs(node.c) do
        if dir > 27 then break end

        if conDir and conDir.connections then
            -- numeric loop: skips nil holes ipairs would stop at
            for i = 1, #conDir.connections do
                local conId = conDir.connections[i]
                -- skip blocked edges/nodes so re-pathing takes a different route
                local edgeKey = node.id .. "::" .. conId
                if not (blockedEdges and blockedEdges[edgeKey]) and not (blockedNodes and blockedNodes[conId]) then
                    local conNode = nodes[conId]
                    if conNode and (not bStrict or isvalid(node, conNode)) then
                        table.insert(adjacentNodes, conNode)
                    end
                end
            end
        else
            print(string.format("Warning: No connections for direction %d of node %d.", dir, node.id))
        end
    end

    return adjacentNodes
end


function AStar.Path(startNode, goalNode, nodes, bStrict, blockedEdges, blockedNodes)
    local openSet = Heap.new()
    local closedSet = {}
    local gScore = {}
    local fScore = {}
    local previous = {}
    local closestNode, closestH = nil, math.huge

    gScore[startNode.id] = 0
    fScore[startNode.id] = HeuristicCostEstimate(startNode, goalNode)

    openSet.Compare = function(a, b) return fScore[a.id] < fScore[b.id] end
    openSet:push(startNode)

    while not openSet:empty() do
        local current = openSet:pop()

        if not closedSet[current.id] then
            if current.id == goalNode.id then
                openSet:clear()
                return ReconstructPath(current, previous)
            end

            closedSet[current.id] = true
            local h = HeuristicCostEstimate(current, goalNode)
            if current.id ~= startNode.id and h < closestH then
                closestH = h
                closestNode = current
            end

            local adjacentNodes = GetAdjacentNodes(current, nodes, bStrict, blockedEdges, blockedNodes)
            for _, neighbor in ipairs(adjacentNodes) do
                if not closedSet[neighbor.id] then
                    local tentativeGScore = gScore[current.id] + HeuristicCostEstimate(current, neighbor)

                    if not gScore[neighbor.id] or tentativeGScore < gScore[neighbor.id] then
                        gScore[neighbor.id] = tentativeGScore
                        fScore[neighbor.id] = tentativeGScore + HeuristicCostEstimate(neighbor, goalNode)
                        previous[neighbor.id] = current
                        openSet:push(neighbor)
                    end
                end
            end
        end
    end

    -- unreachable: return the closest reachable node
    if closestNode then
        return ReconstructPath(closestNode, previous)
    end
    return nil
end

return AStar
