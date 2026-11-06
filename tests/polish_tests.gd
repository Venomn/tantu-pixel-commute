extends SceneTree
var game
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+message)
func labels_fit(view) -> bool:
	for l in view.root.find_children("*","Label",true,false):
		if not Rect2(Vector2.ZERO,l.get_parent().size).encloses(l.get_rect()):
			print("LABEL ",l.text,l.get_rect(),l.get_parent().size);return false
	return true
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="user://qa_polish.json";root.add_child(game);game.set_process(false);game.muted=true;game.saved={};game.new_game("week")
	for viewport in [Vector2i(320,480),Vector2i(359,610),Vector2i(390,740),Vector2i(844,390),Vector2i(667,320),Vector2i(1280,720)]:
		root.size=viewport;game.update_layout();await process_frame
		game.safe_top=20 if viewport.x<viewport.y else 0;game.safe_bottom=30
		for page in ["menu","brief"]:
			game.change_state(page);await process_frame;await process_frame
			var ok: bool=labels_fit(game.intro_view)
			for b in game.intro_view.actions:
				ok=ok and Rect2(Vector2.ZERO,game.intro_view.root.size).encloses(b.get_rect())
				for other in game.intro_view.actions:
					if b!=other:ok=ok and not b.get_rect().intersects(other.get_rect())
			check(ok and game.intro_view.root.find_children("*","ScrollContainer",true,false).is_empty(),"%s %s fits one screen with full text and separated buttons"%[viewport,page])
		game.start_run()
		if game.mobile:
			var view=game.mobile_view
			var rider: Vector2=game.to_global(Vector2(480,432))
			var ratio: float=float(root.size.x)/root.content_scale_size.x
			check((view.road_area.end.y+game.safe_top-rider.y)*ratio>65,"%s leaves open road below rider for the thumb"%viewport)
			view.press(20,rider-Vector2(0,game.safe_top));game._process(.15)
			var lifted: Vector2=game.to_global(Vector2(480,432))
			check((rider.y-lifted.y)*ratio>=45 and game.player_x==480,"%s near-rider touch lifts camera without moving collision coordinates"%viewport)
			game.npcs.assign([{"pos":Vector2(230,-100),"phase":"warn"}]);game.toast="普通提示";game.toast_time=3
			view.update_hud();check(view.message.text.contains("左侧咳咳"),"off-screen warning overrides ordinary toast while camera avoids finger")
			game.npcs.clear()
			view.release(20);game._process(.15);check(game.hand_lift==0,"release restores camera at %s"%viewport)
		for reason in ["spit","trash","late"]:
			game.start_run();game.fail_run(reason);await process_frame;await process_frame
			var crash_ok: bool=labels_fit(game.crash_view)
			for label in game.crash_view.root.find_children("*","Label",true,false):
				crash_ok=crash_ok and not label.get_rect().intersects(game.crash_view.skip.get_rect())
			check(game.state=="crash" and crash_ok,"%s %s animation shows its caption without overlapping skip"%[viewport,reason])
			game.finish_crash()
	root.size=Vector2i(1280,720);game.update_layout();game.start_run();await process_frame
	var pause_button: Button
	for control in game.ui.get_children():
		if control is Button and control.text=="Ⅱ":pause_button=control
	check(is_instance_valid(pause_button),"desktop ride retains its visible pause control")
	if pause_button:pause_button.pressed.emit()
	check(game.state=="pause","desktop pause button still pauses after graphical intro")
	root.size=Vector2i(390,740);game.update_layout();await process_frame
	for page in ["upgrade","crash","menu","brief","shop"]:
		game.start_run()
		if page=="crash":game.fail_run("spit")
		else:game.change_state(page)
		await process_frame;await process_frame
		check(game.mobile_view.built_state==page,"per-frame HUD guard changes before old controls are freed: %s"%page)
		game.mobile_view.update_hud();game._process(.01)
	game.safe_top=0;game.safe_bottom=0
	game.start_run();game.earn_coins(7);game.touch.sprint=true;game.fail_run("spit")
	var earned: int=game.coins;var elapsed: float=game.elapsed
	check(game.saved.phase=="shop" and not game.touch.sprint and game.state=="crash","failure saves settlement and releases input before animation")
	game.finish_run();game.fail_run("trash");game.buy_gear(1);game.update_game(.5)
	check(game.coins==earned and game.elapsed==elapsed and game.last_result.reason=="spit","animation cannot award twice, buy equipment or continue simulation")
	for i in 45:game._process(.05)
	check(game.state=="shop" and game.coins==earned,"animation automatically returns to shop with unchanged wallet")
	game.start_run();game.fail_run("trash");game.load_save();game.resume_save()
	check(game.state=="shop" and game.last_result.reason=="trash","reload during animation restores settled shop without replaying the death")
	game.start_run();game.fail_run("late");game.finish_crash();game.finish_crash()
	check(game.state=="shop","skip is idempotent")
	game.start_run();game.route_stage=1;game.distance=game.target_distance*.51;game.update_game(.001);game.choose_perk(0)
	game.distance=game.target_distance*.76;game.update_game(.001)
	check(game.state=="play" and game.perk_stage==2,"short ride offers only departure and halfway upgrades")
	var r=game.Rules;var anchor:=Vector2(480,450);var body: Vector2=anchor+r.RIDER_BODY_OFFSET
	check(r.spit_contact(body,body,anchor,anchor),"spit hits the drawn torso center")
	check(not r.spit_contact(body+Vector2(15,0),body+Vector2(15,0),anchor,anchor),"spit outside the narrow torso stays safe")
	check(not r.spit_contact(anchor+Vector2(0,12),anchor+Vector2(0,12),anchor,anchor),"spit at rear tyre is not a clothing hit")
	check(r.spit_contact(body-Vector2(70,0),body+Vector2(70,0),anchor,anchor),"fast spit crossing torso cannot tunnel")
	check(r.spit_contact(body,body,anchor-Vector2(60,0),anchor+Vector2(60,0)),"sideways rider motion uses swept torso collision")
	var wheels: Vector2=anchor+r.RIDER_WHEELS_OFFSET
	check(not r.ground_contact(wheels+Vector2(20,0),wheels+Vector2(20,0),anchor,anchor),"garbage outside tyre width does not cause an early death")
	check(r.ground_contact(wheels,wheels,anchor,anchor),"garbage on wheel track is lethal")
	check(r.ground_contact(wheels-Vector2(0,80),wheels+Vector2(0,80),anchor,anchor),"fast ground hazard cannot tunnel")
	for kind in 3:
		var car=game.Traffic.create(kind,1,false,game.rng);car.pos=anchor;car.old_pos=anchor
		check(game.Traffic.contacts_player(car,anchor,anchor),"type %d real overlap bumps the rider"%kind)
		car.pos.x+=game.Traffic.CONTACT_HALF[kind].x+r.RIDER_WHEELS_HALF.x+1;car.old_pos=car.pos
		check(not game.Traffic.contacts_player(car,anchor,anchor),"type %d outside vehicle silhouette remains safe"%kind)
	print("POLISH RESULT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
