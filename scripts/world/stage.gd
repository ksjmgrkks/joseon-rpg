extends Node2D
class_name Stage
##
## 데이터 기반 스테이지 빌더 — assets/stages/<stage_id>.json 한 장으로 레벨 전체를 조립.
## 새 스테이지를 .tscn 수작업 없이 JSON 으로 양산하기 위한 핵심.
##
## .tscn 래퍼는 루트 노드 이름(=저장 지역 키)과 stage_id 만 지정하면 된다.
##
## JSON 스키마 (assets/stages/<id>.json):
## {
##   "backdrop": {"sky":[r,g,b], "tint":[r,g,b], "far_scale":0.12},
##   "ground":   {"tex":"ground_dirt", "width":2800, "x":-600},   # 시각 타일 + 충돌 자동
##   "player_x": 120,
##   "entries":  [{"name":"default","x":120}, {"name":"from_town","x":1480}],
##   "props":    [{"tex":"house_tile","x":300,"y":684,"scale":2.0,"offset":[-48,-80]}],
##   "enemies":  [{"scene":"Goblin","x":800,"y":640}],
##   #  선택 전투(사이드 진혼): "optional":true 면 결계("enemy_gate")를 막지 않음(안 죽여도 통과).
##   #  "on_death_flag":".." 를 처치 시 세운다 — EndingResolver.BURN_FLAGS 에 엮어 저울에 반영.
##   #  {"scene":"Wraith","x":460,"y":640,"optional":true,"on_death_flag":"haewon_side_lost_wraith"},
##   "npcs":     [{"x":400,"dialogue":"res://assets/dialogue/x.json"}],
##   "pickups":  [{"x":600,"item":"herb_field","icon":"herb","count":1,"label":"..","quest":"","stage":"","flag":"","requires_active":""}],
##   "auto_dialogues":[{"x":560,"dialogue":"res://..","once_flag":".."}],
##   "quest_triggers":[{"x":220,"quest":"main_tiger_lord","stage":"boss_arena","only_active":"main_tiger_lord","flag":""}],
##   "exits":    [{"x":1560,"target":"res://scenes/levels/X.tscn","entry":"from_y","color":[.5,.2,.18]}]
## }
##

const TILE_DIR := "res://assets/tilesets/%s.png"
const SIDE_DIR := "res://assets/tilesets/side/%s.png"   # 신규 사이드뷰 지면 타일셋(4x4 wang)
# 리마스터 atlas: 윗줄 256x32는 표면 8변형, 아래 256x192는 연속 속재질.
# 큰 region을 통째로 반복해 단일 32px 무늬가 도장처럼 보이는 현상을 줄인다.
const SURFACE_RECT := Rect2i(0, 0, 256, 32)
const FILL_RECT := Rect2i(0, 32, 256, 192)
const LEGACY_SURFACE_TILE := Vector2i(96, 0)
const LEGACY_FILL_TILE := Vector2i(64, 32)
const SURFACE_RISE := 20.0   # 윗면 타일을 지면선 위로 얼마나 올려 얹을지(잔디가 지면선에 걸치게)
const ENEMY_DIR := "res://scenes/enemies/%s.tscn"
const PLAYER_SCENE := "res://scenes/player/Player.tscn"
const NPC_SCENE := "res://scenes/npc/Npc.tscn"
const HUD_SCENE := "res://scenes/ui/PlayerHud.tscn"
const MOBILE_SCENE := "res://scenes/ui/MobileControls.tscn"
const BACKDROP_SCENE := "res://scenes/world/Backdrop.tscn"
const GROUND_Y := 700.0
const GROUND_TOP := 684          # 지면 윗면 y (시각 타일 상단)
const CAMERA_OFFSET_Y := 160.0   # 카메라를 위로 이만큼 띄워 지면선을 화면 아래쪽으로 내림

