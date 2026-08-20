extends CharacterBody2D
class_name Boss
##
## 보스 적 — 예고(텔레그래프) → 패턴 공격 → 회복의 반복.
##
## 상태:
##   Idle: 플레이어 추적, engage_distance 안에 들면 Telegraph 진입.
##   Telegraph: 멈춰서 **이번에 쓸 패턴을 뽑고**, 머리 위 기호·바닥 연출로 미리 알린다.
##   Attack: 뽑힌 패턴 시전 — 돌진 / 부적 세례 / 물기둥 / 밀물 / 소환(페이즈2).
##   Recover: 잠깐 멈춤(recover_seconds). 그 후 다시 Idle.
##
## 패턴마다 요구하는 **회피 동작이 다르다** — 자세한 건 아래 @export_group("패턴").
##
## Boss 는 HP/XP 보상이 크고 사망 시 옵션으로 보상 아이템(reward_item_id × qty)을 인벤토리에 지급.
##

@export var display_name: String = "호귀 두목"
@export var body_color: Color = Color(0.85, 0.55, 0.20, 1)
@export var engage_distance: float = 320.0
@export var telegraph_seconds: float = 0.85
@export var attack_seconds: float = 0.38
@export var recover_seconds: float = 1.6
@export var dash_speed: float = 280.0
## 돌진 히트박스가 몸 앞으로 나가는 거리 — 덩치 큰 보스일수록 크게.
@export var dash_reach: float = 28.0
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
# 사망 후 전환할 씬(비우면 전환 안 함) — 최종 보스가 엔딩으로 갈 때.
@export var scene_on_death: String = ""
# 이름표 아래 소제목 — 보스마다 다른 한 줄 사극체 설명.
@export var subtitle: String = "닫힌 수문 앞에서 잠긴 넋들"
# 등장 연출에 물기둥 솟구침을 쓸지 — 물 스테이지 전용 보스가 아니면 false.
@export var water_entrance: bool = true

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $HealthComponent
@onready var attack_hitbox: Hitbox = $AttackHitbox

# ── 보스 공격 패턴 (2026-08-19 개편) ───────────────────────────────
# 돌진 하나뿐이던 보스를 **다섯 패턴 + 페이즈 2** 로 확장한다. 설계 원칙:
#   · 패턴마다 **예고(텔레그래프)** 가 먼저 오고, 각기 **다른 회피 동작**을 요구한다.
#       돌진 = 점프/뒤로 / 부적 세례 = 좌우 사이 / 물기둥 = 옆으로 / 밀물 = 점프 / 소환 = 정리
#   · 같은 패턴이 연달아 나오지 않는다(가중 무작위 + 직전 제외).
@export_group("패턴")
## 부적 세례 — 부채꼴로 흩뿌리는 원거리. 사이 공간으로 피한다.
@export var volley_count: int = 5
@export var volley_damage: float = 9.0
@export var volley_spread_deg: float = 46.0
@export var volley_speed: float = 250.0
## 물기둥 — 발밑 예고 후 솟구침. 옆으로 걸어 나가 피한다.
@export var pillar_count: int = 3
@export var pillar_damage: float = 14.0
@export var pillar_warn: float = 0.75
## 밀물 — 낮은 물결. 점프로만 넘는다.
@export var wave_damage: float = 12.0
@export var wave_speed: float = 250.0
## 소환(페이즈 2 전용) — 잡귀를 불러 압박한다.
@export var summon_scene: String = "res://scenes/enemies/Dueoksini.tscn"
@export var summon_count: int = 2
## 이 보스가 쓸 패턴 목록(가중치를 주려면 같은 이름을 여러 번 넣는다).
## 비워두면 기존 기본 풀(돌진·부적세례·물기둥·밀물, 페이즈2 에 소환)을 그대로 쓴다.
## 이름: "dash" "volley" "pillars" "wave" "summon".
## 물기둥·밀물은 물 스테이지 전용 연출이라, 물이 아닌 보스는 여기서 빼면 컨셉이 안 섞인다.
@export var pattern_pool: PackedStringArray = PackedStringArray()

enum Pattern { DASH, VOLLEY, PILLARS, WAVE, SUMMON }

## 현재 시전 중인 패턴과 직전 패턴(연속 반복 방지)
var _pattern: int = Pattern.DASH
var _last_pattern: int = -1

