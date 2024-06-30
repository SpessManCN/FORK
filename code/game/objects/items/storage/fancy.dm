/*
 * The 'fancy' path is for objects like donut boxes that show how many items are in the storage item on the sprite itself
 * .. Sorry for the shitty path name, I couldnt think of a better one.
 *
 * Contains:
 * Donut Box
 * Egg Box
 * Candle Box
 * Cigarette Box
 * Rolling Paper Pack
 * Cigar Case
 * Heart Shaped Box w/ Chocolates
 * Coffee condiments display
 */

/obj/item/storage/fancy
	icon = 'icons/obj/food/containers.dmi'
	resistance_flags = FLAMMABLE
	custom_materials = list(/datum/material/cardboard = SHEET_MATERIAL_AMOUNT)
	/// Used by examine to report what this thing is holding.
	var/contents_tag = "errors"
	/// What type of thing to fill this storage with.
	var/spawn_type
	/// How many of the things to fill this storage with.
	var/spawn_count = 0
	/// Whether the container is open, always open, or closed
	var/open_status = FANCY_CONTAINER_CLOSED
	/// What material do we get when we fold this box?
	var/foldable_result = /obj/item/stack/sheet/cardboard
	/// Whether it supports open and closed state icons.
	var/has_open_closed_states = TRUE

/obj/item/storage/fancy/Initialize(mapload)
	. = ..()

	atom_storage.max_slots = spawn_count

/obj/item/storage/fancy/PopulateContents()
	if(!spawn_type)
		return
	for(var/i = 1 to spawn_count)
		var/thing_in_box = pick(spawn_type)
		new thing_in_box(src)

/obj/item/storage/fancy/update_icon_state()
	icon_state = "[base_icon_state][has_open_closed_states && open_status ? contents.len : null]"
	return ..()

/obj/item/storage/fancy/examine(mob/user)
	. = ..()
	if(!open_status)
		return
	if(length(contents) == 1)
		. += "There is one [contents_tag] left."
	else
		. += "There are [contents.len <= 0 ? "no" : "[contents.len]"] [contents_tag]s left."

/obj/item/storage/fancy/attack_self(mob/user)
	if(open_status == FANCY_CONTAINER_CLOSED)
		open_status = FANCY_CONTAINER_OPEN
	else if(open_status == FANCY_CONTAINER_OPEN)
		open_status = FANCY_CONTAINER_CLOSED

	update_appearance()
	. = ..()
	if(contents.len)
		return
	if(!foldable_result || (flags_1 & HOLOGRAM_1))
		return
	var/obj/item/result = new foldable_result(user.drop_location())
	balloon_alert(user, "folded")
	// Gotta delete first, so then the cardboard appears in the same hand
	qdel(src)
	user.put_in_hands(result)

/obj/item/storage/fancy/Exited(atom/movable/gone, direction)
	. = ..()
	if(open_status == FANCY_CONTAINER_CLOSED)
		open_status = FANCY_CONTAINER_OPEN
	update_appearance()

/obj/item/storage/fancy/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	if(open_status == FANCY_CONTAINER_CLOSED)
		open_status = FANCY_CONTAINER_OPEN
	update_appearance()

#define DONUT_INBOX_SPRITE_WIDTH 4

/*
 * Donut Box
 */

/obj/item/storage/fancy/donut_box
	name = "甜甜圈盒"
	desc = "Mmm. Donuts."
	icon = 'icons/obj/food/donuts.dmi'
	icon_state = "donutbox_open" //composite image used for mapping
	base_icon_state = "donutbox"
	spawn_type = /obj/item/food/donut/plain
	spawn_count = 6
	open_status = TRUE
	appearance_flags = KEEP_TOGETHER|LONG_GLIDE
	custom_premium_price = PAYCHECK_COMMAND * 1.75
	contents_tag = "donut"

/obj/item/storage/fancy/donut_box/Initialize(mapload)
	. = ..()
	atom_storage.set_holdable(/obj/item/food/donut)

