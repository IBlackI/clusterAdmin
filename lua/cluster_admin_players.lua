-- cluster_admin_players sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord)
-- This sub-module is a addon to the cluster_admin module, it allows admins to see player online time, follow or teleport to them, even across servers

--
--	FUNCTIONS
--
function cluster_admin_players_enable()
	if not global.cluster_admin_players.enabled then
		global.cluster_admin_players.enabled = true
		for i, p in pairs(game.connected_players) do
			if p.admin then
				cluster_admin_add_button(p.name, "player_list")
			end
		end
	else 
		return false
	end
end

function cluster_admin_players_disable()
	if global.cluster_admin_players.enabled then
		global.cluster_admin_players.enabled = false
		for i, p in pairs(game.connected_players) do
			if p.admin then
				cluster_admin_remove_button(p.name, "player_list")
			end
		end
	else 
		return false
	end
end

function cluster_admin_players_format_online_time(ticks)
	local seconds = math.floor(ticks / 60)
	local minutes = math.floor(seconds / 60)
	local hours = math.floor(minutes / 60)
	local days = math.floor(hours / 24)
	return string.format("%d:%02d:%02d", hours, minutes % 60, seconds % 60)
end

function cluster_admin_players_toggle_gui(p)
	local pane = cluster_admin_get_flow(p).cluster_admin_players_pane
	if not (global.cluster_admin_players.enabled and p.admin) then
		return
	end
	if pane == nil then
		pane = cluster_admin_players_create_gui(p)
	else
		pane.visible = not pane.visible
	end
	local button = cluster_admin_add_button(p.name, "player_list")
	if pane.visible then
		button.style = "highlighted_tool_button"
		cluster_admin_players_update_player_list(p)
	else
		button.style = "button"
	end
end
	
function cluster_admin_players_create_gui(p)
	local bf = cluster_admin_get_flow(p)
	local pane = bf.cluster_admin_players_pane
	if pane ~= nil then
		pane.clear()
	else 
		pane = bf.add {name = "cluster_admin_players_pane", type = "frame", caption = "Player manager", direction = "vertical"}
		pane.style.use_header_filler = false
	end
	if global.cluster_admin_players.enabled and p.admin then
		pane.style.height = 298
		cluster_admin_players_create_search(pane)
		cluster_admin_players_create_list(pane)
		return pane
	else
		pane.destroy()
	end
end

function cluster_admin_players_create_search(parent)
	local sf = parent.add {type="frame", direction = "horizontal", name="cluster_admin_players_search_frame"}
	sf.style = "bordered_frame"
	local sff = sf.add {type="flow", direction = "horizontal", name="cluster_admin_players_search_frame_flow", tooltip = "Filter the playernames in the list below"}
	sff.style.vertical_align = "center"
	local l = sff.add {name = "cluster_admin_players_search_label", type = "label", caption = "Name: ", tooltip = "Filter the playernames in the list below"}
	l.style = "heading_3_label"
	local search = sff.add {name = "cluster_admin_players_search", type = "textfield", tooltip = "Filter the playernames in the list below"}
	search.style.horizontally_stretchable = true
	search.style.maximal_width = 500
	local refresh = sff.add {name = "cluster_admin_players_search_refresh", type = "button", caption = "Refresh"}
	refresh.style.width = 70
	refresh.style.padding = 0
end

function cluster_admin_players_create_list(parent)
	local lf = parent.add {type="frame", direction = "horizontal", name="cluster_admin_players_list_frame"}
	lf.style = "bordered_frame"
	local plp = lf.add { type="scroll-pane", direction="vertical", name="cluster_admin_players_list_parent", vertical_scroll_policy="always", horizontal_scroll_policy="never" }
	plp.style = "list_box_scroll_pane"
	plp.style.width = 325
	plp.style.vertically_stretchable = true
	plp.style.padding = 0
	
	local pl = plp.add{type="flow", direction="vertical", name="cluster_admin_players_list"}
	pl.style.vertical_spacing = 0
end

