extends SceneTree

const Rules = preload("res://scripts/rules.gd")
var failures := 0
var checks := 0
var game

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: ",label)
	else: print("PASS: ",label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(Rules.probability(2,4,"shortcut") > Rules.probability(2,4,"park"),"route changes probability")
	check(Rules.probability(2,0,"normal") > Rules.probability(0,0,"normal"),"coughing NPC carries greater risk")
	check(Rules.duration("week",0)==390 and Rules.duration("week",4)==450,"full week contains 35 minutes base riding")
	check(Rules.segment_distance(Vector2(50,0),Vector2.ZERO,Vector2(100,0))==0,"swept collision catches fast projectile")
	check(Rules.segment_distance(Vector2(50,40),Vector2.ZERO,Vector2(100,0))==40,"nearby safe projectile does not collide")
	for value in [null,[],{}, {"version":2}, {"version":1,"day":"bad","mode":"week"}, {"version":1,"day":0,"mode":"week","coins":[]}, {"version":1,"day":0,"mode":"week","gear":"broken"}]:
		check(Rules.clean_save(value).is_empty(),"reject malformed save " + str(value))
	var original := ""
	if FileAccess.file_exists("user://qa_run_tests.json"):
		original = FileAccess.get_file_as_string("user://qa_run_tests.json")
	game = load("res://main.tscn").instantiate()
	game.save_path="user://qa_run_tests.json";root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.saved = {}
	game.change_state("menu")
	for control in game.ui.get_children():
		if control is Button and control.text == "开始": control.pressed.emit(); break
	check(game.state=="brief" and game.mode=="week","single Start entry selects full campaign")
	game.start_run()
	check(game.state=="play" and game.day==0,"start is playable")
	game.touch.right = true
	game.update_game(.1)
	check(game.player_x>480,"natural input state moves cyclist")
	game.touch.right = false
	game.touch.sprint = true
	for i in 30: game.update_game(1.0/60)
	check(game.stamina<100 and game.speed>90,"sprint uses stamina and accelerates")
	game.touch.sprint = false
	game.touch.brake = true
	for i in 60: game.update_game(1.0/60)
	check(game.speed<40,"brake decelerates")
	game.touch.brake = false
	var paused_time: float = game.elapsed
	game.pause_game()
	game._process(.08)
	check(game.elapsed==paused_time,"pause freezes simulation")
	check(not game.music.playing,"pause stops web-compatible audio")
	game.unpause()
	game.npcs.clear(); game.spits.clear()
	game.player_x=480
	game.spits.append({"pos":Vector2(450,450),"vel":Vector2(1000,-game.speed),"life":1.0,"near":false})
	game.update_game(.06)
	check(game.state=="shop" and game.result_reason=="spit","actual fast projectile causes single-hit game over")
	game.start_run()
	check(game.spits.is_empty() and game.near_misses==0 and game.elapsed==0,"retry removes all old hazards")
	game.elapsed=game.time_limit
	game.update_game(.01)
	check(game.state=="shop" and game.result_reason=="late","late arrival fails without a spit")
	game.start_run()
	game.distance=game.target_distance*.29
	game.update_game(.01)
	check(game.state=="route" and game.route_stage==1,"first route choice triggers once")
	var before: float = game.target_distance
	game.choose_route("park")
	check(game.target_distance>before and game.state=="play","park increases distance and resumes play")
	game.start_run()
	var p := {"pos":Vector2(235,145),"side":0,"kind":2,"phase":"walk","decided":false,"timer":0.0,"target":Vector2.ZERO,"forced":true,"color":0}
	game.npcs.append(p)
	game.update_game(.02)
	check(p.phase=="warn" and game.spits.is_empty(),"warning always precedes a forced throw")
	for i in 80: game.update_game(1.0/60)
	check(p.phase=="done" and game.total_throws==1,"warning transitions to exactly one throw")
	game.start_run()
	for d in 5:
		game.route_stage=2
		game.distance=game.target_distance
		game.update_game(.001)
		check(game.state=="shop" and game.coins>=100,"day %d can finish"%d)
		game.load_save()
		check(game.saved.day==mini(d+1,4) and game.saved.coins==game.coins and game.saved.wins==d+1,"arrival checkpoint survives reload")
		var amount: int = game.coins
		game.finish_run()
		check(game.coins==amount,"clear cannot award twice")
		if d<4:
			check(game.day==d+1 and game.state=="shop","advance to shop/day %d"%(d+1))
			if not game.equipped.has(1): game.buy_gear(1)
			check(game.gear==1,"gear purchase")
			game.start_run()
	check(game.state=="shop" and game.wins==5,"five-day campaign reaches ending")
	game.resume_save()
	check(game.state=="shop","completed save restores ending, not a replayed reward")
	# Restore existing user state after isolated test.
	if original:
		var f := FileAccess.open("user://qa_run_tests.json",FileAccess.WRITE)
		f.store_string(original)
	elif FileAccess.file_exists("user://qa_run_tests.json"):
		DirAccess.remove_absolute("user://qa_run_tests.json")
	print("RESULT: %d checks, %d failures" % [checks,failures])
	game.queue_free()
	quit(1 if failures else 0)
