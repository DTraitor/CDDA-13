/datum/component/personal_crafting
	var/busy
	var/viewing_category = 1 //typical powergamer starting on the Weapons tab
	var/viewing_subcategory = 1
	var/list/categories = list(
				CAT_WEAPONRY = list(
					CAT_WEAPON,
					CAT_AMMO,
				),
				CAT_ROBOT = CAT_NONE,
				CAT_MISC = CAT_NONE,
				CAT_PRIMAL = CAT_NONE,
				CAT_FOOD = list(
					CAT_BREAD,
					CAT_BURGER,
					CAT_CAKE,
					CAT_EGG,
					CAT_LIZARD,
					CAT_ICE,
					CAT_MEAT,
					CAT_SEAFOOD,
					CAT_MISCFOOD,
					CAT_PASTRY,
					CAT_PIE,
					CAT_PIZZA,
					CAT_SALAD,
					CAT_SANDWICH,
					CAT_SOUP,
					CAT_SPAGHETTI,
				),
				CAT_DRINK = CAT_NONE,
				CAT_CLOTHING = CAT_NONE,
				CAT_ATMOSPHERIC = CAT_NONE,
			)

	var/cur_category = CAT_NONE
	var/cur_subcategory = CAT_NONE
	var/datum/action/innate/crafting/button
	var/display_craftable_only = FALSE
	var/display_compact = TRUE

/datum/component/personal_crafting/Initialize()
	if(ismob(parent))
		RegisterSignal(parent, COMSIG_MOB_CLIENT_LOGIN, .proc/create_mob_button)

/datum/component/personal_crafting/proc/create_mob_button(mob/user, client/CL)
	SIGNAL_HANDLER

	var/datum/hud/H = user.hud_used
	var/atom/movable/screen/craft/C = new()
	H.static_inventory += C
	CL.screen += C
	RegisterSignal(C, COMSIG_CLICK, .proc/component_ui_interact)

/datum/component/personal_crafting/proc/component_ui_interact(atom/movable/screen/craft/image, location, control, params, user)
	SIGNAL_HANDLER

	if(user == parent)
		INVOKE_ASYNC(src, .proc/ui_interact, user)

/datum/component/personal_crafting/ui_state(mob/user)
	return GLOB.not_incapacitated_turf_state

//For the UI related things we're going to assume the user is a mob rather than typesetting it to an atom as the UI isn't generated if the parent is an atom
/datum/component/personal_crafting/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		cur_category = categories[1]
		if(islist(categories[cur_category]))
			var/list/subcats = categories[cur_category]
			cur_subcategory = subcats[1]
		else
			cur_subcategory = CAT_NONE
		ui = new(user, src, "PersonalCrafting")
		ui.open()

/datum/component/personal_crafting/ui_data(mob/user)
	var/list/data = list()
	data["busy"] = busy
	data["category"] = cur_category
	data["subcategory"] = cur_subcategory
	data["display_craftable_only"] = display_craftable_only
	data["display_compact"] = display_compact

	var/list/surroundings = get_surroundings(user)
	var/list/craftability = list()
	for(var/rec in GLOB.crafting_recipes)
		var/datum/crafting_recipe/R = rec

		if(!R.always_available && !(R.type in user?.mind?.learned_recipes)) //User doesn't actually know how to make this.
			continue

		if((R.category != cur_category) || (R.subcategory != cur_subcategory))
			continue

		craftability["[REF(R)]"] = check_contents(user, R, surroundings)

	data["craftability"] = craftability
	return data

/datum/component/personal_crafting/ui_static_data(mob/user)
	var/list/data = list()

	var/list/crafting_recipes = list()
	for(var/rec in GLOB.crafting_recipes)
		var/datum/crafting_recipe/R = rec

		if(R.name == "") //This is one of the invalid parents that sneaks in
			continue

		if(!R.always_available && !(R.type in user?.mind?.learned_recipes)) //User doesn't actually know how to make this.
			continue

		if(isnull(crafting_recipes[R.category]))
			crafting_recipes[R.category] = list()

		if(R.subcategory == CAT_NONE)
			crafting_recipes[R.category] += list(build_recipe_data(R))
		else
			if(isnull(crafting_recipes[R.category][R.subcategory]))
				crafting_recipes[R.category][R.subcategory] = list()
				crafting_recipes[R.category]["has_subcats"] = TRUE
			crafting_recipes[R.category][R.subcategory] += list(build_recipe_data(R))

	data["crafting_recipes"] = crafting_recipes
	return data

