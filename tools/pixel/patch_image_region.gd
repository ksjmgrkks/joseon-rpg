extends SceneTree
##
## 큰 이미지의 한 조각을 떼어내고(crop) 고쳐서 다시 붙이는(paste) 도구.
##
## PixelLab 의 inpaint/edit 도구는 입력이 512px 이하라 688×384 인 시작화면 배경을
## 통째로 못 넣는다 — 고칠 부분만 잘라 보내고 결과를 제자리에 다시 붙이기 위한 것.
##
## 실행:
##   godot --headless --path . --script res://tools/pixel/patch_image_region.gd -- \
##       --mode=crop --src=res://assets/ui/title_bg.png --out=res://.art_gen/crop.png \
##       --rect=520,120,168,264
##   godot --headless --path . --script res://tools/pixel/patch_image_region.gd -- \
##       --mode=paste --src=res://assets/ui/title_bg.png --patch=res://.art_gen/fixed.png \
##       --rect=520,120,168,264
##

func _init() -> void:
	var a := {}
	for s in OS.get_cmdline_user_args():
		var kv := s.trim_prefix("--").split("=", true, 1)
		if kv.size() == 2:
			a[kv[0]] = kv[1]
	var mode := String(a.get("mode", "crop"))
	var src := String(a.get("src", ""))
	var parts := String(a.get("rect", "")).split(",")
	if parts.size() != 4:
		push_error("--rect=x,y,w,h 필요")
		quit(1)
		return
	var rect := Rect2i(int(parts[0]), int(parts[1]), int(parts[2]), int(parts[3]))
	var img := Image.load_from_file(src)
	if img == null:
		push_error("원본 없음: " + src)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)

	if mode == "crop":
		var out := String(a.get("out", ""))
		var piece := img.get_region(rect)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
		piece.save_png(ProjectSettings.globalize_path(out))
		print("잘라냄 %s → %s (%dx%d)" % [rect, out, piece.get_width(), piece.get_height()])
	else:
		var patch := Image.load_from_file(String(a.get("patch", "")))
		if patch == null:
			push_error("패치 없음")
			quit(1)
			return
		patch.convert(Image.FORMAT_RGBA8)
		if patch.get_width() != rect.size.x or patch.get_height() != rect.size.y:
			patch.resize(rect.size.x, rect.size.y, Image.INTERPOLATE_NEAREST)
			print("패치 크기가 달라 %dx%d 로 맞춤" % [rect.size.x, rect.size.y])
		img.blit_rect(patch, Rect2i(0, 0, rect.size.x, rect.size.y), rect.position)
		img.save_png(ProjectSettings.globalize_path(src))
		print("붙임 %s ← 패치 (%s)" % [src, rect])
	quit(0)
