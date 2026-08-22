extends "res://scripts/enemies/boss.gd"
class_name Sangyeogwi
## 빈 상여에 맺힌 4스테이지 보스. 모든 공격을 세 번의 종소리로 먼저 알린다.
## 세 번째 종 직후 공격이 시작되어, 화면을 보지 못한 순간에도 회피 박자를 익힐 수 있다.

const P_POLE_SWEEP := 100
var _bell_sequence: int = 0


func _choose_pattern() -> int:
    var pool: Array = [Pattern.DASH, Pattern.DASH, Pattern.VOLLEY, P_POLE_SWEEP, P_POLE_SWEEP]
    if _phase >= 2:
        pool.append_array([Pattern.VOLLEY, P_POLE_SWEEP, Pattern.SUMMON])
    var picks: Array = []
    for value in pool:
        if value != _last_pattern:
            picks.append(value)
    if picks.is_empty():
        picks = pool
    return picks[randi() % picks.size()]


func _telegraph_time(_pat: int) -> float:
    return 1.2 * _phase_mult_telegraph()


func _warn_glyph(pat: int) -> String:
    if pat == P_POLE_SWEEP:
        return "三"
    return super._warn_glyph(pat)


func _warn_color(_pat: int) -> Color:
    return Color(0.84, 0.9, 1.0)


func _telegraph_fx(pat: int) -> void:
    _bell_sequence += 1
    _ring_three_bells(_bell_sequence)
    match pat:
        Pattern.DASH:
            var dir := 1.0 if _facing_right else -1.0
            SkillFx.ground_shock(global_position + Vector2(dir * 48.0, 0), 150.0)
        Pattern.VOLLEY:
            SkillFx.charge_aura_tick(global_position + Vector2(0, -58.0), 2)
        Pattern.SUMMON:
            SkillFx.charge_aura_tick(global_position + Vector2(0, -46.0), 2)
        P_POLE_SWEEP:
            SkillFx.charge_aura_tick(global_position + Vector2(0, -40.0), 3)


func _ring_three_bells(sequence: int) -> void:
    var interval := _telegraph_time(_pattern) / 3.0
    for i in range(3):
        if sequence != _bell_sequence or _state == State.DEAD:
            return
        if _warn:
            _warn.text = ["一", "二", "三"][i]
        Audio.play_sfx(Sfx.FUNERAL_BELL, -1.0 + float(i), 0.94 + float(i) * 0.04)
        SkillFx.charge_aura_tick(global_position + Vector2(0, -52.0), i + 1)
        await get_tree().create_timer(interval).timeout


func _enter_attack() -> void:
    if _pattern != P_POLE_SWEEP:
        super._enter_attack()
        return
    _hide_warn()
    _state = State.ATTACK
    _last_pattern = _pattern
    _state_timer = 0.8
    ClubWhirl.spawn(get_parent(), global_position + Vector2(0, -18.0),
        19.0 * (1.18 if _phase >= 2 else 1.0), 0.42, 0.62)
    Audio.play_sfx(Sfx.ATTACK, 1.5, 0.84)
    ScreenFx.shake(8.0, 0.18)
