/datum/crafting_recipe
	// In-game display name
	var/name = ""
	// Type paths of items consumed associated with how many are needed
	var/list/required_items_consume = list()
	// Crafting qualities of items consumed associated with how many are needed
	var/list/required_qualities_consume = list()
	// Crafting qualities of items needed but not consumed. Lazy list.
	var/list/tool_qualities
	// Type paths of items explicitly not allowed as an ingredient
	var/list/blacklist = list()
	// Type path of item resulting from this craft
	var/result
	// Time in deciseconds
	var/time = 3 SECONDS
	// Type paths of items that will added to results craft_parts
	var/list/parts = list()
	// Reagents type paths required to craft item. Won't be consumed
	var/list/chem_catalysts = list()
	// Where it shows up in the crafting UI
	var/category = CAT_NONE
	var/subcategory = CAT_NONE
	// Set to FALSE if it needs to be learned first.
	var/always_available = TRUE
	// Additonal requirements text shown in UI
	var/additional_req_text
	// Required machines for the craft, set the assigned value of the typepath to CRAFTING_MACHINERY_CONSUME or CRAFTING_MACHINERY_USE or CRAFTING_MACHINERY_UPGRADE. Lazy associative list: type_path key -> flag value.
	var/list/machinery
	// Should only one object exist on the same turf?
	var/one_per_turf = FALSE

/datum/crafting_recipe/New()
	if(!(result in required_items_consume))
		blacklist += result
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
