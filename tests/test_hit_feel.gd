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
## 6) Hitbox 유효 명중 신호가 실제 HP 감소에만 발신되는가
## 7) 근접·부적·궁극기가 공통 HitFeedback 경로를 쓰는가
## 8) 유효 명중 카메라 피드백이 저강도 방향성 펀치인가
## 9) 연속 카메라 펀치 후 기준 offset으로 정확히 복귀하는가
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
    results.append(await _check_valid_hit_signal())
    results.append(_check_all_player_attack_feedback_routes())
    results.append(_check_camera_feedback_profile())
    results.append(await _check_camera_bump_rebases())

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
    var anim: StringName = a.animation if a.sprite_frames.has_animation(a.animation) else &"idle"
    if not a.sprite_frames.has_animation(anim) or a.sprite_frames.get_frame_count(anim) == 0:
        return 0.0
    var tex := a.sprite_frames.get_frame_texture(anim, 0)
    if tex == null:
        return 0.0
    var rect := EnemyHpBar._opaque_rect(tex)
    return a.position.y + (a.offset.y - tex.get_height() / 2.0 + rect.position.y) * absf(a.scale.y)


func _check_bar_above_head() -> Dictionary:
    var e := await _spawn("res://scenes/enemies/Mulgwisin.tscn")
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
    var e := await _spawn("res://scenes/enemies/Dueoksini.tscn")
    var bar := _find_bar(e)
    if bar == null:
        e.queue_free()
        return { "name": "bar_thickness", "status": FAIL, "reason": "EnemyHpBar 없음" }
    var ok: bool = bar._height >= 7.0 and bar._width >= EnemyHpBar.MIN_WIDTH
    var reason := "" if ok else "height=%.1f width=%.1f (너무 얇거나 좁음)" % [bar._height, bar._width]
    e.queue_free()
    return { "name": "bar_thickness", "status": PASS if ok else FAIL, "reason": reason }


func _check_lag_bar() -> Dictionary:
    var e := await _spawn("res://scenes/enemies/Dueoksini.tscn")
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
    var e := await _spawn("res://scenes/enemies/Dueoksini.tscn")
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
    # KNOCK_RECEIVE 1.6→1.2→1.0(2026-08-18, 사용자 피드백으로 넉백 완화) — 넉백이 실제로 걸리는지만 확인.
    var ok := vx >= 300.0 * 0.9 and stun >= 0.18
    var reason := "" if ok else "velocity.x=%.1f (기대 >=270), hitstun=%.2f (기대 >=0.18)" % [vx, stun]
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


func _check_valid_hit_signal() -> Dictionary:
    var attacker := Node2D.new()
    var hitbox := Hitbox.new()
    hitbox.damage = 10.0
    attacker.add_child(hitbox)
    add_child(attacker)
    var victim := Node2D.new()
    var hurtbox := Hurtbox.new()
    hurtbox.name = "Hurtbox"
    victim.add_child(hurtbox)
    var health := HealthComponent.new()
    health.name = "HealthComponent"
    health.max_hp = 30.0
    health.hurtbox_path = NodePath("../Hurtbox")
    victim.add_child(health)
    add_child(victim)
    await get_tree().process_frame
    var landed := [0]
    hitbox.landed.connect(func(_target: Area2D) -> void: landed[0] += 1)
    hurtbox._on_area_entered(hitbox)
    var first_ok: bool = is_equal_approx(health.hp, 20.0) and int(landed[0]) == 1
    health.shield_charges = 1
    hurtbox._on_area_entered(hitbox)
    var shield_ok: bool = is_equal_approx(health.hp, 20.0) and int(landed[0]) == 1
    attacker.queue_free()
    victim.queue_free()
    var ok: bool = first_ok and shield_ok
    return {"name": "valid_hit_signal_only_after_damage", "status": PASS if ok else FAIL,
        "reason": "hp=%.0f landed=%d (실피해 1회만 기대)" % [health.hp, landed[0]] if not ok else ""}


func _check_all_player_attack_feedback_routes() -> Dictionary:
    var player_src := (load("res://scripts/player/player.gd") as GDScript).get_source_code()
    var shot_src := (load("res://scripts/combat/talisman_shot.gd") as GDScript).get_source_code()
    var problems: Array[String] = []
    if not player_src.contains("attack_hitbox.landed.connect(_on_hitbox_landed)"):
        problems.append("기본/차지/도혼참 landed 배선 없음")
    if player_src.count("HIT_FEEDBACK.player_hit") < 2:
        problems.append("근접 또는 궁극기 공통 피드백 누락")
    if not shot_src.contains("HIT_FEEDBACK.player_hit"):
        problems.append("부적 공통 피드백 누락")
    return {"name": "all_player_attacks_use_hit_confirm", "status": PASS if problems.is_empty() else FAIL,
        "reason": ", ".join(problems)}


func _check_camera_feedback_profile() -> Dictionary:
    var feedback := load("res://scripts/combat/hit_feedback.gd")
    var feel: Dictionary = feedback.profile(1, 1.0)
    var screen_fx_src := (load("res://scripts/combat/screen_fx.gd") as GDScript).get_source_code()
    var player_src := (load("res://scripts/player/player.gd") as GDScript).get_source_code()
    var ok := float(feel.get("kick", 99.0)) <= 2.0 \
        and float(feel.get("duration", 1.0)) <= 0.085 \
        and screen_fx_src.contains("func impact_bump") \
        and player_src.contains("2: ScreenFx.hit_stop") \
        and not player_src.contains("1: ScreenFx.hit_stop")
    return {"name": "directional_camera_bump_not_jitter", "status": PASS if ok else FAIL,
        "reason": "kick=%.2f duration=%.3f" % [feel.get("kick", -1.0), feel.get("duration", -1.0)] if not ok else ""}


func _check_camera_bump_rebases() -> Dictionary:
    var cam := Camera2D.new()
    var base := Vector2(0, -80)
    cam.offset = base
    add_child(cam)
    cam.make_current()
    await get_tree().process_frame
    ScreenFx.impact_bump(2.0, 0.06, 1.0)
    # 렌더 프레임 중간 위치를 재현한 뒤 반대 방향 명중을 넣는다. 이 값이 새 기준점이 되면 안 된다.
    cam.offset = base + Vector2(1.75, -0.25)
    ScreenFx.impact_bump(2.5, 0.06, -1.0)
    var rebased := cam.offset.distance_to(base) < 0.01
    await get_tree().create_timer(0.10, true, false, true).timeout
    var returned := cam.offset.distance_to(base) < 0.01
    var final_offset := cam.offset
    cam.queue_free()
    var ok := rebased and returned
    return {"name": "camera_bump_restores_base_offset", "status": PASS if ok else FAIL,
        "reason": "rebased=%s final=%s base=%s" % [str(rebased), str(final_offset), str(base)] if not ok else ""}
