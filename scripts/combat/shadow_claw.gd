extends Area2D
class_name ShadowClaw
##
## 그림자 갈퀴 — 그슨대 노괴가 지면을 훑어 보내는 긴 손. 코드 생성(아트 있으면 얹음).
##
## 판정이 **지면에 붙은 낮은 띠**라 옆으로 도망쳐도 따라잡힌다. 유일한 회피는 **점프**.
## (물 보스의 밀물과 같은 역할이지만 시각·서사가 다르다 — 물결이 아니라 뻗어오는 손.)
##

const BODY_W := 54.0
const BODY_H := 30.0          # 낮다 = 점프로 넘을 수 있다

var damage: float = 14.0
var knockback: float = 240.0
var velocity: Vector2 = Vector2.ZERO
var _life: float = 3.4
var _hit_done: bool = false


static func spawn(parent: Node, pos: Vector2, dir: float, dmg: float,
        speed: float = 330.0, life: float = 3.4) -> Area2D:
    if parent == null or not is_instance_valid(parent):
        return null
    var c := ShadowClaw.new()
    c.damage = dmg
    c.velocity = Vector2(speed * signf(dir), 0.0)
    c._life = life
    c.collision_mask = 1
    parent.add_child(c)
    c.global_position = pos
    return c


func _ready() -> void:
    z_index = 7
    body_entered.connect(_on_body_entered)
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(BODY_W, BODY_H)
    cs.shape = shape
    cs.position = Vector2(0, -BODY_H * 0.5)
    add_child(cs)
    _draw_claw()


## 손등 덩이 + 갈퀴 손가락 다섯 — 진행 방향으로 굽어 지면을 긁는다.
func _draw_claw() -> void:
    var dir := 1.0 if velocity.x >= 0.0 else -1.0
    var ink := Color(0.05, 0.04, 0.07, 0.95)
    # 어두운 숲 바닥에서 검은 실루엣만 그리면 형체가 안 읽힌다 —
    # 가장자리에 옅은 재빛 테두리를 둘러 어둠 속에서도 손 모양이 보이게 한다.
    var rim := Color(0.62, 0.60, 0.70, 0.85)
    # 손등
    var palm := Polygon2D.new()
    var pts := PackedVector2Array()
    for i in range(12):
        var a := TAU * i / 12.0
        pts.append(Vector2(cos(a) * 26.0 * dir, sin(a) * 13.0 - 12.0))
    palm.polygon = pts
    palm.color = ink
    palm.z_index = 7
    add_child(palm)
    var palm_edge := Line2D.new()
    palm_edge.width = 2.0
    palm_edge.default_color = rim
    var edge_pts := pts.duplicate()
    edge_pts.append(pts[0])
    palm_edge.points = edge_pts
    palm_edge.z_index = 8
    add_child(palm_edge)
    # 갈퀴 손가락 — 앞으로 길게 뻗어 지면을 긁는다
    for i in range(5):
        var t := float(i) / 4.0
        var f := Line2D.new()
        f.width = 5.0 - t * 1.6
        f.default_color = ink
        f.points = PackedVector2Array([
            Vector2(dir * 12.0, -14.0 + t * 8.0),
            Vector2(dir * (34.0 + t * 12.0), -20.0 + t * 14.0),
            Vector2(dir * (52.0 + t * 16.0), -6.0 + t * 6.0),
        ])
        f.z_index = 7
        add_child(f)
        # 손가락 위에 얇은 재빛 선을 덧그어 윤곽을 살린다
        var hl := Line2D.new()
        hl.width = maxf(1.2, f.width * 0.34)
        hl.default_color = rim
        hl.points = f.points
        hl.z_index = 8
        add_child(hl)
        # 손가락이 긁으며 떨린다
        var tw := f.create_tween().set_loops()
        tw.tween_property(f, "rotation", 0.06, 0.14).set_trans(Tween.TRANS_SINE)
        tw.tween_property(f, "rotation", -0.04, 0.14).set_trans(Tween.TRANS_SINE)
    # 뒤로 끌리는 그림자 자락
    var trail := Timer.new()
    trail.wait_time = 0.09
    trail.autostart = true
    trail.timeout.connect(_smoke)
    add_child(trail)


func _smoke() -> void:
    if not is_instance_valid(self) or get_parent() == null:
        return
    var dir := 1.0 if velocity.x >= 0.0 else -1.0
    var from := global_position + Vector2(-dir * 16.0, -12.0)
    SkillFx._mote(get_parent(), from, from + Vector2(-dir * randf_range(14.0, 40.0), randf_range(-34.0, -8.0)),
        randf_range(1.8, 3.2), Color(0.14, 0.12, 0.18), randf_range(0.3, 0.5), 6)


func _physics_process(delta: float) -> void:
    if Dialogue and Dialogue.is_active():
        return
    global_position += velocity * delta
    _life -= delta
    if _life <= 0.0:
        set_physics_process(false)
        monitoring = false
        var tw := create_tween()
        tw.tween_property(self, "modulate:a", 0.0, 0.3)
        tw.tween_callback(queue_free)


func _on_body_entered(body: Node) -> void:
    if _hit_done or not body.is_in_group("player"):
        return
    _hit_done = true
    var hc: HealthComponent = body.get_node_or_null("HealthComponent")
    # 이미 무적(직전 피격 직후)이면 피해·넉백·효과음 생략 — 다른 패턴과 겹쳐도 안 끊기게.
    if hc != null and hc.is_invulnerable():
        return
    if hc:
        hc.take_damage(damage, self)
    if "velocity" in body:
        body.velocity.x = knockback * signf(velocity.x)
        body.velocity.y = -140.0
    Audio.play_sfx(Sfx.HURT)
    ScreenFx.shake(5.0, 0.14)
