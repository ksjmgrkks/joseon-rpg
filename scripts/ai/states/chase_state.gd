extends AIState
##
## Chase — 플레이어에게 다가가되 **일정 거리에서 멈춰 서성인다**. 시야 잃으면 Idle.
##
## 2026-08-22 피드백: "몬스터가 계속 바로 옆에 붙어 있어 버벅거린다. 뭉쳐 있을 때 특히."
## 원인은 이 상태가 플레이어 x 를 향해 **무조건 전속력**으로 밀고 들어왔기 때문 —
## 몸 콜리전이 서로 통과하는 설계(메탈슬러그식)라 여럿이 같은 좌표에 겹쳐 떨었다.
##
## 고친 방식(간격 유지):
##   · 각자 '설 자리'(standoff)를 잡는다. 너무 멀면 다가오고, 너무 가까우면 물러선다.
##   · 그 사이 간격(band) 안에서는 느리게 좌우로 서성인다 — 멈춰 서 있으면 인형 같다.
##   · standoff 는 **적마다 조금씩 다르게**(instance_id 기반) 잡아 여럿이 한 점에 겹치지 않는다.
##   · standoff 는 자기 공격 사거리보다 짧게 유지한다 — 안 그러면 영원히 때리지 못한다.
##

@export var chase_speed: float = 140.0
@export var lose_distance: float = 280.0
## 유지 거리 — 사거리의 배수로 잡는다. 1.0 이면 딱 때릴 거리, 2.x 면 한참 떨어져 서성인다.
## 2026-08-22 2차 피드백: "패트롤 범위가 더 넓어야 한다" → 평소엔 멀찍이 돌다가
## 공격 쿨이 돌아왔을 때만 파고든다(치고 빠지기). 계속 옆에 붙어 있던 버벅임의 원인.
@export var hold_ratio_min: float = 1.9
@export var hold_ratio_max: float = 3.2
## 서성이는 폭(px). 이 안에서는 다가오지도 물러서지도 않고 천천히 왔다 갔다 한다.
@export var standoff_band: float = 22.0
## 물러설 때 속도 배수(다가올 때보다 느리게 — 도망치는 것처럼 보이면 안 된다).
@export var retreat_speed_mult: float = 0.55
## 서성임 속도 배수.
@export var pace_speed_mult: float = 0.45
## 다른 적과 이만큼 안쪽으로 겹치면 서로 밀어낸다(px).
@export var separation_distance: float = 30.0
@export var separation_push: float = 46.0

const GRAVITY: float = 980.0

var _standoff: float = 40.0
var _reach: float = 52.0
var _pace_dir: float = 1.0
var _pace_timer: float = 0.0


func enter(actor: Node) -> void:
    # 사거리를 모르면 보수적으로 52.
    var reach := 52.0
    if actor and "attack_range" in actor:
        reach = float(actor.attack_range)
    _reach = reach
    # instance_id 로 0~1 고정 비율 — 같은 무리도 서로 다른 자리에 선다.
    var slot := float(int(actor.get_instance_id()) % 7) / 6.0
    _standoff = reach * lerpf(hold_ratio_min, hold_ratio_max, slot)
    _pace_dir = 1.0 if randf() > 0.5 else -1.0
    _pace_timer = randf_range(0.4, 1.1)


func process_physics(actor: Node, delta: float) -> String:
    if not (actor is CharacterBody2D):
        return "Idle"
    if not actor.has_method("get_player"):
        return "Idle"
    var player = actor.get_player()
    if player == null or not (player is Node2D):
        return "Idle"

    var body := actor as CharacterBody2D
    var to_player := (player as Node2D).global_position.x - body.global_position.x
    var dir := signf(to_player)
    if dir == 0.0:
        dir = 1.0
    var gap := absf(to_player)

    # 때릴 준비가 됐으면 사거리 안까지 파고든다(치고 빠지기의 '치고').
    # 준비가 안 됐으면 멀찍이 물러나 서성인다 — 이게 넓은 패트롤로 보인다.
    var target := _standoff
    if actor.has_method("wants_to_attack") and actor.wants_to_attack():
        target = _reach * 0.8

    if gap > target + standoff_band:
        body.velocity.x = chase_speed * dir              # 멀다 — 다가간다
    elif gap < target - standoff_band:
        body.velocity.x = -chase_speed * retreat_speed_mult * dir   # 너무 붙었다 — 물러선다
    else:
        # 간격 안 — 느리게 서성인다(가끔 방향을 바꾼다)
        _pace_timer -= delta
        if _pace_timer <= 0.0:
            _pace_dir = -_pace_dir
            _pace_timer = randf_range(0.5, 1.3)
        body.velocity.x = chase_speed * pace_speed_mult * _pace_dir

    body.velocity.x += _separation(body)

    if not body.is_on_floor():
        body.velocity.y += GRAVITY * delta
    body.move_and_slide()

    # 맞고 나서 쫓아오는 중(어그로)이면 훨씬 끈질기게 따라붙는다 —
    # 안 그러면 사거리 밖에서 원거리로만 툭툭 치는 게 최적해가 된다(2026-08-22 피드백).
    var lose := lose_distance
    if "aggro" in actor and actor.aggro:
        lose = lose_distance * 2.5
    var distance := body.global_position.distance_to((player as Node2D).global_position)
    if distance > lose:
        return "Idle"
    return ""


## 다른 적과 너무 겹치면 서로 밀어내는 속도를 돌려준다.
## 적끼리는 몸 콜리전이 통과하는 설계(메탈슬러그식)라, 이걸 안 하면 같은 좌표에 포개진다.
func _separation(body: CharacterBody2D) -> float:
    var push := 0.0
    for other in body.get_tree().get_nodes_in_group("enemy"):
        if other == body or not (other is Node2D):
            continue
        var dx: float = body.global_position.x - (other as Node2D).global_position.x
        # 세로로 크게 떨어져 있으면(다른 발판) 신경 쓰지 않는다.
        if absf(body.global_position.y - (other as Node2D).global_position.y) > 48.0:
            continue
        var ax := absf(dx)
        if ax >= separation_distance:
            continue
        # 완전히 겹쳤으면 instance_id 로 방향을 갈라 서로 반대로 흩어지게 한다.
        var away := signf(dx)
        if away == 0.0:
            away = 1.0 if int(body.get_instance_id()) % 2 == 0 else -1.0
        push += away * separation_push * (1.0 - ax / separation_distance)
    return clampf(push, -separation_push * 1.5, separation_push * 1.5)
