extends SceneTree
##
## 적/플레이어 '화면상 실제 크기' 측정 (헤드리스).
## 실행: godot --headless --path . --script res://tools/pixel/measure_enemy_sizes.gd
##
## 스프라이트 시트 프레임의 불투명 영역 높이 × 실효 스케일 = 화면에 보이는 높이.
## 잡몹/중간보스/보스의 크기 서열을 숫자로 확인하기 위한 도구.
##

func _init() -> void:
	var rows: Array = []
	var dir := DirAccess.open("res://scenes/enemies")
	for f in dir.get_files():
		if not f.ends_with(".tscn"):
			continue
		var r := _measure("res://scenes/enemies/%s" % f)
		if not r.is_empty():
			rows.append(r)
	rows.append(_measure_sheet("Player", "protagonist_custom", 0.4503))
	rows.sort_custom(func(a, b): return float(a["h"]) < float(b["h"]))
	print("%-22s %-28s %8s %8s %8s %8s" % ["scene", "sheet", "frame_h", "content", "scale", "화면h"])
	for r in rows:
		print("%-22s %-28s %8d %8d %8.2f %8.1f" % [r["name"], r["sheet"], r["fh"], r["ch"], r["sc"], r["h"]])
	quit(0)


func _measure(scene_path: String) -> Dictionary:
	var packed: PackedScene = load(scene_path)
	if packed == null:
		return {}
	var inst := packed.instantiate()
	var spr := inst.get_node_or_null("Sprite2D")
	if spr == null:
		inst.free()
		return {}
	var sheet := String(spr.get("sheet")) if spr.get("sheet") != null else ""
	# 런타임 실효 스케일: CharacterVisual._ready() 가 sprite_scale 로 scale 을 덮어쓴다.
	var eff: float = float(spr.get("sprite_scale")) if spr.get("sprite_scale") != null else 1.0
	var node_scale: float = absf(spr.scale.y)
	var r := _measure_sheet(scene_path.get_file().get_basename(), sheet, eff)
	if not r.is_empty():
		r["node_scale"] = node_scale
	inst.free()
	return r


func _measure_sheet(nm: String, sheet: String, eff: float) -> Dictionary:
	var man := _man(sheet)
	var ipath := "res://assets/sprites/%s/idle.png" % sheet
	if sheet == "" or man.is_empty() or not ResourceLoader.exists(ipath):
		return {}
	var fw := int(man.get("frame_w", 32))
	var fh := int(man.get("frame_h", 64))
	var strip: Texture2D = load(ipath)
	var img := strip.get_image()
	var frame := Image.create(fw, fh, false, img.get_format())
	frame.blit_rect(img, Rect2i(0, 0, fw, fh), Vector2i.ZERO)
	var used := frame.get_used_rect()
	return {"name": nm, "sheet": sheet, "fh": fh, "ch": used.size.y, "sc": eff, "h": float(used.size.y) * eff}


func _man(sheet: String) -> Dictionary:
	var p := "res://assets/sprites/%s/manifest.json" % sheet
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	return d if d is Dictionary else {}
