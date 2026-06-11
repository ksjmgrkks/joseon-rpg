extends CharacterVisual
class_name EnemyVisual
##
## 적/보스 비주얼 드라이버 — 부모(patroller.gd 또는 boss.gd)의 상태를 비침습 폴링.
## 노드 이름은 "Sprite2D" 로 유지해 부모 스크립트의 $Sprite2D(modulate/flip_h) 참조와 호환.
##
## 우선순위: death > (부모가 get_anim_hint 제공 시 그 값) > walk > idle
## 사망 후엔 마지막 프레임을 유지하고 더는 갱신하지 않는다.
##

const WALK_THRESHOLD := 8.0

var _dead: bool = false


func _process(_delta: float) -> void:
    if sprite_frames == null:
        return
    var p = get_parent()
    if p == null:
        return

    # 사망 — 1회 재생 후 정지
    var hp_zero := false
    if "health" in p and p.health != null:
        hp_zero = p.health.hp <= 0.0
    if hp_zero:
        if not _dead:
            _dead = true
            play_safe("death")
        return
    _dead = false

    # 부모가 명시적 애님 힌트를 주면(보스 telegraph/attack 등) 우선
    if p.has_method("get_anim_hint"):
        var hint: String = p.get_anim_hint()
        if hint != "":
            _apply_facing(p)
            play_safe(hint)
            return

    _apply_facing(p)
    if "velocity" in p and absf(p.velocity.x) > WALK_THRESHOLD:
        play_safe("walk")
    else:
        play_safe("idle")


func _apply_facing(p) -> void:
    # 부모가 _facing_right 를 노출하면 그걸, 아니면 velocity 부호로.
    if "_facing_right" in p:
        flip_h = not p._facing_right
    elif "velocity" in p and absf(p.velocity.x) > WALK_THRESHOLD:
        flip_h = p.velocity.x < 0.0