/obj/item/storage/fancy/donut_box/PopulateContents()
	. = ..()
	update_appearance()

/obj/item/storage/fancy/donut_box/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state][open_status ? "_inner" : null]"

/obj/item/storage/fancy/donut_box/update_overlays()
	. = ..()
	if(!open_status)
		return

	var/donuts = 0
	for(var/_donut in contents)
		var/obj/item/food/donut/donut = _donut
		if (!istype(donut))
			continue

		. += image(icon = initial(icon), icon_state = donut.in_box_sprite(), pixel_x = donuts * DONUT_INBOX_SPRITE_WIDTH)
		donuts += 1

	. += image(icon = initial(icon), icon_state = "[base_icon_state]_top")

#undef DONUT_INBOX_SPRITE_WIDTH

/*
 * Egg Box
 */

/obj/item/storage/fancy/egg_box
	icon = 'icons/obj/food/containers.dmi'
	inhand_icon_state = "eggbox"
	icon_state = "eggbox"
	base_icon_state = "eggbox"
	lefthand_file = 'icons/mob/inhands/items/food_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/food_righthand.dmi'
	name = "鸡蛋盒"
	desc = "装鸡蛋的纸盒."
	spawn_type = /obj/item/food/egg
	spawn_count = 12
	contents_tag = "egg"

/obj/item/storage/fancy/egg_box/Initialize(mapload)
	. = ..()
	atom_storage.set_holdable(/obj/item/food/egg)

/*
 * Fertile Egg Box
 */

/obj/item/storage/fancy/egg_box/fertile
	name = "孵蛋箱"
	desc = "这里只有一样东西是可以孵化的，而且不是鸡蛋."
	spawn_type = /obj/item/food/egg/fertile
	spawn_count = 6

/*
 * Candle Box
 */

/obj/item/storage/fancy/candle_box
	name = "蜡烛盒"
	desc = "一包红蜡烛."
	icon = 'icons/obj/candle.dmi'
	icon_state = "candlebox5"
	base_icon_state = "candlebox"
	inhand_icon_state = null
	worn_icon_state = "cigpack"
	throwforce = 2
	slot_flags = ITEM_SLOT_BELT
	spawn_type = /obj/item/flashlight/flare/candle
	spawn_count = 5
	open_status = FANCY_CONTAINER_ALWAYS_OPEN
	contents_tag = "candle"

/obj/item/storage/fancy/candle_box/Initialize(mapload)
	. = ..()
	atom_storage.set_holdable(/obj/item/flashlight/flare/candle)

////////////
//CIG PACK//
////////////
/obj/item/storage/fancy/cigarettes
	name = "Space Cigarettes-太空香烟" // \improper
	desc = "最受欢迎的香烟品牌，太空奥运会的赞助商，在背面有广告词标榜自己是唯一能在真空环境下抽的香烟."
	icon = 'icons/obj/cigarettes.dmi'
	icon_state = "cig"
	inhand_icon_state = "cigpacket"
	worn_icon_state = "cigpack"
	base_icon_state = "cig"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 0
	slot_flags = ITEM_SLOT_BELT
	spawn_type = /obj/item/clothing/mask/cigarette/space_cigarette
	spawn_count = 6
	custom_price = PAYCHECK_CREW
	age_restricted = TRUE
	contents_tag = "cigarette"
	///for cigarette overlay
	var/candy = FALSE
	/// Does this cigarette packet come with a coupon attached?
	var/spawn_coupon = TRUE
	/// For VV'ing, set this to true if you want to force the coupon to give an omen
	var/rigged_omen = FALSE
	///Do we not have our own handling for cig overlays?
	var/display_cigs = TRUE

/obj/item/storage/fancy/cigarettes/attack_self(mob/user)
	if(contents.len != 0 || !spawn_coupon)
		return ..()

	balloon_alert(user, "ooh, 免费折扣")
	var/obj/item/coupon/attached_coupon = new
	user.put_in_hands(attached_coupon)
	attached_coupon.generate(rigged_omen ? COUPON_OMEN : null, null, user)
	attached_coupon = null
	spawn_coupon = FALSE
	name = "丢弃的烟盒"
	desc = "一个背面被撕掉的旧烟盒，一文不值."
	atom_storage.max_slots = 0

