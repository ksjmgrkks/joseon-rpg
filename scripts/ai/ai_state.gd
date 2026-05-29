extends Node
class_name AIState
##
## AI 상태 베이스. enter/exit/process_* 를 override.
## process_*가 빈 문자열 "" 을 반환하면 현재 상태 유지, 다른 문자열은 전환할 상태 이름.
##

func enter(_actor: Node) -> void:
    pass

func exit(_actor: Node) -> void:
    pass

func process_physics(_actor: Node, _delta: float) -> String:
    return ""

func process_frame(_actor: Node, _delta: float) -> String:
    return ""
