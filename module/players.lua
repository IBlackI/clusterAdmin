local function format_online_time(ticks)
	local seconds = math.floor(ticks / 60)
	local minutes = math.floor(seconds / 60)
	local hours = math.floor(minutes / 60)
	local days = math.floor(hours / 24)
	return string.format("%d:%02d:%02d", hours, minutes % 60, seconds % 60)
end

local function create_search_frame(parent)
	local sf = parent.add {type="frame", direction = "horizontal", name="search_frame"}
	sf.style = "bordered_frame"
	local sff = sf.add {type="flow", direction = "horizontal", name="search_frame_flow", tooltip = "Filter the playernames in the list below"}
	sff.style.vertical_align = "center"
	local l = sff.add {name = "search_label", type = "label", caption = "Name: ", tooltip = "Filter the playernames in the list below"}
	l.style = "heading_3_label"
	local search_field = sff.add {name = "search_field", type = "textfield", tooltip = "Filter the playernames in the list below"}
	search_field.style.horizontally_stretchable = true
	search_field.style.maximal_width = 500
	local refresh = sff.add {name = "search_refresh", type = "button", caption = "Refresh"}
	refresh.style.width = 70
	refresh.style.padding = 0
end

local function create_player_list_frame(parent)
	local lf = parent.add {type="frame", direction = "horizontal", name="player_list_frame"}
	lf.style = "bordered_frame"
	local pls = lf.add { type="scroll-pane", direction="vertical", name="players_list_scroll", vertical_scroll_policy="always", horizontal_scroll_policy="never" }
	pls.style = "list_box_scroll_pane"
	pls.style.width = 325
	pls.style.vertically_stretchable = true
	pls.style.padding = 0
	
	local plf = pls.add{type="flow", direction="vertical", name="player_list_flow"}
	plf.style.vertical_spacing = 0
end

local function add_player_entry(parent, player, server)
	if parent["player_list_entry_" .. player.name] ~= nil then
		return
	end
	if player.name == "undefined" then
		return
    end
    
	local frame = parent.add { type="frame", name="player_list_entry_" .. player.name, direction = "horizontal"}
	frame.style = "dark_frame"
	frame.style.use_header_filler = false
	frame.style.height = 28
	frame.style.padding = 0
    frame.style.horizontally_stretchable = true
    
    local function style_small(element)
        element.style.height = 20
		element.style.width = 20
		element.style.padding = 0
    end

	local playername = frame.add{name = "player_list_entry_name", type = "label", caption = player.name, tooltip = player.name}
    playername.style.width = 100
    
	local kick = {}
	local ban = {}
	if server == "local" then
		local onlinetime = frame.add{name = "player_list_entry_time", type = "label", caption = format_online_time(player.online_time)}
		onlinetime.style.width = 80
		local follow = frame.add{name = "player_list_entry_follow", type = "button", caption = "F", tooltip = "Follow this player"}
        style_small(follow)

		local teleport = frame.add{name = "player_list_entry_teleport", type = "button", caption = "T", tooltip = "Teleport to this player"}
        style_small(teleport)
        
		local camera = frame.add{name = "player_list_entry_camera", type = "button", caption = "C", tooltip = "Create camera"}
        style_small(camera)

		if parent.gui.player.name == player.name then
			follow.enabled = false
			teleport.enabled = false
        end
        
		kick = frame.add{name = "player_list_entry_kick", type = "button", caption = "K", tooltip = "Kick player"}
		ban = frame.add{name = "player_list_entry_ban", type = "button", caption = "B", tooltip = "Ban player"}
	else
		local serverlabel = frame.add{name = "player_list_entry_server", type = "label", caption = server, tooltip = server}
		serverlabel.style.width = 80
		local connect = frame.add{name = "player_list_entry_connect", type = "button", caption = "Connect", tooltip = "Connect to other server"}
		if global.cluster_admin_players.servers[server] == nil then
			connect.enabled = false
		end
		connect.style.height = 20
		connect.style.width = 68
		connect.style.padding = 0
		kick = frame.add{name = "player_list_entry_remote_kick", type = "button", caption = "K", tooltip = "Kick player"}
		ban = frame.add{name = "player_list_entry_remote_ban", type = "button", caption = "B", tooltip = "Ban player"}
	end
	if player.admin then
		playername.style.font_color = {128, 206, 240}
		ban.enabled = false
    end
    
    style_small(kick)
    style_small(ban)
end

local players_module = players_module or {}

