extends CharacterBody2D
##
## 주인공 횡스크롤 이동 — Phase 1 골격.
## 시각 스프라이트는 아직 placeholder. AnimationPlayer 연결은 주인공 idle.png 확정 후.
## 좌우 이동·점프·중력만 — 전투/콤보는 별도 스크립트로 분리 예정.
##

const SPEED: float = 220.0           # px/s
const JUMP_VELOCITY: float = -380.0  # px/s (위쪽이 음수)
const GRAVITY: float = 980.0         # px/s²

@onready var sprite: Sprite2D = $Sprite2D


func _physics_process(delta: float) -> void:
    # 중력
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    # 점프 (지면일 때만)
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # 좌우 이동 + 스프라이트 방향
    var direction := Input.get_axis("move_left", "move_right")
    if absf(direction) > 0.0:
        velocity.x = direction * SPEED
        if sprite:
            sprite.flip_h = direction < 0.0
    else:
        velocity.x = move_toward(velocity.x, 0.0, SPEED)

    move_and_slide()
