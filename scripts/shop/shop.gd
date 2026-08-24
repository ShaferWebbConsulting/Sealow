extends Control
## Shop screen, reachable from the Main Menu. Every item currently costs
## exactly ItemData.SHOP_COST_SHELLS (1 shell) — this is an intentional MVP
## simplification, not a placeholder bug. No real-money purchases; shells are
## only ever earned by winning battles.


@onready var shells_label: Label = %ShellsLabel
@onready var list_vbox: VBoxContainer = %ListVBox
@onready var back_button: Button = %BackButton
@onready var message_label: Label = %MessageLabel


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	message_label.visible = false
	_refresh()


func _on_back_pressed() -> void:
	SceneManager.go_to_main_menu()


func _refresh() -> void:
	shells_label.text = "🐚 %d Shells" % SaveManager.player_shells
	_clear_rows()
	var inventory: Dictionary = SaveManager.get_inventory()
	for item in ItemData.get_catalog():
		var key: String = ItemData.id_to_key(item.id)
		var owned: int = int(inventory.get(key, 0))
		list_vbox.add_child(_build_row(item, key, owned))


func _clear_rows() -> void:
	for child in list_vbox.get_children():
		child.queue_free()


func _build_row(item: ItemData, key: String, owned: int) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.18, 0.24, 0.9)
	style.set_corner_radius_all(16)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_box)

	var title: Label = Label.new()
	title.text = "%s %s" % [item.icon, item.display_name.to_upper()]
	title.add_theme_font_size_override("font_size", 22)
	info_box.add_child(title)

	var desc: Label = Label.new()
	desc.text = item.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.68, 0.73, 0.74, 1.0))
	info_box.add_child(desc)

	var cost_row: HBoxContainer = HBoxContainer.new()
	cost_row.add_theme_constant_override("separation", 12)
	info_box.add_child(cost_row)

	var cost_label: Label = Label.new()
	cost_label.text = "%d 🐚" % ItemData.SHOP_COST_SHELLS
	cost_label.add_theme_font_size_override("font_size", 18)
	cost_label.add_theme_color_override("font_color", Color(0.941176, 0.760784, 0.239216, 1))
	cost_row.add_child(cost_label)

	var owned_label: Label = Label.new()
	owned_label.text = "Owned: %d" % owned
	owned_label.add_theme_font_size_override("font_size", 18)
	owned_label.add_theme_color_override("font_color", Color(0.678431, 0.72549, 0.741176, 1))
	cost_row.add_child(owned_label)

	var buy_button: Button = Button.new()
	buy_button.text = "BUY"
	buy_button.custom_minimum_size = Vector2(96, 64)
	buy_button.pressed.connect(_on_buy_pressed.bind(key))
	row.add_child(buy_button)

	return panel


## Purchases exactly one of `key` for ItemData.SHOP_COST_SHELLS shells.
## SaveManager.buy_item() atomically checks affordability, spends the
## shells, grants the item, and saves immediately — so a purchase is never
## lost even if the game is closed right after.
func _on_buy_pressed(key: String) -> void:
	if SaveManager.buy_item(key, ItemData.SHOP_COST_SHELLS):
		_show_message("Purchased!")
		_refresh()
	else:
		_show_message("Not enough shells")


func _show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	var tween: Tween = create_tween()
	tween.tween_interval(1.2)
	tween.tween_callback(func() -> void:
		message_label.visible = false
	)
