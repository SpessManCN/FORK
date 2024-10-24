/// 一个叛徒. 叛徒在创建和确立后不应被删除，只能失败.
/// 如果需要从处理器的失败/完成列表中移除叛徒，那么你做错了，应该重新考虑.
/// 当一个目标失败/完成时，这是最终结果，唯一改变的方法是重构代码.
/datum/traitor_objective
	/// 叛徒的名称
	var/name = "叛徒"
	/// 叛徒的描述
	var/description = "这是一个叛徒"
	/// 用于给予进展点和TC的上行链路处理器持有者.
	var/datum/uplink_handler/handler
	/// 此所需的最低进展点
	var/progression_minimum = null
	/// 在此进展点以上时，此不再出现
	var/progression_maximum = INFINITY
	/// 完成此叛徒所奖励的进展点. 可以是 list(min, max) 形式或直接值
	var/progression_reward = 0 MINUTES
	/// 完成此叛徒所奖励的TC. 可以是 list(min,max) 形式或直接值
	var/telecrystal_reward = 0
	/// 失败或取消的TC惩罚
	var/telecrystal_penalty = 1
	/// 此首次创建的时间
	var/time_of_creation = 0
	/// 此完成的时间
	var/time_of_completion = 0
	/// 此的当前状态
	var/objective_state = OBJECTIVE_STATE_INACTIVE
	/// 是否由管理员强制. 超过一定进展点后不会被叛徒子系统自动清除
	var/forced = FALSE
	/// 是否通过从未激活状态跳到失败状态来跳过此.
	var/skipped = FALSE

	/// 确定全局进展对该的影响程度. 设为 0 则禁用.
	var/global_progression_influence_intensity = 0.1
	/// 确定进展开始减少前需要的偏差量.
	var/global_progression_deviance_required = 1
	/// 确定此由于受全局进展影响而可能值的最低和最高进展点
	/// 应小于或等于 1
	var/global_progression_limit_coeff = 0.6
	/// 用于确定进展奖励随机性的偏差系数.
	var/progression_cost_coeff_deviance = 0.05
	/// 在计算更新后的进展成本时添加到系数上的值. 用于变化和一点点随机性
	var/progression_cost_coeff = 0
	/// 此由于进展而增加或减少的百分比. 用于 UI
	var/original_progression = 0
	/// 抽象类型，不会作为可能的包含在内
	var/abstract_type = /datum/traitor_objective
	/// 用于检查重复的重复类型.
	/// 如果未定义，则将从抽象类型或本身的类型中选取
	var/duplicate_type = null
	/// 仅用于单元测试. 可用于显式跳过非抽象的进展奖励和TC奖励检查.
	/// 对于不需要奖励的最终很有用.
	var/needs_reward = TRUE

/// 返回可通过配置更改的变量列表，允许通过配置进行平衡.
/// 不建议在你的服务器上微调的任何值.
/datum/traitor_objective/proc/supported_configuration_changes()
	return list(
		NAMEOF(src, global_progression_influence_intensity),
		NAMEOF(src, global_progression_deviance_required),
		NAMEOF(src, global_progression_limit_coeff)
	)

/// 替换过程名称中的某个词. 描述也会进行相同替换.
/datum/traitor_objective/proc/replace_in_name(replace, word)
	name = replacetext(name, replace, word)
	description = replacetext(description, replace, word)

/datum/traitor_objective/New(datum/uplink_handler/handler)
	. = ..()
	src.handler = handler
	src.time_of_creation = world.time
	apply_configuration()
	if(SStraitor.generate_objectives)
		if(islist(telecrystal_reward))
			telecrystal_reward = rand(telecrystal_reward[1], telecrystal_reward[2])
		if(islist(progression_reward))
			progression_reward = rand(progression_reward[1], progression_reward[2])
	else
		if(!islist(telecrystal_reward))
			telecrystal_reward = list(telecrystal_reward, telecrystal_reward)
		if(!islist(progression_reward))
			progression_reward = list(progression_reward, progression_reward)
	progression_cost_coeff = (rand()*2 - 1) * progression_cost_coeff_deviance

