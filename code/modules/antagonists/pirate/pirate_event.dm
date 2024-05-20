#define NO_ANSWER 0
#define POSITIVE_ANSWER 1
#define NEGATIVE_ANSWER 2

/datum/round_event_control/pirates
	name = "太空海盗"
	typepath = /datum/round_event/pirates
	weight = 10
	max_occurrences = 1
	min_players = 20
	dynamic_should_hijack = TRUE
	category = EVENT_CATEGORY_INVASION
	description = "船员们要么付钱，要么被海盗袭击."
	admin_setup = list(/datum/event_admin_setup/listed_options/pirates)
	map_flags = EVENT_SPACE_ONLY

/datum/round_event_control/pirates/preRunEvent()
	if (!SSmapping.is_planetary())
		return EVENT_CANT_RUN
	return ..()

/datum/round_event/pirates
	///admin chosen pirate team
	var/list/datum/pirate_gang/gang_list

/datum/round_event/pirates/start()
	send_pirate_threat(gang_list)

/proc/send_pirate_threat(list/pirate_selection)
	var/datum/pirate_gang/chosen_gang = pick_n_take(pirate_selection)
	///If there was nothing to pull from our requested list, stop here.
	if(!chosen_gang)
		message_admins("试图运行太空海盗事件时出错，因为给定的海盗团列表为空.")
		return
	//set payoff
	var/payoff = 0
	var/datum/bank_account/account = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(account)
		payoff = max(PAYOFF_MIN, FLOOR(account.account_balance * 0.80, 1000))
	var/datum/comm_message/threat = chosen_gang.generate_message(payoff)
	//send message
	priority_announce("传入子空间通讯. 在所有通讯终端上打开安全频道.", "信息传入", SSstation.announcer.get_rand_report_sound())
	threat.answer_callback = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(pirates_answered), threat, chosen_gang, payoff, world.time)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(spawn_pirates), threat, chosen_gang), RESPONSE_MAX_TIME)
	SScommunications.send_message(threat, unique = TRUE)

/proc/pirates_answered(datum/comm_message/threat, datum/pirate_gang/chosen_gang, payoff, initial_send_time)
	if(world.time > initial_send_time + RESPONSE_MAX_TIME)
		priority_announce(chosen_gang.response_too_late, sender_override = chosen_gang.ship_name, color_override = chosen_gang.announcement_color)
		return
	if(!threat?.answered)
		return
	if(threat.answered == NEGATIVE_ANSWER)
		priority_announce(chosen_gang.response_rejected, sender_override = chosen_gang.ship_name, color_override = chosen_gang.announcement_color)
		return

	var/datum/bank_account/plundered_account = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(plundered_account)
		if(plundered_account.adjust_money(-payoff))
			chosen_gang.paid_off = TRUE
			priority_announce(chosen_gang.response_received, sender_override = chosen_gang.ship_name, color_override = chosen_gang.announcement_color)
		else
			priority_announce(chosen_gang.response_not_enough, sender_override = chosen_gang.ship_name, color_override = chosen_gang.announcement_color)

/proc/spawn_pirates(datum/comm_message/threat, datum/pirate_gang/chosen_gang)
	if(chosen_gang.paid_off)
		return

	var/list/candidates = SSpolling.poll_ghost_candidates("你想成为[chosen_gang.name]的海盗吗?", check_jobban = ROLE_TRAITOR, pic_source = /obj/item/claymore/cutlass, role_name_text = "海盗")
	shuffle_inplace(candidates)

	var/template_key = "pirate_[chosen_gang.ship_template_id]"
	var/datum/map_template/shuttle/pirate/ship = SSmapping.shuttle_templates[template_key]
	var/x = rand(TRANSITIONEDGE,world.maxx - TRANSITIONEDGE - ship.width)
	var/y = rand(TRANSITIONEDGE,world.maxy - TRANSITIONEDGE - ship.height)
	var/z = SSmapping.empty_space.z_value
	var/turf/T = locate(x,y,z)
	if(!T)
		CRASH("Pirate event found no turf to load in")

	if(!ship.load(T))
		CRASH("Loading pirate ship failed!")

	for(var/turf/A in ship.get_affected_turfs(T))
		for(var/obj/effect/mob_spawn/ghost_role/human/pirate/spawner in A)
			if(candidates.len > 0)
				var/mob/our_candidate = candidates[1]
				var/mob/spawned_mob = spawner.create_from_ghost(our_candidate)
				candidates -= our_candidate
				notify_ghosts(
					"[chosen_gang.ship_name]感兴趣的对象: [spawned_mob]!",
					source = spawned_mob,
					header = "Pirates!",
				)
			else
				notify_ghosts(
					"[chosen_gang.ship_name]感兴趣的对象: [spawner]!",
					source = spawner,
					header = "海盗生成!",
				)

	priority_announce(chosen_gang.arrival_announcement, sender_override = chosen_gang.ship_name)

/datum/event_admin_setup/listed_options/pirates
	input_text = "选择海盗团"
	normal_run_option = "随机海盗团"

/datum/event_admin_setup/listed_options/pirates/get_list()
	return subtypesof(/datum/pirate_gang)

/datum/event_admin_setup/listed_options/pirates/apply_to_event(datum/round_event/pirates/event)
	if(isnull(chosen))
		event.gang_list = GLOB.light_pirate_gangs + GLOB.heavy_pirate_gangs
	else
		event.gang_list = list(new chosen)

#undef NO_ANSWER
#undef POSITIVE_ANSWER
#undef NEGATIVE_ANSWER
