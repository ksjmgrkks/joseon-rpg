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
const MAX_FALL_SPEED: float = 900.0  # 종단 낙하 속도 — 얇은 지면 터널링 방지
# 낙사 안전망: 이 y 보다 아래로 떨어지면 마지막으로 땅을 밟았던 지점으로 복귀.
const FALL_LIMIT_Y: float = 1100.0

# ── 조작 손맛(game feel) 튜닝 ──
const ACCEL: float = 2400.0            # 지상 가속(px/s²) — 즉시 최고속 대신 짧은 발구름
const AIR_ACCEL: float = 1500.0        # 공중 가속(지상보다 둔하게 → 무게감)
const FRICTION: float = 2800.0         # 지상 감속(마찰) — 멈출 때 미끄러짐 최소
const AIR_FRICTION: float = 700.0      # 공중 감속(관성 더 살림)
const COYOTE_TIME: float = 0.10        # 발판 떠난 뒤에도 점프 허용 시간
const JUMP_BUFFER_TIME: float = 0.12   # 착지 직전 누른 점프 입력 기억 시간
const JUMP_CUT_MULT: float = 0.45      # 상승 중 점프 떼면 상승 속도 깎기(짧은 점프)
const FALL_GRAVITY_MULT: float = 1.45  # 하강 시 중력 가중 — 붕 뜨지 않고 떨어지는 손맛
const LOW_JUMP_GRAVITY_MULT: float = 1.9   # 상승 중 점프 안 누르면 더 빨리 정점(칼 같은 단타 점프)
const APEX_THRESHOLD: float = 40.0     # 점프 정점 부근(|vy|<이값) 판정 속도
const APEX_BONUS_ACCEL: float = 1.2    # 정점 부근 가로 가속 보너스(공중 미세 제어감)
const TURN_BOOST: float = 1.0          # 반대 방향 전환 시 추가 가속(= +FRICTION 만큼)
const LAND_SHAKE_MIN_FALL: float = 360.0   # 이 낙하속도 이상으로 착지하면 가벼운 흔들림
const LAND_SHAKE: float = 2.0

# 공격 파라미터
const ATTACK_DURATION: float = 0.18      # hitbox 활성 시간 (콤보 1~2타)
const ATTACK_DURATION_FINISH: float = 0.24
const ATTACK_RECOVER: float = 0.18       # 한 타 끝나고 다음 타까지 최소 간격
const COMBO_WINDOW: float = 1.0          # 콤보 입력 허용 윈도우 — 1초 안에 다시 치면 콤보 이어짐(관대)
const CHARGE_THRESHOLD: float = 0.45     # 이 시간보다 길게 누르고 있으면 차지로 인식
const CHARGE_FULL: float = 0.95          # 완전 차지(시각 강조용)

# 회피 구르기
const DODGE_DURATION: float = 0.28       # 무적·dash 지속
const DODGE_SPEED: float = 360.0
const DODGE_COOLDOWN: float = 0.6

@onready var sprite: AnimatedSprite2D = $Visual
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/HitboxShape
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $HealthComponent

# 콤보 단계별로 히트박스를 넓혔다가 되돌릴 기준 크기(씬에 박힌 기본값).
var _hitbox_base_size: Vector2 = Vector2(24, 24)

