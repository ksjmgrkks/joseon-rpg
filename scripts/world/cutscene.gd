extends Node2D
class_name Cutscene
##
## 「해원」 회상 컷 — 전투맵 위 말풍선이 아니라, 전용 '기억 맵'으로 컷 전환해
## 과거 한 장면을 보여준 뒤 SceneManager.return_from_cutscene() 으로 전투맵에 복귀한다.
##
## .tscn 래퍼는 루트 이름을 "Cut..."(autosave 제외 규약)으로 두고 cutscene_id 만 지정하면 된다.
## 실제 내용은 assets/cutscenes/<cutscene_id>.json 한 장으로 조립(데이터 기반 — stage.gd 와 같은 철학).
##
## JSON 스키마 (assets/cutscenes/<id>.json):
## {
##   "backdrop": {"sky":[r,g,b], "tint":[r,g,b], "far_scale":0.12},
##   "ground":   {"tex":"ground_dirt", "width":2000, "x":-200},   # (선택) 바닥
##   "props":    [{"tex":"mul_deung","x":300,"y":686,"scale":0.8,"offset":[-48,-96]}],
##   "figures":  [{"sprite":"res://assets/sprites/cutscene/yunseul/idle.png","x":760,"y":620,"scale":2.0,"flip":true,"hframes":1,"frame":0}],
##   "tone":     "inkwash" | "",        # inkwash = 화면을 수묵 흑백으로 바램(수문 회상). 동틀녘 회상은 "".
##   "dialogue": "res://assets/dialogue/haewon/recall_yunseul.json",
##   "_return":  "(런타임에 SceneManager 가 기억한 전투 씬으로 복귀 — JSON 불필요)"
## }
##
## figure.sprite PNG 가 아직 없으면(아트 PC 적용 전) 수묵 실루엣으로 폴백 — 폰에서도 장면이 읽힌다.
##

const TILE_DIR := "res://assets/tilesets/%s.png"
const BACKDROP_SCENE := "res://scenes/world/Backdrop.tscn"
const GROUND_Y := 700.0
const GROUND_TOP := 684

@export var cutscene_id: String = ""


func _ready() -> void:
    var data := _load()
    if data.is_empty():
        push_error("[Cutscene] cutscene json 없음: %s" % cutscene_id)
        _return()
        return
    _build_backdrop(data.get("backdrop", {}))
    if data.has("ground"):
        _build_ground(data.get("ground", {}))
    _build_props(data.get("props", []))
    _build_figures(data.get("figures", []))
    _build_camera(data.get("camera", {}))
    var tone := String(data.get("tone", ""))
    if tone == "inkwash" and InkWash:
        InkWash.enter(0.6)
    # 페이드 인 뒤 한 박자 — 장면을 먼저 '보게' 하고 대사를 연다(완급).
    await get_tree().create_timer(0.7).timeout
    var dlg := String(data.get("dialogue", ""))
    if dlg != "" and ResourceLoader.exists(dlg) and Dialogue:
        Dialogue.start(dlg)
        await Dialogue.dialogue_ended
    else:
        await get_tree().create_timer(2.0).timeout
    if tone == "inkwash" and InkWash:
        InkWash.exit(0.5)
    await get_tree().create_timer(0.5).timeout
    _return()


## 컷이 끝나면 기억해 둔 전투 씬으로 복귀. 복귀 대상이 없으면(직접 실행·테스트) 메뉴로.
func _return() -> void:
    if SceneManager == null:
        return
    if not SceneManager.transitions_enabled:
        return
    var ok: bool = await SceneManager.return_from_cutscene()
    if not ok:
        await SceneManager.change_scene("res://scenes/ui/MainMenu.tscn")


func _load() -> Dictionary:
    var path := "res://assets/cutscenes/%s.json" % cutscene_id
    if not FileAccess.file_exists(path):
        return {}
    var f := FileAccess.open(path, FileAccess.READ)
    var parsed = JSON.parse_string(f.get_as_text())
    f.close()
    return parsed if parsed is Dictionary else {}


func _col(arr, fallback: Color) -> Color:
    if arr is Array and arr.size() >= 3:
        return Color(arr[0], arr[1], arr[2], 1.0 if arr.size() < 4 else arr[3])
    return fallback


