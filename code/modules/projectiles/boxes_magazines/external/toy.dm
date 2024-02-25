/obj/item/ammo_box/magazine/toy
	name = "泡沫MATA弹匣"
	ammo_type = /obj/item/ammo_casing/foam_dart
	caliber = CALIBER_FOAM

/obj/item/ammo_box/magazine/toy/smg
	name = "泡沫冲锋枪弹匣"
	icon_state = "smg9mm"
	base_icon_state = "smg9mm"
	ammo_type = /obj/item/ammo_casing/foam_dart
	max_ammo = 20

/obj/item/ammo_box/magazine/toy/smg/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]-[LAZYLEN(stored_ammo) ? "full" : "empty"]"

/obj/item/ammo_box/magazine/toy/smg/riot
	ammo_type = /obj/item/ammo_casing/foam_dart/riot

/obj/item/ammo_box/magazine/toy/pistol
	name = "泡沫手枪弹匣"
	icon_state = "9x19p"
	max_ammo = 8
	multiple_sprites = AMMO_BOX_FULL_EMPTY

/obj/item/ammo_box/magazine/toy/pistol/riot
	ammo_type = /obj/item/ammo_casing/foam_dart/riot

/obj/item/ammo_box/magazine/toy/smgm45
	name = "杜松冲锋枪弹匣"
	icon_state = "c20r45-toy"
	base_icon_state = "c20r45"
	caliber = CALIBER_FOAM
	ammo_type = /obj/item/ammo_casing/foam_dart
	max_ammo = 20

/obj/item/ammo_box/magazine/toy/smgm45/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]-[round(ammo_count(), 2)]"

/obj/item/ammo_box/magazine/toy/smgm45/riot
	icon_state = "c20r45-riot"
	ammo_type = /obj/item/ammo_casing/foam_dart/riot

/obj/item/ammo_box/magazine/toy/m762
	name = "杜松弹药盒"
	icon_state = "a7mm-toy"
	base_icon_state = "a7mm"
	ammo_type = /obj/item/ammo_casing/foam_dart
	max_ammo = 50

/obj/item/ammo_box/magazine/toy/m762/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]-[round(ammo_count(), 10)]"

/obj/item/ammo_box/magazine/toy/m762/riot
	icon_state = "a7mm-riot"
	ammo_type = /obj/item/ammo_casing/foam_dart/riot
