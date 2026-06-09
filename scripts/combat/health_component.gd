extends Node
class_name HealthComponent
##
## 체력 컴포넌트. 부모 노드(또는 export로 지정된 Hurtbox)에서 발생하는 hurt 시그널을 받아 처리.
## 시그널: hp_changed(hp, max_hp), died.
##

signal hp_changed(hp: float, max_hp: float)
signal died

@export var max_hp: float = 100.0
@export var hurtbox_path: NodePath

var hp: float


func _ready() -> void:
    hp = max_hp
    if hurtbox_path != NodePath(""):
        var hb := get_node_or_null(hurtbox_path) as Hurtbox
        if hb:
            hb.hurt.connect(_on_hurt)


func _on_hurt(damage: float, _knockback: float, attacker: Node) -> void:
    take_damage(damage, attacker)


## 외부에서도 직접 호출 가능. 부모가 'player' 그룹이면 Equipment 방어력만큼 자동 감산.
func take_damage(amount: float, _source: Node = null) -> void:
    if hp <= 0.0:
        return
    var effective := amount
    var parent := get_parent()
    # 플레이어가 맞은 데미지에만 장착 방어력을 적용. 최소 1은 들어감.
    if parent and parent.is_in_group("player") and Equipment:
        effective = maxf(1.0, amount - Equipment.current_defense())
    hp = maxf(0.0, hp - effective)
    hp_changed.emit(hp, max_hp)
    if hp <= 0.0:
        died.emit()


func heal(amount: float) -> void:
    if hp <= 0.0:
        return
    hp = minf(max_hp, hp + amount)
    hp_changed.emit(hp, max_hp)
