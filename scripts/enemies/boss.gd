extends CharacterBody2D
class_name Boss
##
## 보스 적 — 텔레그래프 → 돌진 공격 → 회복 패턴.
##
## 상태:
##   Idle: 플레이어 위치 추적, ENGAGE_DIST 안에 들어오면 Telegraph 진입.
##   Telegraph: 멈춰서 깜빡이는 경고 표시 (telegraph_seconds 초).
##   Attack: 플레이어 방향으로 짧게 돌진 + 정면 Hitbox 활성. attack_seconds 후 종료.
##   Recover: 잠깐 멈춤(recover_seconds). 그 후 다시 Idle.
##
## Boss 는 HP/XP 보상이 크고 사망 시 옵션으로 보상 아이템(reward_item_id × qty)을 인벤토리에 지급.
##

@export var display_name: String = "호환 두령"
@export var body_color: Color = Color(0.85, 0.55, 0.20, 1)
@export var engage_distance: float = 320.0
@export var telegraph_seconds: float = 0.85
@export var attack_seconds: float = 0.38
@export var recover_seconds: float = 1.6
@export var dash_speed: float = 280.0
@export var attack_damage: float = 18.0
@export var attack_knockback: float = 320.0
@export var xp_reward: int = 80
@export var reward_item_id: String = "rice_bun"
@export var reward_item_qty: int = 5

# 사망 시 진행될 메인 퀘스트 단계 (비워두면 무시).
@export var quest_id_on_death: String = ""
@export var quest_stage_on_death: String = ""
# 사망 시 set_flag 한 번(예: "tiger_lord_defeated").
@export var flag_on_death: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $HealthComponent
@onready var attack_hitbox: Hitbox = $AttackHitbox

const GRAVITY: float = 980.0

enum State { IDLE, TELEGRAPH, ATTACK, RECOVER, DEAD }
var _state: int = State.IDLE
var _state_timer: float = 0.0
var _facing_right: bool = true
var _attacking_blink: bool = false
# 페이즈 2 — HP 50% 이하에서 한 번만 진입. 패턴 가속 + 색감 변화.
var _phase: int = 1


func _ready() -> void:
    add_to_group("enemy")
    add_to_group("boss")
    if sprite:
        sprite.modulate = body_color
    if attack_hitbox:
        attack_hitbox.monitoring = false
        attack_hitbox.monitorable = false
    hurtbox.hurt.connect(_on_hurt)
    health.hp_changed.connect(_on_hp_changed)
    health.died.connect(_on_died)
    # 보스는 폭이 더 넓게 잘 보이도록 y_offset 만 살짝 위. 폭은 EnemyHpBar 기본값 유지.
    var bar := EnemyHpBar.attach_to(self, health)
    bar.position.y = -44


func _physics_process(delta: float) -> void:
    # 중력
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    _state_timer = maxf(0.0, _state_timer - delta)
    match _state:
        State.IDLE:
            _tick_idle(delta)
        State.TELEGRAPH:
            _tick_telegraph(delta)
        State.ATTACK:
            _tick_attack(delta)
        State.RECOVER:
            _tick_recover(delta)
        State.DEAD:
            velocity.x = move_toward(velocity.x, 0.0, 400.0)
    move_and_slide()


func _tick_idle(_delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 400.0)
    var p := _player()
    if p == null:
        return
    var d := global_position.distance_to(p.global_position)
    if d <= engage_distance:
        _facing_right = p.global_position.x >= global_position.x
        _enter_telegraph()


func _tick_telegraph(_delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 400.0)
    # 텔레그래프 깜빡임 — 시각 강조
    if sprite:
        var t := int(Time.get_ticks_msec() / 100) % 2
        sprite.modulate = body_color.lightened(0.4) if t == 0 else body_color
    if _state_timer <= 0.0:
        _enter_attack()


func _tick_attack(_delta: float) -> void:
    var dir := 1.0 if _facing_right else -1.0
    velocity.x = dash_speed * dir
    if sprite:
        sprite.modulate = body_color.lightened(0.6)
        sprite.flip_h = not _facing_right
    if _state_timer <= 0.0:
        _enter_recover()


