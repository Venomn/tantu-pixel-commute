extends SceneTree
const Rules = preload("res://scripts/rules.gd")
var game
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func _initialize() -> void: call_deferred("run")
func fresh() -> void:
	game.saved={};game.new_game("quick");game.start_run()
	game.spawn_timer=100;game.coin_timer=100;game.obstacle_timer=100;game.traffic_timer=100
func give(id: int) -> void:
	game.perk_choices.assign([id]);game.change_state("upgrade");game.choose_perk(0)
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="user://qa_roguelite.json"
	root.add_child(game);game.set_process(false);game.muted=true
	fresh();game.coins=600;game.change_state("brief");game.open_shop("brief");game.buy_gear(4);game.buy_gear(6)
	var bank: int=game.coins
	game.new_game("week")
	check(game.coins==bank and game.owned==[4,6] and game.equipped==[4,6],"new journey preserves permanent wallet, ownership and loadout")
	game.begin_run()
	check(game.state=="upgrade" and game.perk_stage==1 and game.perk_choices.size()==3,"departure offers three temporary choices")
	var distinct := {}
	for id in game.perk_choices: distinct[id]=true
	check(distinct.size()==3,"offered choices are distinct")
	var elapsed: float=game.elapsed
	game._process(.08)
	check(game.elapsed==elapsed and not game.music.playing,"choosing perks freezes simulation and audio")
	game.choose_perk(-1);game.choose_perk(3)
	check(game.state=="upgrade" and game.buffs.is_empty(),"invalid selection does not consume offer")
	var id: int=game.perk_choices[0]
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_1
	game._input(key)
	check(game.state=="play" and game.perk_level(id)==1,"number key selects the displayed upgrade and resumes")
	game.choose_perk(0)
	check(game.perk_level(id)==1,"duplicate selection cannot grant another upgrade")
	fresh();game.route_stage=2
	for stage in [1,2,3]:
		game.distance=game.target_distance*(stage*.25+.001)
		game.update_game(.001)
		check(game.state=="upgrade" and game.perk_stage==stage+1,"distance checkpoint %d offers an upgrade"%stage)
		game.choose_perk(0)
		game.update_game(.001)
		check(game.state=="play","checkpoint is not offered twice")
	fresh();give(0);game.touch.right=true;game.update_game(.1)
	check(is_equal_approx(game.player_x,505.625),"nimble perk changes actual steering speed")
	fresh();give(1);game.stamina=40;game.update_game(.1)
	check(is_equal_approx(game.stamina,42.5),"energy perk increases actual stamina recovery")
	game.stamina=10;give(1)
	check(game.stamina==100,"energy selection refills stamina")
	fresh();give(2)
	check(game.block_spit() and game.spare_guards==0 and not game.block_spit(),"temporary guard blocks exactly one spit")
	fresh();give(3);game.pickups.append({"pos":Vector2(480,450),"value":3,"taken":false});game.update_collectibles(.01,Vector2(480,450))
	check(game.coins==85 and game.run_coins==5 and game.particles.size()==1,"coin perk awards real bonus and creates pickup feedback")
	game.update_pickup_fx(.8)
	check(game.particles.is_empty(),"pickup feedback expires without leaking particles")
	fresh();give(4);game.update_game(.1)
	check(game.speed>90,"tailwind increases real cruise speed")
	fresh();give(5);game.pickups.append({"pos":Vector2(535,450),"value":3,"taken":false})
	for i in 10: game.update_collectibles(.02,Vector2(480,450))
	check(game.coins==83,"temporary pocket attracts and collects coins without permanent magnet")
	fresh();give(6)
	check(game.has_blaster(),"temporary bubble machine enables weapon without ownership")
	var attack:=InputEventKey.new();attack.pressed=true;attack.keycode=KEY_F;game._input(attack)
	check(game.shots.size()==1 and not game.owned.has(6),"temporary F weapon fires without permanently granting equipment")
	game.equipped=[6];game.attack_cooldown=0;game.shots.clear();game.fire_weapon()
	check(game.shots.size()==3,"permanent cannon plus temporary machine produces three-way attack")
	game.update_shots(.1)
	check(game.shots[0].pos.x<480 and game.shots[2].pos.x>480,"spread shots travel in different directions")
	fresh();game.equipped=[4,5,6,8];give(7)
	game.fire_weapon();game.use_umbrella();game.umbrella_time=0;game.block_spit()
	check(is_equal_approx(game.attack_cooldown,2.4) and is_equal_approx(game.umbrella_cooldown,6.4) and is_equal_approx(game.shield_cooldown,14.4),"overclock changes actual weapon and defense cooldowns")
	fresh();give(8)
	var car=game.Traffic.create(2,1,false,game.rng)
	var trash={"pos":Vector2(480,450),"target":Vector2(480,450),"flight":0.0,"source":car,"caught":false}
	game.garbage.append(trash);game.update_garbage(.01,Vector2(480,450))
	check(game.state=="play" and game.jump_charges==0 and game.garbage.is_empty(),"rabbit jump consumes a charge to avoid a real trash collision")
	game.garbage.append(trash.duplicate());game.garbage[0].caught=false;game.update_garbage(.01,Vector2(480,450))
	check(game.state=="shop" and game.last_result.reason=="trash","second trash remains lethal and goes straight to shop")
	fresh();game.equipped=[6];give(6);game.earn_coins(17);game.fail_run("spit")
	check(game.state=="shop" and game.coins==97 and game.buffs.is_empty() and not game.last_result.is_empty(),"failure settles into shop, retains earnings and clears temporary powers")
	game.load_save();game.resume_save()
	check(game.state=="shop" and game.coins==97 and game.last_result.reason=="spit","failure shop and settlement survive reload")
	game.start_run()
	check(game.buffs.is_empty() and not game.has_blaster(),"unowned temporary weapon does not survive another run or reload")
	fresh();give(3);game.earn_coins(9);game.finish_run()
	var paid: int=game.coins
	check(game.state=="shop" and game.day==1 and game.wins==1 and game.last_result.bonus>=100 and game.buffs.is_empty(),"successful run advances day and settles directly into shop")
	game.finish_run();game.fail_run("spit")
	check(game.coins==paid and game.wins==1,"late duplicate terminal events cannot pay or advance twice")
	game.load_save();game.resume_save()
	check(game.state=="shop" and game.day==1 and game.coins==paid,"successful shop reload keeps checkpoint and payout")
	game.buy_gear(4)
	check(game.owned.has(4),"earned rewards can immediately purchase permanent equipment")
	game.depart_shop()
	check(game.state=="upgrade" and game.equipped.has(4) and game.buffs.is_empty(),"shop departure equips purchased gear and offers a fresh build")
	fresh();give(2);game.earn_coins(12);game.pause_game();game.abandon_run()
	check(game.state=="shop" and game.last_result.reason=="quit" and game.coins==92 and game.buffs.is_empty(),"manual abandonment follows same settlement and reset boundary")
	fresh();give(6);game.earn_coins(15);game.load_save();game.resume_save()
	check(game.state=="shop" and game.coins==95 and game.buffs.is_empty() and game.last_result.reason=="quit","reload during run preserves cash but returns to shop without temporary powers")
	fresh();game.day=4;game.wins=4;game.coins=500;game.equipped=[4];game.owned=[4];game.finish_run()
	check(game.state=="shop" and game.wins==5 and game.weeks==1,"fifth successful commute also ends at shop")
	paid=game.coins;game.depart_shop()
	check(game.day==0 and game.wins==0 and game.coins==paid and game.owned==[4] and game.state=="upgrade","next week preserves permanent progression and starts fresh perks")
	fresh();game.buffs={0:2,1:2,2:3,3:2,4:2,5:2,6:1,7:2,8:0};game.perk_stage=0;game.offer_perks()
	check(game.perk_choices==[8],"maxed-out perks do not reappear in random offers")
	var old={"version":2,"day":2,"mode":"quick","coins":350,"gear":3,"wins":2,"owned":[3,8],"equipped":[3,8]}
	var migrated:=Rules.clean_save(JSON.parse_string(JSON.stringify(old)))
	check(migrated.version==3 and migrated.coins==350 and migrated.owned==[3,8] and migrated.mode=="quick","v2 migration preserves assets and original route duration")
	check(Rules.clean_save(migrated)==migrated,"v3 migration is idempotent")
	migrated.last_result={"reason":"arrival","day":2,"earned":"bad","bonus":100,"progress":100}
	check(Rules.clean_save(migrated).is_empty(),"malformed persisted settlement is rejected")
	print("ROGUELITE RESULT: %d checks, %d failures"%[checks,failures])
	game.queue_free();quit(1 if failures else 0)
