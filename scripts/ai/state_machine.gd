extends Node
class_name StateMachine
##
## AI 상태머신 — 자식으로 추가된 AIState 노드들을 이름으로 관리.
## actor 는 보통 부모(CharacterBody2D 등). owner_path 로 명시 가능.
##

@export var initial_state: NodePath
@export var actor_path: NodePath

# 피격 경직 중 넉백 감쇠(px/s²) — 클수록 빨리 멈춤.
const KNOCK_FRICTION: float = 900.0

var current: AIState = null
var states: Dictionary = {}
var _actor: Node = null


func _ready() -> void:
    _actor = get_node_or_null(actor_path) if actor_path != NodePath("") else get_parent()
    for child in get_children():
        if child is AIState:
            states[child.name] = child
    var first: AIState = null
    if initial_state != NodePath(""):
        first = get_node_or_null(initial_state) as AIState
    if first == null and states.size() > 0:
        first = states.values()[0]
    if first:
        _switch_to(first)


func transition_to(state_name: String) -> void:
    if not states.has(state_name):
        push_warning("[StateMachine] unknown state: %s" % state_name)
        return
    _switch_to(states[state_name])


func _switch_to(s: AIState) -> void:
    if current == s:
        return
    if current:
        current.exit(_actor)
    current = s
    current.enter(_actor)


func _physics_process(delta: float) -> void:
    if current == null:
        return
    # 대화 중에는 적 이동/판단 정지 — 중력만 적용해 떠 있지 않게.
    if Dialogue and Dialogue.is_active():
        if _actor is CharacterBody2D:
            var b := _actor as CharacterBody2D
            b.velocity.x = 0.0
            if not b.is_on_floor():
                b.velocity.y += 980.0 * delta
            b.move_and_slide()
        return
    # 피격 경직(hitstun) — AI 가 velocity 를 덮어쓰지 않게 정지시키고, 넉백이 마찰로
    # 감쇠하며 실제로 밀려나게 한다(손맛). actor 에 hitstun(float) 필드가 있을 때만.
    if _actor is CharacterBody2D and "hitstun" in _actor and _actor.hitstun > 0.0:
        var hb := _actor as CharacterBody2D
        hb.hitstun = maxf(0.0, hb.hitstun - delta)
        hb.velocity.x = move_toward(hb.velocity.x, 0.0, KNOCK_FRICTION * delta)
        if not hb.is_on_floor():
            hb.velocity.y += 980.0 * delta
        hb.move_and_slide()
        return
    var next := current.process_physics(_actor, delta)
    if next != "":
        transition_to(next)


func _process(delta: float) -> void:
    if current == null:
        return
    var next := current.process_frame(_actor, delta)
    if next != "":
        transition_to(next)
