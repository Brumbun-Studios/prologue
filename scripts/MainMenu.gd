extends CanvasLayer

signal play_pressed

@onready var play_button = %PlayButton
@onready var exit_button = %ExitButton

func _ready():
	# Ensure the menu is visible when the game starts
	show()
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	# Grab focus for keyboard/controller support
	play_button.grab_focus()

func _on_play_pressed():
	play_pressed.emit()
	hide() # Close the menu

func _on_exit_pressed():
	get_tree().quit()
