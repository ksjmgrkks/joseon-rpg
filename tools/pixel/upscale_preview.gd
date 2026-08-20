extends SceneTree
##
## .pl_tmp/prev/*.png 를 4배 확대해 <이름>.x4.png 로 저장 — 육안 검사용.
## 실행: godot --headless --path . --script res://tools/pixel/upscale_preview.gd
##
func _init() -> void:
	var d := DirAccess.open("res://.pl_tmp/prev")
	if d == null:
		quit(1)
		return
	for f in d.get_files():
		if not f.ends_with(".png") or f.ends_with(".x4.png"):
			continue
		var img := Image.load_from_file("res://.pl_tmp/prev/" + f)
		if img == null:
			continue
		img.resize(img.get_width() * 4, img.get_height() * 4, Image.INTERPOLATE_NEAREST)
		img.save_png(ProjectSettings.globalize_path("res://.pl_tmp/prev/%s.x4.png" % f.get_basename()))
		print("x4: ", f)
	quit(0)
