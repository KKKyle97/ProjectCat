extends Node
## Throwaway: instances the pond level, lets it render a few frames, saves a
## screenshot of the viewport, then quits. Run windowed (not --headless).

func _ready() -> void:
	var scene: PackedScene = load("res://scenes/levels/level_backyard_pond.tscn")
	var level: Node = scene.instantiate()
	add_child(level)
	for i in 45:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://tools/hud_shot.png")
	get_tree().quit()
