extends Node

signal stats_changed
signal inventory_changed

var max_hp: int = 100
var hp: int = 100
var max_mp: int = 50
var mp: int = 50

# The first 4 items act as your hotbar. 
# The rest show up when the inventory expands.
var inventory: Array = [
	{"name": "HP Potion", "qty": 3, "desc": "Restores 50 HP"},
	{"name": "MP Potion", "qty": 1, "desc": "Restores 25 MP"},
	{"name": "Incense", "qty": 1, "desc": "A gift for spirits"},
	{"name": "Slime Gel", "qty": 5, "desc": "Sticky..."},
	{"name": "Old Boot", "qty": 1, "desc": "Fished from a pond"},
	{"name": "Rusty Sword", "qty": 1, "desc": "Needs sharpening"}
]

func heal(amount: int):
	hp = clampi(hp + amount, 0, max_hp)
	stats_changed.emit()

func take_damage(amount: int):
	hp = clampi(hp - amount, 0, max_hp)
	stats_changed.emit()
