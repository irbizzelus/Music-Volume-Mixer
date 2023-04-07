dofile(ModPath .. "lua/menu.lua")

Hooks:Add('LocalizationManagerPostInit', 'VolumeMixerByirbi_loc', function(loc)
	VolumeMixerByirbi:Load()
	
	local lang = "en"
	local file = io.open(SavePath .. 'blt_data.txt', 'r')
    if file then
        for k, v in pairs(json.decode(file:read('*all')) or {}) do
			if k == "language" then
				lang = v
			end
        end
        file:close()
    end
	
	if lang == "ru" then
		loc:load_localization_file(VolumeMixerByirbi.modpath .. 'menus/lang/VolumeMixerByirbimenu_ru.txt', false)
	elseif lang == "chs" then -- thanks Arknights
		loc:load_localization_file(VolumeMixerByirbi.modpath .. 'menus/lang/VolumeMixerByirbimenu_chs.txt', false)
	elseif lang == "es" then -- thanks Un aweonao
		loc:load_localization_file(VolumeMixerByirbi.modpath .. 'menus/lang/VolumeMixerByirbimenu_es.txt', false)
	else
		loc:load_localization_file(VolumeMixerByirbi.modpath .. 'menus/lang/VolumeMixerByirbimenu_en.txt', false)
	end
	
	loc:load_localization_file(VolumeMixerByirbi.modpath .. 'menus/lang/VolumeMixerByirbimenu_en.txt', false)
end)

Hooks:PostHook(MenuManager, "_node_selected", "VolumeMixerByirbi_playmainmenutrack", function(self, menu_name, node)
	if type(node) == "table" and node._parameters.name == "sound" then
		node._items[2]._enabled = false
		node._items[2]._parameters.help_id = "VMBI_soundsettingtip"
		node._items[2]._slider_color = Color( 31.875, 255, 255, 255 ) / 255
		node._items[2]._slider_color_highlight = Color( 1, 255, 255, 255 ) / 255
		VolumeMixerByirbi.fuckingpreplanning = nil
		VolumeMixerByirbi.previousNodeJukebox = nil
	elseif type(node) == "table" and (node._parameters.name == "kit" or node._parameters.name == "loadout" or node._parameters.name == "preplanning") then
		-- add a kit exception that resets volume based on 'event'
		VolumeMixerByirbi.fuckingpreplanning = true
		if VolumeMixerByirbi.settings.fullmute == false then
			local track = Global.music_manager.current_event
			if string.sub(track, 1, 7) == "screen_" then
				track = string.sub(track, 8, string.len(track))
			end
			if VolumeMixerByirbi:checktrack(track) == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		else
			managers.user:set_setting("music_volume", 0)
		end
		if VolumeMixerByirbi.previousNodeJukebox then
			Global.music_manager.current_track = "stop_all_music"
			VolumeMixerByirbi.previousNodeJukebox = nil
		end
	elseif type(node) == "table" and (node._parameters.name == "main" or node._parameters.name == "lobby") then
		if not VolumeMixerByirbi.menucheck then -- when in menus/lobby set current track to current event so other parts of this mod work correctly. in base game 'track' in menus is usually nil
			Global.music_manager.current_track = Global.music_manager.current_event
			VolumeMixerByirbi.menucheck = 1 -- do it only once, cuz switching tracks via this mod switches track var anyway. fuck all other music players lmao
		end
		local track = Global.music_manager.current_track
		local track_noprefix = nil
		if string.sub(Global.music_manager.current_track, 8, string.len(Global.music_manager.current_track)) ~= "" then
			track_noprefix = string.sub(Global.music_manager.current_track, 8, string.len(Global.music_manager.current_track))
		end
		if VolumeMixerByirbi.settings.fullmute == false then
			if VolumeMixerByirbi:checktrack(track) == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track.."_volume"])
			elseif VolumeMixerByirbi:checktrack(track_noprefix) == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_noprefix.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		else
			managers.user:set_setting("music_volume", 0)
		end
		VolumeMixerByirbi.fuckingpreplanning = nil
		VolumeMixerByirbi.previousNodeJukebox = nil
	elseif type(node) == "table" and node._parameters.name == "jukebox" and Utils:IsInGameState() then
		VolumeMixerByirbi.fuckingpreplanning = nil
		VolumeMixerByirbi.previousNodeJukebox = true
	else
		VolumeMixerByirbi.fuckingpreplanning = nil
		VolumeMixerByirbi.previousNodeJukebox = nil
	end
end)

Hooks:PostHook(MenuCallbackHandler, "jukebox_option_back", "VolumeMixerByirbi_fuckinmusicswitchininmenucallbacks", function(self)
	local track_id = Global.music_manager.current_event
	Global.music_manager.current_event = "screen_"..Global.music_manager.current_event
	Global.music_manager.current_track = Global.music_manager.current_event
	if VolumeMixerByirbi:checktrack(track_id) == true then
		managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
	else
		managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
	end
end)

