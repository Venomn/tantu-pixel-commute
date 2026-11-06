class_name CommuteTraffic
extends RefCounted

const LANES = [335.0, 480.0, 625.0]
const NAMES = ["自行车", "摩托车", "小汽车"]
const HALF_SIZE = [Vector2(20, 38), Vector2(25, 42), Vector2(38, 58)]
const CONTACT_HALF = [Vector2(12,26),Vector2(17,29),Vector2(32,57)]
const CONTACT_OFFSET = [Vector2(0,-10),Vector2(0,-8),Vector2.ZERO]

static func create(kind: int, lane: int, from_behind: bool, rng: RandomNumberGenerator) -> Dictionary:
	var cruise: float = [57.0, 70.0, 62.0][kind] if not from_behind else [124.0, 153.0, 138.0][kind]
	return {"kind":kind, "lane":lane, "pos":Vector2(LANES[lane], 660 if from_behind else -90),
		"old_pos":Vector2(LANES[lane], 660 if from_behind else -90), "speed":cruise, "cruise":cruise,
		"phase":"cruise", "phase_time":0.0, "decision":rng.randf_range(2.5,4.5),
		"cough":-1.0, "spit_check":rng.randf_range(2.5,4.0), "target":Vector2.ZERO,
		"litterer":kind == 2 and rng.randf() < 0.55, "litter_check":3.0, "litter_warn":0.0, "litter_target":Vector2.ZERO, "silenced":0.0,
		"hit_cooldown":0.0, "age":0.0, "color":rng.randi_range(0,3), "from_behind":from_behind,"departing":false}

static func begin_action(v: Dictionary, action: String) -> void:
	v.phase = action + "_warn"
	v.phase_time = 0.7 if action == "brake" else 0.55

static func mouth(v: Dictionary, target: Vector2) -> Vector2:
	var side := -1.0 if target.x < v.pos.x else 1.0
	return v.pos + Vector2(side * (39.0 if v.kind == 2 else 18.0), -18)

static func step(v: Dictionary, dt: float, player_speed: float, rng: RandomNumberGenerator) -> Array[String]:
	var events: Array[String] = []
	v.age += dt
	v.silenced = maxf(0, v.silenced-dt)
	v.litter_check -= dt
	v.old_pos = v.pos
	v.hit_cooldown = maxf(0, v.hit_cooldown-dt)
	v.spit_check -= dt
	v.decision -= dt
	if v.age > 28 and not v.departing:
		v.departing = true
		v.cruise = 190
		begin_action(v,"accelerate")
	if v.phase != "cruise":
		v.phase_time -= dt
		if v.phase_time <= 0:
			match v.phase:
				"brake_warn":
					v.phase = "brake"
					v.phase_time = 1.4
					events.append("brake")
				"accelerate_warn":
					v.phase = "accelerate"
					v.phase_time = 2.2
					events.append("accelerate")
				_:
					v.phase = "cruise"
					v.decision = rng.randf_range(2.0,4.5)
	if v.phase == "cruise" and v.decision <= 0 and v.pos.y > 100 and v.pos.y < 485 and not v.departing:
		var choice := rng.randf()
		if choice < 0.35:
			begin_action(v,"brake")
			events.append("brake_warn")
		elif choice < 0.7:
			begin_action(v,"accelerate")
			events.append("accelerate_warn")
		else: v.decision = rng.randf_range(2.0,4.0)
	var desired: float = v.cruise
	if v.phase == "brake": desired = 0
	elif v.phase == "accelerate": desired = minf(v.cruise+85,205)
	v.speed = move_toward(v.speed,desired,dt*(320 if v.phase == "brake" else 70))
	v.pos.y += (player_speed-v.speed)*dt
	return events

static func contacts_player(v: Dictionary, old_player: Vector2, player: Vector2) -> bool:
	# Swept collision in relative coordinates catches high-speed passing in either direction.
	var half: Vector2=CONTACT_HALF[v.kind]+CommuteRules.RIDER_WHEELS_HALF
	var a: Vector2=v.old_pos+CONTACT_OFFSET[v.kind]-old_player-CommuteRules.RIDER_WHEELS_OFFSET
	var b: Vector2=v.pos+CONTACT_OFFSET[v.kind]-player-CommuteRules.RIDER_WHEELS_OFFSET
	return CommuteRules.ellipse_sweep(a,b,half)
