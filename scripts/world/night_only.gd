extends Node2D
class_name NightOnly
##
## TimeManager.is_night 가 true 일 때만 보이고 동작하는 노드. 떠돌이 상인 NPC 같은 용도.
##
## - phase_changed 시그널을 듣고 자신과 자식 노드의 visible/process 토글.
## - Area2D 자식(NPC interaction) 도 같이 비활성화돼 밤에만 상호작용 가능.
## - 게임 시작 시점의 is_night 상태로 초기화.
##

func _ready() -> void:
    if TimeManager:
        TimeManager.phase_changed.connect(_on_phase_changed)
        _apply(TimeManager.is_night())
    else:
        _apply(false)


func _on_phase_changed(is_night: bool) -> void:
    _apply(is_night)


func _apply(is_night: bool) -> void:
    visible = is_night
    # 자식 콜리전(Area2D) 들도 함께 비활성화
    for child in get_children():
        if child is Area2D:
            (child as Area2D).monitoring = is_night
            (child as Area2D).monitorable = is_night
