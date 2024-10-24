/datum/action/cooldown/spell/jaunt/ethereal_jaunt/ash
	name = "尘隐漫行"
	desc = "短距离内隐身并获得穿墙能力."
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	button_icon = 'icons/mob/actions/actions_ecult.dmi'
	button_icon_state = "ash_shift"
	sound = null

	school = SCHOOL_FORBIDDEN
	cooldown_time = 15 SECONDS

	invocation = "ASH'N P'SSG'"
	invocation_type = INVOCATION_WHISPER
	spell_requirements = NONE

	exit_jaunt_sound = null
	jaunt_duration = 1.1 SECONDS
	jaunt_in_time = 1.3 SECONDS
	jaunt_out_time = 0.6 SECONDS
	jaunt_in_type = /obj/effect/temp_visual/dir_setting/ash_shift
	jaunt_out_type = /obj/effect/temp_visual/dir_setting/ash_shift/out

/datum/action/cooldown/spell/jaunt/ethereal_jaunt/ash/do_steam_effects()
	return

/datum/action/cooldown/spell/jaunt/ethereal_jaunt/ash/long
	name = "走尘"
	desc = "长距离内让你获得穿墙能力."
	jaunt_duration = 5 SECONDS

/obj/effect/temp_visual/dir_setting/ash_shift
	name = "ash_shift"
	icon = 'icons/mob/simple/mob.dmi'
	icon_state = "ash_shift2"
	duration = 1.3 SECONDS

/obj/effect/temp_visual/dir_setting/ash_shift/out
	icon_state = "ash_shift"