/datum/traitor_objective/proc/apply_configuration()
	if(!length(SStraitor.configuration_data))
		return
	var/datum/traitor_objective/current_type = type
	var/list/types = list()
	while(current_type != /datum/traitor_objective)
		types += current_type
		current_type = type2parent(current_type)
	types += /datum/traitor_objective
	// Reverse the list direction
	reverse_range(types)
	var/list/supported_configurations = supported_configuration_changes()
	for(var/typepath in types)
		if(!(typepath in SStraitor.configuration_data))
			continue
		var/list/changes = SStraitor.configuration_data[typepath]
		for(var/variable in changes)
			if(!(variable in supported_configurations))
				continue
			vars[variable] = changes[variable]


/// 更新进展奖励，根据当前进展与全局进展的比较进行缩放
/datum/traitor_objective/proc/update_progression_reward()
	if(!SStraitor.generate_objectives)
		return
	progression_reward = original_progression
	if(global_progression_influence_intensity <= 0)
		return
	var/minimum_progression = progression_reward * global_progression_limit_coeff
	var/maximum_progression = progression_reward * (2-global_progression_limit_coeff)
	var/deviance = (SStraitor.current_global_progression - handler.progression_points) / SStraitor.progression_scaling_deviance
	if(abs(deviance) < global_progression_deviance_required)
		return
	if(abs(deviance) == deviance) // If it is positive
		deviance = deviance - global_progression_deviance_required
	else
		deviance = deviance + global_progression_deviance_required
	var/coeff = NUM_E ** (global_progression_influence_intensity * abs(deviance)) - 1
	if(abs(deviance) != deviance)
		coeff *= -1

	// This has less of an effect as the coeff gets nearer to -1. Is linear
	coeff += progression_cost_coeff * min(max(1 - abs(coeff), 1), 0)


	progression_reward = clamp(
		progression_reward + progression_reward * coeff,
		minimum_progression,
		maximum_progression
	)

/datum/traitor_objective/Destroy(force)
	handler = null
	return ..()

/// Called whenever the objective is about to be generated. Bypassed by forcefully adding objectives.
/// Returning false or true will do the same as the generate_objective proc.
/datum/traitor_objective/proc/can_generate_objective(datum/mind/generating_for, list/possible_duplicates)
	return TRUE

/// Called when the objective should be generated. Should return if the objective has been successfully generated.
/// If false is returned, the objective will be removed as a potential objective for the traitor it is being generated for.
/// This is only temporary, it will run the proc again when objectives are generated for the traitor again.
/datum/traitor_objective/proc/generate_objective(datum/mind/generating_for, list/possible_duplicates)
	return FALSE

/// Used to clean up signals and stop listening to states.
/datum/traitor_objective/proc/ungenerate_objective()
	return

/datum/traitor_objective/proc/get_log_data()
	return list(
		"type" = type,
		"owner" = handler.owner.key,
		"name" = name,
		"description" = description,
		"telecrystal_reward" = telecrystal_reward,
		"progression_reward" = progression_reward,
		"original_progression" = original_progression,
		"objective_state" = objective_state,
		"forced" = forced,
		"time_of_creation" = time_of_creation,
	)

/// Converts the type into a useful debug string to be used for logging and debug display.
/datum/traitor_objective/proc/to_debug_string()
	return "[type] (Name: [name], TC: [telecrystal_reward], Progression: [progression_reward], Time of creation: [time_of_creation])"

/datum/traitor_objective/proc/save_objective()
	SSblackbox.record_feedback("associative", "traitor_objective", 1, get_log_data())

/// Used to handle cleaning up the objective.
/datum/traitor_objective/proc/handle_cleanup()
	time_of_completion = world.time
	ungenerate_objective()
	if(objective_state == OBJECTIVE_STATE_INACTIVE)
		skipped = TRUE
		handler.complete_objective(src) // Remove this objective immediately, no reason to keep it around. It isn't even active

