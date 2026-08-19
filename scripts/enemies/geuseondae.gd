extends "res://scripts/enemies/patroller.gd"
class_name Geuseondae
##
## 그슨대 — 조선시대 운몽선 설화 속 그림자 요물. 아이 울음소리를 흉내내 유인하고,
## 칼(근접 공격)로는 죽지 않는다 — 오히려 맞을 때마다 점점 거대해진다.
## 여럿이 횃불(부적=TalismanShot)로 덤벼야 그림자 본체가 드러나 비로소 진혼할 수 있다.
## 참고: https://namu.wiki/w/%EA%B7%B8%EC%8A%A8%EB%8C%80
##

@export var revealed_attack_damage: float = 9.0
@export var revealed_color: Color = Color(0.85, 0.25, 0.2, 1)
@export var max_threat: int = 4          # 이 이상 커지면 성장 멈춤(과한 비대화 방지)
@export var threat_attack_at: int = 2    # 이 위협도부터는 위장 중에도 공격 시작

var _disguised: bool = true
var _threat: int = 0


func _ready() -> void:
    super._ready()
    attack_damage = 0.0                  # 위장 중엔 순수 유인 — 공격 안 함
    health.shield_charges = 999          # 칼이 안 먹힘(사실상 무한 방패) — 대신 맞을 때마다 커짐
    health.shield_broken.connect(_on_disguised_hit)


func _physics_process(delta: float) -> void:
    if _disguised and _threat < threat_attack_at:
        return   # 아직 "안전한" 위장 단계 — 공격 판정 생략(이동은 StateMachine이 계속 처리)
    super._physics_process(delta)


## 위장 상태에서 근접/광역 공격에 맞았을 때(HealthComponent.shield_broken) — 데미지 대신 성장.
func _on_disguised_hit() -> void:
    if not _disguised:
        return
    _threat = mini(_threat + 1, max_threat)
    health.shield_charges = 999          # 재충전 — 위장 중엔 절대 죽지 않음
    if sprite and is_instance_valid(sprite):
        sprite.scale = _spr_base_scale * (1.0 + 0.12 * _threat)
        sprite.modulate = sprite.modulate.lerp(Color(0.25, 0.22, 0.3), 0.35)
    if _threat >= threat_attack_at:
        attack_damage = 4.0 + 2.0 * _threat   # 커질수록 더 위험 — "베려 할수록 위험해진다"
    ScreenFx.shake(2.0 + _threat, 0.1)


## 위장 중엔 패트롤러의 기본 피격 연출(경직/넉백/데미지 숫자)을 생략 — 칼이 안 먹히니
## 아무 반응 없이 그대로 서 있는 쪽이(그리고 커지는 쪽이) 더 섬뜩하다.
func _on_hurt(damage: float, knockback: float, attacker: Node) -> void:
    if _disguised:
        return
    super._on_hurt(damage, knockback, attacker)


## TalismanShot 전용 훅 — talisman_shot.gd 가 body 에 이 메서드가 있으면 데미지 대신 호출.
func _on_talisman_hit(damage: float, attacker: Node) -> void:
    if _disguised:
        _reveal()
        return
    health.take_damage(damage, attacker)


func _reveal() -> void:
    _disguised = false
    health.shield_charges = 0
    attack_damage = revealed_attack_damage
    if sprite and is_instance_valid(sprite):
        sprite.scale = _spr_base_scale     # 정체를 드러내며 원래 크기로 — 부풀린 그림자였을 뿐
        sprite.modulate = revealed_color
        SkillFx.hit_flash(sprite, Color.WHITE, 0.25)
    SkillFx.impact(global_position + Vector2(0, -16), false)
    Audio.play_sfx(Sfx.HIT, 3.0)
