extends SceneTree
## Saves screenshots of the game as PNG files. This needs a real window, so do
## NOT use --headless:
##
##   godot --path . --script res://tools/screenshot.gd -- docs
##
## The folder name after "--" is optional (default "docs", inside the project).

const MainScene := preload("res://scenes/main.tscn")


func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var folder := ProjectSettings.globalize_path("res://docs") if args.is_empty() else args[0]
	DirAccess.make_dir_recursive_absolute(folder)

	var main = MainScene.instantiate()
	root.add_child(main)
	await create_timer(0.3).timeout
	await _save(folder.path_join("title.png"))

	var start := InputEventAction.new()
	start.action = "start"
	start.pressed = true
	Input.parse_input_event(start)
	await create_timer(0.2).timeout
	main.spawn_hazard()
	main.spawn_hazard()
	main.spawn_coin()
	main.spawn_coin()
	await create_timer(1.5).timeout
	await _save(folder.path_join("gameplay.png"))

	main.score = main.COINS_TO_WIN  # jump straight to the winning screen
	main.hud.set_score(main.score, main.COINS_TO_WIN)
	main._win()
	await create_timer(0.2).timeout
	await _save(folder.path_join("win.png"))
	quit()


func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(path)
	print("saved %s (error code %d)" % [path, error])
