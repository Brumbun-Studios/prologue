extends CanvasLayer

signal battle_won
signal battle_lost
signal battle_fled # <--- NEW SIGNAL

@export var player_marker: Marker2D
@export var enemy_marker: Marker2D

@onready var player_hp_bar = %PlayerHP
@onready var enemy_hp_bar = %EnemyHP
@onready var action_menu = %NinePatchRect
@onready var skill_box = %SkillBox
@onready var battle_message = $BottomMenuArea/BattleMessage 

@onready var attack_button = %AttackButton
@onready var skill_button = %SkillButton
@onready var run_button = %RunButton

@onready var fire_btn = %FireButton
@onready var water_btn = %WaterButton
@onready var earth_btn = %EarthButton
@onready var wind_btn = %WindButton

var enemy_hp = 50
var player_sprite: Sprite2D
var enemy_sprite: Sprite2D

enum State { PLAYER_TURN, ENEMY_TURN, BUSY, WON, LOST }
var current_state = State.PLAYER_TURN

enum Element { FIRE, WATER, EARTH, WIND }
var enemy_element: Element

var element_colors = {
	Element.FIRE: Color.ORANGE_RED,
	Element.WATER: Color.DODGER_BLUE,
	Element.EARTH: Color.SADDLE_BROWN,
	Element.WIND: Color.PALE_TURQUOISE
}
var element_names = {
	Element.FIRE: "Fire", Element.WATER: "Water",
	Element.EARTH: "Earth", Element.WIND: "Wind"
}

var skills = {
	"Fire":  { "dmg": 40, "cost": 10, "elem": Element.FIRE },
	"Water": { "dmg": 30, "cost": 5,  "elem": Element.WATER },
	"Earth": { "dmg": 50, "cost": 15, "elem": Element.EARTH },
	"Wind":  { "dmg": 25, "cost": 8,  "elem": Element.WIND }
}

func _ready():
	hide()
	attack_button.pressed.connect(_on_attack_pressed)
	skill_button.pressed.connect(_on_skill_menu_opened)
	run_button.pressed.connect(_on_run_pressed)

	fire_btn.pressed.connect(func(): _use_skill("Fire"))
	water_btn.pressed.connect(func(): _use_skill("Water"))
	earth_btn.pressed.connect(func(): _use_skill("Earth"))
	wind_btn.pressed.connect(func(): _use_skill("Wind"))
	
	fire_btn.text = "Fire (10 MP)"
	water_btn.text = "Water (5 MP)"
	earth_btn.text = "Earth (15 MP)"
	wind_btn.text = "Wind (8 MP)"

func _update_message(text: String):
	if battle_message: battle_message.text = text

func start_battle(enemy_node):
	show()
	current_state = State.PLAYER_TURN
	enemy_hp = 50
	enemy_element = randi() % 4 as Element
	
	player_hp_bar.max_value = PlayerManager.max_hp
	player_hp_bar.value = PlayerManager.hp
	enemy_hp_bar.max_value = 50
	enemy_hp_bar.value = enemy_hp

	_spawn_combatants(enemy_node)

	_update_message("A wild %s Slime appears!\nHP: %d | MP: %d" % [element_names[enemy_element], PlayerManager.hp, PlayerManager.mp])
	action_menu.show()
	skill_box.hide()
	attack_button.grab_focus()

func _spawn_combatants(enemy_node):
	for child in get_children():
		if child is Sprite2D: child.queue_free()

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
	enemy_sprite.modulate = element_colors[enemy_element]

func _get_multiplier(atk_elem: Element, def_elem: Element) -> float:
	if atk_elem == Element.WATER and def_elem == Element.FIRE: return 2.0
	if atk_elem == Element.FIRE and def_elem == Element.EARTH: return 2.0
	if atk_elem == Element.EARTH and def_elem == Element.WIND: return 2.0
	if atk_elem == Element.WIND and def_elem == Element.WATER: return 2.0

	if atk_elem == Element.FIRE and def_elem == Element.WATER: return 0.5
	if atk_elem == Element.EARTH and def_elem == Element.FIRE: return 0.5
	if atk_elem == Element.WIND and def_elem == Element.EARTH: return 0.5
	if atk_elem == Element.WATER and def_elem == Element.WIND: return 0.5
	return 1.0

