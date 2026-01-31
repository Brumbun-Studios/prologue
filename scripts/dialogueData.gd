extends Resource
class_name DialogueData

@export_multiline var text: String
@export var choices: Array[String] = [] # e.g., ["Yes", "No"]
@export var next_nodes: Array[DialogueData] = [] # Maps to the choice index
