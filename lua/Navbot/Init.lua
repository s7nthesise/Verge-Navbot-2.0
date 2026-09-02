-- required modules run in _G; bridge the per-script API before the first require
_G.callbacks = callbacks
_G.GetScriptName = GetScriptName
_G.LoadScript = LoadScript
_G.UnloadScript = UnloadScript
_G.NAVBOT_SCRIPT_NAME = GetScriptName()

local G = require("navbot.Utils.Globals")
local Common = require("navbot.Common")

require("navbot.Modules.Setup")

local Node = require("navbot.Utils.Node")
local Navigation = require("navbot.Utils.Navigation")
local WorkManager = require("navbot.WorkManager")
local TaskManager = require("navbot.TaskManager")
local BlockedStore = require("navbot.Utils.BlockedStore")

local Lib = Common.Lib
local Log = Common.Log

local Notify, WPlayer = Lib.UI.Notify, Lib.TF2.WPlayer

-- net motion per tick that still counts as moving
local STUCK_MOVE_EPS = 0.5

local function findOwnCart(pLocal)
    local fallback = nil
    for _, entity in pairs(entities.FindByClass("CObjectCartDispenser") or {}) do
        if entity:GetTeamNumber() == pLocal:GetTeamNumber() then
            return entity
        end
        if not fallback then fallback = entity end
    end
    return fallback
end

local function smoothViewAngles(userCmd, targetAngles)
    local currentAngles = userCmd.viewangles
    local deltaAngles = { x = targetAngles.x - currentAngles.x, y = targetAngles.y - currentAngles.y }
    deltaAngles.y = ((deltaAngles.y + 180) % 360) - 180

    return EulerAngles(
        currentAngles.x + deltaAngles.x * 0.05,
        currentAngles.y + deltaAngles.y * G.Menu.Movement.smoothFactor,
        0
    )
end

local function getViewAnglesToNode(pLocalWrapped, targetPos)
    local eyePos = pLocalWrapped:GetEyePosition()
    if not eyePos then
        Log:Warn("Eye position is nil.")
        return nil
    end
    return Lib.Utils.Math.PositionAngles(eyePos, targetPos)
end

-- face the move target, not the node center (avoids oscillation)
local function handlePathWalkingView(userCmd, targetPos)
    if not (targetPos and G.Menu.Movement.lookatpath) then
        return
    end

    local pLocalWrapped = WPlayer.GetLocal()
    if not pLocalWrapped then
        Log:Warn("Failed to wrap local player.")
        return
    end

    local angles = getViewAnglesToNode(pLocalWrapped, targetPos)
    if not angles then return end

    angles.x = 0
    if G.Menu.Movement.smoothLookAtPath then
        angles = smoothViewAngles(userCmd, angles)
    end
    engine.SetViewAngles(angles)
end

-- advance on a drop only while airborne, or the stuck-check never fires
local function shouldMoveToNextNode(dist2D, verticalDist, LocalOrigin, nodePos)
    local bDropping = nodePos and LocalOrigin and (LocalOrigin.z - nodePos.z > 200)
        and not (G.pLocal.flags & FL_ONGROUND == 1)
    return (dist2D < G.Misc.NodeTouchDistance) and (verticalDist <= G.Misc.NodeTouchHeight or bDropping)
end

-- skip only along a direct nav edge, capped short
local function shouldSkipToNextNode(currentNode, nextNode, LocalOrigin)
    -- require the player to actually be at the current node
    local playerToCurrentDist = (LocalOrigin - currentNode.pos):Length()
    local currentToNextDist = (currentNode.pos - nextNode.pos):Length()
    local playerToNextDist = (LocalOrigin - nextNode.pos):Length()
    return playerToCurrentDist <= G.Misc.NodeTouchDistance * 2
       and playerToNextDist < currentToNextDist
       and currentToNextDist <= 300
       and Common.hasDirectEdge(currentNode, nextNode)
       and Common.straightLineClear(LocalOrigin, nextNode.pos)
