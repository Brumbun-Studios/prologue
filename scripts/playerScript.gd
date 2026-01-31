extends CharacterBody2D

@export var base_speed: float = 150.0
@export var grass_speed: float = 100.0 # Half speed in grass

@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@export var tilemap: TileMapLayer

func _ready():
	# This searches the whole game for the first node tagged "map"
	tilemap = get_tree().get_first_node_in_group("map")

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
