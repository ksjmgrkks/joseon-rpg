extends Node
##
## 그슨대 노괴(2스테이지 보스) — 위장 무적+성장(체력배율), 부적 노출, 물 전용 패턴 배제 검증.
## 실행: `godot --headless res://tests/test_geuseondae_elder.tscn`
##

const PASS := "PASS"
const FAIL := "FAIL"
const ELDER_SCENE := "res://scenes/enemies/GeuseondaeElder.tscn"


func _ready() -> void:
	print("=== test_geuseondae_elder ===")
	var results: Array[Dictionary] = []
	results.append(await _check_disguised_blocks_damage_and_grows())
	results.append(await _check_reveal_scales_max_hp())
	results.append(await _check_revealed_takes_real_damage())
	results.append(_check_pattern_pool_excludes_water())
	results.append(await _check_interact_prompt_range())
	results.append(await _check_interact_reveals())

	var failed := 0
	for r in results:
		print("[%s] %s" % [r.status, r.name])
		if r.status == FAIL:
			failed += 1
			print("  reason: %s" % r.reason)
	print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
	get_tree().quit(0 if failed == 0 else 1)


func _spawn() -> Node:
	var inst: Node = load(ELDER_SCENE).instantiate()
	add_child(inst)
	return inst


## 위장 상태에서 근접 피격 — 데미지 대신 위협도(_threat)만 오른다.
func _check_disguised_blocks_damage_and_grows() -> Dictionary:
	var b := _spawn()
	await get_tree().process_frame
	var hp_before: float = b.health.hp
	b.health._on_hurt(50.0, 100.0, self)
	var ok: bool = is_equal_approx(b.health.hp, hp_before) and b._disguised == true and b._threat == 1
	var reason := "" if ok else "hp=%.1f(기대 %.1f) disguised=%s threat=%d" % [b.health.hp, hp_before, b._disguised, b._threat]
	b.queue_free()
	return { "name": "disguised_blocks_damage_and_grows", "status": PASS if ok else FAIL, "reason": reason }


## 위장 중 여러 번 맞아 위협도가 쌓인 뒤 부적으로 드러내면 — 최대체력이 위협도만큼 배율 상승.
func _check_reveal_scales_max_hp() -> Dictionary:
	var b := _spawn()
	await get_tree().process_frame
	var base_max: float = b.health.max_hp
	for i in range(3):
		b.health._on_hurt(999.0, 50.0, self)
	var threat: int = b._threat
	b._on_talisman_hit(0.0, self)
	var expect_max: float = base_max * (1.0 + b.threat_hp_mult * float(threat))
	var ok: bool = b._disguised == false and b.health.shield_charges == 0 \
		and is_equal_approx(b.health.max_hp, expect_max) and is_equal_approx(b.health.hp, expect_max)
	var reason := "" if ok else "threat=%d max_hp=%.1f(기대 %.1f) disguised=%s" % [threat, b.health.max_hp, expect_max, b._disguised]
	b.queue_free()
	return { "name": "reveal_scales_max_hp_with_threat", "status": PASS if ok else FAIL, "reason": reason }


## 정체가 드러난 뒤엔 보통 보스처럼 실제 데미지가 들어간다.
func _check_revealed_takes_real_damage() -> Dictionary:
	var b := _spawn()
	await get_tree().process_frame
	b._on_talisman_hit(0.0, self)
	var hp_before: float = b.health.hp
	b.health._on_hurt(20.0, 100.0, self)
	var ok := is_equal_approx(b.health.hp, hp_before - 20.0)
	var reason := "" if ok else "hp=%.1f, expected %.1f" % [b.health.hp, hp_before - 20.0]
	b.queue_free()
	return { "name": "revealed_takes_real_damage", "status": PASS if ok else FAIL, "reason": reason }


## PILLARS/WAVE(물 스테이지 전용 패턴)는 그슨대 숲 보스 패턴 풀에서 나오면 안 된다.
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


## boss.gd 도 텔레그래프용 "!" 라벨(_warn)을 따로 갖고 있어 텍스트로 찾으면 헷갈린다 —
## 우리가 만든 조사 프롬프트 참조(_interact_prompt)를 직접 읽는다.
func _prompt_visible(b: Node) -> bool:
	var lbl: Label = b._interact_prompt
	return lbl != null and lbl.visible


func _fake_player(pos: Vector2) -> Node2D:
	var p := Node2D.new()
	p.add_to_group("player")
	add_child(p)
	p.global_position = pos
	return p


## 위장 상태 + 조사 사거리 안일 때만 "조사" 프롬프트가 뜬다.
func _check_interact_prompt_range() -> Dictionary:
	var b := _spawn()
	await get_tree().process_frame
	var far := _fake_player(b.global_position + Vector2(600, 0))
	b._physics_process(0.016)
	var hidden_far := not _prompt_visible(b)

	far.global_position = b.global_position + Vector2(b.interact_range * 0.5, 0)
	b._physics_process(0.016)
	var visible_near := _prompt_visible(b)

	var prompt_copy_ok: bool = b._interact_prompt != null and b._interact_prompt.text == "조사"
	var ok: bool = hidden_far and visible_near and prompt_copy_ok
	var reason := "" if ok else "hidden_far=%s visible_near=%s prompt=%s" % [hidden_far, visible_near, b._interact_prompt.text]
	far.queue_free()
	b.queue_free()
	return { "name": "interact_prompt_range", "status": PASS if ok else FAIL, "reason": reason }


## 조사 사거리 안에서 interact 를 누르면(부적을 맞히지 않아도) 노괴 정체가 드러난다.
func _check_interact_reveals() -> Dictionary:
	var b := _spawn()
	await get_tree().process_frame
	var p := _fake_player(b.global_position + Vector2(20, 0))
	b._physics_process(0.016)
	if not b._in_interact_range:
		p.queue_free(); b.queue_free()
		return { "name": "interact_reveals", "status": FAIL, "reason": "테스트 셋업 실패 — 사거리 판정이 안 됨" }

	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	b._unhandled_input(ev)

	var ok: bool = (b._disguised == false) and not _prompt_visible(b)
	var reason := "" if ok else "disguised=%s prompt_visible=%s" % [b._disguised, _prompt_visible(b)]
	p.queue_free()
	b.queue_free()
	return { "name": "interact_reveals", "status": PASS if ok else FAIL, "reason": reason }