func _use_skill(skill_name: String):
	if current_state != State.PLAYER_TURN: return
	
	var data = skills[skill_name]
	if PlayerManager.mp < data.cost:
		_update_message("Not enough MP! Need %d." % data.cost)
		return
		
	PlayerManager.mp -= data.cost
	PlayerManager.stats_changed.emit()

	current_state = State.BUSY
	skill_box.hide()

	var mult = _get_multiplier(data.elem, enemy_element)
	var final_damage = int(data.dmg * mult)

	if mult > 1.0: _update_message("Used %s! It's super effective!" % skill_name)
	elif mult < 1.0: _update_message("Used %s... It's not very effective." % skill_name)
	else: _update_message("Used %s!" % skill_name)

	var flash = create_tween()
	flash.tween_property(enemy_sprite, "modulate", Color.WHITE, 0.1)
	flash.tween_property(enemy_sprite, "modulate", element_colors[enemy_element], 0.1)

	var lunge = create_tween()
	lunge.tween_property(player_sprite, "position", enemy_sprite.position, 0.15)
	lunge.tween_property(player_sprite, "position", player_marker.position, 0.15)
	await lunge.finished

	enemy_hp -= final_damage
	enemy_hp_bar.value = enemy_hp

	if enemy_hp <= 0: _end_battle(true)
	else:
		current_state = State.ENEMY_TURN
		_enemy_turn()

func _on_skill_menu_opened():
	if current_state != State.PLAYER_TURN: return
	action_menu.hide()
	skill_box.show()
	fire_btn.grab_focus()
	_update_message("Select a skill to use.")

func _input(event):
	if event.is_action_pressed("ui_cancel") and skill_box.visible:
		skill_box.hide()
		action_menu.show()
		skill_button.grab_focus()
		_update_message("What will you do?\nHP: %d | MP: %d" % [PlayerManager.hp, PlayerManager.mp])

func _on_attack_pressed():
	if current_state != State.PLAYER_TURN: return
	current_state = State.BUSY
	action_menu.hide()
	
	_update_message("You attacked the slime!")
	var tween = create_tween()
	tween.tween_property(player_sprite, "position", enemy_sprite.position, 0.2)
	tween.tween_property(player_sprite, "position", player_marker.position, 0.2)
	await tween.finished

	enemy_hp -= 20
	enemy_hp_bar.value = enemy_hp

	if enemy_hp <= 0: _end_battle(true)
	else:
		current_state = State.ENEMY_TURN
		_enemy_turn()

func _on_run_pressed():
	if current_state != State.PLAYER_TURN: return
	current_state = State.BUSY
	action_menu.hide()
	
	_update_message("You try to run away...")
	await get_tree().create_timer(1.0).timeout

	if randf() > 0.5:
		_update_message("Got away safely!")
		await get_tree().create_timer(1.0).timeout
		_cleanup_sprites()
		hide()
		battle_fled.emit() # <--- NOW IT EMITS FLED INSTEAD OF WON
	else:
		_update_message("Failed to escape!")
		current_state = State.ENEMY_TURN
		_enemy_turn()

func _enemy_turn():
	await get_tree().create_timer(1.0).timeout
	_update_message("The enemy slime attacks!")

	var tween = create_tween()
	tween.tween_property(enemy_sprite, "position", player_sprite.position, 0.2)
	tween.tween_property(enemy_sprite, "position", enemy_marker.position, 0.2)
	await tween.finished

	PlayerManager.take_damage(15)
	player_hp_bar.value = PlayerManager.hp

	if PlayerManager.hp <= 0: _end_battle(false)
	else:
		current_state = State.PLAYER_TURN
		action_menu.show()
		attack_button.grab_focus()
		_update_message("What will you do?\nHP: %d | MP: %d" % [PlayerManager.hp, PlayerManager.mp])

func _end_battle(won: bool):
	current_state = State.WON if won else State.LOST
	if won: _update_message("You won the battle!")
	else: _update_message("You were defeated...")
		
	await get_tree().create_timer(1.5).timeout
	_cleanup_sprites()
	hide()

	if won: battle_won.emit()
	else: battle_lost.emit()

func _cleanup_sprites():
	for child in get_children():
		if child is Sprite2D: child.queue_free()
