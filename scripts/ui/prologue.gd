extends Control
##
## 오프닝 프롤로그 — 새 게임 시작 시 마을 전에 흐르는 도입 서사.
## 한 문단씩 타자기로 찍고, 입력(클릭/공격/점프/대화)으로 다음 문단 / 전체 스킵.
## 마지막 문단 후 마을(Village)로 페이드 전환.
##
## 엔딩과 같은 두루마리/한지 톤. BGM 은 BgmDirector 가 MainMenu·Ending 과 같은 title.wav 재생.
##

const VILLAGE_PATH := "res://scenes/levels/VillageIntro.tscn"

const BEATS := [
    "귀(鬼).\n사람의 한과 산천의 노여움이 엉겨 빚어진 것들을 옛사람은 그리 불렀다.",
    "스무 해 전, 큰 흉년이 이 땅을 덮쳤다.\n굶주린 자들은 산신당과 당산나무를 헐어 팔았고, 신을 저버린 땅에 귀가 들끓었다.",
    "무당 단(丹)은 마(魔)를 봉한 창 — 마창(魔槍)으로 귀를 누르며 버텼으나,\n사당이 불타던 밤 끝내 돌아오지 못했다.",
    "남겨진 것은 한 자루 마창과, 아비의 피를 이은 아들뿐.",
    "스무 해 뒤, 그는 마창을 들고 귀(鬼)가 창궐한 고개를 넘는다.",
    "…이것은 그 창이 꿰뚫을 한(恨)에 관한 기록, 귀창록(鬼槍錄)이다.",
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
