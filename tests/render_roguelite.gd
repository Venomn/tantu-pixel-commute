extends SceneTree
func _initialize() -> void: call_deferred("render")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	print("FRAME ",name,": ",root.get_texture().get_image().save_png("res://../deliverables/"+name+".png"))
func render() -> void:
	var game=load("res://main.tscn").instantiate()
	game.save_path="user://qa_rogue_visual.json"
	root.add_child(game);game.set_process(false);game.muted=true
	game.coins=438;game.owned=[1,4,6,8];game.equipped=[1,4,6,8]
	game.day=2;game.wins=2;game.mode="week"
	game.last_result={"reason":"arrival","earned":84,"bonus":128,"day":1,"progress":100}
	game.state="shop";game.build_ui();game.queue_redraw();await capture("rogue-shop")
	game.perk_choices.assign([2,3,6]);game.perk_stage=2
	game.state="upgrade";game.build_ui();game.queue_redraw();await capture("rogue-choice")
	game.state="play";game.elapsed=125;game.time_limit=580;game.target_distance=40000;game.distance=15000;game.player_x=480;game.road_scroll=100;game.attempts=3;game.toast_time=0
	game.buffs={0:1,2:1,3:1};game.perk_stage=3;game.spare_guards=1
	var car=game.Traffic.create(2,2,false,game.rng);car.pos=Vector2(625,210);car.litter_warn=.8;car.litter_target=Vector2(480,230);car.litterer=true;game.vehicles.append(car)
	var bike=game.Traffic.create(0,0,false,game.rng);bike.pos=Vector2(335,190);game.vehicles.append(bike)
	for i in 3: game.pickups.append({"pos":Vector2(335,315+i*42),"value":3,"taken":false})
	for i in 3: game.pickups.append({"pos":Vector2(480,165+i*42),"value":3,"taken":false})
	game.particles.append({"pos":Vector2(495,405),"life":.5,"value":5})
	game.garbage.append({"pos":Vector2(610,385),"target":Vector2(610,385),"flight":0.0,"source":car,"caught":false})
	game.build_ui();game.queue_redraw();await capture("rogue-coins")
	quit()