# ─────────── 게임성 우선 모드(스토리 제거): 전투-클리어 전용 ───────────
# true 면 NPC·대사·퀘스트·스토리 픽업·자동퀘스트를 빌드하지 않고,
# 아래 CHAIN(전투 스테이지 직선 흐름)대로 전진 게이트+출구만 합성한다.
# 스토리를 되살리려면 GAMEPLAY_ONLY 를 false 로만 바꾸면 기존 데이터 흐름이 복구된다.
const GAMEPLAY_ONLY := true
# 난이도 곡선: 잡몹 → 잡몹+호랑이 → 더 많은 잡몹 → 중간보스(구미호 여왕) → 최종보스(대호)
# 1스테이지(물이 잠긴 골짜기, foothills~sacred_altar/골짜기의 수살귀) 뒤로 2스테이지(그슨대 숲)가,
# 그 뒤로 3스테이지(저잣거리 도깨비, market_ruins~goblin_court/DokkaebiChief)가 이어진다.
const CHAIN := [
    "foothills", "forest_deep", "mountain_pass", "ruined_temple", "sacred_altar",
    "forest_shadow", "forest_mist", "withered_hollow", "wailing_thicket", "elder_hollow",
    "market_ruins", "broken_stalls", "well_court", "lantern_alley", "goblin_court",
]
const CHAIN_TSCN := {
    "foothills": "res://scenes/levels/Foothills.tscn",
    "forest_deep": "res://scenes/levels/ForestDeep.tscn",
    "ruined_temple": "res://scenes/levels/RuinedTemple.tscn",
    "mountain_pass": "res://scenes/levels/MountainPass.tscn",
    "sacred_altar": "res://scenes/levels/SacredAltar.tscn",
    "forest_shadow": "res://scenes/levels/ForestShadow.tscn",
    "forest_mist": "res://scenes/levels/ForestMist.tscn",
    "withered_hollow": "res://scenes/levels/WitheredHollow.tscn",
    "wailing_thicket": "res://scenes/levels/WailingThicket.tscn",
    "elder_hollow": "res://scenes/levels/ElderHollow.tscn",
    "market_ruins": "res://scenes/levels/MarketRuins.tscn",
    "broken_stalls": "res://scenes/levels/BrokenStalls.tscn",
    "well_court": "res://scenes/levels/WellCourt.tscn",
    "lantern_alley": "res://scenes/levels/LanternAlley.tscn",
    "goblin_court": "res://scenes/levels/GoblinCourt.tscn",
}
const CLEAR_SCENE := "res://scenes/ui/Clear.tscn"
const FWD_GATE_X := 1360.0       # 전진 차단 결계 x
const FWD_EXIT_X := 1500.0       # (미사용) 예전 전진 출구 x — 이제 결계와 같은 자리에 낸다
## 결계 앞으로 적을 당길 때 남기는 여유(px). 결계에 딱 붙어 서면 때리기 답답하다.
const GATE_ENEMY_MARGIN := 140.0
## 자동 대사 지점 주변 이만큼은 적을 두지 않는다(대화 직후 난타 방지).
const ENEMY_DIALOGUE_CLEARANCE := 260.0

@export var stage_id: String = ""


func _ready() -> void:
    # 스코어 어택 런 관리 — 첫 전투 스테이지면 새 런 시작(점수·시간 리셋),
    # 이후 체인 스테이지/이어하기면 유지한 채 계속 카운트.
    if stage_id == CHAIN[0]:
        ScoreManager.start_run()
    else:
        ScoreManager.resume()
    var data := _load()
    if data.is_empty():
        push_error("[Stage] stage json 없음: %s" % stage_id)
        return
    # 「해원」 스토리 스테이지는 JSON 에 "gut"(굽이 번호)을 둔다 — 전투-클리어 전용 모드여도
    # 이 스테이지들은 항상 스토리 빌드 경로로 가서 기억 소거 배선을 받는다.
    # (옛 전투 체인 스테이지엔 "gut"이 없어 GAMEPLAY_ONLY 동작 그대로 — test_gameplay_chain 유지.)
    var is_story := data.has("gut")
    if GAMEPLAY_ONLY and not is_story:
        _build_gameplay(data)
        return
    # 이미 클리어한 구간(게이트 flag 셋)이면 적·게이트를 다시 만들지 않음 — 되돌아가도 재전투 X.
    var cleared := _is_cleared(data.get("gates", []))
    _build_backdrop(data.get("backdrop", {}))
    _build_ground(data.get("ground", {}))
    _build_platforms(data.get("platforms", []), String(data.get("ground", {}).get("tileset", "earth")))
    _build_props(data.get("props", []))
    _build_entries(data.get("entries", []))
    if not cleared:
        _build_enemies(data.get("enemies", []))
    _build_npcs(data.get("npcs", []))
    _build_pickups(data.get("pickups", []))
    _build_auto_dialogues(data.get("auto_dialogues", []))
    _build_auto_cutscenes(data.get("auto_cutscenes", []))
    _build_interactables(data.get("interactables", []))
    _build_quest_triggers(data.get("quest_triggers", []))
    if not cleared:
        _build_gates(data.get("gates", []))
    _build_exits(data.get("exits", []))
    _build_player(data)
    _build_ui()
    # 스테이지 진입 시 퀘스트 자동 시작/단계 설정 (퀘스트 받으러 다니지 않게)
    var aq = data.get("auto_quest", {})
    if aq is Dictionary and aq.has("id"):
        var qid := String(aq["id"])
        if not QuestManager.is_completed(qid):
            if not QuestManager.is_active(qid):
                QuestManager.start_quest(qid)
            if aq.has("stage"):
                QuestManager.set_stage(qid, String(aq["stage"]))
    # 「해원」: 이 굽이의 진혼이 끝나면(결계 열림) 기억 한 조각을 지우고 진혼 후 대사를 연다.
    if is_story:
        _wire_haewon(data, cleared)


