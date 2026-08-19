extends Area2D
class_name ShadowPool
##
## 그림자 늪 — 그슨대 노괴가 바닥에 퍼뜨리는 검은 웅덩이. 코드 생성(에셋 불필요).
##
## 두 박자:
##   ① 예고(warn_time): 바닥에 검은 얼룩이 번지기만 하고 **판정 없음**.
##   ② 활성(active_time): 밟으면 피해 + **이동이 끈적하게 묶인다**(속도 저하).
##
## 회피법: 웅덩이 사이로 걸어가거나 뛰어넘기. 물기둥처럼 '즉사형'이 아니라
## '갇히면 다음 패턴을 못 피하는' 압박형이라, 다른 패턴과 겹칠 때 무서워진다.
##

const RADIUS := 58.0

var damage: float = 8.0
var slow_factor: float = 0.42        # 늪 안에서의 이동 속도 배율
var _warn_time: float = 0.55
var _active_time: float = 3.2
var _col: CollisionShape2D
var _hit_cd: float = 0.0
var _inside: Array[Node] = []


static func spawn(parent: Node, pos: Vector2, dmg: float, warn_time: float = 0.55,
        active_time: float = 3.2) -> Area2D:
    if parent == null or not is_instance_valid(parent):
        return null
    var p := ShadowPool.new()
    p.damage = dmg
    p._warn_time = warn_time
    p._active_time = active_time
    p.collision_mask = 1
    p.monitoring = false
    parent.add_child(p)
    p.global_position = pos
    return p


func _ready() -> void:
    z_index = 3                       # 지면 위, 캐릭터 아래
    body_entered.connect(_on_enter)
    body_exited.connect(_on_exit)
    _col = CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(RADIUS * 2.0, 26.0)
    _col.shape = shape
    _col.position = Vector2(0, -13.0)
    _col.disabled = true
    add_child(_col)
    _draw_pool()
    _run()


## 검은 얼룩 — 타원 여러 겹 + 가장자리에서 피어오르는 그림자 자락.
func _draw_pool() -> void:
    for L in [[1.0, Color(0.03, 0.03, 0.05, 0.85)], [0.72, Color(0.09, 0.07, 0.12, 0.9)]]:
        var poly := Polygon2D.new()
        var pts := PackedVector2Array()
        var k := float(L[0])
        for i in range(20):
            var a := TAU * i / 20.0
            # 가장자리를 울퉁불퉁하게 — 그림자가 번진 느낌
            var wobble := 1.0 + 0.16 * sin(a * 3.0) + 0.08 * sin(a * 5.0)
            pts.append(Vector2(cos(a) * RADIUS * k * wobble, sin(a) * 15.0 * k * wobble))
        poly.polygon = pts
        poly.color = L[1]
        poly.z_index = 3
        add_child(poly)
        poly.scale = Vector2(0.15, 0.15)
        var tw := poly.create_tween()
        tw.tween_property(poly, "scale", Vector2.ONE, _warn_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _run() -> void:
    await get_tree().create_timer(_warn_time).timeout
    if not is_instance_valid(self):
        return
    monitoring = true
    if _col:
        _col.disabled = false
    # 활성 순간 그림자 자락이 확 솟았다 가라앉는다
    for i in range(7):
        var a := randf() * TAU
        var from := global_position + Vector2(cos(a) * RADIUS * 0.7, 0)
        SkillFx._mote(get_parent(), from, from + Vector2(randf_range(-14, 14), randf_range(-52, -22)),
            randf_range(2.0, 3.6), Color(0.12, 0.10, 0.16), randf_range(0.4, 0.7), 4)
    await get_tree().create_timer(_active_time).timeout
    if not is_instance_valid(self):
        return
    _release_all()
    monitoring = false
    if _col:
        _col.disabled = true
    var tw := create_tween()
    tw.tween_property(self, "modulate:a", 0.0, 0.45)
    tw.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
    if Dialogue and Dialogue.is_active():
        return
    if _hit_cd > 0.0:
        _hit_cd -= delta
    # 늪 안에 머무는 동안 지속 피해(0.8초 간격) — 오래 갇히면 아프다
    if _hit_cd <= 0.0 and not _inside.is_empty():
        _hit_cd = 0.8
        for b in _inside:
            if not is_instance_valid(b):
                continue
            var hc: HealthComponent = b.get_node_or_null("HealthComponent")
            if hc:
                hc.take_damage(damage, self)
            Audio.play_sfx(Sfx.HURT)


func _on_enter(body: Node) -> void:
    if not body.is_in_group("player") or _inside.has(body):
        return
    _inside.append(body)
    # 발이 묶인다 — 플레이어의 이동 배율을 낮춘다(player 가 지원할 때만).
    if "move_speed_mult" in body:
        body.move_speed_mult = slow_factor
    SkillFx.impact(body.global_position + Vector2(0, -10), false)


func _on_exit(body: Node) -> void:
    if not _inside.has(body):
        return
    _inside.erase(body)
    if "move_speed_mult" in body:
        body.move_speed_mult = 1.0


func _release_all() -> void:
    for b in _inside:
        if is_instance_valid(b) and "move_speed_mult" in b:
            b.move_speed_mult = 1.0
    _inside.clear()
