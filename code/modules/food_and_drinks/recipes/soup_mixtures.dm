/// Abstract parent for soup reagents.
/// These are the majority result from soup recipes,
/// but bear in mind it will(should) have other reagents along side it.
/datum/reagent/consumable/nutriment/soup
	name = "Soup"
	chemical_flags = NONE
	nutriment_factor = 12 // Slightly less to that of nutriment as soups will come with nutriments in tow
	burning_temperature = 520
	default_container = /obj/item/reagent_containers/cup/bowl
	glass_price = FOOD_PRICE_CHEAP
	fallback_icon = 'icons/obj/food/soupsalad.dmi'
	fallback_icon_state = "bowl"
	restaurant_order = /datum/custom_order/reagent/soup

/**
 * ## Soup base chemical reaction.
 *
 * Somewhat important note! Keep in mind one serving of soup is roughly 20-25 units. Adjust your results according.
 *
 * Try to aim to have each reaction worth 3 servings of soup (60u - 90u).
 * By default soup reactions require 50 units of water,
 * and they will also inherent the reagents of the ingredients used,
 * so you might end up with more nutrient than you expect.
 */
/datum/chemical_reaction/food/soup
	required_temp = 450
	optimal_temp = 480
	overheat_temp = SOUP_BURN_TEMP
	optimal_ph_min = 1
	optimal_ph_max = 14
	thermic_constant = 10
	required_reagents = null
	mob_react = FALSE
	required_other = TRUE
	required_container_accepts_subtypes = TRUE
	required_container = /obj/item/reagent_containers/cup/soup_pot
	mix_message = "你从热气腾腾的汤锅里闻到了香味."
	reaction_tags = REACTION_TAG_FOOD | REACTION_TAG_EASY

	// General soup guideline:
	// - Soups should produce 60-90 units (3-4 servings)
	// - One serving size is 20-25 units (8-9 sips, with 3u sips)
	// - The first index of the result list should be the soup type

	/// An assoc list of what ingredients are necessary to how much is needed
	var/list/required_ingredients
	/// Tracks the total number of ingredient items needed, for calculating multipliers. Only done once in first on_reaction
	VAR_FINAL/total_ingredient_max

	/// Multiplier applied to all reagents transferred from reagents to pot when the soup is cooked
	var/ingredient_reagent_multiplier = 0.8
	/// What percent of nutriment is converted to "soup" (what percent does not stay final product)?
	/// Raise this if your ingredients have a lot of nutriment and is overpowering your other reagents
	/// Lower this if your ingredients have a small amount of nutriment and isn't filling enough per serving
	/// (EX: A tomato with 10 nutriment will lose 2.5 nutriment before being added to the pot)
	var/percentage_of_nutriment_converted = 0.25

/datum/chemical_reaction/food/soup/pre_reaction_other_checks(datum/reagents/holder)
	var/obj/item/reagent_containers/cup/soup_pot/pot = holder.my_atom
	if(!istype(pot))
		return FALSE
	if(!length(required_ingredients))
		return TRUE

	//copy of all ingredients to check out
	var/list/reqs_copy = required_ingredients.Copy()
	//number of ingredients who's requested amounts has been satisfied
	var/completed_ingredients = 0
	for(var/obj/item/ingredient as anything in pot.added_ingredients)
		var/ingredient_type = ingredient.type
		do
		{
			var/ingredient_count = reqs_copy[ingredient_type]

			//means we still have left over ingredients
			if(ingredient_count)
				//decode ingredient type i.e. stack or not and fulfill request
				if(ispath(ingredient_type, /obj/item/stack))
					var/obj/item/stack/stack_ingredient = ingredient
					ingredient_count -= stack_ingredient.amount
				else
					ingredient_count -= 1

				//assign final values
				if(ingredient_count <= 0)
					completed_ingredients += 1
					ingredient_count = 0
				reqs_copy[ingredient_type] = ingredient_count

				//work complete
				break

			//means we have to look for subtypes
			else if(isnull(ingredient_count))
				ingredient_type = type2parent(ingredient_type)

			//means we have no more remaining ingredients so bail, can happen if multiple ingredients of the same type/subtype are in the pot
			else
				break
		}
		while(ingredient_type != /obj/item)

	return completed_ingredients == reqs_copy.len

/datum/chemical_reaction/food/soup/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	if(!length(required_ingredients))
		return

	// If a food item is supposed to be made, remove relevant ingredients from the pot, then make the item
	if(!isnull(resulting_food_path))
		var/list/tracked_ingredients
		LAZYINITLIST(tracked_ingredients)
		var/ingredient_max_multiplier = INFINITY
		var/obj/item/reagent_containers/cup/soup_pot/pot = holder.my_atom

		// Tracked ingredients are indexed by type and point to a list containing the actual items
		for(var/obj/item/ingredient as anything in pot.added_ingredients)
			if(is_type_in_list(ingredient, required_ingredients))
				LAZYADD(tracked_ingredients[ingredient.type],ingredient)
		// Find the max number of ingredients that may be used for making the food item
		for(var/list/ingredient_type as anything in tracked_ingredients)
			ingredient_max_multiplier = min(ingredient_max_multiplier,LAZYLEN(tracked_ingredients[ingredient_type]))
		// Create the food items, removing the relavent ingredients at the same time
		for(var/i in 1 to (min(created_volume,ingredient_max_multiplier)))
			for(var/list/ingredient_type as anything in tracked_ingredients)
				var/ingredient = tracked_ingredients[ingredient_type][i]
				LAZYREMOVE(pot.added_ingredients,ingredient)
				qdel(ingredient)
			var/obj/item/created = new resulting_food_path(get_turf(pot))
			created.pixel_y += 8
		// Re-add required reagents that were not used in this step
		if(created_volume > ingredient_max_multiplier)
			for(var/reagent_path as anything in required_reagents)
				holder.add_reagent(reagent_path,(required_reagents[reagent_path])*(created_volume-ingredient_max_multiplier))


	// This only happens if we're being instant reacted so let's just skip to what we really want
	if(isnull(reaction))
		testing("Soup reaction of type [type] instant reacted, cleaning up.")
		clean_up(holder)
		return

	if(isnull(total_ingredient_max))
		total_ingredient_max = 0
		// We only need to calculate this once, effectively static per-type
		for(var/ingredient_type in required_ingredients)
			total_ingredient_max += required_ingredients[ingredient_type]

	var/obj/item/reagent_containers/cup/soup_pot/pot = holder.my_atom
	var/list/tracked_ingredients = list()
	for(var/obj/item/ingredient as anything in pot.added_ingredients)
		// Track all ingredients in data. Assoc list of weakref to ingredient to initial total volume.
		tracked_ingredients[WEAKREF(ingredient)] = ingredient.reagents?.total_volume || 1
		// Equalize temps. Otherwise when we add ingredient temps in, it'll lower reaction temp
		ingredient.reagents?.chem_temp = holder.chem_temp

	// Store a list of weakrefs to ingredients as
	reaction.data["ingredients"] = tracked_ingredients

	testing("Soup reaction started of type [type]! [length(pot.added_ingredients)] inside.")

/datum/chemical_reaction/food/soup/reaction_step(datum/reagents/holder, datum/equilibrium/reaction, delta_t, delta_ph, step_reaction_vol)
	if(!length(required_ingredients))
		return
	testing("Soup reaction step progressing with an increment volume of [step_reaction_vol] and delta_t of [delta_t].")
	var/obj/item/reagent_containers/cup/soup_pot/pot = holder.my_atom
	var/list/cached_ingredients = reaction.data["ingredients"]
	var/num_current_ingredients = length(pot.added_ingredients)
	var/num_cached_ingredients = length(cached_ingredients)

	// Clamp multiplier to ingredient number
	reaction.multiplier = min(reaction.multiplier, num_current_ingredients / total_ingredient_max)

	// An ingredient was removed during the mixing process.
	// Stop reacting immediately, we can't verify the reaction is correct still.
	// If it is still correct it will restart shortly.
	if(num_current_ingredients < num_cached_ingredients)
		testing("Soup reaction ended due to losing ingredients.")
		return END_REACTION

	// An ingredient was added mid mix.
	// Throw it in the ingredients list
	else if(num_current_ingredients > num_cached_ingredients)
		for(var/obj/item/new_ingredient as anything in pot.added_ingredients)
			var/datum/weakref/new_ref = WEAKREF(new_ingredient)
			if(cached_ingredients[new_ref])
				continue
			new_ingredient.reagents?.chem_temp = holder.chem_temp
			cached_ingredients[new_ref] = new_ingredient.reagents?.total_volume || 1

	var/turf/below_pot = get_turf(pot)
	for(var/datum/weakref/ingredient_ref as anything in cached_ingredients)
		var/obj/item/ingredient = ingredient_ref.resolve()

		// An ingredient has gone missing, stop the reaction
		if(QDELETED(ingredient) || ingredient.loc != holder.my_atom)
			testing("Soup reaction ended due to having an invalid ingredient present.")
			return END_REACTION

		// Transfer 20% of the initial reagent volume of the ingredient to the soup.
		if(!transfer_ingredient_reagents(ingredient, holder, max(cached_ingredients[ingredient_ref] * 0.2, 2)))
			continue //all reagents were transfered

		// Uh oh we reached the top of the pot, the soup's gonna boil over.
		if(holder.total_volume >= holder.maximum_volume * 0.95)
			below_pot.visible_message(span_warning("[pot] starts to boil over!"))
			// Create a spread of dirty foam
			var/datum/effect_system/fluid_spread/foam/dirty/soup_mess = new()
			soup_mess.reagent_scale = 0.1 // (Just a little)
			soup_mess.set_up(range = 1, holder = pot, location = below_pot, carry = holder, stop_reactions = TRUE)
			soup_mess.start()
			// Loses a bit from the foam
			for(var/datum/reagent/reagent as anything in holder.reagent_list)
				reagent.volume *= 0.5
			holder.update_total()

/datum/chemical_reaction/food/soup/reaction_finish(datum/reagents/holder, datum/equilibrium/reaction, react_vol)
	. = ..()
	var/obj/item/reagent_containers/cup/soup_pot/pot = holder.my_atom
	if(!istype(pot))
		CRASH("[pot ? "Non-pot atom" : "Null pot"]) made it to the end of the [type] reaction chain.")

	testing("Soup reaction finished with a total react volume of [react_vol] and [length(pot.added_ingredients)] ingredients. Cleaning up.")
	clean_up(holder, reaction, react_vol)

/**
 * Cleans up the ingredients and adds whatever leftover reagents to the mixture
 *
 * * holder: The soup pot
 * * reaction: The reaction being cleaned up, note this CAN be null if being instant reacted
 * * react_vol: How much soup was produced
 */
