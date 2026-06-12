extends CanvasLayer
##
## Player HUD — 좌상단 HP 바 + 레벨/XP. 'player' 그룹의 첫 노드를 찾아 HealthComponent에 연결,
## PlayerStats autoload에서 레벨/XP 가져옴.
##

@onready var hp_bar: ProgressBar = $Panel/Margin/VBox/HPRow/Bar
@onready var hp_label: Label = $Panel/Margin/VBox/HPRow/Label
@onready var level_label: Label = $Panel/Margin/VBox/StatsRow/LevelLabel
@onready var xp_label: Label = $Panel/Margin/VBox/StatsRow/XpLabel
@onready var gold_label: Label = $Panel/Margin/VBox/StatsRow/GoldLabel
@onready var skill_labels: Dictionary = {
    "ilseom": $Panel/Margin/VBox/SkillRow/Skill1,
    "hoecheon": $Panel/Margin/VBox/SkillRow/Skill2,
    "hosinbu": $Panel/Margin/VBox/SkillRow/Skill3,
}

const SKILL_KEYS := { "ilseom": "1", "hoecheon": "2", "hosinbu": "3" }


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
    _update_gold(PlayerStats.gold)
    PlayerStats.gold_changed.connect(_update_gold)

    SkillManager.cooldowns_changed.connect(_update_skills)
    PlayerStats.level_up.connect(func(_l: int) -> void: _update_skills())
    Flags.flag_changed.connect(func(_k: String, _v) -> void: _update_skills())
    _update_skills()


## 스킬 줄 — 잠김: 회색 [잠김], 쿨다운: 남은 초, 준비: 흰색
func _update_skills() -> void:
    for id in skill_labels:
        var lbl: Label = skill_labels[id]
        if lbl == null:
            continue
        var def := SkillManager.get_def(id)
        var sname := String(def.get("name", id))
        var key: String = SKILL_KEYS.get(id, "?")
        if not SkillManager.is_unlocked(id):
            lbl.text = "[%s] %s(잠김)" % [key, sname]
            lbl.modulate = Color(1, 1, 1, 0.35)
        else:
            var cd := SkillManager.cooldown_left(id)
            if cd > 0.0:
                lbl.text = "[%s] %s %.0f" % [key, sname, ceilf(cd)]
                lbl.modulate = Color(1, 1, 1, 0.6)
            else:
                lbl.text = "[%s] %s" % [key, sname]
                lbl.modulate = Color(1, 1, 1, 1)


func _update_hp(hp: float, max_hp: float) -> void:
    hp_bar.max_value = max_hp
    hp_bar.value = hp
    hp_label.text = "%d / %d" % [int(hp), int(max_hp)]


func _update_stats(xp: int, xp_to_next: int) -> void:
    level_label.text = "Lv %d" % PlayerStats.level
    xp_label.text = "XP %d / %d" % [xp, xp + xp_to_next]


func _on_level_up(new_level: int) -> void:
    print("[Player] LEVEL UP → %d" % new_level)
    Audio.play_sfx(Sfx.PICKUP)


func _update_gold(amount: int) -> void:
    if gold_label:
        gold_label.text = "엽전 %d" % amount
