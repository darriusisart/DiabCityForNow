extends Area3D

@export var reward_xp := 10
@export var morning_anim := "DarkMale_ShortJump"
@export var evening_anim := "DarkMale_ShortJump"
@export var stretch_seconds := 7.0
var _stretch_in_progress := false

func _ready() -> void:
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _is_evening() -> bool:
	var df: Node = Data.day_flow()
	return df != null and df.completed_steps.has("store")

func _prompt() -> String:
	if _is_evening():
		return "Press E for evening yoga (gentle flow)"
	return "Press E for morning tai chi (slow stretches)"

func _on_body_entered(body: Node) -> void:
	if body.has_method("set_interactable"):
		body.set_interactable(self, _prompt())

func _on_body_exited(body: Node) -> void:
	if body.has_method("clear_interactable"):
		body.clear_interactable(self)

func interact(player: Node) -> void:
	if _stretch_in_progress:
		return
	_stretch_in_progress = true
	var evening := _is_evening()
	var anim := evening_anim if evening else morning_anim
	if player.has_method("play_stretch_session"):
		await player.play_stretch_session(anim, stretch_seconds)
	var pl: Node = Data.pillars()
	if pl != null and pl.has_method("add_xp"):
		var pillar_key := "wellbeing" if evening else "exercise"
		pl.add_xp(pillar_key, reward_xp, "home_stretch")
	_stretch_in_progress = false