# ─────────── 「해원」 기억 소거 배선 ───────────
## 스토리 스테이지(JSON "gut")의 진혼 완료를 MemoryLedger 에 잇는다.
## 전투가 있는 굽이: 결계(CombatGate).opened → 소거 + clear_dialogue.
## 전투가 없는 굽이(예: 빈 고을): 진입 직후(이미 클리어 아닐 때) 소거.
func _wire_haewon(data: Dictionary, cleared: bool) -> void:
    var gut := int(data.get("gut", -1))
    if gut < 0:
        return
    var clear_dialogue := String(data.get("clear_dialogue", ""))
    # 진혼 후 대사를 '걷는 회상/정적'(수묵 흑백 오버랩)으로 감쌀지.
    var clear_inkwash := bool(data.get("clear_inkwash", false))
    # 진혼 후 '회상 컷' — 전투맵 위 말풍선 대신 전용 회상 씬으로 컷 전환했다가 복귀.
    # (있으면 clear_dialogue/clear_inkwash 대신 이 경로로 간다 — 대사는 컷씬 JSON 안에서 재생.)
    var clear_cutscene := String(data.get("clear_cutscene", ""))
    # 이미 클리어한 구간을 되돌아온 경우: 소거는 세이브에 남아 있으니 다시 하지 않는다.
    if cleared:
        return
    var gate: CombatGate = null
    for c in get_children():
        if c is CombatGate:
            gate = c
            break
    if gate != null:
        gate.opened.connect(_on_gut_cleared.bind(gut, clear_dialogue, clear_inkwash, clear_cutscene))
    else:
        # 전투 없는 굽이 — 진입 직후 한 박자 뒤 소거(자동 대사가 정황을 깔도록).
        await get_tree().create_timer(0.6).timeout
        _on_gut_cleared(gut, clear_dialogue, clear_inkwash, clear_cutscene)


func _on_gut_cleared(gut: int, clear_dialogue: String, ink: bool = false, clear_cutscene: String = "") -> void:
    MemoryLedger.erase_for_gut(gut)
    # 회상 컷이 지정돼 있으면 — 잠깐 뒤 전용 회상 씬으로 컷 전환(복귀 대상 = 이 전투 씬).
    if clear_cutscene != "" and ResourceLoader.exists(clear_cutscene) and SceneManager:
        await get_tree().create_timer(0.5).timeout
        var ret := ""
        if get_tree().current_scene != null:
            ret = get_tree().current_scene.scene_file_path
        SceneManager.play_cutscene(clear_cutscene, ret, &"from_recall")
        return
    if ink and InkWash:
        InkWash.enter()
    if clear_dialogue != "" and ResourceLoader.exists(clear_dialogue):
        # 결계 개방 연출과 겹치지 않게 살짝 뒤에 진혼 후 독백.
        await get_tree().create_timer(0.5).timeout
        Dialogue.start(clear_dialogue)
        if ink and InkWash:
            await Dialogue.dialogue_ended   # 회상/정적 대사가 끝나면 색 복귀
            InkWash.exit()
    elif ink and InkWash:
        await get_tree().create_timer(2.0).timeout
        InkWash.exit()


func _load() -> Dictionary:
    var path := "res://assets/stages/%s.json" % stage_id
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


func _build_backdrop(b: Dictionary) -> void:
    var bd: ParallaxBackground = load(BACKDROP_SCENE).instantiate()
    bd.sky_color = _col(b.get("sky", null), Color(0.93, 0.89, 0.78))
    bd.tint = _col(b.get("tint", null), Color.WHITE)
    if b.has("art_set"):
        bd.art_set = String(b["art_set"])
    if b.has("far_scale"):
        bd.far_scale = float(b["far_scale"])
    # 장면 성격에 맞춰 원경을 끄고 켠다 — 담 안 마당에 산맥이 보이지 않게.
    if b.has("mountains"):
        bd.mountains = bool(b["mountains"])
    if b.has("clouds"):
        bd.clouds = bool(b["clouds"])
    if b.has("mist"):
        bd.mist = bool(b["mist"])
    if b.has("horizon_y"):
        bd.horizon_y = float(b["horizon_y"])
    if b.has("night_luminance"):
        bd.night_luminance = float(b["night_luminance"])
    add_child(bd)


## 지면 빌드 디스패처: "tileset"(신규 사이드뷰 wang 타일셋)이 있으면 그걸,
## 없으면 옛 단일 타일("tex") 방식으로 폴백.
## 화면비가 넓은 폰(19.5:9 등)에서는 stretch=expand 로 뷰포트가 가로로 넓어져
## 스테이지 양 끝 바깥이 보일 수 있다 → 지면을 좌우로 넉넉히 덧대 빈 칸을 없앤다.
const GROUND_EDGE_PAD := 500


