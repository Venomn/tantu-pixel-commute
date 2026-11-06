extends CanvasLayer
# Screen-space UI: the world can zoom independently of readable touch targets.
var game
var root: Control
var status: Label
var perks: Label
var steering_dot: ColorRect
var stamina: ProgressBar
var route_progress: ProgressBar
var message: Label
var pad: Rect2
var regions: Dictionary = {}
var fingers: Dictionary = {}
var control_labels: Dictionary = {}
var steering_id := -999
var steering_origin := 0.0
var steering_axis := 0.0
var scroll: ScrollContainer
var built_state := ""
var height := 800.0
var width := 480.0

func setup(owner_game) -> void:
	game = owner_game
	layer = 10
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

func clear_input() -> void:
	fingers.clear(); steering_id = -999; steering_axis = 0
	for key in game.touch: game.touch[key] = false

func background(box: Rect2, color: Color) -> ColorRect:
	var node := ColorRect.new()
	node.position = box.position; node.size = box.size; node.color = color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(node)
	return node

func label(text: String, box: Rect2, size := 22, color := Color("fff3d1")) -> Label:
	var node := Label.new()
	node.text = text; node.position = box.position; node.size = box.size
	node.add_theme_font_override("font",game.font)
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(node)
	return node

func style(color: Color) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color; result.border_color = Color("526780")
	result.set_border_width_all(3); result.set_corner_radius_all(8)
	return result

func action(text: String, parent: Node, callback: Callable, accent := false) -> Button:
	var b := Button.new()
	b.text=text; b.custom_minimum_size.y=68
	b.add_theme_font_override("font",game.font); b.add_theme_font_size_override("font_size",22)
	b.add_theme_stylebox_override("normal",style(Color("f2d27d") if accent else Color("3a4b68")))
	b.add_theme_stylebox_override("pressed",style(Color("a4d577")))
	b.add_theme_color_override("font_color",Color("293b57") if accent else Color("fff3d1"))
	b.focus_mode=Control.FOCUS_NONE
	b.pressed.connect(func(): game.sfx("click");callback.call())
	parent.add_child(b)
	return b

func text_row(text: String, parent: Node, size := 22, color := Color("fff3d1")) -> Label:
	var node := Label.new()
	node.text=text;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_override("font",game.font);node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color)
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(node)
	return node

