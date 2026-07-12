Hooks:PostHook(LevelsTweakData,"init","MVM_fix_alesso_tweakdata",function(tweak_data)
	tweak_data.arena.death_track = nil
	tweak_data.arena.death_event = nil
	tweak_data.arena.music = "heist"
end)

-- shuffle tracks in between assaults if corresponding setting is enabled
Hooks:PostHook(LevelsTweakData,"get_music_event","MVM_fi_tweakdata",function(self, stage)
	
	local vmbi = VolumeMixerByirbi
			
	if not (stage and vmbi and vmbi.qucikacessgametracks and vmbi.settings) then
		return
	end
	
	local function should_shuffle()
		if stage == "assault" then
			vmbi.should_shuffle_on_next_control = true
		elseif stage == "control" then
			if vmbi.should_shuffle_on_next_control and vmbi.settings.loud_shuffle then
				return true
			end
		end
		return false
	end
	
	if should_shuffle() then
		local random_track = vmbi.qucikacessgametracks[math.random(1,#vmbi.qucikacessgametracks)]
		random_track = string.sub(random_track, 14, string.len(random_track))
		
		-- prevent repeat of same track
		for i = 1, 5 do
			if Global.music_manager.current_track == random_track then
				random_track = vmbi.qucikacessgametracks[math.random(1,#vmbi.qucikacessgametracks)]
				random_track = string.sub(random_track, 14, string.len(random_track))
			else
				break
			end
		end
		
		managers.music:track_listen_start("music_heist_control", random_track)
		Global.music_manager.loadout_selection = random_track

		managers.music._skip_play = nil
		vmbi.currently_looped_track_phase = nil
	end
	
end)