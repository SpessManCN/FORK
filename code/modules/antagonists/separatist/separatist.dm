/datum/team/nation
	name = "\improper 国家"
	member_name = "分离主义者"
	/// 可以加入该国家的一系列等级.
	var/list/potential_recruits
	/// 与该团队相关的部门
	var/datum/job_department/department
	/// 是否制定攻击其他国家的目标
	var/dangerous_nation = TRUE

/datum/team/nation/New(starting_members, potential_recruits, department)
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_CREWMEMBER_JOINED, PROC_REF(new_possible_separatist))
	src.potential_recruits = potential_recruits
	src.department = department

/datum/team/nation/Destroy(force)
	department = null
	UnregisterSignal(SSdcs, COMSIG_GLOB_CREWMEMBER_JOINED)
	. = ..()

/**
 * 信号，用于将新的船员（玩家加入游戏）添加到革命中.
 *
 * 参数:
 * source: 全局信号，因此这是 SSdcs.
 * crewmember: 新的船员.
 * rank: 新船员的等级.
 */
/datum/team/nation/proc/new_possible_separatist(datum/source, mob/living/crewmember, rank)
	SIGNAL_HANDLER

	if(rank in potential_recruits)
		// 我们可以相信刚刚加入游戏的玩家有一颗头脑.
		crewmember.mind.add_antag_datum(/datum/antagonist/separatist,src)

/**
 * 由部门叛乱事件调用，为团队提供一些目标.
 *
 * 参数:
 * dangerous_nation: 是否该国家将获得非常非常嗜血的目标，比如杀死其他部门.
 * target_nation: 他们需要摧毁/与之友好的国家的字符串
 */
/datum/team/nation/proc/generate_nation_objectives(are_we_hostile = TRUE, datum/team/nation/target_nation)

	var/datum/objective/fluff
	if(istype(department, /datum/job_department/silicon))
		// 雪花，但是硅元素有自己的目标
		fluff = new /datum/objective/united_nations()

	else
		dangerous_nation = are_we_hostile
		if(dangerous_nation && target_nation)
			var/datum/objective/destroy = new /datum/objective/destroy_nation(null, target_nation)
			destroy.team = src
			objectives += destroy
			target_nation.war_declared(src) // 他们可能需要得到一个目标
		fluff = new /datum/objective/separatist_fluff(null, name)

	fluff.team = src
	objectives += fluff
	update_all_member_objectives()

/datum/team/nation/proc/war_declared(datum/team/nation/attacking_nation)
	if(!dangerous_nation) // 和平的国家不希望反击
		return
	// 否则，让我们添加一个目标来反击他们
	var/datum/objective/destroy = new /datum/objective/destroy_nation(null, attacking_nation)
	destroy.team = src
	objectives += destroy
	update_all_member_objectives(span_danger("国家[attacking_nation]已宣布意图征服[src]！你有新的目标. "))

/datum/team/nation/proc/update_all_member_objectives(message)
	for(var/datum/mind/member in members)
		var/datum/antagonist/separatist/needs_objectives = member.has_antag_datum(/datum/antagonist/separatist)
		needs_objectives.objectives |= objectives
		if(message)
			to_chat(member.current, message)
		needs_objectives.owner.announce_objectives()

/datum/antagonist/separatist
	name = "\improper 分离主义者"
	show_in_antagpanel = FALSE
	show_name_in_check_antagonists = TRUE
	suicide_cry = "为了祖国!!"
	ui_name = "AntagInfoSeparatist"
	///team datum
	var/datum/team/nation/nation
	///background color of the ui
	var/ui_color

/datum/antagonist/separatist/on_gain()
	create_objectives()
	setup_ui_color()
	. = ..()

//give ais their role as UN
/datum/antagonist/separatist/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/silicon/ai/united_nations_ai = mob_override || owner.current
	if(isAI(united_nations_ai))
		united_nations_ai.laws = new /datum/ai_laws/united_nations()
		united_nations_ai.laws.associate(united_nations_ai)
		united_nations_ai.show_laws()

/datum/antagonist/separatist/on_removal()
	remove_objectives()
	. = ..()

/datum/antagonist/separatist/proc/create_objectives()
	objectives |= nation.objectives

/datum/antagonist/separatist/proc/remove_objectives()
	objectives -= nation.objectives

/datum/antagonist/separatist/proc/setup_ui_color()
	var/list/hsl = rgb2num(nation.department.ui_color, COLORSPACE_HSL)
	hsl[3] = 25 //setting lightness very low
	ui_color = rgb(hsl[1], hsl[2], hsl[3], space = COLORSPACE_HSL)

/datum/antagonist/separatist/create_team(datum/team/nation/new_team)
	if(!new_team)
		return
	nation = new_team

/datum/antagonist/separatist/get_team()
	return nation

/datum/antagonist/separatist/ui_static_data(mob/user)
	var/list/data = list()
	data["objectives"] = get_objectives()
	data["nation"] = nation.name
	data["nationColor"] = ui_color
	return data
