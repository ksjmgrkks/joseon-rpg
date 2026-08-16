extends CanvasLayer
##
## Player HUD — 좌상단 HP 바 + 레벨/XP. 'player' 그룹의 첫 노드를 찾아 HealthComponent에 연결,
## PlayerStats autoload에서 레벨/XP 가져옴.
##

@onready var panel: Control = $Panel
@onready var hp_bar: ProgressBar = $Panel/Margin/VBox/HPRow/Bar
@onready var hp_label: Label = $Panel/Margin/VBox/HPRow/Label
@onready var level_label: Label = $Panel/Margin/VBox/StatsRow/LevelLabel
@onready var xp_label: Label = $Panel/Margin/VBox/StatsRow/XpLabel
@onready var gold_label: Label = $Panel/Margin/VBox/StatsRow/GoldLabel   # 스코어어택: 점수 표시로 재활용
@onready var stats_row: HBoxContainer = $Panel/Margin/VBox/StatsRow
@onready var skill_row: HBoxContainer = $Panel/Margin/VBox/SkillRow

var _time_label: Label = null

const SKILL_ICON := "res://assets/ui/skill_%s.png"   # id 별 아이콘 경로
const SLOT_SIZE := 46.0

# 스킬 슬롯(아이콘+키+쿨다운) 노드 참조 — _build_skill_slots 에서 채운다.
var _slots: Array = []   # [{id, action, icon:TextureRect, key:Label, cd:Label}]


func _ready() -> void:
    var player := get_tree().get_first_node_in_group("player")
    if player == null:
        visible = false
        return
    var health: HealthComponent = player.get_node_or_null("HealthComponent")
    if health == null:
        visible = false
        return
    _update_hp(health.hp, health.max_hp)
    health.hp_changed.connect(_update_hp)

    _update_stats(PlayerStats.xp, PlayerStats.xp_to_next())
    PlayerStats.xp_changed.connect(_update_stats)
    PlayerStats.level_up.connect(_on_level_up)
    # 스코어어택 HUD — 엽전 자리를 점수로 바꾸고, 플레이타임 라벨을 추가.
    _time_label = Label.new()
    _time_label.add_theme_font_size_override("font_size", 14)
    if gold_label:
        gold_label.add_theme_font_size_override("font_size", 14)
    if stats_row:
        stats_row.add_child(_time_label)
    _update_score(ScoreManager.score)
    _update_time(ScoreManager.run_time)
    ScoreManager.score_changed.connect(_update_score)
    ScoreManager.playtime_changed.connect(_update_time)

    _build_skill_slots()
    SkillManager.cooldowns_changed.connect(_update_skills)
    PlayerStats.level_up.connect(func(_l: int) -> void: _update_skills())
    Flags.flag_changed.connect(func(_k: String, _v) -> void: _update_skills())
    InputConfig.bindings_changed.connect(_update_skill_keys)
    _update_skills()
    _update_skill_keys()

    # 대화가 뜨면 HUD를 감춰 몰입을 보존 — 끝나면 다시 부드럽게 나타난다.
    Dialogue.dialogue_started.connect(func(_s, _t, _c) -> void: _set_hud_visible(false))
    Dialogue.dialogue_ended.connect(func() -> void: _set_hud_visible(true))


func _set_hud_visible(show: bool) -> void:
    if panel == null:
        return
    var t := create_tween()
    t.tween_property(panel, "modulate:a", 1.0 if show else 0.0, 0.18)