Hooks:Add('MenuManagerInitialize', 'VolumeMixerByirbi_init', function(menu_manager)
	MenuCallbackHandler.VMBI_clbck_VolumeMixerByirbisave = function(this, item)
		VolumeMixerByirbi:Save()
	end
	
	MenuCallbackHandler.VMBI_clbck_donothing = function(this, item)
		-- Nothing
	end
	
	MenuCallbackHandler.VMBI_clbck_fullmute = function(this, item)
		VolumeMixerByirbi.settings[item:name()] = item:value() == 'on'
		VolumeMixerByirbi:Save()
		if item:value() == "on" then
			managers.user:set_setting("music_volume", 0)
		else
			local menutrack_id = nil
			if Global.music_manager.current_track ~= nil then
				if string.sub(Global.music_manager.current_track, 1, 7) == "screen_" then
					menutrack_id = string.sub(Global.music_manager.current_track, 8, string.len(Global.music_manager.current_track))
				else
					menutrack_id = Global.music_manager.current_track
				end
				if VolumeMixerByirbi:checktrack(menutrack_id) == true then
					managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[menutrack_id.."_volume"])
				else
					managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume or 20)
				end
			else
				if Global.music_manager.current_event then
					if string.sub(Global.music_manager.current_event, 1, 7) == "screen_" then
						menutrack_id = string.sub(Global.music_manager.current_event, 8, string.len(Global.music_manager.current_event))
					else
						menutrack_id = Global.music_manager.current_event
					end
					if VolumeMixerByirbi:checktrack(menutrack_id) == true then
						managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[menutrack_id.."_volume"])
					else
						managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume or 20)
					end
				end
			end
		end
	end
	
	MenuCallbackHandler.VMBI_set_default_volume = function(this, item)
		VolumeMixerByirbi.settings.defaultvolume = tonumber(item:value())
		VolumeMixerByirbi:Save()
		local track_id
		if string.sub(Global.music_manager.current_track, 1, 7) == "screen_" then
			track_id = string.sub(Global.music_manager.current_track, 8, string.len(Global.music_manager.current_track))
		else
			track_id = Global.music_manager.current_track
		end
		
		if VolumeMixerByirbi.settings.fullmute == true then
			managers.user:set_setting("music_volume", 0)
		elseif VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] ~= true then
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)	
		end
	end
	
	MenuCallbackHandler.VMBI_clbck_onVMBImenuquit = function(this, item)
		if not Utils:IsInGameState() then
			if Global.music_manager.current_event == "stop_all_music" then
				local track_id = managers.music:jukebox_menu_track("mainmenu")
				managers.music:post_event(track_id)
				Global.music_manager.current_track = track_id
				if VolumeMixerByirbi.settings.fullmute == true then
					managers.user:set_setting("music_volume", 0)
				elseif VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == true then
					managers.user:set_setting("music_volume",  VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
				else
					managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
				end
			end
		else
			if Global.music_manager.current_event ~= managers.music:jukebox_menu_track("loadout") then
				if Global.music_manager.current_track == "stop_all_music" then
					local CE = Global.music_manager.current_event
					local switches = tweak_data.levels:get_music_switches()
					if switches then -- fml stealth only heists are stupid
						local selected_track = switches[math.random(1,#switches)]
						managers.music:track_listen_start(CE, selected_track)
						managers.music:post_event(selected_track)
						managers.music:post_event(CE)
						managers.music._skip_play = nil
						Global.music_manager.current_track = selected_track
						if VolumeMixerByirbi.settings.fullmute == true then
							managers.user:set_setting("music_volume", 0)
						elseif VolumeMixerByirbi.settings.tracks_data[selected_track.."_toggle"] == true then
							managers.user:set_setting("music_volume",  VolumeMixerByirbi.settings.tracks_data[selected_track.."_volume"])
						else
							managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
						end
					end
				end
			end
		end
		VolumeMixerByirbi:Save()
	end
	
	MenuCallbackHandler.VMBI_clbck_stopallmusic = function(this, item)
		if not Utils:IsInGameState() then
			managers.music:post_event("stop_all_music")
			Global.music_manager.source:stop()
			managers.music:track_listen_stop()
			managers.music:music_ext_listen_stop()
			Global.music_manager.current_track = "stop_all_music"
			Global.music_manager.current_event = "stop_all_music"
		end
	end
	
	--################################### Menu music callbacks ######################################
	
	MenuCallbackHandler.VMBI_clbck_setquickmenutrack = function(this, item)
		VolumeMixerByirbi.QM_M_track_id = string.sub(VolumeMixerByirbi.qucikacessmenutracks[item:value()], 21, string.len(VolumeMixerByirbi.qucikacessmenutracks[item:value()]))
		local node = MenuHelper:GetMenu("VMBI")
		local CE = Global.music_manager.current_event
		-- silly edgecase where our track can be equal but have no prefix, so we avoid restarting the track, but still update the ui and globals
		if Global.music_manager.current_track == VolumeMixerByirbi.QM_M_track_id then
			Global.music_manager.current_track = "screen_"..VolumeMixerByirbi.QM_M_track_id
			Global.music_manager.current_event = "screen_"..VolumeMixerByirbi.QM_M_track_id
		elseif Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_M_track_id then
			managers.music:track_listen_stop()
			if Utils:IsInGameState() then
				managers.music:track_listen_start(VolumeMixerByirbi.QM_M_track_id, "screen_"..VolumeMixerByirbi.QM_M_track_id)
				Global.music_manager.current_event = CE
				Global.music_manager.current_track = "screen_"..VolumeMixerByirbi.QM_M_track_id
			else
				managers.music:track_listen_start(VolumeMixerByirbi.QM_M_track_id, "screen_"..VolumeMixerByirbi.QM_M_track_id)
				managers.music:post_event("screen_"..VolumeMixerByirbi.QM_M_track_id)
				Global.music_manager.current_track = "screen_"..VolumeMixerByirbi.QM_M_track_id
			end
			if VolumeMixerByirbi.settings.fullmute == true then
				managers.user:set_setting("music_volume", 0)
			elseif VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume",  VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		end
		-- ui
		if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_toggle"] == false then
			node._items[11].selected = 2
		else
			node._items[11].selected = 1
		end
		node._items[12]:set_enabled(VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_toggle"])
		node._items[12]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_volume"]
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
	end
	
	MenuCallbackHandler.VMBI_clbck_QM_M_toggle = function(this, item)
		-- if we try to enable toggle for a track that doesnt exist, pick the first track on the list. can only happen if user tries to adjust track before selecting one, but since the default track there is always first from the list, this works perfectly
		if not VolumeMixerByirbi.QM_M_track_id then
			VolumeMixerByirbi.QM_M_track_id = string.sub(VolumeMixerByirbi.qucikacessmenutracks[1], 21, string.len(VolumeMixerByirbi.qucikacessmenutracks[1]))
		end
		local node = MenuHelper:GetMenu("VMBI")
		if Global.music_manager.current_track == VolumeMixerByirbi.QM_M_track_id then
			-- dont restart our track if it has no prefix + updates to globals
			Global.music_manager.current_track = "screen_"..VolumeMixerByirbi.QM_M_track_id
			Global.music_manager.current_event = "screen_"..VolumeMixerByirbi.QM_M_track_id
		elseif Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_M_track_id then
			local CE = Global.music_manager.current_event
			managers.music:track_listen_stop()
			if Utils:IsInGameState() then
				managers.music:track_listen_start(VolumeMixerByirbi.QM_M_track_id, "screen_"..VolumeMixerByirbi.QM_M_track_id)
				Global.music_manager.current_event = CE
				Global.music_manager.current_track = "screen_"..VolumeMixerByirbi.QM_M_track_id
			else
				managers.music:track_listen_start(VolumeMixerByirbi.QM_M_track_id, "screen_"..VolumeMixerByirbi.QM_M_track_id)
				managers.music:post_event("screen_"..VolumeMixerByirbi.QM_M_track_id)
				Global.music_manager.current_track = "screen_"..VolumeMixerByirbi.QM_M_track_id
			end	
		end	
		
		-- ui
		VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_toggle"] = item:value() == 'on'
		node._items[12]:set_enabled(not node._items[12]:enabled())
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
		
		VolumeMixerByirbi:Save()
		
		-- clicking toggle switches volume, so we can hear diff between default and custom volume
		local track_id = VolumeMixerByirbi.QM_M_track_id
		if Global.music_manager.current_track == "screen_"..track_id and VolumeMixerByirbi.settings.fullmute == false then
			if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		else
			managers.user:set_setting("music_volume", 0)
		end
	end

	MenuCallbackHandler.VMBI_clbck_QM_M_volume = function(this, item)
		if not VolumeMixerByirbi.QM_M_track_id then
			VolumeMixerByirbi.QM_M_track_id = string.sub(VolumeMixerByirbi.qucikacessmenutracks[1], 21, string.len(VolumeMixerByirbi.qucikacessmenutracks[1]))
		end
		if Global.music_manager.current_track == VolumeMixerByirbi.QM_M_track_id then
			-- dont restart our track if it has no prefix + updates to globals
			Global.music_manager.current_track = "screen_"..VolumeMixerByirbi.QM_M_track_id
			Global.music_manager.current_event = "screen_"..VolumeMixerByirbi.QM_M_track_id
		elseif Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_M_track_id then
			local CE = Global.music_manager.current_event
			managers.music:track_listen_stop()
			managers.music:post_event("stop_all_music")
			if Utils:IsInGameState() then
				managers.music:track_listen_start(VolumeMixerByirbi.QM_M_track_id, "screen_"..VolumeMixerByirbi.QM_M_track_id)
				Global.music_manager.current_event = CE
				Global.music_manager.current_track = "screen_"..VolumeMixerByirbi.QM_M_track_id
			else
				managers.music:track_listen_start(VolumeMixerByirbi.QM_M_track_id, "screen_"..VolumeMixerByirbi.QM_M_track_id)
				Global.music_manager.current_event = "screen_"..VolumeMixerByirbi.QM_M_track_id
				managers.music:post_event("screen_"..VolumeMixerByirbi.QM_M_track_id)
				Global.music_manager.current_track = "screen_"..VolumeMixerByirbi.QM_M_track_id
			end
		end	
		VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_volume"] = tonumber(item:value())
		
		VolumeMixerByirbi:Save()
		
		local track_id = VolumeMixerByirbi.QM_M_track_id
		if Global.music_manager.current_track == "screen_"..track_id and VolumeMixerByirbi.settings.fullmute == false then
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
		else
			managers.user:set_setting("music_volume", 0)
		end
	end
	
	--################################### Heist music callbacks ######################################
	
	MenuCallbackHandler.VMBI_clbck_setquickgametrack = function(this, item)
		VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[item:value()], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[item:value()]))
		local node = MenuHelper:GetMenu("VMBI")
		local CE = Global.music_manager.current_event
		local track_id = VolumeMixerByirbi.QM_G_track_id
		if Global.music_manager.current_track ~= track_id then
			if Utils:IsInGameState() then
				managers.music:track_listen_start(CE, track_id)
				managers.music:post_event(track_id)
				managers.music:post_event(CE)
				managers.music._skip_play = nil
				Global.music_manager.loadout_selection = track_id
			else
				managers.music:track_listen_start("music_heist_assault", track_id)
				Global.music_manager.current_event = track_id
				--managers.music:post_event(track_id)
			end
			Global.music_manager.current_track = track_id
			if VolumeMixerByirbi.settings.fullmute == true then
				managers.user:set_setting("music_volume", 0)
			elseif VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume",  VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		end
		if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == false then
			node._items[17].selected = 2
		else
			node._items[17].selected = 1
		end
		node._items[18]:set_enabled(VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"])
		node._items[18]._value = VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"]
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)	
	end
	
	MenuCallbackHandler.VMBI_clbck_QM_G_toggle = function(this, item)
		local CE = Global.music_manager.current_event
		local node = MenuHelper:GetMenu("VMBI")
		if not VolumeMixerByirbi.QM_G_track_id then
			VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[1], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[1]))
		end
		local track_id = VolumeMixerByirbi.QM_G_track_id
		if Global.music_manager.current_track ~= track_id then
			if Utils:IsInGameState() then
				managers.music:track_listen_start(CE, track_id)
				managers.music:post_event(track_id)
				managers.music:post_event(CE)
			else
				managers.music:track_listen_start("music_heist_assault", track_id)
				Global.music_manager.current_event = track_id
				--managers.music:post_event(track_id)
			end
			Global.music_manager.current_track = track_id
		end
		VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] = item:value() == 'on'
		node._items[18]:set_enabled(not node._items[18]:enabled())
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
		VolumeMixerByirbi:Save()
		if Global.music_manager.current_track == track_id and VolumeMixerByirbi.settings.fullmute == false then
			if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		else
			managers.user:set_setting("music_volume", 0)
		end
	end
	
	MenuCallbackHandler.VMBI_clbck_QM_G_volume = function(this, item)
		local CE = Global.music_manager.current_event
		if not VolumeMixerByirbi.QM_G_track_id then
			VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[1], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[1]))
		end
		local track_id = VolumeMixerByirbi.QM_G_track_id
		if Global.music_manager.current_track ~= track_id then
			if Utils:IsInGameState() then
				managers.music:track_listen_start(CE, track_id)
				managers.music:post_event(track_id)
				managers.music:post_event(CE)
			else
				managers.music:track_listen_start("music_heist_assault", track_id)
				Global.music_manager.current_event = track_id
				--managers.music:post_event(track_id)
			end
			Global.music_manager.current_track = track_id
		end
		VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"] = tonumber(item:value())
		VolumeMixerByirbi:Save()
		if Global.music_manager.current_track == track_id and VolumeMixerByirbi.settings.fullmute == false then
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
		else
			managers.user:set_setting("music_volume", 0)
		end
	end
	
	function VMBI_play_G_trackphase(phase)
	local CE = Global.music_manager.current_event
	managers.music._skip_play = nil
		if Utils:IsInGameState() then
			if phase == "Default" then
				Global.music_manager.source:stop()
				if Global.music_manager.current_track ~= VolumeMixerByirbi.QM_G_track_id then
					managers.music:track_listen_start(CE, VolumeMixerByirbi.QM_G_track_id)
				end
				Global.music_manager.source:post_event(CE)
				VMBI_postphasevolume_G(VolumeMixerByirbi.QM_G_track_id)
				return
			end
			if Global.music_manager.current_track ~= VolumeMixerByirbi.QM_G_track_id then
				Global.music_manager.source:stop()
				managers.music:track_listen_start(phase, VolumeMixerByirbi.QM_G_track_id)
				if phase == "music_heist_setup" then
					managers.music:post_event("stop_all_music")
					managers.music:track_listen_start("music_heist_setup", VolumeMixerByirbi.QM_G_track_id)
				end
				managers.music:post_event(phase)
				Global.music_manager.current_event = CE
				managers.music._skip_play = true
				VMBI_postphasevolume_G(VolumeMixerByirbi.QM_G_track_id)
			else
				if phase == "music_heist_setup" then
					managers.music:post_event("stop_all_music")
					managers.music:track_listen_start("music_heist_setup", VolumeMixerByirbi.QM_G_track_id)
				end
				managers.music:post_event(phase)
				Global.music_manager.current_event = CE
				managers.music._skip_play = true
				VMBI_postphasevolume_G(VolumeMixerByirbi.QM_G_track_id)
			end
		else
			if Global.music_manager.current_track ~= VolumeMixerByirbi.QM_G_track_id then
				managers.music:track_listen_stop()
				managers.music:post_event("stop_all_music")
				managers.music:track_listen_start(phase, VolumeMixerByirbi.QM_G_track_id)
				Global.music_manager.source:stop()
				Global.music_manager.source:post_event(VolumeMixerByirbi.QM_G_track_id)
				Global.music_manager.source:post_event(phase)
				Global.music_manager.current_track = VolumeMixerByirbi.QM_G_track_id
				Global.music_manager.current_event = phase
				VMBI_postphasevolume_G(VolumeMixerByirbi.QM_G_track_id)
			else
				managers.music:post_event("stop_all_music")
				managers.music:track_listen_start(phase, VolumeMixerByirbi.QM_G_track_id)
				Global.music_manager.source:post_event(phase)
				Global.music_manager.current_event = phase
				VMBI_postphasevolume_G(VolumeMixerByirbi.QM_G_track_id)
			end
		end
	end
	
	function VMBI_postphasevolume_G(track_id)
		if VolumeMixerByirbi.settings.fullmute == false then
			if VolumeMixerByirbi:checktrack(track_id) == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		else
			managers.user:set_setting("music_volume", 0)
		end
	end
	
	MenuCallbackHandler.VMBI_clbck_gametrackphase = function(this, item)
		if not VolumeMixerByirbi.QM_G_track_id then
			VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[1], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[1]))
		end
		
		if item:value() == 1 then
			VMBI_play_G_trackphase("Default")
		elseif item:value() == 2 then
			VMBI_play_G_trackphase("music_heist_setup")
		elseif item:value() == 3 then
			VMBI_play_G_trackphase("music_heist_control")
		elseif item:value() == 4 then
			VMBI_play_G_trackphase("music_heist_anticipation")
		elseif item:value() == 5 then
			VMBI_play_G_trackphase("music_heist_assault")
		end
	end
	
	
	--################################### Stealth music callbacks ######################################
	
	MenuCallbackHandler.VMBI_clbck_setquickghosttrack = function(this, item)
		VolumeMixerByirbi.QM_S_track_id = string.sub(VolumeMixerByirbi.qucikacessghosttracks[item:value()], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[item:value()]))
		local node = MenuHelper:GetMenu("VMBI")
		local CE = Global.music_manager.current_event
		local track_id = VolumeMixerByirbi.QM_S_track_id
		if Utils:IsInGameState() then
			if Global.music_manager.current_track ~= "screen_"..track_id then
				Global.music_manager.source:stop()
				managers.music:track_listen_start("screen_"..track_id, "screen_"..track_id)
				managers.music:track_listen_stop()
				Global.music_manager.source:post_event(track_id)
				managers.music:post_event(CE)
			end
		else
			if Global.music_manager.current_track ~= "screen_"..track_id then
				managers.music:track_listen_stop()
				managers.music:post_event("stop_all_music")
				managers.music:track_listen_start(track_id, "screen_"..track_id)
				Global.music_manager.source:stop()
				Global.music_manager.source:post_event(track_id)
				Global.music_manager.source:post_event("suspense_4")
				Global.music_manager.current_track = "screen_"..track_id
				Global.music_manager.current_event = "suspense_4"
			end
		end
		if VolumeMixerByirbi.settings.fullmute == true then
			managers.user:set_setting("music_volume", 0)
		elseif VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == true then
			managers.user:set_setting("music_volume",  VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
		else
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
		end
		if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == false then
			node._items[24].selected = 2
		else
			node._items[24].selected = 1
		end
		node._items[25]:set_enabled(VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"])
		node._items[25]._value = VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"]
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
	end
	
	MenuCallbackHandler.VMBI_clbck_QM_S_toggle = function(this, item)
		local CE = Global.music_manager.current_event
		local node = MenuHelper:GetMenu("VMBI")
		if not VolumeMixerByirbi.QM_S_track_id then
			VolumeMixerByirbi.QM_S_track_id = string.sub(VolumeMixerByirbi.qucikacessghosttracks[1], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[1]))
		end
		local track_id = VolumeMixerByirbi.QM_S_track_id
		if Utils:IsInGameState() then
			if Global.music_manager.current_track ~= "screen_"..track_id then
				Global.music_manager.source:stop()
				managers.music:track_listen_start("screen_"..track_id, "screen_"..track_id)
				managers.music:track_listen_stop()
				Global.music_manager.source:post_event(track_id)
				managers.music:post_event(CE)
			end
		else
			if Global.music_manager.current_track ~= "screen_"..track_id then
				managers.music:track_listen_stop()
				managers.music:post_event("stop_all_music")
				managers.music:track_listen_start(track_id, "screen_"..track_id)
				Global.music_manager.source:stop()
				Global.music_manager.source:post_event(track_id)
				Global.music_manager.source:post_event("suspense_4")
				Global.music_manager.current_track = "screen_"..track_id
				Global.music_manager.current_event = "suspense_4"
			end
		end
		VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] = item:value() == 'on'
		node._items[25]:set_enabled(not node._items[25]:enabled())
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
		VolumeMixerByirbi:Save()
		if Global.music_manager.current_track == "screen_"..track_id and VolumeMixerByirbi.settings.fullmute == false then
			if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		else
			managers.user:set_setting("music_volume", 0)
		end
	end
	
	MenuCallbackHandler.VMBI_clbck_QM_S_volume = function(this, item)
		local CE = Global.music_manager.current_event
		if not VolumeMixerByirbi.QM_S_track_id then
			VolumeMixerByirbi.QM_S_track_id = string.sub(VolumeMixerByirbi.qucikacessghosttracks[1], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[1]))
			managers.music:track_listen_stop()
		end
		local track_id = VolumeMixerByirbi.QM_S_track_id
		if Utils:IsInGameState() then
			if Global.music_manager.current_track ~= "screen_"..track_id then
				Global.music_manager.source:stop()
				managers.music:track_listen_start("screen_"..track_id, "screen_"..track_id)
				managers.music:track_listen_stop()
				Global.music_manager.source:post_event(track_id)
				managers.music:post_event(CE)
			end
		else
			if Global.music_manager.current_track ~= "screen_"..track_id then
				managers.music:track_listen_stop()
				managers.music:post_event("stop_all_music")
				managers.music:track_listen_start(track_id, "screen_"..track_id)
				Global.music_manager.source:stop()
				Global.music_manager.source:post_event(track_id)
				Global.music_manager.source:post_event("suspense_4")
				Global.music_manager.current_track = "screen_"..track_id
				Global.music_manager.current_event = "suspense_4"
			end
		end
		VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"] = tonumber(item:value())
		VolumeMixerByirbi:Save()
		if Global.music_manager.current_track == "screen_"..track_id and VolumeMixerByirbi.settings.fullmute == false then
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
		else
			managers.user:set_setting("music_volume", 0)
		end
	end
	
	local function VMBI_play_S_trackphase(phase)
	local CE = Global.music_manager.current_event
	managers.music._skip_play = nil
		if Utils:IsInGameState() then
			if phase == "Default" then
				Global.music_manager.source:stop()
				managers.music:track_listen_start("screen_"..VolumeMixerByirbi.QM_S_track_id, CE)
				managers.music:track_listen_stop()
				Global.music_manager.source:post_event(VolumeMixerByirbi.QM_S_track_id)
				managers.music:post_event(CE)
				
				if VolumeMixerByirbi.settings.fullmute == false then
					if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_toggle"] == true then
						managers.user:set_setting("music_volume",  VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_volume"])
					else
						managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
					end
				else
					managers.user:set_setting("music_volume", 0)
				end
				return
			end
			if Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_S_track_id then
				Global.music_manager.source:stop()
				managers.music:track_listen_start("screen_"..VolumeMixerByirbi.QM_S_track_id, "screen_"..VolumeMixerByirbi.QM_S_track_id)
				managers.music:track_listen_stop()
				Global.music_manager.source:post_event(VolumeMixerByirbi.QM_S_track_id)
				managers.music:post_event(phase)
				Global.music_manager.current_event = CE
				managers.music._skip_play = true
			else
				managers.music:post_event(phase)
				Global.music_manager.current_event = CE
				managers.music._skip_play = true
			end
			if VolumeMixerByirbi.settings.fullmute == false then
				if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_toggle"] == true then
					managers.user:set_setting("music_volume",  VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_volume"])
				else
					managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
				end
			else
				managers.user:set_setting("music_volume", 0)
			end
		else
			if Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_S_track_id then
				managers.music:track_listen_stop()
				managers.music:post_event("stop_all_music")
				managers.music:track_listen_start(VolumeMixerByirbi.QM_S_track_id, "screen_"..VolumeMixerByirbi.QM_S_track_id)
				Global.music_manager.source:stop()
				Global.music_manager.source:post_event(VolumeMixerByirbi.QM_S_track_id)
				Global.music_manager.source:post_event(phase)
				Global.music_manager.current_track = "screen_"..VolumeMixerByirbi.QM_S_track_id
				Global.music_manager.current_event = phase
			else
				Global.music_manager.source:post_event(phase)
				Global.music_manager.current_event = phase
			end
		end
	end
	
	MenuCallbackHandler.VMBI_clbck_ghosttrackphase = function(this, item)
		local CE = Global.music_manager.current_event
		if not VolumeMixerByirbi.QM_S_track_id then
			VolumeMixerByirbi.QM_S_track_id = string.sub(VolumeMixerByirbi.qucikacessghosttracks[1], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[1]))
			--managers.music:track_listen_stop()
		end
		
		if item:value() == 1 then
			VMBI_play_S_trackphase("Default")
		elseif item:value() == 2 then
			VMBI_play_S_trackphase("suspense_1")
		elseif item:value() == 3 then
			VMBI_play_S_trackphase("suspense_2")
		elseif item:value() == 4 then
			VMBI_play_S_trackphase("suspense_3")
		elseif item:value() == 5 then
			VMBI_play_S_trackphase("suspense_4")
		elseif item:value() == 6 then
			VMBI_play_S_trackphase("suspense_5")
		end
	end

	VolumeMixerByirbi:Load()

	MenuHelper:LoadFromJsonFile(VolumeMixerByirbi.modpath .. 'menus/VolumeMixerByirbimenu.txt', VolumeMixerByirbi, VolumeMixerByirbi.settings)
end)

Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerCreateCustomMenuItems_For_VMBI", function( menu_manager, nodes )
	MenuHelper:AddDivider({
		id = "VMBIdivider_volumemenu_1",
		size = 16,
		menu_id = "VMBI",
		priority = 22
	})
	MenuHelper:AddButton({
		id = "VMBI_multichoice_header",
		title = "VMBI_multichoice_header",
		desc = "VMBI_empty",
		callback = "VMBI_clbck_donothing",
		menu_id = "VMBI",
		priority = 21,
	})
	MenuHelper:AddDivider({
		id = "VMBIdivider_volumemenu_2",
		size = 16,
		menu_id = "VMBI",
		priority = 20
	})
	
	VolumeMixerByirbi.qucikacessmenutracks = {}
	local function build_quickaccessfor_menu()
		if managers.music then
			local track_list,track_locked = managers.music:jukebox_menu_tracks()
			for __, track_name in pairs(track_list or {}) do
				if not track_locked[track_name] then
					table.insert(VolumeMixerByirbi.qucikacessmenutracks,"menu_jukebox_screen_"..track_name)
				end
			end
			local QM_M_base_val = string.sub(VolumeMixerByirbi.qucikacessmenutracks[1], 21, string.len(VolumeMixerByirbi.qucikacessmenutracks[1]))
			MenuHelper:AddButton({
				id = "VMBI_menumultichoice_header",
				title = "VMBI_menumultichoice_header",
				desc = "VMBI_qucikmenu_musicstop",
				callback = "VMBI_clbck_stopallmusic",
				menu_id = "VMBI",
				priority = 19,
			})
			MenuHelper:AddDivider({
				id = "VMBIdivider_volumemenu_3",
				size = 8,
				menu_id = "VMBI",
				priority = 18
			})
			MenuHelper:AddMultipleChoice({
				id = "VMBImenutracks_multichoice",
				title = "VMBI_empty",
				desc = "VMBI_menutracks_multichoice_desc",
				callback = "VMBI_clbck_setquickmenutrack",
				items = VolumeMixerByirbi.qucikacessmenutracks,
				value = 1,
				menu_id = "VMBI",
				priority = 17,
			})
			MenuHelper:AddToggle({
				id = "VMBI_QM_M_toggle",
				title = "VMBI_track_toggle",
				desc = "VMBI_track_toggle_desc",
				callback = "VMBI_clbck_QM_M_toggle",
				value = VolumeMixerByirbi.settings.tracks_data[QM_M_base_val.."_toggle"],
				menu_id = "VMBI",
				priority = 16
			})
			MenuHelper:AddSlider({
				id = "VMBI_QM_M_volume",
				title = "VMBI_track_volume",
				desc = "VMBI_empty",
				callback = "VMBI_clbck_QM_M_volume",
				value = VolumeMixerByirbi.settings.tracks_data[QM_M_base_val.."_volume"] or 20,
				min = 0,
				max = 100,
				step = 1,
				show_value = true,
				menu_id = "VMBI",
				disabled = not VolumeMixerByirbi.settings.tracks_data[QM_M_base_val.."_toggle"],
				priority = 15
			})
			MenuHelper:AddDivider({
				id = "VMBIdivider_volumemenu_4",
				size = 16,
				menu_id = "VMBI",
				priority = 14
			})
		else
			DelayedCalls:Add("VMBI_buildQAmenutracks_loop", 0.1, function()
				build_quickaccessfor_menu()
			end)
		end
	end
	build_quickaccessfor_menu()
	
	VolumeMixerByirbi.qucikacessgametracks = {}
	local function build_quickaccessfor_game()
		if managers.music then
			local track_list,track_locked = managers.music:jukebox_music_tracks()
			for __, track_name in pairs(track_list or {}) do
				if not track_locked[track_name] then
					table.insert(VolumeMixerByirbi.qucikacessgametracks,"menu_jukebox_"..track_name)
				end
			end
			local QM_G_base_val = string.sub(VolumeMixerByirbi.qucikacessgametracks[1], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[1]))
			MenuHelper:AddButton({
				id = "VMBI_gamemultichoice_header",
				title = "VMBI_gamemultichoice_header",
				desc = "VMBI_qucikmenu_musicstop",
				callback = "VMBI_clbck_stopallmusic",
				menu_id = "VMBI",
				priority = 13,
			})
			MenuHelper:AddDivider({
				id = "VMBIdivider_volumemenu_5",
				size = 8,
				menu_id = "VMBI",
				priority = 12
			})
			MenuHelper:AddMultipleChoice({
				id = "VMBIgametracks_multichoice",
				title = "VMBI_empty",
				desc = "VMBI_gametracks_multichoice_desc",
				callback = "VMBI_clbck_setquickgametrack",
				items = VolumeMixerByirbi.qucikacessgametracks,
				value = 1,
				menu_id = "VMBI",
				priority = 11,
			})
			MenuHelper:AddToggle({
				id = "VMBI_QM_G_toggle",
				title = "VMBI_track_toggle",
				desc = "VMBI_track_toggle_desc",
				callback = "VMBI_clbck_QM_G_toggle",
				value = VolumeMixerByirbi.settings.tracks_data[QM_G_base_val.."_toggle"],
				menu_id = "VMBI",
				priority = 10
			})
			MenuHelper:AddSlider({
				id = "VMBI_QM_G_volume",
				title = "VMBI_track_volume",
				desc = "VMBI_empty",
				callback = "VMBI_clbck_QM_G_volume",
				value = VolumeMixerByirbi.settings.tracks_data[QM_G_base_val.."_volume"] or 20,
				min = 0,
				max = 100,
				step = 1,
				show_value = true,
				menu_id = "VMBI",
				disabled = not VolumeMixerByirbi.settings.tracks_data[QM_G_base_val.."_toggle"],
				priority = 9
			})
			MenuHelper:AddMultipleChoice({
				id = "VMBIgametracks_phasechoice",
				title = "VMBI_phase",
				desc = "VMBI_phase_G_desc",
				callback = "VMBI_clbck_gametrackphase",
				items = {"VMBI_default","VMBI_ass1","VMBI_ass2","VMBI_ass3","VMBI_ass4"},
				value = 1,
				menu_id = "VMBI",
				priority = 8,
			})
			MenuHelper:AddDivider({
				id = "VMBIdivider_volumemenu_6",
				size = 16,
				menu_id = "VMBI",
				priority = 7
			})
		else
			DelayedCalls:Add("VMBI_buildQAgametracks_loop", 0.1, function()
				build_quickaccessfor_game()
			end)
		end
	end
	build_quickaccessfor_game()
	
	VolumeMixerByirbi.qucikacessghosttracks = {}
	local function build_quickaccessfor_ghost()
		if managers.music then
			local track_list,track_locked = managers.music:jukebox_ghost_tracks()
			for __, track_name in pairs(track_list or {}) do
				if not track_locked[track_name] then
					table.insert(VolumeMixerByirbi.qucikacessghosttracks,"menu_jukebox_screen_"..track_name)
				end
			end
			local QM_S_base_val = string.sub(VolumeMixerByirbi.qucikacessghosttracks[1], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[1]))
			MenuHelper:AddButton({
				id = "VMBI_ghostmultichoice_header",
				title = "VMBI_ghostmultichoice_header",
				desc = "VMBI_qucikmenu_musicstop",
				callback = "VMBI_clbck_stopallmusic",
				menu_id = "VMBI",
				priority = 6,
			})
			MenuHelper:AddDivider({
				id = "VMBIdivider_volumemenu_7",
				size = 8,
				menu_id = "VMBI",
				priority = 5
			})
			MenuHelper:AddMultipleChoice({
				id = "VMBIghosttracks_multichoice",
				title = "VMBI_empty",
				desc = "VMBI_ghosttracks_multichoice_desc",
				callback = "VMBI_clbck_setquickghosttrack",
				items = VolumeMixerByirbi.qucikacessghosttracks,
				value = 1,
				menu_id = "VMBI",
				priority = 4,
			})
			MenuHelper:AddToggle({
				id = "VMBI_QM_S_toggle",
				title = "VMBI_track_toggle",
				desc = "VMBI_track_toggle_desc",
				callback = "VMBI_clbck_QM_S_toggle",
				value = VolumeMixerByirbi.settings.tracks_data[QM_S_base_val.."_toggle"],
				menu_id = "VMBI",
				priority = 3
			})
			MenuHelper:AddSlider({
				id = "VMBI_QM_S_volume",
				title = "VMBI_track_volume",
				desc = "VMBI_empty",
				callback = "VMBI_clbck_QM_S_volume",
				value = VolumeMixerByirbi.settings.tracks_data[QM_S_base_val.."_volume"] or 20,
				min = 0,
				max = 100,
				step = 1,
				show_value = true,
				menu_id = "VMBI",
				disabled = not VolumeMixerByirbi.settings.tracks_data[QM_S_base_val.."_toggle"],
				priority = 2
			})
			MenuHelper:AddMultipleChoice({
				id = "VMBIghosttracks_phasechoice",
				title = "VMBI_phase",
				desc = "VMBI_phase_S_desc",
				callback = "VMBI_clbck_ghosttrackphase",
				items = {"VMBI_default","VMBI_susp1","VMBI_susp2","VMBI_susp3","VMBI_susp4","VMBI_susp5"},
				value = 1,
				menu_id = "VMBI",
				priority = 1,
			})
		else
			DelayedCalls:Add("VMBI_buildQAghosttracks_loop", 0.1, function()
				build_quickaccessfor_ghost()
			end)
		end
	end
	build_quickaccessfor_ghost()
end)