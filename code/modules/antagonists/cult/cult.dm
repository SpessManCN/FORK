/datum/antagonist/cult
	name = "血教徒"
	roundend_category = "血教徒"
	antagpanel_category = "血教"
	antag_moodlet = /datum/mood_event/cult
	suicide_cry = "FOR NAR'SIE!!"
	preview_outfit = /datum/outfit/cultist
	job_rank = ROLE_CULTIST
	antag_hud_name = "cult"

	///The vote ability Cultists have to elect someone to be the leader.
	var/datum/action/innate/cult/mastervote/vote_ability

	///Boolean on whether the starting equipment should be given to their inventory.
	var/give_equipment = FALSE
	///Reference to the Blood cult team they are part of.
	var/datum/team/cult/cult_team

/datum/antagonist/cult/can_be_owned(datum/mind/new_owner)
	if(!is_convertable_to_cult(new_owner.current, cult_team))
		return FALSE
	return ..()

/datum/antagonist/cult/greet()
	. = ..()
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/bloodcult/bloodcult_gain.ogg', 100, FALSE, pressure_affected = FALSE, use_reverb = FALSE)//subject to change
	owner.announce_objectives()

/datum/antagonist/cult/on_gain()
	objectives |= cult_team.objectives
	. = ..()
	var/mob/living/current = owner.current
	if(give_equipment)
		equip_cultist(TRUE)

	var/datum/action/innate/cult/comm/communion = new(owner)
	communion.Grant(current)
	if(isnull(cult_team.cult_leader_datum))
		vote_ability = new(owner)
		vote_ability.Grant(current)
	if(ishuman(current))
		var/datum/action/innate/cult/blood_magic/magic = new(owner)
		magic.Grant(current)

	current.log_message("皈依了Nar'Sie血教!", LOG_ATTACK, color="#960000")

/datum/antagonist/cult/on_removal()
	if(!silent)
		owner.current.visible_message(span_deconversion_message("[owner.current]看起来只是回归到了旧信仰!"), ignored_mobs = owner.current)
		to_chat(owner.current, span_userdanger("一道陌生白光闪过你的脑海，清除了几何血尊的腐化与你做为它仆人的全部记忆."))
		owner.current.log_message("放弃了对Nar'Sie的崇拜!", LOG_ATTACK, color="#960000")

	if(vote_ability)
		QDEL_NULL(vote_ability)
	for(var/datum/action/innate/cult/cult_buttons in owner.current.actions)
		qdel(cult_buttons)

	return ..()

/datum/antagonist/cult/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current || mob_override
	handle_clown_mutation(current, mob_override ? null : "你所受的训练让你克服了小丑的本性，你可以在不伤害自己的情况下使用武器.")
	current.faction |= FACTION_CULT
	current.grant_language(/datum/language/narsie, source = LANGUAGE_CULTIST)

	current.throw_alert("bloodsense", /atom/movable/screen/alert/bloodsense)
	if(cult_team.blood_target && cult_team.blood_target_image && current.client)
		current.client.images += cult_team.blood_target_image

	if(cult_team.cult_risen)
		current.AddElement(/datum/element/cult_eyes, initial_delay = 0 SECONDS)
	if(cult_team.cult_ascendent)
		current.AddElement(/datum/element/cult_halo, initial_delay = 0 SECONDS)

	ADD_TRAIT(current, TRAIT_HEALS_FROM_CULT_PYLONS, CULT_TRAIT)
	add_team_hud(current)

/datum/antagonist/cult/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current || mob_override
	handle_clown_mutation(current, removing = FALSE)
	current.faction -= FACTION_CULT
	current.remove_language(/datum/language/narsie, source = LANGUAGE_CULTIST)

	current.clear_alert("bloodsense")
	if(cult_team.blood_target && cult_team.blood_target_image && owner.current.client)
		owner.current.client.images -= cult_team.blood_target_image

	if (HAS_TRAIT(current, TRAIT_UNNATURAL_RED_GLOWY_EYES))
		current.RemoveElement(/datum/element/cult_eyes)
	if (HAS_TRAIT(current, TRAIT_CULT_HALO))
		current.RemoveElement(/datum/element/cult_halo)

	REMOVE_TRAIT(owner.current, TRAIT_HEALS_FROM_CULT_PYLONS, CULT_TRAIT)

/datum/antagonist/cult/on_mindshield(mob/implanter)
	if(!silent)
		to_chat(owner.current, span_warning("你感到有什么东西在干涉你的精神状态，但你抵抗住了!"))
	return

