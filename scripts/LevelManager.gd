extends Node
# =============================================================================
# LevelManager.gd
#
# Autoload singleton that tracks which level the player is on and how many
# enemies they've killed on the current level. Main.gd calls into this to
# decide what to do after each battle.
#
# HOW TO INSTALL:
#   Project → Project Settings → Autoload → Add
#   Node Name : LevelManager
#   Path      : res://scripts/LevelManager.gd
# =============================================================================

# ── Level definitions ─────────────────────────────────────────────────────────
# Add a new entry here whenever you create a new level scene.
# "scene"         : path to the level's .tscn file (loaded into $Node2D)
# "enemies_to_win": how many badSlimes must die before we advance
# "player_spawn"  : where the player appears when this level loads
const LEVELS: Array[Dictionary] = [
	{
		"scene":          "res://Scenes/level_001.tscn",
		"enemies_to_win": 1,
		"player_spawn":   Vector2(57, 62)
	},
	{
		"scene":          "res://Scenes/level_002.tscn",
		"enemies_to_win": 2,
		"player_spawn":   Vector2(60, 60)
	},
	# ── ADD MORE LEVELS HERE ──────────────────────────────────────────────────
	# {
	#     "scene":          "res://Scenes/level_003.tscn",
	#     "enemies_to_win": 3,
	#     "player_spawn":   Vector2(100, 100)
	# },
]

# ── State ─────────────────────────────────────────────────────────────────────
var current_level_index: int = 0
var enemies_defeated_this_level: int = 0

# ── Helpers ───────────────────────────────────────────────────────────────────
func get_current_level_data() -> Dictionary:
	return LEVELS[current_level_index]

func get_current_scene_path() -> String:
	return LEVELS[current_level_index]["scene"]

func get_enemies_to_win() -> int:
	return LEVELS[current_level_index]["enemies_to_win"]

func get_player_spawn() -> Vector2:
	return LEVELS[current_level_index]["player_spawn"]

func is_last_level() -> bool:
	return current_level_index >= LEVELS.size() - 1

func register_enemy_killed() -> bool:
	# Returns true if the level is now complete (all enemies dead)
	enemies_defeated_this_level += 1
	return enemies_defeated_this_level >= get_enemies_to_win()

func advance_to_next_level():
	current_level_index += 1
	enemies_defeated_this_level = 0

func reset():
	current_level_index = 0
	enemies_defeated_this_level = 0
