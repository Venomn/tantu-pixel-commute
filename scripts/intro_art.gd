extends Control
var game
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE;clip_contents=true
func _process(_dt: float) -> void:queue_redraw()
func sprite(name: String,pos: Vector2,z: float) -> void:
	var texture: Texture2D=game.pixels[name];draw_texture_rect(texture,Rect2(pos.round(),texture.get_size()*z),false)
func _draw() -> void:
	if not game:return
	var z:=maxf(1.5,minf(size.x/200,size.y/150))
	var center:=size.x*.5
	draw_rect(Rect2(Vector2.ZERO,size),Color("9ab783"))
	for x in range(0,int(size.x),32):
		for y in range(0,int(size.y),32):sprite("grass",Vector2(x,y),2)
	var road:=Rect2(center-56*z,0,112*z,size.y)
	draw_rect(road.grow(8),Color("eee6b9"));draw_rect(road,Color("d5cc9a"))
	for y in range(-30,int(size.y)+30,40):
		var scroll:=fmod(game.clock*35,40)
		draw_rect(Rect2(center-1,y+scroll,3,19),Color("fff3d1"))
	for side in [-1,1]:
		sprite("tree",Vector2(center+side*82*z-16*z,size.y*.2),z)
		sprite("flowers",Vector2(center+side*80*z-8*z,size.y*.65),z)
	var bob:=sin(game.clock*5)*2
	var rider_zoom:=z*1.3
	sprite("bike0_%d"%(int(game.clock*8)%2),Vector2(center-12*rider_zoom,size.y*.48-17*rider_zoom+bob),rider_zoom)
	for side in [-1,1]:
		sprite("lamp",Vector2(center+side*60*z-4*z,size.y*.60),z*.8)
	for i in 12:
		draw_rect(Rect2(center-54*z+i*9*z,size.y*.04,9*z,5*z),Color("fff3d1") if i%2==0 else Color("3a4b68"))
	for i in 3:
		var p:=Vector2(center+(i-1)*25*z,size.y*.15+sin(game.clock*3+i)*3)
		draw_circle(p,6*z,Color("805635"));draw_circle(p,4.5*z,Color("f2d27d"));draw_line(p-Vector2(0,3*z),p+Vector2(0,3*z),Color("fff3d1"),2)
