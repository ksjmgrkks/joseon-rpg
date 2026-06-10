extends Control
##
## 엔딩 — 메인 퀘스트(호환 두령) 완결 후 두루마리 에필로그.
## 타자기 텍스트 → 크레딧 페이드 인 → '처음 화면으로'.
## 입력(클릭/공격/점프)으로 타자기 스킵 가능.
##

const EPILOGUE := """호환이 그치고, 산골에 다시 등불이 켜졌다.

두령의 어금니는 대장간 화로에서 녹아
호미가 되었다 전한다.

떠돌이 무사는 갓끈을 고쳐 매고,
아무 일 없었다는 듯 길을 나섰다.

— 후일 사람들은 이 일을 일러
   호환기담(虎患奇譚)이라 하였다."""

const CHAR_INTERVAL := 0.045

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
    # 두루마리 아트가 있으면 패널 뒤에 깐다 (없으면 어두운 한지 배경만)
    if ResourceLoader.exists("res://assets/ui/ending_scroll.png"):
        scroll_art.texture = load("res://assets/ui/ending_scroll.png")
        scroll_art.visible = true
    story.text = ""
    credits.modulate.a = 0.0
    credits.text = "「호환기담」\n\n제작 — 규성 & Claude\n그림·소리 — 생성 파이프라인 (tools/pixel · tools/audio)\n글꼴 — Galmuri (SIL OFL)\n엔진 — Godot 4.6.3"
    menu_btn.visible = false
    menu_btn.pressed.connect(_on_menu)
    Audio.play_sfx(Sfx.JINGLE)


func _process(delta: float) -> void:
    if _done:
        return
    if _shown >= EPILOGUE.length():
        _finish()
        return
    _timer -= delta
    if _timer <= 0.0:
        _timer = CHAR_INTERVAL
        _shown += 1
        story.text = EPILOGUE.substr(0, _shown)


func _unhandled_input(event: InputEvent) -> void:
    if _done:
        return
    var pressed: bool = (event is InputEventMouseButton) and event.is_pressed()
    if event.is_action_pressed("attack") or event.is_action_pressed("jump") or event.is_action_pressed("interact") or pressed:
        _shown = EPILOGUE.length()
        story.text = EPILOGUE
        _finish()


func _finish() -> void:
    _done = true
    var tw := create_tween()
    tw.tween_property(credits, "modulate:a", 1.0, 1.2)
    tw.tween_callback(func() -> void: menu_btn.visible = true)


func _on_menu() -> void:
    Audio.play_sfx(Sfx.UI)
    SceneManager.change_scene("res://scenes/ui/MainMenu.tscn")
