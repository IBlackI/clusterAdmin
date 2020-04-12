local cluster_admin = cluster_admin or {}
local clusterio_api = require("modules/clusterio/api")
cluster_admin.boost = require("modules/cluster_admin/boost")
cluster_admin.main = require("modules/cluster_admin/menu")
cluster_admin.players = require("modules/cluster_admin/players")

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
--  EVENT HANDLERS
--
--

function cluster_admin.on_server_startup(event)
    global.cluster_admin = global.cluster_admin or {}
    global.cluster_admin.settings = global.cluster_admin.settings or {
        boost = true,
        camera = false,
        players = true,
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
        cluster_admin.main.update_menu(cluster_admin, p)
        cluster_admin.boost.update_menu(cluster_admin, p)
        cluster_admin.players.update_menu(cluster_admin, p)
    else
        -- In case someone gets demoted, just destroy the gui.
        cluster_admin.get_frame_flow(p).destroy()
    end
end

function cluster_admin.on_gui_click(event)
    local p = game.players[event.player_index]
    if not p.admin then
        return
    end
    local modules = {
        boost = true,
        main = true,
        players = true,
    }
    local e = event.element
    if e.name == "cluster_admin_toggle_button" then
        local ff = cluster_admin.get_frame_flow(p)
        ff.visible = not ff.visible
        if ff.visible then
            e.tooltip = "Close Admin Menu"
        else
            e.tooltip = "Open Admin Menu"
        end
        return
    end

    for key, _ in pairs(modules) do
        local e = event.element
        if not (e and e.valid and e.parent ~= nil and e.parent.valid) then return end
        cluster_admin[key].on_gui_click(cluster_admin, e, p)
    end
end

function cluster_admin.on_gui_value_changed(event)
    local p = game.players[event.player_index]
    if not p.admin then
        return
    end
    local modules = {
        boost = true
    }

    for key, _ in pairs(modules) do
        local e = event.element
        if not (e and e.valid and e.parent ~= nil and e.parent.valid) then return end
        cluster_admin[key].on_gui_value_changed(cluster_admin, e, p)
    end
end

function cluster_admin.on_gui_text_changed(event)
    local p = game.players[event.player_index]
    if not p.admin then
        return
    end
    local modules = {
        players = true
    }

    for key, _ in pairs(modules) do
        local e = event.element
        if not (e and e.valid and e.parent ~= nil and e.parent.valid) then return end
        cluster_admin[key].on_gui_value_changed(cluster_admin, e, p)
    end
end

return {
    events = {
        [defines.events.on_player_joined_game] = cluster_admin.on_player_joined_game,
        [defines.events.on_gui_click] = cluster_admin.on_gui_click,
        [defines.events.on_gui_value_changed] = cluster_admin.on_gui_value_changed,
        [defines.events.on_gui_text_changed] = cluster_admin.on_gui_text_changed,
        [clusterio_api.events.on_server_startup] = cluster_admin.on_server_startup,
    },
}