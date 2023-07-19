if not VolumeMixerByirbi then
    _G.VolumeMixerByirbi = {}
	
	VolumeMixerByirbi.modpath = ModPath
	VolumeMixerByirbi.settings = {
		defaultvolume = 20,
		fullmute = false,
		tracks_data = {}
	}
	VolumeMixerByirbi.currently_looped_track_phase = ""
	VolumeMixerByirbi.pre_game_lobby_track_is_playing = false

    function VolumeMixerByirbi:Save()
        local file = io.open(SavePath .. 'VolumeMixerSettings_save.txt', 'w+')
        if file then
            file:write(json.encode(VolumeMixerByirbi.settings))
            file:close()
			VolumeMixerByirbi.savefile = true
        end
    end
    
    function VolumeMixerByirbi:Load()
        local file = io.open(SavePath .. 'VolumeMixerSettings_save.txt', 'r')
        if file then
            for k, v in pairs(json.decode(file:read('*all')) or {}) do
                VolumeMixerByirbi.settings[k] = v
            end
            file:close()
        end
    end
	
	VolumeMixerByirbi:Load()
	VolumeMixerByirbi:Save()

	function VolumeMixerByirbi:buildtracksdata()
		if VolumeMixerByirbi.savefile == true then
			if managers.music then
				local track_list,track_locked = managers.music:jukebox_music_tracks()
				for __, track_name in pairs(track_list or {}) do
					VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"] = VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"] or false
					VolumeMixerByirbi.settings.tracks_data[track_name.."_volume"] = VolumeMixerByirbi.settings.tracks_data[track_name.."_volume"] or VolumeMixerByirbi.settings.defaultvolume
				end
				track_list,track_locked = managers.music:jukebox_menu_tracks()
				for __, track_name in pairs(track_list or {}) do
					VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"] = VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"] or false
					VolumeMixerByirbi.settings.tracks_data[track_name.."_volume"] = VolumeMixerByirbi.settings.tracks_data[track_name.."_volume"] or VolumeMixerByirbi.settings.defaultvolume
				end
				track_list,track_locked = managers.music:jukebox_ghost_tracks()
				for __, track_name in pairs(track_list or {}) do
					VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"] = VolumeMixerByirbi.settings.tracks_data[track_name.."_toggle"] or false
					VolumeMixerByirbi.settings.tracks_data[track_name.."_volume"] = VolumeMixerByirbi.settings.tracks_data[track_name.."_volume"] or VolumeMixerByirbi.settings.defaultvolume
				end
				VolumeMixerByirbi:Save()
			else
				DelayedCalls:Add("VMBI_buildtracksdata_loop", 0.1, function()
					VolumeMixerByirbi:buildtracksdata()
				end)
			end
		else
			DelayedCalls:Add("VMBI_buildtracksdata2nd_loop", 0.1, function()
				VolumeMixerByirbi:buildtracksdata()
			end)
		end
	end
	VolumeMixerByirbi:buildtracksdata()
	
	function VolumeMixerByirbi:checktrack(track_id)
		if track_id then
			for k,v in pairs(VolumeMixerByirbi.settings.tracks_data) do
				if tostring(k) == track_id.."_toggle" and v == true then
					return true
				end
			end
			return false
		end
		return false
	end

	function VolumeMixerByirbi:returngamestate()
		if not Utils:IsInGameState() then
			return "not_in_game"
		end
		if not BaseNetworkHandler then
			return "unidentifiable" -- can this even happen?
		end
		if BaseNetworkHandler._gamestate_filter.any_ingame_playing[game_state_machine:last_queued_state_name()] == true then
			return "in_game"
		else
			return "pre_game_lobby"
		end
	end
	
	function VolumeMixerByirbi:adjust_current_volume(track)
		if VolumeMixerByirbi.settings.fullmute == true then
			managers.user:set_setting("music_volume", 0)
			return
		end
		if VolumeMixerByirbi:checktrack(track) == true then
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track.."_volume"])
		else
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
		end
	end
	
	-- this one returns true/false in menus based on last played heist, or nil
	-- since we only use this in game, it doesnt matter
	function VolumeMixerByirbi:is_stealth_heist()
		if (not Global) or (not Global.game_settings) then
			return false
		elseif Global.game_settings.level_id == "kosugi" or Global.game_settings.level_id == "tag" or Global.game_settings.level_id == "cage" or Global.game_settings.level_id == "dark" or Global.game_settings.level_id == "fish" then
			return true
		else
			return false
		end
	end
	
end

Hooks:Add('LocalizationManagerPostInit', 'VolumeMixerByirbi_loc_loader', function(loc)
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
end)

