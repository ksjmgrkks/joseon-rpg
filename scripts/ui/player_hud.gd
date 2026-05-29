extends CanvasLayer
##
## Player HUD — 좌상단 HP 바 + 레벨/XP. 'player' 그룹의 첫 노드를 찾아 HealthComponent에 연결,
## PlayerStats autoload에서 레벨/XP 가져옴.
##

@onready var hp_bar: ProgressBar = $Panel/Margin/VBox/HPRow/Bar
@onready var hp_label: Label = $Panel/Margin/VBox/HPRow/Label
@onready var level_label: Label = $Panel/Margin/VBox/StatsRow/LevelLabel
@onready var xp_label: Label = $Panel/Margin/VBox/StatsRow/XpLabel


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
