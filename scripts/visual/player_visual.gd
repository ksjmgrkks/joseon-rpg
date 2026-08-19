extends CharacterVisual
##
## 주인공 비주얼 드라이버 — player.gd 상태를 매 프레임 읽어 애니메이션 선택.
## player.gd 를 침습하지 않는다 (상태 변수만 읽음).
##
## 우선순위: death > dodge > attack(콤보별) > charge > jump > walk > idle
##

var _dead: bool = false


func _ready() -> void:
    # 외부 제작(AI) 커스텀 스프라이트 우선 — 있으면 그걸 쓰고, 없으면 코드 생성 폴백.
    if SpriteDb.frames("protagonist_custom") != null:
        sheet = "protagonist_custom"
        foot_offset = -78.0   # 256px PixelLab 프레임(224px 콘텐츠+중앙패딩): 발 y=222, 콜리전 바닥 +16 정렬 (2026-08-19 크기/퀄리티 개선)
    else:
        sheet = "protagonist"
    super._ready()


func _process(_delta: float) -> void:
    if sprite_frames == null:
        return
    var p = get_parent()
    if p == null or not (p is CharacterBody2D):
        return

    flip_h = not p._facing_right

    # 사망 — 1회 재생 후 마지막 프레임 유지
    if p.health and p.health.hp <= 0.0:
        if not _dead:
            _dead = true
            play_safe("death")
        return
    _dead = false

    if p._dodging:
        play_safe("dodge")
        return

    if p._attacking:
        match int(p._combo_step):
            2: play_safe("attack2")
            3: play_safe("attack3")
            1: play_safe("attack")
            _: play_safe("attack3")   # 콤보 0 인데 공격 중 = 차지 강타
        return

    # 차지 모으는 중 (임계 이상 홀드)
    if p._hold_time >= p.CHARGE_THRESHOLD:
        play_safe("charge")
        return

    if not p.is_on_floor():
        # 점프가 이제 탭/홀드 관계없이 항상 같은 궤적(풀 점프)이라 체공 시간이 일정하다 —
        # 정지 프레임을 속도로 골라 붙이는 대신 점프 애니를 그냥 시간에 맞춰 재생한다.
        # 착지 전에 다 재생되면 마지막 프레임(착지 자세)에서 자연히 멈춘다.
        play_safe("jump")
        return

    if absf(p.velocity.x) > 5.0:
        play_safe("walk")
        return

    play_safe("idle")
