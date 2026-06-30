extends Node
##
## BgmDirector autoload — 현재 씬·낮밤에 맞는 BGM 자동 재생.
## 씬 스크립트 결합 없이 0.5초 폴링으로 current_scene 이름 변화를 감지한다.
## 파일이 없으면 Audio.play_bgm 이 조용히 무시하므로 안전.
##

const POLL := 0.5

const SCENE_BGM := {
    "MainMenu":  "res://assets/audio/bgm/title.wav",
    "Ending":    "res://assets/audio/bgm/title.wav",
    "VillageIntro": "res://assets/audio/bgm/village.wav",
    "Foothills":    "res://assets/audio/bgm/village.wav",
    "ForestDeep":   "res://assets/audio/bgm/forest.wav",
    "Village":   "res://assets/audio/bgm/village.wav",
    "TestLevel": "res://assets/audio/bgm/village.wav",
    "Forest":      "res://assets/audio/bgm/forest.wav",
    "ShrineRuins": "res://assets/audio/bgm/forest.wav",
    "BossArena":   "res://assets/audio/bgm/boss.wav",
    "TownMarket":       "res://assets/audio/bgm/village.wav",
    "MagistrateOffice": "res://assets/audio/bgm/forest.wav",
    "RuinedTemple":     "res://assets/audio/bgm/night.wav",
    "MountainPass":     "res://assets/audio/bgm/forest.wav",
    "SacredAltar":      "res://assets/audio/bgm/boss.wav",
    # 「해원」 6굽이 — 굽이별 전용곡으로 정서 분화.
    #   river 강가 진혼(프롤/1/2굽이) · grief 죄의 확인(3굽이) ·
    #   hollow 빈 고을 공허(5굽이) · requiem 최종 진혼·승화(6굽이/엔딩).
    #   4굽이 수문(중간보스)은 자진모리 전투곡(boss) 유지.
    "Haewon0Prologue": "res://assets/audio/bgm/haewon_river.wav",
    "Haewon1Ferry":    "res://assets/audio/bgm/haewon_river.wav",
    "Haewon2Market":   "res://assets/audio/bgm/haewon_river.wav",
    "Haewon3Village":  "res://assets/audio/bgm/haewon_grief.wav",
    "Haewon4Watergate":"res://assets/audio/bgm/boss.wav",
    "Haewon5EmptyTown":"res://assets/audio/bgm/haewon_hollow.wav",
    "Haewon6Yunseul":  "res://assets/audio/bgm/haewon_requiem.wav",
    "HaewonEnding":    "res://assets/audio/bgm/haewon_requiem.wav",
}
const NIGHT_BGM := "res://assets/audio/bgm/night.wav"
# 밤 BGM 으로 갈아타는 씬 (전투 지역은 밤에도 전투곡 유지)
const NIGHT_SCENES := { "Village": true, "TestLevel": true }

var _timer: float = 0.0
var _current: String = ""


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    if TimeManager:
        TimeManager.phase_changed.connect(func(_n: bool) -> void: _refresh())


func _process(delta: float) -> void:
    _timer -= delta
    if _timer <= 0.0:
        _timer = POLL
        _refresh()


func _refresh() -> void:
    var tree := get_tree()
    if tree == null or tree.current_scene == null:
        return
    var nm := String(tree.current_scene.name)
    var want := String(SCENE_BGM.get(nm, ""))
    if want.is_empty():
        return
    if TimeManager and TimeManager.is_night() and NIGHT_SCENES.has(nm):
        want = NIGHT_BGM
    if want == _current:
        return
    _current = want
    Audio.play_bgm(want)
