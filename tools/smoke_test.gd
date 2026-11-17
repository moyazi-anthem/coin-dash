extends SceneTree
## Automated check of the game rules, run without a window:
##
##   godot --headless --path . --script res://tools/smoke_test.gd
##
## It plays the game by sending key presses and moving things into each other,
## then checks the score, lives and game state. Exit code 0 means every check
## passed; any other number is the count of failed checks.

const MainScene := preload("res://scenes/main.tscn")

var _checks := 0
var _failures := 0
var main
var player


func _initialize() -> void:
	_run()


func _run() -> void:
	main = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	player = main.get_node("Player")
	var State = main.State

	# --- title screen -------------------------------------------------------
	_check(main.state == State.TITLE, "the game starts on the title screen")
	_check(main.hud.message_text().contains("COIN DASH"), "the title message is shown")
	_check(not player.visible, "the player is hidden behind the title text")

	# --- starting a round ---------------------------------------------------
	_press("start")
	await _wait_physics(3)
	_check(main.state == State.PLAYING, "pressing start begins the game")
	_check(main.lives == 3 and main.score == 0, "a round starts with 3 lives and 0 coins")
	_check(get_nodes_in_group("hazards").size() == 1, "a round starts with 1 hazard")
	_check(main.hud.message_text() == "", "the message is hidden while playing")
	_check(player.visible, "the player is visible while playing")
	_calm_the_world()

	# --- movement -----------------------------------------------------------
	var x_before: float = player.position.x
	Input.action_press("move_right")
	await _wait_physics(18)
	Input.action_release("move_right")
	var moved: float = player.position.x - x_before
	_check(moved > 60.0 and moved < 120.0, "holding right for 0.3 s moves ~90 px (moved %.0f)" % moved)

	player.position = Vector2(-500.0, 9999.0)
	await _wait_physics(2)
	_check(main.PLAY_AREA.has_point(player.position), "the player cannot leave the play area")

	# --- coins --------------------------------------------------------------
	player.position = main.PLAY_AREA.get_center()
	await _wait_physics(2)
	main.spawn_coin(player.position)
	await _wait_physics(3)
	_check(main.score == 1, "touching a coin scores 1 (score is %d)" % main.score)
	_check(main.hud._score_label.text == "Coins: 1 / 15", "the HUD shows the new score")

	# --- hazards and lives --------------------------------------------------
	var hazard = get_nodes_in_group("hazards")[0]
	hazard.position = player.position
	await _wait_physics(3)
	_check(main.lives == 2, "touching a hazard costs a life (lives is %d)" % main.lives)
	_check(player.is_invulnerable(), "the player is invulnerable right after a hit")
	await _wait_physics(15)
	_check(main.lives == 2, "no second hit while invulnerable (lives is %d)" % main.lives)
	await _wait_physics(120)  # about 2 s: longer than the 1.5 s invulnerable time
	_check(main.lives == 1, "a hazard that stays put hurts again when the blinking ends (lives is %d)" % main.lives)

	# --- losing -------------------------------------------------------------
	player.make_invulnerable(0.0)
	await _wait_physics(3)
	_check(main.state == State.LOST, "losing the last life ends the round")
	_check(main.hud.message_text().contains("GAME OVER"), "the game over message is shown")
	var frozen_at: Vector2 = player.position
	Input.action_press("move_right")
	await _wait_physics(10)
	Input.action_release("move_right")
	_check(player.position == frozen_at, "the player cannot move after the round ends")

	# --- playing again ------------------------------------------------------
	_press("start")
	await _wait_physics(3)
	_check(main.state == State.PLAYING, "start begins a new round after game over")
	_check(main.lives == 3 and main.score == 0, "the new round resets lives and score")
	_check(get_nodes_in_group("hazards").size() == 1, "the new round has exactly 1 hazard")
	_check(get_nodes_in_group("coins").size() == 1, "the new round has exactly 1 coin")
	_calm_the_world()

	# --- hazards bounce off the walls ---------------------------------------
	hazard = get_nodes_in_group("hazards")[0]
	hazard.position = Vector2(main.PLAY_AREA.end.x - 20.0, 200.0)
	hazard.velocity = Vector2(170.0, 0.0)
	await _wait_physics(30)
	_check(hazard.velocity.x < 0.0, "a hazard turns around at the right wall")
	_check(main.PLAY_AREA.has_point(hazard.position), "a hazard stays inside the play area")

	# --- winning ------------------------------------------------------------
	player.position = main.PLAY_AREA.get_center()
	await _wait_physics(2)
	for i in main.COINS_TO_WIN:
		main.spawn_coin(player.position)
		await _wait_physics(3)
	_check(main.state == State.WON, "collecting 15 coins wins (score is %d)" % main.score)
	_check(main.hud.message_text().contains("YOU WIN"), "the win message is shown")
	_check(main.best_time > 0.0, "the winning time is remembered")
	_check(get_nodes_in_group("hazards").size() == 4, "a new hazard appears every 4th coin (1 + 3 = 4)")

	print("%d checks, %d failed" % [_checks, _failures])
	quit(_failures)


## Stop random coin spawns and freeze the hazards so a check can't be spoiled
## by chance. The rule checks below move things by hand instead.
func _calm_the_world() -> void:
	main._coin_timer.stop()
	for hazard in get_nodes_in_group("hazards"):
		hazard.velocity = Vector2.ZERO
	for coin in get_nodes_in_group("coins"):
		coin.queue_free()


func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)


func _wait_physics(frames: int) -> void:
	for i in frames:
		await physics_frame


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS  " if condition else "FAIL  ") + description)
