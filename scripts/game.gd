extends Node2D

const Rules = preload("res://scripts/rules.gd")
const Perks = preload("res://scripts/perks.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Traffic = preload("res://scripts/traffic.gd")
const INK = Color("3a4b68")
const DARK = Color("293b57")
const CREAM = Color("fff3d1")
const YELLOW = Color("f2d27d")
const GREEN = Color("a4d577")
const RED = Color("e78b86")
const TEAL = Color("528d84")
const SAVE_PATH = "user://commute.json"
var save_path := SAVE_PATH
var font: Font
var pixels := {}
var state := "menu"
var previous_state := "play"
var mode := "week"
var day := 0
var coins := 0
var gear := 0
var wins := 0
var weeks := 0
var last_result: Dictionary = {}
var buffs: Dictionary = {}
var perk_choices: Array[int] = []
var perk_stage := 0
var spare_guards := 0
var jump_charges := 0
var jump_flash := 0.0
var wallet_flash := 0.0
var owned: Array = []
var equipped: Array = []
var pickups: Array[Dictionary] = []
var garbage: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var coin_timer := 2.0
var run_coins := 0
var shield_cooldown := 0.0
var umbrella_time := 0.0
var umbrella_cooldown := 0.0
var attack_cooldown := 0.0
var recycler_cooldown := 0.0
var blocks := 0
var returns := 0
var attacks := 0
var saved: Dictionary = {}
var save_warning := false
var rng := RandomNumberGenerator.new()
var ui: Control
var music: AudioStreamPlayer
var effects: Array[AudioStreamPlayer] = []
var sounds := {}
var tracks: Array[AudioStreamWAV] = []
var muted := false
var music_on := true
var touch := {"left": false, "right": false, "brake": false, "sprint": false}
var clock := 0.0
var elapsed := 0.0
var distance := 0.0
var road_scroll := 0.0
var target_distance := 0.0
var time_limit := 0.0
var stamina := 100.0
var player_x := 480.0
var speed := 90.0
var spawn_timer := 1.0
var obstacle_timer := 6.0
var traffic_timer := 2.0
var warning_gap := 0.0
var traffic_kind := 0
var vehicles: Array[Dictionary] = []
var traffic_stats := {"spawned":0,"brake":0,"accelerate":0,"spit":0,"bump":0,"litter":0}
var bell_cooldown := 0.0
var slow_timer := 0.0
var toast_time := 0.0
var toast := ""
var joke_timer := 14.0
var near_misses := 0
var dodged := 0
var attempts := 0
var route := "normal"
var route_stage := 0
var wind := 0.0
var npcs: Array[Dictionary] = []
var spits: Array[Dictionary] = []
var stains: Array[Dictionary] = []
var obstacles: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var result_reason := ""
var award := 0
var death_pos := Vector2.ZERO
var brake_was := false
var total_throws := 0
var last_spawn_kind := 0
var mobile := false
var portrait := false
var safe_top := 0.0
var safe_bottom := 0.0
var mobile_view
var reward_view
var garage_view
var layout_size := Vector2i.ZERO
var web_pause_callback: JavaScriptObject

func _ready() -> void:
	font = load("res://assets/Chinese.otf")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var pixel_names: Array[String] = ["grass","road","paving","fence","flowers","lamp","tree"]
	for i in 4: pixel_names.append("house%d"%i); pixel_names.append("car%d"%i)
	for i in 5:
		for frame in 2: pixel_names.append("person%d_%d"%[i,frame])
	for i in 3:
		for frame in 2: pixel_names.append("bike%d_%d"%[i,frame])
	for frame in 2:
		pixel_names.append("bike_left%d"%frame); pixel_names.append("bike_right%d"%frame); pixel_names.append("moto%d"%frame)
	for name in pixel_names: pixels[name] = load("res://assets/pixel/"+name+".png")
	rng.randomize()
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	music = AudioStreamPlayer.new()
	music.volume_db = -12
	add_child(music)
	for i in 5:
		var stream: AudioStreamWAV = load("res://assets/music%d.wav" % i)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size() / 2
		tracks.append(stream)
	for name in ["bell", "cough", "spit", "splat", "near", "click", "brake", "win", "lose", "engine", "coin", "shield", "shoot", "return", "trash"]:
		sounds[name] = load("res://assets/" + name + ".wav")
	for i in 12:
		var effect := AudioStreamPlayer.new()
		effect.volume_db = -5
		add_child(effect)
		effects.append(effect)
	load_save()
	mobile = OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()
	mobile_view = preload("res://scripts/mobile_ui.gd").new()
	add_child(mobile_view)
	mobile_view.setup(self)
	garage_view=preload("res://scripts/garage_ui.gd").new()
	add_child(garage_view)
	garage_view.setup(self)
	reward_view=preload("res://scripts/reward_ui.gd").new()
	add_child(reward_view);reward_view.setup(self)
	get_window().size_changed.connect(func(): call_deferred("update_layout"))
	update_layout()
	build_ui()
	if OS.has_feature("web"):
		web_pause_callback=JavaScriptBridge.create_callback(func(_args):
			if state=="play":pause_game())
		JavaScriptBridge.get_interface("window").tantuPause=web_pause_callback
		JavaScriptBridge.eval("window.tantuReady = true;")

func update_layout() -> void:
	var physical := get_window().size
	if physical==layout_size:return
	layout_size=physical
	var is_small := physical.x<900 or (physical.y<600 and physical.x<1200)
	mobile=OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available() or is_small
	portrait=mobile and physical.x<physical.y
	get_window().content_scale_size=Vector2i(480,maxi(640,int(480.0*physical.y/maxi(1,physical.x)))) if portrait else (Vector2i(maxi(960,int(600.0*physical.x/maxi(1,physical.y))),maxi(600,int(960.0*physical.y/maxi(1,physical.x)))) if mobile else Vector2i(960,600))
	if OS.has_feature("web"):
		var ratio := float(get_window().content_scale_size.x)/maxi(1,physical.x)
		safe_top=float(JavaScriptBridge.eval("parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--safe-top')) || 0"))*ratio
		safe_bottom=float(JavaScriptBridge.eval("parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--safe-bottom')) || 0"))*ratio
	position_world()
	if mobile_view:mobile_view.clear_input()
	if state=="play":pause_game()
	elif ui:build_ui()
	queue_redraw()

func mobile_controls_height() -> float:
	return 106.0

func position_world() -> void:
	if portrait:
		scale=Vector2(.96,.96)
		position=Vector2(240-480*.96,get_window().content_scale_size.y-safe_bottom-mobile_controls_height()-65-450*.96)
	else:
		scale=Vector2.ONE;position=Vector2((get_window().content_scale_size.x-960)/2.0,0) if mobile else Vector2.ZERO

func load_save() -> void:
	if FileAccess.file_exists(save_path):
		var f := FileAccess.open(save_path, FileAccess.READ)
		if f: saved = Rules.clean_save(JSON.parse_string(f.get_as_text()))

func save_game() -> void:
	saved = {"version":3,"phase":"shop" if state=="shop" else ("run" if state in ["play","pause","route","upgrade"] else "brief"),"run_earned":run_coins,"run_progress":clampi(int(distance/maxf(1,target_distance)*100),0,100),"weeks":weeks,"last_result":last_result.duplicate(),"owned":owned.duplicate(),"equipped":equipped.duplicate(),"day":day,"mode":mode,"coins":coins,"gear":gear,"wins":wins}
	var temp_path := save_path + ".tmp"
	var f := FileAccess.open(temp_path, FileAccess.WRITE)
	if not f:
		save_warning = true
		return
	f.store_string(JSON.stringify(saved))
	f.flush()
	var error := f.get_error()
	f.close()
	if error == OK: error = DirAccess.rename_absolute(temp_path,save_path)
	save_warning = error != OK

func sfx(name: String) -> void:
	if muted: return
	for effect in effects:
		if not effect.playing:
			effect.stream = sounds[name]
			effect.play()
			if name == "cough": music.volume_db = -22
			return

func start_music() -> void:
	if muted or not music_on: return
	if music.stream != tracks[day] or not music.playing:
		music.stream = tracks[day]
		music.play()

func stop_audio() -> void:
	music.stop()
	for effect in effects: effect.stop()

func clear_ui() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	for key in touch: touch[key] = false
	if mobile_view: mobile_view.clear_input()

func button(label: String, box: Rect2, action: Callable, accent := false) -> Button:
	var b := Button.new()
	b.text = label
	b.position = box.position
	b.size = box.size
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 17)
	var normal := StyleBoxFlat.new()
	normal.bg_color = YELLOW if accent else INK
	normal.border_color = DARK
	normal.set_border_width_all(3)
	normal.shadow_color = Color(0,0,0,0.25)
	normal.shadow_size = 3
	normal.shadow_offset = Vector2(0,3)
	b.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = CREAM if accent else TEAL
	b.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate()
	pressed.bg_color = GREEN
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_color_override("font_color", INK if accent else CREAM)
	b.add_theme_color_override("font_hover_color", INK if accent else CREAM)
	b.add_theme_color_override("font_pressed_color", INK)
	var disabled := normal.duplicate()
	disabled.bg_color = Color("c3bda7")
	b.add_theme_stylebox_override("disabled",disabled)
	b.add_theme_color_override("font_disabled_color",Color("687477"))
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): sfx("click"); action.call())
	ui.add_child(b)
	return b

