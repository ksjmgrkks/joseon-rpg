extends CharacterBody2D
##
## 주인공 횡스크롤 이동 + 공격(콤보/차지) — Phase 1~B 확장.
## 시각 스프라이트는 placeholder. AnimationPlayer 연결은 주인공 idle.png 확정 후.
##
## 공격 흐름:
##   - tap attack: 콤보 1→2→3타. 마지막 타는 데미지·넉백·차지 인디케이터 증가.
##     COMBO_WINDOW(초) 안에 다음 입력이 안 오면 콤보 리셋. 콤보 단계마다 ScreenFx.shake.
##   - hold attack >= CHARGE_THRESHOLD 초 → 차지 상태. 놓으면 강타(데미지 2x, 넉백 1.5x).
##     차지 중에는 이동 속도 감소·sprite 약간 밝아짐.
##

const SPEED: float = 220.0           # px/s
const SPEED_CHARGING: float = 80.0   # 차지 중 이동 속도
const JUMP_VELOCITY: float = -380.0  # px/s (위쪽이 음수)
const GRAVITY: float = 980.0         # px/s²

# 공격 파라미터
const ATTACK_DURATION: float = 0.18      # hitbox 활성 시간 (콤보 1~2타)
const ATTACK_DURATION_FINISH: float = 0.24
const ATTACK_RECOVER: float = 0.18       # 한 타 끝나고 다음 타까지 최소 간격
const COMBO_WINDOW: float = 0.45         # 콤보 입력 허용 윈도우
const CHARGE_THRESHOLD: float = 0.45     # 이 시간보다 길게 누르고 있으면 차지로 인식
const CHARGE_FULL: float = 0.95          # 완전 차지(시각 강조용)

# 회피 구르기
const DODGE_DURATION: float = 0.28       # 무적·dash 지속
const DODGE_SPEED: float = 360.0
const DODGE_COOLDOWN: float = 0.6

@onready var sprite: AnimatedSprite2D = $Visual
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $HealthComponent

var _facing_right: bool = true
# 공격 상태
var _attacking: bool = false             # 한 타가 끝날 때까지 true
var _combo_step: int = 0                 # 0=무, 1/2/3=콤보 단계
var _combo_timer: float = 0.0            # 콤보 유지 카운트다운
var _hold_time: float = 0.0              # attack 키 누른 누적 시간(차지용)
var _charge_started: bool = false        # 이번 누름이 차지로 인식됐는가
var _base_modulate: Color = Color.WHITE
# 회피 상태
var _dodging: bool = false
var _dodge_timer: float = 0.0
var _dodge_cd: float = 0.0


func _ready() -> void:
    if health:
        health.hp_changed.connect(_on_hp_changed)
        health.died.connect(_on_died)
    if sprite:
        _base_modulate = sprite.modulate
    if attack_hitbox:
        # 내가 친 게 적의 Hurtbox에 닿으면 화면 fx 발사
        attack_hitbox.area_entered.connect(_on_hitbox_landed)


func _physics_process(delta: float) -> void:
    # 중력
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    # 회피 진행/쿨다운 카운트다운
    if _dodge_timer > 0.0:
        _dodge_timer = maxf(0.0, _dodge_timer - delta)
        if _dodge_timer <= 0.0:
            _end_dodge()
    if _dodge_cd > 0.0:
        _dodge_cd = maxf(0.0, _dodge_cd - delta)

    # 회피 시작
    if Input.is_action_just_pressed("dodge") and not _dodging and not _attacking and _dodge_cd <= 0.0:
        _start_dodge()

    # 회피 중에는 이동/공격/콤보 윈도우 무시하고 dash 가속 유지
    if _dodging:
        velocity.x = (DODGE_SPEED if _facing_right else -DODGE_SPEED)
        move_and_slide()
        return

    # 점프 (지면일 때만)
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # 콤보 윈도우 카운트다운
    if _combo_timer > 0.0:
        _combo_timer = maxf(0.0, _combo_timer - delta)
        if _combo_timer <= 0.0:
            _combo_step = 0

    # 차지 진행 추적: attack 키를 누르고 있는 동안 _hold_time 누적
    var attack_held := Input.is_action_pressed("attack")
    if attack_held:
        _hold_time += delta
    if not attack_held:
        # 키를 떼는 순간(혹은 이미 떼져 있는 상태): 차지 상태였다면 차지 공격 발사
        if _charge_started and not _attacking:
            _do_charged_attack()
        _hold_time = 0.0
        _charge_started = false

    # 차지 인디케이터(시각 강조) — 일정 시간 이상 누르고 있으면 sprite 밝아짐
    if sprite:
        if _hold_time >= CHARGE_FULL:
            sprite.modulate = _base_modulate.lightened(0.35)
        elif _hold_time >= CHARGE_THRESHOLD:
            sprite.modulate = _base_modulate.lightened(0.15)
        else:
            sprite.modulate = _base_modulate

    # 좌우 이동 + 방향 갱신 (차지 중엔 느림)
    var move_speed := SPEED_CHARGING if (_hold_time >= CHARGE_THRESHOLD) else SPEED
    var direction := Input.get_axis("move_left", "move_right")
    if absf(direction) > 0.0:
        velocity.x = direction * move_speed
        _facing_right = direction > 0.0
        if sprite:
            sprite.flip_h = not _facing_right
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed)

    # 일반/콤보 공격 — '눌리는 순간'만 발동. 단, 이미 차지 임계점을 넘었으면 일반 발동 막음.
    if Input.is_action_just_pressed("attack"):
        # 임계점 도달 시점에만 차지로 간주(릴리스 때 강타). 일반 콤보는 즉시 발동.
        _do_combo_attack()
    # 일반 콤보를 즉시 쳤더라도 그 이후로 계속 누르고 있으면 다음 공격은 차지로 동작.
    if attack_held and _hold_time >= CHARGE_THRESHOLD:
        _charge_started = true

    move_and_slide()


