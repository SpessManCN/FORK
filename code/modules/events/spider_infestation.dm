/datum/round_event_control/spider_infestation
	name = "Spider Infestation-蜘蛛入侵"
	typepath = /datum/round_event/spider_infestation
	weight = 10
	max_occurrences = 1
	min_players = 20
	dynamic_should_hijack = TRUE
	category = EVENT_CATEGORY_ENTITIES
	description = "生成随时可孵化完成的蜘蛛卵."
	min_wizard_trigger_potency = 5
	max_wizard_trigger_potency = 7

/datum/round_event/spider_infestation
	announce_when = 400
	var/spawncount = 2

/datum/round_event/spider_infestation/setup()
	announce_when = rand(announce_when, announce_when + 50)

/datum/round_event/spider_infestation/announce(fake)
	priority_announce("探测到不明生命迹象进入到[station_name()].确保所有外部通道，包括通风等安全.", "生物信号警报", ANNOUNCER_ALIENS)

/datum/round_event/spider_infestation/start()
	create_midwife_eggs(spawncount)

/proc/create_midwife_eggs(amount)
	while(amount > 0)
		var/turf/spawn_loc = find_maintenance_spawn(atmos_sensitive = TRUE, require_darkness = TRUE)
		if(isnull(spawn_loc))
			return //Admins will have already been notified of the spawning failure at this point
		var/obj/effect/mob_spawn/ghost_role/spider/midwife/new_eggs = new (spawn_loc)
		new_eggs.amount_grown = 98
		amount--
	log_game("Midwife spider eggs were spawned via an event.")
	return TRUE

