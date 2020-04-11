local boost_module = boost_module or {}

-- Returns (and creates if needed) the boost menu
function boost_module.get_menu(cluster_admin, p)
    local ff = cluster_admin.get_frame_flow(p)
    local menu = ff.boost_menu
    -- validate the current menu
    if (menu ~= nil 
        and menu.valid
        and menu.boost_flow ~= nil
        and menu.boost_flow.valid) then
        return menu.boost_flow
    else
        -- Create the outer pane.
        menu = ff.add {type = "frame", name = "boost_menu", caption = "Character Menu", direction = "vertical"}
        menu.style.use_header_filler = false
        menu.visible = false

        local flow = menu.add {type = "flow", name = "boost_flow", direction = "vertical"}
        flow.style.vertical_spacing = 0
        return flow
    end
end

function boost_module.update_menu(cluster_admin, p)
    local menu = cluster_admin.boost.get_menu(cluster_admin, p)
    menu.clear()
    local function create_button(name, caption, active)
        local button = menu.add {type = "button", name = name, caption = caption}
        if active then
            button.style = "highlighted_tool_button"
        end
        button.style.width = 150
        button.style.height = 28
        button.style.horizontal_align = "center"

        return button
    end

    local pickup_active = (
        p["character_loot_pickup_distance_bonus"] == 5 
        and p["character_item_pickup_distance_bonus"] == 5)
    local mining_active = p["character_mining_speed_modifier"] == 150
    local crafting_active = p["character_crafting_speed_modifier"] == 60
    local reach_active = (
        p["character_build_distance_bonus"] == 125
        and p["character_item_drop_distance_bonus"] == 125
        and p["character_reach_distance_bonus"] == 125
        and p["character_resource_reach_distance_bonus"] == 125)
    local invincible_active = false
    if p.character ~= nil then
        invincible_active = not p.character.destructible
    end

    local pickup_button = create_button("pickup_button", "Pickup Distance", pickup_active)
    local mining_button = create_button("mining_button", "Mining Speed", mining_active)
    local crafting_button = create_button("crafting_button", "Crafting Speed", crafting_active)
    local reach_button = create_button("reach_button", "Reach Distance", reach_active)
    local invincible_button = create_button("invincible_button", "Invincible", invincible_active)
    
    local walking_flow = menu.add {type="flow", name = "walking_flow", direction = "horizontal"}
    walking_flow.style.horizontal_spacing = 0
    walking_flow.style.top_padding = 4
    walking_flow.style.bottom_padding = 4
    
    local walking_label = walking_flow.add {type="label", name = "walking_label", caption = "Running speed"}
    walking_label.style.width = 130

    local walking_reset_button = walking_flow.add {type = "button", name = "walking_reset_button", caption = "R"}
    walking_reset_button.style = "red_button"
    walking_reset_button.style.width = 20
    walking_reset_button.style.height = 20
    walking_reset_button.style.padding = 0
    
    local walking_slider = menu.add {type = "slider", name = "walking_slider", minimum_value = -0.95, maximum_value = 10, value_step = 0.25, value = p["character_running_speed_modifier"]}
    walking_slider.style.width = 150
end

function boost_module.handle_button(cluster_admin, button, p)
    if button.name == "walking_slider" then return end
    if button.name == "pickup_button" then
        local pickup_active = (
        p["character_loot_pickup_distance_bonus"] == 5 
        and p["character_item_pickup_distance_bonus"] == 5)
        if pickup_active then
            p["character_loot_pickup_distance_bonus"] = 0
		    p["character_item_pickup_distance_bonus"] = 0
        else
            p["character_loot_pickup_distance_bonus"] = 5
		    p["character_item_pickup_distance_bonus"] = 5
        end
    elseif button.name == "mining_button" then
        local mining_active = p["character_mining_speed_modifier"] == 150
        if mining_active then
            p["character_mining_speed_modifier"] = 0
        else
            p["character_mining_speed_modifier"] = 150
        end
    elseif button.name == "crafting_button" then
        local crafting_active = p["character_crafting_speed_modifier"] == 60
        if crafting_active then
            p["character_crafting_speed_modifier"] = 0
        else
            p["character_crafting_speed_modifier"] = 60
        end
    elseif button.name == "reach_button" then
        local reach_active = (
        p["character_build_distance_bonus"] == 125
        and p["character_item_drop_distance_bonus"] == 125
        and p["character_reach_distance_bonus"] == 125
        and p["character_resource_reach_distance_bonus"] == 125)
        if reach_active then
            p["character_build_distance_bonus"] = 0
            p["character_item_drop_distance_bonus"] = 0
            p["character_reach_distance_bonus"] = 0
            p["character_resource_reach_distance_bonus"] = 0
        else
            p["character_build_distance_bonus"] = 125
            p["character_item_drop_distance_bonus"] = 125
            p["character_reach_distance_bonus"] = 125
            p["character_resource_reach_distance_bonus"] = 125
        end
    elseif button.name == "invincible_button" then
        if p.character ~= nil then
            p.character.destructible = not p.character.destructible
        end
    end
    cluster_admin.boost.update_menu(cluster_admin, p)
end

function boost_module.on_gui_click(cluster_admin, e, p)
    if e.name == "walking_reset_button" then
        p["character_running_speed_modifier"] = 0
        cluster_admin.boost.update_menu(cluster_admin, p)
    elseif e.parent.name == "boost_flow" then
        cluster_admin.boost.handle_button(cluster_admin, e, p)
    end
end

function boost_module.on_gui_value_changed(cluster_admin, e, p)
    if e.name == "walking_slider" and e.parent.name == "boost_flow" then
        p["character_running_speed_modifier"] = e.slider_value
    end
end

return boost_module