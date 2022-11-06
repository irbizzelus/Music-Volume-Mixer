Hooks:PostHook(MusicManager, "track_listen_start", "VolumeMixerByirbi_adjustvolume", function(self,event,track)
	if VolumeMixerByirbi:checktrack(event) == true then
		if Utils:IsInGameState() then
			Global.music_manager.current_track = event
		end
		managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[event.."_volume"])
	elseif VolumeMixerByirbi:checktrack(track) == true then
		if Utils:IsInGameState() then
			Global.music_manager.current_track = track
		end
		managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track.."_volume"])
	else
		if Utils:IsInGameState() then
			Global.music_manager.current_track = event
		end
		managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
	end
end)

Hooks:PostHook(MusicManager, "music_ext_listen_start", "VolumeMixerByirbi_setcorrectghosttrackvolumeinplaylists", function(self,music_ext)
	if VolumeMixerByirbi:checktrack(music_ext) == true then
		if Utils:IsInGameState() then
			Global.music_manager.current_track = music_ext
		end
		managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[music_ext.."_volume"])
	else
		if Utils:IsInGameState() then
			Global.music_manager.current_track = music_ext
		end
		managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
	end
end)

-- failsafe that always checks current track volume, should not affect performance with such delay
function VolumeMixerByirbi:ReevaluateMusicVolume()
if managers.user then
	if VolumeMixerByirbi.settings.fullmute == false then
		if Global.music_manager.current_event then
			local track_id = ""
			if string.sub(Global.music_manager.current_event, 1, 7) == "screen_" then
				track_id = string.sub(Global.music_manager.current_event, 8, string.len(Global.music_manager.current_event))
			else
				track_id = Global.music_manager.current_event
			end
			if VolumeMixerByirbi:checktrack(track_id) == true then
				managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
			else
				if Global.music_manager.current_track and not VolumeMixerByirbi.fuckingpreplanning then
					--managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume or 20)
					if string.sub(Global.music_manager.current_track, 1, 7) == "screen_" then
						track_id = string.sub(Global.music_manager.current_track, 8, string.len(Global.music_manager.current_track))
					else
						track_id = Global.music_manager.current_track
					end
					if VolumeMixerByirbi:checktrack(track_id) == true then
						managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track_id.."_volume"])
					else
						managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume or 20)
					end
				end
			end
		end
	else
		managers.user:set_setting("music_volume", 0)
	end
end
DelayedCalls:Add("VMBI_musicVolume_check_loop", 0.25, function()
	VolumeMixerByirbi.ReevaluateMusicVolume()
end)
end
VolumeMixerByirbi.ReevaluateMusicVolume()