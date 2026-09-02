-- persists blocked nodes/edges per map to Navbot/nodes/<map>.json
local G = require("navbot.Utils.Globals")
local Json = require("lnxLib/Libs/dkjson")
local Common = require("navbot.Common")

local Log = Common.Log
local BlockedStore = {}

local function mapName()
    local m = engine.GetMapName()
    return (m or ""):gsub("%.bsp$", "")
end

local function NodePath()
    return string.format("Navbot/nodes/%s.json", mapName())
end

local function countKeys(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

function BlockedStore.Reset()
    G.Navigation.blockedEdges = {}
    G.Navigation.blockedNodes = {}
end

function BlockedStore.Load()
    BlockedStore.Reset()
    local content = filesystem.ReadFile(NodePath())
    if not content or content == "" then return end

    local ok, data = pcall(Json.decode, content)
    if not ok or type(data) ~= "table" then
        Log:Warn("BlockedStore: failed to parse %s", NodePath())
        return
    end

    if type(data.blockedNodes) == "table" then
        for _, id in ipairs(data.blockedNodes) do
            G.Navigation.blockedNodes[id] = true
        end
    end
    if type(data.blockedEdges) == "table" then
        for _, e in ipairs(data.blockedEdges) do
            G.Navigation.blockedEdges[e] = true
        end
    end

    local nNodes, nEdges = countKeys(G.Navigation.blockedNodes), countKeys(G.Navigation.blockedEdges)
    if nNodes + nEdges > 0 then
        Log:Info("BlockedStore: loaded %d nodes / %d edges for %s", nNodes, nEdges, mapName())
    end
end

function BlockedStore.Save()
    local nodes, edges = {}, {}
    for id in pairs(G.Navigation.blockedNodes or {}) do nodes[#nodes + 1] = id end
    for e in pairs(G.Navigation.blockedEdges or {}) do edges[#edges + 1] = e end

    if #nodes == 0 and #edges == 0 then return end

    local ok, json = pcall(Json.encode, { blockedNodes = nodes, blockedEdges = edges })
    if not ok then
        Log:Warn("BlockedStore: failed to encode blacklist")
        return
    end

    filesystem.CreateDirectory("Navbot/nodes")
    if filesystem.WriteFile(NodePath(), json) then
        Log:Info("BlockedStore: saved %d nodes / %d edges to %s", #nodes, #edges, NodePath())
    end
end

return BlockedStore