const GRAVITY: float = 980.0

enum State { IDLE, TELEGRAPH, ATTACK, RECOVER, DEAD }
var _state: int = State.IDLE
var _state_timer: float = 0.0
var _facing_right: bool = true
var _attacking_blink: bool = false
# 페이즈 2 — HP 50% 이하에서 한 번만 진입. 패턴 가속 + 색감 변화.
var _phase: int = 1
# 스프라이트 기본 틴트 — 평소 흰색(원본색), 페이즈 2 에서 핏빛.
var _tint_base: Color = Color.WHITE
# 피격 squash 복귀 기준(드리프트 방지)
var _spr_base_scale: Vector2 = Vector2.ZERO
# 플레이어를 처음 교전하는 순간 등장 연출을 한 번만 재생.
var _engaged: bool = false
## 등장 연출이 재생되는 동안 참 — 이때는 어떤 패턴도 나가지 않는다.
## (연출은 비동기라 이 잠금이 없으면 다음 프레임에 바로 공격이 시작된다.)
var _entrance_playing: bool = false


## EnemyVisual 이 읽는 애니메이션 힌트. 빈 문자열이면 visual 이 velocity 로 idle/walk 결정.
func get_anim_hint() -> String:
    match _state:
        State.TELEGRAPH:
            return "telegraph"
        State.ATTACK:
            return "attack"
        State.DEAD:
            return "death"
        _:
            return ""


func _ready() -> void:
    add_to_group("enemy")
    add_to_group("enemy_gate")
    add_to_group("boss")
    # 적 몸은 월드(bit3=4)에만 부딪히고 플레이어·다른 적은 통과 (메탈슬러그식).
    collision_layer = 2
    collision_mask = 4
    # 실제 스프라이트(EnemyVisual) 사용 — 색 틴트 없이 원본 표시. (페이즈 2에서만 핏빛 틴트)
    # attack_hitbox 활성 게이트는 Hitbox._ready 가 스스로 초기화 (layer 게이트)
    hurtbox.hurt.connect(_on_hurt)
    health.hp_changed.connect(_on_hp_changed)
    health.died.connect(_on_died)
    if sprite:
        _spr_base_scale = sprite.scale
    # 보스 바는 더 두껍고 넓게. 높이는 EnemyHpBar 가 스프라이트를 재서 머리 위에 건다.
    var bar := EnemyHpBar.attach_to(self, health, true)
    _make_warn()
    # 경고 '!' 는 HP 바보다 더 위에 — 겹쳐서 바를 가리지 않게.
    if _warn:
        _warn.position.y = bar.position.y - 44.0


# 돌진 예고 경고 표시 — 머리 위 붉은 '!' (텔레그래프 중에만)
var _warn: Label
func _make_warn() -> void:
    _warn = Label.new()
    _warn.text = "!"
    _warn.position = Vector2(-10, -78)
    _warn.add_theme_font_size_override("font_size", 32)
    _warn.add_theme_color_override("font_color", Color(0.95, 0.25, 0.2))
    _warn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    _warn.add_theme_constant_override("outline_size", 5)
    _warn.visible = false
    add_child(_warn)


func _physics_process(delta: float) -> void:
    # 중력
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    # 대화 중에는 보스도 정지(중력만) — 연출 중 공격/이동 금지.
    if _state != State.DEAD and Dialogue and Dialogue.is_active():
        velocity.x = move_toward(velocity.x, 0.0, 400.0)
        move_and_slide()
        return

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
    if _entrance_playing:
        return                                   # 등장 연출 중엔 아무것도 하지 않는다
    var p := _player()
    if p == null:
        return
    var d := global_position.distance_to(p.global_position)
    if d <= engage_distance:
        _facing_right = p.global_position.x >= global_position.x
        if not _engaged:
            _engaged = true
            _play_entrance()          # 등장 연출이 끝난 뒤에 첫 패턴이 나간다
            return
        _enter_telegraph()