/datum/chemical_reaction/food/soup/proc/clean_up(datum/reagents/holder, datum/equilibrium/reaction, react_vol)
	var/obj/item/reagent_containers/cup/soup_pot/pot = holder.my_atom

	reaction?.data["ingredients"] = null

	// If soup is made, remove ingredients as their reagents were added to the soup
	if(react_vol)
		for(var/obj/item/ingredient as anything in pot.added_ingredients)
			// Let's not mess with  indestructible items.
			// Chef doesn't need more ways to delete things with cooking.
			if(ingredient.resistance_flags & INDESTRUCTIBLE)
				continue

			// Everything else will just get fried
			if(isnull(ingredient.reagents) && !is_type_in_list(ingredient, required_ingredients))
				ingredient.AddElement(/datum/element/fried_item, 30)
				continue

			// Things that had reagents or ingredients in the soup will get deleted
			LAZYREMOVE(pot.added_ingredients, ingredient)
			// Send everything left behind
			transfer_ingredient_reagents(ingredient, holder)
			// Delete, it's done
			qdel(ingredient)

	// Anything left in the ingredient list will get dumped out
	pot.dump_ingredients(get_turf(pot), y_offset = 8)
	// Blackbox log the chemical reaction used, to account for soup reaction that don't produce typical results
	BLACKBOX_LOG_FOOD_MADE(type)

/**
 * Transfers reagents from the passed reagent to the soup pot, as a "result"
 * Also handles deleting a portion of nutriment reagents present, pseudo-converting
 * it into soup reagent. Returns TRUE if any reagents were transfered FALSE if there is
 * nothing to transfer
 *
 * Arguments
 * * obj/item/ingredient - The ingredient to transfer reagents from
 * * datum/reagentsholder - The reagent holder of the soup pot the reaction is taking place in
 * * amount - The amount of reagents to transfer, if null will transfer all reagents
 */
/datum/chemical_reaction/food/soup/proc/transfer_ingredient_reagents(obj/item/ingredient, datum/reagents/holder, amount)
	if(ingredient_reagent_multiplier <= 0)
		return FALSE
	var/datum/reagents/ingredient_pool = ingredient.reagents
	// Some ingredients are purely flavor (no pun intended) and will have reagents
	if(isnull(ingredient_pool) || ingredient_pool.total_volume <= 0)
		return FALSE
	if(isnull(amount))
		amount = ingredient_pool.total_volume
		testing("Soup reaction has made it to the finishing step with ingredients that still contain reagents. [amount] reagents left in [ingredient].")

	// Some of the nutriment goes into "creating the soup reagent" itself, gets deleted.
	// Mainly done so that nutriment doesn't overpower the main course
	var/remove_amount = amount * percentage_of_nutriment_converted
	ingredient_pool.remove_reagent(/datum/reagent/consumable/nutriment, remove_amount)
	ingredient_pool.remove_reagent(/datum/reagent/consumable/nutriment/vitamin, remove_amount)
	// The other half of the nutriment, and the rest of the reagents, will get put directly into the pot
	ingredient_pool.trans_to(holder, amount, ingredient_reagent_multiplier, no_react = TRUE)
	return TRUE

/// Adds text to the requirements list of the recipe
/// Return a list of strings, each string will be a new line in the requirements list
/datum/chemical_reaction/food/soup/proc/describe_recipe_details()
	return

/// Adds text to the results list of the recipe
/// Return a list of strings, each string will be a new line in the results list
/datum/chemical_reaction/food/soup/proc/describe_result()
	return

#ifdef TESTING

/obj/item/soup_test_kit/Initialize(mapload)
	..()
	new /obj/item/food/meatball(loc)
	new /obj/item/food/grown/carrot(loc)
	new /obj/item/food/grown/potato(loc)
	new /obj/item/reagent_containers/cup/soup_pot(loc)
	return INITIALIZE_HINT_QDEL

#endif

/// This subtype is only for easy mapping / spawning in specific types of soup.
/// Do not use it anywhere else.
/obj/item/reagent_containers/cup/bowl/soup
	var/initial_reagent
	var/initial_portion = SOUP_SERVING_SIZE

/obj/item/reagent_containers/cup/bowl/soup/Initialize(mapload)
	. = ..()
	if(initial_reagent)
		reagents.add_reagent(initial_reagent, initial_portion)

/// This style runs dual purpose -
/// Primarily it's just a bowl style for water,
/// but secondarily it lets chefs know if their soup had too much water in it
/datum/glass_style/has_foodtype/soup/watery_soup
	required_drink_type = /datum/reagent/water
	name = "Water soup-一碗水"
	desc = "非常潮湿."
	icon_state = "wishsoup"

/datum/glass_style/has_foodtype/soup/watery_soup/set_name(obj/item/thing)
	if(length(thing.reagents.reagent_list) <= 2)
		return ..()

	thing.name = "一碗类似水的东西."

/datum/glass_style/has_foodtype/soup/watery_soup/set_desc(obj/item/thing)
	if(length(thing.reagents.reagent_list) <= 2)
		return ..()

	thing.desc = "看起来里面的东西都被冲淡了."

/// So this one's kind of a "failed" result, but also a "custom" result
/// Getting to this temperature and having no other soup reaction made means you're either messing something up
/// or you simply aren't following a recipe. So it'll just combine
/datum/chemical_reaction/food/soup/custom
	required_temp = SOUP_BURN_TEMP + 40 // Only done if it's been burning for a little bit
	optimal_temp = SOUP_BURN_TEMP + 50
	overheat_temp = SOUP_BURN_TEMP + 60
	thermic_constant = 0
	mix_message = span_warning("你闻到汤锅里有恶心的味道.")
	required_reagents = list(/datum/reagent/water = 30)
	results = list(/datum/reagent/water = 10)
	ingredient_reagent_multiplier = 1
	percentage_of_nutriment_converted = 0

	/// Custom recipes will not start mixing until at least this many solid ingredients are present
	var/num_ingredients_needed = 3

/datum/chemical_reaction/food/soup/custom/pre_reaction_other_checks(datum/reagents/holder)
	var/obj/item/reagent_containers/cup/soup_pot/pot = holder.my_atom
	if(!istype(pot))
		return FALSE // Not a pot
	if(holder.is_reacting)
		return FALSE // Another soup is being made
	if(length(pot.added_ingredients) <= num_ingredients_needed)
		return FALSE // Not a lot here to go off of
	return TRUE

/datum/chemical_reaction/food/soup/custom/describe_recipe_details()
	return list("由至少含有[num_ingredients_needed]种配料的汤烧制而成")

/datum/chemical_reaction/food/soup/custom/describe_result()
	return list("不管锅里有什么")

// Meatball Soup
/datum/reagent/consumable/nutriment/soup/meatball_soup
	name = "Meatball-肉丸汤"
	description = "你真有胆，小子!"
	data = list("meat" = 1)
	glass_price = FOOD_PRICE_NORMAL
	color = "#FFFDCF"

/datum/glass_style/has_foodtype/soup/meatball_soup
	required_drink_type = /datum/reagent/consumable/nutriment/soup/meatball_soup
	icon_state = "meatballsoup"
	drink_type = MEAT

/obj/item/reagent_containers/cup/bowl/soup/meatball_soup
	initial_reagent = /datum/reagent/consumable/nutriment/soup/meatball_soup

/datum/chemical_reaction/food/soup/meatballsoup
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/meatball = 1,
		/obj/item/food/grown/carrot = 1,
		/obj/item/food/grown/potato = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/meatball_soup = 30,
		/datum/reagent/water = 9,
	)

// Vegetable Soup
/datum/reagent/consumable/nutriment/soup/vegetable_soup
	name = "Vegetable-蔬菜汤"
	description = "清汤寡水的一餐."
	data = list("vegetables" = 1)
	glass_price = FOOD_PRICE_NORMAL
	color = "#FAA810"

/datum/glass_style/has_foodtype/soup/vegetable_soup
	required_drink_type = /datum/reagent/consumable/nutriment/soup/vegetable_soup
	icon_state = "vegetablesoup"
	drink_type = VEGETABLES

/datum/chemical_reaction/food/soup/vegetable_soup
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/grown/carrot = 1,
		/obj/item/food/grown/corn = 1,
		/obj/item/food/grown/eggplant = 1,
		/obj/item/food/grown/potato = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/vegetable_soup = 30,
		/datum/reagent/water = 9,
	)

// Nettle soup - gains some omnizine to offset the acid damage
/datum/reagent/consumable/nutriment/soup/nettle
	name = "Nettle-荨麻汤"
	description = "想想看，植物学家会用这个把你打死的."
	data = list("nettles" = 1)
	glass_price = FOOD_PRICE_NORMAL
	color = "#C1E212"

/datum/glass_style/has_foodtype/soup/nettle
	required_drink_type = /datum/reagent/consumable/nutriment/soup/nettle
	icon_state = "nettlesoup"
	drink_type = VEGETABLES

/obj/item/reagent_containers/cup/bowl/soup/nettle
	initial_reagent = /datum/reagent/consumable/nutriment/soup/nettle

/datum/chemical_reaction/food/soup/nettlesoup
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/grown/nettle = 1,
		/obj/item/food/grown/potato = 1,
		/obj/item/food/boiledegg = 1
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/nettle = 30,
		/datum/reagent/water = 9,
		/datum/reagent/medicine/omnizine = 6,
	)
	ingredient_reagent_multiplier = 0.2 // Too much acid
	percentage_of_nutriment_converted = 0

// Wing Fang Chu
/datum/reagent/consumable/nutriment/soup/wingfangchu
	name = "Wing Fang Chu"
	description = "A savory dish of alien wing wang in soy."
	data = list("soy" = 1)
	color = "#C1E212"

/datum/glass_style/has_foodtype/soup/wingfangchu
	required_drink_type = /datum/reagent/consumable/nutriment/soup/wingfangchu
	icon_state = "wingfangchu"
	drink_type = MEAT

/datum/chemical_reaction/food/soup/wingfangchu
	required_reagents = list(
		/datum/reagent/water = 50,
		/datum/reagent/consumable/soysauce = 5,
	)
	required_ingredients = list(
		/obj/item/food/meat/cutlet/xeno = 2,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/wingfangchu = 30,
		/datum/reagent/consumable/soysauce = 10,
	)

// Chili (Hot, not cold)
/datum/reagent/consumable/nutriment/soup/hotchili
	name = "Hot chili-辣椒汤"
	description = "五级德州辣椒!"
	data = list("hot peppers" = 1)
	glass_price = FOOD_PRICE_NORMAL
	color = "#E23D12"

/datum/glass_style/has_foodtype/soup/hotchili
	required_drink_type = /datum/reagent/consumable/nutriment/soup/hotchili
	icon_state = "hotchili"
	drink_type = VEGETABLES | MEAT

/obj/item/reagent_containers/cup/bowl/soup/hotchili
	initial_reagent = /datum/reagent/consumable/nutriment/soup/hotchili

/datum/chemical_reaction/food/soup/hotchili
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/meat/cutlet = 2,
		/obj/item/food/grown/chili = 1,
		/obj/item/food/grown/tomato = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/hotchili = 30,
		/datum/reagent/consumable/tomatojuice = 10,
		// Capsaicin comes from the chillis, meaning you can make tame chili.
		/*
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 4
		*/
	)
	ingredient_reagent_multiplier = 0.33 // Chilis have a TON of capsaicin naturally
	percentage_of_nutriment_converted = 0

