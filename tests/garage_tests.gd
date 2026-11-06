extends SceneTree
var checks := 0
var failures := 0
var game
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+message)
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
	root.size=Vector2i(1280,720);game.update_layout();await process_frame
	check(garage.root.visible and garage.item_buttons.size()==8 and game.ui.get_child_count()==0,"desktop uses the same visual purchase flow")
	print("GARAGE RESULT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
