extends Control
## Startup screen: the very first thing a player sees. Offers CONTINUE
## (load the existing local save) and NEW DIVE (start fresh, wiping the
## current save after explicit confirmation if one already exists).
##
## Deliberately NOT a login/account system — SeaLow uses exactly one local
## player save per install, like a classic handheld save file.

@onready var continue_button: Button = %ContinueButton
@onready var new_dive_button: Button = %NewDiveButton
@onready var confirm_panel: Control = %ConfirmPanel
@onready var confirm_cancel_button: Button = %ConfirmCancelButton
@onready var confirm_start_new_button: Button = %ConfirmStartNewButton
@onready var name_edit_panel: Control = %NameEditPanel  
@onready var name_input: Control = %NameEditPanel  
@onready var save_name_button: Control = %NameEditPanel  
@onready var cancel_name_button: Control = %NameEditPanel  


func _ready() -> void:
	print("NameEditPanel: ", name_edit_panel)
	print("NameInput: ", name_input)
	print("SaveNameButton: ", save_name_button)
	print("CancelNameButton: ", cancel_name_button)
	continue_button.pressed.connect(_on_continue_pressed)
	new_dive_button.pressed.connect(_on_new_dive_pressed)
	confirm_cancel_button.pressed.connect(_on_confirm_cancel_pressed)
	confirm_start_new_button.pressed.connect(_on_confirm_start_new_pressed)
	confirm_panel.visible = false

	var has_save: bool = SaveManager.has_save()
	continue_button.visible = has_save
	# NEW DIVE is the emphasized/primary action when there's no save yet.
	new_dive_button.text = "NEW DIVE" if has_save else "🌊 NEW DIVE"


## CONTINUE: load the existing save and go straight to the Main Menu (or, if
## the save exists but character select was never finished, MainMenu itself
## already redirects to Character Select in that case).
func _on_continue_pressed() -> void:
	SceneManager.go_to_main_menu()


## NEW DIVE: if there's no existing save, go directly to Character Select.
## If a save already exists, ask for explicit confirmation before wiping it.
func _on_new_dive_pressed() -> void:
	if not SaveManager.has_save():
		SceneManager.go_to_character_select()
		return
	confirm_panel.visible = true


func _on_confirm_cancel_pressed() -> void:
	confirm_panel.visible = false


## Only wipes the save after the player has explicitly confirmed.
func _on_confirm_start_new_pressed() -> void:
	confirm_panel.visible = false
	SaveManager.reset_save()
	SceneManager.go_to_character_select()
