extends Node
##
## 적 '발 정렬' 검증 (헤드리스).
## 실행: `godot --headless res://tests/test_enemy_footing.tscn`
##
## 2026-08-19 사고: 2스테이지 몬스터들이 **공중에 떠 보인다**는 보고. 물리는 정상이고
## (상태기계가 중력·move_and_slide 를 건다) 원인은 **스프라이트 발끝과 콜리전 바닥의 어긋남** —
## 시트를 새로 뽑으면 프레임 안 발끝 위치가 달라지는데 foot_offset 을 안 맞추면 그대로 뜬다.
##
## 검사식: 발 월드y = node.y + (offset + foot - frame_h/2) * scale, 콜리전 바닥 = node.y + half
##         두 값의 차(gap)가 허용치를 넘으면 실패. gap<0 = 공중에 뜸, gap>0 = 땅에 파묻힘.
##

const PASS := "PASS"
const FAIL := "FAIL"
const TOLERANCE := 6.0     # px — 이 이상 어긋나면 눈에 띈다


func _ready() -> void:
    print("=== test_enemy_footing ===")
    var rows: Array[String] = []
    var bad: Array[String] = []
    var dir := DirAccess.open("res://scenes/enemies")
    if dir == null:
        print("[FAIL] enemy_footing\n  reason: scenes/enemies 를 열 수 없음")
        get_tree().quit(1)
        return
    for f in dir.get_files():
        if not f.ends_with(".tscn"):
            continue
        var info := _measure("res://scenes/enemies/%s" % f)
        if info.is_empty():
            continue
        rows.append("  %-22s 프레임 %-10s 발끝 %-5d offset %6.1f (권장 %6.1f)  gap %+.0f" % [
            info["name"], info["frame"], info["foot"], info["cur"], info["want"], info["gap"]])
        if absf(float(info["gap"])) > TOLERANCE:
            bad.append("%s: %s (offset %.1f → %.1f 권장)" % [
                info["name"],
                "공중에 %.0fpx 뜸" % -float(info["gap"]) if float(info["gap"]) < 0 else "%.0fpx 파묻힘" % float(info["gap"]),
                info["cur"], info["want"]])
    for r in rows:
        print(r)
    if not bad.is_empty():
        print("[%s] enemy_footing" % FAIL)
        for b in bad:
            print("  reason: %s" % b)
        print("=== 0/1 passed ===")
        get_tree().quit(1)
        return
    print("[%s] enemy_footing" % PASS)
    print("=== 1/1 passed ===")
    get_tree().quit(0)


func _measure(scene_path: String) -> Dictionary:
    var packed: PackedScene = load(scene_path)
    if packed == null:
        return {}
    var inst := packed.instantiate()
    var spr := inst.get_node_or_null("Sprite2D")
    var col := inst.get_node_or_null("CollisionShape2D") as CollisionShape2D
    if spr == null or col == null:
        inst.free()
        return {}
    var sheet := String(spr.get("sheet")) if spr.get("sheet") != null else ""
    var man := SpriteDb.manifest(sheet)
    var ipath := "res://assets/sprites/%s/idle.png" % sheet
    if sheet == "" or man.is_empty() or not ResourceLoader.exists(ipath):
        inst.free()
        return {}
    var fw := int(man.get("frame_w", 32))
    var fh := int(man.get("frame_h", 64))
    var strip: Texture2D = load(ipath)
    var img := strip.get_image()
    if img == null:
        inst.free()
        return {}
    var frame := Image.create(fw, fh, false, img.get_format())
    frame.blit_rect(img, Rect2i(0, 0, fw, fh), Vector2i.ZERO)
    var used := frame.get_used_rect()
    var foot := used.position.y + used.size.y
    var half := 16.0
    if col.shape is RectangleShape2D:
        half = (col.shape as RectangleShape2D).size.y * 0.5
    var sc: float = absf(spr.scale.y) if spr.scale.y != 0.0 else 1.0
    # CharacterVisual._ready() 가 offset 을 세팅하는데, 테스트는 트리에 안 넣으므로
    # 원본 export 인 foot_offset 을 직접 읽는다(안 그러면 전부 0 으로 읽힌다).
    var cur: float = float(spr.get("foot_offset")) if spr.get("foot_offset") != null else 0.0
    var want := half / sc - (float(foot) - fh / 2.0)
    var gap := (cur + float(foot) - fh / 2.0) * sc - half
    var nm := scene_path.get_file().get_basename()
    inst.free()
    return {"name": nm, "frame": "%dx%d" % [fw, fh], "foot": foot, "cur": cur, "want": want, "gap": gap}
