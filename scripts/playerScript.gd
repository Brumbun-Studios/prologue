extends CharacterBody2D
@export var base_speed: float = 150.0
@export var grass_speed: float = 100.0 # Half speed in grass
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@export var tilemap: TileMapLayer

func _input(event):
	if event.is_action_pressed("ui_accept"): # "ui_accept" is usually Space/Enter
		check_for_interactables()

func check_for_interactables():
	# Find all Area2Ds overlapping the player
	# Better yet, use a dedicated RayCast2D pointing in the direction the player faces
	var interactables = get_tree().get_nodes_in_group("interactable")
	for npc in interactables:
		# Skip if not a Node2D (avoids UI elements like CanvasLayer)
		if not npc is Node2D:
			continue
		if global_position.distance_to(npc.global_position) < 50:
			start_dialogue(npc)

func start_dialogue(npc):
	print("Talking to: ", npc.name)
	# 1. Freeze the Player
	velocity = Vector2.ZERO
	set_physics_process(false) 
	
	# 2. Safely Freeze the NPC
	if "is_wandering" in npc:
		npc.is_wandering = false
	
	npc.set("is_wandering", false)

func _ready():
	tilemap = get_tree().get_first_node_in_group("map")
	
	if not tilemap:
		print("Warning: Player couldn't find a TileMapLayer in group 'map'!")

func _physics_process(_delta: float) -> void:
	# Always check if the tilemap is actually assigned to avoid crashes
	if not tilemap:
		return
		
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 1. Check the terrain under the player's FEET
	var current_speed = base_speed
	
	# We use global_position to find where the player is in the world
	var tile_pos = tilemap.local_to_map(tilemap.to_local(global_position))
	var data = tilemap.get_cell_tile_data(tile_pos)
	
	if data:
		var terrain = data.get_custom_data("terrain_type")
		if terrain == "grass":
			current_speed = grass_speed;
	
	# 2. Apply movement
	if direction:
		velocity = direction * current_speed
		update_animation(direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, current_speed)
		animation_player.play("idle")
	move_and_slide()

func update_animation(dir: Vector2):
	# Determine the animation name based on direction
	if abs(dir.x) > abs(dir.y):
		# Moving horizontally (Left or Right)
		animation_player.play("walk_side")
		
		# If moving right (dir.x > 0), flip_h is false (assuming original faces right)
		# If moving left (dir.x < 0), flip_h is true.
		sprite.flip_h = (dir.x < 0) 
	else:
		# Moving vertically
		# We reset flip_h to false so up/down animations don't look mirrored
		sprite.flip_h = false
		
		if dir.y > 0:
			animation_player.play("walk_down")
		else:
			animation_player.play("walk_up")
