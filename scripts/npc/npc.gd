extends Area2D
##
## NPC 골격 — 플레이어가 가까이 와서 interact 누르면 대화 시작.
## 시각 스프라이트는 placeholder. 표시 텍스트(이름 패널·인터랙트 힌트)는 추후.
##

@export_file("*.json") var dialogue_path: String = "res://assets/dialogue/sample_villager.json"

var _player_in_range: bool = false


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
    if not _player_in_range:
        return
    if Dialogue.is_active():
        return
    if Input.is_action_just_pressed("interact"):
        Dialogue.start(dialogue_path)


func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        _player_in_range = true


func _on_body_exited(body: Node) -> void:
    if body.is_in_group("player"):
        _player_in_range = false
