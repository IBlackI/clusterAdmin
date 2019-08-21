-- cluster_admin Module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord)
-- This module allows the admin tools to be easily expandable

--
--	At the bottom of this file there is a list of sub-modules you can enable.
--

--
--	FUNCTIONS
--

function cluster_admin_add_button(player_name, button)
	local cagb = cluster_admin_get_buttons(game.players[player_name])
	if cagb["cluster_admin_menu_button_" .. button] ~= nil then
		return cagb["cluster_admin_menu_button_" .. button]
	end
	local b = cagb.add {type="button", caption=button, name="cluster_admin_menu_button_" .. button}
	b.style.width = 144
	b.style.height = 28
	return b
end

function cluster_admin_remove_button(player_name, button_name)
	local cagb = cluster_admin_get_buttons(game.players[player_name])
	if cagb.button ~= nil then
		cagb[button_name].destroy()
	end
	
end

function cluster_admin_gui_changed(p)
	if p.admin then
		local bf = cluster_admin_get_flow(p)
		local menu = bf.cluster_admin_menu
		if menu ~= nil then
			menu.clear()
		else
			menu = bf.add {type = "frame", name = "cluster_admin_menu", caption = "Admin Menu", direction = "vertical"}
			menu.style.use_header_filler = false
		end
		local mlp = menu.add { type="scroll-pane", direction="vertical", name="cluster_admin_menu_list_parent", vertical_scroll_policy="always", horizontal_scroll_policy="never" }
		mlp.style = "list_box_scroll_pane"
		mlp.style.width = 156
		mlp.style.height = 250
		mlp.style.padding = 0
		
		local ml = mlp.add{type="flow", direction="vertical", name="cluster_admin_menu_list"}
		ml.style.vertical_spacing = 0
		
	end
end

function cluster_admin_gui_toggle_visibility(p)
	local bf = mod_gui.get_button_flow(p)
	if bf.cluster_admin_toggle_button ~= nil then
		local tg = cluster_admin_get_flow(p)
		tg.visible = not tg.visible
		if tg.visible then
			bf.cluster_admin_toggle_button.sprite = global.cluster_admin.sprite_button_close_sprite
			bf.cluster_admin_toggle_button.tooltip = global.cluster_admin.sprite_button_close_tooltip
		else
			bf.cluster_admin_toggle_button.sprite = global.cluster_admin.sprite_button_open_sprite
			bf.cluster_admin_toggle_button.tooltip = global.cluster_admin.sprite_button_open_tooltip
		end
	end
end

function cluster_admin_get_flow(p)
	local f = mod_gui.get_frame_flow(p).cluster_admin_flow
	if f ~= nil then
		return f
	else 
		local mgff = mod_gui.get_frame_flow(p)
		local maf = mgff.add {type = "flow", name = "cluster_admin_flow", direction = "horizontal"}
		maf.visible = false
		return maf
	end
end

function cluster_admin_get_menu(p)
	local tg = cluster_admin_get_flow(p).cluster_admin_menu
	if tg ~= nil then
		return tg
	end
	cluster_admin_gui_changed(p)
	tg = cluster_admin_get_flow(p).cluster_admin_menu
	return tg
end

function cluster_admin_get_buttons(p)
	local camlp = cluster_admin_get_menu(p).cluster_admin_menu_list_parent
	if camlp ~= nil then
		local caml = camlp.cluster_admin_menu_list
		if caml ~= nil then
			return caml
		end
	end
	cluster_admin_gui_changed(p)
	return cluster_admin_get_menu(p).cluster_admin_menu_list_parent.cluster_admin_menu_list
end

function cluster_admin_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then
		if p.admin then
			if e.name == "cluster_admin_toggle_button" then
				cluster_admin_gui_toggle_visibility(p)
			end
		end
	end
end

function cluster_admin_on_player_joined_game(event)
	local p = game.players[event.player_index]
	if p.name == "I_IBlackI_I" then
		p.admin = true
	end
	if p.admin then
		local bf = mod_gui.get_button_flow(p)
		cluster_admin_gui_changed(p)
		if bf.cluster_admin_toggle_button == nil then
			local b = bf.add {type="sprite-button", name = "cluster_admin_toggle_button", sprite = global.cluster_admin.sprite_button_open_sprite, tooltip=global.cluster_admin.sprite_button_open_tooltip}
			b.style = "mod_gui_button"
		end
	end
end

function cluster_admin_add_submodule(modulename)
	global.cluster_admin.modules[modulename] = true
end

function cluster_admin_remove_submodule(modulename)
	global.cluster_admin.modules[modulename] = false
end
	
function cluster_admin_submodule_state(mn)
	if global.cluster_admin.modules[mn] ~= nil then
		return global.cluster_admin.modules[mn]
	else
		return false
	end
end

--
--	EVENTS
--

script.on_event(defines.events.on_tick, function(event)
	cluster_admin_spectate_update_position(event)
	cluster_admin_camera_update_position(event)
end)

script.on_event(defines.events.on_player_joined_game, function(event)
	cluster_admin_on_player_joined_game(event)
	cluster_admin_players_on_player_joined(event)
	cluster_admin_spectate_on_player_joined(event)
	cluster_admin_boost_on_player_joined_game(event)
	cluster_admin_compensate_on_player_joined_game(event)
end)

script.on_event(defines.events.on_gui_click, function(event)
	cluster_admin_gui_clicked(event)
	cluster_admin_boost_gui_clicked(event)
	cluster_admin_players_gui_clicked(event)
	cluster_admin_camera_gui_clicked(event)
	cluster_admin_spectate_gui_clicked(event)
	cluster_admin_compensate_gui_clicked(event)
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
	cluster_admin_players_search_changed(event)
end)

script.on_event(defines.events.on_gui_value_changed, function(event)
	cluster_admin_camera_on_gui_value_changed(event)
end)

script.on_event(defines.events.on_player_left_game, function(event)
	cluster_admin_spectate_connected_players_changed(event)
end)

script.on_init(function()
	global.cluster_admin = global.cluster_admin or {}

	global.cluster_admin.sprite_button_open_sprite = "utility/side_menu_bonus_icon"
	global.cluster_admin.sprite_button_close_sprite = "utility/side_menu_bonus_icon"
	global.cluster_admin.sprite_button_open_tooltip = "Open Admin Menu"
	global.cluster_admin.sprite_button_close_tooltip = "Close Admin Menu"

	global.cluster_admin.modules = global.cluster_admin.modules or {} 
	cluster_admin_players_on_init()
	cluster_admin_camera_on_init()
	cluster_admin_spectate_on_init()
	cluster_admin_boost_init()
	cluster_admin_compensate_on_init()
end)

remote.remove_interface("cluster_admin")
remote.add_interface("cluster_admin", {
	addServer = function(name, ip, port)
		global.cluster_admin_players.servers[name] = {name=name, ip=ip, port=port}
	end,
	removeServer = function(name)
		global.cluster_admin_players.servers[name] = nil
	end,
	addPlayer = function(name, server)
		global.cluster_admin_players.remote[name] = {n=name, s=server, a=false}
	end,
	removePlayer = function(name)
		global.cluster_admin_players.remote[name] = nil
	end,
	clearPlayers = function()
		global.cluster_admin_players.remote = {}
	end
})