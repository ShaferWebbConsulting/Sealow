extends Control
class_name ItemPopup
## Small polished bottom-sheet style popup listing the player's consumable
## items. Rows are built dynamically from ItemData.get_catalog() + the given
## inventory counts, so adding a new item to the catalog is enough — no
## scene editing required.

signal item_used(item_key: String)
signal closed

@onready var list_vbox: VBoxContainer = %ListVBox
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	visible = false


## Rebuilds the item rows from the current inventory counts and shows the
## popup. `disabled_reasons` optionally maps an item key to a short reason
## string (e.g. "HP FULL") when the item can't be used right now even though
## the player owns one, so it can't be wasted.
func open(inventory_counts: Dictionary, disabled_reasons: Dictionary = {}) -> void:
	_clear_rows()
	for item in ItemData.get_catalog():
		var key: String = ItemData.id_to_key(item.id)
		var count: int = int(inventory_counts.get(key, 0))
		var disabled_reason: String = String(disabled_reasons.get(key, ""))
		list_vbox.add_child(_build_row(item, count, disabled_reason))
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _clear_rows() -> void:
	for child in list_vbox.get_children():
		child.queue_free()


func _build_row(item: ItemData, count: int, disabled_reason: String) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.18, 0.24, 0.9)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_box)

	var title: Label = Label.new()
	var count_suffix: String = " (x%d)" % count if count > 0 else " (none left)"
	title.text = "%s %s%s" % [item.icon, item.display_name, count_suffix]
	title.add_theme_font_size_override("font_size", 20)
	info_box.add_child(title)

	var desc: Label = Label.new()
	desc.text = item.description if disabled_reason.is_empty() else "%s (%s)" % [item.description, disabled_reason]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.68, 0.73, 0.74, 1.0))
	info_box.add_child(desc)

	var use_button: Button = Button.new()
	use_button.text = "USE"
	use_button.custom_minimum_size = Vector2(84, 56)
	# Disable when the player has none left, or the caller marked it unusable
	# right now (e.g. Mermaid Scale at full HP), so it can never be wasted.
	use_button.disabled = count <= 0 or not disabled_reason.is_empty()
	use_button.pressed.connect(func() -> void:
		item_used.emit(ItemData.id_to_key(item.id))
	)
	row.add_child(use_button)

	return panel


func _on_close_pressed() -> void:
	close()
