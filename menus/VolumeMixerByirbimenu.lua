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
	else
		loc:load_localization_file(VolumeMixerByirbi.modpath .. 'menus/lang/VolumeMixerByirbimenu_en.txt', false)
	end
	
	loc:load_localization_file(VolumeMixerByirbi.modpath .. 'menus/lang/VolumeMixerByirbimenu_en.txt', false)
end)

Hooks:PostHook(MenuCallbackHandler, "set_music_volume", "VolumeMixerByirbi_savedefaultvolume", function(self,item)
	log("VMBI_DEBUG: SAVEDDEFAULTVOLUME") -- pretty sure this function is from reeeealy old version of this mod, should be deleted if never called
	VolumeMixerByirbi.settings.defaultvolume = item:value()
	VolumeMixerByirbi:Save()
end)

Hooks:PostHook(MenuManager, "_node_selected", "VolumeMixerByirbi_playmainmenutrack", function(self, menu_name, node)
	if type(node) == "table" and (node._parameters.name == "jukebox_menu_tracks" or node._parameters.name == "jukebox_menu_playlist" or node._parameters.name == "jukebox_heist_tracks" or node._parameters.name == "jukebox_heist_playlist" or node._parameters.name == "jukebox_ghost_tracks" or node._parameters.name == "jukebox_ghost_playlist" or node._parameters.name == "jukebox") then
		VolumeMixerByirbi.playlistcustomizationnode = true
	elseif type(node) == "table" and node._parameters.name == "sound" then
		node._items[2]._enabled = false
		node._items[2]._parameters.help_id = "VMBI_soundsettingtip"
		node._items[2]._slider_color = Color( 31.875, 255, 255, 255 ) / 255
		node._items[2]._slider_color_highlight = Color( 1, 255, 255, 255 ) / 255
		if Utils:IsInGameState() then
			VolumeMixerByirbi.cur_event_ingame = Global.music_manager.current_event
		end
		VolumeMixerByirbi.playlistcustomizationnode = false
	elseif type(node) == "table" and (node == MenuHelper:GetMenu("VMBI_menus") or node == MenuHelper:GetMenu("VMBI_ingame") or node == MenuHelper:GetMenu("VMBI_ghosts")) then
		managers.music:track_listen_stop()
		managers.music:post_event("stop_all_music")
		if Utils:IsInGameState() then
			Global.music_manager.current_event = VolumeMixerByirbi.cur_event_ingame
		else
			Global.music_manager.current_event = "stop_all_music"
		end
		Global.music_manager.current_track = "stop_all_music"
		VolumeMixerByirbi.playlistcustomizationnode = true
	elseif type(node) == "table" and node._parameters.name == "kit" then
		if Network:is_server() then
			managers.music:track_listen_start(Global.music_manager.track_attachment.loadout, "screen_"..Global.music_manager.track_attachment.loadout)
			managers.music:post_event(Global.music_manager.track_attachment.loadout)
		end
		VolumeMixerByirbi.playlistcustomizationnode = false
	elseif type(node) == "table" and node == MenuHelper:GetMenu("VMBI") then
		VolumeMixerByirbi.playlistcustomizationnode = true
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(MenuHelper:GetMenu("VMBI"))
	elseif type(node) == "table" and (node._parameters.name == "main" or node._parameters.name == "lobby") then
		VolumeMixerByirbi.playlistcustomizationnode = false
		-- a really dumb failsafe, since after getting out of the game and into the menu/lobby
		-- our event gets reset to music id but track stays the same as it was in the game
		-- so we have to make sure that our 'track' is set correctly, but we only have to do it once after getting to the menu after the game ends
		if not VolumeMixerByirbi.menucheck then
			Global.music_manager.current_track = Global.music_manager.current_event
			VolumeMixerByirbi.menucheck = 1
		end
		-- make sure to set our music volume to current track's volume when getting into the main menu or lobby, to prevent volume beeing incorrect for 0.1 seconds after entering those menus
		local track = Global.music_manager.current_track
		if VolumeMixerByirbi:checktrack(track) == true then
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track.."_volume"])
		else
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
		end
	else
		VolumeMixerByirbi.playlistcustomizationnode = false
	end
end)

