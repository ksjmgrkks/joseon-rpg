extends Area2D
class_name StallDebris
##
## 좌판 부스러기 — 도깨비 대장이 저잣거리 좌판을 뒤엎어 던지는 나무 상자·항아리 파편.
## 코드 생성(아트 불필요). 부적 세례(SpiritOrb)와 같은 원거리 투사체 역할이지만,
## 시각·서사를 저잣거리 컨셉(나무 상자, 회전하며 날아감)으로 바꿔 다른 보스와 겹치지 않게 한다.
##

var velocity: Vector2 = Vector2.ZERO
var damage: float = 8.0
var _life: float = 3.0
var _spin_dir: float = 1.0


static func spawn(parent: Node, pos: Vector2, dir: float, dmg: float, speed: float = 220.0) -> Area2D:
    if parent == null or not is_instance_valid(parent):
        return null
    var d := StallDebris.new()
    d.damage = dmg
    d.velocity = Vector2(speed * signf(dir), -90.0)
    d._spin_dir = 1.0 if randf() > 0.5 else -1.0
    d.collision_mask = 1
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(14.0, 14.0)
    cs.shape = shape
    d.add_child(cs)
    parent.add_child(d)
    d.global_position = pos
    return d


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    z_index = 6
    var wood := Color(0.46, 0.30, 0.15, 0.95)
    var edge := Color(0.22, 0.13, 0.06, 0.9)
    var box := Polygon2D.new()
    box.polygon = PackedVector2Array([Vector2(-7, -7), Vector2(7, -7), Vector2(7, 7), Vector2(-7, 7)])
    box.color = wood
    add_child(box)
    var frame := Line2D.new()
    frame.width = 1.6
    frame.default_color = edge
    frame.points = PackedVector2Array([Vector2(-7, -7), Vector2(7, -7), Vector2(7, 7), Vector2(-7, 7), Vector2(-7, -7)])
    add_child(frame)


func _physics_process(delta: float) -> void:
    if Dialogue and Dialogue.is_active():
        return
    velocity.y += 640.0 * delta   # 던져진 물건답게 포물선을 그린다
    global_position += velocity * delta
    rotation += _spin_dir * 9.0 * delta
    _life -= delta
    if _life <= 0.0:
        queue_free()


func _on_body_entered(body: Node) -> void:
    if not body.is_in_group("player"):
        return
    var hc: HealthComponent = body.get_node_or_null("HealthComponent")
    # 이미 무적(직전 피격 직후)이면 피해·넉백·효과음 생략 — 다른 패턴과 겹쳐도 안 끊기게.
    if hc == null or not hc.is_invulnerable():
        if hc:
            hc.take_damage(damage, self)
        if "velocity" in body:
            body.velocity.x = 140.0 * signf(velocity.x)
        Audio.play_sfx(Sfx.HURT)
    queue_free()
