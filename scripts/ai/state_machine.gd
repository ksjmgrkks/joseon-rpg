extends Node
class_name StateMachine
##
## AI 상태머신 — 자식으로 추가된 AIState 노드들을 이름으로 관리.
## actor 는 보통 부모(CharacterBody2D 등). owner_path 로 명시 가능.
##

@export var initial_state: NodePath
@export var actor_path: NodePath

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
    var next := current.process_physics(_actor, delta)
    if next != "":
        transition_to(next)


func _process(delta: float) -> void:
    if current == null:
        return
    var next := current.process_frame(_actor, delta)
    if next != "":
        transition_to(next)