# ── 등장 연출 ──────────────────────────────────────────────────
## 처음 교전하는 순간 한 번. 물기둥이 솟구쳐 보스를 드러내고, 이름이 떠오른다.
## 연출 동안 보스는 IDLE 로 굳어 있고(공격 안 함), 끝나면 첫 패턴으로 들어간다.
func _play_entrance() -> void:
    _entrance_playing = true
    _state = State.IDLE
    _state_timer = 999.0                     # 연출 중 자동 전이 방지
    velocity.x = 0.0
    if sprite:
        sprite.modulate = _tint_base
    Audio.play_sfx(Sfx.WARD)
    ScreenFx.shake(16.0, 0.6)
    ScreenFx.rumble(120)
    if water_entrance:
        SkillFx.boss_water_rise(global_position, 1.6)
    SkillFx.boss_entrance(global_position)
    _show_name_plate()
    await get_tree().create_timer(1.15).timeout
    if not is_instance_valid(self) or _state == State.DEAD:
        _entrance_playing = false
        return
    ScreenFx.shake(10.0, 0.35)
    Audio.play_sfx(Sfx.ATTACK)
    await get_tree().create_timer(0.75).timeout
    _entrance_playing = false
    if not is_instance_valid(self) or _state == State.DEAD:
        return
    _state_timer = 0.0
    _enter_telegraph()


## 화면 아래쪽에 보스 이름을 잠깐 띄운다(사극체 호칭 — 수묵 톤).
func _show_name_plate() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 9
    add_child(layer)
    var box := VBoxContainer.new()
    box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    box.anchor_left = 0.5; box.anchor_right = 0.5; box.anchor_top = 1.0; box.anchor_bottom = 1.0
    box.offset_left = -300; box.offset_right = 300; box.offset_top = -190; box.offset_bottom = -100
    box.add_theme_constant_override("separation", 2)
    var name_label := Label.new()
    name_label.text = display_name
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 40)
    name_label.add_theme_color_override("font_color", Color(0.93, 0.90, 0.82))
    name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    name_label.add_theme_constant_override("outline_size", 8)
    box.add_child(name_label)
    var sub := Label.new()
    sub.text = subtitle
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_font_size_override("font_size", 16)
    sub.add_theme_color_override("font_color", Color(0.72, 0.78, 0.84))
    sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    sub.add_theme_constant_override("outline_size", 5)
    box.add_child(sub)
    box.modulate = Color(1, 1, 1, 0)
    layer.add_child(box)
    var tw := box.create_tween()
    tw.tween_property(box, "modulate:a", 1.0, 0.5)
    tw.tween_interval(1.8)
    tw.tween_property(box, "modulate:a", 0.0, 0.7)
    tw.tween_callback(layer.queue_free)


func _tick_telegraph(_delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 400.0)
    # 텔레그래프 깜빡임 — 시각 강조
    if sprite:
        var t := int(Time.get_ticks_msec() / 100) % 2
        sprite.modulate = _tint_base.lightened(0.4) if t == 0 else _tint_base
    if _state_timer <= 0.0:
        _enter_attack()


func _tick_attack(_delta: float) -> void:
    # 돌진만 실제로 몸이 나간다. 나머지 패턴은 제자리에서 시전(회피 공간을 남긴다).
    if _pattern == Pattern.DASH:
        var dir := 1.0 if _facing_right else -1.0
        velocity.x = dash_speed * dir
        if sprite:
            sprite.modulate = _tint_base.lightened(0.5)
            sprite.flip_h = not _facing_right
    else:
        velocity.x = move_toward(velocity.x, 0.0, 600.0)
        if sprite:
            sprite.modulate = _tint_base
    if _state_timer <= 0.0:
        _enter_recover()


func _tick_recover(_delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 400.0)
    if sprite:
        sprite.modulate = _tint_base
    if _state_timer <= 0.0:
        _state = State.IDLE


func _enter_telegraph() -> void:
    _state = State.TELEGRAPH
    _pattern = _choose_pattern()
    _state_timer = _telegraph_time(_pattern)
    # 플레이어 쪽을 보고 시전한다(패턴이 엉뚱한 방향으로 나가지 않게).
    var p := _player()
    if p != null:
        _facing_right = p.global_position.x >= global_position.x
    _show_warn(_warn_glyph(_pattern), _warn_color(_pattern))
    _telegraph_fx(_pattern)


