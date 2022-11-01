Hooks:PostHook(MusicManager, "track_listen_start", "VolumeMixerByirbi_adjustvolume", function(self,event,track)
--log("EVENT: "..tostring(event).." TRACK: "..tostring(track))
	if VolumeMixerByirbi.playlistcustomizationnode == true then
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
	else
		if VolumeMixerByirbi:checktrack(track) == true then
			if Utils:IsInGameState() then
				Global.music_manager.current_track = track
			end
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[track.."_volume"])
		else
			if Utils:IsInGameState() then
				Global.music_manager.current_track = track
			end
			managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume)
		end
	end
end)

Hooks:PostHook(MusicManager, "track_listen_stop", "VolumeMixerByirbi_stopghosttracks", function(self,event,track)
	Global.music_manager.source:post_event("stop_all_music")
end)

Hooks:PostHook(MusicManager, "music_ext_listen_start", "VolumeMixerByirbi_setcorrectghosttrackvolumeinplaylists", function(self,music_ext)
	if VolumeMixerByirbi.playlistcustomizationnode == true then
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
	end
end)

function VolumeMixerByirbi:ReevaluateMusicVolume()
if managers.user then
	if VolumeMixerByirbi.settings.fullmute == false then
		if Global.music_manager.current_track ~= nil then
			local menutrack_id = nil
			if string.sub(Global.music_manager.current_track, 1, 7) == "screen_" then
				menutrack_id = string.sub(Global.music_manager.current_track, 8, string.len(Global.music_manager.current_track))
			else
				menutrack_id = Global.music_manager.current_track
			end
			if VolumeMixerByirbi.playlistcustomizationnode ~= true then
				if VolumeMixerByirbi:checktrack(menutrack_id) == true then
					managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[menutrack_id.."_volume"])
				else
					managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.defaultvolume or 20)
				end
			end
		else
			if Global.music_manager.current_event then
				local menutrack_id = nil
				if string.sub(Global.music_manager.current_event, 1, 7) == "screen_" then
					menutrack_id = string.sub(Global.music_manager.current_event, 8, string.len(Global.music_manager.current_event))
				else
					menutrack_id = Global.music_manager.current_event
				end
				if VolumeMixerByirbi.playlistcustomizationnode ~= true then
					if VolumeMixerByirbi:checktrack(menutrack_id) == true then
						managers.user:set_setting("music_volume", VolumeMixerByirbi.settings.tracks_data[menutrack_id.."_volume"])
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
	DelayedCalls:Add("VMBI_musicVolume_check_loop", 0.05, function()
		VolumeMixerByirbi.ReevaluateMusicVolume()
	end)
end
VolumeMixerByirbi.ReevaluateMusicVolume()