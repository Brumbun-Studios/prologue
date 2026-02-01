extends CharacterBody2D

@export var wander_speed: float = 50.0
@export var idle_time_min: float = 1.5
@export var idle_time_max: float = 4.0
@export var walk_time_min: float = 1.0
@export var walk_time_max: float = 3.0

var move_direction: Vector2 = Vector2.ZERO
var is_wandering: bool = true

@onready var timer = Timer.new()
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D

enum State { IDLE, WALKING }
var current_state = State.IDLE

func _ready():
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	start_idle()

func interact():
	var ui = get_tree().get_first_node_in_group("dialog_ui") 
	
	ui.start_conversation(
		"Mbah Brumbun", 
		"Selamat siang, Le. The spirits of the Brumbun woods are active today. Will you offer them incense?", 
		["I will offer it.", "I have no time."]
	)

	var choice = await ui.choice_selected
	if choice == 0:
		ui.start_conversation("Mbah Brumbun", "A wise choice. The forest remembers respect.")
	else:
		ui.start_conversation("Mbah Brumbun", "Then walk carefully. Some paths do not like being ignored.")

func _physics_process(_delta):
	if is_wandering:
		if current_state == State.WALKING:
			velocity = move_direction * wander_speed
			move_and_slide()
			update_animation(move_direction)
		else:
			velocity = Vector2.ZERO
			if animation_player:
				animation_player.play("idle")

func start_idle():
	current_state = State.IDLE
	move_direction = Vector2.ZERO
	if animation_player:
		animation_player.play("idle")
	timer.wait_time = randf_range(idle_time_min, idle_time_max)
	timer.start()

func start_walking():
	current_state = State.WALKING
	# Pick one of 4 cardinal directions or 4 diagonal directions
	var directions = [
		Vector2.RIGHT,      # East
		Vector2.LEFT,       # West
		Vector2.DOWN,       # South
		Vector2.UP,         # North
		Vector2(1, 1).normalized(),   # Southeast
		Vector2(-1, 1).normalized(),  # Southwest
		Vector2(1, -1).normalized(),  # Northeast
		Vector2(-1, -1).normalized()  # Northwest
	]
	move_direction = directions[randi() % directions.size()]
	timer.wait_time = randf_range(walk_time_min, walk_time_max)
	timer.start()

func _on_timer_timeout():
	if current_state == State.IDLE:
		# 70% chance to walk, 30% to stay idle
		if randf() > 0.3:
			start_walking()
		else:
			start_idle()
	else:
		# After walking, always idle
		start_idle()

func update_animation(dir: Vector2):
	if not animation_player:
		return
		
	# Same animation logic as player
	if abs(dir.x) > abs(dir.y):
		animation_player.play("walk_side")
		sprite.flip_h = (dir.x < 0)
	else:
		sprite.flip_h = false
		if dir.y > 0:
			animation_player.play("walk_down")
		else:
			animation_player.play("walk_up")