func build() -> void:
	if not root: return
	var old_scroll := scroll.scroll_vertical if is_instance_valid(scroll) and built_state==game.state else 0
	clear_input();regions.clear();control_labels.clear();scroll=null
	for child in root.get_children(): root.remove_child(child);child.queue_free()
	root.visible=game.mobile
	if not game.mobile:return
	width=game.get_window().content_scale_size.x;height=game.get_window().content_scale_size.y-game.safe_top-game.safe_bottom
	root.position=Vector2(0,game.safe_top)
	root.size=Vector2(width,height);built_state=game.state
	if game.state=="play": build_play();return
	background(Rect2(0,0,width,height),Color("24394c"))
	var margin := maxf(20,(width-600)/2)
	label("痰途 · 全勤之路",Rect2(margin,22,280,40),26,Color("f2d27d"))
	scroll=ScrollContainer.new();scroll.position=Vector2(margin,90);scroll.size=Vector2(width-2*margin,height-110)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var list := VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",16);scroll.add_child(list)
	match game.state:
		"menu":
			text_row("骑车上班，也是一场冒险。",list,30,Color("f2d27d"))
			text_row("滑动转向 · 躲开咳咳 · 捡钱改装",list)
			var picture := TextureRect.new();picture.texture=game.pixels.bike0_0
			picture.custom_minimum_size=Vector2(100,130);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;list.add_child(picture)
			action("开始",list,game.request_new_game,true)
			if not game.saved.is_empty():action("继续 / 回到改装铺",list,game.resume_save)
			action("玩法与声音",list,func():game.change_state("help"))
		"brief":
			text_row(game.Rules.DAYS[game.day],list,30,Color("f2d27d"))
			text_row("左手在底部滑动区左右拖动转向。\n右手按住冲刺或刹车，松手恢复巡航。\n装备技能放在右侧，能边转向边使用。",list)
			text_row("看清嗓预警躲痰；垃圾也要绕开。\n本局强化三选一，每局结束回商店。",list)
			action("出门上班 →",list,game.begin_run,true)
			action("改装铺 / 装备",list,func():game.open_shop("brief"))
			action("主菜单",list,func():game.change_state("menu"))
		"upgrade":
			text_row("通勤奇遇 · 三选一",list,30,Color("f2d27d"))
			text_row("选择期间已暂停 · 仅本局有效",list,20)
			for i in game.perk_choices.size():
				var choice: int = i
				var item: Dictionary=game.Perks.ITEMS[game.perk_choices[i]]
				text_row(item.name+" · "+item.tag,list,25,Color(item.color))
				text_row((item.desc[0]+"\n"+item.desc[1]).replace("按 F","点技能"),list,20)
				action("选择「"+item.name+"」",list,func():game.choose_perk(choice),true)
		"shop":
			text_row("下班改装铺 · %d 金"%game.coins,list,29,Color("f2d27d"))
			text_row("装备永久保留，临时强化已清空。",list,20)
			if not game.last_result.is_empty():
				var reason: String={"arrival":"打卡成功","spit":"衣服中招","trash":"垃圾翻车","late":"迟到啦","quit":"本局结束"}.get(game.last_result.reason,"本局结束")
				text_row("%s · 本局收入 %d 金"%[reason,game.last_result.earned+game.last_result.bonus],list,22)
			action("新一周，出发！" if game.wins==5 else "出发 · 第 %d 天 →"%(game.day+1),list,game.depart_shop,true)
			for i in game.Equipment.ITEMS.size():
				var id: int = i+1
				var item: Dictionary=game.Equipment.ITEMS[i]
				text_row(item.name+" · "+item.slot,list,25,Color("f2d27d"))
				text_row("\n".join(item.lines).replace("按 E","点撑伞").replace("按 F","点泡泡炮"),list,20)
				var b := action("卸下" if game.equipped.has(id) else ("装备" if game.owned.has(id) else "购买 · %d 金"%item.price),list,func():game.buy_gear(id),game.equipped.has(id))
				b.disabled=not game.owned.has(id) and game.coins<item.price
			action("主菜单",list,func():game.change_state("menu"))
		"pause":
			text_row("路边歇一会儿",list,32,Color("f2d27d"))
			text_row("时间和危险都暂停了。",list)
			action("继续骑行",list,game.unpause,true)
			action("音效："+("关" if game.muted else "开"),list,game.toggle_sound)
			action("音乐："+("开" if game.music_on else "关"),list,game.toggle_music)
			action("结束本局 · 回改装铺",list,game.abandon_run)
		"route":
			text_row("路口选择 · 已暂停",list,30,Color("f2d27d"))
			action("公园：人少，路程稍长",list,func():game.choose_route("park"),true)
			action("近道：人多，路程稍短",list,func():game.choose_route("shortcut"))
		"new_confirm":
			text_row("从第一天重新出发？",list,28)
			text_row("金币和装备会保留，日期进度重新开始。",list)
			action("保留装备，重新出发",list,func():game.new_game("week"),true)
			action("返回",list,func():game.change_state("menu"))
		"help":
			text_row("左手滑动，右手加速",list,30,Color("f2d27d"))
			text_row("在滑动区按住并向左 / 右拖动，控制转向；松手停止转向。\n冲刺与刹车需要按住，松手恢复巡航。\n铃铛、泡泡炮和雨伞点一下使用。\n旋转屏幕或切到后台会暂停，避免误操作。\n竖屏和横屏都能玩。",list)
			action("音效："+("关" if game.muted else "开"),list,game.toggle_sound)
			action("音乐："+("开" if game.music_on else "关"),list,game.toggle_music)
			action("返回",list,func():game.change_state("menu"),true)
	scroll.set_deferred("scroll_vertical",old_scroll)

func control(text: String, key: String, box: Rect2) -> void:
	regions[key]=box
	background(box,Color("526780") if key!="sprint" else Color("aa8748"))
	var node := label(text,box.grow(-4),22)
	control_labels[key]=node
	node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER

