local Navigation = {}

local Common = require("navbot.Common")
local G = require("navbot.Utils.Globals")
local AStar = require("navbot.Utils.A-Star")
local WorkManager = require("navbot.WorkManager")

assert(G, "G is nil")

local Log = Common.Log
local Lib = Common.Lib
assert(Lib, "Lib is nil")

function Navigation.ClearPath()
    G.Navigation.path = {}
end

function Navigation.ResetTickTimer()
    G.Navigation.currentNodeTicks = 0
    G.Navigation.stillTicks = 0
    G.Navigation.stillStartPos = nil
end

function Navigation.FindPath(startNode, goalNode)
    -- re-path every ~30 ticks
    if WorkManager.attemptWork(30, "Pathfinding") then
        Log:Info("Generating new path from node %d to node %d", startNode.id, goalNode.id)
        Navigation.ClearPath()
        Navigation.ResetTickTimer()

        if not startNode or not startNode.pos then
            Log:Warn("Navigation.FindPath: startNode or startNode.pos is nil")
            return false
        end

        if not goalNode or not goalNode.pos then
            Log:Warn("Navigation.FindPath: goalNode or goalNode.pos is nil")
            return false
        end

        -- strict A* first, then lenient, then partial path to the closest reachable node
        local blockedEdges = G.Navigation.blockedEdges or {}
        local blockedNodes = G.Navigation.blockedNodes or {}
        local function reachesGoal(p)
            return p and p[1] and p[1].id == goalNode.id
        end
        local strictP = AStar.Path(startNode, goalNode, G.Navigation.nodes, true, blockedEdges, blockedNodes)
        local path
        if reachesGoal(strictP) then
            path = strictP
        else
            local lenientP = AStar.Path(startNode, goalNode, G.Navigation.nodes, false, blockedEdges, blockedNodes)
            if reachesGoal(lenientP) then
                path = lenientP
            elseif lenientP then
                path = lenientP
            elseif strictP then
                path = strictP
            end
        end
        G.Navigation.path = path

        if not G.Navigation.path or #G.Navigation.path == 0 then
            -- don't clear a healthy blacklist; clear only if over-fragmented
            local blockedCount = 0
            for _ in pairs(G.Navigation.blockedNodes or {}) do blockedCount = blockedCount + 1 end
            if blockedCount > 60 then
                G.Navigation.blockedNodes = {}
                G.Navigation.blockedEdges = {}
                Log:Warn("No path — blacklist over-fragmented (%d nodes), clearing to recover.", blockedCount)
            else
                Log:Warn("No path to %d avoiding blocked nodes — staying clear of the blacklist.", goalNode.id)
            end
            return false
        else
            Log:Info("Path found from %d to %d with %d nodes", startNode.id, goalNode.id, #G.Navigation.path)
        end

        if G.Navigation.path and #G.Navigation.path > 0 then
            G.Navigation.currentNodeinPath = #G.Navigation.path
            G.Navigation.currentNode = G.Navigation.path[G.Navigation.currentNodeinPath]
            G.Navigation.currentNodePos = G.Navigation.currentNode.pos
            Log:Info("Path found.")
        else
            Log:Warn("No path found.")
        end

        return true
    end
end

local function removeNodesAfter(path, targetIndex)
    for i = #path, targetIndex + 1, -1 do
        table.remove(path)
    end
end

function Navigation.SkipToNode(nodeIndexFromStart)
    Navigation.ResetTickTimer()

    if G.Navigation.path and #G.Navigation.path > 0 then
        local targetIndex = math.max(1, math.min(#G.Navigation.path, nodeIndexFromStart))

        G.Navigation.currentNode = G.Navigation.path[targetIndex]
        G.Navigation.currentNodePos = G.Navigation.currentNode.pos

        removeNodesAfter(G.Navigation.path, targetIndex)
        G.Navigation.currentNodeIndex = targetIndex
    else
        G.Navigation.currentNode = nil
        G.Navigation.currentNodePos = nil
    end
end

function Navigation.MoveToNextNode()
    Navigation.ResetTickTimer()
    if G.Navigation.path and #G.Navigation.path > 0 then
        removeNodesAfter(G.Navigation.path, #G.Navigation.path - 1)
        G.Navigation.currentNodeIndex = #G.Navigation.path

        if #G.Navigation.path > 0 then
            G.Navigation.currentNode = G.Navigation.path[#G.Navigation.path]
            G.Navigation.currentNodePos = G.Navigation.currentNode.pos
        else
            G.Navigation.currentNode = nil
            G.Navigation.currentNodePos = nil
        end
    else
        G.Navigation.currentNode = nil
        G.Navigation.currentNodePos = nil
    end
end

return Navigation
