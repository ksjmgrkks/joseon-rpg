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


## 히트박스를 거치지 않는 피해(투사체·장판·궁극기)를 **히트박스와 같은 경로로** 꽂는다.
##
## 2026-08-22 피드백: "결계 뒤 적을 원거리로 잡을 때 피격 반응을 알기 힘들어 체력바만 보게 된다".
## 원인은 투사체들이 `HealthComponent.take_damage()` 를 직접 불러 **Hurtbox.hurt 를 건너뛴 것** —
## 체력은 깎이지만 데미지 숫자·흰 섬광·움찔·넉백은 전부 그 시그널을 듣는 쪽에 있었다.
## 여기로 보내면 근접타와 완전히 같은 반응이 나온다.
##
## 반환값: 실제로 피해를 꽂았으면 true.
static func deal(target: Node, damage: float, knockback: float, attacker: Node) -> bool:
    if target == null or not is_instance_valid(target):
        return false
    var hb := target.get_node_or_null("Hurtbox") as Hurtbox
    if hb != null:
        hb.hurt.emit(damage, knockback, attacker)
        return true
    # Hurtbox 가 없는 대상(특수 오브젝트)은 예전 경로로 폴백.
    var hc: HealthComponent = target.get_node_or_null("HealthComponent")
    if hc != null:
        hc.take_damage(damage, attacker)
        return true
    return false