/datum/antagonist/cult/admin_add(datum/mind/new_owner,mob/admin)
	give_equipment = FALSE
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)]让[key_name_admin(new_owner)]成为血教徒.")
	log_admin("[key_name(admin)]让[key_name(new_owner)]成为血教徒.")

/datum/antagonist/cult/admin_remove(mob/user)
	silent = TRUE
	return ..()

/datum/antagonist/cult/get_admin_commands()
	. = ..()
	.["匕首"] = CALLBACK(src, PROC_REF(admin_give_dagger))
	.["匕首与金属"] = CALLBACK(src, PROC_REF(admin_give_metal))
	.["移除匕首与金属"] = CALLBACK(src, PROC_REF(admin_take_all))

	if(is_cult_leader())
		.["撤去领袖地位"] = CALLBACK(src, PROC_REF(demote_from_leader))
	else if(isnull(cult_team.cult_leader_datum))
		.["给予领袖地位"] = CALLBACK(src, PROC_REF(make_cult_leader))

/datum/antagonist/cult/get_team()
	return cult_team

/datum/antagonist/cult/create_team(datum/team/cult/new_team)
	if(!new_team)
		//todo remove this and allow admin buttons to create more than one cult
		for(var/datum/antagonist/cult/H in GLOB.antagonists)
			if(!H.owner)
				continue
			if(H.cult_team)
				cult_team = H.cult_team
				return
		cult_team = new /datum/team/cult
		cult_team.setup_objectives()
		return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	cult_team = new_team

///Equips the cultist with a dagger and runed metal.
/datum/antagonist/cult/proc/equip_cultist(metal = TRUE)
	var/mob/living/carbon/H = owner.current
	if(!istype(H))
		return
	. += cult_give_item(/obj/item/melee/cultblade/dagger, H)
	if(metal)
		. += cult_give_item(/obj/item/stack/sheet/runed_metal/ten, H)
	to_chat(owner, "这些东西可以帮助你在这个空间站上建立起血教，好好利用它们，记住你不是唯一一个这样做的人.</span>")

///Attempts to make a new item and put it in a potential inventory slot in the provided mob.
/datum/antagonist/cult/proc/cult_give_item(obj/item/item_path, mob/living/carbon/human/mob)
	var/item = new item_path(mob)
	var/where = mob.equip_conspicuous_item(item)
	if(!where)
		to_chat(mob, span_userdanger("很遗憾，你没有得到[item]. 这很糟糕并且你应该立刻adminhelp (按 F1)."))
		return FALSE
	else
		to_chat(mob, span_danger("[item]在你的[where]里."))
		if(where == "backpack")
			mob.back.atom_storage?.show_contents(mob)
		return TRUE

/datum/antagonist/cult/proc/admin_give_dagger(mob/admin)
	if(!equip_cultist(metal = FALSE))
		to_chat(admin, span_danger("生成匕首失败!"))

/datum/antagonist/cult/proc/admin_give_metal(mob/admin)
	if (!equip_cultist(metal = TRUE))
		to_chat(admin, span_danger("生成符文金属失败!"))

/datum/antagonist/cult/proc/admin_take_all(mob/admin)
	var/mob/living/current = owner.current
	for(var/o in current.get_all_contents())
		if(istype(o, /obj/item/melee/cultblade/dagger) || istype(o, /obj/item/stack/sheet/runed_metal))
			qdel(o)

///Returns whether or not this datum is its team's leader.
/datum/antagonist/cult/proc/is_cult_leader()
	return (cult_team.cult_leader_datum == src)

///Turns this antag datum into its team's leader, assigning them their unique abilities, hud, and deathrattle.
/datum/antagonist/cult/proc/make_cult_leader()
	if(cult_team.cult_leader_datum)
		return FALSE
	cult_team.cult_leader_datum = src

	antag_hud_name = "cultmaster"
	add_team_hud(owner.current)
	RegisterSignal(owner.current, COMSIG_MOB_STATCHANGE, PROC_REF(deathrattle))

	if(!cult_team.reckoning_complete)
		var/datum/action/innate/cult/master/finalreck/reckoning = new
		reckoning.Grant(owner.current)
	var/datum/action/innate/cult/master/cultmark/bloodmark = new
	var/datum/action/innate/cult/master/pulse/throwing = new
	bloodmark.Grant(owner.current)
	throwing.Grant(owner.current)
	owner.current.update_mob_action_buttons()

	for(var/datum/mind/cult_mind as anything in cult_team.members)
		vote_ability.Remove(cult_mind.current)
		to_chat(cult_mind.current, span_cultlarge("[owner.current]赢得了血教徒们的支持，现在这个人是教主. \
			尽你所能去完成[owner.current.p_their()]下达的命令!"))

	to_chat(owner.current, span_cultlarge("<span class='warningplain'>你是血教的教主</span>. \
		作为血教教主，首先，你在群语时拥有独特的头衔与响亮的声音；其次，你能够标记目标指引教众，比如标记某地或某不信者；\
		最后，你有<b><i>一次</i></b>召唤所有活着的血教成员到你位置的机会. 你要妥善使用这些能力，指引血教不惜一切代价取得胜利."))

	return TRUE

