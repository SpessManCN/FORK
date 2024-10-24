/datum/action/cooldown/spell/aoe/rust_conversion
	name = "冶锈法"
	desc = "将铁锈扩散到附近表面."
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	button_icon = 'icons/mob/actions/actions_ecult.dmi'
	button_icon_state = "corrode"
	sound = 'sound/items/welder.ogg'

	school = SCHOOL_FORBIDDEN
	cooldown_time = 30 SECONDS

	invocation = "A'GRSV SPR'D"
	invocation_type = INVOCATION_WHISPER
	spell_requirements = NONE

	aoe_radius = 2

/datum/action/cooldown/spell/aoe/rust_conversion/get_things_to_cast_on(atom/center)
	return RANGE_TURFS(aoe_radius, center)

/datum/action/cooldown/spell/aoe/rust_conversion/cast_on_thing_in_aoe(turf/victim, mob/living/caster)
	// We have less chance of rusting stuff that's further
	var/distance_to_caster = get_dist(victim, caster)
	var/chance_of_not_rusting = (max(distance_to_caster, 1) - 1) * 100 / (aoe_radius + 1)

	if(prob(chance_of_not_rusting))
		return

	caster.do_rust_heretic_act(victim)

/datum/action/cooldown/spell/aoe/rust_conversion/small
	name = "冶锈法"
	desc = "将铁锈扩散到附近表面."
	aoe_radius = 2
