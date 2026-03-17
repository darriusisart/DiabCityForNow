extends Node2D
## End-of-game shopkeeper cutscene.
## Shows a summary of the player's shopping trip —
## items grabbed, nutrition score, foods dropped, grade, and a comment.

func show_results(cart_items: Array, total_nutrition: int, foods_dropped: int,
				  mini_games_played: int, screen_size: Vector2):

	var layer = CanvasLayer.new()
	layer.name = "EndLayer"
	layer.layer = 20
	add_child(layer)

	# ── Dim overlay ──
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.size = screen_size
	layer.add_child(dim)

	# ── Main card panel ──
	var panel = Panel.new()
	panel.size = Vector2(620, 520)
	panel.position = Vector2(screen_size.x / 2 - 310, screen_size.y / 2 - 260)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.09, 0.16)
	style.set_corner_radius_all(18)
	style.border_width_left   = 4
	style.border_width_right  = 4
	style.border_width_top    = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.92, 0.78, 0.22)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)

	# ── Shopkeeper "sprite" ──
	var keeper = Label.new()
	keeper.text = "SHOPKEEPER"
	keeper.position = Vector2(230, 12)
	keeper.add_theme_font_size_override("font_size", 16)
	keeper.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	panel.add_child(keeper)

	# Shopkeeper face (ascii art feel)
	var face = Label.new()
	face.text = "[  ^_^  ]"
	face.position = Vector2(240, 34)
	face.add_theme_font_size_override("font_size", 24)
	face.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	panel.add_child(face)

	var thanks = Label.new()
	thanks.text = "Thanks for shopping!"
	thanks.position = Vector2(195, 68)
	thanks.add_theme_font_size_override("font_size", 22)
	thanks.add_theme_color_override("font_color", Color(1, 0.9, 0.35))
	panel.add_child(thanks)

	# ── Tally up items by tier ──
	var green_count  := 0
	var yellow_count := 0
	var red_count    := 0
	for item in cart_items:
		match item.get_meta("tier"):
			"green":  green_count  += 1
			"yellow": yellow_count += 1
			"red":    red_count    += 1

	# ── Stat lines ──
	var y := 110
	var stats := [
		"Items in Cart:      %d" % cart_items.size(),
		"Total Nutrition:    %d" % total_nutrition,
		"Foods Dropped:      %d" % foods_dropped,
		"Mini-Games Played:  %d" % mini_games_played,
		"",
		"  Healthy (Green):  %d" % green_count,
		"  Moderate (Yellow):%d" % yellow_count,
		"  Junk (Red):       %d" % red_count,
	]
	for line in stats:
		var lbl = Label.new()
		lbl.text = line
		lbl.position = Vector2(60, y)
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
		panel.add_child(lbl)
		y += 26

	# ── Grade ──
	var grade = _calc_grade(cart_items, total_nutrition)

	y += 12
	var grade_lbl = Label.new()
	grade_lbl.text = "Grade: " + grade["letter"]
	grade_lbl.position = Vector2(180, y)
	grade_lbl.add_theme_font_size_override("font_size", 30)
	grade_lbl.add_theme_color_override("font_color", grade["color"])
	panel.add_child(grade_lbl)

	y += 44
	var comment = Label.new()
	comment.text = grade["comment"]
	comment.position = Vector2(70, y)
	comment.add_theme_font_size_override("font_size", 15)
	comment.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
	panel.add_child(comment)

	y += 36
	var restart = Label.new()
	restart.text = "Press R to shop again!"
	restart.position = Vector2(210, y)
	restart.add_theme_font_size_override("font_size", 13)
	restart.add_theme_color_override("font_color", Color(0.48, 0.48, 0.48))
	panel.add_child(restart)


# ──────────────────────────────────────────────
#  GRADING — based on average nutrition per item
# ──────────────────────────────────────────────
func _calc_grade(cart_items: Array, total_nutrition: int) -> Dictionary:
	if cart_items.size() == 0:
		return {
			"letter":  "F - Empty Cart",
			"color":   Color(1, 0.2, 0.2),
			"comment": "\"You didn't buy anything... are you okay?\""
		}

	var avg := float(total_nutrition) / cart_items.size()

	if avg >= 26:
		return {
			"letter":  "S  -  Health Nut!",
			"color":   Color(0.2, 1, 0.2),
			"comment": "\"Incredible choices! Your body thanks you!\""
		}
	elif avg >= 21:
		return {
			"letter":  "A  -  Great!",
			"color":   Color(0.4, 0.92, 0.4),
			"comment": "\"Very healthy shopping trip! Keep it up!\""
		}
	elif avg >= 16:
		return {
			"letter":  "B  -  Good",
			"color":   Color(0.35, 0.72, 1),
			"comment": "\"Nice balance of nutrition. Solid haul.\""
		}
	elif avg >= 11:
		return {
			"letter":  "C  -  Okay",
			"color":   Color(1, 0.82, 0.22),
			"comment": "\"Not bad, but maybe grab more greens next time...\""
		}
	elif avg >= 6:
		return {
			"letter":  "D  -  Meh",
			"color":   Color(1, 0.5, 0.22),
			"comment": "\"Too much junk food in that cart...\""
		}
	else:
		return {
			"letter":  "F  -  Junk Royalty",
			"color":   Color(1, 0.22, 0.22),
			"comment": "\"Your dentist is NOT going to be happy!\""
		}