func _tick_recover(_delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 400.0)
    if sprite:
        sprite.modulate = body_color
    if _state_timer <= 0.0:
        _state = State.IDLE


func _enter_telegraph() -> void:
    _state = State.TELEGRAPH
    _state_timer = telegraph_seconds * _phase_mult_telegraph()


func _enter_attack() -> void:
    _state = State.ATTACK
    var dur := attack_seconds * _phase_mult_attack()
    _state_timer = dur
    if attack_hitbox:
        attack_hitbox.position.x = 28.0 if _facing_right else -28.0
        attack_hitbox.damage = attack_damage * (1.25 if _phase >= 2 else 1.0)
        attack_hitbox.knockback = attack_knockback
        attack_hitbox.activate(dur)
    Audio.play_sfx(Sfx.ATTACK)


func _enter_recover() -> void:
    _state = State.RECOVER
    _state_timer = recover_seconds * _phase_mult_recover()


# 페이즈 배율 (1=원본, >=2 면 더 빠르고 회복 짧음)
func _phase_mult_telegraph() -> float:
    return 0.70 if _phase >= 2 else 1.0


func _phase_mult_attack() -> float:
    return 1.0    # 공격 자체는 길이 유지, 데미지만 증가


func _phase_mult_recover() -> float:
    return 0.55 if _phase >= 2 else 1.0


func _on_hp_changed(hp: float, max_hp: float) -> void:
    if _phase == 1 and hp > 0.0 and hp <= max_hp * 0.5:
        _enter_phase2()


func _enter_phase2() -> void:
    _phase = 2
    print("[%s] 페이즈 2 진입 — 패턴 가속" % display_name)
    if sprite:
        # 핏빛 톤으로 강조
        sprite.modulate = body_color.lerp(Color(1, 0.25, 0.20, 1), 0.45)
    ScreenFx.shake(14.0, 0.32)


func _player() -> Node2D:
    var n := get_tree().get_first_node_in_group("player")
    return n as Node2D


func _on_hurt(damage: float, knockback: float, _attacker: Node) -> void:
    if _state == State.DEAD:
        return
    velocity.x += knockback * 0.3   # 보스는 잘 안 밀림
    Audio.play_sfx(Sfx.HIT)
    FloatingNumber.spawn(get_tree().current_scene, global_position, "-%d" % int(damage), Color(1, 0.55, 0.50))
    if sprite and not _attacking_blink:
        _attacking_blink = true
        var prev := sprite.modulate
        sprite.modulate = Color(1, 0.5, 0.5, 1)
        await get_tree().create_timer(0.08).timeout
        if is_instance_valid(sprite):
            sprite.modulate = prev
        _attacking_blink = false


func _on_died() -> void:
    _state = State.DEAD
    print("[%s] died" % display_name)
    Audio.play_sfx(Sfx.DIE)
    if xp_reward > 0:
        PlayerStats.gain_xp(xp_reward)
        FloatingNumber.spawn(get_tree().current_scene, global_position, "+%d XP" % xp_reward, Color(1, 0.95, 0.6))
    if reward_item_id != "" and reward_item_qty > 0 and Inventory:
        Inventory.add(reward_item_id, reward_item_qty)
        FloatingNumber.spawn(get_tree().current_scene, global_position + Vector2(0, -32), "+%d %s" % [reward_item_qty, reward_item_id], Color(1, 0.85, 0.55))
    if quest_id_on_death != "" and quest_stage_on_death != "" and QuestManager.is_active(quest_id_on_death):
        QuestManager.set_stage(quest_id_on_death, quest_stage_on_death)
    if flag_on_death != "":
        Flags.set_flag(flag_on_death, true)
    # 즉시 제거하지 않고 잠깐 두면 사라지는 페이드를 줄 수 있지만 간단히 비활성화
    if attack_hitbox:
        attack_hitbox.monitoring = false
        attack_hitbox.monitorable = false
    if hurtbox:
        hurtbox.monitoring = false
    await get_tree().create_timer(0.45).timeout
    queue_free()
