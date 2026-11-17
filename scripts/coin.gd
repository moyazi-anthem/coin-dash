extends Area2D
## A spinning gold coin. Touch it with the player to collect it.

## Emitted once, when the player touches the coin.
signal collected

const RADIUS := 11.0

var _time := randf() * TAU  # random start so coins don't all spin in step
var _taken := false


func _ready() -> void:
	add_to_group("coins")


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not _taken and has_overlapping_bodies():
		_taken = true
		collected.emit()
		queue_free()


func _draw() -> void:
	# Squash the circle sideways to fake a spinning coin.
	var width := absf(cos(_time * 2.5)) * 0.75 + 0.25
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(width, 1.0))
	draw_circle(Vector2.ZERO, RADIUS, Color("ffd61a"))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, Color("bf8c00"), 2.0)
