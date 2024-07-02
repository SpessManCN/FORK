/datum/round_event_control/electrical_storm
	name = "Electrical Storm-电离风暴"
	typepath = /datum/round_event/electrical_storm
	earliest_start = 10 MINUTES
	min_players = 5
	weight = 20
	category = EVENT_CATEGORY_ENGINEERING
	description = "摧毁大范围内的所有照明灯光."
	min_wizard_trigger_potency = 0
	max_wizard_trigger_potency = 4

/datum/round_event/electrical_storm
	var/lightsoutAmount = 1
	var/lightsoutRange = 25
	announce_when = 1

/datum/round_event/electrical_storm/announce(fake)
	priority_announce("在您的区域检测到电离风暴，请修复潜在的电子过载.", "电离风暴警报", ANNOUNCER_ELECTRICALSTORM) //SKYRAT EDIT CHANGE


/datum/round_event/electrical_storm/start()
	var/list/epicentreList = list()

	for(var/i in 1 to lightsoutAmount)
		var/turf/T = get_safe_random_station_turf()
		if(istype(T))
			epicentreList += T

	if(!epicentreList.len)
		return

	for(var/centre in epicentreList)
		for(var/obj/machinery/power/apc/apc as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/apc))
			if(get_dist(centre, apc) <= lightsoutRange)
				apc.overload_lighting()
