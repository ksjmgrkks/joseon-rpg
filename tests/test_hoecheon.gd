extends Node
##
## 「진혼등」 스킬샷 개편 검증 (헤드리스).
## ① 시전 중 살짝 뜨고, 끝나면 원래 높이로 돌아오는가(부양 잔류 회귀 방지)
## ② 부채꼴 사거리 안(정면)의 적은 맞는가
## ③ 부채꼴 밖(등 뒤)의 적은 안 맞아야 한다 — 이게 이번 개편의 핵심(스킬샷=빗나갈 수 있음).
##

const PASS := "PASS"
const FAIL := "FAIL"
const GROUND_Y := 470.0


func _ready() -> void:
	print("=== test_hoecheon ===")
	var results: Array[Dictionary] = []
	results.append(await _check_rise_and_land())
	results.append(await _check_hits_target_in_front())
	results.append(await _check_misses_target_behind())

	var failed := 0
	for r in results:
		print("[%s] %s" % [r.status, r.name])
		if r.status == FAIL:
			failed += 1
			print("  reason: %s" % r.reason)
	print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
	get_tree().quit(0 if failed == 0 else 1)


func _stage() -> Node2D:
	var root := Node2D.new()
	add_child(root)
	var body := StaticBody2D.new()
	body.collision_layer = 4
	body.position = Vector2(640, GROUND_Y + 16)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(3000, 32)
	cs.shape = shape
	body.add_child(cs)
	root.add_child(body)
	return root


func _spawn_player(root: Node2D, x: float) -> Node2D:
	var p: Node2D = load("res://scenes/player/Player.tscn").instantiate()
	root.add_child(p)
	p.global_position = Vector2(x, GROUND_Y - 40)
	await get_tree().process_frame
	for i in range(20):
		await get_tree().physics_frame        # 착지 안정
	return p


func _spawn_dummy(root: Node2D, x: float) -> Node2D:
	var d: Node2D = load("res://scenes/enemies/Dummy.tscn").instantiate()
	root.add_child(d)
	d.global_position = Vector2(x, GROUND_Y - 16)
	await get_tree().process_frame
	return d


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check_rise_and_land() -> Dictionary:
	var root := _stage()
	var p := await _spawn_player(root, 300.0)
	SkillManager.reset_cooldowns()
	var y0: float = p.global_position.y
	SkillManager.try_cast("hoecheon")
	await _wait(0.25)          # charge_time(0.42) 도중
	var y_air: float = p.global_position.y
	var hovering: bool = p.get("_hover_lock")
	await _wait(1.0)           # 투척 + 착지 + 여유
	var y1: float = p.global_position.y
	var still_hover: bool = p.get("_hover_lock")
	var attacking: bool = p.get("_attacking")
	root.queue_free()
	if not hovering or y_air > y0 - 20.0:
		return { "name": "hoecheon_rise_and_land", "status": FAIL,
			"reason": "시전 중 부양 안 함 (y %.0f→%.0f, hover=%s)" % [y0, y_air, str(hovering)] }
	if still_hover:
		return { "name": "hoecheon_rise_and_land", "status": FAIL, "reason": "끝난 뒤에도 부양 상태(중력 꺼짐)" }
	if absf(y1 - y0) > 12.0:
		return { "name": "hoecheon_rise_and_land", "status": FAIL,
			"reason": "착지 높이가 다름 (%.0f → %.0f)" % [y0, y1] }
	if attacking:
		return { "name": "hoecheon_rise_and_land", "status": FAIL, "reason": "끝난 뒤에도 _attacking 이 참" }
	return { "name": "hoecheon_rise_and_land", "status": PASS, "reason": "" }


func _check_hits_target_in_front() -> Dictionary:
	var root := _stage()
	var p := await _spawn_player(root, 300.0)   # 기본 오른쪽을 바라봄
	var d := await _spawn_dummy(root, 450.0)    # 정면 150px — 부채꼴(±35°) 안
	var hc: HealthComponent = d.get_node("HealthComponent")
	var hp0: float = hc.hp
	SkillManager.reset_cooldowns()
	SkillManager.try_cast("hoecheon")
	await _wait(1.1)
	var hp1: float = hc.hp
	root.queue_free()
	if hp1 >= hp0:
		return { "name": "hoecheon_hits_front_target", "status": FAIL,
			"reason": "정면 표적 hp 불변(%.1f) — 부적이 안 맞음" % hp1 }
	return { "name": "hoecheon_hits_front_target", "status": PASS, "reason": "" }


func _check_misses_target_behind() -> Dictionary:
	var root := _stage()
	var p := await _spawn_player(root, 300.0)   # 기본 오른쪽을 바라봄
	var d := await _spawn_dummy(root, 150.0)    # 등 뒤 150px — 부채꼴 밖(반대 방향)
	var hc: HealthComponent = d.get_node("HealthComponent")
	var hp0: float = hc.hp
	SkillManager.reset_cooldowns()
	SkillManager.try_cast("hoecheon")
	await _wait(1.1)
	var hp1: float = hc.hp
	root.queue_free()
	if hp1 < hp0:
		return { "name": "hoecheon_misses_behind_target", "status": FAIL,
			"reason": "등 뒤 표적이 맞음(hp %.1f→%.1f) — 스킬샷 방향성이 없음" % [hp0, hp1] }
	return { "name": "hoecheon_misses_behind_target", "status": PASS, "reason": "" }
