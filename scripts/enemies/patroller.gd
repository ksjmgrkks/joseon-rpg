extends CharacterBody2D
##
## 기본 적 — StateMachine(Idle/Patrol/Chase) 으로 움직임. Goblin/Fox/Reaper/Tiger 등
## 모든 일반 변종이 이 스크립트를 공유하며 .tscn 에서 색상/HP/속도/XP를 다르게 export.
##

@export var display_name: String = "도깨비"
@export var body_color: Color = Color(0.5, 0.4, 0.6, 1)
@export var detect_range: float = 160.0
@export var xp_reward: int = 14

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
    add_to_group("enemy")
    hurtbox.hurt.connect(_on_hurt)
    health.hp_changed.connect(_on_hp_changed)
    health.died.connect(_on_died)
    if sprite:
        sprite.modulate = body_color


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
            sprite.modulate = body_color


func _on_hp_changed(hp: float, max_hp: float) -> void:
    print("[%s] HP %.0f / %.0f" % [display_name, hp, max_hp])


func _on_died() -> void:
    print("[%s] died" % display_name)
    Audio.play_sfx(Sfx.DIE)
    if xp_reward > 0:
        PlayerStats.gain_xp(xp_reward)
        FloatingNumber.spawn(get_tree().current_scene, global_position, "+%d XP" % xp_reward, Color(1, 0.95, 0.6))
    queue_free()
