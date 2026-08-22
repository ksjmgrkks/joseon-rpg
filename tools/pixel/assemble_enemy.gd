extends SceneTree
##
## PixelLab 프레임 → Godot 스프라이트 시트 조립 (범용).
##
## 실행:
##   godot --headless --path . --script res://tools/pixel/assemble_enemy.gd -- \
##       --name=mulgwisin --anims=idle:6,walk:8,attack:12,death:8 --frames=5
##
## 입력:  .pl_tmp/<name>/<anim>/<i>.png   (east 방향 프레임)
## 출력:  assets/sprites/enemies/<name>/<anim>.png (가로 스트립) + manifest.json
##        --src=/--out= 로 다른 경로도 지정 가능(주인공은 sprites/protagonist_custom)
##
## 규약(tools/pixel/AGENT_GUIDE.md §2): 전 애니·전 프레임의 불투명 영역을 합집합(union bbox)으로
## 한 번에 크롭한다 — 애니 전환 시 캐릭터가 튀지 않도록.
##
## 캐릭터마다 assemble_<이름>.gd 를 새로 복사해 쓰던 걸 이걸로 대체한다(2026-08-20).
##

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var nm := String(args.get("name", ""))
	if nm.is_empty():
		push_error("--name=<시트 이름> 필요")
		quit(1)
		return
	var n_frames := int(args.get("frames", "5"))
	var loop_never := ["attack", "death", "telegraph"]
	var anims := {}
	for spec in String(args.get("anims", "idle:6,walk:8,attack:12,death:8")).split(",", false):
		var parts := spec.split(":")
		var an := parts[0]
		# 형식: 이름[:fps[:프레임수]] — 프레임 수를 생략하면 --frames 값을 쓴다
		# (애니마다 프레임 수가 다른 주인공 때문에 3번째 칸을 추가함)
		anims[an] = {
			"frames": int(parts[2]) if parts.size() > 2 else n_frames,
			"fps": int(parts[1]) if parts.size() > 1 else 8,
			"loop": not (an in loop_never),
		}

	var src := String(args.get("src", "res://.pl_tmp/%s" % nm))
	var out := String(args.get("out", "res://assets/sprites/enemies/%s" % nm))
	var loaded := {}
	var union := Rect2i()
	var first := true
	for anim in anims:
		var arr: Array[Image] = []
		for i in range(int(anims[anim]["frames"])):
			var path := "%s/%s/%d.png" % [src, anim, i]
			var img := Image.load_from_file(path)
			if img == null:
				push_error("프레임 없음: " + path)
				quit(1)
				return
			arr.append(img)
			var r := img.get_used_rect()
			if r.size.x <= 0:
				continue
			if first:
				union = r
				first = false
			else:
				union = union.merge(r)
		loaded[anim] = arr
	print("union bbox: ", union)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for anim in anims:
		var arr: Array = loaded[anim]
		var strip := Image.create(union.size.x * arr.size(), union.size.y, false, Image.FORMAT_RGBA8)
		strip.fill(Color(0, 0, 0, 0))
		for i in range(arr.size()):
			strip.blit_rect(arr[i], union, Vector2i(i * union.size.x, 0))
		strip.save_png(ProjectSettings.globalize_path("%s/%s.png" % [out, anim]))
		print("  %s.png  %dx%d (%d프레임)" % [anim, strip.get_width(), strip.get_height(), arr.size()])

	var f := FileAccess.open("%s/manifest.json" % out, FileAccess.WRITE)
	f.store_string(JSON.stringify({"frame_w": union.size.x, "frame_h": union.size.y, "anims": anims}, "  "))
	f.close()

	# 발 정렬용 권장 foot_offset — idle 첫 프레임의 발끝 기준(스케일 1.0 기준값).
	var idle0: Image = loaded[anims.keys()[0]][0] if not loaded.has("idle") else loaded["idle"][0]
	var r0 := idle0.get_used_rect()
	var foot_in_frame := (r0.position.y + r0.size.y) - union.position.y
	var foot_offset := -(float(union.size.y) - float(foot_in_frame)) - float(union.size.y) * 0.5
	print("frame: %dx%d / 발끝(크롭 기준) y=%d / 권장 foot_offset(scale=1.0)=%.1f"
		% [union.size.x, union.size.y, foot_in_frame, foot_offset])
	print("  (콜리전 반높이 half, 스케일 sc 이면: foot_offset = half/sc - (발끝 - frame_h/2))")
	quit(0)
