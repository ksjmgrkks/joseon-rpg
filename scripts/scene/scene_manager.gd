extends Node
##
## SceneManager autoload — 씬 전환 + 페이드 인/아웃 + 명명 스폰 지점.
##
## 사용:
##   SceneManager.change_scene("res://scenes/levels/TestLevel.tscn")
##   SceneManager.change_scene_to("res://scenes/levels/Village.tscn", &"from_field")
##
## 페이드는 layer 100의 ColorRect로 화면 전체를 덮는다. process_mode=ALWAYS 라
## 일시정지/저장 화면에서도 동작.
##
## change_scene_to 는 _pending_entry 를 기억해 두고, 새 씬이 _ready 끝낸 뒤
## "level_entry" 그룹에서 name이 일치하는 Marker2D 위치로 그룹 "player" 의
## 첫 번째 노드를 옮긴다. 매치 실패 시 씬 기본 위치 유지.
##

const DEFAULT_FADE := 0.4
# 슬롯 0 은 autosave 약속 — SaveManager 코멘트와 일치.
const AUTOSAVE_SLOT := 0

# 메뉴/타이틀 등 게임플레이가 아닌 씬은 자동 저장에서 제외.
const NON_GAMEPLAY_SCENES := {
    "MainMenu": true,
    "SettingsMenu": true,
    "Ending": true,
    "Prologue": true,
    "Clear": true,
}

@export var autosave_on_scene_change: bool = true

# 헤드리스 테스트가 대화 change_scene 액션 등으로 씬이 갈리는 것을 막을 때 끔.
var transitions_enabled: bool = true

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect

# 다음 씬에서 사용할 LevelEntry 이름. change_scene_to 호출 직후 set,
# 새 씬 _ready 후 한 프레임 뒤에 적용 + 클리어.
var _pending_entry: StringName = &""


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _fade_layer = CanvasLayer.new()
    _fade_layer.layer = 100
    add_child(_fade_layer)
    _fade_rect = ColorRect.new()
    _fade_rect.color = Color(0.05, 0.04, 0.03, 0.0)
    _fade_rect.anchor_right = 1.0
    _fade_rect.anchor_bottom = 1.0
    _fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fade_layer.add_child(_fade_rect)


## 화면 페이드 후 씬 교체. 명명 스폰 사용 안 함(현재 위치 유지).
func change_scene(path: String, fade_seconds: float = DEFAULT_FADE) -> bool:
    return await _do_change(path, &"", fade_seconds)


## 씬 교체 후 entry 이름에 맞는 LevelEntry 로 플레이어를 옮긴다.
func change_scene_to(path: String, entry: StringName, fade_seconds: float = DEFAULT_FADE) -> bool:
    return await _do_change(path, entry, fade_seconds)


func _do_change(path: String, entry: StringName, fade_seconds: float) -> bool:
    if path.is_empty() or not transitions_enabled:
        return false
    _pending_entry = entry
    # 떠나기 전 마지막 씬이 게임플레이라면 슬롯 0 (autosave) 에 저장.
    _try_autosave()
    await _fade_to(1.0, fade_seconds)
    get_tree().paused = false
    var err := get_tree().change_scene_to_file(path)
    if err != OK:
        push_error("[Scene] change_scene_to_file failed: %s (err %d)" % [path, err])
        _pending_entry = &""
        await _fade_to(0.0, fade_seconds)
        return false
    # 새 씬이 _ready 끝낼 시간을 한 프레임 줌
    await get_tree().process_frame
    _apply_pending_entry()
    # 진입 즉시 체크포인트 — 새 씬이 게임플레이면 슬롯 0 자동 저장.
    # (첫 스테이지처럼 '떠난 적 없는' 구간도 사망 시 이어하기가 되도록.)
    _try_autosave()
    await _fade_to(0.0, fade_seconds)
    return true


func _try_autosave() -> void:
    if not autosave_on_scene_change:
        return
    if SaveManager == null:
        return
    var tree := get_tree()
    if tree == null or tree.current_scene == null:
        return
    var nm := String(tree.current_scene.name)
    if NON_GAMEPLAY_SCENES.has(nm):
        return
    SaveManager.save(AUTOSAVE_SLOT)


func _apply_pending_entry() -> void:
    if _pending_entry == &"":
        return
    var tree := get_tree()
    var entries := tree.get_nodes_in_group("level_entry")
    var match_node: Node2D = null
    for n in entries:
        if n is Node2D and StringName(n.name) == _pending_entry:
            match_node = n
            break
    if match_node == null:
        _pending_entry = &""
        return
    var players := tree.get_nodes_in_group("player")
    if players.is_empty():
        _pending_entry = &""
        return
    var player := players[0] as Node2D
    if player:
        player.global_position = match_node.global_position
    _pending_entry = &""


func _fade_to(target_alpha: float, dur: float) -> void:
    var tween := create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(_fade_rect, "color:a", target_alpha, dur)
    await tween.finished
