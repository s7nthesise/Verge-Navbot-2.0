local Fonts = require("lnxLib/UI/Fonts")

local Size = { W = 300, H = 50 }
local Offset = { X = 10, Y = 10 }
local Padding = { X = 10, Y = 10 }
local FadeTime = 0.3

local Notify = {}

local notifications = {}
local currentID = 0

function Notify.Push(data)
    assert(type(data) == "table", "Notify.Push: data must be a table")

    data.ID = currentID
    data.Duration = data.Duration or 3
    data.StartTime = globals.RealTime()

    notifications[data.ID] = data
    currentID = (currentID + 1) % 1000

    return data.ID
end

function Notify.Alert(title, duration)
    return Notify.Push({
        Title = title,
        Duration = duration
    })
end

function Notify.Simple(title, msg, duration)
    return Notify.Push({
        Title = title,
        Content = msg,
        Duration = duration
    })
end

function Notify.Pop(id)
    local notification = notifications[id]
    if notification then
        notification.Duration = 0
    end
end

local function OnDraw()
    local currentY = Offset.Y

    for id, note in pairs(notifications) do
        local deltaTime = globals.RealTime() - note.StartTime

        if deltaTime > note.Duration then
            notifications[id] = nil
        else
            local fadeStep = 1.0
            if deltaTime < FadeTime then
                fadeStep = deltaTime / FadeTime
            elseif deltaTime > note.Duration - FadeTime then
                fadeStep = (note.Duration - deltaTime) / FadeTime
            end

            local fadeAlpha = math.floor(fadeStep * 255)
            currentY = currentY - math.floor((1 - fadeStep) * Size.H)

            draw.Color(35, 50, 60, fadeAlpha)
            draw.FilledRect(Offset.X, currentY, Offset.X + Size.W, currentY + Size.H)

            local barWidth = math.floor(Size.W * (deltaTime / note.Duration))
            draw.Color(255, 255, 255, 150)
            draw.FilledRect(Offset.X, currentY, Offset.X + barWidth, currentY + 5)

            draw.Color(245, 245, 245, fadeAlpha)

            draw.SetFont(Fonts.SegoeTitle)
            if note.Title then
                draw.Text(Offset.X + Padding.X, currentY + Padding.Y, note.Title)
            end

            draw.SetFont(Fonts.Segoe)
            if note.Content then
                draw.Text(Offset.X + Padding.X, currentY + Padding.Y + 20, note.Content)
            end

            currentY = currentY + Size.H + Offset.Y
        end
    end
end

Internal.RegisterCallback("Draw", OnDraw, "UI", "Notify")

return Notify
