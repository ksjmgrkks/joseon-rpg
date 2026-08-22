extends Area2D
class_name AutoDialogue
##
## 플레이어가 밟으면 자동으로 대화를 시작하는 트리거 — 보스 일갈, 연출 대사용.
## once_flag 가 채워져 있으면 그 플래그가 없을 때 한 번만 발동하고 플래그를 세운다.
##

@export_file("*.json") var dialogue_path: String = ""
@export var once_flag: String = ""
## 이 진행 플래그가 있어야 발동. 보스 처치 뒤 출구 앞 짧은 해원 대사 등에 쓴다.
@export var requires_flag: String = ""


func _ready() -> void:
    monitoring = true
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
    if not body.is_in_group("player"):
        return
    if dialogue_path.is_empty() or Dialogue.is_active():
        return
    if requires_flag != "" and not Flags.has_flag(requires_flag):
        return
    if once_flag != "" and Flags.has_flag(once_flag):
        return
    if once_flag != "":
        Flags.set_flag(once_flag, true)
    Dialogue.start(dialogue_path)
