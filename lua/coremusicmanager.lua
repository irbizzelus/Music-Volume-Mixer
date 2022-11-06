Hooks:PostHook(CoreMusicManager, "post_event", "VolumeMixerByirbi_corevolumehook", function(self)
	-- gets called when entering playlist but not when changed music is playing. should try to fix
	if Global.game_settings and (Global.game_settings.level_id == "kosugi" or Global.game_settings.level_id == "tag" or Global.game_settings.level_id == "cage" or Global.game_settings.level_id == "dark" or Global.game_settings.level_id == "fish") then 
		Global.music_manager.current_track = Global.music_manager.current_music_ext
		local track_id = Global.music_manager.current_track
		if track_id then
			if VolumeMixerByirbi.settings.fullmute == true then
				managers.user:set_setting("music_volume", 0)
			elseif VolumeMixerByirbi.settings.tracks_data[track_id.."_toggle"] == true then
				managers.user:set_setting("music_volume",  VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
			else
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
			end
		end
	end
end)