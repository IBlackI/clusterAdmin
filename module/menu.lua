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

    local boost_button = menu.add {type="button", caption="Boosts", name="boost_button"}
    local boost_menu_open = cluster_admin.boost.get_menu(cluster_admin, p).parent.visible
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

function menu_module.on_gui_click(cluster_admin, e, p)
    if e.name == "boost_button" and e.parent.name == "main_menu_list" then
        cluster_admin.boost.update_menu(cluster_admin, p)
        local boost_menu = cluster_admin.boost.get_menu(cluster_admin, p)
        boost_menu.parent.visible = not boost_menu.parent.visible
        cluster_admin.main.update_menu(cluster_admin, p)
    end
end

return menu_module