///Admin-only helper to demote someone from Cult leader, taking away their HUD, abilities, and deathrattle
///And gives all cultists from their team back their ability to vote for a new leader.
/datum/antagonist/cult/proc/demote_from_leader()
	if(!cult_team.cult_leader_datum)
		return FALSE
	cult_team.cult_leader_datum = null

	antag_hud_name = initial(antag_hud_name)
	add_team_hud(owner.current)
	UnregisterSignal(owner.current, COMSIG_MOB_STATCHANGE)

	var/datum/action/innate/cult/master/finalreck/reckoning = locate() in owner.current.actions
	if(reckoning)
		reckoning.Remove(owner.current)
	var/datum/action/innate/cult/master/cultmark/bloodmark = locate() in owner.current.actions
	if(bloodmark)
		bloodmark.Remove(owner.current)
	var/datum/action/innate/cult/master/pulse/throwing = locate() in owner.current.actions
	if(throwing)
		throwing.Remove(owner.current)
	owner.current.update_mob_action_buttons()
	for(var/datum/mind/cult_mind as anything in cult_team.members)
		vote_ability.Grant(cult_mind.current)

	to_chat(owner.current, span_cultlarge("你已经从教主位置上被撤职了，你现在又成了教徒!"))

	return TRUE

///If dead (and Narsie isn't summoned), will alert all Cultists of their death, sending their location out.
/datum/antagonist/cult/proc/deathrattle(datum/source)
	SIGNAL_HANDLER

	if(owner.current.stat != DEAD)
		return
	if(!QDELETED(GLOB.cult_narsie))
		return
	if(!is_cult_leader())
		return

	var/area/current_area = get_area(owner.current)
	for(var/datum/mind/cult_mind as anything in cult_team.members)
		SEND_SOUND(cult_mind, sound('sound/hallucinations/veryfar_noise.ogg'))
		to_chat(cult_mind, span_cultlarge("教主，[owner.current.name]，殁于[current_area]!"))

/datum/antagonist/cult/get_preview_icon()
	var/icon/icon = render_preview_outfit(preview_outfit)

	// The longsword is 64x64, but getFlatIcon crunches to 32x32.
	// So I'm just going to add it in post, screw it.

	// Center the dude, because item icon states start from the center.
	// This makes the image 64x64.
	icon.Crop(-15, -15, 48, 48)

	var/obj/item/melee/cultblade/longsword = new
	icon.Blend(icon(longsword.lefthand_file, longsword.inhand_icon_state), ICON_OVERLAY)
	qdel(longsword)

	// Move the guy back to the bottom left, 32x32.
	icon.Crop(17, 17, 48, 48)

	return finish_preview_icon(icon)

/datum/outfit/cultist
	name = "Cultist (Preview only)"

	uniform = /obj/item/clothing/under/color/black
	suit = /obj/item/clothing/suit/hooded/cultrobes/alt
	head = /obj/item/clothing/head/hooded/cult_hoodie/alt
	shoes = /obj/item/clothing/shoes/cult/alt
	r_hand = /obj/item/melee/blood_magic/stun

/datum/outfit/cultist/post_equip(mob/living/carbon/human/equipped, visualsOnly)
	equipped.eye_color_left = BLOODCULT_EYE
	equipped.eye_color_right = BLOODCULT_EYE
	equipped.update_body()

///Returns whether the given mob is convertable to the blood cult
/proc/is_convertable_to_cult(mob/living/target, datum/team/cult/specific_cult)
	if(!istype(target))
		return FALSE
	if(isnull(target.mind) || !GET_CLIENT(target))
		return FALSE
	if(target.mind.unconvertable)
		return FALSE
	if(ishuman(target) && target.mind.holy_role)
		return FALSE
	if(specific_cult?.is_sacrifice_target(target.mind))
		return FALSE
	var/mob/living/master = target.mind.enslaved_to?.resolve()
	if(master && !IS_CULTIST(master))
		return FALSE
	if(IS_HERETIC_OR_MONSTER(target))
		return FALSE
	if(HAS_TRAIT(target, TRAIT_MINDSHIELD) || issilicon(target) || isbot(target) || isdrone(target))
		return FALSE //can't convert machines, shielded, or braindead
	return TRUE
