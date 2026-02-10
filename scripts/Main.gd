extends Node2D # Main is usually a Node2D

@onready var main_menu = $MainMenu
@onready var world = $Node2D # Your overworld container
@onready var battle_ui = $BattleUI # The CanvasLayer child
func _ready():
	# Start the game with the overworld hidden
	world.hide()
	
	# Connect the play signal
	main_menu.play_pressed.connect(_start_game)

func _start_game():
	world.show()
	# Optional: Play a "Game Start" sound or fade-in transition
	
func enter_battle(enemy_node):
	# 1. Freeze the overworld
	world.hide()
	
	# 2. Start the battle in the child scene
	battle_ui.start_battle(enemy_node)
	
	# 3. Listen for when the fight ends
	if not battle_ui.battle_finished.is_connected(_on_battle_won):
		battle_ui.battle_finished.connect(_on_battle_won.bind(enemy_node), CONNECT_ONE_SHOT)

func _on_battle_won(enemy_node):
	world.show()
	if is_instance_valid(enemy_node):
		enemy_node.queue_free()
	
	# Reset the player state
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.is_talking = false
		player.set_physics_process(true)