end

-- collapse at most one hop toward the goal
local function optimizePath()
    local path = G.Navigation.path
    local target = path[#path]
    if not target then return end
    local origin = G.pLocal.Origin

    for i = #path - 1, 1, -1 do
        local currentNode = path[i]
        if (target.pos - currentNode.pos):Length() <= 750
           and Common.hasDirectEdge(target, currentNode)
           and Common.straightLineClear(origin, currentNode.pos) then
            Navigation.SkipToNode(i)
            return
        end
    end
end


-- jump, then crouch ~0.25s later mid-air (clears ledges a plain jump can't)
local cjState = nil
local cjStart = 0.0

local function attemptJumpIfStuck(userCmd)
    local now = globals.CurTime()
    -- once started, run the sequence to completion
    if not cjState then
        if (G.Navigation.stillTicks or 0) <= 66 then
            return
        end
        cjState = "jump"
        cjStart = now
    end
    if cjState == "jump" then
        userCmd:SetButtons(userCmd.buttons | IN_JUMP)
        if now - cjStart >= 0.25 then
            cjState = "crouch"
            cjStart = now
        end
    elseif cjState == "crouch" then
        userCmd:SetButtons(userCmd.buttons | IN_DUCK)
        if now - cjStart >= 0.75 then
            cjState = nil
        end
    end
end

local function OnCreateMove(userCmd)
    local pLocal = entities.GetLocalPlayer()
    G.pLocal.entity = pLocal

    -- reset navigation on respawn (death->alive or >1000u origin jump)
    -- backup to the Setup.lua spawn/death event hook
    local bAlive = pLocal and pLocal:IsAlive()
    local bRespawned = false
    if G.pLocal.prevAlive ~= nil and bAlive ~= G.pLocal.prevAlive and bAlive then
        bRespawned = true
    end
    local curOrigin = bAlive and pLocal:GetAbsOrigin()
    if bAlive and G.pLocal.prevOrigin and curOrigin then
        if (curOrigin - G.pLocal.prevOrigin):Length() > 1000 then
            bRespawned = true
        end
    end
    G.pLocal.prevAlive = bAlive
    G.pLocal.prevOrigin = curOrigin

    if bRespawned then
        Navigation.ClearPath()
        Navigation.ResetTickTimer()
        G.Navigation.currentNode = nil
        G.Navigation.currentNodePos = nil
        G.Navigation.currentNodeIndex = nil
        Log:Info("Respawned — resetting navigation.")
    end

    if not pLocal or not bAlive then
        Navigation.ClearPath()
        return
    end

    local bRoundActive = not gamerules.IsInSetup() and not gamerules.IsInWaitingForPlayers() and gamerules.GetRoundState() == E_RoundState.ROUND_RUNNING
    if not bRoundActive then
        Navigation.ClearPath()
        G.Navigation.currentNode = nil
        G.Navigation.currentNodePos = nil
        G.Navigation.currentNodeIndex = nil
        return
    end

    local currentTask = TaskManager.GetCurrentTask()
    if not currentTask then
        TaskManager.AddTask("Objective")
        Navigation.ClearPath()
        return
    end

    G.pLocal.flags = pLocal:GetPropInt("m_fFlags") or 0
    G.pLocal.Origin = pLocal:GetAbsOrigin()

    if (userCmd:GetForwardMove() ~= 0 or userCmd:GetSideMove() ~= 0) then
        G.State = G.StateDefinition.ManualBypass
    elseif G.Navigation.path and #G.Navigation.path > 0 then
        G.State = G.StateDefinition.PathWalking
    else
        G.State = G.StateDefinition.Pathfinding
    end

    if G.Navigation.bForceRepath then
        G.Navigation.bForceRepath = false
        G.State = G.StateDefinition.Pathfinding
        Navigation.ClearPath()
    elseif currentTask == "Objective" and G.World.goalPos then
        if WorkManager.attemptWork(30, "goalpos") then
            local cart = findOwnCart(pLocal)
            if cart then G.World.goalPos = cart:GetAbsOrigin() end
        end
        local goalDist = (G.pLocal.Origin - G.World.goalPos):Length()
        if goalDist <= 115 then
            G.Navigation.stillTicks = 0
            G.Navigation.stillStartPos = nil
            if WorkManager.attemptWork(100, "recheck") then
                G.Navigation.bForceRepath = true
            end
            Navigation.ClearPath()
            return
        end
        local tr = engine.TraceLine(G.pLocal.Origin + Vector3(0, 0, 55), G.World.goalPos + Vector3(0, 0, 45), MASK_PLAYERSOLID_BRUSHONLY)
        if tr and tr.fraction >= 1.0 then
            Navigation.ClearPath()
            if G.Menu.Main.Walking then
                handlePathWalkingView(userCmd, G.World.goalPos)
                Common.WalkTo(userCmd, pLocal, G.World.goalPos)
            end
            G.Navigation.stillTicks = 0
            G.Navigation.stillStartPos = nil
            return
        end
    end

    if G.State == G.StateDefinition.PathWalking then

        local LocalOrigin = G.pLocal.Origin
        local lastPos = G.Navigation.lastPos
        G.Navigation.lastPos = LocalOrigin
        if lastPos then
            local d = LocalOrigin - lastPos
            d.z = 0
            local dl = d:Length()
            if dl > 0.5 and dl < 500 then
                G.Navigation.lastMoveDir = d * (1 / dl)
            end
        end

        local path = G.Navigation.path
        local currentNode = G.Navigation.currentNode
        local centerPos = currentNode and currentNode.pos or Node.currentNodePos()
        local nodePos = currentNode and Node.ClosestPointOnArea(currentNode, LocalOrigin) or centerPos
        local dist2D = nodePos and math.sqrt((LocalOrigin.x - nodePos.x)^2 + (LocalOrigin.y - nodePos.y)^2) or 0
        local verticalDist = nodePos and math.abs(LocalOrigin.z - nodePos.z) or 0
        -- nudge the drop point and leave the view free while dropping
        local bDropNudge = false
        if nodePos and LocalOrigin and currentNode
           and nodePos.z < LocalOrigin.z - G.Misc.NodeTouchHeight
           and dist2D < G.Misc.NodeTouchDistance then
            local dir = G.Navigation.lastMoveDir
            if dir then
                bDropNudge = true
                nodePos = Node.ClosestPointOnArea(currentNode, LocalOrigin + dir * 40)
                dist2D = math.sqrt((LocalOrigin.x - nodePos.x)^2 + (LocalOrigin.y - nodePos.y)^2)
                verticalDist = math.abs(LocalOrigin.z - nodePos.z)
            end
        end

        local movePos = nodePos
        if G.Menu.Main.Walking then
            movePos = Common.AvoidSteer(LocalOrigin, nodePos)
        end
        if not bDropNudge then
            handlePathWalkingView(userCmd, movePos)
        end
        if G.Menu.Main.Walking then
            Common.WalkTo(userCmd, pLocal, movePos)
        end

        if shouldMoveToNextNode(dist2D, verticalDist, LocalOrigin, nodePos) then
            if currentTask == "Objective" and #G.Navigation.path <= 1
               and G.World.goalPos and (G.pLocal.Origin - G.World.goalPos):Length() <= 150 then
                G.Navigation.stillTicks = 0
                G.Navigation.stillStartPos = nil
                return
            end
            Navigation.MoveToNextNode()
            if not G.Navigation.path or #G.Navigation.path == 0 then
                if currentTask == "Objective" then
                    G.Navigation.stillTicks = 0
                    G.Navigation.stillStartPos = nil
                    return
                end
                Navigation.ClearPath()
                Log:Info("Reached end of path.")
                TaskManager.RemoveTask(currentTask)
                return
            end
        else
            if G.Menu.Main.Skip_Nodes then
                local path = G.Navigation.path
                if path and #path >= 2 then
                    local currentNode = path[#path]
                    local nextNode = path[#path - 1]

                    if currentNode and nextNode and WorkManager.attemptWork(10, "navskip") and shouldSkipToNextNode(currentNode, nextNode, LocalOrigin) then
                        Log:Info("Skipping to next node %d", nextNode.id)
                        Navigation.MoveToNextNode()
                    end

                    if G.Menu.Main.Optymise_Path and WorkManager.attemptWork(17, "optymise path") then
                        -- straighten only once the player is at the current node
                        local playerToNode = nodePos and (LocalOrigin - nodePos):Length()
                        if playerToNode and playerToNode <= G.Misc.NodeTouchDistance * 2 then
                            optimizePath()
                        end
                    end
                end
            end
            -- stuck = commanding movement but frozen; displacement-based only
            local bMoving = userCmd:GetForwardMove() ~= 0 or userCmd:GetSideMove() ~= 0
            if bMoving then
                local stillStart = G.Navigation.stillStartPos
                if stillStart then
                    if (LocalOrigin - stillStart):Length() > STUCK_MOVE_EPS then
                        G.Navigation.stillTicks = 0
                        G.Navigation.stillStartPos = LocalOrigin
                    end
                else
                    G.Navigation.stillStartPos = LocalOrigin
                end
                G.Navigation.stillTicks = (G.Navigation.stillTicks or 0) + 1
            else
                G.Navigation.stillTicks = 0
                G.Navigation.stillStartPos = nil
            end
        end

        -- remember the stuck edge/node so re-pathing avoids it
        attemptJumpIfStuck(userCmd)
        if WorkManager.attemptWork(5, "stuckcheck") then
            if (G.Navigation.stillTicks or 0) > 120 then
                local path = G.Navigation.path
                if path and #path >= 2 then
                    local a, b = path[#path], path[#path - 1]
                    G.Navigation.blockedEdges = G.Navigation.blockedEdges or {}
                    G.Navigation.blockedNodes = G.Navigation.blockedNodes or {}
                    G.Navigation.blockedEdges[a.id .. "::" .. b.id] = true
                    G.Navigation.blockedNodes[a.id] = true

                    -- block nearby nodes except the onward route
                    local stuckPos = LocalOrigin
                    local keepIds = {}
                    for i = 1, #path - 1 do keepIds[path[i].id] = true end
                    for _, node in pairs(G.Navigation.nodes or {}) do
                        if node and node.pos and not keepIds[node.id] and not G.Navigation.blockedNodes[node.id] then
                            if (node.pos - stuckPos):Length() <= 200 then
                                G.Navigation.blockedNodes[node.id] = true
                            end
                        end
                    end
                    Log:Warn("Stuck at node %d — blocked node + edge to %d + region (kept route), re-pathing.", a.id, b.id)

                    -- blacklist too big = map over-fragmented; start fresh
                    local blockedCount = 0
                    for _ in pairs(G.Navigation.blockedNodes) do blockedCount = blockedCount + 1 end
                    if blockedCount > 60 then
                        G.Navigation.blockedNodes = {}
                        G.Navigation.blockedEdges = {}
                        Log:Warn("Blacklist exceeded 60 nodes — clearing to avoid over-blocking.")
                    else
                        BlockedStore.Save()
                    end
                else
                    Log:Warn("Stuck — clearing path to re-path.")
                end
                Navigation.ClearPath()
                Navigation.ResetTickTimer()
            end
        end
    elseif G.State == G.StateDefinition.Pathfinding then
        local LocalOrigin = G.pLocal.Origin or Vector3(0, 0, 0)
        local startNode = Node.GetClosest(LocalOrigin)
        if not startNode then
            Log:Warn("Could not find start node.")
            return
        end

        local goalNode = nil
        local mapName = engine.GetMapName():lower()

        local function findPayloadGoal()
            local cart = findOwnCart(pLocal)
            G.World.goalPos = cart and cart:GetAbsOrigin() or nil
            return G.World.goalPos and Node.GetClosest(G.World.goalPos) or nil
        end

        local function findFlagGoal()
            local myItem = pLocal:GetPropInt("m_hItem")
            G.World.flags = entities.FindByClass("CCaptureFlag")
            for _, entity in pairs(G.World.flags or {}) do
                local myTeam = entity:GetTeamNumber() == pLocal:GetTeamNumber()
                if (myItem > 0 and myTeam) or (myItem <= 0 and not myTeam) then
                    return Node.GetClosest(entity:GetAbsOrigin())
                end
            end
        end

        local function findControlPointGoal()
            local myTeam = pLocal:GetTeamNumber()
            local points = objectives and objectives.GetControlPoints(myTeam)
            if not points or #points == 0 then
                if not objectives and WorkManager.attemptWork(200, "cperr") then
                    Log:Warn("CP: objectives API missing — update Verge.dll")
                end
                return nil
            end
            local bestNode, bestDist, bestIdx = nil, math.huge, -1
            for _, pt in ipairs(points) do
                local owner = pt.owner
                if (owner == nil or owner ~= myTeam) and not pt.locked and pt.position then
                    local node = Node.GetClosest(pt.position)
                    if node then
                        local dist = (G.pLocal.Origin - pt.position):Length()
                        if dist < bestDist then
                            bestDist, bestNode, bestIdx = dist, node, pt.index
                        end
                    end
                end
            end
            if bestNode then
                G.World.goalPos = points[bestIdx + 1].position
                return bestNode
            end
            return nil
        end

        local function findHealthGoal()
            local closestDist = math.huge
            local closestNode = nil
            for _, pos in pairs(G.World.healthPacks or {}) do
                local healthNode = Node.GetClosest(pos)
                if healthNode then
                    local dist = (LocalOrigin - pos):Length()
                    if dist < closestDist then
                        closestDist = dist
                        closestNode = healthNode
                    end
                end
            end
            return closestNode
        end

        if currentTask == "Objective" then
            if mapName:find("plr_") or mapName:find("pl_") then
                goalNode = findPayloadGoal()
            elseif mapName:find("ctf_") then
                goalNode = findFlagGoal()
            elseif mapName:find("cp_") or mapName:find("koth_") or mapName:find("tc_") then
                goalNode = findControlPointGoal()
            else
                return
            end
        elseif currentTask == "Health" then
            goalNode = findHealthGoal()
        else
            Log:Debug("Unknown task: %s", currentTask)
            return
        end

        if not goalNode then
            if WorkManager.attemptWork(100, "nogoal") then
                Log:Warn("Could not find goal node.")
            end
            return
        end

        if startNode and goalNode and startNode.id == goalNode.id then
            Navigation.ClearPath()
            G.Navigation.stillTicks = 0
            G.Navigation.stillStartPos = nil
            return
        end

        Navigation.FindPath(startNode, goalNode)
    end
end

local function OnDrawModel(ctx)
    if ctx:GetModelName():find("medkit") then
        local entity = ctx:GetEntity()
        G.World.healthPacks[entity:GetIndex()] = entity:GetAbsOrigin()
    end
end

callbacks.Unregister("CreateMove", "LNX.navbot.CreateMove")
callbacks.Unregister("DrawModel", "LNX.navbot.DrawModel")

callbacks.Register("CreateMove", "LNX.navbot.CreateMove", function(u)
    Common.safeCall("Main.CreateMove", OnCreateMove, u)
end)
callbacks.Register("DrawModel", "LNX.navbot.DrawModel", function(ctx)
    Common.safeCall("Main.DrawModel", OnDrawModel, ctx)
end)

Notify.Alert("Navbot loaded!")
