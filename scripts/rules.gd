class_name CommuteRules
extends RefCounted

const Equipment = preload("res://scripts/equipment.gd")

const DAYS = ["周一 · 先活着到公司", "周二 · 人间早高峰", "周三 · 风有自己的想法", "周四 · 前方施工", "周五 · 全勤保卫战"]
const ZONES = ["早餐一条街", "幸福公交站", "文明施工路", "摸鱼公园", "公司最后一公里"]

static func probability(kind: int, day: int, route: String) -> float:
	var p: float = [0.12, 0.28, 0.46][clampi(kind, 0, 2)] + day * 0.025
	if route == "shortcut": p += 0.14
	if route == "park": p -= 0.09
	return clampf(p, 0.05, 0.8)

static func duration(mode: String, day: int) -> float:
	return (75.0 + day * 10.0) if mode == "quick" else (390.0 + day * 15.0)

static func segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var delta := b - a
	if delta.length_squared() < 0.001: return point.distance_to(a)
	return point.distance_to(a + delta * clampf((point - a).dot(delta) / delta.length_squared(), 0.0, 1.0))

static func clean_save(data: Variant) -> Dictionary:
	if not data is Dictionary or (data.get("version") != 1 and data.get("version") != 2): return {}
	if not data.get("day") is float and not data.get("day") is int: return {}
	if data.get("mode") not in ["quick", "week"]: return {}
	for key in ["coins", "gear", "wins"]:
		var value: Variant = data.get(key, 0)
		if not (value is int or value is float): return {}
		if not is_finite(float(value)): return {}
	if not is_finite(float(data.day)): return {}
	var old_gear := clampi(int(data.get("gear", 0)), 0, 3)
	var owned: Array = []
	var equipped: Array = []
	if data.version == 1:
		if old_gear > 0: owned.append(old_gear); equipped.append(old_gear)
	else:
		for key in ["owned", "equipped"]:
			if not data.get(key) is Array: return {}
			for id in data[key]:
				if not (id is int or id is float) or not is_finite(float(id)): return {}
				if float(id) != int(id) or not Equipment.valid(int(id)): return {}
		for id in data.owned:
			if not owned.has(int(id)): owned.append(int(id))
		for id in data.equipped:
			if owned.has(int(id)): equipped = Equipment.select(equipped, int(id))
	old_gear = 0
	for id in equipped:
		if id <= 3: old_gear = id
	return {"version": 2, "owned": owned, "equipped": equipped, "day": clampi(int(data.day), 0, 4), "mode": data.mode,
		"coins": clampi(int(data.get("coins", 0)), 0, 9999), "gear": old_gear,
		"wins": clampi(int(data.get("wins", 0)), 0, 5)}