/obj/item/storage/fancy/cigarettes/Initialize(mapload)
	. = ..()
	atom_storage.display_contents = FALSE
	atom_storage.set_holdable(list(/obj/item/clothing/mask/cigarette, /obj/item/lighter))
	register_context()

/obj/item/storage/fancy/cigarettes/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	. = ..()
	if(interacting_with != user) // you can quickly put a cigarette in your mouth only
		return ..()
	quick_remove_item(/obj/item/clothing/mask/cigarette, user, equip_to_mouth = TRUE)

/obj/item/storage/fancy/cigarettes/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	quick_remove_item(/obj/item/clothing/mask/cigarette, user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/storage/fancy/cigarettes/click_alt(mob/user)
	var/obj/item/lighter = locate(/obj/item/lighter) in contents
	if(lighter)
		quick_remove_item(lighter, user)
	else
		quick_remove_item(/obj/item/clothing/mask/cigarette, user)
	return CLICK_ACTION_SUCCESS

/// Removes an item or puts it in mouth from the packet, if any
/obj/item/storage/fancy/cigarettes/proc/quick_remove_item(obj/item/grabbies, mob/user, equip_to_mouth =  FALSE)
	var/obj/item/finger = locate(grabbies) in contents
	if(finger)
		if(!equip_to_mouth)
			atom_storage.remove_single(user, finger, drop_location())
			user.put_in_hands(finger)
			return
		if(user.equip_to_slot_if_possible(finger, ITEM_SLOT_MASK, qdel_on_fail = FALSE, disable_warning = TRUE))
			finger.forceMove(user)
			return
		balloon_alert(user, "mouth is covered!")

/obj/item/storage/fancy/cigarettes/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	if(locate(/obj/item/lighter) in contents)
		context[SCREENTIP_CONTEXT_ALT_LMB] = "Remove lighter"
	context[SCREENTIP_CONTEXT_RMB] = "Remove [contents_tag]"
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/storage/fancy/cigarettes/examine(mob/user)
	. = ..()

	if(spawn_coupon)
		. += span_notice("包后面有一张折扣券，当盒内清空就可以撕下来.")

/obj/item/storage/fancy/cigarettes/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state][contents.len ? null : "_empty"]"

/obj/item/storage/fancy/cigarettes/update_overlays()
	. = ..()
	if(!open_status || !contents.len)
		return

	. += "[icon_state]_open"

	if(!display_cigs)
		return

	var/cig_position = 1
	for(var/C in contents)
		var/use_icon_state = ""

		if(istype(C, /obj/item/lighter/greyscale))
			use_icon_state = "lighter_in"
		else if(istype(C, /obj/item/lighter))
			use_icon_state = "zippo_in"
		else if(candy)
			use_icon_state = "candy"
		else
			use_icon_state = "cigarette"

		. += "[use_icon_state]_[cig_position]"
		cig_position++

/obj/item/storage/fancy/cigarettes/dromedaryco
	name = "DromedaryCo-丹峰牌香烟" // \improper
	desc = "一包六根的进口丹峰致癌棒，包装上写道, \"慢性死亡永不改变\""
	icon_state = "dromedary"
	base_icon_state = "dromedary"
	spawn_type = /obj/item/clothing/mask/cigarette/dromedary

/obj/item/storage/fancy/cigarettes/cigpack_uplift
	name = "Uplift-平滑上升香烟" // \improper
	desc = "你最爱的牌子，现在是薄荷味."
	icon_state = "uplift"
	base_icon_state = "uplift"
	spawn_type = /obj/item/clothing/mask/cigarette/uplift