## 가중 무작위 — 직전과 같은 패턴은 뽑지 않는다. 페이즈 2 에서 소환이 추가된다.
func _choose_pattern() -> int:
    var pool: Array = _default_pool()
    if not pattern_pool.is_empty():
        pool = []
        for nm in pattern_pool:
            var pat := _pattern_from_name(String(nm))
            if pat >= 0:
                pool.append(pat)
        if pool.is_empty():
            pool = _default_pool()
    var picks: Array = []
    for x in pool:
        if x != _last_pattern:
            picks.append(x)
    if picks.is_empty():
        picks = pool
    return picks[randi() % picks.size()]


## 기본 풀(물 보스 기준) — pattern_pool 이 비어 있을 때만 쓰인다.
func _default_pool() -> Array:
    var pool: Array = [Pattern.DASH, Pattern.DASH, Pattern.VOLLEY, Pattern.VOLLEY,
        Pattern.PILLARS, Pattern.PILLARS, Pattern.WAVE, Pattern.WAVE]
    if _phase >= 2:
        pool.append_array([Pattern.VOLLEY, Pattern.PILLARS, Pattern.WAVE, Pattern.SUMMON, Pattern.SUMMON])
    return pool


## 패턴 이름 → enum. 모르는 이름이면 -1(무시).
func _pattern_from_name(nm: String) -> int:
    match nm.strip_edges().to_lower():
        "dash":    return Pattern.DASH
        "volley":  return Pattern.VOLLEY
        "pillars": return Pattern.PILLARS
        "wave":    return Pattern.WAVE
        "summon":  return Pattern.SUMMON
    push_warning("[Boss] 모르는 패턴 이름: %s" % nm)
    return -1
func _telegraph_time(pat: int) -> float:
    var base := telegraph_seconds
    match pat:
        Pattern.VOLLEY:  base = telegraph_seconds * 0.8
        Pattern.PILLARS: base = telegraph_seconds * 0.7    # 기둥 자체가 또 예고한다
        Pattern.WAVE:    base = telegraph_seconds * 0.95
        Pattern.SUMMON:  base = telegraph_seconds * 0.9
    return base * _phase_mult_telegraph()


## 패턴마다 머리 위 기호를 달리해, 무엇이 오는지 눈으로 구분되게 한다.
func _warn_glyph(pat: int) -> String:
    match pat:
        Pattern.VOLLEY:  return "※"
        Pattern.PILLARS: return "▲"
        Pattern.WAVE:    return "≈"
        Pattern.SUMMON:  return "＋"
        _:               return "!"


func _warn_color(pat: int) -> Color:
    match pat:
        Pattern.VOLLEY:  return Color(0.95, 0.82, 0.45)
        Pattern.PILLARS: return Color(0.56, 0.78, 0.84)
        Pattern.WAVE:    return Color(0.42, 0.66, 0.78)
        Pattern.SUMMON:  return Color(0.72, 0.55, 0.98)
        _:               return Color(0.95, 0.25, 0.2)


func _show_warn(glyph: String, col: Color) -> void:
    if _warn == null:
        return
    _warn.text = glyph
    _warn.add_theme_color_override("font_color", col)
    _warn.visible = true
    _warn.modulate.a = 1.0
    var tw := create_tween().set_loops()   # 깜빡이는 경고
    tw.tween_property(_warn, "modulate:a", 0.2, 0.15)
    tw.tween_property(_warn, "modulate:a", 1.0, 0.15)
    _warn.set_meta("tw", tw)


## 시전 전 바닥/몸에 붙는 예고 연출 — '어디로 오는지'를 보여준다.
func _telegraph_fx(pat: int) -> void:
    var dir := 1.0 if _facing_right else -1.0
    match pat:
        Pattern.DASH:
            # 돌진 경로를 바닥에 금으로 그어 보여준다.
            SkillFx.ground_shock(global_position + Vector2(dir * 40.0, 0), 120.0)
        Pattern.VOLLEY:
            SkillFx.charge_aura_tick(global_position + Vector2(0, -40.0), 2)
        Pattern.WAVE:
            # 물이 뒤로 빨려들었다가 밀려나온다.
            SkillFx.river_gather(global_position, _facing_right, _telegraph_time(pat) * 0.8)
        Pattern.SUMMON:
            SkillFx.charge_aura_tick(global_position + Vector2(0, -30.0), 1)


func _hide_warn() -> void:
    if _warn:
        var tw = _warn.get_meta("tw", null)
        if tw and tw.is_valid():
            tw.kill()
        _warn.visible = false


