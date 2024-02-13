/obj/item/gun/energy/ionrifle //SKYRAT EDIT - ICON OVERRIDDEN IN AESTHETICS MODULE
	name = "离子步枪"
	desc = "一种单兵便携式反装甲武器，设计用于在远距离上瘫痪机械结构."
	icon_state = "ionrifle"
	inhand_icon_state = null //so the human update icon uses the icon_state instead.
	worn_icon_state = null
	shaded_charge = TRUE
	w_class = WEIGHT_CLASS_HUGE
	obj_flags = CONDUCTS_ELECTRICITY
	slot_flags = ITEM_SLOT_BACK
	ammo_type = list(/obj/item/ammo_casing/energy/ion)

/obj/item/gun/energy/ionrifle/add_seclight_point()
	AddComponent(/datum/component/seclite_attachable, \
		light_overlay_icon = 'icons/obj/weapons/guns/flashlights.dmi', \
		light_overlay = "flight", \
		overlay_x = 17, \
		overlay_y = 9)

/obj/item/gun/energy/ionrifle/emp_act(severity)
	return

/obj/item/gun/energy/ionrifle/carbine
	name = "离子卡宾枪"
	desc = "MK.II原型离子投射器是离子步枪的轻型卡宾枪版本，符合人体工程学设计，更易携带."
	icon_state = "ioncarbine"
	worn_icon_state = "gun"
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BELT

/obj/item/gun/energy/ionrifle/carbine/add_seclight_point()
	. = ..()
	// We use the same overlay as the parent, so we can just let the component inherit the correct offsets here
	AddComponent(/datum/component/seclite_attachable, overlay_x = 18, overlay_y = 11)

/obj/item/gun/energy/floragun
	name = "花卉特征射线枪"
	desc = "一种释放可控辐射的工具，能诱导植物细胞发生突变."
	icon_state = "flora"
	inhand_icon_state = "gun"
	ammo_type = list(/obj/item/ammo_casing/energy/flora/yield, /obj/item/ammo_casing/energy/flora/mut, /obj/item/ammo_casing/energy/flora/revolution)
	modifystate = 1
	ammo_x_offset = 1
	selfcharge = 1
	gun_flags = NOT_A_REAL_GUN

/obj/item/gun/energy/meteorgun
	name = "陨石枪"
	desc = "看在上帝的份上, 好好地瞄准正确的地方!"
	icon_state = "meteor_gun"
	inhand_icon_state = "c20r"
	w_class = WEIGHT_CLASS_BULKY
	ammo_type = list(/obj/item/ammo_casing/energy/meteor)
	cell_type = /obj/item/stock_parts/cell/potato
	clumsy_check = 0 //Admin spawn only, might as well let clowns use it.
	selfcharge = 1
	automatic_charge_overlays = FALSE

/obj/item/gun/energy/meteorgun/pen
	name = "陨石笔"
	desc = "言语胜于刀剑，笔尖胜过干戈."
	icon = 'icons/obj/service/bureaucracy.dmi'
	icon_state = "pen"
	inhand_icon_state = "pen"
	worn_icon_state = "pen"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	automatic_charge_overlays = FALSE

/obj/item/gun/energy/mindflayer
	name = "夺心魔"
	desc = "从爱普西隆研究站废墟中找到的原型武器."
	icon_state = "xray"
	w_class = WEIGHT_CLASS_BULKY
	inhand_icon_state = null
	ammo_type = list(/obj/item/ammo_casing/energy/mindflayer)
	ammo_x_offset = 2

