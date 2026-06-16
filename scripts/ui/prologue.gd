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
    "스무 해 전, 큰 흉년이 이 산골을 덮쳤다.\n굶주린 마을은 산신당을 헐어 그 재목으로 곳간을 지었다.",
    "당에는 마을을 지키던 늙은 범이 깃들어 있었고,\n무당 단(丹)이 그 범을 사당에 매어 액을 막고 있었다.",
    "사당이 불타던 밤, 매임이 풀린 범은 한(恨)이 되었다.\n달래려 불 속에 뛰어든 무당은 끝내 돌아오지 못했다.",
    "그리고 스무 해 뒤, 그날의 불을 기억하는 한 사내가\n아비의 환도를 찾아 고개를 넘는다.",
    "…이것은 그 칼이 끊어낼 한에 관한 이야기다.",
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
