extends Node
##
## SceneManager autoload — 씬 전환 + 페이드 인/아웃.
##
## 사용:
##   SceneManager.change_scene("res://scenes/levels/TestLevel.tscn")
##   SceneManager.change_scene("res://scenes/ui/MainMenu.tscn", 0.3)
##
## 페이드는 layer 100의 ColorRect로 화면 전체를 덮는다. process_mode=ALWAYS 라
## 일시정지/저장 화면에서도 동작.
##

const DEFAULT_FADE := 0.4

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect


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


## 화면을 페이드 아웃 → 씬 교체 → 페이드 인. 일시정지 상태도 자동 해제.
func change_scene(path: String, fade_seconds: float = DEFAULT_FADE) -> bool:
    if path.is_empty():
        return false
    await _fade_to(1.0, fade_seconds)
    get_tree().paused = false
    var err := get_tree().change_scene_to_file(path)
    if err != OK:
        push_error("[Scene] change_scene_to_file failed: %s (err %d)" % [path, err])
        await _fade_to(0.0, fade_seconds)
        return false
    # 새 씬이 _ready 끝낼 시간을 한 프레임 줌
    await get_tree().process_frame
    await _fade_to(0.0, fade_seconds)
    return true


func _fade_to(target_alpha: float, dur: float) -> void:
    var tween := create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(_fade_rect, "color:a", target_alpha, dur)
    await tween.finished