/obj/item/gun/energy/plasmacutter
	name = "等离子切割器"
	desc = "一种能够驱使浓缩等离子体爆发的采矿工具，你可以用它来切掉异形的四肢!或者...你知道的，别的什么东西."
	icon_state = "plasmacutter"
	inhand_icon_state = "plasmacutter"
	ammo_type = list(/obj/item/ammo_casing/energy/plasma)
	obj_flags = CONDUCTS_ELECTRICITY
	attack_verb_continuous = list("攻击", "劈向", "切向", "划向")
	attack_verb_simple = list("攻击", "劈向", "切向", "划向")
	force = 12
	sharpness = SHARP_EDGED
	can_charge = FALSE
	gun_flags = NOT_A_REAL_GUN

	heat = 3800
	usesound = list('sound/items/welder.ogg', 'sound/items/welder2.ogg')
	tool_behaviour = TOOL_WELDER
	toolspeed = 0.7 //plasmacutters can be used as welders, and are faster than standard welders
	var/charge_weld = 25 //amount of charge used up to start action (multiplied by amount) and per progress_flash_divisor ticks of welding

/obj/item/gun/energy/plasmacutter/Initialize(mapload)
	AddElement(/datum/element/update_icon_blocker)
	. = ..()
	AddComponent(/datum/component/butchering, \
		speed = 2.5 SECONDS, \
		effectiveness = 105, \
		bonus_modifier = 0, \
		butcher_sound = 'sound/weapons/plasma_cutter.ogg', \
	)
	AddElement(/datum/element/tool_flash, 1)

/obj/item/gun/energy/plasmacutter/examine(mob/user)
	. = ..()
	if(cell)
		. += span_notice("[src]当前电量[round(cell.percent())]%.")

/obj/item/gun/energy/plasmacutter/attackby(obj/item/I, mob/user)
	var/charge_multiplier = 0 //2 = Refined stack, 1 = Ore
	if(istype(I, /obj/item/stack/sheet/mineral/plasma))
		charge_multiplier = 2
	if(istype(I, /obj/item/stack/ore/plasma))
		charge_multiplier = 1
	if(charge_multiplier)
		if(cell.charge == cell.maxcharge)
			balloon_alert(user, "已经充满电了!")
			return
		I.use(1)
		cell.give(500*charge_multiplier)
		balloon_alert(user, "电池已充能")
	else
		..()

/obj/item/gun/energy/plasmacutter/emp_act(severity)
	if(!cell.charge)
		return
	cell.use(cell.charge/3)
	if(isliving(loc))
		var/mob/living/user = loc
		user.visible_message(span_danger("聚集的等离子体从[src]释放到了[user]身上!"), span_userdanger("[src]发生故障，将浓缩的等离子体喷射到了你身上!"))
		user.adjust_fire_stacks(4)
		user.ignite_mob()

// Can we weld? Plasma cutter does not use charge continuously.
// Amount cannot be defaulted to 1: most of the code specifies 0 in the call.
/obj/item/gun/energy/plasmacutter/tool_use_check(mob/living/user, amount)
	if(QDELETED(cell))
		balloon_alert(user, "无电池安装!")
		return FALSE
	// Amount cannot be used if drain is made continuous, e.g. amount = 5, charge_weld = 25
	// Then it'll drain 125 at first and 25 periodically, but fail if charge dips below 125 even though it still can finish action
	// Alternately it'll need to drain amount*charge_weld every period, which is either obscene or makes it free for other uses
	if(amount ? cell.charge < charge_weld * amount : cell.charge < charge_weld)
		balloon_alert(user, "没有足够的电量!")
		return FALSE

	return TRUE

/obj/item/gun/energy/plasmacutter/use(used)
	return (!QDELETED(cell) && cell.use(used ? used * charge_weld : charge_weld))

/obj/item/gun/energy/plasmacutter/use_tool(atom/target, mob/living/user, delay, amount=1, volume=0, datum/callback/extra_checks)

	if(amount)
		var/mutable_appearance/sparks = mutable_appearance('icons/effects/welding_effect.dmi', "welding_sparks", GASFIRE_LAYER, src, ABOVE_LIGHTING_PLANE)
		target.add_overlay(sparks)
		LAZYADD(update_overlays_on_z, sparks)
		. = ..()
		LAZYREMOVE(update_overlays_on_z, sparks)
		target.cut_overlay(sparks)
	else
		. = ..(amount=1)

