extends Area2D
class_name QuestTrigger
##
## QuestTrigger — 플레이어가 지나가는 순간 퀘스트 단계/플래그를 한 번 갱신.
## (수동 정의 가능: 같은 매개의 반복 트리거가 필요하면 _used 를 비우면 됨.)
##
## - quest_id + quest_stage 둘 다 있으면 set_stage 실행(필요시 start 자동).
## - only_if_quest_active 가 채워져 있으면 그 퀘스트가 활성일 때만 동작.
## - only_if_quest_stage = "qid:stage" 면 정확히 그 단계일 때만 동작.
##

@export var quest_id: String = ""
@export var quest_stage: String = ""
@export var only_if_quest_active: String = ""
@export var only_if_quest_stage: String = ""
@export var flag_key: String = ""
@export var flag_value: bool = true
@export var one_shot: bool = true

var _used: bool = false


func _ready() -> void:
    monitoring = true
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
    if _used and one_shot:
        return
    if not body.is_in_group("player"):
        return
    if only_if_quest_active != "" and not QuestManager.is_active(only_if_quest_active):
        return
    if only_if_quest_stage != "":
        var parts := only_if_quest_stage.split(":")
        if parts.size() != 2 or not QuestManager.is_stage(parts[0], parts[1]):
            return
    _used = true
    if quest_id != "" and quest_stage != "":
        if not QuestManager.is_active(quest_id):
            QuestManager.start_quest(quest_id)
        QuestManager.set_stage(quest_id, quest_stage)
    elif quest_id != "":
        QuestManager.start_quest(quest_id)
    if flag_key != "":
        Flags.set_flag(flag_key, flag_value)
