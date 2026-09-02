local SetupModule = {}
SetupModule.__index = SetupModule

local Common = require("navbot.Common")
local G = require("navbot.Utils.Globals")
local SourceNav = require("navbot.Utils.SourceNav")
local Node = require("navbot.Utils.Node")
local Navigation = require("navbot.Utils.Navigation")
local TaskManager = require("navbot.TaskManager")
local BlockedStore = require("navbot.Utils.BlockedStore")
local WorkManager = require("navbot.WorkManager")
local Log = Common.Log

require("navbot.Utils.Config")
require("navbot.Visuals")
require("navbot.Menu")

local isNavGenerationInProgress = false
local navGenerationStartTime = 0
local navCheckElapsedTime = 0
local navCheckMaxTime = 60

local pLocal = nil
local function checkGameReady()
    pLocal = entities.GetLocalPlayer()
    if not pLocal then return false end
    return true
end

-- io is blocked; use filesystem.ReadFile (nil when missing)
function SetupModule.tryLoadNavFile(navFilePath, bQuiet)
    local content = filesystem.ReadFile(navFilePath)
    if not content then
        if not bQuiet then print("Nav file not found: " .. navFilePath) end
        return nil, "File not found"
    end

    local navData = SourceNav.parse(content)
    if not navData or #navData.areas == 0 then
        print("Failed to parse nav file or no areas found: " .. navFilePath)
        return nil, "Failed to parse nav file or no areas found."
    end

    return navData
end

function SetupModule.generateNavFile()
    print("Starting nav file generation...")
    client.RemoveConVarProtection("sv_cheats")
    client.RemoveConVarProtection("nav_generate")
    client.SetConVar("sv_cheats", "1")
    client.Command("nav_generate", true)
    print("Nav file generation command sent. Please wait...")

    isNavGenerationInProgress = true
    navGenerationStartTime = globals.RealTime()
    navCheckElapsedTime = 0
end

function SetupModule.processNavData(navData)
    local navNodes = {}
    local totalNodes = 0

    for _, area in pairs(navData.areas) do
        navNodes[area.id] = Node.create(area)
        totalNodes = totalNodes + 1
    end

    Node.SetNodes(navNodes)
    Log:Info("Processed %d nodes in nav data.", totalNodes)
    return navNodes
end

function SetupModule.LoadFile(navFile)
    local fullPath = "maps/" .. navFile

    local navData, error = SetupModule.tryLoadNavFile(fullPath)

    if not navData and error == "File not found" then
        Log:Warn("Nav file not found, generating new one.")
        SetupModule.generateNavFile()
    elseif not navData then
        Log:Error("Error loading nav file: %s", error)
        return
    else
        SetupModule.processNavDataAndSet(navData)
    end
end

function SetupModule.processNavDataAndSet(navData)
    local navNodes = SetupModule.processNavData(navData)
    if not navNodes or next(navNodes) == nil then
        Log:Error("No nodes found in nav data after processing.")
    else
        Node.SetNodes(navNodes)
        Log:Info("Nav nodes set")
    end
end

local lastNavProbeTime = 0

function SetupModule.checkNavFileGeneration()
    if not isNavGenerationInProgress then
        return
    end

    navCheckElapsedTime = globals.RealTime() - navGenerationStartTime

    if navCheckElapsedTime >= navCheckMaxTime then
        Log:Error("Nav file generation failed or took too long.")
        isNavGenerationInProgress = false
        return
    end

    if globals.RealTime() - lastNavProbeTime < 1 then
        return
    end
    lastNavProbeTime = globals.RealTime()

    local mapFile = engine.GetMapName()
    -- GetMapName returns the bare map name (no .bsp)
    local navFile = (mapFile:gsub("%.bsp$", "")) .. ".nav"
    local fullPath = "maps/" .. navFile

    local navData, error = SetupModule.tryLoadNavFile(fullPath, true)
    if navData then
        Log:Info("Nav file generated successfully.")
        isNavGenerationInProgress = false
        SetupModule.processNavDataAndSet(navData)
    else
        if math.floor(navCheckElapsedTime) % 10 == 0 then
            Log:Info("Waiting for nav file generation... (%d seconds elapsed)", math.floor(navCheckElapsedTime))
        end
    end
