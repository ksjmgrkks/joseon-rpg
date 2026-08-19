extends "res://scripts/enemies/boss.gd"
class_name GeuseondaeElder
##
## 그슨대 노괴(老怪) — 2스테이지(그슨대 숲) 보스. 숲 깊은 곳에 웅크린 늙은 그슨대.
## 위장 상태에선 칼이 먹히지 않고, 오히려 맞을 때마다 커진다(최대체력·공격력 배율 상승).
## 부적(TalismanShot)으로 정체를 드러내야 비로소 real 데미지가 들어가고 진혼할 수 있다.
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
@export var revealed_foot_offset: float = -61.5

var _disguised: bool = true
var _threat: int = 0


func _ready() -> void:
	super._ready()
	water_entrance = false
	subtitle = "울음으로 부르고, 그림자로 삼킨다"
	attack_damage = 0.0                # 위장 중엔 순수 유인 — 패턴 잠금 해제 전엔 공격 안 함
	health.shield_charges = 999        # 칼이 안 먹힘 — 대신 맞을 때마다 커짐
	health.shield_broken.connect(_on_disguised_hit)


## 물기둥/밀물은 물 스테이지 전용 연출이라 이 던전(그슨대 숲)엔 안 어울려 제외.
## 돌진(그림자 손톱) · 부적 세례(영혼 구슬) · 소환(작은 그슨대들을 불러모음)만 사용.
func _choose_pattern() -> int:
	var pool: Array = [Pattern.DASH, Pattern.DASH, Pattern.VOLLEY, Pattern.SUMMON]
	if _phase >= 2:
		pool.append_array([Pattern.DASH, Pattern.VOLLEY, Pattern.SUMMON, Pattern.SUMMON])
	var picks: Array = []
	for x in pool:
		if x != _last_pattern:
			picks.append(x)
	if picks.is_empty():
		picks = pool
	return picks[randi() % picks.size()]


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


## TalismanShot 전용 훅 — 부적(빛)에만 반응한다. 잡몹 그슨대와 동일한 규약.
func _on_talisman_hit(damage: float, attacker: Node) -> void:
	if _disguised:
		_reveal()
		return
	health.take_damage(damage, attacker)


func _reveal() -> void:
	_disguised = false
	var mult := 1.0 + threat_hp_mult * float(_threat)
	health.max_hp *= mult
	health.hp = health.max_hp
	health.hp_changed.emit(health.hp, health.max_hp)
	health.shield_charges = 0
	attack_damage = revealed_attack_damage * (1.0 + threat_dmg_mult * float(_threat))
	if sprite and is_instance_valid(sprite):
		sprite.set_sheet(revealed_sheet, revealed_sprite_scale, revealed_foot_offset)
		sprite.modulate = revealed_color
		SkillFx.hit_flash(sprite, Color.WHITE, 0.3)
	SkillFx.impact(global_position + Vector2(0, -20), true)
	ScreenFx.shake(12.0 + float(_threat) * 2.0, 0.3)
	Audio.play_sfx(Sfx.WARD)