## 스킬 슬롯 생성 — 이름 대신 아이콘 이미지. 슬롯 순서는 skills.json 의 slot(1~4).
## 각 슬롯: 아이콘(TextureRect) 위에 쿨다운 숫자, 아래에 실제 배정된 키(유저 키설정 반영).
func _build_skill_slots() -> void:
    for c in skill_row.get_children():
        c.queue_free()
    _slots.clear()
    for id in SkillManager.all_ids():
        var def := SkillManager.get_def(id)
        var slot_num := int(def.get("slot", 1))
        var action := "skill_%d" % slot_num

        var slot := Control.new()
        slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE + 12.0)
        slot.tooltip_text = "%s\n%s" % [String(def.get("name", id)), String(def.get("desc", ""))]

        var icon := TextureRect.new()
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        icon.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
        icon.size = Vector2(SLOT_SIZE, SLOT_SIZE)
        var tex_path := SKILL_ICON % id
        if ResourceLoader.exists(tex_path):
            icon.texture = load(tex_path)
        slot.add_child(icon)

        # 쿨다운 숫자 — 아이콘 중앙, 평소엔 숨김.
        var cd := Label.new()
        cd.add_theme_font_size_override("font_size", 20)
        cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        cd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        cd.set_anchors_preset(Control.PRESET_FULL_RECT)
        cd.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
        cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
        cd.visible = false
        slot.add_child(cd)

        # 배정된 키 — 아이콘 아래.
        var key := Label.new()
        key.add_theme_font_size_override("font_size", 13)
        key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        key.position = Vector2(0, SLOT_SIZE - 2.0)
        key.size = Vector2(SLOT_SIZE, 14.0)
        key.mouse_filter = Control.MOUSE_FILTER_IGNORE
        slot.add_child(key)

        skill_row.add_child(slot)
        _slots.append({"id": id, "action": action, "icon": icon, "key": key, "cd": cd})


## 스킬 상태 — 잠김: 어둡게, 쿨다운: 어둡게+남은 초, 준비: 밝게.
func _update_skills() -> void:
    for s in _slots:
        var id: String = s["id"]
        var icon: TextureRect = s["icon"]
        var cd_lbl: Label = s["cd"]
        if not SkillManager.is_unlocked(id):
            icon.modulate = Color(1, 1, 1, 0.28)
            cd_lbl.visible = true
            cd_lbl.text = "잠김"
            cd_lbl.add_theme_font_size_override("font_size", 13)
            cd_lbl.modulate = Color(1, 1, 1, 0.8)
        else:
            var cd := SkillManager.cooldown_left(id)
            if cd > 0.0:
                icon.modulate = Color(1, 1, 1, 0.4)
                cd_lbl.visible = true
                cd_lbl.text = "%d" % int(ceilf(cd))
                cd_lbl.add_theme_font_size_override("font_size", 20)
                cd_lbl.modulate = Color(1, 1, 1, 1)
            else:
                icon.modulate = Color(1, 1, 1, 1)
                cd_lbl.visible = false


## 배정된 키 표시 갱신 — 유저 키설정(InputConfig) 반영. 여러 키면 첫 키만.
func _update_skill_keys() -> void:
    for s in _slots:
        var key_lbl: Label = s["key"]
        var txt := InputConfig.binding_text(String(s["action"]))
        key_lbl.text = txt.split(",")[0].strip_edges()


func _update_hp(hp: float, max_hp: float) -> void:
    hp_bar.max_value = max_hp
    hp_bar.value = hp
    hp_label.text = "%d / %d" % [int(hp), int(max_hp)]
    # 저체력 경고색 — 30% 이하면 붉게(위험 인지)
    var ratio := hp / maxf(1.0, max_hp)
    if ratio <= 0.3:
        hp_bar.modulate = Color(1.0, 0.5, 0.5)
        hp_label.modulate = Color(1.0, 0.55, 0.55)
    else:
        hp_bar.modulate = Color.WHITE
        hp_label.modulate = Color.WHITE


func _update_stats(xp: int, xp_to_next: int) -> void:
    level_label.text = "Lv %d" % PlayerStats.level
    xp_label.text = "XP %d / %d" % [xp, xp + xp_to_next]


func _on_level_up(new_level: int) -> void:
    print("[Player] LEVEL UP → %d" % new_level)
    Audio.play_sfx(Sfx.PICKUP)


func _update_score(amount: int) -> void:
    if gold_label:
        gold_label.text = "점수 %d" % amount


func _update_time(seconds: float) -> void:
    if _time_label:
        _time_label.text = "시간 %s" % ScoreManager.format_time(seconds)
