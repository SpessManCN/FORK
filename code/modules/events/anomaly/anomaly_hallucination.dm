/datum/round_event_control/anomaly/anomaly_hallucination
	name = "Anomaly: Hallucination-幻觉"
	typepath = /datum/round_event/anomaly/anomaly_hallucination

	min_players = 10
	max_occurrences = 5
	weight = 20
	description = "该异常引发幻觉."
	min_wizard_trigger_potency = 0
	max_wizard_trigger_potency = 2

/datum/round_event/anomaly/anomaly_hallucination
	start_when = ANOMALY_START_MEDIUM_TIME
	announce_when = ANOMALY_ANNOUNCE_MEDIUM_TIME
	anomaly_path = /obj/effect/anomaly/hallucination

/datum/round_event/anomaly/anomaly_hallucination/announce(fake)
	if(isnull(impact_area))
		impact_area = placer.findValidArea()
	priority_announce("在 [ANOMALY_ANNOUNCE_MEDIUM_TEXT] [impact_area.name]检测到心灵异常.", "异常警报", ANNOUNCER_ANOMALIES) //SKYRAT EDIT CHANGE - ORIGINAL: priority_announce("Hallucinatory event detected on [ANOMALY_ANNOUNCE_MEDIUM_TEXT] [impact_area.name].", "Anomaly Alert")
