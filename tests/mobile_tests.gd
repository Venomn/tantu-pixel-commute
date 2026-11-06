extends SceneTree
var game
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+text)
func finger(id: int,pos: Vector2,down: bool,cancel := false) -> void:
	var event := InputEventScreenTouch.new();event.index=id;event.position=pos;event.pressed=down;event.canceled=cancel
	game.mobile_view._input(event)
func drag_finger(id: int,pos: Vector2) -> void:
	var event := InputEventScreenDrag.new();event.index=id;event.position=pos
	game.mobile_view._input(event)
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="user://qa_mobile.json"
	root.add_child(game);game.set_process(false);game.muted=true;game.saved={}
	root.size=Vector2i(359,610);game.update_layout();await process_frame
	check(game.mobile and game.portrait and root.content_scale_size.x==480,"narrow portrait uses a full-height mobile viewport")
	game.change_state("menu")
	for button in game.mobile_view.root.find_children("*","Button",true,false):
		if button.text=="开始":button.pressed.emit();break
	check(game.state=="brief" and game.mode=="week","mobile Start button starts the same full campaign")
	game.begin_run();game.perk_choices.assign([0]);game.choose_perk(0)
	game.spawn_timer=100;game.traffic_timer=100;game.coin_timer=100
	var view = game.mobile_view
	var origin: Vector2 = view.road_area.get_center()
	finger(1,origin,true)
	check(view.steering_target==game.player_x,"road touch does not snap the bicycle to the finger")
	drag_finger(1,origin+Vector2(65,0))
	finger(2,view.regions.sprint.get_center(),true)
	check(view.steering_target>game.player_x and game.held("sprint"),"two real touch events steer and sprint simultaneously")
	check(not view.regions.has("steer") and game.mobile_controls_height()==106,"dedicated steering pad is gone and toolbar is one row")
	var before: float=game.player_x;game.update_game(.1)
	check(game.player_x>before and game.stamina<100,"touch input affects real movement and stamina")
	for i in 10:game.update_game(.01)
	var stopped: float=game.player_x;game.update_game(.1)
	check(is_equal_approx(stopped,game.player_x),"stationary finger does not cause endless sideways drift")
	drag_finger(1,origin+Vector2(100,0))
	finger(3,view.regions.brake.get_center(),true)
	check(game.held("brake") and game.held("sprint"),"brake and sprint touches remain independently tracked")
	finger(2,Vector2(-500,-500),false)
	check(not game.held("sprint") and game.held("brake") and view.steering_target>game.player_x,"releasing outside the control stops only that finger")
	finger(1,Vector2.ZERO,false,true)
	check(view.steering_target==game.player_x and view.steering_id==-999,"cancelled steering touch returns to neutral")
	finger(3,Vector2.ZERO,false)
	finger(5,view.regions.sprint.get_center(),true);finger(6,view.regions.sprint.get_center(),true);finger(5,Vector2.ZERO,false)
	check(game.held("sprint"),"one of two fingers leaving a hold button does not release the other")
	game.pause_game()
	check(view.fingers.is_empty() and not game.held("sprint"),"pause clears all held controls")
	finger(9,origin,true)
	check(view.fingers.is_empty(),"touch steering cannot activate from a modal or pause")
	game.unpause();finger(1,view.road_area.get_center(),true);drag_finger(1,view.road_area.get_center()+Vector2(70,0))
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.state=="pause" and view.steering_target==game.player_x,"losing focus pauses and clears steering")
	game.unpause();finger(2,view.regions.sprint.get_center(),true)
	root.size=Vector2i(844,390);game.update_layout();await process_frame
	check(not game.portrait and game.mobile and game.state=="pause" and not game.held("sprint"),"orientation change pauses and clears touch without losing the run")
	game.unpause()
	for key in view.regions:
		var box: Rect2=view.regions[key]
		check(box.size.y*390/600>=42,"landscape %s has a large touch target"%key)
	game.equipped=[5,6];game.build_ui()
	check(not view.road_area.has_point(view.regions.fire.get_center()),"skill buttons cannot also begin road steering")
	finger(8,view.regions.fire.get_center(),true);finger(8,Vector2.ZERO,false)
	check(game.shots.size()==1 and game.attack_cooldown>0,"touch weapon invokes actual firing and cooldown")
	finger(9,view.regions.umbrella.get_center(),true);finger(9,Vector2.ZERO,false)
	check(game.umbrella_time>0,"touch umbrella activates actual defense")
	root.size=Vector2i(359,610);game.update_layout();await process_frame;game.unpause()
	for x in [283,480,677]:
		var player_screen: Vector2=game.to_global(Vector2(x,450))-Vector2(0,game.safe_top)
		for key in view.regions:check(not view.regions[key].has_point(player_screen),"portrait %s does not cover player lane %d"%[key,x])
	game.equipped=[];game.umbrella_time=0;game.player_x=400
	finger(20,view.road_area.get_center(),true)
	drag_finger(20,view.road_area.get_center()+Vector2(0,100))
	check(view.steering_target==400,"vertical road drag cannot steer sideways")
	finger(21,view.road_area.get_center(),true);drag_finger(21,view.road_area.get_center()+Vector2(200,0))
	check(view.steering_target==400,"a second road finger cannot steal steering")
	drag_finger(20,view.road_area.get_center()+Vector2(2000,0))
	check(view.steering_target==677,"large swipe clamps its target to the road")
	game.spits.assign([{"pos":Vector2(450,450),"vel":Vector2.ZERO,"life":2.0,"near":false}])
	game.update_game(.25)
	check(game.state=="shop" and game.last_result.reason=="spit","fast road swipe still collides with a spit crossed between endpoints")
	game.fail_run("spit")
	check(game.state=="shop" and game.garage_view.root.visible,"mobile settlement opens the scrollable shop")
	for state in ["menu","help","brief","new_confirm","pause","route","upgrade","shop"]:
		game.change_state(state)
		check((game.garage_view.root.visible if state=="shop" else (game.reward_view.root.visible if state=="upgrade" else view.built_state==state and view.scroll!=null)),"mobile %s has a usable menu"%state)
	root.size=Vector2i(1280,720);game.update_layout();await process_frame
	check(not game.mobile and not view.root.visible and game.scale==Vector2.ONE,"desktop restores original artwork and controls")
	print("MOBILE RESULT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
