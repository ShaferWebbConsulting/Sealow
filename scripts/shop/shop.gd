extends Control
## Shop screen, reachable from the Main Menu. Every item currently costs
## exactly ItemData.SHOP_COST_SHELLS (1 shell) — this is an intentional MVP
## simplification, not a placeholder bug. No real-money purchases; shells are
## only ever earned by winning battles.

const HP_UPGRADE_COST: int = 5

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
	list_vbox.add_child(_build_hp_row())
	var inventory: Dictionary = SaveManager.get_inventory()
	for item in ItemData.get_catalog():
		var key: String = ItemData.id_to_key(item.id)
		var owned: int = int(inventory.get(key, 0))
		list_vbox.add_child(_build_row(item, key, owned))


## Permanent max-HP purchase: SaveManager.buy_hp_upgrade() atomically checks
## affordability, spends the shells, and persists immediately.
func _on_buy_hp_pressed() -> void:
	if SaveManager.buy_hp_upgrade(HP_UPGRADE_COST):
		_show_message("Max HP increased!")
		_refresh()
	else:
		_show_message("Not enough shells")


func _clear_rows() -> void:
	for child in list_vbox.get_children():
		child.queue_free()


func _build_hp_row() -> Control:
	var buy_button: Button = Button.new()
	var panel: Control = _build_card(
		null,
		"❤️ HEALTH UPGRADE",
		"Permanently increase your maximum HP by 1.",
		"Current Max HP: %d" % SaveManager.get_max_hp(),
		HP_UPGRADE_COST,
		buy_button
	)
	buy_button.pressed.connect(_on_buy_hp_pressed)
	return panel


func _build_row(item: ItemData, key: String, owned: int) -> Control:
	var icon_texture: Texture2D = ItemData.get_texture(item.id)
	var buy_button: Button = Button.new()
	var title_text: String = item.display_name.to_upper() if icon_texture != null else "%s %s" % [item.icon, item.display_name.to_upper()]
	var panel: Control = _build_card(
		icon_texture,
		title_text,
		item.description,
		"Owned: %d" % owned,
		ItemData.SHOP_COST_SHELLS,
		buy_button
	)
	buy_button.pressed.connect(_on_buy_pressed.bind(key))
	return panel


## Shared card layout for every Shop product (permanent upgrades and items).
func _build_card(icon_texture: Texture2D, title_text: String, description: String, status_text: String, cost: int, buy_button: Button) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"LightPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	if icon_texture != null:
		var icon: TextureRect = TextureRect.new()
		icon.texture = icon_texture
		icon.custom_minimum_size = Vector2(96, 96)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_box)

	var title: Label = Label.new()
	title.text = title_text
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.05, 0.14, 0.27, 1.0))
	info_box.add_child(title)

	var desc: Label = Label.new()
	desc.text = description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 22)
	desc.add_theme_color_override("font_color", Color(0.12, 0.2, 0.32, 1.0))
	info_box.add_child(desc)

	var cost_row: HBoxContainer = HBoxContainer.new()
	cost_row.add_theme_constant_override("separation", 12)
	info_box.add_child(cost_row)

	var cost_label: Label = Label.new()
	cost_label.text = "%d 🐚" % cost
	cost_label.add_theme_font_size_override("font_size", 24)
	cost_label.add_theme_color_override("font_color", Color(0.72, 0.42, 0.05, 1))
	cost_row.add_child(cost_label)

	var status_label: Label = Label.new()
	status_label.text = status_text
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color(0.2, 0.3, 0.4, 1))
	cost_row.add_child(status_label)

	buy_button.theme_type_variation = &"BuyButton"
	buy_button.text = "BUY"
	buy_button.custom_minimum_size = Vector2(120, 64)
	buy_button.disabled = SaveManager.player_shells < cost
	buy_button.add_theme_font_size_override("font_size", 26)
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