func build_ui() -> void:
	clear_ui()
	if garage_view:garage_view.build()
	if reward_view:reward_view.build()
	if mobile_view:
		position_world()
		mobile_view.build()
		if mobile or state in ["shop","upgrade"]: return
	match state:
		"menu":
			button("开始", Rect2(56,328,286,52), request_new_game, true)
			if not saved.is_empty(): button(("回到改装铺" if saved.get("phase","")=="shop" else "继续 · 第 " + str(int(saved.day)+1) + " 天"), Rect2(56,392,286,46), resume_save)
			button("玩法 / 声音", Rect2(56,392 if saved.is_empty() else 456,174,38), func(): change_state("help"))
		"new_confirm":
			button("保留存档，返回", Rect2(230,350,235,48), func(): change_state("menu"), true)
			button("保留装备，重新出发", Rect2(495,350,235,48), func(): new_game("week"))
		"help":
			button("音效：" + ("关" if muted else "开"), Rect2(260,427,205,45), toggle_sound)
			button("音乐：" + ("开" if music_on else "关"), Rect2(495,427,205,45), toggle_music)
			button("返回", Rect2(350,490,260,46), func(): change_state("menu"), true)
		"brief":
			button("出门上班   →", Rect2(330,447,300,52), begin_run, true)
			button("改装铺 / 装备", Rect2(240,510,230,38), func(): open_shop("brief"))
			button("返回主菜单", Rect2(490,510,230,38), func(): change_state("menu"))
		"play":
			button("Ⅱ", Rect2(852,19,42,37), pause_game)
			button("♫" if not muted else "静", Rect2(903,19,40,37), toggle_sound)
			for pair in [["←", "left", 270], ["→", "right", 337], ["刹车", "brake", 428], ["冲刺", "sprint", 519]]:
				var b := button(pair[0], Rect2(pair[2],540,76 if pair[2]>400 else 58,44), func(): pass)
				b.button_down.connect(func(): touch[pair[1]] = true)
				b.button_up.connect(func(): touch[pair[1]] = false)
			button("铃铛", Rect2(610,540,80,44), ring_bell, true)
			if equipped.has(5): button("E 撑伞", Rect2(779,382,164,42), use_umbrella, true)
			if has_blaster(): button("F 泡泡炮", Rect2(779,434,164,42), fire_weapon, true)
		"route":
			button("走公园 · 人少路长", Rect2(220,400,245,54), func(): choose_route("park"), true)
			button("抄近道 · 人多路短", Rect2(495,400,245,54), func(): choose_route("shortcut"))
		"pause":
			button("继续骑行", Rect2(330,295,300,48), unpause, true)
			button("音效：" + ("关" if muted else "开"), Rect2(330,355,145,44), toggle_sound)
			button("音乐：" + ("开" if music_on else "关"), Rect2(485,355,145,44), toggle_music)
			button("结束本局 · 回改装铺", Rect2(330,417,300,44), abandon_run)

func toggle_sound() -> void:
	muted = not muted
	if muted: stop_audio()
	elif state == "play": start_music()
	build_ui()

func toggle_music() -> void:
	music_on = not music_on
	if not music_on: music.stop()
	elif state == "play": start_music()
	build_ui()

func request_new_game() -> void:
	if saved.is_empty(): new_game("week")
	else: change_state("new_confirm")

func new_game(selected: String) -> void:
	mode = selected
	day = 0
	coins = int(saved.get("coins",80))
	owned = saved.get("owned",[]).duplicate()
	equipped = saved.get("equipped",[]).duplicate()
	gear = int(saved.get("gear",0))
	weeks = int(saved.get("weeks",0))
	last_result = {}
	reset_perks()
	wins = 0
	attempts = 0
	change_state("brief")
	save_game()

func resume_save() -> void:
	mode = saved.mode
	day = saved.day
	coins = saved.coins
	gear = saved.gear
	owned = saved.owned.duplicate()
	equipped = saved.equipped.duplicate()
	wins = saved.wins
	weeks = saved.get("weeks",0)
	last_result = saved.get("last_result",{}).duplicate()
	reset_perks()
	if saved.get("phase","")=="run":
		last_result={"reason":"quit","day":day,"earned":saved.get("run_earned",0),"bonus":0,"progress":saved.get("run_progress",0)}
		change_state("shop")
		save_game()
	else: change_state("shop" if saved.get("phase","")=="shop" or wins==5 else "brief")

func change_state(value: String) -> void:
	state = value
	build_ui()
	queue_redraw()

func begin_run() -> void:
	if state not in ["brief","shop"]: return
	start_run()
	perk_stage=0
	offer_perks()

func depart_shop() -> void:
	if state != "shop": return
	if wins == 5: new_game(mode)
	begin_run()

func start_run() -> void:
	reset_perks()
	perk_stage=1
	last_result = {}
	elapsed = 0
	pickups.clear(); garbage.clear(); shots.clear()
	coin_timer = 1.5; run_coins = 0
	shield_cooldown = 0; umbrella_time = 0; umbrella_cooldown = 0
	attack_cooldown = 0; recycler_cooldown = 0
	blocks = 0; returns = 0; attacks = 0
	distance = 0
	target_distance = Rules.duration(mode, day) * 90.0
	time_limit = Rules.duration(mode, day) * 1.38
	player_x = 480
	stamina = 100
	npcs.clear(); spits.clear(); stains.clear(); obstacles.clear(); particles.clear(); vehicles.clear()
	traffic_timer = 1.0; traffic_kind = 0; warning_gap = 0
	traffic_stats = {"spawned":0,"brake":0,"accelerate":0,"spit":0,"bump":0,"litter":0}
	near_misses = 0; dodged = 0; total_throws = 0
	spawn_timer = 1.6; obstacle_timer = 8; bell_cooldown = 0; slow_timer = 0
	route = "normal"; route_stage = 0
	wind = 22.0 if day == 2 else (10.0 if day == 4 else 0.0)
	attempts += 1
	speed = 90
	joke_timer = 11
	change_state("play")
	save_game()
	start_music()
	notify("捡金币买装备！垃圾碰到就翻车，看红色落点绕行。", 5)

func notify(message: String, seconds := 3.0) -> void:
	toast = message
	toast_time = seconds

