-- cluster_admin_boost sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord)
-- This sub-module is a addon to the cluster_admin module, it allows admins to boost their character

--
--	PLAN
--	
--	This module is going to replace the character menu in the old admin tools
--	Admins will be able to increase their reach, speed, crafting, mining and be invincible
--	The gui will present a list of buttons to toggle each of the above
--


--
--	FUNCTIONS
--

function cluster_admin_boost_enable(mod)
	global.cluster_admin_boost.enabled = true
	cluster_admin_add_submodule("cluster_admin_boost")
	for i, p in pairs(game.connected_players) do
		cluster_admin_boost_update_menu_button(p)
	end
end

function cluster_admin_boost_disable(mod)
	global.cluster_admin_boost.enabled = false
	for i, p in pairs(game.connected_players) do
		cluster_admin_boost_update_menu_button(p)
	end
	cluster_admin_remove_submodule("cluster_admin_boost")
end


function cluster_admin_boost_update_menu_button(p)
	if p.admin then
		if global.cluster_admin_boost.enabled then
			local bf = cluster_admin_get_flow(p)
			local button = cluster_admin_add_button(p.name, "boost")
			button.caption = "Boost character"
			if bf.cluster_admin_boost_pane ~= nil then
				local pane = bf.cluster_admin_boost_pane
				if pane.visible then
					button.style = "highlighted_tool_button"
				else
					button.style = "button"
				end
				button.style.width = 144
				button.style.height = 28
				return button
			end
		else 
			cluster_admin_remove_button(p.name, "boost")
		end
	end
end

function cluster_admin_boost_gui_changed(p)
	if p.admin then
		local bf = cluster_admin_get_flow(p)
		if global.cluster_admin_boost.enabled then
			local mabpa
			if bf.cluster_admin_boost_pane ~= nil then
				mabpa = bf.cluster_admin_boost_pane
				mabpa.clear()
			else
				mabpa = bf.add {type = "frame", name = "cluster_admin_boost_pane", caption = "Character Menu", direction = "vertical"}
				mabpa.style.use_header_filler = false
			end
			local mabp = mabpa.add {type = "flow", name = "cluster_admin_boost_flow", direction = "vertical"}
			mabp.style.vertical_spacing = 0
			
			local pbs = global.cluster_admin_boost.bonus_state[p.name]
			
			local b = mabp.add {type = "button", name = "cluster_admin_boost_pickup_button", caption = "Pickup Distance"}
			if pbs.pickup then
				b.style = "highlighted_tool_button"
			end
			b.style.width = 150
			b.style.height = 28
			b.style.horizontal_align = "center"
			
			local b = mabp.add {type = "button", name = "cluster_admin_boost_mining_button", caption = "Mining Speed"}
			if pbs.mining then
				b.style = "highlighted_tool_button"
			end
			b.style.width = 150
			b.style.height = 28
			b.style.horizontal_align = "center"
			
			local b = mabp.add {type = "button", name = "cluster_admin_boost_crafting_button", caption = "Crafting Speed"}
			if pbs.crafting then
				b.style = "highlighted_tool_button"
			end
			b.style.width = 150
			b.style.height = 28
			b.style.horizontal_align = "center"
			
			local b = mabp.add {type = "button", name = "cluster_admin_boost_reach_button", caption = "Reach Distance"}
			if pbs.reach then
				b.style = "highlighted_tool_button"
			end
			b.style.width = 150
			b.style.height = 28
			b.style.horizontal_align = "center"
			
			local b = mabp.add {type = "button", name = "cluster_admin_boost_invincible_button", caption = "Invincible"}
			if pbs.invincible then
				b.style = "highlighted_tool_button"
			end
			b.style.width = 150
			b.style.height = 28
			b.style.horizontal_align = "center"
			
			local flow = mabp.add {type="flow", name = "cluster_admin_boost_walking_flow", direction = "horizontal"}
			flow.style.horizontal_spacing = 0
			flow.style.top_padding = 4
			flow.style.bottom_padding = 4
			
			local l = flow.add {type="label", name = "cluster_admin_boost_walking_label", caption = "Running speed"}
			l.style.width = 130

			local b = flow.add {type = "button", name = "cluster_admin_boost_walking_reset", caption = "R"}
			b.style = "red_button"
			b.style.width = 20
			b.style.height = 20
			b.style.padding = 0
			
			local s = mabp.add {type = "slider", name = "cluster_admin_boost_walking_slider", minimum_value = -0.95, maximum_value = 10, value = pbs.walking}
			s.style.width = 150
			
		else
			if bf.cluster_admin_boost_pane ~= nil then
				bf.cluster_admin_boost_pane.destroy()
			end
		end
	end
	cluster_admin_boost_update_menu_button(p)
