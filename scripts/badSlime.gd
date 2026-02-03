extends "res://scripts/wanderSlime.gd"

func interact():
	var ui = get_tree().get_first_node_in_group("dialog_ui")
	if not ui: return

	ui.start_conversation(
		"Bad Slime", 
		"*gurgle* ... You look delicious. Prepare to be absorbed!", 
		["Wait, no!", "Bring it on!"]
	)
	
	var choice = await ui.choice_selected  # 0 = "Wait, no!", 1 = "Bring it on!"
	
	ui.hide()
	ui.dialogue_finished.emit()  # Manually emit so playerScript unlocks is_talking
	
	if choice == 1:  # "Bring it on!"
		var main = get_tree().root.get_node("Main")
		main.enter_battle(self)
	else:  # "Wait, no!" — just walk away, no battle
		pass