func _enter_attack() -> void:
    _hide_warn()
    _state = State.ATTACK
    _last_pattern = _pattern
    match _pattern:
        Pattern.VOLLEY:
            _state_timer = 0.5
            _do_volley()
        Pattern.PILLARS:
            _state_timer = pillar_warn + 0.6
            _do_pillars()
        Pattern.WAVE:
            _state_timer = 0.55
            _do_wave()
        Pattern.SUMMON:
            _state_timer = 0.7
            _do_summon()
        _:
            _do_dash()


## ① 돌진 — 몸으로 밀고 들어온다. 점프로 넘거나 뒤로 빠져 피한다.
func _do_dash() -> void:
    var dur := attack_seconds * _phase_mult_attack()
    _state_timer = dur
    if attack_hitbox:
        attack_hitbox.position.x = dash_reach if _facing_right else -dash_reach
        attack_hitbox.damage = attack_damage * (1.25 if _phase >= 2 else 1.0)
        attack_hitbox.knockback = attack_knockback
        attack_hitbox.activate(dur)
    Audio.play_sfx(Sfx.ATTACK)


## ② 부적 세례 — 부채꼴 원거리. 탄과 탄 사이로 비집고 피한다.
func _do_volley() -> void:
    var host := get_parent()
    if host == null:
        return
    var dir := 1.0 if _facing_right else -1.0
    var n := maxi(1, volley_count + (2 if _phase >= 2 else 0))
    var spread := deg_to_rad(volley_spread_deg)
    var origin := global_position + Vector2(dir * 26.0, -46.0)
    for i in range(n):
        var t := 0.0 if n == 1 else float(i) / float(n - 1)
        var a := lerpf(-spread * 0.5, spread * 0.5, t)
        var orb = SpiritOrb.spawn(host, origin, dir, volley_damage, volley_speed)
        if orb != null and "velocity" in orb:
            orb.velocity = Vector2(volley_speed * dir, 0).rotated(a * dir)
    Audio.play_sfx(Sfx.ATTACK)
    ScreenFx.shake(5.0, 0.14)


## ③ 물기둥 — 플레이어 발밑을 따라 예고 후 솟구친다. 옆으로 걸어 나가 피한다.
func _do_pillars() -> void:
    var host := get_parent()
    var p := _player()
    if host == null or p == null:
        return
    var n := maxi(1, pillar_count + (1 if _phase >= 2 else 0))
    var base_x: float = p.global_position.x
    var ground_y: float = global_position.y + 8.0
    for i in range(n):
        # 첫 기둥은 플레이어 발밑, 이후엔 도망칠 법한 쪽으로 번져 나간다.
        var off := 0.0 if i == 0 else float(i) * 86.0 * (1.0 if i % 2 == 1 else -1.0)
        WaterPillar.spawn(host, Vector2(base_x + off, ground_y), pillar_damage,
            pillar_warn + i * 0.16, 0.4)
    Audio.play_sfx(Sfx.WARD)


## ④ 밀물 — 지면을 훑는 낮은 물결. **점프로만** 넘는다.
func _do_wave() -> void:
    var host := get_parent()
    if host == null:
        return
    var dir := 1.0 if _facing_right else -1.0
    TideWave.spawn(host, Vector2(global_position.x + dir * 30.0, global_position.y + 8.0),
        dir, wave_damage, wave_speed)
    if _phase >= 2:
        # 페이즈 2 — 반대쪽에서도 한 겹 더(양쪽에서 조여든다)
        TideWave.spawn(host, Vector2(global_position.x - dir * 30.0, global_position.y + 8.0),
            -dir, wave_damage, wave_speed * 0.85)
    Audio.play_sfx(Sfx.ATTACK)
    ScreenFx.shake(6.0, 0.18)


