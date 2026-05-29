extends Node
##
## Audio autoload — SFX 재발사·BGM 1개 재생. 실제 오디오 파일이 없어도 호출은 no-op이라 호출부에서 안전.
##
## 사용:
##   Audio.play_sfx(Sfx.ATTACK)
##   Audio.play_bgm("res://assets/audio/bgm/village.ogg")
##   Audio.set_master_volume(80)   # 0~100
##
## 볼륨은 SaveManager 저장/로드와 자동 연동.
##

var _bgm_player: AudioStreamPlayer
var _master_db: float = 0.0
var _sfx_db: float = 0.0
var _bgm_db: float = 0.0


func _ready() -> void:
    _bgm_player = AudioStreamPlayer.new()
    _bgm_player.bus = "Master"
    add_child(_bgm_player)
    SaveManager.save_requested.connect(_on_save)
    SaveManager.loaded.connect(_on_load)


## 1회용 SFX 재생 — 파일이 없으면 조용히 무시.
func play_sfx(path: String) -> void:
    if path.is_empty() or not ResourceLoader.exists(path):
        return
    var stream := load(path) as AudioStream
    if stream == null:
        return
    var p := AudioStreamPlayer.new()
    add_child(p)
    p.stream = stream
    p.volume_db = _sfx_db + _master_db
    p.finished.connect(p.queue_free)
    p.play()


## BGM 1개 재생 (이전 BGM은 멈춤). 파일 없으면 무시.
func play_bgm(path: String) -> void:
    if path.is_empty() or not ResourceLoader.exists(path):
        return
    var stream := load(path) as AudioStream
    if stream == null:
        return
    _bgm_player.stop()
    _bgm_player.stream = stream
    _bgm_player.volume_db = _bgm_db + _master_db
    _bgm_player.play()


func stop_bgm() -> void:
    _bgm_player.stop()


## 0~100 입력을 dB 로 변환해 저장. 0은 사실상 음소거(-80dB).
func set_master_volume(value: float) -> void:
    _master_db = _to_db(value)
    if _bgm_player.playing:
        _bgm_player.volume_db = _bgm_db + _master_db


func set_sfx_volume(value: float) -> void:
    _sfx_db = _to_db(value)


func set_bgm_volume(value: float) -> void:
    _bgm_db = _to_db(value)
    if _bgm_player.playing:
        _bgm_player.volume_db = _bgm_db + _master_db


func _to_db(value: float) -> float:
    var v := clampf(value, 0.0, 100.0) / 100.0
    if v <= 0.001:
        return -80.0
    return linear_to_db(v)


func _on_save(_slot: int, data: Dictionary) -> void:
    data["audio"] = {
        "master_db": _master_db,
        "sfx_db": _sfx_db,
        "bgm_db": _bgm_db,
    }


func _on_load(_slot: int, data: Dictionary) -> void:
    var a = data.get("audio", {})
    if a is Dictionary:
        _master_db = float(a.get("master_db", 0.0))
        _sfx_db = float(a.get("sfx_db", 0.0))
        _bgm_db = float(a.get("bgm_db", 0.0))
