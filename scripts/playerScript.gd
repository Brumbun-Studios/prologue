extends CharacterBody2D

@export var base_speed: float = 150.0
@export var grass_speed: float = 100.0
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D

var tilemap: TileMapLayer
var is_talking: bool = false

func _ready():
	# Find the TileMapLayer that has group "map" — it lives inside Level001
	var maps = get_tree().get_nodes_in_group("map")
	for node in maps:
		if node is TileMapLayer:
			tilemap = node
			break
	if not tilemap:
		print("Warning: Player couldn't find a TileMapLayer in group 'map'!")

func _input(event):
	if event.is_action_pressed("ui_accept") and not is_talking:
		check_for_interactables()

func check_for_interactables():
	var interactables = get_tree().get_nodes_in_group("interactable")
	for npc in interactables:
		if not npc is Node2D:
			continue
		if global_position.distance_to(npc.global_position) < 50:
			start_dialogue(npc)
			return

func start_dialogue(npc):
	is_talking = true
	velocity = Vector2.ZERO
	set_physics_process(false)

	if npc.has_method("interact"):
		npc.is_wandering = false
		npc.interact()

	var ui = get_tree().get_first_node_in_group("dialog_ui")
	if ui:
		if not ui.dialogue_finished.is_connected(_on_dialogue_finished):
			ui.dialogue_finished.connect(_on_dialogue_finished.bind(npc), CONNECT_ONE_SHOT)

func _on_dialogue_finished(npc):
	is_talking = false
	set_physics_process(true)
	if npc and "is_wandering" in npc:
		npc.is_wandering = true

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var current_speed = base_speed

	if tilemap:
		var tile_pos = tilemap.local_to_map(tilemap.to_local(global_position))
		var data = tilemap.get_cell_tile_data(tile_pos)
		if data:
			var terrain = data.get_custom_data("terrain_type")
			if terrain == "grass":
				current_speed = grass_speed

	if direction:
		velocity = direction * current_speed
		update_animation(direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, current_speed)
		animation_player.play("idle")
	move_and_slide()

func update_animation(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		animation_player.play("walk_side")
		sprite.flip_h = (dir.x < 0)
	else:
		sprite.flip_h = false
		if dir.y > 0:
			animation_player.play("walk_down")
		else:
			animation_player.play("walk_up")
