extends "res://scripts/wanderSlime.gd"

func interact():
	var ui = get_tree().get_first_node_in_group("dialog_ui")
	if not ui: return

	ui.start_conversation(
		"Bad Slime",
		"*gurgle* ...You look delicious. Prepare to be absorbed!",
		["Wait, no!", "Bring it on!"]
	)

	var choice = await ui.choice_selected  # 0 = flee, 1 = fight

	# Instantly hide the dialogue box
	ui.hide()

	if choice == 1:
		# Player chose to fight — hand off to Main.
		# CRITICAL FIX: We do NOT emit dialogue_finished here. 
		# This keeps the player "locked" so they can't accidentally interact twice!
		var main = get_tree().root.get_node("Main")
		if main:
			main.enter_battle(self)
	else:
		# Player backed down, so it's safe to unblock them.
		ui.dialogue_finished.emit()
