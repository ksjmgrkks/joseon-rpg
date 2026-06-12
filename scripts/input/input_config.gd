extends Node
##
## InputConfig autoload — 키 리바인딩 저장/복원.
##
## user://input.cfg 에 액션별 physical keycode 목록을 저장하고,
## 부팅 시 InputMap 에 적용한다. project.godot 의 기본값은 건드리지 않으므로
## '기본값 복원' 은 저장 파일을 지우고 InputMap.load_from_project_settings() 호출.
##
## 리바인딩 대상 액션과 한글 표기는 REBINDABLE 에 정의 (이동 좌우는 고정).
##

const CFG_PATH := "user://input.cfg"

const REBINDABLE := {
    "attack":    "공격",
    "jump":      "점프",
    "dodge":     "회피",
    "skill_1":   "스킬1 일섬",
    "skill_2":   "스킬2 회천격",
    "skill_3":   "스킬3 호신부",
    "interact":  "대화/상호작용",
    "inventory": "인벤토리",
    "quest_log": "퀘스트 일지",
}

signal bindings_changed


func _ready() -> void:
    _load_and_apply()


## 액션의 현재 키들을 사람이 읽을 문자열로 ("X, J")
func binding_text(action: String) -> String:
    var names: Array[String] = []
    for ev in InputMap.action_get_events(action):
        if ev is InputEventKey:
            var k := ev as InputEventKey
            names.append(OS.get_keycode_string(k.physical_keycode if k.physical_keycode != 0 else k.keycode))
    return ", ".join(names) if not names.is_empty() else "(없음)"


## 액션에 키 1개를 새로 배정 — 기존 키들을 교체. 다른 액션이 같은 키를 쓰면 그쪽에서 제거.
func rebind(action: String, key_event: InputEventKey) -> void:
    if not REBINDABLE.has(action):
        return
    var phys := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
    # 충돌 제거 — 다른 리바인딩 가능 액션에서 같은 키 제거
    for other in REBINDABLE:
        if other == action:
            continue
        for ev in InputMap.action_get_events(other):
            if ev is InputEventKey and (ev as InputEventKey).physical_keycode == phys:
                InputMap.action_erase_event(other, ev)
    # 본 액션 키 교체
    for ev in InputMap.action_get_events(action):
        if ev is InputEventKey:
            InputMap.action_erase_event(action, ev)
    var nev := InputEventKey.new()
    nev.physical_keycode = phys
    InputMap.action_add_event(action, nev)
    _save()
    bindings_changed.emit()


## 기본값 복원 — 저장 파일 삭제 + 프로젝트 설정 다시 로드
func reset_to_default() -> void:
    if FileAccess.file_exists(CFG_PATH):
        DirAccess.remove_absolute(CFG_PATH)
    InputMap.load_from_project_settings()
    bindings_changed.emit()


func _save() -> void:
    var cfg := ConfigFile.new()
    for action in REBINDABLE:
        var keys: Array[int] = []
        for ev in InputMap.action_get_events(action):
            if ev is InputEventKey:
                var k := ev as InputEventKey
                keys.append(int(k.physical_keycode if k.physical_keycode != 0 else k.keycode))
        cfg.set_value("bindings", action, keys)
    cfg.save(CFG_PATH)


func _load_and_apply() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(CFG_PATH) != OK:
        return
    for action in REBINDABLE:
        if not cfg.has_section_key("bindings", action):
            continue
        var keys = cfg.get_value("bindings", action, [])
        if not (keys is Array) or keys.is_empty():
            continue
        for ev in InputMap.action_get_events(action):
            if ev is InputEventKey:
                InputMap.action_erase_event(action, ev)
        for k in keys:
            var nev := InputEventKey.new()
            nev.physical_keycode = int(k)
            InputMap.action_add_event(action, nev)
    bindings_changed.emit()
