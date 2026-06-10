extends CharacterBody2D
##
## 더미 적 — Phase 1 전투 테스트용. 가만히 서있고, 피격되면 HP 깎이다 0에서 사라짐.
## 콘솔 로그로 피격/사망 확인. 시각 표현(피격 반짝임·HP 바)은 추후.
##

const GRAVITY: float = 980.0
const KNOCKBACK_DECAY: float = 1200.0  # px/s² 마찰

@export var xp_reward: int = 8

@onready var sprite: Sprite2D = $Sprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox

var _knockback_vel: float = 0.0


func _ready() -> void:
    add_to_group("enemy")
    hurtbox.hurt.connect(_on_hurt)
    health.hp_changed.connect(_on_hp_changed)
    health.died.connect(_on_died)
    EnemyHpBar.attach_to(self, health)


func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    # 넉백 감속
    if absf(_knockback_vel) > 0.0:
        var sign_v := signf(_knockback_vel)
        _knockback_vel = move_toward(_knockback_vel, 0.0, KNOCKBACK_DECAY * delta)
        velocity.x = _knockback_vel
    else:
        velocity.x = 0.0
    move_and_slide()


func _on_hurt(damage: float, knockback: float, _attacker: Node) -> void:
    _knockback_vel = knockback
    velocity.y = -160.0
    Audio.play_sfx(Sfx.HIT)
    FloatingNumber.spawn(get_tree().current_scene, global_position, "-%d" % int(damage), Color(1, 0.6, 0.55))
    if sprite:
        sprite.modulate = Color(1, 0.5, 0.5, 1)
        await get_tree().create_timer(0.08).timeout
        if is_instance_valid(sprite):
            sprite.modulate = Color(0.55, 0.55, 0.65, 1)


func _on_hp_changed(hp: float, max_hp: float) -> void:
    print("[Dummy] HP %.0f / %.0f" % [hp, max_hp])


func _on_died() -> void:
    print("[Dummy] died")
    Audio.play_sfx(Sfx.DIE)
    if xp_reward > 0:
        PlayerStats.gain_xp(xp_reward)
        FloatingNumber.spawn(get_tree().current_scene, global_position, "+%d XP" % xp_reward, Color(1, 0.95, 0.6))
    queue_free()