Hooks:PreHook(MenuManager, "_node_selected", "VolumeMixerByirbi_main_menu_track_volume", function(self, menu_name, node)
	if type(node) == "table" and (node._parameters.name == "main" or node._parameters.name == "lobby") then
		-- this teribleness is made this way to avoid a really dumb pocohud issue:
		-- whenever managers.music:jukebox_menu_track("mainmenu") is requested,
		-- pocohud assumes that mainmenu track has started playing, and makes it's music pop-up appear
		-- tbf, in the base game, this function is only requested whenever that track is enabled
		-- but this kinda makes no sense to do it this way still, so fuck poco for that. otherwise poco is still my beloved
		-- either way, instead of checking that our current track is ~= mainmenu track
		-- we can just check if current event is not one of the possible ones, since with MVM we always know what event should be active
		local function has_value (tab, val)
			for index, value in ipairs(tab) do
				if value == val then
					return true
				end
			end
			return false
		end
		local possible_events = {
			"standard_menu_music",
			"music_heist_setup",
			"music_heist_control",
			"music_heist_anticipation",
			"music_heist_assault",
			"suspense_1",
			"suspense_2",
			"suspense_3",
			"suspense_4",
			"suspense_5"
		}
		if (not Global.music_manager.current_track) or (not has_value(possible_events, Global.music_manager.current_event)) then
			Global.music_manager.current_track = Global.music_manager.current_event
			Global.music_manager.current_event = "standard_menu_music"
		end
		VolumeMixerByirbi:adjust_current_volume(Global.music_manager.current_track)
	end
end)

