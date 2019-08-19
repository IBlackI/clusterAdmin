-- cluster_admin_camera sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord)
-- This sub-module is a addon to the cluster_admin module, it allows admins to create a camera following the target player

--
--	FUNCTIONS
--
function cluster_admin_camera_enable()
	if not global.cluster_admin_camera.enabled then
		global.cluster_admin_camera.enabled = true
		cluster_admin_add_submodule("cluster_admin_camera")
	else 
		return false
	end
end

function cluster_admin_camera_disable()
	if global.cluster_admin_camera.enabled then
		global.cluster_admin_camera.enabled = false
		cluster_admin_remove_submodule("cluster_admin_camera")
	else 
		return false
	end
end

function cluster_admin_camera_create(p, target)
	local pane = p.gui.screen["cluster_admin_camera_pane_" .. target.name]
	if pane ~= nil then
		pane.clear()
	else 
		pane = p.gui.screen.add {name = "cluster_admin_camera_pane_" .. target.name, type = "frame", direction = "vertical"}
		pane.style.padding = 2
		pane.auto_center = true
	end
	if global.cluster_admin_camera.enabled and p.admin then
		local header = pane.add {type="flow", name="cluster_admin_camera_header", direction="horizontal"}
		header.style.horizontal_spacing = 4
		
		local target_label = header.add {type="label", caption=target.name, name="cluster_admin_camera_target"}
		target_label.style.maximal_width = 100
		if target.admin then
			target_label.style.font_color = {128, 206, 240}
		end
		
		local dragg = header.add {type="empty-widget", name="cluster_admin_camera_dragg"}
		dragg.style = "draggable_space"
		dragg.style.margin = 0
		dragg.style.horizontally_stretchable = true
		dragg.style.vertically_stretchable = true
		dragg.drag_target = pane
		
		local cb = header.add {type="button", name="cluster_admin_camera_stop", caption="X"}
		cb.style="red_button"
		cb.style.padding = 0
		cb.style.height = 20
		cb.style.width = 20
		
		local camera = pane.add {type="camera", name="cluster_admin_camera_camera", position=target.position, surface_index=target.surface.index}
		camera.style.height = 160
		camera.style.width = 160
		local slider = pane.add {type="slider", name="cluster_admin_camera_slider", minimum_value=0.05, maximum_value=1.00, value=0.75, value_step=0.02, tooltip="Zoom level"}
		
		global.cluster_admin_camera.cameras[p.name .. " " .. target.name] = pane
		return pane
	else
		pane.destroy()
	end
end

--
--	Events
--
function cluster_admin_camera_on_init()
	global.cluster_admin_camera = global.cluster_admin_camera or {}
	global.cluster_admin_camera.cameras = global.cluster_admin_camera.cameras or {}
	global.cluster_admin_camera.enabled = false
	cluster_admin_camera_enable()
end

function cluster_admin_camera_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if (e and e.parent) ~= nil then
		if p.admin then
			if e.name == "cluster_admin_camera_stop" then
				global.cluster_admin_camera.cameras[p.name .. " " .. e.parent.cluster_admin_camera_target.caption] = nil
				e.parent.parent.destroy()
			end
		end
	end
end

function cluster_admin_camera_on_gui_value_changed(event)
	if not (event and event.element and event.element.valid) then return end
	local e = event.element
	if (e and e.parent) ~= nil then
		if e.name == "cluster_admin_camera_slider" then
			e.parent.cluster_admin_camera_camera.zoom = e.slider_value
		end
	end
end

function cluster_admin_camera_update_position(event)
	if global.cluster_admin_camera.enabled then
		for i, k in pairs(global.cluster_admin_camera.cameras) do
			if k ~= nil and k.valid then
				local target_name = k.cluster_admin_camera_header.cluster_admin_camera_target.caption
				if target_name ~= nil and target_name ~= "" then
					local target = game.players[target_name]
					if target ~= nil then
						k.cluster_admin_camera_camera.position=target.position
						k.cluster_admin_camera_camera.surface_index=target.surface.index
					else
						global.cluster_admin_camera.cameras[i] = nil
					end
				else
					global.cluster_admin_camera.cameras[i] = nil
				end
			else
				global.cluster_admin_camera.cameras[i] = nil
			end
		end
	end
end