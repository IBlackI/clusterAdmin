local menu_module = menu_module or {}

-- Returns (and creates if needed) the main (button) menu.
function menu_module.get_menu(cluster_admin, p)
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
function menu_module.update_menu(cluster_admin, p)
    local menu = menu_module.get_menu(cluster_admin, p)
    local settings = global.cluster_admin.settings
    menu.clear()

    local function create_button(name, caption, active)
        local button = menu.add {type = "button", name = name, caption = caption}
        if active then
            button.style = "highlighted_tool_button"
        else
            button.style = "button"
        end
        button.style.width = 144
        button.style.height = 28

        return button
    end

    local boost_menu_open = cluster_admin.boost.get_menu(cluster_admin, p).parent.visible
    local boost_button = create_button("boost_button", "Boosts", boost_menu_open)
    boost_button.enabled = settings.boost

    local players_menu_open = cluster_admin.players.get_menu(cluster_admin, p).visible
    local players_button = create_button("players_button", "Player Manager", players_menu_open)
    players_button.enabled = settings.players

    local spectate_button = create_button("spectate_button", "Specate", true)
    spectate_button.enabled = settings.spectate

    local compensate_button = create_button("compensate_button", "Compensate", true)
    compensate_button.enabled = settings.compensate
end

function menu_module.on_gui_click(cluster_admin, e, p)
    if e.name == "boost_button" and e.parent.name == "main_menu_list" then
        cluster_admin.boost.update_menu(cluster_admin, p)
        local boost_menu = cluster_admin.boost.get_menu(cluster_admin, p)
        boost_menu.parent.visible = not boost_menu.parent.visible
        cluster_admin.main.update_menu(cluster_admin, p)
    elseif e.name == "players_button" and e.parent.name == "main_menu_list" then
        cluster_admin.players.update_menu(cluster_admin, p)
        local players_menu = cluster_admin.players.get_menu(cluster_admin, p)
        players_menu.visible = not players_menu.visible
        cluster_admin.main.update_menu(cluster_admin, p)
    end
end

return menu_module