# 일반/콤보 공격(즉시 발동)
func _do_combo_attack() -> void:
    if attack_hitbox == null or _attacking:
        return
    _combo_step = clampi(_combo_step + 1, 1, 3)
    _combo_timer = COMBO_WINDOW
    _attacking = true

    var stored_damage: float = attack_hitbox.damage
    var stored_knock: float = attack_hitbox.knockback
    # 무기 장착돼 있으면 그 데미지를 베이스로 사용.
    var base_damage: float = Equipment.current_damage(stored_damage)
    var base_knock: float = stored_knock
    # 콤보 단계별 보너스. 3타에서 데미지·넉백·shake 증가.
    var damage_mult := 1.0
    var knock_mult := 1.0
    var shake_strength := 4.0
    var duration := ATTACK_DURATION
    if _combo_step == 2:
        damage_mult = 1.10
        shake_strength = 5.0
    elif _combo_step == 3:
        damage_mult = 1.6
        knock_mult = 1.6
        shake_strength = 8.0
        duration = ATTACK_DURATION_FINISH
    attack_hitbox.damage = base_damage * damage_mult
    attack_hitbox.knockback = base_knock * knock_mult
    attack_hitbox.position.x = 16.0 if _facing_right else -16.0
    Audio.play_sfx(Sfx.ATTACK)
    # 공격 휘두를 때마다 살짝 진동(피드백). 명중 시 추가 진동은 _on_hitbox_landed에서.
    ScreenFx.shake(shake_strength * 0.5, 0.08)
    await attack_hitbox.activate(duration)
    # 원래 베이스(씬에 박힌 기본값)로 복귀
    attack_hitbox.damage = stored_damage
    attack_hitbox.knockback = stored_knock
    await get_tree().create_timer(ATTACK_RECOVER).timeout
    _attacking = false
    # 3타까지 갔으면 콤보 즉시 리셋(다음 입력은 1타부터)
    if _combo_step >= 3:
        _combo_step = 0
        _combo_timer = 0.0


# 차지 강타(눌렀다 떼는 순간 발동)
func _do_charged_attack() -> void:
    if attack_hitbox == null or _attacking:
        return
    _attacking = true
    _combo_step = 0
    _combo_timer = 0.0
    var stored_damage: float = attack_hitbox.damage
    var stored_knock: float = attack_hitbox.knockback
    var base_damage: float = Equipment.current_damage(stored_damage)
    attack_hitbox.damage = base_damage * 2.0
    attack_hitbox.knockback = stored_knock * 1.6
    attack_hitbox.position.x = 16.0 if _facing_right else -16.0
    Audio.play_sfx(Sfx.ATTACK)
    ScreenFx.shake(10.0, 0.18)
    await attack_hitbox.activate(ATTACK_DURATION_FINISH)
    attack_hitbox.damage = stored_damage
    attack_hitbox.knockback = stored_knock
    await get_tree().create_timer(ATTACK_RECOVER).timeout
    _attacking = false


# 내 hitbox가 적 hurtbox 에 닿았을 때(=공격 명중) 호출
func _on_hitbox_landed(area: Area2D) -> void:
    if not (area is Hurtbox):
        return
    # 적 부모를 침. (자기 자신은 Hurtbox._on_area_entered 에서 이미 걸러짐.)
    var landed_strength := 4.0 + 1.5 * float(_combo_step)
    ScreenFx.shake(landed_strength, 0.16)
    ScreenFx.hit_stop(0.04 if _combo_step < 3 else 0.08)


# 회피 시작/종료 — Hurtbox 비활성으로 무적, sprite 반투명
func _start_dodge() -> void:
    _dodging = true
    _dodge_timer = DODGE_DURATION
    if hurtbox:
        hurtbox.monitoring = false
    if sprite:
        var c := _base_modulate
        c.a = 0.55
        sprite.modulate = c
    ScreenFx.shake(2.0, 0.08)


func _end_dodge() -> void:
    _dodging = false
    _dodge_cd = DODGE_COOLDOWN
    if hurtbox:
        hurtbox.monitoring = true
    if sprite:
        var c := _base_modulate
        c.a = 1.0
        sprite.modulate = c


func _on_hp_changed(hp: float, max_hp: float) -> void:
    print("[Player] HP %.0f / %.0f" % [hp, max_hp])


func _on_died() -> void:
    print("[Player] died")
    Audio.play_sfx(Sfx.DIE)
    velocity = Vector2.ZERO
    GameOverScreen.show_screen()
