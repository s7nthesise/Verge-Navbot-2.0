local Common = require("navbot.Common")
local G = require("navbot.Utils.Globals")
local Visuals = {}

local Lib = Common.Lib
local Fonts = Lib.UI.Fonts

-- client.WorldToScreen returns two values, not a table
local function W2S(pos)
	local x, y = client.WorldToScreen(pos)
	if not x then return nil end
	return { x, y }
end


local function Draw3DBox(size, pos)
    local halfSize = size / 2
    local corners1 = {
        Vector3(-halfSize, -halfSize, -halfSize),
        Vector3(halfSize, -halfSize, -halfSize),
        Vector3(halfSize, halfSize, -halfSize),
        Vector3(-halfSize, halfSize, -halfSize),
        Vector3(-halfSize, -halfSize, halfSize),
        Vector3(halfSize, -halfSize, halfSize),
        Vector3(halfSize, halfSize, halfSize),
        Vector3(-halfSize, halfSize, halfSize)
    }

    local linesToDraw = {
        {1, 2}, {2, 3}, {3, 4}, {4, 1},
        {5, 6}, {6, 7}, {7, 8}, {8, 5},
        {1, 5}, {2, 6}, {3, 7}, {4, 8}
    }

    local screenPositions = {}
    for _, cornerPos in ipairs(corners1) do
        local worldPos = pos + cornerPos
        local screenPos = W2S(worldPos)
        if screenPos then
            table.insert(screenPositions, { x = screenPos[1], y = screenPos[2] })
        end
    end

    for _, line in ipairs(linesToDraw) do
        local p1, p2 = screenPositions[line[1]], screenPositions[line[2]]
        if p1 and p2 then
            draw.Line(p1.x, p1.y, p2.x, p2.y)
        end
    end
end

local function ArrowLine(start_pos, end_pos, arrowhead_length, arrowhead_width, invert)
    if not (start_pos and end_pos) then return end

    if invert then
        start_pos, end_pos = end_pos, start_pos
    end

    local direction = end_pos - start_pos
    local direction_length = direction:Length()
    if direction_length == 0 then return end

    local normalized_direction = Common.Normalize(direction)

    local arrow_base = end_pos - normalized_direction * arrowhead_length

    local perpendicular = Vector3(-normalized_direction.y, normalized_direction.x, 0) * (arrowhead_width / 2)

    local w2s_start, w2s_end = W2S(start_pos), W2S(end_pos)
    local w2s_arrow_base = W2S(arrow_base)
    local w2s_perp1 = W2S(arrow_base + perpendicular)
    local w2s_perp2 = W2S(arrow_base - perpendicular)

    if not (w2s_start and w2s_end and w2s_arrow_base and w2s_perp1 and w2s_perp2) then return end

    draw.Line(w2s_start[1], w2s_start[2], w2s_arrow_base[1], w2s_arrow_base[2])

    draw.Line(w2s_end[1], w2s_end[2], w2s_perp1[1], w2s_perp1[2])
    draw.Line(w2s_end[1], w2s_end[2], w2s_perp2[1], w2s_perp2[2])

    draw.Line(w2s_perp1[1], w2s_perp1[2], w2s_perp2[1], w2s_perp2[2])
end


local function OnDraw()
    draw.SetFont(Fonts.Verdana)
    draw.Color(255, 0, 0, 255)
    local me = entities.GetLocalPlayer()
    if not me then return end

    local myPos = me:GetAbsOrigin()

    -- Draw all nodes (culled to 500u)
    if G.Menu.Visuals.drawNodes then
        draw.Color(0, 255, 0, 255)

        local navNodes = G.Navigation.nodes

        if navNodes then
            for id, node in pairs(navNodes) do
                local nodePos = node.pos
                local dist = (myPos - nodePos):Length()
                if dist > 500 then goto continue end

                local screenPos = W2S(nodePos)
                if not screenPos then goto continue end

                local x, y = screenPos[1], screenPos[2]
                draw.FilledRect(x - 4, y - 4, x + 4, y + 4)

                draw.Text(screenPos[1], screenPos[2] + 10, tostring(id))

                ::continue::
            end
        elseif not Visuals._warnedNodes then
            Visuals._warnedNodes = true -- warn once
            print("errror printing nodes (waiting for nav mesh)")
        end
    end

    if G.Menu.Visuals.drawPath and G.Navigation.path then
        draw.Color(255, 255, 255, 255)

        for i = 1, #G.Navigation.path - 1 do
            local node1 = G.Navigation.path[i]
            local node2 = G.Navigation.path[i + 1]

            local node1Pos = node1.pos
            local node2Pos = node2.pos

            local screenPos1 = W2S(node1Pos)
            local screenPos2 = W2S(node2Pos)
            if not screenPos1 or not screenPos2 then goto continue end

            if node1Pos and node2Pos then
                ArrowLine(node1Pos, node2Pos, 22, 15, true)
            end
            ::continue::
        end

        local node1 = G.Navigation.path[#G.Navigation.path]
        if node1 then
            node1 = node1.pos
            ArrowLine(myPos, node1, 22, 15, false)
        end
    end

    if G.Menu.Visuals.drawCurrentNode and G.Navigation.path then
        draw.Color(255, 0, 0, 255)

        local currentNodePos = G.Navigation.currentNodePos
        if not currentNodePos then return end

        local screenPos = W2S(currentNodePos)
        if screenPos then
            Draw3DBox(20, currentNodePos)
            draw.Text(screenPos[1], screenPos[2] + 40, tostring(G.Navigation.currentNodeinPath))
        end
    end
end

callbacks.Unregister("Draw", "Navbot_Draw")
callbacks.Register("Draw", "Navbot_Draw", function() Common.safeCall("Visuals.Draw", OnDraw) end)

return Visuals