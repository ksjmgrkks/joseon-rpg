extends Label
class_name FloatingNumber
##
## 부유 데미지/HP 숫자 — 화면 위로 떠올라 사라짐.
## 생성: FloatingNumber.spawn(parent_node2d, world_pos, "-15", Color(1, .5, .5))
##

const LIFETIME := 0.9
const RISE := 36.0


func _ready() -> void:
    add_theme_font_size_override("font_size", 18)
    add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    add_theme_constant_override("outline_size", 3)
    var tween := create_tween()
    tween.tween_property(self, "position:y", position.y - RISE, LIFETIME)
    tween.parallel().tween_property(self, "modulate:a", 0.0, LIFETIME * 0.6).set_delay(LIFETIME * 0.4)
    await tween.finished
    queue_free()


static func spawn(parent: Node, world_pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
    if parent == null:
        return
    var n := FloatingNumber.new()
    n.text = text
    n.modulate = color
    n.position = world_pos + Vector2(-12, -40)
    parent.add_child(n)
