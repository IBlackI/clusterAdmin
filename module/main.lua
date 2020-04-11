local clusterio_api = require("modules/clusterio/api")
local cluster_admin = cluster_admin or {}

--
--
--  GENERAL
--
--

-- Returns (and creates if needed) the flow which all panes for this module get placed in.
function cluster_admin.get_frame_flow(p)
    local flow = mod_gui.get_frame_flow(p).cluster_admin_flow
    if flow ~= nil and flow.valid then
        return flow
    else 
        local mgff = mod_gui.get_frame_flow(p)
        flow = mgff.add {type = "flow", name = "cluster_admin_flow", direction = "horizontal"}
        flow.visible = (cluster_admin.get_toggle_button(p).tooltip == "Close Admin Menu")
        return flow
    end
end

-- Returns (and creates if needed) the main (button) menu.
function cluster_admin.get_toggle_button(p)
    local bf = mod_gui.get_button_flow(p)
    local button = bf.cluster_admin_toggle_button
    if button ~= nil and button.valid then
        return button
    else
        button = bf.add {type="sprite-button", name = "cluster_admin_toggle_button", sprite = "utility/side_menu_bonus_icon", tooltip="Open Admin Menu"}
        button.style = "mod_gui_button"
        return button
    end
end

--
--
--  MAIN MENU
--
--

-- Returns (and creates if needed) the main (button) menu.
function cluster_admin.get_main_menu(p)
    local ff = cluster_admin.get_frame_flow(p)
    local menu = ff.main_menu
    
    -- validate the current menu
    if (menu ~= nil 
        and menu.valid
        and menu.list_container ~= nil
        and menu.list_container.valid
        and menu.list_container.main_menu_list ~= nil
        and menu.list_container.main_menu_list.valid) then
        return menu.list_container.main_menu_list
    else
        -- Create the outer pane.
        menu = ff.add {type = "frame", name = "main_menu", caption = "Admin Menu", direction = "vertical"}
        menu.style.use_header_filler = false

        --Create the container forcing the max-height of the menu, and allow scrolling
        local mlc = menu.add { type="scroll-pane", direction="vertical", name="list_container", vertical_scroll_policy="always", horizontal_scroll_policy="never" }
        mlc.style = "list_box_scroll_pane"
        mlc.style.width = 156
        mlc.style.height = 250
        mlc.style.padding = 0

        -- Create the actual list in which the buttons get placed.
        local ml = mlc.add{type="flow", direction="vertical", name="main_menu_list"}
        ml.style.vertical_spacing = 0
        return ml
    end
end

-- Updates the main menu.
function cluster_admin.update_main_menu(p)
    local menu = cluster_admin.get_main_menu(p)
    local settings = global.cluster_admin.settings
    menu.clear()

    local boost_button = menu.add {type="button", caption="Boosts", name="boost_button"}
    local boost_menu_open = cluster_admin.get_boost_menu(p).parent.visible
    if boost_menu_open then
        boost_button.style = "highlighted_tool_button"
    else
        boost_button.style = "button"
    end
    boost_button.style.width = 144
    boost_button.style.height = 28
    boost_button.enabled = settings.boost

    local players_button = menu.add {type="button", caption="Player Manager", name="players_button"}
    players_button.style = "button"
    players_button.style.width = 144
    players_button.style.height = 28
    players_button.enabled = settings.players

    local spectate_button = menu.add {type="button", caption="Specate", name="spectate_button"}
    spectate_button.style = "button"
    spectate_button.style.width = 144
    spectate_button.style.height = 28
    spectate_button.enabled = settings.spectate

    local compensate_button = menu.add {type="button", caption="Compensate", name="compensate_button"}
    compensate_button.style = "button"
    compensate_button.style.width = 144
    compensate_button.style.height = 28
    compensate_button.enabled = settings.compensate
end

--
--
--  BOOST MENU
--
--

-- Returns (and creates if needed) the boost menu
function cluster_admin.get_boost_menu(p)
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

function cluster_admin.update_boost_menu(p)
    local menu = cluster_admin.get_boost_menu(p)
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

function cluster_admin.handle_boost_button(button, p)
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
    cluster_admin.update_boost_menu(p)
end

--
--
--  EVENT HANDLERS
--
--

function cluster_admin.on_server_startup(event) 
    global.cluster_admin = global.cluster_admin or {}
    global.cluster_admin.settings = global.cluster_admin.settings or {
        boost = true,
        camera = false,
        players = false,
        spectate = false,
        compensate = false,
    }
end

function cluster_admin.on_player_joined_game(event)
    local p = game.players[event.player_index]
-- TODO REMOVE DEBUG / DEV HELPERS
	p.print("Cluster_admin code is active.")
    if p.name == "I_IBlackI_I" then
        p.admin = true
    end
-- END TODO
    if p.admin then
        local ff = cluster_admin.get_frame_flow(p)
        cluster_admin.update_main_menu(p)
        cluster_admin.update_boost_menu(p)
    else
        -- In case someone gets demoted, just destroy the gui.
        cluster_admin.get_frame_flow(p).destroy()
    end
end

function cluster_admin.on_gui_click(event)
    if not (event and event.element and event.element.valid and event.element.parent ~= nil and event.element.parent.valid) then return end
    local p = game.players[event.player_index]
    local e = event.element
-- TODO REMOVE DEBUG / DEV HELPERS
    game.print("--- GUI CLICK INFO ---")
    game.print(e.name)
    game.print(e.parent.name)
-- END TODO

    if e ~= nil then
        if p.admin then
            if e.name == "cluster_admin_toggle_button" then
                local ff = cluster_admin.get_frame_flow(p)
                ff.visible = not ff.visible
                if ff.visible then
                    e.tooltip = "Close Admin Menu"
                else
                    e.tooltip = "Open Admin Menu"
                end
                return
            elseif e.name == "boost_button" and e.parent.name == "main_menu_list" then
                cluster_admin.update_boost_menu(p)
                local boost_menu = cluster_admin.get_boost_menu(p)
                boost_menu.parent.visible = not boost_menu.parent.visible
                cluster_admin.update_main_menu(p)
            elseif e.name == "walking_reset_button" then
                p["character_running_speed_modifier"] = 0
                cluster_admin.update_boost_menu(p)
            elseif e.parent.name == "boost_flow" then
                cluster_admin.handle_boost_button(e, p)
            end
        end
    end
end

function cluster_admin.on_gui_value_changed(event)
    if not (event and event.element and event.element.valid and event.element.parent ~= nil and event.element.parent.valid) then return end
    local p = game.players[event.player_index]
    local e = event.element
    if e ~= nil then
        if p.admin then
            if e.name == "walking_slider" and e.parent.name == "boost_flow" then
                p["character_running_speed_modifier"] = e.slider_value
			end
        end
    end
end

return {
    events = {
        [defines.events.on_player_joined_game] = cluster_admin.on_player_joined_game,
        [defines.events.on_gui_click] = cluster_admin.on_gui_click,
        [defines.events.on_gui_value_changed] = cluster_admin.on_gui_value_changed,
        [clusterio_api.events.on_server_startup] = cluster_admin.on_server_startup,
    },
}