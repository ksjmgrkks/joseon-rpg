extends Node
##
## 스토리 데이터 무결성 검사 (헤드리스).
## 실행: `godot --headless res://tests/test_story_data.tscn`
##
## 대사·스테이지·컷신이 전부 JSON 이라 오타 하나가 런타임에야 터진다. 여기서 전수 검사한다:
##  ① 모든 JSON 이 파싱되는가
##  ② 대사: start 노드가 있고, 모든 next 가 실제 노드이거나 null 인가 (끊긴 대화 방지)
##  ③ 스테이지: gut 이 있고, 참조하는 대사·컷신·다음 씬 파일이 실제로 있는가 (죽은 링크 방지)
##  ④ 컷신: 참조하는 대사 파일이 있는가
##  ⑤ MemoryLedger 조각이 굽이 0~6 에 하나씩, 빠짐없이 있는가 (스토리 진행의 뼈대)
##

const PASS := "PASS"
const FAIL := "FAIL"
const DIALOGUE_DIRS := ["res://assets/dialogue", "res://assets/dialogue/haewon"]
const STAGE_DIR := "res://assets/stages"
const CUTSCENE_DIR := "res://assets/cutscenes"


func _ready() -> void:
    print("=== test_story_data ===")
    var results: Array[Dictionary] = []
    results.append(_check_dialogues())
    results.append(_check_stages())
    results.append(_check_cutscenes())
    results.append(_check_ledger_covers_guts())
    results.append(await _check_story_entry())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _files(dir_path: String, ext: String = ".json") -> Array[String]:
    var out: Array[String] = []
    var d := DirAccess.open(dir_path)
    if d == null:
        return out
    for f in d.get_files():
        if f.ends_with(ext):
            out.append("%s/%s" % [dir_path, f])
    return out


func _parse(path: String):
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return null
    var data = JSON.parse_string(file.get_as_text())
    return data


func _check_dialogues() -> Dictionary:
    var count := 0
    for dir_path in DIALOGUE_DIRS:
        for path in _files(dir_path):
            var data = _parse(path)
            if not (data is Dictionary):
                return { "name": "dialogues_parse_and_link", "status": FAIL, "reason": "파싱 실패: %s" % path }
            var nodes = data.get("nodes", null)
            if not (nodes is Dictionary) or (nodes as Dictionary).is_empty():
                return { "name": "dialogues_parse_and_link", "status": FAIL, "reason": "nodes 없음: %s" % path }
            var start := String(data.get("start", ""))
            if not (nodes as Dictionary).has(start):
                return { "name": "dialogues_parse_and_link", "status": FAIL,
                    "reason": "start '%s' 노드가 없음: %s" % [start, path] }
            for key in (nodes as Dictionary):
                var n = nodes[key]
                if not (n is Dictionary):
                    return { "name": "dialogues_parse_and_link", "status": FAIL,
                        "reason": "노드 '%s' 가 객체가 아님: %s" % [key, path] }
                var nxt = (n as Dictionary).get("next", null)
                if nxt != null and not (nodes as Dictionary).has(String(nxt)):
                    return { "name": "dialogues_parse_and_link", "status": FAIL,
                        "reason": "'%s' 의 next '%s' 가 없는 노드: %s" % [key, str(nxt), path] }
            count += 1
    return { "name": "dialogues_parse_and_link", "status": PASS, "reason": "%d개" % count }


