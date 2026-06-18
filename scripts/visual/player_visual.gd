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
        foot_offset = -28.0   # 92px PixelLab 프레임: 발 y=90, 콜리전 바닥 +16 정렬
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
        play_safe("jump")
        # 수직 속도로 프레임 수동 선택: 상승(0) → 정점(1) → 하강(2)
        if sprite_frames.has_animation("jump"):
            var jc := sprite_frames.get_frame_count("jump")
            if jc >= 3:
                if p.velocity.y < -120.0:   frame = 0   # 빠르게 상승
                elif p.velocity.y > 120.0:  frame = 2   # 하강
                else:                       frame = 1   # 정점 근처
            elif jc >= 2:
                frame = 0 if p.velocity.y < 0.0 else 1
            pause()
        return

    if absf(p.velocity.x) > 5.0:
        play_safe("walk")
        return

    play_safe("idle")