-- Returns (and creates if needed) the main (button) menu.
function players_module.get_menu(cluster_admin, p)
    local ff = cluster_admin.get_frame_flow(p)
    local pane = ff.players_pane

    if (pane ~= nil 
        and pane.valid
        and pane.search_frame ~= nil
        and pane.search_frame.valid
        and pane.search_frame.search_frame_flow ~= nil
        and pane.search_frame.search_frame_flow.valid
        and pane.search_frame.search_frame_flow.search_label ~= nil
        and pane.search_frame.search_frame_flow.search_label.valid
        and pane.search_frame.search_frame_flow.search_field ~= nil
        and pane.search_frame.search_frame_flow.search_field.valid
        and pane.search_frame.search_frame_flow.search_refresh ~= nil
        and pane.search_frame.search_frame_flow.search_refresh.valid
        and pane.player_list_frame ~= nil
        and pane.player_list_frame.valid
        and pane.player_list_frame.players_list_scroll ~= nil
        and pane.player_list_frame.players_list_scroll.valid
        and pane.player_list_frame.players_list_scroll.player_list_flow ~= nil
        and pane.player_list_frame.players_list_scroll.player_list_flow.valid
    ) then
        return pane
	else
		if pane ~= nil then
			pane.destroy()
		end
        pane = ff.add {name = "players_pane", type = "frame", caption = "Player manager", direction = "vertical"}
        pane.style.height = 298
		pane.style.use_header_filler = false
		pane.visible = false
        create_search_frame(pane)
        create_player_list_frame(pane)
        return pane
    end
end

function players_module.get_player_list(cluster_admin, p)
    local pane = players_module.get_menu(cluster_admin, p)
    return pane.player_list_frame.players_list_scroll.player_list_flow
end

function players_module.update_menu(cluster_admin, p)
    local pane = players_module.get_menu(cluster_admin, p)
    players_module.update_list(cluster_admin, p)
end

function players_module.update_list(cluster_admin, p)
    local pane = players_module.get_menu(cluster_admin, p)
    local list = pane.player_list_frame.players_list_scroll.player_list_flow
	local filter = pane.search_frame.search_frame_flow.search_field.text
    list.clear()
    
	for k, player in pairs(game.connected_players) do
		if filter ~= "" then
			if string.find(string.lower(player.name), string.lower(filter)) ~= nil then
				add_player_entry(list, player, "local")
			end
		else
			add_player_entry(list, player, "local")
		end
    end

    -- TODO
	for l, remote in pairs({}) do
		if filter ~= "" then
			if string.find(string.lower(remote.n), string.lower(filter)) ~= nil then
				add_player_entry(list, {name=remote.n, admin=remote.a}, remote.s)
			end
		else
			add_player_entry(list, {name=remote.n, admin=remote.a}, remote.s)
		end
    end
end

function players_module.on_gui_click(cluster_admin, e, p)
	if e.name == "search_refresh" and e.parent.name == "search_frame_flow" then
		players_module.update_list(cluster_admin, p)
	elseif e.parent.parent ~= nil and e.parent.parent.name == "player_list_flow" then
		local target_name = string.gsub(e.parent.name, "player_list_entry_", "")
		if target_name ~= nil and target_name ~= "" then
			local target = game.players[target_name]
			if target ~= nil and target.connected then
				if e.name == "player_list_entry_teleport" then
					p.teleport(target.surface.find_non_colliding_position("character", target.position, 0, 1))
				elseif e.name == "player_list_entry_follow" then
					p.print("follow")
					-- if cluster_admin_submodule_state("cluster_admin_spectate_follow") then
					-- 	cluster_admin_spectate_set_spectator(p)
					-- 	cluster_admin_spectate_set_follow_target(p, target)
					-- end
				elseif e.name == "player_list_entry_camera" then
					cluster_admin.camera.create(cluster_admin, p, target)
				elseif e.name == "player_list_entry_kick" then
					game.kick_player(target.name)
				elseif e.name == "player_list_entry_ban" then
					game.ban_player(target.name)
					p.print("You just banned " ..target.name)
					-- print("[CLUSTER_ADMIN] [BAN] " .. target_name .. " [END]")
				end
			else
				if e.name == "player_list_entry_connect" then
					p.print("Connect to remote server")
					-- target = global.cluster_admin_players.remote[target_name]
					-- if target ~= nil then
					-- 	local server = global.cluster_admin_players.servers[target.s]
					-- 	if server ~= nil then
					-- 		p.connect_to_server{address=server.ip .. ":" .. server.port, name=server.name}
					-- 	else
					-- 		p.print("Couldn't find player or server info")
					-- 	end
					-- end
				elseif e.name == "player_list_entry_remote_kick" then
					print("[CLUSTER_ADMIN] [KICK] " .. target_name .. " [END]")
				elseif e.name == "player_list_entry_remote_ban" then
					print("[CLUSTER_ADMIN] [BAN] " .. target_name .. " [END]")
				else
					game.print(e.name)
				end
			end
		end
	end
end

function players_module.on_gui_value_changed(cluster_admin, e, p)
	if e.name == "search_field" and e.parent.name == "search_frame_flow" then
		players_module.update_list(cluster_admin, p)
	end
end

return players_module