/datum/component/personal_crafting/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("make")
			var/mob/user = usr
			var/datum/crafting_recipe/crafting_recipe = locate(params["recipe"]) in GLOB.crafting_recipes
			busy = TRUE
			ui_interact(user)
			var/atom/movable/result = construct_item(user, crafting_recipe)
			if(!istext(result)) //We made an item and didn't get a fail message
				if(ismob(user) && isitem(result)) //In case the user is actually possessing a non mob like a machine
					user.put_in_hands(result)
				else
					result.forceMove(user.drop_location())
				to_chat(user, span_notice("[crafting_recipe.name] constructed."))
				crafting_recipe.on_craft_completion(user, result)
			else
				to_chat(user, span_warning("Construction failed[result]"))
			busy = FALSE
		if("toggle_recipes")
			display_craftable_only = !display_craftable_only
			. = TRUE
		if("toggle_compact")
			display_compact = !display_compact
			. = TRUE
		if("set_category")
			cur_category = params["category"]
			cur_subcategory = params["subcategory"] || ""
			. = TRUE

/datum/component/personal_crafting/proc/build_recipe_data(datum/crafting_recipe/recipe)
	var/list/data = list()
	data["name"] = recipe.name
	data["ref"] = "[REF(recipe)]"
	var/list/req_text = list()
	var/list/tool_list = list()
	var/list/catalyst_text = list()

	for(var/obj/machinery/content as anything in recipe.machinery)
		if(recipe.machinery[content] == CRAFTING_MACHINERY_CONSUME)
			req_text += "[initial(content.name)] to disassemble in the process"
		else
			req_text += "[initial(content.name)] to use"

	for(var/quality in recipe.required_qualities_consume)
		for(var/quality_level in recipe.required_qualities_consume[quality])
			req_text += "[recipe.required_qualities_consume[quality][quality_level]] [GLOB.crafting_qualities[quality][quality_level]] (or better) [quality]"

	for(var/atom/req_atom as anything in recipe.required_items_consume)
		//We just need the name, so cheat-typecast to /atom for speed (even tho Reagents are /datum they DO have a "name" var)
		//Also these are typepaths so sadly we can't just do "[a]"
		req_text += "[recipe.required_items_consume[req_atom]] [initial(req_atom.name)]"

	if(recipe.additional_req_text)
		req_text += recipe.additional_req_text
	data["req_text"] = req_text.Join(", ")

	for(var/atom/req_catalyst as anything in recipe.chem_catalysts)
		catalyst_text += "[recipe.chem_catalysts[req_catalyst]] [initial(req_catalyst.name)]"
	data["catalyst_text"] = catalyst_text.Join(", ")

	for(var/required_quality in recipe.tool_qualities)
		tool_list += required_quality
	data["tool_text"] = tool_list.Join(", ")

	return data

/datum/component/personal_crafting/proc/get_environment(atom/a, list/blacklist = null, radius_range = 1)
	. = list()

	if(!isturf(a.loc))
		return

	for(var/atom/movable/AM in range(radius_range, a))
		if(blacklist && (AM.type in blacklist))
			continue
		. += AM


/datum/component/personal_crafting/proc/get_surroundings(atom/a, list/blacklist)
	. = list()
	.["tool_behaviours"] = list()
	.["crafting_qualities"] = list()
	.["amounts"] = list()
	.["items"] = list()
	.["machinery"] = list()
	for(var/obj/object in get_environment(a, blacklist))
		if(isitem(object))
			var/obj/item/item = object
			LAZYADDASSOC(.["items"], item.type, item)
			if(isitemstack(item))
				var/obj/item/stack/stack = item
				.["amounts"][item.type] += stack.amount
			else if(item.tool_behaviour)
				.["tool_behaviour"][item.tool_behaviour] += item
				.["amounts"][item.type] += 1
			else
				if(isreagentcontainer(item))
					var/obj/item/reagent_containers/container = item
					if(container.is_drainable())
						for(var/datum/reagent/reagent in container.reagents.reagent_list)
							.["amounts"][reagent.type] += reagent.volume
				if(item.crafting_qualities)
					for(var/quality in item.crafting_qualities)
						.["crafting_qualities"][quality][item.crafting_qualities[quality]] += item
				.["amounts"][item.type] += 1
		else if (ismachinery(object))
			.["machinery"][object.type] += object

