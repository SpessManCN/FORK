//his isn't a subtype of the syringe gun because the syringegun subtype is made to hold syringes
//this is meant to hold reagents/obj/item/gun/syringe
/obj/item/gun/chem
	name = "试剂枪"
	desc = "一把Nanotrasen注射器枪，经过修改可以自动合成化学飞镖，还需要向里填充试剂."
	icon_state = "chemgun"
	inhand_icon_state = "chemgun"
	w_class = WEIGHT_CLASS_NORMAL
	throw_speed = 3
	throw_range = 7
	force = 4
	custom_materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT)
	clumsy_check = FALSE
	fire_sound = 'sound/items/syringeproj.ogg'
	var/time_per_syringe = 250
	var/syringes_left = 4
	var/max_syringes = 4
	var/last_synth = 0

/obj/item/gun/chem/apply_fantasy_bonuses(bonus)
	. = ..()
	max_syringes = modify_fantasy_variable("max_syringes", max_syringes, bonus, minimum = 1)
	time_per_syringe = modify_fantasy_variable("time_per_syringe", time_per_syringe, -bonus * 10)

/obj/item/gun/chem/remove_fantasy_bonuses(bonus)
	max_syringes = reset_fantasy_variable("max_syringes", max_syringes)
	time_per_syringe = reset_fantasy_variable("time_per_syringe", time_per_syringe)
	return ..()


/obj/item/gun/chem/Initialize(mapload)
	. = ..()
	chambered = new /obj/item/ammo_casing/chemgun(src)
	START_PROCESSING(SSobj, src)
	create_reagents(90, OPENCONTAINER)

/obj/item/gun/chem/Destroy()
	. = ..()
	STOP_PROCESSING(SSobj, src)

/obj/item/gun/chem/can_shoot()
	return syringes_left

/obj/item/gun/chem/handle_chamber()
	if(chambered && !chambered.loaded_projectile && syringes_left)
		chambered.newshot()

/obj/item/gun/chem/process()
	if(syringes_left >= max_syringes)
		return
	if(world.time < last_synth+time_per_syringe)
		return
	to_chat(loc, span_warning("当[src]合成一个新的飞镖时，你听到一声咔嗒声."))
	syringes_left++
	if(chambered && !chambered.loaded_projectile)
		chambered.newshot()
	last_synth = world.time
