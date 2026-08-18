extends CharacterBody2D
##
## 더미 적 — Phase 1 전투 테스트용. 가만히 서있고, 피격되면 HP 깎이다 0에서 사라짐.
## 콘솔 로그로 피격/사망 확인. 시각 표현(피격 반짝임·HP 바)은 추후.
##

const GRAVITY: float = 980.0
const KNOCKBACK_DECAY: float = 800.0   # px/s² 마찰 (낮을수록 멀리 밀림)
const KNOCK_RECEIVE: float = 1.2       # 받는 넉백 배수 — 타격감 (2026-08-18: 1.6→1.2, 사용자 피드백)

@export var xp_reward: int = 8

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox

var _knockback_vel: float = 0.0
var _spr_base_scale: Vector2 = Vector2.ZERO   # 피격 squash 복귀 기준


func _ready() -> void:
    add_to_group("enemy")
    add_to_group("enemy_gate")
    if sprite:
        _spr_base_scale = sprite.scale
    # 적 몸은 월드(bit3=4)에만 부딪히고 플레이어·다른 적은 통과 (메탈슬러그식).
    collision_layer = 2
    collision_mask = 4
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
    _knockback_vel = knockback * KNOCK_RECEIVE
    velocity.y = -130.0
    # 피격음은 공격자(플레이어) 측 _on_hitbox_landed 에서 1회 재생.
    FloatingNumber.spawn(get_tree().current_scene, global_position, "-%d" % int(damage), Color(1, 0.6, 0.55))
    SkillFx.hit_flash(sprite, Color.WHITE, 0.2)
    _hit_jolt(signf(knockback))


# 피격 움찔 — 납작 눌렸다 되돌아오고 밀리는 쪽으로 휘청(patroller 와 동일 손맛).
func _hit_jolt(dir: float = 0.0) -> void:
    if sprite == null or not is_instance_valid(sprite):
        return
    if _spr_base_scale == Vector2.ZERO:
        _spr_base_scale = sprite.scale
    sprite.scale = _spr_base_scale * Vector2(1.26, 0.76)
    var tw := sprite.create_tween()
    tw.tween_property(sprite, "scale", _spr_base_scale, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    if dir != 0.0:
        sprite.rotation = 0.22 * dir
        tw.parallel().tween_property(sprite, "rotation", 0.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_hp_changed(hp: float, max_hp: float) -> void:
    print("[Dummy] HP %.0f / %.0f" % [hp, max_hp])


func _on_died() -> void:
    print("[Dummy] died")
    Audio.play_sfx(Sfx.DIE)
    SkillFx.soul_ascend(global_position + Vector2(0, -10))   # 진혼: 혼을 달래 천도(성불)
    if xp_reward > 0:
        PlayerStats.gain_xp(xp_reward)
    var pts := xp_reward * 10
    ScoreManager.add_score(pts)
    FloatingNumber.spawn(get_tree().current_scene, global_position, "+%d" % pts, Color(1, 0.95, 0.6))
    queue_free()
