extends Node2D

@export var daytime_color: Gradient

func _process(delta: float) -> void:
	var daytime_point = 1 - ($Timers/DayTimer.time_left / $Timers/DayTimer.wait_time)
	var color = daytime_color.sample(daytime_point) #sample is much more detailed that get_color
	$Overlay/DayTimeColor.color = color
	#print(daytime_point)
