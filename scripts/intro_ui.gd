extends CanvasLayer
const SceneArt=preload("res://scripts/intro_art.gd")
const Icon=preload("res://scripts/reward_art.gd")
var game
var root: Control
var actions: Array[Button]=[]
func setup(owner_game) -> void:
	game=owner_game;layer=12;root=Control.new();root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
func text(value: String,box: Rect2,point: int,color:=Color("fff3d1"),center:=false) -> Label:
	var node:=Label.new();node.text=value;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font",game.font);node.add_theme_font_size_override("font_size",point);node.add_theme_color_override("font_color",color)
	if center:node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(node);node.position=box.position;node.size=box.size;return node
func button(value: String,box: Rect2,callback: Callable,primary:=false) -> Button:
	var b:=Button.new();b.text=value;b.focus_mode=Control.FOCUS_NONE
	b.add_theme_font_override("font",game.font);b.add_theme_font_size_override("font_size",24 if primary else 20)
	for state in ["normal","hover","pressed"]:
		var style:=StyleBoxFlat.new();style.bg_color=Color("f2d27d") if primary else Color("3b5568");style.border_color=Color("fff3d1") if primary else Color("69838b");style.set_border_width_all(3)
		if state=="pressed":style.bg_color=Color("a4d577")
		b.add_theme_stylebox_override(state,style)
	b.add_theme_color_override("font_color",Color("26374b") if primary else Color("fff3d1"))
	b.pressed.connect(func():game.sfx("click");callback.call());root.add_child(b);b.position=box.position;b.size=box.size;actions.append(b);return b
func build() -> void:
	for c in root.get_children():root.remove_child(c);c.queue_free()
	actions.clear();root.visible=game.state in ["menu","brief"]
	if not root.visible:return
	var size: Vector2=Vector2(game.get_window().content_scale_size)-Vector2(0,game.safe_top+game.safe_bottom)
	root.position=Vector2(0,game.safe_top);root.size=size
	var bg:=ColorRect.new();bg.size=size;bg.color=Color("223b4b");bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(bg)
	var tall:=size.x<700
	var margin:=20.0
	var x:=margin if tall else size.x*.60
	var w:=size.x-2*margin if tall else size.x-x-margin
	var touch:=maxf(64,44.0*game.get_window().content_scale_size.x/game.get_window().size.x)
	var brief: bool=game.state=="brief"
	var rows:=2 if brief else (3 if not game.saved.is_empty() else 2)
	var controls_y:=size.y-20-rows*touch-(rows-1)*10
	var art_box:=Rect2(margin,110,size.x-2*margin,controls_y-124) if tall else Rect2(margin,116,x-40,size.y-140)
	if brief and tall:art_box.size.y-=108
	var art:=SceneArt.new();art.game=game;root.add_child(art);art.position=art_box.position;art.size=art_box.size
	if brief:
		text("周"+["一","二","三","四","五"][game.day]+" · 出门上班",Rect2(margin,12,size.x-140,45),30,Color("f2d27d"))
		text("约 %d 秒 · 干净到公司"%int(game.Rules.duration(game.mode,game.day)),Rect2(margin,62,size.x-40,34),21)
		var tips_y:=controls_y-104 if tall else 126.0
		for i in 3:
			var box:=Rect2(x+i*w/3,tips_y,w/3,94)
			var icon:=Icon.new();icon.id=[13,4,0][i];icon.size=Vector2(64,64);icon.position=box.position+Vector2((box.size.x-64)/2,0);root.add_child(icon)
			text(["车下滑动" if game.mobile else "方向键转向","听咳躲痰","捡金改装"][i],Rect2(box.position+Vector2(0,64),Vector2(box.size.x,29)),18,Color("b9cfce"),true)
		if not tall:
			text("这次，别让工服先下班。",Rect2(x,230,w,35),19,Color("b9cfce"),true)
		button("出门上班 →",Rect2(x,controls_y,w,touch),game.begin_run,true)
		button("改装铺",Rect2(x,controls_y+touch+10,w*.64-5,touch),func():game.open_shop("brief"))
		button("返回",Rect2(x+w*.64+5,controls_y+touch+10,w*.36-5,touch),func():game.change_state("menu"))
	else:
		text("痰途",Rect2(margin,4,210,64),48,Color("f2d27d"))
		text("全勤之路 · 一趟约90秒",Rect2(margin,68,size.x-40,32),21,Color("b9cfce"))
		if not tall:text("全勤奖可以没有，\n这口痰必须躲开。",Rect2(x,150,w,90),26,Color("f2d27d"),true)
		button("开始",Rect2(x,controls_y,w,touch),game.request_new_game,true)
		if not game.saved.is_empty():
			button("继续",Rect2(x,controls_y+touch+10,w,touch),game.resume_save)
		button("玩法 / 声音",Rect2(x,size.y-20-touch,w,touch),func():game.change_state("help"))
