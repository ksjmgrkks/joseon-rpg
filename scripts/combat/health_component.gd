extends Node
class_name HealthComponent
##
## 체력 컴포넌트. 부모 노드(또는 export로 지정된 Hurtbox)에서 발생하는 hurt 시그널을 받아 처리.
## 시그널: hp_changed(hp, max_hp), died.
##

signal hp_changed(hp: float, max_hp: float)
signal died
signal shield_broken

signal invuln_started   # 피격 무적 시작(피드백 연출용)

@export var max_hp: float = 100.0
@export var hurtbox_path: NodePath
# 피격 후 짧은 무적(초). 0이면 없음. 플레이어는 무리에게 연타당하지 않게 0.5 권장.
@export var invuln_on_hit: float = 0.0

var hp: float
var shield_charges: int = 0   # 호신부 등 — 피해 1회를 통째로 막는 가호
var _invuln: float = 0.0


func _ready() -> void:
    hp = max_hp
    if hurtbox_path != NodePath(""):
        var hb := get_node_or_null(hurtbox_path) as Hurtbox
        if hb:
            hb.hurt.connect(_on_hurt)


func _physics_process(delta: float) -> void:
    if _invuln > 0.0:
        _invuln = maxf(0.0, _invuln - delta)


func is_invulnerable() -> bool:
    return _invuln > 0.0


func _on_hurt(damage: float, _knockback: float, attacker: Node) -> void:
    take_damage(damage, attacker)


## 외부에서도 직접 호출 가능. 부모가 'player' 그룹이면 Equipment 방어력만큼 자동 감산.
func take_damage(amount: float, _source: Node = null) -> void:
    if hp <= 0.0:
        return
    if _invuln > 0.0:
        return                      # 피격 무적 중 — 무시
    if shield_charges > 0:
        shield_charges -= 1
        shield_broken.emit()
        if invuln_on_hit > 0.0:
            _invuln = invuln_on_hit
            invuln_started.emit()
        return
    var effective := amount
    var parent := get_parent()
    # 플레이어가 맞은 데미지에만 장착 방어력을 적용. 최소 1은 들어감.
    if parent and parent.is_in_group("player") and Equipment:
        effective = maxf(1.0, amount - Equipment.current_defense())
    hp = maxf(0.0, hp - effective)
    hp_changed.emit(hp, max_hp)
    if hp > 0.0 and invuln_on_hit > 0.0:
        _invuln = invuln_on_hit
        invuln_started.emit()
    if hp <= 0.0:
        died.emit()


func heal(amount: float) -> void:
    if hp <= 0.0:
        return
    hp = minf(max_hp, hp + amount)
    hp_changed.emit(hp, max_hp)
