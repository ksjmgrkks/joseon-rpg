extends CanvasLayer
##
## QuestToast autoload — quest_changed 시그널을 듣고 상단 중앙에 짧은 알림을 띄움.
##   '퀘스트 시작: 호환 두령 토벌'
##   '퀘스트 완료: 잃어버린 부적'
##
## 시그널 (quest_id, current_stage, is_completed) 중 시작/완료 두 경우만 표시.
## 동일 퀘스트의 단계 전이(start→to_forest 등)는 표시 안 함 — 알림 피로 방지.
##

const SHOW_SECONDS := 2.4
const FADE_IN := 0.18
const FADE_OUT := 0.32

@onready var label: Label = $Panel/Margin/Label
@onready var panel: PanelContainer = $Panel


var _seen_started: Dictionary = {}   # quest_id -> bool (한 게임 동안 처음 시작될 때만 알림)
var _tween: Tween = null


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    panel.modulate.a = 0.0
    panel.visible = false
    QuestManager.quest_changed.connect(_on_quest_changed)


func _on_quest_changed(quest_id: String, _stage: String, is_completed: bool) -> void:
    var def := QuestManager.get_def(quest_id)
    var qname := String(def.get("name", quest_id))
    if is_completed:
        _show("퀘스트 완료: %s" % qname)
    else:
        if _seen_started.has(quest_id):
            return    # 이미 시작 알림 보낸 퀘스트 — 단계 전환은 조용히
        _seen_started[quest_id] = true
        _show("퀘스트 시작: %s" % qname)


func _show(text: String) -> void:
    label.text = text
    panel.visible = true
    Audio.play_sfx(Sfx.JINGLE)
    if _tween and _tween.is_valid():
        _tween.kill()
    _tween = create_tween()
    _tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _tween.tween_property(panel, "modulate:a", 1.0, FADE_IN)
    _tween.tween_interval(SHOW_SECONDS)
    _tween.tween_property(panel, "modulate:a", 0.0, FADE_OUT)
    _tween.tween_callback(func() -> void:
        panel.visible = false
    )


func clear_history() -> void:
    _seen_started.clear()
