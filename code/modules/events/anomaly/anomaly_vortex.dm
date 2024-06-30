/datum/round_event_control/anomaly/anomaly_vortex
	name = "Anomaly: Vortex-漩涡"
	typepath = /datum/round_event/anomaly/anomaly_vortex

	min_players = 20
	max_occurrences = 2
	weight = 10
	description = "该异常会吸入周围物品并引爆."
	min_wizard_trigger_potency = 3
	max_wizard_trigger_potency = 7

/datum/round_event/anomaly/anomaly_vortex
	start_when = ANOMALY_START_DANGEROUS_TIME
	announce_when = ANOMALY_ANNOUNCE_DANGEROUS_TIME
	anomaly_path = /obj/effect/anomaly/bhole

/datum/round_event/anomaly/anomaly_vortex/announce(fake)
	if(isnull(impact_area))
		impact_area = placer.findValidArea()
	priority_announce("在 [ANOMALY_ANNOUNCE_DANGEROUS_TEXT] [impact_area.name] 检测到旋涡异常", "异常警报", ANNOUNCER_VORTEXANOMALIES) //SKYRAT EDIT CHANGE - ORIGINAL: priority_announce("Localized high-intensity vortex anomaly detected on [ANOMALY_ANNOUNCE_DANGEROUS_TEXT] [impact_area.name]", "Anomaly Alert")
