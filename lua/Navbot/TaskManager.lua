local TaskManager = {}

local G = require("navbot.Utils.Globals")
local Log = require("navbot.Common").Log

function TaskManager.AddTask(taskKey)
    local taskPriority = G.Tasks[taskKey]
    if taskPriority then
        if not G.Current_Tasks[taskKey] then
            G.Current_Tasks[taskKey] = taskPriority
            Log:Info("Added task: %s with priority %d", taskKey, taskPriority)
        else
            Log:Info("Task %s is already in the current tasks.", taskKey)
        end
    else
        Log:Warn("Task '%s' does not exist in G.Tasks.", taskKey)
    end
end

function TaskManager.RemoveTask(taskKey)
    if G.Current_Tasks[taskKey] then
        G.Current_Tasks[taskKey] = nil
        Log:Info("Removed task: %s", taskKey)
    else
        Log:Info("Task %s is not in the current tasks.", taskKey)
    end
end

function TaskManager.GetCurrentTask()
    local highestPriorityTaskKey = nil
    local highestPriority = -math.huge

    for taskKey, priority in pairs(G.Current_Tasks) do
        if priority > highestPriority then  -- Higher numerical value means higher priority
            highestPriority = priority
            highestPriorityTaskKey = taskKey
        end
    end

    if highestPriorityTaskKey then
        G.Current_Task = G.Tasks[highestPriorityTaskKey]
    else
        G.Current_Task = G.Tasks.None
    end

    return highestPriorityTaskKey
end

function TaskManager.Reset(defaultTaskKey)
    G.Current_Tasks = {}
    if defaultTaskKey and G.Tasks[defaultTaskKey] then
        TaskManager.AddTask(defaultTaskKey)
        Log:Info("Tasks reset to default task: %s", defaultTaskKey)
    else
        Log:Warn("Default task key '%s' is invalid.", tostring(defaultTaskKey))
    end
end

function TaskManager.IsTaskActive(taskKey)
    return G.Current_Tasks[taskKey] ~= nil
end

return TaskManager
