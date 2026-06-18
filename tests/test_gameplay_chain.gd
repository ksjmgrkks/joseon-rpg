extends Node
## 게임성 우선(전투-클리어 전용) 모드 검증:
## 체인 스테이지가 ① 적 스폰 ② NPC/자동대사 0 ③ 전진 게이트+출구 ④ 마지막은 Clear 로 연결.
const PASS := "PASS"
const FAIL := "FAIL"

const CHAIN := {
	"res://scenes/levels/Foothills.tscn": "res://scenes/levels/ForestDeep.tscn",
	"res://scenes/levels/ForestDeep.tscn": "res://scenes/levels/MountainPass.tscn",
	"res://scenes/levels/MountainPass.tscn": "res://scenes/levels/RuinedTemple.tscn",
	"res://scenes/levels/RuinedTemple.tscn": "res://scenes/levels/SacredAltar.tscn",
	"res://scenes/levels/SacredAltar.tscn": "res://scenes/ui/Clear.tscn",
}


func _ready() -> void:
	print("=== test_gameplay_chain ===")
	var results: Array = []
	for src in CHAIN:
		results.append(await _check(src, CHAIN[src]))
	var passed := 0
	for r in results:
		print("[%s] %s" % [r.status, r.name])
		if r.status == FAIL:
			print("  reason: %s" % r.reason)
		else:
			passed += 1
	print("=== %d/%d passed ===" % [passed, results.size()])
	get_tree().quit(0 if passed == results.size() else 1)


func _find(node: Node, cls: String) -> Array:
	var out: Array = []
	for c in node.get_children():
		if c.get_class() == "Node2D" and c.get_script() != null and (c as Object).get_script().get_global_name() == cls:
			out.append(c)
		if c is Area2D and c.get_script() != null and (c as Object).get_script().get_global_name() == cls:
			out.append(c)
		out.append_array(_find(c, cls))
	return out


func _check(src: String, expect_target: String) -> Dictionary:
	Flags.clear()
	var nm := src.get_file().get_basename()
	var s: Node = load(src).instantiate()
	add_child(s)
	await get_tree().process_frame
	await get_tree().process_frame
	# 적 스폰
	var enemies := get_tree().get_nodes_in_group("enemy").size()
	# NPC / 자동대사 없음
	var npcs := _find(s, "Npc").size()
	var autodlg := _find(s, "AutoDialogue").size()
	# 전진 출구 + 게이트
	var exits := _find(s, "LevelExit")
	var gates := _find(s, "CombatGate")
	var fwd_ok := false
	for e in exits:
		if String(e.target_scene) == expect_target:
			fwd_ok = true
	s.queue_free()
	await get_tree().process_frame
	if enemies <= 0:
		return {"name": nm, "status": FAIL, "reason": "적 미스폰"}
	if npcs != 0 or autodlg != 0:
		return {"name": nm, "status": FAIL, "reason": "스토리 잔존 npc=%d autodlg=%d" % [npcs, autodlg]}
	if not fwd_ok:
		return {"name": nm, "status": FAIL, "reason": "전진 출구 target!=%s (exits=%d)" % [expect_target, exits.size()]}
	if gates.size() <= 0:
		return {"name": nm, "status": FAIL, "reason": "전투 게이트 없음"}
	return {"name": nm, "status": PASS, "reason": ""}
