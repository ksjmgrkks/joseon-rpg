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
## 8) 유효 명중 피드백이 미세 확대+완만한 감속 프로필인가
## 9) 연속 확대 후 사용자 기준 zoom으로 정확히 복귀하는가
## 10) 명중 슬로 모션이 실시간 타이머 뒤 원래 time_scale로 복귀하는가
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
    results.append(await _check_camera_focus_rebases())
    results.append(await _check_slow_motion_restores())

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
    var heavy: Dictionary = feedback.profile(1, 2.0)
    var screen_fx_src := (load("res://scripts/combat/screen_fx.gd") as GDScript).get_source_code()
    var player_src := (load("res://scripts/player/player.gd") as GDScript).get_source_code()
    var landed_section := player_src.get_slice("func _on_hitbox_landed", 1).get_slice("func _start_dodge", 0)
    var ratio := float(feel.get("zoom_ratio", 9.0))
    var slow_scale := float(feel.get("slow_scale", 0.0))
    var ok := ratio >= 1.108 and ratio <= 1.12 \
        and slow_scale >= 0.3 and slow_scale <= 0.35 \
        and float(feel.get("slow_duration", 0.0)) >= 0.07 \
        and float(feel.get("slow_duration", 1.0)) <= 0.075 \
        and float(heavy.get("zoom_ratio", 0.0)) > ratio \
        and float(heavy.get("slow_duration", 0.0)) > float(feel.get("slow_duration", 0.0)) \
        and float(heavy.get("slow_scale", 1.0)) < slow_scale \
        and screen_fx_src.contains("func impact_focus") \
        and screen_fx_src.contains("func slow_motion") \
        and not landed_section.contains("ScreenFx.hit_stop")
    return {"name": "hit_focus_zoom_and_slow_motion", "status": PASS if ok else FAIL,
        "reason": "zoom=%.3f slow=%.2f" % [ratio, slow_scale] if not ok else ""}


func _check_camera_focus_rebases() -> Dictionary:
    var cam := Camera2D.new()
    var base := Vector2(1.5, 1.5)
    cam.zoom = base
    add_child(cam)
    cam.make_current()
    await get_tree().process_frame
    ScreenFx.impact_focus(1.015, 0.02, 0.06)
    # 확대 중간값을 재현한 뒤 더 강한 다중 명중을 넣어도 이 값이 새 기본 배율이 되면 안 된다.
    cam.zoom = base * 1.012
    ScreenFx.impact_focus(1.025, 0.02, 0.06)
    await get_tree().create_timer(0.12, true, false, true).timeout
    var returned := cam.zoom.distance_to(base) < 0.001
    var final_zoom := cam.zoom
    cam.queue_free()
    return {"name": "camera_focus_restores_user_zoom", "status": PASS if returned else FAIL,
        "reason": "final=%s base=%s" % [str(final_zoom), str(base)] if not returned else ""}


func _check_slow_motion_restores() -> Dictionary:
    var original := Engine.time_scale
    ScreenFx.slow_motion(0.02, 0.7)
    var slowed := is_equal_approx(Engine.time_scale, 0.7)
    await get_tree().create_timer(0.05, true, false, true).timeout
    var restored := is_equal_approx(Engine.time_scale, original)
    if not restored:
        Engine.time_scale = original
    var ok := slowed and restored
    return {"name": "hit_slow_motion_restores_time_scale", "status": PASS if ok else FAIL,
        "reason": "slowed=%s restored=%s" % [str(slowed), str(restored)] if not ok else ""}
