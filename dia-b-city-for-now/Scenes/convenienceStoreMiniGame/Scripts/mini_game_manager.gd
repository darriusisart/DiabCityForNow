extends Node2D
## Handles all 5 mini-game challenge events:
##  1. Timing Bar  – press SPACE when marker is in the green zone
##  2. Button Spam – mash SPACE to fill the bar before time runs out
##  3. Balance     – alternate A / D to keep indicator centred for 5 s
##  4. Simon Says  – memorise arrow-key sequence, then replay it
##  5. Food Match  – press 1 / 2 / 3 to sort food into green / yellow / red

signal mini_game_finished(success: bool)

var active := false
var _panel : Panel
var _screen : Vector2
var _current_game := ""
var _timer := 0.0
var _resolved := false  # true once we know pass/fail

# ── Timing-bar state ──
var _tb_pos := 0.0
var _tb_dir := 1.0
var _tb_speed := 2.5
var _tb_zone_start := 0.3
var _tb_zone_width := 0.18   # fraction of bar

# ── Button-spam state ──
var _spam_count := 0
var _spam_target := 20
var _spam_time_limit := 5.0

# ── Balance state ──
var _bal_value := 0.5
var _bal_safe_time := 0.0
var _bal_target_time := 5.0

# ── Simon-says state ──
var _simon_seq : Array = []
var _simon_idx := 0
var _simon_showing := true
var _simon_show_i := 0
var _simon_show_t := 0.0

# ── Food-match state ──
var _match_foods : Array = []
var _match_idx := 0

# ──────────────────────────────────────────────
func _ready():
	_screen = get_viewport_rect().size
	_build_panel()

func _build_panel():
	var layer = CanvasLayer.new()
	layer.name = "MGLayer"
	layer.layer = 10
	add_child(layer)

	_panel = Panel.new()
	_panel.name = "MGPanel"
	_panel.size = Vector2(520, 370)
	_panel.position = Vector2(_screen.x / 2 - 260, _screen.y / 2 - 185)
	_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.96)
	style.set_corner_radius_all(14)
	style.border_width_left   = 3
	style.border_width_right  = 3
	style.border_width_top    = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.85, 0.72, 0.18)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.focus_mode = Control.FOCUS_NONE   # Don't steal keyboard focus
	layer.add_child(_panel)

# ──────────────────────────────────────────────
#  PUBLIC — called by store_manager
# ──────────────────────────────────────────────
func start_random(difficulty: String):
	active = true
	_resolved = false
	_timer = 0.0
	_clear_panel()

	var pool : Array
	if difficulty == "yellow":
		pool = ["timing_bar", "button_spam", "balance"]
	else:
		pool = ["simon_says", "food_match"]

	_current_game = pool[randi() % pool.size()]

	match _current_game:
		"timing_bar":  _setup_timing_bar()
		"button_spam": _setup_button_spam()
		"balance":     _setup_balance()
		"simon_says":  _setup_simon_says()
		"food_match":  _setup_food_match()

	_panel.visible = true

# ──────────────────────────────────────────────
#  PROCESS
# ──────────────────────────────────────────────
func _process(delta):
	if not active or _resolved:
		return
	_timer += delta
	match _current_game:
		"timing_bar":  _tick_timing_bar(delta)
		"button_spam": _tick_button_spam(delta)
		"balance":     _tick_balance(delta)
		"simon_says":  _tick_simon_says(delta)
		"food_match":  pass  # purely input-driven

# ──────────────────────────────────────────────
#  INPUT
# ──────────────────────────────────────────────
func _input(event):
	if not active or _resolved:
		return
	match _current_game:
		"timing_bar":  _input_timing_bar(event)
		"button_spam": _input_button_spam(event)
		"balance":     _input_balance(event)
		"simon_says":  _input_simon_says(event)
		"food_match":  _input_food_match(event)
	# Consume the event so store_manager doesn't also process it
	get_viewport().set_input_as_handled()