Hooks:PostHook(MenuManager, "_node_selected", "VolumeMixerByirbi_pre_game_node_tweaks", function(self, menu_name, node)
	if type(node) == "table" and (node._parameters.name == "kit" or node._parameters.name == "loadout" or node._parameters.name == "preplanning") then
		local function has_value (tab, val)
			for index, value in ipairs(tab) do
				if value == val then
					return true
				end
			end
			return false
		end
		local possible_events = {
			"music_heist_setup",
			"music_heist_control",
			"music_heist_anticipation",
			"music_heist_assault",
			"suspense_1",
			"suspense_2",
			"suspense_3",
			"suspense_4",
			"suspense_5"
		}
		local CE = Global.music_manager.current_event
		
		if not has_value(possible_events, CE) then
			if VolumeMixerByirbi.pre_game_lobby_track_is_playing == false then
				managers.music:track_listen_start(CE)
				-- we need this check because beardlib re-plays tracks from the start if we use track_listen_start, even if currenlty played music matches one that we request
				-- this doent happen with base game tracks, only BL
				VolumeMixerByirbi.pre_game_lobby_track_is_playing = true
			end
			if not VolumeMixerByirbi:is_stealth_heist() then
				Global.music_manager.current_track = Global.music_manager.loadout_selection
			else
				Global.music_manager.current_track = Global.music_manager.loadout_selection_ghost
			end
		else
			if not VolumeMixerByirbi:is_stealth_heist() then
				local possible_track_options = {
					"global",
					"server",
					"heist",
				}
				if VolumeMixerByirbi.pre_game_lobby_track_is_playing == false then
					if has_value (possible_track_options, Global.music_manager.loadout_selection) or (not Global.music_manager.loadout_selection) then
						-- will play random track from playlists, or the server track, or fall back on black yellow moebius
						local switches = tweak_data.levels:get_music_switches()
						local track_id = "track_01"
						if switches and #switches > 0 then
							track_id = switches[math.random(#switches)]
						end
						managers.music:track_listen_start(CE, track_id)
					else
						managers.music:track_listen_start(CE, Global.music_manager.loadout_selection)
					end
					VolumeMixerByirbi.pre_game_lobby_track_is_playing = true
				end
			elseif VolumeMixerByirbi:is_stealth_heist() then
				local possible_track_options = {
					"all",
					"global",
					"server",
					"heist",
				}
				if VolumeMixerByirbi.pre_game_lobby_track_is_playing == false then
					if has_value (possible_track_options, Global.music_manager.loadout_selection_ghost) then
						-- will play random track from playlists, or the server track, hopefully
						local track, start_switch = tweak_data.levels:get_music_event_ext_ghost()
						managers.music:music_ext_listen_start(track,CE)
					else
						managers.music:music_ext_listen_start(Global.music_manager.loadout_selection_ghost,CE)
					end
					VolumeMixerByirbi.pre_game_lobby_track_is_playing = true
				end
			end
		end
	end
end)

Hooks:PostHook(MenuManager, "_node_selected", "VolumeMixerByirbi_pre_game_jukebox_node_tweaks", function(self, menu_name, node)
	if type(node) == "table" and (node._parameters.name == "jukebox" or node._parameters.name == "jukebox_ghost") then
		VolumeMixerByirbi.pre_game_lobby_track_is_playing = false
		if node._parameters.name == "jukebox_ghost" then
			managers.music._current_music_ext = nil
		end
	end
end)

Hooks:PostHook(MenuManager, "_node_selected", "VolumeMixerByirbi_sound_node_tweaks", function(self, menu_name, node)
	if type(node) == "table" and node._parameters.name == "sound" then
		node._items[2]._enabled = false
		node._items[2]._parameters.help_id = "VMBI_soundsettingtip"
		node._items[2]._slider_color = Color( 31.875, 255, 255, 255 ) / 255
		node._items[2]._slider_color_highlight = Color( 1, 255, 255, 255 ) / 255
		VolumeMixerByirbi.fuckingpreplanning = nil
		VolumeMixerByirbi.previousNodeJukebox = nil
	end
end)

Hooks:PostHook(MenuCallbackHandler, "jukebox_options_enter", "VolumeMixerByirbi_jukebox_option_enter_post_hook", function(self)
	managers.music:track_listen_stop()
end)

Hooks:PostHook(MenuCallbackHandler, "jukebox_option_back", "VolumeMixerByirbi_jukebox_option_back_post_hook", function(self)
	local track = managers.music:jukebox_menu_track("mainmenu")
	VolumeMixerByirbi:adjust_current_volume(track)
	Global.music_manager.current_event = "standard_menu_music"
	Global.music_manager.current_track = track
end)

Hooks:Add('MenuManagerInitialize', 'VolumeMixerByirbi_init_basic_callbacks', function(menu_manager)
	MenuCallbackHandler.VMBI_clbck_VolumeMixerByirbisave = function(this, item)
		VolumeMixerByirbi:Save()
	end
	
	MenuCallbackHandler.VMBI_clbck_donothing = function(this, item)
		-- Nothing
	end
	
	MenuCallbackHandler.VMBI_clbck_onVMBImenuquit = function(this, item)
		-- this should never trigger since removal of the mute button
		if VolumeMixerByirbi.returngamestate() == "not_in_game" then
			if Global.music_manager.current_event == "stop_all_music" then
				managers.music:track_listen_start(managers.music:jukebox_menu_track("mainmenu"))
			end
		end
		-- fix for heist music going mute
		if VolumeMixerByirbi.returngamestate() == "pre_game_lobby" and not VolumeMixerByirbi:is_stealth_heist() then
			managers.music._current_music_ext = nil
		end
		VolumeMixerByirbi:Save()
	end
	
	MenuCallbackHandler.VMBI_clbck_fullmute = function(this, item)
		VolumeMixerByirbi.settings[item:name()] = item:value() == 'on'
		VolumeMixerByirbi:Save()
		if item:value() == "on" then
			managers.user:set_setting("music_volume", 0)
		else
			local track = Global.music_manager.current_track
			if VolumeMixerByirbi:checktrack(track) == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume or 20)
			end
		end
	end
	
	MenuCallbackHandler.VMBI_set_default_volume = function(this, item)
		VolumeMixerByirbi.settings.defaultvolume = tonumber(item:value())
		VolumeMixerByirbi:Save()
		local track = Global.music_manager.current_track
		if VolumeMixerByirbi.settings.fullmute == true then
			managers.user:set_setting("music_volume", 0)
		elseif not VolumeMixerByirbi.settings.tracks_data[track.."_toggle"] then
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)	
		end
	end
	
	VolumeMixerByirbi:Load()

	MenuHelper:LoadFromJsonFile(VolumeMixerByirbi.modpath .. 'menus/VolumeMixerByirbimenu.txt', VolumeMixerByirbi, VolumeMixerByirbi.settings)
end)
	
