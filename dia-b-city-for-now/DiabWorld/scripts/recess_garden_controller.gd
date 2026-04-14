extends Node

var soil_clumps: int = 0

func add_clump_from_mound() -> String:
	soil_clumps += 1
	if soil_clumps >= 2:
		soil_clumps -= 2
		Data.recess_garden_seeds += 1
		return "merged"
	return "stacked"
