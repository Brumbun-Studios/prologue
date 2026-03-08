extends CanvasLayer

@onready var hp_bar = %HPBar
@onready var mp_bar = %MPBar
@onready var hp_label = %HPLabel
@onready var mp_label = %MPLabel
@onready var inventory_panel = %InventoryPanel
@onready var hotbar_container = %HotbarContainer
@onready var full_grid = %FullGrid

var is_expanded: bool = false
var base_panel_y: float

func _ready():
	# Save the initial position of the inventory panel for animations
	base_panel_y = inventory_panel.position.y
	
	full_grid.modulate.a = 0.0
	full_grid.hide()
	
	if PlayerManager:
		PlayerManager.stats_changed.connect(_update_stats)
		PlayerManager.inventory_changed.connect(_render_inventory)
		_update_stats()
		_render_inventory()

func _update_stats():
	hp_bar.max_value = PlayerManager.max_hp
	hp_bar.value = PlayerManager.hp
	hp_label.text = "HP %d/%d" % [PlayerManager.hp, PlayerManager.max_hp]
	
	mp_bar.max_value = PlayerManager.max_mp
	mp_bar.value = PlayerManager.mp
	mp_label.text = "MP %d/%d" % [PlayerManager.mp, PlayerManager.max_mp]

func _render_inventory():
	# Clear existing items
	for child in hotbar_container.get_children(): child.queue_free()
	for child in full_grid.get_children(): child.queue_free()
	
	var inv = PlayerManager.inventory
	
	for i in range(inv.size()):
		var item_box = _create_item_box(inv[i].name, inv[i].qty)
		# First 4 items go to Hotbar, the rest go to the expanded grid
		if i < 4:
			hotbar_container.add_child(item_box)
		else:
			full_grid.add_child(item_box)

func _create_item_box(item_name: String, qty: int) -> Label:
	var lbl = Label.new()
	lbl.text = "%s\nx%d" % [item_name.substr(0, 6), qty] # Shorten name to fit
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color("#0d3d3a")) # Dark Green text
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#f4dabf") # Cream background
	style.border_width_bottom = 2
	style.border_color = Color("#6c171e") # Deep red border
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	
	lbl.add_theme_stylebox_override("normal", style)
	lbl.custom_minimum_size = Vector2(46, 40)
	return lbl

func _input(event):
	# Listen for Tab key
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		_toggle_inventory()

func _toggle_inventory():
	is_expanded = !is_expanded
	
	# Smoothly animate the layout!
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if is_expanded:
		full_grid.show()
		# Expand height and shift position up
		tween.tween_property(inventory_panel, "size:y", 180, 0.4)
		tween.tween_property(inventory_panel, "position:y", base_panel_y - 130, 0.4)
		tween.tween_property(full_grid, "modulate:a", 1.0, 0.4)
	else:
		# Shrink back down to hotbar size
		tween.tween_property(inventory_panel, "size:y", 50, 0.3)
		tween.tween_property(inventory_panel, "position:y", base_panel_y, 0.3)
		tween.tween_property(full_grid, "modulate:a", 0.0, 0.2)
		tween.chain().tween_callback(full_grid.hide)