Hooks:Add('MenuManagerInitialize', 'VolumeMixerByirbi_menu_tracks_callbacks', function(menu_manager)
	
	MenuCallbackHandler.VMBI_clbck_setquickmenutrack = function(this, item)
		VolumeMixerByirbi.QM_M_track_id = string.sub(VolumeMixerByirbi.qucikacessmenutracks[item:value()], 21, string.len(VolumeMixerByirbi.qucikacessmenutracks[item:value()]))
		local CE = Global.music_manager.current_event
		local track_id = VolumeMixerByirbi.QM_M_track_id
		
		if Global.music_manager.current_track ~= track_id then
			managers.music:track_listen_start(track_id)
			if VolumeMixerByirbi.returngamestate() == "in_game" or VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
				Global.music_manager.current_event = CE
				Global.music_manager.current_track = track_id
			end
		end
		-- UI
		local node = MenuHelper:GetMenu("VMBI")
		if not VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] then
			node._items[11].selected = 2
		else
			node._items[11].selected = 1
		end
		node._items[12]:set_enabled(VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_toggle"])
		node._items[12]._value = VolumeMixerByirbi.settings.tracks_data[VolumeMixerByirbi.QM_M_track_id.."_volume"]
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
	end
	
	MenuCallbackHandler.VMBI_clbck_QM_M_toggle = function(this, item)
		-- if user tries to change toggle for a track that doesnt exist yet, pick the first track on the qucikacessmenutracks list - same as default'ly selected track
		if not VolumeMixerByirbi.QM_M_track_id then
			VolumeMixerByirbi.QM_M_track_id = string.sub(VolumeMixerByirbi.qucikacessmenutracks[1], 21, string.len(VolumeMixerByirbi.qucikacessmenutracks[1]))
		end
		local track_id = VolumeMixerByirbi.QM_M_track_id
		VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] = item:value() == 'on'
		VolumeMixerByirbi:Save()
		
		if Global.music_manager.current_track ~= track_id then
			local CE = Global.music_manager.current_event
			managers.music:track_listen_start(track_id)
			if VolumeMixerByirbi.returngamestate() == "in_game" or VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
				Global.music_manager.current_event = CE
				Global.music_manager.current_track = track_id
			end
		else
			VolumeMixerByirbi:adjust_current_volume(track_id)
		end	
		-- UI
		local node = MenuHelper:GetMenu("VMBI")
		node._items[12]:set_enabled(not node._items[12]:enabled())
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
	end

	MenuCallbackHandler.VMBI_clbck_QM_M_volume = function(this, item)
		if not VolumeMixerByirbi.QM_M_track_id then
			VolumeMixerByirbi.QM_M_track_id = string.sub(VolumeMixerByirbi.qucikacessmenutracks[1], 21, string.len(VolumeMixerByirbi.qucikacessmenutracks[1]))
		end
		local track_id = VolumeMixerByirbi.QM_M_track_id
		VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"] = tonumber(item:value())
		VolumeMixerByirbi:Save()
		
		if Global.music_manager.current_track ~= track_id then
			local CE = Global.music_manager.current_event
			managers.music:track_listen_start(track_id)
			if VolumeMixerByirbi.returngamestate() == "in_game" or VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
				Global.music_manager.current_event = CE
				Global.music_manager.current_track = track_id
			end
		else
			VolumeMixerByirbi:adjust_current_volume(track_id)
		end	
	end

end)

