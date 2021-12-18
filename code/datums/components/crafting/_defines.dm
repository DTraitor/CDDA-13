///If the machine is used/deleted in the crafting process
#define CRAFTING_MACHINERY_CONSUME 1
///If the machine is only "used" i.e. it checks to see if it's nearby and allows crafting, but doesn't delete it
#define CRAFTING_MACHINERY_USE 0

GLOBAL_LIST_INIT(crafting_qualities, list(
	CRAFTING_QUALITY_STICK = list("wooden", "steel", "titanium")
))
