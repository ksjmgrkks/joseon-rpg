extends Area2D
class_name SpiritOrb
##
## 영혼 구슬 — 저승사자가 쏘는 원거리 투사체. 수평 비행, 플레이어 적중 시 피해.
## 코드로 생성(별도 에셋 불필요). 점프·회피로 피할 수 있게 느릿하게 난다.
##

var velocity: Vector2 = Vector2.ZERO
var damage: float = 7.0
var _life: float = 3.0


## 런타임 생성 — parent(씬)에 구슬 하나를 쏜다.
static func spawn(parent: Node, pos: Vector2, dir: float, dmg: float, speed: float = 230.0) -> Area2D:
    if parent == null or not is_instance_valid(parent):
        return null
    var orb := SpiritOrb.new()
    orb.damage = dmg
    orb.velocity = Vector2(speed * signf(dir), 0.0)
    orb.collision_mask = 1            # 플레이어(CharacterBody2D, layer 1) 감지
    var cs := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = 8.0
    cs.shape = shape
    orb.add_child(cs)
    parent.add_child(orb)
    orb.global_position = pos
    return orb


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    z_index = 6
    # 시각 — 푸른 영혼 빛 (외곽 옅은 + 밝은 core)
    var halo := Polygon2D.new()
    halo.polygon = _circle(9.0)
    halo.color = Color(0.25, 0.42, 0.55, 0.55)
    add_child(halo)
    var core := Polygon2D.new()
    core.polygon = _circle(4.0)
    core.color = Color(0.78, 0.86, 0.95, 0.95)
    add_child(core)
    # 일렁임
    var tw := create_tween().set_loops()
    tw.tween_property(halo, "scale", Vector2(1.3, 1.3), 0.4)
    tw.tween_property(halo, "scale", Vector2(1.0, 1.0), 0.4)


func _circle(r: float) -> PackedVector2Array:
    var pts := PackedVector2Array()
    for i in range(10):
        var a := TAU * i / 10.0
        pts.append(Vector2(cos(a), sin(a)) * r)
    return pts


func _physics_process(delta: float) -> void:
    if Dialogue and Dialogue.is_active():
        return                      # 대화 중 투사체도 정지
    global_position += velocity * delta
    _life -= delta
    if _life <= 0.0:
        queue_free()


func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        var hc: HealthComponent = body.get_node_or_null("HealthComponent")
        if hc:
            hc.take_damage(damage, self)
        if "velocity" in body:
            body.velocity.x = 140.0 * signf(velocity.x)
        Audio.play_sfx(Sfx.HURT)
        queue_free()