Hooks:Add('MenuManagerInitialize', 'VolumeMixerByirbi_heist_tracks_callbacks', function(menu_manager)
	
	MenuCallbackHandler.VMBI_clbck_setquickgametrack = function(this, item)
		VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[item:value()], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[item:value()]))
		local CE = Global.music_manager.current_event
		local track_id = VolumeMixerByirbi.QM_G_track_id
		
		if Global.music_manager.current_track ~= track_id then
			if VolumeMixerByirbi.returngamestate() == "in_game" then
				if not VolumeMixerByirbi:is_stealth_heist() then
					managers.music:track_listen_start(CE, track_id)
					Global.music_manager.loadout_selection = track_id
				else
					managers.music:track_listen_start("music_heist_assault", track_id)
					Global.music_manager.current_event = CE
				end
			elseif VolumeMixerByirbi.returngamestate() == "not_in_game" then
				managers.music:track_listen_start("music_heist_assault", track_id)
			elseif VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
				managers.music:track_listen_start("music_heist_assault", track_id)
				Global.music_manager.current_event = CE
			end
		else
			if VolumeMixerByirbi.returngamestate() == "in_game" then
				if not VolumeMixerByirbi:is_stealth_heist() then
					if managers.music._skip_play and VolumeMixerByirbi.currently_looped_track_phase ~= CE then
						managers.music:track_listen_start(CE, track_id)
					end
				else
					if managers.music._skip_play and VolumeMixerByirbi.currently_looped_track_phase ~= "music_heist_assault" then
						managers.music:track_listen_start("music_heist_assault", track_id)
						Global.music_manager.current_event = CE
					end
				end
			elseif VolumeMixerByirbi.returngamestate() == "not_in_game" then
				if CE ~= "music_heist_assault" then
					managers.music:track_listen_start("music_heist_assault", track_id)
				end
			elseif VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
				if not VolumeMixerByirbi:is_stealth_heist() then
					if CE == "music_heist_setup" or CE == "music_heist_control" or CE == "music_heist_anticipation" or CE == "music_heist_assault" then
						managers.music:track_listen_start(CE, track_id)
					else
						managers.music:track_listen_start("music_heist_assault", track_id)
						Global.music_manager.current_event = CE
					end
				else
					managers.music:track_listen_start("music_heist_assault", track_id)
					Global.music_manager.current_event = CE
				end
			end
		end
		managers.music._skip_play = nil
		VolumeMixerByirbi.currently_looped_track_phase = nil
		-- UI
		local node = MenuHelper:GetMenu("VMBI")
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
		if not VolumeMixerByirbi.QM_G_track_id then
			VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[1], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[1]))
		end
		local track_id = VolumeMixerByirbi.QM_G_track_id
		local CE = Global.music_manager.current_event
		VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] = item:value() == 'on'
		VolumeMixerByirbi:Save()
		
		if Global.music_manager.current_track ~= track_id then
			if VolumeMixerByirbi.returngamestate() == "in_game" then
				if not VolumeMixerByirbi:is_stealth_heist() then
					managers.music:track_listen_start(CE, track_id)
				else
					managers.music:track_listen_start("music_heist_assault", track_id)
					Global.music_manager.current_event = CE
				end
			elseif VolumeMixerByirbi.returngamestate() == "not_in_game" then
				managers.music:track_listen_start("music_heist_assault", track_id)
			elseif VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then				
				managers.music:track_listen_start("music_heist_assault", track_id)
				Global.music_manager.current_event = CE
			end
		else
			VolumeMixerByirbi:adjust_current_volume(track_id)
		end
		-- UI
		local node = MenuHelper:GetMenu("VMBI")
		node._items[18]:set_enabled(not node._items[18]:enabled())
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
	end
	
	MenuCallbackHandler.VMBI_clbck_QM_G_volume = function(this, item)
		if not VolumeMixerByirbi.QM_G_track_id then
			VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[1], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[1]))
		end
		local CE = Global.music_manager.current_event
		local track_id = VolumeMixerByirbi.QM_G_track_id
		VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"] = tonumber(item:value())
		VolumeMixerByirbi:Save()
		
		if Global.music_manager.current_track ~= track_id then
			if VolumeMixerByirbi.returngamestate() == "in_game" then
				if not VolumeMixerByirbi:is_stealth_heist() then
					managers.music:track_listen_start(CE, track_id)
				else
					managers.music:track_listen_start("music_heist_assault", track_id)
					Global.music_manager.current_event = CE
				end
			elseif VolumeMixerByirbi.returngamestate() == "not_in_game" then
				managers.music:track_listen_start("music_heist_assault", track_id)
			elseif VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then				
				managers.music:track_listen_start("music_heist_assault", track_id)
				Global.music_manager.current_event = CE
			end
		else
			VolumeMixerByirbi:adjust_current_volume(track_id)
		end
	end
	
	function VMBI_play_G_trackphase(phase)
	local CE = Global.music_manager.current_event
	local track_id = VolumeMixerByirbi.QM_G_track_id
		if VolumeMixerByirbi.returngamestate() == "in_game" then
		
			if phase == "Default" then
				if Global.music_manager.current_track ~= track_id then
					if not VolumeMixerByirbi:is_stealth_heist() then
						managers.music:track_listen_start(CE, track_id)
					else
						managers.music:track_listen_start("music_heist_assault", track_id)
						Global.music_manager.current_event = CE
					end
					managers.music._skip_play = nil
					VolumeMixerByirbi.currently_looped_track_phase = nil
				elseif managers.music._skip_play then
					if not VolumeMixerByirbi:is_stealth_heist() then
						if CE ~= VolumeMixerByirbi.currently_looped_track_phase then
							managers.music:track_listen_start(CE, track_id)
						end
					else
						managers.music:track_listen_start("music_heist_assault", track_id)
						Global.music_manager.current_event = CE
					end
					managers.music._skip_play = nil
					VolumeMixerByirbi.currently_looped_track_phase = nil
				end
				return
			end
			
			if Global.music_manager.current_track ~= track_id then
				managers.music:track_listen_start(phase, track_id)
				managers.music._skip_play = true
				VolumeMixerByirbi.currently_looped_track_phase = phase
				Global.music_manager.current_event = CE
			else
				if managers.music._skip_play then
					if phase ~= VolumeMixerByirbi.currently_looped_track_phase then
						managers.music:track_listen_start(phase, track_id)
						VolumeMixerByirbi.currently_looped_track_phase = phase
						Global.music_manager.current_event = CE
					end
				else
					if CE ~= phase then
						managers.music:track_listen_start(phase, track_id)
						Global.music_manager.current_event = CE
					end
					managers.music._skip_play = true
					VolumeMixerByirbi.currently_looped_track_phase = phase
				end
			end
			
		elseif VolumeMixerByirbi.returngamestate() == "not_in_game" then
		
			if phase == "Default" then
				if Global.music_manager.current_track ~= track_id then
					managers.music:track_listen_start("music_heist_assault", track_id)
					managers.music._skip_play = nil
					VolumeMixerByirbi.currently_looped_track_phase = nil
				elseif managers.music._skip_play then
					if CE ~= "music_heist_assault" then
						managers.music:track_listen_start("music_heist_assault", track_id)
					end
					managers.music._skip_play = nil
					VolumeMixerByirbi.currently_looped_track_phase = nil
				end
				return
			end
		
			if Global.music_manager.current_track ~= track_id then
				managers.music:track_listen_start(phase, track_id)
			else
				if CE ~= phase then
					managers.music:track_listen_start(phase, track_id)
				end
			end
			managers.music._skip_play = true
			VolumeMixerByirbi.currently_looped_track_phase = phase
			
		elseif VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
			
			if phase == "Default" then
				if Global.music_manager.current_track ~= track_id then
					managers.music:track_listen_start("music_heist_assault", track_id)
					Global.music_manager.current_event = CE
				end
				managers.music._skip_play = nil
				VolumeMixerByirbi.currently_looped_track_phase = nil
				return
			end
			
			if Global.music_manager.current_track ~= track_id then
				managers.music:track_listen_start(phase, track_id)
				Global.music_manager.current_event = CE
				managers.music._skip_play = true
				VolumeMixerByirbi.currently_looped_track_phase = phase
			else
				if managers.music._skip_play then
					if phase ~= VolumeMixerByirbi.currently_looped_track_phase then
						managers.music:track_listen_start(phase, track_id)
						VolumeMixerByirbi.currently_looped_track_phase = phase
						Global.music_manager.current_event = CE
					end
				else
					if phase ~= CE then
						managers.music:track_listen_start(phase, track_id)
						managers.music._skip_play = true
						VolumeMixerByirbi.currently_looped_track_phase = phase
						Global.music_manager.current_event = CE
					else
						managers.music._skip_play = true
						VolumeMixerByirbi.currently_looped_track_phase = phase
					end
				end
			end
		
		end
	end
	
	MenuCallbackHandler.VMBI_clbck_gametrackphase = function(this, item)
		if not VolumeMixerByirbi.QM_G_track_id then
			VolumeMixerByirbi.QM_G_track_id = string.sub(VolumeMixerByirbi.qucikacessgametracks[1], 14, string.len(VolumeMixerByirbi.qucikacessgametracks[1]))
		end
		local phases = {
			"Default",
			"music_heist_setup",
			"music_heist_control",
			"music_heist_anticipation",
			"music_heist_assault"
		}
		VMBI_play_G_trackphase(phases[item:value()])
	end