func _build_ground(g: Dictionary) -> void:
    var padded := g.duplicate()
    padded["x"] = int(g.get("x", -600)) - GROUND_EDGE_PAD
    padded["width"] = int(g.get("width", 2800)) + GROUND_EDGE_PAD * 2
    if padded.has("tileset") and ResourceLoader.exists(SIDE_DIR % String(padded["tileset"])):
        _build_ground_tileset(padded)
    else:
        _build_ground_legacy(padded)


## 신규 지면 — 잔디/서리 윗면 + 꽉 찬 속. 시트에서 두 타일만 잘라 repeat 로 넓게 깐다.
func _build_ground_tileset(g: Dictionary) -> void:
    var name := String(g.get("tileset", "earth"))
    var w := int(g.get("width", 2800))
    var gx := int(g.get("x", -600))
    var mod := _col(g.get("tint", null), Color(0.94, 0.92, 0.89))  # 살짝 눌러 배경과 조화
    var sheet: Texture2D = load(SIDE_DIR % name)
    var patterns := _terrain_patterns(sheet)
    var surf: Texture2D = patterns["surface"]
    var fill: Texture2D = patterns["fill"]
    # ① 속(흙/돌) — 지면선부터 아래로 (윗면 타일의 투명부 뒤를 메움)
    _tiled_from_tex(fill, w, 360, Vector2(gx, GROUND_TOP), mod)
    # ② 윗면(잔디/서리) — 위로 살짝 올려 얹어 잔디가 지면선에 걸치게
    _tiled_from_tex(surf, w, 32, Vector2(gx, GROUND_TOP - SURFACE_RISE), mod)
    _add_ground_collision(gx, w)


func _build_ground_legacy(g: Dictionary) -> void:
    var tex_name := String(g.get("tex", "ground_dirt"))
    var w := int(g.get("width", 2800))
    var gx := int(g.get("x", -600))
    # 시각: 흙 본체 + 윗면 띠
    for spec in [[GROUND_TOP + 32, 340], [GROUND_TOP, 36]]:
        var t := TiledSprite.new()
        t.tex_path = TILE_DIR % tex_name
        t.width = w
        t.height = spec[1]
        t.position = Vector2(gx, spec[0])
        add_child(t)
    _add_ground_collision(gx, w)


func _add_ground_collision(gx: int, w: int) -> void:
    var body := StaticBody2D.new()
    body.collision_layer = 4        # 월드(bit3) — 플레이어·적 몸이 밟고 선다
    body.position = Vector2(gx + w / 2.0, GROUND_Y)
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(w, 32)
    cs.shape = shape
    body.add_child(cs)
    add_child(body)


## 시트에서 32x32 한 칸을 잘라 독립 텍스처로 — repeat 로 넓게 깔 수 있게.
func _crop_tile(sheet: Texture2D, at: Vector2i) -> ImageTexture:
    return _crop_region(sheet, Rect2i(at.x, at.y, 32, 32))


func _crop_region(sheet: Texture2D, rect: Rect2i) -> ImageTexture:
    var img := sheet.get_image()
    var region := img.get_region(rect)
    return ImageTexture.create_from_image(region)


## 1스테이지 pro atlas(256x224)와 기존 스테이지 wang atlas(128x128)를 함께 지원한다.
func _terrain_patterns(sheet: Texture2D) -> Dictionary:
    if sheet.get_width() >= 256 and sheet.get_height() >= 224:
        return {
            "surface": _crop_region(sheet, SURFACE_RECT),
            "fill": _crop_region(sheet, FILL_RECT),
        }
    return {
        "surface": _crop_tile(sheet, LEGACY_SURFACE_TILE),
        "fill": _crop_tile(sheet, LEGACY_FILL_TILE),
    }


## 패턴 텍스처를 실제 조각으로 이어 붙인다. 동적 ImageTexture는 일부 렌더러에서
## region repeat 시 두 번째 주기부터 투명하게 잘리는 현상이 있어 수동 타일링이 안전하다.
func _tiled_from_tex(tex: Texture2D, w: int, h: int, pos: Vector2, mod: Color) -> void:
    var tile_w := maxi(1, tex.get_width())
    var tile_h := maxi(1, tex.get_height())
    for y in range(0, h, tile_h):
        for x in range(0, w, tile_w):
            var piece := Sprite2D.new()
            piece.texture = tex
            piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            piece.centered = false
            piece.region_enabled = true
            piece.region_rect = Rect2(0, 0, mini(tile_w, w - x), mini(tile_h, h - y))
            piece.position = pos + Vector2(x, y)
            piece.modulate = mod
            add_child(piece)


