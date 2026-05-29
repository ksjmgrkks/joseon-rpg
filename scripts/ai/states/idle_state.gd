extends AIState
##
## Idle — 잠시 멈춤. 시야 안에 플레이어면 Chase, 시간 지나면 Patrol.
##

@export var idle_duration: float = 1.5

const GRAVITY: float = 980.0

var _elapsed: float = 0.0


func enter(_actor: Node) -> void:
    _elapsed = 0.0


func process_physics(actor: Node, delta: float) -> String:
    if actor is CharacterBody2D:
        var body := actor as CharacterBody2D
        body.velocity.x = 0.0
        if not body.is_on_floor():
            body.velocity.y += GRAVITY * delta
        body.move_and_slide()

    _elapsed += delta
    if actor.has_method("can_see_player") and actor.can_see_player():
        return "Chase"
    if _elapsed >= idle_duration:
        return "Patrol"
    return ""
