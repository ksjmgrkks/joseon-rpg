extends Area2D
class_name Hitbox
##
## 공격 판정 영역. 짧게 활성화 → Hurtbox와 겹치면 데미지 발생.
## monitorable=true 면 다른 Area2D(Hurtbox)가 area_entered로 이 노드를 감지함.
##
## 활성/비활성 게이트는 collision_layer(0↔1)로 한다.
## monitoring/monitorable 토글 게이트는 Godot 4.4+ 브로드페이즈에서
## 겹친 채 다시 켜면 페어가 재생성되지 않아(정지 상태 공격 헛스윙) 사용하지 않는다.
##

@export var damage: float = 10.0
@export var knockback: float = 200.0  # px/s, 양수면 hitbox→target 방향으로 밀려남


func _ready() -> void:
    monitoring = false      # hitbox 는 스스로 감시하지 않는다 — Hurtbox 쪽이 감시
    monitorable = true
    collision_layer = 0


## 짧은 시간 동안 활성화. 끝나면 비활성으로 복귀.
func activate(duration: float = 0.15) -> void:
    collision_layer = 1
    await get_tree().create_timer(duration).timeout
    collision_layer = 0
