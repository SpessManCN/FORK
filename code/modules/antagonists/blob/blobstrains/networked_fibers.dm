//does massive brute and burn damage, but can only expand manually
/datum/blobstrain/reagent/networked_fibers
	name = "网络纤维"
	description = "将会造成高额的创伤烧伤混合伤害，同时更快地生成资源，但只能通过核心或节点手动扩展建立."
	shortdesc = "将会造成高额的创伤烧伤混合伤害."
	effectdesc = "在靠近核心或节点的位置时，手动扩展它将移动你的核心和节点."
	analyzerdescdamage = "造成高额的创伤烧伤混合伤害."
	analyzerdesceffect = "具有移动性并且能够快速生成资源."
	color = "#4F4441"
	complementary_color = "#414C4F"
	reagent = /datum/reagent/blob/networked_fibers
	core_regen_bonus = 3

/datum/blobstrain/reagent/networked_fibers/expand_reaction(obj/structure/blob/spawning_blob, obj/structure/blob/new_blob, turf/chosen_turf, mob/camera/blob/overmind)
	if(!overmind && new_blob.overmind)
		new_blob.overmind.add_points(1)
		qdel(new_blob)
		return
	if(isspaceturf(chosen_turf))
		return
	for(var/obj/structure/blob/possible_expander in range(1, new_blob))
		if(possible_expander.overmind == overmind && (istype(possible_expander, /obj/structure/blob/special/core) || istype(possible_expander, /obj/structure/blob/special/node)))
			new_blob.forceMove(get_turf(possible_expander))
			possible_expander.forceMove(chosen_turf)
			possible_expander.setDir(get_dir(new_blob, possible_expander))
			return
	overmind.add_points(4)
	qdel(new_blob)

//does massive brute and burn damage, but can only expand manually
/datum/reagent/blob/networked_fibers
	name = "网络纤维"
	taste_description = "高效"
	color = "#4F4441"

/datum/reagent/blob/networked_fibers/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message, touch_protection, mob/camera/blob/overmind)
	. = ..()
	reac_volume = return_mob_expose_reac_volume(exposed_mob, methods, reac_volume, show_message, touch_protection, overmind)
	exposed_mob.apply_damage(0.6*reac_volume, BRUTE, wound_bonus=CANT_WOUND)
	if(!QDELETED(exposed_mob))
		exposed_mob.apply_damage(0.6*reac_volume, BURN, wound_bonus=CANT_WOUND)
