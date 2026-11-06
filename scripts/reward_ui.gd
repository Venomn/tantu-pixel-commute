extends CanvasLayer
const Art=preload("res://scripts/reward_art.gd")
var game
var root: Control
var cards: Array[Button]=[]
func setup(owner_game) -> void:
	game=owner_game;layer=12;root=Control.new();root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
func panel(parent: Node,box: Rect2,color: Color) -> ColorRect:
	var node:=ColorRect.new();node.position=box.position;node.size=box.size;node.color=color;node.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(node);return node
func label(parent: Node,value: String,box: Rect2,font_size: int,color: Color,center := false) -> Label:
	var node:=Label.new();node.text=value;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font",game.font);node.add_theme_font_size_override("font_size",font_size);node.add_theme_color_override("font_color",color)
	if center:node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(node);node.position=box.position;node.size=box.size;return node
func style(fill: Color,border: Color) -> StyleBoxFlat:
	var result:=StyleBoxFlat.new();result.bg_color=fill;result.border_color=border;result.set_border_width_all(3);return result
func build() -> void:
	for child in root.get_children():root.remove_child(child);child.queue_free()
	cards.clear();root.visible=game.state=="upgrade"
	if not root.visible:return
	var size: Vector2=Vector2(game.get_window().content_scale_size)-Vector2(0,game.safe_top+game.safe_bottom)
	root.position=Vector2(0,game.safe_top);root.size=size
	panel(root,Rect2(Vector2.ZERO,size),Color("203446"))
	var portrait:=size.x<700
	var margin:=20.0
	var gap:=16.0 if portrait else 20.0
	var top:=116.0
	var count: int=game.perk_choices.size()
	label(root,"挑个好东西",Rect2(margin,16,size.x-140,45),32,Color("f2d27d"))
	label(root,"选 1 个 · 本局有效 · 已暂停",Rect2(margin,66,size.x-2*margin,32),19,Color("b9cfce"))
	label(root,"点整张卡，选完继续骑！" if game.mobile else "点击卡片，或按 1 / 2 / 3",Rect2(margin,size.y-38,size.x-2*margin,30),18,Color("b9cfce"),true)
	if count==0:return
	var available:=size.y-top-54
	var card_h:=minf(210,(available-gap*(count-1))/count) if portrait else available
	var card_w:=size.x-2*margin if portrait else (size.x-2*margin-gap*(count-1))/count
	var start_y:=top+maxf(0,(available-card_h*count-gap*(count-1))*.3) if portrait else top
	for i in count:
		var choice: int=i
		var id: int=game.perk_choices[i]
		var item: Dictionary=game.Perks.ITEMS[id]
		var accent:=Color(item.color)
		var pos:=Vector2(margin,start_y+i*(card_h+gap)) if portrait else Vector2(margin+i*(card_w+gap),top)
		panel(root,Rect2(pos+Vector2(0,5),Vector2(card_w,card_h)),Color("132634"))
		var card:=Button.new();card.position=pos;card.size=Vector2(card_w,card_h);card.focus_mode=Control.FOCUS_NONE
		card.add_theme_stylebox_override("normal",style(Color("f3edd8"),accent))
		card.add_theme_stylebox_override("hover",style(Color("fff9e8"),accent.lightened(.25)))
		card.add_theme_stylebox_override("pressed",style(accent.lightened(.15),Color("fff3d1")))
		card.pressed.connect(func():game.choose_perk(choice));root.add_child(card);cards.append(card)
		var icon_box:=Rect2(16,(card_h-96)/2,96,96) if portrait else Rect2((card_w-116)/2,48,116,116)
		panel(card,icon_box,accent.darkened(.2));panel(card,icon_box.grow(-5),accent.lightened(.25))
		var art:=Art.new();art.id=item.icon;art.position=icon_box.position;art.size=icon_box.size;card.add_child(art)
		if not portrait:label(card,str(i+1),Rect2(10,7,28,28),18,Color("49626b"),true)
		var x:=128.0 if portrait else 14.0
		var w:=card_w-x-12 if portrait else card_w-28
		var y: float=(card_h-114)/2 if portrait else 185.0
		label(card,item.name,Rect2(x,y,w,38),26,Color("26374b"),not portrait)
		var headline: String=item.headline
		var note: String=item.note
		if id==6:
			if game.equipped.has(6):headline="泡泡升级三连发"
			note="点泡泡炮 · 仅本局" if game.mobile else "按 F 发射 · 仅本局"
		label(card,headline,Rect2(x,y+41,w,34),22,Color("365e65"),not portrait)
		label(card,note,Rect2(x,y+82,w,29),17,Color("607477"),not portrait)
		if not portrait:label(card,"选择这个 →",Rect2(14,card_h-47,card_w-28,32),20,Color("365e65"),true)
