extends Area2D
class_name TalismanShot
##
## 부적 투사체 — 「진혼의 물등」 스킬샷 개편판(2026-08-18). 부채꼴로 흩뿌려
## 일직선으로 날아가며, 사거리 안에 적이 없으면 그냥 스쳐 지나간다(빗나갈 수 있음).
## SpiritOrb(적 원거리 투사체)와 대칭 구조 — 여긴 반대로 "enemy" 그룹 바디만 감지.
##

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var knockback: float = 160.0
var attacker: Node = null
var _life: float = 0.9


## 런타임 생성 — parent(씬)에 부적 하나를 dir 방향으로 쏜다.
static func spawn(parent: Node, pos: Vector2, dir: Vector2, dmg: float, knock: float,
		speed: float, life: float, atk: Node) -> Area2D:
	if parent == null or not is_instance_valid(parent):
		return null
	var shot := TalismanShot.new()
	shot.damage = dmg
	shot.knockback = knock
	shot.attacker = atk
	shot._life = life
	shot.velocity = dir.normalized() * speed
	shot.rotation = shot.velocity.angle()
	shot.collision_mask = 2            # 적(CharacterBody2D, layer 2) 감지 — 플레이어는 통과
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	cs.shape = shape
	shot.add_child(cs)
	parent.add_child(shot)
	shot.global_position = pos
	return shot


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	z_index = 7
	_build_visual()


func _build_visual() -> void:
	# 진행 방향(+x)을 긴 축으로 삼는 한지 부적 — 먹 테두리 + 붉은 주사 획.
	const INK := Color(0.10, 0.086, 0.07)
	const RED := Color(0.78, 0.22, 0.20)
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([
		Vector2(-8, -4.5), Vector2(8, -4.5), Vector2(8, 4.5), Vector2(-8, 4.5)])
	paper.color = Color(0.96, 0.93, 0.84, 0.97)
	add_child(paper)
	var border := Line2D.new()
	border.points = PackedVector2Array([
		Vector2(-8, -4.5), Vector2(8, -4.5), Vector2(8, 4.5), Vector2(-8, 4.5), Vector2(-8, -4.5)])
	border.width = 1.0
	border.default_color = Color(INK.r, INK.g, INK.b, 0.8)
	border.z_index = 1
	add_child(border)
	for seg in [[Vector2(-5.5, 0), Vector2(5.5, 0)], [Vector2(-2.0, -2.5), Vector2(-2.0, 2.5)],
			[Vector2(2.0, -2.5), Vector2(2.0, 2.5)]]:
		var stroke := Line2D.new()
		stroke.points = PackedVector2Array([seg[0], seg[1]])
		stroke.width = 1.2
		stroke.default_color = Color(RED.r, RED.g, RED.b, 0.95)
		stroke.z_index = 2
		add_child(stroke)
	# 뒤로 끌리는 짧은 물빛 궤적 — 방향성을 눈으로 바로 읽히게.
	var trail := Line2D.new()
	trail.points = PackedVector2Array([Vector2(-20, 0), Vector2(-8, 0)])
	trail.width = 3.0
	trail.default_color = Color(0.7, 0.85, 0.95, 0.35)
	trail.z_index = -1
	add_child(trail)


func _physics_process(delta: float) -> void:
	if Dialogue and Dialogue.is_active():
		return                      # 대화 중 투사체도 정지
	global_position += velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemy"):
		return
	var hc: HealthComponent = body.get_node_or_null("HealthComponent")
	if hc:
		hc.take_damage(damage, attacker)
	if "velocity" in body:
		body.velocity.x = knockback * signf(velocity.x)
	if body is Node2D:
		SkillFx.impact((body as Node2D).global_position + Vector2(0, -16), false)
	Audio.play_sfx(Sfx.HIT, 3.0)
	queue_free()
