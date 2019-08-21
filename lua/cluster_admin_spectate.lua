-- cluster_admin_spectate sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord)
-- This sub-module is a addon to the cluster_admin module, it allows sub-modules set the player to spectator mode or follow players

--
--	FUNCTIONS
--

function cluster_admin_spectate_enable(mod)
	if mod == "module" then
		global.cluster_admin_spectate.enabled = true
		cluster_admin_add_submodule("cluster_admin_spectate")
		if global.cluster_admin_spectate.follow_enabled == true then
			cluster_admin_add_submodule("cluster_admin_spectate_follow")
		end
		if global.cluster_admin_spectate.spectate_enabled == true then
			cluster_admin_add_submodule("cluster_admin_spectate_spectate")
		end
		for i, p in pairs(game.connected_players) do
			cluster_admin_spectate_update_menu_button(p)
		end
	elseif mod == "follow" then
		global.cluster_admin_spectate.follow_enabled = true
		cluster_admin_add_submodule("cluster_admin_spectate_follow")
	elseif mod == "spectate" then
		global.cluster_admin_spectate.spectate_enabled = true
		cluster_admin_add_submodule("cluster_admin_spectate_spectate")
	end
end

function cluster_admin_spectate_disable(mod)
	if mod == "module" then
		for admin, trgt in pairs(global.cluster_admin_spectate.follow_target) do
			cluster_admin_spectate_stop_follow(game.players[admin])
		end
		for admin, bool in pairs(global.cluster_admin_spectate.player_spectator_state) do
			if bool then
				cluster_admin_spectate_set_normal(game.players[admin])
			end
		end
		global.cluster_admin_spectate.enabled = false
		for i, p in pairs(game.connected_players) do
			cluster_admin_spectate_update_menu_button(p)
		end
		cluster_admin_remove_submodule("cluster_admin_spectate")
		cluster_admin_remove_submodule("cluster_admin_spectate_follow")
		cluster_admin_remove_submodule("cluster_admin_spectate_spectate")
	elseif mod == "follow" then
		for admin, trgt in pairs(global.cluster_admin_spectate.follow_target) do
			cluster_admin_spectate_stop_follow(game.players[admin])
		end
		cluster_admin_remove_submodule("cluster_admin_spectate_follow")
		global.cluster_admin_spectate.follow_enabled = false
	elseif mod == "spectate" then
		for admin, bool in pairs(global.cluster_admin_spectate.player_spectator_state) do
			if bool then
				cluster_admin_spectate_set_normal(game.players[admin])
			end
		end
		cluster_admin_remove_submodule("cluster_admin_spectate_spectate")
		global.cluster_admin_spectate.spectate_enabled = false
	end
end


function cluster_admin_spectate_set_follow_target(p, target)
	if global.cluster_admin_spectate.follow_enabled and global.cluster_admin_spectate.enabled then
		if p.connected and target.connected and p.admin then
			if global.cluster_admin_spectate.follow_target[p.name] == target.name then
				cluster_admin_spectate_stop_follow(p)
			else
				global.cluster_admin_spectate.follow_target[p.name] = target.name
				p.print("You are now following " .. target.name)
				cluster_admin_spectate_gui_changed(p)
			end
		end
	else
		p.print("Following is disabled")
	end
end

function cluster_admin_spectate_stop_follow(p)
	global.cluster_admin_spectate.follow_target[p.name] = nil
	cluster_admin_spectate_gui_changed(p)
	p.print("You are no longer following")
end


function cluster_admin_spectate_update_position(event)
	if global.cluster_admin_spectate.follow_enabled and global.cluster_admin_spectate.enabled then
		for admin, target in pairs(global.cluster_admin_spectate.follow_target) do
			if target then
				local player = game.players[admin]
				local follow = game.players[target]
				if player and follow then
					player.teleport(follow.surface.find_non_colliding_position("character", follow.position, 0, 1))
					if follow.selected ~= nil then
						player.create_local_flying_text{text=follow.name, position=follow.selected.position, time_to_live=5}
					end
				end
			end
		end
	end
end