Hooks:Add('MenuManagerInitialize', 'VolumeMixerByirbi_init', function(menu_manager)
	MenuCallbackHandler.VMBI_clbck_VolumeMixerByirbisave = function(this, item)
		VolumeMixerByirbi:Save()
	end
	
	MenuCallbackHandler.VMBI_clbck_donothing = function(this, item)
		-- do nothing
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
		managers.user:set_setting("music_volume", item:value())
		VolumeMixerByirbi.settings.defaultvolume = tonumber(item:value())
		VolumeMixerByirbi:Save()
	end
	
	MenuCallbackHandler.VMBI_clbck_onVMBImenuquit = function(this, item)
		if not Utils:IsInGameState() then
			if Global.music_manager.current_event == "stop_all_music" then
				managers.music:post_event(managers.music:jukebox_menu_track("mainmenu"))
			end
		else
			if Global.music_manager.current_track == "stop_all_music" then
				local CE = Global.music_manager.current_event
				local switches = tweak_data.levels:get_music_switches()
				local selected_track = switches[math.random(1,#switches)]
				managers.music:track_listen_start(CE, selected_track)
				managers.music:post_event(selected_track)
				managers.music:post_event(CE)
				managers.music._skip_play = nil
				Global.music_manager.current_track = selected_track
			end
		end
		VolumeMixerByirbi:Save()
	end
	
	MenuCallbackHandler.VMBI_clbck_ontrackmenuquitstopmusicandsave = function(this, item)
		managers.music:track_listen_stop()
		managers.music:music_ext_listen_stop()
		managers.music:post_event("stop_all_music")
		Global.music_manager.source:stop()
		Global.music_manager.current_track = "stop_all_music"
		if Utils:IsInGameState() then
			Global.music_manager.current_event = VolumeMixerByirbi.cur_event_ingame
		else
			Global.music_manager.current_event = "stop_all_music"
		end
		VolumeMixerByirbi:Save()
	end
	
	MenuCallbackHandler.VMBI_clbck_stopallmusic = function(this, item)
		if not Utils:IsInGameState() then
			Global.music_manager.source:stop()
			managers.music:track_listen_stop()
			managers.music:music_ext_listen_stop()
			managers.music:post_event("stop_all_music")
			Global.music_manager.current_track = "stop_all_music"
			Global.music_manager.current_event = "stop_all_music"
		end
	end
	
	--################################# Basic menus: menu music callbacks #########################################################
	
	MenuCallbackHandler.VMBI_clbck_playtrackonnameclick = function(this, item)
		local track_id = string.sub(item:name(), 13, string.len(item:name()))
		--local CE = Global.music_manager.current_event
		if Global.music_manager.current_track ~= "screen_"..track_id then
			managers.music:track_listen_stop()
			managers.music:post_event("stop_all_music")
			managers.music:track_listen_start(track_id, "screen_"..track_id)
			managers.music:post_event("screen_"..track_id)
			if Utils:IsInGameState() then
				Global.music_manager.current_event = VolumeMixerByirbi.cur_event_ingame
			else
				Global.music_manager.current_event = "screen_"..track_id
			end
			Global.music_manager.current_track = "screen_"..track_id
			if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
			end
		else
			managers.music:track_listen_stop()
			managers.music:post_event("stop_all_music")
			if Utils:IsInGameState() then
				Global.music_manager.current_event = CE
			else
				Global.music_manager.current_event = "screen_"..track_id
			end
			Global.music_manager.current_track = "stop_all_music"
		end
	end
	
	MenuCallbackHandler.VMBI_clbck_enablecustomvolume_menus = function(this, item)
		local track_id = string.sub(item:name(), 18, string.len(item:name()))
		local node = MenuHelper:GetMenu("VMBI_menus")
		VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] = item:value() == 'on'
		for i=1,#node._items do
			if string.sub(node._items[i]._parameters.name, 18, string.len(node._items[i]._parameters.name)) == track_id and string.sub(node._items[i]._parameters.name, 1, 17) == "VMBItrack_volume_" then
				node._items[i]:set_enabled(not node._items[i]:enabled())
				break
			end
		end
		
		-- update quick menu gui after tweaking track data in the music menu
		local backmenunode = MenuHelper:GetMenu("VMBI")
		if not VolumeMixerByirbi.QM_M_track_id then
			VolumeMixerByirbi.QM_M_track_id = string.sub(VolumeMixerByirbi.qucikacessmenutracks[1], 21, string.len(VolumeMixerByirbi.qucikacessmenutracks[1]))
		end
		if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_toggle"] == false then
			backmenunode._items[14].selected = 2
		else
			backmenunode._items[14].selected = 1
		end
		backmenunode._items[15]:set_enabled(VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_toggle"])
		backmenunode._items[15]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_volume"]
		
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
		if Global.music_manager.current_track == "screen_"..track_id then
			if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		end
		VolumeMixerByirbi:Save()
	end

	MenuCallbackHandler.VMBI_clbck_savecustomvolumefortrack_menus = function(this, item)
		local track_id = string.sub(item:name(), 18, string.len(item:name()))
		VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"] = tonumber(item:value())
		if Global.music_manager.current_track == "screen_"..track_id then
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
		end
		-- update quick menu gui after tweaking track data in the music menu
		local backmenunode = MenuHelper:GetMenu("VMBI")
		if not VolumeMixerByirbi.QM_M_track_id then
			VolumeMixerByirbi.QM_M_track_id = string.sub(VolumeMixerByirbi.qucikacessmenutracks[1], 21, string.len(VolumeMixerByirbi.qucikacessmenutracks[1]))
		end
		backmenunode._items[15]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_volume"]
		VolumeMixerByirbi:Save()
	end

--######################################### Basic menus: heist music callbacks #########################################################

	MenuCallbackHandler.VMBI_clbck_playgametrackonnameclick = function(this, item)
		local track_id = string.sub(item:name(), 17, string.len(item:name()))
		--local CE = Global.music_manager.current_event
		if Global.music_manager.current_track ~= track_id then
			managers.music:track_listen_stop()
			managers.music:post_event("stop_all_music")
			if Utils:IsInGameState() then
				managers.music:track_listen_start(VolumeMixerByirbi.cur_event_ingame, track_id)
				managers.music:post_event(track_id)
				managers.music:post_event(VolumeMixerByirbi.cur_event_ingame)
			else
				managers.music:track_listen_start("music_heist_assault", track_id)
				Global.music_manager.current_event = track_id
				managers.music:post_event(track_id)
			end	
			Global.music_manager.current_track = track_id
			if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
			end
		else
			managers.music:track_listen_stop()
			managers.music:post_event("stop_all_music")
			Global.music_manager.source:stop()
			Global.music_manager.current_event = "stop_all_music"
			Global.music_manager.current_track = "stop_all_music"
		end
	end
	
	MenuCallbackHandler.VMBI_clbck_enablecustomvolume_game = function(this, item)
		local track_id = string.sub(item:name(), 22, string.len(item:name()))
		local node = MenuHelper:GetMenu("VMBI_ingame")
		VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] = item:value() == 'on'
		for i=1,#node._items do
			if string.sub(node._items[i]._parameters.name, 22, string.len(node._items[i]._parameters.name)) == track_id and string.sub(node._items[i]._parameters.name, 1, 21) == "VMBIgametrack_volume_" then
				node._items[i]:set_enabled(not node._items[i]:enabled())
				break
			end
		end
		
		-- update quick menu gui after tweaking track data in the game menu
		local backmenunode = MenuHelper:GetMenu("VMBI")
		if not VolumeMixerByirbi.QM_G_track_id then
			VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[1], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[1]))
		end
		if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_toggle"] == false then
			backmenunode._items[20].selected = 2
		else
			backmenunode._items[20].selected = 1
		end
		backmenunode._items[21]:set_enabled(VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_toggle"])
		backmenunode._items[21]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_volume"]
		
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
		if Global.music_manager.current_track == track_id then
			if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		end
		VolumeMixerByirbi:Save()
	end
	
	MenuCallbackHandler.VMBI_clbck_savecustomvolumefortrack_game = function(this, item)
		local track_id = string.sub(item:name(), 22, string.len(item:name()))
		VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"] = tonumber(item:value())
		if Global.music_manager.current_track == track_id then
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
		end
		-- update quick menu gui after tweaking track data in the game menu
		local backmenunode = MenuHelper:GetMenu("VMBI")
		if not VolumeMixerByirbi.QM_G_track_id then
			VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[1], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[1]))
		end
		backmenunode._items[21]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_volume"]
		VolumeMixerByirbi:Save()
	end
	
	--################################### Basic menus: stealth music callbacks ######################################
	
	MenuCallbackHandler.VMBI_clbck_playghosttrackonnameclick = function(this, item)
		local track_id = string.sub(item:name(), 18, string.len(item:name()))
		--local CE = Global.music_manager.current_event
		if Global.music_manager.current_track ~= "screen_"..track_id then
			if Utils:IsInGameState() then
				Global.music_manager.source:stop()
				managers.music:track_listen_start("screen_"..track_id, "screen_"..track_id)
				managers.music:track_listen_stop()
				Global.music_manager.source:post_event(track_id)
				managers.music:post_event(VolumeMixerByirbi.cur_event_ingame)
			else
				managers.music:track_listen_stop()
				managers.music:post_event("stop_all_music")
				managers.music:track_listen_start(track_id, "screen_"..track_id)
				Global.music_manager.source:stop()
				managers.music:post_event(track_id)
				Global.music_manager.source:post_event("suspense_4")
				managers.music:music_ext_listen_start(track_id)
				Global.music_manager.current_track = "screen_"..track_id
				Global.music_manager.current_event = "suspense_4"
			end
			if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
			end
		else
			if not Utils:IsInGameState() then
				managers.music:music_ext_listen_stop(track_id)
			end
			managers.music:track_listen_stop()
			managers.music:post_event("stop_all_music")
			Global.music_manager.current_track = "stop_all_music"
			Global.music_manager.current_event = VolumeMixerByirbi.cur_event_ingame
		end
	end
	
	MenuCallbackHandler.VMBI_clbck_enablecustomvolume_ghost = function(this, item)
		local track_id = string.sub(item:name(), 23, string.len(item:name()))
		local node = MenuHelper:GetMenu("VMBI_ghosts")
		VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] = item:value() == 'on'
		for i=1,#node._items do
			if string.sub(node._items[i]._parameters.name, 23, string.len(node._items[i]._parameters.name)) == track_id and string.sub(node._items[i]._parameters.name, 1, 22) == "VMBIghosttrack_volume_" then
				node._items[i]:set_enabled(not node._items[i]:enabled())
				break
			end
		end
		
		-- update quick menu gui after tweaking track data in the music menu
		local backmenunode = MenuHelper:GetMenu("VMBI")
		if not VolumeMixerByirbi.QM_S_track_id then
			VolumeMixerByirbi.QM_S_track_id = string.sub(VolumeMixerByirbi.qucikacessghosttracks[1], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[1]))
		end
		if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_toggle"] == false then
			backmenunode._items[26].selected = 2
		else
			backmenunode._items[26].selected = 1
		end
		backmenunode._items[27]:set_enabled(VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_toggle"])
		backmenunode._items[27]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_volume"]
		
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
		if Global.music_manager.current_track == "screen_"..track_id then
			if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		end
		VolumeMixerByirbi:Save()
	end

	MenuCallbackHandler.VMBI_clbck_savecustomvolumefortrack_ghost = function(this, item)
		local track_id = string.sub(item:name(), 23, string.len(item:name()))
		VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"] = tonumber(item:value())
		if Global.music_manager.current_track == "screen_"..track_id then
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
		end
		-- update quick menu gui after tweaking track data in the music menu
		local backmenunode = MenuHelper:GetMenu("VMBI")
		if not VolumeMixerByirbi.QM_S_track_id then
			VolumeMixerByirbi.QM_S_track_id = string.sub(VolumeMixerByirbi.qucikacessghosttracks[1], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[1]))
		end
		backmenunode._items[27]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_volume"]
		VolumeMixerByirbi:Save()
	end
	
	--################################### QUICK MENUS: menu music callbacks ######################################
	
	MenuCallbackHandler.VMBI_clbck_setquickmenutrack = function(this, item)
		VolumeMixerByirbi.QM_M_track_id = string.sub(VolumeMixerByirbi.qucikacessmenutracks[item:value()], 21, string.len(VolumeMixerByirbi.qucikacessmenutracks[item:value()]))
		local node = MenuHelper:GetMenu("VMBI")
		if Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_M_track_id then
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
			if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume",  VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		end
		if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_toggle"] == false then
			node._items[14].selected = 2
		else
			node._items[14].selected = 1
		end
		node._items[15]:set_enabled(VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_toggle"])
		node._items[15]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_volume"]
		
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
		
	end
	
	MenuCallbackHandler.VMBI_clbck_QM_M_toggle = function(this, item)
		if not VolumeMixerByirbi.QM_M_track_id then
			VolumeMixerByirbi.QM_M_track_id = string.sub(VolumeMixerByirbi.qucikacessmenutracks[1], 21, string.len(VolumeMixerByirbi.qucikacessmenutracks[1]))
		end
		if Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_M_track_id then
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
		local node = MenuHelper:GetMenu("VMBI")
		VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_toggle"] = item:value() == 'on'
		node._items[15]:set_enabled(not node._items[15]:enabled())
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
		local track_id = VolumeMixerByirbi.QM_M_track_id
		local newnode = MenuHelper:GetMenu("VMBI_menus")
		for i=1,#newnode._items do
			if string.sub(newnode._items[i]._parameters.name, 18, string.len(newnode._items[i]._parameters.name)) == track_id and string.sub(newnode._items[i]._parameters.name, 1, 17) == "VMBItrack_toggle_" then
				if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == false then
					newnode._items[i].selected = 2
				else
					newnode._items[i].selected = 1
				end
				newnode._items[i+1]:set_enabled(not newnode._items[i+1]:enabled())
				break
			end
		end
		VolumeMixerByirbi:Save()
		
		if Global.music_manager.current_track == "screen_"..VolumeMixerByirbi.QM_M_track_id then
			if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		end
	end

	MenuCallbackHandler.VMBI_clbck_QM_M_volume = function(this, item)
		if not VolumeMixerByirbi.QM_M_track_id then
			VolumeMixerByirbi.QM_M_track_id = string.sub(VolumeMixerByirbi.qucikacessmenutracks[1], 21, string.len(VolumeMixerByirbi.qucikacessmenutracks[1]))
		end
		if Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_M_track_id then
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
		local track_id = VolumeMixerByirbi.QM_M_track_id
		local newnode = MenuHelper:GetMenu("VMBI_menus")
		for i=1,#newnode._items do
			if string.sub(newnode._items[i]._parameters.name, 18, string.len(newnode._items[i]._parameters.name)) == track_id and string.sub(newnode._items[i]._parameters.name, 1, 17) == "VMBItrack_toggle_" then
				newnode._items[i+1]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_volume"]
				break
			end
		end
		
		VolumeMixerByirbi:Save()
		if Global.music_manager.current_track == "screen_"..VolumeMixerByirbi.QM_M_track_id then
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_volume"])
		end
	end
	
	--################################### QUICK MENUS: heist music callbacks ######################################
	
	MenuCallbackHandler.VMBI_clbck_setquickgametrack = function(this, item)
		VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[item:value()], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[item:value()]))
		local node = MenuHelper:GetMenu("VMBI")
		local CE = Global.music_manager.current_event
		if Global.music_manager.current_track ~= VolumeMixerByirbi.QM_G_track_id then
			if Utils:IsInGameState() then
				managers.music:track_listen_start(CE, VolumeMixerByirbi.QM_G_track_id)
				managers.music:post_event(VolumeMixerByirbi.QM_G_track_id)
				managers.music:post_event(CE)
				managers.music._skip_play = nil
				Global.music_manager.loadout_selection = VolumeMixerByirbi.QM_G_track_id
			else
				managers.music:track_listen_start("music_heist_assault", VolumeMixerByirbi.QM_G_track_id)
				Global.music_manager.current_event = VolumeMixerByirbi.QM_G_track_id
				managers.music:post_event(VolumeMixerByirbi.QM_G_track_id)
			end
			Global.music_manager.current_track = VolumeMixerByirbi.QM_G_track_id
			if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume",  VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		end
		if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_toggle"] == false then
			node._items[20].selected = 2
		else
			node._items[20].selected = 1
		end
		node._items[21]:set_enabled(VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_toggle"])
		node._items[21]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_volume"]
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)	
	end
	
	MenuCallbackHandler.VMBI_clbck_QM_G_toggle = function(this, item)
		local CE = Global.music_manager.current_event
		if not VolumeMixerByirbi.QM_G_track_id then
			VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[1], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[1]))
		end
		if Global.music_manager.current_track ~= VolumeMixerByirbi.QM_G_track_id then
			if Utils:IsInGameState() then
				managers.music:track_listen_start(CE, VolumeMixerByirbi.QM_G_track_id)
				managers.music:post_event(VolumeMixerByirbi.QM_G_track_id)
				managers.music:post_event(CE)
			else
				managers.music:track_listen_start("music_heist_assault", VolumeMixerByirbi.QM_G_track_id)
				Global.music_manager.current_event = VolumeMixerByirbi.QM_G_track_id
				managers.music:post_event(VolumeMixerByirbi.QM_G_track_id)
			end
			Global.music_manager.current_track = VolumeMixerByirbi.QM_G_track_id
		end
		local node = MenuHelper:GetMenu("VMBI")
		VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_toggle"] = item:value() == 'on'
		node._items[21]:set_enabled(not node._items[21]:enabled())
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
		local track_id = VolumeMixerByirbi.QM_G_track_id
		local newnode = MenuHelper:GetMenu("VMBI_ingame")
		for i=1,#newnode._items do
			if string.sub(newnode._items[i]._parameters.name, 22, string.len(newnode._items[i]._parameters.name)) == track_id and string.sub(newnode._items[i]._parameters.name, 1, 21) == "VMBIgametrack_toggle_" then
				if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == false then
					newnode._items[i].selected = 2
				else
					newnode._items[i].selected = 1
				end
				newnode._items[i+1]:set_enabled(not newnode._items[i+1]:enabled())
				break
			end
		end
		VolumeMixerByirbi:Save()
		if Global.music_manager.current_track == VolumeMixerByirbi.QM_G_track_id then
			if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		end
	end
	
	MenuCallbackHandler.VMBI_clbck_QM_G_volume = function(this, item)
		local CE = Global.music_manager.current_event
		if not VolumeMixerByirbi.QM_G_track_id then
			VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[1], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[1]))
		end
		if Global.music_manager.current_track ~= VolumeMixerByirbi.QM_G_track_id then
			if Utils:IsInGameState() then
				managers.music:track_listen_start(CE, VolumeMixerByirbi.QM_G_track_id)
				managers.music:post_event(VolumeMixerByirbi.QM_G_track_id)
				managers.music:post_event(CE)
			else
				managers.music:track_listen_start("music_heist_assault", VolumeMixerByirbi.QM_G_track_id)
				Global.music_manager.current_event = VolumeMixerByirbi.QM_G_track_id
				managers.music:post_event(VolumeMixerByirbi.QM_G_track_id)
			end
			Global.music_manager.current_track = VolumeMixerByirbi.QM_G_track_id
		end
		VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_volume"] = tonumber(item:value())
		local track_id = VolumeMixerByirbi.QM_G_track_id
		local newnode = MenuHelper:GetMenu("VMBI_ingame")
		for i=1,#newnode._items do
			if string.sub(newnode._items[i]._parameters.name, 22, string.len(newnode._items[i]._parameters.name)) == track_id and string.sub(newnode._items[i]._parameters.name, 1, 21) == "VMBIgametrack_toggle_" then
				newnode._items[i+1]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_volume"]
				break
			end
		end
		VolumeMixerByirbi:Save()
		if Global.music_manager.current_track == VolumeMixerByirbi.QM_G_track_id then
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_G_track_id.."_volume"])
		end
	end
	
	local function VMBI_play_G_trackphase(phase)
	local CE = Global.music_manager.current_event
	managers.music._skip_play = nil
		if Utils:IsInGameState() then
			if phase == "Default" then
				Global.music_manager.source:stop()
				if Global.music_manager.current_track ~= VolumeMixerByirbi.QM_G_track_id then
					managers.music:track_listen_start(CE, VolumeMixerByirbi.QM_G_track_id)
				end
				Global.music_manager.source:post_event(CE)
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
			else
				if phase == "music_heist_setup" then
					managers.music:post_event("stop_all_music")
					managers.music:track_listen_start("music_heist_setup", VolumeMixerByirbi.QM_G_track_id)
				end
				managers.music:post_event(phase)
				Global.music_manager.current_event = CE
				managers.music._skip_play = true
			end
		else
			if Global.music_manager.current_track ~= VolumeMixerByirbi.QM_G_track_id then
				managers.music:track_listen_stop()
				managers.music:post_event("stop_all_music")
				managers.music:track_listen_start(VolumeMixerByirbi.QM_G_track_id, VolumeMixerByirbi.QM_G_track_id)
				Global.music_manager.source:stop()
				Global.music_manager.source:post_event(VolumeMixerByirbi.QM_G_track_id)
				Global.music_manager.source:post_event(phase)
				Global.music_manager.current_track = VolumeMixerByirbi.QM_G_track_id
				Global.music_manager.current_event = phase
			else
				Global.music_manager.source:post_event(phase)
				Global.music_manager.current_event = phase
			end
		end
	end
	
	MenuCallbackHandler.VMBI_clbck_gametrackphase = function(this, item)
		if not VolumeMixerByirbi.QM_G_track_id then
			VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[1], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[1]))
		end
		
		if item:value() == 1 then
			VMBI_play_G_trackphase("Default")
		else
			if item:value() == 2 then
				VMBI_play_G_trackphase("music_heist_setup")
			elseif item:value() == 3 then
				VMBI_play_G_trackphase("music_heist_control")
			elseif item:value() == 4 then
				VMBI_play_G_trackphase("music_heist_anticipation")
			elseif item:value() == 5 then
				VMBI_play_G_trackphase("music_heist_assault")
			end
		end
	end
	
	
	--################################### QUICK MENUS: stealth music callbacks ######################################
	
	MenuCallbackHandler.VMBI_clbck_setquickghosttrack = function(this, item)
		VolumeMixerByirbi.QM_S_track_id = string.sub(VolumeMixerByirbi.qucikacessghosttracks[item:value()], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[item:value()]))
		local node = MenuHelper:GetMenu("VMBI")
		local CE = Global.music_manager.current_event
		if Utils:IsInGameState() then
			if Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_S_track_id then
				Global.music_manager.source:stop()
				managers.music:track_listen_start("screen_"..VolumeMixerByirbi.QM_S_track_id, "screen_"..VolumeMixerByirbi.QM_S_track_id)
				managers.music:track_listen_stop()
				Global.music_manager.source:post_event(VolumeMixerByirbi.QM_S_track_id)
				managers.music:post_event(CE)
			end
		else
			if Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_S_track_id then
				managers.music:track_listen_stop()
				managers.music:post_event("stop_all_music")
				managers.music:track_listen_start(VolumeMixerByirbi.QM_S_track_id, "screen_"..VolumeMixerByirbi.QM_S_track_id)
				Global.music_manager.source:stop()
				Global.music_manager.source:post_event(VolumeMixerByirbi.QM_S_track_id)
				Global.music_manager.source:post_event("suspense_4")
				Global.music_manager.current_track = "screen_"..VolumeMixerByirbi.QM_S_track_id
				Global.music_manager.current_event = "suspense_4"
			end
		end
		if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_toggle"] == true then
			managers.user:set_setting("music_volume",  VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_volume"])
		else
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
		end
		if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_toggle"] == false then
			node._items[27].selected = 2
		else
			node._items[27].selected = 1
		end
		node._items[28]:set_enabled(VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_toggle"])
		node._items[28]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_volume"]
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
	end
	
	MenuCallbackHandler.VMBI_clbck_QM_S_toggle = function(this, item)
		local CE = Global.music_manager.current_event
		if not VolumeMixerByirbi.QM_S_track_id then
			VolumeMixerByirbi.QM_S_track_id = string.sub(VolumeMixerByirbi.qucikacessghosttracks[1], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[1]))
		end
		if Utils:IsInGameState() then
			if Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_S_track_id then
				Global.music_manager.source:stop()
				managers.music:track_listen_start("screen_"..VolumeMixerByirbi.QM_S_track_id, "screen_"..VolumeMixerByirbi.QM_S_track_id)
				managers.music:track_listen_stop()
				Global.music_manager.source:post_event(VolumeMixerByirbi.QM_S_track_id)
				managers.music:post_event(CE)
			end
		else
			if Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_S_track_id then
				managers.music:track_listen_stop()
				managers.music:post_event("stop_all_music")
				managers.music:track_listen_start(VolumeMixerByirbi.QM_S_track_id, "screen_"..VolumeMixerByirbi.QM_S_track_id)
				Global.music_manager.source:stop()
				Global.music_manager.source:post_event(VolumeMixerByirbi.QM_S_track_id)
				Global.music_manager.source:post_event("suspense_4")
				Global.music_manager.current_track = "screen_"..VolumeMixerByirbi.QM_S_track_id
				Global.music_manager.current_event = "suspense_4"
			end
		end
		local node = MenuHelper:GetMenu("VMBI")
		VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_toggle"] = item:value() == 'on'
		node._items[28]:set_enabled(not node._items[28]:enabled())
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
		local track_id = VolumeMixerByirbi.QM_S_track_id
		local newnode = MenuHelper:GetMenu("VMBI_ghosts")
		for i=1,#newnode._items do
			if string.sub(newnode._items[i]._parameters.name, 23, string.len(newnode._items[i]._parameters.name)) == track_id and string.sub(newnode._items[i]._parameters.name, 1, 22) == "VMBIghosttrack_toggle_" then
				if VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == false then
					newnode._items[i].selected = 2
				else
					newnode._items[i].selected = 1
				end
				newnode._items[i+1]:set_enabled(not newnode._items[i+1]:enabled())
				break
			end
		end
		VolumeMixerByirbi:Save()
		if Global.music_manager.current_track == "screen_"..VolumeMixerByirbi.QM_S_track_id then 
			if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		end
	end
	
	MenuCallbackHandler.VMBI_clbck_QM_S_volume = function(this, item)
		local CE = Global.music_manager.current_event
		if not VolumeMixerByirbi.QM_S_track_id then
			VolumeMixerByirbi.QM_S_track_id = string.sub(VolumeMixerByirbi.qucikacessghosttracks[1], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[1]))
			managers.music:track_listen_stop()
		end
		if Utils:IsInGameState() then
			if Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_S_track_id then
				Global.music_manager.source:stop()
				managers.music:track_listen_start("screen_"..VolumeMixerByirbi.QM_S_track_id, "screen_"..VolumeMixerByirbi.QM_S_track_id)
				managers.music:track_listen_stop()
				Global.music_manager.source:post_event(VolumeMixerByirbi.QM_S_track_id)
				managers.music:post_event(CE)
			end
		else
			if Global.music_manager.current_track ~= "screen_"..VolumeMixerByirbi.QM_S_track_id then
				managers.music:track_listen_stop()
				managers.music:post_event("stop_all_music")
				managers.music:track_listen_start(VolumeMixerByirbi.QM_S_track_id, "screen_"..VolumeMixerByirbi.QM_S_track_id)
				Global.music_manager.source:stop()
				Global.music_manager.source:post_event(VolumeMixerByirbi.QM_S_track_id)
				Global.music_manager.source:post_event("suspense_4")
				Global.music_manager.current_track = "screen_"..VolumeMixerByirbi.QM_S_track_id
				Global.music_manager.current_event = "suspense_4"
			end
		end
		VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_volume"] = tonumber(item:value())
		local track_id = VolumeMixerByirbi.QM_S_track_id
		local newnode = MenuHelper:GetMenu("VMBI_ghosts")
		for i=1,#newnode._items do
			if string.sub(newnode._items[i]._parameters.name, 23, string.len(newnode._items[i]._parameters.name)) == track_id and string.sub(newnode._items[i]._parameters.name, 1, 22) == "VMBIghosttrack_toggle_" then
				newnode._items[i+1]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_volume"]
				break
			end
		end
		VolumeMixerByirbi:Save()
		if Global.music_manager.current_track == "screen_"..VolumeMixerByirbi.QM_S_track_id then
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_volume"])
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
				if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_toggle"] == true then
					managers.user:set_setting("music_volume",  VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_volume"])
				else
					managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
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
			if VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume",  VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_S_track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
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
			managers.music:track_listen_stop()
		end
		
		if item:value() == 1 then
			VMBI_play_S_trackphase("Default")
		else
			if item:value() == 2 then
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
	end

	VolumeMixerByirbi:Load()

	MenuHelper:LoadFromJsonFile(VolumeMixerByirbi.modpath .. 'menus/VolumeMixerByirbimenu.txt', VolumeMixerByirbi, VolumeMixerByirbi.settings)
	MenuHelper:LoadFromJsonFile(VolumeMixerByirbi.modpath .. 'menus/VolumeMixerByirbimenu_ghosttracks.txt', VolumeMixerByirbi, VolumeMixerByirbi.settings)
	MenuHelper:LoadFromJsonFile(VolumeMixerByirbi.modpath .. 'menus/VolumeMixerByirbimenu_ingametracks.txt', VolumeMixerByirbi, VolumeMixerByirbi.settings)
	MenuHelper:LoadFromJsonFile(VolumeMixerByirbi.modpath .. 'menus/VolumeMixerByirbimenu_menutracks.txt', VolumeMixerByirbi, VolumeMixerByirbi.settings)
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
			--[[
			MenuHelper:AddDivider({
				id = "VMBIdivider_volumemenu_8",
				size = 16,
				menu_id = "VMBI",
				priority = 1
			})]]
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
	
	local function build_menutracks_menu()
		if managers.music then
			local _prior = 999999
			local track_list,track_locked = managers.music:jukebox_menu_tracks()
			for __, track_name in pairs(track_list or {}) do
				if not track_locked[track_name] then
					MenuHelper:AddButton({
						id = "VMBItrackID_"..track_name,
						title = "menu_jukebox_screen_" .. track_name,
						desc = "VMBI_track_header_desc",
						callback = "VMBI_clbck_playtrackonnameclick",
						menu_id = "VMBI_menus",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddToggle({
						id = "VMBItrack_toggle_"..track_name,
						title = "VMBI_track_toggle",
						desc = "VMBI_track_toggle_desc",
						callback = "VMBI_clbck_enablecustomvolume_menus",
						value = VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"],
						menu_id = "VMBI_menus",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddSlider({
						id = "VMBItrack_volume_"..track_name,
						title = "VMBI_track_volume",
						desc = "VMBI_empty",
						callback = "VMBI_clbck_savecustomvolumefortrack_menus",
						value = VolumeMixerByirbi.settings.tracks_data[track_name.."_volume"] or 20,
						min = 0,
						max = 100,
						step = 1,
						show_value = true,
						menu_id = "VMBI_menus",
						disabled = not VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"],
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddDivider({
						id = "VMBIdividerafter_"..track_name,
						size = 16,
						menu_id = "VMBI_menus",
						priority = _prior
					})
					_prior = _prior -1
				else -- build locked tracks, but disable interactions
					MenuHelper:AddButton({
						id = "VMBItrackID_"..track_name,
						title = "menu_jukebox_screen_" .. track_name,
						desc = "VMBI_locked_track_desc",
						callback = "VMBI_clbck_donothing",
						disabled = true,
						menu_id = "VMBI_menus",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddToggle({
						id = "VMBItrack_toggle_"..track_name,
						title = "VMBI_track_toggle",
						desc = "VMBI_empty",
						callback = "VMBI_clbck_donothing",
						value = VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"],
						disabled = true,
						menu_id = "VMBI_menus",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddSlider({
						id = "VMBItrack_volume_"..track_name,
						title = "VMBI_track_volume",
						desc = "VMBI_empty",
						callback = "VMBI_clbck_donothing",
						value = VolumeMixerByirbi.settings.tracks_data[track_name.."_volume"] or 20,
						min = 0,
						max = 100,
						step = 1,
						show_value = true,
						menu_id = "VMBI_menus",
						disabled = true,
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddDivider({
						id = "VMBIdividerafter_"..track_name,
						size = 16,
						menu_id = "VMBI_menus",
						priority = _prior
					})
					_prior = _prior -1
				end
			end
		else
			DelayedCalls:Add("VMBI_buildmenutracks_loop", 0.1, function()
				build_menutracks_menu()
			end)
		end
	end
	build_menutracks_menu()
	local function build_menutracks_ingame()
		if managers.music then
			local _prior = 999999
			local track_list,track_locked = managers.music:jukebox_music_tracks()
			for __, track_name in pairs(track_list or {}) do
				if not track_locked[track_name] then
					MenuHelper:AddButton({
						id = "VMBIgametrackID_"..track_name,
						title = "menu_jukebox_" .. track_name,
						desc = "VMBI_track_header_desc",
						callback = "VMBI_clbck_playgametrackonnameclick",
						menu_id = "VMBI_ingame",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddToggle({
						id = "VMBIgametrack_toggle_"..track_name,
						title = "VMBI_track_toggle",
						desc = "VMBI_track_toggle_desc",
						callback = "VMBI_clbck_enablecustomvolume_game",
						value = VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"],
						menu_id = "VMBI_ingame",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddSlider({
						id = "VMBIgametrack_volume_"..track_name,
						title = "VMBI_track_volume",
						desc = "VMBI_empty",
						callback = "VMBI_clbck_savecustomvolumefortrack_game",
						value = VolumeMixerByirbi.settings.tracks_data[track_name.."_volume"] or 20,
						min = 0,
						max = 100,
						step = 1,
						show_value = true,
						disabled = not VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"],
						menu_id = "VMBI_ingame",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddDivider({
						id = "VMBIgamedividerafter_"..track_name,
						size = 16,
						menu_id = "VMBI_ingame",
						priority = _prior
					})
					_prior = _prior -1
				else
					MenuHelper:AddButton({
						id = "VMBIgametrackID_"..track_name,
						title = "menu_jukebox_" .. track_name,
						desc = "VMBI_locked_track_desc",
						callback = "VMBI_clbck_donothing",
						disabled = true,
						menu_id = "VMBI_ingame",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddToggle({
						id = "VMBIgametrack_toggle_"..track_name,
						title = "VMBI_track_toggle",
						desc = "VMBI_empty",
						callback = "VMBI_clbck_donothing",
						value = VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"],
						disabled = true,
						menu_id = "VMBI_ingame",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddSlider({
						id = "VMBIgametrack_volume_"..track_name,
						title = "VMBI_track_volume",
						desc = "VMBI_empty",
						callback = "VMBI_clbck_donothing",
						value = VolumeMixerByirbi.settings.tracks_data[track_name.."_volume"] or 20,
						min = 0,
						max = 100,
						step = 1,
						show_value = true,
						disabled = true,
						menu_id = "VMBI_ingame",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddDivider({
						id = "VMBIgamedividerafter_"..track_name,
						size = 16,
						menu_id = "VMBI_ingame",
						priority = _prior
					})
					_prior = _prior -1
				end
			end
		else
			DelayedCalls:Add("VMBI_buildingametracks_loop", 0.1, function()
				build_menutracks_menu()
			end)
		end
	end
	build_menutracks_ingame()
	local function build_menutracks_ghosts()
		if managers.music then
			local _prior = 999999
			local track_list,track_locked = managers.music:jukebox_ghost_tracks()
			for __, track_name in pairs(track_list or {}) do
				if not track_locked[track_name] then
					MenuHelper:AddButton({
						id = "VMBIghosttrackID_"..track_name,
						title = "menu_jukebox_screen_" .. track_name,
						desc = "VMBI_track_header_desc",
						callback = "VMBI_clbck_playghosttrackonnameclick",
						menu_id = "VMBI_ghosts",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddToggle({
						id = "VMBIghosttrack_toggle_"..track_name,
						title = "VMBI_track_toggle",
						desc = "VMBI_track_toggle_desc",
						callback = "VMBI_clbck_enablecustomvolume_ghost",
						value = VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"],
						menu_id = "VMBI_ghosts",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddSlider({
						id = "VMBIghosttrack_volume_"..track_name,
						title = "VMBI_track_volume",
						desc = "VMBI_empty",
						callback = "VMBI_clbck_savecustomvolumefortrack_ghost",
						value = VolumeMixerByirbi.settings.tracks_data[track_name.."_volume"] or 20,
						min = 0,
						max = 100,
						step = 1,
						show_value = true,
						menu_id = "VMBI_ghosts",
						disabled = not VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"],
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddDivider({
						id = "VMBIdividerafter_"..track_name,
						size = 16,
						menu_id = "VMBI_ghosts",
						priority = _prior
					})
					_prior = _prior -1
				else -- build locked tracks, but disable interactions
					MenuHelper:AddButton({
						id = "VMBIghoststrackID_"..track_name,
						title = "menu_jukebox_screen_" .. track_name,
						desc = "VMBI_locked_track_desc",
						callback = "VMBI_clbck_donothing",
						disabled = true,
						menu_id = "VMBI_ghosts",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddToggle({
						id = "VMBIghosttrack_toggle_"..track_name,
						title = "VMBI_track_toggle",
						desc = "VMBI_empty",
						callback = "VMBI_clbck_donothing",
						value = VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"],
						disabled = true,
						menu_id = "VMBI_ghosts",
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddSlider({
						id = "VMBIghosttrack_volume_"..track_name,
						title = "VMBI_track_volume",
						desc = "VMBI_empty",
						callback = "VMBI_clbck_donothing",
						value = VolumeMixerByirbi.settings.tracks_data[track_name.."_volume"] or 20,
						min = 0,
						max = 100,
						step = 1,
						show_value = true,
						menu_id = "VMBI_ghosts",
						disabled = true,
						priority = _prior
					})
					_prior = _prior -1
					MenuHelper:AddDivider({
						id = "VMBIdividerafter_"..track_name,
						size = 16,
						menu_id = "VMBI_ghosts",
						priority = _prior
					})
					_prior = _prior -1
				end
			end
		else
			DelayedCalls:Add("VMBI_buildghosttracks_loop", 0.1, function()
				build_menutracks_ghosts()
			end)
		end
	end
	build_menutracks_ghosts()
end)