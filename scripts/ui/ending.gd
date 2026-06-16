extends Control
##
## 엔딩 — 메인 퀘스트(호환 두령) 완결 후 두루마리 에필로그.
## 타자기 텍스트 → 크레딧 페이드 인 → '처음 화면으로'.
## 입력(클릭/공격/점프)으로 타자기 스킵 가능.
##

const EPILOGUE_BASE := """신산 꼭대기, 재앙의 근원이 마침내 스러졌다.

마창(魔槍)이 꿰뚫은 것은 짐승도, 귀(鬼)도 아니었다.
스무 해를 떠돌던 한(恨), 그리고 아비가 못다 푼 약속이었다.

사내는 헐벗은 신당 터에 창을 꽂고,
그 위에 새 당집을 세워 넋들을 달랬다.

귀가 잦아든 땅에 다시 사람이 깃들고,
사람들은 이 일을 일러 귀창록(鬼槍錄)이라 적었다."""

# 사이드 퀘스트 전부 완료 시 — 은혜의 문단
const EPILOGUE_ALL_SIDES := """

무사가 마을에 남긴 것은 칼자국만이 아니었다.
임자 찾은 부적과 서찰, 약방의 약초 광주리,
다시 불 댕긴 대장간의 풀무 소리 —
작은 은혜들이 산골의 봄을 앞당겼다."""

# 일부만 도왔을 때 — 여운의 문단
const EPILOGUE_SOME_SIDES := """

마을 사람들은 두고두고 아쉬워했다.
그 길손에게 미처 다 갚지 못한
신세가 남았노라고."""

const EPILOGUE_TAIL := """

마창잡이는 갓끈을 고쳐 매고,
아무 일 없었다는 듯 다음 고개를 향했다.

— 귀가 있는 곳에 그 창이 닿으리니,
   이 또한 귀창록(鬼槍錄)의 한 장(章)이라."""

const SIDE_QUESTS := ["side_lost_charm", "side_meet_blacksmith", "side_collect_herbs", "side_lost_scroll"]

const CHAR_INTERVAL := 0.045

var _epilogue: String = ""

@onready var story: Label = $Scroll/Margin/VBox/Story
@onready var credits: Label = $Scroll/Margin/VBox/Credits
@onready var menu_btn: Button = $Scroll/Margin/VBox/MenuBtn
@onready var scroll_art: TextureRect = $ScrollArt

var _shown: int = 0
var _timer: float = 0.0
var _done: bool = false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().paused = false
    # 사이드 퀘스트 완료 수에 따라 에필로그 분기
    var done := 0
    for q in SIDE_QUESTS:
        if QuestManager.is_completed(q):
            done += 1
    _epilogue = EPILOGUE_BASE
    if done >= SIDE_QUESTS.size():
        _epilogue += EPILOGUE_ALL_SIDES
    elif done >= 1:
        _epilogue += EPILOGUE_SOME_SIDES
    _epilogue += EPILOGUE_TAIL
    # 두루마리 아트가 있으면 패널 뒤에 깐다 (없으면 어두운 한지 배경만)
    if ResourceLoader.exists("res://assets/ui/ending_scroll.png"):
        scroll_art.texture = load("res://assets/ui/ending_scroll.png")
        scroll_art.visible = true
    story.text = ""
    credits.modulate.a = 0.0
    credits.text = "「귀창록」(鬼槍錄)\n\n제작 — 규성 & Claude\n그림·소리 — 생성 파이프라인 (tools/pixel · tools/audio)\n글꼴 — Galmuri (SIL OFL)\n엔진 — Godot 4.6.3"
    menu_btn.visible = false
    menu_btn.pressed.connect(_on_menu)
    Audio.play_sfx(Sfx.JINGLE)


func _process(delta: float) -> void:
    if _done:
        return
    if _shown >= _epilogue.length():
        _finish()
        return
    _timer -= delta
    if _timer <= 0.0:
        _timer = CHAR_INTERVAL
        _shown += 1
        story.text = _epilogue.substr(0, _shown)


func _unhandled_input(event: InputEvent) -> void:
    if _done:
        return
    var pressed: bool = (event is InputEventMouseButton) and event.is_pressed()
    if event.is_action_pressed("attack") or event.is_action_pressed("jump") or event.is_action_pressed("interact") or pressed:
        _shown = _epilogue.length()
        story.text = _epilogue
        _finish()


func _finish() -> void:
    _done = true
    var tw := create_tween()
    tw.tween_property(credits, "modulate:a", 1.0, 1.2)
    tw.tween_callback(func() -> void: menu_btn.visible = true)


func _on_menu() -> void:
    Audio.play_sfx(Sfx.UI)
    SceneManager.change_scene("res://scenes/ui/MainMenu.tscn")
