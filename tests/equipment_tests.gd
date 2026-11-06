extends SceneTree
const Rules = preload("res://scripts/rules.gd")
const Traffic = preload("res://scripts/traffic.gd")
var game
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ")+label)
func _initialize() -> void: call_deferred("run")
func reset() -> void:
	game.saved={}; game.new_game("quick"); game.start_run()
	game.spawn_timer=100;game.traffic_timer=100;game.obstacle_timer=100;game.coin_timer=100
func spit() -> void:
	game.spits.append({"pos":Vector2(game.player_x,450),"vel":Vector2(0,-game.speed),"life":1.0,"near":false})
func source_car() -> Dictionary:
	var v := Traffic.create(2,1,false,game.rng)
	v.pos=Vector2(480,200);v.old_pos=v.pos;v.litterer=true;v.decision=100;v.spit_check=100;v.litter_check=100
	return v
func trash(at: Vector2, source: Dictionary) -> void:
	game.garbage.append({"pos":at,"target":at,"flight":0.0,"source":source,"caught":false})
func run() -> void:
	var original := FileAccess.get_file_as_string("user://qa_equipment_tests.json") if FileAccess.file_exists("user://qa_equipment_tests.json") else ""
	game=load("res://main.tscn").instantiate();game.save_path="user://qa_equipment_tests.json";root.add_child(game);game.set_process(false);game.muted=true
	# Load a genuine previous release fixture through the same disk/JSON entry point.
	var fixture := {"version":1,"day":3,"mode":"week","coins":245,"gear":2,"wins":3}
	var f:=FileAccess.open("user://qa_equipment_tests.json",FileAccess.WRITE);f.store_string(JSON.stringify(fixture));f.close()
	game.load_save();game.resume_save()
	check(game.day==3 and game.coins==245 and game.wins==3,"v1 disk fixture preserves campaign and wallet")
	check(game.owned==[2] and game.equipped==[2] and game.gear==2,"v1 paid gear migrates into owned and equipped inventory")
	game.save_game();game.load_save();game.resume_save()
	check(game.saved.version==3 and game.owned==[2],"migration writes explicit v3 and reloads idempotently")
	var duplicate := {"version":2,"day":1,"mode":"quick","coins":90,"owned":[1,1,2,4,5],"equipped":[1,2,4,5,8]}
	var cleaned := Rules.clean_save(duplicate)
	check(cleaned.owned==[1,2,4,5] and cleaned.equipped==[2,5],"ambiguous v2 input deduplicates and only equips owned item per slot")
	for bad in [[0],[9],[1.5],["1"],[INF]]:
		duplicate.owned=bad
		check(Rules.clean_save(duplicate).is_empty(),"reject invalid inventory "+str(bad))
	game.request_new_game()
	check(game.state=="new_confirm" and game.coins==245 and game.day==3,"new campaign UI protects existing wallet and inventory until confirmed")
	reset()
	check(game.coins==80 and game.owned.is_empty(),"new campaign gives starter budget and clean inventory")
	game.buy_gear(1)
	check(game.coins==80 and game.owned.is_empty(),"cannot purchase through gameplay entry point")
	game.fail_run("late");game.finish_crash();game.buy_gear(8)
	check(game.coins==80 and not game.owned.has(8),"insufficient funds never grants equipment")
	game.buy_gear(0);game.buy_gear(99)
	check(game.coins==80,"invalid equipment ID cannot mutate wallet")
	game.buy_gear(1)
	check(game.coins==0 and game.owned==[1] and game.equipped==[1],"purchase subtracts exact price and equips")
	game.buy_gear(1);game.buy_gear(1)
	check(game.coins==0 and game.owned==[1] and game.equipped==[1],"owned gear can be taken off and equipped for free")
	game.coins=2000
	for id in range(2,9): game.buy_gear(id)
	check(game.owned.size()==8 and game.equipped==[3,5,6,8],"all eight purchases preserve ownership and four independent slots")
	game.save_game();game.load_save();game.resume_save()
	check(game.owned.size()==8 and game.equipped==[3,5,6,8],"inventory and loadout survive real file reload")
	reset()
	game.pickups.append({"pos":Vector2(480,450),"value":3,"taken":false})
	game.update_game(.01)
	check(game.coins==83 and game.pickups.is_empty(),"coin physically picked up once")
	game.update_game(.01);game.fail_run("spit");game.load_save();game.resume_save()
	check(game.coins==83,"failure and refresh retain collected coins without duplication")
	game.start_run();game.coin_timer=100
	check(game.coins==83 and game.run_coins==0,"retry preserves wallet but clears attempt earnings")
	reset();game.equipped=[7]
	game.pickups.append({"pos":Vector2(560,450),"value":3,"taken":false})
	for i in 20: game.update_collectibles(.02,Vector2(480,450))
	check(game.coins==83 and game.pickups.is_empty(),"magnet attracts distant coin into pickup radius")
	reset();game.equipped=[4]
	spit();game.update_game(.01)
	check(game.state=="play" and game.blocks==1 and game.shield_cooldown>17,"shield prevents first fatal spit and enters cooldown")
	spit();game.update_game(.01)
	check(game.state=="crash","shield cooldown leaves next spit lethal")
	reset();game.equipped=[4];game.shield_cooldown=.01
	spit();game.update_game(.02)
	check(game.state=="play" and game.blocks==1,"shield recharges through simulation time")
	reset();game.equipped=[5]
	game.use_umbrella();game.use_umbrella()
	spit();spit();game.update_game(.01)
	check(game.state=="play" and game.blocks==2 and game.umbrella_cooldown<8,"active umbrella blocks multiple spits and cannot be spam-reset")
	game.umbrella_time=0;spit();game.update_game(.01)
	check(game.state=="crash","umbrella expiry restores lethal spit collision")
	reset();game.use_umbrella();game.fire_weapon()
	check(game.umbrella_time==0 and game.shots.is_empty(),"unowned abilities cannot activate")
	reset();game.equipped=[5,6,8];game.use_umbrella();game.fire_weapon();game.recycler_cooldown=4
	var timer: float=game.umbrella_time
	game.pause_game();game._process(.08);game.use_umbrella();game.fire_weapon()
	check(game.umbrella_time==timer and game.recycler_cooldown==4 and game.shots.size()==1,"pause freezes cooldowns and disallows abilities")
	game.start_run()
	check(game.shots.is_empty() and game.garbage.is_empty() and game.pickups.is_empty() and game.recycler_cooldown==0 and game.umbrella_time==0,"retry clears every new entity and cooldown")
	reset();game.equipped=[6]
	var car := source_car();car.pos=Vector2(480,320);car.cough=.8;car.litter_warn=.8
	game.vehicles.assign([car]);game.fire_weapon();game.fire_weapon()
	check(game.shots.size()==1,"attack cooldown prevents duplicate projectile")
	game.update_shots(.25)
	check(car.silenced==6 and car.cough<0 and car.litter_warn==0 and game.attacks==1,"offensive projectile cancels both vehicle warnings on hit")
	game.update_traffic(.1,Vector2(480,450))
	check(game.spits.is_empty() and game.garbage.is_empty(),"suppressed vehicle does not emit late warned hazards")
	reset();game.equipped=[6];game.fire_weapon()
	game.spits.append({"pos":Vector2(480,350),"vel":Vector2.ZERO,"life":1.0,"near":false})
	game.update_shots(.2)
	check(game.spits[0].life==0,"offensive bubble neutralizes projectile on its path")
	reset();car=source_car();car.litter_warn=.3;car.litter_target=Vector2(480,140);game.vehicles.assign([car])
	game.update_traffic(.1,Vector2(480,450))
	check(game.garbage.is_empty(),"car garbage cannot launch before visible telegraph")
	game.update_traffic(.21,Vector2(480,450));game.update_traffic(.1,Vector2(480,450))
	check(game.garbage.size()==1 and game.garbage[0].source==car,"one telegraph emits one trash with original car identity")
	game.update_garbage(.4,Vector2(480,450))
	check(game.garbage[0].flight>0 and game.state=="play","garbage animates through air before landing")
	game.update_garbage(.41,Vector2(480,450))
	check(game.garbage[0].flight==0,"garbage lands as a persistent road hazard")
	reset();car=source_car();trash(Vector2(480,300),car)
	game.speed=900;game.update_garbage(.3,Vector2(480,450))
	check(game.state=="crash" and game.result_reason=="trash","swept trash collision detects fast pass-through as failure")
	reset();car=source_car();trash(Vector2(450,450),car);game.player_x=500
	game.update_garbage(.001,Vector2(400,450))
	check(game.state=="crash","lateral player crossing cannot tunnel through stationary garbage")
	reset();game.equipped=[4,5];game.use_umbrella();trash(Vector2(480,450),source_car());game.update_garbage(.01,Vector2(480,450))
	check(game.state=="crash","spit defense does not incorrectly protect from road garbage")
	reset();game.equipped=[8];car=source_car();game.vehicles.assign([car]);trash(Vector2(480,370),car)
	game.update_garbage(.01,Vector2(480,450))
	check(game.garbage.is_empty() and game.shots.size()==1 and game.recycler_cooldown==7,"mechanical arm automatically catches imminent trash")
	check(game.shots[0].source==car,"return projectile targets the exact offending car")
	car.pos.x=540;game.update_shots(.5)
	check(game.shots.is_empty() and car.silenced==8 and game.returns==1 and game.coins==92,"return tracks moving source, rewards once and silences offender")
	game.update_shots(.5)
	check(game.coins==92,"completed return cannot award twice")
	trash(Vector2(480,450),car);game.update_garbage(.01,Vector2(480,450))
	check(game.state=="crash","mechanical arm cooldown still requires dodging next trash")
	reset();game.equipped=[8];car=source_car();trash(Vector2(480,450),car)
	game.update_garbage(.01,Vector2(480,450))
	check(game.state=="play" and game.garbage.is_empty(),"ready arm intercepts before fatal contact boundary")
	game.vehicles.clear();game.update_shots(1)
	check(game.returns==1 and car.silenced==8,"source identity survives leaving the active traffic list")
	reset();trash(Vector2(400,200),source_car());trash(Vector2(600,200),source_car())
	check(not game.can_warn_spit(),"garbage occupies shared danger budget to avoid hazard floods")
	game.pause_game();var before: Vector2=game.garbage[0].pos;game._process(.08)
	check(game.garbage[0].pos==before,"pause freezes road garbage")
	game.save_path="user://missing_qa_directory/commute.json"
	game.save_game()
	check(game.save_warning and game.saved.version==3,"storage failure remains playable and displays persistence warning")
	if original:
		f=FileAccess.open("user://qa_equipment_tests.json",FileAccess.WRITE);f.store_string(original);f.close()
	elif FileAccess.file_exists("user://qa_equipment_tests.json"): DirAccess.remove_absolute("user://qa_equipment_tests.json")
	print("EQUIPMENT RESULT: %d checks, %d failures"%[checks,failures])
	game.queue_free();quit(1 if failures else 0)