/// Used to fail objectives. Players can clear completed objectives in the UI
/datum/traitor_objective/proc/fail_objective(penalty_cost = 0, trigger_update = TRUE)
	// Don't let players succeed already succeeded/failed objectives
	if(objective_state != OBJECTIVE_STATE_INACTIVE && objective_state != OBJECTIVE_STATE_ACTIVE)
		return
	SEND_SIGNAL(src, COMSIG_TRAITOR_OBJECTIVE_FAILED)
	handle_cleanup()
	log_traitor("[key_name(handler.owner)] [objective_state == OBJECTIVE_STATE_INACTIVE? "missed" : "已失败"] [to_debug_string()]")
	if(penalty_cost)
		handler.add_telecrystals(-penalty_cost)
		objective_state = OBJECTIVE_STATE_FAILED
	else
		objective_state = OBJECTIVE_STATE_INVALID
	save_objective()
	if(trigger_update)
		handler.on_update() // Trigger an update to the UI

/// Used to succeed objectives. Allows the player to cash it out in the UI.
/datum/traitor_objective/proc/succeed_objective()
	// Don't let players succeed already succeeded/failed objectives
	if(objective_state != OBJECTIVE_STATE_INACTIVE && objective_state != OBJECTIVE_STATE_ACTIVE)
		return
	SEND_SIGNAL(src, COMSIG_TRAITOR_OBJECTIVE_COMPLETED)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_TRAITOR_OBJECTIVE_COMPLETED, src)
	handle_cleanup()
	log_traitor("[key_name(handler.owner)] [objective_state == OBJECTIVE_STATE_INACTIVE? "missed" : "已完成"] [to_debug_string()]")
	objective_state = OBJECTIVE_STATE_COMPLETED
	save_objective()
	handler.on_update() // Trigger an update to the UI

/// Called by player input, do not call directly. Validates whether the objective is finished and pays out the handler if it is.
/datum/traitor_objective/proc/finish_objective(mob/user)
	switch(objective_state)
		if(OBJECTIVE_STATE_FAILED, OBJECTIVE_STATE_INVALID)
			user.playsound_local(get_turf(user), 'sound/traitor/objective_failed.ogg', vol = 100, vary = FALSE, channel = CHANNEL_TRAITOR)
			return TRUE
		if(OBJECTIVE_STATE_COMPLETED)
			user.playsound_local(get_turf(user), 'sound/traitor/objective_success.ogg', vol = 100, vary = FALSE, channel = CHANNEL_TRAITOR)
			completion_payout()
			return TRUE
	return FALSE

/// Called when rewards should be given to the user.
/datum/traitor_objective/proc/completion_payout()
	handler.progression_points += progression_reward
	handler.add_telecrystals(telecrystal_reward)

/// Used for sending data to the uplink UI
/datum/traitor_objective/proc/uplink_ui_data(mob/user)
	return list(
		"name" = name,
		"description" = description,
		"progression_minimum" = progression_minimum,
		"progression_reward" = progression_reward,
		"telecrystal_reward" = telecrystal_reward,
		"ui_buttons" = generate_ui_buttons(user),
		"objective_state" = objective_state,
		"original_progression" = original_progression,
		"telecrystal_penalty" = telecrystal_penalty,
	)

/datum/traitor_objective/proc/on_objective_taken(mob/user)
	SStraitor.on_objective_taken(src)
	log_traitor("[key_name(handler.owner)] 已接取目标: [to_debug_string()]")

/// Used for generating the UI buttons for the UI. Use ui_perform_action to respond to clicks.
/datum/traitor_objective/proc/generate_ui_buttons(mob/user)
	return

/datum/traitor_objective/proc/add_ui_button(name, tooltip, icon, action)
	return list(list(
		"name" = name,
		"tooltip" = tooltip,
		"icon" = icon,
		"action" = action,
	))

/// Return TRUE to trigger a UI update
/datum/traitor_objective/proc/ui_perform_action(mob/user, action)
	return TRUE