/datum/component/personal_crafting/proc/check_contents(atom/atom, datum/crafting_recipe/recipe, list/contents)
	var/list/item_instances = contents["items"]
	// List that contains lists with lists
	var/list/list/list/crafting_qualities = contents["crafting_qualities"]
	var/list/machines = contents["machinery"]
	contents = contents["amounts"]

	var/list/requirements_list = list()

	// Process all requirements
	for(var/requirement_path in recipe.required_items_consume)
		// Check we have the appropriate amount available in the contents list
		var/needed_amount = recipe.required_items_consume[requirement_path]
		for(var/content_item_path in contents)
			// Right path and not blacklisted
			if(!ispath(content_item_path, requirement_path) || recipe.blacklist.Find(content_item_path))
				continue

			needed_amount -= contents[content_item_path]
			if(needed_amount <= 0)
				break

		if(needed_amount > 0)
			return FALSE

		// Store the instances of what we will use for recipe.check_requirements() for requirement_path
		var/list/instances_list = list()
		for(var/instance_path in item_instances)
			if(ispath(instance_path, requirement_path))
				instances_list += item_instances[instance_path]

		requirements_list[requirement_path] = instances_list

	for(var/quality in recipe.required_qualities_consume)
		for(var/quality_level in recipe.required_qualities_consume[quality])
			if(crafting_qualities[quality][quality_level].len < recipe.required_qualities_consume[quality][quality_level])
				return FALSE
			else
				requirements_list[quality][quality_level] = crafting_qualities[quality][quality_level]

	for(var/requirement_path in recipe.chem_catalysts)
		if(contents[requirement_path] < recipe.chem_catalysts[requirement_path])
			return FALSE

	for(var/machinery_path in recipe.machinery)
		if(!machines[machinery_path])//We don't care for volume with machines, just if one is there or not
			return FALSE
		else
			requirements_list[machinery_path] = machines[machinery_path]

	return recipe.check_requirements(atom, requirements_list)

/// Returns a boolean on whether the tool requirements of the input recipe are satisfied by the input source and surroundings.
/datum/component/personal_crafting/proc/check_tools(atom/source, datum/crafting_recipe/recipe, list/surroundings)
	if(!length(recipe.tool_qualities))
		return TRUE
	var/list/available_tools = list()
	var/list/present_qualities = list()

	for(var/obj/item/contained_item in source.contents)
		if(isstorage(contained_item))
			for(var/obj/item/subcontained_item in contained_item.contents)
				available_tools[subcontained_item.type] = TRUE
				if(subcontained_item.tool_behaviour)
					present_qualities[subcontained_item.tool_behaviour] = TRUE
		available_tools[contained_item.type] = TRUE
		if(contained_item.tool_behaviour)
			present_qualities[contained_item.tool_behaviour] = TRUE

	for(var/quality in surroundings["tool_behaviour"])
		present_qualities[quality] = TRUE

	for(var/path in surroundings["other"])
		available_tools[path] = TRUE

	for(var/required_quality in recipe.tool_qualities)
		if(present_qualities[required_quality])
			continue
		return FALSE

	return TRUE

/datum/component/personal_crafting/proc/construct_item(atom/a, datum/crafting_recipe/R)
	var/list/contents = get_surroundings(a,R.blacklist)
	var/send_feedback = 1
	if(check_contents(a, R, contents))
		if(check_tools(a, R, contents))
			if(R.one_per_turf)
				for(var/content in get_turf(a))
					if(istype(content, R.result))
						return ", object already present."
			//If we're a mob we'll try a do_after; non mobs will instead instantly construct the item
			if(ismob(a) && !do_after(a, R.time, target = a))
				return "."
			contents = get_surroundings(a,R.blacklist)
			if(!check_contents(a, R, contents))
				return ", missing component."
			if(!check_tools(a, R, contents))
				return ", missing tool."
			var/list/parts = del_reqs(R, a)
			var/atom/movable/I = new R.result (get_turf(a.loc))
			I.CheckParts(parts, R)
			if(send_feedback)
				SSblackbox.record_feedback("tally", "object_crafted", 1, I.type)
			return I //Send the item back to whatever called this proc so it can handle whatever it wants to do with the new item
		return ", missing tool."
	return ", missing component."

