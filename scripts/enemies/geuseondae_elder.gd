extends "res://scripts/enemies/boss.gd"
class_name GeuseondaeElder
##
## 그슨대 노괴(老怪) — 2스테이지(그슨대 숲) 보스. 숲 깊은 곳에 웅크린 늙은 그슨대.
## 위장 상태에선 칼이 먹히지 않고, 오히려 맞을 때마다 커진다(최대체력·공격력 배율 상승).
## 가까이 다가가 그림자를 조사하거나 부적불로 비추면 정체가 드러나고 진혼할 수 있다.
## 잡몹 Geuseondae(scripts/enemies/geuseondae.gd)와 같은 규칙 — 참고: https://namu.wiki/w/그슨대
##

@export var max_threat: int = 5
@export var threat_attack_at: int = 2      # 이 위협도부터는 위장 중에도 패턴을 쓰기 시작
@export var threat_hp_mult: float = 0.22   # 위협도 1당 최대체력 배율 증가(드러난 뒤 적용)
@export var threat_dmg_mult: float = 0.15  # 위협도 1당 공격력 배율 증가
@export var revealed_attack_damage: float = 16.0
@export var revealed_color: Color = Color(1, 1, 1, 1)
@export var revealed_sheet: String = "enemies/geuseondae_elder_shadow"
@export var revealed_sprite_scale: float = 1.0
## 정체(그림자) 시트의 발 정렬. 시트 실측값 기준 — 어긋나면 보스가 공중에 뜬다.
## (2026-08-19: 그림자 시트를 PixelLab 로 재제작 170x247·발끝 247. 정체 변신 때
##  콜리전도 60x120 으로 키우므로 half=60 → foot_offset = 60 - 123.5 = -63.5)
@export var revealed_foot_offset: float = -63.5
## 정체는 위장(소년)보다 훨씬 크다 — 변신 순간 몸·피격 판정도 같이 키운다.
@export var revealed_body_size: Vector2 = Vector2(60, 120)
@export var revealed_hurt_size: Vector2 = Vector2(76, 150)

## 조사(interact) 로 정체를 드러낼 수 있는 사거리 — 부적 대신 다가가서 버튼으로 확인한다.
@export var interact_range: float = 78.0

var _disguised: bool = true
var _threat: int = 0
var _in_interact_range: bool = false
var _interact_prompt: Label = null


func _ready() -> void:
	super._ready()
	water_entrance = false
	subtitle = "울음으로 부르고, 그림자로 삼킨다"
	attack_damage = 0.0                # 위장 중엔 순수 유인 — 패턴 잠금 해제 전엔 공격 안 함
	health.shield_charges = 999        # 칼이 안 먹힘 — 대신 맞을 때마다 커짐
	health.shield_broken.connect(_on_disguised_hit)
	_build_interact_prompt()


## "조사" — 조사 사거리 안에 들어오면 뜬다(위장 중일 때만).
func _build_interact_prompt() -> void:
	var lbl := Label.new()
	lbl.text = "조사"
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-20, -86)
	lbl.z_index = 40
	lbl.visible = false
	add_child(lbl)
	_interact_prompt = lbl


func _physics_process(delta: float) -> void:
	_update_interact_prompt()
	super._physics_process(delta)


func _update_interact_prompt() -> void:
	if not _disguised or _state == State.DEAD:
		if _in_interact_range:
			_in_interact_range = false
			if _interact_prompt:
				_interact_prompt.visible = false
		return
	var p := _player()
	var near := p != null and global_position.distance_to(p.global_position) <= interact_range
	if near != _in_interact_range:
		_in_interact_range = near
		if _interact_prompt:
			_interact_prompt.visible = near


## 조사 버튼 — 부적(스킬)을 맞히는 대신, 다가가서 눌러 정체를 드러낸다.
func _unhandled_input(event: InputEvent) -> void:
	if not _disguised or not _in_interact_range or _state == State.DEAD:
		return
	if Dialogue and Dialogue.is_active():
		return
	if event.is_action_pressed("interact"):
		_reveal()
		get_viewport().set_input_as_handled()


