if not VolumeMixerByirbi then
    _G.VolumeMixerByirbi = {}
	
	VolumeMixerByirbi.modpath = ModPath
	VolumeMixerByirbi.settings = {
		defaultvolume = nil,
		fullmute = false,
		tracks_data = {}
	}
	function set_defaultvolume()
		if VolumeMixerByirbi.settings.defaultvolume == nil then
			if managers.user then
				VolumeMixerByirbi.settings.defaultvolume = managers.user:get_setting("music_volume")
			else
				DelayedCalls:Add("VMBI_set_defualtvalue_loop", 0.1, function()
					set_defaultvolume()
				end)
			end
		end
	end
	set_defaultvolume()

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
	
	function VolumeMixerByirbi:loadsettingsonboot()
		if VolumeMixerByirbi.settings.defaultvolume ~= nil then
			VolumeMixerByirbi:Load()
			VolumeMixerByirbi:Save()
			
		else
			DelayedCalls:Add("VMBI_loadsettings_loop", 0.1, function()
				VolumeMixerByirbi.loadsettingsonboot()
			end)
		end
	end
	VolumeMixerByirbi.loadsettingsonboot()

	function VolumeMixerByirbi:buildtracksdata()
		if VolumeMixerByirbi.savefile == true and VolumeMixerByirbi.settings.defaultvolume ~= nil then
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
end


function VolumeMixerByirbi:checktrack(track_id)
	if track_id then -- randomly crashes sometimes if we reboot the game with SuperBLT's restart game featre? how? we cant even call this fucnction with empty track id
		for k,v in pairs(VolumeMixerByirbi.settings.tracks_data) do
			if tostring(k) == track_id.."_toggle" and v == true then
				return true
			end
		end
		return false
	end
	return false
end