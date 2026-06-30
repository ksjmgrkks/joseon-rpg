extends Node
##
## Audio autoload — SFX 재발사·BGM 1개 재생 + 오디오 버스(Music/SFX) 잔향.
## 실제 오디오 파일이 없어도 호출은 no-op이라 호출부에서 안전.
##
## 버스 구조:  Master ← Music(깊은 잔향) / SFX(옅은 잔향)
##   괴담 사극의 '울림'을 버스 리버브로 부여한다. 모노 소스도 버스를 거치며
##   스테레오 공간감을 얻고, 파일 재생성 없이 실시간으로 조정된다.
##   (default_bus_layout.tres 없이 코드로 구성 — 시그널 연결과 같은 추적 우선 원칙.)
##
## 사용:
##   Audio.play_sfx(Sfx.ATTACK)
##   Audio.play_bgm("res://assets/audio/bgm/village.wav")
##   Audio.set_master_volume(80)   # 0~100 (버스 게인으로 적용)
##
## 볼륨은 버스 게인(dB)으로 적용되고 SaveManager 저장/로드와 연동된다.
##

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var _bgm_player: AudioStreamPlayer


func _ready() -> void:
    _setup_buses()
    _bgm_player = AudioStreamPlayer.new()
    _bgm_player.bus = MUSIC_BUS
    add_child(_bgm_player)
    SaveManager.save_requested.connect(_on_save)
    SaveManager.loaded.connect(_on_load)


## Master 아래 Music/SFX 버스를 코드로 구성(이미 있으면 건너뜀).
## 괴담 사극 톤 = 넓고 어두운 공간. 고역 잔향은 damping 으로 눌러 탁하지 않게,
## wet 은 보수적으로 잡아 선율/타격을 가리지 않는 선에서 '울림'만 더한다.
func _setup_buses() -> void:
    # Music: 깊은 잔향 — BGM 환경 공간감(폐사지·강가·산골의 울림)
    _ensure_reverb_bus(MUSIC_BUS, 0.62, 0.55, 0.26, 0.92, 1.0, 28.0)
    # SFX: 옅은 잔향 — 타격감은 살리되 같은 공간에 있다는 일체감만
    _ensure_reverb_bus(SFX_BUS, 0.50, 0.62, 0.10, 1.0, 0.85, 12.0)


func _ensure_reverb_bus(bus_name: String, room: float, damp: float, wet: float,
        dry: float, spread: float, predelay: float) -> void:
    if AudioServer.get_bus_index(bus_name) != -1:
        return
    var idx := AudioServer.bus_count
    AudioServer.add_bus(idx)
    AudioServer.set_bus_name(idx, bus_name)
    AudioServer.set_bus_send(idx, "Master")
    var rv := AudioEffectReverb.new()
    rv.room_size = room
    rv.damping = damp
    rv.wet = wet
    rv.dry = dry
    rv.spread = spread
    rv.predelay_msec = predelay
    AudioServer.add_bus_effect(idx, rv)


## 1회용 SFX 재생 — 파일이 없으면 조용히 무시. SFX 버스(옅은 잔향)로 보낸다.
## volume_db 로 개별 사운드 가감(예: 피격음 부각) — 버스 게인 위에 얹는 offset.
func play_sfx(path: String, volume_db: float = 0.0) -> void:
    if path.is_empty() or not ResourceLoader.exists(path):
        return
    var stream := load(path) as AudioStream
    if stream == null:
        return
    var p := AudioStreamPlayer.new()
    p.bus = SFX_BUS
    add_child(p)
    p.stream = stream
    p.volume_db = volume_db
    p.finished.connect(p.queue_free)
    p.play()


## BGM 1개 재생 (이전 BGM은 멈춤). Music 버스(깊은 잔향)로 보낸다. 파일 없으면 무시.
func play_bgm(path: String) -> void:
    if path.is_empty() or not ResourceLoader.exists(path):
        return
    var stream := load(path) as AudioStream
    if stream == null:
        return
    _bgm_player.stop()
    _bgm_player.stream = stream
    _bgm_player.play()


func stop_bgm() -> void:
    _bgm_player.stop()


## 0~100 입력을 버스 게인(dB)으로 적용. 0은 사실상 음소거(-80dB).
func set_master_volume(value: float) -> void:
    _apply_db("Master", _to_db(value))


func set_sfx_volume(value: float) -> void:
    _apply_db(SFX_BUS, _to_db(value))


func set_bgm_volume(value: float) -> void:
    _apply_db(MUSIC_BUS, _to_db(value))


func _apply_db(bus_name: String, db: float) -> void:
    var idx := AudioServer.get_bus_index(bus_name)
    if idx != -1:
        AudioServer.set_bus_volume_db(idx, db)


func _bus_db(bus_name: String) -> float:
    var idx := AudioServer.get_bus_index(bus_name)
    return AudioServer.get_bus_volume_db(idx) if idx != -1 else 0.0


func _to_db(value: float) -> float:
    var v := clampf(value, 0.0, 100.0) / 100.0
    if v <= 0.001:
        return -80.0
    return linear_to_db(v)


func _on_save(_slot: int, data: Dictionary) -> void:
    data["audio"] = {
        "master_db": _bus_db("Master"),
        "sfx_db": _bus_db(SFX_BUS),
        "bgm_db": _bus_db(MUSIC_BUS),
    }


func _on_load(_slot: int, data: Dictionary) -> void:
    var a = data.get("audio", {})
    if a is Dictionary:
        _apply_db("Master", float(a.get("master_db", 0.0)))
        _apply_db(SFX_BUS, float(a.get("sfx_db", 0.0)))
        _apply_db(MUSIC_BUS, float(a.get("bgm_db", 0.0)))