## 떠 있는 발판 — 위에서 밟고 설 수 있고 아래에서 점프로 통과(one-way). 지면 타일셋으로 그린다.
func _build_platforms(items: Array, ground_tileset: String) -> void:
    for p in items:
        if not (p is Dictionary):
            continue
        var px := float(p.get("x", 600))
        var py := float(p.get("y", 560))     # 밟는 윗면 y
        var pw := int(p.get("w", 160))
        var name := String(p.get("tileset", ground_tileset))
        var mod := _col(p.get("tint", null), Color(0.94, 0.92, 0.89))
        var left := px - pw / 2.0
        if ResourceLoader.exists(SIDE_DIR % name):
            var sheet: Texture2D = load(SIDE_DIR % name)
            var patterns := _terrain_patterns(sheet)
            var surf: Texture2D = patterns["surface"]
            var fill: Texture2D = patterns["fill"]
            _tiled_from_tex(fill, pw, 40, Vector2(left, py + 12.0), mod)
            _tiled_from_tex(surf, pw, 32, Vector2(left, py - SURFACE_RISE), mod)
        elif ResourceLoader.exists(TILE_DIR % "wood_platform"):
            var t := TiledSprite.new()
            t.tex_path = TILE_DIR % "wood_platform"
            t.width = pw; t.height = 32
            t.position = Vector2(left, py - 8.0)
            add_child(t)
        # 충돌 — 윗면(py)만 막는 one-way 발판
        var body := StaticBody2D.new()
        body.collision_layer = 4    # 월드(bit3)
        body.position = Vector2(px, py + 8.0)
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = Vector2(pw, 16)
        cs.shape = shape
        cs.one_way_collision = true
        body.add_child(cs)
        add_child(body)


## 소품 배치 — **바닥 정렬을 코드가 계산한다**(2026-08-22).
##
## 예전엔 JSON 에 `offset` 을 손으로 적어 맞췄는데, 텍스처가 바뀌거나 scale 을 조정할 때마다
## 다시 재야 해서 결국 공중에 뜨거나 바닥을 뚫는 소품이 계속 나왔다(사용자 지적).
## 이제는 텍스처의 **불투명 영역 아래 끝**이 JSON 의 y 에 정확히 닿도록 offset 을 자동 계산한다.
## scale 을 바꿔도, 그림을 새로 뽑아도 정렬이 저절로 유지된다.
##
## 예외가 필요하면(허공에 매단 등불 등) JSON 에 "free_offset": true 를 주면 옛 방식(수동 offset).
func _build_props(props: Array) -> void:
    for p in props:
        if not (p is Dictionary):
            continue
        var tex_path := TILE_DIR % String(p.get("tex", ""))
        if not ResourceLoader.exists(tex_path):
            continue
        var spr := Sprite2D.new()
        var tex: Texture2D = load(tex_path)
        spr.texture = tex
        spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        spr.centered = false
        spr.scale = Vector2.ONE * float(p.get("scale", 1.0))
        if bool(p.get("free_offset", false)):
            var off = p.get("offset", [0, 0])
            spr.offset = Vector2(off[0], off[1]) if off is Array else Vector2.ZERO
        else:
            spr.offset = ground_align_offset(tex)
        spr.position = Vector2(float(p.get("x", 0)), float(p.get("y", GROUND_TOP)))
        add_child(spr)


## 그림의 '발밑 가운데'를 원점으로 오게 하는 offset. centered=false 인 Sprite2D 기준.
## 투명 여백이 얼마나 있든, 보이는 부분의 아래 끝이 노드 y 에 딱 닿는다.
static func ground_align_offset(tex: Texture2D) -> Vector2:
    if tex == null:
        return Vector2.ZERO
    var img := tex.get_image()
    if img == null:
        return Vector2.ZERO
    var used := img.get_used_rect()
    if used.size.x <= 0 or used.size.y <= 0:
        return Vector2.ZERO
    return Vector2(
        -(float(used.position.x) + float(used.size.x) * 0.5),
        -(float(used.position.y) + float(used.size.y)))

func _build_entries(entries: Array) -> void:
    for e in entries:
        if not (e is Dictionary):
            continue
        var m := Marker2D.new()
        m.name = String(e.get("name", "default"))
        m.position = Vector2(float(e.get("x", 120)), float(e.get("y", 400)))
        m.add_to_group("level_entry")
        add_child(m)


func _build_enemies(enemies: Array) -> void:
    for e in enemies:
        if not (e is Dictionary):
            continue
        var path := ENEMY_DIR % String(e.get("scene", ""))
        if not ResourceLoader.exists(path):
            push_warning("[Stage] 적 씬 없음: %s" % path)
            continue
        var inst := load(path).instantiate() as Node2D
        inst.position = Vector2(float(e.get("x", 800)), float(e.get("y", 656)))
        if e.has("optional") and "optional" in inst:
            inst.optional = bool(e["optional"])
        if e.has("on_death_flag") and "on_death_flag" in inst:
            inst.on_death_flag = String(e["on_death_flag"])
        add_child(inst)


