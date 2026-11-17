extends Node2D
## Coin Dash: collect the coins, dodge the red spiky balls.
##
## This script is the "game manager". It owns the score, lives and game state,
## and it spawns the coins and hazards. The other scripts are small:
## player.gd moves the player, and coin.gd / hazard.gd only report when the
## player touches them.

enum State { TITLE, PLAYING, WON, LOST }

const CoinScene := preload("res://scenes/coin.tscn")
const HazardScene := preload("res://scenes/hazard.tscn")

const SCREEN_SIZE := Vector2(960, 540)
## Where the player and hazards may go. The strip above it is for the HUD.
const PLAY_AREA := Rect2(20, 60, 920, 460)
const GRID_STEP := 46.0

const COINS_TO_WIN := 15
const START_LIVES := 3
const MAX_COINS_ON_SCREEN := 3
const COIN_SPAWN_SECONDS := 1.0
const HAZARD_EVERY_N_COINS := 4  # a new hazard appears every 4th coin
const HAZARD_SPEED := 170.0
const SAFE_DISTANCE := 220.0  # new hazards appear at least this far from the player
const HIT_INVULNERABLE_SECONDS := 1.5

var state := State.TITLE
var score := 0
var lives := START_LIVES
var elapsed := 0.0  # seconds since the round started
var best_time := -1.0  # best winning time this session (-1 = none yet)

@onready var entities: Node2D = $Entities  # parent of all coins and hazards
@onready var player = $Player
@onready var hud = $HUD

var _coin_timer := Timer.new()


func _ready() -> void:
	_register_input_actions()
	_coin_timer.wait_time = COIN_SPAWN_SECONDS
	_coin_timer.timeout.connect(_on_coin_timer_timeout)
	add_child(_coin_timer)
	player.bounds = PLAY_AREA
	_show_title()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color("14171f"))
	draw_rect(PLAY_AREA, Color("1f2433"))
	var grid_color := Color(1, 1, 1, 0.04)
	for i in range(1, int(PLAY_AREA.size.x / GRID_STEP)):
		var x := PLAY_AREA.position.x + i * GRID_STEP
		draw_line(Vector2(x, PLAY_AREA.position.y), Vector2(x, PLAY_AREA.end.y), grid_color)
	for j in range(1, int(PLAY_AREA.size.y / GRID_STEP)):
		var y := PLAY_AREA.position.y + j * GRID_STEP
		draw_line(Vector2(PLAY_AREA.position.x, y), Vector2(PLAY_AREA.end.x, y), grid_color)
	draw_rect(PLAY_AREA, Color("3a4258"), false, 3.0)


func _process(delta: float) -> void:
	if state == State.PLAYING:
		elapsed += delta
		hud.set_time(elapsed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start") and state != State.PLAYING:
		start_game()


## Begin a fresh round (from the title screen or after winning or losing).
func start_game() -> void:
	_clear_entities()
	score = 0
	lives = START_LIVES
	elapsed = 0.0
	state = State.PLAYING
	player.reset(PLAY_AREA.get_center())
	player.visible = true
	entities.process_mode = Node.PROCESS_MODE_INHERIT
	hud.hide_message()
	hud.set_score(score, COINS_TO_WIN)
	hud.set_lives(lives)
	hud.set_time(elapsed)
	spawn_hazard()
	spawn_coin()
	_coin_timer.start()


## Put a coin at `at`, or at a random spot away from the player if omitted.
func spawn_coin(at: Vector2 = Vector2.INF) -> void:
	var coin = CoinScene.instantiate()
	coin.position = at if at != Vector2.INF else _random_point(100.0, 24.0)
	coin.collected.connect(_on_coin_collected)
	entities.add_child(coin)


## Add one more bouncing hazard, far enough from the player to be fair.
func spawn_hazard() -> void:
	var hazard = HazardScene.instantiate()
	hazard.bounds = PLAY_AREA
	hazard.position = _random_point(SAFE_DISTANCE, 30.0)
	hazard.velocity = Vector2.from_angle(randf() * TAU) * HAZARD_SPEED
	hazard.hit.connect(_on_hazard_hit)
	entities.add_child(hazard)


func _show_title() -> void:
	state = State.TITLE
	player.reset(PLAY_AREA.get_center())
	player.set_active(false)
	player.visible = false  # keep the title text readable
	hud.set_score(0, COINS_TO_WIN)
	hud.set_lives(START_LIVES)
	hud.set_time(0.0)
	hud.show_message(
		"COIN DASH\n\nCollect %d coins and dodge the red spikes!\nMove with WASD or the arrow keys.\n\nPress Enter or Space to start"
		% COINS_TO_WIN
	)


func _on_coin_timer_timeout() -> void:
	if get_tree().get_nodes_in_group("coins").size() < MAX_COINS_ON_SCREEN:
		spawn_coin()


func _on_coin_collected() -> void:
	if state != State.PLAYING:
		return
	score += 1
	hud.set_score(score, COINS_TO_WIN)
	if score >= COINS_TO_WIN:
		_win()
	elif score % HAZARD_EVERY_N_COINS == 0:
		spawn_hazard()


func _on_hazard_hit() -> void:
	# The hazard keeps reporting while it overlaps the player, so ignore it
	# during the short "just hit" invulnerable period.
	if state != State.PLAYING or player.is_invulnerable():
		return
	lives -= 1
	hud.set_lives(lives)
	if lives <= 0:
		_lose()
	else:
		player.make_invulnerable(HIT_INVULNERABLE_SECONDS)


func _win() -> void:
	_end_round(State.WON)
	var text := "YOU WIN!\n\nAll %d coins in %.1f seconds" % [COINS_TO_WIN, elapsed]
	if best_time < 0.0 or elapsed < best_time:
		best_time = elapsed
		text += "\nNew best time!"
	else:
		text += "\nBest time this session: %.1f seconds" % best_time
	hud.show_message(text + "\n\nPress Enter or Space to play again")


func _lose() -> void:
	_end_round(State.LOST)
	hud.show_message(
		"GAME OVER\n\nYou collected %d of %d coins\n\nPress Enter or Space to try again"
		% [score, COINS_TO_WIN]
	)


## Freeze the world so the final picture stays on screen behind the message.
func _end_round(final_state: State) -> void:
	state = final_state
	_coin_timer.stop()
	entities.process_mode = Node.PROCESS_MODE_DISABLED
	player.set_active(false)


func _clear_entities() -> void:
	for child in entities.get_children():
		entities.remove_child(child)
		child.queue_free()


## A random point inside the play area (kept `margin` px from the edges) that
## is at least `min_distance_from_player` px from the player when possible.
func _random_point(min_distance_from_player: float, margin: float) -> Vector2:
	var area := PLAY_AREA.grow(-margin)
	var point := area.get_center()
	for attempt in 20:
		point = Vector2(
			randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y)
		)
		if point.distance_to(player.position) >= min_distance_from_player:
			break
	return point


## The keyboard controls are registered here in code, so the whole project is
## readable as plain text. You can also see them in Project Settings > Input Map
## by moving them there.
func _register_input_actions() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"start": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)
