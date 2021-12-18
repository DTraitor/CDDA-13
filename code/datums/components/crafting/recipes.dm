/datum/crafting_recipe
	// In-game display name
	var/name = ""
	// In-game description
	var/desc = ""
	// Type paths of items consumed associated with how many are needed
	var/list/required_items_consume = list()
	// Crafting qualities of items consumed associated with levels list. Levels are associated with how many are needed
	var/list/required_qualities_consume = list()
	// Crafting qualities of items needed but not consumed. Lazy list.
	var/list/tool_qualities
	// Type paths of items explicitly not allowed as an ingredient
	var/list/blacklist = list()
	// Type path of item resulting from this craft
	var/result
	// Type path of object that will be replaced with recipe result (if obj_to_upgrade defined)
	var/obj_to_upgrade
	// Time in deciseconds
	var/time = 3 SECONDS
	// Type paths of items that will added to results craft_parts
	var/list/parts = list()
	// Reagents type paths required to craft item. Won't be consumed
	var/list/chem_catalysts = list()
	// Where it shows up in the crafting UI
	var/category = CAT_NONE
	// Set to FALSE if it needs to be learned first.
	var/always_available = TRUE
	// Additonal requirements text shown in UI
	var/additional_req_text
	// Required machines for the craft, set the assigned value of the typepath to CRAFTING_MACHINERY_CONSUME or CRAFTING_MACHINERY_USE. Lazy associative list: type_path key -> flag value.
	var/list/machinery
	// Should only one object exist on the same turf?
	var/one_per_turf = FALSE

/datum/crafting_recipe/New()
	if(!(result in required_items_consume))
		blacklist += result
	if(obj_to_upgrade)
		if(ispath(obj_to_upgrade, /obj/item) && !(obj_to_upgrade in required_items_consume))
			required_items_consume[obj_to_upgrade] = 1
		if(ispath(obj_to_upgrade, /obj/machinery) && !machinery?[obj_to_upgrade])
			LAZYINITLIST(machinery)
			machinery[obj_to_upgrade] = CRAFTING_MACHINERY_CONSUME
	.=..()

/**
 * Run custom pre-craft checks for this recipe
 *
 * user: The /mob that initiated the crafting
 * collected_requirements: A list of lists of /obj/item instances that satisfy reqs. Top level list is keyed by requirement path.
 */
/datum/crafting_recipe/proc/check_requirements(mob/user, list/collected_requirements)
	return TRUE

/datum/crafting_recipe/proc/on_craft_completion(mob/user, atom/result)
	return

/datum/crafting_recipe/the_test_one
	name = "very testy"
	desc = "lets see how it works"
	required_items_consume = list(/obj/item/storage/backpack = 1, /obj/item/tape = 0, /obj/item/mass_spectrometer = 5)
	required_qualities_consume = list(CRAFT_QUALITY_STICK = list("1" = 3, "2" = 5, "3" = 0))
	tool_qualities = list(TOOL_MULTITOOL, TOOL_WIRECUTTER)
	blacklist = list()
	result = /obj/item/megaphone
	time = 5 SECONDS
	parts = list()
	chem_catalysts = list(/datum/reagent/lube)
	category = CAT_WEAPON
	always_available = TRUE
	additional_req_text = "this is a the best test text I've ever seen"
	machinery = list(/obj/machinery/light/small = CRAFTING_MACHINERY_USE)
	one_per_turf = FALSE

/datum/crafting_recipe/the_test_one_but_the_second
	name = "even more testy"
	required_items_consume = list(/obj/item/storage/backpack = 1, /obj/item/tape = 0, /obj/item/mass_spectrometer = 5)
	required_qualities_consume = list(CRAFT_QUALITY_STICK = list("1" = 3, "2" = 5, "3" = 0))
	tool_qualities = list(TOOL_MULTITOOL, TOOL_WIRECUTTER)
	blacklist = list()
	result = /obj/item/megaphone
	time = 5 SECONDS
	parts = list()
	chem_catalysts = list(/datum/reagent/lube)
	category = CAT_AMMO
	always_available = TRUE
	additional_req_text = "this is a the best test text I've ever seen"
	machinery = list(/obj/machinery/light/small = CRAFTING_MACHINERY_USE)
	one_per_turf = FALSE