# ════════════════════════════════════════════════
#  1. TIMING BAR
# ════════════════════════════════════════════════
func _setup_timing_bar():
	_tb_pos = 0.0
	_tb_dir = 1.0
	_tb_speed = 2.0 + randf() * 1.5
	_tb_zone_start = 0.25 + randf() * 0.35
	_tb_zone_width = 0.18

	_add_label("Title", "TIMING CHALLENGE!", Vector2(130, 18), 22, Color(1, 0.9, 0.3))
	_add_label("Instr", "Press SPACE when the marker is in the green zone!", Vector2(60, 52), 14, Color(0.78, 0.78, 0.78))

	# Bar background
	var bar_bg = ColorRect.new(); bar_bg.name = "BarBg"
	bar_bg.color = Color(0.3, 0.3, 0.3); bar_bg.size = Vector2(420, 44)
	bar_bg.position = Vector2(50, 120); _panel.add_child(bar_bg)

	# Green target zone
	var zone = ColorRect.new(); zone.name = "Zone"
	zone.color = Color(0.2, 0.82, 0.2, 0.65)
	zone.size = Vector2(_tb_zone_width * 420, 44)
	zone.position = Vector2(50 + _tb_zone_start * 420, 120)
	_panel.add_child(zone)

	# Marker
	var mk = ColorRect.new(); mk.name = "Marker"
	mk.color = Color.WHITE; mk.size = Vector2(6, 54)
	mk.position = Vector2(50, 115); _panel.add_child(mk)

	_add_label("Result", "", Vector2(180, 210), 26, Color.WHITE)

func _tick_timing_bar(delta):
	_tb_pos += _tb_dir * _tb_speed * delta
	if _tb_pos >= 1.0:
		_tb_pos = 1.0; _tb_dir = -1.0
	elif _tb_pos <= 0.0:
		_tb_pos = 0.0; _tb_dir = 1.0
	var mk = _panel.get_node_or_null("Marker")
	if mk:
		mk.position.x = 50 + _tb_pos * 414
	if _timer > 8.0:
		_resolve(false)

