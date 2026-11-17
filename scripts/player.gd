extends CharacterBody2D
## The player: a blue square moved with WASD or the arrow keys.
## The input actions ("move_left" and so on) are registered by main.gd.

const SPEED := 300.0
const HALF_SIZE := 14.0

## The rectangle the player must stay inside. main.gd sets this.
var bounds := Rect2(0, 0, 960, 540)

var _invulnerable_seconds := 0.0


func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * SPEED
	move_and_slide()
	var inner := bounds.grow(-HALF_SIZE)
	position = position.clamp(inner.position, inner.end)


func _process(delta: float) -> void:
	# Blink while invulnerable so the player can see they were just hit.
	if _invulnerable_seconds > 0.0:
		_invulnerable_seconds -= delta
		modulate.a = 0.3 if int(_invulnerable_seconds * 10.0) % 2 == 0 else 1.0
	else:
		modulate.a = 1.0


func _draw() -> void:
	var box := Rect2(-HALF_SIZE, -HALF_SIZE, HALF_SIZE * 2.0, HALF_SIZE * 2.0)
	draw_rect(box, Color("3d9bff"))
	draw_rect(box, Color("bfe0ff"), false, 2.0)


func is_invulnerable() -> bool:
	return _invulnerable_seconds > 0.0


func make_invulnerable(seconds: float) -> void:
	_invulnerable_seconds = seconds


## Turn the player's movement on or off (off between rounds).
func set_active(active: bool) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if not active:
		modulate.a = 1.0


## Put the player back at `spot`, standing still and ready to play.
func reset(spot: Vector2) -> void:
	position = spot
	velocity = Vector2.ZERO
	_invulnerable_seconds = 0.0
	set_active(true)