function cluster_admin_spectate_set_normal(p)
	if global.cluster_admin_spectate.player_spectator_state[p.name] == true then
		p.cheat_mode = false
		if p.character == nil then
			if global.cluster_admin_spectate.player_spectator_character[p.name] and global.cluster_admin_spectate.player_spectator_character[p.name].valid then
				if not teleport then p.print("Returning you to your character.") end
				p.set_controller { type = defines.controllers.character, character = global.cluster_admin_spectate.player_spectator_character[p.name] }
				p.character.destructible = true
			else
				p.print("Character missing, will create new character at spawn.")
				p.set_controller { type = defines.controllers.character, character = p.surface.create_entity { name = "player", position = { 0, 0 }, force = global.cluster_admin_spectate.player_spectator_force[p.name] } }
				p.insert { name = "pistol", count = 1 }
				p.insert { name = "firearm-magazine", count = 10 }
			end
			--restore character logistics slots due to bug in base game that clears them after returning from spectator mode
			for slot=1, p.character.request_slot_count do
				if global.cluster_admin_spectate.player_spectator_logistics_slots[p.name][slot] then
					p.character.set_request_slot(global.cluster_admin_spectate.player_spectator_logistics_slots[p.name][slot], slot)
				end
			end
		end
		if cluster_admin_submodule_state("cluster_admin_boost") then
			if cluster_admin_submodule_state("cluster_admin_compensate") then
				if not cluster_admin_compensate_player(p) then
					local b = cluster_admin_boost_update_menu_button(p)
					if b ~= nil then
						b.enabled = true
					end
					cluster_admin_boost_apply_bonus(p)
				end
				local b = cluster_admin_add_button(p.name, "compensate")
				if b ~= nil then
					b.enabled = true
				end
			else 
				local b = cluster_admin_boost_update_menu_button(p)
				if b ~= nil then
					b.enabled = true
				end
				cluster_admin_boost_apply_bonus(p)
			end
		end
		if cluster_admin_submodule_state("cluster_admin_compensate") then
			cluster_admin_compensate_player(p)
			local b = cluster_admin_add_button(p.name, "compensate")
			if b ~= nil then
				b.enabled = true
			end
		end
		p.force = game.forces[global.cluster_admin_spectate.player_spectator_force[p.name].name]
		global.cluster_admin_spectate.player_spectator_state[p.name] = false
		cluster_admin_spectate_gui_changed(p)
	end
end

function cluster_admin_spectate_set_normal_teleport(p)
	local pos = p.position
	cluster_admin_spectate_set_normal(p)
	if global.cluster_admin_spectate.player_spectator_state[p.name] == false then
		p.print("Teleporting you to the location you are currently looking at.")
		p.teleport(p.surface.find_non_colliding_position("character", pos, 0, 1))
	end
end

function cluster_admin_spectate_set_spectator(p)
	if global.cluster_admin_spectate.spectate_enabled and global.cluster_admin_spectate.enabled then
		if global.cluster_admin_spectate.player_spectator_state[p.name] ~= true then
			if p.character then
				p.character.destructible = false
				p.walking_state = { walking = false, direction = defines.direction.north }
				global.cluster_admin_spectate.player_spectator_character[p.name] = p.character
				--store character logistics slots due to an apparent bug in the base game that discards them when returning from spectate
				global.cluster_admin_spectate.player_spectator_logistics_slots[p.name] = {}
				for slot=1, p.character.request_slot_count do
					global.cluster_admin_spectate.player_spectator_logistics_slots[p.name][slot] = p.character.get_request_slot(slot)
				end
				p.set_controller { type = defines.controllers.god }
				
			end
			global.cluster_admin_spectate.player_spectator_force[p.name] = p.force
			p.cheat_mode = true
			if game.forces.Admins ~= nil then
				p.force = game.forces["Admins"]
			end
			global.cluster_admin_spectate.player_spectator_state[p.name] = true
			p.print("You are now a spectator")
			if cluster_admin_submodule_state("cluster_admin_boost") then
				local bf = cluster_admin_get_flow(p)
				if bf.cluster_admin_boost_pane ~= nil then
					bf.cluster_admin_boost_pane.visible = false
				end
				local b = cluster_admin_boost_update_menu_button(p)
				if b ~= nil then
					b.enabled = false
				end
			end
			if cluster_admin_submodule_state("cluster_admin_compensate") then
				local b = cluster_admin_add_button(p.name, "compensate")
				if b ~= nil then
					b.enabled = false
				end
			end
			cluster_admin_spectate_gui_changed(p)
		end
	else
		p.print("Spectating is disabled")
	end
end

function cluster_admin_spectate_get_state(p)
	if global.cluster_admin_spectate.player_spectator_state[p.name] == true and global.cluster_admin_spectate.spectate_enabled and global.cluster_admin_spectate.enabled then
		return true
	else
		return false
	end
end

function cluster_admin_spectate_connected_players_changed(event)
	if global.cluster_admin_spectate.follow_enabled and global.cluster_admin_spectate.enabled then
		for admin, target in pairs(global.cluster_admin_spectate.follow_target) do
			local p = game.players[admin]
			local t = game.players[target]
			if p.index == event.player_index or t.index == event.player_index then
				cluster_admin_spectate_stop_follow(p)
				if t.index == event.player_index then
					p.print("Follow target disconnected.")
				end
			end
		end
	end
end

function cluster_admin_spectate_update_menu_button(p)
	if p.admin then
		if global.cluster_admin_spectate.enabled then
			local bf = cluster_admin_get_flow(p)
			local button = cluster_admin_add_button(p.name, "spectate_button")
			button.caption = "Spectate"
			if bf.cluster_admin_spectate_pane ~= nil then
				local pane = bf.cluster_admin_spectate_pane
				if pane.visible then
					button.style = "highlighted_tool_button"
				else
					button.style = "button"
				end
				button.style.width = 144
				button.style.height = 28
			end
		else 
			cluster_admin_remove_button(p.name, "spectate_button")
		end
	end
