extends Node
##
## 「해원」 회상 컷 전환 시스템 검증 (폰세션이 Godot 없이 만든 신규 시스템 — PC에서 테스트 신설):
##  ① Cut*.tscn 래퍼 → cutscene JSON → 참조 에셋(대사·인물 스프라이트·prop/바닥 텍스처) 무결
##  ② haewon 굽이의 clear_cutscene/auto_cutscenes 가 존재하는 Cut*.tscn 을 가리키고 from_recall 복귀점이 있음
##  ③ SceneManager.play_cutscene → return_from_cutscene 복귀 컨텍스트(전투 씬+entry) 왕복
##  ④ stage.gd._build_auto_cutscenes 가 위치 트리거를 올바른 파라미터로 생성
##

const PASS := "PASS"
const FAIL := "FAIL"
const CUT_JSON := "res://assets/cutscenes/%s.json"
const TILE := "res://assets/tilesets/%s.png"

# 컷 래퍼 .tscn (루트 Cutscene 노드, cutscene_id export)
const WRAPPERS := [
	"res://scenes/cutscenes/CutRecallYunseul.tscn",
	"res://scenes/cutscenes/CutWatergate.tscn",
	"res://scenes/cutscenes/CutFloodNight.tscn",
]


func _ready() -> void:
	print("=== test_cutscene ===")
	var results: Array = []
	for w in WRAPPERS:
		results.append(_check_wrapper_chain(w))
	results.append(_check_haewon_clear_cutscene("res://assets/stages/haewon_1_ferry.json"))
	results.append(_check_haewon_clear_cutscene("res://assets/stages/haewon_4_watergate.json"))
	results.append(_check_haewon_auto_cutscene("res://assets/stages/haewon_5_emptytown.json"))
	results.append(await _check_scene_manager_roundtrip())
	results.append(await _check_auto_cutscene_built())

	var passed := 0
	for r in results:
		print("[%s] %s" % [r.status, r.name])
		if r.status == FAIL:
			print("  reason: %s" % r.reason)
		else:
			passed += 1
	print("=== %d/%d passed ===" % [passed, results.size()])
	get_tree().quit(0 if passed == results.size() else 1)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}


func _find(node: Node, cls: String) -> Array:
	var out: Array = []
	for c in node.get_children():
		if c.get_script() != null and (c as Object).get_script().get_global_name() == cls:
			out.append(c)
		out.append_array(_find(c, cls))
	return out


## ① 래퍼 → cutscene_id → JSON → 참조 에셋(대사·인물·prop·바닥) 전부 해소되는가.
func _check_wrapper_chain(wrapper_path: String) -> Dictionary:
	var nm := wrapper_path.get_file().get_basename()
	var packed: PackedScene = load(wrapper_path)
	if packed == null:
		return {"name": nm, "status": FAIL, "reason": "래퍼 로드 실패"}
	# 트리에 안 넣고 export 만 읽음 → _ready(씬 빌드·대사) 부작용 없음.
	var inst := packed.instantiate()
	var cid := String(inst.cutscene_id) if "cutscene_id" in inst else ""
	inst.free()
	if cid == "":
		return {"name": nm, "status": FAIL, "reason": "cutscene_id 비어 있음"}
	var json_path := CUT_JSON % cid
	var data := _load_json(json_path)
	if data.is_empty():
		return {"name": nm, "status": FAIL, "reason": "cutscene JSON 없음/파싱실패: %s" % json_path}
	# 대사 참조
	var dlg := String(data.get("dialogue", ""))
	if dlg == "" or not ResourceLoader.exists(dlg):
		return {"name": nm, "status": FAIL, "reason": "대사 참조 깨짐: '%s'" % dlg}
	# 인물 스프라이트(있으면 실존해야 — 폴백은 의도지만 커밋된 경로 오타 잡기)
	for fig in data.get("figures", []):
		if fig is Dictionary and fig.has("sprite"):
			var sp := String(fig["sprite"])
			if sp != "" and not ResourceLoader.exists(sp):
				return {"name": nm, "status": FAIL, "reason": "인물 스프라이트 없음: %s" % sp}
	# prop / 바닥 텍스처
	for p in data.get("props", []):
		if p is Dictionary:
			var tp := TILE % String(p.get("tex", ""))
			if not ResourceLoader.exists(tp):
				return {"name": nm, "status": FAIL, "reason": "prop 텍스처 없음: %s" % tp}
	if data.has("ground"):
		var gt := TILE % String(data["ground"].get("tex", "ground_dirt"))
		if not ResourceLoader.exists(gt):
			return {"name": nm, "status": FAIL, "reason": "바닥 텍스처 없음: %s" % gt}
	return {"name": nm + "→" + cid, "status": PASS, "reason": ""}


