//The SmartDarts themselves
/obj/item/reagent_containers/syringe/smartdart
	name = "智能镖"
	desc = "能让使用者安全地远程注射化学物质，不会伤害患者."
	volume = 10
	icon = 'modular_skyrat/modules/medical/icons/obj/smartdarts.dmi'
	icon_state = "dart_0"
	possible_transfer_amounts = list(1, 2, 5, 10)
	base_icon_state = "dart"

//Code that handles the base interactions involving smartdarts
/obj/item/reagent_containers/syringe/smartdart/interact_with_atom(atom/target, mob/living/user, list/modifiers)
	if(isliving(target))
		to_chat(user, span_warning("[src]不支持手动注射化学物质."))
	return

//A majority of this code is from the original syringes.dm file.
/obj/item/reagent_containers/syringe/smartdart/interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(!try_syringe(interacting_with, user))
		return ITEM_INTERACT_BLOCKING

	if(reagents.total_volume >= reagents.maximum_volume)
		to_chat(user, span_notice("[src]已经满了."))
		return ITEM_INTERACT_BLOCKING

	if(isliving(interacting_with))
		to_chat(user, span_warning("[src]不支持抽血操作."))
		return ITEM_INTERACT_BLOCKING

	if(!interacting_with.reagents.total_volume)
		to_chat(user, span_warning("[interacting_with]已经空了!"))
		return ITEM_INTERACT_BLOCKING

	if(!interacting_with.is_drawable(user))
		to_chat(user, span_warning("无法直接从[interacting_with]中移除试剂!"))
		return ITEM_INTERACT_BLOCKING

	var/trans = interacting_with.reagents.trans_to(src, amount_per_transfer_from_this, transferred_by = user) // transfer from, transfer to - who cares?
	to_chat(user, span_notice("你将[trans]单位的溶液注入到[src] .目前它含有[reagents.total_volume]单位."))

	return ITEM_INTERACT_SUCCESS

//The base smartdartgun
/obj/item/gun/syringe/smartdart
	name = "医用飞镖枪"
	desc = "经过改装的医疗注射枪，只能装填智能镖."
	w_class = WEIGHT_CLASS_NORMAL //I might need to look into changing this later depending on feedback
	icon = 'modular_skyrat/modules/medical/icons/obj/dartguns.dmi'
	icon_state = "smartdartgun"
	worn_icon_state = "medicalsyringegun"
	item_flags = null

/obj/item/gun/syringe/smartdart/Initialize(mapload)
	. = ..()
	chambered = new /obj/item/ammo_casing/syringegun/dart(src)

/obj/item/gun/syringe/smartdart/give_gun_safeties()
	return

/obj/item/gun/syringe/smartdart/attackby(obj/item/container, mob/user, params, show_msg = TRUE)
	if(istype(container, /obj/item/reagent_containers/syringe/smartdart))
		..()
	else
		to_chat(user, span_notice("[container]无法装进[src]!请尝试使用<b>智能镖</b>."))
		return FALSE

/obj/item/gun/syringe/smartdart/examine(mob/user)
	. = ..()

	for(var/obj/item/reagent_containers/syringe/dart as anything in syringes)
		. += "里面已装有[dart]."

//Smartdart projectiles
/obj/item/ammo_casing/syringegun/dart
	harmful = FALSE
	projectile_type = /obj/projectile/bullet/dart/syringe/dart

//Handles loading smartdarts into regular syringeguns
/obj/item/ammo_casing/syringegun/newshot(alternative_ammo)
	if(!loaded_projectile)
		if(!isnull(alternative_ammo))
			loaded_projectile = new alternative_ammo(src, src)
			harmful = FALSE
		else
			loaded_projectile = new projectile_type(src, src)
			harmful = TRUE

/obj/projectile/bullet/dart/syringe/dart
	name = "智能镖"
	damage = 0
	//A list used to store to store the allergns of the target, so that it can be compared with later.
	var/list/allergy_list = list()
	///Is allergy prevention used?
	var/prevention_used = FALSE
	///List containing chemicals that Smartdarts can Inject.
	var/list/allowed_medicine = list(
		/datum/reagent/medicine,
		/datum/reagent/vaccine
	)
	///Blacklist that contains medicines that SmartDarts are unable to inject.
	var/list/disallowed_medicine = list(
		/datum/reagent/inverse/,
		/datum/reagent/medicine/morphine,
	)

/obj/projectile/bullet/dart/syringe/dart/on_hit(atom/target, blocked = 0, pierce_hit)
	if(!iscarbon(target))
		..(target, blocked)
		reagents.flags &= ~(NO_REACT)
		reagents.handle_reactions()
		return BULLET_ACT_HIT

	var/mob/living/carbon/injectee = target
	if(!injectee.can_inject(target_zone = def_zone, injection_flags = inject_flags)) // if the syringe is blocked
		blocked = 100
	if(blocked == 100)
		target.visible_message(span_danger("[src]被弹开了!"),
							span_userdanger("你防护住了[src]!"))
		return

	//Checks for allergies, and saves allergies to a list if they are present
	for(var/datum/quirk/quirky as anything in injectee.quirks)
		if(!istype(quirky, /datum/quirk/item_quirk/allergic))
			continue
		var/datum/quirk/item_quirk/allergic/allergies_quirk = quirky
		allergy_list = allergies_quirk.allergies

	//Variable that handles storage of chemical temperature
	var/chemical_temp = reagents.chem_temp

	//The code that handles the actual injections
	for(var/datum/reagent/meds in reagents.reagent_list)
		//Variable to store OD threshold (If present)
		var/overdose_amount
		//Amount of chemicals to inject, Changes if OD is present
		var/inject_amount = meds.volume

		if(meds.overdose_threshold > 0)
			overdose_amount = meds.overdose_threshold

			//This is mostly here for chemicals that have a low enough OD that an entire dart could trigger it
			if(inject_amount >= overdose_amount)
				inject_amount = overdose_amount

			for(var/datum/reagent/injectee_chemical in injectee.reagents.reagent_list)
				if(istype(injectee_chemical, meds))
					inject_amount = overdose_amount - injectee_chemical.volume

			inject_amount = inject_amount - 2 //This is here to give a bit of a buffer. If this is not here, the overdose prevention will fail to work.

			if(inject_amount <= 0)
				continue

		if(!is_type_in_list(meds, allowed_medicine))
			continue
		if(is_type_in_list(meds, disallowed_medicine))
			continue
		if(is_type_in_list(meds, allergy_list))
			prevention_used = TRUE
		else
			injectee.reagents.add_reagent(meds.type, inject_amount, null, chemical_temp, meds.purity)

	injectee.visible_message(span_notice("[src]嵌进了[injectee]体内"), span_notice("你感觉到一阵轻微刺痛，[src]嵌入了你的体内."))
	if(prevention_used) //Used to signal that allergens were not injected into the target mob.
		injectee.visible_message(span_notice("[src]发出一声短促的蜂鸣声."), span_notice("你听到[src]发出一声短促的蜂鸣声."))
		playsound(loc, 'sound/machines/ping.ogg', 50, 1, -1)
	return BULLET_ACT_HIT