function cluster_admin_players_add_entry(parent, player, server)
	if parent["cluster_admin_players_list_entry_" .. player.name] ~= nil then
		return
	end
	local frame = parent.add { type="frame", name="cluster_admin_players_list_entry_" .. player.name, direction = "horizontal"}
	frame.style = "dark_frame"
	frame.style.use_header_filler = false
	frame.style.height = 28
	frame.style.padding = 0
	frame.style.horizontally_stretchable = true
	local playername = frame.add{name = "cluster_admin_players_label_player_list_name", type = "label", caption = player.name, tooltip = player.name}
	playername.style.width = 100
	local kick = {}
	local ban = {}
	if server == "local" then
		local onlinetime = frame.add{name = "cluster_admin_players_label_player_list_time", type = "label", caption = cluster_admin_players_format_online_time(player.online_time)}
		onlinetime.style.width = 80
		local follow = frame.add{name = "cluster_admin_players_label_player_list_follow", type = "button", caption = "F", tooltip = "Follow this player"}
		follow.enabled = cluster_admin_submodule_state("cluster_admin_spectate_follow")
		follow.style.height = 20
		follow.style.width = 20
		follow.style.padding = 0
		local teleport = frame.add{name = "cluster_admin_players_label_player_list_teleport", type = "button", caption = "T", tooltip = "Teleport to this player"}
		teleport.style.height = 20
		teleport.style.width = 20
		teleport.style.padding = 0
		local camera = frame.add{name = "cluster_admin_players_label_player_list_camera", type = "button", caption = "C", tooltip = "Create camera"}
		camera.enabled = cluster_admin_submodule_state("cluster_admin_camera")
		camera.style.height = 20
		camera.style.width = 20
		camera.style.padding = 0
		if parent.gui.player.name == player.name then
			follow.enabled = false
			teleport.enabled = false
		end
		kick = frame.add{name = "cluster_admin_players_label_player_list_kick", type = "button", caption = "K", tooltip = "Kick player"}
		ban = frame.add{name = "cluster_admin_players_label_player_list_ban", type = "button", caption = "B", tooltip = "Ban player"}
	else
		local serverlabel = frame.add{name = "cluster_admin_players_label_player_list_server", type = "label", caption = server, tooltip = server}
		serverlabel.style.width = 80
		local connect = frame.add{name = "cluster_admin_players_label_player_list_connect", type = "button", caption = "Connect", tooltip = "Connect to other server"}
		if global.cluster_admin_players.servers[server] == nil then
			connect.enabled = false
		end
		connect.style.height = 20
		connect.style.width = 68
		connect.style.padding = 0
		kick = frame.add{name = "cluster_admin_players_label_player_list_remote_kick", type = "button", caption = "K", tooltip = "Kick player"}
		ban = frame.add{name = "cluster_admin_players_label_player_list_remote_ban", type = "button", caption = "B", tooltip = "Ban player"}
	end
	if player.admin then
		playername.style.font_color = {128, 206, 240}
		ban.enabled = false
	end
	kick.style.height = 20
	kick.style.width = 20
	kick.style.padding = 0
	ban.style.height = 20
	ban.style.width = 20
	ban.style.padding = 0
	
end

function cluster_admin_players_update_player_list(p)
	if not (global.cluster_admin_players.enabled and p.admin) then
		return
	end
	local pane = cluster_admin_get_flow(p).cluster_admin_players_pane
	if pane == nil then
		pane = cluster_admin_players_create_gui(p)
	end
	local list = pane.cluster_admin_players_list_frame.cluster_admin_players_list_parent.cluster_admin_players_list
	local filter = pane.cluster_admin_players_search_frame.cluster_admin_players_search_frame_flow.cluster_admin_players_search.text
	list.clear()
	for k, player in pairs(game.connected_players) do
		if filter ~= "" then
			if string.find(string.lower(player.name), string.lower(filter)) ~= nil then
				cluster_admin_players_add_entry(list, player, "local")
			end
		else
			cluster_admin_players_add_entry(list, player, "local")
		end
	end
	for l, remote in pairs(global.cluster_admin_players.remote) do
		if filter ~= "" then
			if string.find(string.lower(remote.n), string.lower(filter)) ~= nil then
				cluster_admin_players_add_entry(list, {name=remote.n, admin=remote.a}, remote.s)
			end
		else
			cluster_admin_players_add_entry(list, {name=remote.n, admin=remote.a}, remote.s)
		end
	end
