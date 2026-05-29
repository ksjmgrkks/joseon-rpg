extends AIState
##
## Patrol — 시작 위치 기준 좌우 왕복. 시야 안에 플레이어면 Chase. 일정 시간 지나면 Idle.
##

@export var patrol_speed: float = 60.0
@export var patrol_range: float = 80.0
@export var patrol_duration: float = 4.0

const GRAVITY: float = 980.0

var _origin_x: float = 0.0
var _dir: float = 1.0
var _elapsed: float = 0.0


func enter(actor: Node) -> void:
    if actor is Node2D:
        _origin_x = (actor as Node2D).global_position.x
    _dir = 1.0 if randf() > 0.5 else -1.0
    _elapsed = 0.0


func process_physics(actor: Node, delta: float) -> String:
    if actor is CharacterBody2D:
        var body := actor as CharacterBody2D
        body.velocity.x = patrol_speed * _dir
        if not body.is_on_floor():
            body.velocity.y += GRAVITY * delta
        body.move_and_slide()
        # 범위 밖이면 방향 반전
        var offset := body.global_position.x - _origin_x
        if absf(offset) > patrol_range:
            _dir = -signf(offset)

    _elapsed += delta
    if actor.has_method("can_see_player") and actor.can_see_player():
        return "Chase"
    if _elapsed >= patrol_duration:
        return "Idle"
    return ""
