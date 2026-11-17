extends CanvasLayer
## The on-screen text: coins, time, lives, and the big centre message.

@onready var _score_label: Label = $ScoreLabel
@onready var _time_label: Label = $TimeLabel
@onready var _lives_label: Label = $LivesLabel
@onready var _message_label: Label = $MessageLabel
@onready var _backdrop: ColorRect = $Backdrop


func set_score(coins: int, goal: int) -> void:
	_score_label.text = "Coins: %d / %d" % [coins, goal]


func set_time(seconds: float) -> void:
	_time_label.text = "Time: %.1f" % seconds


func set_lives(lives: int) -> void:
	_lives_label.text = "Lives: %d" % lives


func show_message(text: String) -> void:
	_message_label.text = text
	_message_label.visible = true
	_backdrop.visible = true


func hide_message() -> void:
	_message_label.visible = false
	_backdrop.visible = false


func message_text() -> String:
	return _message_label.text if _message_label.visible else ""