func _input_timing_bar(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		var hit = _tb_pos >= _tb_zone_start and _tb_pos <= _tb_zone_start + _tb_zone_width
		_resolve(hit)

# ════════════════════════════════════════════════
#  2. BUTTON SPAM
# ════════════════════════════════════════════════
func _setup_button_spam():
	_spam_count = 0
	_spam_target = 15 + randi() % 11
	_spam_time_limit = 5.0

	_add_label("Title", "BUTTON MASH!", Vector2(160, 18), 22, Color(1, 0.55, 0.2))
	_add_label("Instr", "Mash SPACE as fast as you can!", Vector2(110, 52), 14, Color(0.78, 0.78, 0.78))
	_add_label("Count", "0 / " + str(_spam_target), Vector2(190, 110), 36, Color.WHITE)

	var bar_bg = ColorRect.new(); bar_bg.name = "BarBg"
	bar_bg.color = Color(0.3, 0.3, 0.3); bar_bg.size = Vector2(420, 32)
	bar_bg.position = Vector2(50, 190); _panel.add_child(bar_bg)

	var fill = ColorRect.new(); fill.name = "Fill"
	fill.color = Color(1, 0.55, 0.2); fill.size = Vector2(0, 32)
	fill.position = Vector2(50, 190); _panel.add_child(fill)

	_add_label("Timer", "Time: 5.0s", Vector2(200, 240), 16, Color(0.7, 0.7, 0.7))
	_add_label("Result", "", Vector2(180, 290), 26, Color.WHITE)

func _tick_button_spam(_delta):
	var left = _spam_time_limit - _timer
	var tl = _panel.get_node_or_null("Timer")
	if tl:
		tl.text = "Time: %.1fs" % max(0, left)
	if left <= 0:
		_resolve(false)

func _input_button_spam(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_spam_count += 1
		var cl = _panel.get_node_or_null("Count")
		if cl: cl.text = str(_spam_count) + " / " + str(_spam_target)
		var fl = _panel.get_node_or_null("Fill")
		if fl: fl.size.x = (float(_spam_count) / _spam_target) * 420
		if _spam_count >= _spam_target:
			_resolve(true)

# ════════════════════════════════════════════════
#  3. BALANCE
# ════════════════════════════════════════════════
func _setup_balance():
	_bal_value = 0.5
	_bal_safe_time = 0.0

	_add_label("Title", "BALANCE CHALLENGE!", Vector2(130, 18), 22, Color(0.3, 0.85, 1))
	_add_label("Instr", "Press A (left) and D (right) to keep it centred for 5 s!", Vector2(50, 52), 14, Color(0.78, 0.78, 0.78))

	var bar_bg = ColorRect.new(); bar_bg.name = "BarBg"
	bar_bg.color = Color(0.3, 0.3, 0.3); bar_bg.size = Vector2(420, 44)
	bar_bg.position = Vector2(50, 130); _panel.add_child(bar_bg)

	var safe = ColorRect.new(); safe.name = "Safe"
	safe.color = Color(0.2, 0.8, 0.2, 0.35)
	safe.size = Vector2(130, 44); safe.position = Vector2(195, 130)
	_panel.add_child(safe)

	var ind = ColorRect.new(); ind.name = "Ind"
	ind.color = Color(1, 1, 0); ind.size = Vector2(10, 54)
	ind.position = Vector2(255, 125); _panel.add_child(ind)

	_add_label("Timer", "Hold: 0.0 / 5.0s", Vector2(170, 200), 18, Color(0.7, 0.7, 0.7))
	_add_label("Result", "", Vector2(180, 270), 26, Color.WHITE)

func _tick_balance(delta):
	# Strong random drift — makes it harder to keep centred
	_bal_value += (randf() - 0.5) * 2.2 * delta
	# Additional sine-wave sway for unpredictable swinging
	_bal_value += sin(_timer * 3.5) * 0.4 * delta
	_bal_value = clamp(_bal_value, 0.0, 1.0)

	var ind = _panel.get_node_or_null("Ind")
	if ind:
		ind.position.x = 50 + _bal_value * 410

	var in_safe = _bal_value > 0.33 and _bal_value < 0.67
	if ind:
		ind.color = Color(0, 1, 0) if in_safe else Color(1, 0, 0)

	if in_safe:
		_bal_safe_time += delta
	else:
		_bal_safe_time = max(0, _bal_safe_time - delta * 0.5)

	var tl = _panel.get_node_or_null("Timer")
	if tl: tl.text = "Hold: %.1f / 5.0s" % _bal_safe_time

	if _bal_safe_time >= _bal_target_time:
		_resolve(true)
	if _timer > 15.0:
		_resolve(false)

func _input_balance(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_A:
			_bal_value = clamp(_bal_value - 0.08, 0.0, 1.0)
		elif event.keycode == KEY_D:
			_bal_value = clamp(_bal_value + 0.08, 0.0, 1.0)

# ════════════════════════════════════════════════
#  4. SIMON SAYS  (arrow-key memory)
# ════════════════════════════════════════════════
func _setup_simon_says():
	_simon_seq.clear()
	_simon_idx = 0
	_simon_showing = true
	_simon_show_i = 0
	_simon_show_t = 0.0

	var dirs = ["up", "down", "left", "right"]
	var length = 4 + randi() % 3   # 4-6
	for _i in range(length):
		_simon_seq.append(dirs[randi() % 4])

	_add_label("Title", "MEMORY CHALLENGE!", Vector2(140, 18), 22, Color(0.8, 0.35, 1))
	_add_label("Instr", "Watch the sequence, then repeat it with arrow keys!", Vector2(55, 52), 14, Color(0.78, 0.78, 0.78))
	_add_label("Dir", "Watch...", Vector2(190, 120), 34, Color(1, 1, 0.3))
	_add_label("Arrows", "", Vector2(70, 200), 28, Color(0.6, 0.6, 0.6))
	_add_label("Progress", "Sequence length: " + str(_simon_seq.size()), Vector2(160, 260), 15, Color(0.7, 0.7, 0.7))
	_add_label("Result", "", Vector2(180, 310), 26, Color.WHITE)

func _tick_simon_says(delta):
	if not _simon_showing:
		return
	_simon_show_t += delta
	if _simon_show_t >= 0.85:
		_simon_show_t = 0.0
		_simon_show_i += 1
		var dl = _panel.get_node_or_null("Dir")
		if _simon_show_i >= _simon_seq.size():
			_simon_showing = false
			if dl:
				dl.text = "Your turn!"
				dl.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
			return
		if dl:
			dl.text = _arrow_label(_simon_seq[_simon_show_i])

func _input_simon_says(event):
	if _simon_showing:
		return
	if event is InputEventKey and event.pressed:
		var dir := ""
		match event.keycode:
			KEY_UP:    dir = "up"
			KEY_DOWN:  dir = "down"
			KEY_LEFT:  dir = "left"
			KEY_RIGHT: dir = "right"
		if dir == "":
			return

		if dir == _simon_seq[_simon_idx]:
			_simon_idx += 1
			var al = _panel.get_node_or_null("Arrows")
			if al: al.text += _arrow_label(dir) + " "
			if _simon_idx >= _simon_seq.size():
				_resolve(true)
		else:
			_resolve(false)

func _arrow_label(dir: String) -> String:
	match dir:
		"up":    return "UP"
		"down":  return "DN"
		"left":  return "LT"
		"right": return "RT"
	return "?"

# ════════════════════════════════════════════════
#  5. FOOD MATCH  (sort food by colour)
# ════════════════════════════════════════════════
func _setup_food_match():
	_match_idx = 0
	_match_foods = [
		{"name": "Apple",   "color": "green"},
		{"name": "Banana",  "color": "green"},
		{"name": "Salad",   "color": "green"},
		{"name": "Granola", "color": "yellow"},
		{"name": "Juice",   "color": "yellow"},
		{"name": "Crackers","color": "yellow"},
		{"name": "Chips",   "color": "red"},
		{"name": "Candy",   "color": "red"},
		{"name": "Soda",    "color": "red"},
	]
	_match_foods.shuffle()
	_match_foods = _match_foods.slice(0, 5)

	_add_label("Title", "FOOD MATCH!", Vector2(175, 18), 22, Color(0.2, 0.92, 0.55))
	_add_label("Instr", "Press  1 = Green   2 = Yellow   3 = Red", Vector2(100, 52), 14, Color(0.78, 0.78, 0.78))

	_add_label("G", "1: Green",  Vector2(60,  82), 15, Color(0.3, 0.9, 0.3))
	_add_label("Y", "2: Yellow", Vector2(210, 82), 15, Color(0.9, 0.8, 0.2))
	_add_label("R", "3: Red",    Vector2(370, 82), 15, Color(0.9, 0.3, 0.3))

	_add_label("Food", _match_foods[0]["name"], Vector2(190, 140), 32, Color.WHITE)
	_add_label("Progress", "1 / " + str(_match_foods.size()), Vector2(220, 200), 16, Color(0.7, 0.7, 0.7))
	_add_label("Result", "", Vector2(160, 270), 26, Color.WHITE)

func _input_food_match(event):
	if event is InputEventKey and event.pressed:
		var chosen := ""
		match event.keycode:
			KEY_1: chosen = "green"
			KEY_2: chosen = "yellow"
			KEY_3: chosen = "red"
		if chosen == "":
			return

		var correct = _match_foods[_match_idx]["color"]
		if chosen == correct:
			_match_idx += 1
			if _match_idx >= _match_foods.size():
				_resolve(true)
				return
			var fl = _panel.get_node_or_null("Food")
			if fl: fl.text = _match_foods[_match_idx]["name"]
			var pl = _panel.get_node_or_null("Progress")
			if pl: pl.text = str(_match_idx + 1) + " / " + str(_match_foods.size())
			var rl = _panel.get_node_or_null("Result")
			if rl:
				rl.text = "Correct!"
				rl.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		else:
			_resolve(false)

# ──────────────────────────────────────────────
#  RESOLVE & CLEANUP
# ──────────────────────────────────────────────
func _resolve(success: bool):
	if _resolved:
		return
	_resolved = true

	var rl = _panel.get_node_or_null("Result")
	if rl:
		if success:
			rl.text = "SUCCESS!"
			rl.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		else:
			rl.text = "FAILED!"
			rl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

	# Small delay, then close
	await get_tree().create_timer(1.0).timeout
	_panel.visible = false
	active = false
	emit_signal("mini_game_finished", success)

# ──────────────────────────────────────────────
#  HELPERS
# ──────────────────────────────────────────────
func _clear_panel():
	for c in _panel.get_children():
		c.queue_free()

func _add_label(node_name: String, text: String, pos: Vector2, size: int, col: Color):
	var lbl = Label.new()
	lbl.name = node_name
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", col)
	_panel.add_child(lbl)
