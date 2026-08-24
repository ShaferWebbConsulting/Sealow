extends Control
## Renders the pip dots for a Dice (res://scenes/ui/Dice.tscn) on top of its
## rounded background panel. Kept as a separate Control so its _draw() calls
## happen after (i.e. visually on top of) the sibling Background panel.

var pip_color: Color = Color(0.09, 0.14, 0.22, 1.0)
var value: int = 1

## Fractional (0-1) pip positions per face value, laid out like a real die.
const PIP_LAYOUTS: Dictionary = {
	1: [[0.5, 0.5]],
	2: [[0.28, 0.28], [0.72, 0.72]],
	3: [[0.28, 0.28], [0.5, 0.5], [0.72, 0.72]],
	4: [[0.28, 0.28], [0.72, 0.28], [0.28, 0.72], [0.72, 0.72]],
	5: [[0.28, 0.28], [0.72, 0.28], [0.5, 0.5], [0.28, 0.72], [0.72, 0.72]],
	6: [[0.28, 0.25], [0.72, 0.25], [0.28, 0.5], [0.72, 0.5], [0.28, 0.75], [0.72, 0.75]],
}


func set_pip_value(new_value: int) -> void:
	value = clampi(new_value, 1, 6)
	queue_redraw()


func _draw() -> void:
	var layout: Array = PIP_LAYOUTS.get(value, PIP_LAYOUTS[1])
	var radius: float = minf(size.x, size.y) * 0.09
	for pip_pos in layout:
		var center: Vector2 = Vector2(pip_pos[0] * size.x, pip_pos[1] * size.y)
		draw_circle(center, radius, pip_color)