var _facing_right: bool = true
# 점프 손맛 상태 (코요테/버퍼/가변 점프)
var _coyote_timer: float = 0.0           # >0 이면 (지상이 아니어도) 점프 가능
var _jump_buffer_timer: float = 0.0      # >0 이면 최근 점프 입력이 살아있음
var _jumping: bool = false               # 이번 점프가 상승 중인가(가변 점프 컷용)
var _was_on_floor: bool = false          # 직전 프레임 접지 여부(착지 감지)
var _air_fall_speed: float = 0.0         # 공중에서의 마지막 낙하 속도(착지 피드백용)
# 공격 런지 — 콤보/강타 시 전방으로 짧게 치고 나가는 잔여 속도
var _lunge_vel: float = 0.0
# 공격 상태
var _attacking: bool = false             # 한 타가 끝날 때까지 true
var _combo_step: int = 0                 # 0=무, 1/2/3=콤보 단계
var _combo_timer: float = 0.0            # 콤보 유지 카운트다운
var _combo_buffered: bool = false        # 공격 중 누른 입력 — 현재 타 끝나면 다음 타로 이어감(판정 관대)
var _hold_time: float = 0.0              # attack 키 누른 누적 시간(차지용)
var _charge_started: bool = false        # 이번 누름이 차지로 인식됐는가
var _charge_fx_timer: float = 0.0        # 차지 오라 이펙트 분사 간격 타이머
var _charge_full_fired: bool = false     # 완전 차지 도달 한 방 연출을 이번 누름에 이미 터뜨렸나
var _base_modulate: Color = Color.WHITE
# 회피 상태
var _dodging: bool = false
var _dodge_timer: float = 0.0
var _dodge_cd: float = 0.0
# 스킬 상태 (일섬 돌진)
var _skill_dash_timer: float = 0.0
var _skill_dash_speed: float = 0.0
# 공중 부양 스킬(궁극기·물등) 중 — 중력·이동·입력을 모두 끄고 트윈이 위치를 잡는다.
var _hover_lock: bool = false
const ULT_RISE: float = 120.0        # 떠오르는 높이(px)
const ULT_RISE_TIME: float = 0.3
const ULT_SLAM_TIME: float = 0.12    # 내리꽂는 시간 — 짧을수록 묵직
const HOECHEON_RISE: float = 56.0    # 물등 시전 중 뜨는 높이(px) — 궁극기보다 얕게
const HOECHEON_RISE_TIME: float = 0.22
const HOECHEON_LAND_TIME: float = 0.16
# 낙사 안전망 — 마지막으로 땅을 밟았던 안전 위치
var _last_safe_pos: Vector2 = Vector2.ZERO
var _has_safe_pos: bool = false
# 호신부 오라 노드
var _ward: Node2D = null
# 피격 연출용 직전 HP
var _last_hp: float = 100.0


func _ready() -> void:
    # 충돌 레이어 (메탈슬러그식 통과 판정):
    #   bit1=플레이어 몸, bit2=적 몸, bit3(값4)=월드(지면/발판/결계).
    #   플레이어 몸은 월드(4)에만 부딪히고 적 몸(2)은 통과한다.
    #   레이어1은 유지 — spirit_orb·NPC·픽업 등 Area가 mask=1로 플레이어를 감지.
    collision_layer = 1
    collision_mask = 4
    if health:
        health.hp_changed.connect(_on_hp_changed)
        health.died.connect(_on_died)
        health.shield_broken.connect(_on_shield_broken)
    if sprite:
        _base_modulate = sprite.modulate
    if attack_hitbox:
        # 내가 친 게 적의 Hurtbox에 닿으면 화면 fx 발사
        attack_hitbox.area_entered.connect(_on_hitbox_landed)
    if attack_shape and attack_shape.shape is RectangleShape2D:
        _hitbox_base_size = (attack_shape.shape as RectangleShape2D).size
    SkillManager.skill_cast.connect(_on_skill_cast)
    if health:
        _last_hp = health.hp
    PlayerStats.level_up.connect(_on_level_up)


# 레벨업 보상 — 체력 일부 회복(전투 지속·성장 보상감)
func _on_level_up(_new_level: int) -> void:
    if health:
        health.heal(health.max_hp * 0.4)
        FloatingNumber.spawn(get_tree().current_scene, global_position + Vector2(0, -44), "기력 회복", Color(0.6, 0.9, 0.6))


