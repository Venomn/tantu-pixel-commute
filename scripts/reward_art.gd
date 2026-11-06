extends Control
const INK=Color("26374b")
const CREAM=Color("fff3d1")
const TEAL=Color("69b8a8")
const YELLOW=Color("f2d27d")
const RED=Color("df8177")
const GREEN=Color("a4d577")
var id := 0
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func rect(x: float,y: float,w: float,h: float,color: Color) -> void:draw_rect(Rect2(x,y,w,h),color)
func _draw() -> void:
	draw_set_transform(size/2,0,Vector2.ONE*minf(size.x,size.y)/64)
	if id==0:
		draw_circle(Vector2.ZERO,21,INK);draw_circle(Vector2.ZERO,17,YELLOW);draw_arc(Vector2.ZERO,12,0,TAU,12,Color("b78035"),3)
		rect(-3,-10,6,20,CREAM);rect(-7,-6,14,3,CREAM);rect(-7,3,14,3,CREAM)
		return
	match id:
		1:
			for i in 8:
				var p := Vector2(cos(i*PI/4),sin(i*PI/4))*14
				rect(p.x-3,p.y-3,6,6,TEAL)
			draw_arc(Vector2.ZERO,10,0,TAU,12,INK,6)
			rect(-3,-3,6,6,YELLOW)
		2:
			draw_line(Vector2(-16,-11),Vector2(10,-11),INK,6)
			draw_line(Vector2(8,-11),Vector2(-7,13),TEAL,5)
			draw_line(Vector2(-7,13),Vector2(-17,15),INK,5)
			rect(-3,-13,6,6,YELLOW)
		3:
			draw_line(Vector2(4,17),Vector2(4,0),INK,4)
			rect(-12,-16,27,20,INK);rect(-9,-13,21,14,Color("90cfdd"))
			rect(-6,-11,10,3,CREAM)
		4:
			draw_colored_polygon(PackedVector2Array([Vector2(-15,-15),Vector2(15,-15),Vector2(13,7),Vector2(0,19),Vector2(-13,7)]),INK)
			draw_colored_polygon(PackedVector2Array([Vector2(-11,-11),Vector2(11,-11),Vector2(9,5),Vector2(0,13),Vector2(-9,5)]),Color("78b6df"))
			rect(-2,-7,4,16,CREAM);rect(-7,-1,14,4,CREAM)
		5:
			draw_line(Vector2.ZERO,Vector2(0,16),INK,4)
			draw_colored_polygon(PackedVector2Array([Vector2(-19,0),Vector2(-12,-13),Vector2(0,-18),Vector2(12,-13),Vector2(19,0)]),RED)
			draw_line(Vector2(0,-18),Vector2.ZERO,CREAM,3)
		6:
			rect(-14,-8,28,17,INK);rect(-11,-5,22,11,TEAL)
			rect(-6,8,8,10,INK);rect(12,-11,7,23,Color("78b6df"))
			draw_arc(Vector2(24,-5),5,0,TAU,10,TEAL,2)
		7:
			rect(-14,-14,8,27,RED);rect(6,-14,8,27,Color("78b6df"));rect(-14,9,28,8,INK)
			rect(-14,-15,8,7,CREAM);rect(6,-15,8,7,CREAM)
		8:
			draw_line(Vector2(-15,15),Vector2(-6,-2),INK,8)
			draw_line(Vector2(-6,-2),Vector2(9,-10),YELLOW,7)
			draw_arc(Vector2(12,-12),9,0,PI*1.5,8,INK,4)
			rect(-19,12,16,6,TEAL)
		9:
			rect(-9,-15,18,29,INK);rect(-6,-12,12,22,RED)
			rect(-4,-18,8,4,CREAM);rect(-4,-5,8,5,CREAM)
		10:
			rect(-12,-7,24,21,CREAM);rect(-11,-23,7,20,CREAM);rect(5,-23,7,20,CREAM)
			rect(-9,-20,3,12,RED);rect(7,-20,3,12,RED)
			rect(-7,-2,4,5,INK);rect(4,-2,4,5,INK);rect(-2,5,5,4,RED)
		11:
			for i in 3:
				rect(-19+i*4,-12+i*11,29-i*2,4,TEAL)
				draw_arc(Vector2(10+i*2,-13+i*11),6,-PI/2,PI/2,8,TEAL,3)
		12:
			rect(-12,-16,24,32,INK);rect(-5,-20,10,5,INK);rect(-9,-13,18,26,GREEN)
			draw_colored_polygon(PackedVector2Array([Vector2(1,-10),Vector2(-6,2),Vector2(0,2),Vector2(-2,12),Vector2(7,-2),Vector2(2,-2)]),CREAM)
		13:
			rect(-12,-13,15,27,TEAL);rect(-12,5,30,12,TEAL);rect(-12,14,31,4,INK)
			rect(-7,-9,9,3,CREAM);rect(-7,-2,9,3,CREAM)
