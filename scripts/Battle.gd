extends CanvasLayer
signal battle_finished

@export var player_marker: Marker2D
@export var enemy_marker: Marker2D

@onready var player_hp_bar = %PlayerHP
@onready var enemy_hp_bar = %EnemyHP
@onready var action_menu = %NinePatchRect
@onready var skill_box = %SkillBox # Your new subbox

# Main Buttons
@onready var attack_button = %AttackButton
@onready var skill_button = %SkillButton
@onready var run_button = %RunButton

# Skill Buttons
@onready var fire_btn = %FireButton
@onready var water_btn = %WaterButton
@onready var earth_btn = %EarthButton
@onready var wind_btn = %WindButton

var player_hp = 100
var enemy_hp = 50
var player_sprite: Sprite2D
var enemy_sprite: Sprite2D

enum State { PLAYER_TURN, ENEMY_TURN, BUSY, WON, LOST }
var current_state = State.PLAYER_TURN

func _ready():
	hide()
	# Connect Main Buttons
	attack_button.pressed.connect(_on_attack_pressed)
	skill_button.pressed.connect(_on_skill_menu_opened)
	run_button.pressed.connect(_on_run_pressed)
	
	# Connect Elemental Buttons
	fire_btn.pressed.connect(func(): _use_skill("Fire", 40, Color.ORANGE_RED))
	water_btn.pressed.connect(func(): _use_skill("Water", 30, Color.AQUA))
	earth_btn.pressed.connect(func(): _use_skill("Earth", 50, Color.SADDLE_BROWN))
	wind_btn.pressed.connect(func(): _use_skill("Wind", 25, Color.PALE_TURQUOISE))

func _use_skill(skill_name: String, damage: int, effect_color: Color):
	current_state = State.BUSY
	skill_box.hide()
	
	print("Using ", skill_name, "!")
	
	# Snappy Persona-style flash effect
	var flash = create_tween()
	flash.tween_property(enemy_sprite, "modulate", effect_color, 0.1)
	flash.tween_property(enemy_sprite, "modulate", Color.WHITE, 0.1)
	
	# Attack Lunge
	var lunge = create_tween()
	lunge.tween_property(player_sprite, "position", enemy_sprite.position, 0.15)
	lunge.tween_property(player_sprite, "position", player_marker.position, 0.15)
	
	await lunge.finished
	
	enemy_hp -= damage
	enemy_hp_bar.value = enemy_hp
	
	if enemy_hp <= 0:
		_end_battle(true)
	else:
		current_state = State.ENEMY_TURN
		_enemy_turn()
		
func _on_skill_menu_opened():
	if current_state != State.PLAYER_TURN: return
	action_menu.hide()
	skill_box.show()
	fire_btn.grab_focus() # Good for controller/keyboard support

func _input(event):
	# Allow backing out of the skill menu with "ui_cancel" (Escape/B button)
	if event.is_action_pressed("ui_cancel") and skill_box.visible:
		skill_box.hide()
		action_menu.show()
		skill_button.grab_focus()
		
func start_battle(enemy_node):
	show()
	player_hp = 100
	enemy_hp = 50
	current_state = State.PLAYER_TURN
	action_menu.show()
	
	player_hp_bar.max_value = 100
	player_hp_bar.value = player_hp
	enemy_hp_bar.max_value = 50
	enemy_hp_bar.value = enemy_hp
	
	_spawn_combatants(enemy_node)

func _spawn_combatants(enemy_node):
	player_sprite = Sprite2D.new()
	player_sprite.texture = load("res://assets/Player.png")
	player_sprite.hframes = 6
	player_sprite.vframes = 10
	player_sprite.scale = Vector2(4, 4)
	add_child(player_sprite)
	player_sprite.global_position = player_marker.global_position
	
	enemy_sprite = Sprite2D.new()
	var overworld_sprite = enemy_node.get_node("Sprite2D")
	enemy_sprite.texture = overworld_sprite.texture
	enemy_sprite.hframes = overworld_sprite.hframes
	enemy_sprite.vframes = overworld_sprite.vframes
	enemy_sprite.scale = Vector2(4, 4)
	enemy_sprite.flip_h = true
	add_child(enemy_sprite)
	enemy_sprite.global_position = enemy_marker.global_position

# --- COMBAT LOGIC ---
func _on_attack_pressed():
	if current_state != State.PLAYER_TURN: return
	current_state = State.BUSY
	action_menu.hide()
	
	var tween = create_tween()
	tween.tween_property(player_sprite, "position", enemy_sprite.position, 0.2)
	tween.tween_property(player_sprite, "position", player_marker.position, 0.2)
	await tween.finished
	
	enemy_hp -= 20
	enemy_hp_bar.value = enemy_hp
	
	if enemy_hp <= 0:
		_end_battle(true)
	else:
		current_state = State.ENEMY_TURN
		_enemy_turn()

func _on_skill_pressed():
	if current_state != State.PLAYER_TURN: return
	current_state = State.BUSY
	action_menu.hide()
	
	# Skill does more damage (35) but could have a cooldown or MP cost later
	var tween = create_tween()
	# Slightly faster lunge to sell the "power attack" feel
	tween.tween_property(player_sprite, "position", enemy_sprite.position, 0.15)
	tween.tween_property(player_sprite, "position", player_marker.position, 0.15)
	await tween.finished
	
	enemy_hp -= 35
	enemy_hp_bar.value = enemy_hp
	
	if enemy_hp <= 0:
		_end_battle(true)
	else:
		current_state = State.ENEMY_TURN
		_enemy_turn()

func _on_run_pressed():
	if current_state != State.PLAYER_TURN: return
	current_state = State.BUSY
	action_menu.hide()
	
	# 50/50 chance to escape
	if randf() > 0.5:
		print("You escaped!")
		await get_tree().create_timer(1.0).timeout
		# Cleanup sprites but don't kill the enemy
		for child in get_children():
			if child is Sprite2D: child.queue_free()
		hide()
		battle_finished.emit()
	else:
		print("Failed to escape!")
		# Failed — enemy gets a free hit, then it's your turn again
		current_state = State.ENEMY_TURN
		_enemy_turn()

func _enemy_turn():
	await get_tree().create_timer(1.0).timeout
	
	var tween = create_tween()
	tween.tween_property(enemy_sprite, "position", player_sprite.position, 0.2)
	tween.tween_property(enemy_sprite, "position", enemy_marker.position, 0.2)
	await tween.finished
	
	player_hp -= 15
	player_hp_bar.value = player_hp
	
	if player_hp <= 0:
		_end_battle(false)
	else:
		current_state = State.PLAYER_TURN
		action_menu.show()

func _end_battle(won: bool):
	if won:
		print("You won!")
	else:
		print("Game Over")
	
	await get_tree().create_timer(1.5).timeout
	
	for child in get_children():
		if child is Sprite2D: child.queue_free()
		
	hide()
	battle_finished.emit()
