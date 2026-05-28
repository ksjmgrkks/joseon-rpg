extends Area2D
class_name Hitbox
##
## 공격 판정 영역. 짧게 활성화 → Hurtbox와 겹치면 데미지 발생.
## monitorable=true 면 다른 Area2D(Hurtbox)가 area_entered로 이 노드를 감지함.
##

@export var damage: float = 10.0
@export var knockback: float = 200.0  # px/s, 양수면 hitbox→target 방향으로 밀려남


func _ready() -> void:
    monitoring = false
    monitorable = false


## 짧은 시간 동안 활성화. 끝나면 비활성으로 복귀.
func activate(duration: float = 0.15) -> void:
    monitoring = true
    monitorable = true
    await get_tree().create_timer(duration).timeout
    monitoring = false
    monitorable = false
