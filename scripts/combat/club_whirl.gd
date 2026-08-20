extends Area2D
class_name ClubWhirl
##
## 방망이 휘돌리기 — 도깨비 대장이 몸을 돌며 사방을 후려친다. 코드 생성(아트 불필요).
##
## 다른 패턴은 전부 "정면은 막힘, 등 뒤가 빈틈"이 원칙이지만, 이 패턴만은 예외 —
## 몸을 통째로 돌리는 순간이라 **양쪽 다** 맞는다(정면에 버티고 서서 등만 신경 쓰면
## 오히려 이 패턴에 크게 맞도록). 유일한 회피는 점프(판정이 낮은 띠라 넘을 수 있다).
##

const RADIUS := 62.0
const BAND_H := 30.0

var damage: float = 16.0
var knockback: float = 260.0
var _warn_time: float = 0.35
var _active_time: float = 0.5
var _col: CollisionShape2D
var _hit_done: bool = false


static func spawn(parent: Node, pos: Vector2, dmg: float, warn_time: float = 0.35,
        active_time: float = 0.5) -> Area2D:
    if parent == null or not is_instance_valid(parent):
        return null
    var w := ClubWhirl.new()
    w.damage = dmg
    w._warn_time = warn_time
    w._active_time = active_time
    w.collision_mask = 1
    w.monitoring = false
    parent.add_child(w)
    w.global_position = pos
    return w


func _ready() -> void:
    z_index = 7
    body_entered.connect(_on_body_entered)
    _col = CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(RADIUS * 2.0, BAND_H)
    _col.shape = shape
    _col.position = Vector2(0, -BAND_H * 0.5)
    _col.disabled = true
    add_child(_col)
    _draw_whirl()
    _run()


## 몸통 중심으로 방망이 자국 4갈래가 도는 잔상 — 나무 빛깔로 방향성 없음을 강조.
func _draw_whirl() -> void:
    var wood := Color(0.42, 0.28, 0.14, 0.92)
    var rim := Color(0.78, 0.62, 0.30, 0.85)
    var root := self
    for i in range(4):
        var a0 := TAU * i / 4.0
        var arc := Line2D.new()
        arc.width = 9.0
        arc.default_color = wood
        var pts := PackedVector2Array()
        var seg := 10
        for s in range(seg + 1):
            var a := a0 + (TAU / 4.0) * (float(s) / float(seg))
            pts.append(Vector2(cos(a) * RADIUS, sin(a) * (BAND_H * 0.5)))
        arc.points = pts
        root.add_child(arc)
        var hl := Line2D.new()
        hl.width = 3.0
        hl.default_color = rim
        hl.points = pts
        root.add_child(hl)
    var tw := root.create_tween()
    tw.tween_property(root, "scale", Vector2(0.3, 0.3), 0.0)
    tw.tween_property(root, "scale", Vector2.ONE, _warn_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    var spin_tw := root.create_tween().set_loops()
    spin_tw.tween_property(root, "rotation", TAU, 0.45).set_trans(Tween.TRANS_LINEAR)


func _run() -> void:
    await get_tree().create_timer(_warn_time).timeout
    if not is_instance_valid(self):
        return
    monitoring = true
    if _col:
        _col.disabled = false
    await get_tree().create_timer(_active_time).timeout
    if not is_instance_valid(self):
        return
    monitoring = false
    if _col:
        _col.disabled = true
    var tw := create_tween()
    tw.tween_property(self, "modulate:a", 0.0, 0.2)
    tw.tween_callback(queue_free)


func _physics_process(_delta: float) -> void:
    if Dialogue and Dialogue.is_active():
        return


func _on_body_entered(body: Node) -> void:
    if _hit_done or not body.is_in_group("player"):
        return
    _hit_done = true
    var hc: HealthComponent = body.get_node_or_null("HealthComponent")
    if hc:
        hc.take_damage(damage, self)
    if "velocity" in body:
        var dir := signf(body.global_position.x - global_position.x)
        body.velocity.x = knockback * (dir if dir != 0.0 else 1.0)
        body.velocity.y = -160.0
    Audio.play_sfx(Sfx.HURT)
    ScreenFx.shake(8.0, 0.2)
