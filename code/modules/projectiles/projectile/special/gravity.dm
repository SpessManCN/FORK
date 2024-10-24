/obj/projectile/gravityrepulse
	name = "排斥球"
	icon = 'icons/effects/effects.dmi'
	icon_state = "chronofield"
	hitsound = 'sound/weapons/wave.ogg'
	damage = 0
	damage_type = BRUTE
	color = COLOR_BLUE_LIGHT
	var/turf/T
	var/power = 4
	var/list/thrown_items = list()

/obj/projectile/gravityrepulse/Initialize(mapload)
	. = ..()
	var/obj/item/ammo_casing/energy/gravity/repulse/C = loc
	if(istype(C)) //Hard-coded maximum power so servers can't be crashed by trying to throw the entire Z level's items
		power = min(C.gun?.power, 15)

/obj/projectile/gravityrepulse/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	T = get_turf(src)
	for(var/atom/movable/A in range(T, power))
		if(A == src || (firer && A == src.firer) || A.anchored || thrown_items[A])
			continue
		if(ismob(A)) //because (ismob(A) && A:mob_negates_gravity()) is a recipe for bugs.
			var/mob/M = A
			if(M.mob_negates_gravity())
				continue
		var/throwtarget = get_edge_target_turf(src, get_dir(src, get_step_away(A, src)))
		A.safe_throw_at(throwtarget,power+1,1, force = MOVE_FORCE_EXTREMELY_STRONG)
		thrown_items[A] = A
	for(var/turf/F in RANGE_TURFS(power, T))
		new /obj/effect/temp_visual/gravpush(F)

/obj/projectile/gravityattract
	name = "牵引球"
	icon = 'icons/effects/effects.dmi'
	icon_state = "chronofield"
	hitsound = 'sound/weapons/wave.ogg'
	damage = 0
	damage_type = BRUTE
	color = "#FF6600"
	var/turf/T
	var/power = 4
	var/list/thrown_items = list()

/obj/projectile/gravityattract/Initialize(mapload)
	. = ..()
	var/obj/item/ammo_casing/energy/gravity/attract/C = loc
	if(istype(C)) //Hard-coded maximum power so servers can't be crashed by trying to throw the entire Z level's items
		power = min(C.gun?.power, 15)

/obj/projectile/gravityattract/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	T = get_turf(src)
	for(var/atom/movable/A in range(T, power))
		if(A == src || (firer && A == src.firer) || A.anchored || thrown_items[A])
			continue
		if(ismob(A))
			var/mob/M = A
			if(M.mob_negates_gravity())
				continue
		A.safe_throw_at(T, power+1, 1, force = MOVE_FORCE_EXTREMELY_STRONG)
		thrown_items[A] = A
	for(var/turf/F in RANGE_TURFS(power, T))
		new /obj/effect/temp_visual/gravpush(F)

/obj/projectile/gravitychaos
	name = "引力爆破"
	icon = 'icons/effects/effects.dmi'
	icon_state = "chronofield"
	hitsound = 'sound/weapons/wave.ogg'
	damage = 0
	damage_type = BRUTE
	color = COLOR_FULL_TONER_BLACK
	var/turf/T
	var/power = 4
	var/list/thrown_items = list()

/obj/projectile/gravitychaos/Initialize(mapload)
	. = ..()
	var/obj/item/ammo_casing/energy/gravity/chaos/C = loc
	if(istype(C)) //Hard-coded maximum power so servers can't be crashed by trying to throw the entire Z level's items
		power = min(C.gun?.power, 15)

/obj/projectile/gravitychaos/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	T = get_turf(src)
	for(var/atom/movable/A in range(T, power))
		if(A == src || (firer && A == src.firer) || A.anchored || thrown_items[A])
			continue
		if(ismob(A))
			var/mob/M = A
			if(M.mob_negates_gravity())
				continue
		A.safe_throw_at(get_edge_target_turf(A, pick(GLOB.cardinals)), power+1, 1, force = MOVE_FORCE_EXTREMELY_STRONG)
		thrown_items[A] = A
	for(var/turf/Z as anything in RANGE_TURFS(power,T))
		new /obj/effect/temp_visual/gravpush(Z)
