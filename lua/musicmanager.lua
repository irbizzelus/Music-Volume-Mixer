Hooks:PostHook(MusicManager, "track_listen_start", "VolumeMixerByirbi_track_listen_start_adjustvolume", function(self,event,track)
	if VolumeMixerByirbi.returngamestate() == "in_game" then
		if track then
			VolumeMixerByirbi:adjust_current_volume(track)
			Global.music_manager.current_event = event
			Global.music_manager.current_track = track
		else
			VolumeMixerByirbi:adjust_current_volume(event)
		end
	elseif VolumeMixerByirbi.returngamestate() == "not_in_game" then
		if track then
			VolumeMixerByirbi:adjust_current_volume(track)
			Global.music_manager.current_event = event
			Global.music_manager.current_track = track
		else
			VolumeMixerByirbi:adjust_current_volume(event)
			Global.music_manager.current_event = "standard_menu_music"
			Global.music_manager.current_track = event
		end
	elseif VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
		local CE = Global.music_manager.current_event
		if event == "stop_all_music" then
			Global.music_manager.current_event = CE
			Global.music_manager.current_track = "stop_all_music"
			return
		end
		if track then
			VolumeMixerByirbi:adjust_current_volume(track)
			Global.music_manager.current_track = track
			Global.music_manager.current_event = CE
		else
			VolumeMixerByirbi:adjust_current_volume(event)
			Global.music_manager.current_event = CE
			Global.music_manager.current_track = event
		end
	end
end)

function MusicManager:music_ext_listen_start(music_ext,event)
	if self._current_music_ext == music_ext and not event then
		return
	end
	
	local function has_value (tab, val)
		for index, value in ipairs(tab) do
			if value == val then
				return true
			end
		end
		return false
	end
	local default_stealth_tracks = {
		"kosugi_music",
		"music_dark",
		"music_fish",
		"music_tag",
		"music_xmn", -- my beloved
	}
	local track_is_default = true
	if not has_value (default_stealth_tracks, music_ext) then
		track_is_default = false
	end
	
	if track_is_default then
		local CE = Global.music_manager.current_event
		local _event = "suspense_4"
		-- this next line is needed because BeardLib tracks refuse to shut the fuck up if source.stop is used
		-- if we pretend to use normal track start, then readjust everything as we need, it works
		managers.music:track_listen_start(_event, "screen_"..music_ext)
		Global.music_manager.source:stop()
		Global.music_manager.source:post_event(music_ext)
		if not event then
			Global.music_manager.source:post_event("suspense_4")
		else
			Global.music_manager.source:post_event(event)
			_event = event
		end
		self._current_music_ext = music_ext
		
		if VolumeMixerByirbi.returngamestate() == "in_game" or VolumeMixerByirbi.returngamestate() == "not_in_game" then
			VolumeMixerByirbi:adjust_current_volume(music_ext)
			Global.music_manager.current_event = _event
			Global.music_manager.current_track = music_ext
		elseif VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
			VolumeMixerByirbi:adjust_current_volume(music_ext)
			Global.music_manager.current_track = music_ext
			Global.music_manager.current_event = CE
		end
	else
		local CE = Global.music_manager.current_event
		local _event = "suspense_4"
		if event then
			_event = event
		end
		managers.music:track_listen_start(_event, music_ext)
		self._current_music_ext = nil
		if VolumeMixerByirbi.returngamestate() == "in_game" or VolumeMixerByirbi.returngamestate() == "not_in_game" then
			Global.music_manager.current_event = _event
			Global.music_manager.current_track = music_ext
		elseif VolumeMixerByirbi.returngamestate() == "pre_game_lobby" then
			Global.music_manager.current_track = music_ext
			Global.music_manager.current_event = CE
		end
	end
end

-- shows current track name in 'more info tab" (tab keybind)
function MusicManager:current_track_string()
	local level_data = Global.level_data.level_id and tweak_data.levels[Global.level_data.level_id]
	local music_style = tweak_data.levels:get_music_style_from_level_data(level_data)

	if music_style == "heist" or music_style == "ghost" then
		if Global.music_manager.current_track then
			local track_string = managers.localization:to_upper_text("menu_jukebox_" .. Global.music_manager.current_track)
			if string.sub(track_string, 1, 6) == "ERROR:" then
				return managers.localization:to_upper_text("menu_jukebox_screen_" .. Global.music_manager.current_track)
			else
				return track_string
			end
		end
	elseif Global.level_data.level_id then
		return managers.localization:to_upper_text("menu_jukebox_track_" .. Global.level_data.level_id)
	end

	return ""
end

-- could've been a post hook, but get_music_event_ext_ghost returns random tracks if music is set to playlist or random-all
-- which would mean inconsistency between track that is played and one that our post-hook recieves
-- seems to only be used when entering heists so we'll use it to update volume
function MusicManager:check_music_ext_ghost()
	local music, start_switch = tweak_data.levels:get_music_event_ext_ghost()
	Global.music_manager.current_music_ext = music
	
	if VolumeMixerByirbi:is_stealth_heist() then
		-- why would this even be called during loud heists?
		Global.music_manager.current_track = music
		VolumeMixerByirbi:adjust_current_volume(music)
		managers.music._skip_play = nil
		VolumeMixerByirbi.currently_looped_track_phase = nil
	end
	
	if music then
		self:post_event(music)
		self:post_event(start_switch)
	end
end