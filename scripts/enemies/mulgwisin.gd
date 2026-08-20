extends "res://scripts/enemies/patroller.gd"
class_name Mulgwisin
##
## 물귀신(水鬼) — 골짜기 소(沼)에 잠긴 넋. 물에 빠져 죽은 자가 저 대신 들어올 사람을
## 물속으로 끌어당긴다는 조선 민담의 그것. 때리기보다 **붙잡는다** —
## 한 번 잡히면 잠시 발이 무거워져 다음 공격을 피하기 어려워진다.
##
## 구현: patroller 의 `_on_attack_hit` 훅만 오버라이드한다(전투 본체는 건드리지 않음).
## 플레이어의 `move_speed_mult`(그림자 늪이 쓰는 것과 같은 훅)를 잠깐 낮췄다가 되돌린다.
##

## 잡혔을 때 이동 속도 배율(1.0 = 영향 없음)과 지속 시간.
@export var grab_slow_factor: float = 0.55
@export var grab_slow_seconds: float = 1.4


func _on_attack_hit(player: Node2D) -> void:
    if player == null or not is_instance_valid(player):
        return
    if not ("move_speed_mult" in player):
        return
    player.move_speed_mult = clampf(grab_slow_factor, 0.1, 1.0)
    QuestToast._show("발목이 잡혔다")
    await get_tree().create_timer(maxf(0.1, grab_slow_seconds)).timeout
    # 반드시 되돌린다 — 안 그러면 스테이지 내내 느려진 채로 남는다.
    if is_instance_valid(player) and "move_speed_mult" in player:
        player.move_speed_mult = 1.0
