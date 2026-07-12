core:module("CoreElementMusic")
core:import("CoreMissionScriptElement")
ElementMusic = ElementMusic or class(CoreMissionScriptElement.MissionScriptElement)

-- while playing on alesso heist, ignore all alesso specific event triggers to avoid custom music from breaking. this func calls for post_event so we grab stuff here, cause otherwise beardlib custom music breaks
local MVM_ElementMusic_on_executed = ElementMusic.on_executed
Hooks:OverrideFunction(ElementMusic, "on_executed", function (self, instigator)
	if Global and Global.level_data and Global.level_data.level_id == "arena" then
		if not self._values.enabled then
			return
		end
		if not self._values.use_instigator or instigator == managers.player:player_unit() then
			if self._values.music_event then
				local event_ignore = {
					crowd_crazy = true,
					crowd_heavy = true,
					crowd_light = true,
					crowd_medium = true,
					crowd_single_ending = true,
					alesso_muffle_1 = true,
					alesso_muffle_2 = true,
					alesso_muffle_3 = true,
					alesso_muffle_4 = true,
					alesso_muffle_5 = true,
					alesso_muffle_6 = true,
					alesso_muffle_7 = true,
					alesso_muffle_8 = true,
					alesso_music_cut = true,
					alesso_music_drop = true,
					alesso_music_fade = true,
					alesso_music_play = true,
					alesso_music_state = true,
					alesso_music_hacking_progress = true,
					alesso_music_hacking_standby = true,
					alesso_payday = true,
				}
				local event_conversion = {
					alesso_music_anticipation = "music_heist_anticipation",
					alesso_music_assault = "music_heist_assault",
					alesso_music_control = "music_heist_control",
					alesso_music_stealth = "music_heist_setup",
				}
				if event_ignore[self._values.music_event] then
					-- do fuck all
				elseif event_conversion[self._values.music_event] then
					managers.music:post_event(event_conversion[self._values.music_event])
				else
					managers.music:post_event(self._values.music_event)
				end
			elseif Application:editor() then
				managers.editor:output_error("Cant play music event nil [" .. self._editor_name .. "]")
			end
		end

		ElementMusic.super.on_executed(self, instigator)
	else
		MVM_ElementMusic_on_executed(self, instigator)
	end
end)