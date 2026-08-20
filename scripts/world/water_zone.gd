extends Area2D
class_name WaterZone
##
## 물웅덩이 구간 — 플레이어가 걸어 들어오거나 그 안에서 움직이면 발밑에 물이 튄다.
## 순수 시각 연출(피해·감속 없음). 코드 생성(에셋 불필요), SkillFx 의 기존 물보라 모트 재사용.
##

@export var width: float = 200.0
const HEIGHT := 40.0
const STEP_INTERVAL := 0.22   # 걷는 동안 튀는 간격 — 실제 발걸음 리듬에 가깝게

var _inside: Node2D = null
var _step_cd: float = 0.0


static func spawn(parent: Node, center_x: float, ground_y: float, w: float) -> Area2D:
    if parent == null or not is_instance_valid(parent):
        return null
    var z := WaterZone.new()
    z.width = w
    z.collision_mask = 1
    parent.add_child(z)
    z.global_position = Vector2(center_x, ground_y)
    return z


func _ready() -> void:
    monitoring = true
    monitorable = false
    body_entered.connect(_on_enter)
    body_exited.connect(_on_exit)
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(width, HEIGHT)
    cs.shape = shape
    cs.position = Vector2(0, -HEIGHT * 0.5)
    add_child(cs)


func _on_enter(body: Node) -> void:
    if not body.is_in_group("player"):
        return
    _inside = body as Node2D
    _splash(body.global_position)


func _on_exit(body: Node) -> void:
    if body == _inside:
        _inside = null


func _physics_process(delta: float) -> void:
    if _step_cd > 0.0:
        _step_cd -= delta
    if _inside == null or not is_instance_valid(_inside):
        return
    if Dialogue and Dialogue.is_active():
        return
    var moving: bool = "velocity" in _inside and absf(_inside.velocity.x) > 4.0
    var grounded: bool = not ("is_on_floor" in _inside) or _inside.is_on_floor()
    if moving and grounded and _step_cd <= 0.0:
        _step_cd = STEP_INTERVAL
        _splash(_inside.global_position)


## 발밑에 튀는 물방울 — 기존 SkillFx 물보라 모트를 재사용(신규 에셋 없음).
func _splash(at: Vector2) -> void:
    var host := get_parent()
    if host == null:
        return
    var foot := at + Vector2(0, 6.0)
    for i in range(4):
        var end := foot + Vector2(randf_range(-16.0, 16.0), randf_range(-22.0, -8.0))
        SkillFx._mote(host, foot, end, randf_range(1.4, 2.4),
            SkillFx.FOAM if i % 2 == 0 else SkillFx.WATER, randf_range(0.26, 0.4), 9)