## ② 전투 굽이 clear_cutscene → 존재하는 Cut*.tscn + from_recall 복귀점.
func _check_haewon_clear_cutscene(stage_json: String) -> Dictionary:
	var nm := stage_json.get_file().get_basename() + "/clear_cutscene"
	var data := _load_json(stage_json)
	if data.is_empty():
		return {"name": nm, "status": FAIL, "reason": "스테이지 JSON 파싱실패"}
	var cc := String(data.get("clear_cutscene", ""))
	if cc == "" or not ResourceLoader.exists(cc):
		return {"name": nm, "status": FAIL, "reason": "clear_cutscene 깨짐: '%s'" % cc}
	if not _has_entry(data, "from_recall"):
		return {"name": nm, "status": FAIL, "reason": "from_recall 복귀점 없음"}
	return {"name": nm, "status": PASS, "reason": ""}


## ② 무전투 굽이 auto_cutscenes → 존재하는 Cut*.tscn + from_recall 복귀점.
func _check_haewon_auto_cutscene(stage_json: String) -> Dictionary:
	var nm := stage_json.get_file().get_basename() + "/auto_cutscenes"
	var data := _load_json(stage_json)
	var acs = data.get("auto_cutscenes", [])
	if not (acs is Array) or acs.is_empty():
		return {"name": nm, "status": FAIL, "reason": "auto_cutscenes 비어 있음"}
	for a in acs:
		var cp := String(a.get("cutscene", "")) if a is Dictionary else ""
		if cp == "" or not ResourceLoader.exists(cp):
			return {"name": nm, "status": FAIL, "reason": "auto cutscene 깨짐: '%s'" % cp}
	if not _has_entry(data, "from_recall"):
		return {"name": nm, "status": FAIL, "reason": "from_recall 복귀점 없음"}
	return {"name": nm, "status": PASS, "reason": ""}


func _has_entry(data: Dictionary, entry_name: String) -> bool:
	for e in data.get("entries", []):
		if e is Dictionary and String(e.get("name", "")) == entry_name:
			return true
	return false


## ③ SceneManager: play_cutscene 가 복귀 컨텍스트를 기억하고, return_from_cutscene 가 소비.
func _check_scene_manager_roundtrip() -> Dictionary:
	var nm := "scene_manager_roundtrip"
	if SceneManager == null:
		return {"name": nm, "status": FAIL, "reason": "SceneManager 오토로드 없음"}
	var prev := SceneManager.transitions_enabled
	SceneManager.transitions_enabled = false   # 실제 씬 전환 차단(컨텍스트만 검사)
	var ret_path := "res://scenes/levels/Haewon4Watergate.tscn"
	await SceneManager.play_cutscene("res://scenes/cutscenes/CutWatergate.tscn", ret_path, &"from_recall")
	var stored_ok := SceneManager._cut_return_path == ret_path and SceneManager._cut_return_entry == &"from_recall"
	var consumed := await SceneManager.return_from_cutscene()   # transitions off → false, 컨텍스트는 소비
	var cleared := SceneManager._cut_return_path == ""
	var empty_false := not (await SceneManager.return_from_cutscene())   # 컨텍스트 없으면 false
	SceneManager.transitions_enabled = prev
	if not stored_ok:
		return {"name": nm, "status": FAIL, "reason": "play_cutscene 가 복귀 컨텍스트 미저장"}
	if not cleared:
		return {"name": nm, "status": FAIL, "reason": "return_from_cutscene 가 컨텍스트 미소비"}
	if not empty_false:
		return {"name": nm, "status": FAIL, "reason": "컨텍스트 없는데 return 이 true"}
	return {"name": nm, "status": PASS, "reason": ""}


## ④ stage.gd 가 haewon_5 의 auto_cutscene 위치 트리거를 올바른 파라미터로 생성하는가.
func _check_auto_cutscene_built() -> Dictionary:
	var nm := "auto_cutscene_built"
	Flags.clear()
	MemoryLedger.reset()
	var s: Node = load("res://scenes/levels/Haewon5EmptyTown.tscn").instantiate()
	add_child(s)
	await get_tree().process_frame
	await get_tree().process_frame
	var acs := _find(s, "AutoCutscene")
	var ok := false
	var reason := "AutoCutscene 노드 미생성"
	for a in acs:
		var cp := String(a.cutscene_path) if "cutscene_path" in a else ""
		var of := String(a.once_flag) if "once_flag" in a else ""
		var re := String(a.return_entry) if "return_entry" in a else ""
		if ResourceLoader.exists(cp) and of != "" and re == "from_recall":
			ok = true
		else:
			reason = "파라미터 불량: path='%s' once='%s' entry='%s'" % [cp, of, re]
	s.queue_free()
	await get_tree().process_frame
	if not ok:
		return {"name": nm, "status": FAIL, "reason": reason}
	return {"name": nm, "status": PASS, "reason": ""}
