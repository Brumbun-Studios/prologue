extends CanvasLayer

signal dialogue_finished

@onready var content_label = %DialogueContent
@onready var name_label = %SpeakerName
@onready var choice_container = %ChoiceContainer

signal choice_selected(index: int)

func _ready():
	hide() 
	# We check if content_label exists before touching it to prevent the 'null instance' crash
	if content_label:
		content_label.visible_characters = 0

func start_conversation(speaker_name: String, text: String, choices: Array = []):
	show()
	name_label.text = speaker_name
	content_label.text = text
	content_label.visible_ratio = 0.0
	
	# Clear old buttons
	for child in choice_container.get_children():
		child.queue_free()
	
	# Snappy typewriter effect for that Persona feel
	var tween = get_tree().create_tween()
	tween.tween_property(content_label, "visible_ratio", 1.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Only show choices once the text is fully typed
	await tween.finished
	_create_choice_buttons(choices)

func _create_choice_buttons(choices: Array):
	for i in range(choices.size()):
		var btn = Button.new()
		btn.text = choices[i]
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT # Book style
		btn.pressed.connect(func(): _on_choice_pressed(i))
		choice_container.add_child(btn)
		
		if i == 0: 
			btn.grab_focus() # Allows keyboard/controller selection

func _on_choice_pressed(index: int):
	choice_selected.emit(index)
	# This closes the UI and tells the player they can move again
	hide() 
	dialogue_finished.emit()
	# You can either hide here or wait for the next data from the NPC
