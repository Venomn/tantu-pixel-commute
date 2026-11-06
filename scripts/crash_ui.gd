extends CanvasLayer
var game
var root: Control
var skip: Button
var shade: ColorRect
func setup(owner_game) -> void:
	game=owner_game;layer=15;root=Control.new();add_child(root)
func _process(_dt: float) -> void:
	if root.visible and skip:
		skip.disabled=game.crash_time<.4
		shade.color.a=lerpf(.2,.92,minf(1,game.crash_time/.3))
func build() -> void:
	for c in root.get_children():root.remove_child(c);c.queue_free()
	root.visible=game.state=="crash"
	if not root.visible:return
	var size: Vector2=Vector2(game.get_window().content_scale_size)-Vector2(0,game.safe_top+game.safe_bottom)
	root.position=Vector2(0,game.safe_top);root.size=size;root.mouse_filter=Control.MOUSE_FILTER_STOP
	var bg:=ColorRect.new();bg.size=size;bg.color=Color("203446",.92);root.add_child(bg);shade=bg
	var art:=preload("res://scripts/crash_art.gd").new();art.game=game;art.size=size;root.add_child(art)
	var titles: Dictionary={"spit":"啪叽！工服中招","trash":"车还在，人先下班","late":"老板：你骑的是日晷？"}
	var notes: Dictionary={"spit":"今日穿搭：抹茶泼墨限定款","trash":"完美落地！除了姿势。","late":"全勤奖：下次一定。"}
	var wide:=size.x>=700
	var text_x:=size.x*.55 if wide else 12.0
	var text_w:=size.x-text_x-12 if wide else size.x-24
	var touch:=maxf(60,44.0*game.get_window().content_scale_size.x/game.get_window().size.x)
	var button_y:=size.y-20-touch
	var caption_y:=minf(size.y*.52 if wide else size.y*.70,button_y-98)
	for row in 2:
		var l:=Label.new();l.text=titles[game.result_reason] if row==0 else notes[game.result_reason]
		l.add_theme_font_override("font",game.font);l.add_theme_font_size_override("font_size",28 if row==0 else 20);l.add_theme_color_override("font_color",Color("f2d27d") if row==0 else Color("fff3d1"));l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.mouse_filter=Control.MOUSE_FILTER_IGNORE
		root.add_child(l);l.position=Vector2(text_x,caption_y+row*42);l.size=Vector2(text_w,42)
	skip=Button.new();skip.text="去改装铺 →";skip.add_theme_font_override("font",game.font);skip.add_theme_font_size_override("font_size",22)
	var style:=StyleBoxFlat.new();style.bg_color=Color("3b5568");style.border_color=Color("f2d27d");style.set_border_width_all(3);skip.add_theme_stylebox_override("normal",style)
	skip.disabled=true;root.add_child(skip);skip.position=Vector2(text_x if wide else size.x*.25,button_y);skip.size=Vector2(text_w if wide else size.x*.5,touch);skip.pressed.connect(game.finish_crash)