func _physics_process(delta: float) -> void:
    # 대화 중에는 주인공을 완전히 잠근다 — 이동·점프·공격·차지·회피·스킬 전부 무시.
    # (적은 각자 상태머신이 Dialogue.is_active()로 멈춘다. 여기선 주인공만 담당.)
    if Dialogue and Dialogue.is_active():
        _freeze_for_dialogue(delta)
        return

    # 부양 스킬 중 — 위치는 트윈이 잡는다. 중력·입력·이동 전부 정지.
    if _hover_lock:
        velocity = Vector2.ZERO
        return

    var on_floor := is_on_floor()

    # 중력 — 상승/하강·점프 유지 여부로 가중치 변화(붕 뜨는 느낌 제거, 묵직한 낙하)
    if not on_floor:
        var g := GRAVITY
        if velocity.y > 0.0:
            g *= FALL_GRAVITY_MULT                       # 하강은 더 묵직하게
        elif velocity.y < 0.0 and not Input.is_action_pressed("jump"):
            g *= LOW_JUMP_GRAVITY_MULT                   # 상승 중 점프 뗌 → 정점 빨리
        velocity.y = minf(velocity.y + g * delta, MAX_FALL_SPEED)
        _air_fall_speed = velocity.y                     # 착지 피드백용 낙하속도 기록
    else:
        # 땅 위 + 공격/회피 중이 아닐 때의 위치를 안전 지점으로 기록
        if not _attacking and not _dodging and _skill_dash_timer <= 0.0:
            _last_safe_pos = global_position
            _has_safe_pos = true

    # 코요테 타임 — 발판을 떠난 직후에도 잠깐 점프 가능(낭떠러지 직전 점프 구제)
    if on_floor:
        _coyote_timer = COYOTE_TIME
        _jumping = false
        if not _was_on_floor and _air_fall_speed >= LAND_SHAKE_MIN_FALL:
            ScreenFx.shake(LAND_SHAKE, 0.06)             # 빠르게 떨어져 착지하면 가벼운 흔들림
        _air_fall_speed = 0.0
    else:
        _coyote_timer = maxf(0.0, _coyote_timer - delta)
    _was_on_floor = on_floor

    # 낙사 안전망 — 어떤 이유로든 지면 아래로 떨어지면 마지막 안전 지점으로 복귀
    if global_position.y > FALL_LIMIT_Y:
        _recover_from_fall()
        return

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

    # 스킬 발동 (1/2/3) — SkillManager 가 해금·쿨다운 게이트, 효과는 _on_skill_cast
    if not _dodging and not _attacking:
        if Input.is_action_just_pressed("skill_1"):
            SkillManager.try_cast("ilseom")
        elif Input.is_action_just_pressed("skill_2"):
            SkillManager.try_cast("hoecheon")
        elif Input.is_action_just_pressed("skill_3"):
            SkillManager.try_cast("hosinbu")
        elif Input.is_action_just_pressed("skill_4"):
            SkillManager.try_cast("guichang")

    # 일섬 돌진 진행 — 돌진 동안 조작 잠금
    if _skill_dash_timer > 0.0:
        _skill_dash_timer = maxf(0.0, _skill_dash_timer - delta)
        velocity.x = _skill_dash_speed if _facing_right else -_skill_dash_speed
        move_and_slide()
        return

    # 회피 중에는 이동/공격/콤보 윈도우 무시하고 dash 가속 유지
    if _dodging:
        velocity.x = (DODGE_SPEED if _facing_right else -DODGE_SPEED)
        move_and_slide()
        return

    # 점프 버퍼 — 착지 직전에 누른 입력을 잠시 기억했다가 닿는 즉시 발동
    if Input.is_action_just_pressed("jump"):
        _jump_buffer_timer = JUMP_BUFFER_TIME
    else:
        _jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

    # 점프 실행 — 버퍼된 입력 + (지상 or 코요테 타임)
    if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
        velocity.y = JUMP_VELOCITY
        _jump_buffer_timer = 0.0
        _coyote_timer = 0.0
        _jumping = true
        Audio.play_sfx(Sfx.JUMP)

    # 가변 점프 — 상승 중 점프를 떼면 상승 속도를 즉시 깎아 짧은 점프
    if _jumping and velocity.y < 0.0 and not Input.is_action_pressed("jump"):
        velocity.y *= JUMP_CUT_MULT
        _jumping = false

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
        _charge_full_fired = false

    # 차지 인디케이터(시각 강조) — 일정 시간 이상 누르고 있으면 sprite 밝아짐
    if sprite:
        if _hold_time >= CHARGE_FULL:
            sprite.modulate = _base_modulate.lightened(0.35)
        elif _hold_time >= CHARGE_THRESHOLD:
            sprite.modulate = _base_modulate.lightened(0.15)
        else:
            sprite.modulate = _base_modulate
    # 완전 차지 도달 순간 — '기 다 모였다' 한 방 연출(누름당 1회)
    if _hold_time >= CHARGE_FULL and not _charge_full_fired:
        _charge_full_fired = true
        SkillFx.charge_ready(global_position + Vector2(0, -18))
    # 차지 오라 — 임계 이상 누르는 동안 주기적으로 '기 모으기' 이펙트 분사
    if _hold_time >= CHARGE_THRESHOLD:
        _charge_fx_timer -= delta
        if _charge_fx_timer <= 0.0:
            _charge_fx_timer = 0.1
            SkillFx.charge_aura_tick(global_position + Vector2(0, -18),
                2 if _hold_time >= CHARGE_FULL else 1)
    else:
        _charge_fx_timer = 0.0

    # 좌우 이동 — 가속/마찰 기반(즉시 스냅 대신 발구름·관성). 차지 중엔 목표 속도가 느림.
    var move_speed := SPEED_CHARGING if (_hold_time >= CHARGE_THRESHOLD) else SPEED
    var direction := Input.get_axis("move_left", "move_right")
    var accel := ACCEL if on_floor else AIR_ACCEL
    var fric := FRICTION if on_floor else AIR_FRICTION
    # 공격 중엔 방향키 이동을 막고(콤보 도중 걸어다님 방지) 마찰을 크게 줄여
    # 런지(전방 임펄스)만 살아 흐르게 한다 — 바라보는 쪽으로 역동적 전진 3타.
    if _attacking:
        direction = 0.0
        fric *= 0.18
    # 점프 정점 부근에서는 가로 가속을 살짝 키워 공중 미세 제어가 잘 먹게(체공 제어감)
    if not on_floor and absf(velocity.y) < APEX_THRESHOLD:
        accel *= APEX_BONUS_ACCEL
    if absf(direction) > 0.0:
        # 진행 반대 방향으로 꺾을 땐 가속을 키워 칼같이 전환(끈적임 제거)
        var rate := accel
        if signf(direction) != signf(velocity.x) and absf(velocity.x) > 1.0:
            rate += fric * TURN_BOOST
        velocity.x = move_toward(velocity.x, direction * move_speed, rate * delta)
        _facing_right = direction > 0.0
        if sprite:
            sprite.flip_h = not _facing_right
    else:
        velocity.x = move_toward(velocity.x, 0.0, fric * delta)

    # 일반/콤보 공격 — '눌리는 순간' 발동. 공격 중에 누르면 버퍼링해 두었다가
    # 현재 타가 끝나는 즉시 다음 타로 이어간다(타이밍 빡빡함 해소 → 콤보가 잘 나감).
    if Input.is_action_just_pressed("attack"):
        if _attacking:
            _combo_buffered = true
        else:
            _do_combo_attack()
    # 일반 콤보를 즉시 쳤더라도 그 이후로 계속 누르고 있으면 다음 공격은 차지로 동작.
    if attack_held and _hold_time >= CHARGE_THRESHOLD:
        _charge_started = true

    # 공격 런지 — 트리거 시 1회성 전방 임펄스. velocity.x 에 한 번만 실으면
    # 다음 프레임들의 move_toward(가속/마찰)가 자연스럽게 감쇠시킨다(누적 없음).
    if _lunge_vel != 0.0:
        velocity.x += _lunge_vel
        _lunge_vel = 0.0

    move_and_slide()