// Chili (Cold)
/datum/reagent/consumable/nutriment/soup/coldchili
	name = "Cold chili-冷椒汤"
	description = "这冰沙根本就不是液体!"
	data = list("tomato" = 1, "mint" = 1)
	glass_price = FOOD_PRICE_NORMAL
	color = "#3861C2"

/datum/glass_style/has_foodtype/soup/coldchili
	required_drink_type = /datum/reagent/consumable/nutriment/soup/coldchili
	icon_state = "coldchili"
	drink_type = VEGETABLES | MEAT

/datum/chemical_reaction/food/soup/coldchili
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/meat/cutlet = 2,
		/obj/item/food/grown/icepepper = 1,
		/obj/item/food/grown/tomato = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/coldchili = 30,
		/datum/reagent/consumable/tomatojuice = 10,
		// Frost Oil comes from the chilis
	)
	ingredient_reagent_multiplier = 0.33 // Chilis have a TON of frost oil naturally
	percentage_of_nutriment_converted = 0

// Chili (Clownish)
/datum/reagent/consumable/nutriment/soup/clownchili
	name = "Chili (Clownish)-辣椒嘉年华"
	description = "美味的炖肉，辣椒，还有咸的，咸的小丑眼泪."
	data = list(
		"番茄" = 1,
		"辣椒" = 2,
		"小丑鞋" = 2,
		"好笑的事情" = 2,
		"别人的父母" = 2,
	)
	glass_price = FOOD_PRICE_EXOTIC
	color = "#FF0000"

/datum/glass_style/has_foodtype/soup/clownchili
	required_drink_type = /datum/reagent/consumable/nutriment/soup/clownchili
	icon_state = "clownchili"
	drink_type = VEGETABLES | MEAT

/datum/chemical_reaction/food/soup/clownchili
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/meat/cutlet = 2,
		/obj/item/food/grown/chili = 1,
		/obj/item/food/grown/tomato = 1,
		/obj/item/clothing/shoes/clown_shoes = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/clownchili = 30,
		/datum/reagent/consumable/tomatojuice = 8,
		/datum/reagent/consumable/laughter = 4,
		/datum/reagent/consumable/banana = 4,
	)
	percentage_of_nutriment_converted = 0.15

// Vegan Chili
/datum/reagent/consumable/nutriment/soup/chili_sin_carne
	name = "Vegan Chili-酸辣椒汤"
	description = "为那些不想吃肉的人准备的."
	data = list("苦" = 1, "酸" = 1)
	color = "#E23D12"

/datum/glass_style/has_foodtype/soup/chili_sin_carne
	required_drink_type = /datum/reagent/consumable/nutriment/soup/chili_sin_carne
	icon_state = "hotchili"
	drink_type = VEGETABLES

/datum/chemical_reaction/food/soup/chili_sin_carne
	required_reagents = list(
		/datum/reagent/water = 30,
		/datum/reagent/water/salt = 10,
	)
	required_ingredients = list(
		/obj/item/food/grown/chili = 1,
		/obj/item/food/grown/tomato = 1
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/chili_sin_carne = 30,
		/datum/reagent/consumable/tomatojuice = 10,
	)

// 番茄汤
/datum/reagent/consumable/nutriment/soup/tomato
	name = "Tomato soup-番茄汤"
	description = "喝这个感觉就像吸血鬼一样!吸番茄鬼..."
	data = list("tomato" = 1)
	color = "#FF0000"

/datum/glass_style/has_foodtype/soup/tomato
	required_drink_type = /datum/reagent/consumable/nutriment/soup/tomato
	name = "Tomato soup-番茄汤"
	icon_state = "tomatosoup"
	drink_type = VEGETABLES | FRUIT // ??

/datum/chemical_reaction/food/soup/tomatosoup
	required_reagents = list(
		/datum/reagent/water = 50,
		/datum/reagent/consumable/cream = 5
	)
	required_ingredients = list(
		/obj/item/food/grown/tomato = 2,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/tomato = 30,
		/datum/reagent/consumable/tomatojuice = 20,
		/*
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/tomatojuice = 10,
		/datum/reagent/consumable/nutriment/vitamin = 3
		*/
	)
	percentage_of_nutriment_converted = 0.1

// Tomato-eyeball soup
/datum/reagent/consumable/nutriment/soup/eyeball
	name = "Eyeball soup-眼球汤"
	description = "它回头看着你..."
	data = list("番茄" = 1, "蠕动" = 1)
	color = "#FF1C1C"

/datum/glass_style/has_foodtype/soup/eyeball
	required_drink_type = /datum/reagent/consumable/nutriment/soup/eyeball
	icon_state = "eyeballsoup"
	drink_type = VEGETABLES | FRUIT | MEAT | GORE // 番茄汤 + an eyeball

/datum/chemical_reaction/food/soup/eyeballsoup
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/grown/tomato = 2,
		/obj/item/organ/internal/eyes = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/eyeball = 20,
		// Logically this would be more but we wouldn't get the eyeball icon state if it was.
		/datum/reagent/consumable/nutriment/soup/tomato = 10,
		/datum/reagent/consumable/nutriment = 2,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/tomatojuice = 6,
		/datum/reagent/consumable/liquidgibs = 6,
	)
	percentage_of_nutriment_converted = 0.1

// Miso soup
/datum/reagent/consumable/nutriment/soup/miso
	name = "Miso-味噌汤"
	description = "世界上最好的汤!Yum ! !"
	data = list("miso" = 1)
	glass_price = FOOD_PRICE_NORMAL
	color = "#E2BD12"

/datum/glass_style/has_foodtype/soup/miso
	required_drink_type = /datum/reagent/consumable/nutriment/soup/miso
	icon_state = "misosoup"
	drink_type = VEGETABLES | BREAKFAST

/datum/chemical_reaction/food/soup/misosoup
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/soydope = 2,
		/obj/item/food/tofu = 2,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/miso = 30,
		/datum/reagent/water = 10,
	)
	percentage_of_nutriment_converted = 0 // Soy has very low nutrients.

// Blood soup
// Fake 番茄汤.
// Can also appear by pouring blood into a bowl!
/datum/glass_style/has_foodtype/soup/tomato/blood
	required_drink_type = /datum/reagent/blood
	name = "Blood soup-番茄汤"
	desc = "闻起来像铜."
	drink_type = GROSS

/datum/chemical_reaction/food/soup/bloodsoup
	required_reagents = list(
		/datum/reagent/water/salt = 10, // SKYRAT EDIT CHANGE - ORIGINAL: /datum/reagent/water = 10,
		/datum/reagent/blood = 10,
	)
	required_ingredients = list(
		/obj/item/food/grown/tomato/blood = 2,
	)
	results = list(
		// Blood tomatos will give us like 30u blood, so just add in the 10 from the recipe
		/datum/reagent/blood = 10,
		/datum/reagent/water = 8,
		/datum/reagent/consumable/nutriment/protein = 7,
	)
	percentage_of_nutriment_converted = 0.1

// Slime soup
// Made with a slime extract, toxic to non-slime-people.
// Can also be created by mixing water and slime jelly.
/datum/reagent/consumable/nutriment/soup/slime
	name = "Slime soup-史莱姆汤"
	description = "如果没有水，你可以用眼泪代替."
	data = list("slime" = 1)
	glass_price = FOOD_PRICE_NORMAL
	color = "#41C0C0"

/datum/glass_style/has_foodtype/soup/slime
	required_drink_type = /datum/reagent/consumable/nutriment/soup/slime
	icon_state = "slimesoup"
	drink_type = GROSS

/datum/chemical_reaction/food/soup/slimesoup
	required_reagents = list(
		/datum/reagent/water = 40,
	)
	required_ingredients = list(
		/obj/item/slime_extract = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/slime = 30,
		/datum/reagent/toxin/slimejelly = 20,
		// Comes out of thin air, as none of our ingredients contain nutrients naturally.
		/datum/reagent/consumable/nutriment = 7,
		/datum/reagent/consumable/nutriment/vitamin = 7,
		/datum/reagent/water = 6,
	)

/datum/chemical_reaction/food/soup/slimesoup/alt
	// Alt recipe that allows you to create a slime soup by just mixing slime jelly and water.
	// Pretty much just a normal chemical reaction.
	// This also creates nutrients out of thin air.

	required_other = FALSE
	required_reagents = list(
		/datum/reagent/water = 40,
		/datum/reagent/toxin/slimejelly = 20,
	)
	required_ingredients = null

// Clown Tear soup
/datum/reagent/consumable/nutriment/soup/clown_tears
	name = "Clown Tear-小丑之泪"
	description = "千千万万失去亲人的小丑的悲伤和忧郁."
	nutriment_factor = 5
	ph = 9.2
	data = list("烂笑话" = 1, "悲伤的鸣笛" = 1)
	color = "#EEF442"

/datum/glass_style/has_foodtype/soup/clown_tears
	required_drink_type = /datum/reagent/consumable/nutriment/soup/clown_tears
	name = "Clown Tear-小丑之泪"
	desc = "这不好笑，孩子."
	icon_state = "clownstears"
	drink_type = FRUIT | SUGAR

/datum/chemical_reaction/food/soup/clownstears
	required_reagents = list(
		/datum/reagent/lube = 30,
	)
	required_ingredients = list(
		/obj/item/food/grown/banana = 1,
		/obj/item/stack/sheet/mineral/bananium = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/clown_tears = 30,
		/datum/reagent/consumable/banana = 8,
		/datum/reagent/consumable/nutriment/vitamin = 12,
		/datum/reagent/lube = 5,
	)
	percentage_of_nutriment_converted = 0 // Bananas have a small amount of nutrition naturally

// Mystery soup
// Acts a little funny, because when it's mixed it gains a new random reagent as well
/datum/reagent/consumable/nutriment/soup/mystery
	name = "Mystery soup-谜之汤"
	description = "真正的谜团是，你吃不吃？"
	data = list("chaos" = 1)
	color = "#4C2A18"

/datum/glass_style/has_foodtype/soup/mystery
	required_drink_type = /datum/reagent/consumable/nutriment/soup/mystery
	icon_state = "mysterysoup"

/datum/chemical_reaction/food/soup/mysterysoup
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/badrecipe = 1,
		/obj/item/food/tofu = 1,
		/obj/item/food/boiledegg = 1,
		/obj/item/food/cheese/wedge = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/mystery = 30,
	)
	percentage_of_nutriment_converted = 0.33 // Full of garbage

	/// Number of units of bonus reagent added
	var/num_bonus = 10
	/// A list of reagent types we can randomly gain in the soup on creation
	var/list/extra_reagent_types = list(
		/datum/reagent/blood,
		/datum/reagent/carbon,
		/datum/reagent/consumable/banana,
		/datum/reagent/consumable/capsaicin,
		/datum/reagent/consumable/frostoil,
		/datum/reagent/medicine/oculine,
		/datum/reagent/medicine/omnizine,
		/datum/reagent/toxin,
		/datum/reagent/toxin/slimejelly,
	)