## 아직 "안전한" 위장 단계(위협도 < threat_attack_at)면 어떤 패턴도 꺼내지 않는다 —
## 플레이어가 계속 접근해도 그저 서서 운다(유인). 위협도가 쌓이면 그때부터 패턴 시작.
func _enter_telegraph() -> void:
	if _disguised and _threat < threat_attack_at:
		return
	super._enter_telegraph()


## 위장 상태에서 근접/광역 공격에 맞았을 때(HealthComponent.shield_broken) — 데미지 대신 성장.
func _on_disguised_hit() -> void:
	if not _disguised:
		return
	_threat = mini(_threat + 1, max_threat)
	health.shield_charges = 999        # 재충전 — 위장 중엔 절대 죽지 않음
	if sprite and is_instance_valid(sprite):
		sprite.scale = _spr_base_scale * (1.0 + 0.10 * _threat)
		sprite.modulate = sprite.modulate.lerp(Color(0.22, 0.2, 0.28), 0.3)
	ScreenFx.shake(3.0 + _threat, 0.12)


## 위장 중엔 기본 보스 피격 연출(데미지 숫자·번쩍임·넉백)을 생략 — 칼이 안 먹히니
## 아무 반응 없이 그대로 서 있는 쪽이(그리고 커지는 쪽이) 더 섬뜩하다.
func _on_hurt(damage: float, knockback: float, attacker: Node) -> void:
	if _disguised:
		return
	super._on_hurt(damage, knockback, attacker)


## TalismanShot 전용 훅. 반환값은 확인음/흔들림을 낼 유효 적중인가를 뜻한다.
func _on_talisman_hit(damage: float, attacker: Node) -> bool:
	if _disguised:
		_reveal()
		return true
	# 히트박스 경로로 — 부적 명중도 근접타와 같은 반응(숫자·섬광·움찔)이 나오게.
	var kb := 140.0
	if attacker is Node2D:
		kb = 140.0 * signf(global_position.x - (attacker as Node2D).global_position.x)
	return Hurtbox.deal(self, damage, kb, attacker)


func _reveal() -> void:
	_disguised = false
	_in_interact_range = false
	if _interact_prompt:
		_interact_prompt.visible = false
	var mult := 1.0 + threat_hp_mult * float(_threat)
	health.max_hp *= mult
	health.hp = health.max_hp
	health.hp_changed.emit(health.hp, health.max_hp)
	health.shield_charges = 0
	attack_damage = revealed_attack_damage * (1.0 + threat_dmg_mult * float(_threat))
	_grow_collision()
	if sprite and is_instance_valid(sprite):
		sprite.set_sheet(revealed_sheet, revealed_sprite_scale, revealed_foot_offset)
		sprite.modulate = revealed_color
		SkillFx.hit_flash(sprite, Color.WHITE, 0.3)
	SkillFx.impact(global_position + Vector2(0, -20), true)
	ScreenFx.shake(12.0 + float(_threat) * 2.0, 0.3)
	Audio.play_sfx(Sfx.WARD)


## 정체를 드러내면 덩치가 확 커진다 — 스프라이트만 키우면 판정이 발밑에만 남아
## "때려도 안 맞는" 느낌이 되므로, 몸·피격 판정도 같이 키운다.
func _grow_collision() -> void:
	var body := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body != null and body.shape is RectangleShape2D:
		var s := (body.shape as RectangleShape2D).duplicate() as RectangleShape2D
		s.size = revealed_body_size
		body.shape = s
	var hb := get_node_or_null("Hurtbox/HurtboxShape") as CollisionShape2D
	if hb != null and hb.shape is RectangleShape2D:
		var hs := (hb.shape as RectangleShape2D).duplicate() as RectangleShape2D
		hs.size = revealed_hurt_size
		hb.shape = hs
		hb.position = Vector2(0, -(revealed_hurt_size.y - revealed_body_size.y) * 0.5)
	# HP 바는 붙을 때 '위장' 시트를 재서 자리를 잡았다 — 정체는 훨씬 크므로 다시 재게 한다
	# (안 하면 거대 그림자의 몸통 한가운데에 바가 걸린다).
	for c in get_children():
		if c is EnemyHpBar:
			(c as EnemyHpBar).call_deferred("_fit_to_host", self, true)