end

function cluster_admin_boost_apply_bonus(p)
	local pbs = global.cluster_admin_boost.bonus_state[p.name]
	
	if pbs.pickup then
		p["character_loot_pickup_distance_bonus"] = 5
		p["character_item_pickup_distance_bonus"] = 5
	else
		p["character_item_pickup_distance_bonus"] = 0
		p["character_loot_pickup_distance_bonus"] = 0
	end
	
	if pbs.mining then
		p["character_mining_speed_modifier"] = 150
	else
		p["character_mining_speed_modifier"] = 0
	end
	
	if pbs.crafting then
		p["character_crafting_speed_modifier"] = 60
	else
		p["character_crafting_speed_modifier"] = 0
	end
	
	if pbs.reach then
		p["character_build_distance_bonus"] = 125
		p["character_item_drop_distance_bonus"] = 125
		p["character_reach_distance_bonus"] = 125
		p["character_resource_reach_distance_bonus"] = 125
	else
		p["character_build_distance_bonus"] = 0
		p["character_item_drop_distance_bonus"] = 0
		p["character_reach_distance_bonus"] = 0
		p["character_resource_reach_distance_bonus"] = 0
	end

	if p.character ~= nil then
		if pbs.invincible then
			p.character.destructible = false
		else
			p.character.destructible = true
		end
	end
	
	p["character_running_speed_modifier"] = pbs.walking
end

function cluster_admin_boost_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then
		if e.name == "cluster_admin_menu_button_boost" then
			local bf = cluster_admin_get_flow(p)
			if bf.cluster_admin_boost_pane ~= nil then
				local pane = bf.cluster_admin_boost_pane
				pane.visible = not pane.visible
			end
			cluster_admin_boost_update_menu_button(p)
		elseif e.parent ~= nil and (e.parent.name == "cluster_admin_boost_flow" or e.parent.name == "cluster_admin_boost_walking_flow") then
			local pbs = global.cluster_admin_boost.bonus_state[p.name]

			if e.name == "cluster_admin_boost_pickup_button" then
				if pbs.pickup then
					pbs.pickup = false
					e.style = "button"
				else
					pbs.pickup = true
					e.style = "highlighted_tool_button"
				end
			elseif e.name == "cluster_admin_boost_mining_button" then
				if pbs.mining then
					pbs.mining = false
					e.style = "button"
				else
					pbs.mining = true
					e.style = "highlighted_tool_button"
				end
			elseif e.name == "cluster_admin_boost_crafting_button" then
				if pbs.crafting then
					pbs.crafting = false
					e.style = "button"
				else
					pbs.crafting = true
					e.style = "highlighted_tool_button"
				end
			elseif e.name == "cluster_admin_boost_reach_button" then
				if pbs.reach then
					pbs.reach = false
					e.style = "button"
				else
					pbs.reach = true
					e.style = "highlighted_tool_button"
				end
			elseif e.name == "cluster_admin_boost_invincible_button" then
				if pbs.invincible then
					pbs.invincible = false
					e.style = "button"
				else
					pbs.invincible = true
					e.style = "highlighted_tool_button"
				end
			elseif e.name == "cluster_admin_boost_walking_reset" then
				pbs.walking = 0
				e.parent.parent.cluster_admin_boost_walking_slider.slider_value = pbs.walking
			end
			cluster_admin_boost_apply_bonus(p)
		end
	end
end

function cluster_admin_camera_on_gui_value_changed(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if (e and e.parent) ~= nil then
		if e.name == "cluster_admin_boost_walking_slider" then
			global.cluster_admin_boost.bonus_state[p.name].walking = e.slider_value
			cluster_admin_boost_apply_bonus(p)
		end
	end
end

function cluster_admin_boost_on_player_joined_game(event)
	local p = game.players[event.player_index]
	if p.admin then
		global.cluster_admin_boost.bonus_state[p.name] = global.cluster_admin_boost.bonus_state[p.name] or {pickup = false, mining = false, crafting = false, reach = false, invincible = false, walking = 0}
		cluster_admin_boost_gui_changed(p)
	end
end

function cluster_admin_boost_init()
	global.cluster_admin_boost = global.cluster_admin_boost or {}
	global.cluster_admin_boost.enabled = global.cluster_admin_boost.enabled or true
	global.cluster_admin_boost.bonus_state = global.cluster_admin_boost.bonus_state or {}
	
	if(global.cluster_admin_boost.enabled) then
		cluster_admin_add_submodule("cluster_admin_boost")
	else
		cluster_admin_remove_submodule("cluster_admin_boost")
	end
end

