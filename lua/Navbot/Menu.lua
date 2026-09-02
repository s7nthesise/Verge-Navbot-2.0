local MenuModule = {}

local G = require("navbot.Utils.Globals")
local Common = require("navbot.Common")

local Fonts = Common.Lib.UI.Fonts

local menuLoaded, ImMenu = pcall(require, "ImMenu")
assert(menuLoaded, "ImMenu not found, please install it!")
assert(ImMenu.GetVersion() >= 0.66, "ImMenu version is too old, please update it!")

local lastToggleTime = 0
local Lbox_Menu_Open = true
local toggleCooldown = 0.1

function MenuModule.toggleMenu()
    local currentTime = globals.RealTime()
    if currentTime - lastToggleTime >= toggleCooldown then
        Lbox_Menu_Open = not Lbox_Menu_Open
        lastToggleTime = currentTime
    end
end

local function OnDrawMenu()
    draw.SetFont(Fonts.Verdana)
    draw.Color(255, 255, 255, 255)
    local Menu = G.Menu
    local Main = Menu.Main

    -- HOME toggles the menu
    if input.IsButtonDown(KEY_HOME) then
        MenuModule.toggleMenu()
    end

    if Lbox_Menu_Open == true and ImMenu and ImMenu.Begin("Navbot", true) then
        if ImMenu.BeginTabBar("NavbotTabs") then
            if ImMenu.BeginTabItem("Main") then
                Main.Walking = ImMenu.Checkbox("Walking", Main.Walking)
                Main.Skip_Nodes = ImMenu.Checkbox("Skip Nodes", Main.Skip_Nodes)
                Main.Optymise_Path = ImMenu.Checkbox("Optimise Path", Main.Optymise_Path)
                Main.shouldfindhealth = ImMenu.Checkbox("Path to Health", Main.shouldfindhealth)
                if Main.shouldfindhealth then
                    ImMenu.Text("Self Heal Threshold")
                    Main.SelfHealTreshold = ImMenu.Slider("##heal", Main.SelfHealTreshold, 0, 100)
                end
                ImMenu.EndTabItem()
            end

            if ImMenu.BeginTabItem("Visuals") then
                Menu.Visuals.drawNodes = ImMenu.Checkbox("Draw Nodes", Menu.Visuals.drawNodes)
                Menu.Visuals.drawPath = ImMenu.Checkbox("Draw Path", Menu.Visuals.drawPath)
                Menu.Visuals.drawCurrentNode = ImMenu.Checkbox("Draw Current Node", Menu.Visuals.drawCurrentNode)
                ImMenu.EndTabItem()
            end

            if ImMenu.BeginTabItem("Movement") then
                Menu.Movement.lookatpath = ImMenu.Checkbox("Look at Path", Menu.Movement.lookatpath)
                Menu.Movement.smoothLookAtPath = ImMenu.Checkbox("Smooth Look At Path", Menu.Movement.smoothLookAtPath)
                ImMenu.Text("Smooth Factor")
                Menu.Movement.smoothFactor = ImMenu.Slider("##smooth", Menu.Movement.smoothFactor, 0.010, 1.0, 0.01)
                ImMenu.EndTabItem()
            end

            ImMenu.EndTabBar()
        end
        ImMenu.End()
    end

    -- Read-only nav-generation progress while loading
    if G.Menu.Main.Loading < 100 and ImMenu and ImMenu.Begin("Loading Resources", true) then
        ImMenu.BeginFrame(1)
        ImMenu.Text("Loading Progress")
        ImMenu.Slider("##load", G.Menu.Main.Loading, 0, 100, nil, true) -- 5th arg = read-only
        ImMenu.EndFrame()
        ImMenu.End()
    end
end

callbacks.Unregister("Draw", "OnDrawMenu")
callbacks.Register("Draw", "OnDrawMenu", function() Common.safeCall("Menu.Draw", OnDrawMenu) end)

return MenuModule
