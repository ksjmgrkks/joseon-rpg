extends Node
##
## test_audio — 오디오 버스(Music/SFX) + 리버브 구성, 볼륨→버스 게인,
##   그리고 bgm_director 씬→곡 매핑 경로 무결성 검증.
## 헤드리스(dummy audio)에서도 AudioServer 의 버스/이펙트는 생성되므로 검증 가능.
##
const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_audio ===")
    var results := [_check_buses(), _check_reverb(), _check_volume(), _check_bgm_paths()]
    var passed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            print("  reason: %s" % r.reason)
        else:
            passed += 1
    print("=== %d/%d passed ===" % [passed, results.size()])
    get_tree().quit(0 if passed == results.size() else 1)


## Music/SFX 버스가 존재하고 Master 로 라우팅되는가.
func _check_buses() -> Dictionary:
    var m := AudioServer.get_bus_index(Audio.MUSIC_BUS)
    var s := AudioServer.get_bus_index(Audio.SFX_BUS)
    if m == -1:
        return {"name": "buses_exist", "status": FAIL, "reason": "Music 버스 없음"}
    if s == -1:
        return {"name": "buses_exist", "status": FAIL, "reason": "SFX 버스 없음"}
    if AudioServer.get_bus_send(m) != "Master":
        return {"name": "buses_exist", "status": FAIL, "reason": "Music→Master 라우팅 아님"}
    return {"name": "buses_exist", "status": PASS, "reason": ""}


## Music 버스 첫 이펙트가 리버브인가(공간감의 핵심).
func _check_reverb() -> Dictionary:
    var m := AudioServer.get_bus_index(Audio.MUSIC_BUS)
    if m == -1 or AudioServer.get_bus_effect_count(m) < 1:
        return {"name": "reverb_present", "status": FAIL, "reason": "Music 버스 이펙트 없음"}
    if not (AudioServer.get_bus_effect(m, 0) is AudioEffectReverb):
        return {"name": "reverb_present", "status": FAIL, "reason": "첫 이펙트가 리버브 아님"}
    return {"name": "reverb_present", "status": PASS, "reason": ""}


## set_bgm_volume(50) 이 Music 버스 게인(dB)으로 정확히 반영되는가.
func _check_volume() -> Dictionary:
    Audio.set_bgm_volume(50.0)
    var m := AudioServer.get_bus_index(Audio.MUSIC_BUS)
    var db := AudioServer.get_bus_volume_db(m)
    var expected := linear_to_db(0.5)
    Audio.set_bgm_volume(100.0)   # 원복
    if absf(db - expected) > 0.5:
        return {"name": "volume_to_bus", "status": FAIL,
            "reason": "50%% 입력이 버스 게인에 미반영(실제 %.2f / 기대 %.2f)" % [db, expected]}
    return {"name": "volume_to_bus", "status": PASS, "reason": ""}


## bgm_director 의 모든 씬→곡 매핑 경로가 실재하는 리소스인가(import 누락·오타 회귀 방지).
func _check_bgm_paths() -> Dictionary:
    var missing: Array[String] = []
    for nm in BgmDirector.SCENE_BGM:
        var path := String(BgmDirector.SCENE_BGM[nm])
        if not ResourceLoader.exists(path):
            missing.append("%s→%s" % [nm, path.get_file()])
    if not ResourceLoader.exists(BgmDirector.NIGHT_BGM):
        missing.append("NIGHT_BGM→%s" % String(BgmDirector.NIGHT_BGM).get_file())
    if not missing.is_empty():
        return {"name": "bgm_paths_exist", "status": FAIL, "reason": "없는 곡: %s" % ", ".join(missing)}
    return {"name": "bgm_paths_exist", "status": PASS, "reason": ""}