/obj/item/gun/energy/plasmacutter/adv
	name = "先进等离子切割器"
	icon_state = "adv_plasmacutter"
	inhand_icon_state = "adv_plasmacutter"
	force = 15
	ammo_type = list(/obj/item/ammo_casing/energy/plasma/adv)

#define AMMO_SELECT_BLUE 1
#define AMMO_SELECT_ORANGE 2

/obj/item/gun/energy/wormhole_projector
	name = "蓝空虫洞投影仪"
	desc = "发射高密度量子耦合蓝空光束的投影仪，需要蓝空间异常核心才能运作. 可以装到包里."
	ammo_type = list(/obj/item/ammo_casing/energy/wormhole, /obj/item/ammo_casing/energy/wormhole/orange)
	can_select = FALSE // left-click for blue, right-click for orange.
	w_class = WEIGHT_CLASS_NORMAL
	inhand_icon_state = null
	icon_state = "wormhole_projector"
	base_icon_state = "wormhole_projector"
	automatic_charge_overlays = FALSE
	var/obj/effect/portal/p_blue
	var/obj/effect/portal/p_orange
	var/firing_core = FALSE
	gun_flags = NOT_A_REAL_GUN

/obj/item/gun/energy/wormhole_projector/examine(mob/user)
	. = ..()
	. += span_notice("<b>左键</b>左键发射蓝色虫洞门，<b><font color=orange>右键</font></b>发射橙色虫洞门.")

/obj/item/gun/energy/wormhole_projector/attackby(obj/item/C, mob/user)
	if(istype(C, /obj/item/assembly/signaler/anomaly/bluespace))
		to_chat(user, span_notice("你把[C]插入虫洞投影仪，武器开始轻轻地嗡嗡作响."))
		firing_core = TRUE
		playsound(src.loc, 'sound/machines/click.ogg', 50, TRUE)
		qdel(C)
		return

/obj/item/gun/energy/wormhole_projector/can_shoot()
	if(!firing_core)
		return FALSE
	return ..()

/obj/item/gun/energy/wormhole_projector/shoot_with_empty_chamber(mob/living/user)
	. = ..()
	to_chat(user, span_danger("显示说，'无核心安装'."))

/obj/item/gun/energy/wormhole_projector/update_icon_state()
	. = ..()
	icon_state = inhand_icon_state = "[base_icon_state][select]"

/obj/item/gun/energy/wormhole_projector/update_ammo_types()
	. = ..()
	for(var/i in 1 to ammo_type.len)
		var/obj/item/ammo_casing/energy/wormhole/W = ammo_type[i]
		if(istype(W))
			W.gun = WEAKREF(src)
			var/obj/projectile/beam/wormhole/WH = W.loaded_projectile
			if(istype(WH))
				WH.gun = WEAKREF(src)

/obj/item/gun/energy/wormhole_projector/afterattack(atom/target, mob/living/user, flag, params)
	if(select == AMMO_SELECT_ORANGE) //Last fired in right click mode. Switch to blue wormhole (left click).
		select_fire()
	return ..()

/obj/item/gun/energy/wormhole_projector/afterattack_secondary(atom/target, mob/living/user, flag, params)
	if(select == AMMO_SELECT_BLUE) //Last fired in left click mode. Switch to orange wormhole (right click).
		select_fire()
	fire_gun(target, user, flag, params)
	return SECONDARY_ATTACK_CONTINUE_CHAIN

/obj/item/gun/energy/wormhole_projector/proc/on_portal_destroy(obj/effect/portal/P)
	SIGNAL_HANDLER
	if(P == p_blue)
		p_blue = null
	else if(P == p_orange)
		p_orange = null

/obj/item/gun/energy/wormhole_projector/proc/has_blue_portal()
	if(istype(p_blue) && !QDELETED(p_blue))
		return TRUE
	return FALSE