# 대화 중 주인공 동결 — 가로 이동은 즉시 멈추고, 중력만 살려 땅에 붙어 있게 한다.
# 진행 중이던 차지 시각/상태를 정리해 대화 후 잔상이 남지 않게 한다.
func _freeze_for_dialogue(delta: float) -> void:
    # 대화가 시작되면 진행 중이던 구르기/공격/스킬 돌진을 즉시 정리한다.
    # (안 그러면 구르던 자세 그대로 얼어붙어 어색한 포즈로 대화하게 됨 — player_visual 이
    #  _dodging/_attacking 을 읽어 dodge/attack 프레임에 멈춰 있기 때문.)
    if _dodging:
        _dodge_timer = 0.0
        _end_dodge()
    _skill_dash_timer = 0.0
    _skill_dash_speed = 0.0
    _attacking = false
    _combo_step = 0
    _combo_timer = 0.0
    _lunge_vel = 0.0
    if not is_on_floor():
        velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
    velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
    _hold_time = 0.0
    _charge_started = false
    _charge_full_fired = false
    _combo_buffered = false
    if sprite:
        sprite.modulate = _base_modulate
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
    # 콤보 단계별 점증 — 1→2→3 으로 데미지·범위·넉백·전진 모두 커진다(범위 공격화).
    var damage_mult := 1.0
    var knock_mult := 1.0
    var shake_strength := 4.0
    var duration := ATTACK_DURATION
    var hb_w := 28.0          # 히트박스 폭(앞으로 뻗는 사거리) — 1타는 좁은 찌름
    var lunge_amt := 150.0    # 전방 런지(바라보는 쪽으로 치고 나감)
    if _combo_step == 2:
        damage_mult = 1.35
        knock_mult = 1.2
        shake_strength = 6.0
        hb_w = 44.0           # 2타 — 넓은 횡베기
        lunge_amt = 200.0
    elif _combo_step == 3:
        damage_mult = 2.0
        knock_mult = 1.7
        shake_strength = 9.0
        duration = ATTACK_DURATION_FINISH
        hb_w = 70.0           # 3타 — 광역 회전 마무리(여러 적 동시 타격)
        lunge_amt = 300.0
    attack_hitbox.damage = base_damage * damage_mult
    attack_hitbox.knockback = base_knock * knock_mult
    # 히트박스를 단계별로 넓혀 '범위 공격'화 — 폭이 커질수록 세로도 살짝 키워 회전 마무리를 광역으로.
    var hb_h := 26.0 + (hb_w - 28.0) * 0.34
    if attack_shape and attack_shape.shape is RectangleShape2D:
        (attack_shape.shape as RectangleShape2D).size = Vector2(hb_w, hb_h)
    # 근거리 가장자리는 몸 앞에 고정하고 폭만 앞으로 확장(중심 = 6 + 폭/2).
    var reach_x := 6.0 + hb_w * 0.5
    attack_hitbox.position.x = reach_x if _facing_right else -reach_x
    # 전방 런지 — 3타가 가장 크게 치고 나가 타격감·역동 강조(공격 중 마찰↓로 글라이드).
    _lunge_vel = lunge_amt * (1.0 if _facing_right else -1.0)
    Audio.play_sfx(Sfx.ATTACK)
    # 콤보 단계별 창 이펙트(1 찌르기 / 2 횡소 / 3 회전베기)
    SkillFx.combo(global_position + Vector2(0, -16), _facing_right, _combo_step)
    # 콤보 동작 잔상 트레일 — 새 PixelLab 모션을 강조(3타가 가장 화려)
    if sprite:
        var trail_tint: Color = SkillFx.MAGE if _combo_step < 3 else SkillFx.MAGE_HOT
        var trail_n := 3 if _combo_step < 3 else 5
        SkillFx.afterimage_burst(sprite, trail_tint, trail_n, duration + ATTACK_RECOVER * 0.6)
    # 공격 휘두를 때마다 살짝 진동(피드백). 명중 시 추가 진동은 _on_hitbox_landed에서.
    ScreenFx.shake(shake_strength * 0.5, 0.08)
    await attack_hitbox.activate(duration)
    # 원래 베이스(씬에 박힌 기본값)로 복귀 — 데미지·넉백·히트박스 크기·위치
    attack_hitbox.damage = stored_damage
    attack_hitbox.knockback = stored_knock
    attack_hitbox.position.x = 16.0 if _facing_right else -16.0
    if attack_shape and attack_shape.shape is RectangleShape2D:
        (attack_shape.shape as RectangleShape2D).size = _hitbox_base_size
    await get_tree().create_timer(ATTACK_RECOVER).timeout
    _attacking = false
    # 3타까지 갔으면 콤보 즉시 리셋(다음 입력은 1타부터)
    if _combo_step >= 3:
        _combo_step = 0
        _combo_timer = 0.0
        _combo_buffered = false
    # 공격 중 눌러둔 입력이 있고 콤보가 아직 살아있으면 곧장 다음 타로 이어간다.
    elif _combo_buffered and _combo_timer > 0.0:
        _combo_buffered = false
        _do_combo_attack()
    else:
        _combo_buffered = false


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
    _lunge_vel = 150.0 * (1.0 if _facing_right else -1.0)
    Audio.play_sfx(Sfx.ATTACK)
    ScreenFx.shake(10.0, 0.18)
    # 기 모은 한 방 — 금빛 일섬으로 일반 콤보와 확실히 구분(차지 준비→발동 시각 루프 완성)
    var slash_x := 22.0 if _facing_right else -22.0
    SkillFx.slash(global_position + Vector2(slash_x, -10), _facing_right, SkillFx.GOLD)
    if sprite:
        SkillFx.afterimage_burst(sprite, SkillFx.MAGE_HOT, 4, 0.28)
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
    # 타격이 적중하는 순간 '퍽' 하는 피격음(적 측에서 내던 걸 공격자 측으로 모음 → 허공 스윙엔 안 남).
    # 스윙음(바람가르는 소리)에 묻히지 않게 +3dB 부각(피크 -0.2dBFS, 클립 없음).
    Audio.play_sfx(Sfx.HIT, 3.0)
    var landed_strength := 4.0 + 1.5 * float(_combo_step)
    ScreenFx.shake(landed_strength, 0.16)
    # 등급별 히트스톱 — 1·2타는 짧고 얕게(경쾌), 3타(마무리)는 길고 '딱' 멈춤(묵직).
    match _combo_step:
        1: ScreenFx.hit_stop(0.035, 0.18)
        2: ScreenFx.hit_stop(0.05, 0.10)
        _: ScreenFx.hit_stop(0.09, 0.03)
    # 폰 햅틱 — 타수가 커질수록 길게(손끝 타격감). 데스크톱은 무시됨.
    ScreenFx.rumble(10 + 8 * _combo_step)
    # 적중 임팩트 스파크 — 히트박스 위치 근처
    var fx_pos := area.global_position if area else (global_position + Vector2(0, -16))
    SkillFx.impact(fx_pos, _combo_step >= 3)
    SkillFx.bleed(fx_pos, _facing_right, _combo_step >= 3)


