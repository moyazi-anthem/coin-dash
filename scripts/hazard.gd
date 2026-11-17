extends Area2D
## A red spiky ball that bounces around the play area. Touching it costs a life.

## Emitted every physics frame while the player is touching the hazard.
## main.gd decides what that means (it ignores hits while the player blinks).
signal hit

const RADIUS := 15.0

## The rectangle to bounce inside, and the speed and direction, set by main.gd.
var bounds := Rect2(0, 0, 960, 540)
var velocity := Vector2.ZERO


func _ready() -> void:
	add_to_group("hazards")


func _physics_process(delta: float) -> void:
	position += velocity * delta
	rotation += delta * 2.0
	var inner := bounds.grow(-RADIUS)
	if position.x < inner.position.x:
		position.x = inner.position.x
		velocity.x = absf(velocity.x)
	elif position.x > inner.end.x:
		position.x = inner.end.x
		velocity.x = -absf(velocity.x)
	if position.y < inner.position.y:
		position.y = inner.position.y
		velocity.y = absf(velocity.y)
	elif position.y > inner.end.y:
		position.y = inner.end.y
		velocity.y = -absf(velocity.y)
	if has_overlapping_bodies():
		hit.emit()


func _draw() -> void:
	# An 8-pointed star: alternate the outer and inner radius around the circle.
	var points := PackedVector2Array()
	var spikes := 8
	for i in spikes * 2:
		var radius := RADIUS if i % 2 == 0 else RADIUS * 0.6
		points.append(Vector2.from_angle(PI * i / spikes) * radius)
	draw_colored_polygon(points, Color("ff4d4d"))
	draw_circle(Vector2.ZERO, 4.0, Color("7a0f0f"))