/datum/chemical_reaction/food/soup/mysterysoup/reaction_finish(datum/reagents/holder, datum/equilibrium/reaction, react_vol)
	. = ..()
	holder.add_reagent(pick(extra_reagent_types), num_bonus)

/datum/chemical_reaction/food/soup/mysterysoup/describe_result()
	var/list/extra_sublist = list()
	for(var/datum/reagent/extra_type as anything in extra_reagent_types)
		extra_sublist += "[initial(extra_type.name)]"

	return list("还将包含[num_bonus]个随机单位: [jointext(extra_sublist, ", ")]")

// Monkey Soup
/datum/reagent/consumable/nutriment/soup/monkey
	name = "Monkeys delight-猿猴喜乐汤"
	description = "一种美味的汤汁，里面有饺子和大块的猴子肉，煮得恰到好处，汤里有淡淡的香蕉味."
	data = list("the jungle" = 1, "banana" = 1)
	glass_price = FOOD_PRICE_NORMAL
	color = "#4C2A18"

/datum/glass_style/has_foodtype/soup/monkey
	required_drink_type = /datum/reagent/consumable/nutriment/soup/monkey
	icon_state = "monkeysdelight"
	drink_type = FRUIT

/obj/item/reagent_containers/cup/bowl/soup/monkey
	initial_reagent = /datum/reagent/consumable/nutriment/soup/monkey

/datum/chemical_reaction/food/soup/monkey
	required_reagents = list(
		/datum/reagent/water = 20,
		/datum/reagent/consumable/flour = 5,
		/datum/reagent/water/salt = 10,
		/datum/reagent/consumable/blackpepper = 5,
	)
	required_ingredients = list(
		/obj/item/food/monkeycube = 1, // This will make a monkey if a batch of 2 is made
		/obj/item/food/grown/banana = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/monkey = 30,
		/datum/reagent/consumable/nutriment = 12,
		/datum/reagent/consumable/salt = 4,
		/datum/reagent/consumable/blackpepper = 4,
	)

/datum/chemical_reaction/food/soup/monkey/describe_result()
	return list("可能包含一只猴子.")

// Cream of mushroom soup
/datum/reagent/consumable/nutriment/soup/mushroom
	name = "mushroom soup-蘑菇奶油汤"
	description = "美味而丰盛的蘑菇汤."
	data = list("mushroom" = 1)
	color = "#CEB1B0"

/datum/glass_style/has_foodtype/soup/mushroom
	required_drink_type = /datum/reagent/consumable/nutriment/soup/mushroom
	icon_state = "mushroomsoup"
	drink_type = VEGETABLES | DAIRY

/datum/chemical_reaction/food/soup/mushroomsoup
	required_reagents = list(
		/datum/reagent/water = 40,
		/datum/reagent/consumable/milk = 10,
	)
	required_ingredients = list(
		/obj/item/food/grown/mushroom/chanterelle = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/mushroom = 30,
		/datum/reagent/consumable/nutriment = 9,
		/datum/reagent/consumable/nutriment/vitamin = 8,
		/datum/reagent/consumable/milk = 2,
	)

// Beet soup (Borscht)
// This has a gimmick where it randomizes its name based on common mispellings on Borsch
/datum/reagent/consumable/nutriment/soup/white_beet
	name = "Borscht-罗宋汤"
	description = "等等，你能再说一遍吗..?"
	data = list("beet" = 1)
	color = "#E00000"

/datum/glass_style/has_foodtype/soup/white_beet
	required_drink_type = /datum/reagent/consumable/nutriment/soup/white_beet
	icon_state = "beetsoup"
	drink_type = VEGETABLES | DAIRY

/datum/glass_style/has_foodtype/soup/white_beet/set_name(obj/item/thing)
	var/how_do_you_spell_it = pick("罗宋汤", "罗宋汤", "罗宋汤", "罗宋汤", "罗宋汤", "罗宋汤")
	thing.name = how_do_you_spell_it

	var/datum/reagent/soup = locate(required_drink_type) in thing.reagents
	if(!soup)
		// Shouldn't happen but things are weird
		return

	// Update tastes with the new name
	LAZYSET(soup.data, how_do_you_spell_it, 1)
	// Not perfect. Doesn't clear when the bowl type is unset. But it'll do well enough

/obj/item/reagent_containers/cup/bowl/soup/white_beet
	initial_reagent = /datum/reagent/consumable/nutriment/soup/white_beet

/datum/chemical_reaction/food/soup/beetsoup
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/grown/whitebeet = 1,
		/obj/item/food/grown/cabbage = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/white_beet = 30,
		/datum/reagent/water = 10,
	)
	percentage_of_nutriment_converted = 0.1

/datum/chemical_reaction/food/soup/beetsoup/describe_result()
	return list("Changes name randomly to a common misspelling of \"Borscht\".")

// Stew
/datum/reagent/consumable/nutriment/soup/stew
	name = "Stew-炖菜"
	description = "一道热乎乎的炖菜."
	data = list("tomato" = 1, "carrot" = 1)
	glass_price = FOOD_PRICE_NORMAL
	color = "#EB7C82"

/datum/glass_style/has_foodtype/soup/stew
	required_drink_type = /datum/reagent/consumable/nutriment/soup/stew
	icon_state = "stew"
	drink_type = VEGETABLES | FRUIT | MEAT

/obj/item/reagent_containers/cup/bowl/soup/stew
	initial_reagent = /datum/reagent/consumable/nutriment/soup/stew

/datum/chemical_reaction/food/soup/stew
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/grown/tomato = 1,
		/obj/item/food/meat/cutlet = 3,
		/obj/item/food/grown/potato = 1,
		/obj/item/food/grown/carrot = 1,
		/obj/item/food/grown/eggplant = 1,
		/obj/item/food/grown/mushroom = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/stew = 30,
		/datum/reagent/consumable/tomatojuice = 10,
		// Gains a ton of nutriments from the variety of ingredients.
	)

// Sweet potato soup
/datum/reagent/consumable/nutriment/soup/sweetpotato
	name = "Sweet potato soup-甘薯汤"
	description = "美味的甘薯汤."
	data = list("sweet potato" = 1)
	color = "#903E22"

/datum/glass_style/has_foodtype/soup/sweetpotato
	required_drink_type = /datum/reagent/consumable/nutriment/soup/sweetpotato
	icon_state = "sweetpotatosoup"
	drink_type = VEGETABLES | SUGAR

/obj/item/reagent_containers/cup/bowl/soup/sweetpotato
	initial_reagent = /datum/reagent/consumable/nutriment/soup/sweetpotato

/datum/chemical_reaction/food/soup/sweetpotatosoup
	required_reagents = list(
		/datum/reagent/water = 40,
		/datum/reagent/consumable/milk = 10, // Coconut milk, but, close enough
	)
	required_ingredients = list(
		/obj/item/food/grown/potato/sweet = 2,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/sweetpotato = 30,
		/datum/reagent/water = 10,
	)

// Red beet soup
/datum/reagent/consumable/nutriment/soup/red_beet
	name = "Red beet soup-红甜菜汤"
	description = "相当美味."
	data = list("beet" = 1)
	color = "#851127"

/datum/glass_style/has_foodtype/soup/red_beet
	required_drink_type = /datum/reagent/consumable/nutriment/soup/red_beet
	icon_state = "redbeetsoup"
	drink_type = VEGETABLES

/datum/chemical_reaction/food/soup/redbeetsoup
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/grown/redbeet = 1,
		/obj/item/food/grown/cabbage = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/red_beet = 30,
		/datum/reagent/water = 10,
	)
	percentage_of_nutriment_converted = 0.1

// French Onion soup
/datum/reagent/consumable/nutriment/soup/french_onion
	name = "French Onion soup-法式洋葱汤"
	description = "好得足以让一个成年哑剧演员哭出来."
	data = list("caramelized onions" = 1)
	color = "#E1C47F"

/datum/glass_style/has_foodtype/soup/french_onion
	required_drink_type = /datum/reagent/consumable/nutriment/soup/french_onion
	icon_state = "onionsoup"
	drink_type = VEGETABLES | DAIRY

/datum/chemical_reaction/food/soup/onionsoup
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/grown/onion = 1,
		/obj/item/food/cheese/wedge = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/french_onion = 30,
		/datum/reagent/consumable/nutriment/protein = 8, // No idea where this comes from
		/datum/reagent/consumable/tomatojuice = 8, // No idea where this comes from
	)
	ingredient_reagent_multiplier = 0.5 // Onions are very reagent heavy
	percentage_of_nutriment_converted = 0.1

// Bisque / Crab soup
/datum/reagent/consumable/nutriment/soup/bisque
	name = "Bisque-法式浓汤"
	description = "来自法国的经典主菜."
	data = list("奶油质地" = 1, "蟹肉" = 4)
	glass_price = FOOD_PRICE_EXOTIC
	color = "#C8682F"

/datum/glass_style/has_foodtype/soup/bisque
	required_drink_type = /datum/reagent/consumable/nutriment/soup/bisque
	icon_state = "bisque"
	drink_type = MEAT

/datum/chemical_reaction/food/soup/bisque
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/meat/crab = 1,
		/obj/item/food/boiledrice = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/bisque = 30,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/water = 5,
	)

// Bungo Tree Curry
/datum/reagent/consumable/nutriment/soup/bungo
	name = "Bungo咖喱"
	description = "一种辛辣的蔬菜咖喱，由不起眼的邦戈水果制成，充满异国情调!"
	data = list("bungo" = 2, "辣咖喱" = 4, "热带甜蜜" = 1)
	glass_price = FOOD_PRICE_NORMAL
	color = "#E6BC32"

/datum/glass_style/has_foodtype/soup/bungo
	required_drink_type = /datum/reagent/consumable/nutriment/soup/bungo
	icon_state = "bungocurry"
	drink_type = VEGETABLES | FRUIT | DAIRY

/datum/chemical_reaction/food/soup/bungocurry
	required_reagents = list(
		/datum/reagent/water = 40,
		/datum/reagent/consumable/cream = 10,
	)
	required_ingredients = list(
		/obj/item/food/grown/chili = 1,
		/obj/item/food/grown/bungofruit = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/bungo = 30,
		/datum/reagent/consumable/bungojuice = 15,
	)
	percentage_of_nutriment_converted = 0.1

// Electron Soup.
// Special soup for Ethereals to consume to gain nutrition (energy) from.
/datum/reagent/consumable/nutriment/soup/electrons
	name = "Electron Soup-电子汤"
	description = "源自虚无缥缈的美食奇珍，它以在适当准备的汤上形成的微型天气系统而闻名。"
	data = list("mushroom" = 1, "electrons" = 4)
	glass_price = FOOD_PRICE_EXOTIC
	color = "#E60040"

/datum/glass_style/has_foodtype/soup/electrons
	required_drink_type = /datum/reagent/consumable/nutriment/soup/electrons
	icon_state = "electronsoup"
	drink_type = VEGETABLES | TOXIC

