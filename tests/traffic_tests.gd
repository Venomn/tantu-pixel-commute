extends SceneTree
const Traffic = preload("res://scripts/traffic.gd")
var failures := 0
var checks := 0
var rng := RandomNumberGenerator.new()
var game
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ")+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	rng.seed=912
	for kind in 3:
		var v := Traffic.create(kind,kind,false,rng)
		v.pos.y=200
		v.decision=100
		var speed: float=v.speed
		Traffic.begin_action(v,"brake")
		Traffic.step(v,.3,90,rng)
		check(v.speed==speed and v.phase=="brake_warn","type %d signals before braking"%kind)
		for i in 70: Traffic.step(v,.02,90,rng)
		check(v.speed==0 and v.phase=="brake","type %d really stops"%kind)
		Traffic.begin_action(v,"accelerate")
		for i in 100: Traffic.step(v,.02,90,rng)
		check(v.speed>speed,"type %d really accelerates"%kind)
		var rear := Traffic.create(kind,kind,true,rng)
		var rear_y: float=rear.pos.y
		Traffic.step(rear,.1,90,rng)
		check(rear.pos.y<rear_y,"type %d overtakes from behind using relative speed"%kind)
		v.old_pos=Vector2(480,300);v.pos=Vector2(480,600)
		check(Traffic.contacts_player(v,Vector2(480,450),Vector2(480,450)),"type %d fast vehicle cannot tunnel through player"%kind)
		check(not Traffic.contacts_player(v,Vector2(625,450),Vector2(625,450)),"type %d adjacent lane is safe"%kind)
		v.age=29;v.departing=false;v.pos.y=300
		Traffic.step(v,.01,90,rng)
		check(v.departing and v.phase=="accelerate_warn" and v.pos.y>100,"old vehicle visibly accelerates away instead of vanishing")
	var original := FileAccess.get_file_as_string("user://qa_traffic_tests.json") if FileAccess.file_exists("user://qa_traffic_tests.json") else ""
	game=load("res://main.tscn").instantiate()
	game.save_path="user://qa_traffic_tests.json";root.add_child(game);game.set_process(false);game.muted=true
	game.saved={};game.new_game("quick");game.start_run()
	for i in 30:
		game.spawn_vehicle()
		var lanes: Array[int]=[]
		for v in game.vehicles:
			if not lanes.has(v.lane): lanes.append(v.lane)
		check(lanes.size()<=2 and game.vehicles.size()<=4,"spawn %d keeps a free lane and bounded density"%i)
	game.vehicles.clear()
	game.warning_gap=.5
	check(not game.can_warn_spit(),"new warnings respect the reaction gap")
	game.warning_gap=0
	game.npcs.assign([{"phase":"warn"}])
	var busy := Traffic.create(0,0,false,rng)
	busy.cough=.5
	game.vehicles.assign([busy])
	check(not game.can_warn_spit(),"pedestrian and vehicle warnings share the same hazard limit")
	game.npcs.clear();game.vehicles.clear()
	check(game.can_warn_spit(),"hazard limit reopens when previous hazards finish")
	for kind in 3:
		var v := Traffic.create(kind,0,false,rng)
		v.pos=Vector2(335,250);v.target=Vector2(480,450);v.cough=.3;v.decision=100
		game.vehicles.assign([v]);game.spits.clear()
		game.update_traffic(.1,Vector2(480,450))
		check(game.spits.is_empty(),"type %d cough telegraph cannot launch early"%kind)
		game.update_traffic(.21,Vector2(480,450))
		check(game.spits.size()==1,"type %d launches through shared spit physics"%kind)
		game.update_traffic(.1,Vector2(480,450))
		check(game.spits.size()==1,"type %d one warning creates one shot"%kind)
	game.spits.clear()
	game.throw_spit({"pos":Vector2(480,450),"mouth":Vector2(480,450),"target":Vector2(480,450),"vehicle":true})
	check(game.spits.is_empty(),"point-blank vehicle spit is suppressed")
	var car := Traffic.create(2,1,false,rng)
	car.pos=Vector2(480,440);car.old_pos=car.pos;car.decision=100;car.spit_check=100
	game.vehicles.assign([car]);game.player_x=480;game.stamina=100
	game.update_traffic(.01,Vector2(480,450))
	check(game.state=="play" and game.slow_timer>0 and game.stamina==88,"body contact slows and drains stamina without ending run")
	game.update_traffic(.01,Vector2(480,450))
	check(game.stamina==88,"contact cooldown prevents repeated frame-by-frame damage")
	car.cough=.7;car.target=Vector2(625,450)
	var before: Vector2=car.pos
	game.pause_game();game._process(.08)
	check(car.pos==before and car.cough==.7,"pause freezes vehicles and pending vehicle spit")
	game.unpause();game.start_run()
	check(game.vehicles.is_empty() and game.traffic_stats.spawned==0,"retry clears vehicles and traffic state")
	# A representative traffic-emitted projectile must obey the same one-hit rule.
	game.spits.append({"pos":Vector2(450,450),"vel":Vector2(1000,-game.speed),"life":1.0,"near":false})
	game.update_game(.06)
	check(game.state=="crash","vehicle projectile path still ends run on a hit")
	# Follow-distance resolution keeps an entering follower behind its leader.
	game.start_run();game.player_x=625
	var leader := Traffic.create(2,0,false,rng)
	var follower := Traffic.create(1,0,true,rng)
	leader.pos=Vector2(335,200);follower.pos=Vector2(335,240)
	game.vehicles.assign([leader,follower])
	game.update_traffic(.02,Vector2(625,450))
	check(follower.pos.y-leader.pos.y>=128,"vehicles preserve following distance")
	if original:
		var f:=FileAccess.open("user://qa_traffic_tests.json",FileAccess.WRITE);f.store_string(original)
	elif FileAccess.file_exists("user://qa_traffic_tests.json"): DirAccess.remove_absolute("user://qa_traffic_tests.json")
	print("TRAFFIC RESULT: %d checks, %d failures"%[checks,failures])
	game.queue_free();quit(1 if failures else 0)
