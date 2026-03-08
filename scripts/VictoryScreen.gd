extends CanvasLayer
# ──────────────────────────────────────────────────────────────────────────────
# VictoryScreen.gd
#
# Scene setup required:
#   VictoryScreen (CanvasLayer) — this script
#     └─ Panel (or ColorRect, whatever background you like)
#          ├─ VBoxContainer
#          │    ├─ Label      (Name: "TitleLabel")        text: "✨ VICTORY! ✨"
#          │    ├─ Label      (Name: "SubLabel")          text: "You conquered all enemies!"
#          │    ├─ Button     (Name: "PlayAgainButton")   text: "Play Again"
#          │    └─ Button     (Name: "QuitButton")        text: "Quit"
# ──────────────────────────────────────────────────────────────────────────────

@onready var play_again_button = %PlayAgainButton
@onready var quit_button       = %QuitButton

func _ready():
	hide()
	play_again_button.pressed.connect(_on_play_again)
	quit_button.pressed.connect(_on_quit)

func show_victory():
	show()
	play_again_button.grab_focus()

func _on_play_again():
	hide()
	# Tell Main to restart
	var main = get_tree().root.get_node("Main")
	if main and main.has_method("restart_game"):
		main.restart_game()

func _on_quit():
	get_tree().quit()
