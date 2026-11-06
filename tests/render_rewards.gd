extends SceneTree
var game
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../deliverables/"+name+".png")
func run() -> void:
	root.size=Vector2i(390,740)
	game=load("res://main.tscn").instantiate();game.save_path="user://qa_reward_art.json";root.add_child(game);game.set_process(false);game.muted=true;game.saved={};game.new_game("week");game.begin_run()
	for group in 3:
		game.perk_choices.assign([group*3,group*3+1,group*3+2]);game.build_ui();await capture("rewards-group-%d"%group)
	for viewport in [Vector2i(359,610),Vector2i(320,480),Vector2i(844,390),Vector2i(1280,720)]:
		root.size=viewport;game.update_layout();await capture("rewards-%dx%d"%[viewport.x,viewport.y])
	quit()