/datum/chemical_reaction/food/soup/electron
	required_reagents = list(
		/datum/reagent/water = 40,
		/datum/reagent/water/salt = 10,
	)
	required_ingredients = list(
		/obj/item/food/grown/mushroom/jupitercup = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/electrons = 30,
		// Jupiter cups obviously contain a fair amount of LE naturally,
		// but to make it "worthwhile" for Ethereals to eat we add a bit extra
		/datum/reagent/consumable/liquidelectricity/enriched = 10,
	)
	percentage_of_nutriment_converted = 0.10

// Pea Soup
/datum/reagent/consumable/nutriment/soup/pea
	name = "Pea Soup-豌豆汤"
	description = "一碗不起眼的豌豆汤."
	data = list("奶油豌豆" = 2, "parsnip" = 1)
	color = "#9D7B20"

/datum/glass_style/has_foodtype/soup/pea
	required_drink_type = /datum/reagent/consumable/nutriment/soup/pea
	icon_state = "peasoup"
	drink_type = VEGETABLES

/datum/chemical_reaction/food/soup/peasoup
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/grown/peas = 2,
		/obj/item/food/grown/parsnip = 1,
		/obj/item/food/grown/carrot = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/pea = 30,
		/datum/reagent/water = 10,
	)

// Indian curry
/datum/reagent/consumable/nutriment/soup/indian_curry
	name = "Indian curry-印度咖喱"
	description = "一种来自古老次大陆的温和的印度咖喱，太空英国人很喜欢，因为这让他们想起了大英帝国。"
	data = list("chicken" = 2, "creamy curry" = 4, "earthy heat" = 1)
	glass_price = FOOD_PRICE_NORMAL
	color = "#BB2D1A"

/datum/glass_style/has_foodtype/soup/indian_curry
	required_drink_type = /datum/reagent/consumable/nutriment/soup/indian_curry
	icon_state = "indian_curry"
	drink_type = VEGETABLES | MEAT | DAIRY

/datum/chemical_reaction/food/soup/indian_curry
	required_reagents = list(
		/datum/reagent/water = 50,
		/datum/reagent/consumable/cream = 5,
	)
	required_ingredients = list(
		/obj/item/food/meat/slab/chicken = 1,
		/obj/item/food/grown/onion = 2,
		/obj/item/food/grown/chili = 1,
		/obj/item/food/grown/garlic = 1,
		/obj/item/food/butterslice = 1,
		/obj/item/food/boiledrice = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/indian_curry = 30,
		// Gains a ton of other reagents from ingredients.
	)

// Oatmeal (Soup like)
/datum/reagent/consumable/nutriment/soup/oatmeal
	name = "oatmeal-燕麦粥"
	description = "一碗美味的燕麦粥."
	data = list("麦片" = 1, "牛奶" = 1)
	color = "#FFD7B4"

/datum/glass_style/has_foodtype/soup/oatmeal
	required_drink_type = /datum/reagent/consumable/nutriment/soup/oatmeal
	icon_state = "oatmeal"
	drink_type = DAIRY | GRAIN | BREAKFAST

/datum/chemical_reaction/food/soup/oatmeal
	required_reagents = list(
		/datum/reagent/consumable/milk = 20,
	)
	required_ingredients = list(
		/obj/item/food/grown/oat = 2,
	)
	results =  list(
		/datum/reagent/consumable/nutriment/soup/oatmeal = 20,
		/datum/reagent/consumable/milk = 12,
		/datum/reagent/consumable/nutriment/vitamin = 8,
	)
	percentage_of_nutriment_converted = 0 // Oats have barely any nutrients

// Zurek, a Polish soup
/datum/reagent/consumable/nutriment/soup/zurek
	name = "Zurek-酸汤"
	description = "一种由蔬菜、肉和鸡蛋组成的传统波兰汤，和面包搭配很好."
	data = list("奶油蔬菜" = 2, "香肠" = 1)
	color = "#F1CB6D"

/datum/glass_style/has_foodtype/soup/zurek
	required_drink_type = /datum/reagent/consumable/nutriment/soup/zurek
	icon_state = "zurek"
	drink_type = VEGETABLES | MEAT | GRAIN | BREAKFAST

/datum/chemical_reaction/food/soup/zurek
	required_reagents = list(
		/datum/reagent/water = 40,
		/datum/reagent/consumable/flour = 10,
	)
	required_ingredients = list(
		/obj/item/food/boiledegg = 1,
		/obj/item/food/meat/cutlet = 1,
		/obj/item/food/grown/carrot = 1,
		/obj/item/food/grown/onion = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/zurek = 30,
	)
	ingredient_reagent_multiplier = 0.5
	percentage_of_nutriment_converted = 0.1

// Cullen Skink, a Scottish soup with a funny name
/datum/reagent/consumable/nutriment/soup/cullen_skink
	name = "Cullen Skink-苏格兰汤"
	description = "由熏鱼、土豆和洋葱制成的浓苏格兰汤."
	data = list("奶油浓汤" = 1, "鱼肉" = 1, "蔬菜" = 1)
	color = "#F6F664"

/datum/glass_style/has_foodtype/soup/cullen_skink
	required_drink_type = /datum/reagent/consumable/nutriment/soup/cullen_skink
	icon_state = "cullen_skink"
	drink_type = VEGETABLES | SEAFOOD | DAIRY

/datum/chemical_reaction/food/soup/cullen_skink
	required_reagents = list(
		/datum/reagent/water = 40,
		/datum/reagent/consumable/milk = 10,
		/datum/reagent/consumable/blackpepper = 4,
	)
	required_ingredients = list(
		/obj/item/food/fishmeat = 1,
		/obj/item/food/grown/onion = 1,
		/obj/item/food/grown/potato = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/cullen_skink = 30,
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/water = 6,
	)
	ingredient_reagent_multiplier = 0.5
	percentage_of_nutriment_converted = 0

// Chicken Noodle Soup
/datum/reagent/consumable/nutriment/soup/chicken_noodle_soup
	name = "Chicken Noodle-鸡肉面条汤"
	description = "一碗丰盛的鸡汤面，当你困在家里生病的时候再合适不过了."
	data = list("肉汤" = 1, "鸡肉" = 1, "面条" = 1, "胡萝卜" = 1)
	color = "#DDB23E"

/datum/glass_style/has_foodtype/soup/chicken_noodle_soup
	required_drink_type = /datum/reagent/consumable/nutriment/soup/chicken_noodle_soup
	icon_state = "chicken_noodle_soup"
	drink_type = VEGETABLES | MEAT | GRAIN

/datum/chemical_reaction/food/soup/chicken_noodle_soup
	required_reagents = list(/datum/reagent/water = 30)
	required_ingredients = list(
		/obj/item/food/grown/carrot = 1,
		/obj/item/food/meat/slab/chicken = 1,
		/obj/item/food/spaghetti/boiledspaghetti = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/chicken_noodle_soup = 30,
		/datum/reagent/consumable/nutriment = 2,
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/nutriment/protein = 5,
	)

// Corn Cowder
/datum/reagent/consumable/nutriment/soup/corn_chowder
	name = "Corn Chowder-玉米浓汤"
	description = "一碗奶油玉米浓汤，配上培根和什锦蔬菜，一碗永远不够."
	data = list("奶油浓汤" = 1, "培根" = 1, "什锦蔬菜" = 1)
	color = "#FFF200"

/datum/glass_style/has_foodtype/soup/corn_chowder
	required_drink_type = /datum/reagent/consumable/nutriment/soup/corn_chowder
	icon_state = "corn_chowder"
	drink_type = VEGETABLES | MEAT

/datum/chemical_reaction/food/soup/corn_chowder
	required_reagents = list(
		/datum/reagent/water = 40,
		/datum/reagent/consumable/cream = 5,
	)
	required_ingredients = list(
		/obj/item/food/grown/corn = 1,
		/obj/item/food/grown/potato = 1,
		/obj/item/food/grown/carrot = 1,
		/obj/item/food/meat/bacon = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/corn_chowder = 30,
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/consumable/nutriment = 2,
	)

// Lizard stuff

// Atrakor Dumpling soup
/datum/reagent/consumable/nutriment/soup/atrakor_dumplings
	name = "\improper Atrakor dumpling soup-蜥蜴饺子汤"
	description = "一碗丰富的肉馅饺子汤，传统上在缇兹兰的阿特拉克五月节期间供应，饺子的形状像夜空领主本人."
	data = list("大骨汤" = 1, "洋葱" = 1, "土豆" = 1)
	color = "#7B453B"

/datum/glass_style/has_foodtype/soup/atrakor_dumplings
	required_drink_type = /datum/reagent/consumable/nutriment/soup/atrakor_dumplings
	icon = 'icons/obj/food/lizard.dmi'
	icon_state = "atrakor_dumplings"
	drink_type = MEAT | VEGETABLES | NUTS

/datum/chemical_reaction/food/soup/atrakor_dumplings
	required_reagents = list(
		/datum/reagent/water = 40,
		/datum/reagent/consumable/soysauce = 10,
	)
	required_ingredients = list(
		/obj/item/food/meat/rawcutlet = 2,
		/obj/item/food/grown/onion = 1,
		/obj/item/food/lizard_dumplings = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/atrakor_dumplings = 30,
		/datum/reagent/water = 10,
	)
	ingredient_reagent_multiplier = 0.5
	percentage_of_nutriment_converted = 0.2

// Meatball Soup, but lizard-like
/datum/reagent/consumable/nutriment/soup/meatball_noodles
	name = "Meatball Noodle-肉丸面条汤"
	description = "丰盛的面汤，由肉丸和尼扎亚在丰富的肉汤中制成，通常在上面放一把切碎的坚果。"
	data = list("大骨汤" = 1, "肉丸" = 1, "团子" = 1, "坚果" = 1)
	color = "#915145"

/datum/glass_style/has_foodtype/soup/meatball_noodles
	required_drink_type = /datum/reagent/consumable/nutriment/soup/meatball_noodles
	icon = 'icons/obj/food/lizard.dmi'
	icon_state = "meatball_noodles"
	drink_type = MEAT | VEGETABLES | NUTS

/datum/chemical_reaction/food/soup/meatball_noodles
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/meat/rawcutlet = 2,
		/obj/item/food/grown/onion = 1,
		/obj/item/food/spaghetti/nizaya = 1,
		/obj/item/food/meatball = 2,
		/obj/item/food/grown/peanut = 1
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/meatball_noodles = 30,
		/datum/reagent/water = 10,
	)
	ingredient_reagent_multiplier = 0.5
	percentage_of_nutriment_converted = 0.1

// Black Broth
/datum/reagent/consumable/nutriment/soup/black_broth
	name = "\improper Tiziran black-缇兹兰黑肉汤"
	description = "一碗香肠，洋葱，血和醋，冰镇上菜，就像听起来一样."
	data = list("醋" = 1, "铁" = 1)
	color = "#340010"

/datum/glass_style/has_foodtype/soup/black_broth
	required_drink_type = /datum/reagent/consumable/nutriment/soup/black_broth
	icon = 'icons/obj/food/lizard.dmi'
	icon_state = "black_broth"
	drink_type = MEAT | VEGETABLES | GORE