func build_play() -> void:
	background(Rect2(0,0,width,126 if game.portrait else 76),Color("293b57"))
	var pause := action("暂停",root,game.pause_game)
	pause.position=Vector2(12,12);pause.size=Vector2(86,58);pause.custom_minimum_size.y=58
	label("第 %d 天 · 干净上班"%(game.day+1),Rect2(110,15,width-230,40),22,Color("f2d27d"))
	status=label("",Rect2(16 if game.portrait else 365,77 if game.portrait else 16, width-32 if game.portrait else 400,36),22)
	route_progress=ProgressBar.new();route_progress.position=Vector2(16,114 if game.portrait else 66);route_progress.size=Vector2(width-32,8);route_progress.show_percentage=false;root.add_child(route_progress)
	if not game.portrait:background(Rect2(10,84,224,76),Color("293b57",.9))
	perks=label("",Rect2(16,134 if game.portrait else 90,width-32 if game.portrait else 210,64),18,Color("293b57") if game.portrait else Color("fff3d1"))
	route_progress.add_theme_stylebox_override("background",style(Color("526780")))
	route_progress.add_theme_stylebox_override("fill",style(Color("a4d577")))
	var footer: float=game.mobile_controls_height()
	var bottom := height-footer
	background(Rect2(0,bottom-36 if game.portrait else height-30,width,footer+36 if game.portrait else 30),Color("293b57"))
	stamina=ProgressBar.new();stamina.position=Vector2(16,bottom-25 if game.portrait else height-22);stamina.size=Vector2(width-32,12);stamina.show_percentage=false;root.add_child(stamina)
	stamina.add_theme_stylebox_override("background",style(Color("526780")))
	stamina.add_theme_stylebox_override("fill",style(Color("a4d577")))
	if game.portrait:
		pad=Rect2(12,bottom+8,210,footer-32)
		control("←  滑动转向  →\n按住，左右拖动", "steer",pad)
		control("按住冲刺","sprint",Rect2(234,bottom+8,110,66))
		control("刹车","brake",Rect2(354,bottom+8,114,66))
		control("铃铛","bell",Rect2(234,bottom+84,234,66))
		if game.has_blaster():control("泡泡炮","fire",Rect2(234,bottom+160,110 if game.equipped.has(5) else 234,66))
		if game.equipped.has(5):control("撑伞","umbrella",Rect2(354 if game.has_blaster() else 234,bottom+160,114 if game.has_blaster() else 234,66))
	else:
		pad=Rect2(16,bottom+8,216,142);control("←  滑动转向  →", "steer",pad)
		control("按住冲刺","sprint",Rect2(width-224,bottom+8,100,66))
		control("刹车","brake",Rect2(width-112,bottom+8,100,66))
		control("铃铛","bell",Rect2(width-112,bottom+84,100,66))
		if game.has_blaster():control("泡泡炮","fire",Rect2(width-224,bottom+84,100,66))
		if game.equipped.has(5):control("撑伞","umbrella",Rect2(width-224,bottom-76,212,66))
	steering_dot=background(Rect2(pad.get_center().x-14,pad.end.y-14,28,6),Color("f2d27d"))
	background(Rect2(16,204 if game.portrait else 160,width-32 if game.portrait else 216,54),Color("293b57",.85))
	message=label("",Rect2(22,208 if game.portrait else 164,width-44 if game.portrait else 204,48),16,Color("f2d27d"))
	update_hud()

func update_hud() -> void:
	if not game.mobile or built_state!="play":return
	var seconds := maxi(0,ceili(game.time_limit-game.elapsed))
	status.text="%02d:%02d  ·  %d 金  ·  %d%%"%[seconds/60,seconds%60,game.coins,int(100*game.distance/maxf(1,game.target_distance))]
	route_progress.value=100*game.distance/maxf(1,game.target_distance)
	stamina.value=game.stamina
	for key in ["fire","umbrella","bell"]:
		if not control_labels.has(key):continue
		var cooldown: float=game.attack_cooldown if key=="fire" else (game.umbrella_cooldown if key=="umbrella" else game.bell_cooldown)
		var title: String={"fire":"泡泡炮","umbrella":"撑伞","bell":"铃铛"}[key]
		control_labels[key].text=title+(" %.1fs"%cooldown if cooldown>0 else "")
	steering_dot.position.x=pad.get_center().x-14+steering_axis*(pad.size.x/2-24)
	var names: Array[String]=[]
	for id in game.buffs:
		var suffix := ""
		if id==2:suffix=" %d次"%game.spare_guards
		if id==8:suffix=" %d次"%game.jump_charges
		names.append(game.Perks.ITEMS[id].name+suffix)
	perks.text=" / ".join(names)
	message.text=game.toast if game.toast_time>0 else "看清嗓预警，提前躲开"

func press(id: int, pos: Vector2) -> bool:
	if game.state!="play":return false
	for key in regions:
		if not regions[key].has_point(pos):continue
		if key=="steer":
			if steering_id!=-999:return true
			steering_id=id;steering_origin=pos.x;steering_axis=0
		elif key in ["sprint","brake"]:game.touch[key]=true
		elif key=="bell":game.ring_bell()
		elif key=="fire":game.fire_weapon()
		elif key=="umbrella":game.use_umbrella()
		fingers[id]=key
		return true
	return false

func drag(id: int, pos: Vector2) -> void:
	if id==steering_id:
		steering_axis=clampf((pos.x-steering_origin)/60,-1,1)
		if absf(steering_axis)<.12:steering_axis=0

func release(id: int) -> void:
	if not fingers.has(id):return
	var key: String=fingers[id];fingers.erase(id)
	if id==steering_id:steering_id=-999;steering_axis=0
	if key in ["sprint","brake"]:game.touch[key]=fingers.values().has(key)

func _input(event: InputEvent) -> void:
	if not game or not game.mobile:return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			if press(event.index,event.position):get_viewport().set_input_as_handled()
		else:release(event.index)
	elif event is InputEventScreenDrag:
		drag(event.index,event.position)
		if fingers.has(event.index):get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device!=-1 and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			if press(-100,event.position):get_viewport().set_input_as_handled()
		else:release(-100)
	elif event is InputEventMouseMotion and event.device!=-1:drag(-100,event.position)