/obj/item/gun/energy/wormhole_projector/proc/has_orange_portal()
	if(istype(p_orange) && !QDELETED(p_orange))
		return TRUE
	return FALSE

/obj/item/gun/energy/wormhole_projector/proc/crosslink()
	if(!has_blue_portal() && !has_orange_portal())
		return
	if(!has_blue_portal() && has_orange_portal())
		p_orange.link_portal(null)
		return
	if(!has_orange_portal() && has_blue_portal())
		p_blue.link_portal(null)
		return
	p_orange.link_portal(p_blue)
	p_blue.link_portal(p_orange)

/obj/item/gun/energy/wormhole_projector/proc/create_portal(obj/projectile/beam/wormhole/wormhole_beam, turf/target)
	var/obj/effect/portal/new_portal = new /obj/effect/portal(target, 300, null, FALSE, null)
	RegisterSignal(new_portal, COMSIG_QDELETING, PROC_REF(on_portal_destroy))
	if(istype(wormhole_beam, /obj/projectile/beam/wormhole/orange))
		qdel(p_orange)
		p_orange = new_portal
		new_portal.icon_state = "portal1"
		new_portal.set_light_color(COLOR_MOSTLY_PURE_ORANGE)
		new_portal.update_light()
	else
		qdel(p_blue)
		p_blue = new_portal
	crosslink()

/obj/item/gun/energy/wormhole_projector/core_inserted
	firing_core = TRUE

#undef AMMO_SELECT_BLUE
#undef AMMO_SELECT_ORANGE

/* 3d printer 'pseudo guns' for borgs */

/obj/item/gun/energy/printer
	name = "赛博格轻机枪"
	desc = "可以发射3D打印弹片的轻机枪，会使用赛博格电源缓慢补给."
	icon_state = "l6_cyborg"
	icon = 'icons/obj/weapons/guns/ballistic.dmi'
	cell_type = /obj/item/stock_parts/cell/secborg
	ammo_type = list(/obj/item/ammo_casing/energy/c3dbullet)
	can_charge = FALSE
	use_cyborg_cell = TRUE

/obj/item/gun/energy/printer/Initialize(mapload)
	AddElement(/datum/element/update_icon_blocker)
	. = ..()
	AddComponent(/datum/component/automatic_fire, 0.3 SECONDS)

/obj/item/gun/energy/printer/emp_act()
	return

/obj/item/gun/energy/temperature
	name = "温度枪"
	icon_state = "freezegun"
	desc = "能改变温度的枪，附带可折叠枪托."
	w_class = WEIGHT_CLASS_NORMAL
	ammo_type = list(/obj/item/ammo_casing/energy/temp, /obj/item/ammo_casing/energy/temp/hot)
	cell_type = /obj/item/stock_parts/cell/high
	pin = null

/obj/item/gun/energy/temperature/security
	name = "安保温度枪"
	desc = "只有真正强健的人才能充分发挥它的潜能."
	pin = /obj/item/firing_pin

/obj/item/gun/energy/temperature/freeze
	name = "低温枪"
	desc = "降低温度的枪，能让人的血管里流着冰."
	pin = /obj/item/firing_pin
	ammo_type = list(/obj/item/ammo_casing/energy/temp)

/obj/item/gun/energy/gravity_gun
	name = "单点重力操纵器"
	desc = "一种实验性的多模式装置，可以发射零点能量，造成局部重力扭曲，需要重力异常核心才能发挥作用."
	w_class = WEIGHT_CLASS_BULKY
	ammo_type = list(/obj/item/ammo_casing/energy/gravity/repulse, /obj/item/ammo_casing/energy/gravity/attract, /obj/item/ammo_casing/energy/gravity/chaos)
	inhand_icon_state = "gravity_gun"
	icon_state = "gravity_gun"
	automatic_charge_overlays = FALSE
	var/power = 4
	var/firing_core = FALSE
	gun_flags = NOT_A_REAL_GUN