/datum/chemical_reaction/food/soup/black_broth
	required_reagents = list(
		/datum/reagent/water = 40,
		/datum/reagent/consumable/vinegar = 8,
		/datum/reagent/blood = 8,
		/datum/reagent/consumable/ice = 4,
	)
	required_ingredients = list(
		/obj/item/food/tiziran_sausage = 1,
		/obj/item/food/grown/onion = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/black_broth = 30,
		/datum/reagent/blood = 8,
		/datum/reagent/consumable/liquidgibs = 7,
		/datum/reagent/consumable/vinegar = 5,
	)
	ingredient_reagent_multiplier = 0.5
	percentage_of_nutriment_converted = 0.1

// Jellyfish Stew
/datum/reagent/consumable/nutriment/soup/jellyfish
	name = "Jellyfish Stew-水母炖"
	description = "一碗黏糊糊的水母炖菜，你摇动它，它就会摇晃."
	data = list("黏糊糊" = 1)
	color = "#3FAA7E"

/datum/glass_style/has_foodtype/soup/jellyfish
	required_drink_type = /datum/reagent/consumable/nutriment/soup/jellyfish
	icon = 'icons/obj/food/lizard.dmi'
	icon_state = "jellyfish_stew"
	drink_type = MEAT | VEGETABLES | GORE

/datum/chemical_reaction/food/soup/jellyfish_stew
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/canned/jellyfish = 1,
		/obj/item/food/grown/soybeans = 1,
		/obj/item/food/grown/redbeet = 1,
		/obj/item/food/grown/potato = 1
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/jellyfish = 30,
		/datum/reagent/water = 5,
	)

// Rootbread Soup
/datum/reagent/consumable/nutriment/soup/rootbread
	name = "Rootbread Soup-粗面包汤"
	description = "一大碗用粗面包做成的辛辣的、可口的汤，味道很浓，味道很好."
	data = list("面包" = 1, "蛋" = 1, "辣椒" = 1, "大蒜" = 1)
	color = "#AC3232"

/datum/glass_style/has_foodtype/soup/rootbread
	required_drink_type = /datum/reagent/consumable/nutriment/soup/rootbread
	icon = 'icons/obj/food/lizard.dmi'
	icon_state = "rootbread_soup"
	drink_type = MEAT | VEGETABLES

/datum/chemical_reaction/food/soup/rootbread_soup
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/breadslice/root = 2,
		/obj/item/food/grown/garlic = 1,
		/obj/item/food/grown/chili = 1,
		/obj/item/food/egg = 1
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/rootbread = 30,
		/datum/reagent/consumable/nutriment/protein = 8,
	)
	percentage_of_nutriment_converted = 0.2

// Moth stuff

// Cotton Soup
/datum/reagent/consumable/nutriment/soup/cottonball
	name = "Flöfrölenmæsch" //flöf = cotton, rölen = ball, mæsch = soup
	description = "用原棉在美味的蔬菜汤中熬制的汤，只有飞蛾和罪犯才享受."
	data = list("棉花" = 1, "蔬菜汤" = 1)
	color = "#E6A625"

/datum/glass_style/has_foodtype/soup/cottonball
	required_drink_type = /datum/reagent/consumable/nutriment/soup/cottonball
	name = "flöfrölenmæsch"
	icon = 'icons/obj/food/moth.dmi'
	icon_state = "moth_cotton_soup"
	drink_type = VEGETABLES | CLOTH

/datum/chemical_reaction/food/soup/cottonball
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/grown/cotton = 1, // Why are you buying clothes at the soup store?!
		/obj/item/food/grown/onion = 1,
		/obj/item/food/grown/carrot = 1,
		/obj/item/food/grown/eggplant = 1,
		/obj/item/food/oven_baked_corn = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/cottonball = 30,
	)
	ingredient_reagent_multiplier = 0.5
	percentage_of_nutriment_converted = 0.1 // Cotton has no nutrition

// Cheese Soup
/datum/reagent/consumable/nutriment/soup/cheese
	name = "Ælosterrmæsch" //ælo = cheese, sterr = melt, mæsch = soup
	description = "用自制的奶酪和甘薯做成的简单而充实的汤，凝乳提供质地，而乳清提供体积——它们都提供美味!"
	data = list("cheese" = 1, "cream" = 1, "sweet potato" = 1)
	color = "#F3CE3A"

/datum/glass_style/has_foodtype/soup/cheese
	required_drink_type = /datum/reagent/consumable/nutriment/soup/cheese
	name = "ælosterrmæsch"
	icon = 'icons/obj/food/moth.dmi'
	icon_state = "moth_cheese_soup"
	drink_type = DAIRY | GRAIN

/datum/chemical_reaction/food/soup/cheese
	required_reagents = list(
		/datum/reagent/water = 30,
		/datum/reagent/consumable/milk = 10,
	)
	required_ingredients = list(
		/obj/item/food/doughslice = 2,
		/obj/item/food/cheese/wedge = 2,
		/obj/item/food/butterslice = 1,
		/obj/item/food/grown/potato/sweet = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/cheese = 30,
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/milk = 2,
	)

// Seed Soup
/datum/reagent/consumable/nutriment/soup/seed
	name = "Misklmæsch" //miskl = seed, mæsch = soup
	description = "一种以种子为原料的汤，将种子发芽后煮沸制成产生一种特别苦的汤，通常通过添加醋来平衡."
	data = list("苦味" = 1, "酸味" = 1)
	color = "#4F6F31"

/datum/glass_style/has_foodtype/soup/seed
	required_drink_type = /datum/reagent/consumable/nutriment/soup/seed
	name = "misklmæsch"
	icon = 'icons/obj/food/moth.dmi'
	icon_state = "moth_seed_soup"
	drink_type = VEGETABLES

/datum/chemical_reaction/food/soup/seed
	required_reagents = list(
		/datum/reagent/water = 40,
		/datum/reagent/consumable/vinegar = 10,
	)
	required_ingredients = list(
		/obj/item/seeds/sunflower = 1,
		/obj/item/seeds/poppy/lily = 1,
		/obj/item/seeds/ambrosia = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/seed = 30,
		/datum/reagent/consumable/nutriment/vitamin = 13,
		/datum/reagent/consumable/nutriment = 12,
		/datum/reagent/consumable/vinegar = 8,
		/datum/reagent/water = 7,
	)

// Bean Soup
/datum/reagent/consumable/nutriment/soup/beans
	name = "Prickeldröndolhaskl" //prickeld = spicy, röndol = bean, haskl = stew
	description = "一种辣味豆炖菜，加了很多蔬菜，通常在舰队上与米饭或面包一起吃."
	data = list("豆子" = 1, "卷心菜" = 1, "辣酱" = 1)
	color = "#DF7126"

/datum/glass_style/has_foodtype/soup/beans
	required_drink_type = /datum/reagent/consumable/nutriment/soup/beans
	name = "prickeldröndolhaskl"
	icon = 'icons/obj/food/moth.dmi'
	icon_state = "moth_bean_stew"
	drink_type = VEGETABLES

/datum/chemical_reaction/food/soup/beans
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/canned/beans = 1,
		/obj/item/food/grown/cabbage = 1,
		/obj/item/food/grown/tomato = 1,
		/obj/item/food/grown/onion = 1,
		/obj/item/food/grown/chili = 1,
		/obj/item/food/oven_baked_corn = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/beans = 30,
		/datum/reagent/consumable/nutriment/protein = 10,
		/datum/reagent/water = 10,
	)
	ingredient_reagent_multiplier = 0.5
	percentage_of_nutriment_converted = 0.1

// Oat Soup, but not oatmeal
/datum/reagent/consumable/nutriment/soup/moth_oats
	name = "Häfmisklhaskl" //häfmiskl = oat (häf from German hafer meaning oat, miskl meaning seed), haskl = stew
	description = "一种辣味豆炖菜，加了很多蔬菜，通常在舰队上与米饭或面包一起吃."
	data = list("燕麦" = 1, "甘薯" = 1, "胡萝卜" = 1, "欧防风" = 1, "南瓜" = 1)
	color = "#CAA94E"

/datum/glass_style/has_foodtype/soup/moth_oats
	required_drink_type = /datum/reagent/consumable/nutriment/soup/moth_oats
	name = "häfmisklhaskl"
	icon = 'icons/obj/food/moth.dmi'
	icon_state = "moth_oat_stew"
	drink_type = VEGETABLES | GRAIN

/datum/chemical_reaction/food/soup/moth_oats
	required_reagents = list(/datum/reagent/water = 50)
	required_ingredients = list(
		/obj/item/food/grown/oat = 1,
		/obj/item/food/grown/potato/sweet = 1,
		/obj/item/food/grown/parsnip = 1,
		/obj/item/food/grown/carrot = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/moth_oats = 30,
	)
	percentage_of_nutriment_converted = 0.1

// Fire Soup
/datum/reagent/consumable/nutriment/soup/fire_soup
	name = "Tömpröttkrakklmæsch" //tömprött = heart (tömp = thump, rött = muscle), krakkl = fire, mæsch = soup
	description = "Tömpröttkrakklmæsch，或者是烧心汤，是一种起源于丛林飞蛾的冷汤，它的名字来源于两个东西——它的玫瑰色和它灼热的辣椒味."
	data = list("爱" = 1, "恨" = 1)
	color = "#FBA8F3"

/datum/glass_style/has_foodtype/soup/fire_soup
	required_drink_type = /datum/reagent/consumable/nutriment/soup/fire_soup
	name = "tömpröttkrakklmæsch"
	icon = 'icons/obj/food/moth.dmi'
	icon_state = "moth_fire_soup"
	drink_type = VEGETABLES | DAIRY

/datum/chemical_reaction/food/soup/fire_soup
	required_reagents = list(
		/datum/reagent/water = 30,
		/datum/reagent/consumable/yoghurt = 15,
		/datum/reagent/consumable/vinegar = 5,
	)
	required_ingredients = list(
		/obj/item/food/grown/ghost_chili = 1,
		/obj/item/food/tofu = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/fire_soup = 30,
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/vinegar = 2,
	)
	ingredient_reagent_multiplier = 0.33 // Chilis have a TON of capsaicin naturally
	percentage_of_nutriment_converted = 0

// Rice Porridge (Soup-ish)
/datum/reagent/consumable/nutriment/soup/rice_porridge
	name = "Rice Porridge-米粥"
	description = "一盘米粥，大部分都是无味的，但它确实填补了一个位置，对中国人来说，这是粥，飞蛾叫它höllflöfmisklsløsk." //höllflöfmiskl = rice (höllflöf = cloud, miskl = seed), sløsk = porridge
	data = list("什么味都没有" = 1)
	color = "#EDE3E3"

/datum/glass_style/has_foodtype/soup/rice_porridge
	required_drink_type = /datum/reagent/consumable/nutriment/soup/rice_porridge
	name = "Rice Porridge-米粥"
	icon = 'icons/obj/food/moth.dmi'
	icon_state = "rice_porridge"
	drink_type = GRAIN

/datum/chemical_reaction/food/soup/rice_porridge
	required_reagents = list(
		/datum/reagent/water = 20,
		/datum/reagent/water/salt = 10,
	)
	required_ingredients = list(
		/obj/item/food/boiledrice = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/rice_porridge = 20,
		/datum/reagent/consumable/salt = 5,
	)
	percentage_of_nutriment_converted = 0.15