end

--
--	Events
--
function cluster_admin_players_on_init()
	global.cluster_admin_players = global.cluster_admin_players or {}
	global.cluster_admin_players.remote = global.cluster_admin_players.remote or {}
	global.cluster_admin_players.servers = global.cluster_admin_players.servers or {}
	global.cluster_admin_players.enabled = true
	cluster_admin_add_submodule("modular_admin_players")
end


function cluster_admin_players_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if (e and e.parent) ~= nil then
		if p.admin then
			if e.name == "cluster_admin_menu_button_player_list" then
				if global.cluster_admin_players.enabled then
					cluster_admin_players_toggle_gui(p)
				else 
					p.print("Sorry, this sub-module has just been disabled")
				end
			elseif e.name == "cluster_admin_players_search_refresh" then
				cluster_admin_players_update_player_list(p)
			elseif e.parent.parent ~= nil and e.parent.parent.name == "cluster_admin_players_list" then
				local target_name = string.gsub(e.parent.name, "cluster_admin_players_list_entry_", "")
				if target_name ~= nil and target_name ~= "" then
					local target = game.players[target_name]
					if target ~= nil and target.connected then
						if e.name == "cluster_admin_players_label_player_list_teleport" then
							p.teleport(target.surface.find_non_colliding_position("character", target.position, 0, 1))
						elseif e.name == "cluster_admin_players_label_player_list_follow" then
							if cluster_admin_submodule_state("cluster_admin_spectate_follow") then
								cluster_admin_spectate_set_spectator(p)
								cluster_admin_spectate_set_follow_target(p, target)
							end
						elseif e.name == "cluster_admin_players_label_player_list_camera" then
							if cluster_admin_submodule_state("cluster_admin_camera") then
								cluster_admin_camera_create(p, target)
							end
						elseif e.name == "cluster_admin_players_label_player_list_kick" then
							game.kick_player(target.name)
						elseif e.name == "cluster_admin_players_label_player_list_ban" then
							game.ban_player(target.name)
							if remote.interfaces["fagc"] ~= nil then
								if remote.interfaces["fagc"]["createPopup"] then
									remote.call("fagc", "createPopup", p.name, target.name)
								end
							end
						end
					else
						if e.name == "cluster_admin_players_label_player_list_connect" then
							target = global.cluster_admin_players.remote[target_name]
							if target ~= nil then
								local server = global.cluster_admin_players.servers[target.s]
								if server ~= nil then
									p.connect_to_server{address=server.ip .. ":" .. server.port, name=server.name}
								else
									p.print("Couldn't find player or server info")
								end
							end
						elseif e.name == "cluster_admin_players_label_player_list_remote_kick" then
							print("[CLUSTER_ADMIN] [KICK] " .. target_name .. " [END]")
						elseif e.name == "cluster_admin_players_label_player_list_remote_ban" then
							print("[CLUSTER_ADMIN] [BAN] " .. target_name .. " [END]")
							if remote.interfaces["fagc"] ~= nil then
								if remote.interfaces["fagc"]["createPopup"] then
									remote.call("fagc", "createPopup", p.name, target_name)
								end
							end
						else
							game.print(e.name)
						end
					end
				end
			end
		end
	end
end

function cluster_admin_players_search_changed(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then
		if e.name == "cluster_admin_players_search" then
			cluster_admin_players_update_player_list(p)
		end
	end
end

function cluster_admin_players_on_player_joined(event)
	local p = game.players[event.player_index]
	if p.admin then
		if global.cluster_admin_players.enabled then
			local button = cluster_admin_add_button(p.name, "player_list")
			button.caption = "Player manager"
		else 
			cluster_admin_remove_button(p.name, "player_list")
		end
	end
end