extends Control
var game
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE;clip_contents=true
func _process(_dt: float) -> void:queue_redraw()
func _draw() -> void:
	if not game:return
	var t: float=game.crash_time
	var origin: Vector2=game.to_global(Vector2(game.player_x,432))-Vector2(0,game.safe_top)
	var p:=origin.lerp(Vector2(size.x*(.28 if size.x>=700 else .5),size.y*.42),smoothstep(0,.35,t))
	var scale_factor:=minf(4.0,size.y/135)
	var texture: Texture2D=game.pixels.bike0_0
	var angle:=sin(t*15)*.13
	var shift:=Vector2.ZERO
	if game.result_reason=="trash":
		angle=minf(PI*.55,t*4);shift=Vector2(sin(t*7)*18,-absf(sin(t*4))*45)
	elif game.result_reason=="late":shift.y=absf(sin(t*8))*12
	draw_circle(p+Vector2(0,56),45,Color(0,0,0,.18))
	draw_set_transform(p+shift,angle,Vector2.ONE*scale_factor)
	draw_texture(texture,-texture.get_size()/2)
	draw_set_transform(Vector2.ZERO)
	if game.result_reason=="spit":
		for i in 9:
			var direction:=Vector2(cos(i*TAU/9),sin(i*TAU/9))
			var distance:=minf(54,t*120)*(1-.25*sin(t*4))
			draw_circle(p+Vector2(0,-34)+direction*distance,8+3*sin(i),Color("a4d577"))
		draw_circle(p+Vector2(0,-30),23,Color("91b662"))
		draw_line(p+Vector2(-10,-34),p+Vector2(-3,-27),Color("365164"),3);draw_line(p+Vector2(8,-34),p+Vector2(1,-27),Color("365164"),3)
	elif game.result_reason=="late":
		var clock_pos:=p+Vector2(54,-65)
		draw_circle(clock_pos,30,Color("f2d27d"));draw_circle(clock_pos,24,Color("fff3d1"))
		draw_line(clock_pos,clock_pos+Vector2(cos(t*15),sin(t*15))*20,Color("26374b"),4)
		draw_line(clock_pos,clock_pos+Vector2(0,-13),Color("df8177"),3)
	for i in 5:
		var star:=p+Vector2(cos(t*4+i*TAU/5)*73,-80+sin(t*4+i*TAU/5)*15)
		draw_rect(Rect2(star-Vector2(2,7),Vector2(4,14)),Color("f2d27d"));draw_rect(Rect2(star-Vector2(7,2),Vector2(14,4)),Color("f2d27d"))
