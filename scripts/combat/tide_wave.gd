extends Area2D
class_name TideWave
##
## 밀물 — 보스가 밀어보내는 낮은 물결. 코드 생성(에셋 불필요).
##
## 판정이 **지면에 붙은 낮은 띠**라서 옆으로 도망쳐도 결국 따라잡힌다.
## 유일한 회피법은 **점프로 넘기**. 보스 패턴에 '수직 회피'를 강제해 단조로움을 깬다.
##

const BODY_W := 46.0
const BODY_H := 34.0        # 낮다 = 점프로 넘을 수 있다

var damage: float = 12.0
var knockback: float = 260.0
var velocity: Vector2 = Vector2.ZERO
var _life: float = 4.0
var _hit_done: bool = false


## parent 에 물결 하나를 흘려보낸다. pos = 지면 접점, dir = +1(오른쪽)/-1(왼쪽).
static func spawn(parent: Node, pos: Vector2, dir: float, dmg: float,
        speed: float = 250.0, life: float = 4.0, knock: float = 260.0) -> Area2D:
    if parent == null or not is_instance_valid(parent):
        return null
    var w := TideWave.new()
    w.damage = dmg
    w.knockback = knock
    w.velocity = Vector2(speed * signf(dir), 0.0)
    w._life = life
    w.collision_mask = 1              # 플레이어(layer 1) 감지
    parent.add_child(w)
    w.global_position = pos
    return w


func _ready() -> void:
    z_index = 7
    body_entered.connect(_on_body_entered)
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(BODY_W, BODY_H)
    cs.shape = shape
    cs.position = Vector2(0, -BODY_H * 0.5)
    add_child(cs)
    _draw_wave()


## 물마루 — 채워진 물 덩이 위에 초승달 3겹 + 앞머리 거품. 얇은 선만 있으면
## 물결이 아니라 아치처럼 보여서, 아래를 물빛으로 채워 부피를 준다.
func _draw_wave() -> void:
    var dir := 1.0 if velocity.x >= 0.0 else -1.0
    # 물마루 아래를 채우는 덩이(지면까지) — 부피감
    var fill := Polygon2D.new()
    var poly := PackedVector2Array()
    for i in range(9):
        var ft := i / 8.0
        poly.append(Vector2(dir * lerpf(-26.0, 22.0, ft), -BODY_H * sin(PI * ft) * 0.9 - 2.0))
    poly.append(Vector2(dir * 22.0, 2.0))
    poly.append(Vector2(dir * -26.0, 2.0))
    fill.polygon = poly
    fill.color = Color(SkillFx.WATER_DEEP.r, SkillFx.WATER_DEEP.g, SkillFx.WATER_DEEP.b, 0.75)
    fill.z_index = 6
    add_child(fill)
    for L in [[13.0, Color(SkillFx.WATER_DEEP.r, SkillFx.WATER_DEEP.g, SkillFx.WATER_DEEP.b, 0.55)],
            [8.0, SkillFx.WATER], [3.5, SkillFx.FOAM]]:
        var line := Line2D.new()
        line.width = float(L[0])
        line.default_color = L[1]
        var pts := PackedVector2Array()
        for i in range(9):
            var t := i / 8.0
            # 뒤(-dir)에서 앞(+dir)으로 솟았다 말리는 곡선
            pts.append(Vector2(dir * lerpf(-26.0, 22.0, t), -BODY_H * sin(PI * t) * 0.9 - 2.0))
        line.points = pts
        line.z_index = 7
        add_child(line)
        # 물결이 살아 일렁이도록 위아래로 아주 조금 흔든다
        var tw := line.create_tween().set_loops()
        tw.tween_property(line, "position:y", -3.0, 0.22)
        tw.tween_property(line, "position:y", 0.0, 0.22)
    # PixelLab 물마루 스프라이트 — 코드 라인 위에 얹어 부피를 준다.
    SkillFx.tide_crest_art(self, dir)
    # 앞머리에서 튀는 물보라
    var spray := Timer.new()
    spray.wait_time = 0.12
    spray.autostart = true
    spray.timeout.connect(_spray)
    add_child(spray)


func _spray() -> void:
    if not is_instance_valid(self) or get_parent() == null:
        return
    var dir := 1.0 if velocity.x >= 0.0 else -1.0
    var from := global_position + Vector2(dir * 20.0, -10.0)
    SkillFx._mote(get_parent(), from, from + Vector2(dir * randf_range(10.0, 34.0), randf_range(-30.0, -6.0)),
        randf_range(1.4, 2.4), SkillFx.FOAM, randf_range(0.24, 0.4), 8)


func _physics_process(delta: float) -> void:
    if Dialogue and Dialogue.is_active():
        return                        # 대화 중 정지
    global_position += velocity * delta
    _life -= delta
    if _life <= 0.0:
        _fade_out()


func _fade_out() -> void:
    set_physics_process(false)
    monitoring = false
    var tw := create_tween()
    tw.tween_property(self, "modulate:a", 0.0, 0.3)
    tw.tween_callback(queue_free)


func _on_body_entered(body: Node) -> void:
    if _hit_done or not body.is_in_group("player"):
        return
    _hit_done = true                  # 물결 하나당 1회만
    var hc: HealthComponent = body.get_node_or_null("HealthComponent")
    # 이미 무적(직전 피격 직후)이면 피해·넉백·효과음 생략 — 다른 패턴과 겹쳐도 안 끊기게.
    if hc != null and hc.is_invulnerable():
        return
    if hc:
        hc.take_damage(damage, self)
    if "velocity" in body:
        body.velocity.x = knockback * signf(velocity.x)
        body.velocity.y = -150.0
    Audio.play_sfx(Sfx.HURT)
    ScreenFx.shake(4.0, 0.12)
