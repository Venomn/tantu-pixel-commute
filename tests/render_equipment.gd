extends SceneTree
func _initialize() -> void: call_deferred("render")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	print("FRAME ",name," : ",root.get_texture().get_image().save_png("res://../deliverables/"+name+".png"))
func render() -> void:
	var game=load("res://main.tscn").instantiate()
	game.save_path="user://qa_render.json"
	root.add_child(game);game.set_process(false);game.muted=true
	game.coins=352;game.owned=[1,4,6,7,8];game.equipped=[1,4,6,8]
	game.state="shop";game.build_ui();game.queue_redraw()
	await capture("equipment-shop")
	game.state="play";game.day=1;game.elapsed=22;game.target_distance=9000;game.distance=2800;game.time_limit=120
	game.player_x=480;game.road_scroll=100;game.toast_time=0;game.attempts=1
	var rng := RandomNumberGenerator.new();rng.seed=55
	var car=game.Traffic.create(2,2,false,rng)
	car.pos=Vector2(625,230);car.litterer=true;car.litter_warn=.7;car.litter_target=Vector2(480,250)
	game.vehicles.append(car)
	var bike=game.Traffic.create(0,0,false,rng);bike.pos=Vector2(335,170);bike.phase="accelerate";game.vehicles.append(bike)
	game.garbage.append({"pos":Vector2(400,350),"flight":0.0,"target":Vector2(400,350),"source":car,"caught":false})
	game.shots.append({"kind":"return","pos":Vector2(570,326),"source":car,"life":2.0})
	game.shots.append({"kind":"bubble","pos":Vector2(480,307),"life":1.0})
	for i in 3: game.pickups.append({"pos":Vector2(335,310+i*35),"value":3,"taken":false})
	game.build_ui();game.queue_redraw();await capture("equipment-ride")
	quit()