/obj/item/gun/energy/gravity_gun/attackby(obj/item/C, mob/user)
	if(istype(C, /obj/item/assembly/signaler/anomaly/grav))
		to_chat(user, span_notice("你把[C]插入重力操纵器，武器开始轻轻地嗡嗡作响."))
		firing_core = TRUE
		playsound(src.loc, 'sound/machines/click.ogg', 50, TRUE)
		qdel(C)
		return
	return ..()

/obj/item/gun/energy/gravity_gun/can_shoot()
	if(!firing_core)
		return FALSE
	return ..()

/obj/item/gun/energy/tesla_cannon
	name = "特斯拉加农炮"
	icon_state = "tesla"
	inhand_icon_state = "tesla"
	desc = "一把能射出\"特斯拉\"的枪，射就是了."
	ammo_type = list(/obj/item/ammo_casing/energy/tesla_cannon)
	shaded_charge = TRUE
	weapon_weight = WEAPON_HEAVY

/obj/item/gun/energy/tesla_cannon/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/automatic_fire, 0.1 SECONDS)

/obj/item/gun/energy/marksman_revolver
	name = "神射手左轮"
	desc = "利用电脉冲以极高的速度发射微小的金属碎片，在开火时右键抛出硬币，击中后可以获得额外的火力."
	icon = 'icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "revolver"
	ammo_type = list(/obj/item/ammo_casing/energy/marksman)
	fire_sound = 'sound/weapons/gun/revolver/shot_alt.ogg'
	automatic_charge_overlays = FALSE
	/// How many coins we can have at a time. Set to 0 for infinite
	var/max_coins = 4
	/// How many coins we currently have available
	var/coin_count = 0
	/// How long it takes to regen a coin
	var/coin_regen_rate = 2 SECONDS
	/// The cooldown for regenning coins
	COOLDOWN_DECLARE(coin_regen_cd)

/obj/item/gun/energy/marksman_revolver/Initialize(mapload)
	. = ..()
	coin_count = max_coins

/obj/item/gun/energy/marksman_revolver/examine(mob/user)
	. = ..()
	if(max_coins)
		. += "它当前有[coin_count]枚硬币，最多可储存[max_coins]枚，每过[coin_regen_rate/10]将补充一枚."
	else
		. += "它拥有无限的硬币可供使用."

/obj/item/gun/energy/marksman_revolver/process(seconds_per_tick)
	if(!max_coins || coin_count >= max_coins)
		STOP_PROCESSING(SSobj, src)
		return

	if(COOLDOWN_FINISHED(src, coin_regen_cd))
		if(ismob(loc))
			var/mob/owner = loc
			owner.playsound_local(owner, 'sound/machines/ding.ogg', 20)
		coin_count++
		COOLDOWN_START(src, coin_regen_cd, coin_regen_rate)

/obj/item/gun/energy/marksman_revolver/afterattack_secondary(atom/target, mob/living/user, params)
	if(!can_see(user, get_turf(target), length = 9))
		return ..()

	if(max_coins && coin_count <= 0)
		to_chat(user, span_warning("你当前没有任何硬币可用!"))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if(max_coins)
		START_PROCESSING(SSobj, src)
		coin_count = max(0, coin_count - 1)

	var/turf/target_turf = get_offset_target_turf(target, rand(-1, 1), rand(-1, 1)) // choose a random tile adjacent to the clicked one
	playsound(user.loc, 'sound/effects/coin2.ogg', 50, TRUE)
	user.visible_message(span_warning("[user]向[target]抛出硬币!"), span_danger("你向[target]抛出硬币!"))
	var/obj/projectile/bullet/coin/new_coin = new(get_turf(user), target_turf, user)
	new_coin.preparePixelProjectile(target_turf, user)
	new_coin.fire()

	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