func held(name: String) -> bool:
	if mobile and mobile_view and mobile_view.steering_id!=-999:
		if name=="left":return mobile_view.steering_target<player_x-1
		if name=="right":return mobile_view.steering_target>player_x+1
	if touch.get(name, false): return true
	match name:
		"left": return Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
		"right": return Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
		"brake": return Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
		"sprint": return Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_SHIFT)
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			if state == "play": pause_game()
			elif state == "pause": unpause()
		if state == "play" and event.keycode == KEY_SPACE: ring_bell()
		if state == "play" and event.keycode == KEY_E: use_umbrella()
		if state == "play" and event.keycode == KEY_F: fire_weapon()
		if state == "upgrade" and event.keycode >= KEY_1 and event.keycode <= KEY_3: choose_perk(event.keycode-KEY_1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "play": pause_game()

func pause_game() -> void:
	stop_audio()
	change_state("pause")

func abandon_run() -> void:
	if state != "pause": return
	state="play"
	settle_run("quit")

func unpause() -> void:
	change_state("play")
	start_music()

func ring_bell() -> void:
	if state != "play" or bell_cooldown > 0: return
	bell_cooldown = 3.0
	sfx("bell")
	var changed := false
	for p in npcs:
		if p.pos.y > 80 and p.pos.y < 440 and p.phase == "walk":
			p.pos.x += -24 if p.side == 0 else 24
			if not p.decided and rng.randf() < 0.32:
				p.forced = true
				changed = true
	notify("叮铃！有人回头了，留意清嗓预警。" if changed else "叮铃铃！借过，打工人！", 2)

func choose_route(value: String) -> void:
	route = value
	target_distance += Rules.duration(mode, day) * (6.0 if route == "park" else -4.0)
	change_state("play")
	start_music()
	notify("绕一点远路，换一身干净。" if route == "park" else "老板：这条近路，我都不敢走。", 4)

func open_shop(_back: String) -> void:
	if state not in ["brief","shop"]: return
	change_state("shop")
	save_game()

func buy_gear(item: int) -> void:
	if state != "shop" or not Equipment.valid(item): return
	if not owned.has(item):
		var price: int = Equipment.ITEMS[item-1].price
		if coins < price:
			notify("钱包：再捡一点！还差 %d 金。" % (price-coins), 3)
			return
		coins -= price
		owned.append(item)
		sfx("coin")
	# Existing purchases are free to swap; pressing equipped gear takes it off.
	if equipped.has(item): equipped.erase(item)
	else: equipped = Equipment.select(equipped,item)
	gear = 0
	for id in equipped:
		if id <= 3: gear = id
	save_game()
	build_ui()

func settle_run(reason: String) -> void:
	if state != "play": return
	result_reason = reason
	var success := reason == "arrival"
	award = 100 + near_misses*8 + maxi(0,int((time_limit-elapsed)/4)) if success else 0
	coins = mini(9999,coins+award)
	last_result = {"reason":reason,"day":day,"earned":run_coins,"bonus":award,"progress":clampi(int(100*distance/maxf(1,target_distance)),0,100)}
	if success:
		wins = mini(5,wins+1)
		if day < 4: day += 1
		else: weeks += 1
	stop_audio()
	sfx("win" if success else ("splat" if reason=="spit" else "lose"))
	reset_perks()
	change_state("shop")
	save_game()

func fail_run(reason: String) -> void:
	settle_run(reason)

func finish_run() -> void:
	settle_run("arrival")

func _process(dt: float) -> void:
	if mobile_view: mobile_view.update_hud()
	clock += dt
	toast_time = maxf(0, toast_time-dt)
	if state == "play":
		update_pickup_fx(dt)
		# Bounded simulation substeps prevent a slow frame skipping collision or warnings.
		var remaining := minf(dt, 0.1)
		while remaining > 0 and state == "play":
			var step := minf(remaining, 1.0/60.0)
			update_game(step)
			remaining -= step
	queue_redraw()

func update_game(dt: float) -> void:
	elapsed += dt
	warning_gap = maxf(0,warning_gap-dt)
	music.volume_db = move_toward(music.volume_db,-12,dt*7)
	bell_cooldown = maxf(0,bell_cooldown-dt)
	shield_cooldown = maxf(0,shield_cooldown-dt)
	umbrella_time = maxf(0,umbrella_time-dt)
	umbrella_cooldown = maxf(0,umbrella_cooldown-dt)
	attack_cooldown = maxf(0,attack_cooldown-dt)
	recycler_cooldown = maxf(0,recycler_cooldown-dt)
	slow_timer = maxf(0,slow_timer-dt)
	var braking := held("brake")
	var sprinting := held("sprint") and stamina > 2 and not braking
	var desired := 28.0 if braking else (148.0+perk_level(4)*20 if sprinting else 90.0+perk_level(4)*12)
	if slow_timer > 0: desired *= 0.48
	speed = move_toward(speed,desired,dt*(220 if gear==2 else 140))
	if braking and not brake_was: sfx("brake")
	brake_was = braking
	stamina = clampf(stamina + dt * (-26 if sprinting else (23 if gear==1 else 17)+perk_level(1)*8),0,100)
	var direction := float(held("right"))-float(held("left"))
	var old_player := Vector2(player_x,450)
	if mobile and mobile_view and mobile_view.steering_id!=-999:
		# Follow the finger without teleporting; existing swept collisions still see the whole movement.
		player_x=move_toward(player_x,mobile_view.steering_target,dt*(450 if not braking else 330)*(1.0+perk_level(0)*.25))
	else:
		player_x = clampf(player_x + direction*dt*(205 if not braking else 160)*(1.0+perk_level(0)*.25),283,677)
	distance += speed*dt
	road_scroll += speed*dt
	spawn_timer -= dt
	obstacle_timer -= dt
	traffic_timer -= dt
	if traffic_timer <= 0:
		spawn_vehicle()
		traffic_timer = rng.randf_range(4.5,6.5) * (1.5 if route=="park" else 1.0)
	if spawn_timer <= 0:
		spawn_npc()
		spawn_timer = rng.randf_range(1.25,2.2) * (1.4 if route=="park" else 1.0) * (1.0-day*.065)
	if obstacle_timer <= 0:
		obstacles.append({"pos":Vector2(rng.randf_range(320,640),-30),"kind":0 if day<3 else rng.randi_range(0,1)})
		obstacle_timer = rng.randf_range(7,11)
	for p in npcs:
		p.pos.y += speed*dt
		if p.pos.y > 145 and not p.decided:
			p.decided = true
			if (p.forced or rng.randf() < Rules.probability(p.kind,day,route)) and can_warn_spit():
				warning_gap = 0.75
				p.phase = "warn"
				p.timer = (1.65 if gear==3 else 1.3)
				p.target = Vector2(player_x,450)
				sfx("cough")
		if p.phase == "warn":
			p.timer -= dt
			if p.timer <= 0:
				p.phase = "done"
				throw_spit(p)
	update_traffic(dt,old_player)
	update_collectibles(dt,old_player)
	update_shots(dt)
	update_garbage(dt,old_player)
	if state != "play": return
	for sp in spits:
		if sp.life <= 0: continue
		var old: Vector2 = sp.pos
		sp.vel.x += wind*dt
		sp.pos += (sp.vel+Vector2(0,speed))*dt
		sp.life -= dt
		var separation := Rules.segment_distance(Vector2.ZERO,old-old_player,sp.pos-Vector2(player_x,450))
		if separation < 12:
			if block_spit():
				sp.life = 0
				continue
			fail_run("spit")
			return
		if separation < 35 and not sp.near:
			sp.near = true
			near_misses += 1
			sfx("near")
			notify(["擦弹 +8 金，打卡时结算", "这走位，老板看了都沉默。", "差一点就要洗衣服了！"][near_misses%3],1.8)
		if sp.life <= 0:
			stains.append({"pos":sp.pos,"life":3.0})
			dodged += 1
	for obstacle in obstacles:
		obstacle.pos.y += speed*dt
		if obstacle.pos.distance_to(Vector2(player_x,460)) < 26 and slow_timer <= 0:
			slow_timer = 1.1
			stamina = maxf(0,stamina-15)
			sfx("brake")
			notify("颠了一下！鞋没湿，人还在。",2)
	for stain in stains:
		stain.pos.y += speed*dt
		stain.life -= dt
	npcs = npcs.filter(func(p): return p.pos.y < 650)
	spits = spits.filter(func(p): return p.life > 0 and p.pos.y < 650 and p.pos.x > 160 and p.pos.x < 800)
	obstacles = obstacles.filter(func(p): return p.pos.y < 650)
	stains = stains.filter(func(p): return p.life > 0 and p.pos.y < 650)
	if distance/target_distance > (0.28 if route_stage==0 else 0.65) and route_stage < 2:
		route_stage += 1
		stop_audio()
		change_state("route")
		return
	joke_timer -= dt
	if joke_timer <= 0:
		joke_timer = rng.randf_range(15,23)
		notify(["老板：不急，注意安全。还有两分钟。", "导航：道路畅通。建议闭眼？不建议！", "温馨提示：全勤奖不含洗衣补贴。", "文明街道评选中，请大家自由发挥。", "今天的目标：衣服比工资干净。"].pick_random(),4)
	if elapsed >= time_limit: fail_run("late")
	elif distance >= target_distance: finish_run()
	elif perk_stage < 4 and distance/target_distance >= perk_stage*.25: offer_perks()

func spawn_npc() -> void:
	var side := rng.randi_range(0,1)
	var kind := rng.randi_range(0,2)
	last_spawn_kind = kind
	npcs.append({"pos":Vector2(rng.randf_range(221,246) if side==0 else rng.randf_range(714,740),-35), "side":side,"kind":kind,"phase":"walk","decided":false,"timer":0.0,"target":Vector2.ZERO,"forced":false,"color":rng.randi_range(0,4)})

func throw_spit(p: Dictionary) -> void:
	var origin: Vector2 = p.get("mouth", p.pos + Vector2(12 if p.get("side",0)==0 else -12,-12))
	if p.get("vehicle",false) and origin.distance_to(Vector2(player_x,450)) < 75: return
	var travel := clampf(origin.distance_to(p.target)/240.0,0.7,1.7) if p.get("vehicle",false) else clampf(absf(p.target.x-origin.x)/240.0,0.6,1.7)
	var vel: Vector2 = (p.target-origin)/travel-Vector2(0,speed)
	spits.append({"pos":origin,"vel":vel,"life":travel+0.55,"near":false})
	total_throws += 1
	sfx("spit")

func can_warn_spit() -> bool:
	if warning_gap > 0: return false
	var active := spits.size() + garbage.size()
	for p in npcs:
		if p.phase == "warn": active += 1
	for v in vehicles:
		if v.cough > 0: active += 1
		if v.get("litter_warn",0) > 0: active += 1
	return active < 2

func spawn_vehicle() -> void:
	if vehicles.size() >= 4: return
	var occupied: Array[int] = []
	for v in vehicles:
		if not occupied.has(v.lane): occupied.append(v.lane)
	var lanes: Array[int] = [0,1,2]
	# Keep one whole lane free of vehicles; spits still make staying there a choice.
	if occupied.size() >= 2: lanes = occupied.duplicate()
	var offset := rng.randi_range(0,lanes.size()-1)
	for i in lanes.size():
		var lane: int = lanes[(i+offset)%lanes.size()]
		var from_behind := traffic_kind%3 == 1 or rng.randf()<0.25
		var entry := 660.0 if from_behind else -90.0
		var room := true
		for v in vehicles:
			if v.lane == lane and absf(v.pos.y-entry) < 240: room = false
		if not room: continue
		vehicles.append(Traffic.create(traffic_kind%3,lane,from_behind,rng))
		traffic_kind += 1
		traffic_stats.spawned += 1
		return

func update_traffic(dt: float, old_player: Vector2) -> void:
	var player := Vector2(player_x,450)
	for v in vehicles:
		var events: Array[String] = Traffic.step(v,dt,speed,rng)
		for event in events:
			if event == "brake":
				traffic_stats.brake += 1
				sfx("brake")
			elif event == "accelerate":
				traffic_stats.accelerate += 1
				sfx("engine")
		# Following traffic brakes before stacking on a vehicle in the same lane.
		for lead in vehicles:
			if lead == v or lead.lane != v.lane: continue
			var gap: float = v.pos.y-lead.pos.y
			var minimum: float = Traffic.HALF_SIZE[v.kind].y+Traffic.HALF_SIZE[lead.kind].y+28
			if gap > 0 and gap < minimum:
				v.pos.y = lead.pos.y+minimum
				v.speed = minf(v.speed,lead.speed)
		if v.silenced > 0:
			v.cough = -1
			v.litter_warn = 0
		elif v.litter_warn > 0:
			v.litter_warn -= dt
			v.litter_target.y += speed*dt
			if v.litter_warn <= 0: throw_garbage(v)
		elif v.litterer and v.litter_check <= 0 and v.cough <= 0 and v.pos.y > 85 and v.pos.y < 240:
			v.litter_check = rng.randf_range(5,8)
			if can_warn_spit() and rng.randf() < .62:
				v.litter_warn = 1.2
				v.litter_target = Vector2(Traffic.LANES[rng.randi_range(0,2)],minf(140,v.pos.y+30))
				warning_gap = .9
				sfx("trash")
		if v.cough > 0:
			v.cough -= dt
			if v.cough <= 0:
				var before := total_throws
				throw_spit({"pos":v.pos,"mouth":Traffic.mouth(v,v.target),"target":v.target,"vehicle":true})
				traffic_stats.spit += total_throws-before
		elif v.silenced <= 0 and v.litter_warn <= 0 and v.spit_check <= 0 and v.pos.y > 110 and v.pos.y < 490:
			v.spit_check = rng.randf_range(4.5,7.0)
			if can_warn_spit() and v.pos.distance_to(player) > 110 and rng.randf() < Rules.probability(1+int(v.kind==1),day,route):
				warning_gap = 0.75
				v.cough = 1.25 if gear==3 else 0.95
				v.target = player
				sfx("cough")
		if v.hit_cooldown <= 0 and Traffic.contacts_player(v,old_player,player):
			v.hit_cooldown = 2.0
			slow_timer = maxf(slow_timer,.7)
			stamina = maxf(0,stamina-12)
			traffic_stats.bump += 1
			sfx("brake")
			notify("剐蹭减速！" + Traffic.NAMES[v.kind] + "：我先急，你随意。",2)
	vehicles = vehicles.filter(func(v): return v.pos.y > -180 and v.pos.y < 750 )

func pixel_sprite(name: String, pos: Vector2, scale_factor := 3.0) -> void:
	var texture: Texture2D = pixels[name]
	draw_texture_rect(texture,Rect2(pos.round(),texture.get_size()*scale_factor),false)

func tile_area(name: String, box: Rect2, offset: float) -> void:
	var y := box.position.y-48.0+fmod(floorf(offset/3.0)*3.0,48.0)
	while y < box.end.y:
		var x := box.position.x
		while x < box.end.x:
			var top := maxf(y,box.position.y)
			var bottom := minf(y+48,box.end.y)
			var width := minf(48,box.end.x-x)
			draw_texture_rect_region(pixels[name],Rect2(x,top,width,bottom-top),Rect2(0,(top-y)/3,width/3,(bottom-top)/3))
			x += 48
		y += 48

func draw_vehicle(v: Dictionary) -> void:
	var p: Vector2 = v.pos.round()
	var braking: bool = v.phase in ["brake_warn","brake"]
	var accelerating: bool = v.phase in ["accelerate_warn","accelerate"]
	if p.y > 525:
		if v.from_behind:
			panel(Rect2(p.x-43,481,86,35),YELLOW)
			txt("↑ 后车",p.x-32,505,17,INK)
		if p.y > 595: return
	var frame := int(clock*7)%2 if state=="play" and v.speed>2 else 0
	if v.kind == 2:
		pixel_sprite("car%d"%v.color,p+Vector2(-42,-66),3)
		if braking:
			rect(p.x-27,p.y+57,15,6,Color("f47972")); rect(p.x+12,p.y+57,15,6,Color("f47972"))
		if v.cough > 0:
			var mouth: Vector2 = Traffic.mouth(v,v.target)
			rect(mouth.x-3,mouth.y,6,9,Color("f5c49a"))
	elif v.kind == 1:
		pixel_sprite("moto%d"%frame,p+Vector2(-24,-44),2)
	else:
		pixel_sprite("bike%d_%d"%[1+v.color%2,frame],p+Vector2(-24,-44),2)
	if braking and v.kind != 2: rect(p.x-5,p.y+18,10,4,Color("f47972"))
	if accelerating:
		for i in 3: rect(p.x-13+i*12,p.y+56+fmod(clock*120+i*9,20),3,9,YELLOW)
	if v.litterer and v.kind == 2:
		rect(p.x-12,p.y-18,24,20,RED); txt("垃",p.x-8,p.y-2,15,INK)
	if v.silenced > 0:
		panel(Rect2(p.x-48,p.y-93,96,28),GREEN)
		txt("文明冷静中",p.x-41,p.y-73,14,INK)
	elif v.litter_warn > 0:
		panel(Rect2(p.x-48,p.y-93,96,28),RED)
		txt("垃圾飞来！",p.x-41,p.y-73,15,INK)
		draw_arc(v.litter_target,23,0,TAU,16,RED,3)
		draw_line(p,v.litter_target,Color(RED,.6),2)
	elif v.cough > 0:
		panel(Rect2(p.x-43,p.y-97,86,29),YELLOW)
		txt("咳…呸！",p.x-34,p.y-76,16,INK)
		var origin := Traffic.mouth(v,v.target)
		for i in range(1,10):
			var dot: Vector2 = origin.lerp(v.target,i/10.0)
			rect(dot.x-2,dot.y-2,4,4,Color(YELLOW,.7))
		draw_arc(v.target,18,0,TAU,16,YELLOW,2)
	elif braking or accelerating:
		panel(Rect2(p.x-35,p.y-88,70,27),RED if braking else YELLOW)
		txt("急停！" if braking else "加速！",p.x-26,p.y-68,16,INK)

func rect(x: float,y: float,w: float,h: float,c: Color) -> void:
	draw_rect(Rect2(roundf(x),roundf(y),w,h),c)

func txt(value: String,x: float,y: float,size := 18,color := CREAM) -> void:
	draw_string(font,Vector2(x,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func centered(value: String,y: float,size := 24,color := INK) -> void:
	var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	txt(value,(960-width)/2,y,size,color)

func panel(box: Rect2, color := CREAM) -> void:
	draw_rect(Rect2(box.position+Vector2(6,6),box.size),Color(0,0,0,.28))
	draw_rect(box,color)
	draw_rect(box,INK,false,3)
	draw_rect(Rect2(box.position+Vector2(4,4),box.size-Vector2(8,8)),Color("a2b1bb") if color==CREAM else color.lightened(.2),false,2)

func _draw() -> void:
	if not font or state in ["shop","upgrade"]: return
	if mobile:
		if state=="play":draw_world()
		return
	if state == "menu": draw_menu(); return
	draw_world()
	draw_hud()
	if state == "play":
		if elapsed < 9:
			panel(Rect2(309,87,342,55),YELLOW)
			txt("A D 左右 · S 刹车 · W 冲刺",326,110,16,INK)
			txt("空格响铃 · 小心「咳咳」",345,131,15,INK)
		return
	rect(0,0,960,600,Color(0.035,0.1,0.13,.78))
	match state:
		"new_confirm":
			panel(Rect2(180,160,600,280))
			centered("重新开始？",219,32)
			centered("重新从第一天出发，金币和装备永久保留。",272,20)
			centered("继续原来的游戏，请返回主菜单选「继续」。",310,16,TEAL)
		"brief": draw_brief()
		"help": draw_help()
		"route": draw_route()
		"pause":
			panel(Rect2(265,148,430,345))
			centered("路边歇一会儿",208,33)
			centered("时间和危险都暂停了。",252,17)

func draw_menu() -> void:
	rect(0,0,960,600,INK)
	# A living pixel city postcard, framed beside the title.
	draw_city(8.0*sin(clock*.25)+clock*18)
	rect(0,0,392,600,CREAM)
	rect(392,0,6,600,YELLOW)
	rect(56,46,112,26,INK)
	txt("打工人的掌机冒险",62,65,12,YELLOW)
	txt("痰 途",49,169,78,INK)
	txt("全 勤 之 路",57,215,29,INK)
	rect(57,239,54,5,RED)
	txt("上个班而已。",56,281,21,INK)
	txt("怎么还得走位？",56,310,21,INK)
	txt("局外改装 / 局内奇遇 / 文明反击",56,578,13,TEAL)
	rect(424,32,199,29,DARK)
	txt("07:58 AM   ·   宜 干净上班",434,52,13,CREAM)
	cyclist(Vector2(571,398),2.7,true)
	person(Vector2(782,264),2,2.0,2)
	panel(Rect2(705,130,160,44),YELLOW)
	txt("咳、咳——",719,160,23,INK)
	var sx := 752-fmod(clock*92,180)
	rect(sx,320,13,8,GREEN)
	rect(sx+10,317,5,6,GREEN)
	rect(428,497,482,66,DARK)
	txt("「争创文明街道」",448,525,24,YELLOW)
	txt("奖品已备好：自愿加班体验券一张。",449,548,15,CREAM)
	for i in 7: rect(925,30+i*82,9,37,YELLOW)

func draw_city(offset: float) -> void:
	tile_area("grass",Rect2(398,0,562,600),offset)
	tile_area("road",Rect2(475,0,267,600),offset)
	tile_area("paving",Rect2(443,0,32,600),offset)
	tile_area("paving",Rect2(742,0,34,600),offset)
	for i in range(-1,4):
		var y := float(i*240)+fmod(offset,240)
		building(781,y,155,154,i+2)
		tree(Vector2(419,y+120),1.1)
		pixel_sprite("flowers",Vector2(875,y+195),3)

func draw_world() -> void:
	if mobile:tile_area("grass",Rect2(-position/scale,Vector2(get_window().content_scale_size)/scale),road_scroll)
	if portrait:
		var top := minf(0,-position.y/scale.y)
		tile_area("paving",Rect2(196,top,67,-top),road_scroll)
		tile_area("paving",Rect2(697,top,67,-top),road_scroll)
		tile_area("road",Rect2(263,top,434,-top),road_scroll)
	if not mobile:tile_area("grass",Rect2(0,0,960,600),road_scroll)
	tile_area("paving",Rect2(196,0,67,600),road_scroll)
	tile_area("paving",Rect2(697,0,67,600),road_scroll)
	tile_area("road",Rect2(263,0,434,600),road_scroll)
	rect(260,0,6,600,Color("b0a781")); rect(694,0,6,600,Color("b0a781"))
	rect(266,0,3,600,Color("fff1c8")); rect(691,0,3,600,Color("fff1c8"))
	for i in range(-1,10):
		var y := i*80+fmod(floorf(road_scroll/3)*3,80)
		rect(404,y,3,21,Color("f8edce")); rect(552,y,3,21,Color("f8edce"))
	for i in range(-1,4):
		var y := i*240+fmod(floorf(road_scroll/3)*3,240)
		if route == "park":
			tree(Vector2(72,y+50),1.5); tree(Vector2(866,y+30),1.5)
			pixel_sprite("flowers",Vector2(50,y+120),3);pixel_sprite("flowers",Vector2(825,y+118),3)
		else:
			building(18,y-13,155,154,i+day)
			building(788,y-70,150,132,i+day+2)
		for j in 3:
			pixel_sprite("fence",Vector2(15+j*48,y+205),3)
			pixel_sprite("fence",Vector2(790+j*48,y+152),3)
		tree(Vector2(174,y+158),.8); tree(Vector2(786,y+93),.8)
		pixel_sprite("lamp",Vector2(209,y+36),2)
		pixel_sprite("lamp",Vector2(724,y+169),2)
	if route == "shortcut":
		for i in range(-1,10):
			var sy := i*70+fmod(road_scroll,70)
			rect(269,sy,13,32,YELLOW); rect(678,sy,13,32,YELLOW)
	if target_distance > 0 and target_distance-distance < 420:
		var finish_y := 450-(target_distance-distance)
		for i in 14:
			rect(271+i*30,finish_y,30,15,CREAM if i%2==0 else INK)
			rect(271+i*30,finish_y+15,30,15,INK if i%2==0 else CREAM)
		panel(Rect2(336,finish_y-60,288,38),YELLOW)
		txt("全勤有限公司 · 打卡入口",349,finish_y-34,18,INK)
	for stain in stains:
		rect(stain.pos.x-9,stain.pos.y-3,18,7,Color("a6b680"))
		rect(stain.pos.x-3,stain.pos.y-7,9,15,Color("a6b680"))
	for o in obstacles:
		if o.kind==0:
			rect(o.pos.x-16,o.pos.y+8,32,6,DARK)
			rect(o.pos.x-11,o.pos.y-5,22,14,RED)
			rect(o.pos.x-7,o.pos.y-16,14,11,RED)
			rect(o.pos.x-8,o.pos.y-3,16,5,CREAM)
		else:
			rect(o.pos.x-24,o.pos.y-8,48,19,Color("354f55"))
			rect(o.pos.x-18,o.pos.y-5,33,11,Color("78a7a2"))
	for p in npcs:
		person(p.pos,p.color,1.15,p.kind)
		if p.phase == "warn":
			var c := YELLOW if p.timer>.55 else RED
			panel(Rect2(p.pos.x-36,p.pos.y-78,73,30),c)
			txt("咳咳！",p.pos.x-27,p.pos.y-57,17,INK)
			# Dashed intent line is visual assistance; actual trajectory remains physical.
			var from: Vector2 = p.pos
			for j in range(1,10):
				var dot := from.lerp(p.target,j/10.0)
				rect(dot.x-2,dot.y-2,4,4,Color(c,.45))
			draw_arc(p.target,19,0,TAU,16,Color(c,.7),2)
	for c in pickups: draw_coin(c.pos+Vector2(0,sin(clock*4+c.pos.x)*2))
	for g in garbage: draw_garbage(g)
	for v in vehicles: draw_vehicle(v)
	for sp in spits:
		var tail: Vector2 = sp.pos-sp.vel.normalized()*12
		draw_line(tail,sp.pos,Color("789b56"),6)
		rect(sp.pos.x-5,sp.pos.y-5,10,10,GREEN)
		rect(sp.pos.x-2,sp.pos.y-5,4,3,CREAM)
	for shot in shots:
		if shot.kind == "bubble":
			draw_circle(shot.pos,13,Color("9ee9dd")); draw_arc(shot.pos,13,0,TAU,16,CREAM,3)
		else:
			draw_line(shot.pos,shot.pos+Vector2(0,22),YELLOW,3)
			draw_trash(shot.pos)
	cyclist(Vector2(player_x,450-18*sin(PI*jump_flash/.5)),1.5,state=="play")
	draw_pickup_fx()
	if equipped.has(4) and shield_cooldown <= 0: draw_arc(Vector2(player_x,435),31,0,TAU,24,Color("9ee9dd"),3)
	if umbrella_time > 0:
		draw_line(Vector2(player_x,441),Vector2(player_x,405),CREAM,4)
		draw_colored_polygon(PackedVector2Array([Vector2(player_x-39,414),Vector2(player_x-27,391),Vector2(player_x,380),Vector2(player_x+27,391),Vector2(player_x+39,414)]),RED)
		draw_line(Vector2(player_x,380),Vector2(player_x,414),CREAM,3)
	if has_blaster(): rect(player_x+16,412,10,21,TEAL); rect(player_x+13,408,16,7,CREAM)
	if equipped.has(8):
		draw_line(Vector2(player_x-12,445),Vector2(player_x-32,422),INK,6)
		draw_line(Vector2(player_x-32,422),Vector2(player_x-27,404),YELLOW,5)
		draw_arc(Vector2(player_x-27,400),7,0,PI,8,YELLOW,3)
	# Subtle pixel grain on the tarmac.
	for i in 30:
		rect(280+fmod(i*137,398),fmod(i*97+road_scroll,600),3,2,Color(0.7,0.6,0.4,.09))

func building(x: float,y: float,w: float,_h: float,variant: int) -> void:
	var v := posmod(variant,4)
	pixel_sprite("house%d"%v,Vector2(x,y),3)
	pixel_sprite("flowers",Vector2(x+7,y+174),3)
	pixel_sprite("flowers",Vector2(x+w-45,y+172),3)
	rect(x+45,y+173,79,23,Color("776953"))
	rect(x+48,y+175,73,18,Color("f7e9bf"))
	txt(["早安食堂","好运商店","文明公寓","摸鱼咖啡"][v],x+53,y+189,13,INK)

func tree(p: Vector2,scale_factor: float) -> void:
	var zoom := maxf(2,roundf(scale_factor*3))
	pixel_sprite("tree",p-Vector2(16*zoom,32*zoom),zoom)

func person(p: Vector2,variant: int,s: float,_kind: int) -> void:
	var zoom := maxf(2,roundf(s*2))
	var frame := int(clock*4+variant)%2
	pixel_sprite("person%d_%d"%[posmod(variant,5),frame],p-Vector2(8*zoom,19*zoom),zoom)

func cyclist(p: Vector2,s: float,moving: bool) -> void:
	var zoom := maxf(2,roundf(s*1.5))
	var frame := int(clock*9)%2 if moving else 0
	var name := "bike0_%d"%frame
	var size := Vector2(24,34)
	if state=="play" and (held("left") or held("right")):
		name = ("bike_left%d" if held("left") else "bike_right%d")%frame
		size = Vector2(28,32)
	pixel_sprite(name,p-Vector2(size.x*zoom/2,22*zoom),zoom)

func draw_hud() -> void:
	rect(0,0,960,72,DARK)
	txt("痰途",22,34,25,YELLOW)
	txt("全勤之路",23,55,12,CREAM)
	txt(Rules.DAYS[day],138,31,20)
	var fraction := clampf(distance/maxf(target_distance,1),0,1)
	rect(139,45,300,9,Color("355259")); rect(139,45,300*fraction,9,GREEN)
	txt("%d%%" % int(fraction*100),451,54,13,GREEN)
	txt("打卡倒计时",524,28,12,Color("a7beb6"))
	var seconds := maxi(0,ceili(time_limit-elapsed))
	txt("%02d:%02d" % [seconds/60,seconds%60],524,56,25,YELLOW if seconds>30 else RED)
	txt("衣服状态",663,28,12,Color("a7beb6"))
	txt("一 尘 不 染",663,53,18,GREEN)
	if save_warning: txt("浏览器存储不可用，本次进度仅在页面内保留",290,81,12,RED)
	# Small side readouts keep the road fully visible.
	panel(Rect2(16,91,166,131),INK)
	txt("今日路况",30,118,14,YELLOW)
	txt(Rules.ZONES[mini(4,int(fraction*5))],30,147,18)
	txt("公园绕行" if route=="park" else ("施工近道" if route=="shortcut" else "普通街道"),30,173,14,GREEN)
	txt("风 → %d" % int(wind) if wind else "无风 · 宜走位",30,201,13,CREAM)
	panel(Rect2(778,91,165,153),INK)
	txt("通勤小账本",793,118,14,YELLOW)
	txt("惊险闪避  %02d" % near_misses,793,148,16)
	draw_coin(Vector2(804,170),.6)
	txt(str(coins),824,179,24,YELLOW if wallet_flash>0 else CREAM)
	txt("第 %d 次出门" % attempts,793,205,13,GREEN)
	txt("通勤第 %d 天" % (day+1),793,228,12,CREAM)
	panel(Rect2(778,257,165,112),INK)
	txt("装备就绪",793,281,14,YELLOW)
	var defense := "未装备防御"
	if equipped.has(4): defense = "护盾 " + ("就绪" if shield_cooldown <= 0 else "%.1fs" % shield_cooldown)
	if equipped.has(5): defense = "雨伞 " + ("E 撑开" if umbrella_cooldown <= 0 else "%.1fs" % umbrella_cooldown)
	txt(defense,793,305,14)
	txt("泡泡炮 " + ("F 发射" if attack_cooldown <= 0 else "%.1fs" % attack_cooldown) if has_blaster() else "未装备攻击",793,329,14,GREEN)
	txt("回投 " + ("就绪" if recycler_cooldown <= 0 else "%.1fs" % recycler_cooldown) if equipped.has(8) else ("磁铁吸金中" if equipped.has(7) else "未装备辅助"),793,352,13,YELLOW)
	draw_perk_hud()
	rect(0,527,960,73,DARK)
	txt("体力",23,550,13,CREAM)
	rect(23,561,159,10,Color("355259")); rect(23,561,159*stamina/100,10,GREEN if stamina>25 else RED)
	txt("%d km/h" % int(speed*.2),198,567,15,YELLOW)
	txt("P 暂停 / 空格 铃",752,555,13,CREAM)
	txt("铃铛冷却 %.1fs" % bell_cooldown if bell_cooldown>0 else "叮铃铃，打工人！",752,578,13,GREEN)
	if toast_time>0:
		var width := font.get_string_size(toast,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+32
		rect((960-width)/2,486,width,29,INK)
		txt(toast,(960-width)/2+16,507,16,YELLOW)

func draw_brief() -> void:
	panel(Rect2(210,90,540,430))
	centered("出门前，做个心理建设",132,15,TEAL)
	centered(Rules.DAYS[day],189,31)
	centered(["今天的 KPI：衬衫保持出厂设置。", "人多不是问题，问题是他们都想清嗓子。", "风会吹弯弹道。看预警，也看风向。", "路上有坑，老板的饼也不小。", "四天都过来了，别在公司门口破防。 "][day],233,17)
	centered("← A / D → 转向     W / ↑ 冲刺     S / ↓ 刹车",285,17)
	centered("空格 响铃    E 撑伞    F 泡泡炮    P 暂停",318,17)
	centered("局外买装备永久保留，局内三选一临时强化。",354,16)
	centered("每局结束自动回改装铺，花金币再变强。",381,16)
	centered("垃圾落地后撞到即失败！机械臂冷却时仍需躲避。",407,15)
	centered("平安到公司，才是今天的胜利。",436,13,TEAL)

func draw_help() -> void:
	panel(Rect2(200,59,560,505))
	centered("通勤生存手册",109,32)
	var lines := ["① 概率决定路人是否吐痰，真实弹道决定命中。", "② 清嗓和虚线是预警：赶紧离开瞄准位置。", "③ 刹车能等危险飞过；冲刺消耗体力。", "④ 空格响铃；装备后 E 撑伞、F 泡泡炮。", "⑤ 局内三选一；结束回商店，临时强化清空。", "⑥ 垃圾撞到即失败！机械臂可自动捡起回投。", "离开页面自动暂停；进度保存在当前浏览器。"]
	for i in lines.size(): centered(lines[i],160+i*34,16)

func draw_route() -> void:
	panel(Rect2(170,127,620,369))
	centered("导航正在重新规划你的命运",178,29)
	centered("岔路 %d / 2 · 选路时计时暂停" % route_stage,214,15,TEAL)
	txt("摸鱼公园",239,280,26,INK); txt("施工近道",514,280,26,INK)
	txt("更少路人 / 概率降低",239,318,17,INK)
	txt("更多路人 / 概率升高",514,318,17,INK)
	txt("多骑约 7% 路程",239,351,16,TEAL)
	txt("少骑约 4% 路程",514,351,16,TEAL)
	centered("老板：选哪条都行，反正别迟到。",480,15)


func earn_coins(amount: int) -> void:
	coins = mini(9999,coins+amount)
	run_coins += amount
	save_game()

func update_collectibles(dt: float, old_player: Vector2) -> void:
	coin_timer -= dt
	if coin_timer <= 0:
		coin_timer = 4.0
		var x: float = Traffic.LANES[rng.randi_range(0,2)]
		for i in 3: pickups.append({"pos":Vector2(x,-25-i*42),"value":3,"taken":false})
	var player := Vector2(player_x,450)
	for c in pickups:
		var old: Vector2 = c.pos
		c.pos.y += speed*dt
		if c.pos.distance_to(player) < (110 if equipped.has(7) else 0)+perk_level(5)*65:
			c.pos = c.pos.move_toward(player,dt*420)
		if Rules.segment_distance(Vector2.ZERO,old-old_player,c.pos-player) < 23:
			c.taken = true
			earn_coins(c.value+perk_level(3)*2)
			particles.append({"pos":c.pos,"life":.75,"value":c.value+perk_level(3)*2})
			wallet_flash = .4
			sfx("coin")
	pickups = pickups.filter(func(c): return not c.taken and c.pos.y < 640)

func block_spit() -> bool:
	if umbrella_time > 0:
		blocks += 1
		sfx("shield")
		return true
	if equipped.has(4) and shield_cooldown <= 0:
		shield_cooldown = perk_cooldown(18)
		blocks += 1
		sfx("shield")
		notify("护盾挡下了！18秒充能，先靠走位。",2)
		return true
	if spare_guards > 0:
		spare_guards -= 1
		blocks += 1
		sfx("shield")
		notify("防污贴纸替你挡住了！",2)
		return true
	return false

func use_umbrella() -> void:
	if state != "play" or not equipped.has(5) or umbrella_cooldown > 0: return
	umbrella_time = 2.5
	umbrella_cooldown = perk_cooldown(8)
	sfx("shield")
	notify("打工人结界！挡痰，不挡地上垃圾。",2)

func fire_weapon() -> void:
	if state != "play" or not has_blaster() or attack_cooldown > 0: return
	attack_cooldown = perk_cooldown(3)
	for dx in ([-95.0,0.0,95.0] if equipped.has(6) and perk_level(6)>0 else [0.0]):
		shots.append({"kind":"bubble","pos":Vector2(player_x,409),"life":1.6,"dx":dx})
	sfx("shoot")

func silence_vehicle(v: Dictionary, seconds: float) -> void:
	v.silenced = seconds
	v.cough = -1
	v.litter_warn = 0
	v.spit_check = seconds+1
	v.litter_check = seconds+1

func update_shots(dt: float) -> void:
	for shot in shots:
		var old: Vector2 = shot.pos
		shot.life -= dt
		if shot.kind == "return":
			# Keep the original vehicle identity even if it has left the visible traffic list.
			var source: Dictionary = shot.source
			var target: Vector2 = source.pos
			shot.pos = shot.pos.move_toward(target,dt*640)
			if Rules.segment_distance(target,old,shot.pos) < 30:
				shot.life = 0
				silence_vehicle(source,8)
				returns += 1
				earn_coins(12)
				sfx("return")
				notify("垃圾已退回原车！清洁奖励 +12 金。",2.5)
		else:
			shot.pos.y += (speed-520)*dt
			shot.pos.x += shot.get("dx",0)*dt
			for sp in spits:
				if sp.life > 0 and Rules.segment_distance(sp.pos,old,shot.pos) < 28:
					sp.life = 0
					sfx("shield")
			for v in vehicles:
				if Rules.segment_distance(v.pos,old,shot.pos) < Traffic.HALF_SIZE[v.kind].x+15:
					silence_vehicle(v,6)
					shot.life = 0
					attacks += 1
					sfx("shield")
					notify("文明泡泡命中！对方停嘴、停扔6秒。",2)
					break
	shots = shots.filter(func(s): return s.life > 0 and s.pos.y > -160)

func throw_garbage(v: Dictionary) -> void:
	traffic_stats.litter += 1
	var target: Vector2 = v.litter_target
	garbage.append({"pos":Traffic.mouth(v,target),"target":target,"flight":.8,"source":v,"caught":false})
	sfx("trash")

func update_garbage(dt: float, old_player: Vector2) -> void:
	var player := Vector2(player_x,450)
	for g in garbage:
		var old: Vector2 = g.pos
		var was_airborne: bool = g.flight > 0
		if was_airborne:
			g.target.y += speed*dt
			g.pos = g.pos.lerp(g.target,minf(1,dt/g.flight))
			g.flight = maxf(0,g.flight-dt)
		else: g.pos.y += speed*dt
		if equipped.has(8) and recycler_cooldown <= 0 and g.pos.y <= 480 and Rules.segment_distance(Vector2.ZERO,old-old_player,g.pos-player) < 105:
			g.caught = true
			recycler_cooldown = perk_cooldown(7)
			shots.append({"kind":"return","pos":g.pos,"source":g.source,"life":4.0})
			sfx("return")
			notify("机械臂：谁扔的？请签收原件！",2)
		elif not was_airborne and Rules.segment_distance(Vector2.ZERO,old-old_player,g.pos-player) < 27:
			if jump_charges > 0:
				jump_charges -= 1
				g.caught = true
				jump_flash = .5
				sfx("near")
				notify("兔子跳！逃过一次垃圾翻车。",2)
			else:
				fail_run("trash")
				return
	garbage = garbage.filter(func(g): return not g.caught and g.pos.y < 640)

func draw_coin(pos: Vector2, zoom := 1.0) -> void:
	var p := pos.round()
	draw_set_transform(p,0,Vector2.ONE*zoom)
	rect(-10,15,22,4,Color(0,0,0,.25))
	# Stepped circular rim stays readable against the sandy road at native scale.
	for yy in range(-14,15,2):
		var half := int(sqrt(maxf(0,196-yy*yy))/2)*2
		rect(-half,yy,half*2+2,2,Color("704323"))
	for yy in range(-12,13,2):
		var half := int(sqrt(maxf(0,144-yy*yy))/2)*2
		rect(-half,yy,half*2+2,2,Color("ffda4a") if yy<5 else Color("e59a27"))
	rect(-6,-12,14,2,Color("fff5ba")); rect(-10,-8,3,9,Color("fff5ba"))
	var glyph := ["01110","11000","11000","01110","00011","00011","11110"]
	for y in glyph.size():
		for x in 5:
			if glyph[y][x]=="1": rect(-5+x*2,-7+y*2,2,2,Color("98601d"))
	rect(-1,-10,2,19,Color("98601d"))
	if fmod(clock+pos.y*.003,2)<.65:
		rect(8,-16,3,9,CREAM); rect(5,-13,9,3,CREAM)
	draw_set_transform(Vector2.ZERO)

func draw_trash(pos: Vector2) -> void:
	rect(pos.x-15,pos.y+8,30,7,Color(0,0,0,.25))
	rect(pos.x-12,pos.y-8,24,19,Color("947f9e"))
	rect(pos.x-8,pos.y-12,17,25,Color("bbadc4"))
	rect(pos.x-5,pos.y-17,10,6,CREAM)
	rect(pos.x-5,pos.y-5,10,9,RED)
	rect(pos.x-2,pos.y-5,4,9,CREAM)

func draw_garbage(g: Dictionary) -> void:
	if g.flight > 0:
		draw_arc(g.target,23,0,TAU,16,RED,3)
		draw_line(g.target-Vector2(10,10),g.target+Vector2(10,10),RED,3)
		draw_line(g.target+Vector2(10,-10),g.target+Vector2(-10,10),RED,3)
	draw_trash(g.pos)

func perk_level(id: int) -> int:
	return int(buffs.get(id,0))

func perk_cooldown(base: float) -> float:
	return base*pow(.8,perk_level(7))

func has_blaster() -> bool:
	return equipped.has(6) or perk_level(6)>0

func reset_perks() -> void:
	buffs.clear(); perk_choices.clear()
	perk_stage=0;spare_guards=0;jump_charges=0;jump_flash=0

func offer_perks() -> void:
	if state != "play" or perk_stage >= 4: return
	var pool: Array[int] = []
	for i in Perks.ITEMS.size():
		if perk_level(i) >= Perks.ITEMS[i].max: continue
		if i==7 and not (equipped.has(4) or equipped.has(5) or equipped.has(8) or has_blaster()): continue
		pool.append(i)
	perk_choices.clear()
	for i in mini(3,pool.size()):
		var index := rng.randi_range(0,pool.size()-1)
		perk_choices.append(pool[index]);pool.remove_at(index)
	perk_stage += 1
	stop_audio()
	change_state("upgrade")

func choose_perk(index: int) -> void:
	if state != "upgrade" or index < 0 or index >= perk_choices.size(): return
	var id: int = perk_choices[index]
	buffs[id] = perk_level(id)+1
	if id==1: stamina=100
	if id==2: spare_guards+=1
	if id==8: jump_charges+=1
	perk_choices.clear()
	change_state("play")
	start_music();sfx("win")
	notify("获得「%s」！仅本局生效。"%Perks.ITEMS[id].name,3)

func update_pickup_fx(dt: float) -> void:
	wallet_flash=maxf(0,wallet_flash-dt)
	jump_flash=maxf(0,jump_flash-dt)
	for fx in particles:
		fx.life-=dt
		fx.pos.y-=dt*46
	particles=particles.filter(func(fx):return fx.life>0)

func draw_pickup_fx() -> void:
	for fx in particles:
		var alpha := minf(1,fx.life*3)
		rect(fx.pos.x-18,fx.pos.y-37,47,27,Color(INK,alpha*.95))
		txt("+%d"%fx.value,fx.pos.x-12,fx.pos.y-17,21,Color(YELLOW,alpha))
		for i in 5:
			var offset: Vector2 = Vector2(cos(i*TAU/5),sin(i*TAU/5))*(.75-fx.life)*50
			rect(fx.pos.x+offset.x,fx.pos.y+offset.y,4,4,Color(CREAM,alpha))

func draw_perk_hud() -> void:
	if buffs.is_empty(): return
	panel(Rect2(16,243,166,225),INK)
	txt("本局强化  %d/4"%perk_stage,29,269,14,YELLOW)
	var row := 0
	for id in buffs:
		var name: String = Perks.ITEMS[id].name
		var suffix := " ×%d"%perk_level(id)
		if id==2: suffix=" %d次"%spare_guards
		if id==8: suffix=" %d次"%jump_charges
		rect(29,289+row*37,5,20,Color(Perks.ITEMS[id].color))
		txt(name+suffix,40,305+row*37,13,CREAM)
		row+=1
	txt("结束后清空",29,452,12,Color("a7beb6"))
