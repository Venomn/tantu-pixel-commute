extends Control
# Original pixel-workshop drawing; preview is supplied without mutating player assets.
const INK=Color("26374b")
const CREAM=Color("fff3d1")
const GOLD=Color("f2d27d")
const TEAL=Color("69b8a8")
const RED=Color("df8177")
var gear: Array=[]
var icon_id := 0
var time := 0.0
var flash := 0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;set_process(icon_id==0)
func _process(dt: float) -> void:
	time+=dt;flash=maxf(0,flash-dt);queue_redraw()
func r(x: float,y: float,w: float,h: float,c: Color) -> void:draw_rect(Rect2(x,y,w,h),c)
func line(a: Vector2,b: Vector2,c: Color,w := 4.0) -> void:draw_line(a,b,c,w,false)
func wheel(p: Vector2) -> void:
	draw_arc(p,33,0,TAU,16,INK,9)
	draw_arc(p,27,0,TAU,16,CREAM,3)
	for i in 8:
		var v := Vector2(cos(i*TAU/8),sin(i*TAU/8))*26
		line(p,p+v,Color("8599a1"),2)
	draw_circle(p,5,GOLD)
func _draw() -> void:
	if icon_id>0:
		draw_set_transform(size/2,0,Vector2.ONE*minf(size.x,size.y)/46)
		draw_icon(icon_id)
		return
	draw_set_transform(Vector2.ZERO,0,size/Vector2(440,240))
	# Pegboard, warm lamp, tool cabinet, floor tiles and repair stand.
	r(0,0,440,240,Color("b6c9b5"));r(0,0,440,12,INK)
	for x in range(14,440,20):
		for y in range(22,130,20):r(x,y,3,3,Color("849b8e"))
	r(0,148,440,92,Color("758d8c"))
	for x in range(0,440,44):line(Vector2(x,148),Vector2(x-50,240),Color("94aaa0"),2)
	for y in [164,188,216]:r(0,y,440,2,Color("94aaa0"))
	r(162,8,116,7,INK);r(184,15,72,6,GOLD)
	draw_colored_polygon(PackedVector2Array([Vector2(184,21),Vector2(256,21),Vector2(346,172),Vector2(94,172)]),Color(1,.94,.64,.16))
	r(12,90,61,101,INK);r(17,96,51,88,Color("b37e65"))
	for y in [104,130,156]:r(20,y,45,21,Color("d69b74"));r(37,y+5,12,4,INK)
	r(364,112,62,79,INK);r(369,118,52,66,Color("647c91"))
	for i in 3:r(375,128+i*18,40,3,CREAM)
	for x in [87,115,324,348]:
		line(Vector2(x,29),Vector2(x,68),INK,6);draw_arc(Vector2(x,26),8,0,PI,6,GOLD,4)
	# Bicycle silhouette, repair stand and visible parts.
	r(88,208,258,9,Color(0,0,0,.18))
	line(Vector2(220,176),Vector2(220,212),INK,6);line(Vector2(196,214),Vector2(244,214),INK,6)
	wheel(Vector2(126,171));wheel(Vector2(311,171))
	var frame_color := TEAL if not gear.has(1) else GOLD
	for pair in [[Vector2(126,171),Vector2(179,113)],[Vector2(179,113),Vector2(211,174)],[Vector2(211,174),Vector2(126,171)],[Vector2(179,113),Vector2(280,113)],[Vector2(280,113),Vector2(211,174)],[Vector2(280,113),Vector2(311,171)]]:
		line(pair[0],pair[1],INK,10);line(pair[0],pair[1],frame_color,5)
	line(Vector2(179,113),Vector2(169,91),INK,6);r(153,86,36,8,INK);r(157,84,28,4,RED)
	line(Vector2(280,113),Vector2(272,80),INK,6);line(Vector2(271,80),Vector2(297,76),INK,6)
	line(Vector2(297,76),Vector2(306,88),INK,5)
	draw_arc(Vector2(211,174),12,0,TAU,12,INK,5)
	line(Vector2(211,174),Vector2(231,183),INK,5);r(224,182,17,5,INK)
	line(Vector2(126,174),Vector2(211,184),Color("61777a"),3)
	if gear.has(1):
		draw_arc(Vector2(211,174),13,0,TAU,12,GOLD,5)
		for i in 8:
			var p:=Vector2(211,174)+Vector2(cos(i*PI/4),sin(i*PI/4))*16;r(p.x-3,p.y-3,6,6,INK)
	if gear.has(2):
		r(299,137,8,17,RED);r(315,137,8,17,RED);line(Vector2(302,88),Vector2(310,141),CREAM,2)
	if gear.has(3):
		line(Vector2(281,81),Vector2(292,50),INK,4);r(286,37,27,18,INK);r(290,40,19,11,Color("a5dce5"));r(292,42,8,3,CREAM)
	if gear.has(4):
		draw_arc(Vector2(218,141),106,PI,TAU,24,Color("83d3eb"),4)
		draw_set_transform(Vector2(210,113)*size/Vector2(440,240),0,size/Vector2(440,240)*.7);draw_icon(4);draw_set_transform(Vector2.ZERO,0,size/Vector2(440,240))
	if gear.has(5):
		line(Vector2(240,113),Vector2(240,52),INK,5)
		draw_colored_polygon(PackedVector2Array([Vector2(186,58),Vector2(201,32),Vector2(239,18),Vector2(277,32),Vector2(294,58)]),RED)
		line(Vector2(240,19),Vector2(240,58),CREAM,3);line(Vector2(240,19),Vector2(211,58),CREAM,2)
	if gear.has(6):
		r(292,91,43,17,INK);r(297,94,36,11,TEAL);r(330,87,9,25,Color("a5dce5"))
		var x := 349+fmod(time*17,20);draw_arc(Vector2(x,92),7,0,TAU,10,CREAM,2)
	if gear.has(7):
		r(103,112,10,28,RED);r(127,112,10,28,Color("83d3eb"));r(103,134,34,10,INK);r(103,108,10,8,CREAM);r(127,108,10,8,CREAM)
	if gear.has(8):
		line(Vector2(151,125),Vector2(133,85),INK,10);line(Vector2(133,85),Vector2(91,73),GOLD,9)
		draw_circle(Vector2(133,85),8,INK);draw_arc(Vector2(82,71),13,PI*.5,PI*1.8,8,INK,6)
	if flash>0:
		for i in 8:
			var p:=Vector2(220,130)+Vector2(cos(i*TAU/8),sin(i*TAU/8))*(90+(1-flash)*50)
			r(p.x-2,p.y-7,4,14,GOLD);r(p.x-7,p.y-2,14,4,GOLD)

