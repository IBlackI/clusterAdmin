local camera_module = camera_module or {}

function camera_module.create(cluster_admin, p, target)
	local pane = p.gui.screen["camera_pane_" .. target.name]
	if pane ~= nil then
		pane.clear()
	else 
		pane = p.gui.screen.add {name = "camera_pane_" .. target.name, type = "frame", direction = "vertical"}
		pane.style.padding = 2
		pane.auto_center = true
    end

    local header = pane.add {type="flow", name="camera_pane_header", direction="horizontal"}
    header.style.horizontal_spacing = 4
    
    local target_label = header.add {type="label", caption=target.name, name="target_label"}
    target_label.style.maximal_width = 100
    if target.admin then
        target_label.style.font_color = {128, 206, 240}
    end
    
    local dragg = header.add {type="empty-widget", name="draggable_space"}
    dragg.style = "draggable_space"
    dragg.style.margin = 0
    dragg.style.horizontally_stretchable = true
    dragg.style.vertically_stretchable = true
    dragg.drag_target = pane
    
    local cb = header.add {type="button", name="stop", caption="X"}
    cb.style="red_button"
    cb.style.padding = 0
    cb.style.height = 20
    cb.style.width = 20
    
    local camera = pane.add {type="camera", name="camera_view", position=target.position, surface_index=target.surface.index}
    camera.style.height = 160
    camera.style.width = 160
    local slider = pane.add {type="slider", name="camera_slider", minimum_value=0.05, maximum_value=1.00, value=0.75, value_step=0.02, tooltip="Zoom level"}
    
    global.cluster_admin.cameras[p.name .. " " .. target.name] = pane
    return pane
end

--
--	Events
--

function camera_module.on_gui_click(cluster_admin, e, p)
    if e.name == "stop" and e.parent.name == "camera_pane_header" then
        global.cluster_admin.cameras[p.name .. " " .. e.parent.target_label.caption] = nil
        e.parent.parent.destroy()
    elseif e.name == "camera_view" or (e.name == "target_label" and e.parent.name == "camera_pane_header") then
        local target_name
        if e.name == "target_label" then
            target_name = e.caption
        else
            target_name = e.parent.camera_pane_header.target_label.caption
        end
        if target_name ~= nil then
            local target = game.players[target_name]
            if target ~= nil and target.connected then
                p.zoom_to_world(target.position)
            end
        end
    end
end

function camera_module.on_gui_value_changed(cluster_admin, e, p)
    if e.name == "camera_slider" then
        e.parent.camera_view.zoom = e.slider_value
    end
end

local function update_camera(key, camera)
    if camera ~= nil and camera.valid then
        local target_name = camera.camera_pane_header.target_label.caption
        if target_name ~= nil and target_name ~= "" then
            local target = game.players[target_name]
            if target ~= nil then
                if target.selected ~= nil then
                    camera.gui.player.create_local_flying_text{text=target.name, position=target.selected.position, time_to_live=5}
                end
                camera.camera_view.position=target.position
                camera.camera_view.surface_index=target.surface.index
                return
            end
        end
    end
    if camera ~= nil then
        camera.destroy()
    end
    global.cluster_admin.cameras[key] = nil
end

function camera_module.on_tick(cluster_admin)
    for key, camera in pairs(global.cluster_admin.cameras) do
        update_camera(key, camera)
    end
end


return camera_module