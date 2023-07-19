function CoreMusicManager:check_music_switch()
	local switches = tweak_data.levels:get_music_switches()
	local CT = Global.music_manager.current_track
	local CE = Global.music_manager.current_event

	if switches and #switches > 0 then
		Global.music_manager.current_track = switches[math.random(#switches)]
		
		if CT ~= Global.music_manager.current_track then
			if not VolumeMixerByirbi:is_stealth_heist() then
				managers.music:track_listen_start(CE, Global.music_manager.current_track)
			end
		end
		VolumeMixerByirbi:adjust_current_volume(Global.music_manager.current_track)
		managers.music._skip_play = nil
		VolumeMixerByirbi.currently_looped_track_phase = nil
		print("CoreMusicManager:check_music_switch()", Global.music_manager.current_track)
		Global.music_manager.source:set_switch("music_randomizer", Global.music_manager.current_track)
	end
end