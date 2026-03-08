extends CanvasLayer
# ──────────────────────────────────────────────────────────────────────────────
# GameOver.gd
#
# Scene setup required:
#   GameOverScreen (CanvasLayer) — this script
#     └─ Panel (or ColorRect)
#          ├─ VBoxContainer
#          │    ├─ Label      (Name: "TitleLabel")        text: "💀 GAME OVER 💀"
#          │    ├─ Label      (Name: "SubLabel")          text: "You were defeated..."
#          │    ├─ Button     (Name: "PlayAgainButton")   text: "Try Again"
#          │    └─ Button     (Name: "QuitButton")        text: "Quit"
# ──────────────────────────────────────────────────────────────────────────────

@onready var play_again_button = %PlayAgainButton
@onready var quit_button       = %QuitButton

func _ready():
	hide()
	play_again_button.pressed.connect(_on_play_again)
	quit_button.pressed.connect(_on_quit)

func show_gameover():
	show()
	play_again_button.grab_focus()

func _on_play_again():
	hide()
	var main = get_tree().root.get_node("Main")
	if main and main.has_method("restart_game"):
		main.restart_game()

func _on_quit():
	get_tree().quit()
