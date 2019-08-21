-- cluster_admin_compensate sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord)
-- This sub-module is a addon to the cluster_admin module, it allows admins to "compensate" their time spent as an admin

--
--	FUNCTIONS
--
function cluster_admin_compensate_enable()
	cluster_admin_add_submodule("cluster_admin_compensate")
	if not global.cluster_admin_compensate.enabled then
		global.cluster_admin_compensate.enabled = true
		for i, p in pairs(game.connected_players) do
			if p.admin then
				local button = cluster_admin_add_button(p.name, "compensate")
				button.caption = "Compensation"
				global.cluster_admin_compensate.players[p.name] = false
			end
		end
	else 
		return false
	end
end

function cluster_admin_compensate_disable()
	cluster_admin_remove_submodule("cluster_admin_compensate")
	if global.cluster_admin_compensate.enabled then
		global.cluster_admin_compensate.enabled = false
		for i, p in pairs(game.connected_players) do
			if p.admin then
				cluster_admin_remove_button(p.name, "compensate")
			end
		end
	else 
		return false
	end
end

function cluster_admin_compensate_player(p)
	if p.admin and p.character ~= nil then
		if global.cluster_admin_compensate.players[p.name] then
			p["character_build_distance_bonus"] = 5
			p["character_item_drop_distance_bonus"] = 5
			p["character_reach_distance_bonus"] = 5
			p["character_resource_reach_distance_bonus"] = 5
			p["character_crafting_speed_modifier"] = 0.5
			p["character_mining_speed_modifier"] = 1
			p["character_running_speed_modifier"] = 0.5
			p.character.destructible = true
			return true
		else
			p["character_build_distance_bonus"] = 0
			p["character_item_drop_distance_bonus"] = 0
			p["character_reach_distance_bonus"] = 0
			p["character_resource_reach_distance_bonus"] = 0
			p["character_crafting_speed_modifier"] = 0
			p["character_mining_speed_modifier"] = 0
			p["character_running_speed_modifier"] = 0
			p.character.destructible = true
		end
	end
	return false
end

function cluster_admin_compensate_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if (e and e.parent) ~= nil then
		if p.admin then
			if e.name == "cluster_admin_menu_button_compensate" then
				if global.cluster_admin_compensate.enabled then
					local gcacp = global.cluster_admin_compensate.players
					gcacp[p.name] = not gcacp[p.name]
					cluster_admin_compensate_player(p)
					local button = cluster_admin_add_button(p.name, "compensate")
					if gcacp[p.name] then
						button.style = "highlighted_tool_button"
					else
						button.style = "button"
					end
					if cluster_admin_submodule_state("cluster_admin_boost") then
						local bf = cluster_admin_get_flow(p)
						if bf.cluster_admin_boost_pane ~= nil then
							bf.cluster_admin_boost_pane.visible = false
						end
						cluster_admin_boost_update_menu_button(p)
						local b = cluster_admin_boost_update_menu_button(p)
						if b ~= nil then
							b.enabled = not gcacp[p.name]
						end
					end
				else
					cluster_admin_remove_button(p.name, "cluster_admin_compensate_button")
					p.print("Sorry, this sub-module has just been disabled")
				end
			end
		end
	end
end

function cluster_admin_compensate_on_player_joined_game(event)
	local p = game.players[event.player_index]
	if p.admin then
		if global.cluster_admin_compensate.enabled then
			local button = cluster_admin_add_button(p.name, "compensate")
			button.caption = "Compensation"
		else 
			cluster_admin_remove_button(p.name, "compensate")
		end
	end
end

function cluster_admin_compensate_on_init()
	global.cluster_admin_compensate = global.cluster_admin_compensate or {}
	global.cluster_admin_compensate.players = global.cluster_admin_compensate.players or {}
	global.cluster_admin_compensate.enabled = global.cluster_admin_compensate.enabled or true
	cluster_admin_compensate_enable()
end
