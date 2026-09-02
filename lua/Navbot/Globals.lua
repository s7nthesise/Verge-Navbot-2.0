local G = {}

-- bridged from Main.lua (scripts run in _G)
G.Lua__fileName = (rawget(_G, "NAVBOT_SCRIPT_NAME") or "main"):match("([^/\\]+)%.lua$")

G.default_menu = {
    Tabs = {
        Main = true,
        Settings = false,
        Visuals = false,
        Movement = false,
    },

    Main = {
        Loading = 100,
        Walking = true,
        Skip_Nodes = true,
        Optymise_Path = true,
        shouldfindhealth = true,
        SelfHealTreshold = 45,
    },
    Visuals = {
        drawNodes = false,
        drawPath = true,
        drawCurrentNode = true,
    },
    Movement = {
        lookatpath = true,
        smoothLookAtPath = true,
        smoothFactor = 0.1,
    }
}

G.Menu = G.default_menu

G.Default = {
    flags = 1,
}

G.pLocal = G.Default

G.World_Default = {
    healthPacks = {},
    payloads = {},
    flags = {},
    goalPos = nil,
    lockedPoints = {},
    cpOwner = {},
}

G.World = G.World_Default

G.Misc = {
    NodeTouchDistance = 25,  -- native PathFollower m_goalTolerance
    NodeTouchHeight = 82,
}

G.Navigation = {
    path = nil,
    nodes = nil,
    currentNode = nil,
    currentNodePos = nil,
    currentNodeinPath = 1000,
    currentNodeTicks = 0,
    stillTicks = 0,        -- consecutive ticks the bot is physically frozen while commanding movement
    stillStartPos = nil,   -- last position where the bot was physically moving (stillness snapshot)
    lastPos = nil,         -- last origin for tracking movement direction (drop nudge)
    lastMoveDir = nil,     -- last horizontal movement direction (drop nudge)
    blockedEdges = {},  -- edges/nodes the bot got stuck on; A* avoids them
    blockedNodes = {},
    bForceRepath = false,
}

G.Tasks = {
    None = 0,
    Objective = 1,
    Health = 3,
}

G.Current_Tasks = {}
G.Current_Task = G.Tasks.Objective

G.StateDefinition = {
    Pathfinding = 1,
    PathWalking = 2,
    ManualBypass = 5,
}

G.State = nil

return G
