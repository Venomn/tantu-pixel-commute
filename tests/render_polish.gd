extends SceneTree
var game
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../deliverables/"+name+".png")
func run() -> void:
	root.size=Vector2i(390,740)
	game=load("res://main.tscn").instantiate();game.save_path="user://qa_polish_render.json";root.add_child(game);game.set_process(false);game.muted=true;game.saved={}
	game.change_state("menu");await capture("polish-menu")
	game.new_game("week");await capture("polish-brief")
	for viewport in [Vector2i(320,480),Vector2i(844,390)]:
		root.size=viewport;game.update_layout();await capture("polish-brief-%dx%d"%[viewport.x,viewport.y])
	root.size=Vector2i(390,740);game.update_layout();game.start_run()
	game.spawn_timer=100;game.traffic_timer=100;game.coin_timer=100;game.obstacle_timer=100
	var v=game.Traffic.create(2,0,false,game.rng);v.pos=Vector2(335,180);v.old_pos=v.pos;v.cough=1;v.target=Vector2(480,432);game.vehicles.assign([v]);game.toast_time=0
	await capture("polish-ride")
	game.mobile_view.press(1,game.to_global(Vector2(480,432)))
	game._process(.15);await capture("polish-finger-lift")
	game.mobile_view.release(1)
	for reason in ["spit","trash","late"]:
		game.start_run();game.fail_run(reason);game.crash_time=.85;await capture("polish-crash-"+reason)
	root.size=Vector2i(844,390);game.update_layout();game.crash_view.build();await capture("polish-crash-landscape")
	quit()
