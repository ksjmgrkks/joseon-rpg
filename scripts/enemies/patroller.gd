extends CharacterBody2D
##
## Patroller 적 — StateMachine(Idle/Patrol/Chase) 으로 움직임.
## get_player()/can_see_player() 를 노출해 AI 상태가 참고.
##

@export var detect_range: float = 160.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
    add_to_group("enemy")
    hurtbox.hurt.connect(_on_hurt)
    health.hp_changed.connect(_on_hp_changed)
    health.died.connect(_on_died)


func get_player() -> Node:
    return get_tree().get_first_node_in_group("player")


func can_see_player() -> bool:
    var p := get_player()
    if p == null or not (p is Node2D):
        return false
    return global_position.distance_to((p as Node2D).global_position) < detect_range


func _on_hurt(_damage: float, knockback: float, _attacker: Node) -> void:
    velocity.x = knockback
    velocity.y = -160.0
    Audio.play_sfx(Sfx.HIT)
    if sprite:
        sprite.modulate = Color(1, 0.5, 0.5, 1)
        await get_tree().create_timer(0.08).timeout
        if is_instance_valid(sprite):
            sprite.modulate = Color(0.5, 0.4, 0.6, 1)


func _on_hp_changed(hp: float, max_hp: float) -> void:
    print("[Patroller] HP %.0f / %.0f" % [hp, max_hp])


func _on_died() -> void:
    print("[Patroller] died")
    Audio.play_sfx(Sfx.DIE)
    queue_free()