/datum/component/personal_crafting/proc/del_reqs(datum/crafting_recipe/R, atom/a)
	var/list/surroundings
	var/list/Deletion = list()
	. = list()
	var/data
	var/amt
	var/list/requirements = list()
	if(R.required_items_consume)
		requirements += R.required_items_consume
	if(R.machinery)
		requirements += R.machinery
	main_loop:
		for(var/path_key in requirements)
			amt = R.required_items_consume[path_key] || R.machinery[path_key]
			if(!amt)//since machinery can have 0 aka CRAFTING_MACHINERY_USE - i.e. use it, don't consume it!
				continue main_loop
			surroundings = get_environment(a, R.blacklist)
			surroundings -= Deletion
			if(ispath(path_key, /datum/reagent))
				var/datum/reagent/RG = new path_key
				var/datum/reagent/RGNT
				while(amt > 0)
					var/obj/item/reagent_containers/RC = locate() in surroundings
					RG = RC.reagents.get_reagent(path_key)
					if(RG)
						if(!locate(RG.type) in Deletion)
							Deletion += new RG.type()
						if(RG.volume > amt)
							RG.volume -= amt
							data = RG.data
							RC.reagents.conditional_update(RC)
							RG = locate(RG.type) in Deletion
							RG.volume = amt
							RG.data += data
							continue main_loop
						else
							surroundings -= RC
							amt -= RG.volume
							RC.reagents.reagent_list -= RG
							RC.reagents.conditional_update(RC)
							RGNT = locate(RG.type) in Deletion
							RGNT.volume += RG.volume
							RGNT.data += RG.data
							qdel(RG)
						SEND_SIGNAL(RC.reagents, COMSIG_REAGENTS_CRAFTING_PING) // - [] TODO: Make this entire thing less spaghetti
					else
						surroundings -= RC
			else if(ispath(path_key, /obj/item/stack))
				var/obj/item/stack/S
				var/obj/item/stack/SD
				while(amt > 0)
					S = locate(path_key) in surroundings
					if(S.amount >= amt)
						if(!locate(S.type) in Deletion)
							SD = new S.type()
							Deletion += SD
						S.use(amt)
						SD = locate(S.type) in Deletion
						SD.amount += amt
						continue main_loop
					else
						amt -= S.amount
						if(!locate(S.type) in Deletion)
							Deletion += S
						else
							data = S.amount
							S = locate(S.type) in Deletion
							S.add(data)
						surroundings -= S
			else
				var/atom/movable/I
				while(amt > 0)
					I = locate(path_key) in surroundings
					Deletion += I
					surroundings -= I
					amt--
	var/list/partlist = list(R.parts.len)
	for(var/M in R.parts)
		partlist[M] = R.parts[M]
	for(var/part in R.parts)
		if(istype(part, /datum/reagent))
			var/datum/reagent/RG = locate(part) in Deletion
			if(RG.volume > partlist[part])
				RG.volume = partlist[part]
			. += RG
			Deletion -= RG
			continue
		else if(istype(part, /obj/item/stack))
			var/obj/item/stack/ST = locate(part) in Deletion
			if(ST.amount > partlist[part])
				ST.amount = partlist[part]
			. += ST
			Deletion -= ST
			continue
		else
			while(partlist[part] > 0)
				var/atom/movable/AM = locate(part) in Deletion
				. += AM
				Deletion -= AM
				partlist[part] -= 1
	while(Deletion.len)
		var/DL = Deletion[Deletion.len]
		Deletion.Cut(Deletion.len)
		// Snowflake handling of reagent containers and storage atoms.
		// If we consumed them in our crafting, we should dump their contents out before qdeling them.
		if(isreagentcontainer(DL))
			var/obj/item/reagent_containers/container = DL
			container.reagents.expose(container.loc, TOUCH)
		else if(isstorage(DL))
			var/obj/item/storage/container = DL
			container.quick_empty()
		qdel(DL)

/datum/mind/proc/teach_crafting_recipe(R)
	if(!learned_recipes)
		learned_recipes = list()
	learned_recipes |= R
