extends "res://scripts/enemies/patroller.gd"
class_name Geuseondae
##
## 그슨대 — 조선시대 운몽선 설화 속 그림자 요물. 아이 울음소리를 흉내내 유인하고,
## 칼(근접 공격)로는 죽지 않는다 — 오히려 맞을 때마다 점점 거대해진다.
## 가까이 다가가 그림자를 조사하거나 부적불로 비추면 본체가 드러나 비로소 진혼할 수 있다.
## 참고: https://namu.wiki/w/%EA%B7%B8%EC%8A%A8%EB%8C%80
##

@export var revealed_attack_damage: float = 9.0
@export var revealed_color: Color = Color(0.85, 0.25, 0.2, 1)
@export var max_threat: int = 4          # 이 이상 커지면 성장 멈춤(과한 비대화 방지)
@export var threat_attack_at: int = 2    # 이 위협도부터는 위장 중에도 공격 시작
## 조사(interact) 로 정체를 드러낼 수 있는 사거리 — 부적 대신 다가가서 버튼으로 확인한다.
@export var interact_range: float = 68.0

var _disguised: bool = true
var _threat: int = 0
var _in_interact_range: bool = false
var _interact_prompt: Label = null


func _ready() -> void:
    super._ready()
    attack_damage = 0.0                  # 위장 중엔 순수 유인 — 공격 안 함
    health.shield_charges = 999          # 칼이 안 먹힘(사실상 무한 방패) — 대신 맞을 때마다 커짐
    health.shield_broken.connect(_on_disguised_hit)
    _build_interact_prompt()


## "조사" — 조사 사거리 안에 들어오면 뜬다(위장 중일 때만).
func _build_interact_prompt() -> void:
    var lbl := Label.new()
    lbl.text = "조사"
    lbl.add_theme_font_size_override("font_size", 14)
    lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35))
    lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    lbl.add_theme_constant_override("outline_size", 4)
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.position = Vector2(-16, -66)
    lbl.z_index = 40
    lbl.visible = false
    add_child(lbl)
    _interact_prompt = lbl


func _physics_process(delta: float) -> void:
    _update_interact_prompt()
    if _disguised and _threat < threat_attack_at:
        return   # 아직 "안전한" 위장 단계 — 공격 판정 생략(이동은 StateMachine이 계속 처리)
    super._physics_process(delta)


func _update_interact_prompt() -> void:
    if not _disguised:
        if _in_interact_range:
            _in_interact_range = false
            if _interact_prompt:
                _interact_prompt.visible = false
        return
    var p := get_player()
    var near := p != null and global_position.distance_to((p as Node2D).global_position) <= interact_range
    if near != _in_interact_range:
        _in_interact_range = near
        if _interact_prompt:
            _interact_prompt.visible = near


## 조사 버튼 — 부적(스킬)을 맞히는 대신, 다가가서 눌러 정체를 드러낸다.
func _unhandled_input(event: InputEvent) -> void:
    if not _disguised or not _in_interact_range or _dying:
        return
    if Dialogue and Dialogue.is_active():
        return
    if event.is_action_pressed("interact"):
        _reveal()
        get_viewport().set_input_as_handled()


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


## TalismanShot 전용 훅. 반환값은 확인음/흔들림을 낼 유효 적중인가를 뜻한다.
func _on_talisman_hit(damage: float, attacker: Node) -> bool:
    aggro = true                # 부적으로 맞아도 쫓아온다(원거리 농성 방지)
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
    health.shield_charges = 0
    attack_damage = revealed_attack_damage
    if sprite and is_instance_valid(sprite):
        sprite.scale = _spr_base_scale     # 정체를 드러내며 원래 크기로 — 부풀린 그림자였을 뿐
        sprite.modulate = revealed_color
        SkillFx.hit_flash(sprite, Color.WHITE, 0.25)
    SkillFx.impact(global_position + Vector2(0, -16), false)
    Audio.play_sfx(Sfx.HIT, 3.0)
