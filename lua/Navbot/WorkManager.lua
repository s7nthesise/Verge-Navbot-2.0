local WorkManager = {}
WorkManager.works = {}

local function getCurrentTick()
    return globals.TickCount()
end

function WorkManager.attemptWork(delay, identifier)
    local currentTime = getCurrentTick()

    if WorkManager.works[identifier] and currentTime - WorkManager.works[identifier].lastExecuted < delay then
        return false
    end

    if not WorkManager.works[identifier] then
        WorkManager.works[identifier] = {
            lastExecuted = currentTime,
            delay = delay
        }
    else
        WorkManager.works[identifier].lastExecuted = currentTime
    end

    return true
end

-- re-arm all gates (TickCount resets on map change)
function WorkManager.Reset()
    WorkManager.works = {}
end

return WorkManager
