extends SceneTree
var game
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+message)
func fits(view) -> bool:
	var bounds:=Rect2(Vector2.ZERO,view.root.size)
	for card in view.cards:
		if not bounds.encloses(card.get_rect()):return false
		for other in view.cards:
			if other!=card and card.get_rect().grow(5).intersects(other.get_rect()):return false
		var labels: Array=card.find_children("*","Label",true,false)
		for l in labels:
			if not Rect2(Vector2.ZERO,card.size).encloses(l.get_rect()):
				print("CLIPPED ",l.text,l.get_rect(),card.size);return false
			for other in labels:
				if other!=l and other.get_rect().intersects(l.get_rect()):return false
	for l in view.root.find_children("*","Label",true,false):
		if l.get_parent()==view.root and not bounds.encloses(l.get_rect()):return false
	return view.root.find_children("*","ScrollContainer",true,false).is_empty()
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="user://qa_rewards.json";root.add_child(game);game.set_process(false);game.muted=true;game.saved={};game.new_game("week")
	game.begin_run()
	var view=game.reward_view
	for viewport in [Vector2i(320,480),Vector2i(359,610),Vector2i(390,740),Vector2i(844,390),Vector2i(667,320),Vector2i(1280,720)]:
		root.size=viewport;game.update_layout();await process_frame
		game.safe_top=24 if viewport.x<viewport.y else 0;game.safe_bottom=34;game.build_ui()
		for group in 3:
			game.perk_choices.assign([group*3,group*3+1,group*3+2]);game.build_ui();await process_frame;await process_frame
			check(view.cards.size()==3 and fits(view),"%s reward group %d: three graphic cards and all text fit without scrolling or overlap"%[viewport,group])
		var before: float=game.elapsed;game._process(.1)
		check(game.state=="upgrade" and game.elapsed==before,"reward layout pauses gameplay at %s"%viewport)
	for id in 9:
		game.reset_perks();game.perk_choices.assign([id]);game.change_state("upgrade")
		view.cards[0].pressed.emit()
		check(game.state=="play" and game.perk_level(id)==1 and not view.root.visible,"whole card grants actual perk %d once and resumes"%id)
		game.choose_perk(0);check(game.perk_level(id)==1,"stale selection cannot duplicate perk %d"%id)
	game.reset_perks();game.equipped=[6];game.perk_choices.assign([6,0,1]);game.change_state("upgrade")
	var words: Array[String]=[]
	for l in view.cards[0].find_children("*","Label",true,false):words.append(l.text)
	check(words.has("泡泡升级三连发"),"cannon owner sees the actual spread-shot upgrade")
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_2;game._input(key)
	check(game.state=="play" and game.perk_level(0)==1,"number shortcut still selects the matching displayed card")
	print("REWARD RESULT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