end

function SetupModule.LoadNavFile()
    local mapFile = engine.GetMapName()
    -- GetMapName returns the bare map name (no .bsp)
    local navFile = (mapFile:gsub("%.bsp$", "")) .. ".nav"
    Log:Info("Loading nav file for current map: %s", navFile)
    SetupModule.LoadFile(navFile)
end

function SetupModule.SetupNavigation()
    -- re-arm throttle gates (TickCount resets on map change)
    WorkManager.Reset()
    SetupModule.LoadNavFile()
    Navigation.ClearPath()
    TaskManager.Reset("Objective")  -- takes the string task key, not its value
    -- load this map's persisted blacklist
    BlockedStore.Load()
    Log:Info("Navigation setup initiated.")

    -- nodes may be nil until a nav file loads; never reindex (fragments the graph)
    local nodes = Node.GetNodes()
    if nodes then
        Log:Info(string.format("Total nodes: %d", #nodes))
    else
        Log:Warn("No nav nodes yet — waiting for nav mesh.")
    end
end

local function OnGameEvent(event)
    local eventName = event:GetName()
    if eventName == "game_newmap" then
        Log:Info("New map detected, reloading nav file...")
        SetupModule.SetupNavigation()

        Navigation.ClearPath()
        G.World.ownFlagHome = nil
        G.World.enemyFlagHome = nil
        G.World.bFlagDirty = true
        G.World.bTouchObjective = false
    elseif eventName == "round_start" then
        Navigation.ClearPath()
        Navigation.ResetTickTimer()
        G.Navigation.currentNode = nil
        G.Navigation.currentNodePos = nil
        G.Navigation.currentNodeIndex = nil
        TaskManager.Reset("Objective")
        G.World.lockedPoints = {}
        G.World.cpOwner = {}
        Log:Info("Round started — re-arming navigation.")
    elseif eventName == "teamplay_point_captured" then
        G.World.cpOwner[event:GetInt("cp")] = event:GetInt("team")
        G.Navigation.bForceRepath = true
    elseif eventName == "teamplay_point_locked" then
        G.World.lockedPoints[event:GetInt("cp")] = true
    elseif eventName == "teamplay_point_unlocked" then
        G.World.lockedPoints[event:GetInt("cp")] = nil
    elseif eventName == "ctf_flag_captured" or eventName == "teamplay_flag_event" or eventName == "flagstatus_update" then
        G.World.bFlagDirty = true
    elseif eventName == "player_spawn" or eventName == "player_death" then
        -- reset navigation on local spawn/death (more reliable than the CreateMove check)
        local idx = engine.GetPlayerForUserID(event:GetInt("userid"))
        if idx and idx == client.GetLocalPlayerIndex() then
            Navigation.ClearPath()
            Navigation.ResetTickTimer()
            G.Navigation.currentNode = nil
            G.Navigation.currentNodePos = nil
            G.Navigation.currentNodeIndex = nil
            Log:Info("%s — resetting navigation.", eventName == "player_spawn" and "Spawned" or "Died")
        end
    end
end

callbacks.Unregister("FireGameEvent", "LNX.navbot.FireGameEvent")
callbacks.Register("FireGameEvent", "LNX.navbot.FireGameEvent", OnGameEvent)

local function delayedSetup()
    if not checkGameReady() then return end
    -- unregister first so a setup error can't leave it firing every tick
    callbacks.Unregister("CreateMove", "delayedSetupCallback")
    SetupModule.SetupNavigation()
end

collectgarbage("collect")

callbacks.Register("CreateMove", "delayedSetupCallback", delayedSetup)

-- poll so a freshly generated nav is picked up
callbacks.Unregister("CreateMove", "checkNavFileCallback")
callbacks.Register("CreateMove", "checkNavFileCallback", function()
    if isNavGenerationInProgress then
        SetupModule.checkNavFileGeneration()
    end
end)

return SetupModule
