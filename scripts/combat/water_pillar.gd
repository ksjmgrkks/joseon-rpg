extends Area2D
class_name WaterPillar
##
## 물기둥 — 보스가 바닥에서 솟구치게 하는 장판 공격. 코드 생성(에셋 불필요).
##
## 두 박자로 나뉜다:
##   ① 예고(warn_time): 바닥에 물문양이 번지기만 하고 **판정 없음** → 플레이어가 비켜설 시간.
##   ② 분출(active_time): 물기둥이 솟으며 판정 켜짐. 좁고 높아서 옆으로 걸어 나가면 피한다.
##
## 회피법: 옆으로 이동(점프로는 못 피함 — 기둥이 높다).
##

const WIDTH := 34.0
const HEIGHT := 132.0

var damage: float = 14.0
var knockback: float = 180.0
var _warn_time: float = 0.7
var _active_time: float = 0.4
var _col: CollisionShape2D
var _hit_done: bool = false


## parent 에 물기둥 하나를 예고→분출로 세운다. pos = 지면 접점.
static func spawn(parent: Node, pos: Vector2, dmg: float, warn_time: float = 0.7,
        active_time: float = 0.4, knock: float = 180.0) -> Area2D:
    if parent == null or not is_instance_valid(parent):
        return null
    var p := WaterPillar.new()
    p.damage = dmg
    p.knockback = knock
    p._warn_time = warn_time
    p._active_time = active_time
    p.collision_mask = 1              # 플레이어(layer 1) 감지
    p.monitoring = false              # 예고 동안엔 판정 없음
    parent.add_child(p)
    p.global_position = pos
    return p


func _ready() -> void:
    z_index = 8
    body_entered.connect(_on_body_entered)
    _col = CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(WIDTH, HEIGHT)
    _col.shape = shape
    _col.position = Vector2(0, -HEIGHT * 0.5)
    _col.disabled = true
    add_child(_col)
    _run()


func _run() -> void:
    _draw_warning()
    await get_tree().create_timer(_warn_time).timeout
    if not is_instance_valid(self):
        return
    _erupt()


## ① 예고 — 바닥에 번지는 물문양(고리 2겹 + 차오르는 실선). 판정 없음.
func _draw_warning() -> void:
    var ring := _ring(WIDTH * 0.62, 2.0, Color(SkillFx.WATER.r, SkillFx.WATER.g, SkillFx.WATER.b, 0.85))
    add_child(ring)
    ring.scale = Vector2(0.3, 0.12)
    var t1 := ring.create_tween()
    t1.tween_property(ring, "scale", Vector2(1.0, 0.4), _warn_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    var inner := _ring(WIDTH * 0.34, 1.5, Color(SkillFx.FOAM.r, SkillFx.FOAM.g, SkillFx.FOAM.b, 0.7))
    add_child(inner)
    inner.scale = Vector2(1.0, 0.4)
    var t2 := inner.create_tween().set_loops()
    t2.tween_property(inner, "modulate:a", 0.25, 0.18)
    t2.tween_property(inner, "modulate:a", 1.0, 0.18)


## ② 분출 — 물기둥이 솟고 판정이 켜진다.
func _erupt() -> void:
    monitoring = true
    if _col:
        _col.disabled = false
    Audio.play_sfx(Sfx.ATTACK)
    ScreenFx.shake(4.0, 0.12)
    # PixelLab 물기둥 스프라이트 — 코드 라인 위에 얹어 질감을 준다.
    SkillFx.water_pillar_art(global_position, HEIGHT)
    # 기둥 3겹(깊은물 → 물빛 → 거품) — 아래에서 위로 뻗었다 흩어진다.
    for L in [[16.0, Color(SkillFx.WATER_DEEP.r, SkillFx.WATER_DEEP.g, SkillFx.WATER_DEEP.b, 0.6)],
            [10.0, SkillFx.WATER], [4.0, SkillFx.FOAM]]:
        var col := Line2D.new()
        col.width = float(L[0])
        col.default_color = L[1]
        col.points = PackedVector2Array([Vector2(0, 6), Vector2(0, -HEIGHT)])
        col.z_index = 8
        add_child(col)
        col.scale = Vector2(1.0, 0.05)
        var tw := col.create_tween()
        tw.tween_property(col, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.tween_interval(_active_time)
        tw.tween_property(col, "modulate:a", 0.0, 0.22)
    # 튀는 물방울
    for i in range(8):
        var end := global_position + Vector2(randf_range(-40.0, 40.0), randf_range(-140.0, -40.0))
        SkillFx._mote(get_parent(), global_position, end, randf_range(1.6, 3.0),
            SkillFx.FOAM if i % 2 == 0 else SkillFx.WATER, randf_range(0.3, 0.5), 9)
    await get_tree().create_timer(_active_time).timeout
    if not is_instance_valid(self):
        return
    monitoring = false
    if _col:
        _col.disabled = true
    await get_tree().create_timer(0.3).timeout
    if is_instance_valid(self):
        queue_free()


func _ring(radius: float, width: float, color: Color) -> Line2D:
    var l := Line2D.new()
    l.width = width
    l.default_color = color
    var pts := PackedVector2Array()
    for i in range(17):
        var a := TAU * i / 16.0
        pts.append(Vector2(cos(a), sin(a)) * radius)
    l.points = pts
    l.z_index = 7
    return l


func _on_body_entered(body: Node) -> void:
    if _hit_done or not body.is_in_group("player"):
        return
    _hit_done = true                  # 기둥 하나당 1회만
    var hc: HealthComponent = body.get_node_or_null("HealthComponent")
    if hc:
        hc.take_damage(damage, self)
    if "velocity" in body:
        body.velocity.y = -260.0      # 위로 쳐올림(물기둥에 떠밀림)
    Audio.play_sfx(Sfx.HURT)