/obj/item/storage/fancy/cigarettes/cigpack_robust
	name = "Robust-强健牌香烟" // \improper
	desc = "强健人，强健烟."
	icon_state = "robust"
	base_icon_state = "robust"
	spawn_type = /obj/item/clothing/mask/cigarette/robust

/obj/item/storage/fancy/cigarettes/cigpack_robustgold
	name = "Robust Gold-金强健牌香烟" // \improper
	desc = "给那些真强健的人."
	icon_state = "robustg"
	base_icon_state = "robustg"
	spawn_type = /obj/item/clothing/mask/cigarette/robustgold

/obj/item/storage/fancy/cigarettes/cigpack_carp
	name = "Carp Classic-经典鲤鱼香烟" // \improper
	desc = "Since 2313."
	icon_state = "carp"
	base_icon_state = "carp"
	spawn_type = /obj/item/clothing/mask/cigarette/carp

/obj/item/storage/fancy/cigarettes/cigpack_syndicate
	name = "特工牌香烟"
	desc = "一包来自未被查实品牌的香烟."
	icon_state = "syndie"
	base_icon_state = "syndie"
	spawn_type = /obj/item/clothing/mask/cigarette/syndicate

/obj/item/storage/fancy/cigarettes/cigpack_midori
	name = "Midori Tabako-野生卷烟包" // \improper
	desc = "你看不懂那些图案，而且闻起来很怪."
	icon_state = "midori"
	base_icon_state = "midori"
	spawn_type = /obj/item/clothing/mask/cigarette/rollie/nicotine

/obj/item/storage/fancy/cigarettes/cigpack_candy
	name = "Timmy's Candy-蒂米牌糖果香烟" // \improper
	desc = "不确定吸烟年龄吗？想让孩子健康地体验抽烟传统吗？不用再找特殊品牌了！这里有100%不含尼古丁的糖果香烟."
	icon_state = "candy"
	base_icon_state = "candy"
	contents_tag = "candy cigarette"
	spawn_type = /obj/item/clothing/mask/cigarette/candy
	candy = TRUE
	age_restricted = FALSE

/obj/item/storage/fancy/cigarettes/cigpack_candy/Initialize(mapload)
	. = ..()
	if(prob(7))
		spawn_type = /obj/item/clothing/mask/cigarette/candy/nicotine //uh oh!

/obj/item/storage/fancy/cigarettes/cigpack_shadyjims
	name = "Shady Jim's Super Slims-超级燃脂烟" // \improper
	desc = "体重拖累了你? 在逃离引力奇点时遇到了麻烦? 忍不住不停地吃吃吃? 抽一口超级燃脂眼，看着你的脂肪熊熊燃烧，质量有保证!"
	icon_state = "shadyjim"
	base_icon_state = "shadyjim"
	spawn_type = /obj/item/clothing/mask/cigarette/shadyjims

/obj/item/storage/fancy/cigarettes/cigpack_xeno
	name = "Xeno Filtered-异筛牌香烟" // \improper
	desc = "满载100%纯黏液，还有尼古丁."
	icon_state = "slime"
	base_icon_state = "slime"
	spawn_type = /obj/item/clothing/mask/cigarette/xeno

/obj/item/storage/fancy/cigarettes/cigpack_cannabis
	name = "芙蓉王香烟" // \improper
	desc = "包装上写着, \"请勿在公共场合抽烟.\""
	icon_state = "midori"
	base_icon_state = "midori"
	spawn_type = /obj/item/clothing/mask/cigarette/rollie/cannabis

/obj/item/storage/fancy/cigarettes/cigpack_mindbreaker
	name = "Leary's Delight-乐牌香烟" // \improper
	desc = "在超过36个星系被禁止售卖."
	icon_state = "shadyjim"
	base_icon_state = "shadyjim"
	spawn_type = /obj/item/clothing/mask/cigarette/rollie/mindbreaker