# 회피 시작/종료 — Hurtbox 비활성으로 무적, sprite 반투명
func _start_dodge() -> void:
    _dodging = true
    _dodge_timer = DODGE_DURATION
    Audio.play_sfx(Sfx.DODGE)
    if hurtbox:
        hurtbox.monitoring = false
    if sprite:
        var c := _base_modulate
        c.a = 0.55
        sprite.modulate = c
        SkillFx.afterimage_burst(sprite, SkillFx.BLUE, 4, DODGE_DURATION)
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


# ────────────────────────────── 스킬 효과 ──────────────────────────────

func _on_skill_cast(id: String) -> void:
    match id:
        "ilseom":
            _skill_ilseom()
        "hoecheon":
            _skill_hoecheon()
        "hosinbu":
            _skill_hosinbu()
        "guichang":
            _skill_ultimate()


## 궁극기 '귀창 강림' — 공중으로 떠올라 기를 모은 뒤 내려찍는다.
## ① 부양 + 시전(창들이 하늘에서 모여듦) → ② 급강하 → ③ 착지 순간 광역 대피해 + 충격파.
func _skill_ultimate() -> void:
    var def := SkillManager.get_def("guichang")
    _attacking = true
    _hover_lock = true
    var ground := global_position
    var apex := ground + Vector2(0, -ULT_RISE)
    var charge := float(def.get("charge_time", 0.65))
    Audio.play_sfx(Sfx.WARD)
    # ① 떠오름 — 중력을 끄고 정점까지 부드럽게 상승
    var rise := create_tween()
    rise.tween_property(self, "global_position", apex, ULT_RISE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    SkillFx.ultimate_charge(apex, charge)
    if sprite:
        SkillFx.afterimage_burst(sprite, SkillFx.MAGE_HOT, 6, charge)
    await get_tree().create_timer(charge).timeout
    if not is_instance_valid(self) or not _hover_lock:
        return
    # ② 급강하 — 짧고 빠르게 내리꽂는다
    Audio.play_sfx(Sfx.ULT)
    var slam := create_tween()
    slam.tween_property(self, "global_position", ground, ULT_SLAM_TIME).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
    if sprite:
        SkillFx.afterimage_burst(sprite, SkillFx.MAGE_HOT, 4, ULT_SLAM_TIME)
    await slam.finished
    if not is_instance_valid(self):
        return
    _hover_lock = false
    velocity = Vector2.ZERO
    # ③ 착지 — 화면이 멈췄다 터진다
    var radius := float(def.get("radius", 360.0))
    var mult := float(def.get("damage_mult", 3.5))
    var dmg := Equipment.current_damage(attack_hitbox.damage) * mult
    ScreenFx.hit_stop(0.14, 0.02)
    ScreenFx.shake(20.0, 0.55)
    ScreenFx.rumble(90)
    SkillFx.ultimate(ground)
    SkillFx.ground_shock(ground, radius)
    # 사거리 안 모든 적에게 피해 (궁극기는 히트박스를 안 거치므로 피격음을 1회 직접 재생)
    var hit_any := false
    for e in get_tree().get_nodes_in_group("enemy"):
        if not (e is Node2D):
            continue
        if ground.distance_to((e as Node2D).global_position) > radius:
            continue
        var hc: HealthComponent = e.get_node_or_null("HealthComponent")
        if hc:
            hc.take_damage(dmg, self)
            hit_any = true
            var epos: Vector2 = (e as Node2D).global_position + Vector2(0, -16)
            SkillFx.impact(epos, true)
            SkillFx.bleed(epos, _facing_right, true)
    if hit_any:
        Audio.play_sfx(Sfx.HIT, 3.0)
    await get_tree().create_timer(0.4).timeout
    _attacking = false


## 「여울 가르기」(id: ilseom) — 강물을 갈라 앞으로 밀어내는 진혼의 물살.
## 전방 돌진 + 돌진 내내 넓은 물마루 히트박스로 앞의 넋을 씻어 보낸다.
## ① 시전(물이 몸으로 감겨듦) → ② 일직선 돌진 + 베기 → ③ 지나간 자리마다 파도 → ④ 물기둥 마무리.
func _skill_ilseom() -> void:
    var def := SkillManager.get_def("ilseom")
    _attacking = true
    var dir := 1.0 if _facing_right else -1.0

    # ① 시전 — 몸을 살짝 뒤로 당기며 물을 끌어모은다(발동 예고).
    var windup := float(def.get("windup", 0.32))
    Audio.play_sfx(Sfx.WARD)
    SkillFx.river_gather(global_position, _facing_right, windup)
    velocity.x = -dir * 70.0
    await get_tree().create_timer(windup).timeout
    if not is_instance_valid(self):
        return

    # ② 돌진 — 일직선으로 길게 가르며 지나간다.
    _skill_dash_speed = float(def.get("dash_speed", 560.0))
    var dur := float(def.get("dash_time", 0.42))
    _skill_dash_timer = dur
    var stored_damage: float = attack_hitbox.damage
    var stored_knock: float = attack_hitbox.knockback
    attack_hitbox.damage = Equipment.current_damage(stored_damage) * float(def.get("damage_mult", 1.9))
    # 물마루 — 앞으로 넓게 뻗는 판정(전방 사거리 확장)
    if attack_shape and attack_shape.shape is RectangleShape2D:
        (attack_shape.shape as RectangleShape2D).size = Vector2(86.0, 40.0)
    attack_hitbox.position.x = 34.0 * dir
    Audio.play_sfx(Sfx.ATTACK)
    ScreenFx.shake(8.0, 0.16)
    ScreenFx.rumble(30)
    SkillFx.river_cleave(global_position + Vector2(0, -16), _facing_right)
    if sprite:
        SkillFx.afterimage_burst(sprite, SkillFx.WATER, 8, dur)
    # ③ 지나가는 자리마다 파도 (돌진과 동시에 진행)
    _spawn_wave_trail(dur)
    await attack_hitbox.activate(dur)
    attack_hitbox.damage = stored_damage
    attack_hitbox.knockback = stored_knock
    attack_hitbox.position.x = 16.0 if _facing_right else -16.0
    if attack_shape and attack_shape.shape is RectangleShape2D:
        (attack_shape.shape as RectangleShape2D).size = _hitbox_base_size

    # ④ 마무리 — 멈춘 자리에서 물이 크게 터진다.
    SkillFx.river_burst(global_position, _facing_right)
    ScreenFx.shake(9.0, 0.2)
    _attacking = false


# 돌진 내내 일정 간격으로 발밑에 파도를 남긴다(fire-and-forget).
func _spawn_wave_trail(dur: float) -> void:
    var left := dur
    while left > 0.0 and is_instance_valid(self):
        SkillFx.wave_wake(global_position, _facing_right)
        await get_tree().create_timer(0.06).timeout
        left -= 0.06


## 「진혼의 물등」(id: hoecheon) — 2026-08-18 개편: 광역 즉발 파문 → 스킬샷형
## 부적 투척으로 변경. ① 짧게 공중에 뜨며 시전(부적이 모여듦) → ② 정점에서
## 부채꼴로 다량의 부적을 일직선 투척 — 사거리·각도 밖 적은 맞지 않는다(빗나감 있음).
func _skill_hoecheon() -> void:
    var def := SkillManager.get_def("hoecheon")
    _attacking = true
    _hover_lock = true
    var ground := global_position
    var apex := ground + Vector2(0, -HOECHEON_RISE)
    var charge := float(def.get("charge_time", 0.42))
    Audio.play_sfx(Sfx.WARD)
    var rise := create_tween()
    rise.tween_property(self, "global_position", apex, HOECHEON_RISE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    SkillFx.requiem_lantern(apex)
    if sprite:
        SkillFx.afterimage_burst(sprite, SkillFx.LANTERN, 4, charge)
    await get_tree().create_timer(charge).timeout
    if not is_instance_valid(self) or not _hover_lock:
        return

    # ② 투척 — 바라보는 방향으로 부채꼴 다발.
    var dir := 1.0 if _facing_right else -1.0
    var count := int(def.get("count", 7))
    var spread_deg := float(def.get("spread_deg", 70.0))
    var speed := float(def.get("speed", 620.0))
    var life := float(def.get("life", 0.85))
    var dmg := Equipment.current_damage(attack_hitbox.damage) * float(def.get("damage_mult", 1.6))
    var knock := attack_hitbox.knockback * float(def.get("knock_mult", 1.3))
    Audio.play_sfx(Sfx.ATTACK)
    ScreenFx.shake(6.0, 0.14)
    ScreenFx.hit_stop(0.04, 0.06)
    SkillFx.ward_cast(global_position)
    var host: Node = get_tree().current_scene
    var half: float = deg_to_rad(spread_deg) * 0.5
    var denom: float = maxf(float(count - 1), 1.0)
    for i in range(count):
        var t: float = float(i) / denom   # 0..1
        var ang: float = lerp(-half, half, t)
        var shot_dir: Vector2 = Vector2(dir, 0.0).rotated(ang)
        TalismanShot.spawn(host, global_position, shot_dir, dmg, knock, speed, life, self)

    # ③ 착지 — 짧게 내려온다.
    _hover_lock = false
    var land := create_tween()
    land.tween_property(self, "global_position", ground, HOECHEON_LAND_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    await land.finished
    if not is_instance_valid(self):
        return
    velocity = Vector2.ZERO
    _attacking = false


## 호신부 — 피해 1회 무효 가호
func _skill_hosinbu() -> void:
    var def := SkillManager.get_def("hosinbu")
    health.shield_charges = int(def.get("shield_charges", 1))
    Audio.play_sfx(Sfx.WARD)
    ScreenFx.rumble(20)
    # 발동 연출 — 한지 조각이 모여들고 금빛 파문이 앉는다
    SkillFx.ward_cast(global_position)
    # 부적 오라 부착 (이전 것이 남아 있으면 제거)
    if _ward != null and is_instance_valid(_ward):
        _ward.queue_free()
    _ward = SkillFx.attach_ward(self)
    FloatingNumber.spawn(get_tree().current_scene, global_position + Vector2(0, -40), "護", Color(1, 0.9, 0.5))


func _on_shield_broken() -> void:
    Audio.play_sfx(Sfx.HIT)
    ScreenFx.shake(5.0, 0.12)
    SkillFx.impact(global_position + Vector2(0, -16), true)
    FloatingNumber.spawn(get_tree().current_scene, global_position + Vector2(0, -40), "가호 소멸", Color(1, 0.85, 0.5))
    if _ward != null and is_instance_valid(_ward):
        _ward.queue_free()
        _ward = null
    if sprite:
        sprite.modulate = _base_modulate


# 낙사 복구 — 마지막 안전 지점(없으면 현재 x, 화면 위)으로 되돌리고 속도 0
func _recover_from_fall() -> void:
    velocity = Vector2.ZERO
    if _dodging:
        _end_dodge()
    _skill_dash_timer = 0.0
    _hover_lock = false          # 부양 중 낙사 구제되면 중력 복구
    _attacking = false
    if _has_safe_pos:
        global_position = _last_safe_pos
    else:
        global_position = Vector2(global_position.x, 200.0)
    ScreenFx.shake(4.0, 0.15)
    # 작은 불이익만 — 추락은 사망이 아니라 '미끄러짐'으로 처리(버그 구제 성격)
    if health and health.hp > 0.0:
        health.take_damage(5.0)


func _on_hp_changed(hp: float, max_hp: float) -> void:
    # 피해를 입었을 때만 피격 연출(회복은 제외)
    if hp < _last_hp:
        Audio.play_sfx(Sfx.HURT)
        ScreenFx.shake(4.0, 0.14)
        ScreenFx.rumble(45)      # 내가 맞을 때는 길고 굵게(적중과 구분)
        _hurt_flash()
    _last_hp = hp


func _hurt_flash() -> void:
    if not sprite:
        return
    # 피격 무적 동안 깜빡임(붉게)
    for i in range(3):
        sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
        await get_tree().create_timer(0.09).timeout
        if not is_instance_valid(sprite):
            return
        sprite.modulate = _base_modulate
        await get_tree().create_timer(0.09).timeout
        if not is_instance_valid(sprite):
            return


func _on_died() -> void:
    print("[Player] died")
    Audio.play_sfx(Sfx.DIE)
    _hover_lock = false          # 부양 중 죽어도 공중에 얼지 않게
    velocity = Vector2.ZERO
    GameOverScreen.show_screen()
