extends SceneTree
var checks := 0
var failures := 0
var game
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+message)
func fits_mobile(garage) -> bool:
	var bounds:=Rect2(Vector2.ZERO,garage.root.size)
	var controls: Array[Control]=[garage.art,garage.preview_label,garage.detail,garage.purchase]
	controls.append_array(garage.item_buttons);controls.append_array(garage.navigation)
	for c in controls:
		if not bounds.encloses(c.get_rect()) or c.size.x<=0 or c.size.y<=0:
			print("BOUNDS ",c,c.get_rect(),bounds);return false
	for i in controls.size():
		for j in range(i+1,controls.size()):
			if controls[i].get_rect().intersects(controls[j].get_rect()):
				print("OVERLAP ",controls[i],controls[i].get_rect(),controls[j],controls[j].get_rect());return false
	var ratio: float=float(root.size.x)/root.content_scale_size.x
	for b in garage.item_buttons+[garage.purchase]+garage.navigation:
		if minf(b.size.x,b.size.y)*ratio<43.9:
			print("SMALL ",b,b.size,ratio);return false
	for l in garage.root.find_children("*","Label",true,false):
		if not Rect2(Vector2.ZERO,l.get_parent().size).encloses(l.get_rect()):
			print("LABEL BOUNDS ",l.text,l.get_rect());return false
		if l.get_line_count()>l.get_visible_line_count():
			print("TEXT ",l.text,l.get_line_count(),l.get_visible_line_count(),l.size);return false
	return garage.scroll==null and garage.art.size.y>=80
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.size=Vector2i(359,610)
	game=load("res://main.tscn").instantiate();game.save_path="user://qa_garage.json";root.add_child(game);game.set_process(false);game.muted=true;game.saved={}
	game.new_game("week");game.open_shop("brief")
	var garage=game.garage_view
	check(garage.root.visible and not game.mobile_view.root.visible,"mobile shop uses visual garage without old text-only shop")
	check(garage.item_buttons.size()==8 and garage.art.gear.is_empty(),"garage shows eight selectable parts and unmodified owned bicycle")
	var before:=FileAccess.get_file_as_string(game.save_path)
	garage.item_buttons[3].pressed.emit()
	check(garage.preview==[4] and game.equipped.is_empty() and game.owned.is_empty() and game.coins==80,"selecting shield previews a real part without purchasing or equipping")
	check(before==FileAccess.get_file_as_string(game.save_path),"preview cannot change persisted assets")
	check(garage.purchase.disabled,"unaffordable preview cannot be purchased")
	garage.buy_selected();check(game.coins==80 and game.owned.is_empty(),"purchase boundary rejects insufficient balance")
	game.coins=600;game.save_game();garage.select_item(4);garage.purchase.pressed.emit()
	check(game.coins==500 and game.equipped==[4] and garage.art.gear==[4] and garage.art.flash>0,"actual purchase deducts money, equips part and shows assembled bicycle")
	garage.select_item(5)
	check(garage.art.gear==[5] and game.equipped==[4],"defense preview replaces slot visually without altering actual loadout")
	garage.purchase.pressed.emit()
	check(game.coins==360 and game.equipped==[5] and game.owned.has(4),"buying another defense swaps slot while preserving old ownership")
	garage.purchase.pressed.emit()
	check(game.equipped.is_empty() and garage.art.gear.is_empty() and game.coins==360,"unequipping visibly removes the part without charging money")
	garage.select_item(4);garage.purchase.pressed.emit()
	check(game.equipped==[4] and game.coins==360,"previously purchased equipment mounts for free")
	game.load_save();game.resume_save()
	check(game.equipped==[4] and game.coins==360,"garage purchase survives actual save reload")
	for id in range(1,9):
		garage.select_item(id)
		check(garage.art.gear.has(id),"part %d is included in rendered preview"%id)
	garage.select_item(8);game.depart_shop()
	check(not game.equipped.has(8) and not game.owned.has(8),"leaving a preview never grants unpurchased equipment")
	check(not garage.root.visible,"garage closes when departing")
	game.choose_perk(0);game.fail_run("spit")
	check(garage.root.visible and garage.art.gear==game.equipped,"settlement returns to actual owned bicycle instead of stale preview")
	for viewport in [Vector2i(320,480),Vector2i(359,610),Vector2i(390,740),Vector2i(430,932),Vector2i(844,390),Vector2i(667,320)]:
		root.size=viewport;game.update_layout();await process_frame
		game.safe_top=24 if viewport.x<viewport.y else 0;game.safe_bottom=34;game.build_ui()
		for id in range(1,9):
			garage.select_item(id);await process_frame;await process_frame
			check(fits_mobile(garage),"%s part %d: preview, eight cards, effects and purchase fit without scrolling, overlap or small targets"%[viewport,id])
		game.coins=9999;game.wins=5;game.last_result={"reason":"arrival","earned":9999,"bonus":9999};game.build_ui();await process_frame
		check(fits_mobile(garage),"%s: maximum wallet, settlement and completed-week labels remain visible"%viewport)
	game.safe_top=0;game.safe_bottom=0
	root.size=Vector2i(1280,720);game.update_layout();await process_frame
	check(garage.root.visible and garage.item_buttons.size()==8 and game.ui.get_child_count()==0,"desktop uses the same visual purchase flow")
	print("GARAGE RESULT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
