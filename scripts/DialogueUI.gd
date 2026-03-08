extends CanvasLayer

signal dialogue_finished
signal choice_selected(index: int)
signal dialogue_opened 

@onready var content_label = %DialogueContent
@onready var name_label = %SpeakerName
@onready var choice_container = %ChoiceContainer

var rustic_button_style: StyleBoxFlat
var rustic_hover_style: StyleBoxFlat

func _ready():
	hide() 
	if content_label:
		content_label.visible_characters = 0
		
	# Programmatically create the choice buttons using your palette
	rustic_button_style = StyleBoxFlat.new()
	rustic_button_style.bg_color = Color("#6c171e") # Deep Red
	rustic_button_style.border_width_bottom = 4
	rustic_button_style.border_color = Color("#0d3d3a") # Dark Green
	rustic_button_style.corner_radius_top_left = 4
	rustic_button_style.corner_radius_top_right = 4
	rustic_button_style.corner_radius_bottom_left = 4
	rustic_button_style.corner_radius_bottom_right = 4
	rustic_button_style.content_margin_left = 10
	rustic_button_style.content_margin_top = 5
	rustic_button_style.content_margin_bottom = 5
	
	rustic_hover_style = rustic_button_style.duplicate()
	rustic_hover_style.bg_color = Color("#0d3d3a") # Dark Green
	rustic_hover_style.border_color = Color("#6c171e") # Deep Red

func start_conversation(speaker_name: String, text: String, choices: Array = []):
	show()
	dialogue_opened.emit() 
	name_label.text = speaker_name
	content_label.text = text
	content_label.visible_ratio = 0.0
	
	for child in choice_container.get_children():
		child.queue_free()
	
	var tween = get_tree().create_tween()
	tween.tween_property(content_label, "visible_ratio", 1.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	if choices.size() > 0:
		_create_choice_buttons(choices)
	else:
		await get_tree().create_timer(1.5).timeout
		hide()
		dialogue_finished.emit()

func _on_choice_pressed(index: int):
	hide() # 1. Instantly hide the UI from the screen
	
	# 2. Instantly wipe the buttons so they don't linger
	for child in choice_container.get_children():
		child.queue_free() 
		
	# 3. Now tell the game which option was picked
	choice_selected.emit(index)

func _create_choice_buttons(choices: Array):
	for i in range(choices.size()):
		var btn = Button.new()
		btn.text = choices[i]
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		
		# Inject the styling
		btn.add_theme_stylebox_override("normal", rustic_button_style)
		btn.add_theme_stylebox_override("hover", rustic_hover_style)
		btn.add_theme_stylebox_override("focus", rustic_hover_style)
		
		# Text color: Cream for everything
		btn.add_theme_color_override("font_color", Color("#f4dabf")) 
		btn.add_theme_color_override("font_hover_color", Color("#f4dabf"))
		btn.add_theme_color_override("font_focus_color", Color("#f4dabf"))
		
		# --- THE MAGICAL FIX IS RIGHT HERE ---
		# Instead of a lambda, we bind the integer directly to the function!
		btn.pressed.connect(_on_choice_pressed.bind(i))
		# -------------------------------------
		
		choice_container.add_child(btn)
		
		if i == 0: 
			btn.grab_focus()