// Cornmeal Porridge (Soup-ish)
// Also, pretty much just a normal chemical reaction. Used in other stuff
/datum/reagent/consumable/nutriment/soup/cornmeal_porridge
	name = "Cornmeal Porridge-玉米粥"
	description = "一盘玉米粥，它比大多数粥都更有味道，也是其他口味的好底料."
	data = list("玉米粥" = 1)
	color = "#ECDA7B"

/datum/glass_style/has_foodtype/soup/cornmeal_porridge
	required_drink_type = /datum/reagent/consumable/nutriment/soup/cornmeal_porridge
	name = "Cornmeal porridge-玉米粥"
	icon = 'icons/obj/food/moth.dmi'
	icon_state = "cornmeal_porridge"
	drink_type = GRAIN

/datum/chemical_reaction/food/soup/cornmeal_porridge
	required_other = FALSE
	required_reagents = list(
		/datum/reagent/consumable/cornmeal = 20,
		/datum/reagent/water = 20,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/cornmeal_porridge = 20,
	)

// Cheese Porridge (Soup-ish)
/datum/reagent/consumable/nutriment/soup/cheese_porridge
	name = "Cheesy Porridge-芝士玉米粥" //milk, polenta, firm cheese, curd cheese, butter
	description = "一碗口感丰富、奶油味浓郁的芝士玉米粥."
	data = list("玉米粥" = 1, "芝士" = 1, "芝士" = 1, "芝士" = 1)
	color = "#F0DD5A"

/datum/glass_style/has_foodtype/soup/cheese_porridge
	required_drink_type = /datum/reagent/consumable/nutriment/soup/cheese_porridge
	name = "Cheesy Porridge-芝士玉米粥"
	icon = 'icons/obj/food/moth.dmi'
	icon_state = "cheesy_porridge"
	drink_type = DAIRY | GRAIN

/datum/chemical_reaction/food/soup/cheese_porridge
	required_reagents = list(
		/datum/reagent/consumable/milk = 5,
		/datum/reagent/consumable/nutriment/soup/cornmeal_porridge = 20,
		/datum/reagent/water = 20,
	)
	required_ingredients = list(
		/obj/item/food/cheese/firm_cheese_slice = 1,
		/obj/item/food/cheese/curd_cheese = 1,
		/obj/item/food/butterslice = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/cheese_porridge = 30,
		/datum/reagent/consumable/nutriment/vitamin = 8,
		/datum/reagent/consumable/nutriment/protein = 4,
	)

// Rice Porridge again but with Toechtause
/datum/reagent/consumable/nutriment/soup/toechtauese_rice_porridge
	name = "Töchtaüse米粥"
	description = "通常在飞蛾舰队上供应，含有töchtaüse糖浆的米粥比普通的东西更美味，即使只是因为它比普通的更辣."
	data = list("sugar" = 1, "spice" = 1)
	color = "#D8CFCC"

/datum/glass_style/has_foodtype/soup/toechtauese_rice_porridge
	required_drink_type = /datum/reagent/consumable/nutriment/soup/toechtauese_rice_porridge
	name = "Töchtaüse米粥"
	icon = 'icons/obj/food/moth.dmi'
	icon_state = "toechtauese_rice_porridge"
	drink_type = GRAIN | VEGETABLES

/datum/chemical_reaction/food/soup/toechtauese_rice_porridge
	required_reagents = list(
		/datum/reagent/consumable/nutriment/soup/rice_porridge = 20,
		/datum/reagent/consumable/toechtauese_syrup = 10,
		/datum/reagent/water = 10,
	)
	required_ingredients = list(
		/obj/item/food/grown/chili = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/toechtauese_rice_porridge = 30,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment/vitamin = 6,
		/datum/reagent/consumable/toechtauese_syrup = 6,
	)

// Red Porridge
/datum/reagent/consumable/nutriment/soup/red_porridge
	name = "Eltsløsk ül a priktæolk" //eltsløsk = red porridge, ül a = with, prikt = sour, æolk = cream
	description = "酸奶红粥，这道菜的名字和蔬菜成分掩盖了它的甜味，它通常是舰队上的甜点."
	data = list("sweet beets" = 1, "sugar" = 1, "sweetened yoghurt" = 1)
	color = "#FF858B"

/datum/glass_style/has_foodtype/soup/red_porridge
	required_drink_type = /datum/reagent/consumable/nutriment/soup/red_porridge
	name = "eltsløsk ül a priktæolk"
	icon = 'icons/obj/food/moth.dmi'
	icon_state = "red_porridge"
	drink_type = VEGETABLES | SUGAR | DAIRY

/datum/chemical_reaction/food/soup/red_porridge
	required_temp = WATER_BOILING_POINT
	optimal_temp = 400
	overheat_temp = 415 // Caramel forms
	thermic_constant = 0
	required_reagents = list(
		/datum/reagent/consumable/vanilla = 10,
		/datum/reagent/consumable/yoghurt = 20,
		/datum/reagent/consumable/sugar = 10,
	)
	required_ingredients = list(
		/obj/item/food/grown/redbeet = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/red_porridge = 24,
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/sugar = 8,
	)
	percentage_of_nutriment_converted = 0.1

// Martian Food
// Boiled Noodles
/datum/chemical_reaction/food/soup/boilednoodles
	required_reagents = list(
		/datum/reagent/consumable/salt = 2
	)
	required_ingredients = list(
		/obj/item/food/spaghetti/rawnoodles = 1
	)
	required_catalysts = list(
		/datum/reagent/water/salt = 10,
	)
	resulting_food_path = /obj/item/food/spaghetti/boilednoodles
	ingredient_reagent_multiplier = 0

// Dashi Broth
/datum/reagent/consumable/nutriment/soup/dashi
	name = "Dashi-狐鲣鱼汤"
	description = "由海带和狐鲣鱼制成，这种母汤构成了大量日本菜肴的基础."
	data = list("umami" = 1)
	color = "#D49D26"

/datum/glass_style/has_foodtype/soup/dashi
	required_drink_type = /datum/reagent/consumable/nutriment/soup/dashi
	name = "Dashi-狐鲣鱼汤"
	drink_type = SEAFOOD

/datum/chemical_reaction/food/soup/dashi
	required_reagents = list(
		/datum/reagent/consumable/dashi_concentrate = 5,
		/datum/reagent/water = 40,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/dashi = 40,
	)

// Teriyaki Sauce
/datum/reagent/consumable/nutriment/soup/teriyaki
	name = "Teriyaki-照烧酱"
	description = "一种鲜味很重的日本酱."
	data = list("umami" = 1)
	color = "#3F0D02"

/datum/glass_style/has_foodtype/soup/teriyaki
	required_drink_type = /datum/reagent/consumable/nutriment/soup/teriyaki
	name = "Teriyaki-照烧酱"
	drink_type = VEGETABLES

/datum/chemical_reaction/food/soup/teriyaki
	required_reagents = list(
		/datum/reagent/consumable/soysauce = 10,
		/datum/reagent/consumable/ethanol/sake = 10,
		/datum/reagent/consumable/honey = 5,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/teriyaki = 20,
	)

// Curry Sauce
/datum/reagent/consumable/nutriment/soup/curry_sauce
	name = "Curry-咖喱酱"
	description = "一种基本的咖喱酱，适用于各种各样的食物."
	data = list("咖喱" = 1)
	color = "#F6C800"

/datum/glass_style/has_foodtype/soup/curry_sauce
	required_drink_type = /datum/reagent/consumable/nutriment/soup/curry_sauce
	name = "Curry-咖喱酱"
	drink_type = VEGETABLES

/datum/chemical_reaction/food/soup/curry_sauce
	required_reagents = list(
		/datum/reagent/water = 30,
		/datum/reagent/consumable/curry_powder = 10,
		/datum/reagent/consumable/soysauce = 5,
		/datum/reagent/consumable/corn_starch = 5,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/curry_sauce = 40,
	)

// Shoyu Ramen
/datum/reagent/consumable/nutriment/soup/shoyu_ramen
	name = "Shōyu Ramen-酱油拉面"
	description = "一种酱油拉面，有拉面、鱼糕、烤肉和煮蛋."
	data = list("蛋" = 1, "鱼糕" = 1, "拉面" = 1, "肉" = 1, "拉面汤" = 1)
	color = "#442621"

/datum/glass_style/has_foodtype/soup/shoyu_ramen
	required_drink_type = /datum/reagent/consumable/nutriment/soup/shoyu_ramen
	name = "Shōyu Ramen-酱油拉面"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "shoyu_ramen"
	drink_type = MEAT | GRAIN | VEGETABLES | SEAFOOD

/datum/chemical_reaction/food/soup/shoyu_ramen
	required_reagents = list(
		/datum/reagent/consumable/nutriment/soup/dashi = 20,
		/datum/reagent/consumable/nutriment/soup/teriyaki = 15,
	)
	required_ingredients = list(
		/obj/item/food/spaghetti/boilednoodles = 1,
		/obj/item/food/kamaboko_slice = 1,
		/obj/item/food/meat/cutlet = 1,
		/obj/item/food/boiledegg = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/shoyu_ramen = 30,
		/datum/reagent/consumable/nutriment/vitamin = 8,
		/datum/reagent/consumable/nutriment/protein = 8,
	)
	percentage_of_nutriment_converted = 0.2

// Gyuramen
/datum/reagent/consumable/nutriment/soup/gyuramen
	name = "Gyuramen Miy Käzu-谜团拉面"
	description = "浓郁的牛肉洋葱芝士拉面，将多种文化融合在一道美味的菜肴中."
	data = list("beef broth" = 1, "onion" = 1, "cheese" = 1)
	color = "#442621"

/datum/glass_style/has_foodtype/soup/gyuramen
	required_drink_type = /datum/reagent/consumable/nutriment/soup/gyuramen
	name = "Gyuramen Miy Käzu-谜团拉面"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "gyuramen"
	drink_type = MEAT | GRAIN | DAIRY | VEGETABLES

/datum/chemical_reaction/food/soup/gyuramen
	required_reagents = list(
		/datum/reagent/consumable/nutriment/soup/dashi = 20,
		/datum/reagent/consumable/soysauce = 5,
	)
	required_ingredients = list(
		/obj/item/food/spaghetti/boilednoodles = 1,
		/obj/item/food/cheese/wedge = 1,
		/obj/item/food/onion_slice = 2,
		/obj/item/food/meat/cutlet = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/gyuramen = 30,
		/datum/reagent/consumable/nutriment/vitamin = 2,
		/datum/reagent/consumable/nutriment/protein = 10,
	)
	percentage_of_nutriment_converted = 0.15

// New Osaka Sunrise
/datum/reagent/consumable/nutriment/soup/new_osaka_sunrise
	name = "New Osaka Sunrise Soup-新大阪日升汤"
	description = "一种鲜亮可口的豆腐味噌汤，通常是火星传统早餐的一部分，至少在新大阪是这样."
	data = list("味增汤" = 1, "豆腐" = 1, "洋葱" = 1, "茄子" = 1)
	color = "#EAB26E"