/obj/item/storage/fancy/rollingpapers
	name = "卷烟纸包"
	desc = "一包Nanotrasen牌卷烟纸."
	w_class = WEIGHT_CLASS_TINY
	icon = 'icons/obj/cigarettes.dmi'
	icon_state = "cig_paper_pack"
	base_icon_state = "cig_paper_pack"
	contents_tag = "rolling paper"
	spawn_type = /obj/item/rollingpaper
	spawn_count = 10
	custom_price = PAYCHECK_LOWER
	has_open_closed_states = FALSE

/obj/item/storage/fancy/rollingpapers/Initialize(mapload)
	. = ..()
	atom_storage.set_holdable(/obj/item/rollingpaper)

/obj/item/storage/fancy/rollingpapers/update_overlays()
	. = ..()
	if(!contents.len)
		. += "[base_icon_state]_empty"

/////////////
//CIGAR BOX//
/////////////

/obj/item/storage/fancy/cigarettes/cigars
	name = "\improper 优质雪茄盒"
	desc = "一盒上等雪茄，非常昂贵."
	icon = 'icons/obj/cigarettes.dmi'
	icon_state = "cigarcase"
	base_icon_state = "cigarcase"
	w_class = WEIGHT_CLASS_NORMAL
	contents_tag = "premium cigar"
	spawn_type = /obj/item/clothing/mask/cigarette/cigar/premium
	spawn_count = 5
	spawn_coupon = FALSE
	display_cigs = FALSE

/obj/item/storage/fancy/cigarettes/cigars/Initialize(mapload)
	. = ..()
	atom_storage.set_holdable(/obj/item/clothing/mask/cigarette/cigar)

/obj/item/storage/fancy/cigarettes/cigars/update_icon_state()
	. = ..()
	//reset any changes the parent call may have made
	icon_state = base_icon_state

/obj/item/storage/fancy/cigarettes/cigars/update_overlays()
	. = ..()
	if(!open_status)
		return
	var/cigar_position = 1 //generate sprites for cigars in the box
	for(var/obj/item/clothing/mask/cigarette/cigar/smokes in contents)
		. += "[smokes.icon_off]_[cigar_position]"
		cigar_position++

/obj/item/storage/fancy/cigarettes/cigars/cohiba
	name = "\improper 高斯巴强力雪茄盒"
	desc = "一盒进口高斯巴雪茄，以其浓郁的味道而闻名."
	icon_state = "cohibacase"
	base_icon_state = "cohibacase"
	spawn_type = /obj/item/clothing/mask/cigarette/cigar/cohiba

/obj/item/storage/fancy/cigarettes/cigars/havana
	name = "\improper 上等哈瓦那雪茄盒" //
	desc = "一盒上等的哈瓦那雪茄."
	icon_state = "cohibacase"
	base_icon_state = "cohibacase"
	spawn_type = /obj/item/clothing/mask/cigarette/cigar/havana

/*
 * Heart Shaped Box w/ Chocolates
 */

/obj/item/storage/fancy/heart_box
	name = "爱心盒子"
	desc = "装巧克力的爱心形盒子"
	icon = 'icons/obj/food/containers.dmi'
	inhand_icon_state = "chocolatebox"
	icon_state = "chocolatebox"
	base_icon_state = "chocolatebox"
	lefthand_file = 'icons/mob/inhands/items/food_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/food_righthand.dmi'
	contents_tag = "chocolate"
	spawn_type = list(
		/obj/item/food/bonbon,
		/obj/item/food/bonbon/chocolate_truffle,
		/obj/item/food/bonbon/caramel_truffle,
		/obj/item/food/bonbon/peanut_truffle,
		/obj/item/food/bonbon/peanut_butter_cup,
	)
	spawn_count = 8

/obj/item/storage/fancy/heart_box/Initialize(mapload)
	. = ..()
	atom_storage.set_holdable(/obj/item/food/bonbon)


/obj/item/storage/fancy/nugget_box
	name = "鸡块盒"
	desc = "用来装鸡块的鸡块盒."
	icon = 'icons/obj/food/containers.dmi'
	icon_state = "nuggetbox"
	base_icon_state = "nuggetbox"
	contents_tag = "nugget"
	spawn_type = /obj/item/food/nugget
	spawn_count = 6

