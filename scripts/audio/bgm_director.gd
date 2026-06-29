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
    # 「해원」 6굽이 — 강·밤·진혼의 비장한 톤. 보스 굽이(수문/윤슬)는 전투곡, 엔딩은 잔잔.
    "Haewon0Prologue": "res://assets/audio/bgm/night.wav",
    "Haewon1Ferry":    "res://assets/audio/bgm/night.wav",
    "Haewon2Market":   "res://assets/audio/bgm/night.wav",
    "Haewon3Village":  "res://assets/audio/bgm/night.wav",
    "Haewon4Watergate":"res://assets/audio/bgm/boss.wav",
    "Haewon5EmptyTown":"res://assets/audio/bgm/night.wav",
    "Haewon6Yunseul":  "res://assets/audio/bgm/boss.wav",
    "HaewonEnding":    "res://assets/audio/bgm/title.wav",
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