/datum/glass_style/has_foodtype/soup/new_osaka_sunrise
	required_drink_type = /datum/reagent/consumable/nutriment/soup/new_osaka_sunrise
	name = "\improper New Osaka Sunrise Soup-新大阪日升汤"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "new_osaka_sunrise"
	drink_type = VEGETABLES | BREAKFAST

/datum/chemical_reaction/food/soup/new_osaka_sunrise
	required_reagents = list(
		/datum/reagent/consumable/nutriment/soup/miso = 15,
	)
	required_ingredients = list(
		/obj/item/food/grown/herbs = 1,
		/obj/item/food/grown/eggplant = 1,
		/obj/item/food/onion_slice = 1,
		/obj/item/food/tofu = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/new_osaka_sunrise = 30,
		/datum/reagent/consumable/nutriment/vitamin = 8,
		/datum/reagent/consumable/nutriment/protein = 2,
	)
	percentage_of_nutriment_converted = 0.15

// Satsuma Black
/datum/reagent/consumable/nutriment/soup/satsuma_black
	name = "Satsuma Black Soup-萨摩黑汤"
	description = "一种来自火星的浓郁海鲜和面条汤，用鱿鱼墨水给人一种强烈的海洋味道."
	data = list("seafood" = 1, "tofu" = 1, "noodles" = 1)
	color = "#171221"

/datum/glass_style/has_foodtype/soup/satsuma_black
	required_drink_type = /datum/reagent/consumable/nutriment/soup/satsuma_black
	name = "\improper Satsuma Black Soup-萨摩黑汤"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "satsuma_black"
	drink_type = SEAFOOD | GRAIN | VEGETABLES

/datum/chemical_reaction/food/soup/satsuma_black
	required_reagents = list(
		/datum/reagent/consumable/nutriment/soup/dashi = 20,
	)
	required_ingredients = list(
		/obj/item/food/spaghetti/boilednoodles = 1,
		/obj/item/food/seaweedsheet = 1,
		/obj/item/food/tofu = 1,
		/obj/item/food/canned/squid_ink = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/satsuma_black = 30,
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/nutriment/protein = 6,
	)
	percentage_of_nutriment_converted = 0.15

// Dragon Style
/datum/reagent/consumable/nutriment/soup/dragon_ramen
	name = "Dragon Style Ramen-龙式拉面"
	description = "对于讨厌自己的味蕾和消化道的拉面爱好者来说，传统上是用七种不同的辣椒做的，不过在加入两种左右的辣椒后，还要加多少就没那么重要了."
	data = list("肉" = 1, "液态热岩浆" = 1, "拉面" = 1)
	color = "#980F00"

/datum/glass_style/has_foodtype/soup/dragon_ramen
	required_drink_type = /datum/reagent/consumable/nutriment/soup/dragon_ramen
	name = "\improper Dragon Style Ramen-龙式拉面"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "dragon_ramen"
	drink_type = SEAFOOD | GRAIN | VEGETABLES

/datum/chemical_reaction/food/soup/dragon_ramen
	required_reagents = list(
		/datum/reagent/consumable/nutriment/soup/dashi = 20,
		/datum/reagent/consumable/nutriment/soup/teriyaki = 10,
		/datum/reagent/consumable/red_bay = 5,
	)
	required_ingredients = list(
		/obj/item/food/spaghetti/boilednoodles = 1,
		/obj/item/food/grown/ghost_chili = 1,
		/obj/item/food/grown/chili = 1,
		/obj/item/food/kamaboko_slice = 1,
		/obj/item/food/boiledegg = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/dragon_ramen = 30,
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/nutriment/protein = 6,
	)
	ingredient_reagent_multiplier = 0.3 //reduces the impact of the chilis to manageable levels

// Hong Kong Borscht
/datum/reagent/consumable/nutriment/soup/hong_kong_borscht
	name = "Hong Kong Borscht-港式罗宋汤"
	description = "与东欧罗宋汤几乎没有任何相似之处——事实上，这是一种番茄汤，没有甜菜."
	data = list("番茄" = 1, "肉" = 1, "卷心菜" = 1)
	color = "#CA4810"

/datum/glass_style/has_foodtype/soup/hong_kong_borscht
	required_drink_type = /datum/reagent/consumable/nutriment/soup/hong_kong_borscht
	name = "\improper Hong Kong Borscht-港式罗宋汤"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "hong_kong_borscht"
	drink_type = MEAT | VEGETABLES

/datum/chemical_reaction/food/soup/hong_kong_borscht
	required_reagents = list(
		/datum/reagent/water = 50,
		/datum/reagent/consumable/soysauce = 5,
	)
	required_ingredients = list(
		/obj/item/food/grown/tomato = 1,
		/obj/item/food/grown/cabbage = 1,
		/obj/item/food/grown/onion = 1,
		/obj/item/food/grown/carrot = 1,
		/obj/item/food/meat/cutlet = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/hong_kong_borscht = 30,
		/datum/reagent/consumable/nutriment/vitamin = 8,
		/datum/reagent/consumable/nutriment/protein = 2,
	)
	percentage_of_nutriment_converted = 0.1

// Huotui Tong Fen
/datum/reagent/consumable/nutriment/soup/hong_kong_macaroni
	name = "Hong Kong Macaroni-港式通心粉汤"
	description = "香港茶餐厅(Cha Chaan Tengs)的最爱，这道通心面汤是由赛博森实业(Cybersun Industries)旗下的广东移民带到火星的，在那里和在中国一样成为早餐的主食."
	data = list("奶油" = 1, "鸡肉" = 1, "通心粉" = 1, "火腿" = 1)
	color = "#FFFAB5"

/datum/glass_style/has_foodtype/soup/hong_kong_macaroni
	required_drink_type = /datum/reagent/consumable/nutriment/soup/hong_kong_macaroni
	name = "\improper Hong Kong Macaroni-港式通心粉汤"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "hong_kong_macaroni"
	drink_type = MEAT | VEGETABLES | GRAIN

/datum/chemical_reaction/food/soup/hong_kong_macaroni
	required_reagents = list(
		/datum/reagent/water = 30,
		/datum/reagent/consumable/cream = 10,
	)
	required_ingredients = list(
		/obj/item/food/spaghetti/boiledspaghetti = 1,
		/obj/item/food/meat/cutlet/chicken = 1,
		/obj/item/food/meat/bacon = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/hong_kong_macaroni = 30,
		/datum/reagent/consumable/nutriment/protein = 6,
	)
	percentage_of_nutriment_converted = 0.2

// Fox's Prize Soup
/datum/reagent/consumable/nutriment/soup/foxs_prize_soup
	name = "Fox's Prize Soup-狐花汤"
	description = "最初是基于中国经典的蛋花汤，狐花汤通过添加野草和鱼汤来重复这个概念，制作出一道菜，真正吸引任何饥饿的狐狸."
	data = list("鸡蛋" = 1, "鸡肉" = 1, "炸豆腐" = 1, "鲜汤" = 1)
	color = "#E9B200"

/datum/glass_style/has_foodtype/soup/foxs_prize_soup
	required_drink_type = /datum/reagent/consumable/nutriment/soup/foxs_prize_soup
	name = "Fox's Prize Soup-狐花汤"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "foxs_prize_soup"
	drink_type = MEAT | VEGETABLES

/datum/chemical_reaction/food/soup/foxs_prize_soup
	required_reagents = list(
		/datum/reagent/consumable/nutriment/soup/dashi = 30,
		/datum/reagent/consumable/eggwhite = 10,
	)
	required_ingredients = list(
		/obj/item/food/meat/cutlet/chicken = 1,
		/obj/item/food/tofu = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/foxs_prize_soup = 30,
		/datum/reagent/consumable/nutriment/protein = 6,
	)

// Secret Noodle Soup
/datum/reagent/consumable/nutriment/soup/secret_noodle_soup
	name = "Secret Noodle Soup-秘制面汤"
	description = "是按照祖传秘方做的(出现在了好几本烹饪书里)，你会问，秘方是什么?好吧，这么说吧，它可能是任何东西...."
	data = list("面条" = 1, "鸡肉" = 1, "肉汤" = 1)
	color = "#D9BB79"

/datum/glass_style/has_foodtype/soup/secret_noodle_soup
	required_drink_type = /datum/reagent/consumable/nutriment/soup/secret_noodle_soup
	name = "Secret Noodle Soup-秘制面汤"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "secret_noodle_soup"
	drink_type = MEAT | VEGETABLES | GRAIN

/datum/chemical_reaction/food/soup/secret_noodle_soup
	required_reagents = list(
		/datum/reagent/consumable/nutriment/soup/dashi = 30,
	)
	required_ingredients = list(
		/obj/item/food/meat/cutlet/chicken = 1,
		/obj/item/food/spaghetti/boilednoodles = 1,
		/obj/item/food/grown/mushroom/chanterelle = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/secret_noodle_soup = 30,
		/datum/reagent/consumable/nutriment/protein = 6,
	)

// Budae-Jjigae
/datum/reagent/consumable/nutriment/soup/budae_jjigae
	name = "Budae-Jjigae-部队锅"
	description = "这道菜诞生于美国在韩驻扎期间，用20世纪60年代美国陆军基地的典型食材——热狗、辣椒和烤豆，以及一些韩国本土食材，如辣酱和泡菜."
	data = list("hot dog" = 1, "pork" = 1, "beans" = 1, "kimchi" = 1, "noodles" = 1)
	color = "#C8400E"

/datum/glass_style/has_foodtype/soup/budae_jjigae
	required_drink_type = /datum/reagent/consumable/nutriment/soup/budae_jjigae
	name = "Budae-Jjigae-部队锅"
	icon = 'icons/obj/food/martian.dmi'
	icon_state = "budae_jjigae"
	drink_type = MEAT | VEGETABLES | GRAIN

/datum/chemical_reaction/food/soup/budae_jjigae
	required_reagents = list(
		/datum/reagent/water = 30,
	)
	required_ingredients = list(
		/obj/item/food/canned/beans = 1,
		/obj/item/food/spaghetti/rawnoodles = 1,
		/obj/item/food/sausage/american = 1,
		/obj/item/food/chapslice = 2,
		/obj/item/food/kimchi = 1,
		/obj/item/food/cheese/wedge = 1,
	)
	results = list(
		/datum/reagent/consumable/nutriment/soup/budae_jjigae = 30,
		/datum/reagent/consumable/nutriment/protein = 6,
	)
	percentage_of_nutriment_converted = 0.1

// 24-Volt Fish
// Simply poach the fish in boiling energy drink, easy as
/datum/chemical_reaction/food/soup/volt_fish
	required_reagents = list(
		/datum/reagent/consumable/volt_energy = 15,
	)
	required_ingredients = list(
		/obj/item/food/fishmeat = 1
	)
	resulting_food_path = /obj/item/food/volt_fish
	ingredient_reagent_multiplier = 0
	mix_message = "空气中充满了鱼和人造香料的混合物."
