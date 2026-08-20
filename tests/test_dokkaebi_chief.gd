extends Node
##
## 도깨비 대장(3스테이지 보스) — 정면(방망이 막힘)=칩 데미지, 등 뒤(빈틈)=온전한 피해+보너스 검증.
## 실행: `godot --headless res://tests/test_dokkaebi_chief.tscn`
##

const PASS := "PASS"
const FAIL := "FAIL"
const CHIEF_SCENE := "res://scenes/enemies/DokkaebiChief.tscn"


func _ready() -> void:
	print("=== test_dokkaebi_chief ===")
	var results: Array[Dictionary] = []
	results.append(await _check_front_hit_is_chip_damage())
	results.append(await _check_back_hit_is_full_damage())
	results.append(_check_pattern_pool_excludes_water())
	results.append(await _check_health_not_auto_bound())

	var failed := 0
	for r in results:
		print("[%s] %s" % [r.status, r.name])
		if r.status == FAIL:
			failed += 1
			print("  reason: %s" % r.reason)
	print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
	get_tree().quit(0 if failed == 0 else 1)


func _spawn() -> Node:
	var inst: Node = load(CHIEF_SCENE).instantiate()
	add_child(inst)
	return inst


## 보스가 오른쪽(_facing_right=true)을 볼 때, 오른쪽(정면)에서 때리면 칩 데미지만 들어간다.
func _check_front_hit_is_chip_damage() -> Dictionary:
	var b := _spawn()
	await get_tree().process_frame
	b._facing_right = true
	var attacker := Node2D.new()
	attacker.global_position = b.global_position + Vector2(30, 0)   # 오른쪽 = 정면
	add_child(attacker)
	var hp_before: float = b.health.hp
	b._on_hurt(50.0, 100.0, attacker)
	var expect: float = hp_before - 50.0 * b.front_block_mult
	var ok := is_equal_approx(b.health.hp, expect)
	var reason := "" if ok else "hp=%.1f (기대 %.1f)" % [b.health.hp, expect]
	attacker.queue_free()
	b.queue_free()
	return { "name": "front_hit_is_chip_damage", "status": PASS if ok else FAIL, "reason": reason }


## 같은 상황에서 등 뒤(왼쪽=빈틈)를 때리면 온전한 피해 + 보너스가 들어간다.
func _check_back_hit_is_full_damage() -> Dictionary:
	var b := _spawn()
	await get_tree().process_frame
	b._facing_right = true
	var attacker := Node2D.new()
	attacker.global_position = b.global_position + Vector2(-30, 0)   # 왼쪽 = 등 뒤(빈틈)
	add_child(attacker)
	var hp_before: float = b.health.hp
	b._on_hurt(50.0, 100.0, attacker)
	var expect: float = hp_before - 50.0 * b.back_bonus_mult
	var ok := is_equal_approx(b.health.hp, expect)
	var reason := "" if ok else "hp=%.1f (기대 %.1f)" % [b.health.hp, expect]
	attacker.queue_free()
	b.queue_free()
	return { "name": "back_hit_is_full_damage", "status": PASS if ok else FAIL, "reason": reason }


## PILLARS/WAVE(물 스테이지 전용 패턴)는 저잣거리 보스 패턴 풀에서 나오면 안 된다.
func _check_pattern_pool_excludes_water() -> Dictionary:
	var b := _spawn()
	var seen: Dictionary = {}
	for i in range(200):
		seen[b._choose_pattern()] = true
	var bad := seen.has(b.Pattern.PILLARS) or seen.has(b.Pattern.WAVE)
	b.queue_free()
	var ok := not bad
	var reason := "" if ok else "물 전용 패턴이 나왔음: %s" % [seen.keys()]
	return { "name": "pattern_pool_excludes_water_patterns", "status": PASS if ok else FAIL, "reason": reason }


## HealthComponent 가 Hurtbox 에 자동 연결돼 있으면 안 된다 — 자동 연결 시 원본 데미지가
## 그대로 한 번 더 들어가 (앞/뒤 배율과 무관하게) 이중 피해 버그가 난다.
func _check_health_not_auto_bound() -> Dictionary:
	var b := _spawn()
	await get_tree().process_frame
	var ok: bool = b.health.hurtbox_path == NodePath("")
	b.queue_free()
	var reason := "" if ok else "hurtbox_path=%s — 자동 연결돼 있음(이중 피해 위험)" % b.health.hurtbox_path
	return { "name": "health_not_auto_bound_to_hurtbox", "status": PASS if ok else FAIL, "reason": reason }