## 회상 씬엔 따라다닐 플레이어가 없으므로 정지 카메라로 화면(1280x720)을 잡는다.
## 기본값은 지면(y≈684)이 화면 하단, 인물이 화면 중앙에 오도록.
func _build_camera(c: Dictionary) -> void:
    var cam := Camera2D.new()
    cam.position = Vector2(float(c.get("x", 640)), float(c.get("y", 430)))
    if c.has("zoom"):
        var z := float(c["zoom"])
        cam.zoom = Vector2(z, z)
    # 씬에 카메라가 이것 하나뿐이라 트리 진입 시 자동으로 활성 카메라가 된다(stage.gd 와 동일 패턴).
    add_child(cam)


func _build_backdrop(b: Dictionary) -> void:
    var bd: ParallaxBackground = load(BACKDROP_SCENE).instantiate()
    bd.sky_color = _col(b.get("sky", null), Color(0.93, 0.89, 0.78))
    bd.tint = _col(b.get("tint", null), Color.WHITE)
    if b.has("far_scale"):
        bd.far_scale = float(b["far_scale"])
    add_child(bd)


func _build_ground(g: Dictionary) -> void:
    var tex_name := String(g.get("tex", "ground_dirt"))
    var w := int(g.get("width", 2000))
    var gx := int(g.get("x", -200))
    for spec in [[GROUND_TOP + 32, 340], [GROUND_TOP, 36]]:
        var t := TiledSprite.new()
        t.tex_path = TILE_DIR % tex_name
        t.width = w
        t.height = spec[1]
        t.position = Vector2(gx, spec[0])
        add_child(t)


func _build_props(props: Array) -> void:
    for p in props:
        if not (p is Dictionary):
            continue
        var tex_path := TILE_DIR % String(p.get("tex", ""))
        if not ResourceLoader.exists(tex_path):
            continue
        var spr := Sprite2D.new()
        spr.texture = load(tex_path)
        spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        spr.centered = false
        spr.scale = Vector2.ONE * float(p.get("scale", 1.0))
        var off = p.get("offset", [0, 0])
        spr.offset = Vector2(off[0], off[1]) if off is Array else Vector2.ZERO
        spr.position = Vector2(float(p.get("x", 0)), float(p.get("y", GROUND_TOP)))
        add_child(spr)


## 회상 속 인물 — PNG 가 있으면 스프라이트, 없으면 수묵 실루엣 폴백.
func _build_figures(figs: Array) -> void:
    for f in figs:
        if not (f is Dictionary):
            continue
        var x := float(f.get("x", 0))
        var y := float(f.get("y", GROUND_TOP))
        var sc := float(f.get("scale", 1.0))
        var flip := bool(f.get("flip", false))
        var path := String(f.get("sprite", ""))
        if path != "" and ResourceLoader.exists(path):
            var spr := Sprite2D.new()
            var tex: Texture2D = load(path)
            spr.texture = tex
            spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            spr.scale = Vector2(sc, sc)
            spr.flip_h = flip
            var hf := int(f.get("hframes", 1))
            spr.centered = false
            if hf > 1:
                spr.hframes = hf
                spr.frame = int(f.get("frame", 0))
            # 발(불투명 영역 아래중앙)을 (x,y)에 정렬 — PixelLab 캔버스의 투명 여백을 보정.
            var fw := tex.get_width() / float(max(1, hf))
            var fh := tex.get_height()
            var anchor_x := fw / 2.0
            var anchor_y := fh
            if hf <= 1:
                var img := tex.get_image()
                if img != null:
                    var ur := img.get_used_rect()
                    if ur.size.x > 0 and ur.size.y > 0:
                        anchor_x = ur.position.x + ur.size.x / 2.0
                        anchor_y = ur.position.y + ur.size.y
            spr.offset = Vector2(-anchor_x, -anchor_y)
            spr.position = Vector2(x, y)
            add_child(spr)
        else:
            _placeholder_figure(x, y, sc)


## 아트 적용 전 폴백 — 서 있는 사람 모양의 수묵 실루엣(머리+몸).
func _placeholder_figure(x: float, y: float, sc: float) -> void:
    var col := Color(0.13, 0.14, 0.2, 0.85)
    var h := 78.0 * sc
    var w := 26.0 * sc
    var body := Polygon2D.new()
    body.color = col
    body.polygon = PackedVector2Array([
        Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0),
        Vector2(w * 0.34, -h * 0.72), Vector2(-w * 0.34, -h * 0.72)])
    body.position = Vector2(x, y)
    add_child(body)
    var head := Polygon2D.new()
    head.color = col
    var r := w * 0.42
    var pts := PackedVector2Array()
    for i in 12:
        var a := float(i) * PI / 6.0
        pts.append(Vector2(cos(a) * r, sin(a) * r - h * 0.82))
    head.polygon = pts
    head.position = Vector2(x, y)
    add_child(head)
