// The rune carver, a heretic knife that can draw rune traps.
/obj/item/melee/rune_carver
	name = "雕刻刀"
	desc = "一把由冷钢制成的小刀，纯净无暇. 它锋利到能雕刻钛金属 - \
		但只有少数人能真正唤起潜藏在实在下的危险."
	icon = 'icons/obj/antags/eldritch.dmi'
	icon_state = "rune_carver"
	obj_flags = CONDUCTS_ELECTRICITY
	sharpness = SHARP_EDGED
	w_class = WEIGHT_CLASS_SMALL
	wound_bonus = 20
	force = 10
	throwforce = 20
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = list("攻击", "劈砍", "刺向", "切割", "捅向", "斩向")
	attack_verb_simple = list("攻击", "劈砍", "刺向", "切割", "捅向", "斩向")
	actions_types = list(/datum/action/item_action/rune_shatter)
	embedding = list(
		ignore_throwspeed_threshold = TRUE,
		embed_chance = 75,
		jostle_chance = 2,
		jostle_pain_mult = 5,
		pain_stam_pct = 0.4,
		pain_mult = 3,
		rip_time = 15,
	)

	/// Whether we're currently drawing a rune
	var/drawing = FALSE
	/// Max amount of runes that can be drawn
	var/max_rune_amt = 3
	/// A list of weakrefs to all of ourc urrent runes
	var/list/datum/weakref/current_runes = list()
	/// Turfs that you cannot draw carvings on
	var/static/list/blacklisted_turfs = typecacheof(list(/turf/open/space, /turf/open/openspace, /turf/open/lava))

/obj/item/melee/rune_carver/examine(mob/user)
	. = ..()
	if(!IS_HERETIC_OR_MONSTER(user) && !isobserver(user))
		return

	. += span_notice("<b>[length(current_runes)] / [max_rune_amt]</b> 已雕刻总数.")
	. += span_info("可雕刻以下刻印:")
	for(var/obj/structure/trap/eldritch/trap as anything in subtypesof(/obj/structure/trap/eldritch))
		var/potion_string = span_info("\tThe " + initial(trap.name) + " - " + initial(trap.carver_tip))
		. += potion_string

/obj/item/melee/rune_carver/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!IS_HERETIC_OR_MONSTER(user))
		return NONE
	if(!isopenturf(interacting_with) || is_type_in_typecache(interacting_with, blacklisted_turfs))
		return NONE

	INVOKE_ASYNC(src, PROC_REF(try_carve_rune), interacting_with, user)
	return ITEM_INTERACT_SUCCESS

/*
 * Begin trying to carve a rune. Go through a few checks, then call do_carve_rune if successful.
 */
/obj/item/melee/rune_carver/proc/try_carve_rune(turf/open/target_turf, mob/user)
	if(drawing)
		target_turf.balloon_alert(user, "已经在雕刻了!")
		return

	if(locate(/obj/structure/trap/eldritch) in range(1, target_turf))
		target_turf.balloon_alert(user, "过于靠近另一处刻印!")
		return

	for(var/datum/weakref/rune_ref as anything in current_runes)
		if(!rune_ref?.resolve())
			current_runes -= rune_ref

	if(length(current_runes) >= max_rune_amt)
		target_turf.balloon_alert(user, "有太多刻印了!")
		return

	drawing = TRUE
	do_carve_rune(target_turf, user)
	drawing = FALSE

/*
 * The actual proc that handles selecting the rune to draw and creating it.
 */
/obj/item/melee/rune_carver/proc/do_carve_rune(turf/open/target_turf, mob/user)
	// Assoc list of [name] to [image] for the radial (to show tooltips)
	var/static/list/choices = list()
	// Assoc list of [name] to [path] for after the radial
	var/static/list/names_to_path = list()
	if(!choices.len || !names_to_path.len)
		for(var/obj/structure/trap/eldritch/trap as anything in subtypesof(/obj/structure/trap/eldritch))
			names_to_path[initial(trap.name)] = trap
			choices[initial(trap.name)] = image(icon = initial(trap.icon), icon_state = initial(trap.icon_state))

	var/picked_choice = show_radial_menu(
		user,
		target_turf,
		choices,
		require_near = TRUE,
		tooltips = TRUE,
		)

	if(isnull(picked_choice))
		return

	var/to_make = names_to_path[picked_choice]
	if(!ispath(to_make, /obj/structure/trap/eldritch))
		CRASH("[type] attempted to create a rune of incorrect type! (got: [to_make])")

	target_turf.balloon_alert(user, "雕刻[picked_choice]...")
	user.playsound_local(target_turf, 'sound/items/sheath.ogg', 50, TRUE)
	if(!do_after(user, 5 SECONDS, target = target_turf))
		target_turf.balloon_alert(user, "被打断!")
		return

	target_turf.balloon_alert(user, "已雕刻[picked_choice]")
	var/obj/structure/trap/eldritch/new_rune = new to_make(target_turf, user)
	current_runes += WEAKREF(new_rune)