# ══════════ 그슨대 전용 패턴 (2026-08-19 신설) ══════════
#
# 물 보스에게서 물려받은 돌진/부적/소환만으로는 이 보스의 정체성이 안 산다.
# 그슨대는 **그림자**이고 **울음으로 부르며** **베일수록 자라는** 것이다. 그 셋을 패턴으로:
#   · 그림자 늪  — 바닥에 검은 웅덩이를 퍼뜨려 발을 묶는다(직접 피해보다 '가둠'이 목적)
#   · 갈퀴 훑기  — 긴 그림자 팔이 지면을 훑는다. **점프로만** 넘는다
#   · 암전 강습  — 화면이 캄캄해진 사이 플레이어 뒤로 돌아가 내리찍는다. 예고 표식을 보고 피한다
#
# 부모(boss.gd)의 Pattern enum 을 확장할 수 없으므로, 부모가 안 쓰는 큰 정수를 전용 값으로 쓴다.
const P_SHADOW_POOL := 100
const P_CLAW_SWEEP := 101
const P_BLACKOUT := 102

@export_group("그슨대 패턴")
## 그림자 늪 — 한 번에 퍼뜨릴 웅덩이 수와 지속 피해.
@export var pool_count: int = 3
@export var pool_damage: float = 8.0
## 갈퀴 훑기 — 지면을 훑는 속도·피해.
@export var claw_damage: float = 14.0
@export var claw_speed: float = 330.0
## 암전 강습 — 어둠이 깔린 시간과 내리찍기 피해.
@export var blackout_time: float = 0.75
@export var blackout_damage: float = 22.0


## 패턴 선택 — 부모 것(돌진/부적/소환)에 전용 패턴 셋을 섞는다.
## 위장 단계에선 부모가 이미 막고 있으므로 여기선 순수 선택만 담당.
func _choose_pattern() -> int:
	var pool: Array = [Pattern.DASH, Pattern.VOLLEY, P_SHADOW_POOL, P_CLAW_SWEEP]
	if _phase >= 2:
		pool.append_array([P_BLACKOUT, P_CLAW_SWEEP, P_SHADOW_POOL, Pattern.SUMMON, P_BLACKOUT])
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
	match pat:
		P_SHADOW_POOL: return 0.5 * _phase_mult_telegraph()
		P_CLAW_SWEEP:  return 0.62 * _phase_mult_telegraph()
		P_BLACKOUT:    return 0.45 * _phase_mult_telegraph()
	return super._telegraph_time(pat)


func _warn_glyph(pat: int) -> String:
	match pat:
		P_SHADOW_POOL: return "●"
		P_CLAW_SWEEP:  return "〜"
		P_BLACKOUT:    return "×"
	return super._warn_glyph(pat)


func _warn_color(pat: int) -> Color:
	match pat:
		P_SHADOW_POOL: return Color(0.55, 0.42, 0.72)
		P_CLAW_SWEEP:  return Color(0.72, 0.70, 0.78)
		P_BLACKOUT:    return Color(0.95, 0.95, 1.0)
	return super._warn_color(pat)


func _telegraph_fx(pat: int) -> void:
	match pat:
		P_SHADOW_POOL, P_CLAW_SWEEP, P_BLACKOUT:
			# 그림자가 몸으로 모여든다 — 물 보스의 물 연출 대신 어둠으로.
			SkillFx.shadow_gather(global_position, _telegraph_time(pat) * 0.9)
		_:
			super._telegraph_fx(pat)


func _enter_attack() -> void:
	match _pattern:
		P_SHADOW_POOL:
			_hide_warn(); _state = State.ATTACK; _last_pattern = _pattern
			_state_timer = 0.8
			_do_shadow_pool()
		P_CLAW_SWEEP:
			_hide_warn(); _state = State.ATTACK; _last_pattern = _pattern
			_state_timer = 0.6
			_do_claw_sweep()
		P_BLACKOUT:
			_hide_warn(); _state = State.ATTACK; _last_pattern = _pattern
			_state_timer = blackout_time + 0.5
			_do_blackout()
		_:
			super._enter_attack()