func draw_icon(id: int) -> void:
	match id:
		1:
			for i in 8:
				var p:=Vector2(cos(i*PI/4),sin(i*PI/4))*15;r(p.x-3,p.y-3,6,6,INK)
			draw_arc(Vector2.ZERO,10,0,TAU,12,GOLD,7);r(-3,-3,6,6,INK)
		2:
			line(Vector2(-16,-12),Vector2(12,-12),INK,6);line(Vector2(12,-12),Vector2(-6,14),RED,6);r(-17,10,13,7,INK)
		3:
			line(Vector2(4,17),Vector2(4,-4),INK,4);r(-13,-17,29,21,INK);r(-9,-13,21,13,Color("9bd3de"));r(-6,-10,9,3,CREAM)
		4:
			draw_colored_polygon(PackedVector2Array([Vector2(-15,-16),Vector2(15,-16),Vector2(12,7),Vector2(0,20),Vector2(-12,7)]),INK)
			draw_colored_polygon(PackedVector2Array([Vector2(-11,-12),Vector2(11,-12),Vector2(8,5),Vector2(0,14),Vector2(-8,5)]),Color("83d3eb"));r(-2,-8,4,17,CREAM);r(-7,-2,14,4,CREAM)
		5:
			line(Vector2.ZERO,Vector2(0,18),INK,4)
			draw_colored_polygon(PackedVector2Array([Vector2(-20,0),Vector2(-12,-13),Vector2(0,-18),Vector2(12,-13),Vector2(20,0)]),RED);line(Vector2(0,-17),Vector2.ZERO,CREAM,3)
		6:
			r(-16,-8,29,18,INK);r(-12,-4,25,10,TEAL);r(-7,10,8,10,INK);r(12,-12,7,25,Color("83d3eb"));draw_arc(Vector2(24,-7),5,0,TAU,8,TEAL,2)
		7:
			r(-15,-15,9,28,RED);r(6,-15,9,28,Color("83d3eb"));r(-15,10,30,9,INK);r(-15,-16,9,8,CREAM);r(6,-16,9,8,CREAM)
		8:
			line(Vector2(-16,16),Vector2(-6,-3),INK,9);line(Vector2(-6,-3),Vector2(10,-11),GOLD,8);draw_arc(Vector2(13,-13),9,0,PI*1.5,8,INK,5);r(-21,14,18,6,TEAL)
