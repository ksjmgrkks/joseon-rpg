extends Node
##
## 타격감·적 HP 바 검증 (헤드리스).
## 실행: `godot --headless res://tests/test_hit_feel.tscn`
##
## 1) HP 바가 적 스프라이트 **머리 위**에 걸리는가 (몸통 가운데 아님)
## 2) 바가 충분히 두꺼운가 (얇은 4px 문제 회귀 방지)
## 3) 피격 시 잔상(lag) 바가 실제 바보다 뒤에 남는가 (깎인 양이 보임)
## 4) 피격 시 넉백이 배수로 커져 실제로 뒤로 밀리는가 + 경직이 걸리는가
## 5) 보스 바가 더 두꺼운가
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_hit_feel ===")
    var results: Array[Dictionary] = []
    results.append(await _check_bar_above_head())
    results.append(await _check_bar_thickness())
    results.append(await _check_lag_bar())
    results.append(await _check_knockback())
    results.append(await _check_boss_bar())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _spawn(path: String) -> Node2D:
    var e: Node2D = load(path).instantiate()
    add_child(e)
    e.global_position = Vector2(400, 400)
    await get_tree().process_frame
    return e


func _find_bar(host: Node) -> EnemyHpBar:
    for c in host.get_children():
        if c is EnemyHpBar:
            return c as EnemyHpBar
    return null


# 스프라이트 프레임 상단(머리끝) y — enemy_hp_bar 와 같은 계산.
func _sprite_top(host: Node) -> float:
    var a := host.get_node_or_null("Sprite2D") as AnimatedSprite2D
    if a == null or a.sprite_frames == null:
        return 0.0
    var anim := a.animation if a.sprite_frames.has_animation(a.animation) else "idle"
    if not a.sprite_frames.has_animation(anim) or a.sprite_frames.get_frame_count(anim) == 0:
        return 0.0
    var tex := a.sprite_frames.get_frame_texture(anim, 0)
    if tex == null:
        return 0.0
    return a.position.y + (a.offset.y - tex.get_height() / 2.0) * absf(a.scale.y)


func _check_bar_above_head() -> Dictionary:
    var e := await _spawn("res://scenes/enemies/DrownedHeavy.tscn")
    var bar := _find_bar(e)
    if bar == null:
        e.queue_free()
        return { "name": "bar_above_head", "status": FAIL, "reason": "EnemyHpBar 없음" }
    var top := _sprite_top(e)
    var bar_bottom: float = bar.position.y + bar._height
    var ok := top < 0.0 and bar_bottom <= top    # 바 아래선이 머리끝보다 위
    var reason := "" if ok else "bar_bottom=%.1f, sprite_top=%.1f (머리 위가 아님)" % [bar_bottom, top]
    e.queue_free()
    return { "name": "bar_above_head", "status": PASS if ok else FAIL, "reason": reason }


func _check_bar_thickness() -> Dictionary:
    var e := await _spawn("res://scenes/enemies/DrownedSwarm.tscn")
    var bar := _find_bar(e)
    if bar == null:
        e.queue_free()
        return { "name": "bar_thickness", "status": FAIL, "reason": "EnemyHpBar 없음" }
    var ok: bool = bar._height >= 7.0 and bar._width >= EnemyHpBar.MIN_WIDTH
    var reason := "" if ok else "height=%.1f width=%.1f (너무 얇거나 좁음)" % [bar._height, bar._width]
    e.queue_free()
    return { "name": "bar_thickness", "status": PASS if ok else FAIL, "reason": reason }


func _check_lag_bar() -> Dictionary:
    var e := await _spawn("res://scenes/enemies/DrownedSwarm.tscn")
    var bar := _find_bar(e)
    var hc := e.get_node_or_null("HealthComponent") as HealthComponent
    if bar == null or hc == null:
        e.queue_free()
        return { "name": "lag_bar", "status": FAIL, "reason": "바 또는 HealthComponent 없음" }
    hc.take_damage(hc.max_hp * 0.5)
    await get_tree().process_frame
    var fill: float = bar._bar.size.x
    var lag: float = bar._lag.size.x
    var ok: bool = fill < bar._width and lag > fill and bar.visible
    var reason := "" if ok else "fill=%.1f lag=%.1f width=%.1f visible=%s" % [fill, lag, bar._width, str(bar.visible)]
    e.queue_free()
    return { "name": "lag_bar", "status": PASS if ok else FAIL, "reason": reason }


func _check_knockback() -> Dictionary:
    var e := await _spawn("res://scenes/enemies/DrownedSwarm.tscn")
    var hurtbox := e.get_node_or_null("Hurtbox") as Hurtbox
    if hurtbox == null:
        e.queue_free()
        return { "name": "knockback_and_hitstun", "status": FAIL, "reason": "Hurtbox 없음" }
    hurtbox.hurt.emit(10.0, 300.0, null)
    await get_tree().process_frame
    var body := e as CharacterBody2D
    if body == null:
        e.queue_free()
        return { "name": "knockback_and_hitstun", "status": FAIL, "reason": "적이 CharacterBody2D 가 아님" }
    var vx: float = body.velocity.x
    var stun: float = float(body.get("hitstun"))
    var ok := vx >= 300.0 * 1.5 and stun >= 0.18
    var reason := "" if ok else "velocity.x=%.1f (기대 >=450), hitstun=%.2f (기대 >=0.18)" % [vx, stun]
    e.queue_free()
    return { "name": "knockback_and_hitstun", "status": PASS if ok else FAIL, "reason": reason }


func _check_boss_bar() -> Dictionary:
    var e := await _spawn("res://scenes/enemies/FloodWraith.tscn")
    var bar := _find_bar(e)
    if bar == null:
        e.queue_free()
        return { "name": "boss_bar_bigger", "status": FAIL, "reason": "EnemyHpBar 없음" }
    var top := _sprite_top(e)
    var ok: bool = bar._height >= EnemyHpBar.BOSS_BAR_HEIGHT and bar._width >= 64.0 and (bar.position.y + bar._height) <= top
    var reason := "" if ok else "height=%.1f width=%.1f pos.y=%.1f top=%.1f" % [bar._height, bar._width, bar.position.y, top]
    e.queue_free()
    return { "name": "boss_bar_bigger", "status": PASS if ok else FAIL, "reason": reason }
