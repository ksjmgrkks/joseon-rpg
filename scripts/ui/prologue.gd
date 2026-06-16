extends Control
##
## 오프닝 프롤로그 — 새 게임 시작 시 마을 전에 흐르는 도입 서사.
## 한 문단씩 타자기로 찍고, 입력(클릭/공격/점프/대화)으로 다음 문단 / 전체 스킵.
## 마지막 문단 후 마을(Village)로 페이드 전환.
##
## 엔딩과 같은 두루마리/한지 톤. BGM 은 BgmDirector 가 MainMenu·Ending 과 같은 title.wav 재생.
##

const VILLAGE_PATH := "res://scenes/levels/Village.tscn"

const BEATS := [
    "호환(虎患).\n사람을 해치는 호랑이의 재앙을 옛사람은 그리 불렀다.",
    "깊은 산골 마을에 그 재앙이 돌기 시작한 것은\n달이 이지러지던 어느 가을부터였다.",
    "밤이면 사당 터 쪽에서 짐승의 울음이 들리고,\n사람들은 문을 걸어 잠근 채 새벽을 기다렸다.",
    "그 무렵, 갓을 눌러쓴 떠돌이 무사 하나가\n고개를 넘어 마을로 들어섰다.",
    "…이것은 그 칼이 끊어낸 한(恨)에 관한 이야기다.",
]

const CHAR_INTERVAL := 0.05
const HOLD_AFTER := 1.1     # 한 문단 다 찍힌 뒤 자동으로 다음까지 대기(초)

@onready var label: Label = $Center/Text
@onready var hint: Label = $Hint

var _beat: int = 0
var _shown: int = 0
var _char_timer: float = 0.0
var _hold_timer: float = 0.0
var _beat_done: bool = false
var _finishing: bool = false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().paused = false
    label.text = ""
    hint.text = "▶ 눌러서 넘기기"
    hint.modulate.a = 0.0


func _process(delta: float) -> void:
    if _finishing:
        return
    if not _beat_done:
        _char_timer -= delta
        if _char_timer <= 0.0:
            _char_timer = CHAR_INTERVAL
            _shown += 1
            label.text = BEATS[_beat].substr(0, _shown)
            if _shown >= BEATS[_beat].length():
                _beat_done = true
                _hold_timer = HOLD_AFTER
                hint.modulate.a = 0.6
    else:
        _hold_timer -= delta
        if _hold_timer <= 0.0:
            _next_beat()


func _unhandled_input(event: InputEvent) -> void:
    if _finishing:
        return
    var pressed := (event is InputEventMouseButton and event.is_pressed())
    var act := event.is_action_pressed("attack") or event.is_action_pressed("jump") \
        or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
    if not (pressed or act):
        return
    get_viewport().set_input_as_handled()
    if not _beat_done:
        # 아직 찍는 중이면 즉시 완성
        _shown = BEATS[_beat].length()
        label.text = BEATS[_beat]
        _beat_done = true
        _hold_timer = HOLD_AFTER
        hint.modulate.a = 0.6
    else:
        _next_beat()


func _next_beat() -> void:
    _beat += 1
    if _beat >= BEATS.size():
        _finish()
        return
    _shown = 0
    _char_timer = 0.0
    _beat_done = false
    hint.modulate.a = 0.0
    label.text = ""
    Audio.play_sfx(Sfx.UI)


func _finish() -> void:
    _finishing = true
    SceneManager.change_scene(VILLAGE_PATH)
