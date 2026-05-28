extends CharacterBody2D
##
## 주인공 횡스크롤 이동 + 기본 공격 — Phase 1 골격.
## 시각 스프라이트는 placeholder. AnimationPlayer 연결은 주인공 idle.png 확정 후.
##

const SPEED: float = 220.0           # px/s
const JUMP_VELOCITY: float = -380.0  # px/s (위쪽이 음수)
const GRAVITY: float = 980.0         # px/s²
const ATTACK_DURATION: float = 0.18  # 공격 hitbox 활성 시간(초)

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var health: HealthComponent = $HealthComponent

var _facing_right: bool = true


func _ready() -> void:
    if health:
        health.hp_changed.connect(_on_hp_changed)
        health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
    # 중력
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    # 점프 (지면일 때만)
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # 좌우 이동 + 방향 갱신
    var direction := Input.get_axis("move_left", "move_right")
    if absf(direction) > 0.0:
        velocity.x = direction * SPEED
        _facing_right = direction > 0.0
        if sprite:
            sprite.flip_h = not _facing_right
    else:
        velocity.x = move_toward(velocity.x, 0.0, SPEED)

    # 공격
    if Input.is_action_just_pressed("attack"):
        _do_attack()

    move_and_slide()


func _do_attack() -> void:
    if attack_hitbox == null:
        return
    attack_hitbox.position.x = 16.0 if _facing_right else -16.0
    attack_hitbox.activate(ATTACK_DURATION)


func _on_hp_changed(hp: float, max_hp: float) -> void:
    print("[Player] HP %.0f / %.0f" % [hp, max_hp])


func _on_died() -> void:
    print("[Player] died — 위치 리셋(Phase 1 임시)")
    position = Vector2(200, 400)
    velocity = Vector2.ZERO
    health.heal(health.max_hp)