func _build_npcs(npcs: Array) -> void:
    for n in npcs:
        if not (n is Dictionary):
            continue
        var inst := load(NPC_SCENE).instantiate() as Node2D
        inst.position = Vector2(float(n.get("x", 400)), float(n.get("y", 668)))
        if "dialogue" in inst:
            inst.dialogue_path = String(n.get("dialogue", ""))
        if n.has("sheet") and "sheet" in inst:
            inst.sheet = String(n["sheet"])
        if n.has("once_flag") and "once_flag" in inst:
            inst.once_flag = String(n["once_flag"])
        add_child(inst)


func _build_pickups(pickups: Array) -> void:
    var pickup_script: Script = load("res://scripts/quests/pickup.gd")
    for p in pickups:
        if not (p is Dictionary):
            continue
        var area := Area2D.new()
        area.collision_mask = 1
        area.set_script(pickup_script)
        area.position = Vector2(float(p.get("x", 600)), float(p.get("y", 660)))
        area.item_id = String(p.get("item", ""))
        area.count = int(p.get("count", 1))
        area.icon = String(p.get("icon", ""))
        area.pickup_label = String(p.get("label", ""))
        area.quest_id = String(p.get("quest", ""))
        area.quest_stage = String(p.get("stage", ""))
        area.flag_key = String(p.get("flag", ""))
        area.requires_quest_active = String(p.get("requires_active", ""))
        var cs := CollisionShape2D.new()
        var shape := CircleShape2D.new()
        shape.radius = float(p.get("radius", 18))
        cs.shape = shape
        area.add_child(cs)
        add_child(area)


func _build_auto_dialogues(items: Array) -> void:
    var ad_script: Script = load("res://scripts/world/auto_dialogue.gd")
    for a in items:
        if not (a is Dictionary):
            continue
        var area := Area2D.new()
        area.collision_mask = 1
        area.set_script(ad_script)
        area.position = Vector2(float(a.get("x", 560)), float(a.get("y", 620)))
        area.dialogue_path = String(a.get("dialogue", ""))
        area.once_flag = String(a.get("once_flag", ""))
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = Vector2(float(a.get("w", 120)), float(a.get("h", 110)))
        cs.shape = shape
        area.add_child(cs)
        add_child(area)


## 위치 기반 회상 컷 트리거(게이트 없는 굽이용). 밟으면 회상 씬으로 컷 전환→복귀.
func _build_auto_cutscenes(items: Array) -> void:
    var ac_script: Script = load("res://scripts/world/auto_cutscene.gd")
    for a in items:
        if not (a is Dictionary):
            continue
        var area := Area2D.new()
        area.collision_mask = 1
        area.set_script(ac_script)
        area.position = Vector2(float(a.get("x", 560)), float(a.get("y", 620)))
        area.cutscene_path = String(a.get("cutscene", ""))
        area.once_flag = String(a.get("once_flag", ""))
        area.return_entry = String(a.get("return_entry", "from_recall"))
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = Vector2(float(a.get("w", 120)), float(a.get("h", 110)))
        cs.shape = shape
        area.add_child(cs)
        add_child(area)


## 조사 가능한 지형지물(#2) — 가까이서 interact 키로 대사/플래그 발동. tex 주면 그림도 함께.
func _build_interactables(items: Array) -> void:
    var it_script: Script = load("res://scripts/world/interactable.gd")
    for a in items:
        if not (a is Dictionary):
            continue
        var area := Area2D.new()
        area.collision_mask = 1
        area.set_script(it_script)
        area.position = Vector2(float(a.get("x", 560)), float(a.get("y", GROUND_TOP)))
        area.dialogue_path = String(a.get("dialogue", ""))
        area.flag_on_use = String(a.get("flag", ""))
        area.once = a.get("once", true) != false
        area.once_flag = String(a.get("once_flag", ""))
        var po = a.get("prompt_offset", null)
        if po is Array and po.size() == 2:
            area.prompt_offset = Vector2(po[0], po[1])
        # 선택: 지형지물 그림(props 와 동일한 방식) — 없으면 보이지 않는 조사 영역만.
        if a.has("tex"):
            var tp := TILE_DIR % String(a["tex"])
            if ResourceLoader.exists(tp):
                var spr := Sprite2D.new()
                spr.texture = load(tp)
                spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
                spr.centered = false
                spr.scale = Vector2.ONE * float(a.get("scale", 1.0))
                var off = a.get("offset", [0, 0])
                spr.offset = Vector2(off[0], off[1]) if off is Array else Vector2.ZERO
                area.add_child(spr)
        var cs := CollisionShape2D.new()
        var shape := CircleShape2D.new()
        shape.radius = float(a.get("radius", 40))
        cs.shape = shape
        area.add_child(cs)
        add_child(area)