/datum/action/item_action/rune_shatter
	name = "销毁符文"
	desc = "摧毁这把刀刻出的所有符文."
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	button_icon_state = "rune_break"
	button_icon = 'icons/mob/actions/actions_ecult.dmi'

/datum/action/item_action/rune_shatter/New(Target)
	. = ..()
	if(!istype(Target, /obj/item/melee/rune_carver))
		qdel(src)
		return

/datum/action/item_action/rune_shatter/Grant(mob/granted)
	if(!IS_HERETIC_OR_MONSTER(granted))
		return

	return ..()

/datum/action/item_action/rune_shatter/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return
	if(!IS_HERETIC_OR_MONSTER(owner))
		return FALSE
	var/obj/item/melee/rune_carver/target_sword = target
	if(!length(target_sword.current_runes))
		return FALSE

/datum/action/item_action/rune_shatter/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return

	owner.playsound_local(get_turf(owner), 'sound/magic/blind.ogg', 50, TRUE)
	var/obj/item/melee/rune_carver/target_sword = target
	QDEL_LIST(target_sword.current_runes)
	target_sword.SpinAnimation(5, 1)
	return TRUE

// The actual rune traps the knife draws.
/obj/structure/trap/eldritch
	name = "古老刻印"
	desc = "一系列未知的符号，让你想起了久远的时光..."
	icon = 'icons/obj/service/hand_of_god_structures.dmi'
	/// A tip displayed to heretics who examine the rune carver. Explains what the rune does.
	var/carver_tip
	/// Reference to trap owner mob
	var/datum/weakref/owner

/obj/structure/trap/eldritch/Initialize(mapload, new_owner)
	. = ..()
	if(new_owner)
		owner = WEAKREF(new_owner)

/obj/structure/trap/eldritch/on_entered(datum/source, atom/movable/entering_atom)
	if(!isliving(entering_atom))
		return ..()
	var/mob/living/living_mob = entering_atom
	if(WEAKREF(living_mob) == owner)
		return
	if(IS_HERETIC_OR_MONSTER(living_mob))
		return
	return ..()

/obj/structure/trap/eldritch/attacked_by(obj/item/weapon, mob/living/user)
	if(istype(weapon, /obj/item/melee/rune_carver) || istype(weapon, /obj/item/nullrod))
		loc.balloon_alert(user, "雕刻驱散")
		playsound(src, 'sound/items/sheath.ogg', 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE, ignore_walls = FALSE)
		qdel(src)

	return ..()

/obj/structure/trap/eldritch/alert
	name = "警戒刻印"
	icon_state = "alert_rune"
	alpha = 10
	time_between_triggers = 5 SECONDS
	sparks = FALSE
	carver_tip = "一个几乎不可见的符文，当它被踩到时，会对雕刻者通报触发者的身份与位置."

/obj/structure/trap/eldritch/alert/trap_effect(mob/living/victim)
	var/mob/living/real_owner = owner?.resolve()
	if(real_owner)
		to_chat(real_owner, span_userdanger("[victim.real_name]踩到了位于[get_area(src)]的警戒刻印!"))
		real_owner.playsound_local(get_turf(real_owner), 'sound/magic/curse.ogg', 50, TRUE)

/obj/structure/trap/eldritch/tentacle
	name = "握力刻印"
	icon_state = "tentacle_rune"
	time_between_triggers = 45 SECONDS
	charges = 1
	carver_tip = "当它被踩到时，对触发者腿部造成严重的伤害并击昏五秒，有一次充能."

/obj/structure/trap/eldritch/tentacle/trap_effect(mob/living/victim)
	if(!iscarbon(victim))
		return
	var/mob/living/carbon/carbon_victim = victim
	carbon_victim.Paralyze(5 SECONDS)
	carbon_victim.apply_damage(20, BRUTE, BODY_ZONE_R_LEG)
	carbon_victim.apply_damage(20, BRUTE, BODY_ZONE_L_LEG)
	playsound(src, 'sound/magic/demon_attack1.ogg', 75, TRUE)

/obj/structure/trap/eldritch/mad
	name = "疯狂刻印"
	icon_state = "madness_rune"
	time_between_triggers = 20 SECONDS
	charges = 2
	carver_tip = "当它被踩到时，对触发者造成严重的耐力伤，施加失明和各种疾病. 有两次充能."

/obj/structure/trap/eldritch/mad/trap_effect(mob/living/victim)
	if(!iscarbon(victim))
		return
	var/mob/living/carbon/carbon_victim = victim
	carbon_victim.adjustStaminaLoss(80)
	carbon_victim.adjust_silence(20 SECONDS)
	carbon_victim.adjust_stutter(1 MINUTES)
	carbon_victim.adjust_confusion(5 SECONDS)
	carbon_victim.set_jitter_if_lower(20 SECONDS)
	carbon_victim.set_dizzy_if_lower(40 SECONDS)
	carbon_victim.adjust_temp_blindness(4 SECONDS)
	carbon_victim.add_mood_event("gates_of_mansus", /datum/mood_event/gates_of_mansus)
	playsound(src, 'sound/magic/blind.ogg', 75, TRUE)
