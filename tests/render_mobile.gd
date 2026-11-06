extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.size=Vector2i(390,740)
	var game=load("res://main.tscn").instantiate();game.save_path="user://qa_render_mobile.json";root.add_child(game)
	game.set_process(false);game.muted=true;game.saved={};game.new_game("week");game.equipped=[5,6,8];game.owned=[5,6,8];game.start_run();game.coins=438
	game.distance=game.target_distance*.37;game.elapsed=120;game.buffs={2:1,6:1};game.spare_guards=1
	game.pickups.assign([{"pos":Vector2(400,280),"value":3,"taken":false},{"pos":Vector2(400,330),"value":3,"taken":false}])
	game.build_ui();game.queue_redraw()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/Users/bingao/Documents/ChatGPT/像素风格吐痰游戏/deliverables/mobile-controls-fixture.png")
	quit()
