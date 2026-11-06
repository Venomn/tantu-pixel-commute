extends SceneTree
var game
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/Users/bingao/Documents/ChatGPT/像素风格吐痰游戏/deliverables/"+name+".png")
func run() -> void:
	root.size=Vector2i(390,740)
	game=load("res://main.tscn").instantiate();game.save_path="user://qa_render_garage.json";root.add_child(game);game.set_process(false);game.muted=true;game.saved={};game.new_game("week")
	game.owned=[1,4,5,6,8];game.equipped=[1,5,6,8];game.coins=438;game.open_shop("brief")
	await capture("garage-portrait")
	game.garage_view.select_item(4)
	await capture("garage-preview")
	game.garage_view.select_item(8)
	root.size=Vector2i(359,610);game.update_layout()
	await capture("garage-compact")
	root.size=Vector2i(320,480);game.update_layout();game.safe_top=24;game.safe_bottom=34;game.build_ui()
	await capture("garage-small")
	game.safe_top=0;game.safe_bottom=0
	root.size=Vector2i(844,390);game.update_layout()
	await capture("garage-landscape")
	root.size=Vector2i(1280,720);game.update_layout()
	await capture("garage-desktop")
	quit()