end)	
	
Hooks:Add('MenuManagerInitialize', 'VolumeMixerByirbi_stealth_tracks_callbacks', function(menu_manager)
	
	MenuCallbackHandler.VMBI_clbck_setquickghosttrack = function(this, item)
		VolumeMixerByirbi.QM_S_track_id = string.sub(VolumeMixerByirbi.qucikacessghosttracks[item:value()], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[item:value()]))
		local CE = Global.music_manager.current_event
		local track_id = VolumeMixerByirbi.QM_S_track_id
		
		if Global.music_manager.current_track ~= track_id then
			if VolumeMixerByirbi.returngamestate() == "in_game" then
				if not VolumeMixerByirbi:is_stealth_heist() then
					managers.music:music_ext_listen_start(track_id,"suspense_4")
					Global.music_manager.current_event = CE
				else
					managers.music:music_ext_listen_start(track_id,CE)
					Global.music_manager.loadout_selection_ghost = track_id
				end
			elseif VolumeMixerByirbi.returngamestate() == "not_in_game" then
				managers.music:music_ext_listen_start(track_id,"suspense_4")
			elseif VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
				managers.music:music_ext_listen_start(track_id,"suspense_4")
				Global.music_manager.current_event = CE
			end
		else
			if VolumeMixerByirbi.returngamestate() == "in_game" then
				if not VolumeMixerByirbi:is_stealth_heist() then
					if managers.music._skip_play and VolumeMixerByirbi.currently_looped_track_phase ~= "suspense_4" then
						managers.music:music_ext_listen_start(track_id,"suspense_4")
						Global.music_manager.current_event = CE
					end
				else
					if managers.music._skip_play and VolumeMixerByirbi.currently_looped_track_phase ~= CE then
						managers.music:music_ext_listen_start(track_id,CE)
					end
				end
			end
			if VolumeMixerByirbi.returngamestate() == "not_in_game" then
				if CE ~= "suspense_4" then
					managers.music:music_ext_listen_start(track_id,"suspense_4")
				end
			end
			if VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
				if not VolumeMixerByirbi:is_stealth_heist() then
					managers.music:music_ext_listen_start(track_id,"suspense_4")
					Global.music_manager.current_event = CE
				else
					if CE == "suspense_1" or CE == "suspense_2" or CE == "suspense_3" or CE == "suspense_4" or CE == "suspense_5" then
						managers.music:music_ext_listen_start(track_id,CE)
					else
						managers.music:music_ext_listen_start(track_id,"suspense_4")
						Global.music_manager.current_event = CE
					end
				end
			end
		end
		managers.music._skip_play = nil
		VolumeMixerByirbi.currently_looped_track_phase = nil
		
		-- UI
		local node = MenuHelper:GetMenu("VMBI")
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
		if not VolumeMixerByirbi.QM_S_track_id then
			VolumeMixerByirbi.QM_S_track_id = string.sub(VolumeMixerByirbi.qucikacessghosttracks[1], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[1]))
		end
		local track_id = VolumeMixerByirbi.QM_S_track_id
		local CE = Global.music_manager.current_event
		VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] = item:value() == 'on'
		VolumeMixerByirbi:Save()
		
		if Global.music_manager.current_track ~= track_id then
			if VolumeMixerByirbi.returngamestate() == "in_game" then
				if not VolumeMixerByirbi:is_stealth_heist() then
					managers.music:music_ext_listen_start(track_id,"suspense_4")
					Global.music_manager.current_event = CE
				else
					managers.music:music_ext_listen_start(track_id,CE)
				end
			elseif VolumeMixerByirbi.returngamestate() == "not_in_game" then
				managers.music:music_ext_listen_start(track_id,"suspense_4")
			elseif VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
				managers.music:music_ext_listen_start(track_id,"suspense_4")
				Global.music_manager.current_event = CE
			end
		else
			VolumeMixerByirbi:adjust_current_volume(track_id)
		end
		-- UI
		local node = MenuHelper:GetMenu("VMBI")
		node._items[25]:set_enabled(not node._items[25]:enabled())
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(node)
	end
	
	MenuCallbackHandler.VMBI_clbck_QM_S_volume = function(this, item)
		if not VolumeMixerByirbi.QM_S_track_id then
			VolumeMixerByirbi.QM_S_track_id = string.sub(VolumeMixerByirbi.qucikacessghosttracks[1], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[1]))
		end
		local track_id = VolumeMixerByirbi.QM_S_track_id
		local CE = Global.music_manager.current_event
		VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"] = tonumber(item:value())
		VolumeMixerByirbi:Save()
		if Global.music_manager.current_track ~= track_id then
			if VolumeMixerByirbi.returngamestate() == "in_game" then
				if not VolumeMixerByirbi:is_stealth_heist() then
					managers.music:music_ext_listen_start(track_id,"suspense_4")
					Global.music_manager.current_event = CE
				else
					managers.music:music_ext_listen_start(track_id,CE)
				end
			elseif VolumeMixerByirbi.returngamestate() == "not_in_game" then
				managers.music:music_ext_listen_start(track_id,"suspense_4")
			elseif VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
				managers.music:music_ext_listen_start(track_id,"suspense_4")
				Global.music_manager.current_event = CE
			end
			managers.music._skip_play = nil
			VolumeMixerByirbi.currently_looped_track_phase = nil
		else
			VolumeMixerByirbi:adjust_current_volume(track_id)
		end
	end
	
	local function VMBI_play_S_trackphase(phase)
		local CE = Global.music_manager.current_event
		local track_id = VolumeMixerByirbi.QM_S_track_id
	
		if VolumeMixerByirbi.returngamestate() == "in_game" then
		
			if phase == "Default" then
				if Global.music_manager.current_track ~= track_id then
					if not VolumeMixerByirbi:is_stealth_heist() then
						managers.music:music_ext_listen_start(track_id,"suspense_4")
						Global.music_manager.current_event = CE
					else
						managers.music:music_ext_listen_start(track_id,CE)
					end
					managers.music._skip_play = nil
					VolumeMixerByirbi.currently_looped_track_phase = nil
				elseif managers.music._skip_play then
					if not VolumeMixerByirbi:is_stealth_heist() then
						managers.music:music_ext_listen_start(track_id,"suspense_4")
						Global.music_manager.current_event = CE
					else
						if CE ~= VolumeMixerByirbi.currently_looped_track_phase then
							managers.music:music_ext_listen_start(track_id, CE)
						end
					end
					managers.music._skip_play = nil
					VolumeMixerByirbi.currently_looped_track_phase = nil
				end
				return
			end
			
			if Global.music_manager.current_track ~= track_id then
				managers.music:music_ext_listen_start(track_id, phase)
				managers.music._skip_play = true
				VolumeMixerByirbi.currently_looped_track_phase = phase
				Global.music_manager.current_event = CE
			else
				if managers.music._skip_play then
					if phase ~= VolumeMixerByirbi.currently_looped_track_phase then
						managers.music:music_ext_listen_start(track_id, phase)
						VolumeMixerByirbi.currently_looped_track_phase = phase
						Global.music_manager.current_event = CE
					end
				else
					if CE ~= phase then
						managers.music:music_ext_listen_start(track_id, phase)
						Global.music_manager.current_event = CE	
					end
					managers.music._skip_play = true
					VolumeMixerByirbi.currently_looped_track_phase = phase
				end
			end
			
		elseif VolumeMixerByirbi.returngamestate() == "not_in_game" then
		
			if phase == "Default" then
				if Global.music_manager.current_track ~= track_id then
					managers.music:music_ext_listen_start(track_id, "suspense_4")
					managers.music._skip_play = nil
					VolumeMixerByirbi.currently_looped_track_phase = nil
				elseif managers.music._skip_play then
					if CE ~= "suspense_4" then
						managers.music:music_ext_listen_start(track_id, "suspense_4")
					end
					managers.music._skip_play = nil
					VolumeMixerByirbi.currently_looped_track_phase = nil
				end
				return
			end
			
			if Global.music_manager.current_track ~= track_id then
				managers.music:music_ext_listen_start(track_id, phase)
			else
				if CE ~= phase then
					managers.music:music_ext_listen_start(track_id, phase)
				end
			end
			managers.music._skip_play = true
			VolumeMixerByirbi.currently_looped_track_phase = phase
			
		elseif VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
			
			if phase == "Default" then
				if Global.music_manager.current_track ~= track_id then
					managers.music:music_ext_listen_start(track_id,"suspense_4")
					Global.music_manager.current_event = CE
				elseif managers.music._skip_play then
					if "suspense_4" ~= VolumeMixerByirbi.currently_looped_track_phase then
						managers.music:music_ext_listen_start(track_id, "suspense_4")
					end
				end
				managers.music._skip_play = nil
				VolumeMixerByirbi.currently_looped_track_phase = nil
				return
			end
			
			if Global.music_manager.current_track ~= track_id then
				managers.music:music_ext_listen_start(track_id, phase)
				Global.music_manager.current_event = CE
				managers.music._skip_play = true
				VolumeMixerByirbi.currently_looped_track_phase = phase
			else
				if managers.music._skip_play then
					if phase ~= VolumeMixerByirbi.currently_looped_track_phase then
						managers.music:music_ext_listen_start(track_id, phase)
						VolumeMixerByirbi.currently_looped_track_phase = phase
						Global.music_manager.current_event = CE
					end
				else
					if phase ~= CE then
						managers.music:music_ext_listen_start(track_id, phase)
						managers.music._skip_play = true
						VolumeMixerByirbi.currently_looped_track_phase = phase
						Global.music_manager.current_event = CE
					else
						managers.music._skip_play = true
						VolumeMixerByirbi.currently_looped_track_phase = phase
					end
				end
			end
			
		end
	end
	
	MenuCallbackHandler.VMBI_clbck_ghosttrackphase = function(this, item)
		if not VolumeMixerByirbi.QM_S_track_id then
			VolumeMixerByirbi.QM_S_track_id = string.sub(VolumeMixerByirbi.qucikacessghosttracks[1], 21, string.len(VolumeMixerByirbi.qucikacessghosttracks[1]))
		end
		local phases = {
			"Default",
			"suspense_1",
			"suspense_2",
			"suspense_3",
			"suspense_4",
			"suspense_5"
		}
		VMBI_play_S_trackphase(phases[item:value()])
	end
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
				desc = "VMBI_empty",
				callback = "VMBI_clbck_donothing",
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
				desc = "VMBI_empty",
				callback = "VMBI_clbck_donothing",
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
				desc = "VMBI_empty",
				callback = "VMBI_clbck_donothing",
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