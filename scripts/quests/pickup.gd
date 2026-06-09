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

var _used: bool = false


func _ready() -> void:
    monitoring = true
    body_entered.connect(_on_body_entered)


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
