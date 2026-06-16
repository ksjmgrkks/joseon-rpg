extends CharacterBody2D
##
## 기본 적 — StateMachine(Idle/Patrol/Chase) 으로 움직임. Goblin/Fox/Reaper/Tiger 등
## 모든 일반 변종이 이 스크립트를 공유하며 .tscn 에서 색상/HP/속도/XP를 다르게 export.
##

@export var display_name: String = "도깨비"
@export var body_color: Color = Color(0.5, 0.4, 0.6, 1)
@export var detect_range: float = 160.0
@export var xp_reward: int = 14
# 근접 공격 — 잡몹도 플레이어를 친다(일방적 전투 해소). 거리 판정 방식(아군 오사 없음).
@export var attack_damage: float = 6.0
@export var attack_range: float = 56.0
@export var attack_knockback: float = 170.0
@export var attack_cooldown: float = 1.5
@export var attack_telegraph: float = 0.28

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $HealthComponent

var _dying: bool = false
var _attacking: bool = false
var _atk_cd: float = 0.0


func _ready() -> void:
    add_to_group("enemy")
    hurtbox.hurt.connect(_on_hurt)
    health.hp_changed.connect(_on_hp_changed)
    health.died.connect(_on_died)
    EnemyHpBar.attach_to(self, health)
    # 실제 스프라이트(EnemyVisual) 사용 — 색 틴트 없이 원본 표시.


func _physics_process(delta: float) -> void:
    if _dying:
        return
    if _atk_cd > 0.0:
        _atk_cd -= delta
    if _attacking or _atk_cd > 0.0:
        return
    var p := get_player()
    if p == null or not (p is Node2D):
        return
    var pp := (p as Node2D).global_position
    if global_position.distance_to(pp) <= attack_range and absf(pp.y - global_position.y) < 60.0:
        _do_attack(p as Node2D)


# 예비동작(번쩍) → 타격: 그 순간 플레이어가 사거리 안이면 데미지+넉백.
func _do_attack(player: Node2D) -> void:
    _attacking = true
    _atk_cd = attack_cooldown
    var facing := signf(player.global_position.x - global_position.x)
    if sprite:
        sprite.flip_h = facing < 0.0
        sprite.modulate = Color(1.0, 0.8, 0.5, 1.0)   # 예비동작 경고색
    await get_tree().create_timer(attack_telegraph).timeout
    if _dying or not is_instance_valid(self):
        return
    if sprite and is_instance_valid(sprite):
        sprite.modulate = Color.WHITE
    # 타격 판정 — 여전히 사거리 안이면 적중
    if is_instance_valid(player) and global_position.distance_to(player.global_position) <= attack_range + 14.0:
        var ph: HealthComponent = player.get_node_or_null("HealthComponent")
        if ph:
            ph.take_damage(attack_damage, self)
        if "velocity" in player:
            player.velocity.x = attack_knockback * facing
            player.velocity.y = -120.0
        Audio.play_sfx(Sfx.HURT)
        ScreenFx.shake(3.5, 0.12)
    await get_tree().create_timer(0.18).timeout
    _attacking = false


func get_player() -> Node:
    return get_tree().get_first_node_in_group("player")


func can_see_player() -> bool:
    var p := get_player()
    if p == null or not (p is Node2D):
        return false
    return global_position.distance_to((p as Node2D).global_position) < detect_range


func _on_hurt(damage: float, knockback: float, _attacker: Node) -> void:
    velocity.x = knockback
    velocity.y = -160.0
    Audio.play_sfx(Sfx.HIT)
    FloatingNumber.spawn(get_tree().current_scene, global_position, "-%d" % int(damage), Color(1, 0.6, 0.55))
    if sprite:
        sprite.modulate = Color(1, 0.5, 0.5, 1)
        await get_tree().create_timer(0.08).timeout
        if is_instance_valid(sprite):
            sprite.modulate = Color.WHITE


func _on_hp_changed(hp: float, max_hp: float) -> void:
    print("[%s] HP %.0f / %.0f" % [display_name, hp, max_hp])


func _on_died() -> void:
    if _dying:
        return
    _dying = true
    print("[%s] died" % display_name)
    Audio.play_sfx(Sfx.DIE)
    if xp_reward > 0:
        PlayerStats.gain_xp(xp_reward)
        FloatingNumber.spawn(get_tree().current_scene, global_position, "+%d XP" % xp_reward, Color(1, 0.95, 0.6))
    # 더는 안 맞고, 죽음 애니메이션이 보이도록 잠깐 둔 뒤 제거
    if hurtbox:
        hurtbox.monitoring = false
    set_physics_process(false)
    velocity = Vector2.ZERO
    await get_tree().create_timer(0.6).timeout
    queue_free()
