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
##   "npcs":     [{"x":400,"dialogue":"res://assets/dialogue/x.json"}],
##   "pickups":  [{"x":600,"item":"herb_field","icon":"herb","count":1,"label":"..","quest":"","stage":"","flag":"","requires_active":""}],
##   "auto_dialogues":[{"x":560,"dialogue":"res://..","once_flag":".."}],
##   "quest_triggers":[{"x":220,"quest":"main_tiger_lord","stage":"boss_arena","only_active":"main_tiger_lord","flag":""}],
##   "exits":    [{"x":1560,"target":"res://scenes/levels/X.tscn","entry":"from_y","color":[.5,.2,.18]}]
## }
##

const TILE_DIR := "res://assets/tilesets/%s.png"
const ENEMY_DIR := "res://scenes/enemies/%s.tscn"
const PLAYER_SCENE := "res://scenes/player/Player.tscn"
const NPC_SCENE := "res://scenes/npc/Npc.tscn"
const HUD_SCENE := "res://scenes/ui/PlayerHud.tscn"
const MOBILE_SCENE := "res://scenes/ui/MobileControls.tscn"
const BACKDROP_SCENE := "res://scenes/world/Backdrop.tscn"
const GROUND_Y := 700.0
const GROUND_TOP := 684          # 지면 윗면 y (시각 타일 상단)

@export var stage_id: String = ""


func _ready() -> void:
    var data := _load()
    if data.is_empty():
        push_error("[Stage] stage json 없음: %s" % stage_id)
        return
    # 이미 클리어한 구간(게이트 flag 셋)이면 적·게이트를 다시 만들지 않음 — 되돌아가도 재전투 X.
    var cleared := _is_cleared(data.get("gates", []))
    _build_backdrop(data.get("backdrop", {}))
    _build_ground(data.get("ground", {}))
    _build_props(data.get("props", []))
    _build_entries(data.get("entries", []))
    if not cleared:
        _build_enemies(data.get("enemies", []))
    _build_npcs(data.get("npcs", []))
    _build_pickups(data.get("pickups", []))
    _build_auto_dialogues(data.get("auto_dialogues", []))
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
    if b.has("far_scale"):
        bd.far_scale = float(b["far_scale"])
    add_child(bd)


func _build_ground(g: Dictionary) -> void:
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
    # 충돌: 시각 폭과 동일하게
    var body := StaticBody2D.new()
    body.position = Vector2(gx + w / 2.0, GROUND_Y)
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(w, 32)
    cs.shape = shape
    body.add_child(cs)
    add_child(body)


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
    var exit_script: Script = load("res://scripts/scene/level_exit.gd")
    for x in exits:
        if not (x is Dictionary):
            continue
        var area := Area2D.new()
        area.collision_mask = 1
        area.set_script(exit_script)
        area.position = Vector2(float(x.get("x", 1560)), float(x.get("y", 620)))
        area.target_scene = String(x.get("target", ""))
        area.target_entry = StringName(String(x.get("entry", "default")))
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = Vector2(32, 96)
        cs.shape = shape
        area.add_child(cs)
        # 표식 (반투명 기둥)
        var mark := ColorRect.new()
        mark.color = _col(x.get("color", null), Color(0.55, 0.5, 0.3, 0.5))
        mark.offset_left = -16; mark.offset_top = -48
        mark.offset_right = 16; mark.offset_bottom = 48
        area.add_child(mark)
        add_child(area)


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
    player.add_child(cam)


func _build_ui() -> void:
    add_child(load(MOBILE_SCENE).instantiate())
    add_child(load(HUD_SCENE).instantiate())
