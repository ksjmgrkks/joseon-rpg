extends AIState
##
## Chase — 플레이어 쪽으로 이동. 시야 잃거나 너무 멀면 Idle.
##

@export var chase_speed: float = 140.0
@export var lose_distance: float = 280.0

const GRAVITY: float = 980.0


func process_physics(actor: Node, delta: float) -> String:
    if not (actor is CharacterBody2D):
        return "Idle"
    if not actor.has_method("get_player"):
        return "Idle"
    var player = actor.get_player()
    if player == null or not (player is Node2D):
        return "Idle"

    var body := actor as CharacterBody2D
    var dir := signf((player as Node2D).global_position.x - body.global_position.x)
    body.velocity.x = chase_speed * dir
    if not body.is_on_floor():
        body.velocity.y += GRAVITY * delta
    body.move_and_slide()

    var distance := body.global_position.distance_to((player as Node2D).global_position)
    if distance > lose_distance:
        return "Idle"
    return ""