func _check_stages() -> Dictionary:
    var story := 0
    for path in _files(STAGE_DIR):
        var data = _parse(path)
        if not (data is Dictionary):
            return { "name": "stages_parse_and_refs", "status": FAIL, "reason": "파싱 실패: %s" % path }
        var d := data as Dictionary
        if not path.get_file().begins_with("haewon_"):
            continue                                  # 옛 전투 체인 스테이지는 스토리 검사 제외
        story += 1
        if not d.has("gut"):
            return { "name": "stages_parse_and_refs", "status": FAIL, "reason": "gut 없음(스토리 배선 끊김): %s" % path }
        for key in ["clear_dialogue", "clear_cutscene"]:
            var ref := String(d.get(key, ""))
            if ref != "" and not ResourceLoader.exists(ref) and not FileAccess.file_exists(ref):
                return { "name": "stages_parse_and_refs", "status": FAIL, "reason": "%s 가 없는 파일: %s (%s)" % [key, ref, path] }
        for ad in d.get("auto_dialogues", []):
            var ref2 := String((ad as Dictionary).get("dialogue", ""))
            if not FileAccess.file_exists(ref2):
                return { "name": "stages_parse_and_refs", "status": FAIL, "reason": "auto_dialogue 없는 파일: %s (%s)" % [ref2, path] }
        for ex in d.get("exits", []):
            var target := String((ex as Dictionary).get("target", ""))
            if not ResourceLoader.exists(target):
                return { "name": "stages_parse_and_refs", "status": FAIL, "reason": "exit 없는 씬: %s (%s)" % [target, path] }
    if story < 7:
        return { "name": "stages_parse_and_refs", "status": FAIL, "reason": "스토리 스테이지 %d개 (7개 기대)" % story }
    return { "name": "stages_parse_and_refs", "status": PASS, "reason": "%d개" % story }


func _check_cutscenes() -> Dictionary:
    var count := 0
    for path in _files(CUTSCENE_DIR):
        var data = _parse(path)
        if not (data is Dictionary):
            return { "name": "cutscenes_parse_and_refs", "status": FAIL, "reason": "파싱 실패: %s" % path }
        var ref := String((data as Dictionary).get("dialogue", ""))
        if ref != "" and not FileAccess.file_exists(ref):
            return { "name": "cutscenes_parse_and_refs", "status": FAIL, "reason": "없는 대사 파일: %s (%s)" % [ref, path] }
        count += 1
    return { "name": "cutscenes_parse_and_refs", "status": PASS, "reason": "%d개" % count }


func _check_ledger_covers_guts() -> Dictionary:
    var seen := {}
    for frag in MemoryLedger.FRAGMENTS:
        var g := int(frag["gut"])
        if seen.has(g):
            return { "name": "ledger_covers_guts", "status": FAIL, "reason": "굽이 %d 조각이 둘 이상" % g }
        seen[g] = true
        if String(frag.get("label", "")) == "":
            return { "name": "ledger_covers_guts", "status": FAIL, "reason": "굽이 %d 조각에 label 없음" % g }
    for g in range(7):
        if not seen.has(g):
            return { "name": "ledger_covers_guts", "status": FAIL, "reason": "굽이 %d 기억 조각 없음" % g }
    return { "name": "ledger_covers_guts", "status": PASS, "reason": "" }


# 메뉴에서 이야기 모드로 들어갈 수 있는가 (스코어어택과 별개 진입로).
func _check_story_entry() -> Dictionary:
    var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
    add_child(menu)
    await get_tree().process_frame
    var btn := menu.get_node_or_null("Margin/VBox/Buttons/StoryBtn") as Button
    var start_path: String = menu.get("STORY_START_PATH") if menu.get("STORY_START_PATH") != null else ""
    var has_handler := menu.has_method("_on_story")
    menu.queue_free()
    if btn == null:
        return { "name": "story_menu_entry", "status": FAIL, "reason": "메뉴에 StoryBtn 이 없음" }
    if btn.text.strip_edges() == "":
        return { "name": "story_menu_entry", "status": FAIL, "reason": "StoryBtn 라벨이 비었음" }
    if not has_handler:
        return { "name": "story_menu_entry", "status": FAIL, "reason": "_on_story 핸들러 없음" }
    if not ResourceLoader.exists(start_path):
        return { "name": "story_menu_entry", "status": FAIL, "reason": "이야기 시작 씬 없음: %s" % start_path }
    return { "name": "story_menu_entry", "status": PASS, "reason": start_path.get_file() }
