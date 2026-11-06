class_name CommuteEquipment
extends RefCounted

# IDs 1–3 preserve the original save's gear identity.
const ITEMS = [
 {"name":"轻便齿盘","slot":"骑行","price":80,"lines":["体力恢复 +35%","让冲刺更持久"]},
 {"name":"灵敏刹车","slot":"骑行","price":80,"lines":["加减速响应 +57%","刹车躲弹更灵活"]},
 {"name":"观察后视镜","slot":"骑行","price":80,"lines":["吐痰预警 +0.3秒","提前发现坏心思"]},
 {"name":"防痰护盾","slot":"防御","price":100,"lines":["自动挡一口痰","18秒后重新充能"]},
 {"name":"打工人雨伞","slot":"防御","price":140,"lines":["按 E 挡痰 2.5秒","冷却8秒，不挡垃圾"]},
 {"name":"文明泡泡炮","slot":"攻击","price":180,"lines":["按 F 发射，冷却3秒","消痰 / 让前方车停嘴"]},
 {"name":"招财磁铁","slot":"辅助","price":100,"lines":["自动吸取附近金币","与回投机械臂二选一"]},
 {"name":"垃圾回投机械臂","slot":"辅助","price":320,"lines":["自动捡垃圾扔回原车","近身自动 / 冷却7秒"]}
]
static func valid(id: int) -> bool: return id >= 1 and id <= ITEMS.size()
static func select(current: Array, id: int) -> Array:
 var result: Array = []
 for other in current:
  if valid(other) and ITEMS[other-1].slot != ITEMS[id-1].slot: result.append(other)
 result.append(id)
 return result