end

function cluster_admin_spectate_gui_changed(p)
	if p.admin then
		local bf = cluster_admin_get_flow(p)
		if global.cluster_admin_spectate.enabled then
			local st
			if bf.cluster_admin_spectate_pane ~= nil then
				st = bf.cluster_admin_spectate_pane
				st.clear()
			else
				st = bf.add {type = "frame", name = "cluster_admin_spectate_pane", caption = "Specate Menu", direction = "vertical"}
				st.style.use_header_filler = false
			end
			local sm = st
			if global.cluster_admin_spectate.player_spectator_state[p.name] == true then
				local srb = sm.add {type = "button", name = "cluster_admin_spectate_return_button", caption = "Return"}
				local stb = sm.add {type = "button", name = "cluster_admin_spectate_teleport_button", caption = "Teleport"}
				srb.style.width = 156
				srb.style.height = 28
				stb.style.width = 156
				if global.cluster_admin_spectate.follow_target[p.name] ~= nil then
					srb.enabled = false
					stb.enabled = false
				end
			else
				local ssb = sm.add {type = "button", name = "cluster_admin_spectate_spectate_button", caption = "Start spectating"}
				ssb.style = "working_weapon_button"
				ssb.style.width = 156
				ssb.style.height = 28
				ssb.style.horizontal_align = "center"
			end
			if global.cluster_admin_spectate.follow_target[p.name] ~= nil then
				local labeltext = "You are spectating: " .. game.players[global.cluster_admin_spectate.follow_target[p.name]].name
				local sfl = sm.add {type = "label", name = "cluster_admin_spectate_follow_label", caption = labeltext}
				sfl.style.maximal_width = 150
				sfl.style.single_line = false
				local ssfb = sm.add {type = "button", name = "cluster_admin_spectate_stop_follow_button", caption = "Stop following"}
				ssfb.style = "red_button"
				ssfb.style.height = 28
				ssfb.style.width = 156
				ssfb.style.horizontal_align = "center"
			end
		else
			if bf.cluster_admin_spectate_pane ~= nil then
				bf.cluster_admin_spectate_pane.destroy()
			end
		end
	end
end
	
function cluster_admin_spectate_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then
		if e.name == "cluster_admin_menu_button_spectate_button" then
			local bf = cluster_admin_get_flow(p)
			cluster_admin_spectate_gui_changed(p)
			if bf.cluster_admin_spectate_pane ~= nil then
				local pane = bf.cluster_admin_spectate_pane
				pane.visible = not pane.visible
			end
			cluster_admin_spectate_update_menu_button(p)
		elseif e.name == "cluster_admin_spectate_stop_follow_button" then
			cluster_admin_spectate_stop_follow(p)
		elseif e.name == "cluster_admin_spectate_spectate_button" then
			cluster_admin_spectate_set_spectator(p)
		elseif e.name == "cluster_admin_spectate_teleport_button" then
			cluster_admin_spectate_set_normal_teleport(p)
		elseif e.name == "cluster_admin_spectate_return_button" then
			cluster_admin_spectate_set_normal(p)
		end
	end
end

function cluster_admin_spectate_on_player_joined(event)
	cluster_admin_spectate_connected_players_changed(event)
	local p = game.players[event.player_index]
	cluster_admin_spectate_update_menu_button(p)
end

function cluster_admin_spectate_on_init(event)
	global.cluster_admin_spectate = global.cluster_admin_spectate or {}
	global.cluster_admin_spectate.enabled = true
	global.cluster_admin_spectate.follow_enabled = true
	global.cluster_admin_spectate.spectate_enabled = true
	global.cluster_admin_spectate.follow_target = global.cluster_admin_spectate.follow_target or {}
	global.cluster_admin_spectate.player_spectator_state = global.cluster_admin_spectate.player_spectator_state or {}
	global.cluster_admin_spectate.player_spectator_force = global.cluster_admin_spectate.player_spectator_force or {}
	global.cluster_admin_spectate.player_spectator_character = global.cluster_admin_spectate.player_spectator_character or {}
	global.cluster_admin_spectate.player_spectator_logistics_slots = global.cluster_admin_spectate.player_spectator_logistics_slots or {}
	if(global.cluster_admin_spectate.enabled) then
		cluster_admin_add_submodule("cluster_admin_spectate")
		if global.cluster_admin_spectate.follow_enabled then
			cluster_admin_add_submodule("cluster_admin_spectate_follow")			
		end
		if global.cluster_admin_spectate.spectate_enabled then
			cluster_admin_add_submodule("cluster_admin_spectate_spectate")
		end
	else
		cluster_admin_remove_submodule("cluster_admin_spectate")
		cluster_admin_remove_submodule("cluster_admin_spectate_follow")
		cluster_admin_remove_submodule("cluster_admin_spectate_spectate")
	end
end