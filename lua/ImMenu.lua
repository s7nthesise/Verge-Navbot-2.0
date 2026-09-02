-- ImMenu.lua — ImMenu shim for Lua menu API
--
-- The real ImMenu is a third-party library that wraps Verge's raw
-- ImGui.* Lua bindings and adds frame/column layout. Verge exposes a curated
-- ImGui.* table (LuaApiImGui.cpp); each script's ImGui.Begin(...) opens its own
-- window. This shim maps the ImMenu calls scripts make onto that table so
-- `require "ImMenu"` resolves and the Navbot's Menu.lua can run.

local ImMenu = {}

ImMenu.GetVersion = function()
	return 0.66
end

ImMenu.Begin = function(title, open)
	return ImGui.Begin(title, open)
end
ImMenu.End = function()
	return ImGui.End()
end

ImMenu.BeginFrame = function(cols)
	return ImGui.BeginFrame(cols)
end
ImMenu.EndFrame = function()
	return ImGui.EndFrame()
end

-- Real tabs (each script's UI is its own window; tabs organize it inside).
ImMenu.BeginTabBar = function(label)
	return ImGui.TabBar(label)
end
ImMenu.EndTabBar = function()
	return ImGui.EndTabBar()
end
ImMenu.BeginTabItem = function(label)
	return ImGui.TabItem(label)
end
ImMenu.EndTabItem = function()
	return ImGui.EndTabItem()
end

ImMenu.Text = function(...)
	return ImGui.Text(...)
end

ImMenu.Button = function(label)
	return ImGui.Button(label)
end
ImMenu.Checkbox = function(label, value)
	return ImGui.Checkbox(label, value)
end
ImMenu.Slider = function(label, value, min, max, step, readOnly)
	return ImGui.Slider(label, value, min, max, step, readOnly)
end

ImMenu.Combo = function(label, current, items)
	return ImGui.Combo(label, current, items)
end
ImMenu.InputText = function(label, value)
	return ImGui.InputText(label, value)
end

-- Extended widgets (Verge ImGui.* surface — see LuaApiImGui.cpp). ColorEdit4,
-- CheckboxFlags and Selectable return (pressed, ...value) like the core menu.
ImMenu.ColorEdit4 = function(label, r, g, b, a)
	return ImGui.ColorEdit4(label, r, g, b, a)
end
ImMenu.CheckboxFlags = function(label, flags, flag)
	return ImGui.CheckboxFlags(label, flags, flag)
end
ImMenu.Selectable = function(label, selected)
	return ImGui.Selectable(label, selected)
end
ImMenu.RadioButton = function(label, active)
	return ImGui.RadioButton(label, active)
end
ImMenu.SetItemTooltip = function(text)
	return ImGui.SetItemTooltip(text)
end

ImMenu.SameLine = function(offset, spacing)
	return ImGui.SameLine(offset, spacing)
end
ImMenu.Separator = function()
	return ImGui.Separator()
end
ImMenu.NewLine = function()
	return ImGui.NewLine()
end
ImMenu.GetCursorPos = function()
	return ImGui.GetCursorPos()
end
ImMenu.SetCursorPos = function(x, y)
	return ImGui.SetCursorPos(x, y)
end
ImMenu.GetContentRegionAvail = function()
	return ImGui.GetContentRegionAvail()
end
ImMenu.GetWindowSize = function()
	return ImGui.GetWindowSize()
end
ImMenu.GetWindowPos = function()
	return ImGui.GetWindowPos()
end

return ImMenu
