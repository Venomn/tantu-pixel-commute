extends SceneTree
func _initialize() -> void: call_deferred("render")
func render() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false);game.muted=true
	game.state="play";game.day=1;game.elapsed=22;game.target_distance=9000;game.distance=2800;game.time_limit=120
	game.player_x=480;game.road_scroll=100;game.toast_time=0;game.attempts=1
	var rng := RandomNumberGenerator.new();rng.seed=55
	for kind in 3:
		var v=game.Traffic.create(kind,0 if kind<2 else 2,false,rng)
		v.pos=Vector2(335 if kind<2 else 625,[240,380,200][kind])
		if kind==0: game.Traffic.begin_action(v,"brake")
		elif kind==1: game.Traffic.begin_action(v,"accelerate")
		else: v.cough=.5;v.target=Vector2(480,450)
		game.vehicles.append(v)
	game.build_ui();game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://../deliverables/traffic-scene.png")
	print("TRAFFIC FRAME saved: ",error)
	quit(error)
