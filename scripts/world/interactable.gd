extends Area2D
class_name Interactable
##
## 조사할 수 있는 지형지물 — 플레이어가 사거리에 들어오면 머리 위에 '△(조사)' 프롬프트가
## 뜨고, interact 키를 누르면 대사(dialogue)를 재생하거나 플래그를 세운다.
##
## auto_dialogue 가 '밟으면 자동'이라면, 이건 '가까이서 버튼을 눌러야' 발동하는 능동적 상호작용.
## 지형지물이 그저 배경이 아니라 만질 수 있는 세계가 되게 한다(#2). once 면 한 번 조사 후
## 프롬프트가 사라진다(once_flag 로 세이브 넘어 1회 보장 — 엔딩 단서·진행 플래그 연동).
##
## 배치는 stage.gd `_build_interactables` 가 JSON `interactables` 항목으로 짓는다:
##   {"tex":"well","x":700,"y":660,"scale":1.5,"radius":40,
##    "dialogue":"res://assets/dialogue/haewon/well.json","flag":"haewon_well_seen","once":true}
##

@export_file("*.json") var dialogue_path: String = ""
@export var flag_on_use: String = ""            # 조사 시 세울 플래그(엔딩 단서·진행 등)
@export var once: bool = true
@export var once_flag: String = ""              # 세이브 넘어 1회 보장(비면 런타임 _used 만)
@export var prompt_offset: Vector2 = Vector2(0, -52)

var _in_range: bool = false
var _used: bool = false
var _prompt: Label = null


func _ready() -> void:
    monitoring = true
    body_entered.connect(_on_enter)
    body_exited.connect(_on_exit)
    if once_flag != "" and Flags.has_flag(once_flag):
        _used = true
    _build_prompt()


func _build_prompt() -> void:
    var lbl := Label.new()
    lbl.text = "△"                              # '조사' 힌트 — 가까이 가면 나타난다
    lbl.add_theme_font_size_override("font_size", 18)
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.position = prompt_offset
    lbl.z_index = 40
    lbl.visible = false
    add_child(lbl)
    _prompt = lbl


func _on_enter(body: Node) -> void:
    if not body.is_in_group("player"):
        return
    _in_range = true
    _refresh_prompt()


func _on_exit(body: Node) -> void:
    if not body.is_in_group("player"):
        return
    _in_range = false
    _refresh_prompt()


func _refresh_prompt() -> void:
    if _prompt:
        _prompt.visible = _in_range and not (_used and once)


func _unhandled_input(event: InputEvent) -> void:
    if not _in_range or Dialogue.is_active():
        return
    if _used and once:
        return
    if event.is_action_pressed("interact"):
        _trigger()


## 실제 상호작용 발동 — 테스트에서 키 입력 없이 직접 호출할 수 있게 분리.
func _trigger() -> void:
    _used = true
    if once_flag != "":
        Flags.set_flag(once_flag, true)
    if flag_on_use != "":
        Flags.set_flag(flag_on_use, true)
    _refresh_prompt()
    if not dialogue_path.is_empty() and not Dialogue.is_active():
        Dialogue.start(dialogue_path)
