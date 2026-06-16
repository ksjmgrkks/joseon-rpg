extends Area2D
class_name Pickup
##
## Pickup — 플레이어가 닿으면 아이템을 지급하고, 옵션으로 퀘스트 단계/플래그를 갱신.
##
## 사용:
##   - 플레이어 그룹과 충돌(layer 1, collision_mask=1)
##   - item_id/count 가 비면 아무 아이템도 안 지급(트리거 전용).
##   - quest_id + quest_stage 가 모두 채워져 있으면 set_stage 실행.
##   - quest_id 만 있으면 start_quest 실행.
##   - flag_key 가 있으면 Flags.set_flag(flag_key, flag_value).
##   - destroy_on_pickup=true 면 발동 후 큐프리.
##

@export var item_id: String = ""
@export var count: int = 1
@export var quest_id: String = ""
@export var quest_stage: String = ""
@export var flag_key: String = ""
@export var flag_value: bool = true
@export var destroy_on_pickup: bool = true
@export var pickup_label: String = ""
# 비워두면 항상 동작. 채워져 있으면 그 퀘스트가 active 일 때만 픽업 가능.
@export var requires_quest_active: String = ""
# assets/sprites/pickups/<icon>.png 아이콘. 지정 시 기존 placeholder(ColorRect)는 숨기고
# 스프라이트를 띄워 살짝 부유시킨다. (charm/herb/coin/scroll)
@export var icon: String = ""

var _used: bool = false


## 적 처치 드롭 등 — 런타임에 픽업 하나를 parent 에 떨군다.
static func spawn(parent: Node, pos: Vector2, item_id: String, count: int = 1,
                  icon: String = "", label: String = "") -> Area2D:
    if parent == null or not is_instance_valid(parent):
        return null
    var a := Area2D.new()
    a.set_script(load("res://scripts/quests/pickup.gd"))
    a.collision_mask = 1
    a.item_id = item_id
    a.count = count
    a.icon = icon
    a.pickup_label = label
    var cs := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = 18.0
    cs.shape = shape
    a.add_child(cs)
    parent.add_child(a)
    a.global_position = pos
    return a


func _ready() -> void:
    monitoring = true
    body_entered.connect(_on_body_entered)
    _setup_icon()


func _setup_icon() -> void:
    if icon == "":
        return
    var tex_path := "res://assets/sprites/pickups/%s.png" % icon
    if not ResourceLoader.exists(tex_path):
        return
    # placeholder ColorRect 자식이 있으면 숨김
    for child in get_children():
        if child is ColorRect:
            (child as ColorRect).visible = false
    var spr := Sprite2D.new()
    spr.texture = load(tex_path)
    spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    spr.scale = Vector2(1.5, 1.5)
    spr.position = Vector2(0, -10)
    add_child(spr)
    # 위아래 부유 연출
    var tw := create_tween().set_loops()
    tw.tween_property(spr, "position:y", -16.0, 0.9).set_trans(Tween.TRANS_SINE)
    tw.tween_property(spr, "position:y", -10.0, 0.9).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node) -> void:
    if _used:
        return
    if not body.is_in_group("player"):
        return
    if requires_quest_active != "" and not QuestManager.is_active(requires_quest_active):
        return
    _used = true
    if item_id != "" and count > 0:
        # 'gold' 속성이 정의된 아이템은 인벤토리에 넣지 않고 PlayerStats.add_gold 로 환산.
        var def := Inventory.get_def(item_id)
        var gold_per := int(def.get("gold", 0))
        if gold_per > 0:
            PlayerStats.add_gold(gold_per * count)
            var glabel := pickup_label if pickup_label != "" else ("+%d 엽전" % (gold_per * count))
            FloatingNumber.spawn(get_tree().current_scene, global_position, glabel, Color(1.0, 0.85, 0.35))
        else:
            Inventory.add(item_id, count)
            var label := pickup_label if pickup_label != "" else ("+%d %s" % [count, item_id])
            FloatingNumber.spawn(get_tree().current_scene, global_position, label, Color(1, 0.85, 0.55))
        Audio.play_sfx(Sfx.PICKUP)
    if quest_id != "":
        if quest_stage != "":
            # set_stage 는 active 일 때만 동작 — 아직 active 아니면 start 먼저
            if not QuestManager.is_active(quest_id):
                QuestManager.start_quest(quest_id)
            QuestManager.set_stage(quest_id, quest_stage)
        else:
            QuestManager.start_quest(quest_id)
    if flag_key != "":
        Flags.set_flag(flag_key, flag_value)
    if destroy_on_pickup:
        queue_free()
