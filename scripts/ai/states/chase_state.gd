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
## 서성이는 폭(px). 이 안에서는 다가오지도 물러서지도 않고 천천히 왔다 갔다 한다.
@export var standoff_band: float = 16.0
## 물러설 때 속도 배수(다가올 때보다 느리게 — 도망치는 것처럼 보이면 안 된다).
@export var retreat_speed_mult: float = 0.55
## 서성임 속도 배수.
@export var pace_speed_mult: float = 0.35

const GRAVITY: float = 980.0

var _standoff: float = 40.0
var _pace_dir: float = 1.0
var _pace_timer: float = 0.0


func enter(actor: Node) -> void:
    # 자기 공격 사거리 안쪽에 서야 실제로 때릴 수 있다. 사거리를 모르면 보수적으로 40.
    var reach := 52.0
    if actor and "attack_range" in actor:
        reach = float(actor.attack_range)
    # instance_id 로 0~1 고정 비율 — 같은 무리도 서로 다른 자리에 선다.
    # 사거리 안쪽 구간(55%~90%)에 흩뿌려야 '겹치지도 않고 때릴 수도 있는' 자리가 된다.
    # (처음엔 고정 오프셋을 더했다가, 사거리 밖에 서서 영영 못 때리는 적이 생겼다 —
    #  tests/test_enemy_spacing.gd 가 잡아냈다.)
    var slot := float(int(actor.get_instance_id()) % 7) / 6.0
    _standoff = maxf(24.0, lerpf(reach * 0.55, reach * 0.90, slot))
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

    if gap > _standoff + standoff_band:
        body.velocity.x = chase_speed * dir              # 멀다 — 다가간다
    elif gap < _standoff - standoff_band:
        body.velocity.x = -chase_speed * retreat_speed_mult * dir   # 너무 붙었다 — 물러선다
    else:
        # 간격 안 — 느리게 서성인다(가끔 방향을 바꾼다)
        _pace_timer -= delta
        if _pace_timer <= 0.0:
            _pace_dir = -_pace_dir
            _pace_timer = randf_range(0.5, 1.3)
        body.velocity.x = chase_speed * pace_speed_mult * _pace_dir

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