## ⑤ 소환(페이즈 2) — 잡귀를 불러 압박한다.
func _do_summon() -> void:
    var host := get_parent()
    if host == null or not ResourceLoader.exists(summon_scene):
        return
    var packed: PackedScene = load(summon_scene)
    if packed == null:
        return
    for i in range(maxi(1, summon_count)):
        var m := packed.instantiate() as Node2D
        if m == null:
            continue
        var side := 1.0 if i % 2 == 0 else -1.0
        host.add_child(m)
        m.global_position = global_position + Vector2(side * (70.0 + i * 26.0), -6.0)
        SkillFx.impact(m.global_position + Vector2(0, -16), false)
    Audio.play_sfx(Sfx.WARD)
    ScreenFx.shake(7.0, 0.2)
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
    # 원본색 위에 옅은 핏빛 — 실제 스프라이트가 너무 죽지 않게 0.3
    _tint_base = Color.WHITE.lerp(Color(1, 0.45, 0.40, 1), 0.3)
    if sprite:
        sprite.modulate = _tint_base
    SkillFx.boss_enrage(global_position)
    ScreenFx.shake(14.0, 0.32)


func _player() -> Node2D:
    var n := get_tree().get_first_node_in_group("player")
    return n as Node2D


func _on_hurt(damage: float, knockback: float, _attacker: Node) -> void:
    if _state == State.DEAD:
        return
    velocity.x += knockback * 0.5   # 보스는 잘 안 밀림(그래도 반응은 보이게)
    # 피격음은 공격자(플레이어) 측 _on_hitbox_landed 에서 1회 재생.
    FloatingNumber.spawn(get_tree().current_scene, global_position, "-%d" % int(damage), Color(1, 0.55, 0.50))
    _hit_jolt(signf(knockback))
    if sprite and not _attacking_blink:
        _attacking_blink = true
        sprite.modulate = Color(1.9, 1.9, 1.9, 1)   # 흰빛 번쩍(과노출)
        await get_tree().create_timer(0.1).timeout
        if is_instance_valid(sprite):
            sprite.modulate = _tint_base
        _attacking_blink = false


# 보스 피격 움찔 — 덩치가 크므로 얕게(밀리진 않아도 맞은 티는 나게).
func _hit_jolt(dir: float = 0.0) -> void:
    if sprite == null or not is_instance_valid(sprite):
        return
    if _spr_base_scale == Vector2.ZERO:
        _spr_base_scale = sprite.scale
    sprite.scale = _spr_base_scale * Vector2(1.12, 0.9)
    var tw := sprite.create_tween()
    tw.tween_property(sprite, "scale", _spr_base_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    if dir != 0.0:
        sprite.rotation = 0.1 * dir
        tw.parallel().tween_property(sprite, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_died() -> void:
    _state = State.DEAD
    _hide_warn()
    print("[%s] died" % display_name)
    Audio.play_sfx(Sfx.DIE)
    SkillFx.soul_ascend(global_position + Vector2(0, -16), true)   # 진혼: 원귀 두령도 달래 천도(성불)
    ScreenFx.shake(16.0, 0.5)
    if xp_reward > 0:
        PlayerStats.gain_xp(xp_reward)
    # 스코어 어택 — 보스 처치 점수 (xp_reward ×10, 대형 점수).
    var pts := xp_reward * 10
    ScoreManager.add_score(pts)
    FloatingNumber.spawn(get_tree().current_scene, global_position, "+%d" % pts, Color(1, 0.95, 0.6))
    if reward_item_id != "" and reward_item_qty > 0 and Inventory:
        Inventory.add(reward_item_id, reward_item_qty)
        FloatingNumber.spawn(get_tree().current_scene, global_position + Vector2(0, -32), "+%d %s" % [reward_item_qty, reward_item_id], Color(1, 0.85, 0.55))
    if quest_id_on_death != "" and quest_stage_on_death != "" and QuestManager.is_active(quest_id_on_death):
        QuestManager.set_stage(quest_id_on_death, quest_stage_on_death)
    if flag_on_death != "":
        Flags.set_flag(flag_on_death, true)
    # 즉시 제거하지 않고 잠깐 두면 사라지는 페이드를 줄 수 있지만 간단히 비활성화
    if attack_hitbox:
        attack_hitbox.collision_layer = 0
    if hurtbox:
        hurtbox.set_deferred("monitoring", false)   # 피격 신호 처리 중이라 지연 설정
    # death 애니메이션(6프레임)이 끝까지 보이도록 충분히 둔 뒤 제거
    await get_tree().create_timer(1.1).timeout
    if scene_on_death != "":
        # 최종 보스 — 처치 연출 후 다음 씬(엔딩 등)으로
        SceneManager.change_scene(scene_on_death)
        return
    queue_free()
