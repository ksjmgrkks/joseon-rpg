extends Area2D
class_name Hurtbox
##
## 피격 판정 영역. Hitbox와 겹치면 hurt 시그널 발사.
## 같은 부모의 Hitbox(=자기 자신의 공격)는 무시.
##

signal hurt(damage: float, knockback: float, attacker: Node)


func _ready() -> void:
    monitoring = true
    monitorable = true
    area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
    if not (area is Hitbox):
        return
    var attacker := area.get_parent()
    # 같은 부모(=자기 자신)의 hitbox는 무시
    if attacker == get_parent():
        return
    # 아군 오사 방지 — 공격자와 피격자가 둘 다 "enemy" 그룹이면 무시(몬스터끼리는 공격 안 함).
    var victim := get_parent()
    if attacker and attacker.is_in_group("enemy") and victim and victim.is_in_group("enemy"):
        return
    var hb := area as Hitbox
    var dir_x := signf(global_position.x - area.global_position.x)
    if dir_x == 0.0:
        dir_x = 1.0
    hurt.emit(hb.damage, hb.knockback * dir_x, attacker)
