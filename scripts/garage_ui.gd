extends CanvasLayer
const Art=preload("res://scripts/garage_art.gd")
const Equipment=preload("res://scripts/equipment.gd")
const SHORT=["齿盘","刹车","后视镜","护盾","雨伞","泡泡炮","磁铁","机械臂"]
var game
var root: Control
var art
var selected := 1
var preview: Array=[]
var preview_enabled := false
var purchase: Button
var item_buttons: Array[Button]=[]
var scroll: ScrollContainer
var built := false
func setup(owner_game) -> void:
	game=owner_game;layer=11;root=Control.new();root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
func style(color: Color,border := Color("536d78")) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=color;s.border_color=border;s.set_border_width_all(3);return s
func text(value: String,parent: Node,font_size := 20,color := Color("fff3d1")) -> Label:
	var l:=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font",game.font);l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",color);parent.add_child(l);return l
func button(value: String,parent: Node,callback: Callable,accent := false) -> Button:
	var b:=Button.new();b.text=value;b.custom_minimum_size.y=64;b.focus_mode=Control.FOCUS_NONE
	b.add_theme_font_override("font",game.font);b.add_theme_font_size_override("font_size",21)
	b.add_theme_stylebox_override("normal",style(Color("f2d27d") if accent else Color("3a5065")))
	b.add_theme_stylebox_override("pressed",style(Color("a4d577")));b.add_theme_stylebox_override("disabled",style(Color("536270")))
	b.add_theme_color_override("font_color",Color("293b57") if accent else Color("fff3d1"));b.add_theme_color_override("font_disabled_color",Color("b4bbb8"))
	b.pressed.connect(func():game.sfx("click");callback.call());parent.add_child(b);return b
func column(parent: Node) -> VBoxContainer:
	var c:=VBoxContainer.new();c.size_flags_horizontal=Control.SIZE_EXPAND_FILL;c.add_theme_constant_override("separation",10);parent.add_child(c);return c
func select_item(id: int) -> void:
	if game.state!="shop" or not Equipment.valid(id):return
	selected=id;preview_enabled=true;build()
func buy_selected() -> void:
	if game.state!="shop":return
	preview_enabled=false
	game.buy_gear(selected)
	if game.equipped.has(selected):art.flash=1.0
func build() -> void:
	if not root:return
	var old_scroll := scroll.scroll_vertical if is_instance_valid(scroll) and built else 0
	for c in root.get_children():root.remove_child(c);c.queue_free()
	root.visible=game.state=="shop";item_buttons.clear();scroll=null
	if not root.visible:built=false;preview_enabled=false;return
	built=true
	var size: Vector2=Vector2(game.get_window().content_scale_size)-Vector2(0,game.safe_top+game.safe_bottom)
	root.position=Vector2(0,game.safe_top);root.size=size
	var bg:=ColorRect.new();bg.color=Color("263b4c");bg.size=size;bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(bg)
	var title:=text("下班改装铺",root,30,Color("f2d27d"));title.position=Vector2(18,12);title.size=Vector2(270,40)
	var wallet:=text("钱包  %d 金"%game.coins,root,22);wallet.position=Vector2(20,56);wallet.size=Vector2(size.x-40,32)
	scroll=ScrollContainer.new();scroll.position=Vector2(16,92);scroll.size=size-Vector2(32,174);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;root.add_child(scroll)
	var outer:=column(scroll)
	if not game.last_result.is_empty():
		var outcome: String={"arrival":"打卡成功","spit":"衣服中招","trash":"垃圾翻车","late":"迟到啦","quit":"本局结束"}.get(game.last_result.reason,"本局结束")
		text("%s · 收入 %d 金已入账"%[outcome,game.last_result.earned+game.last_result.bonus],outer,18,Color("a4d577"))
	var layout: BoxContainer=VBoxContainer.new() if size.x<700 else HBoxContainer.new();layout.add_theme_constant_override("separation",16);outer.add_child(layout)
	var left:=column(layout)
	if size.x>=700:left.custom_minimum_size.x=(size.x-64)*.48
	preview=game.equipped.duplicate() if not preview_enabled or game.equipped.has(selected) else Equipment.select(game.equipped,selected)
	art=Art.new();art.gear=preview.duplicate();art.custom_minimum_size=Vector2(0,215 if size.x<700 else 275);art.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.add_child(art)
	text("当前自行车 · 已装配" if not preview_enabled or game.equipped.has(selected) else "试装预览 · "+("已拥有，可免费装配" if game.owned.has(selected) else "尚未购买"),left,18,Color("a4d577") if game.equipped.has(selected) else Color("f2d27d"))
	var slots:=HBoxContainer.new();slots.add_theme_constant_override("separation",8);left.add_child(slots)
	for slot in ["骑行","防御","攻击","辅助"]:
		var current := 0
		for id in game.equipped:
			if Equipment.ITEMS[id-1].slot==slot:current=id
		var pick: int=current
		if pick==0:
			for i in Equipment.ITEMS.size():
				if Equipment.ITEMS[i].slot==slot:pick=i+1;break
		var b:=button(slot+"\n"+(SHORT[current-1] if current else "空槽"),slots,func():select_item(pick))
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_font_size_override("font_size",17)
	var right:=column(layout)
	var grid:=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);right.add_child(grid)
	for i in Equipment.ITEMS.size():
		var id:=i+1
		var b:=button("",grid,func():select_item(id));b.custom_minimum_size=Vector2(0,108);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		b.add_theme_stylebox_override("normal",style(Color("dfe6ce") if id==selected else Color("3a5065"),Color("f2d27d") if id==selected else Color("536d78")))
		var icon:=Art.new();icon.icon_id=id;icon.position=Vector2(23,5);icon.size=Vector2(48,48);b.add_child(icon)
		var name:=text(SHORT[i]+(" ✓" if game.equipped.has(id) else ""),b,17,Color("293b57") if id==selected else Color("fff3d1"));name.position=Vector2(2,55);name.size=Vector2(94,24);name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var price:=text("已拥有" if game.owned.has(id) else "%d 金"%Equipment.ITEMS[i].price,b,16,Color("528d84") if id==selected else Color("f2d27d"));price.position=Vector2(2,81);price.size=Vector2(94,23);price.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;price.mouse_filter=Control.MOUSE_FILTER_IGNORE
		b.resized.connect(func():icon.position.x=(b.size.x-48)/2;name.size.x=b.size.x-4;price.size.x=b.size.x-4)
		item_buttons.append(b)
	var item: Dictionary=Equipment.ITEMS[selected-1]
	text(item.name+" · "+item.slot,right,25,Color("f2d27d"))
	text("\n".join(item.lines).replace("按 E","点撑伞").replace("按 F","点泡泡炮"),right,19)
	var label := "卸下装备" if game.equipped.has(selected) else ("装配到自行车 · 免费" if game.owned.has(selected) else "购买并装配 · %d 金"%item.price)
	if not game.owned.has(selected) and game.coins<item.price:label="还差 %d 金"%(item.price-game.coins)
	purchase=button(label,right,buy_selected,true);purchase.disabled=not game.owned.has(selected) and game.coins<item.price
	var back:=button("主菜单",root,func():game.change_state("menu"));back.position=Vector2(16,size.y-72);back.size=Vector2(108,60)
	var go:=button("新一周，出发！" if game.wins==5 else "装好了，出发 →",root,game.depart_shop,true);go.position=Vector2(136,size.y-72);go.size=Vector2(size.x-152,60)
	scroll.set_deferred("scroll_vertical",old_scroll)
