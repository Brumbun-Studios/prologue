extends CharacterBody2D

@export var speed: float = 150.0
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D

func _physics_process(_delta: float) -> void:
	# Get input
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction:
		velocity = direction * speed
		update_animation(direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		animation_player.play("idle") # Or animation_player.stop()

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