func _build_quest_triggers(items: Array) -> void:
    var qt_script: Script = load("res://scripts/quests/quest_trigger.gd")
    for q in items:
        if not (q is Dictionary):
            continue
        var area := Area2D.new()
        area.collision_mask = 1
        area.set_script(qt_script)
        area.position = Vector2(float(q.get("x", 220)), float(q.get("y", 620)))
        area.quest_id = String(q.get("quest", ""))
        area.quest_stage = String(q.get("stage", ""))
        area.only_if_quest_active = String(q.get("only_active", ""))
        area.flag_key = String(q.get("flag", ""))
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = Vector2(96, 110)
        cs.shape = shape
        area.add_child(cs)
        add_child(area)


func _build_exits(exits: Array) -> void:
    for x in exits:
        if not (x is Dictionary):
            continue
        _spawn_exit(float(x.get("x", 1560)), String(x.get("target", "")),
            String(x.get("entry", "default")), _col(x.get("color", null), Color(0.55, 0.5, 0.3, 0.5)),
            float(x.get("y", 620)))


## 출구 영역 1개 생성(전진/스토리 공용).
## 만든 출구 Area2D 를 돌려준다(결계와 연동해 열고 닫기 위해).
func _spawn_exit(x: float, target: String, entry: String, color: Color, y: float = 620.0,
        show_art: bool = true) -> Area2D:
    if target.is_empty():
        return null
    var area := Area2D.new()
    area.collision_mask = 1
    area.set_script(load("res://scripts/scene/level_exit.gd"))
    area.position = Vector2(x, y)
    area.target_scene = target
    area.target_entry = StringName(entry)
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(32, 96)
    cs.shape = shape
    area.add_child(cs)
    # 열린 출구도 결계와 같은 금줄 경계석의 마지막 상태를 쓴다.
    # 전투 게이트가 함께 있으면 그 노드가 해제 후 그대로 남으므로 중복 그림은 만들지 않는다.
    if show_art:
        if ResourceLoader.exists(GateArt.SHEET):
            var art := GateArt.make_sprite(true)
            art.position = Vector2(0, -40)     # area y=620 기준 바닥 y=684
            area.add_child(art)
        else:
            var mark := ColorRect.new()
            mark.color = color
            mark.offset_left = -16; mark.offset_top = -48
            mark.offset_right = 16; mark.offset_bottom = 48
            area.add_child(mark)
    add_child(area)
    return area


# ─────────── 게임성 우선(전투-클리어 전용) 빌드 ───────────
func _build_gameplay(data: Dictionary) -> void:
    var clear_flag := _clear_flag(data)
    var cleared := clear_flag != "" and Flags.has_flag(clear_flag)
    _build_backdrop(data.get("backdrop", {}))
    _build_ground(data.get("ground", {}))
    _build_platforms(data.get("platforms", []), String(data.get("ground", {}).get("tileset", "earth")))
    _build_props(data.get("props", []))
    # 전투 전용 모드에도 위치 대사를 허용한다 — 새 기믹(그슨대: 칼이 안 먹힘)처럼
    # **플레이어가 모르면 막히는 규칙**은 게임 안에서 한 줄이라도 알려줘야 한다.
    _build_auto_dialogues(data.get("auto_dialogues", []))
    _build_interactables(data.get("interactables", []))
    _build_entries(data.get("entries", []))
    var has_enemies := (data.get("enemies", []) as Array).size() > 0
    if not cleared:
        # 배치 정리(2026-08-22 피드백 2건):
        #  · 결계 뒤에 적이 있으면 원거리로만 잡아야 해서 답답하다 → 전부 결계 앞으로 당긴다.
        #  · 대사 트리거가 몹들 사이에 있으면 대화가 끝나는 순간 두들겨 맞는다 → 떼어 놓는다.
        _build_enemies(_sanitize_enemy_spots(data.get("enemies", []),
            data.get("auto_dialogues", [])))
    # 전진 차단 결계 — 신규 진입 + 적이 있을 때만(적 0 처치 시 자동 개방)
    var gate: Node2D = null
    if not cleared and has_enemies:
        gate = Node2D.new()
        gate.set_script(load("res://scripts/world/combat_gate.gd"))
        gate.position = Vector2(FWD_GATE_X, 600)
        gate.open_flag = clear_flag
        gate.gate_height = 260
        add_child(gate)
    # 전진 출구 — 결계와 **같은 자리**에 낸다. 금줄 경계석 하나가 봉인과 통과 표식을 겸한다.
    # 다 처치하면 금줄이 실제로 풀리고, 별도 문으로 교체하지 않는다.
    var exit_node := _spawn_exit(FWD_GATE_X, _next_target(), "default", Color(0.5, 0.55, 0.4, 0.5),
        620.0, gate == null)
    if gate != null and exit_node != null:
        # 금줄이 묶인 동안 출구 판정은 잠겨 있다(보이지도, 통하지도 않는다).
        exit_node.visible = false
        exit_node.set_deferred("monitoring", false)
        gate.opened.connect(func() -> void:
            if not is_instance_valid(exit_node):
                return
            exit_node.visible = true
            exit_node.set_deferred("monitoring", true)
            exit_node.modulate.a = 0.0
            exit_node.create_tween().tween_property(exit_node, "modulate:a", 1.0, 0.5))
    _build_player(data)
    _build_ui()


