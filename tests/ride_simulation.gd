extends SceneTree
var game
var failures := 0
var completed := 0
var riding := 0.0
var attempts := 0
var destination := 480.0
var total_trash := 0
var total_returns := 0
var total_attacks := 0
var total_collected := 0
func buy_available() -> void:
	game.open_shop("brief")
	for id in [4,8,6,3]:
		if not game.equipped.has(id) and game.coins >= game.Equipment.ITEMS[id-1].price: game.buy_gear(id)
func tally() -> void:
	total_trash += game.traffic_stats.litter
	total_returns += game.returns
	total_attacks += game.attacks
	total_collected += game.run_coins
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var original := FileAccess.get_file_as_string("user://qa_ride_simulation.json") if FileAccess.file_exists("user://qa_ride_simulation.json") else ""
	game=load("res://main.tscn").instantiate()
	game.save_path="user://qa_ride_simulation.json";root.add_child(game)
	game.set_process(false)
	game.muted=true
	game.saved={}
	game.new_game("quick" if OS.get_cmdline_user_args().has("--quick") else "week")
	game.rng.seed=91822
	game.begin_run()
	attempts=1
	for frame in 360000:
		if game.state=="route": game.choose_route("park")
		elif game.state=="upgrade":
			var picked := 0
			for wanted in [2,8,0,1,6,7,5,3,4]:
				if game.perk_choices.has(wanted): picked=game.perk_choices.find(wanted);break
			game.choose_perk(picked)
		elif game.state=="shop":
			tally()
			if game.last_result.reason=="arrival": completed+=1
			else: failures+=1
			print("SETTLEMENT: ",game.last_result," owned=",game.owned)
			if completed==5 or failures>30: break
			buy_available()
			game.depart_shop()
			attempts+=1
		if game.state!="play": continue
		game.fire_weapon()
		# A deliberately simple reactive rider. It only steers, never alters hazards or position.
		var best_cost := INF
		for x in [310.0,370.0,430.0,490.0,550.0,610.0,660.0]:
			var cost: float = absf(x-game.player_x)*.01
			for c in game.pickups:
				if c.pos.y > 230 and c.pos.y < 460: cost += absf(x-c.pos.x)*.012
			for g in game.garbage:
				for t in [.1,.3,.6,.9,1.2]:
					var future: Vector2 = (g.target if g.flight > 0 else g.pos)+Vector2(0,game.speed)*t
					var rider := Vector2(move_toward(game.player_x,x,205*t),450)
					cost += maxf(0,65-future.distance_to(rider))*16
			for p in game.npcs:
				if p.phase=="warn": cost+=maxf(0,100-absf(x-p.target.x))*.7
			for v in game.vehicles:
				if v.cough>0: cost+=maxf(0,110-absf(x-v.target.x))*.7
				for t in [.1,.4,.8,1.2]:
					var future: Vector2=v.pos+Vector2(0,game.speed-v.speed)*t
					var rider := Vector2(move_toward(game.player_x,x,205*t),450)
					var relative: Vector2=(future-rider)/(game.Traffic.HALF_SIZE[v.kind]+Vector2(20,30))
					cost+=maxf(0,1.5-relative.length())*10
			for sp in game.spits:
				for t in [.1,.3,.6,.9,1.2]:
					var future: Vector2=sp.pos+(sp.vel+Vector2(0,game.speed))*t+Vector2(.5*game.wind*t*t,0)
					var rider := Vector2(move_toward(game.player_x,x,205*t),450)
					cost+=maxf(0,55-future.distance_to(rider))*12
			if cost<best_cost: best_cost=cost; destination=x
		game.touch.left=destination<game.player_x-8
		game.touch.right=destination>game.player_x+8
		game.update_game(1.0/30)
		riding+=1.0/30
	if original:
		var f := FileAccess.open("user://qa_ride_simulation.json",FileAccess.WRITE)
		f.store_string(original)
	elif FileAccess.file_exists("user://qa_ride_simulation.json"): DirAccess.remove_absolute("user://qa_ride_simulation.json")
	print("ECONOMY: collected=",total_collected," inventory=",game.owned," litter=",total_trash," returns=",total_returns," attacks=",total_attacks)
	print("FULL RIDE: days=",completed," attempts=",attempts," deaths=",failures," simulated minutes=",snappedf(riding/60,.1))
	game.queue_free()
	quit(0 if completed==5 else 1)
