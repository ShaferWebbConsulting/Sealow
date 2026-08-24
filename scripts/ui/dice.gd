extends Control
class_name Dice
## Reusable ocean-themed dice component. Large, rounded-square, pastel body
## color with a soft ocean-blue border and drop shadow, drawn entirely with
## Godot UI elements (no external artwork required).
##
## Usage:
##   dice.set_value(4)
##   dice.set_rolling(true)
##   await dice.play_roll_animation(4)   # ~1.2-1.6s satisfying roll

## Emitted whenever the roll settles on its final face, for callers that
## want to react without awaiting play_roll_animation directly.
signal roll_finished(final_value: int)

@export var body_color: Color = Color(0.68, 0.9, 0.85, 1.0):
	set(new_color):
		body_color = new_color
		_apply_style()

@onready var background: Panel = %Background
@onready var pips: Control = %Pips

var value: int = 1
var is_rolling: bool = false

var _settle_tween: Tween


func _ready() -> void:
	pivot_offset = size / 2.0
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	_apply_style()
	set_value(value)


## Sets the displayed face without animating (used for instant resets).
func set_value(new_value: int) -> void:
	value = clampi(new_value, 1, 6)
	if pips:
		pips.set_pip_value(value)


## Marks whether this die is currently mid-roll. play_roll_animation() calls
## this automatically; exposed separately so callers can also drive simpler
## "shaking" states if desired.
func set_rolling(rolling: bool) -> void:
	is_rolling = rolling


## Plays a self-contained ~1.2-1.6s roll animation: rapid face changes that
## gradually slow down, with a small scale bounce and slight rotation/shake,
## then settles cleanly on final_value. Uses Tween/await only, so it never
## blocks the UI thread — callers can run several of these concurrently by
## not awaiting each one individually.
func play_roll_animation(final_value: int, total_duration: float = 1.4) -> void:
	set_rolling(true)
	if _settle_tween != null and _settle_tween.is_valid():
		_settle_tween.kill()

	var elapsed: float = 0.0
	var step: float = 0.06
	var spin_duration: float = total_duration * 0.75

	while elapsed < spin_duration:
		set_value(randi_range(1, 6))
		var bounce: Tween = create_tween()
		bounce.tween_property(self, "scale", Vector2(1.1, 1.1), step * 0.4)
		bounce.tween_property(self, "scale", Vector2(1.0, 1.0), step * 0.4)
		rotation = randf_range(-0.08, 0.08)

		await get_tree().create_timer(step).timeout
		if not is_inside_tree():
			return
		elapsed += step
		# Gradually slow the face-change rate down for a "settling" feel.
		step = minf(step * 1.22, 0.22)

	set_value(final_value)
	rotation = 0.0
	_settle_tween = create_tween()
	_settle_tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12)
	_settle_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.22) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await _settle_tween.finished

	if is_inside_tree():
		set_rolling(false)
		roll_finished.emit(final_value)


func _apply_style() -> void:
	if background == null:
		return
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = body_color
	style.set_corner_radius_all(18)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.25, 0.5, 0.58, 0.85)
	style.shadow_color = Color(0.0, 0.05, 0.08, 0.35)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	background.add_theme_stylebox_override("panel", style)
