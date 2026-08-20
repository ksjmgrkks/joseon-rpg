extends "res://scripts/enemies/boss.gd"
class_name DokkaebiChief
##
## 도깨비 대장 — 3스테이지(저잣거리) 보스. 방망이로 정면을 완전히 막아낸다.
## 그슨대(위장→성장→노출)와 달리 **매 타격마다** 판정한다: 방망이가 향한 쪽(정면)을 치면
## 칼이 대부분 튕겨나가고(칩 데미지만), 등 뒤(빈틈)를 치면 온전한 피해 + 보너스가 들어간다.
## → "부적으로 여는" 1회성 게이트가 아니라, 매 순간 위치를 골라야 하는 지속 기믹.
## 참고: https://namu.wiki/w/도깨비 (방망이를 든 우두머리, 씨름 설화의 "빈틈" 모티프를 차용)
##

@export var front_block_mult: float = 0.2   # 정면(방망이 막힘) — 칩 데미지만
@export var back_bonus_mult: float = 1.4    # 등 뒤(빈틈) — 온전한 피해 + 보너스

## 등 뒤(빈틈) 표식 — 늘 보여서, 플레이어가 어느 쪽으로 돌아가야 하는지 항상 읽힌다.
var _weak_marker: Label


func _ready() -> void:
	super._ready()
	water_entrance = false
	subtitle = "정면은 방망이가 막고, 등 뒤엔 빈틈이 있다"
	_make_weak_marker()


func _process(_delta: float) -> void:
	if _weak_marker == null or not is_instance_valid(_weak_marker):
		return
	# 빈틈은 항상 등 뒤(마주보는 방향의 반대쪽)에 있다.
	_weak_marker.position.x = -26.0 if _facing_right else 26.0


func _make_weak_marker() -> void:
	_weak_marker = Label.new()
	_weak_marker.text = "◆"
	_weak_marker.position = Vector2(-26, -60)
	_weak_marker.add_theme_font_size_override("font_size", 20)
	_weak_marker.add_theme_color_override("font_color", Color(0.55, 0.86, 0.95))
	_weak_marker.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_weak_marker.add_theme_constant_override("outline_size", 4)
	add_child(_weak_marker)
	var tw := _weak_marker.create_tween().set_loops()
	tw.tween_property(_weak_marker, "modulate:a", 0.35, 0.5)
	tw.tween_property(_weak_marker, "modulate:a", 1.0, 0.5)


## HealthComponent 는 이 보스에선 hurtbox_path 를 비워둔다(.tscn) — 즉 데미지는 여기서만
## 발생시킨다. 앞/뒤를 판정해 효과 데미지를 계산한 뒤 health.take_damage 를 직접 호출하고,
## 화면 연출(피격 넘버·움찔·번쩍임)은 부모 것을 effective 값으로 그대로 재사용한다.
func _on_hurt(damage: float, knockback: float, attacker: Node) -> void:
	if _state == State.DEAD:
		return
	var eff := damage * (back_bonus_mult if _is_back_hit(attacker) else front_block_mult)
	health.take_damage(eff, attacker)
	super._on_hurt(eff, knockback, attacker)


func _is_back_hit(attacker: Node) -> bool:
	if attacker == null or not (attacker is Node2D):
		return false
	var atk_on_right: bool = (attacker as Node2D).global_position.x >= global_position.x
	return atk_on_right != _facing_right


# ══════════ 도깨비 대장 전용 패턴(방망이) ══════════
# 돌진/부적 세례/소환(페이즈2)은 부모 것을 그대로 쓰되, 물기둥·밀물은 물 스테이지 전용이라 뺀다.
# 여기에 "방망이 강타" 하나를 더한다 — 넓은 정면 강타로 접근을 억제해, 등 뒤로 도는 선택을
# 유도한다(정면에서 버티면 이 패턴에 크게 맞는다).
const P_CLUB_SLAM := 100

@export_group("도깨비 패턴")
@export var club_slam_damage: float = 18.0
@export var club_slam_reach: float = 56.0


func _choose_pattern() -> int:
	var pool: Array = [Pattern.DASH, Pattern.DASH, Pattern.VOLLEY, P_CLUB_SLAM, P_CLUB_SLAM]
	if _phase >= 2:
		pool.append_array([Pattern.VOLLEY, P_CLUB_SLAM, Pattern.SUMMON])
	else:
		pool.append(Pattern.SUMMON)
	var picks: Array = []
	for x in pool:
		if x != _last_pattern:
			picks.append(x)
	if picks.is_empty():
		picks = pool
	return picks[randi() % picks.size()]


func _telegraph_time(pat: int) -> float:
	if pat == P_CLUB_SLAM:
		return 0.7 * _phase_mult_telegraph()
	return super._telegraph_time(pat)


func _warn_glyph(pat: int) -> String:
	if pat == P_CLUB_SLAM:
		return "●"
	return super._warn_glyph(pat)


func _warn_color(pat: int) -> Color:
	if pat == P_CLUB_SLAM:
		return Color(0.85, 0.62, 0.3)
	return super._warn_color(pat)


func _telegraph_fx(pat: int) -> void:
	if pat == P_CLUB_SLAM:
		SkillFx.charge_aura_tick(global_position + Vector2(0, -30.0), 2)
		return
	super._telegraph_fx(pat)


func _enter_attack() -> void:
	if _pattern == P_CLUB_SLAM:
		_hide_warn(); _state = State.ATTACK; _last_pattern = _pattern
		_state_timer = 0.5
		_do_club_slam()
		return
	super._enter_attack()


func _do_club_slam() -> void:
	var dir := 1.0 if _facing_right else -1.0
	Audio.play_sfx(Sfx.ATTACK)
	ScreenFx.shake(10.0, 0.25)
	if attack_hitbox:
		attack_hitbox.position.x = dir * club_slam_reach
		attack_hitbox.damage = club_slam_damage * (1.25 if _phase >= 2 else 1.0)
		attack_hitbox.knockback = attack_knockback * 1.3
		attack_hitbox.activate(0.3)
	SkillFx.impact(global_position + Vector2(dir * 40.0, -10.0), true)