## ① 그림자 늪 — 플레이어 발밑과 그 좌우로 웅덩이를 퍼뜨린다.
func _do_shadow_pool() -> void:
	var host := get_parent()
	var p := _player()
	if host == null or p == null:
		return
	var base_x: float = p.global_position.x
	var ground_y: float = global_position.y + 24.0
	var n := maxi(1, pool_count + (1 if _phase >= 2 else 0))
	for i in range(n):
		var off := 0.0 if i == 0 else float(i) * 120.0 * (1.0 if i % 2 == 1 else -1.0)
		ShadowPool.spawn(host, Vector2(base_x + off, ground_y), pool_damage, 0.5 + float(i) * 0.12)
	Audio.play_sfx(Sfx.WARD)
	ScreenFx.shake(4.0, 0.15)


## ② 갈퀴 훑기 — 긴 그림자 팔이 지면을 훑고 지나간다. 점프로만 넘는다.
func _do_claw_sweep() -> void:
	var host := get_parent()
	if host == null:
		return
	var dir := 1.0 if _facing_right else -1.0
	ShadowClaw.spawn(host, Vector2(global_position.x + dir * 40.0, global_position.y + 24.0),
		dir, claw_damage, claw_speed)
	if _phase >= 2:
		# 페이즈 2 — 뒤쪽에서도 한 손 더. 점프 타이밍을 두 번 잡아야 한다.
		await get_tree().create_timer(0.35).timeout
		if is_instance_valid(self) and _state != State.DEAD:
			ShadowClaw.spawn(host, Vector2(global_position.x - dir * 40.0, global_position.y + 24.0),
				-dir, claw_damage, claw_speed * 0.9)
	Audio.play_sfx(Sfx.ATTACK)
	ScreenFx.shake(6.0, 0.18)


## ③ 암전 강습 — 화면이 캄캄해진 사이 플레이어 뒤로 돌아가 내리찍는다.
## 어둠 속에서도 **착지 지점에 표식**이 떠서, 보고 피할 수 있다(무조건 맞는 패턴 금지).
func _do_blackout() -> void:
	var host := get_parent()
	var p := _player()
	if host == null or p == null:
		return
	SkillFx.blackout(blackout_time)
	Audio.play_sfx(Sfx.WARD)
	await get_tree().create_timer(blackout_time * 0.45).timeout
	if not is_instance_valid(self) or _state == State.DEAD or not is_instance_valid(p):
		return
	# 플레이어 뒤편(등 뒤)으로 이동 — 화면 밖으로 나가지 않게 x 만 옮긴다.
	var behind := -1.0 if p.global_position.x >= global_position.x else 1.0
	var target := p.global_position.x + behind * 120.0
	global_position.x = target
	_facing_right = p.global_position.x >= global_position.x
	SkillFx.shadow_burst(global_position + Vector2(0, -30.0))
	# 착지 표식 — 어둠 속에서도 이것만은 보인다
	SkillFx.strike_marker(Vector2(global_position.x, global_position.y + 24.0), blackout_time * 0.55)
	await get_tree().create_timer(blackout_time * 0.55).timeout
	if not is_instance_valid(self) or _state == State.DEAD:
		return
	# 내리찍기 — 표식 자리에 판정
	if attack_hitbox:
		attack_hitbox.position.x = 0.0
		attack_hitbox.damage = blackout_damage * (1.0 + threat_dmg_mult * float(_threat))
		attack_hitbox.knockback = attack_knockback
		attack_hitbox.activate(0.22)
	SkillFx.shadow_slam(Vector2(global_position.x, global_position.y + 24.0))
	ScreenFx.shake(14.0, 0.35)
	ScreenFx.rumble(70)
	Audio.play_sfx(Sfx.HIT, 2.0)
