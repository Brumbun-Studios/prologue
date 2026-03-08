extends Area2D
# ============================================================
# ZoneTransition.gd
# Place this on any Area2D. Set the exports in the Inspector.
# The player walks in and presses E (or ui_accept) to travel.
# ============================================================

@export var target_scene:     String = ""   # e.g. "res://Scenes/level_003.tscn"
@export var spawn_point_name: String = ""   # Marker2D name inside target_scene
@export var prompt_text:      String = "[ E ] Enter"

var _player_inside: bool = false
var _prompt:        Label = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_prompt = Label.new()
	_prompt.text = prompt_text
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 12)
	_prompt.position = Vector2(-40, -28)
	_prompt.hide()
	add_child(_prompt)

func _on_body_entered(body):
	if body is CharacterBody2D:
		_player_inside = true
		_prompt.show()

func _on_body_exited(body):
	if body is CharacterBody2D:
		_player_inside = false
		_prompt.hide()

func _unhandled_input(event):
	if not _player_inside:
		return
	if event.is_action_pressed("ui_accept") or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		if target_scene != "":
			get_tree().root.get_node("Main").travel_to_zone(target_scene, spawn_point_name)
