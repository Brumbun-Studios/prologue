extends Node2D

@onready var main_menu   = $MainMenu
@onready var world       = $Node2D
@onready var battle_ui   = $BattleUI
@onready var victory_ui  = $VictoryScreen
@onready var gameover_ui = $GameOverScreen

@onready var dialogue_ui = $DialogueUI
@onready var overworld_ui = $OverworldUI 

const LEVELS: Array = [
	{ "scene": "res://Scenes/level_001_with_cave.tscn", "enemies_to_win": 1, "player_spawn": Vector2(57, 62) },
	{ "scene": "res://Scenes/level_002.tscn", "enemies_to_win": 2, "player_spawn": Vector2(60, 60) },
]

var _level_index:    int = 0
var _enemies_killed: int = 0
var _current_battle_won_callable: Callable # Used to safely track signals

func _ready():
	world.hide()
	victory_ui.hide()
	gameover_ui.hide()
	
	if overworld_ui: overworld_ui.hide()
		
	main_menu.play_pressed.connect(_start_game)
	
	# Hook up our custom, ironclad signals!
	if dialogue_ui:
		dialogue_ui.dialogue_opened.connect(_on_dialogue_opened)
		dialogue_ui.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_opened():
	if overworld_ui:
		overworld_ui.hide()

func _on_dialogue_finished():
	# Only restore the HUD if the actual overworld is currently active
	if overworld_ui and world.visible:
		overworld_ui.show()

func _start_game():
	_level_index    = 0
	_enemies_killed = 0
	
	# Fully heal player when starting a new game
	PlayerManager.hp = PlayerManager.max_hp
	PlayerManager.mp = PlayerManager.max_mp
	PlayerManager.stats_changed.emit()
	
	_load_level(0)
	if overworld_ui: overworld_ui.show()

func restart_game():
	# Fully heal player when hitting "Try Again"
	PlayerManager.hp = PlayerManager.max_hp
	PlayerManager.mp = PlayerManager.max_mp
	PlayerManager.stats_changed.emit()
	
	get_tree().reload_current_scene()

func _load_level(index: int):
	for child in world.get_children(): child.queue_free()
	await get_tree().process_frame

	var data = LEVELS[index]
	world.add_child(load(data["scene"]).instantiate())

	var player      = load("res://Scenes/Player.tscn").instantiate()
	player.position = data["player_spawn"]
	world.add_child(player)
	world.show()

func travel_to_zone(target_scene: String, spawn_name: String):
	for child in world.get_children(): child.queue_free()
	await get_tree().process_frame

	var zone = load(target_scene).instantiate()
	world.add_child(zone)

	var spawn_pos = Vector2(60, 60)
	var marker    = zone.get_node_or_null(spawn_name)
	if marker: spawn_pos = marker.global_position

	var player      = load("res://Scenes/Player.tscn").instantiate()
	player.position = spawn_pos
	world.add_child(player)
	world.show()

func enter_battle(enemy_node):
	world.hide()
	
	# Hide all Overworld & Dialogue HUDs to guarantee a clean battle screen
	if overworld_ui: overworld_ui.hide()
	if dialogue_ui: dialogue_ui.hide() 
		
	_disconnect_battle_signals()

	battle_ui.start_battle(enemy_node)

	_current_battle_won_callable = _on_battle_won.bind(enemy_node)
	battle_ui.battle_won.connect(_current_battle_won_callable)
	battle_ui.battle_lost.connect(_on_battle_lost)
	battle_ui.battle_fled.connect(_on_battle_fled)

func _disconnect_battle_signals():
	if _current_battle_won_callable and battle_ui.battle_won.is_connected(_current_battle_won_callable):
		battle_ui.battle_won.disconnect(_current_battle_won_callable)
	if battle_ui.battle_lost.is_connected(_on_battle_lost):
		battle_ui.battle_lost.disconnect(_on_battle_lost)
	if battle_ui.battle_fled.is_connected(_on_battle_fled):
		battle_ui.battle_fled.disconnect(_on_battle_fled)

func _on_battle_won(enemy_node):
	if is_instance_valid(enemy_node): enemy_node.queue_free()

	_unlock_player()
	_enemies_killed += 1

	if _enemies_killed >= LEVELS[_level_index]["enemies_to_win"]:
		if _level_index >= LEVELS.size() - 1:
			victory_ui.show_victory()
			if overworld_ui: overworld_ui.hide()
		else:
			_level_index    += 1
			_enemies_killed  = 0
			_load_level(_level_index)
			if overworld_ui: overworld_ui.show() # <--- BUG FIXED HERE!
	else:
		world.show()
		if overworld_ui: overworld_ui.show()

func _on_battle_lost():
	_unlock_player()
	gameover_ui.show_gameover()
	if overworld_ui: overworld_ui.hide()

func _on_battle_fled():
	# If you run, you just return to the map. No kills counted!
	_unlock_player()
	world.show()
	if overworld_ui: overworld_ui.show()

func _unlock_player():
	var player = world.get_node_or_null("Player")
	if not player:
		for child in world.get_children():
			if child is CharacterBody2D:
				player = child
				break
	if player:
		player.is_talking = false
		player.set_physics_process(true)