## 배치 좌표 보정 — 규칙을 코드로 못박아 데이터가 어긋나도 플레이가 깨지지 않게 한다.
##  ① 결계(FWD_GATE_X) 뒤의 적은 결계 앞으로 당긴다.
##  ② 자동 대사 지점 반경 ENEMY_DIALOGUE_CLEARANCE 안의 적은 바깥으로 밀어낸다.
func _sanitize_enemy_spots(enemies: Array, dialogues: Array) -> Array:
    var out: Array = []
    for raw in enemies:
        if not (raw is Dictionary):
            continue
        var e: Dictionary = (raw as Dictionary).duplicate()
        var x := float(e.get("x", 0.0))
        if x > FWD_GATE_X - GATE_ENEMY_MARGIN:
            x = FWD_GATE_X - GATE_ENEMY_MARGIN
        for d in dialogues:
            if not (d is Dictionary):
                continue
            var dx := float(d.get("x", -99999.0))
            if absf(x - dx) < ENEMY_DIALOGUE_CLEARANCE:
                # 대사 지점 기준으로 먼 쪽(뒤쪽)으로 밀어낸다 — 앞으로 밀면 결계에 붙는다.
                x = dx - ENEMY_DIALOGUE_CLEARANCE if x <= dx else dx + ENEMY_DIALOGUE_CLEARANCE
                x = minf(x, FWD_GATE_X - GATE_ENEMY_MARGIN)
        e["x"] = x
        out.append(e)
    return out

## 클리어 판정 플래그: JSON 게이트에 명시돼 있으면 그걸, 없으면 "<stage_id>_cleared".
func _clear_flag(data: Dictionary) -> String:
    var gates = data.get("gates", [])
    if gates is Array and gates.size() > 0 and gates[0] is Dictionary:
        var f := String(gates[0].get("flag", ""))
        if f != "":
            return f
    return stage_id + "_cleared"


## 체인상의 다음 목적지(.tscn). 마지막이면 클리어 화면, 체인 밖이면 체인 시작.
func _next_target() -> String:
    var idx := CHAIN.find(stage_id)
    if idx >= 0 and idx + 1 < CHAIN.size():
        return CHAIN_TSCN[CHAIN[idx + 1]]
    if idx == CHAIN.size() - 1:
        return CLEAR_SCENE
    return CHAIN_TSCN[CHAIN[0]]


## 게이트 중 하나라도 open_flag 가 이미 셋이면 이 구간은 클리어된 것으로 본다.
func _is_cleared(gates: Array) -> bool:
    for g in gates:
        if g is Dictionary:
            var f := String(g.get("flag", ""))
            if f != "" and Flags.has_flag(f):
                return true
    return false


func _build_gates(gates: Array) -> void:
    var gate_script: Script = load("res://scripts/world/combat_gate.gd")
    for g in gates:
        if not (g is Dictionary):
            continue
        var gate := Node2D.new()
        gate.set_script(gate_script)
        gate.position = Vector2(float(g.get("x", 1400)), float(g.get("y", 600)))
        gate.open_flag = String(g.get("flag", ""))
        gate.gate_height = float(g.get("height", 200))
        add_child(gate)


func _build_player(data: Dictionary) -> void:
    var player := load(PLAYER_SCENE).instantiate() as Node2D
    player.position = Vector2(float(data.get("player_x", 120)), 400.0)
    add_child(player)
    var cam := Camera2D.new()
    # 카메라를 캐릭터 기준 위로 띄워 지면선을 화면 중앙이 아니라 아래쪽(약 70%)으로 내림 —
    # 안 그러면 화면 절반이 땅으로 보이고, 모바일 터치 버튼 클러스터와 캐릭터/적이 겹친다.
    # 설정 → 시야(카메라 배율). ViewConfig 가 이 그룹을 보고 실시간으로 갱신한다.
    # offset 은 월드 단위라 확대하면 화면에서 그만큼 더 밀린다 — 배율로 나눠
    # '화면에서 본 지면선 위치'가 배율과 무관하게 같게 유지한다.
    cam.set_meta("base_offset", Vector2(0, -CAMERA_OFFSET_Y))
    cam.add_to_group("player_cam")
    cam.zoom = Vector2(ViewConfig.zoom, ViewConfig.zoom)
    cam.offset = Vector2(0, -CAMERA_OFFSET_Y / ViewConfig.zoom)
    player.add_child(cam)


func _build_ui() -> void:
    add_child(load(MOBILE_SCENE).instantiate())
    add_child(load(HUD_SCENE).instantiate())