/obj/item/storage/fancy/nugget_box/Initialize(mapload)
	. = ..()
	atom_storage.set_holdable(/obj/item/food/nugget)

/*
 * Jar of pickles
 */

/obj/item/storage/fancy/pickles_jar
	icon = 'icons/obj/food/containers.dmi'
	icon_state = "pickles"
	base_icon_state = "pickles"
	name = "腌菜罐"
	desc = "装腌菜的罐子."
	spawn_type = /obj/item/food/pickle
	spawn_count = 10
	contents_tag = "pickle"
	foldable_result = /obj/item/reagent_containers/cup/beaker/large
	custom_materials = list(/datum/material/glass = SHEET_MATERIAL_AMOUNT)
	open_status = FANCY_CONTAINER_ALWAYS_OPEN
	has_open_closed_states = FALSE

/obj/item/storage/fancy/pickles_jar/Initialize(mapload)
	. = ..()
	atom_storage.set_holdable(/obj/item/food/pickle)

/obj/item/storage/fancy/pickles_jar/update_icon_state()
	. = ..()
	if(!contents.len)
		icon_state = "[base_icon_state]_empty"
	else
		if(contents.len < 5)
			icon_state = "[base_icon_state]_[contents.len]"
		else
			icon_state = base_icon_state

/*
 * Coffee condiments display
 */

/obj/item/storage/fancy/coffee_condi_display
	icon = 'icons/obj/food/containers.dmi'
	icon_state = "coffee_condi_display"
	base_icon_state = "coffee_condi_display"
	name = "咖啡调味品收纳架"
	desc = "一个整洁的小木盒，装着所有你喜欢的咖啡调味品."
	contents_tag = "coffee condiment"
	custom_materials = list(/datum/material/wood = SHEET_MATERIAL_AMOUNT/2)
	resistance_flags = FLAMMABLE
	foldable_result = /obj/item/stack/sheet/mineral/wood
	open_status = FANCY_CONTAINER_ALWAYS_OPEN
	has_open_closed_states = FALSE

/obj/item/storage/fancy/coffee_condi_display/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 14
	atom_storage.set_holdable(list(
		/obj/item/reagent_containers/condiment/pack/sugar,
		/obj/item/reagent_containers/condiment/creamer,
		/obj/item/reagent_containers/condiment/pack/astrotame,
		/obj/item/reagent_containers/condiment/chocolate,
	))

/obj/item/storage/fancy/coffee_condi_display/update_overlays()
	. = ..()
	var/has_sugar = FALSE
	var/has_sweetener = FALSE
	var/has_creamer = FALSE
	var/has_chocolate = FALSE

	for(var/thing in contents)
		if(istype(thing, /obj/item/reagent_containers/condiment/pack/sugar))
			has_sugar = TRUE
		else if(istype(thing, /obj/item/reagent_containers/condiment/pack/astrotame))
			has_sweetener = TRUE
		else if(istype(thing, /obj/item/reagent_containers/condiment/creamer))
			has_creamer = TRUE
		else if(istype(thing, /obj/item/reagent_containers/condiment/chocolate))
			has_chocolate = TRUE

	if (has_sugar)
		. += "condi_display_sugar"
	if (has_sweetener)
		. += "condi_display_sweetener"
	if (has_creamer)
		. += "condi_display_creamer"
	if (has_chocolate)
		. += "condi_display_chocolate"

/obj/item/storage/fancy/coffee_condi_display/PopulateContents()
	for(var/i in 1 to 4)
		new /obj/item/reagent_containers/condiment/pack/sugar(src)
	for(var/i in 1 to 3)
		new /obj/item/reagent_containers/condiment/pack/astrotame(src)
	for(var/i in 1 to 4)
		new /obj/item/reagent_containers/condiment/creamer(src)
	for(var/i in 1 to 3)
		new /obj/item/reagent_containers/condiment/chocolate(src)
	update_appearance()
