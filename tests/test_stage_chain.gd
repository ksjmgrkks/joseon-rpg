extends Node
##
## 전투 체인(일반 모드) 연결 검증 (헤드리스).
## 실행: `godot --headless res://tests/test_stage_chain.tscn`
##
## 2026-08-19 사고: 1스테이지 보스(수문의 원혼)에 `scene_on_death = Ending.tscn` 이 남아 있어
## **보스를 잡으면 엔딩으로 직행, 2스테이지(그슨대 숲)로 넘어가지 못했다.** 체인 정의는 멀쩡했는데
## 보스 한 줄이 흐름을 가로챈 것. 같은 사고가 조용히 재발하지 않도록 아래를 전수 검사한다:
##  ① 체인의 각 스테이지가 실제로 '다음 스테이지'로 가는 출구를 만드는가
##  ② 마지막 스테이지만 클리어 화면으로 가는가
##  ③ **중간 보스가 scene_on_death 로 흐름을 끊지 않는가** (마지막 스테이지 보스만 허용)
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_stage_chain ===")
    var results: Array[Dictionary] = []
    results.append(await _check_forward_exits())
    results.append(_check_no_midchain_scene_on_death())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _find_exits(node: Node) -> Array:
    var out: Array = []
    for c in node.get_children():
        if c is LevelExit:
            out.append(c)
        out.append_array(_find_exits(c))
    return out


## ① + ② — 각 스테이지가 다음 목적지로 이어지는가.
func _check_forward_exits() -> Dictionary:
    var chain: Array = Stage.CHAIN
    var tscn: Dictionary = Stage.CHAIN_TSCN
    for i in range(chain.size()):
        var stage_id := String(chain[i])
        var expected := String(tscn[String(chain[i + 1])]) if i + 1 < chain.size() else Stage.CLEAR_SCENE
        Flags.clear()
        var s: Node = load(String(tscn[stage_id])).instantiate()
        add_child(s)
        await get_tree().process_frame
        await get_tree().process_frame
        var targets: Array = []
        for e in _find_exits(s):
            targets.append(String(e.target_scene))
        s.queue_free()
        await get_tree().process_frame
        if not targets.has(expected):
            return { "name": "forward_exits", "status": FAIL,
                "reason": "%s 의 출구가 %s 로 안 이어짐 (실제: %s)" % [stage_id, expected.get_file(), str(targets)] }
    return { "name": "forward_exits", "status": PASS, "reason": "%d스테이지" % chain.size() }


## ③ — 마지막이 아닌 스테이지의 보스가 scene_on_death 로 다음 스테이지를 가로채지 않는가.
func _check_no_midchain_scene_on_death() -> Dictionary:
    var chain: Array = Stage.CHAIN
    var last_stage := String(chain[chain.size() - 1])
    for i in range(chain.size()):
        var stage_id := String(chain[i])
        var path := "res://assets/stages/%s.json" % stage_id
        var f := FileAccess.open(path, FileAccess.READ)
        if f == null:
            return { "name": "no_midchain_scene_on_death", "status": FAIL, "reason": "스테이지 JSON 없음: %s" % path }
        var data = JSON.parse_string(f.get_as_text())
        f.close()
        if not (data is Dictionary):
            return { "name": "no_midchain_scene_on_death", "status": FAIL, "reason": "파싱 실패: %s" % path }
        for e in (data as Dictionary).get("enemies", []):
            var scene_name := String((e as Dictionary).get("scene", ""))
            var epath := "res://scenes/enemies/%s.tscn" % scene_name
            if not ResourceLoader.exists(epath):
                continue
            var inst := (load(epath) as PackedScene).instantiate()
            var sod := String(inst.get("scene_on_death")) if inst.get("scene_on_death") != null else ""
            inst.free()
            if sod != "" and stage_id != last_stage:
                return { "name": "no_midchain_scene_on_death", "status": FAIL,
                    "reason": "%s 의 %s 가 scene_on_death='%s' 로 체인을 끊음(중간 스테이지)" % [stage_id, scene_name, sod] }
    return { "name": "no_midchain_scene_on_death", "status": PASS, "reason": "" }
